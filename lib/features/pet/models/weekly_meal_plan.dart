import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'weekly_meal_plan.g.dart';

@HiveType(typeId: 8)
class WeeklyMealPlan {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String petId;

  @HiveField(2)
  final DateTime startDate;

  @HiveField(3)
  final DateTime endDate;

  @HiveField(4)
  final String dietType; // 'Ração', 'Natural', 'Híbrida'

  @HiveField(5)
  final String nutritionalGoal; // 'Manutenção', 'Renal', etc.

  @HiveField(6)
  final List<DailyMealItem> meals;

  @HiveField(7)
  final NutrientMetadata metadata;
  
  @HiveField(8)
  final String? templateName; // If this is a saved template

  @HiveField(9)
  final DateTime createdAt;

  WeeklyMealPlan({
    required this.id,
    required this.petId,
    required this.startDate,
    required this.endDate,
    required this.dietType,
    required this.nutritionalGoal,
    required this.meals,
    required this.metadata,
    this.templateName,
    required this.createdAt,
  });

  factory WeeklyMealPlan.create({
    required String petId,
    required DateTime startDate,
    required String dietType,
    required String nutritionalGoal,
    required List<DailyMealItem> meals,
    required NutrientMetadata metadata,
    String? templateName,
  }) {
    // Calculate end date (Sunday of the week)
    // Assuming startDate is ideally Monday, but we can enforce logic elsewhere.
    final endDate = startDate.add(const Duration(days: 6));
    
    return WeeklyMealPlan(
      id: const Uuid().v4(),
      petId: petId,
      startDate: startDate,
      endDate: endDate,
      dietType: dietType,
      nutritionalGoal: nutritionalGoal,
      meals: meals,
      metadata: metadata,
      templateName: templateName,
      createdAt: DateTime.now(),
    );
  }
}

@HiveType(typeId: 9)
class DailyMealItem {
  @HiveField(0)
  final int dayOfWeek; // 1 = Monday, 7 = Sunday

  @HiveField(1)
  final String time; // '08:00'

  @HiveField(2)
  final String title; // 'Café da Manhã'

  @HiveField(3)
  final String description;

  @HiveField(4)
  final String quantity;
  
  @HiveField(5)
  final String? benefit; // Optional explanation

  DailyMealItem({
    required this.dayOfWeek,
    required this.time,
    required this.title,
    required this.description,
    required this.quantity,
    this.benefit,
  });
}

@HiveType(typeId: 10)
class NutrientMetadata {
  @HiveField(0)
  final String protein;

  @HiveField(1)
  final String fat;

  @HiveField(2)
  final String fiber;

  @HiveField(3)
  final String micronutrients;

  @HiveField(4)
  final String hydration;

  NutrientMetadata({
    required this.protein,
    required this.fat,
    required this.fiber,
    required this.micronutrients,
    required this.hydration,
  });
}
