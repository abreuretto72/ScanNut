import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Modelo de alimento
class FoodItem {
  final String id;
  final String nome;
  final String categoria;
  final String porcao;
  final int calorias;
  final double proteinas;
  final double carboidratos;
  final double gorduras;
  final double fibras;

  FoodItem({
    required this.id,
    required this.nome,
    required this.categoria,
    required this.porcao,
    required this.calorias,
    required this.proteinas,
    required this.carboidratos,
    required this.gorduras,
    required this.fibras,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
      categoria: json['categoria'] ?? '',
      porcao: json['porcao'] ?? '1 porção',
      calorias: json['calorias'] ?? 0,
      proteinas: (json['proteinas'] ?? 0).toDouble(),
      carboidratos: (json['carboidratos'] ?? 0).toDouble(),
      gorduras: (json['gorduras'] ?? 0).toDouble(),
      fibras: (json['fibras'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'categoria': categoria,
      'porcao': porcao,
      'calorias': calorias,
      'proteinas': proteinas,
      'carboidratos': carboidratos,
      'gorduras': gorduras,
      'fibras': fibras,
    };
  }
}

/// Modelo de receita
class RecipeItem {
  final String id;
  final String nome;
  final String tempoPreparo;
  final String dificuldade;
  final int porcoes;
  final List<String> ingredientes;
  final String modoPreparo;
  final int calorias;
  final double proteinas;
  final double carboidratos;
  final double gorduras;
  final List<String> restricoes;

  RecipeItem({
    required this.id,
    required this.nome,
    required this.tempoPreparo,
    required this.dificuldade,
    required this.porcoes,
    required this.ingredientes,
    required this.modoPreparo,
    required this.calorias,
    required this.proteinas,
    required this.carboidratos,
    required this.gorduras,
    required this.restricoes,
  });

  factory RecipeItem.fromJson(Map<String, dynamic> json) {
    return RecipeItem(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
      tempoPreparo: json['tempoPreparo'] ?? '15 minutos',
      dificuldade: json['dificuldade'] ?? 'fácil',
      porcoes: json['porcoes'] ?? 1,
      ingredientes: List<String>.from(json['ingredientes'] ?? []),
      modoPreparo: json['modoPreparo'] ?? '',
      calorias: json['calorias'] ?? 0,
      proteinas: (json['proteinas'] ?? 0).toDouble(),
      carboidratos: (json['carboidratos'] ?? 0).toDouble(),
      gorduras: (json['gorduras'] ?? 0).toDouble(),
      restricoes: List<String>.from(json['restricoes'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'tempoPreparo': tempoPreparo,
      'dificuldade': dificuldade,
      'porcoes': porcoes,
      'ingredientes': ingredientes,
      'modoPreparo': modoPreparo,
      'calorias': calorias,
      'proteinas': proteinas,
      'carboidratos': carboidratos,
      'gorduras': gorduras,
      'restricoes': restricoes,
    };
  }

  /// Verifica se a receita atende às restrições
  bool atendeRestricoes(List<String> restricoesUsuario) {
    if (restricoesUsuario.isEmpty) return true;
    
    // Se o usuário tem restrições, a receita deve ter TODAS as restrições do usuário
    for (final restricao in restricoesUsuario) {
      if (!restricoes.contains(restricao)) {
        return false;
      }
    }
    return true;
  }
}

/// Serviço para carregar dados offline (JSON)
class NutritionDataService {
  static final NutritionDataService _instance = NutritionDataService._internal();
  factory NutritionDataService() => _instance;
  NutritionDataService._internal();

  List<FoodItem> _foods = [];
  List<RecipeItem> _recipes = [];
  bool _isLoaded = false;
  String? _lastError;

  bool get isLoaded => _isLoaded;
  String? get lastError => _lastError;
  List<FoodItem> get foods => _foods;
  List<RecipeItem> get recipes => _recipes;

  /// Carrega os dados dos assets JSON
  Future<bool> loadData() async {
    try {
      debugPrint('📦 Loading nutrition data from assets...');
      
      // Carregar alimentos
      final foodsJson = await rootBundle.loadString('assets/data/foods_ptbr.json');
      final foodsData = json.decode(foodsJson);
      _foods = (foodsData['alimentos'] as List)
          .map((item) => FoodItem.fromJson(item))
          .toList();
      
      debugPrint('✅ Loaded ${_foods.length} foods');
      
      // Carregar receitas
      final recipesJson = await rootBundle.loadString('assets/data/recipes_ptbr.json');
      final recipesData = json.decode(recipesJson);
      _recipes = (recipesData['receitas'] as List)
          .map((item) => RecipeItem.fromJson(item))
          .toList();
      
      debugPrint('✅ Loaded ${_recipes.length} recipes');
      
      _isLoaded = true;
      _lastError = null;
      return true;
    } catch (e) {
      debugPrint('❌ Error loading nutrition data: $e');
      _lastError = e.toString();
      _isLoaded = false;
      return false;
    }
  }

  /// Busca alimentos por nome
  List<FoodItem> searchFoods(String query) {
    if (query.isEmpty) return _foods;
    
    final lowerQuery = query.toLowerCase();
    return _foods.where((food) {
      return food.nome.toLowerCase().contains(lowerQuery) ||
             food.categoria.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Busca receitas por nome
  List<RecipeItem> searchRecipes(String query) {
    if (query.isEmpty) return _recipes;
    
    final lowerQuery = query.toLowerCase();
    return _recipes.where((recipe) {
      return recipe.nome.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Retorna receitas que atendem às restrições
  List<RecipeItem> getRecipesByRestrictions(List<String> restricoes) {
    if (restricoes.isEmpty) return _recipes;
    
    return _recipes.where((recipe) {
      return recipe.atendeRestricoes(restricoes);
    }).toList();
  }

  /// Retorna alimentos por categoria
  List<FoodItem> getFoodsByCategory(String categoria) {
    return _foods.where((food) => food.categoria == categoria).toList();
  }

  /// Retorna todas as categorias de alimentos
  List<String> getFoodCategories() {
    return _foods.map((food) => food.categoria).toSet().toList()..sort();
  }

  /// Retorna um alimento aleatório
  FoodItem? getRandomFood() {
    if (_foods.isEmpty) return null;
    _foods.shuffle();
    return _foods.first;
  }

  /// Retorna uma receita aleatória
  RecipeItem? getRandomRecipe({List<String>? restricoes}) {
    List<RecipeItem> available = restricoes != null && restricoes.isNotEmpty
        ? getRecipesByRestrictions(restricoes)
        : _recipes;
    
    if (available.isEmpty) return null;
    available.shuffle();
    return available.first;
  }
}
