
class AnaliseFezesModel {
  final DateTime dataAnalise;
  final String imagemRef;
  final String caracteristicas;
  final String descricaoVisual;
  final Map<String, dynamic> stoolDetails;
  final List<String> possiveisCausas;
  final String nivelRisco; // Verde, Amarelo, Vermelho
  final String recomendacao;

  AnaliseFezesModel({
    required this.dataAnalise,
    required this.imagemRef,
    required this.caracteristicas,
    required this.descricaoVisual,
    required this.stoolDetails,
    required this.possiveisCausas,
    required this.nivelRisco,
    required this.recomendacao,
  });

  factory AnaliseFezesModel.fromJson(Map<String, dynamic> json) {
    return AnaliseFezesModel(
      dataAnalise: DateTime.parse(json['dataAnalise'] ?? DateTime.now().toIso8601String()),
      imagemRef: json['imagemRef'] ?? '',
      caracteristicas: json['caracteristicas'] ?? '',
      descricaoVisual: json['descricaoVisual'] ?? '',
      stoolDetails: Map<String, dynamic>.from(json['stoolDetails'] ?? {}),
      possiveisCausas: List<String>.from(json['possiveisCausas'] ?? []),
      nivelRisco: json['nivelRisco'] ?? 'Verde',
      recomendacao: json['recomendacao'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dataAnalise': dataAnalise.toIso8601String(),
      'imagemRef': imagemRef,
      'caracteristicas': caracteristicas,
      'descricaoVisual': descricaoVisual,
      'stoolDetails': stoolDetails,
      'possiveisCausas': possiveisCausas,
      'nivelRisco': nivelRisco,
      'recomendacao': recomendacao,
    };
  }

  // Getters for Bristol Scale and other details for UI
  int get bristolScale => stoolDetails['consistency_bristol_scale'] ?? 4;
  String get colorHex => stoolDetails['color_hex'] ?? '#8B4513';
  String get colorName => stoolDetails['color_name'] ?? 'Marrom';
  String get clinicalColorMeaning => stoolDetails['clinical_color_meaning'] ?? '';
  List<String> get foreignBodies => List<String>.from(stoolDetails['foreign_bodies'] ?? []);
  bool get parasitesDetected => stoolDetails['parasites_detected'] ?? false;
  String get volumeAssessment => stoolDetails['volume_assessment'] ?? '';
}
