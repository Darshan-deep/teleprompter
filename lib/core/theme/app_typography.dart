import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typographic scale for the app chrome. Script text inside the prompter uses
/// its own user-controlled sizing (`ScriptTypography`), never these styles.
abstract final class AppTypography {
  static String get uiFont => GoogleFonts.outfit().fontFamily ?? 'Outfit';

  static TextTheme textTheme(Color primary, Color secondary) => TextTheme(
        displaySmall: GoogleFonts.outfit(
          fontSize: 34,
          height: 1.15,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
          color: primary,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 26,
          height: 1.2,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: primary,
        ),
        headlineSmall: GoogleFonts.outfit(
          fontSize: 21,
          height: 1.25,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          color: primary,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 18,
          height: 1.3,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: primary,
        ),
        titleMedium: GoogleFonts.outfit(
          fontSize: 15.5,
          height: 1.35,
          fontWeight: FontWeight.w600,
          color: primary,
        ),
        titleSmall: GoogleFonts.outfit(
          fontSize: 13.5,
          height: 1.3,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: secondary,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 16,
          height: 1.45,
          fontWeight: FontWeight.w400,
          color: primary,
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 14,
          height: 1.45,
          fontWeight: FontWeight.w400,
          color: secondary,
        ),
        bodySmall: GoogleFonts.outfit(
          fontSize: 12.5,
          height: 1.4,
          fontWeight: FontWeight.w400,
          color: secondary,
        ),
        labelLarge: GoogleFonts.outfit(
          fontSize: 14,
          height: 1.2,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: primary,
        ),
        labelMedium: GoogleFonts.outfit(
          fontSize: 11.5,
          height: 1.2,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: secondary,
        ),
        labelSmall: GoogleFonts.outfit(
          fontSize: 10.5,
          height: 1.2,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: secondary,
        ),
      );
}
