import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../domain/entities/script.dart';
import '../../domain/usecases/script_usecases.dart';
import 'script_list_state.dart';

/// Owns the home screen's list of scripts and every mutation that can be
/// triggered from it.
///
/// Mutations are optimistic: the list updates immediately and rolls back if the
/// store rejects the change, which keeps the UI instant on device while still
/// being honest when a save fails.
class ScriptListCubit extends Cubit<ScriptListState> {
  ScriptListCubit({
    required GetScripts getScripts,
    required SaveScript saveScript,
    required DeleteScript deleteScript,
    required DuplicateScript duplicateScript,
  })  : _getScripts = getScripts,
        _saveScript = saveScript,
        _deleteScript = deleteScript,
        _duplicateScript = duplicateScript,
        super(const ScriptListState());

  final GetScripts _getScripts;
  final SaveScript _saveScript;
  final DeleteScript _deleteScript;
  final DuplicateScript _duplicateScript;

  Future<void> load({bool showLoading = true}) async {
    if (showLoading) {
      emit(state.copyWith(status: ScriptListStatus.loading, clearFailure: true));
    }
    final result = await _getScripts();
    switch (result) {
      case Ok<List<Script>>(:final value):
        emit(
          state.copyWith(
            status: ScriptListStatus.ready,
            scripts: value,
            clearFailure: true,
          ),
        );
      case Err<List<Script>>(:final failure):
        emit(state.copyWith(status: ScriptListStatus.error, failure: failure));
    }
  }

  /// Reloads without flashing the loading state (used after returning from the
  /// editor or the prompter).
  Future<void> refresh() => load(showLoading: false);

  /// Creates a script and returns it, or `null` when saving failed.
  Future<Script?> createScript({
    String title = '',
    String content = '',
  }) async {
    final result = await _saveScript(title: title, content: content);
    switch (result) {
      case Ok<Script>(:final value):
        _insertOrReplace(value);
        return value;
      case Err<Script>(:final failure):
        emit(state.copyWith(failure: failure));
        return null;
    }
  }

  /// Applies an update coming from the editor (title and/or content).
  Future<Script?> updateScript({
    required String id,
    required String title,
    required String content,
  }) async {
    final result = await _saveScript(id: id, title: title, content: content);
    switch (result) {
      case Ok<Script>(:final value):
        _insertOrReplace(value);
        return value;
      case Err<Script>(:final failure):
        emit(state.copyWith(failure: failure));
        return null;
    }
  }

  /// Puts back a script that was just deleted (undo), keeping its original
  /// creation time and id so "the same script" really is the same script.
  Future<Script?> restoreScript(Script script) async {
    final result = await _saveScript(
      id: script.id,
      title: script.title,
      content: script.content,
      createdAt: script.createdAt,
    );
    switch (result) {
      case Ok<Script>(:final value):
        _insertOrReplace(value);
        return value;
      case Err<Script>(:final failure):
        emit(state.copyWith(failure: failure));
        return null;
    }
  }

  Future<bool> renameScript(String id, String title) async {
    final Script? existing = _find(id);
    if (existing == null) return false;

    _beginBusy(id);
    final result = await _saveScript(
      id: id,
      title: title,
      content: existing.content,
    );
    _endBusy(id);

    switch (result) {
      case Ok<Script>(:final value):
        _insertOrReplace(value);
        return true;
      case Err<Script>(:final failure):
        emit(state.copyWith(failure: failure));
        return false;
    }
  }

  Future<Script?> duplicateScript(String id) async {
    _beginBusy(id);
    final result = await _duplicateScript(id);
    _endBusy(id);

    switch (result) {
      case Ok<Script>(:final value):
        _insertOrReplace(value);
        return value;
      case Err<Script>(:final failure):
        emit(state.copyWith(failure: failure));
        return null;
    }
  }

  /// Deletes a script, removing it from the list immediately.
  Future<bool> deleteScript(String id) async {
    final List<Script> previous = state.scripts;
    final Script? removed = _find(id);
    if (removed == null) return false;

    _removeLocally(id);
    final result = await _deleteScript(id);
    switch (result) {
      case Ok<void>():
        return true;
      case Err<void>(:final failure):
        // Roll back so the UI keeps matching reality.
        emit(state.copyWith(scripts: previous, failure: failure));
        return false;
    }
  }

  void clearFailure() => emit(state.copyWith(clearFailure: true));

  Script? _find(String id) {
    for (final Script script in state.scripts) {
      if (script.id == id) return script;
    }
    return null;
  }

  void _insertOrReplace(Script script) {
    final List<Script> next = <Script>[
      script,
      ...state.scripts.where((Script item) => item.id != script.id),
    ]..sort((Script a, Script b) => b.updatedAt.compareTo(a.updatedAt));

    emit(
      state.copyWith(
        status: ScriptListStatus.ready,
        scripts: next,
        clearFailure: true,
      ),
    );
  }

  void _removeLocally(String id) {
    emit(
      state.copyWith(
        scripts: state.scripts.where((Script item) => item.id != id).toList(growable: false),
      ),
    );
  }

  void _beginBusy(String id) {
    emit(state.copyWith(busyScriptIds: <String>{...state.busyScriptIds, id}));
  }

  void _endBusy(String id) {
    emit(
      state.copyWith(
        busyScriptIds: <String>{...state.busyScriptIds}..remove(id),
      ),
    );
  }
}
