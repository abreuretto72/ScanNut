import 'package:hive/hive.dart';

part 'botany_history_item.g.dart';

@HiveType(typeId: 21)
class BotanyHistoryItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime timestamp;

  @HiveField(2)
  final String plantName;

  @HiveField(3)
  final String healthStatus; // saudável/doente

  @HiveField(4)
  final String? diseaseDiagnosis;

  @HiveField(5)
  final String recoveryPlan;

  @HiveField(6)
  final String survivalSemaphore; // verde/amarelo/vermelho

  @HiveField(7)
  final Map<String, String> lightWaterSoilNeeds;

  @HiveField(8)
  final String fengShuiTips;

  @HiveField(9)
  final String? imagePath;

  @HiveField(10)
  final String toxicityStatus; // safe / toxic / harmful_pets

  @HiveField(12)
  final Map<String, dynamic>? rawMetadata;

  BotanyHistoryItem({
    required this.id,
    required this.timestamp,
    required this.plantName,
    required this.healthStatus,
    this.diseaseDiagnosis,
    required this.recoveryPlan,
    required this.survivalSemaphore,
    required this.lightWaterSoilNeeds,
    required this.fengShuiTips,
    this.imagePath,
    required this.toxicityStatus,
    this.rawMetadata,
  });
}
