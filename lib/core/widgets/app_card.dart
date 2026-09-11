import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';
import '../theme/app_colors.dart';

/// Rounded, hairline-bordered surface used for every panel in the app.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = AppSpacing.cardPadding,
    this.color,
    this.borderRadius,
    this.borderColor,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double? borderRadius;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final double radius = borderRadius ?? AppSpacing.radiusLg;
    final BorderRadius shape = BorderRadius.circular(radius);

    return Material(
      color: color ?? colors.surface,
      borderRadius: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: shape,
            border: Border.all(
              color: borderColor ?? colors.outline,
              width: AppSpacing.hairline,
            ),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Small metadata chip (`128 words`, `1m 20s`) used on cards and in the editor.
class MetaChip extends StatelessWidget {
  const MetaChip({
    required this.icon,
    required this.label,
    this.dense = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: dense ? 12 : 13, color: colors.textTertiary),
        const SizedBox(width: AppSpacing.xs + 1),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.textTertiary,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
        ),
      ],
    );
  }
}
