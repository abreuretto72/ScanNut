import 'package:hive/hive.dart';

part 'food_recipe_suggestion.g.dart';

@HiveType(typeId: 32)
class RecipeSuggestion extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String instructions;

  @HiveField(3)
  final String prepTime;

  @HiveField(4)
  final String justification;

  @HiveField(5)
  final String difficulty;

  @HiveField(6)
  final String calories;

  @HiveField(7)
  final String sourceFood;

  RecipeSuggestion({
    required this.id,
    required this.name,
    required this.instructions,
    required this.prepTime,
    required this.justification,
    required this.difficulty,
    required this.calories,
    this.sourceFood = '',
  });

  factory RecipeSuggestion.fromJson(Map<String, dynamic> json, {String foodName = ''}) {
    // 🛡️ Helper de Extração Numérica Invariável
    int parseSafeInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      final clean = v.toString().replaceAll(RegExp(r'[^0-9]'), '');
      return int.tryParse(clean) ?? 0;
    }

    String finalName = json['name']?.toString() ?? '';
    // Apply name origin logic if needed
    if (foodName.isNotEmpty && finalName.isNotEmpty && !finalName.toLowerCase().contains(foodName.toLowerCase())) {
       finalName = '$foodName: $finalName';
    }

    return RecipeSuggestion(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: finalName.isNotEmpty ? finalName : 'Sugestão do Chef',
      instructions: json['instructions']?.toString() ?? '',
      prepTime: '${parseSafeInt(json['prep_time'])}_minutes', // Store as safe string
      justification: json['justification']?.toString() ?? '',
      difficulty: json['difficulty']?.toString() ?? '',
      calories: '${parseSafeInt(json['calories'])}_kcal', // Store as safe string
      sourceFood: foodName,
    );
  }

  static int _parseIntSafe(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    if (val is double) return val.toInt();
    final s = val.toString().replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(s) ?? 0;
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'instructions': instructions,
        'prep_time': prepTime,
        'justification': justification,
        'difficulty': difficulty,
        'calories': calories,
        'source_food': sourceFood,
      };

  bool get isValid =>
      name.isNotEmpty &&
      !name.contains('Sem Nome') &&
      instructions.isNotEmpty &&
      instructions.length > 20 &&
      calories.isNotEmpty &&
      !calories.contains('N/A');
}
