/// ============================================================================
/// 🚫 SERVIÇO BLINDADO E CONGELADO - NÃO ALTERAR
/// Este serviço gerencia a persistência e histórico de análises botânicas.
/// Box: box_plants_history (Registros de plantas e diagnósticos)
/// Data de Congelamento: 01/01/2026
/// ============================================================================

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/botany_history_item.dart';
import '../models/plant_analysis_model.dart';
import '../../../core/services/file_upload_service.dart';
import '../../../core/services/permanent_backup_service.dart';
import '../../../core/services/media_vault_service.dart';

class BotanyService {
  static final BotanyService _instance = BotanyService._internal();
  factory BotanyService() => _instance;
  BotanyService._internal();

  static const String boxName = 'box_plants_history';
  Box<BotanyHistoryItem>? _box;

  /// Guaranteed Opening Pattern
  Future<Box<BotanyHistoryItem>> _ensureBox({HiveCipher? cipher}) async {
    if (_box != null && _box!.isOpen) return _box!;
    try {
      if (!Hive.isAdapterRegistered(21)) {
        Hive.registerAdapter(BotanyHistoryItemAdapter());
      }
      _box = await Hive.openBox<BotanyHistoryItem>(boxName, encryptionCipher: cipher);
      debugPrint('✅ BotanyService: box_plants_history initialized (Secure).');
      return _box!;
    } catch (e) {
      debugPrint('❌ Error initializing Secure BotanyService: $e');
      rethrow;
    }
  }

  Future<void> init({HiveCipher? cipher}) async {
    await _ensureBox(cipher: cipher);
    // 🧹 GLOBAL RESET: Limpeza de Paths Órfãos (Cache/Temp)
    await _sanitizeOrphanedCachePaths();
  }

