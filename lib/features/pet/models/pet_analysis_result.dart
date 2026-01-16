import '../services/pet_fallback_service.dart';

class PetAnalysisResult {
  final IdentificacaoPet identificacao;
  final PerfilComportamental perfilComportamental;
  final NutricaoEStrutura nutricao;
  final Grooming higiene;
  final SaudePreventiva saude;
  final LifestyleEEducacao lifestyle;
  final DicaEspecialista dica;
  
  final String? petName;
  final String analysisType;
  final String? reliability; // Added Reliability

  // Diagnosis Specific Fields (Compatibility)
  final String? especieId; // Added for identification mode
  final String? especieDiag;
  final String? racaDiag;
  final String? caracteristicasDiag;
  final String? descricaoVisualDiag;
  final List<String>? possiveisCausasDiag;
  final String? urgenciaNivelDiag;
  final String? orientacaoImediataDiag;
  final Map<String, dynamic>? clinicalSignsDiag; // 🛡️ V139: Added for Deep Scan
  final Map<String, dynamic>? stoolAnalysis; // 🛡️ V231: Stool Analysis specialized data
  final String? category; // 🛡️ V460: Clinical Category Tag
  final Map<String, dynamic>? eyeDetails; // 🛡️ V460: Ocular specialist data
  final Map<String, dynamic>? dentalDetails; // 🛡️ V460: Dental specialist data
  final Map<String, dynamic>? skinDetails; // 🛡️ V460: Skin specialist data
  final Map<String, dynamic>? woundDetails; // 🛡️ V460: Wound specialist data

  final List<Map<String, String>> tabelaBenigna;
  final List<Map<String, String>> tabelaMaligna;
  final List<Map<String, String>> planoSemanal;
  final String? orientacoesGerais;
  final Map<String, dynamic>? protocoloImunizacao;
  final String? limitacoesAnalise;

  PetAnalysisResult({
    required this.identificacao,
    required this.perfilComportamental,
    required this.nutricao,
    required this.higiene,
    required this.saude,
    required this.lifestyle,
    required this.dica,
    this.petName,
    this.analysisType = 'identification',
    this.reliability, // Added
    this.especieId, // Added
    this.especieDiag,
    this.racaDiag,
    this.caracteristicasDiag,
    this.descricaoVisualDiag,
    this.possiveisCausasDiag,
    this.urgenciaNivelDiag,
    this.orientacaoImediataDiag,
    this.clinicalSignsDiag,
    this.stoolAnalysis, // 🛡️ V231
    this.category, // 🛡️ V460
    this.eyeDetails, // 🛡️ V460
    this.dentalDetails, // 🛡️ V460
    this.skinDetails, // 🛡️ V460
    this.woundDetails, // 🛡️ V460
    this.tabelaBenigna = const [],
    this.tabelaMaligna = const [],
    this.planoSemanal = const [],
    this.orientacoesGerais,
    this.protocoloImunizacao,
    this.limitacoesAnalise,
  });

  // Backward compatibility getters
  String get raca => analysisType == 'diagnosis' || analysisType == 'stool_analysis' ? (racaDiag ?? 'N/A') : identificacao.racaPredominante;
  String get especie => analysisType == 'diagnosis' || analysisType == 'stool_analysis' ? (especieDiag ?? 'Animal') : (especieId ?? "Animal");
  String get caracteristicas => analysisType == 'diagnosis' || analysisType == 'stool_analysis' ? (caracteristicasDiag ?? 'N/A') : identificacao.porteEstimado;
  String get descricaoVisual => analysisType == 'diagnosis' || analysisType == 'stool_analysis' ? (descricaoVisualDiag ?? 'N/A') : perfilComportamental.driveAncestral;
  String get urgenciaNivel => analysisType == 'diagnosis' || analysisType == 'stool_analysis' ? (urgenciaNivelDiag ?? 'Verde') : "Verde"; 
  String get orientacaoImediata => analysisType == 'diagnosis' || analysisType == 'stool_analysis' ? (orientacaoImediataDiag ?? 'Consulte um Vet.') : dica.insightExclusivo;
  List<String> get possiveisCausas => possiveisCausasDiag ?? [];

