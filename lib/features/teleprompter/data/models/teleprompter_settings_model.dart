import 'dart:ui' show Color;

import 'package:flutter/painting.dart' show TextAlign;

import '../../../../core/theme/prompt_palette.dart';
import '../../../../core/theme/script_fonts.dart';
import '../../../../core/theme/script_typography.dart';
import '../../domain/entities/teleprompter_settings.dart';
import 'json_utils.dart';

/// Storage representation of [TeleprompterSettings].
///
/// Every field is read defensively and clamped, so an out-of-range or missing
/// value degrades to the default instead of producing an unreadable session.
class TeleprompterSettingsModel {
  const TeleprompterSettingsModel(this.settings);

  factory TeleprompterSettingsModel.fromEntity(TeleprompterSettings settings) =>
      TeleprompterSettingsModel(settings);

  factory TeleprompterSettingsModel.fromJson(Map<String, Object?> json) {
    const TeleprompterSettings defaults = TeleprompterSettings();

    return TeleprompterSettingsModel(
      TeleprompterSettings(
        speed: JsonUtils.readDouble(json['speed'], fallback: defaults.speed).clamp(
          TeleprompterSettings.minSpeed,
          TeleprompterSettings.maxSpeed,
        ),
        fontSize: JsonUtils.readDouble(json['fontSize'], fallback: defaults.fontSize).clamp(
          ScriptTypography.minFontSize,
          ScriptTypography.maxFontSize,
        ),
        lineHeight:
            JsonUtils.readDouble(json['lineHeight'], fallback: defaults.lineHeight).clamp(
          ScriptTypography.minPrompterLineHeight,
          ScriptTypography.maxPrompterLineHeight,
        ),
        paragraphSpacing: JsonUtils
            .readDouble(json['paragraphSpacing'], fallback: defaults.paragraphSpacing)
            .clamp(
          ScriptTypography.minParagraphSpacing,
          ScriptTypography.maxParagraphSpacing,
        ),
        mirrored: JsonUtils.readBool(json['mirrored'], fallback: defaults.mirrored),
        showReadingGuide:
            JsonUtils.readBool(json['showReadingGuide'], fallback: defaults.showReadingGuide),
        alignment: _readAlignment(json['alignment'], defaults.alignment),
        themeId: _readThemeId(json['themeId']),
        fontId: _readFontId(json['fontId']),
        customBackgroundColor: _readColor(json['customBackgroundColor']),
        customTextColor: _readColor(json['customTextColor']),
      ),
    );
  }

  final TeleprompterSettings settings;

  Map<String, Object?> toJson() => <String, Object?>{
        'speed': settings.speed,
        'fontSize': settings.fontSize,
        'lineHeight': settings.lineHeight,
        'paragraphSpacing': settings.paragraphSpacing,
        'mirrored': settings.mirrored,
        'showReadingGuide': settings.showReadingGuide,
        'alignment': _alignmentId(settings.alignment),
        'themeId': settings.themeId,
        'fontId': settings.fontId,
        'customBackgroundColor': settings.customBackgroundColor?.toARGB32(),
        'customTextColor': settings.customTextColor?.toARGB32(),
      };

  static TeleprompterSettings fromNullableJson(Object? raw) {
    if (raw is! Map) return const TeleprompterSettings();
    return TeleprompterSettingsModel.fromJson(JsonUtils.readMap(raw)).settings;
  }

  static const String _alignLeft = 'left';
  static const String _alignCenter = 'center';

  static String _alignmentId(TextAlign align) =>
      align == TextAlign.center ? _alignCenter : _alignLeft;

  static TextAlign _readAlignment(Object? value, TextAlign fallback) {
    final String id = JsonUtils.readString(value);
    return switch (id) {
      _alignCenter => TextAlign.center,
      _alignLeft => TextAlign.left,
      _ => fallback,
    };
  }

  /// Unknown palette ids fall back to the default instead of a broken canvas.
  static String _readThemeId(Object? value) {
    final String id = JsonUtils.readString(value);
    for (final PromptPalette palette in PromptPalette.values) {
      if (palette.id == id) return id;
    }
    return PromptPalette.classicId;
  }

  static String _readFontId(Object? value) {
    final String id = JsonUtils.readString(value);
    for (final ScriptFontFamily font in ScriptFontFamily.values) {
      if (font.id == id) return id;
    }
    return ScriptFontFamily.interId;
  }

  static Color? _readColor(Object? value) {
    final int? argb = JsonUtils.readInt(value);
    if (argb == null) return null;
    return Color(argb);
  }
}
