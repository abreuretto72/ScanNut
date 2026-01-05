import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import '../models/shopping_list_item.dart';

/// Serviço para gerenciar lista de compras
/// Box: nutrition_shopping_list
class ShoppingListService {
  static const String _boxName = 'nutrition_shopping_list';
  
  Box<ShoppingListItem>? _box;

  /// Inicializa o box
  Future<void> init({HiveCipher? cipher}) async {
    try {
      _box = await Hive.openBox<ShoppingListItem>(_boxName, encryptionCipher: cipher);
      debugPrint('✅ ShoppingListService initialized (Secure). Box Open: ${_box?.isOpen}');
    } catch (e) {
      debugPrint('❌ Error initializing Secure ShoppingListService: $e');
      rethrow;
    }
  }

  /// Adiciona um item à lista
  Future<void> addItem(ShoppingListItem item) async {
    try {
      await _box?.add(item);
      debugPrint('✅ Shopping item added: ${item.nome}');
    } catch (e) {
      debugPrint('❌ Error adding shopping item: $e');
      rethrow;
    }
  }

  /// Adiciona múltiplos itens
  Future<void> addItems(List<ShoppingListItem> items) async {
    try {
      for (final item in items) {
        await addItem(item);
      }
      debugPrint('✅ ${items.length} shopping items added');
    } catch (e) {
      debugPrint('❌ Error adding shopping items: $e');
      rethrow;
    }
  }

  /// Retorna todos os itens
  List<ShoppingListItem> getAllItems() {
    try {
      return _box?.values.toList() ?? [];
    } catch (e) {
      debugPrint('❌ Error getting all items: $e');
      return [];
    }
  }

  /// Retorna itens não marcados
  List<ShoppingListItem> getPendingItems() {
    try {
      return _box?.values.where((item) => !item.marcado).toList() ?? [];
    } catch (e) {
      debugPrint('❌ Error getting pending items: $e');
      return [];
    }
  }

  /// Retorna itens marcados
  List<ShoppingListItem> getCompletedItems() {
    try {
      return _box?.values.where((item) => item.marcado).toList() ?? [];
    } catch (e) {
      debugPrint('❌ Error getting completed items: $e');
      return [];
    }
  }

  /// Marca/desmarca um item
  Future<void> toggleItem(int index) async {
    try {
      final item = _box?.getAt(index);
      if (item != null) {
        item.toggleMarcado();
        await item.save();
        debugPrint('✅ Item toggled: ${item.nome} - ${item.marcado}');
      }
    } catch (e) {
      debugPrint('❌ Error toggling item: $e');
      rethrow;
    }
  }

  /// Remove um item
  Future<void> deleteItem(int index) async {
    try {
      await _box?.deleteAt(index);
      debugPrint('🗑️ Shopping item deleted at index: $index');
    } catch (e) {
      debugPrint('❌ Error deleting shopping item: $e');
      rethrow;
    }
  }

  /// Remove todos os itens marcados
  Future<void> clearCompleted() async {
    try {
      final completedIndices = <int>[];
      final items = _box?.values.toList() ?? [];
      
      for (int i = 0; i < items.length; i++) {
        if (items[i].marcado) {
          completedIndices.add(i);
        }
      }
      
      // Remove de trás para frente para não afetar os índices
      for (int i = completedIndices.length - 1; i >= 0; i--) {
        await _box?.deleteAt(completedIndices[i]);
      }
      
      debugPrint('🧹 ${completedIndices.length} completed items removed');
    } catch (e) {
      debugPrint('❌ Error clearing completed items: $e');
      rethrow;
    }
  }

  /// Limpa toda a lista
  Future<void> clearAll() async {
    try {
      await _box?.clear();
      debugPrint('🧹 ShoppingListService cleared');
    } catch (e) {
      debugPrint('❌ Error clearing ShoppingListService: $e');
      rethrow;
    }
  }

  /// Fecha o box
  Future<void> close() async {
    try {
      await _box?.close();
      debugPrint('📦 ShoppingListService closed');
    } catch (e) {
      debugPrint('❌ Error closing ShoppingListService: $e');
    }
  }
}
