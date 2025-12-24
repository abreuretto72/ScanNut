// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_day.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlanDayAdapter extends TypeAdapter<PlanDay> {
  @override
  final int typeId = 27;

  @override
  PlanDay read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlanDay(
      date: fields[0] as DateTime,
      meals: (fields[1] as List).cast<Meal>(),
      status: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PlanDay obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.meals)
      ..writeByte(2)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanDayAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
