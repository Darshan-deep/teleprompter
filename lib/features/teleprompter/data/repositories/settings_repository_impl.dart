import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/teleprompter_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_data_source.dart';

class TeleprompterSettingsRepositoryImpl implements TeleprompterSettingsRepository {
  const TeleprompterSettingsRepositoryImpl(this._localDataSource);

  final TeleprompterSettingsLocalDataSource _localDataSource;

  @override
  Future<TeleprompterSettings> getSettings() async {
    try {
      return await _localDataSource.read();
    } catch (error) {
      throw StorageException('Could not read prompter settings', cause: error);
    }
  }

  @override
  Future<void> saveSettings(TeleprompterSettings settings) async {
    try {
      await _localDataSource.write(settings);
    } catch (error) {
      throw StorageException('Could not save prompter settings', cause: error);
    }
  }

  @override
  Future<void> resetSettings() async {
    try {
      await _localDataSource.clear();
    } catch (error) {
      throw StorageException('Could not reset prompter settings', cause: error);
    }
  }
}

class AppSettingsRepositoryImpl implements AppSettingsRepository {
  const AppSettingsRepositoryImpl(this._localDataSource);

  final AppSettingsLocalDataSource _localDataSource;

  @override
  Future<AppSettings> getSettings() async {
    try {
      return await _localDataSource.read();
    } catch (error) {
      throw StorageException('Could not read settings', cause: error);
    }
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    try {
      await _localDataSource.write(settings);
    } catch (error) {
      throw StorageException('Could not save settings', cause: error);
    }
  }

  @override
  Future<void> resetSettings() async {
    try {
      await _localDataSource.clear();
    } catch (error) {
      throw StorageException('Could not reset settings', cause: error);
    }
  }
}
