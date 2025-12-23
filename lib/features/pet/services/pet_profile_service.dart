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
  /// Update Weekly Menu Plan (Atomic Patch)
  Future<void> saveWeeklyMenu({
    required String petName,
    required List<Map<String, dynamic>> menuPlan,
    String? guidelines,
    String? startDate,
    String? endDate,
  }) async {
      try {
          await init();
          final key = _normalizeKey(petName);
          final entry = _profileBox?.get(key);
          
          if (entry != null) {
              final map = Map<String, dynamic>.from(entry as Map);
              final data = Map<String, dynamic>.from(map['data'] as Map);
              
              // CRITICAL: Preserve all keys (especially 'refeicoes' array)
              final List<Map<String, dynamic>> sanitizedPlan = menuPlan.map((item) {
                 return Map<String, dynamic>.from(item);
              }).toList();

              data['plano_semanal'] = sanitizedPlan;
              data['orientacoes_gerais'] = guidelines ?? data['orientacoes_gerais']; // Preserve if null
              
              // New date fields for date range logic
              if (startDate != null) data['data_inicio_semana'] = startDate;
              if (endDate != null) data['data_fim_semana'] = endDate;
              
              map['data'] = data;
              map['last_updated'] = DateTime.now().toIso8601String();
              
              await _profileBox!.put(key, map);
              await _profileBox!.flush();
              debugPrint('HIVE_OK: Cardápio Semanal persistido. Key: $key. Items: ${sanitizedPlan.length}. Range: $startDate to $endDate');
              // Debug first item to ensure structure
              if (sanitizedPlan.isNotEmpty) {
                 debugPrint('  [DEBUG MENU SAMPLE] Item 0: ${sanitizedPlan.first}');
              }
          } else {
              debugPrint('⚠️ Cannot update menu: Profile not found for $petName');
          }
      } catch (e, stack) {
          debugPrint('❌ Error updating weekly menu: $e\n$stack');
      }
  }

  /// Add Wound Analysis to History (Atomic Append)
  Future<void> saveWoundAnalysis({
    required String petName,
    required Map<String, dynamic> analysisData,
  }) async {
      try {
          await init();
          final key = _normalizeKey(petName);
          final entry = _profileBox?.get(key);
          
          if (entry != null) {
              final map = Map<String, dynamic>.from(entry as Map);
              final data = Map<String, dynamic>.from(map['data'] as Map);
              
              // Get existing wound analysis history or create new list
              final List<Map<String, dynamic>> history = 
                  (data['wound_analysis_history'] as List?)
                      ?.map((e) => Map<String, dynamic>.from(e as Map))
                      .toList() ?? [];
              
              // Add new analysis with timestamp
              final newEntry = {
                'date': DateTime.now().toIso8601String(),
                'imagePath': analysisData['imagePath'],
                'diagnosis': analysisData['diagnosis'],
                'severity': analysisData['severity'],
                'recommendations': analysisData['recommendations'],
                'rawData': analysisData['rawData'], // Store complete analysis
              };
              
              history.insert(0, newEntry); // Most recent first
              
              data['wound_analysis_history'] = history;
              map['data'] = data;
              map['last_updated'] = DateTime.now().toIso8601String();
              
              await _profileBox!.put(key, map);
              await _profileBox!.flush();
              debugPrint('HIVE_OK: Wound analysis saved for $petName. Total entries: ${history.length}');
          } else {
              debugPrint('⚠️ Cannot save wound analysis: Profile not found for $petName');
          }
      } catch (e, stack) {
          debugPrint('❌ Error saving wound analysis: $e\n$stack');
      }
  }

  /// Delete Wound Analysis from History
  Future<void> deleteWoundAnalysis({
    required String petName,
    required String analysisDate,
  }) async {
      try {
          await init();
          final key = _normalizeKey(petName);
          final entry = _profileBox?.get(key);
          
          if (entry != null) {
              final map = Map<String, dynamic>.from(entry as Map);
              final data = Map<String, dynamic>.from(map['data'] as Map);
              
              // Get existing wound analysis history
              final List<Map<String, dynamic>> history = 
                  (data['wound_analysis_history'] as List?)
                      ?.map((e) => Map<String, dynamic>.from(e as Map))
                      .toList() ?? [];
              
              // Remove the analysis with matching date
              history.removeWhere((analysis) => analysis['date'] == analysisDate);
              
              data['wound_analysis_history'] = history;
              map['data'] = data;
              map['last_updated'] = DateTime.now().toIso8601String();
              
              await _profileBox!.put(key, map);
              await _profileBox!.flush();
              debugPrint('HIVE_OK: Wound analysis deleted for $petName. Remaining entries: ${history.length}');
          } else {
              debugPrint('⚠️ Cannot delete wound analysis: Profile not found for $petName');
          }
      } catch (e, stack) {
          debugPrint('❌ Error deleting wound analysis: $e\n$stack');
      }
  }
}
