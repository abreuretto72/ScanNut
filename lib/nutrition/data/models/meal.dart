import 'package:hive/hive.dart';

part 'meal.g.dart';

/// Refeição individual
/// TypeId: 25
@HiveType(typeId: 25)
class Meal extends HiveObject {
  @HiveField(0)
  String tipo; // cafe, almoco, lanche, jantar

  @HiveField(1)
  String? recipeId; // ID da receita (se aplicável)

  @HiveField(2)
  List<MealItem> itens; // Itens da refeição

  @HiveField(3)
  String observacoes;

  @HiveField(4)
  DateTime criadoEm;

  Meal({
    required this.tipo,
    this.recipeId,
    required this.itens,
    this.observacoes = '',
    required this.criadoEm,
  });

  Map<String, dynamic> toJson() {
    return {
      'tipo': tipo,
      'recipeId': recipeId,
      'itens': itens.map((i) => i.toJson()).toList(),
      'observacoes': observacoes,
      'criadoEm': criadoEm.toIso8601String(),
    };
  }

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      tipo: json['tipo'] ?? '',
      recipeId: json['recipeId'],
      itens: (json['itens'] as List?)?.map((i) => MealItem.fromJson(i)).toList() ?? [],
      observacoes: json['observacoes'] ?? '',
      criadoEm: DateTime.parse(json['criadoEm']),
    );
  }
}

/// Item de uma refeição
/// TypeId: 26
@HiveType(typeId: 26)
class MealItem extends HiveObject {
  @HiveField(0)
  String nome;

  @HiveField(1)
  String quantidadeTexto; // ex: "1 porção", "200g", "1 xícara"

  @HiveField(2)
  String? observacoes; // macros ou outras informações

  MealItem({
    required this.nome,
    required this.quantidadeTexto,
    this.observacoes,
  });

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'quantidadeTexto': quantidadeTexto,
      'observacoes': observacoes,
    };
  }

  factory MealItem.fromJson(Map<String, dynamic> json) {
    return MealItem(
      nome: json['nome'] ?? '',
      quantidadeTexto: json['quantidadeTexto'] ?? '1 porção',
      observacoes: json['observacoes'],
    );
  }
}
