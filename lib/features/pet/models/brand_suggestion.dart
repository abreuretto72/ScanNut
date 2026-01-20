import 'package:hive/hive.dart';

part 'brand_suggestion.g.dart';

@HiveType(typeId: 15) // 🛡️ Novo typeId para evitar conflitos
class BrandSuggestion {
  @HiveField(0)
  final String brand;

  @HiveField(1)
  final String reason;

  BrandSuggestion({
    required this.brand,
    required this.reason,
  });

  factory BrandSuggestion.fromJson(Map<String, dynamic> json) {
    return BrandSuggestion(
      brand: json['marca']?.toString() ?? json['brand']?.toString() ?? '',
      reason: json['por_que_escolhemos']?.toString() ?? 
              json['reason']?.toString() ?? 
              json['justificativa']?.toString() ?? 
              'Marca selecionada por critérios de qualidade Super Premium para o perfil do pet.', // 🛡️ Fallback
    );
  }

  Map<String, dynamic> toJson() => {
    'marca': brand,
    'por_que_escolhemos': reason,
  };

  // 🛡️ Helper para garantir que sempre há uma razão válida
  String get safeReason => reason.isEmpty 
    ? 'Marca selecionada por critérios de qualidade Super Premium para o perfil do pet.'
    : reason;
}
