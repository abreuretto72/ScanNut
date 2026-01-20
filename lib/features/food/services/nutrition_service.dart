/// ============================================================================
/// 🚫 COMPONENTE BLINDADO E CONGELADO - NÃO ALTERAR
/// Este módulo de Serviço de Nutrição foi concluído e validado.
/// Nenhuma rotina ou lógica interna deve ser modificada.
/// Data de Congelamento: 29/12/2025
/// ============================================================================

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/nutrition_history_item.dart';
import '../models/food_analysis_model.dart';
import '../../../core/services/file_upload_service.dart';
import '../../../core/services/permanent_backup_service.dart';

import '../../../core/services/media_vault_service.dart';
import '../../../core/services/hive_atomic_manager.dart';

class NutritionService {
  static final NutritionService _instance = NutritionService._internal();
  factory NutritionService() => _instance;
  NutritionService._internal();

  static const String boxName = 'box_nutrition_human';
  Box<NutritionHistoryItem>? _box;

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
             debugPrint('🧹 [NUTRITION SANITIZER] Clearing phantom path for Food "${item.foodName}"');
             
             final newItem = NutritionHistoryItem(
                 id: item.id,
                 timestamp: item.timestamp,
                 foodName: item.foodName,
                 calories: item.calories,
                 proteins: item.proteins,
                 carbs: item.carbs,
                 fats: item.fats,
                 isUltraprocessed: item.isUltraprocessed,
                 biohackingTips: item.biohackingTips,
                 recipesList: item.recipesList,
                 imagePath: null, // CLEAR PATH
                 rawMetadata: item.rawMetadata
             );
             
             await box.put(key, newItem);
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Sanitizer error in NutritionService: $e');
    }
  }

  Future<Box<NutritionHistoryItem>> _ensureBox({HiveCipher? cipher}) async {
    if (!Hive.isAdapterRegistered(20)) {
      Hive.registerAdapter(NutritionHistoryItemAdapter());
    }
    _box = await HiveAtomicManager().ensureBoxOpen<NutritionHistoryItem>(boxName, cipher: cipher);
    return _box!;
  }

  ValueListenable<Box<NutritionHistoryItem>>? get listenable {
    // Best effort: if box implies synchronous access, return listenable.
    // However, listenable is synchronous property.
    // If box is closed, we can't get listenable easily without async.
    // We return _box?.listenable() but _box might be closed.
    if (_box != null && _box!.isOpen) return _box!.listenable();
    return null;
  }

  Future<void> saveFoodAnalysis(FoodAnalysisModel analysis, File? image) async {
    final box = await _ensureBox();
    
    String? savedPath;
    if (image != null) {
      try {
           savedPath = await MediaVaultService().secureClone(
              image,
              MediaVaultService.FOOD_DIR,
              analysis.identidade.nome
           );
           debugPrint('✅ Food Image Secured in Vault: $savedPath');
      } catch (e) {
           debugPrint('❌ Failed to save to Vault (Food): $e');
           // Fallback to legacy if critical, but user wants strict vault.
           // We'll let it be null rather than cache.
      }
    }

    try {
      // 🛠️ DEBUG: Log detailed payload before saving
      debugPrint('🔍 [NutritionService] Preparing to save analysis for: ${analysis.identidade.nome}');
      
      try {
        final recipesListTyped = analysis.receitas.map((r) => {
          'nome': r.nome,
          'instrucoes': r.instrucoes,
          'tempo': r.tempoPreparo,
        }).toList();

        debugPrint('   Recipes Count: ${recipesListTyped.length}');
        if (recipesListTyped.isNotEmpty) {
           debugPrint('   Sample Recipe Type: ${recipesListTyped.first.runtimeType}');
        }

        final item = NutritionHistoryItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          timestamp: DateTime.now(),
          foodName: analysis.identidade.nome,
          calories: analysis.macros.calorias100g,
          proteins: analysis.macros.proteinas,
          carbs: analysis.macros.carboidratosLiquidos,
          fats: analysis.macros.gordurasPerfil,
          isUltraprocessed: analysis.identidade.statusProcessamento.toLowerCase().contains('ultra'),
          biohackingTips: [
            analysis.performance.impactoFocoEnergia,
            analysis.performance.momentoIdealConsumo,
            ...analysis.performance.pontosPositivosCorpo,
          ],
          recipesList: recipesListTyped,
          imagePath: savedPath,
          rawMetadata: analysis.toJson(),
        );

        debugPrint('🔍 [NutritionService] Object created successfully. Attempting to add to Hive Box...');
        debugPrint('   Box Name: $boxName | Is Open: ${box.isOpen}');
        
        await box.add(item);
        
        debugPrint('✅ [NutritionService] Saved item: ${item.foodName} to box (Total items: ${box.length})');
        // Force verify save
        debugPrint('   [Verify] Box keys: ${box.keys.toList()}');
        
        // 🔄 Trigger automatic permanent backup
        PermanentBackupService().createAutoBackup().then((_) {
          debugPrint('💾 Backup permanente atualizado após salvar comida');
        }).catchError((e) {
          debugPrint('⚠️ Backup automático falhou: $e');
        });

      } catch (innerError, innerStack) {
         debugPrint('❌ [NutritionService] HIVE WRITE ERROR: $innerError');
         debugPrint('   Item structure dump:');
         // Attempt to isolate the faulty field by logging types
         debugPrint('   - recipesList Type: ${analysis.receitas.runtimeType}');
         debugPrint('   - rawMetadata Type: ${analysis.toJson().runtimeType}'); 
         debugPrint(innerStack.toString());
         rethrow;
      }

    } catch (e, stack) {
      debugPrint('❌ [NutritionService] CRITICAL ERROR SAVING: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  Future<List<NutritionHistoryItem>> getHistory() async {
    final box = await _ensureBox();
    final items = box.values.toList();
    debugPrint('📊 [NutritionService] getHistory: Retrieved ${items.length} items from box ${box.name}');
    if (items.isNotEmpty) {
       debugPrint('   Last item: ${items.last.foodName} (${items.last.timestamp})');
    }
    return box.values.whereType<NutritionHistoryItem>().toList().reversed.toList();
  }

  Future<void> deleteHistoryItem(NutritionHistoryItem item) async {
    await item.delete();
    debugPrint('🗑️ [NutritionService] Deleted item: ${item.foodName}');
  }

  /// Get daily sum of calories and macros
  Future<Map<String, double>> getDailySummary(DateTime date) async {
    final box = await _ensureBox();

    final dayItems = box.values.where((item) =>
        item.timestamp.year == date.year &&
        item.timestamp.month == date.month &&
        item.timestamp.day == date.day);

    double cal = 0, prot = 0, carb = 0, fat = 0;
    
    for (var item in dayItems) {
      cal += item.calories;
      prot += _extractValue(item.proteins);
      carb += _extractValue(item.carbs);
      fat += _extractValue(item.fats);
    }

    return {
      'calories': cal,
      'proteins': prot,
      'carbs': carb,
      'fats': fat,
    };
  }

  double _extractValue(String text) {
    // Basic regex to find numbers in strings like "10g" or "10.5 g"
    final match = RegExp(r'(\d+[.,]?\d*)').firstMatch(text);
    if (match != null) {
      return double.tryParse(match.group(1)!.replaceAll(',', '.')) ?? 0;
    }
    return 0;
  }

  Future<void> clearAllFood() async {
    final box = await _ensureBox();
    debugPrint('🔥 [NutritionService] Clearing all food history from $boxName...');
    await box.clear();
    // await box.compact(); // Optional optimization
    debugPrint('✅ [NutritionService] All food history cleared.');
  }
}