  factory PetAnalysisResult.fromJson(Map<String, dynamic> json) {
    List<Map<String, String>> parseTable(dynamic input) {
      if (input is List) {
        return input
            .where((e) => e is Map)
            .map((e) => Map<String, String>.from((e as Map).map((k, v) => MapEntry(k.toString(), v.toString()))))
            .toList();
      }
      return [];
    }

    // V490: Atomic Reliability Mapping
    String mapReliability(Map<String, dynamic> j) {
        final val = j['reliability'] ?? j['confiabilidade'] ?? j['score'] ?? j['confianca'];
        if (val == null) return 'N/A';
        if (val is num) {
           if (val <= 1.0) return '${(val * 100).toInt()}%';
           return '$val%';
        }
        final s = val.toString().replaceAll('%', '');
        final d = double.tryParse(s);
        if (d != null && d <= 1.0) return '${(d * 100).toInt()}%';
        return val.toString();
    }

    final reliabilityVal = mapReliability(json);

    // Check for Diagnosis Mode
    if (json['analysis_type'] == 'diagnosis' || json['analysis_type'] == 'stool_analysis' || json['urgency_level'] != null) {
      return PetAnalysisResult(
        analysisType: json['analysis_type'] ?? 'diagnosis',
        identificacao: IdentificacaoPet.empty(),
        perfilComportamental: PerfilComportamental.empty(),
        nutricao: NutricaoEStrutura.empty(),
        higiene: Grooming.empty(),
        saude: SaudePreventiva.empty(),
        lifestyle: LifestyleEEducacao.empty(),
        dica: DicaEspecialista.empty(),
        petName: json['pet_name'],
        especieDiag: json['species'] ?? 'Pet',
        racaDiag: json['breed'] ?? 'N/A',
        caracteristicasDiag: json['characteristics'] ?? 'N/A',
        descricaoVisualDiag: json['visual_description'] ?? 'N/A',
        possiveisCausasDiag: List<String>.from(json['possible_causes'] ?? []),
        clinicalSignsDiag: json['clinical_signs'] != null ? Map<String, dynamic>.from(json['clinical_signs']) : null, 
        stoolAnalysis: json['stool_details'] != null ? Map<String, dynamic>.from(json['stool_details']) : null, // 🛡️ V231
        category: json['category'], // 🛡️ V460
        eyeDetails: json['eye_details'] != null ? Map<String, dynamic>.from(json['eye_details']) : null, // 🛡️ V460
        dentalDetails: json['dental_details'] != null ? Map<String, dynamic>.from(json['dental_details']) : null, // 🛡️ V460
        skinDetails: json['skin_details'] != null ? Map<String, dynamic>.from(json['skin_details']) : null, // 🛡️ V460
        woundDetails: json['wound_details'] != null ? Map<String, dynamic>.from(json['wound_details']) : null, // 🛡️ V460
        urgenciaNivelDiag: json['urgency_level'] ?? 'Verde',
        orientacaoImediataDiag: json['immediate_care'] ?? 'Consulte um Vet.',
        tabelaBenigna: parseTable(json['tabela_benigna']),
        tabelaMaligna: parseTable(json['tabela_maligna']),
        planoSemanal: [],
        orientacoesGerais: null,
        reliability: reliabilityVal, // V490 Mapped
      );
    }

    // "Inference Master" Mapping
    final idMap = _safeMap(json['identification']);
    return PetAnalysisResult(
      analysisType: 'identification',
      identificacao: IdentificacaoPet.fromTotalInference(
        idMap,
        _safeMap(json['growth_curve'])
      ),
      perfilComportamental: PerfilComportamental.empty(),
      nutricao: NutricaoEStrutura.fromTotalInference(_safeMap(json['nutrition']), _safeMap(json['identification'])['size']?.toString() ?? 'Medium'),
      higiene: Grooming.fromTotalInference(_safeMap(json['grooming'])),
      saude: SaudePreventiva.fromTotalInference(_safeMap(json['health'])),
      lifestyle: LifestyleEEducacao.fromTotalInference(_safeMap(json['lifestyle'])),
      dica: DicaEspecialista.empty(),
      reliability: reliabilityVal, // V490 Mapped
      limitacoesAnalise: null,
      especieId: idMap['species']?.toString(), // Capture species from identification
      petName: json['pet_name'] ?? 'Pet',
      tabelaBenigna: [],
      tabelaMaligna: [],
      planoSemanal: [],
      orientacoesGerais: null,
      protocoloImunizacao: null,
    );
  }

