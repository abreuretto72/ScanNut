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
import 'package:uuid/uuid.dart';
import 'pet_event_service.dart';
import '../models/analise_ferida_model.dart';

import '../../../core/utils/json_cast.dart';
import '../../../core/services/simple_auth_service.dart';
import '../../../core/services/media_vault_service.dart';
import '../../../core/services/hive_atomic_manager.dart';
import '../../../core/services/history_service.dart';

final petProfileServiceProvider =
    Provider<PetProfileService>((ref) => PetProfileService());

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

    // 🛡️ [V200-FIX] PREVENT PREMATURE ACCESS (DATA LOSS PROTECTION)
    // If we don't have a cipher, we cannot open the encrypted box safely.
    // Attempting to do so triggers HiveError, which previously triggered Atomic Reset (Nuke).
    if (effectiveCipher == null) {
      debugPrint(
          '🛑 [PetProfileService] Init aborted: No encryption cipher available (User locked).');
      _profileBox = null;
      return;
    }

    // 🛡️ [V105] ATOMIC MANAGER DELEGATION
    // We delegate the opening to the Atomic Manager which handles
    // "Closed unexpectedly", "File not found", and "Zombie" states.
    try {
      _profileBox = await HiveAtomicManager()
          .ensureBoxOpen(_profileBoxName, cipher: effectiveCipher);

      // 🧹 RESET TÉCNICO: Limpeza de Paths Órfãos (Cache)
      await _sanitizeOrphanedCachePaths();

      debugPrint('✅ [V105] PetProfileService initialized via Atomic Manager.');

      // 🛡️ [V_UUID] MIGRAÇÃO E INTEGRIDADE
      await _migrateToUuidKeys();
    } catch (e) {
      debugPrint(
          '❌ [V105] Critical: Failed to open Pet Profile Box: $e. Attempting Atomic Reset...');
      // ☢️ [V105] NUCLEAR OPTION
      try {
        await HiveAtomicManager()
            .recreateBox(_profileBoxName, cipher: effectiveCipher);
        _profileBox = await HiveAtomicManager()
            .ensureBoxOpen(_profileBoxName, cipher: effectiveCipher);
        debugPrint('✅ [V105] PetProfileService recovered via Atomic Reset.');
      } catch (resetErr) {
        debugPrint(
            '☠️ [V105] FATAL: Could not recover Pet Profile Box: $resetErr');
        rethrow;
      }
    }
  }

  /// 🔄 [V107] ATOMIC RESET & RELOAD
  /// Forces a complete re-initialization of the service, closing any open boxes
  /// to purge in-memory ghosts and reloading data fresh from disk.
  Future<void> resetAndReload() async {
    debugPrint(
        '🔄 [V107] PetProfileService: Initiating Atomic Reset & Reload...');
    try {
      if (_profileBox != null && _profileBox!.isOpen) {
        await _profileBox!.close();
        debugPrint('   [V107] Box closed to purge memory.');
      }
      _profileBox = null;
      await init(); // Re-open fresh
      debugPrint(
          '✅ [V107] PetProfileService: Reload Complete. State is clean.');
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
      _profileBox =
          null; // Forces ensureOpenBox to run again in syncWithDisk or init
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
      debugPrint(
          '🔍 [V111-WIPE] Deletando arquivos físicos de $_profileBoxName...');
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
        debugPrint(
            '✅ [V111-STATUS] O banco de dados está 100% limpo. O \'TOI\' foi eliminado.');
      } else {
        debugPrint(
            '❌ [V111-STATUS] CRÍTICO: O fantasma sobreviveu! Contagem: $count');
      }
    } catch (e) {
      debugPrint('❌ [V111-FAIL] Falha catastrófica: $e');
    }
  }

  /// 💿 [V108] ALIAS: Sincronização Forçada (Lei de Ferro)
  Future<void> syncWithDisk() async {
    debugPrint('🔍 [V108-SYNC] Iniciando Sincronização Nuclear com o Disco...');
    try {
      if (_profileBox != null && _profileBox!.isOpen) {
        await _profileBox!.flush(); // Garante escrita do que está em memória
        await _profileBox!.close(); // Fecha para limpar cache do Hive
      }
      _profileBox = null;
      await init(); // Reabre forçando leitura física
      debugPrint(
          '✅ [V108-SYNC] Sincronização física concluída. Box está limpa.');
    } catch (e) {
      debugPrint('❌ [V108-SYNC] Erro durante sincronização: $e');
      await init(); // Fallback
    }
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
          debugPrint(
              '🧹 [SANITIZER] Clearing phantom CACHE path for "$petName" (Top-Level)');
          map['photo_path'] = null;
          changed = true;
        }

        // Check Data Level
        if (map['data'] != null && map['data'] is Map) {
          final data = deepCastMap(map['data']);
          String? innerPath = data['image_path'];
          if (innerPath != null && innerPath.contains('cache')) {
            debugPrint(
                '🧹 [SANITIZER] Clearing phantom CACHE path for "$petName" (Data-Level)');
            data['image_path'] = null;
            map['data'] = data;
            changed = true;
          }
        }

        if (changed) {
          await _profileBox!.put(key, map);
          debugPrint(
              '   ✨ Path Reset applied for "$petName". Ready for new secure photo.');
        }
      }
    }
  }

  String _normalizeKey(String id) {
    return id.trim().toLowerCase();
  }

  /// 🛡️ [V_UUID] MIGRATION: Converts old name-based keys to UUID-based keys
  Future<void> _migrateToUuidKeys() async {
    if (_profileBox == null) return;

    final keys = _profileBox!.keys.toList();
    bool migrated = false;

    for (var key in keys) {
      final entry = _profileBox!.get(key);
      if (entry is Map) {
        final map = deepCastMap(entry);
        final data = deepCastMap(map['data'] ?? map);

        String? id = map['id'] ?? data['id'];

        // Se a chave não parece um UUID (ex: é o nome do pet) e não tem ID interno
        bool keyIsName = !key.toString().contains('-') ||
            key.toString().length < 30; // Heurística simples

        if (id == null || keyIsName) {
          final petName = data['pet_name'] ?? key.toString();
          final newId = id ?? const Uuid().v4();

          debugPrint('🔄 [MIGRATION] Re-keying pet "$petName": $key -> $newId');

          // Atualiza os dados com o novo ID
          data['id'] = newId;
          map['id'] = newId;
          map['data'] = data;
          map['pet_name'] = petName;

          // Salva na nova chave
          await _profileBox!.put(newId, map);

          // Se a chave antiga for diferente da nova, remove a antiga
          if (key.toString() != newId) {
            await _profileBox!.delete(key);
          }

          migrated = true;
        }
      }
    }

    if (migrated) {
      await _profileBox!.flush();
      debugPrint('✅ [MIGRATION] Database successfully migrated to UUID keys.');
    }
  }

  /// Save or update pet profile
  Future<void> saveOrUpdateProfile(
      String petName, Map<String, dynamic> profileData) async {
    try {
      if (_profileBox == null || !(_profileBox?.isOpen ?? false)) {
        debugPrint(
            '⚠️ Warning: PetProfileService box closed/null. Re-initializing...');
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
              debugPrint(
                  '🔒 SECURING IMAGE: Moving from volatile cache to Vault...');
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

      final petId = profileData['id'] ?? const Uuid().v4();
      final key = _normalizeKey(petId.toString());

      debugPrint(
          '💾 [HIVE_TRACE] saveOrUpdateProfile: Target Key="$key" (Derived from ID: ${profileData['id']})');

      if (profileData['id'] == null) {
        profileData['id'] = petId;
      }

      debugPrint(
          '💾 [PetProfileService] Saving profile for key: "$key" (Display: $petName)...');
      debugPrint(
          '   [PetProfileService] Image Path: ${profileData['image_path']}');

      // 🛡️ [V_FIX] SMART MERGE: historico_analise_feridas (Health Domain)
      // Prevent stale UI state (missing new items) from overwriting the DB.
      // This logic treats saveOrUpdateProfile as "Append/Update Only" for history.
      // Deletions must be done via specific atomic methods (which update DB first).
      try {
        final existing = _profileBox!.get(key);
        if (existing != null && existing is Map) {
          final existingData = existing['data'] as Map?;
          if (existingData != null) {
            final List<dynamic> existingHistoryRaw =
                existingData['historico_analise_feridas'] ?? [];
            final List<dynamic> newHistoryRaw =
                profileData['historico_analise_feridas'] ?? [];

            // Helper to generate unique ID for an item
            String getItemId(dynamic item) {
              if (item == null) return 'null';
              final m = item as Map;
              // Support snake_case (DB), camelCase (Model JSON), and legacy keys
              final date = m['date'] ??
                  m['data_analise'] ??
                  m['dataAnalise'] ??
                  'unknown_date';
              final path = m['imagePath'] ?? m['imagemRef'] ?? 'no_image';
              return '${date.toString()}_${path.toString()}';
            }

            final newIds = newHistoryRaw.map((e) => getItemId(e)).toSet();
            final List<dynamic> mergedHistory = List.from(newHistoryRaw);
            bool restoredItems = false;

            debugPrint(
                '🔍 [PET_TRACE] Smart Merge: UI=${newHistoryRaw.length} items, Disk=${existingHistoryRaw.length} items');

            for (var oldItem in existingHistoryRaw) {
              final oldId = getItemId(oldItem);
              if (!newIds.contains(oldId)) {
                mergedHistory.add(oldItem);
                restoredItems = true;
                debugPrint(
                    '   [PET_TRACE] Restoring missing item from disk: $oldId');
              }
            }

            if (restoredItems) {
              debugPrint(
                  '🛡️ [Smart Merge] Restored ${mergedHistory.length - newHistoryRaw.length} items from disk.');
              // Re-sort by date (descending)
              mergedHistory.sort((a, b) {
                try {
                  final dA = DateTime.tryParse(
                          (a['date'] ?? a['data_analise'] ?? a['dataAnalise'])
                              .toString()) ??
                      DateTime(2000);
                  final dB = DateTime.tryParse(
                          (b['date'] ?? b['data_analise'] ?? b['dataAnalise'])
                              .toString()) ??
                      DateTime(2000);
                  return dB.compareTo(dA);
                } catch (_) {
                  return 0;
                }
              });
              profileData['historico_analise_feridas'] = mergedHistory;
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ [PetProfileService] Smart merge error: $e');
      }

      await _profileBox!.put(key, {
        'id': petId,
        'pet_name': petName.trim(),
        'last_updated': DateTime.now().toIso8601String(),
        'photo_path': profileData['image_path'],
        'data': profileData,
      });
      await _profileBox!.flush();
      debugPrint(
          '💾 [Lei de Ferro] DISK_CONFIRMED: Pet "$petName" (ID: $petId) salvo fisicamente no disco.');

      // Auto-backup removido conforme solicitação do usuário
    } catch (e, stack) {
      debugPrint('❌ Error saving profile: $e\n$stack');
    }
  }

  /// 🛡️ [V_FIX] HELPER: Resolve Key by ID or Name
  /// Searches for the actual disk key (UUID) if a name is provided.
  Future<String?> _resolveEntryKey(String idOrName) async {
    debugPrint(
        '🔍 [HIVE_TRACE] _resolveEntryKey: Searching for "$idOrName"...');
    final key = _normalizeKey(idOrName);
    if (_profileBox?.containsKey(key) ?? false) {
      debugPrint('   [HIVE_TRACE] Direct match found for key "$key"');
      return key;
    }

    debugPrint(
        '🔍 [PET_TRACE] Key "$idOrName" not found. Searching by name matching...');
    final allKeys = _profileBox!.keys;
    for (var k in allKeys) {
      final entry = _profileBox!.get(k);
      if (entry is Map) {
        final name = entry['pet_name']?.toString().toLowerCase();
        if (name == idOrName.toLowerCase()) {
          debugPrint(
              '   [PET_TRACE] Match found! Name "$idOrName" -> Key "$k"');
          return k.toString();
        }
      }
    }
    return null;
  }

  /// Get pet profile by ID or Name (Compatibility layer)
  Future<Map<String, dynamic>?> getProfile(String idOrName) async {
    try {
      debugPrint('📖 [HIVE_TRACE] getProfile: Request for "$idOrName"');
      final key = await _resolveEntryKey(idOrName) ?? _normalizeKey(idOrName);
      debugPrint('   [HIVE_TRACE] Resolved Key: "$key"');
      var profile = _profileBox?.get(key);

      if (profile == null) {
        // Fallback: Search by name if key lookup fails
        debugPrint(
            '🔍 [PROFILE_TRACE] Key lookup failed for "$idOrName". Searching by name...');
        final all = await getAllProfiles();
        final match = all.firstWhere(
            (p) =>
                p['pet_name']?.toString().toLowerCase() ==
                idOrName.toLowerCase(),
            orElse: () => {});
        if (match.isNotEmpty) {
          profile = match;
        }
      }

      if (profile == null) {
        debugPrint('⚠️ [PROFILE_TRACE] Profile not found for: "$idOrName"');
        return null;
      }

      final map = deepCastMap(profile);

      // 🛡️ DATA SURVIVAL CHECK (Self-Healing)
      try {
        String? pathCheck = map['photo_path'] as String?;
        if (pathCheck == null && map['data'] != null && map['data'] is Map) {
          pathCheck = map['data']['image_path'] as String?;
        }

        debugPrint(
            '🔍 [PROFILE_TRACE] Checking image for ${map['pet_name']} ($key)');
        debugPrint('   [PROFILE_TRACE] Raw Path: $pathCheck');

        if (pathCheck != null && pathCheck.isNotEmpty) {
          final healedPath =
              await MediaVaultService().attemptRecovery(pathCheck);
          debugPrint('   [PROFILE_TRACE] Healed Path: $healedPath');
          // Update in memory map (optional: could save back to DB?)
          if (map['data'] != null && map['data'] is Map) {
            map['data']['image_path'] = healedPath;
          }
          map['photo_path'] = healedPath; // Update top level too
        }
      } catch (e) {
        debugPrint(
            '⚠️ [PROFILE_TRACE] Self-healing check failed gracefully: $e');
      }

      debugPrint('✅ [PROFILE_TRACE] Profile loaded & verified for key: "$key"');
      return map;
    } catch (e) {
      debugPrint('❌ Error getting profile: $e');
      return null;
    }
  }

  /// Check if pet profile exists [UUID_AWARE]
  Future<bool> hasProfile(String idOrName) async {
    final key = await _resolveEntryKey(idOrName);
    return key != null;
  }

  /// Get all pet names with V105 STRICT GHOST CHECK
  /// Get all pet IDs and names for selection dialogs [UUID_SAFE]
  Future<List<Map<String, String>>> getAllPetIdsWithNames() async {
    final profiles = await getAllProfiles();
    return profiles
        .map((p) => {
              'id': (p['id'] ?? p['pet_id'] ?? '').toString(),
              'name': (p['pet_name'] ?? 'Pet').toString(),
            })
        .toList();
  }

  Future<List<String>> getAllPetNames() async {
    final profiles = await getAllProfiles();
    return profiles.map((p) => p['pet_name'] as String).toList();
  }

  /// Get name and ID of all pets for dropdowns and filtering
  Future<Map<String, String>> getAllPetSummaries() async {
    final profiles = await getAllProfiles();
    final Map<String, String> summary = {};
    for (var p in profiles) {
      final name = p['pet_name']?.toString() ?? 'Desconhecido';
      final id = p['id']?.toString() ?? name; // Fallback to name if no ID
      summary[name] = id;
    }
    return summary;
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
      debugPrint(
          '📜 [HIVE_TRACE] getAllProfiles returned ${profiles.length} items. Keys in box: ${safeBox.keys.toList()}');
      return profiles;
    } catch (e) {
      debugPrint('❌ Error getting all profiles: $e');
      return [];
    }
  }

  /// Delete pet profile (Robust ID/Name lookup)
  Future<void> deleteProfile(String idOrName) async {
    try {
      if (_profileBox == null || !(_profileBox?.isOpen ?? false)) await init();

      final key = _normalizeKey(idOrName);
      String? actualPetName;
      bool deleted = false;

      // 1. Try direct key deletion
      if (_profileBox?.containsKey(key) ?? false) {
        final entry = _profileBox?.get(key);
        if (entry is Map) {
          actualPetName = entry['pet_name'];
        }
        await _profileBox?.delete(key);
        deleted = true;
        debugPrint(
            '✅ Profile deleted by direct key: "$key" (Name: $actualPetName)');
      }

      // 2. Fallback: Search all profiles by name if direct key didn't work
      if (!deleted) {
        debugPrint(
            '🔍 [PetProfileService] Direct key lookup failed for "$idOrName". Searching by name...');
        final profiles = await getAllProfiles();
        final match = profiles.firstWhere(
            (p) =>
                p['pet_name']?.toString().toLowerCase() ==
                idOrName.toLowerCase(),
            orElse: () => {});

        if (match.isNotEmpty) {
          actualPetName = match['pet_name'];
          final actualId = match['id']?.toString();
          if (actualId != null) {
            final realKey = _normalizeKey(actualId);
            await _profileBox?.delete(realKey);
            deleted = true;
            debugPrint(
                '✅ Profile deleted by name resolution: "$idOrName" -> "$actualId"');
          }
        }
      }

      await _profileBox?.flush();

      // 3. Cleanup associated events and history
      // Use the resolved pet name if found, otherwise use input
      final targetNameForEvents = actualPetName ?? idOrName;
      await PetEventService().deleteAllEventsForPet(targetNameForEvents);
      await HistoryService.deletePet(targetNameForEvents);

      if (!deleted) {
        debugPrint(
            '⚠️ Delete failed: No profile found for "$idOrName" or its name.');
      }
    } catch (e) {
      debugPrint('❌ Error deleting profile: $e');
    }
  }

  /// Update Linked Partners (Atomic Patch)
  Future<void> updateLinkedPartners(
      String idOrName, List<String> linkedPartnerIds) async {
    try {
      await init(); // Ensure open
      final key = await _resolveEntryKey(idOrName) ?? _normalizeKey(idOrName);
      final entry = _profileBox?.get(key);

      if (entry != null) {
        final map = deepCastMap(entry);
        final data = deepCastMap(map['data']);

        data['linked_partner_ids'] = linkedPartnerIds;

        map['data'] = data;
        map['last_updated'] = DateTime.now().toIso8601String();

        await _profileBox!.put(key, map);
        await _profileBox!.flush();
        debugPrint(
            'HIVE_OK: Vínculo persistido no disco. IDs: $linkedPartnerIds');
      } else {
        debugPrint(
            '⚠️ Cannot update partners: Profile not found for $idOrName');
      }
    } catch (e, stack) {
      debugPrint('❌ Error updating linked partners: $e\n$stack');
    }
  }

  /// Update Agenda Events (Atomic Patch)
  Future<void> updateAgendaEvents(
      String petName, List<Map<String, dynamic>> events) async {
    try {
      await init();
      final key = await _resolveEntryKey(petName) ?? _normalizeKey(petName);
      final entry = _profileBox?.get(key);

      if (entry != null) {
        final map = deepCastMap(entry);
        final data = deepCastMap(map['data']);

        data['agendaEvents'] = events;

        map['data'] = data;
        map['last_updated'] = DateTime.now().toIso8601String();

        await _profileBox!.put(key, map);
        await _profileBox!.flush();
        debugPrint(
            'HIVE_OK: Eventos da Agenda persistidos no disco. Count: ${events.length}');
      } else {
        debugPrint('⚠️ Cannot update agenda: Profile not found for $petName');
      }
    } catch (e, stack) {
      debugPrint('❌ Error updating agenda events: $e\n$stack');
    }
  }

  /// Update Partner Notes (Atomic Patch)
  Future<void> updatePartnerNotes(
      String petName, Map<String, List<Map<String, dynamic>>> notes) async {
    try {
      await init();
      final key = await _resolveEntryKey(petName) ?? _normalizeKey(petName);
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
      final key = await _resolveEntryKey(petName) ?? _normalizeKey(petName);
      final entry = _profileBox?.get(key);

      if (entry != null) {
        final map = deepCastMap(entry);
        final data = deepCastMap(map['data']);

        // CRITICAL: Preserve all keys (especially 'refeicoes' array)
        final List<Map<String, dynamic>> sanitizedPlan = menuPlan.map((item) {
          return Map<String, dynamic>.from(item);
        }).toList();

        data['plano_semanal'] = sanitizedPlan;
        data['orientacoes_gerais'] =
            guidelines ?? data['orientacoes_gerais']; // Preserve if null

        // New date fields for date range logic
        if (startDate != null) data['data_inicio_semana'] = startDate;
        if (endDate != null) data['data_fim_semana'] = endDate;

        map['data'] = data;
        map['last_updated'] = DateTime.now().toIso8601String();

        await _profileBox!.put(key, map);
        await _profileBox!.flush();
        debugPrint(
            'HIVE_OK: Cardápio Semanal persistido. Key: $key. Items: ${sanitizedPlan.length}. Range: $startDate to $endDate');
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
    required String petId,
    required Map<String, dynamic> analysisData,
  }) async {
    try {
      await init();
      final key = await _resolveEntryKey(petId) ?? _normalizeKey(petId);
      final entry = _profileBox?.get(key);

      if (entry != null) {
        final map = Map<String, dynamic>.from(entry as Map);
        final data = Map<String, dynamic>.from(map['data'] as Map);

        // Get existing wound analysis history or create new list
        final List<Map<String, dynamic>> history =
            deepCastMapList(data['wound_analysis_history']);

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
        debugPrint(
            'HIVE_OK: Wound analysis saved for $petId. Total entries: ${history.length}');
      } else {
        debugPrint(
            '⚠️ Cannot save wound analysis: Profile not found for $petId');
      }
    } catch (e, stack) {
      debugPrint('❌ Error saving wound analysis: $e\n$stack');
    }
  }

  /// 🛡️ V170: Save Detailed Health Analysis (Atomic Append)
  Future<void> saveDetailedAnalysis(
      String petId, AnaliseFeridaModel analysis) async {
    try {
      await init();
      final key = await _resolveEntryKey(petId) ?? _normalizeKey(petId);
      var entry = _profileBox?.get(key);

      // 🛡️ SELF-HEALING: Create skeleton if profile is missing during clinical save
      if (entry == null) {
        debugPrint(
            '🚑 [V_FIX] Profile $petId not found. Creating auto-skeleton...');
        final isUuid = petId.contains('-');
        await saveOrUpdateProfile(isUuid ? 'Pet' : petId, {
          'id': isUuid ? petId : const Uuid().v4(),
          'pet_name': isUuid ? 'Pet' : petId,
          'historico_analise_feridas': [analysis.toJson()],
        });
        return;
      }

      if (entry != null) {
        final map = deepCastMap(entry);
        final data = deepCastMap(map['data']);

        // Load existing history
        final List<dynamic> existingRaw =
            data['historico_analise_feridas'] ?? [];
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
        debugPrint(
            '✅ [UUID_OK] Analysis persisted in historico_analise_feridas (Key: $key). Total: ${history.length}');
      }
    } catch (e, stack) {
      debugPrint('❌ Error saving detailed analysis: $e\n$stack');
    }
  }

  /// Delete Wound Analysis from History
  Future<void> deleteWoundAnalysis({
    required String petId,
    required String analysisDate,
  }) async {
    try {
      await init();
      final key = await _resolveEntryKey(petId) ?? _normalizeKey(petId);
      final entry = _profileBox?.get(key);

      if (entry != null) {
        final map = Map<String, dynamic>.from(entry as Map);
        final data = Map<String, dynamic>.from(map['data'] as Map);

        // Get existing wound analysis history
        final List<Map<String, dynamic>> history =
            deepCastMapList(data['wound_analysis_history']);

        // Remove the analysis with matching date
        history.removeWhere((analysis) => analysis['date'] == analysisDate);

        data['wound_analysis_history'] = history;
        map['data'] = data;
        map['last_updated'] = DateTime.now().toIso8601String();

        await _profileBox!.put(key, map);
        await _profileBox!.flush();
        debugPrint(
            'HIVE_OK: Wound analysis deleted (Key: $key). Remaining entries: ${history.length}');
      } else {
        debugPrint(
            '⚠️ Cannot delete wound analysis: Profile not found for key $key');
      }
    } catch (e, stack) {
      debugPrint('❌ Error deleting wound analysis: $e\n$stack');
    }
  }

  /// Add a general analysis to the pet history (Sound, Food, etc.)
  Future<void> addAnalysisToHistory(
      String petId, Map<String, dynamic> analysisData) async {
    try {
      await init();
      final key = await _resolveEntryKey(petId) ?? _normalizeKey(petId);
      final entry = _profileBox?.get(key);

      if (entry != null) {
        final map = deepCastMap(entry);
        final data = deepCastMap(map['data']);

        final List<dynamic> rawHistory =
            data['analysisHistory'] ?? data['analysis_history'] ?? [];
        final List<Map<String, dynamic>> history = [];
        for (var item in rawHistory) {
          if (item is Map) history.add(deepCastMap(item));
        }

        // Prepend local timestamp if missing
        if (analysisData['last_updated'] == null) {
          analysisData['last_updated'] = DateTime.now().toIso8601String();
        }

        history.insert(0, analysisData);

        // Maintain both naming conventions for safety
        data['analysisHistory'] = history;
        data['analysis_history'] = history;

        map['data'] = data;
        map['last_updated'] = DateTime.now().toIso8601String();

        await _profileBox!.put(key, map);
        await _profileBox!.flush();
        debugPrint(
            '✅ [PetProfileService] Analysis history updated for $petId (Key: $key). Total: ${history.length}');
      } else {
        debugPrint(
            '❌ [PetProfileService] Profile NOT FOUND for addAnalysis: "$petId"');
      }
    } catch (e) {
      debugPrint('❌ [PetProfileService] addAnalysisToHistory failed: $e');
    }
  }

  /// Remove a specific analysis from the pet history
  Future<void> removeAnalysisFromHistory(
      String petId, Map<String, dynamic> analysisData) async {
    try {
      await init();
      final key = await _resolveEntryKey(petId) ?? _normalizeKey(petId);
      final entry = _profileBox?.get(key);

      if (entry != null) {
        final map = deepCastMap(entry);
        final data = deepCastMap(map['data']);

        final List<dynamic> rawHistory =
            data['analysisHistory'] ?? data['analysis_history'] ?? [];
        final List<Map<String, dynamic>> history = [];
        for (var item in rawHistory) {
          if (item is Map) history.add(deepCastMap(item));
        }

        // Filter out the item to remove (matching by timestamp is safest)
        final String? targetTime = analysisData['last_updated']?.toString();
        if (targetTime != null) {
          history.removeWhere(
              (item) => item['last_updated']?.toString() == targetTime);
        }

        data['analysisHistory'] = history;
        data['analysis_history'] = history;

        map['data'] = data;
        map['last_updated'] = DateTime.now().toIso8601String();

        await _profileBox!.put(key, map);
        await _profileBox!.flush();
        debugPrint(
            '🗑️ [PetProfileService] Analysis removed for $petId. Remaining: ${history.length}');
      }
    } catch (e) {
      debugPrint('❌ [PetProfileService] removeAnalysisFromHistory failed: $e');
    }
  }
}
