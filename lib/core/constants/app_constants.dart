/// Non-visual, app-wide constants.
///
/// Visual tokens live in `core/constants/app_spacing.dart` and `core/theme/`.
abstract final class AppConstants {
  static const String appName = 'Teleprompter';
  static const String appTagline = 'Read confidently, on camera.';
  static const String appVersion = '1.0.0';

  /// Fallback title used when a script is saved without a name.
  static const String untitledScriptTitle = 'Untitled script';
  static const int maxTitleLength = 80;

  /// Average out-loud reading pace, used only for duration estimates.
  static const int wordsPerMinute = 150;

  /// Safety valve so a corrupted/duplicated store can never blow up memory.
  static const int maxStoredScripts = 1000;

  /// Preview length shown on the home screen cards.
  static const int cardPreviewLength = 140;

  /// The teleprompter scrolls at most this many text lines per second when the
  /// speed control is at 100%. Slow, controllable speeds are the priority, so
  /// the curve is deliberately generous at the low end.
  static const double maxLinesPerSecond = 1.35;

  /// Below this value the speed slider is effectively "creeping" speed.
  static const double minLinesPerSecond = 0.04;
}
