import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';
import '../theme/app_colors.dart';

/// All-caps section heading used in settings and sheets.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.label, {this.trailing, super.key});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.xxl,
        AppSpacing.xs,
        AppSpacing.md,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.textTertiary,
                    letterSpacing: 0.8,
                  ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Card that groups related rows with hairline separators between them.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({required this.children, this.dividerIndices, super.key});

  final List<Widget> children;

  /// Rows after which a divider is drawn. Defaults to every row but the last.
  final Set<int>? dividerIndices;

  @override
  Widget build(BuildContext context) {
    final Set<int> dividers = dividerIndices ??
        <int>{for (int i = 0; i < children.length - 1; i++) i};
    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (dividers.contains(i) && i != children.length - 1) {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.lg),
            child: Divider(height: AppSpacing.hairline, color: context.colors.outline),
          ),
        );
      }
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: context.colors.outline, width: AppSpacing.hairline),
      ),
      child: Column(children: rows),
    );
  }
}

/// Label + optional description + trailing control, laid out for one-handed use
/// (control anchored to the trailing edge, whole row tappable when it navigates).
class SettingRow extends StatelessWidget {
  const SettingRow({
    required this.label,
    this.description,
    this.leading,
    this.trailing,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
    super.key,
  });

  final String label;
  final String? description;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final TextTheme text = Theme.of(context).textTheme;

    final Widget content = Padding(
      padding: padding,
      child: Row(
        children: <Widget>[
          if (leading != null) ...<Widget>[
            leading!,
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(label, style: text.titleMedium),
                if (description != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    description!,
                    style: text.bodySmall?.copyWith(color: colors.textTertiary),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: AppSpacing.md),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: content,
    );
  }
}
