import 'package:flutter/material.dart' show TextAlign;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/theme/script_typography.dart';
import '../../domain/entities/script.dart';
import '../../domain/entities/teleprompter_settings.dart';
import '../../domain/usecases/compute_scroll_speed.dart';
import '../../domain/usecases/script_usecases.dart';
import 'teleprompter_state.dart';

/// Owns a single prompter session.
///
/// Deliberately does **not** hold the scroll offset: that is per-frame rendering
/// state owned by the scrolling engine, and pushing it through a Bloc would
/// rebuild the widget tree on every frame. The engine reports back only at
/// meaningful moments (end reached, manual scrub).
class TeleprompterCubit extends Cubit<TeleprompterState> {
  TeleprompterCubit({
    required GetScript getScript,
    required TeleprompterSettings defaults,
  })  : _getScript = getScript,
        _defaults = defaults,
        super(TeleprompterState(settings: defaults));

  final GetScript _getScript;

  /// App-wide defaults the session starts from.
  final TeleprompterSettings _defaults;

  int _loadToken = 0;

  TeleprompterSettings get defaults => _defaults;

  /// Loads the script and prepares a ready-to-read session.
  Future<void> load(String scriptId) async {
    final int token = ++_loadToken;
    emit(
      state.copyWith(
        status: TeleprompterStatus.loading,
        settings: _defaults,
        clearFailure: true,
      ),
    );

    final Result<Script?> result = await _getScript(scriptId);
    if (isClosed || token != _loadToken) return;

    switch (result) {
      case Ok<Script?>(:final value):
        if (value == null) {
          emit(
            state.copyWith(
              status: TeleprompterStatus.error,
              failure: Failure.scriptNotFound,
            ),
          );
          return;
        }
        emit(
          state.copyWith(
            status: TeleprompterStatus.ready,
            script: value,
            settings: _defaults,
            clearFailure: true,
          ),
        );
      case Err<Script?>(:final failure):
        emit(state.copyWith(status: TeleprompterStatus.error, failure: failure));
    }
  }

  Future<void> retry(String scriptId) => load(scriptId);

  // ---------------------------------------------------------------- playback

  /// Starts or resumes. No-op when the script is empty or failed to load.
  void play() {
    if (!_canAdvance) return;
    emit(state.copyWith(status: TeleprompterStatus.running, clearFailure: true));
  }

  /// Pauses at the current position (resume continues from here).
  void pause() {
    if (state.status != TeleprompterStatus.running) return;
    emit(state.copyWith(status: TeleprompterStatus.paused));
  }

  void togglePlayback() {
    if (state.isRunning) {
      pause();
    } else {
      play();
    }
  }

  /// Returns to the top and starts again.
  void restart() {
    if (!_canAdvance) return;
    emit(state.copyWith(status: TeleprompterStatus.running, clearFailure: true));
  }

  /// Ends playback but keeps the session and the position — used when leaving
  /// the prompter, so the scrolling engine stops before the route animates out
  /// instead of being torn down mid-frame.
  void stop() {
    if (state.status == TeleprompterStatus.ready) return;
    emit(state.copyWith(status: TeleprompterStatus.ready));
  }

  /// Called by the scrolling engine when the last line has passed the guide.
  void complete() {
    if (state.status == TeleprompterStatus.completed) return;
    emit(state.copyWith(status: TeleprompterStatus.completed));
  }

  bool get _canAdvance {
    final Script? script = state.script;
    return state.status != TeleprompterStatus.error &&
        script != null &&
        !script.isEmpty;
  }

  // ---------------------------------------------------------------- controls

  void setSpeed(double speed) {
    final double next = speed.clamp(
      TeleprompterSettings.minSpeed,
      TeleprompterSettings.maxSpeed,
    );
    if (next == state.settings.speed) return;
    emit(state.withSettings(state.settings.copyWith(speed: next)));
  }

  /// ± step nudge used by the −/+ buttons and the arrow keys.
  void adjustSpeed(double delta) => setSpeed(state.settings.speed + delta);

  void setFontSize(double fontSize) {
    final TeleprompterSettings next = state.settings.copyWith(fontSize: fontSize);
    if (next.fontSize == state.settings.fontSize) return;
    emit(state.withSettings(next));
  }

  void adjustFontSize(double delta) => setFontSize(state.settings.fontSize + delta);

  void setAlignment(TextAlign alignment) =>
      emit(state.withSettings(state.settings.copyWith(alignment: alignment)));

  void setTheme(String themeId) {
    if (themeId == state.settings.themeId) return;
    emit(state.withSettings(state.settings.copyWith(themeId: themeId)));
  }

  void toggleMirror() =>
      emit(state.withSettings(state.settings.copyWith(mirrored: !state.settings.mirrored)));

  void toggleReadingGuide() => emit(
        state.withSettings(
          state.settings.copyWith(showReadingGuide: !state.settings.showReadingGuide),
        ),
      );

  /// Applies a whole settings object (used by "reset to defaults" and by the
  /// editor's live preview handoff).
  void applySettings(TeleprompterSettings settings) =>
      emit(state.withSettings(settings));

  /// Replaces session settings with the persisted defaults.
  void resetToDefaults() => emit(state.withSettings(_defaults));
}

/// Convenience for widgets that need the pixel rate for the current settings.
extension TeleprompterStateScrollMath on TeleprompterState {
  double pixelsPerSecond() => const ComputeScrollSpeed().call(
        speed: settings.speed,
        fontSize: settings.fontSize,
        lineHeight: settings.lineHeight,
      );

}

/// Re-exported so pages can clamp user input without importing the domain.
abstract final class PrompterBounds {
  static const double minFontSize = ScriptTypography.minFontSize;
  static const double maxFontSize = ScriptTypography.maxFontSize;
  static const double minLineHeight = ScriptTypography.minPrompterLineHeight;
  static const double maxLineHeight = ScriptTypography.maxPrompterLineHeight;
  static const double minParagraphSpacing = ScriptTypography.minParagraphSpacing;
  static const double maxParagraphSpacing = ScriptTypography.maxParagraphSpacing;
}
