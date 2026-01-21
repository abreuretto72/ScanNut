import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/analysis_state.dart';
import '../services/gemini_service.dart';
import '../services/groq_api_service.dart';
import '../services/meal_history_service.dart';
import '../enums/scannut_mode.dart';
import '../utils/prompt_factory.dart';
import '../../features/food/models/food_analysis_model.dart';
import '../../features/plant/models/plant_analysis_model.dart';
import '../../features/pet/models/pet_analysis_result.dart';
import '../services/image_deduplication_service.dart';

// Provider for GeminiService
final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

// StateNotifier for managing analysis state
class AnalysisNotifier extends StateNotifier<AnalysisState> {
  final GeminiService _geminiService;
  final GroqApiService _groqService;

  AnalysisNotifier(this._geminiService, this._groqService) : super(AnalysisIdle());

  /// Analyze image based on selected mode
  Future<AnalysisState> analyzeImage({
    required File imageFile,
    required ScannutMode mode,
    String? petName,
    String? petId, // 🛡️ UUID Link
    List<String> excludedBases = const [],
    String locale = 'pt', // Default to Portuguese
    Map<String, String>? contextData, // 🛡️ NEW: Context Injection
  }) async {
    state = AnalysisLoading(
      message: _getLoadingMessage(mode),
      imagePath: imageFile.path,
    );

    try {
      // 🛡️ [V180] Image Deduplication Check
      final deduplication = ImageDeduplicationService();
      final hash = await deduplication.calculateHash(imageFile);
      
      if (hash.isNotEmpty) {
          final existing = await deduplication.checkDeduplication(hash);
          if (existing != null) {
              debugPrint('🚫 [DEDUPLICATION] Image already analyzed. Stopping.');
              state = AnalysisError('error_image_already_analyzed');
              return state;
          }
      }
      Map<String, dynamic> jsonResponse;
      // 3. Alinhamento de Idioma (Locale)
      String normalizedLocale = locale;
      if (locale.toLowerCase().startsWith('en')) {
        normalizedLocale = 'en';
      }

      try {
        jsonResponse = await _geminiService.analyzeImage(
          imageFile: imageFile,
          mode: mode,
          excludedBases: excludedBases, 
          locale: normalizedLocale,
          contextData: contextData, // 🛡️ Pass context
        );
      } on GeminiException catch (geminiError) { // Changed catch type to GeminiException for clarity
        debugPrint('⚠️ Gemini falhou, tentando Groq: $geminiError');
        
        // 1. Aumento de Timeout e Retry no Fallback
        int retries = 1;
        String? groqResponse;
        
        while (retries >= 0) {
          try {
            final prompt = PromptFactory.getPrompt(mode, locale: normalizedLocale, contextData: contextData);
            groqResponse = await _groqService.analyzeImage(imageFile, prompt);
            if (groqResponse != null) break;
          } catch (e) {
            debugPrint('⚠️ Groq attempt failed (Retries left: $retries): $e');
            if (retries == 0) rethrow;
          }
          retries--;
          if (retries >= 0) await Future.delayed(const Duration(seconds: 2));
        }
        
        if (groqResponse == null) {
          throw Exception('analysisErrorAiFailure');
        }

        // 2. Validação do JSON (Sanitização Robusta)
        String cleanJson = groqResponse;
        if (cleanJson.contains('```json')) {
          cleanJson = cleanJson.split('```json').last.split('```').first.trim();
        } else if (cleanJson.contains('```')) {
          cleanJson = cleanJson.split('```').last.split('```').first.trim();
        } else {
          cleanJson = cleanJson.trim();
        }
        
        try {
          jsonResponse = jsonDecode(cleanJson);
        } catch (e) {
          debugPrint('❌ Critical JSON Parse Error on fallback: $e');
          debugPrint('Raw Content: $cleanJson');
          throw const FormatException('Invalid JSON format from fallback');
        }
      }
      
      // 4. Verificação de Erro na Resposta (Não é Pet/Planta/Comida)
      if (jsonResponse.containsKey('error')) {
        final errorVal = jsonResponse['error'].toString().toLowerCase();
        if (errorVal.contains('not_pet') || 
            errorVal.contains('not_food') || 
            errorVal.contains('not_plant')) {
          state = AnalysisError('analysisErrorInvalidCategory');
          return state;
        }
        if (errorVal.contains('not_detected')) {
          state = AnalysisError('analysisErrorNotDetected');
          return state;
        }
      }

      // 🛡️ SHIELDING: Enforce Source of Truth for species/breed
      if (contextData != null && (contextData.containsKey('species') || contextData.containsKey('breed'))) {
          final knownSpecies = contextData['species'];
          final knownBreed = contextData['breed'];

          // Phase 4: Debug Logging of restricted fields
          final aiSpecies = jsonResponse['species'] ?? jsonResponse['identification']?['species'];
          final aiBreed = jsonResponse['breed'] ?? jsonResponse['identification']?['breed'];
          
          if (aiSpecies != null && aiSpecies.toString().toLowerCase() != 'n/a' && aiSpecies != knownSpecies) {
               debugPrint('🛡️ DEBUG: [SOURCE OF TRUTH BREACH] AI returned species: $aiSpecies');
          }
          if (aiBreed != null && aiBreed.toString().toLowerCase() != 'n/a' && aiBreed != knownBreed) {
               debugPrint('🛡️ DEBUG: [SOURCE OF TRUTH BREACH] AI returned breed: $aiBreed');
          }
          
          if (knownSpecies != null) jsonResponse['species'] = knownSpecies;
          if (knownBreed != null) jsonResponse['breed'] = knownBreed;
          
          if (jsonResponse.containsKey('identification') && jsonResponse['identification'] is Map) {
              if (knownSpecies != null) jsonResponse['identification']['species'] = knownSpecies;
              if (knownBreed != null) jsonResponse['identification']['breed'] = knownBreed;
          }
      }

      // 🛡️ V230: Master History Save moved to UI/Result Screens for better context injection
      // (Avoids duplicate entries with identical timestamps)


      // Parse response based on mode
      switch (mode) {
        case ScannutMode.food:
          final foodAnalysis = FoodAnalysisModel.fromJson(jsonResponse);
          
          // AUTO-SAVE: Removed to prevent duplication (Handled by HomeView)
          // debugPrint('✅ [AnalysisNotifier] Food Analysis Ready.');

          state = AnalysisSuccess<FoodAnalysisModel>(foodAnalysis);
          
          // 🛡️ [V180] Register hash on success
          if (hash.isNotEmpty) {
              await deduplication.registerProcessedImage(
                hash: hash,
                type: mode.toString(),
                extraMetadata: {
                  'timestamp': DateTime.now().toIso8601String(),
                  'mode': mode.toString(),
                }
              );
          }
          break;

        case ScannutMode.plant:
          final plantAnalysis = PlantAnalysisModel.fromJson(jsonResponse);
          state = AnalysisSuccess<PlantAnalysisModel>(plantAnalysis);
          
          // 🛡️ [V180] Register hash on success
          if (hash.isNotEmpty) {
              await deduplication.registerProcessedImage(
                hash: hash,
                type: mode.toString(),
                extraMetadata: {
                  'timestamp': DateTime.now().toIso8601String(),
                  'mode': mode.toString(),
                }
              );
          }
          break;

        case ScannutMode.petIdentification:
        case ScannutMode.petDiagnosis:
          final petAnalysis = PetAnalysisResult.fromJson({
            ...jsonResponse,
            if (petName != null) 'pet_name': petName,
            if (petId != null) 'pet_id': petId,
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
          
          // 🛡️ [V180] Register hash on success
          if (hash.isNotEmpty) {
              await deduplication.registerProcessedImage(
                hash: hash,
                type: mode.toString(),
                petId: petId,
                petName: petName,
                extraMetadata: {
                  'timestamp': DateTime.now().toIso8601String(),
                  'mode': mode.toString(),
                }
              );
          }
          break;

        default:
          throw Exception('Modo não suportado: $mode');
      }
      
      return state;
    } on GeminiException {
      // Use user-friendly message key
      state = AnalysisError('analysisErrorAiFailure');
      return state;
    } on FormatException catch (e) {
      debugPrint('❌ Erro de formato no JSON: $e');
      state = AnalysisError('analysisErrorJsonFormat');
      return state;
    } catch (e, stack) {
      if (mode == ScannutMode.plant) {
        debugPrint('Plant Analysis Error: $e');
      }
      debugPrint('DEBUG ERROR: $e');
      debugPrint('STACKTRACE: $stack');
      
      final msg = e.toString().toLowerCase();
      if (msg.contains('400') || msg.contains('bad request') || msg.contains('invalid category')) {
        state = AnalysisError('analysisErrorInvalidCategory');
      } else {
        state = AnalysisError('analysisErrorUnexpected');
      }
    }
    return state;
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
      case ScannutMode.petVisualAnalysis:
      case ScannutMode.petDocumentOCR:
         return 'loadingPetHealth';
      case ScannutMode.petStoolAnalysis:
         return 'loadingPetStool';
      default:
         return 'loadingGeneric';
    }
  }
}

// Provider for AnalysisNotifier
final analysisNotifierProvider =
    StateNotifierProvider<AnalysisNotifier, AnalysisState>((ref) {
  final geminiService = ref.watch(geminiServiceProvider);
  final groqService = ref.watch(groqApiServiceProvider);
  return AnalysisNotifier(geminiService, groqService);
});
