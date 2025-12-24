import 'package:hive/hive.dart';
import 'meal.dart';

part 'meal_log.g.dart';

/// Registro de refeição consumida
/// TypeId: 29
@HiveType(typeId: 29)
class MealLog extends HiveObject {
  @HiveField(0)
  DateTime dateTime; // Data e hora do consumo

  @HiveField(1)
  String tipo; // cafe, almoco, lanche, jantar

  @HiveField(2)
  String origem; // plano, manual, scan

  @HiveField(3)
  List<MealItem> itens;

  @HiveField(4)
  bool aderenteAoPlano; // Se seguiu o plano ou não

  @HiveField(5)
  String observacoes;

  MealLog({
    required this.dateTime,
    required this.tipo,
    required this.origem,
    required this.itens,
    this.aderenteAoPlano = false,
    this.observacoes = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'dateTime': dateTime.toIso8601String(),
      'tipo': tipo,
      'origem': origem,
      'itens': itens.map((i) => i.toJson()).toList(),
      'aderenteAoPlano': aderenteAoPlano,
      'observacoes': observacoes,
    };
  }

  factory MealLog.fromJson(Map<String, dynamic> json) {
    return MealLog(
      dateTime: DateTime.parse(json['dateTime']),
      tipo: json['tipo'] ?? '',
      origem: json['origem'] ?? 'manual',
      itens: (json['itens'] as List?)?.map((i) => MealItem.fromJson(i)).toList() ?? [],
      aderenteAoPlano: json['aderenteAoPlano'] ?? false,
      observacoes: json['observacoes'] ?? '',
    );
  }

  /// Cria log a partir do scan
  factory MealLog.fromScan({
    required String tipo,
    required List<MealItem> itens,
    String observacoes = '',
  }) {
    return MealLog(
      dateTime: DateTime.now(),
      tipo: tipo,
      origem: 'scan',
      itens: itens,
      aderenteAoPlano: false,
      observacoes: observacoes,
    );
  }

  /// Cria log a partir do plano
  factory MealLog.fromPlano({
    required String tipo,
    required List<MealItem> itens,
  }) {
    return MealLog(
      dateTime: DateTime.now(),
      tipo: tipo,
      origem: 'plano',
      itens: itens,
      aderenteAoPlano: true,
      observacoes: 'Consumido do plano semanal',
    );
  }
}
