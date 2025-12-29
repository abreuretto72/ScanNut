// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MealAdapter extends TypeAdapter<Meal> {
  @override
  final int typeId = 25;

  @override
  Meal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Meal(
      tipo: fields[0] as String,
      recipeId: fields[1] as String?,
      nomePrato: fields[5] as String?,
      itens: (fields[2] as List).cast<MealItem>(),
      observacoes: fields[3] as String,
      criadoEm: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Meal obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.tipo)
      ..writeByte(1)
      ..write(obj.recipeId)
      ..writeByte(2)
      ..write(obj.itens)
      ..writeByte(3)
      ..write(obj.observacoes)
      ..writeByte(4)
      ..write(obj.criadoEm)
      ..writeByte(5)
      ..write(obj.nomePrato);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MealItemAdapter extends TypeAdapter<MealItem> {
  @override
  final int typeId = 26;

  @override
  MealItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MealItem(
      nome: fields[0] as String,
      quantidadeTexto: fields[1] as String,
      observacoes: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MealItem obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.nome)
      ..writeByte(1)
      ..write(obj.quantidadeTexto)
      ..writeByte(2)
      ..write(obj.observacoes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
