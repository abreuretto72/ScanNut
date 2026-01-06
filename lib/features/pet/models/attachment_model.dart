import 'package:hive/hive.dart';

part 'attachment_model.g.dart';

@HiveType(typeId: 40)
class AttachmentModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String kind; // image, video, audio, file

  @HiveField(2)
  final String path;

  @HiveField(3)
  final String mimeType;

  @HiveField(4)
  final int size;

  @HiveField(5)
  final String hash;

  @HiveField(6)
  final DateTime createdAt;

  AttachmentModel({
    required this.id,
    required this.kind,
    required this.path,
    required this.mimeType,
    required this.size,
    required this.hash,
    required this.createdAt,
  });
}
