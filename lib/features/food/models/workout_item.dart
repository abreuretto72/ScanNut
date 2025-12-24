import 'package:hive/hive.dart';

part 'workout_item.g.dart';

@HiveType(typeId: 22)
class WorkoutItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime timestamp;

  @HiveField(2)
  final String exerciseName;

  @HiveField(3)
  final int caloriesBurned;

  @HiveField(4)
  final int durationMinutes;

  WorkoutItem({
    required this.id,
    required this.timestamp,
    required this.exerciseName,
    required this.caloriesBurned,
    required this.durationMinutes,
  });
}
