import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';
import '../theme/app_colors.dart';

/// Uniform icon button: fixed 44×44 tap area, borderless by default, optional
/// filled style for primary actions. Keeps every header in the app consistent.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.filled = false,
    this.iconSize = 20,
    this.foreground,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool filled;
  final double iconSize;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final Color color = onPressed == null
        ? colors.textTertiary
        : foreground ?? (filled ? colors.onPrimary : colors.textPrimary);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: filled ? colors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: AppSpacing.minTapTarget - AppSpacing.xs,
            height: AppSpacing.minTapTarget - AppSpacing.xs,
            child: Center(child: Icon(icon, size: iconSize, color: color)),
          ),
        ),
      ),
    );
  }
}
