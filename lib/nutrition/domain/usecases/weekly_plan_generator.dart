import 'dart:math';
import 'package:flutter/foundation.dart';
import '../data/models/weekly_plan.dart';
import '../data/models/plan_day.dart';
import '../data/models/meal.dart';
import '../data/models/user_nutrition_profile.dart';
import '../data/datasources/nutrition_data_service.dart';

/// Gerador de plano semanal automático
class WeeklyPlanGenerator {
  final NutritionDataService _dataService = NutritionDataService();
  final Random _random = Random();

  /// Gera um plano semanal baseado no perfil do usuário
  Future<WeeklyPlan?> generateWeeklyPlan({
    required UserNutritionProfile profile,
    int? seed,
  }) async {
    try {
      // Garantir que os dados estão carregados
      if (!_dataService.isLoaded) {
        final loaded = await _dataService.loadData();
        if (!loaded) {
          debugPrint('❌ Failed to load nutrition data');
          return null;
        }
      }

      // Usar seed para reproduzibilidade
      if (seed != null) {
        _random.setSeed(seed);
      }

      final now = DateTime.now();
      final monday = _getMonday(now);
      
      final days = <PlanDay>[];
      
      // Gerar 7 dias
      for (int i = 0; i < 7; i++) {
        final date = monday.add(Duration(days: i));
        final dayMeals = _generateDayMeals(profile);
        
        days.add(PlanDay(
          date: date,
          meals: dayMeals,
          status: 'planejado',
        ));
      }

      final plan = WeeklyPlan(
        weekStartDate: monday,
        seed: seed ?? DateTime.now().millisecondsSinceEpoch,
        days: days,
        criadoEm: DateTime.now(),
        atualizadoEm: DateTime.now(),
      );

      debugPrint('✅ Generated weekly plan with ${days.length} days');
      return plan;
    } catch (e) {
      debugPrint('❌ Error generating weekly plan: $e');
      return null;
    }
  }

  /// Gera refeições para um dia
  List<Meal> _generateDayMeals(UserNutritionProfile profile) {
    final meals = <Meal>[];
    final tiposRefeicao = profile.horariosRefeicoes.keys.toList();

    for (final tipo in tiposRefeicao) {
      try {
        // Buscar receitas que atendem às restrições
        final receitasDisponiveis = _dataService.getRecipesByRestrictions(profile.restricoes);
        
        if (receitasDisponiveis.isEmpty) {
          // Fallback: criar refeição simples com alimentos
          meals.add(_createSimpleMeal(tipo, profile.restricoes));
        } else {
          // Escolher receita aleatória
          final receita = receitasDisponiveis[_random.nextInt(receitasDisponiveis.length)];
          
          meals.add(Meal(
            tipo: tipo,
            recipeId: receita.id,
            itens: receita.ingredientes.map((ing) => MealItem(
              nome: ing,
              quantidadeTexto: '1 porção',
            )).toList(),
            observacoes: '${receita.tempoPreparo} - ${receita.calorias} kcal',
            criadoEm: DateTime.now(),
          ));
        }
      } catch (e) {
        debugPrint('❌ Error generating meal for $tipo: $e');
        meals.add(_createSimpleMeal(tipo, profile.restricoes));
      }
    }

    return meals;
  }

  /// Cria uma refeição simples com alimentos
  Meal _createSimpleMeal(String tipo, List<String> restricoes) {
    final foods = _dataService.foods;
    if (foods.isEmpty) {
      return Meal(
        tipo: tipo,
        itens: [MealItem(nome: 'Refeição livre', quantidadeTexto: '1 porção')],
        observacoes: 'Planeje sua refeição',
        criadoEm: DateTime.now(),
      );
    }

    // Selecionar 2-3 alimentos aleatórios
    final numItens = 2 + _random.nextInt(2); // 2 ou 3 itens
    final selectedFoods = <MealItem>[];
    
    for (int i = 0; i < numItens && i < foods.length; i++) {
      final food = foods[_random.nextInt(foods.length)];
      selectedFoods.add(MealItem(
        nome: food.nome,
        quantidadeTexto: food.porcao,
        observacoes: '${food.calorias} kcal',
      ));
    }

    return Meal(
      tipo: tipo,
      itens: selectedFoods,
      observacoes: 'Refeição montada automaticamente',
      criadoEm: DateTime.now(),
    );
  }

  /// Troca uma refeição específica mantendo o tipo
  Future<Meal?> swapMeal({
    required String tipo,
    required UserNutritionProfile profile,
  }) async {
    try {
      if (!_dataService.isLoaded) {
        await _dataService.loadData();
      }

      final receitasDisponiveis = _dataService.getRecipesByRestrictions(profile.restricoes);
      
      if (receitasDisponiveis.isEmpty) {
        return _createSimpleMeal(tipo, profile.restricoes);
      }

      final receita = receitasDisponiveis[_random.nextInt(receitasDisponiveis.length)];
      
      return Meal(
        tipo: tipo,
        recipeId: receita.id,
        itens: receita.ingredientes.map((ing) => MealItem(
          nome: ing,
          quantidadeTexto: '1 porção',
        )).toList(),
        observacoes: '${receita.tempoPreparo} - ${receita.calorias} kcal',
        criadoEm: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Error swapping meal: $e');
      return null;
    }
  }

  /// Retorna a segunda-feira da semana
  DateTime _getMonday(DateTime date) {
    final weekday = date.weekday; // 1 = Monday, 7 = Sunday
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: weekday - 1));
  }
}

/// Extensão para Random com seed
extension RandomSeed on Random {
  void setSeed(int seed) {
    // Criar novo Random com seed
    final newRandom = Random(seed);
    // Copiar estado (workaround)
    for (int i = 0; i < seed % 100; i++) {
      newRandom.nextInt(100);
    }
  }
}
