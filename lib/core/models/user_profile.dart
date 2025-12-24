import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 23)
class UserProfile extends HiveObject {
  @HiveField(0)
  final String userName;

  @HiveField(1)
  final int dailyCalorieGoal;

  @HiveField(2)
  final double weight;

  @HiveField(3)
  final double height;

  @HiveField(4)
  final Map<String, dynamic> preferences;

  UserProfile({
    required this.userName,
    required this.dailyCalorieGoal,
    required this.weight,
    required this.height,
    required this.preferences,
  });
}