  static Map<String, dynamic> _safeMap(dynamic input) {
    if (input is Map) {
      return Map<String, dynamic>.from(input);
    }
    return {};
  }
  
  Map<String, dynamic> toJson() => {
    'analysis_type': analysisType,
    'pet_name': petName,
    'species': especieDiag,
    'breed': racaDiag,
    'characteristics': caracteristicasDiag,
    'visual_description': descricaoVisualDiag,
    'possible_causes': possiveisCausasDiag,
    'urgency_level': urgenciaNivelDiag,
    'immediate_care': orientacaoImediataDiag,
    'clinical_signs': clinicalSignsDiag,
    'stool_details': stoolAnalysis,
    'category': category,
    'eye_details': eyeDetails,
    'dental_details': dentalDetails,
    'skin_details': skinDetails,
    'wound_details': woundDetails,
    'tabela_benigna': tabelaBenigna,
    'tabela_maligna': tabelaMaligna,
    'identification': identificacao.toJson(),
    'growth_curve': identificacao.curvaCrescimento,
    'nutrition': nutricao.toJson(),
    'grooming': higiene.toJson(),
    'health': saude.toJson(),
    'lifestyle': lifestyle.toJson(), // We need this
  };
}

class IdentificacaoPet {
  final String racaPredominante;
  final String linhagemSrdProvavel;
  final String porteEstimado;
  final String expectativaVidaMedia;
  final Map<String, dynamic> curvaCrescimento;

  IdentificacaoPet({
    required this.racaPredominante,
    required this.linhagemSrdProvavel,
    required this.porteEstimado,
    required this.expectativaVidaMedia,
    required this.curvaCrescimento,
    this.racaPredict = '',
    this.origemGeografica = '',
    this.morfologiaBase = '',
  });

  // New optional fields for detailed PDF
  final String racaPredict;
  final String origemGeografica;
  final String morfologiaBase;

  factory IdentificacaoPet.fromTotalInference(Map<String, dynamic> id, Map<String, dynamic> growth) {
    String size = id['size']?.toString() ?? 'Medium';
    Map<String, dynamic> fallbackGrowth = PetFallbackService.getGrowthCurve(size);

    final Map<String, dynamic> mappedGrowth = {};
    
    // Use fallback if AI value is null or N/A
    String? check(dynamic val, String key) {
       // Aggressive check: if null, N/A, empty, or "null" string
       if (val == null || 
           val.toString().toLowerCase().contains('n/a') || 
           val.toString().trim().isEmpty || 
           val.toString().toLowerCase() == 'null') {
         
         final fallbackValue = fallbackGrowth[key];
         return fallbackValue != null ? '$fallbackValue [ESTIMATED]' : 'Estimated [ESTIMATED]'; 
       }
       return val.toString();
    }

    mappedGrowth['peso_3_meses'] = check(growth['weight_3_months'], 'weight_3_months');
    mappedGrowth['peso_6_meses'] = check(growth['weight_6_months'], 'weight_6_months');
    mappedGrowth['peso_12_meses'] = check(growth['weight_12_months'], 'weight_12_months');
    mappedGrowth['peso_adulto'] = check(growth['adult_weight'], 'adult_weight');

    // V490: Atomic Identity Mapping - Redundant Key Checks
    String? getString(List<String> keys) {
       for (final k in keys) {
          if (id[k] != null && id[k].toString().isNotEmpty && id[k].toString().toLowerCase() != 'null') {
             return id[k].toString();
          }
       }
       return null;
    }

    final raca = getString(['breed_name', 'breed', 'raca', 'raça']) ?? 'Unknown Breed';
    final origem = getString(['origin_region', 'regiao_origem', 'region', 'pais_origem']) ?? '';
    final morfologia = getString(['morphology_type', 'tipo_morfologico', 'morfologia', 'morphology']) ?? '';
    final linhagem = getString(['lineage', 'linhagem', 'linhagem_provavel', 'ancestry']) ?? 'Pure/Standard';
    final life = getString(['lifespan', 'expectativa_vida', 'longevidade']) ?? '10-12 years';

    // Trace Logic for Deep Debugging
    // debugPrint('🔍 [ID_MAP] Raca: $raca | Origem: $origem | Morfo: $morfologia | Lin: $linhagem');

    return IdentificacaoPet(
      racaPredominante: raca,
      racaPredict: raca, 
      origemGeografica: origem, 
      morfologiaBase: morfologia, 
      linhagemSrdProvavel: linhagem,
      porteEstimado: size,
      expectativaVidaMedia: life,
      curvaCrescimento: mappedGrowth,
    );
  }
  
