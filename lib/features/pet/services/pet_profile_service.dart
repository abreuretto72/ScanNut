import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

/// Service for managing pet profiles (Raça & ID data)
class PetProfileService {
  static const String _profileBoxName = 'pet_profiles';
  Box? _profileBox;

  Future<void> init() async {
    if (!Hive.isBoxOpen(_profileBoxName)) {
      _profileBox = await Hive.openBox(_profileBoxName);
      debugPrint('✅ PetProfileService initialized');
    }
  }

  /// Save or update pet profile
  Future<void> saveOrUpdateProfile(String petName, Map<String, dynamic> profileData) async {
    try {
      await _profileBox?.put(petName, {
        'pet_name': petName,
        'last_updated': DateTime.now().toIso8601String(),
        'data': profileData,
      });
      debugPrint('✅ Profile saved/updated for $petName');
    } catch (e) {
      debugPrint('❌ Error saving profile: $e');
    }
  }

  /// Get pet profile
  Future<Map<String, dynamic>?> getProfile(String petName) async {
    try {
      final profile = _profileBox?.get(petName);
      return profile != null ? Map<String, dynamic>.from(profile as Map) : null;
    } catch (e) {
      debugPrint('❌ Error getting profile: $e');
      return null;
    }
  }

  /// Check if pet profile exists
  Future<bool> hasProfile(String petName) async {
    return _profileBox?.containsKey(petName) ?? false;
  }

  /// Get all pet names
  Future<List<String>> getAllPetNames() async {
    try {
      return _profileBox?.keys.cast<String>().toList() ?? [];
    } catch (e) {
      debugPrint('❌ Error getting pet names: $e');
      return [];
    }
  }

  /// Delete pet profile
  Future<void> deleteProfile(String petName) async {
    try {
      await _profileBox?.delete(petName);
      debugPrint('✅ Profile deleted for $petName');
    } catch (e) {
      debugPrint('❌ Error deleting profile: $e');
    }
  }
}
