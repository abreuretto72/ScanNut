import 'package:hive/hive.dart';
import 'attachment_model.dart';

part 'pet_event_model.g.dart';

@HiveType(typeId: 41)
class PetEventModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String petId;

  @HiveField(2)
  final String group; // food, health, elimination, grooming, activity, behavior, schedule, media, metrics

  @HiveField(3)
  final String type; // Subtype (e.g., 'medication', 'vaccine')

  @HiveField(4)
  final String title;

  @HiveField(5)
  final String notes;

  @HiveField(6)
  final DateTime timestamp;

  @HiveField(7)
  final bool includeInPdf;

  @HiveField(8)
  final Map<dynamic, dynamic> data; // Changed to Map<dynamic, dynamic> for Hive compatibility with generic maps

  @HiveField(9)
  final List<AttachmentModel> attachments;

  @HiveField(10)
  final DateTime createdAt;

  @HiveField(11)
  final DateTime updatedAt;

  @HiveField(12)
  final bool isDeleted;

  PetEventModel({
    required this.id,
    required this.petId,
    required this.group,
    required this.type,
    required this.title,
    required this.notes,
    required this.timestamp,
    this.includeInPdf = true,
    required this.data,
    this.attachments = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  PetEventModel copyWith({
    String? title,
    String? notes,
    DateTime? timestamp,
    bool? includeInPdf,
    Map<dynamic, dynamic>? data,
    List<AttachmentModel>? attachments,
    bool? isDeleted,
  }) {
    return PetEventModel(
      id: id,
      petId: petId,
      group: group,
      type: type,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      timestamp: timestamp ?? this.timestamp,
      includeInPdf: includeInPdf ?? this.includeInPdf,
      data: data ?? this.data,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
