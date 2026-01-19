/// ============================================================================
/// 🚫 COMPONENTE BLINDADO E CONGELADO - NÃO ALTERAR
/// Este módulo de Gestão de Pets foi concluído e validado.
/// Nenhuma rotina ou lógica interna deve ser modificada.
/// Data de Congelamento: 29/12/2025
/// ============================================================================

import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pet_event_service.dart';
import '../models/analise_ferida_model.dart';

import '../../../core/utils/json_cast.dart';
import '../../../core/services/simple_auth_service.dart';
import '../../../core/services/permanent_backup_service.dart';
import '../../../core/services/media_vault_service.dart';
import '../../../core/services/hive_atomic_manager.dart';

final petProfileServiceProvider = Provider<PetProfileService>((ref) => PetProfileService());

/// Service for managing pet profiles (Raça & ID data)
class PetProfileService {
  static final PetProfileService _instance = PetProfileService._internal();
  factory PetProfileService() => _instance;
  PetProfileService._internal();

  static const String _profileBoxName = 'box_pets_master';
  Box? _profileBox;

  static PetProfileService get to => _instance;

  Future<void> init({HiveCipher? cipher}) async {
    // 🛡️ PROTEÇÃO: Se não passar cipher, tenta pegar o global do SimpleAuthService
    final effectiveCipher = cipher ?? SimpleAuthService().encryptionCipher;
    
    // 🛡️ [V105] ATOMIC MANAGER DELEGATION
    // We delegate the opening to the Atomic Manager which handles 
    // "Closed unexpectedly", "File not found", and "Zombie" states.
    try {
        _profileBox = await HiveAtomicManager().ensureBoxOpen(_profileBoxName, cipher: effectiveCipher);
        
        // 🧹 RESET TÉCNICO: Limpeza de Paths Órfãos (Cache)
        await _sanitizeOrphanedCachePaths();
        
        debugPrint('✅ [V105] PetProfileService initialized via Atomic Manager.');
    } catch (e) {
        debugPrint('❌ [V105] Critical: Failed to open Pet Profile Box: $e. Attempting Atomic Reset...');
        // ☢️ [V105] NUCLEAR OPTION
        try {
           await HiveAtomicManager().recreateBox(_profileBoxName, cipher: effectiveCipher);
           _profileBox = await HiveAtomicManager().ensureBoxOpen(_profileBoxName, cipher: effectiveCipher);
           debugPrint('✅ [V105] PetProfileService recovered via Atomic Reset.');
        } catch (resetErr) {
           debugPrint('☠️ [V105] FATAL: Could not recover Pet Profile Box: $resetErr');
           rethrow;
        }
    }
  }

  /// 🔄 [V107] ATOMIC RESET & RELOAD
  /// Forces a complete re-initialization of the service, closing any open boxes
  /// to purge in-memory ghosts and reloading data fresh from disk.
  Future<void> resetAndReload() async {
    debugPrint('🔄 [V107] PetProfileService: Initiating Atomic Reset & Reload...');
    try {
      if (_profileBox != null && _profileBox!.isOpen) {
        await _profileBox!.close();
        debugPrint('   [V107] Box closed to purge memory.');
      }
      _profileBox = null;
      await init(); // Re-open fresh
      debugPrint('✅ [V107] PetProfileService: Reload Complete. State is clean.');
    } catch (e) {
      debugPrint('❌ [V107] Error during resetAndReload: $e');
    }
  }

  /// 🧹 [V108] ALIAS: Limpa referência de memória
  void clearMemoryCache() {
      // Just nullify the reference if we want to force re-open.
      // Or close it if open.
      if (_profileBox != null && _profileBox!.isOpen) {
         // We won't await here because it's void, but we can fire and forget or just nullify.
         // Better to be safe and just invalidate the variable so next call forces re-fetch.
         // Note: closing async is better but let's stick to the requested signature.
         _profileBox = null; // Forces ensureOpenBox to run again in syncWithDisk or init
         debugPrint('🔍 [V108-CACHE] Memória RAM limpa (Reference Invalidated).');
      }
  }

