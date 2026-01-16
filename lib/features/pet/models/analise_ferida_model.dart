
class AnaliseFeridaModel {
  final DateTime dataAnalise;
  final String imagemRef;
  final Map<String, dynamic> achadosVisuais; // Hiperemia, Opacidade, etc.
  final String nivelRisco; // Verde, Amarelo, Vermelho
  final String recomendacao;
  // Campos extras para Deep Analysis 360
  final String? profundidadeEstimada; // Cubagem
  final List<String> diagnosticosProvaveis;
  final Map<String, dynamic>? rawClinicalSigns; // Dados brutos da IA
  final String? categoria; // 🛡️ V460: Tag de Especialidade (olhos, dentes, pele, ferida)
  final String? descricaoVisual;
  final String? caracteristicas;

  AnaliseFeridaModel({
    required this.dataAnalise,
    required this.imagemRef,
    required this.achadosVisuais,
    required this.nivelRisco,
    required this.recomendacao,
    this.categoria,
    this.profundidadeEstimada,
    this.diagnosticosProvaveis = const [],
    this.rawClinicalSigns,
    this.descricaoVisual,
    this.caracteristicas,
  });

  factory AnaliseFeridaModel.fromJson(Map<String, dynamic> json) {
    return AnaliseFeridaModel(
      dataAnalise: DateTime.parse(json['dataAnalise']),
      imagemRef: json['imagemRef'],
      achadosVisuais: Map<String, dynamic>.from(json['achadosVisuais'] ?? {}),
      nivelRisco: json['nivelRisco'] ?? 'Verde',
      recomendacao: json['recomendacao'] ?? '',
      categoria: json['categoria'],
      profundidadeEstimada: json['profundidadeEstimada'],
      diagnosticosProvaveis: List<String>.from(json['diagnosticosProvaveis'] ?? []),
      rawClinicalSigns: json['rawClinicalSigns'] != null 
          ? Map<String, dynamic>.from(json['rawClinicalSigns']) 
          : null,
      descricaoVisual: json['descricaoVisual'],
      caracteristicas: json['caracteristicas'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dataAnalise': dataAnalise.toIso8601String(),
      'imagemRef': imagemRef,
      'achadosVisuais': achadosVisuais,
      'nivelRisco': nivelRisco,
      'recomendacao': recomendacao,
      'categoria': categoria,
      'profundidadeEstimada': profundidadeEstimada,
      'diagnosticosProvaveis': diagnosticosProvaveis,
      'rawClinicalSigns': rawClinicalSigns,
      'descricaoVisual': descricaoVisual,
      'caracteristicas': caracteristicas,
    };
  }
}
