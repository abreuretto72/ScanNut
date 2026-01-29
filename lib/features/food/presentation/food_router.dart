import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/food_analysis_provider.dart';
import 'package:scannut/features/food/models/food_analysis_model.dart';
import 'package:scannut/features/food/presentation/food_intelligence_screen.dart';
import 'widgets/result_card.dart';
import 'nutrition_history_screen.dart';
import '../nutrition/presentation/screens/nutrition_home_screen.dart';
import '../../../core/models/analysis_state.dart';
import '../services/nutrition_service.dart';

import 'package:scannut/features/food/presentation/chef_recipe_screen.dart';
import 'package:google_fonts/google_fonts.dart';

/// 🛡️ FOOD ROUTER (V135) - Selagem de Navegação
/// Este arquivo é o único ponto de entrada para a UI de Comida.
/// Ele blinda a HomeView de conhecer detalhes do domínio.
class FoodRouter {
  FoodRouter._();

  /// 🚀 ORQUESTRADOR MASTER: Faz a análise e navega (Selagem Total)
  static Future<void> analyzeAndOpen({
    required BuildContext context,
    required WidgetRef ref,
    required File image,
    bool isMeal = false,
    bool isChefVision = false,
    String? userConstraints,
  }) async {
    try {
      // 1. Reset e Trigger no Provider Isolado
      ref.read(foodAnalysisNotifierProvider.notifier).reset();
      
      final state = await ref.read(foodAnalysisNotifierProvider.notifier).analyze(
        image, 
        isMeal: isMeal, 
        isChefVision: isChefVision, 
        userConstraints: userConstraints
      );

      debugPrint('🔄 [FoodTrace] Router received state: ${state.runtimeType}');

      if (!context.mounted) {
        debugPrint('⚠️ [FoodTrace] Context not mounted after analysis.');
        return;
      }

      // 2. Encaminha para o Tratamento de Resultado (Persistência + Navegação)
      if (context.mounted) {
        await handleResult(context, state, image, isChefVision: isChefVision);
      } else {
         debugPrint('⚠️ [FoodTrace] Context unmounted before handleResult.');
      }
      
      // 3. Reset Final para Limpeza de Memória
      ref.read(foodAnalysisNotifierProvider.notifier).reset();
    } catch (e) {
      debugPrint('❌ FoodRouter Critical Error: $e');
      if (context.mounted) {
        // Enviar para tela de erro em vez de SnackBar
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              backgroundColor: Colors.red.shade900,
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 80, color: Colors.white),
                      const SizedBox(height: 16),
                      Text('Critical Analysis Error', style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Text(e.toString(), style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Try Again'),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }
  }

  /// Ponto de entrada atômico para processar o resultado da IA
  static Future<void> handleResult(BuildContext context, AnalysisState state, File? image, {bool isChefVision = false}) async {
    debugPrint('🔄 [FoodTrace] handleResult called with ${state.runtimeType}');
    if (state is! AnalysisSuccess || state.data is! FoodAnalysisModel) {
       debugPrint('❌ [FoodTrace] Invalid state for handleResult: $state');
       if (state is AnalysisError && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro na Análise: ${(state as AnalysisError).message}'),
              backgroundColor: Colors.red,
            ),
          );
       }
       return;
    }
    
    final analysis = state.data as FoodAnalysisModel;

    try {
      // 🛡️ V135: O salvamento já ocorreu no FoodAnalysisNotifier (Auto-Save Mandatório)
      if (!context.mounted) return;

      // Navegação Direta
      await navigateToResult(
        context: context,
        analysis: analysis,
        imageFile: image,
        isChefVision: isChefVision,
      );
      debugPrint('🚀 [FoodTrace] Navigating to Result Screen');
    } catch (e) {
      debugPrint('❌ FoodRouter Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao abrir resultado: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// Salva a análise de comida (Persistência Blindada)
  static Future<void> saveAnalysis(dynamic analysis, File? imageFile) async {
    if (analysis is FoodAnalysisModel) {
      await NutritionService().saveFoodAnalysis(analysis, imageFile);
    }
  }

  /// Navega para o resultado da análise de comida
  static Future<void> navigateToResult({
    required BuildContext context,
    required FoodAnalysisModel analysis,
    File? imageFile,
    bool isChefVision = false,
  }) async {
    print('DEBUG_CHEF: Tentando navegar para FoodIntelligenceScreen...');
    // 🛡️ Filtro de Integridade: Se houver imagem, vai para tela cheia (V135)
    // Se não, abre o BottomSheet (ResultCard)
    if (imageFile != null) {
      // 🚀 UNIFIED NAVIGATION: FoodIntelligenceScreen handles ChefVision too (V135)
      // Removed ChefRecipeScreen redirection to strict adherence to Unified UI.

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FoodIntelligenceScreen( // 🚀 UNIFIED NAVIGATION (2.5)
            analysis: analysis,
            imageFile: imageFile,
          ),
        ),
      );
    } else {
      // Falback for no-image scenario, or maybe direct to full screen as well?
      // "Abandon Legacy" -> Let's push to full screen even without image for consistency,
      // or keep ResultCard for modal. The prompt said "Abandono de Legado".
      // Let's use FoodIntelligenceScreen for EVERYTHING.
      await Navigator.push(
        context,
        MaterialPageRoute(
           builder: (context) => FoodIntelligenceScreen(
             analysis: analysis,
             imageFile: null,
           )
        )
      );
    }
  }

  /// Exibe o histórico de nutrição
  static void navigateToHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NutritionHistoryScreen()),
    );
  }

  /// Exibe a gestão de nutrição (Plano Semanal)
  static void navigateToManagement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NutritionHomeScreen()),
    );
  }
}
