import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The app mark: three text lines with the reading line highlighted.
///
/// Drawn with a painter instead of shipping an asset, so it stays crisp at any
/// size and recolours with the theme.
class PrompterLogo extends StatelessWidget {
  const PrompterLogo({this.size = 34, this.color, super.key});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final Color tint = color ?? colors.primary;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PrompterLogoPainter(tint: tint, surface: colors.surfaceHighest),
      ),
    );
  }
}

class _PrompterLogoPainter extends CustomPainter {
  const _PrompterLogoPainter({required this.tint, required this.surface});

  final Color tint;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width * 0.28;
    final RRect background = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    canvas
      ..save()
      ..clipRRect(background)
      ..drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = surface,
      )
      ..restore();

    final Paint line = Paint()
      ..color = tint.withValues(alpha: 0.45)
      ..strokeCap = StrokeCap.round;

    final double padding = size.width * 0.22;
    final double lineWidth = size.width - padding * 2;
    final double barHeight = size.height * 0.075;
    final double gap = size.height * 0.145;
    final double startY = size.height * 0.5 - gap;

    // Two soft lines above, the highlighted reading line, then one below.
    for (int i = 0; i < 3; i++) {
      final double y = startY + gap * i;
      final Rect rect = Rect.fromLTWH(padding, y - barHeight / 2, lineWidth, barHeight);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(barHeight)),
        i == 1 ? (Paint()..color = tint) : line,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PrompterLogoPainter oldDelegate) =>
      oldDelegate.tint != tint || oldDelegate.surface != surface;
}
