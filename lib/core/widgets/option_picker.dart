import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';
import '../theme/app_colors.dart';

/// One choice in an [OptionPicker].
@immutable
class PickerOption<T> {
  const PickerOption({
    required this.value,
    required this.label,
    this.icon,
    this.previewBuilder,
  });

  final T value;
  final String label;

  /// Optional leading icon (e.g. alignment glyph).
  final IconData? icon;

  /// Optional visual preview rendered above the label (used to show a typeface
  /// or a colour pair rather than just naming it).
  final WidgetBuilder? previewBuilder;
}

/// A horizontal row of selectable pills — the single control used for
/// alignment, font family, palette and theme choices so the UI never sprouts
/// five different toggle styles.
class OptionPicker<T> extends StatelessWidget {
  const OptionPicker({
    required this.options,
    required this.selected,
    required this.onSelected,
    this.scrollable = true,
    this.previewHeight,
    super.key,
  });

  final List<PickerOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;

  /// When false, options share the available width equally.
  final bool scrollable;

  final double? previewHeight;

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = options
        .map((PickerOption<T> option) => _OptionTile<T>(
              option: option,
              isSelected: option.value == selected,
              previewHeight: previewHeight,
              onTap: () => onSelected(option.value),
            ))
        .toList(growable: false);

    if (!scrollable) {
      return Row(
        children: <Widget>[
          for (int i = 0; i < children.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            Expanded(child: children[i]),
          ],
        ],
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: <Widget>[
          for (int i = 0; i < children.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _OptionTile<T> extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
    this.previewHeight,
  });

  final PickerOption<T> option;
  final bool isSelected;
  final VoidCallback onTap;
  final double? previewHeight;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final TextTheme text = Theme.of(context).textTheme;
    final bool hasPreview = option.previewBuilder != null;

    return Semantics(
      button: true,
      selected: isSelected,
      label: option.label,
      child: Material(
        color: isSelected ? colors.primaryContainer : colors.surfaceHigh,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppSpacing.instant,
            curve: Curves.easeOut,
            constraints: const BoxConstraints(
              minHeight: AppSpacing.minTapTarget,
              minWidth: AppSpacing.minTapTarget,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: hasPreview ? AppSpacing.sm : AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: isSelected ? colors.primary : Colors.transparent,
                width: AppSpacing.hairline,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (option.previewBuilder != null) ...<Widget>[
                  SizedBox(
                    height: previewHeight ?? 40,
                    width: 56,
                    child: option.previewBuilder!(context),
                  ),
                  const SizedBox(height: AppSpacing.xs + 2),
                ],
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (option.icon != null) ...<Widget>[
                      Icon(
                        option.icon,
                        size: 16,
                        color: isSelected ? colors.onPrimaryContainer : colors.textSecondary,
                      ),
                      if (option.label.isNotEmpty) const SizedBox(width: AppSpacing.xs + 2),
                    ],
                    if (option.label.isNotEmpty)
                      Text(
                        option.label,
                        style: text.labelLarge?.copyWith(
                          color: isSelected ? colors.onPrimaryContainer : colors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
