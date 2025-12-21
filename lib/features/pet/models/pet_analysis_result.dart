class PetAnalysisResult {
  final IdentificacaoPet identificacao;
  final PerfilComportamental perfilComportamental;
  final NutricaoEStrutura nutricao;
  final Grooming higiene; // Fixed typo
  final SaudePreventiva saude;
  final LifestyleEEducacao lifestyle;
  final DicaEspecialista dica;
  final String? petName;
  final String analysisType;

  // Diagnosis Specific Fields (Compatibility)
  final String? especieDiag;
  final String? racaDiag;
  final String? caracteristicasDiag;
  final String? descricaoVisualDiag;
  final List<String>? possiveisCausasDiag;
  final String? urgenciaNivelDiag;
  final String? orientacaoImediataDiag;

  // New Nutrition Tables
  final List<Map<String, String>> tabelaBenigna;
  final List<Map<String, String>> tabelaMaligna;
  
  // Weekly Meal Planner
  final List<Map<String, String>> planoSemanal;
  final String? orientacoesGerais;
  
  // Vaccination Protocol
  final Map<String, dynamic>? protocoloImunizacao;

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
    this.especieDiag,
    this.racaDiag,
    this.caracteristicasDiag,
    this.descricaoVisualDiag,
    this.possiveisCausasDiag,
    this.urgenciaNivelDiag,
    this.orientacaoImediataDiag,
    this.tabelaBenigna = const [],
    this.tabelaMaligna = const [],
    this.planoSemanal = const [],
    this.orientacoesGerais,
    this.protocoloImunizacao,
  });

  // Backward compatibility getters
  String get raca => analysisType == 'diagnosis' ? (racaDiag ?? 'N/A') : identificacao.racaPredominante;
  String get especie => analysisType == 'diagnosis' ? (especieDiag ?? 'Animal') : "Animal";
  String get caracteristicas => analysisType == 'diagnosis' ? (caracteristicasDiag ?? 'N/A') : identificacao.porteEstimado;
  String get descricaoVisual => analysisType == 'diagnosis' ? (descricaoVisualDiag ?? 'N/A') : perfilComportamental.driveAncestral;
  String get urgenciaNivel => analysisType == 'diagnosis' ? (urgenciaNivelDiag ?? 'Verde') : "Verde"; 
  String get orientacaoImediata => analysisType == 'diagnosis' ? (orientacaoImediataDiag ?? 'Consulte um Vet.') : dica.insightExclusivo;
  List<String> get possiveisCausas => possiveisCausasDiag ?? [];

  factory PetAnalysisResult.fromJson(Map<String, dynamic> json) {
    List<Map<String, String>> parseTable(dynamic input) {
      if (input is List) {
        return input.map((e) => Map<String, String>.from(e.map((k, v) => MapEntry(k.toString(), v.toString())))).toList();
      }
      return [];
    }

    if (json['analysis_type'] == 'diagnosis' || json['urgency_level'] != null) {
      return PetAnalysisResult(
        analysisType: 'diagnosis',
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
        urgenciaNivelDiag: json['urgency_level'] ?? 'Verde',
        orientacaoImediataDiag: json['immediate_care'] ?? 'Consulte um Vet.',
        tabelaBenigna: parseTable(json['tabela_benigna']),
        tabelaMaligna: parseTable(json['tabela_maligna']),
        planoSemanal: [],
        orientacoesGerais: null,
      );
    }

    return PetAnalysisResult(
      analysisType: 'identification',
      identificacao: IdentificacaoPet.fromJson(json['identificacao'] ?? {}),
      perfilComportamental: PerfilComportamental.fromJson(json['perfil_comportamental'] ?? {}),
      nutricao: NutricaoEStrutura.fromJson(json['nutricao_e_dieta_estrategica'] ?? {}),
      higiene: Grooming.fromJson(json['grooming'] ?? {}),
      saude: SaudePreventiva.fromJson(json['saude_preventiva'] ?? {}),
      lifestyle: LifestyleEEducacao.fromJson(json['lifestyle_e_educacao'] ?? {}),
      dica: DicaEspecialista.fromJson(json['dica_do_especialista'] ?? {}),
      petName: json['pet_name'],
      tabelaBenigna: parseTable(json['tabela_benigna']),
      tabelaMaligna: parseTable(json['tabela_maligna']),
      planoSemanal: parseTable(json['plano_semanal']),
      orientacoesGerais: json['orientacoes_gerais'],
      protocoloImunizacao: json['protocolo_imunizacao'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'identificacao': identificacao.toJson(),
      'perfil_comportamental': perfilComportamental.toJson(),
      'nutricao_e_dieta_estrategica': nutricao.toJson(),
      'grooming': higiene.toJson(),
      'saude_preventiva': saude.toJson(),
      'lifestyle_e_educacao': lifestyle.toJson(),
      'dica_do_especialista': dica.toJson(),
      'pet_name': petName,
      'analysis_type': analysisType,
      'species': especieDiag,
      'breed': racaDiag,
      'characteristics': caracteristicasDiag,
      'visual_description': descricaoVisualDiag,
      'possible_causes': possiveisCausasDiag,
      'urgency_level': urgenciaNivelDiag,
      'immediate_care': orientacaoImediataDiag,
      'tabela_benigna': tabelaBenigna,
      'tabela_maligna': tabelaMaligna,
      'plano_semanal': planoSemanal,
      'orientacoes_gerais': orientacoesGerais,
      'protocolo_imunizacao': protocoloImunizacao,
    };
  }
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
  });

  factory IdentificacaoPet.fromJson(Map<String, dynamic> json) {
    return IdentificacaoPet(
      racaPredominante: json['raca_predominante']?.toString() ?? 'N/A',
      linhagemSrdProvavel: json['linhagem_srd_provavel']?.toString() ?? 'N/A',
      porteEstimado: json['porte_estimado']?.toString() ?? 'Médio',
      expectativaVidaMedia: json['expectativa_vida_media']?.toString() ?? 'N/A',
      curvaCrescimento: Map<String, dynamic>.from(json['curva_crescimento'] ?? {}),
    );
  }

  factory IdentificacaoPet.empty() => IdentificacaoPet(racaPredominante: 'N/A', linhagemSrdProvavel: 'N/A', porteEstimado: 'N/A', expectativaVidaMedia: 'N/A', curvaCrescimento: {});

  Map<String, dynamic> toJson() => {
    'raca_predominante': racaPredominante,
    'linhagem_srd_provavel': linhagemSrdProvavel,
    'porte_estimado': porteEstimado,
    'expectativa_vida_media': expectativaVidaMedia,
    'curva_crescimento': curvaCrescimento,
  };
}

