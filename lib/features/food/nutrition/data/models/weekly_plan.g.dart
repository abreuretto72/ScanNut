// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weekly_plan.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WeeklyPlanAdapter extends TypeAdapter<WeeklyPlan> {
  @override
  final int typeId = 28;

  @override
  WeeklyPlan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WeeklyPlan(
      weekStartDate: fields[0] as DateTime,
      seed: fields[1] as int,
      days: (fields[2] as List).cast<PlanDay>(),
      criadoEm: fields[3] as DateTime,
      atualizadoEm: fields[4] as DateTime,
      dicasPreparo: fields[5] as String?,
      id: fields[6] as String?,
      periodType: fields[7] as String?,
      endDate: fields[8] as DateTime?,
      objective: fields[9] as String?,
      version: fields[10] as int,
      status: fields[11] as String,
      shoppingListJson: fields[12] as String?,
      petId: fields[13] as String?,
      petName: fields[14] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, WeeklyPlan obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.weekStartDate)
      ..writeByte(1)
      ..write(obj.seed)
      ..writeByte(2)
      ..write(obj.days)
      ..writeByte(3)
      ..write(obj.criadoEm)
      ..writeByte(4)
      ..write(obj.atualizadoEm)
      ..writeByte(5)
      ..write(obj.dicasPreparo)
      ..writeByte(6)
      ..write(obj.id)
      ..writeByte(7)
      ..write(obj.periodType)
      ..writeByte(8)
      ..write(obj.endDate)
      ..writeByte(9)
      ..write(obj.objective)
      ..writeByte(10)
      ..write(obj.version)
      ..writeByte(11)
      ..write(obj.status)
      ..writeByte(12)
      ..write(obj.shoppingListJson)
      ..writeByte(13)
      ..write(obj.petId)
      ..writeByte(14)
      ..write(obj.petName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeeklyPlanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
