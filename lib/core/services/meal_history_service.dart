import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'hive_atomic_manager.dart';

final mealHistoryServiceProvider = Provider((ref) => MealHistoryService());

class MealHistoryService {
  static const String boxName = 'scannut_meal_history';

  Future<void> init({HiveCipher? cipher}) async {
    await HiveAtomicManager().ensureBoxOpen(boxName, cipher: cipher);
  }

  // 🛡️ SELF-HEALING BOX ACCESS
  Future<Box> _getOpenBox() async {
    return await HiveAtomicManager().ensureBoxOpen(boxName);
  }

  // Save the ingredients used in a weekly plan for a specific pet
  Future<void> saveWeeklyIngredients(
      String petName, List<String> ingredients) async {
    final box = await _getOpenBox();
    final key = 'meal_history_${petName.toLowerCase().trim()}';

    // We store a list of past weeks. Each entry is a list of ingredients.
    // We'll keep only the last 2 weeks to avoid accumulating too much old data
    // unless we want a longer history.
    List<List<String>> history = [];

    if (box.containsKey(key)) {
      final data = box.get(key);
      if (data is List) {
        history =
            List<List<String>>.from(data.map((e) => List<String>.from(e)));
      }
    }

    // Add new week's ingredients
    history.add(ingredients);

    // Keep only last 4 weeks (approx 1 month) for rotation logic
    if (history.length > 4) {
      history.removeAt(0);
    }

    await box.put(key, history);
  }

  // Get ALL ingredients used in the last X saved plans to use as exclusion/restriction
  Future<List<String>> getRecentIngredients(String petName) async {
    final box = await _getOpenBox();
    final key = 'meal_history_${petName.toLowerCase().trim()}';

    if (!box.containsKey(key)) return [];

    final data = box.get(key);
    if (data is List) {
      final history =
          List<List<String>>.from(data.map((e) => List<String>.from(e)));

      // Flatten the list to get all ingredients used recently
      final Set<String> uniqueIngredients = {};
      for (var week in history) {
        uniqueIngredients.addAll(week);
      }
      return uniqueIngredients.toList();
    }

    return [];
  }
}