class PerfilComportamental {
  final int nivelEnergia;
  final int nivelInteligencia;
  final String driveAncestral;
  final int sociabilidadeGeral;

  PerfilComportamental({
    required this.nivelEnergia,
    required this.nivelInteligencia,
    required this.driveAncestral,
    required this.sociabilidadeGeral,
  });

  factory PerfilComportamental.fromJson(Map<String, dynamic> json) {
    return PerfilComportamental(
      nivelEnergia: _toInt(json['nivel_energia'], 3),
      nivelInteligencia: _toInt(json['nivel_inteligencia'], 3),
      driveAncestral: json['drive_ancestral']?.toString() ?? 'Companhia',
      sociabilidadeGeral: _toInt(json['sociabilidade_geral'], 3),
    );
  }

  factory PerfilComportamental.empty() => PerfilComportamental(nivelEnergia: 0, nivelInteligencia: 0, driveAncestral: 'N/A', sociabilidadeGeral: 0);

  Map<String, dynamic> toJson() => {
    'nivel_energia': nivelEnergia,
    'nivel_inteligencia': nivelInteligencia,
    'drive_ancestral': driveAncestral,
    'sociabilidade_geral': sociabilidadeGeral,
  };
}

class NutricaoEStrutura {
  final Map<String, String> metaCalorica;
  final List<String> nutrientesAlvo;
  final List<String> suplementacaoSugerida;
  final Map<String, dynamic> segurancaAlimentar;

  NutricaoEStrutura({
    required this.metaCalorica,
    required this.nutrientesAlvo,
    required this.suplementacaoSugerida,
    required this.segurancaAlimentar,
  });

  factory NutricaoEStrutura.fromJson(Map<String, dynamic> json) {
    return NutricaoEStrutura(
      metaCalorica: Map<String, String>.from(json['meta_calorica'] ?? {}),
      nutrientesAlvo: (json['nutrientes_alvo'] as List? ?? []).map((e) => e.toString()).toList(),
      suplementacaoSugerida: (json['suplementacao_sugerida'] as List? ?? []).map((e) => e.toString()).toList(),
      segurancaAlimentar: Map<String, dynamic>.from(json['seguranca_alimentar'] ?? {}),
    );
  }

