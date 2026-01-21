import 'package:hive/hive.dart';
import 'plan_day.dart';

part 'weekly_plan.g.dart';

/// Plano semanal de refeições
/// TypeId: 28
@HiveType(typeId: 28)
class WeeklyPlan extends HiveObject {
  @HiveField(0)
  DateTime weekStartDate; // Início do período

  @HiveField(1)
  int seed; // Seed para regeneração

  @HiveField(2)
  List<PlanDay> days; // Dias do plano

  @HiveField(3)
  DateTime criadoEm;

  @HiveField(4)
  DateTime atualizadoEm;

  @HiveField(5)
  String? dicasPreparo;

  @HiveField(6)
  String? id; // UUID

  @HiveField(7)
  String? periodType; // weekly | monthly | 28days

  @HiveField(8)
  DateTime? endDate;

  @HiveField(9)
  String? objective; // maintenance | emagrecimento | etc

  @HiveField(10)
  int version;

  @HiveField(11)
  String status; // active | archived | deleted

  @HiveField(12)
  String? shoppingListJson; // JSON serialized WeeklyShoppingList list

  @HiveField(13)
  String? petId; // 🛡️ UUID Link

  @HiveField(14)
  String? petName; // For logging/UI

  WeeklyPlan({
    required this.weekStartDate,
    required this.seed,
    required this.days,
    required this.criadoEm,
    required this.atualizadoEm,
    this.dicasPreparo,
    this.id,
    this.periodType = 'weekly',
    this.endDate,
    this.objective = 'maintenance',
    this.version = 1,
    this.status = 'active',
    this.shoppingListJson,
    this.petId,
    this.petName,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'petId': petId,
      'petName': petName,
      'weekStartDate': weekStartDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'periodType': periodType,
      'objective': objective,
      'version': version,
      'status': status,
      'seed': seed,
      'days': days.map((day) => day.toJson()).toList(),
      'criadoEm': criadoEm.toIso8601String(),
      'atualizadoEm': atualizadoEm.toIso8601String(),
      'dicasPreparo': dicasPreparo,
      'shoppingListJson': shoppingListJson,
    };
  }

  factory WeeklyPlan.fromJson(Map<String, dynamic> json) {
    return WeeklyPlan(
      id: json['id'],
      weekStartDate: DateTime.parse(json['weekStartDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      periodType: json['periodType'] ?? 'weekly',
      objective: json['objective'] ?? 'maintenance',
      version: json['version'] ?? 1,
      status: json['status'] ?? 'active',
      seed: json['seed'] ?? 0,
      days: (json['days'] as List).map((dayJson) => PlanDay.fromJson(dayJson)).toList(),
      criadoEm: DateTime.parse(json['criadoEm']),
      atualizadoEm: DateTime.parse(json['atualizadoEm']),
      dicasPreparo: json['dicasPreparo'],
      shoppingListJson: json['shoppingListJson'] ?? json['shopping_list_json'],
      petId: json['petId'] ?? json['pet_id'],
      petName: json['petName'] ?? json['pet_name'],
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
