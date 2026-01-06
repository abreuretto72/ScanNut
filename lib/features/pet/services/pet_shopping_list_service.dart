import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../../core/utils/json_cast.dart';

class PetShoppingListService {
  static final PetShoppingListService _instance = PetShoppingListService._internal();
  factory PetShoppingListService() => _instance;
  PetShoppingListService._internal();

  static const String boxName = 'pet_shopping_lists';
  
  Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
      debugPrint('🛒 PetShoppingListService initialized');
    }
  }

  Future<void> saveList(String planId, List<Map<String, dynamic>> items) async {
    await init();
    final box = Hive.box(boxName);
    await box.put(planId, items);
  }

  Future<List<Map<String, dynamic>>> getList(String planId) async {
    await init();
    final box = Hive.box(boxName);
    final data = box.get(planId);
    
    if (data == null) return [];
    
    return deepCastMapList(data);
  }

  Future<void> deleteList(String planId) async {
    await init();
    final box = Hive.box(boxName);
    await box.delete(planId);
  }
}
