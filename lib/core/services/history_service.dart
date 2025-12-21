import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  }
}
