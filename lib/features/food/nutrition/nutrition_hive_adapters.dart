import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import 'data/models/user_nutrition_profile.dart';
import 'data/models/meal.dart';
import 'data/models/plan_day.dart';
import 'data/models/weekly_plan.dart';
import 'data/models/meal_log.dart';
import 'data/models/shopping_list_item.dart';

/// Registra todos os adapters do módulo de nutrição
/// Deve ser chamado no main.dart após Hive.initFlutter()
class NutritionHiveAdapters {
  static void registerAdapters() {
    try {
      // TypeId 24: UserNutritionProfile
      if (!Hive.isAdapterRegistered(24)) {
        Hive.registerAdapter(UserNutritionProfileAdapter());
      }

      // TypeId 25: Meal
      if (!Hive.isAdapterRegistered(25)) {
        Hive.registerAdapter(MealAdapter());
      }

      // TypeId 26: MealItem
      if (!Hive.isAdapterRegistered(26)) {
        Hive.registerAdapter(MealItemAdapter());
      }

      // TypeId 27: PlanDay
      if (!Hive.isAdapterRegistered(27)) {
        Hive.registerAdapter(PlanDayAdapter());
      }

      // TypeId 28: WeeklyPlan
      if (!Hive.isAdapterRegistered(28)) {
        Hive.registerAdapter(WeeklyPlanAdapter());
      }

      // TypeId 29: MealLog
      if (!Hive.isAdapterRegistered(29)) {
        Hive.registerAdapter(MealLogAdapter());
      }

      // TypeId 30: ShoppingListItem
      if (!Hive.isAdapterRegistered(30)) {
        Hive.registerAdapter(ShoppingListItemAdapter());
      }

      debugPrint('✅ Nutrition Hive Adapters registered successfully');
    } catch (e) {
      debugPrint('❌ Error registering Nutrition Hive Adapters: $e');
    }
  }
}
