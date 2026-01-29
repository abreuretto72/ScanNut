
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/services/hive_atomic_manager.dart';
import 'nutrition/nutrition_hive_adapters.dart';

// Models required for Typed Boxes
import 'nutrition/data/models/weekly_plan.dart';
import 'nutrition/data/models/meal_log.dart';
import 'nutrition/data/models/shopping_list_item.dart';

/// 🛡️ FOOD MODULE (V135 - IRON LAW OF ISOLATION)
/// Single Entrypoint for the Food Feature.
/// Manages initialization, persistence, and dependency injection for the entire domain.
class FoodModule {
  static bool _isInitialized = false;

  /// 🚀 INIT: Initializes the Food Micro-App
  /// Must be called by the Core (HiveInitService) passing the global cipher.
  static Future<void> init({required HiveCipher? cipher}) async {
    if (_isInitialized) {
      _log('⚠️ Already initialized. Skipping.');
      return;
    }

    _log('🚀 Initializing Food Domain...');

    try {
      // 1. REGISTER ADAPTERS (Internal to the Module)
      NutritionHiveAdapters.registerAdapters();

      // 2. OPEN HIVES BOXES (Encrypted & Atomic)
      final atom = HiveAtomicManager();

      // 2.1 User Profile
      await atom.ensureBoxOpen('nutrition_user_profile', cipher: cipher);

      // 2.2 Weekly Plans (Typed)
      await _openTypedBox<WeeklyPlan>('nutrition_weekly_plans', cipher, atom);

      // 2.3 Meal Logs (Typed)
      await _openTypedBox<MealLog>('nutrition_meal_logs', cipher, atom);

      // 2.4 Shopping List (Typed)
      await _openTypedBox<ShoppingListItem>('nutrition_shopping_list', cipher, atom);

      // 2.5 Filter Settings
      await atom.ensureBoxOpen('menu_filter_settings', cipher: cipher);

      // 2.6 Recipe History
      await atom.ensureBoxOpen('recipe_history_box', cipher: cipher);

      // 2.7 Central Food Analysis History (NutritionService)
      await atom.ensureBoxOpen('box_nutrition_human', cipher: cipher);

      _isInitialized = true;
      _log('✅ Initialization Complete. All boxes active.');

    } catch (e) {
      _log('❌ CRITICAL INIT FAILURE: $e');
      rethrow;
    }
  }

  /// 🛠️ Private Helper for Typed Boxes with Auto-Recovery
  static Future<void> _openTypedBox<T>(String name, HiveCipher? cipher, HiveAtomicManager atom) async {
    try {
      await atom.ensureBoxOpen<T>(name, cipher: cipher);
    } catch (e) {
      if (e.toString().contains('unknown typeId') || e.toString().contains('HiveError')) {
        _log('☢️ CORRUPTION DETECTED in "$name". Recreating box...');
        await atom.recreateBox<T>(name, cipher: cipher);
        await atom.ensureBoxOpen<T>(name, cipher: cipher);
        _log('✅ Box "$name" reconstructed.');
      } else {
        rethrow;
      }
    }
  }

  /// 🎨 Internal Logger (Orange Prefix)
  static void _log(String message) {
    // ANSI Orange Color for Food Domain Logic
    debugPrint('\x1B[38;5;208m[FoodModule] $message\x1B[0m');
  }
}
