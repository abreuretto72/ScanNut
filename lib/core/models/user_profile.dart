import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 23)
class UserProfile extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userName;

  @HiveField(2)
  final int dailyCalorieGoal;

  @HiveField(3)
  final double weight;

  @HiveField(4)
  final double height;

  @HiveField(5)
  final Map<String, dynamic> preferences;

  UserProfile({
    required this.id,
    required this.userName,
    required this.dailyCalorieGoal,
    required this.weight,
    required this.height,
    required this.preferences,
  });
}
