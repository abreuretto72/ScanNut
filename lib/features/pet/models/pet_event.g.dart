// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pet_event.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EventTypeAdapter extends TypeAdapter<EventType> {
  @override
  final int typeId = 4;

  @override
  EventType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return EventType.vaccine;
      case 1:
        return EventType.bath;
      case 2:
        return EventType.grooming;
      case 3:
        return EventType.veterinary;
      case 4:
        return EventType.medication;
      case 5:
        return EventType.other;
      default:
        return EventType.other;
    }
  }

  @override
  void write(BinaryWriter writer, EventType obj) {
    switch (obj) {
      case EventType.vaccine:
        writer.writeByte(0);
        break;
      case EventType.bath:
        writer.writeByte(1);
        break;
      case EventType.grooming:
        writer.writeByte(2);
        break;
      case EventType.veterinary:
        writer.writeByte(3);
        break;
      case EventType.medication:
        writer.writeByte(4);
        break;
      case EventType.other:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RecurrenceTypeAdapter extends TypeAdapter<RecurrenceType> {
  @override
  final int typeId = 5;

  @override
  RecurrenceType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RecurrenceType.once;
      case 1:
        return RecurrenceType.daily;
      case 2:
        return RecurrenceType.weekly;
      case 3:
        return RecurrenceType.monthly;
      case 4:
        return RecurrenceType.yearly;
      default:
        return RecurrenceType.once;
    }
  }

  @override
  void write(BinaryWriter writer, RecurrenceType obj) {
    switch (obj) {
      case RecurrenceType.once:
        writer.writeByte(0);
        break;
      case RecurrenceType.daily:
        writer.writeByte(1);
        break;
      case RecurrenceType.weekly:
        writer.writeByte(2);
        break;
      case RecurrenceType.monthly:
        writer.writeByte(3);
        break;
      case RecurrenceType.yearly:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurrenceTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PetEventAdapter extends TypeAdapter<PetEvent> {
  @override
  final int typeId = 6;

  @override
  PetEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PetEvent(
      id: fields[0] as String,
      petName: fields[1] as String,
      title: fields[2] as String,
      type: fields[3] as EventType,
      dateTime: fields[4] as DateTime,
      recurrence: fields[5] as RecurrenceType,
      notificationMinutes: fields[6] as int,
      notes: fields[7] as String?,
      completed: fields[8] as bool,
      createdAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PetEvent obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.petName)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.dateTime)
      ..writeByte(5)
      ..write(obj.recurrence)
      ..writeByte(6)
      ..write(obj.notificationMinutes)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.completed)
      ..writeByte(9)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PetEventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
