import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';
import '../theme/app_colors.dart';

/// Labelled slider row with a live value readout and optional reset.
///
/// The readout is fixed-width so the label never jitters while dragging, and
/// callers decide when to persist (usually on `onChangeEnd`) so a drag does not
/// hammer the storage layer.
class SliderField extends StatelessWidget {
  const SliderField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.onChangeEnd,
    this.valueLabel,
    this.divisions,
    this.icon,
    this.onReset,
    this.resetTooltip = 'Reset',
    super.key,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  final String? valueLabel;
  final int? divisions;
  final IconData? icon;
  final VoidCallback? onReset;
  final String resetTooltip;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final TextTheme text = Theme.of(context).textTheme;
    final bool modified = onReset != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 15, color: colors.textTertiary),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: Text(
                label,
                style: text.titleSmall?.copyWith(color: colors.textSecondary),
              ),
            ),
            if (valueLabel != null)
              Text(
                valueLabel!,
                style: text.labelLarge?.copyWith(
                  color: colors.textPrimary,
                  fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
            if (modified) ...<Widget>[
              const SizedBox(width: AppSpacing.xs),
              Tooltip(
                message: resetTooltip,
                child: IconButton(
                  onPressed: onReset,
                  icon: const Icon(Icons.restart_alt_rounded, size: 16),
                  visualDensity: VisualDensity.compact,
                  color: colors.textTertiary,
                  constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackShape: const RoundedRectSliderTrackShape(),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
            semanticFormatterCallback: (double v) => valueLabel ?? v.toStringAsFixed(1),
          ),
        ),
      ],
    );
  }
}
