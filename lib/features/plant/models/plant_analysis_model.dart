class PlantAnalysisModel {
  final String plantName;
  final String condition;
  final String diagnosis;
  final String organicTreatment;
  final String urgency; // 'low', 'medium', 'high'

  PlantAnalysisModel({
    required this.plantName,
    required this.condition,
    required this.diagnosis,
    required this.organicTreatment,
    required this.urgency,
  });

  factory PlantAnalysisModel.fromJson(Map<String, dynamic> json) {
    return PlantAnalysisModel(
      plantName: json['plant_name'] ?? 'Planta Desconhecida',
      condition: json['condition'] ?? 'Desconhecido',
      diagnosis: json['diagnosis'] ?? 'Sem diagnóstico.',
      organicTreatment: json['organic_treatment'] ?? 'Consulte um especialista.',
      urgency: json['urgency'] ?? 'low',
    );
  }

  // Helper properties
  bool get isHealthy => condition.toLowerCase().contains('saudável') || diagnosis.toLowerCase().contains('saudável');
  double get urgencyValue {
    switch (urgency.toLowerCase()) {
      case 'high': return 0.9;
      case 'medium': return 0.5;
      case 'low': 
      default: return 0.1;
    }
  }
}
