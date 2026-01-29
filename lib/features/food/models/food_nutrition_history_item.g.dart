// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_nutrition_history_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NutritionHistoryItemAdapter extends TypeAdapter<NutritionHistoryItem> {
  @override
  final int typeId = 20;

  @override
  NutritionHistoryItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NutritionHistoryItem(
      id: fields[0] as String,
      timestamp: fields[1] as DateTime,
      foodName: fields[2] as String,
      calories: fields[3] as int,
      proteins: fields[4] as String,
      carbs: fields[5] as String,
      fats: fields[6] as String,
      isUltraprocessed: fields[7] as bool,
      biohackingTips: (fields[8] as List).cast<String>(),
      recipesList: (fields[9] as List)
          .map((dynamic e) => (e as Map).cast<String, String>())
          .toList(),
      imagePath: fields[10] as String?,
      rawMetadata: (fields[11] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, NutritionHistoryItem obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.foodName)
      ..writeByte(3)
      ..write(obj.calories)
      ..writeByte(4)
      ..write(obj.proteins)
      ..writeByte(5)
      ..write(obj.carbs)
      ..writeByte(6)
      ..write(obj.fats)
      ..writeByte(7)
      ..write(obj.isUltraprocessed)
      ..writeByte(8)
      ..write(obj.biohackingTips)
      ..writeByte(9)
      ..write(obj.recipesList)
      ..writeByte(10)
      ..write(obj.imagePath)
      ..writeByte(11)
      ..write(obj.rawMetadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NutritionHistoryItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
