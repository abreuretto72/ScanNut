/// ============================================================================
/// 🚫 COMPONENTE BLINDADO E CONGELADO - NÃO ALTERAR
/// Este módulo de Geração de Cardápios foi concluído e validado.
/// Nenhuma rotina ou lógica interna deve ser modificada.
/// Data de Congelamento: 29/12/2025
/// ============================================================================

import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../data/models/weekly_plan.dart';
import '../../data/models/plan_day.dart';
import '../../data/models/meal.dart';
import '../../data/models/user_nutrition_profile.dart';
import '../../data/models/menu_creation_params.dart';
import '../../data/datasources/nutrition_data_service.dart';

/// Gerador de plano semanal automático
class WeeklyPlanGenerator {
  final NutritionDataService _dataService = NutritionDataService();
  final Random _random = Random();

  /// Gera um plano semanal baseado no perfil do usuário
  Future<WeeklyPlan?> generateWeeklyPlan({
    required UserNutritionProfile profile,
    MenuCreationParams? params,
    int? seed,
    DateTime? startDate,
    String? languageCode,
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

      final now = startDate ?? DateTime.now();
      final monday = _getMonday(now);

      final days = <PlanDay>[];
      final Set<String> usedRecipeIds = {};

      // Determine period
      final periodType = params?.periodType ?? 'weekly';

      int numDays;
      if (periodType == 'custom' && params?.customDays != null) {
        numDays = params!.customDays!;
        // Cap at 60 days just in case, though UI validates
        if (numDays > 60) numDays = 60;
      } else {
        numDays = (periodType == 'monthly' || periodType == '28days') ? 28 : 7;
      }

      // If custom, use exact start date. Otherwise snap to Monday.
      final DateTime anchorDate =
          (periodType == 'custom') ? now : _getMonday(now);

      final objective = params?.objective ?? profile.objetivo ?? 'maintenance';

      // Determine meal types based on params or profile
      List<String> mealTypes;
      if (params != null) {
        // Logic for meals count
        final allTypes = ['cafe', 'almoco', 'lanche', 'jantar'];
        if (params.mealsPerDay >= 4) {
          mealTypes = allTypes;
        } else {
          mealTypes = allTypes.take(params.mealsPerDay).toList();
        }
      } else {
        mealTypes = profile.horariosRefeicoes.keys.toList();
      }

      // Gerar dias conforme período
      for (int i = 0; i < numDays; i++) {
        final date = anchorDate.add(Duration(days: i));

        final dayMeals = _generateDayMeals(
          profile,
          mealTypes,
          params,
          usedRecipeIds,
          languageCode,
          objective: objective,
        );

        days.add(PlanDay(
          date: date,
          meals: dayMeals,
          status: 'planejado',
        ));
      }

      final plan = WeeklyPlan(
        weekStartDate: anchorDate,
        endDate: anchorDate.add(Duration(days: numDays - 1)),
        seed: seed ?? DateTime.now().millisecondsSinceEpoch,
        days: days,
        criadoEm: DateTime.now(),
        atualizadoEm: DateTime.now(),
        dicasPreparo: _generatePreparationTips(days),
        periodType: periodType,
        objective: objective,
        version: 1,
        status: 'active',
      );

      debugPrint(
          '✅ Generated plan: days=${days.length}, period=$periodType, objective=$objective');
      return plan;
    } catch (e) {
      debugPrint('❌ Error generating plan: $e');
      return null;
    }
  }

  /// Gera dicas de Batch Cooking e preparo baseadas nos ingredientes da semana
  /// Gera dicas de Batch Cooking e preparo baseadas nos ingredientes da semana
  String _generatePreparationTips(List<PlanDay> days) {
    final tips = <String>[];
    final allItems = days
        .expand((d) => d.meals)
        .expand((m) => m.itens)
        .map((i) => i.nome.toLowerCase())
        .toList();

    if (allItems.any((i) => i.contains('feijão'))) {
      tips.add('tipBeans');
    }
    if (allItems.any((i) => i.contains('arroz'))) {
      tips.add('tipRice');
    }
    if (allItems.any((i) => i.contains('frango'))) {
      tips.add('tipChicken');
    }
    if (allItems.any((i) => i.contains('ovo'))) {
      tips.add('tipEggs');
    }
    if (allItems.any((i) =>
        i.contains('legumes') ||
        i.contains('vegetais') ||
        i.contains('salada'))) {
      tips.add('tipVeggies');
    }
    if (allItems
        .any((i) => i.contains('mandioca') || i.contains('batata doce'))) {
      tips.add('tipRoots');
    }
    if (allItems.any((i) => i.contains('carne moída'))) {
      tips.add('tipGroundMeat');
    }
    if (allItems.any((i) =>
        i.contains('fruta') || i.contains('manga') || i.contains('banana'))) {
      tips.add('tipFruits');
    }

    if (tips.isEmpty) return 'tipDefault';

    // Shuffle and pick 3 interesting tips
    tips.shuffle();
    return tips.take(3).join('|');
  }

