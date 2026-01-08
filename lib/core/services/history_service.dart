import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../utils/json_cast.dart';

import 'simple_auth_service.dart';

final historyServiceProvider = Provider((ref) => HistoryService());

class HistoryService {
  static const String boxName = 'scannut_history';

  Future<void> init({HiveCipher? cipher}) async {
    final effectiveCipher = cipher ?? SimpleAuthService().encryptionCipher;
    await Hive.openBox(boxName, encryptionCipher: effectiveCipher);
    
    // 🧹 GLOBAL RESET: Limpeza de Paths Órfãos (Cache/Temp)
    await _sanitizeOrphanedCachePaths();
  }

  /// 🧹 ONE-TIME DISINFECTION: Removes paths pointing to volatile cache
  Future<void> _sanitizeOrphanedCachePaths() async {
      try {
          final box = await getBox();
          if (!box.isOpen) return;

          final keys = box.keys.toList();
          for (var key in keys) {
             final val = box.get(key);
             if (val is Map) {
                final map = deepCastMap(val);
                bool changed = false;
                
                // Top Level
                String? path = map['image_path'];
                if (path != null && (path.contains('cache') || path.contains('temp'))) {
                     debugPrint('🧹 [HISTORY SANITIZER] Clearing phantom path for History Key $key');
                     map['image_path'] = null;
                     changed = true;
                }
                
                // Data Level
                if (map['data'] != null && map['data'] is Map) {
                    final data = deepCastMap(map['data']);
                    String? innerPath = data['image_path'];
                    if (innerPath != null && (innerPath.contains('cache') || innerPath.contains('temp'))) {
                        debugPrint('🧹 [HISTORY SANITIZER] Clearing phantom inner path for History Key $key');
                        data['image_path'] = null;
                        map['data'] = data;
                        changed = true;
                    }
                }
                
                if (changed) {
                    await box.put(key, map);
                }
             }
          }
      } catch (e) {
          debugPrint('⚠️ Sanitizer error in HistoryService: $e');
      }
  }

  static Future<Box> getBox() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box(boxName);
    } else {
      // 🛡️ Safe open
      return await Hive.openBox(boxName, encryptionCipher: SimpleAuthService().encryptionCipher);
    }
  }

  static Future<List<Map<String, dynamic>>> getHistory() async {
    try {
      final box = await getBox();
      return deepCastMapList(box.values.toList());
    } catch (e) {
      debugPrint('⚠️ Error loading history info: $e');
      return [];
    }
  }

  static Future<void> deleteItem(int index) async {
     final box = await getBox();
     await box.deleteAt(index);
  }

  static Future<void> deletePet(String petName) async {
    final box = await getBox();
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
    try {
      final box = await getBox();
      final entry = {
        'timestamp': DateTime.now().toIso8601String(),
        'mode': mode,
        'data': analysis,
        if (imagePath != null) 'image_path': imagePath,
      };
      await box.add(entry);
      await box.flush(); // Ensure persistence
    } catch (e) {
      debugPrint('❌ Error saving analysis: $e');
    }
  }


  Future<void> savePetAnalysis(String petName, Map<String, dynamic> analysis, {String? imagePath}) async {
    try {
      final box = await getBox();
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
      await box.flush(); // Ensure persistence
    } catch (e) {
       debugPrint('❌ Error saving pet analysis: $e');
       throw Exception('Não foi possível salvar os dados do pet. Tente novamente.');
    }
  }

  Future<void> clearHistory() async {
    final box = await getBox();
    await box.clear();
  }

  Future<void> clearAllPets() async {
    final box = await getBox();
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
    final box = await getBox();
    final keysToDelete = <dynamic>[];
    
    for (var key in box.keys) {
      final value = box.get(key);
      if (value is Map && value['mode'] == 'Plant') {
        keysToDelete.add(key);
      }
    }
    
    await box.deleteAll(keysToDelete);

    // Also clear botany boxes
    final plantBoxes = ['box_botany_intel', 'box_plants_history'];
    for(var b in plantBoxes) {
      try {
        if (Hive.isBoxOpen(b)) await Hive.box(b).clear();
        else await Hive.deleteBoxFromDisk(b);
      } catch (e) { debugPrint('Error clearing $b: $e'); }
    }

    // Physically delete plant images
    try {
       final appDir = await getApplicationDocumentsDirectory();
       final botanyDir = Directory('${appDir.path}/botany_images');
       if (await botanyDir.exists()) await botanyDir.delete(recursive: true);
    } catch (e) { debugPrint('Error deleting botany images: $e'); }
  }

  Future<void> clearAllFood() async {
    final box = await getBox();
    final keysToDelete = <dynamic>[];
    
    for (var key in box.keys) {
      final value = box.get(key);
      if (value is Map && value['mode'] == 'Food') {
        keysToDelete.add(key);
      }
    }
    
    await box.deleteAll(keysToDelete);

    // Also clear the dedicated nutrition boxes
    final foodBoxes = ['box_nutrition_human', 'nutrition_weekly_plans', 'meal_log', 'nutrition_shopping_list', 'scannut_meal_history'];
    for(var b in foodBoxes) {
      try {
        if (Hive.isBoxOpen(b)) await Hive.box(b).clear();
        else await Hive.deleteBoxFromDisk(b);
      } catch (e) { debugPrint('Error clearing $b: $e'); }
    }

    // Clear Food Events from Pet Journal
    try {
      if (Hive.isBoxOpen('pet_events_journal')) {
        final journal = Hive.box('pet_events_journal');
        final keysToDelete = journal.keys.where((k) {
          final val = journal.get(k);
          // Check if it's a Map or PetEventModel and has group 'food'
          if (val is Map) return val['group'] == 'food';
          // If it's the model, we can't easily check without casting but we can try common keys
          try { return (val as dynamic).group == 'food'; } catch(_) { return false; }
        }).toList();
        await journal.deleteAll(keysToDelete);
        debugPrint('🧹 Cleared ${keysToDelete.length} food events from journal');
      }
    } catch (e) { debugPrint('Error clearing food journal: $e'); }

    // Physically delete food images
    try {
       final appDir = await getApplicationDocumentsDirectory();
       final foodDir = Directory('${appDir.path}/nutrition_images');
       if (await foodDir.exists()) await foodDir.delete(recursive: true);
    } catch (e) { debugPrint('Error deleting food images: $e'); }
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
      'pet_health_records',
      'pet_events_journal'
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

    // Physically wipe ALL files in documents directory
    try {
       final appDir = await getApplicationDocumentsDirectory();
       if (await appDir.exists()) {
          final entities = appDir.listSync();
          for (var entity in entities) {
             // Don't delete our .env if it was copied there, but usually it's not.
             // Be aggressive. 
             await entity.delete(recursive: true);
          }
       }
       debugPrint('☢️  FILESYSTEM WIPE CONCLUÍDO.');
    } catch (e) {
       debugPrint('⚠️  FILESYSTEM WIPE ERROR: $e');
    }

    debugPrint('☢️  SISTEMA RESETADO DE FÁBRICA.');
  }
}
