import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import '../models/workout_item.dart';

class WorkoutService {
  static final WorkoutService _instance = WorkoutService._internal();
  factory WorkoutService() => _instance;
  WorkoutService._internal();

  static const String boxName = 'box_workouts';
  Box<WorkoutItem>? _box;

  Future<void> init() async {
    if (_box != null && _box!.isOpen) return;
    try {
      if (!Hive.isAdapterRegistered(22)) {
        Hive.registerAdapter(WorkoutItemAdapter());
      }
      _box = await Hive.openBox<WorkoutItem>(boxName);
      debugPrint('✅ WorkoutService initialized.');
    } catch (e) {
      debugPrint('❌ Error initializing WorkoutService: $e');
    }
  }

  ValueListenable<Box<WorkoutItem>>? get listenable => _box?.listenable();

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

    return dayWorkouts.fold(0, (sum, w) => sum + w.caloriesBurned);
  }
}