  /// ☢️ [V111] PROTOCOLO DE PURGA NUCLEAR E RECONSTRUÇÃO
  /// Força o fechamento de TODAS as boxes (Global Stop), deleta arquivos físicos
  /// e reinicia o motor do Hive. Solução definitiva para "Arquivos Zumbis" (Locks).
  Future<void> wipeAllDataPhysically() async {
      debugPrint('🔍 [V111-WIPE] Iniciando protocolo Nuclear V111...');
      try {
          // 1. GLOBAL STOP (Para soltar qualquer LOCK do arquivo)
          await Hive.close(); 
          debugPrint('   [V111] Todas as boxes fechadas. Motor Hive parado.');

          // 2. PHYSICAL OBLITERATION
          debugPrint('🔍 [V111-WIPE] Deletando arquivos físicos de $_profileBoxName...');
          try {
             // Tenta deletar via Hive API (agora que fechou tudo, deve funcionar)
             await Hive.deleteBoxFromDisk(_profileBoxName);
          } catch (e) {
             debugPrint('⚠️ [V111] Erro na deleção via API: $e. Tentando manual...');
             // Fallback manual (se a API falhar) - Requer path_provider, mas vamos confiar no close() primeiro.
          }
          
          _profileBox = null;
          
          // 3. REBIRTH (Reiniciar o motor)
          debugPrint('🔍 [V111-REBIRTH] Reconstruindo motor Hive...');
          // Re-init requer abrir as coisas de novo. Init() deste serviço abre a dele.
          // Mas como fechamos TUDO, outros serviços podem precisar de re-init se forem usados.
          // O DataArchivingScreen chama pEvents.init() depois disso, então OK.
          
          await init();
          
          // 4. VERIFICATION
          final count = _profileBox?.length ?? -1;
          debugPrint('🔍 [V111-VERIFY] Conteúdo físico após wipe: $count itens.');
          
          if (count == 0) {
             debugPrint('✅ [V111-STATUS] O banco de dados está 100% limpo. O \'TOI\' foi eliminado.');
          } else {
             debugPrint('❌ [V111-STATUS] CRÍTICO: O fantasma sobreviveu! Contagem: $count');
          }
          
      } catch (e) {
          debugPrint('❌ [V111-FAIL] Falha catastrófica: $e');
      }
  }

  /// 💿 [V108] ALIAS: Sincronização Forçada
  Future<void> syncWithDisk() async {
      debugPrint('🔍 [V108-SYNC] Sincronizando com Hive...');
      await init();
      // Ensure strict ghost check is respected by init/ensureOpenBox
      debugPrint('✅ [V108-SYNC] Sincronização concluída.');
  }

  /// 🧹 ONE-TIME DISINFECTION: Removes paths pointing to volatile cache
  Future<void> _sanitizeOrphanedCachePaths() async {
      if (_profileBox == null) return;
      
      final keys = _profileBox!.keys.toList();
      for (var key in keys) {
          final entry = _profileBox!.get(key);
          if (entry is Map) {
              final map = deepCastMap(entry);
              bool changed = false;
              final petName = map['pet_name'] ?? key;
              
              // Check Top Level
              String? photoPath = map['photo_path'];
              if (photoPath != null && photoPath.contains('cache')) {
                  debugPrint('🧹 [SANITIZER] Clearing phantom CACHE path for "$petName" (Top-Level)');
                  map['photo_path'] = null;
                  changed = true;
              }
              
              // Check Data Level
              if (map['data'] != null && map['data'] is Map) {
                  final data = deepCastMap(map['data']);
                  String? innerPath = data['image_path'];
                  if (innerPath != null && innerPath.contains('cache')) {
                      debugPrint('🧹 [SANITIZER] Clearing phantom CACHE path for "$petName" (Data-Level)');
                      data['image_path'] = null;
                      map['data'] = data;
                      changed = true;
                  }
              }
              
              if (changed) {
                  await _profileBox!.put(key, map);
                  debugPrint('   ✨ Path Reset applied for "$petName". Ready for new secure photo.');
              }
          }
      }
  }

  ValueListenable<Box>? get listenable => _profileBox?.listenable();

  String _normalizeKey(String petName) {
    final normalized = petName.trim().toLowerCase();
    // debugPrint('🔑 [PetProfileService] Normalizing key: "$petName" -> "$normalized"');
    return normalized;
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
      
      // 🛡️ ZERO CACHE INTERVENTION: Enforce Vault Storage
      final rawPath = profileData['image_path'] as String?;
      if (rawPath != null && rawPath.isNotEmpty) {
          final vault = MediaVaultService();
          if (!vault.isPathSecure(rawPath)) {
             final file = File(rawPath);
             if (await file.exists()) {
                 try {
                     debugPrint('🔒 SECURING IMAGE: Moving from volatile cache to Vault...');
                     final securePath = await vault.secureClone(
                         file, 
                         MediaVaultService.PETS_DIR, 
                         petName // Use pet name for organization
                     );
                     profileData['image_path'] = securePath;
                     debugPrint('✅ IMAGE SECURED at: $securePath');
                 } catch (e) {
                     debugPrint('❌ Failed to secure image (saving invalid path): $e');
                 }
             }
          }
      }
      
      final key = _normalizeKey(petName);
      debugPrint('💾 [PetProfileService] Saving profile for key: "$key" (Display: $petName)...');
      debugPrint('   [PetProfileService] Image Path: ${profileData['image_path']}');
      
      await _profileBox!.put(key, {
        'pet_name': petName.trim(), // Keep original display name
        'last_updated': DateTime.now().toIso8601String(),
        'photo_path': profileData['image_path'], // New top-level key for auditing
        'data': profileData,
      });
      await _profileBox!.flush(); // Force write to disk
      debugPrint('✅ [PetProfileService] HIVE SUCCESS: Objeto ["$key"] persistido no disco.');
    
    // 🔄 Trigger automatic permanent backup
    PermanentBackupService().createAutoBackup().then((_) {
      debugPrint('💾 Backup permanente atualizado após salvar pet');
    }).catchError((e) {
      debugPrint('⚠️ Backup automático falhou: $e');
    });
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
          debugPrint('⚠️ [PROFILE_TRACE] Profile not found for key: "$key"');
          return null;
      }
      
