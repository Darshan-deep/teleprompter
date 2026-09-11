import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/prompt_palette.dart';
import '../../../../core/theme/script_fonts.dart';
import '../../../../core/theme/script_typography.dart';

/// Everything that controls how a script is presented while reading.
///
/// This is the model the teleprompter session starts from, and the model the
/// settings screen edits as the app-wide defaults.
@immutable
class TeleprompterSettings extends Equatable {
  const TeleprompterSettings({
    this.speed = defaultSpeed,
    this.fontSize = defaultFontSize,
    this.lineHeight = defaultLineHeight,
    this.paragraphSpacing = defaultParagraphSpacing,
    this.mirrored = false,
    this.showReadingGuide = true,
    this.alignment = TextAlign.left,
    this.themeId = PromptPalette.classicId,
    this.fontId = ScriptFontFamily.outfitId,
    this.customBackgroundColor,
    this.customTextColor,
  });

  /// Defaults live here (not in the widgets) so "Reset settings" has a single
  /// source of truth.
  static const double defaultSpeed = 0.9;
  static const double defaultFontSize = 44;
  static const double defaultLineHeight = 1.45;
  static const double defaultParagraphSpacing = 18;

  /// Speed is stored as 0…1; the scrolling engine converts it to px/s.
  final double speed;

  /// Logical pixels — see [ScriptTypography.minFontSize] / [maxFontSize].
  final double fontSize;

  /// Multiplier applied to the font size.
  final double lineHeight;

  /// Extra vertical gap inserted between paragraphs, in logical pixels.
  final double paragraphSpacing;

  final bool mirrored;
  final bool showReadingGuide;
  final TextAlign alignment;
  final String themeId;
  final String fontId;

  /// Only meaningful when [themeId] is `custom`.
  final Color? customBackgroundColor;
  final Color? customTextColor;

  PromptPalette get palette => PromptPalette.fromId(
        themeId,
        customBackground: customBackgroundColor,
        customForeground: customTextColor,
      );

  ScriptFontFamily get fontFamily => ScriptFontFamily.fromId(fontId);

  /// The style prompter text is rendered with.
  TextStyle textStyle(Color color) => ScriptTypography.build(
        fontFamily: fontFamily.family,
        fontSize: fontSize.clamp(
          ScriptTypography.minFontSize,
          ScriptTypography.maxFontSize,
        ),
        lineHeight: lineHeight,
        color: color,
        align: alignment,
        weight: FontWeight.w500,
      );

  TeleprompterSettings copyWith({
    double? speed,
    double? fontSize,
    double? lineHeight,
    double? paragraphSpacing,
    bool? mirrored,
    bool? showReadingGuide,
    TextAlign? alignment,
    String? themeId,
    String? fontId,
    Color? customBackgroundColor,
    Color? customTextColor,
  }) {
    return TeleprompterSettings(
      speed: (speed ?? this.speed).clamp(minSpeed, maxSpeed),
      fontSize: (fontSize ?? this.fontSize).clamp(
        ScriptTypography.minFontSize,
        ScriptTypography.maxFontSize,
      ),
      lineHeight: (lineHeight ?? this.lineHeight).clamp(
        ScriptTypography.minPrompterLineHeight,
        ScriptTypography.maxPrompterLineHeight,
      ),
      paragraphSpacing: (paragraphSpacing ?? this.paragraphSpacing).clamp(
        ScriptTypography.minParagraphSpacing,
        ScriptTypography.maxParagraphSpacing,
      ),
      mirrored: mirrored ?? this.mirrored,
      showReadingGuide: showReadingGuide ?? this.showReadingGuide,
      alignment: alignment ?? this.alignment,
      themeId: themeId ?? this.themeId,
      fontId: fontId ?? this.fontId,
      customBackgroundColor: customBackgroundColor ?? this.customBackgroundColor,
      customTextColor: customTextColor ?? this.customTextColor,
    );
  }

  /// Applies a change made inside a live session (settings that were adjusted
  /// while reading) without disturbing the rest.
  TeleprompterSettings mergeSession(TeleprompterSettings other) => copyWith(
        speed: other.speed,
        fontSize: other.fontSize,
        lineHeight: other.lineHeight,
        paragraphSpacing: other.paragraphSpacing,
        mirrored: other.mirrored,
        showReadingGuide: other.showReadingGuide,
        alignment: other.alignment,
        themeId: other.themeId,
        fontId: other.fontId,
        customBackgroundColor: other.customBackgroundColor,
        customTextColor: other.customTextColor,
      );

  /// Speed bounds, kept next to the field they constrain.
  static const double minSpeed = 0;
  static const double maxSpeed = 1;

  /// Human label for a normalised speed value.
  static String speedLabel(double value) {
    final int percent = (value * 100).round();
    if (percent < 20) return 'Very slow';
    if (percent < 40) return 'Slow';
    if (percent < 60) return 'Steady';
    if (percent < 80) return 'Brisk';
    if (percent < 100) return 'Fast';
    return 'Maximum';
  }

  static String fontSizeLabel(double fontSize) => '${fontSize.round()} pt';

  static String lineHeightLabel(double value) => '${value.toStringAsFixed(2)}×';

  static String spacingLabel(double value) => '${value.round()} px';

  @override
  List<Object?> get props => <Object?>[
        speed,
        fontSize,
        lineHeight,
        paragraphSpacing,
        mirrored,
        showReadingGuide,
        alignment,
        themeId,
        fontId,
        customBackgroundColor,
        customTextColor,
      ];
}
