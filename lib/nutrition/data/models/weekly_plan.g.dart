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
    );
  }

  @override
  void write(BinaryWriter writer, WeeklyPlan obj) {
    writer
      ..writeByte(6)
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
      ..write(obj.dicasPreparo);
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
