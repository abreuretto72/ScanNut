// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_history_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecipeHistoryItemAdapter extends TypeAdapter<RecipeHistoryItem> {
  @override
  final int typeId = 31;

  @override
  RecipeHistoryItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecipeHistoryItem(
      id: fields[0] as String,
      foodName: fields[1] as String,
      recipeName: fields[2] as String,
      instructions: fields[3] as String,
      prepTime: fields[4] as String,
      timestamp: fields[5] as DateTime,
      imagePath: fields[6] as String?,
      justification: fields[7] as String?,
      difficulty: fields[8] as String?,
      calories: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, RecipeHistoryItem obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.foodName)
      ..writeByte(2)
      ..write(obj.recipeName)
      ..writeByte(3)
      ..write(obj.instructions)
      ..writeByte(4)
      ..write(obj.prepTime)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.imagePath)
      ..writeByte(7)
      ..write(obj.justification)
      ..writeByte(8)
      ..write(obj.difficulty)
      ..writeByte(9)
      ..write(obj.calories);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeHistoryItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
