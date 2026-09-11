import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/prompt_palette.dart';
import '../../../../core/theme/script_fonts.dart';
import '../../../../core/theme/script_typography.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/option_picker.dart';
import '../../../../core/widgets/setting_row.dart';
import '../../../../core/widgets/slider_field.dart';
import '../../domain/entities/teleprompter_settings.dart';
import 'palette_controls.dart';

/// Opens the reading-setup sheet.
///
/// The same sheet is used while editing (changing app-wide defaults) and while
/// reading (changing the live session), so the controls never move and muscle
/// memory carries over. Every change is reported immediately through
/// [onChanged], so the screen behind the sheet updates live.
Future<void> showScriptStyleSheet({
  required BuildContext context,
  required TeleprompterSettings settings,
  required ValueChanged<TeleprompterSettings> onChanged,
  String title = 'Reading setup',
  String? subtitle,
  bool showGuideControl = true,
  VoidCallback? onReset,
  String resetTooltip = 'Reset to defaults',
  Widget? footer,
}) {
  return showAppSheet<void>(
    context: context,
    title: title,
    subtitle: subtitle,
    actions: <Widget>[
      if (onReset != null)
        IconButton(
          tooltip: resetTooltip,
          onPressed: onReset,
          icon: const Icon(Icons.restart_alt_rounded, size: 20),
        ),
    ],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ScriptStyleSheet(
          initial: settings,
          onChanged: onChanged,
          showGuideControl: showGuideControl,
        ),
        ?footer,
      ],
    ),
  );
}

/// Live preview of the current reading setup, at the true reading size.
class ScriptPreviewStrip extends StatelessWidget {
  const ScriptPreviewStrip({required this.settings, this.height = 116, super.key});

  final TeleprompterSettings settings;
  final double height;

  static const String _sample = 'Read this line on camera.';

