// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'botany_history_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BotanyHistoryItemAdapter extends TypeAdapter<BotanyHistoryItem> {
  @override
  final int typeId = 21;

  @override
  BotanyHistoryItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BotanyHistoryItem(
      id: fields[0] as String,
      timestamp: fields[1] as DateTime,
      plantName: fields[2] as String,
      healthStatus: fields[3] as String,
      diseaseDiagnosis: fields[4] as String?,
      recoveryPlan: fields[5] as String,
      survivalSemaphore: fields[6] as String,
      lightWaterSoilNeeds: (fields[7] as Map).cast<String, String>(),
      fengShuiTips: fields[8] as String,
      imagePath: fields[9] as String?,
      toxicityStatus: fields[10] as String,
      rawMetadata: (fields[12] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, BotanyHistoryItem obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.plantName)
      ..writeByte(3)
      ..write(obj.healthStatus)
      ..writeByte(4)
      ..write(obj.diseaseDiagnosis)
      ..writeByte(5)
      ..write(obj.recoveryPlan)
      ..writeByte(6)
      ..write(obj.survivalSemaphore)
      ..writeByte(7)
      ..write(obj.lightWaterSoilNeeds)
      ..writeByte(8)
      ..write(obj.fengShuiTips)
      ..writeByte(9)
      ..write(obj.imagePath)
      ..writeByte(10)
      ..write(obj.toxicityStatus)
      ..writeByte(12)
      ..write(obj.rawMetadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BotanyHistoryItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
