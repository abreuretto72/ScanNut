import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

final historyServiceProvider = Provider((ref) => HistoryService());

class HistoryService {
  static const String boxName = 'scannut_history';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(boxName);
  }

  static Future<List<Map<String, dynamic>>> getHistory() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.initFlutter();
      await Hive.openBox(boxName);
    }
    final box = Hive.box(boxName);
    return box.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<void> deleteItem(int index) async {
     final box = Hive.box(boxName);
     await box.deleteAt(index);
  }

  static Future<void> deletePet(String petName) async {
    final box = Hive.box(boxName);
    final key = 'pet_${petName.toLowerCase().trim()}';
    if (box.containsKey(key)) {
      await box.delete(key);
    } else {
       // Fallback: search by value if ID key pattern mismatch
       final keyToDelete = box.keys.firstWhere((k) {
         final val = box.get(k);
         return val is Map && val['pet_name'] == petName;
       }, orElse: () => null);
       
       if (keyToDelete != null) {
         await box.delete(keyToDelete);
       }
    }
  }

  Future<void> saveAnalysis(Map<String, dynamic> analysis, String mode, {String? imagePath}) async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.initFlutter();
      await Hive.openBox(boxName);
    }
    final box = Hive.box(boxName);
    final entry = {
      'timestamp': DateTime.now().toIso8601String(),
      'mode': mode,
      'data': analysis,
      if (imagePath != null) 'image_path': imagePath,
    };
    await box.add(entry);
  }


  Future<void> savePetAnalysis(String petName, Map<String, dynamic> analysis, {String? imagePath}) async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.initFlutter();
      await Hive.openBox(boxName);
    }
    final box = Hive.box(boxName);
    final key = 'pet_${petName.toLowerCase().trim()}';
    
    final entry = {
      'id': key,
      'timestamp': DateTime.now().toIso8601String(),
      'mode': 'Pet',
      'pet_name': petName,
      'data': analysis,
      if (imagePath != null) 'image_path': imagePath,
    };
    
    await box.put(key, entry);
  }

  Future<void> clearHistory() async {
    final box = Hive.box(boxName);
    await box.clear();
  }

  Future<void> clearAllPets() async {
    final box = Hive.box(boxName);
    final keysToDelete = <dynamic>[];
    
    for (var key in box.keys) {
      final value = box.get(key);
      if (value is Map && value['mode'] == 'Pet') {
        keysToDelete.add(key);
      }
    }
    
    await box.deleteAll(keysToDelete);
  }

  Future<void> clearAllPlants() async {
    final box = Hive.box(boxName);
    final keysToDelete = <dynamic>[];
    
    for (var key in box.keys) {
      final value = box.get(key);
      if (value is Map && value['mode'] == 'Plant') {
        keysToDelete.add(key);
      }
    }
    
    await box.deleteAll(keysToDelete);
  }

  Future<void> clearAllFood() async {
    final box = Hive.box(boxName);
    final keysToDelete = <dynamic>[];
    
    for (var key in box.keys) {
      final value = box.get(key);
      if (value is Map && value['mode'] == 'Food') {
        keysToDelete.add(key);
      }
    }
    
    await box.deleteAll(keysToDelete);

    // Also clear the dedicated nutrition box
    try {
      const nutritionBoxName = 'box_nutrition_human';
      if (Hive.isBoxOpen(nutritionBoxName)) {
        await Hive.box(nutritionBoxName).close();
      }
      await Hive.deleteBoxFromDisk(nutritionBoxName);
      debugPrint('✅ [Danger Zone] Physically deleted $nutritionBoxName');
    } catch (e) {
      debugPrint('❌ [Danger Zone] Error deleting nutrition box: $e');
    }
  }

  Future<void> hardResetAllDatabases() async {
    await powerDeleteAll();
  }

  Future<void> powerDeleteAll() async {
    final boxes = [
      'scannut_history',
      'scannut_meal_history',
      'box_nutrition_human',
      'box_nutrition_pets',
      'box_pets_profiles',
      'box_pets_master',
      'box_plants_history',
      'box_botany_intel',
      'box_settings',
      'weekly_meal_plans',
      'nutrition_weekly_plans',
      'nutrition_user_profile',
      'box_user_profile',
      'nutrition_shopping_list',
      'pet_events',
      'vaccine_status',
      'meal_log',
      'workout_plans',
      'partners_box',
      'pet_health_records'
    ];

    for (var name in boxes) {
      try {
        if (Hive.isBoxOpen(name)) {
          await Hive.box(name).close();
        }
        // DELEÇÃO FÍSICA NO DISCO (Nuclear Option)
        await Hive.deleteBoxFromDisk(name);
        debugPrint('💣 [Nuclear Delete] Physically destroyed $name');
      } catch (e) {
        debugPrint('⚠️ [Nuclear Delete] Could not destroy $name: $e');
      }
    }
    debugPrint('☢️  SISTEMA RESETADO DE FÁBRICA.');
  }
}
