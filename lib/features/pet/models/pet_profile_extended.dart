import 'pet_analysis_result.dart';

/// Extended Pet Profile Model with bio-information
class PetProfileExtended {
  // Identidade Biológica
  final String petName;
  final String? raca;
  final String? idadeExata; // "2 anos 3 meses" ou "15 meses"
  final double? pesoAtual; // kg
  final String? nivelAtividade; // Sedentário, Moderado, Ativo
  final String? statusReprodutivo; // Castrado, Inteiro
  
  // Restrições Alimentares
  final List<String> alergiasConhecidas;
  final List<String> preferencias;
  
  // Configurações de Lifestyle
  final DateTime? dataUltimaV10;
  final DateTime? dataUltimaAntirrabica;
  final String? frequenciaBanho; // Semanal, Quinzenal, Mensal
  
  // Metadata
  final DateTime lastUpdated;
  final String? imagePath;
  final Map<String, dynamic>? rawAnalysis; // Store complete analysis data

  PetProfileExtended({
    required this.petName,
    this.raca,
    this.idadeExata,
    this.pesoAtual,
    this.nivelAtividade,
    this.statusReprodutivo,
    this.alergiasConhecidas = const [],
    this.preferencias = const [],
    this.dataUltimaV10,
    this.dataUltimaAntirrabica,
    this.frequenciaBanho,
    required this.lastUpdated,
    this.imagePath,
    this.rawAnalysis,
  });

  factory PetProfileExtended.fromJson(Map<String, dynamic> json) {
    return PetProfileExtended(
      petName: json['pet_name'] as String,
      raca: json['raca'] as String?,
      idadeExata: json['idade_exata'] as String?,
      pesoAtual: (json['peso_atual'] as num?)?.toDouble(),
      nivelAtividade: json['nivel_atividade'] as String?,
      statusReprodutivo: json['status_reprodutivo'] as String?,
      alergiasConhecidas: (json['alergias_conhecidas'] as List?)?.cast<String>() ?? [],
      preferencias: (json['preferencias'] as List?)?.cast<String>() ?? [],
      dataUltimaV10: json['data_ultima_v10'] != null 
          ? DateTime.parse(json['data_ultima_v10'] as String)
          : null,
      dataUltimaAntirrabica: json['data_ultima_antirrabica'] != null
          ? DateTime.parse(json['data_ultima_antirrabica'] as String)
          : null,
      frequenciaBanho: json['frequencia_banho'] as String?,
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : DateTime.now(),
      imagePath: json['image_path'] as String?,
      rawAnalysis: json['raw_analysis'] != null 
          ? Map<String, dynamic>.from(json['raw_analysis'] as Map) 
          : null,
    );
  }

  factory PetProfileExtended.fromAnalysisResult(PetAnalysisResult result, String imagePath) {
     // Use full serialization as base to ensure all data is preserved for reconstruction
     Map<String, dynamic> rawAnalysis = result.toJson();

     // Inject UI Compatibility Keys (Adapters for EditPetForm specific widgets)
     rawAnalysis['caracteristicas_fisicas'] = {
         'expectativa_vida': result.identificacao.expectativaVidaMedia,
         'porte': result.identificacao.porteEstimado,
         'peso_estimado': 'Consultar curva de crescimento',
     };
     
     rawAnalysis['temperamento'] = {
         'personalidade': result.perfilComportamental.driveAncestral,
         'comportamento_social': 'Sociabilidade nota ${result.perfilComportamental.sociabilidadeGeral}/5',
         'nivel_energia': result.perfilComportamental.nivelEnergia,
     };
     
     // Ensure plano_semanal is accessible via alternative keys if needed (optional)

     String nivelAtiv = 'Moderado';
     if (result.perfilComportamental.nivelEnergia >= 4) nivelAtiv = 'Ativo';
     if (result.perfilComportamental.nivelEnergia <= 2) nivelAtiv = 'Sedentário';
     
     return PetProfileExtended(
         petName: result.petName ?? '',
         raca: result.identificacao.racaPredominante != 'N/A' ? result.identificacao.racaPredominante : null,
         nivelAtividade: nivelAtiv,
         rawAnalysis: rawAnalysis,
         imagePath: imagePath,
         lastUpdated: DateTime.now(),
         alergiasConhecidas: [],
         preferencias: [],
         frequenciaBanho: 'Quinzenal',
     );
  }

