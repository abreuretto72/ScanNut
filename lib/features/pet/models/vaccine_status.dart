import 'package:hive/hive.dart';

part 'vaccine_status.g.dart';

@HiveType(typeId: 7)
class VaccineStatus extends HiveObject {
  @HiveField(0)
  String petName;

  @HiveField(1)
  String vaccineName;

  @HiveField(2)
  bool isCompleted;

  @HiveField(3)
  DateTime? completedDate;

  @HiveField(4)
  DateTime createdAt;

  VaccineStatus({
    required this.petName,
    required this.vaccineName,
    this.isCompleted = false,
    this.completedDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get key => '${petName}_$vaccineName';
}
