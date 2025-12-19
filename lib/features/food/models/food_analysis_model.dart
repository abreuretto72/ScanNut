class FoodAnalysisModel {
  final String itemName;
  final int estimatedCalories;
  final Macronutrients macronutrients;
  final List<String> benefits;
  final List<String> risks;
  final String advice;

  FoodAnalysisModel({
    required this.itemName,
    required this.estimatedCalories,
    required this.macronutrients,
    required this.benefits,
    required this.risks,
    required this.advice,
  });

  factory FoodAnalysisModel.fromJson(Map<String, dynamic> json) {
    return FoodAnalysisModel(
      itemName: json['item_name'] ?? 'Alimento Desconhecido',
      estimatedCalories: json['estimated_calories'] ?? 0,
      macronutrients: Macronutrients.fromJson(json['macronutrients'] ?? {}),
      benefits: List<String>.from(json['benefits'] ?? []),
      risks: List<String>.from(json['risks'] ?? []),
      advice: json['advice'] ?? 'Sem conselhos disponíveis.',
    );
  }
}

class Macronutrients {
  final String protein;
  final String carbs;
  final String fats;

  Macronutrients({
    required this.protein,
    required this.carbs,
    required this.fats,
  });

  factory Macronutrients.fromJson(Map<String, dynamic> json) {
    return Macronutrients(
      protein: json['protein'] ?? '0g',
      carbs: json['carbs'] ?? '0g',
      fats: json['fats'] ?? '0g',
    );
  }
}
