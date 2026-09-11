import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/theme/prompt_palette.dart';
import '../../domain/entities/script.dart';
import '../../domain/entities/teleprompter_settings.dart';

/// Session lifecycle of the prompter.
///
/// `initial → loading → ready ⇄ running ⇄ paused → completed`, with `error` for
/// load failures. Every transition is driven by the cubit; the view only
/// renders and forwards intents.
enum TeleprompterStatus {
  initial,
  loading,
  ready,
  running,
  paused,
  completed,
  error,
}

class TeleprompterState extends Equatable {
  const TeleprompterState({
    this.status = TeleprompterStatus.initial,
    this.script,
    this.settings = const TeleprompterSettings(),
    this.failure,
  });

  final TeleprompterStatus status;
  final Script? script;
  final TeleprompterSettings settings;
  final Failure? failure;

  bool get isLoading => status == TeleprompterStatus.loading;

  bool get hasScript => script != null;

  bool get isRunning => status == TeleprompterStatus.running;

  bool get isCompleted => status == TeleprompterStatus.completed;

  String get title => script?.displayTitle ?? '';

  TeleprompterState copyWith({
    TeleprompterStatus? status,
    Script? script,
    TeleprompterSettings? settings,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return TeleprompterState(
      status: status ?? this.status,
      script: script ?? this.script,
      settings: settings ?? this.settings,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  /// Convenience for the settings sheet so widgets stay dumb.
  TeleprompterState withSettings(TeleprompterSettings next) =>
      copyWith(settings: next);

  PromptPalette get palette => settings.palette;

  @override
  List<Object?> get props => <Object?>[status, script, settings, failure];
}
