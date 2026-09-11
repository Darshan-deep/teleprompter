import 'package:flutter/material.dart';

/// Semantic colour tokens for the app chrome (not the prompter canvas, which
/// has its own catalogue in `prompt_palette.dart`).
///
/// Implemented as a [ThemeExtension] so widgets ask for meaning (`colors.textSecondary`)
/// instead of hard-coding hex values, and light/dark stay in sync.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.ink,
    required this.surface,
    required this.surfaceHigh,
    required this.surfaceHighest,
    required this.outline,
    required this.outlineStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.danger,
    required this.success,
    required this.warning,
    required this.scrim,
  });

  /// App background (near-black in dark mode).
  final Color ink;
  final Color surface;
  final Color surfaceHigh;
  final Color surfaceHighest;
  final Color outline;
  final Color outlineStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color danger;
  final Color success;
  final Color warning;
  final Color scrim;

  static const AppColors dark = AppColors(
    ink: Color(0xFF0A0A0C),
    surface: Color(0xFF131317),
    surfaceHigh: Color(0xFF1B1B21),
    surfaceHighest: Color(0xFF24242C),
    outline: Color(0xFF2A2A33),
    outlineStrong: Color(0xFF3B3B48),
    textPrimary: Color(0xFFF5F5F8),
    textSecondary: Color(0xFFA2A2B2),
    textTertiary: Color(0xFF6F6F7F),
    primary: Color(0xFF7C8CFF),
    onPrimary: Color(0xFF0B0B14),
    primaryContainer: Color(0xFF23274A),
    onPrimaryContainer: Color(0xFFC9CFFF),
    danger: Color(0xFFFF5F6D),
    success: Color(0xFF49D9A0),
    warning: Color(0xFFFFC46B),
    scrim: Color(0xCC000000),
  );

  static const AppColors light = AppColors(
    ink: Color(0xFFF5F5F8),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFF1F1F5),
    surfaceHighest: Color(0xFFE7E7EE),
    outline: Color(0xFFE1E1E9),
    outlineStrong: Color(0xFFC9C9D4),
    textPrimary: Color(0xFF15151B),
    textSecondary: Color(0xFF5F5F6D),
    textTertiary: Color(0xFF8C8C9B),
    primary: Color(0xFF4453E0),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE3E5FF),
    onPrimaryContainer: Color(0xFF1B2170),
    danger: Color(0xFFD92D3C),
    success: Color(0xFF0F8A5F),
    warning: Color(0xFF9A6200),
    scrim: Color(0x8A000000),
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>() ?? dark;

  @override
  AppColors copyWith({
    Color? ink,
    Color? surface,
    Color? surfaceHigh,
    Color? surfaceHighest,
    Color? outline,
    Color? outlineStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? primary,
    Color? onPrimary,
    Color? primaryContainer,
    Color? onPrimaryContainer,
    Color? danger,
    Color? success,
    Color? warning,
    Color? scrim,
  }) {
    return AppColors(
      ink: ink ?? this.ink,
      surface: surface ?? this.surface,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      surfaceHighest: surfaceHighest ?? this.surfaceHighest,
      outline: outline ?? this.outline,
      outlineStrong: outlineStrong ?? this.outlineStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
      danger: danger ?? this.danger,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      scrim: scrim ?? this.scrim,
    );
  }

  @override
  AppColors lerp(covariant AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      ink: Color.lerp(ink, other.ink, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t)!,
      surfaceHighest: Color.lerp(surfaceHighest, other.surfaceHighest, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      outlineStrong: Color.lerp(outlineStrong, other.outlineStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      primaryContainer: Color.lerp(primaryContainer, other.primaryContainer, t)!,
      onPrimaryContainer: Color.lerp(onPrimaryContainer, other.onPrimaryContainer, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
    );
  }
}

/// `context.colors.textSecondary` — the terse accessor used throughout the UI.
extension AppColorsContext on BuildContext {
  AppColors get colors => AppColors.of(this);
}
