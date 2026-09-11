import 'package:equatable/equatable.dart';

import 'teleprompter_settings.dart';

/// Which theme the app chrome uses. Independent of the prompter canvas palette.
enum AppThemeMode {
  dark('dark', 'Dark'),
  light('light', 'Light'),
  system('system', 'System');

  const AppThemeMode(this.id, this.label);

  final String id;
  final String label;

  static AppThemeMode fromId(String? id) {
    for (final AppThemeMode mode in values) {
      if (mode.id == id) return mode;
    }
    return AppThemeMode.dark;
  }
}

/// Preferences that describe the app itself plus the prompter defaults.
class AppSettings extends Equatable {
  const AppSettings({
    this.themeMode = AppThemeMode.dark,
    this.keepScreenAwake = true,
    this.teleprompter = const TeleprompterSettings(),
  });

  /// Dark-first: the app is used in studios and dim rooms.
  final AppThemeMode themeMode;

  /// Keeps the display on for the length of a prompter session.
  final bool keepScreenAwake;

  final TeleprompterSettings teleprompter;

  AppSettings copyWith({
    AppThemeMode? themeMode,
    bool? keepScreenAwake,
    TeleprompterSettings? teleprompter,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      teleprompter: teleprompter ?? this.teleprompter,
    );
  }

  @override
  List<Object?> get props => <Object?>[themeMode, keepScreenAwake, teleprompter];
}
