import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/analysis_state.dart';
import '../services/gemini_service.dart';
import '../services/groq_api_service.dart';
import '../services/history_service.dart';
import '../services/meal_history_service.dart';
import '../enums/scannut_mode.dart';
import '../utils/prompt_factory.dart';
import '../../features/food/models/food_analysis_model.dart';
import '../../features/plant/models/plant_analysis_model.dart';
import '../../features/pet/models/pet_analysis_result.dart';

// Provider for GeminiService
final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

// StateNotifier for managing analysis state
class AnalysisNotifier extends StateNotifier<AnalysisState> {
  final GeminiService _geminiService;
  final GroqApiService _groqService;
  final HistoryService _historyService;

  AnalysisNotifier(this._geminiService, this._groqService, this._historyService) : super(AnalysisIdle());

  /// Analyze image based on selected mode
  Future<void> analyzeImage({
    required File imageFile,
    required ScannutMode mode,
    String? petName,
    List<String> excludedBases = const [],
  }) async {
    state = AnalysisLoading(
      message: _getLoadingMessage(mode),
      imagePath: imageFile.path,
    );

    try {
      Map<String, dynamic> jsonResponse;
      
      try {
        jsonResponse = await _geminiService.analyzeImage(
          imageFile: imageFile,
          mode: mode,
          excludedBases: excludedBases, // Pass restriction
        );
      } catch (geminiError) {
        debugPrint('⚠️ Gemini falhou, tentando Groq: $geminiError');
        
        // Use Groq as fallback
        final prompt = PromptFactory.getPrompt(mode);
        final groqResponse = await _groqService.analyzeImage(imageFile, prompt);
        
        if (groqResponse == null) {
          throw Exception('analysisErrorAiFailure');
        }

        // Clean up markdown code blocks if present in Groq response
        final cleanJson = groqResponse
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        
        jsonResponse = jsonDecode(cleanJson);
      }
      
      // Save to history
      await _historyService.saveAnalysis(jsonResponse, mode.toString());

      // Parse response based on mode
      switch (mode) {
        case ScannutMode.food:
          final foodAnalysis = FoodAnalysisModel.fromJson(jsonResponse);
          state = AnalysisSuccess<FoodAnalysisModel>(foodAnalysis);
          break;

        case ScannutMode.plant:
          final plantAnalysis = PlantAnalysisModel.fromJson(jsonResponse);
          state = AnalysisSuccess<PlantAnalysisModel>(plantAnalysis);
          break;

        case ScannutMode.petIdentification:
        case ScannutMode.petDiagnosis:
          final petAnalysis = PetAnalysisResult.fromJson({
            ...jsonResponse,
            if (petName != null) 'pet_name': petName,
          });
          
          // Save meal plan ingredients for rotation logic
          if (mode == ScannutMode.petIdentification && 
              petName != null && 
              petAnalysis.planoSemanal.isNotEmpty) {
            final mealService = MealHistoryService();
            await mealService.init();
            
            // Extract base ingredients from meal plan
            final ingredients = <String>{};
            for (var day in petAnalysis.planoSemanal) {
              final meal = day['refeicao'] ?? '';
              // Simple extraction: split by common separators
              final parts = meal.split(RegExp(r'[,;e]'));
              for (var part in parts) {
                final cleaned = part.trim().toLowerCase();
                if (cleaned.isNotEmpty) {
                  // Extract first meaningful word (usually the protein/veggie)
                  final firstWord = cleaned.split(' ').first;
                  if (firstWord.length > 3) ingredients.add(firstWord);
                }
              }
            }
            
            await mealService.saveWeeklyIngredients(petName, ingredients.toList());
            debugPrint('💾 Salvos ${ingredients.length} ingredientes para rotação futura');
          }
          
          state = AnalysisSuccess<PetAnalysisResult>(petAnalysis);
          break;
      }
    } on GeminiException catch (e) {
      // Use user-friendly message key
      state = AnalysisError('analysisErrorAiFailure');
    } on FormatException catch (e) {
      debugPrint('❌ Erro de formato no JSON: $e');
      state = AnalysisError('analysisErrorJsonFormat');
    } catch (e) {
      debugPrint('❌ Erro inesperado: $e');
      state = AnalysisError('analysisErrorUnexpected');
    }
  }

  /// Reset state to idle
  void reset() {
    state = AnalysisIdle();
  }

  String _getLoadingMessage(ScannutMode mode) {
    switch (mode) {
      case ScannutMode.food:
        return 'loadingFood';
      case ScannutMode.plant:
        return 'loadingPlant';
      case ScannutMode.petIdentification:
        return 'loadingPetBreed';
      case ScannutMode.petDiagnosis:
         return 'loadingPetHealth';
    }
  }
}

// Provider for AnalysisNotifier
final analysisNotifierProvider =
    StateNotifierProvider<AnalysisNotifier, AnalysisState>((ref) {
  final geminiService = ref.watch(geminiServiceProvider);
  final groqService = ref.watch(groqApiServiceProvider);
  final historyService = ref.watch(historyServiceProvider);
  return AnalysisNotifier(geminiService, groqService, historyService);
});
