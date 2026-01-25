import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';

import '../models/walk_models.dart';
import 'audio_event_service.dart';

/// 🎯 MultimodalEventController - Unified Triple Input System
///
/// **Lei de Ferro Compliance:**
/// - Each of the 6 icons (Xixi, Fezes, Água, Amigo, Latido, Perigo) can capture:
///   1. Photo (Visual Evidence)
///   2. Voice Note (Transcribed to Text)
///   3. Sound Analysis (Emotional AI Processing)
/// - Manual activation, automatic save on completion
/// - Domain isolation per PetID
/// - Zero overflow on SM A256E
class MultimodalEventController {
  final AudioEventService _audioService = AudioEventService();
  final ImagePicker _imagePicker = ImagePicker();

  // Current event being processed
  WalkEventType? _currentEventType;
  String? _currentPhotoPath;
  String? _currentAudioPath;
  String? _currentTranscription;
  Position? _currentPosition;

  // State tracking
  bool _isCapturingPhoto = false;
  bool _isRecordingAudio = false;

  /// 📸 Capture Photo for Event
  /// Returns the photo path if successful
  Future<String?> capturePhoto({
    required WalkEventType eventType,
    required String petId,
    Position? position,
  }) async {
    try {
      if (_isCapturingPhoto) {
        debugPrint('⚠️ [MultimodalEvent] Already capturing photo');
        return null;
      }

      _isCapturingPhoto = true;
      _currentEventType = eventType;
      _currentPosition = position;

      // Open camera
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo == null) {
        _isCapturingPhoto = false;
        return null;
      }

      // Save to permanent location
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final eventName = eventType.toString().split('.').last;
      final permanentPath =
          '${dir.path}/photo_${petId}_${eventName}_$timestamp.jpg';

      await File(photo.path).copy(permanentPath);

      _currentPhotoPath = permanentPath;
      _isCapturingPhoto = false;

      debugPrint('📸 [MultimodalEvent] Photo captured: $permanentPath');
      return permanentPath;
    } catch (e) {
      debugPrint('❌ [MultimodalEvent] Photo capture failed: $e');
      _isCapturingPhoto = false;
      return null;
    }
  }

  /// 🎙️ Start Voice Recording for Event
  /// Returns true if recording started successfully
  Future<bool> startVoiceRecording({
    required WalkEventType eventType,
    required String petId,
    Position? position,
  }) async {
    try {
      if (_isRecordingAudio) {
        debugPrint('⚠️ [MultimodalEvent] Already recording audio');
        return false;
      }

      _currentEventType = eventType;
      _currentPosition = position;

      final eventName = eventType.toString().split('.').last;
      final path = await _audioService.startRecording(
        petId: petId,
        eventType: eventName,
      );

      if (path != null) {
        _isRecordingAudio = true;
        _currentAudioPath = path;
        debugPrint('🎙️ [MultimodalEvent] Voice recording started: $path');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ [MultimodalEvent] Voice recording failed: $e');
      return false;
    }
  }

  /// 🔇 Stop Voice Recording (Auto-Save on Silence)
  /// Returns the audio path and optional transcription
  Future<Map<String, String?>> stopVoiceRecording() async {
    try {
      if (!_isRecordingAudio) {
        return {'audioPath': null, 'transcription': null};
      }

      final path = await _audioService.stopRecording();
      _isRecordingAudio = false;

      if (path != null) {
        // TODO: Integrate Speech-to-Text service here
        // For now, return a placeholder transcription
        _currentTranscription = 'Transcrição pendente (IA)';

        debugPrint('🔇 [MultimodalEvent] Voice recording stopped: $path');
        return {
          'audioPath': path,
          'transcription': _currentTranscription,
        };
      }

      return {'audioPath': null, 'transcription': null};
    } catch (e) {
      debugPrint('❌ [MultimodalEvent] Stop recording failed: $e');
      _isRecordingAudio = false;
      return {'audioPath': null, 'transcription': null};
    }
  }

  /// 🔊 Capture Ambient Sound for Analysis
  /// Used for bark/growl emotional analysis
  Future<String?> captureAmbientSound({
    required WalkEventType eventType,
    required String petId,
    Position? position,
    int durationSeconds = 5,
  }) async {
    try {
      _currentEventType = eventType;
      _currentPosition = position;

      final eventName = eventType.toString().split('.').last;
      final path = await _audioService.startRecording(
        petId: petId,
        eventType: '${eventName}_ambient',
      );

      if (path != null) {
        // Auto-stop after duration
        await Future.delayed(Duration(seconds: durationSeconds));
        final finalPath = await _audioService.stopRecording();

        debugPrint('🔊 [MultimodalEvent] Ambient sound captured: $finalPath');
        return finalPath;
      }

      return null;
    } catch (e) {
      debugPrint('❌ [MultimodalEvent] Ambient sound capture failed: $e');
      return null;
    }
  }

  /// 💾 Build Complete WalkEvent with All Data
  /// Combines photo, audio, transcription, and GPS into a single event
  WalkEvent buildCompleteEvent({
    required WalkEventType eventType,
    String? photoPath,
    String? audioPath,
    String? transcription,
    String? description,
    int? bristolScore,
    Map<String, String>? metadata, // For Amigo/Fight details
    Position? position,
  }) {
    // Combine all descriptions
    final descriptionParts = <String>[];

    if (description != null) descriptionParts.add(description);
    if (transcription != null) descriptionParts.add('🎙️ $transcription');
    if (bristolScore != null) descriptionParts.add('Bristol: $bristolScore');

    // Add metadata if present (Friend/Fight details)
    if (metadata != null) {
      metadata.forEach((key, value) {
        descriptionParts.add('$key: $value');
      });
    }

    final fullDescription = descriptionParts.join(' • ');

    return WalkEvent(
      timestamp: DateTime.now(),
      type: eventType,
      description: fullDescription.isNotEmpty ? fullDescription : null,
      photoPath: photoPath ?? _currentPhotoPath,
      audioPath: audioPath ?? _currentAudioPath,
      bristolScore: bristolScore,
      lat: position?.latitude ?? _currentPosition?.latitude,
      lng: position?.longitude ?? _currentPosition?.longitude,
    );
  }

  /// 💩 AI Stool Analysis
  Future<String> analyzeStool(String photoPath) async {
    // Mocking AI processing delay
    await Future.delayed(const Duration(seconds: 2));

    // Randomized mock result
    final results = [
      "Bristol 3 (Normal) • Sem parasitas visíveis. ✅",
      "Bristol 2 (Ressecado) • Sugestão: Aumentar hidratação. 💧",
      "Bristol 5 (Pastoso) • Observar próxima evacuação. ⚠️",
      "Bristol 4 (Ideal) • Digestão excelente! ✨",
    ];
    return results[DateTime.now().second % results.length];
  }

  /// 🗣️ AI Emotional Analysis (Voice/Sound)
  Future<String> analyzeEmotion(String audioPath) async {
    // Mocking AI processing delay
    await Future.delayed(const Duration(seconds: 1));

    final emotions = [
      "Alerta/Curioso 🐕",
      "Feliz/Brincalhão 🎾",
      "Assustado/Inseguro 😨",
      "Agressivo/Territorial ❗",
    ];
    return emotions[DateTime.now().second % emotions.length];
  }

  /// 🧹 Clear Current Event Data
  void clearCurrentEvent() {
    _currentEventType = null;
    _currentPhotoPath = null;
    _currentAudioPath = null;
    _currentTranscription = null;
    _currentPosition = null;
  }

  /// 📊 Get Current Event State
  Map<String, dynamic> getCurrentEventState() {
    return {
      'eventType': _currentEventType?.toString(),
      'hasPhoto': _currentPhotoPath != null,
      'hasAudio': _currentAudioPath != null,
      'hasTranscription': _currentTranscription != null,
      'hasGPS': _currentPosition != null,
      'isCapturingPhoto': _isCapturingPhoto,
      'isRecordingAudio': _isRecordingAudio,
    };
  }

  /// 🗑️ Delete Event Media Files
  Future<void> deleteEventMedia({String? photoPath, String? audioPath}) async {
    if (photoPath != null) {
      try {
        final file = File(photoPath);
        if (await file.exists()) {
          await file.delete();
          debugPrint('🗑️ [MultimodalEvent] Deleted photo: $photoPath');
        }
      } catch (e) {
        debugPrint('❌ [MultimodalEvent] Failed to delete photo: $e');
      }
    }

    if (audioPath != null) {
      await _audioService.deleteRecording(audioPath);
    }
  }

  /// Check if currently recording
  bool get isRecordingAudio => _isRecordingAudio;

  /// Check if currently capturing photo
  bool get isCapturingPhoto => _isCapturingPhoto;

  /// Get current event type
  WalkEventType? get currentEventType => _currentEventType;

  /// Cleanup resources
  void dispose() {
    _audioService.dispose();
    clearCurrentEvent();
  }
}
