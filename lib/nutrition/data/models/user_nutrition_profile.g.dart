// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_nutrition_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserNutritionProfileAdapter extends TypeAdapter<UserNutritionProfile> {
  @override
  final int typeId = 24;

  @override
  UserNutritionProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserNutritionProfile(
      objetivo: fields[0] as String,
      restricoes: (fields[1] as List).cast<String>(),
      metaRefeicoesSemanais: fields[2] as int,
      metaAguaDiaria: fields[3] as int,
      horariosRefeicoes: (fields[4] as Map).cast<String, String>(),
      criadoEm: fields[5] as DateTime,
      atualizadoEm: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, UserNutritionProfile obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.objetivo)
      ..writeByte(1)
      ..write(obj.restricoes)
      ..writeByte(2)
      ..write(obj.metaRefeicoesSemanais)
      ..writeByte(3)
      ..write(obj.metaAguaDiaria)
      ..writeByte(4)
      ..write(obj.horariosRefeicoes)
      ..writeByte(5)
      ..write(obj.criadoEm)
      ..writeByte(6)
      ..write(obj.atualizadoEm);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserNutritionProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
