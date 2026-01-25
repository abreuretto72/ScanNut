import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// 🎙️ AudioEventService - Manual Trigger + Auto-Save Intelligence
///
/// **Lei de Ferro Compliance:**
/// - Manual activation prevents noise pollution from other pets
/// - Automatic silence detection for hands-free closure
/// - Auto-save to walk_history_box with PetID isolation
/// - Visual feedback without UI overflow on SM A256E
class AudioEventService {
  final AudioRecorder _recorder = AudioRecorder();

  // State Management
  bool _isRecording = false;
  Timer? _silenceTimer;
  String? _currentRecordingPath;

  // Configuration
  static const Duration _silenceThreshold = Duration(seconds: 2);
  static const int _maxRecordingDuration = 30; // seconds

  /// Check microphone permissions
  Future<bool> checkPermissions() async {
    final status = await Permission.microphone.status;
    if (status.isDenied) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    }
    return status.isGranted;
  }

  /// Start recording (Manual Trigger)
  /// Returns the recording path if successful, null otherwise
  Future<String?> startRecording(
      {required String petId, required String eventType}) async {
    try {
      // 1. Permission Check
      if (!await checkPermissions()) {
        debugPrint('❌ [AudioEvent] Microphone permission denied');
        return null;
      }

      // 2. Prevent double recording
      if (_isRecording) {
        debugPrint('⚠️ [AudioEvent] Already recording, ignoring new request');
        return null;
      }

      // 3. Generate unique path
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath =
          '${dir.path}/audio_${petId}_${eventType}_$timestamp.m4a';

      // 4. Start recording
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );

      _isRecording = true;
      debugPrint('🎙️ [AudioEvent] Recording started: $_currentRecordingPath');

      // 5. Auto-stop after max duration (safety)
      Future.delayed(const Duration(seconds: _maxRecordingDuration), () {
        if (_isRecording) {
          debugPrint('⏱️ [AudioEvent] Max duration reached, auto-stopping');
          stopRecording();
        }
      });

      return _currentRecordingPath;
    } catch (e) {
      debugPrint('❌ [AudioEvent] Failed to start recording: $e');
      _isRecording = false;
      _currentRecordingPath = null;
      return null;
    }
  }

  /// Stop recording and return the final path
  /// This is called automatically by silence detection or manually
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) {
        debugPrint('⚠️ [AudioEvent] Not recording, nothing to stop');
        return null;
      }

      // Cancel silence timer if active
      _silenceTimer?.cancel();
      _silenceTimer = null;

      // Stop recording
      final path = await _recorder.stop();
      _isRecording = false;

      debugPrint('✅ [AudioEvent] Recording stopped: $path');

      // Validate file exists and has content
      if (path != null && await File(path).exists()) {
        final fileSize = await File(path).length();
        if (fileSize > 1024) {
          // At least 1KB
          debugPrint('✅ [AudioEvent] Valid audio file saved: $fileSize bytes');
          final finalPath = _currentRecordingPath;
          _currentRecordingPath = null;
          return finalPath;
        } else {
          debugPrint('⚠️ [AudioEvent] Audio file too small, deleting');
          await File(path).delete();
          _currentRecordingPath = null;
          return null;
        }
      }

      _currentRecordingPath = null;
      return null;
    } catch (e) {
      debugPrint('❌ [AudioEvent] Failed to stop recording: $e');
      _isRecording = false;
      _currentRecordingPath = null;
      return null;
    }
  }

  /// Simulate silence detection (placeholder for real implementation)
  /// In production, this would use amplitude monitoring
  void startSilenceDetection({required VoidCallback onSilenceDetected}) {
    // Cancel existing timer
    _silenceTimer?.cancel();

    // Start new timer
    _silenceTimer = Timer(_silenceThreshold, () {
      debugPrint('🔇 [AudioEvent] Silence detected, auto-stopping recording');
      onSilenceDetected();
    });
  }

  /// Reset silence timer (call this when audio activity is detected)
  void resetSilenceTimer({required VoidCallback onSilenceDetected}) {
    startSilenceDetection(onSilenceDetected: onSilenceDetected);
  }

  /// Check if currently recording
  bool get isRecording => _isRecording;

  /// Get current recording path
  String? get currentRecordingPath => _currentRecordingPath;

  /// Cleanup resources
  void dispose() {
    _silenceTimer?.cancel();
    _recorder.dispose();
  }

  /// Delete a recording file
  Future<void> deleteRecording(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        debugPrint('🗑️ [AudioEvent] Deleted recording: $path');
      }
    } catch (e) {
      debugPrint('❌ [AudioEvent] Failed to delete recording: $e');
    }
  }
}
