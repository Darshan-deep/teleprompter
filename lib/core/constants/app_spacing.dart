import 'package:flutter/widgets.dart';

/// Layout tokens — every gap, radius and duration in the app comes from here so
/// spacing stays consistent and there are no magic numbers in widgets.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;
  static const double xxxl = 40;

  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 28;
  static const double radiusPill = 999;

  /// Minimum tap target for anything a reader touches while recording.
  static const double minTapTarget = 48;
  static const double controlHeight = 52;
  static const double hairline = 1;

  /// Maximum content width for tablets / desktop / landscape phones.
  static const double maxContentWidth = 720;

  /// Breakpoint below which the teleprompter switches to its compact layout.
  static const double compactHeightBreakpoint = 460;

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: lg,
  );
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  static const EdgeInsets sheetPadding = EdgeInsets.fromLTRB(
    xl,
    sm,
    xl,
    xl,
  );

  static const Duration instant = Duration(milliseconds: 120);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 280);

  /// How long the teleprompter controls stay on screen without interaction.
  static const Duration controlsAutoHide = Duration(seconds: 4);

  /// Delay after a manual scroll before auto-scroll picks the reading back up.
  static const Duration resumeAfterDrag = Duration(milliseconds: 900);

  /// Debounce for persisting settings while a slider is being dragged.
  static const Duration settingsPersistDebounce = Duration(milliseconds: 400);

  /// Debounce for auto-saving the script editor.
  static const Duration autosaveDebounce = Duration(milliseconds: 900);
}
