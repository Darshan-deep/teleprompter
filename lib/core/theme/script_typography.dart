import 'package:flutter/material.dart';

/// Builds the text style used for script content, in the editor and in the
/// prompter. Kept parameter-only (no feature imports) so both can share it.
abstract final class ScriptTypography {
  /// Prompter scripts need more leading than UI copy: the reader's eye has to
  /// track a moving line without losing its place.
  static const double minPrompterLineHeight = 1.15;
  static const double maxPrompterLineHeight = 2.4;

  static const double minFontSize = 20;
  static const double maxFontSize = 100;

  static const double minParagraphSpacing = 0;
  static const double maxParagraphSpacing = 48;

  static TextStyle build({
    required String fontFamily,
    required double fontSize,
    required double lineHeight,
    required Color color,
    TextAlign align = TextAlign.left,
    FontWeight weight = FontWeight.w500,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      height: lineHeight.clamp(minPrompterLineHeight, maxPrompterLineHeight),
      color: color,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      // Prompter text must never be silently truncated or ellipsised.
      overflow: TextOverflow.clip,
    );
  }
}
