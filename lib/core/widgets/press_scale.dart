import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';

/// Adds a short, functional press feedback (2 px scale) to any tappable child.
///
/// Used where material ink would be invisible or distracting — round prompter
/// buttons and the home CTA on a near-black background.
class PressScale extends StatefulWidget {
  const PressScale({
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.scale = 0.96,
    this.semanticLabel,
    this.borderRadius,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final String? semanticLabel;
  final BorderRadius? borderRadius;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onTapDown: enabled ? (_) => _setPressed(true) : null,
        onTapUp: enabled ? (_) => _setPressed(false) : null,
        onTapCancel: enabled ? () => _setPressed(false) : null,
        child: AnimatedScale(
          scale: _pressed ? widget.scale : 1,
          duration: AppSpacing.instant,
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}
