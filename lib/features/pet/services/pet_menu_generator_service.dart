import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/groq_api_service.dart';
import '../../pet/models/weekly_meal_plan.dart';
import '../../pet/services/meal_plan_service.dart';
import '../../pet/services/pet_shopping_list_service.dart';
import '../../pet/models/pet_profile_extended.dart';
import '../../../core/utils/json_cast.dart';


final petMenuGeneratorProvider = Provider<PetMenuGeneratorService>((ref) {
  final groqService = ref.watch(groqApiServiceProvider);
  return PetMenuGeneratorService(groqService);
});

class PetMenuGeneratorService {
  final GroqApiService _groqService;
  
  PetMenuGeneratorService(this._groqService);

  Future<void> generateAndSave({
    required String petId, 
    required Map<String, dynamic> profileData,
    required String mode,
    required DateTime startDate,
    required DateTime endDate,
    required String locale,
    required String dietType, // New
    String? otherNote,        // New
  }) async {
    // 1. VALIDATION
    if (petId.trim().isEmpty) throw Exception('Nome do Pet é obrigatório.');
    if (profileData.isEmpty) throw Exception('Perfl incompleto.');
    if (dietType.isEmpty) throw Exception('Tipo de dieta obrigatório.');

    // 2. LOGIC
    DateTime chunkStart = startDate;
    int safeGuard = 0;
    
    // Construct simplified diet string for storage/display
    String finalDietLabel = dietType;
    if (dietType == 'other') {
       finalDietLabel = "Outra: ${otherNote ?? ''}"; 
    }

    try {
      while (chunkStart.isBefore(endDate) && safeGuard < 10) {
         safeGuard++;
         DateTime chunkEnd = chunkStart.add(const Duration(days: 6));
         if (chunkEnd.isAfter(endDate)) {
           chunkEnd = endDate;
         }

         debugPrint('🦴 [PetMenu] Generating chunk: $chunkStart, Diet: $finalDietLabel');
         
         await _generateSingleWeek(
           petId, profileData, chunkStart, locale, finalDietLabel
         );

         chunkStart = chunkStart.add(const Duration(days: 7));
      }
    } catch (e) {
      debugPrint('🚨 [PetMenu] PET_MEALPLAN_PARSE_ERROR: $e');
      if (e.toString().contains('400') || e.toString().contains('Bad Request')) {
         throw Exception('Não foi possível gerar o cardápio agora. Tente novamente.');
      }
      throw Exception('Não foi possível gerar o cardápio agora. Tente novamente.');
    }

  }

  Future<void> _generateSingleWeek(
    String petId, 
    Map<String, dynamic> profileData, 
    DateTime startOfWeek, 
    String locale,
    String dietLabel
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
      
      // LOG PROMPT
      debugPrint('📝 [PetMenu] Prompt Truncated: ${prompt.substring(0, 100)}...');

      String? jsonString;
      try {
         jsonString = await _groqService.generateText(prompt);
      } catch (e) {
         debugPrint('❌ [PetMenu] API Error: $e');
         rethrow;
      }

      if (jsonString == null) throw Exception('Empty AI Response');
      
      String cleanJson = jsonString;
      if (cleanJson.contains('```json')) {
        cleanJson = cleanJson.split('```json').last.split('```').first.trim();
      } else if (cleanJson.contains('```')) {
        cleanJson = cleanJson.split('```').last.split('```').first.trim();
      }
      
      final dynamic decoded = jsonDecode(cleanJson);
      final Map<String, dynamic> data = deepCastMap(decoded);

      
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
