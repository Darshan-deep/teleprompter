import '../../../../core/constants/app_constants.dart';

/// Converts the user's 0…1 speed setting into a pixel-per-second scroll rate.
///
/// The mapping is non-linear on purpose:
///
/// * below 50% it acts almost like a fine adjustment (0.04 → 0.5 lines/second),
///   because the hardest part of reading on camera is going *slow* enough;
/// * above 50% it ramps up steeply so fast talkers still have headroom;
/// * the result is expressed in lines per second and then scaled by the line
///   height actually rendered, so the same speed setting feels identical at
///   20 pt and at 100 pt, and on any screen size.
class ComputeScrollSpeed {
  const ComputeScrollSpeed();

  /// Pixels per second for a given settings/glyph geometry.
  double call({
    required double speed,
    required double fontSize,
    required double lineHeight,
  }) {
    final double normalized = speed.clamp(
      TeleprompterSpeedBounds.min,
      TeleprompterSpeedBounds.max,
    );
    final double linesPerSecond = _linesPerSecond(normalized);
    final double lineBox = fontSize * lineHeight;
    return linesPerSecond * lineBox;
  }

  /// Exposed separately so the UI can show "≈ 18 lines / min".
  double linesPerSecond(double speed) =>
      _linesPerSecond(speed.clamp(TeleprompterSpeedBounds.min, TeleprompterSpeedBounds.max));

  double _linesPerSecond(double normalized) {
    final double curved = normalized * normalized;
    return AppConstants.minLinesPerSecond +
        curved * (AppConstants.maxLinesPerSecond - AppConstants.minLinesPerSecond);
  }
}

/// Bounds for the 0…1 speed setting, kept in the domain so both the model and
/// the engine agree.
abstract final class TeleprompterSpeedBounds {
  static const double min = 0;
  static const double max = 1;

  /// Step applied by the −/+ buttons and keyboard shortcuts.
  static const double step = 0.05;

  /// Speed a session starts at when the stored value is invalid.
  static const double fallback = 0.9;
}
