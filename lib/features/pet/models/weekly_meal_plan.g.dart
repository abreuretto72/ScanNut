// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weekly_meal_plan.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WeeklyMealPlanAdapter extends TypeAdapter<WeeklyMealPlan> {
  @override
  final int typeId = 8;

  @override
  WeeklyMealPlan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WeeklyMealPlan(
      id: fields[0] as String,
      petId: fields[1] as String,
      startDate: fields[2] as DateTime,
      endDate: fields[3] as DateTime,
      dietType: fields[4] as String,
      nutritionalGoal: fields[5] as String,
      meals: (fields[6] as List).cast<DailyMealItem>(),
      metadata: fields[7] as NutrientMetadata,
      templateName: fields[8] as String?,
      createdAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, WeeklyMealPlan obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.petId)
      ..writeByte(2)
      ..write(obj.startDate)
      ..writeByte(3)
      ..write(obj.endDate)
      ..writeByte(4)
      ..write(obj.dietType)
      ..writeByte(5)
      ..write(obj.nutritionalGoal)
      ..writeByte(6)
      ..write(obj.meals)
      ..writeByte(7)
      ..write(obj.metadata)
      ..writeByte(8)
      ..write(obj.templateName)
      ..writeByte(9)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeeklyMealPlanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DailyMealItemAdapter extends TypeAdapter<DailyMealItem> {
  @override
  final int typeId = 9;

  @override
  DailyMealItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyMealItem(
      dayOfWeek: fields[0] as int,
      time: fields[1] as String,
      title: fields[2] as String,
      description: fields[3] as String,
      quantity: fields[4] as String,
      benefit: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DailyMealItem obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.dayOfWeek)
      ..writeByte(1)
      ..write(obj.time)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.quantity)
      ..writeByte(5)
      ..write(obj.benefit);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyMealItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NutrientMetadataAdapter extends TypeAdapter<NutrientMetadata> {
  @override
  final int typeId = 10;

  @override
  NutrientMetadata read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NutrientMetadata(
      protein: fields[0] as String,
      fat: fields[1] as String,
      fiber: fields[2] as String,
      micronutrients: fields[3] as String,
      hydration: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, NutrientMetadata obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.protein)
      ..writeByte(1)
      ..write(obj.fat)
      ..writeByte(2)
      ..write(obj.fiber)
      ..writeByte(3)
      ..write(obj.micronutrients)
      ..writeByte(4)
      ..write(obj.hydration);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NutrientMetadataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
