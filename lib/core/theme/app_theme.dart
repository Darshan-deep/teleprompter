import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Material 3 theme for the app chrome.
///
/// Dark-first by design: the app is used in dim rooms next to cameras, so the
/// dark palette is the default and the light one is a deliberate, complete
/// counterpart rather than an afterthought.
abstract final class AppTheme {
  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  static ThemeData light() => _build(AppColors.light, Brightness.light);

  static ThemeData _build(AppColors colors, Brightness brightness) {
    final ColorScheme scheme = ColorScheme(
      brightness: brightness,
      primary: colors.primary,
      onPrimary: colors.onPrimary,
      primaryContainer: colors.primaryContainer,
      onPrimaryContainer: colors.onPrimaryContainer,
      secondary: colors.primary,
      onSecondary: colors.onPrimary,
      secondaryContainer: colors.surfaceHigh,
      onSecondaryContainer: colors.textPrimary,
      tertiary: colors.success,
      onTertiary: colors.onPrimary,
      error: colors.danger,
      onError: colors.onPrimary,
      errorContainer: colors.danger.withValues(alpha: 0.16),
      onErrorContainer: colors.danger,
      surface: colors.ink,
      onSurface: colors.textPrimary,
      surfaceContainerLowest: colors.ink,
      surfaceContainerLow: colors.surface,
      surfaceContainer: colors.surfaceHigh,
      surfaceContainerHigh: colors.surfaceHighest,
      surfaceContainerHighest: colors.surfaceHighest,
      onSurfaceVariant: colors.textSecondary,
      outline: colors.outline,
      outlineVariant: colors.outline,
      shadow: const Color(0xFF000000),
      scrim: colors.scrim,
      inverseSurface: colors.textPrimary,
      onInverseSurface: colors.ink,
      inversePrimary: colors.primaryContainer,
    );

    final TextTheme textTheme = AppTypography.textTheme(
      colors.textPrimary,
      colors.textSecondary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      extensions: <ThemeExtension<dynamic>>[colors],
      scaffoldBackgroundColor: colors.ink,
      canvasColor: colors.ink,
      fontFamily: AppTypography.uiFont,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarThemeData(
        backgroundColor: colors.ink,
        surfaceTintColor: Colors.transparent,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: AppSpacing.sm,
        toolbarHeight: 64,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: colors.textPrimary, size: 22),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(color: colors.outline, width: AppSpacing.hairline),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        modalBackgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll<Size>(
            Size(AppSpacing.minTapTarget, AppSpacing.controlHeight),
          ),
          padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
            EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          ),
          shape: WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
          textStyle: WidgetStatePropertyAll<TextStyle>(textTheme.labelLarge!),
          elevation: const WidgetStatePropertyAll<double>(0),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll<Size>(
            Size(AppSpacing.minTapTarget, AppSpacing.controlHeight),
          ),
          side: WidgetStatePropertyAll<BorderSide>(
            BorderSide(color: colors.outlineStrong, width: AppSpacing.hairline),
          ),
          foregroundColor: WidgetStatePropertyAll<Color>(colors.textPrimary),
          shape: WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
          textStyle: WidgetStatePropertyAll<TextStyle>(textTheme.labelLarge!),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll<Size>(
            Size(AppSpacing.minTapTarget, AppSpacing.minTapTarget),
          ),
          foregroundColor: WidgetStatePropertyAll<Color>(colors.textPrimary),
          textStyle: WidgetStatePropertyAll<TextStyle>(textTheme.labelLarge!),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll<Color>(colors.textSecondary),
          iconSize: const WidgetStatePropertyAll<double>(22),
          shape: WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: colors.surfaceHigh,
        hintStyle: textTheme.bodyMedium?.copyWith(color: colors.textTertiary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: colors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: colors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: colors.danger),
        ),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 4,
        activeTrackColor: colors.primary,
        inactiveTrackColor: colors.surfaceHighest,
        thumbColor: colors.primary,
        overlayColor: colors.primary.withValues(alpha: 0.14),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
        showValueIndicator: ShowValueIndicator.never,
      ),
      dividerTheme: DividerThemeData(
        color: colors.outline,
        thickness: AppSpacing.hairline,
        space: AppSpacing.hairline,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.surfaceHighest,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: colors.textPrimary),
        actionTextColor: colors.primary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colors.surfaceHighest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        textStyle: textTheme.bodyLarge,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) return colors.onPrimary;
          return colors.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) return colors.primary;
          return colors.surfaceHighest;
        }),
        trackOutlineColor: WidgetStatePropertyAll<Color>(colors.outlineStrong),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        linearTrackColor: colors.surfaceHighest,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colors.surfaceHighest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: colors.textPrimary),
        waitDuration: const Duration(milliseconds: 600),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
