import 'package:flutter_test/flutter_test.dart';
import 'package:teleprompter/core/constants/app_constants.dart';
import 'package:teleprompter/features/teleprompter/domain/usecases/compute_scroll_speed.dart';

void main() {
  const ComputeScrollSpeed compute = ComputeScrollSpeed();

  double pxPerSecond(double speed, {double fontSize = 40, double lineHeight = 1.4}) =>
      compute(speed: speed, fontSize: fontSize, lineHeight: lineHeight);

  test('speed 0 still creeps slowly rather than stopping dead', () {
    expect(pxPerSecond(0), greaterThan(0));
  });

  test('is monotonic and capped at the documented maximum', () {
    double previous = -1;
    for (double speed = 0; speed <= 1.0001; speed += 0.05) {
      final double value = pxPerSecond(speed);
      expect(value, greaterThan(previous));
      previous = value;
    }
    final double maxLines = compute.linesPerSecond(1);
    expect(maxLines, closeTo(AppConstants.maxLinesPerSecond, 0.0001));
  });

  test('scales with the rendered line box, so speed feels the same at any size', () {
    final double small = pxPerSecond(0.5, fontSize: 24, lineHeight: 1.3);
    final double large = pxPerSecond(0.5, fontSize: 72, lineHeight: 1.3);
    expect(large / small, closeTo(3, 0.001));
  });

  test('clamps out-of-range input instead of extrapolating', () {
    expect(pxPerSecond(-5), pxPerSecond(TeleprompterSpeedBounds.min));
    expect(pxPerSecond(9), pxPerSecond(TeleprompterSpeedBounds.max));
  });
}
