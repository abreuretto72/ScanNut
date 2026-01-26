import 'package:uuid/uuid.dart';

class FriendModel {
  final String id;
  final String name;
  final String gender;
  final String age;
  final String breed;
  final String ownerName;
  final String ownerContact;
  final DateTime registeredAt;

  FriendModel({
    required this.id,
    required this.name,
    required this.gender,
    required this.age,
    required this.breed,
    required this.ownerName,
    required this.ownerContact,
    required this.registeredAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'gender': gender,
      'age': age,
      'breed': breed,
      'ownerName': ownerName,
      'ownerContact': ownerContact,
      'registeredAt': registeredAt.toIso8601String(),
    };
  }

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      id: json['id'] ?? const Uuid().v4(),
      name: json['name'] ?? '',
      gender: json['gender'] ?? '',
      age: json['age'] ?? '',
      breed: json['breed'] ?? '',
      ownerName: json['ownerName'] ?? '',
      ownerContact: json['ownerContact'] ?? '',
      registeredAt: json['registeredAt'] != null 
          ? DateTime.parse(json['registeredAt']) 
          : DateTime.now(),
    );
  }
}
