import '../entities/app_settings.dart';
import '../entities/teleprompter_settings.dart';

/// App-wide defaults for the prompter (speed, size, palette, mirror…).
abstract interface class TeleprompterSettingsRepository {
  Future<TeleprompterSettings> getSettings();

  Future<void> saveSettings(TeleprompterSettings settings);

  Future<void> resetSettings();
}

/// General preferences: app theme and screen-awake behaviour.
abstract interface class AppSettingsRepository {
  Future<AppSettings> getSettings();

  Future<void> saveSettings(AppSettings settings);

  Future<void> resetSettings();
}