  /// 🧹 ONE-TIME DISINFECTION: Removes paths pointing to volatile cache
  Future<void> _sanitizeOrphanedCachePaths() async {
    try {
      final box = await _ensureBox();
      final keys = box.keys.toList();
      
      for (var key in keys) {
        final item = box.get(key);
        if (item != null) {
          String? path = item.imagePath;
          if (path != null && (path.contains('cache') || path.contains('temp'))) {
             debugPrint('🧹 [BOTANY SANITIZER] Clearing phantom path for Plant "${item.plantName}"');
             
             final newItem = BotanyHistoryItem(
                 id: item.id,
                 timestamp: item.timestamp,
                 plantName: item.plantName,
                 healthStatus: item.healthStatus,
                 diseaseDiagnosis: item.diseaseDiagnosis,
                 recoveryPlan: item.recoveryPlan,
                 survivalSemaphore: item.survivalSemaphore,
                 lightWaterSoilNeeds: item.lightWaterSoilNeeds,
                 fengShuiTips: item.fengShuiTips,
                 imagePath: null, // CLEAR PATH
                 toxicityStatus: item.toxicityStatus,
                 locale: item.locale,
                 rawMetadata: item.rawMetadata
             );
             
             await box.put(key, newItem);
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Sanitizer error in BotanyService: $e');
    }
  }

  ValueListenable<Box<BotanyHistoryItem>>? get listenable => _box?.listenable();

  Future<void> savePlantAnalysis(PlantAnalysisModel analysis, File? image, {String? locale}) async {
    final box = await _ensureBox();

    String? savedPath;
    if (image != null) {
      try {
        savedPath = await MediaVaultService().secureClone(
          image, 
          MediaVaultService.BOTANY_DIR
        );
        debugPrint('✅ Plant saved to Vault: $savedPath');
      } catch (e) {
        debugPrint('⚠️ Vault save failed for plant, trying legacy: $e');
        savedPath = await FileUploadService().saveAnalysisImage(
          file: image,
          type: 'plant',
          name: analysis.identificacao.nomeCientifico,
        );
      }
    }

    // Determine toxicity status from analysis keywords
    String tox = 'safe';
    final toxInfo = analysis.segurancaBiofilia.segurancaDomestica.toString().toLowerCase();
    if (toxInfo.contains('toxic') || toxInfo.contains('tóxica') || toxInfo.contains('perigo') || toxInfo.contains('poisonous')) {
      tox = 'toxic';
    } 
    
    // Specific pet check
    final isToxicToPets = analysis.segurancaBiofilia.segurancaDomestica['is_toxic_to_pets'] == true || 
                          analysis.segurancaBiofilia.segurancaDomestica['toxica_para_pets'] == true;
    
    if (isToxicToPets) {
      tox = 'harmful_pets';
    }

    // Determine survival semaphore
    String semaphore = 'verde';
    final cond = analysis.saude.condicao.toLowerCase();
    final urg = analysis.saude.urgencia.toLowerCase();
    
    if (cond.contains('crítico') || cond.contains('critical') || urg == 'high') {
      semaphore = 'vermelho';
    } else if (cond.contains('atenção') || cond.contains('attention') || urg == 'medium' || cond.contains('sick') || cond.contains('doente')) {
      semaphore = 'amarelo';
    }

    final item = BotanyHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      plantName: analysis.identificacao.nomesPopulares.isNotEmpty 
          ? analysis.identificacao.nomesPopulares.first 
          : analysis.identificacao.nomeCientifico,
      healthStatus: analysis.saude.condicao,
      diseaseDiagnosis: analysis.saude.detalhes != 'N/A' ? analysis.saude.detalhes : null,
      recoveryPlan: analysis.saude.planoRecuperacao,
      survivalSemaphore: semaphore,
      lightWaterSoilNeeds: {
        'luz': analysis.sobrevivencia.luminosidade['type']?.toString() ?? analysis.sobrevivencia.luminosidade['tipo']?.toString() ?? 'N/A',
        'agua': analysis.sobrevivencia.regimeHidrico['frequency']?.toString() ?? analysis.sobrevivencia.regimeHidrico['frequencia']?.toString() ?? 'N/A',
        'solo': analysis.sobrevivencia.soloENutricao['soil_composition']?.toString() ?? analysis.sobrevivencia.soloENutricao['tipo_solo']?.toString() ?? 'N/A',
      },
      fengShuiTips: analysis.lifestyle.simbolismo,
      imagePath: savedPath,
      toxicityStatus: tox,
      locale: locale,
      rawMetadata: _sanitizeMetadata(analysis.toJson(), locale),
    );

    try {
      await box.add(item);
      debugPrint("✅ Gravado no histórico com sucesso! ID: ${item.id}");
      
      // 🔄 Trigger automatic permanent backup
      PermanentBackupService().createAutoBackup().then((_) {
        debugPrint('💾 Backup permanente atualizado após salvar planta');
      }).catchError((e) {
        debugPrint('⚠️ Backup automático falhou: $e');
      });
    } catch (e, stack) {
      debugPrint("❌ ERRO AO GRAVAR: $e");
      debugPrint("TRACE: $stack");
      rethrow;
    }
  }

  Future<List<BotanyHistoryItem>> getHistory() async {
    final box = await _ensureBox();
    final list = box.values.whereType<BotanyHistoryItem>().toList().reversed.toList();
    debugPrint("🔍 Itens encontrados no banco: ${list.length}");
    return list;
  }

  /// Quick check for toxicity alerts
  Future<List<BotanyHistoryItem>> getToxicPlants() async {
    final box = await _ensureBox();
    return box.values.where((p) => p.toxicityStatus != 'safe').toList();
  }

  Future<void> clearAll() async {
    final box = await _ensureBox();
    await box.clear();
    debugPrint('🧹 Botany history cleared');
  }

  /// Sanitizes metadata to remove common Portuguese leakages if locale is English
  Map<String, dynamic> _sanitizeMetadata(Map<String, dynamic> json, String? locale) {
    if (locale == null || !locale.toLowerCase().startsWith('en')) {
      return json;
    }

    // Convert map to string, replace terms, and convert back
    // This is safer than deep recursion for simple term replacement
    String jsonString = json.toString();
    
    // Replacement Dictionary (Common Leaks)
    final replacements = {
      'Saudável': 'Healthy',
      'Doente': 'Sick',
      'Manchas': 'Spots',
      'Rega': 'Watering',
      'Luz Direta': 'Full Sun',
      'Sombra': 'Shade',
      'Meia Sombra': 'Partial Shade',
      'Tóxica': 'Toxic',
      'Perigo': 'Danger',
      'Não': 'No',
      'Sim': 'Yes',
      'Vermelho': 'Red',
      'Amarelo': 'Yellow',
      'Verde': 'Green',
      'Alta': 'High',
      'Média': 'Medium',
      'Baixa': 'Low',
    };

    replacements.forEach((pt, en) {
      // Basic string replacement that doesn't break JSON structure
      // We look for values wrapped in quotes theoretically, but since we are working
      // with a stringified Map (not JSON string), we are careful.
      // Ideally we would recurse, but this is a quick safety net.
      jsonString = jsonString.replaceAll(pt, en);
    });

    // Note: Since we are doing string manipulation on the .toString() of a Map,
    // we cannot easily convert it back to a Map.
    // So instead, we will use a recursive approach to be type-safe.
    return _recursiveSanitize(json, replacements);
  }

  dynamic _recursiveSanitize(dynamic data, Map<String, String> replacements) {
    if (data is String) {
      String result = data;
      replacements.forEach((pt, en) {
        if (result.contains(pt)) {
           result = result.replaceAll(pt, en);
        }
      });
      return result;
    } else if (data is Map<String, dynamic>) {
      final newMap = <String, dynamic>{};
      data.forEach((key, value) {
        newMap[key] = _recursiveSanitize(value, replacements);
      });
      return newMap;
    } else if (data is List) {
      return data.map((e) => _recursiveSanitize(e, replacements)).toList();
    }
    return data;
  }
}