  factory NutricaoEStrutura.empty() => NutricaoEStrutura(metaCalorica: {}, nutrientesAlvo: [], suplementacaoSugerida: [], segurancaAlimentar: {});

  Map<String, dynamic> toJson() => {
    'meta_calorica': metaCalorica,
    'nutrientes_alvo': nutrientesAlvo,
    'suplementacao_sugerida': suplementacaoSugerida,
    'seguranca_alimentar': segurancaAlimentar,
  };
}

class Grooming {
  final Map<String, dynamic> manutencaoPelagem;
  final Map<String, dynamic> banhoEHigiene;

  Grooming({
    required this.manutencaoPelagem,
    required this.banhoEHigiene,
  });

  factory Grooming.fromJson(Map<String, dynamic> json) {
    return Grooming(
      manutencaoPelagem: Map<String, dynamic>.from(json['manutencao_pelagem'] ?? {}),
      banhoEHigiene: Map<String, dynamic>.from(json['banho_e_higiene'] ?? {}),
    );
  }

  factory Grooming.empty() => Grooming(manutencaoPelagem: {}, banhoEHigiene: {});

  Map<String, dynamic> toJson() => {
    'manutencao_pelagem': manutencaoPelagem,
    'banho_e_higiene': banhoEHigiene,
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
  });

  factory SaudePreventiva.fromJson(Map<String, dynamic> json) {
    return SaudePreventiva(
      predisposicaoDoencas: (json['predisposicao_doencas'] as List? ?? []).map((e) => e.toString()).toList(),
      pontosCriticosAnatomicos: (json['pontos_criticos_anatomicos'] as List? ?? []).map((e) => e.toString()).toList(),
      checkupVeterinario: Map<String, dynamic>.from(json['checkup_veterinario'] ?? {}),
      sensibilidadeClimatica: Map<String, dynamic>.from(json['sensibilidade_climatica'] ?? {}),
    );
  }

  factory SaudePreventiva.empty() => SaudePreventiva(predisposicaoDoencas: [], pontosCriticosAnatomicos: [], checkupVeterinario: {}, sensibilidadeClimatica: {});

  Map<String, dynamic> toJson() => {
    'predisposicao_doencas': predisposicaoDoencas,
    'pontos_criticos_anatomicos': pontosCriticosAnatomicos,
    'checkup_veterinario': checkupVeterinario,
    'sensibilidade_climatica': sensibilidadeClimatica,
  };
}

class LifestyleEEducacao {
  final Map<String, dynamic> treinamento;
  final Map<String, dynamic> ambienteIdeal;
  final Map<String, dynamic> estimuloMental;

  LifestyleEEducacao({
    required this.treinamento,
    required this.ambienteIdeal,
    required this.estimuloMental,
  });

  factory LifestyleEEducacao.fromJson(Map<String, dynamic> json) {
    return LifestyleEEducacao(
      treinamento: Map<String, dynamic>.from(json['treinamento'] ?? {}),
      ambienteIdeal: Map<String, dynamic>.from(json['ambiente_ideal'] ?? {}),
      estimuloMental: Map<String, dynamic>.from(json['estimulo_mental'] ?? {}),
    );
  }

  factory LifestyleEEducacao.empty() => LifestyleEEducacao(treinamento: {}, ambienteIdeal: {}, estimuloMental: {});

  Map<String, dynamic> toJson() => {
    'treinamento': treinamento,
    'ambiente_ideal': ambienteIdeal,
    'estimulo_mental': estimuloMental,
  };
}

class DicaEspecialista {
  final String insightExclusivo;

  DicaEspecialista({required this.insightExclusivo});

  factory DicaEspecialista.fromJson(Map<String, dynamic> json) {
    return DicaEspecialista(insightExclusivo: json['insight_exclusivo']?.toString() ?? '');
  }

  factory DicaEspecialista.empty() => DicaEspecialista(insightExclusivo: '');

  Map<String, dynamic> toJson() => {'insight_exclusivo': insightExclusivo};
}

int _toInt(dynamic value, int defaultValue) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}
