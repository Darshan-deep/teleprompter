import 'package:flutter/material.dart';

/// Typographic scale for the app chrome. Script text inside the prompter uses
/// its own user-controlled sizing (`ScriptTypography`), never these styles.
abstract final class AppTypography {
  static const String uiFont = 'Inter';

  static TextTheme textTheme(Color primary, Color secondary) => TextTheme(
        displaySmall: TextStyle(
          fontFamily: uiFont,
          fontSize: 34,
          height: 1.15,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
          color: primary,
        ),
        headlineMedium: TextStyle(
          fontFamily: uiFont,
          fontSize: 26,
          height: 1.2,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: primary,
        ),
        headlineSmall: TextStyle(
          fontFamily: uiFont,
          fontSize: 21,
          height: 1.25,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          color: primary,
        ),
        titleLarge: TextStyle(
          fontFamily: uiFont,
          fontSize: 18,
          height: 1.3,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: primary,
        ),
        titleMedium: TextStyle(
          fontFamily: uiFont,
          fontSize: 15.5,
          height: 1.35,
          fontWeight: FontWeight.w600,
          color: primary,
        ),
        titleSmall: TextStyle(
          fontFamily: uiFont,
          fontSize: 13.5,
          height: 1.3,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: secondary,
        ),
        bodyLarge: TextStyle(
          fontFamily: uiFont,
          fontSize: 16,
          height: 1.45,
          fontWeight: FontWeight.w400,
          color: primary,
        ),
        bodyMedium: TextStyle(
          fontFamily: uiFont,
          fontSize: 14,
          height: 1.45,
          fontWeight: FontWeight.w400,
          color: secondary,
        ),
        bodySmall: TextStyle(
          fontFamily: uiFont,
          fontSize: 12.5,
          height: 1.4,
          fontWeight: FontWeight.w400,
          color: secondary,
        ),
        labelLarge: TextStyle(
          fontFamily: uiFont,
          fontSize: 14,
          height: 1.2,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: primary,
        ),
        labelMedium: TextStyle(
          fontFamily: uiFont,
          fontSize: 11.5,
          height: 1.2,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: secondary,
        ),
        labelSmall: TextStyle(
          fontFamily: uiFont,
          fontSize: 10.5,
          height: 1.2,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: secondary,
        ),
      );
}