      final map = deepCastMap(profile);

      // 🛡️ DATA SURVIVAL CHECK (Self-Healing)
      try {
        String? pathCheck = map['photo_path'] as String?;
        if (pathCheck == null && map['data'] != null && map['data'] is Map) {
            pathCheck = map['data']['image_path'] as String?;
        }
        
        debugPrint('🔍 [PROFILE_TRACE] Checking image for $petName ($key)');
        debugPrint('   [PROFILE_TRACE] Raw Path: $pathCheck');
        
        if (pathCheck != null && pathCheck.isNotEmpty) {
             final healedPath = await MediaVaultService().attemptRecovery(pathCheck);
             debugPrint('   [PROFILE_TRACE] Healed Path: $healedPath');
             // Update in memory map (optional: could save back to DB?)
             if (map['data'] != null && map['data'] is Map) {
                 map['data']['image_path'] = healedPath;
             }
             map['photo_path'] = healedPath; // Update top level too
        }
      } catch (e) {
        debugPrint('⚠️ [PROFILE_TRACE] Self-healing check failed gracefully: $e');
      }

      debugPrint('✅ [PROFILE_TRACE] Profile loaded & verified for key: "$key"');
      return map;

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

  /// Get all pet names with V105 STRICT GHOST CHECK
  Future<List<String>> getAllPetNames() async {
    final profiles = await getAllProfiles();
    return profiles.map((p) => p['pet_name'] as String).toList();
  }

  /// Get all profiles as raw maps
  Future<List<Map<String, dynamic>>> getAllProfiles() async {
    try {
      if (_profileBox == null || !(_profileBox?.isOpen ?? false)) {
        await init();
      }
      
      final safeBox = _profileBox;
      if (safeBox == null || !safeBox.isOpen) return [];

      final profiles = <Map<String, dynamic>>[];
      for (var key in safeBox.keys) {
        final value = safeBox.get(key);
        if (value != null && value is Map) {
          final map = deepCastMap(value);
          // Consistency: Add 'name' key for home_view audit
          map['name'] = map['pet_name'];
          profiles.add(map);
        }
      }
      return profiles;
    } catch (e) {
      debugPrint('❌ Error getting all profiles: $e');
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
              final map = deepCastMap(entry);
              final data = deepCastMap(map['data']);

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
              final map = deepCastMap(entry);
              final data = deepCastMap(map['data']);

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
              final map = deepCastMap(entry);
              final data = deepCastMap(map['data']);

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
              final map = deepCastMap(entry);
              final data = deepCastMap(map['data']);

              
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
              final List<Map<String, dynamic>> history = deepCastMapList(data['wound_analysis_history']);

              
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

  /// 🛡️ V170: Save Detailed Health Analysis (Atomic Append)
  Future<void> saveDetailedAnalysis(String petName, AnaliseFeridaModel analysis) async {
    try {
      await init();
      final key = _normalizeKey(petName);
      final entry = _profileBox?.get(key);

      if (entry != null) {
        final map = deepCastMap(entry);
        final data = deepCastMap(map['data']);
        
        // Load existing history
        final List<dynamic> existingRaw = data['historico_analise_feridas'] ?? [];
        final List<Map<String, dynamic>> history = [];
        
        for (var item in existingRaw) {
             if (item is Map) history.add(deepCastMap(item));
        }

        // Add new analysis
        history.insert(0, analysis.toJson()); // Most recent first
        
        data['historico_analise_feridas'] = history;
        map['data'] = data;
        map['last_updated'] = DateTime.now().toIso8601String();

        await _profileBox!.put(key, map);
        await _profileBox!.flush();
        debugPrint('✅ [V170] Analysis persisted in historico_analise_feridas. Total: ${history.length}');
      }
    } catch (e, stack) {
      debugPrint('❌ Error saving detailed analysis: $e\n$stack');
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
              final List<Map<String, dynamic>> history = deepCastMapList(data['wound_analysis_history']);

              
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
