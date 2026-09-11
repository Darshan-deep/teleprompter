import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service to manage screen recording with high quality video capture.
///
/// Uses the camera plugin to record front-facing camera video with audio.
/// Videos are saved to the device's Pictures directory for gallery access.
class ScreenRecordingService extends ChangeNotifier {
  static const platform = MethodChannel('com.teleprompter.app/gallery');
  
  CameraController? _cameraController;
  bool _isRecording = false;
  bool _isInitialized = false;
  String? _lastRecordingPath;
  String? _nextOutputPath;
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
    debugPrint('📹 Camera permission: $cameraStatus');
    if (cameraStatus.isDenied) {
      return PermissionStatus.denied;
    }

    // Request microphone permission
    final PermissionStatus micStatus = await Permission.microphone.request();
    debugPrint('🎤 Microphone permission: $micStatus');
    if (micStatus.isDenied) {
      return PermissionStatus.denied;
    }

    // Request storage permissions for saving videos
    if (Platform.isAndroid) {
      // On Android 13+, we need READ/WRITE_EXTERNAL_STORAGE AND MANAGE_EXTERNAL_STORAGE
      final PermissionStatus writeStatus = await Permission.storage.request();
      debugPrint('💾 Storage (write) permission: $writeStatus');
      
      // Also request manage external storage on Android 12+
      final PermissionStatus manageStatus = await Permission.manageExternalStorage.request();
      debugPrint('💾 Manage external storage permission: $manageStatus');
      
      if (writeStatus.isDenied || manageStatus.isDenied) {
        debugPrint('⚠️ Storage permissions denied');
        // Don't return denied - continue anyway, some devices may not require this
      }
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

      // Create output directory and get path BEFORE starting recording
      _nextOutputPath = await _getOutputPath();
      debugPrint('📍 Video will be saved to: $_nextOutputPath');

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

  /// Get the output path for the video file (public storage).
  Future<String> _getOutputPath() async {
    if (Platform.isAndroid) {
      try {
        // Use native Android method to get proper public storage path
        final String videoDir = await platform.invokeMethod('getVideosDirectory') as String;
        final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        final String filename = 'teleprompter_$timestamp.mp4';
        final String finalPath = '$videoDir/$filename';
        debugPrint('📍 Output path: $finalPath');
        return finalPath;
      } catch (e) {
        debugPrint('⚠️ Failed to get videos directory: $e');
        // Fallback to environment variable
        final String externalStoragePath = Platform.environment['EXTERNAL_STORAGE'] ?? '/storage/emulated/0';
        final String moviesPath = '$externalStoragePath/Movies/Teleprompter';
        final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        final String filename = 'teleprompter_$timestamp.mp4';
        return '$moviesPath/$filename';
      }
    } else if (Platform.isIOS) {
      // For iOS, use Documents/Videos/
      final Directory docDir = await getApplicationDocumentsDirectory();
      final Directory videosDir = Directory('${docDir.path}/Videos');
      if (!await videosDir.exists()) {
        try {
          await videosDir.create(recursive: true);
        } catch (e) {
          debugPrint('⚠️ Failed to create iOS videos directory: $e');
        }
      }

      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String filename = 'teleprompter_$timestamp.mp4';
      final String finalPath = '${videosDir.path}/$filename';
      
      return finalPath;
    }

    // Fallback to temp directory
    final Directory tempDir = await getTemporaryDirectory();
    return '${tempDir.path}/teleprompter_${DateTime.now().millisecondsSinceEpoch}.mp4';
  }

  /// Stop the current recording and save the video file.
  ///
  /// Returns the path to the saved video file, or null if recording failed.
  /// Video is moved from cache to public storage for gallery access.
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
      debugPrint('📹 Raw video path from camera: ${video.path}');
      
      // Move the camera output into the shared gallery collection.
      final String finalPath = await _moveVideoToPublicStorage(video.path);
      
      _isRecording = false;
      _lastRecordingPath = finalPath;
      _error = null;
      debugPrint('✅ Video recording stopped. Saved to: $_lastRecordingPath');
      
      // Verify file and trigger media scan
      try {
        final File savedFile = File(finalPath);
        final bool exists = await savedFile.exists();
        debugPrint('📂 File exists: $exists');
        if (exists) {
          final int bytes = await savedFile.length();
          debugPrint('📊 File size: ${bytes ~/ (1024 * 1024)} MB');
          
          // Trigger media scan on Android to refresh gallery
          if (Platform.isAndroid && !finalPath.startsWith('content://')) {
            try {
              await platform.invokeMethod('scanMediaFile', {'path': finalPath});
              debugPrint('✅ Media scan triggered');
            } catch (e) {
              debugPrint('⚠️ Media scan error: $e');
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error verifying file: $e');
      }
      
      notifyListeners();
      return finalPath;
    } catch (e) {
      _error = 'Error stopping recording: $e';
      debugPrint('❌ $_error');
      _isRecording = false;
      notifyListeners();
      return null;
    }
  }

  /// Move video from cache to public storage directory.
  Future<String> _moveVideoToPublicStorage(String cachePath) async {
    try {
      if (Platform.isAndroid) {
        String videoDir;
        
        try {
          final String galleryUri = await platform.invokeMethod<String>(
            'saveVideoToGallery',
            <String, String>{'path': cachePath},
          ) ?? '';
          if (galleryUri.isNotEmpty) {
            debugPrint('✅ Video saved to gallery: $galleryUri');
            return galleryUri;
          }
          throw StateError('Android gallery returned an empty URI');
        } catch (e) {
          debugPrint('⚠️ Native gallery save failed: $e. Using fallback path.');
          // Fallback: construct the path directly
          // /storage/emulated/0/Movies/Teleprompter
          videoDir = '/storage/emulated/0/Movies/Teleprompter';
          
          // Create directory if it doesn't exist
          final Directory dir = Directory(videoDir);
          try {
            if (!await dir.exists()) {
              await dir.create(recursive: true);
              debugPrint('📁 Created fallback directory: $videoDir');
            }
          } catch (dirError) {
            debugPrint('❌ Failed to create directory: $dirError');
          }
        }

        final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        final String filename = 'teleprompter_$timestamp.mp4';
        final String finalPath = '$videoDir/$filename';

        debugPrint('📹 Moving video from: $cachePath');
        debugPrint('📹 Moving video to: $finalPath');

        final File cacheFile = File(cachePath);
        final bool cacheExists = await cacheFile.exists();
        debugPrint('📂 Cache file exists: $cacheExists');
        
        if (cacheExists) {
          try {
            final File movedFile = await cacheFile.rename(finalPath);
            debugPrint('✅ Video moved successfully to: ${movedFile.path}');
            
            // Verify the file was actually moved
            final bool finalExists = await movedFile.exists();
            debugPrint('✅ Final file exists: $finalExists');
            
            if (finalExists) {
              final int sizeBytes = await movedFile.length();
              debugPrint('✅ Final file size: ${sizeBytes ~/ (1024 * 1024)} MB');
            }
            
            return movedFile.path;
          } catch (moveError) {
            debugPrint('❌ Failed to rename file: $moveError');
            return cachePath;
          }
        } else {
          debugPrint('⚠️ Cache file not found: $cachePath');
          return cachePath;
        }
      } else if (Platform.isIOS) {
        // For iOS, move to Documents/Videos/
        final Directory docDir = await getApplicationDocumentsDirectory();
        final Directory videosDir = Directory('${docDir.path}/Videos');
        if (!await videosDir.exists()) {
          await videosDir.create(recursive: true);
        }

        final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        final String filename = 'teleprompter_$timestamp.mp4';
        final String finalPath = '${videosDir.path}/$filename';

        final File cacheFile = File(cachePath);
        if (await cacheFile.exists()) {
          final File movedFile = await cacheFile.rename(finalPath);
          debugPrint('✅ Video moved to iOS Documents');
          return movedFile.path;
        }
        return cachePath;
      }

      return cachePath;
    } catch (e) {
      debugPrint('❌ Unexpected error in _moveVideoToPublicStorage: $e');
      return cachePath;
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
