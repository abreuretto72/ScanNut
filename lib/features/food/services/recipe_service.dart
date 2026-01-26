import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/recipe_history_item.dart';
import '../models/recipe_suggestion.dart';
import '../models/food_analysis_model.dart';
import '../../../core/services/hive_atomic_manager.dart';
import '../../../core/services/gemini_service.dart';
import 'food_logger.dart';
import '../data/emergency_recipes.dart';
import 'food_remote_config_repository.dart';

class RecipeService {
  static final RecipeService _instance = RecipeService._internal();
  factory RecipeService() => _instance;
  RecipeService._internal();

  static const String boxName = 'recipe_history_box';
  Box<RecipeHistoryItem>? _box;

  Future<List<RecipeSuggestion>> generateRecipeSuggestions(String foodName) async {
    // 1. Fetch Remote Config (Dynamic Model Selection)
    final remoteConfig = await FoodRemoteConfigRepository().fetchRemoteConfig();
    final modelName = remoteConfig.activeModel;
    final qty = remoteConfig.recipesPerRequest;

    FoodLogger().logInfo('using_remote_model', data: {
      'model': modelName,
      'endpoint': remoteConfig.apiEndpoint,
      'qty': qty
    });
    FoodLogger().traceRecipeGenerationValues(foodName, qty);
    final Stopwatch stopwatch = Stopwatch()..start();

    try {
      final prompt = "Sugira $qty receitas criativas e saudáveis usando: $foodName. "
          "Retorne um JSON array com objetos: 'name', 'instructions', 'prep_time', 'calories', 'difficulty', 'justification'. "
          "Sempre varie as sugestões.";
      
      FoodLogger().logDebug('sending_ai_prompt', data: {'prompt_preview': prompt.substring(0, 50)});
      
      // 1. Request to Dynamic Model (Multiverso API)
      final result = await GeminiService().generateWithModel(
        prompt: prompt,
        model: modelName,
        apiEndpoint: remoteConfig.apiEndpoint,
      );
      
      stopwatch.stop();
      FoodLogger().logInfo('ai_response_received', data: {'duration_ms': stopwatch.elapsedMilliseconds});

      // 2. Parsing Logic
      final cleanJson = result.replaceAll('```json', '').replaceAll('```', '').trim();
      FoodLogger().logDebug('raw_json_payload', data: {'payload': cleanJson});
      
      final List<dynamic> list = jsonDecode(cleanJson);
      
      final suggestions = list.map((e) => RecipeSuggestion.fromJson(e, foodName: foodName)).toList();
      
      // 🛡️ [Lei de Ferro] Validação de Integridade
      final validSuggestions = suggestions.where((r) => r.isValid).toList();
      
      if (validSuggestions.isEmpty) {
        FoodLogger().logError('no_valid_recipes_from_ai', error: 'Response failed validation');
        throw Exception("Invalid AI Response"); // Trigger catch block for fallback
      }

      FoodLogger().logInfo('recipes_parsed_success', data: {'count': validSuggestions.length});
      
      return validSuggestions;
    } catch (e, stack) {
      stopwatch.stop();
      FoodLogger().logError('recipe_generation_failed_using_fallback', error: e, stackTrace: stack);
      
      // 🛡️ FALLBACK: "Lei de Ferro" Protection
      FoodLogger().logInfo('local_fallback_triggered', data: {'reason': 'ai_instability'});
      final fallback = EmergencyRecipes.getFallback(foodName);
      
      // Throw special exception to signal UI
      throw RecipeFallbackException(fallback);
    }
  }

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
      _box =
          await HiveAtomicManager().ensureBoxOpen<RecipeHistoryItem>(boxName);

      debugPrint('✅ [RecipeService] Box "$boxName" opened.');
    } catch (e) {
      debugPrint(
          '❌ [RecipeService] Init failed. Attempting SELF-HEALING (Recreate Box)... Error: $e');
      try {
        await HiveAtomicManager().recreateBox<RecipeHistoryItem>(boxName);
        _box =
            await HiveAtomicManager().ensureBoxOpen<RecipeHistoryItem>(boxName);
        debugPrint('✅ [RecipeService] SELF-HEALING SUCCESS.');
      } catch (e2) {
        debugPrint('💀 [RecipeService] SELF-HEALING FAILED: $e2');
        rethrow;
      }
    }
  }

  Future<void> saveAuto(List<RecipeSuggestion> recipes, String foodName) async {
    if (_box == null || !_box!.isOpen) await init();

    // 🛡️ GARANTIA DE DADOS: Se a lista estiver vazia ou o primeiro item for inválido,
    // garantimos uma vaga com EmergencyRecipes.
    List<RecipeSuggestion> processedRecipes = List.from(recipes);
    if (processedRecipes.isEmpty || !processedRecipes.first.isValid) {
      final fallbacks = EmergencyRecipes.getFallback(foodName);
      if (processedRecipes.isEmpty) {
        processedRecipes.addAll(fallbacks);
      } else {
        processedRecipes[0] = fallbacks.first;
      }
    }

    for (var recipe in processedRecipes) {
      // 🛡️ Validação Final: Se mesmo após o processamento houver algo nulo (improvável), skip.
      if (!recipe.isValid) continue;
      
      // Check for duplication (simple check by name + foodName)
      final exists = _box!.values.any((item) =>
          item.foodName == foodName && item.recipeName == recipe.name);

      if (!exists) {
        final item = RecipeHistoryItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          foodName: foodName,
          recipeName: recipe.name,
          instructions: recipe.instructions,
          prepTime: recipe.prepTime,
          justification: recipe.justification,
          difficulty: recipe.difficulty,
          calories: recipe.calories,
          timestamp: DateTime.now(),
          imagePath: null,
        );
        final key = await _box!.add(item);
        debugPrint('🍳 [RecipeService] Auto-saved recipe: ${recipe.name}');

        // 🚀 Background Image Generation
        _generateImageForRecipe(key, item);
      }
    }
  }

  Future<void> _generateImageForRecipe(
      dynamic key, RecipeHistoryItem item) async {
    // ⚠️ DISABLED FOR PERFORMANCE OPTIMIZATION (User Request Step 1942)
    debugPrint(
        '⚡ [RecipeService] Skipping Image Generation (Optimization Enabled)');
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

  Future<void> _updateItemWithImage(
      dynamic key, RecipeHistoryItem oldItem, String path) async {
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

class RecipeFallbackException implements Exception {
  final List<RecipeSuggestion> fallbackRecipes;
  RecipeFallbackException(this.fallbackRecipes);
}
