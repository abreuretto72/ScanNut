import 'package:hive/hive.dart';
import 'plan_day.dart';

part 'weekly_plan.g.dart';

/// Plano semanal de refeições
/// TypeId: 28
@HiveType(typeId: 28)
class WeeklyPlan extends HiveObject {
  @HiveField(0)
  DateTime weekStartDate; // Segunda-feira da semana

  @HiveField(1)
  int seed; // Seed para regeneração

  @HiveField(2)
  List<PlanDay> days; // 7 dias

  @HiveField(3)
  DateTime criadoEm;

  @HiveField(4)
  DateTime atualizadoEm;

  WeeklyPlan({
    required this.weekStartDate,
    required this.seed,
    required this.days,
    required this.criadoEm,
    required this.atualizadoEm,
  });

  Map<String, dynamic> toJson() {
    return {
      'weekStartDate': weekStartDate.toIso8601String(),
      'seed': seed,
      'days': days.map((d) => d.toJson()).toList(),
      'criadoEm': criadoEm.toIso8601String(),
      'atualizadoEm': atualizadoEm.toIso8601String(),
    };
  }

  factory WeeklyPlan.fromJson(Map<String, dynamic> json) {
    return WeeklyPlan(
      weekStartDate: DateTime.parse(json['weekStartDate']),
      seed: json['seed'] ?? 0,
      days: (json['days'] as List?)?.map((d) => PlanDay.fromJson(d)).toList() ?? [],
      criadoEm: DateTime.parse(json['criadoEm']),
      atualizadoEm: DateTime.parse(json['atualizadoEm']),
    );
  }

  /// Retorna o dia da semana (0-6, sendo 0 = segunda)
  PlanDay? getDayByIndex(int index) {
    if (index >= 0 && index < days.length) {
      return days[index];
    }
    return null;
  }

  /// Retorna o dia por data
  PlanDay? getDayByDate(DateTime date) {
    try {
      return days.firstWhere(
        (day) => day.date.year == date.year && 
                 day.date.month == date.month && 
                 day.date.day == date.day,
      );
    } catch (e) {
      return null;
    }
  }
}
