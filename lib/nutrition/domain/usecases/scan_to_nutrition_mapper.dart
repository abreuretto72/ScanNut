import '../../../features/food/models/food_analysis_model.dart';
import '../data/models/meal.dart';
import '../data/models/meal_log.dart';

/// Mapper para converter FoodAnalysisModel (do scan) em MealItem/MealLog
class ScanToNutritionMapper {
  /// Converte FoodAnalysisModel em MealItem
  static MealItem toMealItem(FoodAnalysisModel analysis) {
    try {
      final nome = analysis.identidade.nome;
      final porcao = analysis.identidade.porcao ?? '1 porção';
      
      // Criar observações com macros
      final macros = analysis.macros;
      final observacoes = '${macros.calorias100g} kcal | '
          'P: ${macros.proteinas100g}g | '
          'C: ${macros.carboidratos100g}g | '
          'G: ${macros.gorduras100g}g';
      
      return MealItem(
        nome: nome,
        quantidadeTexto: porcao,
        observacoes: observacoes,
      );
    } catch (e) {
      // Fallback seguro
      return MealItem(
        nome: analysis.itemName,
        quantidadeTexto: '1 porção',
        observacoes: '${analysis.estimatedCalories} kcal (estimado)',
      );
    }
  }

  /// Converte FoodAnalysisModel em lista de MealItems
  static List<MealItem> toMealItems(FoodAnalysisModel analysis) {
    return [toMealItem(analysis)];
  }

  /// Cria MealLog a partir do scan
  static MealLog createMealLogFromScan({
    required FoodAnalysisModel analysis,
    required String tipo,
  }) {
    try {
      final itens = toMealItems(analysis);
      final observacoes = 'Adicionado via scan de foto | ${analysis.dicaEspecialista}';
      
      return MealLog.fromScan(
        tipo: tipo,
        itens: itens,
        observacoes: observacoes,
      );
    } catch (e) {
      // Fallback
      return MealLog.fromScan(
        tipo: tipo,
        itens: [
          MealItem(
            nome: analysis.itemName,
            quantidadeTexto: '1 porção',
            observacoes: '${analysis.estimatedCalories} kcal',
          )
        ],
        observacoes: 'Adicionado via scan',
      );
    }
  }

  /// Cria Meal a partir do scan para adicionar ao plano
  static Meal createMealFromScan({
    required FoodAnalysisModel analysis,
    required String tipo,
  }) {
    try {
      final itens = toMealItems(analysis);
      final observacoes = 'Adicionado via scan | ${analysis.dicaEspecialista}';
      
      return Meal(
        tipo: tipo,
        itens: itens,
        observacoes: observacoes,
        criadoEm: DateTime.now(),
      );
    } catch (e) {
      // Fallback
      return Meal(
        tipo: tipo,
        itens: [
          MealItem(
            nome: analysis.itemName,
            quantidadeTexto: '1 porção',
          )
        ],
        observacoes: 'Adicionado via scan',
        criadoEm: DateTime.now(),
      );
    }
  }
}
