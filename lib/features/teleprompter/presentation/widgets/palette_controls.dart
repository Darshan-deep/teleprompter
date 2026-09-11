import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/prompt_palette.dart';
import '../../../../core/widgets/option_picker.dart';
import '../../../../core/widgets/setting_row.dart';

/// Palette + custom colour controls, shared by the editor sheet and the live
/// prompter sheet so the two always look and behave the same.
class PaletteControls extends StatelessWidget {
  const PaletteControls({
    required this.themeId,
    required this.onThemeChanged,
    required this.onCustomColours,
    this.customBackground,
    this.customText,
    super.key,
  });

  final String themeId;
  final ValueChanged<String> onThemeChanged;
  final void Function(int background, int foreground) onCustomColours;
  final Color? customBackground;
  final Color? customText;

  @override
  Widget build(BuildContext context) {
    final PromptPalette resolved = PromptPalette.fromId(
      themeId,
      customBackground: customBackground,
      customForeground: customText,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        OptionPicker<String>(
          selected: themeId,
          previewHeight: 40,
          onSelected: onThemeChanged,
          options: PromptPalette.values
              .map(
                (PromptPalette palette) => PickerOption<String>(
                  value: palette.id,
                  label: palette.label,
                  previewBuilder: (BuildContext context) => _PaletteSwatch(
                    palette: palette.id == PromptPalette.customId ? resolved : palette,
                  ),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          resolved.description,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.colors.textTertiary,
              ),
        ),
        if (themeId == PromptPalette.customId) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          SettingsGroup(
            children: <Widget>[
              SettingRow(
                label: 'Text colour',
                description: _hex(resolved.foreground),
                trailing: _SwatchDot(color: resolved.foreground),
                onTap: () => _pick(context, background: false),
              ),
              SettingRow(
                label: 'Background colour',
                description: _hex(resolved.background),
                trailing: _SwatchDot(color: resolved.background),
                onTap: () => _pick(context, background: true),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _pick(BuildContext context, {required bool background}) async {
    final Color? picked = await showPromptColourPicker(
      context,
      title: background ? 'Background colour' : 'Text colour',
      initial: background
          ? (customBackground ?? PromptPalette.custom.background)
          : (customText ?? PromptPalette.custom.foreground),
    );
    if (picked == null) return;

    final PromptPalette current = PromptPalette.fromId(
      themeId,
      customBackground: customBackground,
      customForeground: customText,
    );
    onCustomColours(
      background ? picked.toARGB32() : current.background.toARGB32(),
      background ? current.foreground.toARGB32() : picked.toARGB32(),
    );
  }

  static String _hex(Color color) =>
      '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
}

class _PaletteSwatch extends StatelessWidget {
  const _PaletteSwatch({required this.palette});

  final PromptPalette palette;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: context.colors.outlineStrong,
          width: AppSpacing.hairline,
        ),
      ),
      child: Center(
        child: Text(
          'Aa',
          style: TextStyle(
            color: palette.foreground,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _SwatchDot extends StatelessWidget {
  const _SwatchDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: context.colors.outlineStrong),
      ),
    );
  }
}

/// Curated colour grid.
///
/// Deliberately a palette rather than a hue wheel: prompter colours need to be
/// high-contrast and glare-free, and a fixed set keeps every script readable.
Future<Color?> showPromptColourPicker(
  BuildContext context, {
  required String title,
  required Color initial,
}) {
  return showDialog<Color>(
    context: context,
    builder: (BuildContext dialogContext) {
      final AppColors colors = dialogContext.colors;
      final List<Color> swatches = <Color>[
        // Neutrals
        const Color(0xFF000000), const Color(0xFF0A0A0C), const Color(0xFF141414),
        const Color(0xFF1F1D1A), const Color(0xFF26262B), const Color(0xFF3A3A42),
        const Color(0xFF6E6E78), const Color(0xFF9A9AA5), const Color(0xFFC9C9D2),
        const Color(0xFFE8E8EE), const Color(0xFFF5F5F8), const Color(0xFFFFFFFF),
        // Warm
        const Color(0xFF1A1512), const Color(0xFF2A201A), const Color(0xFFF6E7D8),
        const Color(0xFFFFC46B), const Color(0xFFE8A33D), const Color(0xFFFFF3D6),
        // Cool / bright
        const Color(0xFF0F1A24), const Color(0xFF10202B), const Color(0xFF9FD8FF),
        const Color(0xFF7C8CFF), const Color(0xFF49D9A0), const Color(0xFFFF6B81),
      ];

      return AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 300,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
            ),
            itemCount: swatches.length,
            itemBuilder: (BuildContext context, int index) {
              final Color swatch = swatches[index];
              final bool isSelected = swatch.toARGB32() == initial.toARGB32();
              return GestureDetector(
                onTap: () => Navigator.of(dialogContext).pop(swatch),
                child: Container(
                  decoration: BoxDecoration(
                    color: swatch,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? colors.primary : colors.outlineStrong,
                      width: isSelected ? 2.5 : AppSpacing.hairline,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: swatch.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                        )
                      : null,
                ),
              );
            },
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
          ),
        ],
      );
    },
  );
}