  factory IdentificacaoPet.fromJson(Map<String, dynamic> json) {
     // Robust fromJson handling 
     Map<String, dynamic> growth = {};
     if (json['curva_crescimento'] is Map) {
        growth = Map<String, dynamic>.from(json['curva_crescimento']);
     }
     
     // Recursively use redundancy check even for direct Json
     // Only if identifying via inference logic helper, but here we just map direct
     return IdentificacaoPet(
       racaPredominante: json['racaPredominante'] ?? json['breed'] ?? '',
       linhagemSrdProvavel: json['linhagemSrdProvavel'] ?? json['linhagem'] ?? '',
       porteEstimado: json['porteEstimado'] ?? json['size'] ?? '',
       expectativaVidaMedia: json['expectativaVidaMedia'] ?? '',
       curvaCrescimento: growth,
       racaPredict: json['racaPredict'] ?? '',
       origemGeografica: json['origemGeografica'] ?? json['origin_region'] ?? '',
       morfologiaBase: json['morfologiaBase'] ?? json['morphology_type'] ?? '',
     );
  }
  factory IdentificacaoPet.empty() => IdentificacaoPet(
    racaPredominante: '', 
    racaPredict: '',
    origemGeografica: '',
    morfologiaBase: '',
    linhagemSrdProvavel: '', 
    porteEstimado: '', 
    expectativaVidaMedia: '', 
    curvaCrescimento: {},
  );
  Map<String, dynamic> toJson() => {
    'breed_name': racaPredominante,
    'origin_region': origemGeografica,
    'morphology_type': morfologiaBase,
    'lineage': linhagemSrdProvavel,
    'size': porteEstimado,
    'lifespan': expectativaVidaMedia,
  };
}

class NutricaoEStrutura {
  final Map<String, String> metaCalorica;
  final List<String> nutrientesAlvo;
  // Legacy fields
  final List<String> suplementacaoSugerida;
  final Map<String, dynamic> segurancaAlimentar;

  NutricaoEStrutura({
    required this.metaCalorica,
    required this.nutrientesAlvo,
    required this.suplementacaoSugerida,
    required this.segurancaAlimentar,
  });

  factory NutricaoEStrutura.fromTotalInference(Map<String, dynamic> json, String size) {
    Map<String, String> meta = {};
    Map<String, String> fallback = PetFallbackService.getNutritionalTargets(size);

    String check(dynamic val, String key) {
       if (val == null || 
           val.toString().toLowerCase().contains('n/a') || 
           val.toString().trim().isEmpty || 
           val.toString().toLowerCase() == 'null') {
         final f = fallback[key];
         return f != null ? '$f [ESTIMATED]' : 'Estimated [ESTIMATED]';
       }
       return val.toString();
    }

    meta['kcal_filhote'] = check(json['kcal_puppy'], 'kcal_filhote');
    meta['kcal_adulto'] = check(json['kcal_adult'], 'kcal_adulto');
    meta['kcal_senior'] = check(json['kcal_senior'], 'kcal_senior');

    return NutricaoEStrutura(
      metaCalorica: meta,
      nutrientesAlvo: (json['target_nutrients'] as List? ?? []).map((e) => e.toString()).toList(),
      suplementacaoSugerida: [],
      segurancaAlimentar: {},
    );
  }
  
