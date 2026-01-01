/// ============================================================================
/// 🚫 MODELO BLINDADO E CONGELADO - NÃO ALTERAR
/// Este modelo representa o histórico persistente de alimentos do usuário.
/// Índices @HiveField (0-11) são imutáveis para garantir retrocompatibilidade.
/// Data de Congelamento: 01/01/2026
/// ============================================================================

import 'package:hive/hive.dart';

part 'nutrition_history_item.g.dart';

@HiveType(typeId: 20)
class NutritionHistoryItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime timestamp;

  @HiveField(2)
  final String foodName;

  @HiveField(3)
  final int calories;

  @HiveField(4)
  final String proteins;

  @HiveField(5)
  final String carbs;

  @HiveField(6)
  final String fats;

  @HiveField(7)
  final bool isUltraprocessed;

  @HiveField(8)
  final List<String> biohackingTips;

  @HiveField(9)
  final List<Map<String, String>> recipesList;

  @HiveField(10)
  final String? imagePath;

  @HiveField(11)
  final Map<String, dynamic>? rawMetadata;

  NutritionHistoryItem({
    required this.id,
    required this.timestamp,
    required this.foodName,
    required this.calories,
    required this.proteins,
    required this.carbs,
    required this.fats,
    required this.isUltraprocessed,
    required this.biohackingTips,
    required this.recipesList,
    this.imagePath,
    this.rawMetadata,
  });
}
