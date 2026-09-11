import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Frame-synced, jitter-free driver for the teleprompter text.
///
/// Why an [AnimationController] instead of a `Timer`:
///
/// * it is driven by the frame pipeline, so the text advances exactly once per
///   rendered frame — identical motion on 60 Hz, 90 Hz and 120 Hz displays and
///   no drift over a long read;
/// * velocity is expressed as a duration for the *whole* range, and Flutter
///   scales it by the distance actually left, so changing speed, resuming after
///   a scrub or rotating the device never produces a jump;
/// * it costs one `jumpTo` per frame and no widget rebuilds, because the offset
///   is pushed straight into the [ScrollPosition];
/// * it stops scheduling frames entirely when paused, so a paused prompter uses
///   no CPU.
///
/// The controller is also a [ValueListenable] of read progress (0…1) that only
/// notifies on meaningful changes, so a progress bar can follow the read
/// without rebuilding the script every frame.
class TextScrollController extends ChangeNotifier implements ValueListenable<double> {
  TextScrollController({required TickerProvider vsync})
      : _driver = AnimationController(
          vsync: vsync,
          duration: const Duration(seconds: 1),
        ) {
    _driver
      ..addListener(_handleTick)
      ..addStatusListener(_handleStatus);
  }

  final AnimationController _driver;

  /// The position controller handed to the script's scrollable.
  final ScrollController scrollController = ScrollController(keepScrollOffset: false);

  /// True while the script is taller than the viewport.
  final ValueNotifier<bool> scrollable = ValueNotifier<bool>(false);

  /// Fired when the last line has travelled past the reading guide.
  void Function()? onCompleted;

  static const double _progressEpsilon = 0.004;
  static const double _endThresholdPx = 1.0;
  static const double _atEndFraction = 0.999;
  static const int _maxPlanMicros = Duration.microsecondsPerDay * 24;

  double _pixelsPerSecond = 0;
  double _lastNotifiedProgress = 0;
  bool _playing = false;

  bool get isPlaying => _playing;

  double get pixelsPerSecond => _pixelsPerSecond;

  /// 0…1 through the script.
  @override
  double get value {
    final double extent = _maxExtent;
    if (extent <= 0) return _driver.value;
    return (scrollController.offset / extent).clamp(0.0, 1.0);
  }

  bool get isScrollable => scrollable.value;

  /// True when there is nothing left to read.
  bool get isAtEnd => !isScrollable || value >= _atEndFraction;

  double get _maxExtent {
    if (!scrollController.hasClients) return 0;
    final ScrollPosition position = scrollController.position;
    if (!position.hasContentDimensions) return 0;
    final double extent = position.maxScrollExtent;
    return extent.isFinite && extent > 0 ? extent : 0;
  }

  /// Updates velocity. Safe to call while playing: the remaining distance is
  /// re-planned from the current position, so the text neither stutters nor
  /// jumps when the speed slider moves.
  void setPixelsPerSecond(double value) {
    final double next = value.isFinite && value > 0 ? value : 0;
    if (next == _pixelsPerSecond) return;
    _pixelsPerSecond = next;
    if (_playing) _plan();
  }

  void play() {
    if (_playing) return;
    _playing = true;
    _plan();
    notifyListeners();
  }

  void pause() {
    if (!_playing) return;
    _playing = false;
    _driver.stop();
    notifyListeners();
  }

  void toggle() => _playing ? pause() : play();

  /// Back to the first line, still playing.
  void restart() {
    _driver.stop();
    if (scrollController.hasClients) {
      scrollController.jumpTo(0);
    }
    _driver.value = 0;
    _lastNotifiedProgress = 0;
    _playing = true;
    _plan();
    notifyListeners();
  }

  /// Moves the text by [pixels] (negative scrolls back).
  void jumpBy(double pixels) {
    final double extent = _maxExtent;
    if (extent <= 0) return;
    final double target = (scrollController.offset + pixels).clamp(0.0, extent);
    scrollController.jumpTo(target);
    _syncDriverToPosition(target, extent);
    _publishProgress(force: true);
  }

  /// Keeps the reader's place in the *script* (not in pixels) when geometry
  /// changes — used after font-size changes and orientation changes.
  void seekToFraction(double fraction) {
    final double extent = _maxExtent;
    if (extent <= 0) return;
    final double clamped = fraction.clamp(0.0, 1.0);
    scrollController.jumpTo(clamped * extent);
    _syncDriverToPosition(clamped * extent, extent);
    _publishProgress(force: true);
  }

  double get currentFraction => value;

  /// The reader grabbed the screen: auto-scroll yields immediately.
  void pauseForInteraction() {
    if (_playing) pause();
  }

  /// Continues from wherever the text is after a drag or resize.
  void resumeAfterInteraction() {
    if (!_playing) return;
    _plan();
  }

  void _syncDriverToPosition(double offset, double extent) {
    _driver.stop();
    _driver.value = extent <= 0 ? 0 : (offset / extent).clamp(0.0, 1.0);
    if (_playing) _plan();
  }

  void _plan() {
    final double extent = _maxExtent;
    _updateScrollable(extent);

    if (extent <= _endThresholdPx) {
      // The whole script fits on screen: nothing to move. Stay in the playing
      // state so the reader is not told they "finished" the instant they start.
      _driver.stop();
      return;
    }
    if (_driver.value >= _atEndFraction) {
      // Already at the end — surface completion instead of silently doing
      // nothing.
      _playing = false;
      _driver.stop();
      notifyListeners();
      onCompleted?.call();
      return;
    }
    if (_pixelsPerSecond <= 0) {
      _driver.stop();
      return;
    }

    final double fullRangeSeconds = extent / _pixelsPerSecond;
    if (!fullRangeSeconds.isFinite || fullRangeSeconds <= 0) return;

    final int micros = math.max(
      1,
      math.min(
        _maxPlanMicros,
        (fullRangeSeconds * Duration.microsecondsPerSecond).round(),
      ),
    );

    // Flutter scales this duration by the fraction of the range still to go.
    _driver
      ..duration = Duration(microseconds: micros)
      ..forward();
  }

  void _handleTick() {
    final double extent = _maxExtent;
    if (extent <= 0) {
      _updateScrollable(0);
      return;
    }
    _updateScrollable(extent);
    scrollController.jumpTo((_driver.value * extent).clamp(0.0, extent));
    _publishProgress();
  }

  void _handleStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (_maxExtent <= _endThresholdPx) return;
    _playing = false;
    _publishProgress(force: true);
    notifyListeners();
    onCompleted?.call();
  }

  void _publishProgress({bool force = false}) {
    final double next = value;
    if (!force && (next - _lastNotifiedProgress).abs() < _progressEpsilon) return;
    _lastNotifiedProgress = next;
    notifyListeners();
  }

  void _updateScrollable(double extent) {
    final bool next = extent > _endThresholdPx;
    if (next != scrollable.value) scrollable.value = next;
  }

  /// Called by the view after layout so the engine can recover if it was asked
  /// to play before the script had been measured.
  void syncLayout() {
    final double extent = _maxExtent;
    _updateScrollable(extent);
    if (_playing && extent > 0 && !_driver.isAnimating) _plan();
  }

  @override
  void dispose() {
    _driver
      ..removeListener(_handleTick)
      ..removeStatusListener(_handleStatus)
      ..stop()
      ..dispose();
    scrollable.dispose();
    scrollController.dispose();
    super.dispose();
  }
}
