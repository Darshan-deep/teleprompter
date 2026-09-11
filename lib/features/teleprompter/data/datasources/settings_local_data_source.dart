import 'dart:convert';

import '../../../../core/constants/storage_keys.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/teleprompter_settings.dart';
import '../models/app_settings_model.dart';
import '../models/teleprompter_settings_model.dart';
import 'key_value_store.dart';

/// Reads and writes prompter defaults.
abstract interface class TeleprompterSettingsLocalDataSource {
  Future<TeleprompterSettings> read();

  Future<void> write(TeleprompterSettings settings);

  Future<void> clear();
}

/// Reads and writes general app preferences.
abstract interface class AppSettingsLocalDataSource {
  Future<AppSettings> read();

  Future<void> write(AppSettings settings);

  Future<void> clear();
}

class TeleprompterSettingsLocalDataSourceImpl
    implements TeleprompterSettingsLocalDataSource {
  TeleprompterSettingsLocalDataSourceImpl(this._store);

  final KeyValueStore _store;

  @override
  Future<TeleprompterSettings> read() async {
    final Object? decoded = _tryDecode(_store.read(StorageKeys.teleprompterSettings));
    return TeleprompterSettingsModel.fromNullableJson(decoded);
  }

  @override
  Future<void> write(TeleprompterSettings settings) async {
    final String payload = jsonEncode(
      TeleprompterSettingsModel.fromEntity(settings).toJson(),
    );
    try {
      await _store.write(StorageKeys.teleprompterSettings, payload);
    } catch (error) {
      throw StorageException('Could not save prompter settings', cause: error);
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _store.remove(StorageKeys.teleprompterSettings);
    } catch (error) {
      throw StorageException('Could not reset prompter settings', cause: error);
    }
  }
}

class AppSettingsLocalDataSourceImpl implements AppSettingsLocalDataSource {
  AppSettingsLocalDataSourceImpl(this._store);

  final KeyValueStore _store;

  @override
  Future<AppSettings> read() async {
    final Object? decoded = _tryDecode(_store.read(StorageKeys.appSettings));
    return AppSettingsModel.fromNullableJson(decoded);
  }

  @override
  Future<void> write(AppSettings settings) async {
    final String payload = jsonEncode(AppSettingsModel.fromEntity(settings).toJson());
    try {
      await _store.write(StorageKeys.appSettings, payload);
    } catch (error) {
      throw StorageException('Could not save settings', cause: error);
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _store.remove(StorageKeys.appSettings);
    } catch (error) {
      throw StorageException('Could not reset settings', cause: error);
    }
  }
}

/// Corrupt payloads are treated as "nothing saved yet".
Object? _tryDecode(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    return jsonDecode(raw);
  } on FormatException {
    return null;
  }
}
