import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/recipe_history_item.dart';
import '../models/food_analysis_model.dart'; // For ReceitaRapida
import '../../../core/services/hive_atomic_manager.dart';

class RecipeService {
  static final RecipeService _instance = RecipeService._internal();
  factory RecipeService() => _instance;
  RecipeService._internal();

  static const String boxName = 'recipe_history_box';
  Box<RecipeHistoryItem>? _box;

  Future<void> _initService() async {
    // ⚠️ Deprecated method call, keeping signature to match view_file but logic is inside init() below
  }
 
  Future<void> init() async {
    debugPrint('🔧 [RecipeService] Init called.');
    
    try {
      if (!Hive.isAdapterRegistered(31)) {
        debugPrint('🔧 [RecipeService] Registering Adapter(31)...');
        Hive.registerAdapter(RecipeHistoryItemAdapter());
      }

      debugPrint('🔧 [RecipeService] Ensuring box "$boxName" is open...');
      _box = await HiveAtomicManager().ensureBoxOpen<RecipeHistoryItem>(boxName);
      
      debugPrint('✅ [RecipeService] Box "$boxName" opened.');
    } catch (e) {
      debugPrint('❌ [RecipeService] Init failed. Attempting SELF-HEALING (Recreate Box)... Error: $e');
      try {
        await HiveAtomicManager().recreateBox<RecipeHistoryItem>(boxName);
        _box = await HiveAtomicManager().ensureBoxOpen<RecipeHistoryItem>(boxName);
        debugPrint('✅ [RecipeService] SELF-HEALING SUCCESS.');
      } catch (e2) {
         debugPrint('💀 [RecipeService] SELF-HEALING FAILED: $e2');
         rethrow;
      }
    }
  }

  Future<void> saveAuto(List<ReceitaRapida> recipes, String foodName) async {
    if (_box == null || !_box!.isOpen) await init();
    
    for (var recipe in recipes) {
      // Check for duplication (simple check by name + foodName)
      final exists = _box!.values.any((item) => 
          item.foodName == foodName && item.recipeName == recipe.nome);
      
      if (!exists) {
        final item = RecipeHistoryItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          foodName: foodName,
          recipeName: recipe.nome,
          instructions: recipe.instrucoes,
          prepTime: recipe.tempoPreparo,
          timestamp: DateTime.now(),
          imagePath: null,
        );
        final key = await _box!.add(item);
        debugPrint('🍳 [RecipeService] Auto-saved recipe: ${recipe.nome}');
        
        // 🚀 Background Image Generation
        _generateImageForRecipe(key, item);
      }
    }
  }

  Future<void> _generateImageForRecipe(dynamic key, RecipeHistoryItem item) async {
    // ⚠️ DISABLED FOR PERFORMANCE OPTIMIZATION (User Request Step 1942)
    debugPrint('⚡ [RecipeService] Skipping Image Generation (Optimization Enabled)');
    return;
    /*
    // 1. Pro Entitlement Check - DIAGNÓSTICO DE CONEXÃO
    final isPro = await SubscriptionService().isPro();
    if (!isPro) {
       debugPrint('🔒 [RecipeService] User is not Pro. Skipping AI image generation.');
       return;
    }
    // ... [Rest of code commented out]
    */
  }

  Future<void> _updateItemWithImage(dynamic key, RecipeHistoryItem oldItem, String path) async {
    if (_box == null || !_box!.isOpen) return;

    final newItem = RecipeHistoryItem(
      id: oldItem.id,
      foodName: oldItem.foodName,
      recipeName: oldItem.recipeName,
      instructions: oldItem.instructions,
      prepTime: oldItem.prepTime,
      timestamp: oldItem.timestamp,
      imagePath: path,
    );
    
    await _box!.put(key, newItem);
  }

  List<RecipeHistoryItem> getAllRecipes() {
    if (_box == null || !_box!.isOpen) return [];
    final list = _box!.values.toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Newest first
    return list;
  }

  Future<void> clearHistory() async {
    if (_box == null || !_box!.isOpen) await init();
    await _box!.clear();
  }
  
  Future<void> deleteRecipe(RecipeHistoryItem item) async {
    await item.delete();
  }
}
