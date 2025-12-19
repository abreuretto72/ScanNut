class PetAnalysisResult {
  final String especie;
  final String descricaoVisual;
  final List<String> possiveisCausas;
  final String urgenciaNivel; // 'Verde', 'Amarelo', 'Vermelho'
  final String orientacaoImediata;

  PetAnalysisResult({
    required this.especie,
    required this.descricaoVisual,
    required this.possiveisCausas,
    required this.urgenciaNivel,
    required this.orientacaoImediata,
  });

  factory PetAnalysisResult.fromJson(Map<String, dynamic> json) {
    return PetAnalysisResult(
      especie: json['especie'] ?? 'Desconhecido',
      descricaoVisual: json['descricao_visual'] ?? 'Sem descrição.',
      possiveisCausas: List<String>.from(json['possiveis_causas'] ?? []),
      urgenciaNivel: json['urgencia_nivel'] ?? 'Amarelo',
      orientacaoImediata: json['orientacao_imediata'] ?? 'Consulte um veterinário.',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'especie': especie,
      'descricao_visual': descricaoVisual,
      'possiveis_causas': possiveisCausas,
      'urgencia_nivel': urgenciaNivel,
      'orientacao_imediata': orientacaoImediata,
    };
  }
}
