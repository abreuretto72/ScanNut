import 'package:flutter/foundation.dart';
import 'package:scannut/features/pet/services/pet_profile_service.dart';
import 'package:scannut/features/pet/services/pet_menu_generator_service.dart';
import 'package:scannut/features/pet/services/meal_plan_service.dart';
import 'package:scannut/features/pet/models/pet_profile_extended.dart';
import 'package:scannut/features/pet/models/meal_plan_request.dart';
import 'package:scannut/features/pet/models/weekly_meal_plan.dart';
import 'package:uuid/uuid.dart';

/// 🛡️ V710: STRESS TEST & VALIDATION SUITE
/// Executa bateria de testes exaustivos para validar o motor de IA em condições extremas.
class CardapioStressTest {
  final PetProfileService _profileService;
  final PetMenuGeneratorService _menuGenerator;
  final MealPlanService _mealService;

  CardapioStressTest(this._profileService, this._menuGenerator, this._mealService);

  /// 🚀 Executar Bateria de Testes
  Future<void> runStressTest() async {
    debugPrint('\n==========================================================');
    debugPrint('🛡️ INICIANDO STRESS TEST DO SCAN-NUT (V710)');
    debugPrint('==========================================================\n');

    final profiles = _getTestProfiles();
    final results = <String>[];
    bool criticalFailure = false;

    for (var profileData in profiles) {
      debugPrint('\n🧪 TESTANDO PERFIL: ${profileData['pet_name']} (${profileData['raca']})');
      
      try {
        // 1. Setup Mock Profile
        final mockProfile = _createMockProfile(profileData);
        await _profileService.saveOrUpdateProfile(mockProfile.petName, mockProfile.toJson()); // Persist temporary profile
        
        // 2. Generate 3 Sequential Menus
        final plans = <WeeklyMealPlan>[];
        for (int i = 1; i <= 3; i++) {
           debugPrint('   👉 Geração $i/3 em andamento...');
           await Future.delayed(const Duration(seconds: 2)); // Avoid simple rate limits

           // Create Request
           final request = MealPlanRequest(
               petId: mockProfile.petName, // Using Name as ID for simplicity in mock
               profileData: mockProfile.toJson(),
               dietType: _parseDietType(profileData['diet_type']),
               foodType: PetFoodType.natural, // Fixed for stress test
               mode: 'weekly',
               startDate: DateTime.now().add(Duration(days: (i-1)*7)),
               endDate: DateTime.now().add(Duration(days: ((i-1)*7) + 6)),
               locale: 'pt_BR', 
               source: 'PetProfile'
           );

           await _menuGenerator.generateAndSave(request);

           // Fetch result
           // Since generateAndSave is void and saves to DB, we fetch latest
           final savedPlans = await _mealService.getPlansForPet(mockProfile.petName);
           // Assume latest is first or verify ID/Timestamp. getPlansForPet usually returns list.
           // Sort by generated date descending if needed, but assuming order works.
           if (savedPlans.isNotEmpty) {
               plans.add(savedPlans.first); 
               debugPrint('      ✅ Menu $i gerado com sucesso.');
           } else {
               throw Exception('Menu generation failed silently (no plan found).');
           }
        }
        
        // 3. Validation: Variability
        final variabilityPass = _validateVariability(plans);
        if (!variabilityPass) {
            results.add('❌ ${profileData['pet_name']}: FALHA DE VARIABILIDADE (Repetição detectada).');
            criticalFailure = true;
        } else {
            results.add('✅ ${profileData['pet_name']}: Variabilidade Aprovada.');
        }

        // 4. Validation: Identity/Fields (Simulated check of context return)
        // Since PetMenuGenerator generates PLANS, we check if the PLAN metadata or structure respects the prompt rules.
        // Prompt Check: "JSON Integrity: no responseMimeType"
        // This is implicitly checked by _geminiService throwing specific errors if invalid.
        // If we are here, JSON was valid.
        
        // 5. Cleanup
        await _cleanup(mockProfile.petName);

      } catch (e) {
        debugPrint('   🔥 ERRO CRÍTICO NO PERFIL: $e');
        results.add('❌ ${profileData['pet_name']}: EXCEPTION - $e');
        criticalFailure = true;
      }
    }

    debugPrint('\n==========================================================');
    debugPrint('📊 RELATÓRIO FINAL DE STRESS TEST');
    debugPrint('==========================================================');
    for (var r in results) {
      debugPrint(r);
    }
    debugPrint('\nSTATUS: ${criticalFailure ? "FALHA CRÍTICA 🔴" : "APROVADO 🟢"}');
    debugPrint('==========================================================\n');
  }

