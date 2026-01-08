// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'partner_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PartnerModelAdapter extends TypeAdapter<PartnerModel> {
  @override
  final int typeId = 5;

  @override
  PartnerModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PartnerModel(
      id: fields[0] as String,
      name: fields[1] as String,
      cnpj: fields[2] as String?,
      category: fields[3] as String,
      latitude: fields[4] as double,
      longitude: fields[5] as double,
      phone: fields[6] as String,
      whatsapp: fields[7] as String?,
      instagram: fields[8] as String?,
      email: fields[16] as String?,
      address: fields[9] as String,
      openingHours: (fields[10] as Map).cast<String, dynamic>(),
      rating: fields[11] as double,
      photos: (fields[12] as List).cast<String>(),
      specialties: (fields[13] as List).cast<String>(),
      metadata: (fields[14] as Map).cast<String, dynamic>(),
      isFavorite: fields[15] as bool,
      teamMembers: (fields[17] as List).cast<String>(),
      website: fields[18] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PartnerModel obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.cnpj)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.latitude)
      ..writeByte(5)
      ..write(obj.longitude)
      ..writeByte(6)
      ..write(obj.phone)
      ..writeByte(7)
      ..write(obj.whatsapp)
      ..writeByte(8)
      ..write(obj.instagram)
      ..writeByte(9)
      ..write(obj.address)
      ..writeByte(10)
      ..write(obj.openingHours)
      ..writeByte(11)
      ..write(obj.rating)
      ..writeByte(12)
      ..write(obj.photos)
      ..writeByte(13)
      ..write(obj.specialties)
      ..writeByte(14)
      ..write(obj.metadata)
      ..writeByte(15)
      ..write(obj.isFavorite)
      ..writeByte(16)
      ..write(obj.email)
      ..writeByte(17)
      ..write(obj.teamMembers)
      ..writeByte(18)
      ..write(obj.website);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PartnerModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
