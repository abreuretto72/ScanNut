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

  factory RecipeSuggestion.fromJson(dynamic json, {String foodName = ''}) {
    if (json is String) {
      return RecipeSuggestion(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: json,
        instructions: 'Consulte o modo de preparo detalhado.',
        prepTime: '20 min',
        justification: 'Sugestão rápida baseada no ingrediente.',
        difficulty: 'Fácil',
        calories: '\u00B1 300 kcal',
        sourceFood: foodName,
      );
    }
    
    // Ensure it's a map before proceeding with map logic
    final Map<String, dynamic> map = (json is Map) ? Map<String, dynamic>.from(json) : {};
    
    // Robust name extraction
    String rawName = map['name']?.toString() ?? 
                     map['title']?.toString() ?? 
                     map['recipe_name']?.toString() ?? 
                     '';
    
    // Fallback: extract from first line of instructions if name is still empty
    if (rawName.isEmpty && map['instructions'] != null) {
      final instructions = map['instructions'].toString();
      if (instructions.isNotEmpty) {
        rawName = instructions.split('\n').first;
        if (rawName.length > 50) rawName = rawName.substring(0, 47) + '...';
      }
    }

    // Protection against "Receita de [Vazio]"
    if (rawName.isEmpty || rawName.trim().length < 3) {
      rawName = 'Sugestão Especial';
    }

    // Format final name: [Origin]: [Name]
    // IF the name already contains the origin, don't duplicate it
    String finalName = rawName;
    if (foodName.isNotEmpty) {
      if (!rawName.toLowerCase().contains(foodName.toLowerCase())) {
        finalName = '$foodName: $rawName';
      }
    }

    // Sanitize calories: replace "Aproximadamente" or "Aprox." with ±
    String finalCalories = map['calories']?.toString() ?? 'N/A';
    finalCalories = finalCalories.replaceAll(RegExp(r'Aproximadamente|Aprox\.', caseSensitive: false), '\u00B1').trim();
    if (finalCalories == 'N/A' || finalCalories.isEmpty) finalCalories = '\u00B1 350 kcal';

    return RecipeSuggestion(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: finalName,
      instructions: map['instructions']?.toString() ?? '',
      prepTime: map['prep_time']?.toString() ?? '15 min',
      justification: map['justification']?.toString() ?? 'Recomendado para sua dieta.',
      difficulty: map['difficulty']?.toString() ?? 'Médio',
      calories: finalCalories,
      sourceFood: foodName,
    );
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
