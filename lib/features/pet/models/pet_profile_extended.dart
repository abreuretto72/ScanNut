import 'pet_analysis_result.dart';
import 'analise_ferida_model.dart';
import 'analise_fezes_model.dart';
import '../../../core/utils/json_cast.dart';


/// Extended Pet Profile Model with bio-information
class PetProfileExtended {
  // Identidade Biológica
  final String petName;
  final String? especie;
  final String? raca;
  final String? idadeExata; // "2 anos 3 meses" ou "15 meses"
  final double? pesoAtual; // kg
  final double? pesoIdeal; // kg - Target Weight
  final String? nivelAtividade; // Sedentário, Moderado, Ativo
  final String? statusReprodutivo; // Castrado, Inteiro
  final String? sex; // Macho, Fêmea
  final String? porte; // Pequeno, Médio, Grande, Gigante
  final String? reliability; // % of AI confidence
  
  // Restrições Alimentares
  final List<String> alergiasConhecidas;
  final List<String> preferencias;
  final List<String> restricoes;
  
  // Configurações de Lifestyle
  final DateTime? dataUltimaV10;
  final DateTime? dataUltimaAntirrabica;
  final String? frequenciaBanho; // Semanal, Quinzenal, Mensal
  
  // Rede de Apoio
  final List<String> linkedPartnerIds;
  final Map<String, List<Map<String, dynamic>>> partnerNotes; // PartnerID -> List of notes {id, content, date}
  final List<Map<String, dynamic>> weightHistory; // [{date: iso, weight: 10.5, status: 'normal'}]
  final List<Map<String, dynamic>> labExams; // Lab exams with OCR and AI analysis
  final List<Map<String, dynamic>> woundAnalysisHistory; // Legacy: Wound/injury analysis history [{date, imagePath, diagnosis, severity, recommendations}]
  final List<AnaliseFeridaModel> historicoAnaliseFeridas; // 🛡️ V170: Structured Wound History
  final List<AnaliseFezesModel> historicoFezes; // 🛡️ V231: Stool Analysis History
  final List<Map<String, dynamic>> analysisHistory; // Completed AI Analysis Result History
  
  // Observações Cumulativas por Seção (com timestamps)
  final String observacoesIdentidade;
  final String observacoesSaude;
  final String observacoesNutricao;
  final String observacoesGaleria;
  final String observacoesPrac;
  
  // Metadata
  final DateTime lastUpdated;
  final String? imagePath;
  final Map<String, dynamic>? rawAnalysis; // Store complete analysis data

  PetProfileExtended({
    required this.petName,
    this.especie,
    this.raca,
    this.idadeExata,
    this.pesoAtual,
    this.pesoIdeal,
    this.nivelAtividade,
    this.statusReprodutivo,
    this.sex,
    this.alergiasConhecidas = const [],
    this.preferencias = const [],
    this.restricoes = const [],
    this.dataUltimaV10,
    this.dataUltimaAntirrabica,
    this.frequenciaBanho,
    this.linkedPartnerIds = const [],
    this.partnerNotes = const {},
    this.weightHistory = const [],
    this.labExams = const [],
    this.woundAnalysisHistory = const [],
    this.historicoAnaliseFeridas = const [],
    this.historicoFezes = const [],
    this.analysisHistory = const [],
    this.observacoesIdentidade = '',
    this.observacoesSaude = '',
    this.observacoesNutricao = '',
    this.observacoesGaleria = '',
    this.observacoesPrac = '',
    required this.lastUpdated,
    this.imagePath,
    this.rawAnalysis,
    this.reliability,
    this.porte,
  });

