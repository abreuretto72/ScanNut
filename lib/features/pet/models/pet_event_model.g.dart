// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pet_event_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PetEventModelAdapter extends TypeAdapter<PetEventModel> {
  @override
  final int typeId = 41;

  @override
  PetEventModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PetEventModel(
      id: fields[0] as String,
      petId: fields[1] as String,
      group: fields[2] as String,
      type: fields[3] as String,
      title: fields[4] as String,
      notes: fields[5] as String,
      timestamp: fields[6] as DateTime,
      includeInPdf: fields[7] as bool,
      data: (fields[8] as Map).cast<dynamic, dynamic>(),
      attachments: (fields[9] as List).cast<AttachmentModel>(),
      createdAt: fields[10] as DateTime,
      updatedAt: fields[11] as DateTime,
      isDeleted: fields[12] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, PetEventModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.petId)
      ..writeByte(2)
      ..write(obj.group)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.title)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.timestamp)
      ..writeByte(7)
      ..write(obj.includeInPdf)
      ..writeByte(8)
      ..write(obj.data)
      ..writeByte(9)
      ..write(obj.attachments)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.updatedAt)
      ..writeByte(12)
      ..write(obj.isDeleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PetEventModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