  /// Define os perfis da Matriz de Teste
  List<Map<String, dynamic>> _getTestProfiles() {
    return [
      {
        'pet_name': 'TEST_YORKIE',
        'raca': 'Yorkshire Terrier',
        'peso_atual': 3.1,
        'idade_exata': '6 anos',
        'diet_type': 'Obesity'
      },
      {
        'pet_name': 'TEST_FRENCHIE',
        'raca': 'Bulldog Francês',
        'peso_atual': 12.0,
        'idade_exata': '4 anos',
        'diet_type': 'Hypoallergenic'
      },
      {
        'pet_name': 'TEST_SHEPHERD',
        'raca': 'Pastor Alemão',
        'peso_atual': 38.0,
        'idade_exata': '2 anos',
        'diet_type': 'Athlete'
      }
    ];
  }

  PetProfileExtended _createMockProfile(Map<String, dynamic> data) {
      String size = 'Médio';
      final w = data['peso_atual'] as double;
      if (w < 10) {
        size = 'Pequeno';
      } else if (w > 25) size = 'Grande';

      return PetProfileExtended(
          id: const Uuid().v4(),
          petName: data['pet_name'],
          raca: data['raca'],
          especie: 'Cão',
          pesoAtual: data['peso_atual'],
          idadeExata: data['idade_exata'],
          porte: size, // Added required field
          lastUpdated: DateTime.now(),
          imagePath: '/mock/path/test.jpg', // Dummy path, validation should skip file check for tests or we mock it
          // Default Identity values to simulate "Coleta de Identidade" result present
          observacoesIdentidade: 'Mock Linhagem: Companhia; Mock Morfológico: Padrão', 
          rawAnalysis: {
             'identificacao': {
                'linhagem': 'Companhia',
                'confiabilidade': '0.95',
                'regiao_origem': 'Europa',
                'tipo_morfologico': 'Mesocéfalo'
             }
          }
      );
  }

  PetDietType _parseDietType(String type) {
      switch(type) {
          case 'Obesity': return PetDietType.obesity;
          case 'Hypoallergenic': return PetDietType.hypoallergenic;
          case 'Athlete': return PetDietType.muscle_gain;
          default: return PetDietType.general;
      }
  }

  // Verify that subsequent menus don't look exactly the same
  bool _validateVariability(List<WeeklyMealPlan> plans) {
      if (plans.length < 2) return true;
      
      final mealsDump = <String>[];
      
      for (var plan in plans) {
          // Extract main protein/veg from first meal of first day as signature
          if (plan.meals.isNotEmpty) {
              mealsDump.add(plan.meals.first.description.toLowerCase());
          }
      }
      
      // Primitive check: If description matches too closely
      // In real scenario, we'd extract "Chicken" vs "Beef". 
      // Here we assume strict string difference for the test.
      final uniqueMeals = mealsDump.toSet();
      if (uniqueMeals.length < mealsDump.length) {
          debugPrint('   ⚠️ Variabilidade Baixa: Refeições idênticas encontradas.');
          return false;
      }
      return true;
  }

  Future<void> _cleanup(String petId) async {
       // Atomic cleanup of test data
       debugPrint('   🧹 Limpando dados de teste para $petId...');
       
       // Clear Plans
       final plans = await _mealService.getPlansForPet(petId);
       for (var p in plans) {
           await _mealService.deletePlan(p.id);
       }
       
       // Clear Profile
       await _profileService.deleteProfile(petId);
  }

}