  @override
  Widget build(BuildContext context) {
    final PromptPalette palette = settings.palette;
    final TextStyle style = settings.textStyle(palette.foreground);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        height: height,
        width: double.infinity,
        color: palette.background,
        alignment: Alignment.center,
        child: Transform(
          alignment: Alignment.center,
          transform: settings.mirrored
              ? Matrix4.diagonal3Values(-1, 1, 1)
              : Matrix4.identity(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: FittedBox(
              // The sample is shown at the real reading size, and only scaled
              // down when the current size genuinely cannot fit the strip.
              fit: BoxFit.scaleDown,
              child: Text(
                _sample,
                textAlign: settings.alignment,
                maxLines: 1,
                style: style.copyWith(fontSize: style.fontSize!.clamp(18, 64)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The sheet body: text, spacing and appearance controls.
class ScriptStyleSheet extends StatefulWidget {
  const ScriptStyleSheet({
    required this.initial,
    required this.onChanged,
    this.showGuideControl = true,
    super.key,
  });

  final TeleprompterSettings initial;
  final ValueChanged<TeleprompterSettings> onChanged;
  final bool showGuideControl;

  @override
  State<ScriptStyleSheet> createState() => _ScriptStyleSheetState();
}

class _ScriptStyleSheetState extends State<ScriptStyleSheet> {
  late TeleprompterSettings _settings = _sanitize(widget.initial);

  /// Guards against a stale, half-written settings object coming from storage.
  TeleprompterSettings _sanitize(TeleprompterSettings value) => value.copyWith();

  void _update(TeleprompterSettings next, {bool notify = true}) {
    setState(() => _settings = next);
    if (notify) widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ScriptPreviewStrip(settings: _settings),
        SectionLabel('Text'),
        SliderField(
          label: 'Text size',
          icon: Icons.format_size_rounded,
          value: _settings.fontSize,
          min: ScriptTypography.minFontSize,
          max: ScriptTypography.maxFontSize,
          divisions: ((ScriptTypography.maxFontSize - ScriptTypography.minFontSize) / 2).round(),
          valueLabel: TeleprompterSettings.fontSizeLabel(_settings.fontSize),
          onChanged: (double value) => _update(_settings.copyWith(fontSize: value)),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Typeface',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colors.textSecondary,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        OptionPicker<String>(
          selected: _settings.fontId,
          previewHeight: 44,
          onSelected: (String id) => _update(_settings.copyWith(fontId: id)),
          options: ScriptFontFamily.values
              .map(
                (ScriptFontFamily font) => PickerOption<String>(
                  value: font.id,
                  label: font.label,
                  previewBuilder: (BuildContext context) => Center(
                    child: Text(
                      'Aa',
                      style: TextStyle(
                        fontFamily: font.family,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          _settings.fontFamily.description,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.textTertiary,
              ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Alignment',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colors.textSecondary,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        OptionPicker<TextAlign>(
          scrollable: false,
          selected: _settings.alignment,
          onSelected: (TextAlign align) => _update(_settings.copyWith(alignment: align)),
          options: const <PickerOption<TextAlign>>[
            PickerOption<TextAlign>(
              value: TextAlign.left,
              label: 'Left',
              icon: Icons.format_align_left_rounded,
            ),
            PickerOption<TextAlign>(
              value: TextAlign.center,
              label: 'Center',
              icon: Icons.format_align_center_rounded,
            ),
          ],
        ),
        SectionLabel('Spacing'),
        SliderField(
          label: 'Line height',
          icon: Icons.format_line_spacing_rounded,
          value: _settings.lineHeight,
          min: ScriptTypography.minPrompterLineHeight,
          max: ScriptTypography.maxPrompterLineHeight,
          divisions: 25,
          valueLabel: TeleprompterSettings.lineHeightLabel(_settings.lineHeight),
          onChanged: (double value) => _update(_settings.copyWith(lineHeight: value)),
        ),
        const SizedBox(height: AppSpacing.md),
        SliderField(
          label: 'Paragraph spacing',
          icon: Icons.notes_rounded,
          value: _settings.paragraphSpacing,
          min: ScriptTypography.minParagraphSpacing,
          max: ScriptTypography.maxParagraphSpacing,
          divisions: 24,
          valueLabel: TeleprompterSettings.spacingLabel(_settings.paragraphSpacing),
          onChanged: (double value) =>
              _update(_settings.copyWith(paragraphSpacing: value)),
        ),
        SectionLabel('Appearance'),
        PaletteControls(
          themeId: _settings.themeId,
          customBackground: _settings.customBackgroundColor,
          customText: _settings.customTextColor,
          onThemeChanged: (String id) => _update(_settings.copyWith(themeId: id)),
          onCustomColours: (int background, int foreground) => _update(
            _settings.copyWith(
              themeId: PromptPalette.customId,
              customBackgroundColor: Color(background),
              customTextColor: Color(foreground),
            ),
          ),
        ),
        SectionLabel('Session'),
        SettingsGroup(
          children: <Widget>[
            SettingRow(
              label: 'Mirror Text',
              description: 'For beam-splitter glass rigs — display only',
              leading: Icon(Icons.flip_rounded, size: 20, color: colors.textSecondary),
              trailing: Switch(
                value: _settings.mirrored,
                onChanged: (bool value) => _update(_settings.copyWith(mirrored: value)),
              ),
              onTap: () => _update(_settings.copyWith(mirrored: !_settings.mirrored)),
            ),
            if (widget.showGuideControl)
              SettingRow(
                label: 'Reading guide',
                description: 'Line across the middle to read against',
                leading: Icon(
                  Icons.horizontal_rule_rounded,
                  size: 20,
                  color: colors.textSecondary,
                ),
                trailing: Switch(
                  value: _settings.showReadingGuide,
                  onChanged: (bool value) =>
                      _update(_settings.copyWith(showReadingGuide: value)),
                ),
                onTap: () => _update(
                  _settings.copyWith(showReadingGuide: !_settings.showReadingGuide),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}
