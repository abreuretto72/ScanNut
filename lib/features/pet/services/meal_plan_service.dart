import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/weekly_meal_plan.dart';

class MealPlanService {
  static final MealPlanService _instance = MealPlanService._internal();
  factory MealPlanService() => _instance;
  MealPlanService._internal();

  static const String _boxName = 'weekly_meal_plans';
  Box<WeeklyMealPlan>? _box;

  Future<void> init() async {
    if (_box != null && _box!.isOpen) return;
    try {
      // Register Adapters if not already registered
      // We reserve IDs 8, 9, 10
      if (!Hive.isAdapterRegistered(8)) {
        Hive.registerAdapter(WeeklyMealPlanAdapter());
      }
      if (!Hive.isAdapterRegistered(9)) {
        Hive.registerAdapter(DailyMealItemAdapter());
      }
      if (!Hive.isAdapterRegistered(10)) {
        Hive.registerAdapter(NutrientMetadataAdapter());
      }

      _box = await Hive.openBox<WeeklyMealPlan>(_boxName);
      debugPrint('✅ MealPlanService initialized (Box: $_boxName)');
    } catch (e, stack) {
      debugPrint('❌ MealPlanService init failed: $e\n$stack');
    }
  }

  // Save or Update Plan
  Future<void> savePlan(WeeklyMealPlan plan) async {
    await init();
    if (_box == null) return;
    
    await _box!.put(plan.id, plan);
    debugPrint('🍽️ Menu saved: ${plan.id} for ${plan.petId} (Week: ${plan.startDate})');
  }

  // Get Plan for a Specific Date (Finds the week covering this date)
  Future<WeeklyMealPlan?> getPlanForDate(String petId, DateTime date) async {
    await init();
    if (_box == null) return null;

    final normalizedDate = DateTime(date.year, date.month, date.day);
    
    try {
      final plans = _box!.values.where((p) => p.petId == petId);
      
      for (var plan in plans) {
         // Check if date falls within start and end
         if (normalizedDate.isAtSameMomentAs(plan.startDate) || 
             normalizedDate.isAtSameMomentAs(plan.endDate) ||
             (normalizedDate.isAfter(plan.startDate) && normalizedDate.isBefore(plan.endDate))) {
             return plan;
         }
      }
      return null;
    } catch (e) {
      debugPrint('Error searching plan: $e');
      return null;
    }
  }
  
  // Get All Plans for Pet (History)
  Future<List<WeeklyMealPlan>> getPlansForPet(String petId) async {
    await init();
    if (_box == null) return [];
    
    return _box!.values
        .where((p) => p.petId == petId)
        .toList()
        ..sort((a, b) => b.startDate.compareTo(a.startDate)); // Newest first
  }

  // Delete Plan
  Future<void> deletePlan(String planId) async {
    await init();
    await _box?.delete(planId);
  }

  // Create a Copy for Next Week
  Future<WeeklyMealPlan?> copyPlanToNextWeek(String planId) async {
    await init();
    final original = _box?.get(planId);
    if (original == null) return null;

    final newStartDate = original.endDate.add(const Duration(days: 1)); // Next Monday
    
    final newPlan = WeeklyMealPlan.create(
      petId: original.petId,
      startDate: newStartDate,
      dietType: original.dietType,
      nutritionalGoal: original.nutritionalGoal,
      meals: original.meals, // Deep copy might be needed if we mutate, but mostly immutable
      metadata: original.metadata,
      templateName: original.templateName != null ? '${original.templateName} (Copy)' : null,
    );

    await savePlan(newPlan);
    return newPlan;
  }
}
