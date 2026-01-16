import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/pet/models/weekly_meal_plan.dart';
import '../../features/plant/models/botany_history_item.dart';
import '../../nutrition/data/models/weekly_plan.dart';
import '../../nutrition/data/models/meal_log.dart';
import '../../nutrition/data/models/shopping_list_item.dart';
import 'hive_atomic_manager.dart';

/// 🛡️ V70: CENTRALIZED HIVE INITIALIZATION SERVICE
/// Opens all boxes once at app startup to prevent "Box already open as dynamic" errors
class HiveInitService {
  static final HiveInitService _instance = HiveInitService._internal();
  factory HiveInitService() => _instance;
  HiveInitService._internal();

  bool _isInitialized = false;
  final Map<String, bool> _boxStatus = {};

  bool get isInitialized => _isInitialized;

  /// Initialize all Hive boxes at app startup
  Future<void> initializeAllBoxes({required HiveCipher? cipher}) async {
    if (_isInitialized) {
      debugPrint('⚠️ [V70-HIVE] Boxes already initialized. Skipping.');
      return;
    }

    debugPrint('🔧 [V70-HIVE] Step 1: Starting centralized box initialization...');
    
    // 🛡️ REGISTER ADAPTERS (Critical for Typed Boxes)
    // Checking and registering adapters to prevent "Unknown Type" errors
    // Note: MealPlan adapters commented out until ID verification (compile fix)
    // if (!Hive.isAdapterRegistered(8)) Hive.registerAdapter(WeeklyMealPlanAdapter());
    // if (!Hive.isAdapterRegistered(9)) Hive.registerAdapter(DailyMealItemAdapter());
    
    // Botany Adapter (Type 21)
    if (!Hive.isAdapterRegistered(21)) {
        Hive.registerAdapter(BotanyHistoryItemAdapter());
        debugPrint('✅ [V70-HIVE] BotanyHistoryItemAdapter (Type 21) registered.');
    }

    try {
      // 1. AUTHENTICATION BOX (no encryption)
      await _openBox('box_auth_local', cipher: null);

      // 2. PET MODULE BOXES (encrypted)
      await _openBox('box_pets_master', cipher: cipher);
      await _openBox('pet_events', cipher: cipher);
      await _openBox('vaccine_status', cipher: cipher);
      await _openBox('pet_health_records', cipher: cipher);
      await _openBox('lab_exams', cipher: cipher);
      
      // 3. MEAL PLAN BOX (typed, encrypted)
      await _openTypedBox<WeeklyMealPlan>('weekly_meal_plans', cipher: cipher);

      // 4. HISTORY BOXES (encrypted)
      await _openBox('scannut_history', cipher: cipher);
      await _openBox('scannut_meal_history', cipher: cipher);
      await _openTypedBox<BotanyHistoryItem>('box_plants_history', cipher: cipher);

      // 5. SETTINGS & USER BOXES (encrypted)
      await _openBox('settings', cipher: cipher);
      await _openBox('user_profiles', cipher: cipher);
      await _openBox('box_workouts', cipher: cipher);
      await _openBox('recipe_history_box', cipher: cipher);

      // 6. NUTRITION MODULE BOXES (encrypted)
      await _openBox('nutrition_user_profile', cipher: cipher);
      await _openTypedBox<WeeklyPlan>('nutrition_weekly_plans', cipher: cipher);
      await _openTypedBox<MealLog>('nutrition_meal_logs', cipher: cipher);
      await _openTypedBox<ShoppingListItem>('nutrition_shopping_list', cipher: cipher);
      await _openBox('menu_filter_settings', cipher: cipher);

      // 7. PARTNERS BOX (encrypted)
      await _openBox('partners_box', cipher: cipher);

      _isInitialized = true;
      debugPrint('✅ [V70-HIVE] Step 2: All boxes initialized successfully');
      debugPrint('📊 [V70-HIVE] Total boxes opened: ${_boxStatus.length}');
      
    } catch (e) {
      debugPrint('❌ [V70-HIVE] Critical error during initialization: $e');
      rethrow;
    }
  }

  /// Open a regular box with error handling using Atomic Manager (V115)
  Future<void> _openBox(String boxName, {HiveCipher? cipher}) async {
    try {
      await HiveAtomicManager().ensureBoxOpen(boxName, cipher: cipher);
      _boxStatus[boxName] = true;
    } catch (e) {
      debugPrint('❌ [V70-HIVE] Failed to open box "$boxName": $e');
      
      // 🛡️ SELF-HEALING: If box has unknown typeId (legacy/corrupt), NUKE IT.
      if (e.toString().contains('unknown typeId') || e.toString().contains('HiveError')) {
         debugPrint('☢️ [V70-HIVE] DETECTED CORRUPT/LEGACY DATA IN "$boxName". INITIATING ATOMIC RECONSTRUCTION...');
         try {
           await HiveAtomicManager().recreateBox(boxName, cipher: cipher);
           await HiveAtomicManager().ensureBoxOpen(boxName, cipher: cipher);
           _boxStatus[boxName] = true;
           debugPrint('✅ [V70-HIVE] Box "$boxName" successfully reconstructed and opened.');
           return;
         } catch (e2) {
           debugPrint('💀 [V70-HIVE] RECONSTRUCTION FAILED for "$boxName": $e2');
         }
      }
      
      _boxStatus[boxName] = false;
      rethrow;
    }
  }

  /// Open a typed box with error handling using Atomic Manager (V115)
  Future<void> _openTypedBox<T>(String boxName, {HiveCipher? cipher}) async {
    try {
      await HiveAtomicManager().ensureBoxOpen<T>(boxName, cipher: cipher);
      _boxStatus[boxName] = true;
    } catch (e) {
      debugPrint('❌ [V70-HIVE] Failed to open typed box "$boxName": $e');

      // 🛡️ SELF-HEALING: If box has unknown typeId (legacy/corrupt), NUKE IT.
      if (e.toString().contains('unknown typeId') || e.toString().contains('HiveError')) {
         debugPrint('☢️ [V70-HIVE] DETECTED CORRUPT/LEGACY DATA IN "$boxName". INITIATING ATOMIC RECONSTRUCTION...');
         try {
           await HiveAtomicManager().recreateBox<T>(boxName, cipher: cipher);
           await HiveAtomicManager().ensureBoxOpen<T>(boxName, cipher: cipher);
           _boxStatus[boxName] = true;
           debugPrint('✅ [V70-HIVE] Box "$boxName" successfully reconstructed and opened.');
           return;
         } catch (e2) {
           debugPrint('💀 [V70-HIVE] RECONSTRUCTION FAILED for "$boxName": $e2');
         }
      }

      _boxStatus[boxName] = false;
      rethrow;
    }
  }

  /// Get box status report
  Map<String, bool> getBoxStatus() => Map.unmodifiable(_boxStatus);

  /// Check if a specific box is open
  bool isBoxOpen(String boxName) => _boxStatus[boxName] == true;

  /// Close all boxes (for testing/reset)
  Future<void> closeAllBoxes() async {
    debugPrint('🔒 [V70-HIVE] Closing all boxes...');
    await Hive.close();
    _boxStatus.clear();
    _isInitialized = false;
    debugPrint('✅ [V70-HIVE] All boxes closed');
  }
}

// Global singleton instance
final hiveInitService = HiveInitService();
