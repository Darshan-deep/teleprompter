import 'package:flutter/material.dart';

/// Background/text combinations for the prompter canvas.
///
/// The prompter is deliberately independent of the app theme: a reader may want
/// a light canvas while the rest of the app stays dark, and mirror rigs behave
/// best with high-contrast, low-glare combinations.
@immutable
class PromptPalette {
  const PromptPalette({
    required this.id,
    required this.label,
    required this.description,
    required this.background,
    required this.foreground,
  });

  final String id;
  final String label;
  final String description;
  final Color background;
  final Color foreground;

  /// True when the canvas is dark, used to pick control-chrome contrast.
  bool get isDark => background.computeLuminance() < 0.4;

  /// Stable ids. Declared as constants so they can be used as const defaults
  /// (a const constructor cannot read a field of another const instance).
  static const String classicId = 'classic';
  static const String warmId = 'warm';
  static const String lightId = 'light';
  static const String customId = 'custom';

  static const PromptPalette classic = PromptPalette(
    id: classicId,
    label: 'Classic',
    description: 'Black canvas, white text',
    background: Color(0xFF000000),
    foreground: Color(0xFFFFFFFF),
  );

  static const PromptPalette warm = PromptPalette(
    id: warmId,
    label: 'Warm',
    description: 'Low-glare amber on charcoal',
    background: Color(0xFF1A1512),
    foreground: Color(0xFFF6E7D8),
  );

  static const PromptPalette light = PromptPalette(
    id: lightId,
    label: 'Light',
    description: 'Paper white, black text',
    background: Color(0xFFF7F6F2),
    foreground: Color(0xFF121212),
  );

  /// Placeholder id — the actual colours come from user selection.
  static const PromptPalette custom = PromptPalette(
    id: customId,
    label: 'Custom',
    description: 'Your own colours',
    background: Color(0xFF101820),
    foreground: Color(0xFFF2F2F2),
  );

  static const List<PromptPalette> values = <PromptPalette>[
    classic,
    warm,
    light,
    custom,
  ];

  static const PromptPalette fallback = classic;

  static PromptPalette fromId(String? id, {
    Color? customBackground,
    Color? customForeground,
  }) {
    if (id == customId) {
      return PromptPalette.custom.copyWith(
        background: customBackground,
        foreground: customForeground,
      );
    }
    for (final PromptPalette palette in values) {
      if (palette.id == id) return palette;
    }
    return fallback;
  }

  PromptPalette copyWith({Color? background, Color? foreground}) => PromptPalette(
        id: id,
        label: label,
        description: description,
        background: background ?? this.background,
        foreground: foreground ?? this.foreground,
      );

  /// Swatch colours for the palette picker.
  List<Color> get swatch => <Color>[background, foreground];
}
