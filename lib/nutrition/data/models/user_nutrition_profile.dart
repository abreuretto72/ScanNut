import 'package:hive/hive.dart';

part 'user_nutrition_profile.g.dart';

/// Perfil nutricional do usuário
/// TypeId: 24
@HiveType(typeId: 24)
class UserNutritionProfile extends HiveObject {
  @HiveField(0)
  String objetivo; // emagrecer, manter, saude, ganhar_massa

  @HiveField(1)
  List<String> restricoes; // sem_lactose, sem_gluten, diabetes, hipertensao, vegetariano, vegano

  @HiveField(2)
  int metaRefeicoesSemanais; // ex: 21 (3 refeições x 7 dias)

  @HiveField(3)
  int metaAguaDiaria; // em ml, ex: 2000

  @HiveField(4)
  Map<String, String> horariosRefeicoes; // cafe: "07:00", almoco: "12:00", jantar: "19:00", lanche: "15:00"

  @HiveField(5)
  DateTime criadoEm;

  @HiveField(6)
  DateTime atualizadoEm;

  UserNutritionProfile({
    required this.objetivo,
    required this.restricoes,
    required this.metaRefeicoesSemanais,
    required this.metaAguaDiaria,
    required this.horariosRefeicoes,
    required this.criadoEm,
    required this.atualizadoEm,
  });

  /// Factory para criar perfil padrão
  factory UserNutritionProfile.padrao() {
    final now = DateTime.now();
    return UserNutritionProfile(
      objetivo: 'saude',
      restricoes: [],
      metaRefeicoesSemanais: 21, // 3 refeições x 7 dias
      metaAguaDiaria: 2000, // 2L
      horariosRefeicoes: {
        'cafe': '07:00',
        'almoco': '12:00',
        'lanche': '15:00',
        'jantar': '19:00',
      },
      criadoEm: now,
      atualizadoEm: now,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'objetivo': objetivo,
      'restricoes': restricoes,
      'metaRefeicoesSemanais': metaRefeicoesSemanais,
      'metaAguaDiaria': metaAguaDiaria,
      'horariosRefeicoes': horariosRefeicoes,
      'criadoEm': criadoEm.toIso8601String(),
      'atualizadoEm': atualizadoEm.toIso8601String(),
    };
  }

  factory UserNutritionProfile.fromJson(Map<String, dynamic> json) {
    return UserNutritionProfile(
      objetivo: json['objetivo'] ?? 'saude',
      restricoes: List<String>.from(json['restricoes'] ?? []),
      metaRefeicoesSemanais: json['metaRefeicoesSemanais'] ?? 21,
      metaAguaDiaria: json['metaAguaDiaria'] ?? 2000,
      horariosRefeicoes: Map<String, String>.from(json['horariosRefeicoes'] ?? {}),
      criadoEm: DateTime.parse(json['criadoEm']),
      atualizadoEm: DateTime.parse(json['atualizadoEm']),
    );
  }
}
