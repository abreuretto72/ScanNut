import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/food_analysis_service.dart';
import '../services/nutrition_service.dart';
import '../models/food_analysis_model.dart';
import '../../../core/models/analysis_state.dart';

// 🛡️ Provider exclusivo para o Notifier de Comida (Isolamento de Domínio)
final foodAnalysisNotifierProvider = 
    StateNotifierProvider.autoDispose<FoodAnalysisNotifier, AnalysisState>((ref) {
  // 🛡️ Sustentação de Estado V135: Mantém os dados vivos durante transição de telas
  ref.keepAlive();
  
  final service = ref.watch(foodAnalysisServiceProvider);
  return FoodAnalysisNotifier(service, NutritionService());
});

class FoodAnalysisNotifier extends StateNotifier<AnalysisState> {
  final FoodAnalysisService _service;
  final NutritionService _nutritionService;

  FoodAnalysisNotifier(this._service, this._nutritionService) : super(AnalysisIdle()) {
    // ignore: avoid_print
    print('DEBUG_LIFECYCLE: FoodAnalysisNotifier Initialized');
  }

  @override
  void dispose() {
    // ignore: avoid_print
    print('DEBUG_LIFECYCLE: FoodAnalysisNotifier Disposed');
    super.dispose();
  }

  Future<AnalysisState> analyze(File image, {bool isMeal = false, bool isChefVision = false, String? userConstraints}) async {
    debugPrint('🔄 [FoodTrace] Notifier.analyze called. ChefVision: $isChefVision');
    // 🛡️ REATIVIDADE IMEDIATA: State Loading disparado antes de qualquer await
    state = AnalysisLoading(message: isChefVision ? 'Criando receitas...' : 'loadingFood', imagePath: image.path);
    
    try {
      // 1. Chamada Isolada: Uso do Service exclusivo do módulo Food
      FoodAnalysisModel result;
      if (isChefVision) {
        result = await _service.analyzeChefVision(image, constraints: userConstraints);
      } else if (isMeal) {
        result = await _service.analyzeMeal(image);
      } else {
        result = await _service.analyzeFood(image);
      }
      
      // 2. 🚀 AUTO-SAVE MANDATÓRIO (V135): Salva em background antes do sucesso
      await _saveAutomatically(result, image);
      
      // 3. Mapeamento V135: O Service já retorna o modelo rico
      state = AnalysisSuccess<FoodAnalysisModel>(result);
      debugPrint('✅ [FoodTrace] Notifier State: Success. Data: ${result.identidade.nome}');
      return state;
    } catch (e) {
      debugPrint('❌ FoodAnalysisNotifier Error: $e');
      debugPrint('❌ [FoodTrace] Notifier State: Error. $e');
      state = AnalysisError("Falha na análise nutricional: $e");
      return state;
    }
  }

  /// 🛡️ PERSISTÊNCIA SILENCIOSA (Lei de Ferro): Blinda o dado no Hive/Backup
  Future<void> _saveAutomatically(FoodAnalysisModel analysis, File image) async {
    try {
      debugPrint('💾 Iniciando Auto-Save para: ${analysis.identidade.nome}');
      await _nutritionService.saveFoodAnalysis(analysis, image);
      debugPrint('✅ Auto-Save concluído com sucesso.');
    } catch (e) {
      debugPrint('🚨 ERRO CRÍTICO NO AUTO-SAVE: $e');
      // 🛡️ Lei de Ferro: Se não salvou, é erro de análise (Não garantido no disco)
      throw Exception("Erro ao garantir persistência dos dados: $e");
    }
  }

  void reset() {
    debugPrint('🧹 [FoodNotifier] Forçando Reset de Estado para Idle.');
    if (state is! AnalysisIdle) {
      state = AnalysisIdle();
    }
  }
}
