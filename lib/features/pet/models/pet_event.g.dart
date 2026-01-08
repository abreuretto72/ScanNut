// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pet_event.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

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
      createdAt: fields[9] as DateTime?,
      attendant: fields[10] as String?,
      partnerId: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PetEvent obj) {
    writer
      ..writeByte(12)
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
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.attendant)
      ..writeByte(11)
      ..write(obj.partnerId);
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
      case 6:
        return EventType.food;
      case 7:
        return EventType.elimination;
      case 8:
        return EventType.activity;
      case 9:
        return EventType.behavior;
      case 10:
        return EventType.media;
      case 11:
        return EventType.metrics;
      case 12:
        return EventType.documents;
      case 13:
        return EventType.exams;
      case 14:
        return EventType.dentistry;
      case 15:
        return EventType.parasite;
      case 16:
        return EventType.surgery;
      default:
        return EventType.vaccine;
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
      case EventType.food:
        writer.writeByte(6);
        break;
      case EventType.elimination:
        writer.writeByte(7);
        break;
      case EventType.activity:
        writer.writeByte(8);
        break;
      case EventType.behavior:
        writer.writeByte(9);
        break;
      case EventType.media:
        writer.writeByte(10);
        break;
      case EventType.metrics:
        writer.writeByte(11);
        break;
      case EventType.documents:
        writer.writeByte(12);
        break;
      case EventType.exams:
        writer.writeByte(13);
        break;
      case EventType.dentistry:
        writer.writeByte(14);
        break;
      case EventType.parasite:
        writer.writeByte(15);
        break;
      case EventType.surgery:
        writer.writeByte(16);
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
