// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'brand_suggestion.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BrandSuggestionAdapter extends TypeAdapter<BrandSuggestion> {
  @override
  final int typeId = 15;

  @override
  BrandSuggestion read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BrandSuggestion(
      brand: fields[0] as String,
      reason: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, BrandSuggestion obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.brand)
      ..writeByte(1)
      ..write(obj.reason);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BrandSuggestionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
