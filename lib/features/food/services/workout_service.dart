import 'package:hive_flutter/hive_flutter.dart';

/// ============================================================================
/// 🚫 COMPONENTE BLINDADO E CONGELADO - NÃO ALTERAR
/// Este módulo de Treinos e Exercícios foi concluído e validado.
/// Nenhuma rotina ou lógica interna deve ser modificada.
/// Data de Congelamento: 29/12/2025
/// ============================================================================

import 'package:flutter/material.dart';
import '../models/workout_item.dart';
import '../../../core/services/hive_atomic_manager.dart';

class WorkoutService {
  static final WorkoutService _instance = WorkoutService._internal();
  factory WorkoutService() => _instance;
  WorkoutService._internal();

  static const String boxName = 'box_workouts';
  Box<WorkoutItem>? _box;

  Future<void> init({HiveCipher? cipher}) async {
    if (_box != null && _box!.isOpen) return;
    try {
      if (!Hive.isAdapterRegistered(22)) {
        Hive.registerAdapter(WorkoutItemAdapter());
      }
      _box = await HiveAtomicManager()
          .ensureBoxOpen<WorkoutItem>(boxName, cipher: cipher);
      debugPrint('✅ WorkoutService initialized (Secure).');
    } catch (e) {
      debugPrint('❌ Error initializing Secure WorkoutService: $e');
    }
  }

  Future<void> saveWorkout(WorkoutItem workout) async {
    await init();
    await _box?.add(workout);
  }

  Future<List<WorkoutItem>> getHistory() async {
    await init();
    return _box?.values.toList().reversed.toList() ?? [];
  }

  Future<int> getDailyCaloriesBurned(DateTime date) async {
    await init();
    if (_box == null) return 0;

    final dayWorkouts = _box!.values.where((w) =>
        w.timestamp.year == date.year &&
        w.timestamp.month == date.month &&
        w.timestamp.day == date.day);

    return dayWorkouts.fold<int>(0, (sum, w) => sum + w.caloriesBurned);
  }
}
