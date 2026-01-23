import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/gemini_service.dart';
import '../../pet/models/weekly_meal_plan.dart';
import '../../pet/services/meal_plan_service.dart';
import '../../pet/services/pet_shopping_list_service.dart';
import '../../pet/models/meal_plan_request.dart';
import 'package:scannut/features/pet/services/pet_profile_service.dart';
import '../models/brand_suggestion.dart'; // 🛡️ NEW: Import BrandSuggestion
import 'pet_indexing_service.dart'; // 🧠 Indexing Service

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

    


    // Enhanced extraction logic
    final rawReprod = profile['statusReprodutivo'] ?? 
                      profile['status_reprodutivo'] ?? 
                      profile['reproductiveStatus'] ?? 
                      profile['reproductive_status'] ??
                      profile['status'];
    
    final reprodStatus = (rawReprod == null || rawReprod.toString().isEmpty || rawReprod.toString() == 'Unknown') 
        ? 'Não informado (Assumido Neutro)' 
        : rawReprod.toString();


    final restrictions = (profile['restricoes'] as List?)?.join(', ') ?? 'None';
    final preferences = (profile['preferencias'] as List?)?.join(', ') ?? 'None';
    


    debugPrint('🧬 [PetMenu] Reproductive Status Parsed: "$reprodStatus" (Raw: "$rawReprod")');

    
    String dietLabel = request.dietType.toString().split('.').last;
    if (request.dietType == PetDietType.other) {
       dietLabel = "Other: ${request.otherNote ?? ''}"; 
    }

    String foodTypeInstruction = "";
    if (request.foodType == PetFoodType.kibble) {
        foodTypeInstruction = "FOOD TYPE: ONLY COMMERCIAL KIBBLE (Dry/Wet). Specify quantity in grams/cups based on caloric density. Do not suggest home-cooked recipes.";
    } else if (request.foodType == PetFoodType.natural) {
        foodTypeInstruction = "FOOD TYPE: ONLY NATURAL INGREDIENTS (Home Cooked / AN). Specify raw/cooked weights. Do not suggest kibble.";
    } else {
        foodTypeInstruction = "FOOD TYPE: MIXED (Kibble + Natural Toppers). Combine commercial food with safe natural additions.";
    }

    // 2.2. HISTORY & DIVERSITY CHECK (Phase 8 - AI Memory)
    final mealService = MealPlanService();
    // Ensure service is ready (might be re-entrant safe)
    try { await mealService.init(); } catch (_) {} 
    
    String exclusionPrompt = "";
    try {
       final historyPlans = await mealService.getPlansForPet(request.petId); // Saved in DB
       if (historyPlans.isNotEmpty) {
           final recentIngredients = <String>{};
           // Look at the last 2 plans (14 days) to extract patterns
           for (var p in historyPlans.take(2)) {
               for (var m in p.meals) {
                   final desc = m.description.toLowerCase();
                   // Extrator simples de ingredientes chave para o prompt
                   if (desc.contains('frango')) recentIngredients.add('Frango');
                   if (desc.contains('carne')) recentIngredients.add('Carne Bovina');
                   if (desc.contains('peixe')) recentIngredients.add('Peixe');
                   if (desc.contains('arroz')) recentIngredients.add('Arroz');
                   if (desc.contains('cenoura')) recentIngredients.add('Cenoura');
                   if (desc.contains('abóbora')) recentIngredients.add('Abóbora');
                   if (desc.contains('batata')) recentIngredients.add('Batata Doce');
               }
           }
           
           if (recentIngredients.isNotEmpty) {
               final sample = recentIngredients.take(10).join(", ");
               exclusionPrompt = """
               HISTÓRICO RECENTE (MEMÓRIA DE DIETA):
               O pet consumiu recentemente estes ingredientes principais: [$sample].

               REGRA DE OURO (VARIABILIDADE):
               - É terminantemente PROIBIDO repetir a combinação exata de proteína e vegetal principal destas refeições anteriores.
               - Varie os ingredientes para evitar tédio alimentar e garantir rotação de nutrientes.
               """;
               debugPrint('🧬 [PetMenu] Memória de Dieta Ativada: $sample');
           }
       }
    } catch (e) {
       debugPrint('⚠️ [PetMenu] Erro ao carregar memória de dieta: $e');
    }

    // 3. MASTER PROMPT (Phase 5 - Rigid Rules)
    const ingredientsPool = """
    AVAILABLE INGREDIENTS POOL (USE THIS TO VARIATE):
    - Proteins: Chicken, Beef, Fish (White/Salmon), Pork, Lamb, Turkey, Egg.
    - Vegetables: Carrot, Pumpkin, Zucchini, Green Beans, Broccoli, Spinach, Sweet Potato, Beets, Chayote, Peas.
    - Carbs: Rice, Oats, Potato, Quinoa, Sweet Potato.
    """;

    String rigidFoodRule = "";
    if (request.foodType == PetFoodType.natural) {
        // 🛡️ V3: Softened constraint + Positive Reinforcement to prevent JSON breakage
        rigidFoodRule = "7. INGREDIENT SOURCE: Prioritize fresh natural ingredients (Meat, Vegetables, Grains). Avoid commercial dry food/kibble.";
    }

    final prompt = """
Act as a Veterinary Nutritionist specialized in pet diets (AAFCO/FEDIAF guidelines).
Generate a specialized Diet Plan and Meal Schedule with HIGH VARIETY.

CONTEXT (SOURCE OF TRUTH - DO NOT ALTER):
// ... (omitted for brevity, keep existing context lines)
- Restrictions: $restrictions
- Owner Preferences: $preferences

DIET PARAMETERS:
- Main Goal/Diet Type: $dietLabel
- Food Type: ${request.foodType.name} (STRICT)
- Generation Mode: ${request.mode}
// ... (keep existing)
$foodTypeInstruction

$exclusionPrompt

$ingredientsPool

RIGID RULES:
1. DO NOT invent or return: species, breed, age, weight, or pet_name.
2. DO NOT return medical diagnosis.
3. Use ONLY the provided context for the pet's identity.
4. Language: EXCLUSIVELY ${request.locale}.
5. Response Format: PURE JSON ONLY. No markdown blocks, NO COMMENTS (// or /*), no prefix/suffix text.
6. CHECK ALLERGIES: If the pet is allergic to an item in the Pool or History, DISCARD IT immediately.
7. RECOMMENDATIONS: If any meal in the plan contains "Commercial Kibble", "Dry Food", "Ração" or "Wet Food", you MUST include a list of 2-3 high-quality commercial brand suggestions in the "marcas_sugeridas" field. 
   🛡️ CRITICAL: For EACH brand, provide a technical justification (max 2 lines) explaining WHY this brand is suitable for the pet's specific goal (e.g., "Contains L-carnitine to aid fat burning for weight loss" or "Hydrolyzed protein for sensitive digestion"). The justification MUST reference the pet's current dietary goal or health condition.
$rigidFoodRule

INSTRUCTIONS:
- Calculate Daily Energy Needs (MER) based on size, weight, and activity.
- Suggest daily meals consisting of balanced Proteins, Carbohydrates, and Fiber.
- Handle allergies and restrictions strictly.
- If mode is monthly, reflect 4 distinct weeks if possible.
- If mode is weekly, provide 7 days.

EXAMPLE OUTPUT STRUCTURE (FOLLOW EXACTLY):
{
  "diet_type": "$dietLabel",
  "nutritional_goal": "Maintenance...",
  "marcas_sugeridas": ["Brand A", "Brand B"],
  "weeks": [
    {
      "week_number": 1,
      "start_date": "2024-01-01",
      "end_date": "2024-01-07",
      "marcas_sugeridas": [
        {
          "marca": "Premier Pet - Linha Light",
          "por_que_escolhemos": "Contém L-carnitina que auxilia na queima de gordura, ideal para o objetivo de emagrecimento do pet."
        },
        {
          "marca": "Royal Canin - Weight Control",
          "por_que_escolhemos": "Baixo índice glicêmico e fibras que promovem saciedade, respeitando a restrição calórica necessária."
        }
      ],
      "days": [
        {
          "date": "YYYY-MM-DD",
          "meals": [
            {
              "time": "08:00",
              "title": "Breakfast",
              "description": "100g Chicken + 50g Rice",
              "quantity": "150g",
              "kcal": 300,
              "benefit": "Protein"
            }
          ]
        }
      ],
      "shopping_list": [
        { "category": "Proteins", "item": "Chicken Breast", "total_quantity": "1kg", "kcal": 1500 }
      ]
    }
  ],
  "metadata": { "protein": "High" }
}
""";

    // 🛡️ V3: Final Reminder
    final finalPrompt = "$prompt\n\nIMPORTANT: The JSON MUST be valid and contain the 'weeks' array. RETURN ONLY JSON.";

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
      debugPrint('Food Type: ${request.foodType.name}'); // Added Debug
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
      /* REMOVED: Managed by default 'Assumido Neutro' above
      if (reprodStatus == 'Unknown' || reprodStatus.isEmpty) {
        throw Exception('PERFIL INCOMPLETO: Status reprodutivo não informado. Complete o perfil do pet antes de gerar o cardápio.');
      }
      */
      
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
                    // 🛡️ Defensive Parsing: Skip invalid items
                    if (m is! Map) continue; 
                    
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

           // 🛡️ UPDATED: Parse brand suggestions with justifications
           final List<BrandSuggestion> recommendedBrands = [];
           // 🛡️ Robust Parsing: Check inside specific week first, then fallback to root
           final marcasSugeridas = weekEntry['marcas_sugeridas'] ?? rawResult['marcas_sugeridas'];
           
           if (marcasSugeridas != null && marcasSugeridas is List) {
             for (var item in marcasSugeridas) {
               try {
                 if (item is Map<String, dynamic>) {
                   // New format with justifications
                   recommendedBrands.add(BrandSuggestion.fromJson(item));
                 } else if (item is String) {
                   // Legacy format: just brand name
                   recommendedBrands.add(BrandSuggestion(
                     brand: item,
                     reason: 'Marca selecionada por critérios de qualidade Super Premium para o perfil do pet.',
                   ));
                 }
               } catch (e) {
                 debugPrint('⚠️ [PetMenu] Error parsing brand suggestion: $e');
               }
             }
           }

           final plan = WeeklyMealPlan.create(
               petId: request.petId,
               startDate: weekStart,
               dietType: dietLabel,
               nutritionalGoal: rawResult['nutritional_goal'] ?? 'Health',
               meals: dailyItems,
               metadata: meta,
               templateName: 'AI Generated',
               recommendedBrands: recommendedBrands,
               foodType: request.foodType.id, // 🛡️ BLINDAGEM: Persiste filtro original
               goal: request.dietType.id, // 🛡️ BLINDAGEM: Persiste objetivo original
           );

           // SAVE PLAN (Calendar)
           debugPrint('🛡️ [TRACE-HIVE] Saving Plan ${plan.id}. Brands Count: ${plan.recommendedBrands?.length ?? 0}');
           try {
              await mealService.savePlan(plan);
              debugPrint('💾 [PetMenu] Saved Week starting $weekStart');
           } catch (e) {
              debugPrint('🛑 [TRACE-HIVE] CRITICAL HIVE ERROR SAVING PLAN: $e');
              rethrow;
           }

           // SAVE SHOPPING LIST
           // 🛡️ V4: Robust Parsing (Handle potential String list hallucination)
           if (weekEntry['shopping_list'] != null && weekEntry['shopping_list'] is List) {
               final rawList = weekEntry['shopping_list'] as List;
               final List<Map<String, dynamic>> shoppingList = [];
               
               for (var item in rawList) {
                   if (item is Map) {
                       shoppingList.add(Map<String, dynamic>.from(item));
                   } else if (item is String) {
                       // Fix: Convert string item to object structure
                       shoppingList.add({
                           'category': 'General', 
                           'item': item, 
                           'total_quantity': '-', 
                           'kcal': 0
                       });
                   }
               }
               
               if (shoppingList.isNotEmpty) {
                   await shoppingService.saveList(plan.id, shoppingList);
               }
           }
      }

      // 5. INDEXING (Timeline Event)
      try {
          final petName = request.profileData['nome'] ?? request.profileData['name'] ?? 'Pet';
          final firstWeekStart = weeksJson.isNotEmpty ? (weeksJson.first['start_date'] ?? '-') : '-';
          
          await PetIndexingService().indexOccurrence(
            petId: request.petId,
            petName: petName.toString(),
            group: 'food', // Grupo Alimentação
            title: 'Cardápio Nutricional Gerado',
            type: 'Cardápio', // 🛡️ Explicit Type
            localizedTitle: 'Novo Cardápio (IA)',
            localizedNotes: 'Plano alimentar gerado: ${_translateMode(request.mode)}. Início: $firstWeekStart. Objetivo: ${_translateDiet(dietLabel)}.',
            extraData: {
              'diet_type': dietLabel,
              'weeks_count': weeksJson.length,
              'source': 'ai_generator',
              'is_automatic': true
            }
          );
          debugPrint('🧠 [PetMenu] Cardápio indexado na timeline com sucesso.');
      } catch (e) {
         debugPrint('⚠️ [PetMenu] Falha ao indexar evento na timeline: $e');
      }

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

  // 🔄 RECYCLE FEATURE (Phase 9 - Granular Updates) + 🛡️ BLINDAGEM DE FILTROS
  Future<DailyMealItem?> regenerateSingleMeal(
    DailyMealItem meal, 
    String petId, 
    {String? foodType, String? goal} // 🛡️ NEW: Filtros originais persistidos
  ) async {
      try {
           final profileService = PetProfileService();
           await profileService.init();
           final profile = await profileService.getProfile(petId);
           final pData = profile?['data'] ?? {};
           
           final allergies = (pData['alergias_conhecidas'] as List?)?.join(', ') ?? 'None';
           final species = pData['especie']?.toString() ?? 'Pet';
           final restrictions = (pData['restricoes'] as List?)?.join(', ') ?? 'None';

           // 🛡️ BLINDAGEM: Determina restrições de tipo de comida
           String foodTypeInstruction = '';
           if (foodType == 'kibble') {
             foodTypeInstruction = '\n🛡️ FILTER ENFORCEMENT: ONLY suggest COMMERCIAL KIBBLE (dry/wet food). NO home-cooked meals.';
           } else if (foodType == 'natural') {
             foodTypeInstruction = '\n🛡️ FILTER ENFORCEMENT: ONLY suggest NATURAL/HOME-COOKED ingredients. NO commercial kibble.';
           } else if (foodType == 'mixed') {
             foodTypeInstruction = '\n🛡️ FILTER ENFORCEMENT: You can suggest EITHER kibble OR natural food, but maintain variety.';
           }

           // 🛡️ BLINDAGEM: Adiciona contexto do objetivo
           String goalContext = goal != null && goal.isNotEmpty 
             ? '\nNUTRITIONAL GOAL: $goal (e.g., weight loss, renal support, etc.)'
             : '';

           final prompt = """
Act as a Veterinary Nutritionist.
TASK: REPLACE this specific meal with a DIFFERENT, healthy alternative.
TARGET: $species
ALLERGIES (CRITICAL): $allergies
RESTRICTIONS: $restrictions$goalContext$foodTypeInstruction

CURRENT MEAL (TO AVOID):
"${meal.description}"

INSTRUCTIONS:
- Propose a distinct, balanced meal option for this slot.
- Ensure ingredients are safe for $species.
- Maintain similar caloric density.
- Do NOT repeat the ingredients from the current meal.
- STRICTLY FOLLOW the food type filter above.
- Return ONLY JSON.

OUTPUT STRUCTURE:
{
  "title": "${meal.title}",
  "description": "New description with ingredients...",
  "quantity": "${meal.quantity}",
  "benefit": "Why this is good..."
}
""";
         
         final result = await _geminiService.generateTextContent(prompt);
         
         return DailyMealItem(
            dayOfWeek: meal.dayOfWeek,
            time: result['time']?.toString() ?? meal.time,
            title: result['title']?.toString() ?? meal.title,
            description: result['description']?.toString() ?? '',
            quantity: result['quantity']?.toString() ?? meal.quantity,
            benefit: result['benefit']?.toString()
         );
      } catch (e) {
         debugPrint('🚨 [PetMenu] Single Regeneration Failed: $e');
         return null;
      }
  }

  String _translateMode(String mode) {
    switch (mode.toLowerCase()) {
      case 'weekly': return 'Semanal';
      case 'monthly': return 'Mensal';
      case 'custom': return 'Personalizado';
      default: return mode;
    }
  }

  String _translateDiet(String diet) {
    switch (diet.toLowerCase()) {
       case 'general': return 'Manutenção Geral';
       case 'obesity': return 'Perda de Peso';
       case 'muscle_gain': return 'Ganho Muscular';
       case 'renal': return 'Renal';
       case 'hepatic': return 'Hepática';
       case 'gastrointestinal': return 'Gastrointestinal';
       case 'hypoallergenic': return 'Hipoalergênica';
       case 'diabetes': return 'Diabetes';
       case 'cardiac': return 'Cardíaca';
       case 'urinary': return 'Urinária';
       case 'pediatric': return 'Pediátrica';
       case 'growth': return 'Crescimento';
       case 'other': return 'Outra';
       default: return diet;
    }
  }
}
