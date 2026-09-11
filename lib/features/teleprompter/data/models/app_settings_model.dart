import '../../domain/entities/app_settings.dart';
import 'json_utils.dart';
import 'teleprompter_settings_model.dart';

/// Storage representation of [AppSettings].
class AppSettingsModel {
  const AppSettingsModel(this.settings);

  factory AppSettingsModel.fromEntity(AppSettings settings) => AppSettingsModel(settings);

  factory AppSettingsModel.fromJson(Map<String, Object?> json) {
    const AppSettings defaults = AppSettings();
    return AppSettingsModel(
      AppSettings(
        themeMode: JsonUtils.readEnum<AppThemeMode>(
          json['themeMode'],
          AppThemeMode.values,
          fallback: defaults.themeMode,
          idOf: (AppThemeMode mode) => mode.id,
        ),
        keepScreenAwake:
            JsonUtils.readBool(json['keepScreenAwake'], fallback: defaults.keepScreenAwake),
        teleprompter: TeleprompterSettingsModel.fromNullableJson(json['teleprompter']),
      ),
    );
  }

  final AppSettings settings;

  Map<String, Object?> toJson() => <String, Object?>{
        'themeMode': settings.themeMode.id,
        'keepScreenAwake': settings.keepScreenAwake,
        'teleprompter':
            TeleprompterSettingsModel.fromEntity(settings.teleprompter).toJson(),
      };

  static AppSettings fromNullableJson(Object? raw) {
    if (raw is! Map) return const AppSettings();
    return AppSettingsModel.fromJson(JsonUtils.readMap(raw)).settings;
  }
}
