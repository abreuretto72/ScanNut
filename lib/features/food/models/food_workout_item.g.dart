// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_workout_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkoutItemAdapter extends TypeAdapter<WorkoutItem> {
  @override
  final int typeId = 22;

  @override
  WorkoutItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkoutItem(
      id: fields[0] as String,
      timestamp: fields[1] as DateTime,
      exerciseName: fields[2] as String,
      caloriesBurned: fields[3] as int,
      durationMinutes: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutItem obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.exerciseName)
      ..writeByte(3)
      ..write(obj.caloriesBurned)
      ..writeByte(4)
      ..write(obj.durationMinutes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
