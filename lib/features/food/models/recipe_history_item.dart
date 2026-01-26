import 'package:hive/hive.dart';

part 'recipe_history_item.g.dart';

@HiveType(typeId: 31)
class RecipeHistoryItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String foodName;

  @HiveField(2)
  final String recipeName;

  @HiveField(3)
  final String instructions;

  @HiveField(4)
  final String prepTime;

  @HiveField(5)
  final DateTime timestamp;

  @HiveField(6)
  final String? imagePath;

  @HiveField(7)
  final String? justification;

  @HiveField(8)
  final String? difficulty;

  @HiveField(9)
  final String? calories;

  RecipeHistoryItem({
    required this.id,
    required this.foodName,
    required this.recipeName,
    required this.instructions,
    required this.prepTime,
    required this.timestamp,
    this.imagePath,
    this.justification,
    this.difficulty,
    this.calories,
  });
}
