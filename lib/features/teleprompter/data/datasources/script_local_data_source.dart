import 'dart:async';
import 'dart:convert';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/script.dart';
import '../models/script_model.dart';
import 'key_value_store.dart';

/// Raw script persistence. Returns entities so repositories stay thin and the
/// serialisation format never leaks upward.
abstract interface class ScriptLocalDataSource {
  Future<List<Script>> readAll();

  Future<Script?> readById(String id);

  Future<Script> upsert(Script script);

  Future<void> deleteById(String id);

  Future<void> clear();
}

/// JSON-in-shared_preferences implementation.
///
/// The decoded list is cached in memory, so a prompter start or a list rebuild
/// never re-parses the store, and mutations write through with a serialised
/// queue so two concurrent saves can't lose an update.
class ScriptLocalDataSourceImpl implements ScriptLocalDataSource {
  ScriptLocalDataSourceImpl(this._store);

  final KeyValueStore _store;

  List<ScriptModel>? _cache;
  Future<void> _writeChain = Future<void>.value();

  static const JsonEncoder _encoder = JsonEncoder();

  @override
  Future<List<Script>> readAll() async {
    final List<ScriptModel> models = _load();
    // Most recently edited first — the order the home screen wants.
    final List<ScriptModel> sorted = List<ScriptModel>.of(models)
      ..sort((ScriptModel a, ScriptModel b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted.map((ScriptModel model) => model.toEntity()).toList(growable: false);
  }

  @override
  Future<Script?> readById(String id) async {
    if (id.isEmpty) return null;
    for (final ScriptModel model in _load()) {
      if (model.id == id) return model.toEntity();
    }
    return null;
  }

  @override
  Future<Script> upsert(Script script) async {
    final ScriptModel model = ScriptModel.fromEntity(script);
    final List<ScriptModel> models = _load();

    final int index = models.indexWhere((ScriptModel item) => item.id == model.id);
    if (index >= 0) {
      models[index] = model;
    } else {
      models.add(model);
      _enforceLimit(models);
    }

    await _persist();
    return script;
  }

  @override
  Future<void> deleteById(String id) async {
    final List<ScriptModel> models = _load();
    final int before = models.length;
    models.removeWhere((ScriptModel item) => item.id == id);
    if (models.length == before) return; // Idempotent: nothing to write.
    await _persist();
  }

  @override
  Future<void> clear() async {
    _cache = <ScriptModel>[];
    await _serialize(() => _store.remove(StorageKeys.scripts));
  }

  /// Drops the least recently edited scripts if the store somehow grows past
  /// [AppConstants.maxStoredScripts] (protects memory and write latency).
  void _enforceLimit(List<ScriptModel> models) {
    if (models.length <= AppConstants.maxStoredScripts) return;
    models.sort((ScriptModel a, ScriptModel b) => a.updatedAt.compareTo(b.updatedAt));
    models.removeRange(0, models.length - AppConstants.maxStoredScripts);
  }

  List<ScriptModel> _load() {
    final List<ScriptModel>? cached = _cache;
    if (cached != null) return cached;

    final String? raw = _store.read(StorageKeys.scripts);
    if (raw == null || raw.isEmpty) {
      return _cache = <ScriptModel>[];
    }

    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) {
        return _cache = <ScriptModel>[];
      }
      final List<ScriptModel> models = decoded
          .map(ScriptModel.tryFromJson)
          .whereType<ScriptModel>()
          .toList();
      return _cache = models;
    } on FormatException {
      // Corrupt payload: start clean rather than crash on launch. The next
      // successful save rewrites the key with valid JSON.
      return _cache = <ScriptModel>[];
    }
  }

  Future<void> _persist() {
    final List<ScriptModel> models = _load();
    final String payload = _encoder.convert(
      models.map((ScriptModel model) => model.toJson()).toList(growable: false),
    );
    return _serialize(() => _store.write(StorageKeys.scripts, payload));
  }

  /// Ensures writes are applied one at a time, in call order.
  Future<void> _serialize(Future<void> Function() write) {
    final Future<void> next = _writeChain.then((_) => write());
    // Keep the chain alive even if a write fails; the error still reaches the
    // caller through `next`.
    _writeChain = next.catchError((Object _) {});
    return next.timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw const StorageException('Timed out while saving'),
    );
  }
}
