import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/gemini_service.dart';
import '../../pet/models/weekly_meal_plan.dart';
import '../../pet/services/meal_plan_service.dart';
import '../../pet/services/pet_shopping_list_service.dart';
import '../../pet/models/meal_plan_request.dart';
import '../../../core/utils/json_cast.dart';



final petMenuGeneratorProvider = Provider<PetMenuGeneratorService>((ref) {
  final geminiService = ref.watch(geminiServiceProvider);
  return PetMenuGeneratorService(geminiService);
});

class PetMenuGeneratorService {
  final GeminiService _geminiService;
  
  PetMenuGeneratorService(this._geminiService);

  Future<void> generateAndSave(MealPlanRequest request) async {
    // 1. VALIDATION (Blindada)
    try {
      request.validateOrThrow();
      
      // 🛡️ ARCHITECTURE BLINDAGE: Source Enforcement
      if (request.source != 'PetProfile') {
          debugPrint('🚨 [PetMenu] SECURITY_BLOCK: Unauthorized generation source: ${request.source}');
          return; // Block execution
      }
    } catch (e) {
      debugPrint('🚨 [PetMenu] Validation failed: $e');
      rethrow;
    }

    // 2. LOGIC
    DateTime chunkStart = request.startDate;
    int safeGuard = 0;
    
    // Construct diet label using localized version or note
    String dietLabel = request.dietType.toString().split('.').last; // Logic ID
    if (request.dietType == PetDietType.other) {
       dietLabel = "Other: ${request.otherNote ?? ''}"; 
    }

    try {
      while (chunkStart.isBefore(request.endDate) && safeGuard < 10) {
         safeGuard++;
         DateTime chunkEnd = chunkStart.add(const Duration(days: 6));
         if (chunkEnd.isAfter(request.endDate)) {
           chunkEnd = request.endDate;
         }

         debugPrint('🦴 [PetMenu] GENERATING CHUNK: $chunkStart to $chunkEnd');
         debugPrint('📊 [PetMenu] REQUEST_PAYLOAD: ${request.toJson()}');
         
         await _generateSingleWeek(
           request.petId, 
           request.profileData, 
           chunkStart, 
           request.locale, 
           dietLabel,
           request.dietType
         );

         chunkStart = chunkStart.add(const Duration(days: 7));
      }
    } catch (e) {
      debugPrint('🚨 [PetMenu] GENERATION_ERROR: $e');
      throw Exception('Não foi possível gerar o cardápio agora. Tente novamente.');
    }
  }


  Future<void> _generateSingleWeek(
    String petId, 
    Map<String, dynamic> profileData, 
    DateTime startOfWeek, 
    String locale,
    String dietLabel,
    PetDietType dietType
  ) async {

      final species = profileData['species'] ?? 'Dog';
      final breed = profileData['breed'] ?? 'Unknown';
      final weight = profileData['weight']?.toString() ?? 'Unknown';
      final age = profileData['age']?.toString() ?? 'Unknown';
      final allergies = (profileData['alergias_conhecidas'] as List?)?.join(', ') ?? 'None';
      final preferences = (profileData['preferencias'] as List?)?.join(', ') ?? 'None';
      
      final prompt = """
      Act as a Veterinary Nutritionist. Generate a 7-day Meal Plan for a Pet.
      
      CONTEXT:
      - Species: $species
      - Breed: $breed
      - Weight: $weight kg
      - Age: $age
      - Allergies: $allergies
      - Preferences: $preferences
      - DIET REQUIREMENT: $dietLabel
      - Locale: $locale
      
      REQUIREMENTS:
      1. Plan for 7 days (Monday to Sunday).
      2. STRICTLY follow the Diet Requirement ($dietLabel).
      3. Provide nutritional metadata.
      4. Provide a consolidated SHOPPING LIST.
      5. Language: Strict $locale.
      6. Output JSON ONLY.
      
      JSON STRUCTURE:
      {
        "diet_type": "$dietLabel",
        "nutritional_goal": "...",
        "daily_meals": [
           { 
             "day_of_week": 1, 
             "meals": [ 
                { "time": "08:00", "title": "...", "description": "...", "quantity": "...", "benefit": "..." } 
             ]
           }
        ],
        "shopping_list": [
           { "category": "Proteins", "item": "Chicken Breast", "quantity": "1kg" }
        ],
        "metadata": {
           "protein": "High", "fat": "Med", "fiber": "Low", "micronutrients": "Balanced", "hydration": "High"
        }
      }
      """;
      
      final finalPrompt = """
      $prompt
      
      RETORNE APENAS JSON VÁLIDO E COMPLETO (sem ```). Não trunque strings e não inclua texto fora do JSON.
      IMPORTANTE: Finalize exatamente com o token __END_JSON__ logo após o fechamento do objeto JSON (ex: }__END_JSON__).
      """;
      
      // LOG PROMPT (Phase 3)
      debugPrint('🦴 [PetMenu] Prompt Size: ${finalPrompt.length}');
      debugPrint('📝 [PetMenu] Request Sample: ${finalPrompt.substring(0, finalPrompt.length > 200 ? 200 : finalPrompt.length)}...');

      Map<String, dynamic>? data;
      try {
         // Using Gemini implementation directly for PetMenu (Phase 2)
         data = await _geminiService.generatePetMealPlan(finalPrompt);
         debugPrint('✅ [PetMenu] Response Status: 200');
         
         // Log sample of response (Phase 3)
         String rawRes = jsonEncode(data);
         debugPrint('📄 [PetMenu] Response Body: ${rawRes.substring(0, rawRes.length > 2000 ? 2000 : rawRes.length)}');

      } catch (e) {
         debugPrint('❌ [PetMenu] Gemini Error: $e');
         rethrow;
      }

      if (data == null || data.isEmpty) throw Exception('Empty AI Response');

      
      final List<DailyMealItem> dailyItems = [];
      if (data['daily_meals'] != null) {
         for (var d in data['daily_meals']) {
             int day = d['day_of_week'];
             if (d['meals'] != null) {
                 for (var m in d['meals']) {
                     dailyItems.add(DailyMealItem(
                         dayOfWeek: day,
                         time: m['time'] ?? '',
                         title: m['title'] ?? '',
                         description: m['description'] ?? '',
                         quantity: m['quantity']?.toString() ?? '',
                         benefit: m['benefit']
                     ));
                 }
             }
         }
      }
      
      final meta = NutrientMetadata(
          protein: data['metadata']?['protein'] ?? '',
          fat: data['metadata']?['fat'] ?? '',
          fiber: data['metadata']?['fiber'] ?? '',
          micronutrients: data['metadata']?['micronutrients'] ?? '',
          hydration: data['metadata']?['hydration'] ?? ''
      );
      
      final plan = WeeklyMealPlan.create(
          petId: petId,
          startDate: startOfWeek,
          dietType: dietLabel, // Store accurate user selection
          nutritionalGoal: data['nutritional_goal'] ?? 'Health',
          meals: dailyItems,
          metadata: meta,
          templateName: 'AI Generated'
      );
      
      await MealPlanService().savePlan(plan);
      
      if (data['shopping_list'] != null) {
          final List<Map<String, dynamic>> shoppingList = deepCastMapList(data['shopping_list']);
          await PetShoppingListService().saveList(plan.id, shoppingList);
      }

  }
}
