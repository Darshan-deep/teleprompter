import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/script_fonts.dart';
import '../../../../core/theme/script_typography.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_icon_button.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/option_picker.dart';
import '../../../../core/widgets/setting_row.dart';
import '../../../../core/widgets/slider_field.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/teleprompter_settings.dart';
import '../bloc/app_settings_cubit.dart';
import '../bloc/app_settings_state.dart';
import '../widgets/palette_controls.dart';
import '../widgets/script_style_sheet.dart';

/// App settings: the prompter defaults, the app appearance and general
/// behaviour. Everything here writes to the same store the prompter reads, so a
/// change is visible on the next session.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    return Scaffold(
      backgroundColor: colors.ink,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: AppIconButton(
          icon: Icons.arrow_back_rounded,
          tooltip: 'Back',
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: BlocConsumer<AppSettingsCubit, AppSettingsState>(
        listenWhen: (AppSettingsState previous, AppSettingsState current) =>
            current.failure != null && previous.failure != current.failure,
        listener: (BuildContext context, AppSettingsState state) {
          final failure = state.failure;
          if (failure == null) return;
          showAppSnackBar(context, failure.message, icon: Icons.error_outline_rounded);
          context.read<AppSettingsCubit>().clearFailure();
        },
        builder: (BuildContext context, AppSettingsState state) {
          final AppSettingsCubit cubit = context.read<AppSettingsCubit>();
          final AppSettings settings = state.settings;
          final TeleprompterSettings prompter = settings.teleprompter;

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.xxxl,
                ),
                children: <Widget>[
                  const SectionLabel('Teleprompter defaults'),
                  const _PrompterPreview(),
                  const SizedBox(height: AppSpacing.md),
                  SettingsGroup(
                    children: <Widget>[
                      SettingRow(
                        label: 'Reading guide',
                        description: 'Line across the screen to read against',
                        trailing: Switch(
                          value: prompter.showReadingGuide,
                          onChanged: (bool value) => cubit.updateTeleprompter(
                            prompter.copyWith(showReadingGuide: value),
                            immediate: true,
                          ),
                        ),
                        onTap: () => cubit.updateTeleprompter(
                          prompter.copyWith(showReadingGuide: !prompter.showReadingGuide),
                          immediate: true,
                        ),
                      ),
                      SettingRow(
                        label: 'Mirror Text',
                        description: 'For prompter glass — display only',
                        trailing: Switch(
                          value: prompter.mirrored,
                          onChanged: (bool value) => cubit.updateTeleprompter(
                            prompter.copyWith(mirrored: value),
                            immediate: true,
                          ),
                        ),
                        onTap: () => cubit.updateTeleprompter(
                          prompter.copyWith(mirrored: !prompter.mirrored),
                          immediate: true,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.lg),
                    child: SliderField(
                      label: 'Default speed',
                      icon: Icons.speed_rounded,
                      value: prompter.speed,
                      min: TeleprompterSettings.minSpeed,
                      max: TeleprompterSettings.maxSpeed,
                      divisions: 20,
                      valueLabel: TeleprompterSettings.speedLabel(prompter.speed),
                      onChanged: (double value) => cubit.updateTeleprompter(
                        prompter.copyWith(speed: value),
                      ),
                      onChangeEnd: (double value) =>
                          cubit.updateTeleprompter(prompter.copyWith(speed: value)),
                    ),
                  ),
                  SliderField(
                    label: 'Default text size',
                    icon: Icons.format_size_rounded,
                    value: prompter.fontSize,
                    min: ScriptTypography.minFontSize,
                    max: ScriptTypography.maxFontSize,
                    divisions: ((ScriptTypography.maxFontSize -
                                ScriptTypography.minFontSize) /
                            2)
                        .round(),
                    valueLabel: TeleprompterSettings.fontSizeLabel(prompter.fontSize),
                    onChanged: (double value) => cubit.updateTeleprompter(
                      prompter.copyWith(fontSize: value),
                    ),
                    onChangeEnd: (double value) =>
                        cubit.updateTeleprompter(prompter.copyWith(fontSize: value)),
                  ),
                  const SectionLabel('Appearance'),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: OptionPicker<AppThemeMode>(
                      scrollable: false,
                      selected: settings.themeMode,
                      onSelected: cubit.setThemeMode,
                      options: AppThemeMode.values
                          .map(
                            (AppThemeMode mode) => PickerOption<AppThemeMode>(
                              value: mode,
                              label: mode.label,
                              icon: switch (mode) {
                                AppThemeMode.dark => Icons.dark_mode_outlined,
                                AppThemeMode.light => Icons.light_mode_outlined,
                                AppThemeMode.system => Icons.brightness_auto_outlined,
                              },
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                  const SectionLabel('Prompter canvas'),
                  PaletteControls(
                    themeId: prompter.themeId,
                    customBackground: prompter.customBackgroundColor,
                    customText: prompter.customTextColor,
                    onThemeChanged: (String id) =>
                        cubit.updateTeleprompter(prompter.copyWith(themeId: id), immediate: true),
                    onCustomColours: (int background, int foreground) =>
                        cubit.updateTeleprompter(
                      prompter.copyWith(
                        themeId: 'custom',
                        customBackgroundColor: Color(background),
                        customTextColor: Color(foreground),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Typeface',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OptionPicker<String>(
                    selected: prompter.fontId,
                    previewHeight: 44,
                    onSelected: (String id) =>
                        cubit.updateTeleprompter(prompter.copyWith(fontId: id), immediate: true),
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
                  SliderField(
                    label: 'Line height',
                    icon: Icons.format_line_spacing_rounded,
                    value: prompter.lineHeight,
                    min: ScriptTypography.minPrompterLineHeight,
                    max: ScriptTypography.maxPrompterLineHeight,
                    divisions: 25,
                    valueLabel: TeleprompterSettings.lineHeightLabel(prompter.lineHeight),
                    onChanged: (double value) => cubit.updateTeleprompter(
                      prompter.copyWith(lineHeight: value),
                    ),
                    onChangeEnd: (double value) => cubit.updateTeleprompter(
                      prompter.copyWith(lineHeight: value),
                    ),
                  ),
                  SliderField(
                    label: 'Paragraph spacing',
                    icon: Icons.notes_rounded,
                    value: prompter.paragraphSpacing,
                    min: ScriptTypography.minParagraphSpacing,
                    max: ScriptTypography.maxParagraphSpacing,
                    divisions: 24,
                    valueLabel:
                        TeleprompterSettings.spacingLabel(prompter.paragraphSpacing),
                    onChanged: (double value) => cubit.updateTeleprompter(
                      prompter.copyWith(paragraphSpacing: value),
                    ),
                    onChangeEnd: (double value) => cubit.updateTeleprompter(
                      prompter.copyWith(paragraphSpacing: value),
                    ),
                  ),
                  const SectionLabel('General'),
                  SettingsGroup(
                    children: <Widget>[
                      SettingRow(
                        label: 'Keep screen awake',
                        description: 'Stops the display sleeping during a session',
                        leading: Icon(
                          Icons.brightness_high_outlined,
                          size: 20,
                          color: colors.textSecondary,
                        ),
                        trailing: Switch(
                          value: settings.keepScreenAwake,
                          onChanged: cubit.setKeepScreenAwake,
                        ),
                        onTap: () =>
                            cubit.setKeepScreenAwake(!settings.keepScreenAwake),
                      ),
                      SettingRow(
                        label: 'Reset settings',
                        description: 'Back to the defaults, scripts are kept',
                        leading: Icon(
                          Icons.restart_alt_rounded,
                          size: 20,
                          color: colors.textSecondary,
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: colors.textTertiary,
                        ),
                        onTap: () => _reset(context, cubit),
                      ),
                      SettingRow(
                        label: 'About',
                        description: 'Version, shortcuts and offline note',
                        leading: Icon(
                          Icons.info_outline_rounded,
                          size: 20,
                          color: colors.textSecondary,
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: colors.textTertiary,
                        ),
                        onTap: () => _about(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _reset(BuildContext context, AppSettingsCubit cubit) async {
    final bool confirmed = await showConfirmDialog(
      context,
      title: 'Reset settings?',
      message:
          'Speed, text size, spacing, colours and the app theme return to their '
          'defaults. Your scripts are not touched.',
      confirmLabel: 'Reset',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await cubit.resetToDefaults();
    if (!context.mounted) return;
    showAppSnackBar(context, 'Settings reset', icon: Icons.restart_alt_rounded);
  }

  Future<void> _about(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        final TextTheme text = Theme.of(dialogContext).textTheme;
        final AppColors colors = dialogContext.colors;

        Widget shortcut(String keys, String action) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceHighest,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      border: Border.all(color: colors.outline),
                    ),
                    child: Text(keys, style: text.labelSmall),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Text(action, style: text.bodySmall)),
                ],
              ),
            );

        return AlertDialog(
          title: Text('${AppConstants.appName} ${AppConstants.appVersion}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(AppConstants.appTagline, style: text.bodyMedium),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Everything is stored on this device — scripts, settings and '
                  'colours. The app never needs a network connection.',
                  style: text.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('KEYBOARD SHORTCUTS', style: text.labelMedium),
                const SizedBox(height: AppSpacing.md),
                shortcut('Ctrl / ⌘ + S', 'Save the script'),
                shortcut('Ctrl / ⌘ + ⏎', 'Save and start the prompter'),
                shortcut('Space', 'Play / pause while reading'),
                shortcut('↑ / ↓', 'Faster / slower'),
                shortcut('R', 'Restart from the top'),
                shortcut('M', 'Mirror the text'),
                shortcut('G', 'Toggle the reading guide'),
                shortcut('Esc', 'Leave the prompter'),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          actions: <Widget>[
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

/// Small live preview so the defaults can be judged without starting a session.
class _PrompterPreview extends StatelessWidget {
  const _PrompterPreview();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AppSettingsCubit, AppSettingsState, TeleprompterSettings>(
      selector: (AppSettingsState state) => state.settings.teleprompter,
      builder: (BuildContext context, TeleprompterSettings settings) =>
          ScriptPreviewStrip(settings: settings),
    );
  }
}