  Map<String, dynamic> toJson() {
    return {
      'pet_name': petName,
      if (raca != null) 'raca': raca,
      if (idadeExata != null) 'idade_exata': idadeExata,
      if (pesoAtual != null) 'peso_atual': pesoAtual,
      if (nivelAtividade != null) 'nivel_atividade': nivelAtividade,
      if (statusReprodutivo != null) 'status_reprodutivo': statusReprodutivo,
      'alergias_conhecidas': alergiasConhecidas,
      'preferencias': preferencias,
      if (dataUltimaV10 != null) 'data_ultima_v10': dataUltimaV10!.toIso8601String(),
      if (dataUltimaAntirrabica != null) 'data_ultima_antirrabica': dataUltimaAntirrabica!.toIso8601String(),
      if (frequenciaBanho != null) 'frequencia_banho': frequenciaBanho,
      'last_updated': lastUpdated.toIso8601String(),
      if (imagePath != null) 'image_path': imagePath,
      if (rawAnalysis != null) 'raw_analysis': rawAnalysis,
    };
  }

  /// Calculate ideal weight based on breed (simplified)
  double? getIdealWeight() {
    if (raca == null) return null;
    // TODO: Implement breed-specific ideal weight calculation
    return pesoAtual; // Placeholder
  }

  /// Check if weight change is significant (>10%)
  bool hasSignificantWeightChange(double? previousWeight) {
    if (pesoAtual == null || previousWeight == null) return false;
    final percentageChange = ((pesoAtual! - previousWeight) / previousWeight).abs();
    return percentageChange > 0.10;
  }

  /// Check if vaccine is overdue
  bool isVaccineOverdue(DateTime? lastDate, {int monthsValid = 12}) {
    if (lastDate == null) return true;
    final difference = DateTime.now().difference(lastDate).inDays;
    return difference > (monthsValid * 30);
  }

  PetProfileExtended copyWith({
    String? petName,
    String? raca,
    String? idadeExata,
    double? pesoAtual,
    String? nivelAtividade,
    String? statusReprodutivo,
    List<String>? alergiasConhecidas,
    List<String>? preferencias,
    DateTime? dataUltimaV10,
    DateTime? dataUltimaAntirrabica,
    String? frequenciaBanho,
    DateTime? lastUpdated,
    String? imagePath,
  }) {
    return PetProfileExtended(
      petName: petName ?? this.petName,
      raca: raca ?? this.raca,
      idadeExata: idadeExata ?? this.idadeExata,
      pesoAtual: pesoAtual ?? this.pesoAtual,
      nivelAtividade: nivelAtividade ?? this.nivelAtividade,
      statusReprodutivo: statusReprodutivo ?? this.statusReprodutivo,
      alergiasConhecidas: alergiasConhecidas ?? this.alergiasConhecidas,
      preferencias: preferencias ?? this.preferencias,
      dataUltimaV10: dataUltimaV10 ?? this.dataUltimaV10,
      dataUltimaAntirrabica: dataUltimaAntirrabica ?? this.dataUltimaAntirrabica,
      frequenciaBanho: frequenciaBanho ?? this.frequenciaBanho,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}

/// Response model for edit profile mode
class EditProfileResponse {
  final String mode;
  final String targetPet;
  final Map<String, dynamic> updatedData;
  final EditProfileTriggers triggers;
  final List<String> recommendations;
  final Map<String, dynamic> metadata;

  EditProfileResponse({
    required this.mode,
    required this.targetPet,
    required this.updatedData,
    required this.triggers,
    required this.recommendations,
    required this.metadata,
  });

  factory EditProfileResponse.fromJson(Map<String, dynamic> json) {
    return EditProfileResponse(
      mode: json['mode'] as String,
      targetPet: json['target_pet'] as String,
      updatedData: json['updated_data'] as Map<String, dynamic>,
      triggers: EditProfileTriggers.fromJson(json['triggers'] as Map<String, dynamic>),
      recommendations: (json['recommendations'] as List).cast<String>(),
      metadata: json['metadata'] as Map<String, dynamic>,
    );
  }
}

/// Triggers for intelligent recalculation
class EditProfileTriggers {
  final bool recalculateMenu;
  final bool regenerateAllergenTable;
  final bool scheduleVaccineAlert;

  EditProfileTriggers({
    required this.recalculateMenu,
    required this.regenerateAllergenTable,
    required this.scheduleVaccineAlert,
  });

  factory EditProfileTriggers.fromJson(Map<String, dynamic> json) {
    return EditProfileTriggers(
      recalculateMenu: json['recalculate_menu'] as bool? ?? false,
      regenerateAllergenTable: json['regenerate_allergen_table'] as bool? ?? false,
      scheduleVaccineAlert: json['schedule_vaccine_alert'] as bool? ?? false,
    );
  }
}
