import 'package:hive/hive.dart';

part 'shopping_list_item.g.dart';

/// Item da lista de compras
/// TypeId: 30
@HiveType(typeId: 30)
class ShoppingListItem extends HiveObject {
  @HiveField(0)
  String nome;

  @HiveField(1)
  String quantidadeTexto; // ex: "1 kg", "2 unidades", "1 bandeja"

  @HiveField(2)
  bool marcado; // Se já foi comprado

  @HiveField(3)
  DateTime criadoEm;

  @HiveField(4)
  DateTime? marcadoEm;

  ShoppingListItem({
    required this.nome,
    required this.quantidadeTexto,
    this.marcado = false,
    required this.criadoEm,
    this.marcadoEm,
  });

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'quantidadeTexto': quantidadeTexto,
      'marcado': marcado,
      'criadoEm': criadoEm.toIso8601String(),
      'marcadoEm': marcadoEm?.toIso8601String(),
    };
  }

  factory ShoppingListItem.fromJson(Map<String, dynamic> json) {
    return ShoppingListItem(
      nome: json['nome'] ?? '',
      quantidadeTexto: json['quantidadeTexto'] ?? '1 unidade',
      marcado: json['marcado'] ?? false,
      criadoEm: DateTime.parse(json['criadoEm']),
      marcadoEm:
          json['marcadoEm'] != null ? DateTime.parse(json['marcadoEm']) : null,
    );
  }

  /// Marca/desmarca o item
  void toggleMarcado() {
    marcado = !marcado;
    marcadoEm = marcado ? DateTime.now() : null;
  }
}
