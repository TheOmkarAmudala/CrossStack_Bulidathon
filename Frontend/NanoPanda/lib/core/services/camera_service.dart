// lib/core/services/camera_service.dart
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class CameraService {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isDisposing = false;

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    // Don't reinitialize if already initialized
    if (_isInitialized && _controller != null) {
      return;
    }

    // Dispose existing controller if any
    if (_controller != null) {
      await dispose();
    }

    _isDisposing = false;

    try {
      // Platform checks for camera plugin support
      if (kIsWeb) {
        // Web: camera_web is used automatically by camera package
        final cameras = await availableCameras();
        if (cameras.isEmpty) {
          throw Exception('No cameras available');
        }
        final frontCamera = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        );
        _controller = CameraController(
          frontCamera,
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );
        await _controller!.initialize();
        if (!_isDisposing) {
          _isInitialized = true;
        }
      } else if (Platform.isAndroid || Platform.isIOS) {
        // Mobile: use camera package
        final cameras = await availableCameras();
        if (cameras.isEmpty) {
          throw Exception('No cameras available');
        }
        final frontCamera = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        );
        _controller = CameraController(
          frontCamera,
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );
        await _controller!.initialize();
        if (!_isDisposing) {
          _isInitialized = true;
        }
      } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        // Desktop: use camera_windows, camera_macos, or camera_linux
        final cameras = await availableCameras();
        if (cameras.isEmpty) {
          throw Exception('No cameras available');
        }
        final frontCamera = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        );
        _controller = CameraController(
          frontCamera,
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );
        await _controller!.initialize();
        if (!_isDisposing) {
          _isInitialized = true;
        }
      } else {
        throw UnsupportedError('Camera not supported on this platform');
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      _isInitialized = false;
      _controller = null;
      rethrow;
    }
  }

  Future<void> dispose() async {
    if (_controller != null && !_isDisposing) {
      _isDisposing = true;
      _isInitialized = false;

      try {
        await _controller!.dispose();
      } catch (e) {
        debugPrint('Error disposing camera: $e');
      } finally {
        _controller = null;
        _isDisposing = false;
      }
    }
  }

  bool get isReady => _isInitialized && _controller != null && _controller!.value.isInitialized;
}