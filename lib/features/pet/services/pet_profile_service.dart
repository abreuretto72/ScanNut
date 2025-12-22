import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'pet_event_service.dart';

/// Service for managing pet profiles (Raça & ID data)
class PetProfileService {
  static final PetProfileService _instance = PetProfileService._internal();
  factory PetProfileService() => _instance;
  PetProfileService._internal();

  static const String _profileBoxName = 'pet_profiles';
  Box? _profileBox;

  Future<void> init() async {
    // Prevent multiple opens if already ready
    if (_profileBox != null && _profileBox!.isOpen) return;
    
    try {
        if (!Hive.isBoxOpen(_profileBoxName)) {
            _profileBox = await Hive.openBox(_profileBoxName);
        } else {
            _profileBox = Hive.box(_profileBoxName);
        }
        debugPrint('✅ PetProfileService initialized (Singleton). Box Open: ${_profileBox?.isOpen}');
    } catch (e, stack) {
        debugPrint('❌ CRITICAL: Failed to open Pet Profile Box: $e\n$stack');
    }
  }

  String _normalizeKey(String petName) {
    return petName.trim().toLowerCase();
  }

  /// Save or update pet profile
  Future<void> saveOrUpdateProfile(String petName, Map<String, dynamic> profileData) async {
    try {
      if (_profileBox == null || !(_profileBox?.isOpen ?? false)) {
         debugPrint('⚠️ Warning: PetProfileService box closed/null. Re-initializing...');
         await init();
         if (_profileBox == null || !(_profileBox?.isOpen ?? false)) {
             throw HiveError('Failed to open Hive Box $_profileBoxName');
         }
      }
      
      final key = _normalizeKey(petName);
      await _profileBox!.put(key, {
        'pet_name': petName.trim(), // Keep original display name
        'last_updated': DateTime.now().toIso8601String(),
        'photo_path': profileData['image_path'], // New top-level key for auditing
        'data': profileData,
      });
      await _profileBox!.flush(); // Force write to disk
      debugPrint('HIVE: Objeto ["$key"] persistido no disco com sucesso. (Display: $petName)');
    } catch (e, stack) {
      debugPrint('❌ Error saving profile: $e\n$stack');
    }
  }

  /// Get pet profile
  Future<Map<String, dynamic>?> getProfile(String petName) async {
    try {
      final key = _normalizeKey(petName);
      final profile = _profileBox?.get(key);
      if (profile == null) {
          debugPrint('⚠️ Profile not found for key: "$key"');
          return null;
      }
      debugPrint('✅ Profile loaded for key: "$key"');
      return Map<String, dynamic>.from(profile as Map);
    } catch (e) {
      debugPrint('❌ Error getting profile: $e');
      return null;
    }
  }

  /// Check if pet profile exists
  Future<bool> hasProfile(String petName) async {
    final key = _normalizeKey(petName);
    return _profileBox?.containsKey(key) ?? false;
  }

  /// Get all pet names
  Future<List<String>> getAllPetNames() async {
    try {
      return _profileBox?.values
          .map((e) => (e as Map)['pet_name'] as String)
          .toList() ?? [];
    } catch (e) {
      debugPrint('❌ Error getting pet names: $e');
      return [];
    }
  }

  /// Delete pet profile
  Future<void> deleteProfile(String petName) async {
    try {
      final key = _normalizeKey(petName);
      await _profileBox?.delete(key);
      await _profileBox?.flush();
      
      // Cleanup associated events
      await PetEventService().deleteAllEventsForPet(petName);
      
      debugPrint('✅ Profile deleted for key: "$key" and events purged.');
    } catch (e) {
      debugPrint('❌ Error deleting profile: $e');
    }
  }

  /// Update Linked Partners (Atomic Patch)
  Future<void> updateLinkedPartners(String petName, List<String> linkedPartnerIds) async {
      try {
          await init(); // Ensure open
          final key = _normalizeKey(petName);
          final entry = _profileBox?.get(key);
          
          if (entry != null) {
              final map = Map<String, dynamic>.from(entry as Map);
              final data = Map<String, dynamic>.from(map['data'] as Map);
              data['linked_partner_ids'] = linkedPartnerIds;
              
              map['data'] = data;
              map['last_updated'] = DateTime.now().toIso8601String();
              
              await _profileBox!.put(key, map);
              await _profileBox!.flush();
              debugPrint('HIVE_OK: Vínculo persistido no disco. IDs: $linkedPartnerIds');
          } else {
              debugPrint('⚠️ Cannot update partners: Profile not found for $petName');
          }
      } catch (e, stack) {
          debugPrint('❌ Error updating linked partners: $e\n$stack');
      }
  }

  /// Update Agenda Events (Atomic Patch)
  Future<void> updateAgendaEvents(String petName, List<Map<String, dynamic>> events) async {
      try {
          await init();
          final key = _normalizeKey(petName);
          final entry = _profileBox?.get(key);
          
          if (entry != null) {
              final map = Map<String, dynamic>.from(entry as Map);
              final data = Map<String, dynamic>.from(map['data'] as Map);
              data['agendaEvents'] = events;
              
              map['data'] = data;
              map['last_updated'] = DateTime.now().toIso8601String();
              
              await _profileBox!.put(key, map);
              await _profileBox!.flush();
              debugPrint('HIVE_OK: Eventos da Agenda persistidos no disco. Count: ${events.length}');
          } else {
              debugPrint('⚠️ Cannot update agenda: Profile not found for $petName');
          }
      } catch (e, stack) {
          debugPrint('❌ Error updating agenda events: $e\n$stack');
      }
  }

  /// Update Partner Notes (Atomic Patch)
  Future<void> updatePartnerNotes(String petName, Map<String, List<Map<String, dynamic>>> notes) async {
      try {
          await init();
          final key = _normalizeKey(petName);
          final entry = _profileBox?.get(key);
          
          if (entry != null) {
              final map = Map<String, dynamic>.from(entry as Map);
              final data = Map<String, dynamic>.from(map['data'] as Map);
              data['partner_notes'] = notes;
              
              map['data'] = data;
              map['last_updated'] = DateTime.now().toIso8601String();
              
              await _profileBox!.put(key, map);
              await _profileBox!.flush();
              debugPrint('HIVE_OK: Notas de parceiros persistidas no disco.');
          }
      } catch (e, stack) {
          debugPrint('❌ Error updating partner notes: $e\n$stack');
      }
  }
}
