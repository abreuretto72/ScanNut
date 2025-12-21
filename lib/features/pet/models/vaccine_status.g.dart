// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vaccine_status.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VaccineStatusAdapter extends TypeAdapter<VaccineStatus> {
  @override
  final int typeId = 7;

  @override
  VaccineStatus read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VaccineStatus(
      petName: fields[0] as String,
      vaccineName: fields[1] as String,
      isCompleted: fields[2] as bool,
      completedDate: fields[3] as DateTime?,
      createdAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, VaccineStatus obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.petName)
      ..writeByte(1)
      ..write(obj.vaccineName)
      ..writeByte(2)
      ..write(obj.isCompleted)
      ..writeByte(3)
      ..write(obj.completedDate)
      ..writeByte(4)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VaccineStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
