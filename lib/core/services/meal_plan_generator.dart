import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../enums/scannut_mode.dart';
import '../services/gemini_service.dart';
import '../services/meal_history_service.dart';

final mealPlanGeneratorProvider = Provider((ref) => MealPlanGenerator(ref));

class MealPlanGenerator {
  final Ref _ref;

  MealPlanGenerator(this._ref);

  /// Generate a new weekly meal plan with rotation logic
  Future<Map<String, dynamic>> generateNewWeeklyPlan({
    required String petName,
    required String raceName,
    File? petImage,
  }) async {
    // Get recent ingredients to exclude
    final mealHistoryService = _ref.read(mealHistoryServiceProvider);
    final excludedIngredients = await mealHistoryService.getRecentIngredients(petName);

    // Use Gemini to generate new plan
    final geminiService = GeminiService();
    
    // If we have an image, use it; otherwise, create a text-only request
    // For now, we'll create a simplified prompt for meal generation only
    final prompt = _buildMealGenerationPrompt(raceName, excludedIngredients);
    
    // TODO: Implement text-only Gemini request or use cached pet data
    // For now, return a placeholder response
    throw UnimplementedError('Meal generation requires pet analysis data');
  }

  String _buildMealGenerationPrompt(String raceName, List<String> excludedIngredients) {
    final exclusionText = excludedIngredients.isEmpty
        ? 'Nenhuma restrição.'
        : 'EVITE os seguintes ingredientes usados recentemente: ${excludedIngredients.join(", ")}.';

    return '''
Atue como Nutrólogo Pet especializado em Alimentação Natural (AN).
Gere um novo plano semanal de 7 dias para a raça: $raceName.

$exclusionText

REGRAS:
- PROIBIDO sugerir ração ou alimentos processados
- Use apenas: Proteínas (carnes, ovos), Vísceras, Vegetais, Carboidratos saudáveis
- Varie os ingredientes para garantir rotação nutricional

Responda em JSON:
{
  "plano_semanal": [
    {"dia": "Segunda-feira", "refeicao": "string", "beneficio": "string"}
  ],
  "orientacoes_gerais": "string"
}
''';
  }
}
