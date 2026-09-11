import 'package:equatable/equatable.dart';

/// Recording state for the teleprompter recording feature.
sealed class RecordingState extends Equatable {
  const RecordingState();

  const factory RecordingState.initial() = RecordingInitial;
  const factory RecordingState.loading() = RecordingLoading;
  const factory RecordingState.ready() = RecordingReady;
  const factory RecordingState.recording() = RecordingRecording;
  const factory RecordingState.completed(String recordingPath) = RecordingCompleted;
  const factory RecordingState.error(String message) = RecordingError;

  bool get isRecording => this is RecordingRecording;
  bool get isLoading => this is RecordingLoading;
  bool get isError => this is RecordingError;
  bool get isReady => this is RecordingReady || this is RecordingCompleted;

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state before any action.
class RecordingInitial extends RecordingState {
  const RecordingInitial();
}

/// Loading state during permission requests or recording start/stop.
class RecordingLoading extends RecordingState {
  const RecordingLoading();
}

/// Ready state when recording service is initialized and ready to record.
class RecordingReady extends RecordingState {
  const RecordingReady();
}

/// Recording state when actively recording.
class RecordingRecording extends RecordingState {
  const RecordingRecording();
}

/// Completed state after successful recording.
class RecordingCompleted extends RecordingState {
  const RecordingCompleted(this.recordingPath);

  final String recordingPath;

  @override
  List<Object?> get props => <Object?>[recordingPath];
}

/// Error state with error message.
class RecordingError extends RecordingState {
  const RecordingError(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}
