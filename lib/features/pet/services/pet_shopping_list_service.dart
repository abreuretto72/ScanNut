import 'package:flutter/foundation.dart';
import '../../../core/services/hive_atomic_manager.dart';
import '../../../core/utils/json_cast.dart';

class PetShoppingListService {
  static final PetShoppingListService _instance = PetShoppingListService._internal();
  factory PetShoppingListService() => _instance;
  PetShoppingListService._internal();

  static const String boxName = 'pet_shopping_lists';
  
  Future<void> init() async {
    await HiveAtomicManager().ensureBoxOpen(boxName);
    debugPrint('🛒 PetShoppingListService initialized');
  }

  Future<void> saveList(String planId, List<Map<String, dynamic>> items) async {
    final box = await HiveAtomicManager().ensureBoxOpen(boxName);
    await box.put(planId, items);
  }

  Future<List<Map<String, dynamic>>> getList(String planId) async {
    final box = await HiveAtomicManager().ensureBoxOpen(boxName);
    final data = box.get(planId);
    
    if (data == null) return [];
    
    return deepCastMapList(data);
  }

  Future<void> deleteList(String planId) async {
    final box = await HiveAtomicManager().ensureBoxOpen(boxName);
    await box.delete(planId);
  }
}