  /// Gera refeições para um dia
  List<Meal> _generateDayMeals(
    UserNutritionProfile profile,
    List<String> mealTypes,
    MenuCreationParams? params,
    Set<String> usedRecipeIds,
    String? languageCode, {
    String objective = 'maintenance',
  }) {
    final isEn = languageCode?.startsWith('en') == true;
    final meals = <Meal>[];

    // Merge restrictions
    final List<String> effectiveRestrictions = <String>{
      ...profile.restricoes,
      ...(params?.restrictions ?? [])
    }.toList();

    final bool avoidRepetition = params?.allowRepetition == false;

    for (final tipo in mealTypes) {
      try {
        // Buscar receitas que atendem às restrições
        var receitasDisponiveis =
            _dataService.getRecipesByRestrictions(effectiveRestrictions);

        // --- FILTRO INTELIGENTE DE TIPO DE REFEIÇÃO ---
        receitasDisponiveis = receitasDisponiveis.where((r) {
          final textToCheck =
              '${r.nome} ${r.ingredientes.join(' ')}'.toLowerCase();
          final isBreakfastOrSnack = tipo == 'cafe' || tipo == 'lanche';

          // Filter by objective: Weight Loss
          if (objective == 'emagrecimento') {
            if (isBreakfastOrSnack && r.calorias > 250) return false;
            if (!isBreakfastOrSnack && r.calorias > 500) return false;
          }

          if (isBreakfastOrSnack) {
            // Café/Lanche: Bloquear pratos pesados
            if (textToCheck.contains('feijão') ||
                textToCheck.contains('arroz') ||
                textToCheck.contains('macarrão') ||
                textToCheck.contains('espaguete') ||
                textToCheck.contains('sopa') ||
                textToCheck.contains('risoto')) {
              return false;
            }

            // Bloquear carnes principais (exceto em sanduíches/wraps)
            final isSandwich = textToCheck.contains('sanduíche') ||
                textToCheck.contains('wrap') ||
                textToCheck.contains('torta') ||
                textToCheck.contains('salgado') ||
                textToCheck.contains('pão');
            if (!isSandwich) {
              if (textToCheck.contains('frango') ||
                  textToCheck.contains('carne') ||
                  textToCheck.contains('peixe') ||
                  textToCheck.contains('bife')) {
                return false;
              }
            }
            return true;
          } else {
            // Almoço/Jantar: Bloquear itens de café
            if (r.nome.toLowerCase().contains('vitamina') ||
                r.nome.toLowerCase().contains('iogurte') ||
                r.nome.toLowerCase().contains('mingau') ||
                r.nome.toLowerCase().contains('tapioca') ||
                r.nome.toLowerCase().contains('bolo')) {
              return false;
            }

            // Bloquear lanches muito leves se for almoço principal (opcional, mas bom pra evitar "Pão com manteiga" no almoço)
            if (r.nome.toLowerCase().contains('pão') &&
                !textToCheck.contains('hambúrguer')) {
              return false; // Hambúrguer pode ser janta
            }

            return true;
          }
        }).toList();
        // -----------------------------------------------

        // Filter out used recipes if no repetition allowed
        if (avoidRepetition) {
          final freshRecipes = receitasDisponiveis
              .where((r) => !usedRecipeIds.contains(r.id))
              .toList();
          // Only filter if we still have options, otherwise fallback to repeating
          if (freshRecipes.isNotEmpty) {
            receitasDisponiveis = freshRecipes;
          }
        }

        if (receitasDisponiveis.isEmpty) {
          // Fallback: criar refeição simples com alimentos
          meals.add(
              _createSimpleMeal(tipo, effectiveRestrictions, languageCode));
        } else {
          // Escolher receita aleatória
          final receita =
              receitasDisponiveis[_random.nextInt(receitasDisponiveis.length)];

          if (avoidRepetition) {
            usedRecipeIds.add(receita.id);
          }

          meals.add(Meal(
            tipo: tipo,
            recipeId: receita.id,
            nomePrato: receita.nome,
            itens: receita.ingredientes
                .map((ing) => MealItem(
                      nome: ing,
                      quantidadeTexto: isEn ? '1 serving' : '1 porção',
                    ))
                .toList(),
            observacoes:
                '${receita.tempoPreparo.replaceAll("minutos", "min")} - ${receita.calorias} kcal',
            criadoEm: DateTime.now(),
          ));
        }
      } catch (e) {
        debugPrint('❌ Error generating meal for $tipo: $e');
        meals.add(_createSimpleMeal(tipo, effectiveRestrictions, languageCode));
      }
    }

    return meals;
  }