  factory PetProfileExtended.fromJson(Map<String, dynamic> json) {
    try {
      return PetProfileExtended(

      petName: (json['pet_name'] ?? json['name'] ?? '').toString(),
      especie: json['especie'] as String?,
      raca: json['raca'] as String?,
      idadeExata: json['idade_exata'] as String?,
      pesoAtual: (json['peso_atual'] as num?)?.toDouble(),
      pesoIdeal: (json['peso_ideal'] as num?)?.toDouble(),
      nivelAtividade: json['nivel_atividade'] as String?,
      statusReprodutivo: json['status_reprodutivo'] as String?,
      sex: json['sex'] as String?,
      porte: json['porte'] as String?,
      alergiasConhecidas: (json['alergias_conhecidas'] as List?)?.cast<String>() ?? [],
      preferencias: (json['preferencias'] as List?)?.cast<String>() ?? [],
      restricoes: (json['restricoes'] as List?)?.cast<String>() ?? [],
      dataUltimaV10: json['data_ultima_v10'] != null 
          ? DateTime.parse(json['data_ultima_v10'] as String)
          : null,
      dataUltimaAntirrabica: json['data_ultima_antirrabica'] != null
          ? DateTime.parse(json['data_ultima_antirrabica'] as String)
          : null,
      frequenciaBanho: json['frequencia_banho'] as String?,
      reliability: json['reliability'] as String?,
      linkedPartnerIds: (json['linked_partner_ids'] as List?)?.cast<String>() ?? [],
      partnerNotes: (json['partner_notes'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), deepCastMapList(v)),
          ) ?? {},
      weightHistory: deepCastMapList(json['weight_history']),
      labExams: deepCastMapList(json['lab_exams']),
      woundAnalysisHistory: deepCastMapList(json['wound_analysis_history']),
      historicoAnaliseFeridas: (json['historico_analise_feridas'] as List?)
          ?.map((e) => AnaliseFeridaModel.fromJson(Map<String, dynamic>.from(e)))
          .toList() ?? [],
      historicoFezes: (json['historico_fezes'] as List?)
          ?.map((e) => AnaliseFezesModel.fromJson(Map<String, dynamic>.from(e)))
          .toList() ?? [],
      analysisHistory: deepCastMapList(json['analysis_history']),

      observacoesIdentidade: (json['observacoes_identidade'] ?? '') as String,
      observacoesSaude: (json['observacoes_saude'] ?? '') as String,
      observacoesNutricao: (json['observacoes_nutricao'] ?? '') as String,
      observacoesGaleria: (json['observacoes_galeria'] ?? '') as String,
      observacoesPrac: (json['observacoes_prac'] ?? '') as String,
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : DateTime.now(),
      imagePath: (json['image_path'] ?? json['photo_path']) as String?,
      rawAnalysis: _extractRawAnalysis(json),
    );
    } catch (e) {
      throw Exception('PET_PROFILE_PARSE_ERROR: $e');
    }
  }


  static Map<String, dynamic>? _extractRawAnalysis(Map<String, dynamic> json) {
    final Map<String, dynamic>? base = json['raw_analysis'] != null 
          ? deepCastMap(json['raw_analysis']) 
          : null;

    
    // Capture AI-generated fields that might be at the top level due to saveWeeklyMenu
    final List<String> aiKeys = [
      'plano_semanal', 
      'orientacoes_gerais', 
      'data_inicio_semana', 
      'data_fim_semana',
      'last_meal_plan_gen'
    ];

    Map<String, dynamic>? result = base;
    
    for (var key in aiKeys) {
      if (json.containsKey(key) && json[key] != null) {
        result ??= {};
        result[key] = json[key];
      }
    }
    
    return result;
  }

  factory PetProfileExtended.fromHiveEntry(Map<String, dynamic> entry) {
    final rawData = entry['data'] != null 
        ? deepCastMap(entry['data']) 
        : deepCastMap(entry);

    
    // Ensure petName consistency
    if (rawData['pet_name'] == null && entry['pet_name'] != null) {
      rawData['pet_name'] = entry['pet_name'];
    }
    
    // Map photo_path from wrapper to image_path if missing
    if (rawData['image_path'] == null && entry['photo_path'] != null) {
      rawData['image_path'] = entry['photo_path'];
    }
    
    return PetProfileExtended.fromJson(rawData);
  }

  factory PetProfileExtended.fromAnalysisResult(PetAnalysisResult result, String imagePath) {
     // Use full serialization as base to ensure all data is preserved for reconstruction
     Map<String, dynamic> rawAnalysis = result.toJson();
     rawAnalysis['last_updated'] = DateTime.now().toIso8601String(); // Fix: Add timestamp

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
         especie: _normalizeSpecies(result.especie),
         raca: _formatBreedWithLineage(result),
         reliability: result.reliability,
         nivelAtividade: nivelAtiv,
         rawAnalysis: rawAnalysis,
         imagePath: imagePath,
          lastUpdated: DateTime.now(),
          alergiasConhecidas: [],
          preferencias: [],
          restricoes: [],
          frequenciaBanho: 'Quinzenal',
         linkedPartnerIds: [],
         partnerNotes: {},
         weightHistory: [],
         labExams: [],
         woundAnalysisHistory: [],
         historicoAnaliseFeridas: [],
         historicoFezes: [],
          analysisHistory: [rawAnalysis],
          porte: result.identificacao.porteEstimado,
     );
  }

  Map<String, dynamic> toJson() {
    return {
      'pet_name': petName,
      if (especie != null) 'especie': especie,
      if (raca != null) 'raca': raca,
      if (idadeExata != null) 'idade_exata': idadeExata,
      if (pesoAtual != null) 'peso_atual': pesoAtual,
      if (pesoIdeal != null) 'peso_ideal': pesoIdeal,
      if (nivelAtividade != null) 'nivel_atividade': nivelAtividade,
      if (statusReprodutivo != null) 'status_reprodutivo': statusReprodutivo,
      if (sex != null) 'sex': sex,
      if (porte != null) 'porte': porte,
      'alergias_conhecidas': alergiasConhecidas,
      'preferencias': preferencias,
      'restricoes': restricoes,
      if (dataUltimaV10 != null) 'data_ultima_v10': dataUltimaV10!.toIso8601String(),
      if (dataUltimaAntirrabica != null) 'data_ultima_antirrabica': dataUltimaAntirrabica!.toIso8601String(),
      if (frequenciaBanho != null) 'frequencia_banho': frequenciaBanho,
      if (reliability != null) 'reliability': reliability,
      'linked_partner_ids': linkedPartnerIds,
      'partner_notes': partnerNotes,
      'weight_history': weightHistory,
      'lab_exams': labExams,
      'wound_analysis_history': woundAnalysisHistory,
      'historico_analise_feridas': historicoAnaliseFeridas.map((e) => e.toJson()).toList(),
      'historico_fezes': historicoFezes.map((e) => e.toJson()).toList(),
      'analysis_history': analysisHistory,
      'observacoes_identidade': observacoesIdentidade,
      'observacoes_saude': observacoesSaude,
      'observacoes_nutricao': observacoesNutricao,
      'observacoes_galeria': observacoesGaleria,
      'observacoes_prac': observacoesPrac,
      'last_updated': lastUpdated.toIso8601String(),
      if (imagePath != null) 'image_path': imagePath,
      if (rawAnalysis != null) ...{
        'raw_analysis': rawAnalysis,
        // Spread AI fields to top level for compatibility with services/UI looking there
        if (rawAnalysis!.containsKey('plano_semanal')) 'plano_semanal': rawAnalysis!['plano_semanal'],
        if (rawAnalysis!.containsKey('orientacoes_gerais')) 'orientacoes_gerais': rawAnalysis!['orientacoes_gerais'],
        if (rawAnalysis!.containsKey('data_inicio_semana')) 'data_inicio_semana': rawAnalysis!['data_inicio_semana'],
        if (rawAnalysis!.containsKey('data_fim_semana')) 'data_fim_semana': rawAnalysis!['data_fim_semana'],
      },
    };
  }

  /// Calculate ideal weight based on breed (simplified)
  double? getIdealWeight() {
    if (pesoIdeal != null) return pesoIdeal;
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
    String? especie,
    String? raca,
    String? idadeExata,
    double? pesoAtual,
    double? pesoIdeal,
    String? nivelAtividade,
    String? statusReprodutivo,
    String? sex,
    List<String>? alergiasConhecidas,
    List<String>? preferencias,
    List<String>? restricoes,
    DateTime? dataUltimaV10,
    DateTime? dataUltimaAntirrabica,
    String? frequenciaBanho,
    List<String>? linkedPartnerIds,
    Map<String, List<Map<String, dynamic>>>? partnerNotes,
    List<Map<String, dynamic>>? weightHistory,
    List<Map<String, dynamic>>? labExams,
    List<Map<String, dynamic>>? woundAnalysisHistory,
    List<AnaliseFeridaModel>? historicoAnaliseFeridas,
    List<AnaliseFezesModel>? historicoFezes,
    List<Map<String, dynamic>>? analysisHistory, // New
    String? observacoesIdentidade,
    String? observacoesSaude,
    String? observacoesNutricao,
    String? observacoesGaleria,
    String? observacoesPrac,
    DateTime? lastUpdated,
    String? imagePath,
    Map<String, dynamic>? rawAnalysis,
    String? reliability,
    String? porte,
  }) {
    return PetProfileExtended(
      petName: petName ?? this.petName,
      especie: especie ?? this.especie,
      raca: raca ?? this.raca,
      idadeExata: idadeExata ?? this.idadeExata,
      pesoAtual: pesoAtual ?? this.pesoAtual,
      pesoIdeal: pesoIdeal ?? this.pesoIdeal,
      nivelAtividade: nivelAtividade ?? this.nivelAtividade,
      statusReprodutivo: statusReprodutivo ?? this.statusReprodutivo,
      sex: sex ?? this.sex,
      alergiasConhecidas: alergiasConhecidas ?? this.alergiasConhecidas,
      preferencias: preferencias ?? this.preferencias,
      restricoes: restricoes ?? this.restricoes,
      dataUltimaV10: dataUltimaV10 ?? this.dataUltimaV10,
      dataUltimaAntirrabica: dataUltimaAntirrabica ?? this.dataUltimaAntirrabica,
      frequenciaBanho: frequenciaBanho ?? this.frequenciaBanho,
      linkedPartnerIds: linkedPartnerIds ?? this.linkedPartnerIds,
      partnerNotes: partnerNotes ?? this.partnerNotes,
      weightHistory: weightHistory ?? this.weightHistory,
      labExams: labExams ?? this.labExams,
      woundAnalysisHistory: woundAnalysisHistory ?? this.woundAnalysisHistory,
      historicoAnaliseFeridas: historicoAnaliseFeridas ?? this.historicoAnaliseFeridas,
      historicoFezes: historicoFezes ?? this.historicoFezes,
      analysisHistory: analysisHistory ?? this.analysisHistory, // New
      observacoesIdentidade: observacoesIdentidade ?? this.observacoesIdentidade,
      observacoesSaude: observacoesSaude ?? this.observacoesSaude,
      observacoesNutricao: observacoesNutricao ?? this.observacoesNutricao,
      observacoesGaleria: observacoesGaleria ?? this.observacoesGaleria,
      observacoesPrac: observacoesPrac ?? this.observacoesPrac,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      imagePath: imagePath ?? this.imagePath,
      rawAnalysis: rawAnalysis ?? this.rawAnalysis,
      reliability: reliability ?? this.reliability,
      porte: porte ?? this.porte,
    );
  }
  static String? _normalizeSpecies(String? raw) {
      if (raw == null) return null;
      final s = raw.toUpperCase();
      if (s.contains('CÃO') || s.contains('CAO') || s.contains('DOG') || s.contains('CACHORRO') || s.contains('CANIN')) {
          return 'Cão'; // Standard internal/localized key for Radio
      }
      if (s.contains('GATO') || s.contains('CAT') || s.contains('FELIN')) {
          return 'Gato'; // Standard internal/localized key for Radio
      }
      return raw;
  }

  static String _formatBreedWithLineage(PetAnalysisResult result) {
      final breed = normalizeBreed(result.identificacao.racaPredominante, result.especie);
      final lineage = result.identificacao.linhagemSrdProvavel;
      
      if (lineage != null && 
          lineage.isNotEmpty && 
          lineage.toUpperCase() != 'N/A' && 
          lineage.toUpperCase() != 'NULL' &&
          lineage != breed) {
          return '$breed ($lineage)';
      }
      return breed ?? 'SRD';
  }

  static String? normalizeBreed(String? raw, String? species) {
      if (raw == null) return null;
      var processed = raw.trim();
      final invalidValues = [
        'N/A', 'NA', 'N/A.', 'UNKNOWN', 'DESCONHECIDO', 
        'DESCONHECIDA', 'NÃO IDENTIFICADO', 'NÃO IDENTIFICADA',
        'RAÇA NÃO IDENTIFICADA', 'NULL'
      ];
      if (processed.isEmpty || invalidValues.contains(processed.toUpperCase())) {
          if (species != null) {
              final s = species.toUpperCase();
              if (s.contains('CÃO') || s.contains('CAO') || s.contains('DOG') || s.contains('CACHORRO')) {
                  return 'Sem Raça Definida (SRD)';
              }
              if (s.contains('GATO') || s.contains('CAT') || s.contains('FELINO')) {
                  return 'Sem Raça Definida (SRD)';
              }
          }
          return null;
      }
      if (!processed.contains(' ')) {
          return processed.toLowerCase();
      }
      return processed; 
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
