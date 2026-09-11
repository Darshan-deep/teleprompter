import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/screen_recording_service.dart';
import 'recording_state.dart';

/// Manages screen recording state and user interactions.
///
/// Handles permission requests, recording lifecycle, and error handling.
class RecordingCubit extends Cubit<RecordingState> {
  RecordingCubit(this._recordingService) : super(const RecordingState.initial());

  final ScreenRecordingService _recordingService;

  /// Initialize recording service and request permissions.
  Future<void> initialize() async {
    try {
      emit(const RecordingState.loading());
      debugPrint('🎬 RecordingCubit: Initializing...');
      final bool success = await _recordingService.initialize();

      if (success) {
        debugPrint('✅ RecordingCubit: Initialization successful');
        emit(const RecordingState.ready());
      } else {
        debugPrint('❌ RecordingCubit: Initialization failed - ${_recordingService.error}');
        emit(RecordingState.error(_recordingService.error ?? 'Failed to initialize recording'));
      }
    } catch (e) {
      debugPrint('❌ RecordingCubit: Exception during initialization - $e');
      emit(RecordingState.error('Initialization error: $e'));
    }
  }

  /// Start screen recording.
  Future<void> startRecording() async {
    if (state is RecordingLoading) return;

    try {
      emit(const RecordingState.loading());
      debugPrint('🎬 RecordingCubit: Starting recording...');
      final bool started = await _recordingService.startRecording();

      if (started) {
        debugPrint('✅ RecordingCubit: Recording started');
        emit(const RecordingState.recording());
      } else {
        debugPrint('❌ RecordingCubit: Failed to start recording - ${_recordingService.error}');
        emit(RecordingState.error(_recordingService.error ?? 'Failed to start recording'));
      }
    } catch (e) {
      debugPrint('❌ RecordingCubit: Exception during start - $e');
      emit(RecordingState.error('Error starting recording: $e'));
    }
  }

  /// Stop screen recording and get the file path.
  Future<String?> stopRecording() async {
    if (state is! RecordingRecording) {
      debugPrint('❌ RecordingCubit: No recording in progress');
      emit(RecordingState.error('No recording in progress'));
      return null;
    }

    try {
      emit(const RecordingState.loading());
      debugPrint('🎬 RecordingCubit: Stopping recording...');
      final String? path = await _recordingService.stopRecording();

      if (path != null) {
        debugPrint('✅ RecordingCubit: Recording stopped, saved to $path');
        emit(RecordingState.completed(path));
        return path;
      } else {
        debugPrint('❌ RecordingCubit: Failed to stop recording - ${_recordingService.error}');
        emit(RecordingState.error(_recordingService.error ?? 'Failed to stop recording'));
        return null;
      }
    } catch (e) {
      debugPrint('❌ RecordingCubit: Exception during stop - $e');
      emit(RecordingState.error('Error stopping recording: $e'));
      return null;
    }
  }

  /// Toggle recording on/off.
  Future<void> toggleRecording() async {
    if (state is RecordingRecording) {
      await stopRecording();
    } else if (state is RecordingReady || state is RecordingCompleted) {
      await startRecording();
    }
  }

  /// Clear error message.
  void clearError() {
    if (state is RecordingError) {
      emit(const RecordingState.ready());
    }
  }

  /// Reset to ready state after successful recording.
  void reset() {
    emit(const RecordingState.ready());
  }

  @override
  Future<void> close() async {
    _recordingService.dispose();
    await super.close();
  }
}
