import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/food_analysis_provider.dart';
import 'package:scannut/features/food/models/food_analysis_model.dart';
import 'food_result_screen.dart';
import 'widgets/result_card.dart';
import 'nutrition_history_screen.dart';
import '../../../nutrition/presentation/screens/nutrition_home_screen.dart';
import '../../../core/models/analysis_state.dart';
import '../services/nutrition_service.dart';

import 'package:scannut/features/food/presentation/chef_recipe_screen.dart';

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

      if (!context.mounted) return;

      // 2. Encaminha para o Tratamento de Resultado (Persistência + Navegação)
      if (context.mounted) {
        await handleResult(context, state, image, isChefVision: isChefVision);
      }
      
      // 3. Reset Final para Limpeza de Memória
      ref.read(foodAnalysisNotifierProvider.notifier).reset();
    } catch (e) {
      debugPrint('❌ FoodRouter Critical Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro Crítico: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Ponto de entrada atômico para processar o resultado da IA
  static Future<void> handleResult(BuildContext context, AnalysisState state, File? image, {bool isChefVision = false}) async {
    if (state is! AnalysisSuccess || state.data is! FoodAnalysisModel) return;
    
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
    // 🛡️ Filtro de Integridade: Se houver imagem, vai para tela cheia (V135)
    // Se não, abre o BottomSheet (ResultCard)
    if (imageFile != null) {
      // 🍳 CHEF VISION REDIRECT: New Screen for Inventory & Recipes
      if (isChefVision) {
         await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChefRecipeScreen(
                analysis: analysis,
                imageFile: imageFile,
              ),
            ),
         );
         return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FoodResultScreen(
            analysis: analysis,
            imageFile: imageFile,
            initialTab: 0,
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ResultCard(
          analysis: analysis,
        ),
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
