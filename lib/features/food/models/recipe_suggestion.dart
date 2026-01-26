import 'package:hive/hive.dart';

part 'recipe_suggestion.g.dart';

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
    // Robust name extraction
    String rawName = json['name']?.toString() ?? 
                     json['title']?.toString() ?? 
                     json['recipe_name']?.toString() ?? 
                     '';
    
    // Fallback: extract from first line of instructions if name is still empty
    if (rawName.isEmpty && json['instructions'] != null) {
      final instructions = json['instructions'].toString();
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
    String finalCalories = json['calories']?.toString() ?? 'N/A';
    finalCalories = finalCalories.replaceAll(RegExp(r'Aproximadamente|Aprox\.', caseSensitive: false), '\u00B1').trim();
    if (finalCalories == 'N/A' || finalCalories.isEmpty) finalCalories = '\u00B1 350 kcal';

    return RecipeSuggestion(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: finalName,
      instructions: json['instructions']?.toString() ?? '',
      prepTime: json['prep_time']?.toString() ?? '15 min',
      justification: json['justification']?.toString() ?? 'Recomendado para sua dieta.',
      difficulty: json['difficulty']?.toString() ?? 'Médio',
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
