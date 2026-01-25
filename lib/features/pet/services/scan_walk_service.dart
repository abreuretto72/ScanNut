import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/walk_models.dart';
import '../../../core/services/hive_atomic_manager.dart';
import '../../../core/services/simple_auth_service.dart';

class ScanWalkService {
  static final ScanWalkService _instance = ScanWalkService._internal();
  factory ScanWalkService() => _instance;
  ScanWalkService._internal();

  static const String _walkBoxName = 'box_walk_history';
  Box? _walkBox;

  Future<void> init() async {
    final cipher = SimpleAuthService().encryptionCipher;
    // Attempt open via Atomic Manager for safety
    try {
      if (cipher != null) {
        _walkBox = await HiveAtomicManager()
            .ensureBoxOpen(_walkBoxName, cipher: cipher);
      } else {
        // Fallback for dev mode if auth not ready (should not happen in prod)
        if (!Hive.isBoxOpen(_walkBoxName)) {
          _walkBox = await Hive.openBox(_walkBoxName);
        } else {
          _walkBox = Hive.box(_walkBoxName);
        }
      }
    } catch (e) {
      debugPrint("⚠️ ScanWalkService Init Error: $e");
    }
  }

  // --- LOCATION SERVICES ---

  Future<bool> checkPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters
      ),
    );
  }

  // --- PERSISTENCE ---

  Future<void> saveWalkSession(WalkSession session) async {
    if (_walkBox == null || !_walkBox!.isOpen) await init();

    final key = session.id;
    await _walkBox!.put(key, session.toJson());
    await _walkBox!.flush(); // 💿 Garante escrita física imediata
    debugPrint(
        "✅ [Lei de Ferro] ScanWalk: Sessão $key salva e sincronizada em disco.");
  }

  Future<List<WalkSession>> getHistoryForPet(String petId) async {
    if (_walkBox == null || !_walkBox!.isOpen) await init();

    final List<WalkSession> history = [];
    for (var key in _walkBox!.keys) {
      final entry = _walkBox!.get(key);
      if (entry != null) {
        try {
          // Handle potential type mismatch if raw Map vs JSON string
          final Map<String, dynamic> map =
              Map<String, dynamic>.from(entry as Map);
          if (map['pet_id'] == petId || map['petId'] == petId) {
            history.add(WalkSession.fromJson(map));
          }
        } catch (e) {
          debugPrint("⚠️ Corruption in walk history entry: $e");
        }
      }
    }

    // Sort by date desc
    history.sort((a, b) => b.startTime.compareTo(a.startTime));
    return history;
  }
}
