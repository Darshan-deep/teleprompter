import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/script_typography.dart';
import '../../domain/entities/teleprompter_settings.dart';

/// Bottom toolbar of the editor.
///
/// The two controls a writer reaches for constantly (text size and alignment)
/// act immediately; everything else opens the shared reading-setup sheet. Undo
/// and redo are here too, wired to the text field's undo history.
class EditorToolbar extends StatelessWidget {
  const EditorToolbar({
    required this.settings,
    required this.onSettingsChanged,
    required this.onOpenSetup,
    required this.onUndo,
    required this.onRedo,
    required this.canUndo,
    required this.canRedo,
    this.onReset,
    super.key,
  });

  final TeleprompterSettings settings;
  final ValueChanged<TeleprompterSettings> onSettingsChanged;
  final VoidCallback onOpenSetup;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final bool canUndo;
  final bool canRedo;
  final VoidCallback? onReset;

  static const double _sizeStep = 2;

  /// Below this width the toolbar shows only the writing essentials.
  static const double _regularWidth = 430;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.outline, width: AppSpacing.hairline),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              // Phones keep the writing essentials; the quick appearance
              // toggles live one tap away in the setup sheet rather than being
              // clipped off the edge of a narrow screen.
              final bool narrow = constraints.maxWidth < _regularWidth;
              return Row(
                children: <Widget>[
                  _SizeStepper(
                    value: settings.fontSize,
                    onDecrease: _canShrink
                        ? () => onSettingsChanged(
                              settings.copyWith(fontSize: settings.fontSize - _sizeStep),
                            )
                        : null,
                    onIncrease: _canGrow
                        ? () => onSettingsChanged(
                              settings.copyWith(fontSize: settings.fontSize + _sizeStep),
                            )
                        : null,
                  ),
                  if (!narrow) ...<Widget>[
                    const _ToolbarDivider(),
                    _ToolbarButton(
                      icon: settings.alignment == TextAlign.center
                          ? Icons.format_align_center_rounded
                          : Icons.format_align_left_rounded,
                      tooltip: settings.alignment == TextAlign.center
                          ? 'Center aligned'
                          : 'Left aligned',
                      onPressed: () => onSettingsChanged(
                        settings.copyWith(
                          alignment: settings.alignment == TextAlign.center
                              ? TextAlign.left
                              : TextAlign.center,
                        ),
                      ),
                    ),
                    _ToolbarButton(
                      icon: Icons.flip_rounded,
                      tooltip: 'Mirror text',
                      isActive: settings.mirrored,
                      onPressed: () => onSettingsChanged(
                        settings.copyWith(mirrored: !settings.mirrored),
                      ),
                    ),
                    _ToolbarButton(
                      icon: Icons.format_line_spacing_rounded,
                      tooltip: 'Spacing',
                      onPressed: onOpenSetup,
                    ),
                  ],
                  const Spacer(),
                  _ToolbarButton(
                    icon: Icons.undo_rounded,
                    tooltip: 'Undo',
                    onPressed: canUndo ? onUndo : null,
                  ),
                  _ToolbarButton(
                    icon: Icons.redo_rounded,
                    tooltip: 'Redo',
                    onPressed: canRedo ? onRedo : null,
                  ),
                  _ToolbarButton(
                    icon: Icons.tune_rounded,
                    tooltip: narrow ? 'Reading setup' : 'More settings',
                    onPressed: onOpenSetup,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  bool get _canShrink => settings.fontSize > ScriptTypography.minFontSize;

  bool get _canGrow => settings.fontSize < ScriptTypography.maxFontSize;
}

class _SizeStepper extends StatelessWidget {
  const _SizeStepper({
    required this.value,
    required this.onDecrease,
    required this.onIncrease,
  });

  final double value;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final TextTheme text = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _ToolbarButton(
          icon: Icons.text_decrease_rounded,
          tooltip: 'Smaller text',
          onPressed: onDecrease,
        ),
        SizedBox(
          width: 46,
          child: Text(
            TeleprompterSettings.fontSizeLabel(value),
            textAlign: TextAlign.center,
            style: text.labelLarge?.copyWith(
              color: colors.textPrimary,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ),
        _ToolbarButton(
          icon: Icons.text_increase_rounded,
          tooltip: 'Larger text',
          onPressed: onIncrease,
        ),
      ],
    );
  }
}

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Container(
          width: AppSpacing.hairline,
          height: 24,
          color: context.colors.outline,
        ),
      );
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isActive = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final bool enabled = onPressed != null;

    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        isSelected: isActive,
        selectedIcon: Icon(icon, size: 20, color: colors.primary),
        color: enabled ? colors.textSecondary : colors.textTertiary.withValues(alpha: 0.5),
        style: IconButton.styleFrom(
          minimumSize: const Size(AppSpacing.minTapTarget, AppSpacing.minTapTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
    );
  }
}
