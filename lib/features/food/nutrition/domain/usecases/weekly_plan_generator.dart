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
          
          // 🛡️ LOG REQ: Rastreabilidade da "IA"
          debugPrint('📥 [MenuGen] RESPOSTA BRUTA DA IA (Simulada): ${receita.toJson()}');
          debugPrint('   -> Selected Recipe: ${receita.nome} | ID: ${receita.id}');

          // 🛡️ REQ V135: Enriched Title & Instructions
          String finalTitle = receita.nome;
          String extraInstructions = '';
          
          if (receita.ingredientes.length > 1) { // Removed ' com ' check to guarantee side instructions
             if (receita.ingredientes.any((i) => i.toLowerCase().contains('arroz'))) {
               if (!finalTitle.contains('Completo') && !finalTitle.contains(' com ') && !finalTitle.contains('Arroz')) finalTitle = '$finalTitle Completo';
               extraInstructions += '\n\n🍚 ARROZ: Refogue alho e cebola no azeite. Adicione o arroz e sal. Coloque 2 medidas de água fervente para 1 de arroz. Cozinhe em fogo baixo até secar.';
             }
             if (receita.ingredientes.any((i) => i.toLowerCase().contains('feijão'))) {
               if (!finalTitle.contains('Completo') && !finalTitle.contains(' com ') && !finalTitle.contains('Feijão')) finalTitle = '$finalTitle com Feijão';
               extraInstructions += '\n\n🫘 FEIJÃO: Se usar pré-cozido, refogue alho no azeite, adicione o feijão e deixe apurar o caldo. Finalize com cheiro-verde.';
             }
             if (receita.ingredientes.any((i) => i.toLowerCase().contains('salada') || i.toLowerCase().contains('folhas'))) {
               if (!finalTitle.contains('Completo') && !finalTitle.contains(' com ')) finalTitle = '$finalTitle Leve';
               extraInstructions += '\n\n🥗 SALADA: Lave e seque bem as folhas. Prepare um molho com azeite, limão e sal. Só tempere na hora de servir para não murchar.';
             }
             if (receita.ingredientes.any((i) => i.toLowerCase().contains('purê') || i.toLowerCase().contains('batata'))) {
                extraInstructions += '\n\n🥔 PURÊ/BATATA: Cozinhe as batatas até ficarem macias. Amasse bem, adicione manteiga e um pouco de leite. Mexa até ficar cremoso. Ajuste o sal.';
             }
          }

          meals.add(Meal(
            tipo: tipo,
            recipeId: receita.id, // Keep ID for base lookup too
            nomePrato: finalTitle,
            itens: receita.ingredientes.map((ing) {
              String qtd = '';
              String nome = ing;
              final lower = ing.toLowerCase();

              // 1. Try Regex Extraction (e.g. "200g Frango")
              final regex = RegExp(r'^(\d+(?:[.,]\d+)?\s?(?:g|kg|ml|l|col|un|fatia|xícara|copo)s?\.?)\s+(.*)$', caseSensitive: false);
              final match = regex.firstMatch(ing);
              
              if (match != null) {
                qtd = match.group(1) ?? '';
                nome = match.group(2) ?? ing;
              } 
              
              // 2. Fallback to centralized Smart Engine
              qtd = _getSmartQuantity(nome, qtd, isEn);

              // Capitalize name
              if (nome.isNotEmpty) {
                nome = nome[0].toUpperCase() + nome.substring(1);
              }

              return MealItem(
                nome: nome,
                quantidadeTexto: qtd,
              );
            }).toList(),
            observacoes:
                '${receita.tempoPreparo.replaceAll("minutos", "min")} - ${receita.calorias} kcal|||${receita.modoPreparo}\n$extraInstructions',
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

    // Helper to get random food by category with Smart Quantity
    MealItem? getFoodByCat(List<String> categories) {
      final candidates = foods
          .where((f) => categories
              .any((c) => f.categoria.toLowerCase().contains(c.toLowerCase())))
          .toList();
      if (candidates.isEmpty) return null;
      final food = candidates[_random.nextInt(candidates.length)];
      
      // 🛡️ REQ V135: Smart Quantity Logic (Unified)
      final qtd = _getSmartQuantity(food.nome, food.porcao, isEn);

      return MealItem(
        nome: food.nome,
        quantidadeTexto: qtd,
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
        // Apply smart logic manually for single item fallback
        selectedFoods.add(getFoodByCat([food.categoria]) ?? MealItem(
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
           selectedFoods.add(getFoodByCat([food.categoria]) ?? MealItem(
              nome: food.nome,
              quantidadeTexto: food.porcao,
              observacoes: '${food.calorias} kcal'));
        }
      }
    }

    // 🛡️ REQ V135: Dynamic Instructions for Simple Meals
    String instructions = isEn 
        ? '1. Organize the ingredients.\n2. Prepare the main protein (grilled or roasted).\n3. Serve with the sides.'
        : '1. Organize os ingredientes.\n2. Prepare a proteína principal (grelhada ou assada).\n3. Sirva com os acompanhamentos.';
        
    // Generate specialized instructions based on items
    final instructionsList = <String>[];
    for (var item in selectedFoods) {
       final n = item.nome.toLowerCase();
       if (n.contains('arroz')) instructionsList.add('🍚 ARROZ: Refogue alho, adicione arroz e água (2:1). Cozinhe até secar.');
       else if (n.contains('feijão')) instructionsList.add('🫘 FEIJÃO: Tempere o feijão cozido com alho e cebola refogados.');
       else if (n.contains('frango')) instructionsList.add('🍗 FRANGO: Tempere com limão, sal e pimenta. Grelhe em frigideira quente até dourar.');
       else if (n.contains('ovo')) instructionsList.add('🥚 OVO: Prepare cozido (8min) ou mexido com pouco óleo.');
       else if (n.contains('salada')) instructionsList.add('🥗 SALADA: Higienize as folhas e tempere apenas na hora de servir.');
       else if (n.contains('pão')) instructionsList.add('🍞 PÃO: Pode ser tostado levemente na frigideira.');
    }
    
    if (instructionsList.isNotEmpty) {
       instructions = instructionsList.join('\n\n');
    }

    return Meal(
      tipo: tipo,
      nomePrato: dishName,
      itens: selectedFoods,
      observacoes: (isEn ? 'Balanced choice' : 'Escolha equilibrada') + '|||' + instructions,
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

      // 🛡️ REQ V135: Enriched Logic reuse for Swapped Meals
      String finalTitle = receita.nome;
      String extraInstructions = '';
      
      if (receita.ingredientes.length > 1) {
         if (receita.ingredientes.any((i) => i.toLowerCase().contains('arroz'))) {
           if (!finalTitle.contains('Completo') && !finalTitle.contains(' com ') && !finalTitle.contains('Arroz')) finalTitle = '$finalTitle Completo';
           extraInstructions += '\n\n🍚 ARROZ: Refogue alho e cebola no azeite. Adicione o arroz e sal. Coloque 2 medidas de água fervente para 1 de arroz. Cozinhe em fogo baixo até secar.';
         }
         if (receita.ingredientes.any((i) => i.toLowerCase().contains('feijão'))) {
           if (!finalTitle.contains('Completo') && !finalTitle.contains(' com ') && !finalTitle.contains('Feijão')) finalTitle = '$finalTitle com Feijão';
           extraInstructions += '\n\n🫘 FEIJÃO: Se usar pré-cozido, refogue alho no azeite, adicione o feijão e deixe apurar o caldo. Finalize com cheiro-verde.';
         }
         if (receita.ingredientes.any((i) => i.toLowerCase().contains('salada') || i.toLowerCase().contains('folhas'))) {
           if (!finalTitle.contains('Completo') && !finalTitle.contains(' com ')) finalTitle = '$finalTitle Leve';
           extraInstructions += '\n\n🥗 SALADA: Lave e seque bem as folhas. Prepare um molho com azeite, limão e sal. Só tempere na hora de servir para não murchar.';
         }
         if (receita.ingredientes.any((i) => i.toLowerCase().contains('purê') || i.toLowerCase().contains('batata'))) {
            extraInstructions += '\n\n🥔 PURÊ/BATATA: Cozinhe as batatas até ficarem macias. Amasse bem, adicione manteiga e um pouco de leite. Mexa até ficar cremoso. Ajuste o sal.';
         }
      }

      return Meal(
        tipo: tipo,
        recipeId: receita.id,
        nomePrato: finalTitle,
        itens: receita.ingredientes.map((ing) {
              String qtd = '';
              String nome = ing;
              final lower = ing.toLowerCase();

              // 1. Try Regex Extraction
              final regex = RegExp(r'^(\d+(?:[.,]\d+)?\s?(?:g|kg|ml|l|col|un|fatia|xícara|copo)s?\.?)\s+(.*)$', caseSensitive: false);
              final match = regex.firstMatch(ing);
              
              if (match != null) {
                qtd = match.group(1) ?? '';
                nome = match.group(2) ?? ing;
              } 
              
              // 2. Fallback to centralized Smart Engine
              qtd = _getSmartQuantity(nome, qtd, isEn);

              if (nome.isNotEmpty) nome = nome[0].toUpperCase() + nome.substring(1);

              return MealItem(
                nome: nome,
                quantidadeTexto: qtd,
              );
            }).toList(),
        observacoes:
            '${receita.tempoPreparo.replaceAll("minutos", "min")} - ${receita.calorias} kcal|||${receita.modoPreparo}\n$extraInstructions',
        criadoEm: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Error swapping meal: $e');
      return _createSimpleMeal(tipo, profile.restricoes, languageCode);
    }
  }

  // 🛡️ REQ V135: Smart Quantity Engine
  String _getSmartQuantity(String name, String currentQtd, bool isEn) {
      if (currentQtd.isNotEmpty && !currentQtd.contains('1 porção') && !currentQtd.contains('1 serving')) {
          return currentQtd;
      }
      
      final lower = name.toLowerCase();
      
      // Protein
      if (lower.contains('frango') || lower.contains('carne') || lower.contains('peixe') || lower.contains('bife') || lower.contains('filé') || lower.contains('hambúrguer') || lower.contains('lombo')) return '1 filé médio (120g)';
      if (lower.contains('ovo') || lower.contains('omelete')) return isEn ? '2 large units' : '2 ovos grandes';
      if (lower.contains('queijo') || lower.contains('presunto')) return isEn ? '2 slices' : '2 fatias médias';
      
      // Carbs
      if (lower.contains('arroz')) return isEn ? '1 cup (cooked)' : '1 escumadeira cheia';
      if (lower.contains('feijão') || lower.contains('lentilha') || lower.contains('grão')) return isEn ? '1 ladle' : '1 concha média';
      if (lower.contains('purê') || lower.contains('batata') || lower.contains('mandioca') || lower.contains('inhame')) return isEn ? '3 tbsp' : '3 col. servir';
      if (lower.contains('macarrão') || lower.contains('espaguete') || lower.contains('penne') || lower.contains('lasanha')) return isEn ? '1.5 cups' : '1 prato raso';
      if (lower.contains('pão') || lower.contains('torrada') || lower.contains('bagel')) return isEn ? '2 slices' : '2 fatias';
      if (lower.contains('tapioca') || lower.contains('panqueca') || lower.contains('waffle')) return isEn ? '1 unit' : '1 unidade';
      if (lower.contains('aveia') || lower.contains('granola') || lower.contains('cereal')) return isEn ? '3 tbsp' : '3 col. sopa';
      if (lower.contains('bolo')) return isEn ? '1 slice' : '1 fatia média';
      
      // Veggies & Fruits
      if (lower.contains('salada') || lower.contains('folhas') || lower.contains('alface') || lower.contains('rúcula')) return isEn ? 'Fill half plate' : 'Metade do prato';
      if (lower.contains('legumes') || lower.contains('cenoura') || lower.contains('abobrinha') || lower.contains('brócolis') || lower.contains('vagem')) return isEn ? '1 cup' : '1 pires cheio';
      if (lower.contains('tomate') || lower.contains('cebola') || lower.contains('pepino')) return isEn ? '1/2 unit' : '1/2 unidade';
      if (lower.contains('fruta') || lower.contains('banana') || lower.contains('maçã') || lower.contains('laranja') || lower.contains('pera')) return isEn ? '1 unit' : '1 unidade';
      if (lower.contains('abacate') || lower.contains('mamão') || lower.contains('manga')) return isEn ? '1/2 unit' : '1/2 unidade';
      if (lower.contains('morango') || lower.contains('uva')) return isEn ? '10 units' : '10 unidades';

      // Liquids & Others
      if (lower.contains('leite') || lower.contains('iogurte') || lower.contains('suco') || lower.contains('café') || lower.contains('chá') || lower.contains('vitamina') || lower.contains('whey')) return isEn ? '1 glass (200ml)' : '1 copo (200ml)';
      if (lower.contains('azeite') || lower.contains('óleo')) return isEn ? '1 tsp' : '1 fio generoso';
      if (lower.contains('manteiga') || lower.contains('requeijão') || lower.contains('pasta')) return isEn ? '1 tsp' : '1 ponta de faca';
      if (lower.contains('mel') || lower.contains('açúcar') || lower.contains('adoçante')) return isEn ? '1 tsp' : '1 col. chá';
      
      // Default
      return isEn ? '1 portion' : '1 porção média';
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
