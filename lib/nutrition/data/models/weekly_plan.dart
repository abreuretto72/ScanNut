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

  @HiveField(5)
  String? dicasPreparo;

  WeeklyPlan({
    required this.weekStartDate,
    required this.seed,
    required this.days,
    required this.criadoEm,
    required this.atualizadoEm,
    this.dicasPreparo,
  });

  Map<String, dynamic> toJson() {
    return {
      'weekStartDate': weekStartDate.toIso8601String(),
      'seed': seed,
      'days': days.map((day) => day.toJson()).toList(),
      'criadoEm': criadoEm.toIso8601String(),
      'atualizadoEm': atualizadoEm.toIso8601String(),
      'dicasPreparo': dicasPreparo,
    };
  }

  factory WeeklyPlan.fromJson(Map<String, dynamic> json) {
    return WeeklyPlan(
      weekStartDate: DateTime.parse(json['weekStartDate']),
      seed: json['seed'] ?? 0,
      days: (json['days'] as List).map((dayJson) => PlanDay.fromJson(dayJson)).toList(),
      criadoEm: DateTime.parse(json['criadoEm']),
      atualizadoEm: DateTime.parse(json['atualizadoEm']),
      dicasPreparo: json['dicasPreparo'],
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
