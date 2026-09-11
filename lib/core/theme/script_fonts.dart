import 'package:flutter/material.dart';

/// A typeface the reader can pick for prompter text.
///
/// All families are either bundled (see `pubspec.yaml`) or fetched from
/// Google Fonts at runtime, so the app renders identically on every platform.
@immutable
class ScriptFontFamily {
  const ScriptFontFamily({
    required this.id,
    required this.label,
    required this.family,
    required this.description,
  });

  /// Stable id persisted in settings.
  final String id;

  /// Human label shown in the picker.
  final String label;

  /// Flutter font family name.
  final String family;

  /// One-line guidance for choosing between faces.
  final String description;

  /// Stable ids, usable as const defaults inside other const constructors.
  static const String outfitId = 'outfit';
  static const String interId = 'inter';
  static const String atkinsonId = 'atkinson';
  static const String loraId = 'lora';
  static const String monoId = 'mono';

  static const ScriptFontFamily outfit = ScriptFontFamily(
    id: outfitId,
    label: 'Outfit',
    family: 'Outfit',
    description: 'Modern geometric · default',
  );

  static const ScriptFontFamily inter = ScriptFontFamily(
    id: interId,
    label: 'Inter',
    family: 'Inter',
    description: 'Neutral sans',
  );

  static const ScriptFontFamily atkinson = ScriptFontFamily(
    id: atkinsonId,
    label: 'Atkinson',
    family: 'AtkinsonHyperlegible',
    description: 'Maximum legibility',
  );

  static const ScriptFontFamily lora = ScriptFontFamily(
    id: loraId,
    label: 'Lora',
    family: 'Lora',
    description: 'Serif · comfortable long reads',
  );

  static const ScriptFontFamily mono = ScriptFontFamily(
    id: monoId,
    label: 'Mono',
    family: 'JetBrainsMono',
    description: 'Even spacing · narration',
  );

  static const List<ScriptFontFamily> values = <ScriptFontFamily>[
    outfit,
    inter,
    atkinson,
    lora,
    mono,
  ];

  static const ScriptFontFamily fallback = outfit;

  static ScriptFontFamily fromId(String? id) {
    if (id == null) return fallback;
    for (final ScriptFontFamily font in values) {
      if (font.id == id) return font;
    }
    return fallback;
  }
}