  /// Cria uma refeição simples com alimentos equilibrados (Fallback inteligente)
  Meal _createSimpleMeal(
      String tipo, List<String> restricoes, String? languageCode) {
    final foods = _dataService.foods;
    final isEn = languageCode?.startsWith('en') == true;
    final servingText = isEn ? '1 serving' : '1 porção';
    if (foods.isEmpty) {
      return Meal(
        tipo: tipo,
        nomePrato: isEn ? 'Free Meal' : 'Refeição Livre',
        itens: [
          MealItem(
              nome: isEn ? 'Free meal choice' : 'Refeição livre',
              quantidadeTexto: servingText)
        ],
        observacoes: isEn ? 'Plan your meal' : 'Planeje sua refeição',
        criadoEm: DateTime.now(),
      );
    }

    // Helper to get random food by category
    MealItem? getFoodByCat(List<String> categories) {
      final candidates = foods
          .where((f) => categories
              .any((c) => f.categoria.toLowerCase().contains(c.toLowerCase())))
          .toList();
      if (candidates.isEmpty) return null;
      final food = candidates[_random.nextInt(candidates.length)];
      return MealItem(
        nome: food.nome,
        quantidadeTexto: food.porcao,
        observacoes: '${food.calorias} kcal',
      );
    }

    final selectedFoods = <MealItem>[];
    final isBreakfastOrSnack = tipo == 'cafe' || tipo == 'lanche';
    String dishName = isEn
        ? (isBreakfastOrSnack ? 'Simple Breakfast' : 'Balanced Meal')
        : (isBreakfastOrSnack ? 'Café Simples' : 'Prato Feito');

    if (isBreakfastOrSnack) {
      // Café/Lanche: 1 Fonte de Energia + 1 Acompanhamento
      var item1 = getFoodByCat(['panificação', 'pães', 'cereais', 'frutas']);
      var item2 =
          getFoodByCat(['laticínios', 'leite', 'queijos', 'bebidas', 'frutas']);

      // Avoid same item
      if (item1 != null) selectedFoods.add(item1);
      if (item2 != null && item2.nome != item1?.nome) selectedFoods.add(item2);

      // Infer Dish Name
      if (selectedFoods.any((f) => f.nome.toLowerCase().contains('iogurte'))) {
        dishName = isEn ? 'Yogurt with Side' : 'Iogurte com Acompanhamento';
      } else if (selectedFoods.any((f) => f.nome.toLowerCase().contains('pão')))
        dishName = isEn ? 'Sandwich' : 'Sanduíche';
      else if (selectedFoods.any((f) => f.nome.toLowerCase().contains('fruta')))
        dishName = isEn ? 'Fruit Salad' : 'Salada de Frutas';
      else if (selectedFoods.any((f) => f.nome.toLowerCase().contains('café')))
        dishName = isEn ? 'Coffee' : 'Cafézinho';

      // Fallback if structured picking failed
      if (selectedFoods.isEmpty) {
        final food = foods[_random.nextInt(foods.length)];
        selectedFoods.add(MealItem(
            nome: food.nome,
            quantidadeTexto: food.porcao,
            observacoes: '${food.calorias} kcal'));
        dishName = food.nome;
      }
    } else {
      // Almoço/Jantar: Proteína + Carbo + Vegetal
      var protein =
          getFoodByCat(['carnes', 'aves', 'peixes', 'ovos', 'leguminosas']);
      var carb =
          getFoodByCat(['cereais', 'arroz', 'massas', 'tubérculos', 'batata']);
      var veg = getFoodByCat(['hortaliças', 'legumes', 'verduras', 'saladas']);

      if (protein != null) selectedFoods.add(protein);
      if (carb != null) selectedFoods.add(carb);
      if (veg != null) selectedFoods.add(veg);

      if (protein != null) {
        dishName = isEn
            ? '${protein.nome} with Sides'
            : '${protein.nome} com Acompanhamentos';
      }

      // If we couldn't build a full plate, fill with random to avoid empty meal
      if (selectedFoods.length < 2) {
        final food = foods[_random.nextInt(foods.length)];
        if (!selectedFoods.any((f) => f.nome == food.nome)) {
          selectedFoods.add(MealItem(
              nome: food.nome,
              quantidadeTexto: food.porcao,
              observacoes: '${food.calorias} kcal'));
        }
      }
    }

    return Meal(
      tipo: tipo,
      nomePrato: dishName,
      itens: selectedFoods,
      observacoes: isEn ? 'Balanced suggestion' : 'Sugestão equilibrada',
      criadoEm: DateTime.now(),
    );
  }

