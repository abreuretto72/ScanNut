import 'package:hive/hive.dart';
import 'meal.dart';

part 'plan_day.g.dart';

/// Dia do plano semanal
/// TypeId: 27
@HiveType(typeId: 27)
class PlanDay extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  List<Meal> meals; // Refeições do dia

  @HiveField(2)
  String status; // planejado, em_andamento, concluido

  PlanDay({
    required this.date,
    required this.meals,
    this.status = 'planejado',
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'meals': meals.map((m) => m.toJson()).toList(),
      'status': status,
    };
  }

  factory PlanDay.fromJson(Map<String, dynamic> json) {
    return PlanDay(
      date: DateTime.parse(json['date']),
      meals:
          (json['meals'] as List?)?.map((m) => Meal.fromJson(m)).toList() ?? [],
      status: json['status'] ?? 'planejado',
    );
  }
}
