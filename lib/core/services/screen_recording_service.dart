import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service to manage screen recording with high quality video capture.
///
/// Uses the camera plugin to record front-facing camera video with audio.
class ScreenRecordingService extends ChangeNotifier {
  CameraController? _cameraController;
  bool _isRecording = false;
  bool _isInitialized = false;
  String? _lastRecordingPath;
  String? _error;

  bool get isRecording => _isRecording;
  bool get isInitialized => _isInitialized;
  String? get lastRecordingPath => _lastRecordingPath;
  String? get error => _error;

  /// Initialize the recording service and request necessary permissions.
  Future<bool> initialize() async {
    if (_isInitialized) {
      debugPrint('📹 Recording service already initialized');
      return true;
    }

    try {
      debugPrint('📹 Initializing recording service...');
      // Request necessary permissions
      final PermissionStatus status = await _requestPermissions();
      debugPrint('📹 Permission status: $status');

      if (status.isDenied) {
        _error = 'Camera or microphone permission denied';
        debugPrint('❌ $_error');
        notifyListeners();
        return false;
      }

      // Get available cameras
      final cameras = await availableCameras();
      debugPrint('📹 Available cameras: ${cameras.length}');
      if (cameras.isEmpty) {
        _error = 'No camera available on this device';
        debugPrint('❌ $_error');
        notifyListeners();
        return false;
      }

      // Use front camera if available (for selfie-style recording), otherwise back camera
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      debugPrint('📹 Using camera: ${camera.name} (${camera.lensDirection})');

      // Initialize camera controller with front camera
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      debugPrint('📹 Camera controller initialized');

      _isInitialized = true;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to initialize recording: $e';
      debugPrint('❌ $_error');
      notifyListeners();
      return false;
    }
  }

  /// Request necessary permissions for screen recording.
  Future<PermissionStatus> _requestPermissions() async {
    // Request camera permission
    final PermissionStatus cameraStatus = await Permission.camera.request();
    if (cameraStatus.isDenied) {
      return PermissionStatus.denied;
    }

    // Request microphone permission
    final PermissionStatus micStatus = await Permission.microphone.request();
    if (micStatus.isDenied) {
      return PermissionStatus.denied;
    }

    // Request storage permission for saving videos
    if (Platform.isAndroid) {
      await Permission.storage.request();
    }

    return PermissionStatus.granted;
  }

  /// Start recording video from the camera.
  ///
  /// Returns true if recording started successfully, false otherwise.
  Future<bool> startRecording({String? customName}) async {
    if (_isRecording) {
      _error = 'Recording is already in progress';
      debugPrint('❌ $_error');
      notifyListeners();
      return false;
    }

    if (!_isInitialized) {
      debugPrint('📹 Service not initialized, initializing now...');
      final bool initialized = await initialize();
      if (!initialized) return false;
    }

    try {
      if (_cameraController == null || !_cameraController!.value.isInitialized) {
        _error = 'Camera not initialized';
        debugPrint('❌ $_error');
        notifyListeners();
        return false;
      }

      debugPrint('📹 Starting video recording...');
      await _cameraController!.startVideoRecording();
      debugPrint('✅ Video recording started successfully');
      
      _isRecording = true;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error starting recording: $e';
      debugPrint('❌ $_error');
      notifyListeners();
      return false;
    }
  }

  /// Stop the current recording and save the video file.
  ///
  /// Returns the path to the saved video file, or null if recording failed.
  Future<String?> stopRecording() async {
    if (!_isRecording) {
      _error = 'No recording in progress';
      debugPrint('❌ $_error');
      notifyListeners();
      return null;
    }

    try {
      if (_cameraController == null) {
        _error = 'Camera controller is not available';
        debugPrint('❌ $_error');
        notifyListeners();
        return null;
      }

      debugPrint('📹 Stopping video recording...');
      final XFile video = await _cameraController!.stopVideoRecording();
      _isRecording = false;
      _lastRecordingPath = video.path;
      _error = null;
      debugPrint('✅ Video recording stopped. Saved to: $_lastRecordingPath');
      notifyListeners();
      return video.path;
    } catch (e) {
      _error = 'Error stopping recording: $e';
      debugPrint('❌ $_error');
      _isRecording = false;
      notifyListeners();
      return null;
    }
  }

  /// Get the file size of the last recording in MB.
  Future<double?> getLastRecordingFileSize() async {
    if (_lastRecordingPath == null) return null;

    try {
      final File file = File(_lastRecordingPath!);
      if (await file.exists()) {
        final int bytes = await file.length();
        return bytes / (1024 * 1024); // Convert to MB
      }
    } catch (e) {
      _error = 'Error getting file size: $e';
      notifyListeners();
    }
    return null;
  }

  /// Delete a recording file.
  Future<bool> deleteRecording(String filePath) async {
    try {
      final File file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        if (_lastRecordingPath == filePath) {
          _lastRecordingPath = null;
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Error deleting recording: $e';
      notifyListeners();
      return false;
    }
  }

  /// Clear the last recording path reference.
  void clearLastRecording() {
    _lastRecordingPath = null;
    notifyListeners();
  }

  /// Clear any error message.
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }
}
