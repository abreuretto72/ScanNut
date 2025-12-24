// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_list_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ShoppingListItemAdapter extends TypeAdapter<ShoppingListItem> {
  @override
  final int typeId = 30;

  @override
  ShoppingListItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ShoppingListItem(
      nome: fields[0] as String,
      quantidadeTexto: fields[1] as String,
      marcado: fields[2] as bool,
      criadoEm: fields[3] as DateTime,
      marcadoEm: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ShoppingListItem obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.nome)
      ..writeByte(1)
      ..write(obj.quantidadeTexto)
      ..writeByte(2)
      ..write(obj.marcado)
      ..writeByte(3)
      ..write(obj.criadoEm)
      ..writeByte(4)
      ..write(obj.marcadoEm);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShoppingListItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
