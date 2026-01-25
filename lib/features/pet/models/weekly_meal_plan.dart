import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'brand_suggestion.dart'; // 🛡️ NEW: Import BrandSuggestion

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

  @HiveField(10)
  final List<dynamic>?
      recommendedBrands; // 🛡️ UPDATED: List<dynamic> for backward compatibility (String vs BrandSuggestion)

  @HiveField(11)
  final String?
      foodType; // 'kibble', 'natural', 'mixed' - Filtro original persistido

  @HiveField(12)
  final String?
      goal; // Objetivo original (ex: 'obesity', 'renal') - Filtro original persistido

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
    this.recommendedBrands,
    this.foodType,
    this.goal,
  });

  factory WeeklyMealPlan.create({
    required String petId,
    required DateTime startDate,
    required String dietType,
    required String nutritionalGoal,
    required List<DailyMealItem> meals,
    required NutrientMetadata metadata,
    String? templateName,
    List<dynamic>? recommendedBrands, // Accept dynamic list
    String? foodType,
    String? goal,
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
      recommendedBrands: recommendedBrands,
      foodType: foodType,
      goal: goal,
    );
  }

  // 🛡️ Robust Getter: Handles both old String list and new BrandSuggestion list
  List<BrandSuggestion> get safeRecommendedBrands {
    if (recommendedBrands == null) return [];

    return recommendedBrands!.map((item) {
      if (item is BrandSuggestion) return item;

      // Handle Map (if Hive returns Maps for objects)
      if (item is Map) {
        try {
          return BrandSuggestion.fromJson(Map<String, dynamic>.from(item));
        } catch (e) {
          // Fallback if parsing fails
          return BrandSuggestion(
              brand: item.toString(),
              reason: 'Recomendação baseada no perfil.');
        }
      }

      // Legacy Fallback: String -> BrandSuggestion
      return BrandSuggestion(
        brand: item.toString(),
        reason:
            'Marca selecionada por critérios de qualidade Super Premium para o perfil do pet.',
      );
    }).toList();
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