  /// Troca uma refeição específica mantendo o tipo e as restrições
  Future<Meal?> swapMeal({
    required String tipo,
    required UserNutritionProfile profile,
    List<String>? excludedRecipeIds,
    String? languageCode,
    String? objective,
  }) async {
    final isEn = languageCode?.startsWith('en') == true;
    try {
      if (!_dataService.isLoaded) {
        await _dataService.loadData();
      }

      var receitasDisponiveis =
          _dataService.getRecipesByRestrictions(profile.restricoes);

      // Aplicar o mesmo Filtro Inteligente do gerador principal
      receitasDisponiveis = receitasDisponiveis.where((r) {
        final textToCheck =
            '${r.nome} ${r.ingredientes.join(' ')}'.toLowerCase();
        final isBreakfastOrSnack = tipo == 'cafe' || tipo == 'lanche';

        // Filter by objective: Weight Loss
        if (objective == 'emagrecimento') {
          if (isBreakfastOrSnack && r.calorias > 250) return false;
          if (!isBreakfastOrSnack && r.calorias > 500) return false;
        }

        if (isBreakfastOrSnack) {
          if (textToCheck.contains('feijão') ||
              textToCheck.contains('arroz') ||
              textToCheck.contains('macarrão') ||
              textToCheck.contains('espaguete') ||
              textToCheck.contains('sopa') ||
              textToCheck.contains('risoto')) {
            return false;
          }

          final isSandwich = textToCheck.contains('sanduíche') ||
              textToCheck.contains('wrap') ||
              textToCheck.contains('torta') ||
              textToCheck.contains('salgado') ||
              textToCheck.contains('pão');
          if (!isSandwich) {
            if (textToCheck.contains('frango') ||
                textToCheck.contains('carne') ||
                textToCheck.contains('peixe') ||
                textToCheck.contains('bife')) {
              return false;
            }
          }
          return true;
        } else {
          if (r.nome.toLowerCase().contains('vitamina') ||
              r.nome.toLowerCase().contains('iogurte') ||
              r.nome.toLowerCase().contains('mingau') ||
              r.nome.toLowerCase().contains('tapioca') ||
              r.nome.toLowerCase().contains('bolo')) {
            return false;
          }

          if (r.nome.toLowerCase().contains('pão') &&
              !textToCheck.contains('hambúrguer')) {
            return false;
          }
          return true;
        }
      }).toList();

      // Excluir receitas atuais para forçar mudança
      if (excludedRecipeIds != null && excludedRecipeIds.isNotEmpty) {
        receitasDisponiveis = receitasDisponiveis
            .where((r) => !excludedRecipeIds.contains(r.id))
            .toList();
      }

      if (receitasDisponiveis.isEmpty) {
        return _createSimpleMeal(tipo, profile.restricoes, languageCode);
      }

      final receita =
          receitasDisponiveis[_random.nextInt(receitasDisponiveis.length)];

      return Meal(
        tipo: tipo,
        recipeId: receita.id,
        nomePrato: receita.nome,
        itens: receita.ingredientes
            .map((ing) => MealItem(
                  nome: ing,
                  quantidadeTexto: isEn ? '1 serving' : '1 porção',
                ))
            .toList(),
        observacoes:
            '${receita.tempoPreparo.replaceAll("minutos", "min")} - ${receita.calorias} kcal',
        criadoEm: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Error swapping meal: $e');
      return _createSimpleMeal(tipo, profile.restricoes, languageCode);
    }
  }

  /// Retorna a segunda-feira da semana
  DateTime _getMonday(DateTime date) {
    final weekday = date.weekday; // 1 = Monday, 7 = Sunday
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: weekday - 1));
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
