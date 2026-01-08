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
import 'package:scannut/features/pet/services/pet_profile_service.dart';

final petMenuGeneratorProvider = Provider<PetMenuGeneratorService>((ref) {
  final geminiService = ref.watch(geminiServiceProvider);
  return PetMenuGeneratorService(geminiService);
});

class PetMenuGeneratorService {
  final GeminiService _geminiService;
  
  PetMenuGeneratorService(this._geminiService);

  Future<void> generateAndSave(MealPlanRequest request) async {
    // 1. VALIDATION (Phase 7)
    try {
      request.validateOrThrow();
      
      if (request.source != 'PetProfile') {
          debugPrint('🚨 [PetMenu] SECURITY_BLOCK: Unauthorized generation source: ${request.source}');
          return;
      }
    } catch (e) {
      debugPrint('🚨 [PetMenu] Validation failed: $e');
      rethrow;
    }

    // 2. CONTEXT EXTRACTION (Source of Truth - Phase 1)
    final profile = request.profileData;
    final species = profile['especie'] ?? profile['species'] ?? 'Dog';
    final breed = profile['raca'] ?? profile['breed'] ?? 'Unknown';
    final weight = profile['peso_atual']?.toString() ?? profile['weight']?.toString() ?? 'Unknown';
    final age = profile['idade_exata'] ?? profile['age'] ?? 'Unknown';
    final size = profile['porte'] ?? profile['size'] ?? 'Medium';
    
    final sex = profile['sex'] ?? 'Unknown';
    final reprodStatus = profile['statusReprodutivo'] ?? profile['status_reprodutivo'] ?? 'Unknown';
    final allergies = (profile['alergias_conhecidas'] as List?)?.join(', ') ?? 'None';
    final restrictions = (profile['restricoes'] as List?)?.join(', ') ?? 'None';
    final preferences = (profile['preferencias'] as List?)?.join(', ') ?? 'None';
    
    String dietLabel = request.dietType.toString().split('.').last;
    if (request.dietType == PetDietType.other) {
       dietLabel = "Other: ${request.otherNote ?? ''}"; 
    }

    // 3. MASTER PROMPT (Phase 5 - Rigid Rules)
    final prompt = """
Act as a Veterinary Nutritionist specialized in pet diets (AAFCO/FEDIAF guidelines).
Generate a specialized Diet Plan and Meal Schedule.

CONTEXT (SOURCE OF TRUTH - DO NOT ALTER):
- Species: $species
- Breed: $breed
- Age: $age
- Weight: $weight kg
- Size/Porte: $size
- Sex: $sex
- Reproductive Status: $reprodStatus
- Known Allergies: $allergies
- Restrictions: $restrictions
- Owner Preferences: $preferences

DIET PARAMETERS:
- Main Goal/Diet Type: $dietLabel
- Generation Mode: ${request.mode}
- Start Date: ${request.startDate.toIso8601String().split('T')[0]}
- End Date: ${request.endDate.toIso8601String().split('T')[0]}
- Locale: ${request.locale}
- Units: Metric (kg, g, kcal)

RIGID RULES:
1. DO NOT invent or return: species, breed, age, weight, or pet_name.
2. DO NOT return medical diagnosis.
3. Use ONLY the provided context for the pet's identity.
4. Language: EXCLUSIVELY ${request.locale}.
5. Response Format: PURE JSON ONLY. No markdown blocks, no prefix/suffix text.

INSTRUCTIONS:
- Calculate Daily Energy Needs (MER) based on size, weight, and activity.
- Suggest daily meals consisting of balanced Proteins, Carbohydrates, and Fiber.
- Handle allergies and restrictions strictly (e.g., if "no chicken", exclude all poultry).
- If mode is monthly, reflect 4 distinct weeks if possible.
- If mode is weekly, provide 7 days of schedule.

OUTPUT STRUCTURE:
{
  "diet_type": "$dietLabel",
  "nutritional_goal": "Detailed description of the nutritional target",
  "weeks": [
    {
      "week_start": "YYYY-MM-DD",
      "days": [
        {
          "date": "YYYY-MM-DD",
          "meals": [
            {
              "time": "08:00",
              "title": "Short title",
              "description": "Ex: 100g Rice + 50g Beef",
              "quantity": "150g",
              "kcal": 350,
              "benefit": "Protein focus"
            }
          ]
        }
      ],
      "shopping_list": [
        { "category": "Proteins", "item": "Beef", "total_quantity": "2kg", "kcal": 4000 }
      ]
    }
  ],
  "metadata": {
    "protein": "High/Med/Low",
    "fat": "High/Med/Low",
    "fiber": "High/Med/Low",
    "hydration": "High/Med/Low"
  }
}
""";

    final finalPrompt = "$prompt\n\nRETURN PURE JSON ONLY. Any other text will cause a parse error.";

    try {
      // 🛡️ PAYLOAD VALIDATION & LOGGING (Security & Debug)
      debugPrint('🦴 [PetMenu] === PAYLOAD VALIDATION ===');
      debugPrint('Pet ID: ${request.petId}');
      debugPrint('Species: $species');
      debugPrint('Breed: $breed');
      debugPrint('Weight: $weight kg');
      debugPrint('Age: $age');
      debugPrint('Reproductive Status: $reprodStatus');
      debugPrint('Diet Type: $dietLabel');
      debugPrint('Mode: ${request.mode}');
      debugPrint('Date Range: ${request.startDate.toIso8601String().split('T')[0]} to ${request.endDate.toIso8601String().split('T')[0]}');
      
      // Validate critical fields
      if (species == 'Unknown' || species.isEmpty) {
        throw Exception('PERFIL INCOMPLETO: Espécie não informada. Complete o perfil do pet antes de gerar o cardápio.');
      }
      if (weight == 'Unknown' || weight.isEmpty) {
        throw Exception('PERFIL INCOMPLETO: Peso não informado. Complete o perfil do pet antes de gerar o cardápio.');
      }
      if (age == 'Unknown' || age.isEmpty) {
        throw Exception('PERFIL INCOMPLETO: Idade não informada. Complete o perfil do pet antes de gerar o cardápio.');
      }
      if (reprodStatus == 'Unknown' || reprodStatus.isEmpty) {
        throw Exception('PERFIL INCOMPLETO: Status reprodutivo não informado. Complete o perfil do pet antes de gerar o cardápio.');
      }
      
      debugPrint('✅ [PetMenu] Payload validation passed. Requesting AI Generation...');
      final Map<String, dynamic> rawResult = await _geminiService.generatePetMealPlan(finalPrompt);
      
      // 🛡️ SHIELDING & LOGGING (Phase 5 & 8)
      if (rawResult.containsKey('species') || rawResult.containsKey('breed') || rawResult.containsKey('pet_name')) {
          debugPrint('🛡️ DEBUG: [SOURCE OF TRUTH BREACH] AI attempted to return identity fields: ${rawResult.keys.where((k) => ['species', 'breed', 'pet_name', 'age', 'weight'].contains(k)).toList()}');
          rawResult.remove('species');
          rawResult.remove('breed');
          rawResult.remove('pet_name');
          rawResult.remove('age');
          rawResult.remove('weight');
      }

      // 4. PARSING AND SAVING (Phase 6)
      if (!rawResult.containsKey('weeks') || rawResult['weeks'] is! List) {
          throw Exception('Invalid AI Response: Missing "weeks" array');
      }

      final List<dynamic> weeksJson = rawResult['weeks'];
      final meta = NutrientMetadata(
          protein: rawResult['metadata']?['protein'] ?? 'Med',
          fat: rawResult['metadata']?['fat'] ?? 'Med',
          fiber: rawResult['metadata']?['fiber'] ?? 'Med',
          micronutrients: 'Balanced',
          hydration: rawResult['metadata']?['hydration'] ?? 'Med'
      );

      final mealService = MealPlanService();
      final shoppingService = PetShoppingListService();

      for (var weekEntry in weeksJson) {
           DateTime weekStart = DateTime.tryParse(weekEntry['week_start'] ?? '') ?? request.startDate;
           
           final List<DailyMealItem> dailyItems = [];
           final List<dynamic> daysJson = weekEntry['days'] ?? [];
           
           for (var dayJson in daysJson) {
                DateTime dayDate = DateTime.tryParse(dayJson['date'] ?? '') ?? weekStart;
                int dayOfWeek = dayDate.weekday; // 1-7
                
                final List<dynamic> mealsJson = dayJson['meals'] ?? [];
                for (var m in mealsJson) {
                    dailyItems.add(DailyMealItem(
                        dayOfWeek: dayOfWeek,
                        time: m['time'] ?? '08:00',
                        title: m['title'] ?? '',
                        description: m['description'] ?? '',
                        quantity: m['quantity']?.toString() ?? '',
                        benefit: m['benefit']
                    ));
                }
           }

           final plan = WeeklyMealPlan.create(
               petId: request.petId,
               startDate: weekStart,
               dietType: dietLabel,
               nutritionalGoal: rawResult['nutritional_goal'] ?? 'Health',
               meals: dailyItems,
               metadata: meta,
               templateName: 'AI Generated'
           );

           // SAVE PLAN (Calendar)
           await mealService.savePlan(plan);
           debugPrint('💾 [PetMenu] Saved Week starting $weekStart');

           // SAVE SHOPPING LIST
           if (weekEntry['shopping_list'] != null) {
               final List<Map<String, dynamic>> shoppingList = deepCastMapList(weekEntry['shopping_list']);
               await shoppingService.saveList(plan.id, shoppingList);
           }
      }

      // Final Step: Update Active Menu Markdown (Optional display)
      // Since the new structure is more granular, we might not have a full markdown field anymore, 
      // but we can generate one or just use the JSON-based view.
      // For now, let's just complete the process.
      debugPrint('✅ [PetMenu] Successfully generated ${weeksJson.length} weeks of meal plans.');

    } catch (e) {
      debugPrint('🚨 [PetMenu] GENERATION_ERROR: $e');
      
      // Enhanced error messages for better UX
      if (e.toString().contains('timeout') || e.toString().contains('SocketException')) {
        throw Exception('A IA está processando muitos dados. Por favor, tente novamente em alguns instantes.');
      } else if (e.toString().contains('PERFIL INCOMPLETO')) {
        rethrow; // Pass through validation errors as-is
      } else {
        throw Exception('Falha ao gerar cardápio: ${e.toString().replaceAll('Exception:', '').trim()}');
      }
    }
  }
}
