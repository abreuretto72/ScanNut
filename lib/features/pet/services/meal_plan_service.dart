/// ============================================================================
/// 🚫 COMPONENTE BLINDADO E CONGELADO - NÃO ALTERAR
/// Este módulo de Planos Alimentares de Pets foi concluído e validado.
/// Nenhuma rotina ou lógica interna deve ser modificada.
/// Data de Congelamento: 29/12/2025
/// ============================================================================

import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/weekly_meal_plan.dart';

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
    // 🔍 V64 REPAIR: Reset de Tipagem
    final isOpen = Hive.isBoxOpen(_boxName);
    
    if (isOpen) {
      try {
        // Tenta pegar a box tipada
        _box = Hive.box<WeeklyMealPlan>(_boxName);
        debugPrint('✅ [V64-REPAIR] Box "$_boxName" já aberta corretamente.');
        return _box!;
      } catch (e) {
        debugPrint('🚨 [V64-REPAIR] Conflito Box<dynamic> detectado. Resetando...');
        // FECHAMENTO FORÇADO (Cirurgia V64)
        await Hive.box(_boxName).close();
        debugPrint('🔄 [V64-REPAIR] Box dinâmica encerrada para cura.');
      }
    }

    try {
      debugPrint('📂 [V64-REPAIR] Abrindo Box tipada: $_boxName');
      _box = await Hive.openBox<WeeklyMealPlan>(_boxName, encryptionCipher: cipher);
      return _box!;
    } catch (e, stack) {
      debugPrint('❌ [V64-REPAIR] Falha crítica ao abrir box de cardápio: $e');
      rethrow;
    }
  }

  // Save or Update Plan
  Future<void> savePlan(WeeklyMealPlan plan) async {
    final box = await _ensureBox();
    await box.put(plan.id, plan);
    await box.flush(); // Force write to disk
    debugPrint('🍽️ Menu saved: ${plan.id} for ${plan.petId} (Week: ${plan.startDate})');
  }

  // Get Plan for a Specific Date (Finds the week covering this date)
  Future<WeeklyMealPlan?> getPlanForDate(String petId, DateTime date) async {
    final box = await _ensureBox();

    final normalizedDate = DateTime(date.year, date.month, date.day);
    
    try {
      final plans = box.values.where((p) => p.petId == petId);
      
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
    final box = await _ensureBox();
    
    return box.values
        .where((p) => p.petId == petId)
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
