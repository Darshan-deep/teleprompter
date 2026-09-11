import '../../../../core/errors/result.dart';
import '../../../../core/errors/result_guard.dart';
import '../entities/app_settings.dart';
import '../entities/teleprompter_settings.dart';
import '../repositories/settings_repository.dart';

/// Reads the saved prompter defaults (speed, size, palette, mirror…).
class GetTeleprompterSettings {
  const GetTeleprompterSettings(this._repository);

  final TeleprompterSettingsRepository _repository;

  Future<Result<TeleprompterSettings>> call() =>
      guard<TeleprompterSettings>(_repository.getSettings);
}

/// Persists prompter defaults. Any out-of-range value is clamped by the model,
/// so a malformed store can never produce an unreadable session.
class SaveTeleprompterSettings {
  const SaveTeleprompterSettings(this._repository);

  final TeleprompterSettingsRepository _repository;

  Future<Result<void>> call(TeleprompterSettings settings) =>
      guard<void>(() => _repository.saveSettings(settings));
}

class ResetTeleprompterSettings {
  const ResetTeleprompterSettings(this._repository);

  final TeleprompterSettingsRepository _repository;

  Future<Result<void>> call() => guard<void>(_repository.resetSettings);
}

/// Reads general preferences (app theme, keep-awake).
class GetAppSettings {
  const GetAppSettings(this._repository);

  final AppSettingsRepository _repository;

  Future<Result<AppSettings>> call() => guard<AppSettings>(_repository.getSettings);
}

class SaveAppSettings {
  const SaveAppSettings(this._repository);

  final AppSettingsRepository _repository;

  Future<Result<void>> call(AppSettings settings) =>
      guard<void>(() => _repository.saveSettings(settings));
}

class ResetAppSettings {
  const ResetAppSettings(this._repository);

  final AppSettingsRepository _repository;

  Future<Result<void>> call() => guard<void>(_repository.resetSettings);
}