  factory NutricaoEStrutura.fromJson(Map<String, dynamic> json) => NutricaoEStrutura.empty();
  factory NutricaoEStrutura.fromSimplifiedJson(Map<String, dynamic> json) => NutricaoEStrutura.empty();
  factory NutricaoEStrutura.fromUnifiedJson(Map<String, dynamic> json) => NutricaoEStrutura.empty();
  factory NutricaoEStrutura.empty() => NutricaoEStrutura(metaCalorica: {}, nutrientesAlvo: [], suplementacaoSugerida: [], segurancaAlimentar: {});
  Map<String, dynamic> toJson() => {
      'kcal_puppy': metaCalorica['kcal_filhote'],
      'kcal_adult': metaCalorica['kcal_adulto'],
      'kcal_senior': metaCalorica['kcal_senior'],
      'target_nutrients': nutrientesAlvo,
  };
}

class Grooming {
  final Map<String, dynamic> manutencaoPelagem;
  final Map<String, dynamic> banhoEHigiene;

  Grooming({
    required this.manutencaoPelagem,
    required this.banhoEHigiene,
  });

  factory Grooming.fromTotalInference(Map<String, dynamic> json) {
    String type = json['coat_type']?.toString() ?? 'Normal';
    
    String check(dynamic val, String fallback) {
       if (val == null || 
           val.toString().toLowerCase().contains('n/a') || 
           val.toString().trim().isEmpty || 
           val.toString().toLowerCase() == 'null') {
         return fallback;
       }
       return val.toString();
    }

    String freq = check(json['grooming_frequency'], '${PetFallbackService.getGroomingFrequency(type)} [ESTIMATED]');

    return Grooming(
      manutencaoPelagem: {
        'tipo_pelo': type,
        'frequencia_escovacao_semanal': freq,
        'alerta_subpelo': json['grooming_alert'],
      },
      banhoEHigiene: {},
    );
  }
  
  factory Grooming.fromJson(Map<String, dynamic> json) => Grooming.empty();
  factory Grooming.fromUnifiedJson(Map<String, dynamic> a, Map<String, dynamic> b) => Grooming.empty();
  factory Grooming.empty() => Grooming(manutencaoPelagem: {}, banhoEHigiene: {});
  Map<String, dynamic> toJson() => {
     'coat_type': manutencaoPelagem['tipo_pelo'],
     'grooming_frequency': manutencaoPelagem['frequencia_escovacao_semanal'],
     'grooming_alert': manutencaoPelagem['alerta_subpelo'],
  };
}

class SaudePreventiva {
  final List<String> predisposicaoDoencas;
  final List<String> pontosCriticosAnatomicos;
  final Map<String, dynamic> checkupVeterinario;
  final Map<String, dynamic> sensibilidadeClimatica;
  
  SaudePreventiva({
    required this.predisposicaoDoencas, 
    required this.pontosCriticosAnatomicos,
    required this.checkupVeterinario,
    required this.sensibilidadeClimatica,
    this.predisposicoesGeneticas = '',
    this.sinaisAlertaPrecoce = '',
  });

  // Updated Fields for PDF
  final String predisposicoesGeneticas;
  final String sinaisAlertaPrecoce;
  
  factory SaudePreventiva.fromTotalInference(Map<String, dynamic> json) {
    List<String> predis = (json['predispositions'] as List? ?? []).map((e) => e.toString()).toList();
    if (predis.isEmpty || (predis.length == 1 && predis[0].contains('N/A'))) {
      predis = ['Consulte veterinário para predisposições específicas'];
    }

    return SaudePreventiva(
      predisposicaoDoencas: predis,
      pontosCriticosAnatomicos: [],
      checkupVeterinario: {
        'exames_obrigatorios_anuais': [json['preventive_checkup'] ?? 'Hemograma e Checkup Geral']
      },
      sensibilidadeClimatica: {},
      predisposicoesGeneticas: predis.join(", "), // 🚀 V125
      sinaisAlertaPrecoce: json['early_warning_signs']?.toString() ?? '', // 🚀 V125
    );
  }
  
  factory SaudePreventiva.empty() => SaudePreventiva(
    predisposicaoDoencas: [], 
    pontosCriticosAnatomicos: [],
    checkupVeterinario: {},
    sensibilidadeClimatica: {},
    predisposicoesGeneticas: '', // 🚀 V125
    sinaisAlertaPrecoce: '', // 🚀 V125
  );
  
