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

class NutritionService {
  static final NutritionService _instance = NutritionService._internal();
  factory NutritionService() => _instance;
  NutritionService._internal();

  static const String boxName = 'box_nutrition_human';
  Box<NutritionHistoryItem>? _box;

  Future<void> init() async {
    if (_box != null && _box!.isOpen) return;
    try {
      if (!Hive.isAdapterRegistered(20)) {
        Hive.registerAdapter(NutritionHistoryItemAdapter());
      }
      _box = await Hive.openBox<NutritionHistoryItem>(boxName);
      debugPrint('✅ NutritionService initialized.');
    } catch (e) {
      debugPrint('❌ Error initializing NutritionService: $e');
    }
  }

  ValueListenable<Box<NutritionHistoryItem>>? get listenable => _box?.listenable();

  Future<void> saveFoodAnalysis(FoodAnalysisModel analysis, File? image) async {
    await init();
    if (_box == null) {
      debugPrint('❌ [NutritionService] saveFoodAnalysis: Box is null, cannot save.');
      return;
    }

    String? savedPath;
    if (image != null) {
      savedPath = await FileUploadService().saveAnalysisImage(
        file: image,
        type: 'food',
        name: analysis.identidade.nome,
      );
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
      recipesList: analysis.receitas.map((r) => {
        'nome': r.nome,
        'instrucoes': r.instrucoes,
        'tempo': r.tempoPreparo,
      }).toList(),
      imagePath: savedPath,
      rawMetadata: analysis.toJson(),
    );

    await _box!.add(item);
    debugPrint('✅ [NutritionService] Saved item: ${item.foodName} to box $_box (Total items: ${_box!.length})');
  }

  Future<List<NutritionHistoryItem>> getHistory() async {
    await init();
    if (_box == null) {
      debugPrint('⚠️ [NutritionService] getHistory: Box is null');
      return [];
    }
    final items = _box!.values.toList();
    debugPrint('📊 [NutritionService] getHistory: Retrieved ${items.length} items from box ${_box!.name}');
    if (items.isNotEmpty) {
       debugPrint('   Last item: ${items.last.foodName} (${items.last.timestamp})');
    }
    return _box!.values.toList().reversed.toList();
  }

  Future<void> deleteHistoryItem(NutritionHistoryItem item) async {
    await item.delete();
    debugPrint('🗑️ [NutritionService] Deleted item: ${item.foodName}');
  }

  /// Get daily sum of calories and macros
  Future<Map<String, double>> getDailySummary(DateTime date) async {
    await init();
    if (_box == null) return {'calories': 0, 'proteins': 0, 'carbs': 0, 'fats': 0};

    final dayItems = _box!.values.where((item) =>
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
}
