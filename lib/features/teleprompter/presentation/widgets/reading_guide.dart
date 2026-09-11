import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import 'prompt_text_view.dart';

/// The fixed horizontal line the reader tracks.
///
/// Drawn above the scrolling text and deliberately subtle: a soft gradient line
/// with a small centre notch, never a hard rule that competes with the words.
class ReadingGuide extends StatelessWidget {
  const ReadingGuide({
    required this.color,
    this.visible = true,
    super.key,
  });

  /// Height of the band the line is painted in — the line itself is thin, the
  /// band just gives the ends their tick marks room.
  static const double bandHeight = 14;

  final Color color;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: AppSpacing.medium,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double width = constraints.maxWidth;
            final double inset = width * 0.04;

            return Align(
              alignment: Alignment(
                0,
                PrompterLayout.readingLineFraction * 2 - 1,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: inset),
                child: SizedBox(
                  height: bandHeight,
                  // An explicit width is required: inside a loose constraint a
                  // SizedBox with only a height collapses to zero width and the
                  // guide would silently paint nothing.
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _GuidePainter(color: color),
                    isComplex: false,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GuidePainter extends CustomPainter {
  const _GuidePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final double y = size.height / 2;
    final double notchWidth = size.width * 0.09;
    final double lineStart = notchWidth;
    final double lineEnd = size.width - notchWidth;

    final Paint line = Paint()
      ..strokeWidth = 1.2
      ..shader = LinearGradient(
        colors: <Color>[
          color.withValues(alpha: 0),
          color.withValues(alpha: 0.55),
          color.withValues(alpha: 0.55),
          color.withValues(alpha: 0),
        ],
        stops: const <double>[0, 0.25, 0.75, 1],
      ).createShader(Rect.fromLTWH(lineStart, y - 1, lineEnd - lineStart, 2));

    canvas.drawLine(Offset(lineStart, y), Offset(lineEnd, y), line);

    final Paint marker = Paint()
      ..color = color.withValues(alpha: 0.75)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Small tick marks at both ends so the line is findable even on a busy
    // background, plus a centre notch for the exact reading spot.
    canvas
      ..drawLine(Offset(0, y - 4), Offset(0, y + 4), marker)
      ..drawLine(Offset(size.width, y - 4), Offset(size.width, y + 4), marker);

    marker.strokeWidth = 1.6;
    canvas.drawLine(
      Offset(size.width / 2, y - 3),
      Offset(size.width / 2, y + 3),
      marker,
    );
  }

  @override
  bool shouldRepaint(covariant _GuidePainter oldDelegate) => oldDelegate.color != color;
}