  factory SaudePreventiva.fromJson(Map<String, dynamic> json) => SaudePreventiva.empty();
  factory SaudePreventiva.fromSimplifiedJson(Map<String, dynamic> json) => SaudePreventiva.empty();
  factory SaudePreventiva.fromUnifiedJson(Map<String, dynamic> json) => SaudePreventiva.empty();
  Map<String, dynamic> toJson() => {
      'predispositions': predisposicaoDoencas,
      'preventive_checkup': (checkupVeterinario['exames_obrigatorios_anuais'] is List && (checkupVeterinario['exames_obrigatorios_anuais'] as List).isNotEmpty) ? (checkupVeterinario['exames_obrigatorios_anuais'] as List).first : null,
  };
}

class LifestyleEEducacao {
  final Map<String, dynamic> treinamento;
  final Map<String, dynamic> ambienteIdeal;
  final Map<String, dynamic> estimuloMental;
  LifestyleEEducacao({required this.treinamento, required this.ambienteIdeal, required this.estimuloMental});
  
  factory LifestyleEEducacao.fromTotalInference(Map<String, dynamic> json) {
    return LifestyleEEducacao(
      treinamento: {
        'dificuldade_adestramento': json['training_intelligence'] ?? 'N/A',
        'metodos_recomendados': 'Reforço positivo'
      },
      ambienteIdeal: {
        'necessidade_de_espaco_aberto': json['environment_type'] ?? 'N/A',
        'adaptacao_apartamento_score': (json['environment_type']?.toString().toLowerCase().contains('apart') ?? false) ? 5 : 3
      },
      estimuloMental: {
        'necessidade_estimulo_mental': json['activity_level'] ?? 'N/A',
        'atividades_sugeridas': 'Brinquedos interativos e passeios'
      }
    );
  }

  factory LifestyleEEducacao.empty() => LifestyleEEducacao(treinamento: {}, ambienteIdeal: {}, estimuloMental: {});
  factory LifestyleEEducacao.fromJson(Map<String, dynamic> json) => LifestyleEEducacao.empty();
  factory LifestyleEEducacao.fromSimplifiedJson(Map<String, dynamic> json) => LifestyleEEducacao.empty();
  factory LifestyleEEducacao.fromUnifiedJson(Map<String, dynamic> json) => LifestyleEEducacao.empty();
  Map<String, dynamic> toJson() => {
      'training_intelligence': treinamento['dificuldade_adestramento'],
      'environment_type': ambienteIdeal['necessidade_de_espaco_aberto'],
      'activity_level': estimuloMental['necessidade_estimulo_mental'],
  };
}

class DicaEspecialista {
  final String insightExclusivo;
  DicaEspecialista({required this.insightExclusivo});
  factory DicaEspecialista.empty() => DicaEspecialista(insightExclusivo: '');
  factory DicaEspecialista.fromJson(Map<String, dynamic> json) => DicaEspecialista.empty();
  factory DicaEspecialista.fromSimplifiedJson(dynamic json) => DicaEspecialista.empty();
  factory DicaEspecialista.fromUnifiedJson(dynamic json) => DicaEspecialista.empty();
  Map<String, dynamic> toJson() => {};
}

class PerfilComportamental {
    final int nivelEnergia;
    final int nivelInteligencia;
    final String driveAncestral;
    final int sociabilidadeGeral;
    PerfilComportamental({required this.nivelEnergia, required this.nivelInteligencia, required this.driveAncestral, required this.sociabilidadeGeral});
    factory PerfilComportamental.empty() => PerfilComportamental(nivelEnergia: 0, nivelInteligencia: 0, driveAncestral: 'N/A', sociabilidadeGeral: 0);
    factory PerfilComportamental.fromTotalInference(Map<String, dynamic> json) => PerfilComportamental.empty();
    factory PerfilComportamental.fromJson(Map<String, dynamic> json) => PerfilComportamental.empty();
    Map<String, dynamic> toJson() => {};
}

int _toInt(dynamic value, int defaultValue) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}
