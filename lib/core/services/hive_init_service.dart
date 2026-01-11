import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/pet/models/weekly_meal_plan.dart';

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

    try {
      // 1. AUTHENTICATION BOX (no encryption)
      await _openBox('box_auth_local', cipher: null);

      // 2. PET MODULE BOXES (encrypted)
      await _openBox('box_pets_master', cipher: cipher);
      await _openBox('pet_events', cipher: cipher);
      await _openBox('vaccine_status', cipher: cipher);
      await _openBox('lab_exams', cipher: cipher);
      
      // 3. MEAL PLAN BOX (typed, encrypted)
      await _openTypedBox<WeeklyMealPlan>('weekly_meal_plans', cipher: cipher);

      // 4. HISTORY BOXES (encrypted)
      await _openBox('scannut_history', cipher: cipher);
      await _openBox('meal_history', cipher: cipher);

      // 5. SETTINGS & USER BOXES (encrypted)
      await _openBox('settings', cipher: cipher);
      await _openBox('user_profiles', cipher: cipher);

      // 6. NUTRITION MODULE BOXES (encrypted)
      await _openBox('nutrition_profiles', cipher: cipher);
      await _openBox('weekly_plans', cipher: cipher);
      await _openBox('meal_logs', cipher: cipher);
      await _openBox('shopping_lists', cipher: cipher);
      await _openBox('menu_filters', cipher: cipher);

      // 7. PARTNERS BOX (encrypted)
      await _openBox('partners', cipher: cipher);

      _isInitialized = true;
      debugPrint('✅ [V70-HIVE] Step 2: All boxes initialized successfully');
      debugPrint('📊 [V70-HIVE] Total boxes opened: ${_boxStatus.length}');
      
    } catch (e) {
      debugPrint('❌ [V70-HIVE] Critical error during initialization: $e');
      rethrow;
    }
  }

  /// Open a regular box with error handling
  Future<void> _openBox(String boxName, {HiveCipher? cipher}) async {
    try {
      if (Hive.isBoxOpen(boxName)) {
        debugPrint('⚠️ [V70-HIVE] Box "$boxName" already open. Skipping.');
        _boxStatus[boxName] = true;
        return;
      }

      if (cipher != null) {
        await Hive.openBox(boxName, encryptionCipher: cipher);
      } else {
        await Hive.openBox(boxName);
      }
      
      _boxStatus[boxName] = true;
      debugPrint('✅ [V70-HIVE] Opened box: $boxName');
    } catch (e) {
      debugPrint('❌ [V70-HIVE] Failed to open box "$boxName": $e');
      _boxStatus[boxName] = false;
      rethrow;
    }
  }

  /// Open a typed box with error handling
  Future<void> _openTypedBox<T>(String boxName, {HiveCipher? cipher}) async {
    try {
      if (Hive.isBoxOpen(boxName)) {
        // Check if it's the correct type
        final box = Hive.box(boxName);
        if (box is Box<T>) {
          debugPrint('✅ [V70-HIVE] Box "$boxName" already open with correct type.');
          _boxStatus[boxName] = true;
          return;
        } else {
          // Wrong type - close and reopen
          debugPrint('⚠️ [V70-HIVE] Box "$boxName" open with wrong type. Closing...');
          await box.close();
        }
      }

      if (cipher != null) {
        await Hive.openBox<T>(boxName, encryptionCipher: cipher);
      } else {
        await Hive.openBox<T>(boxName);
      }
      
      _boxStatus[boxName] = true;
      debugPrint('✅ [V70-HIVE] Opened typed box: $boxName<$T>');
    } catch (e) {
      debugPrint('❌ [V70-HIVE] Failed to open typed box "$boxName": $e');
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
