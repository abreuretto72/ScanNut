import 'package:flutter/foundation.dart';
import '../../data/models/weekly_plan.dart';
import '../../data/models/shopping_list_item.dart';

/// Gerador de lista de compras a partir do plano semanal
class ShoppingListGenerator {
  /// Gera lista de compras agregada do plano semanal
  List<ShoppingListItem> generateFromWeeklyPlan(WeeklyPlan plan) {
    try {
      final Map<String, int> itemCount = {};

      // Agregar todos os itens do plano
      for (final day in plan.days) {
        for (final meal in day.meals) {
          for (final item in meal.itens) {
            final nome = item.nome.toLowerCase().trim();
            itemCount[nome] = (itemCount[nome] ?? 0) + 1;
          }
        }
      }

      // Criar lista de compras
      final shoppingList = <ShoppingListItem>[];
      final now = DateTime.now();

      itemCount.forEach((nome, count) {
        shoppingList.add(ShoppingListItem(
          nome: _capitalize(nome),
          quantidadeTexto: count > 1 ? '$count unidades' : '1 unidade',
          marcado: false,
          criadoEm: now,
        ));
      });

      // Ordenar alfabeticamente
      shoppingList.sort((a, b) => a.nome.compareTo(b.nome));

      debugPrint('✅ Generated shopping list with ${shoppingList.length} items');
      return shoppingList;
    } catch (e) {
      debugPrint('❌ Error generating shopping list: $e');
      return [];
    }
  }

  /// Capitaliza a primeira letra
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
