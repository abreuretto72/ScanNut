/// ============================================================================
/// 🚫 COMPONENTE BLINDADO E CONGELADO - NÃO ALTERAR
/// Este módulo de Planos Alimentares de Pets foi concluído e validado.
/// Nenhuma rotina ou lógica interna deve ser modificada.
/// Data de Congelamento: 29/12/2025
/// ============================================================================

import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/weekly_meal_plan.dart';
import '../../../core/services/hive_atomic_manager.dart';

final mealPlanServiceProvider =
    Provider<MealPlanService>((ref) => MealPlanService());

class MealPlanService {
  static final MealPlanService _instance = MealPlanService._internal();
  factory MealPlanService() => _instance;
  MealPlanService._internal();

  static const String _boxName = 'weekly_meal_plans';
  Box<WeeklyMealPlan>? _box;

  Future<void> init({HiveCipher? cipher}) async {
    debugPrint('🚀 [V61-TRACE] MealPlanService.init starting...');
    await _ensureBox(cipher: cipher);
  }

  Future<Box<WeeklyMealPlan>> _ensureBox({HiveCipher? cipher}) async {
    _box = await HiveAtomicManager()
        .ensureBoxOpen<WeeklyMealPlan>(_boxName, cipher: cipher);
    return _box!;
  }

  // Save or Update Plan
  Future<void> savePlan(WeeklyMealPlan plan) async {
    final box = await _ensureBox();
    await box.put(plan.id, plan);
    await box.flush(); // Force write to disk
    debugPrint(
        '🍽️ Menu saved: ${plan.id} for ${plan.petId} (Week: ${plan.startDate})');
  }

  // Get Plan for a Specific Date (Finds the week covering this date)
  Future<WeeklyMealPlan?> getPlanForDate(String petId, DateTime date,
      {String? fallbackName}) async {
    final box = await _ensureBox();

    final normalizedDate = DateTime(date.year, date.month, date.day);

    try {
      final plans = box.values.where((p) =>
          p.petId == petId ||
          (fallbackName != null && p.petId == fallbackName));

      for (var plan in plans) {
        // Check if date falls within start and end
        if (normalizedDate.isAtSameMomentAs(plan.startDate) ||
            normalizedDate.isAtSameMomentAs(plan.endDate) ||
            (normalizedDate.isAfter(plan.startDate) &&
                normalizedDate.isBefore(plan.endDate))) {
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
  Future<List<WeeklyMealPlan>> getPlansForPet(String petId,
      {String? fallbackName}) async {
    final box = await _ensureBox();

    return box.values
        .where((p) =>
            p.petId == petId ||
            (fallbackName != null && p.petId == fallbackName))
        .toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate)); // Newest first
  }

  // Delete Plan
  Future<void> deletePlan(String planId) async {
    final box = await _ensureBox();
    await box.delete(planId);
  }

  // Create a Copy for Next Week
  Future<WeeklyMealPlan?> copyPlanToNextWeek(String planId) async {
    final box = await _ensureBox();
    final original = box.get(planId);
    if (original == null) return null;

    final newStartDate =
        original.endDate.add(const Duration(days: 1)); // Next Monday

    final newPlan = WeeklyMealPlan.create(
      petId: original.petId,
      startDate: newStartDate,
      dietType: original.dietType,
      nutritionalGoal: original.nutritionalGoal,
      meals: original
          .meals, // Deep copy might be needed if we mutate, but mostly immutable
      metadata: original.metadata,
      templateName: original.templateName != null
          ? '${original.templateName} (Copy)'
          : null,
    );

    await savePlan(newPlan);
    return newPlan;
  }
}
