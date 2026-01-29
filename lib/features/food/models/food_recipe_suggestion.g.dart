// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_recipe_suggestion.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecipeSuggestionAdapter extends TypeAdapter<RecipeSuggestion> {
  @override
  final int typeId = 32;

  @override
  RecipeSuggestion read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecipeSuggestion(
      id: fields[0] as String,
      name: fields[1] as String,
      instructions: fields[2] as String,
      prepTime: fields[3] as String,
      justification: fields[4] as String,
      difficulty: fields[5] as String,
      calories: fields[6] as String,
      sourceFood: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, RecipeSuggestion obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.instructions)
      ..writeByte(3)
      ..write(obj.prepTime)
      ..writeByte(4)
      ..write(obj.justification)
      ..writeByte(5)
      ..write(obj.difficulty)
      ..writeByte(6)
      ..write(obj.calories)
      ..writeByte(7)
      ..write(obj.sourceFood);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeSuggestionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
