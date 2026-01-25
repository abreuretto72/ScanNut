class PlantAnalysisModel {
  final Identificacao identificacao;
  final EsteticaViva estetica;
  final DiagnosticoSaude saude;
  final GuiaSobrevivencia sobrevivencia;
  final SegurancaEBiofilia segurancaBiofilia;
  final EngenhariaPropagacao propagacao;
  final InteligenciaEcossistema ecossistema;
  final LifestyleEFengShui lifestyle;
  final AlertasSazonais alertasSazonais;

  PlantAnalysisModel({
    required this.identificacao,
    required this.estetica,
    required this.saude,
    required this.sobrevivencia,
    required this.segurancaBiofilia,
    required this.propagacao,
    required this.ecossistema,
    required this.lifestyle,
    required this.alertasSazonais,
  });

  // Backward compatibility getters for existing UI
  String get plantName => identificacao.nomesPopulares.isNotEmpty
      ? identificacao.nomesPopulares.first
      : identificacao.nomeCientifico;
  String get condition => saude.condicao;
  String get diagnosis => saude.detalhes;
  String get organicTreatment => saude.planoRecuperacao;
  String get urgency => saude.urgencia;

  bool get isHealthy =>
      saude.condicao.toLowerCase().contains('saudável') ||
      saude.condicao.toLowerCase().contains('healthy');

  Map<String, dynamic> toJson() {
    return {
      'identification': identificacao.toJson(),
      'living_aesthetics': estetica.toJson(),
      'health_analysis': saude.toJson(),
      'survival_guide': sobrevivencia.toJson(),
      'safety_and_biofillia': segurancaBiofilia.toJson(),
      'propagation_engineering': propagacao.toJson(),
      'ecosystem_intelligence': ecossistema.toJson(),
      'lifestyle_and_feng_shui': lifestyle.toJson(),
      'seasonal_alerts': alertasSazonais.toJson(),
    };
  }

  static String _translateFallback(dynamic value) {
    if (value == null) return 'N/A';
    String text = value.toString();

    // Simple mapper for common technical terms leaked from Portuguese
    final Map<String, String> mapper = {
      'Rega': 'Watering',
      'Regar': 'Watering',
      'Luz direta': 'Direct Light',
      'Luz Indireta': 'Indirect Light',
      'Meia sombra': 'Partial Shade',
      'Sombra': 'Shade',
      'Sol Pleno': 'Full Sun',
      'Saudável': 'Healthy',
      'Doente': 'Sick',
      'Pragas': 'Pests',
      'Deficiência Nutricional': 'Nutrient Deficiency',
      'Baixa': 'low',
      'Média': 'medium',
      'Alta': 'high',
      'Oídio': 'Powdery Mildew',
      'Oidio': 'Powdery Mildew',
      'Manchas': 'Spots',
      'Mancha': 'Spot',
      'Cochonilha': 'Mealybugs',
      'Cochonilhas': 'Mealybugs',
      'Pulgão': 'Aphids',
      'Pulgões': 'Aphids',
      'Tripes': 'Thrips',
      'Ácaro': 'Spider Mites',
      'Ácaros': 'Spider Mites',
      'Fungo': 'Fungus',
      'Fungos': 'Fungus',
      'Podridão': 'Rot',
      'Podridão Radicular': 'Root Rot',
      'Folhas amarelas': 'Yellow leaves',
      'Folhas secas': 'Dry leaves',
      'Queimadura': 'Burn',
    };

    if (mapper.containsKey(text)) {
      return mapper[text] ?? text;
    }
    return text;
  }

  factory PlantAnalysisModel.fromJson(Map<dynamic, dynamic> json) {
    return PlantAnalysisModel(
      identificacao: Identificacao.fromJson(Map<dynamic, dynamic>.from(
          json['identification'] ?? json['identificacao'] ?? {})),
      estetica: EsteticaViva.fromJson(Map<dynamic, dynamic>.from(
          json['care_instructions']?['living_aesthetics'] ??
              json['living_aesthetics'] ??
              json['estetica_viva'] ??
              {})),
      saude: DiagnosticoSaude.fromJson(Map<dynamic, dynamic>.from(
          json['health_analysis'] ?? json['diagnostico_saude'] ?? {})),
      sobrevivencia: GuiaSobrevivencia.fromJson(Map<dynamic, dynamic>.from(
          json['care_instructions'] ??
              json['survival_guide'] ??
              json['guia_sobrevivencia'] ??
              {})),
      segurancaBiofilia: SegurancaEBiofilia.fromJson(Map<dynamic, dynamic>.from(
          json['safety_and_biofillia'] ?? json['seguranca_e_biofilia'] ?? {})),
      propagacao: EngenhariaPropagacao.fromJson(Map<dynamic, dynamic>.from(
          json['propagation_engineering'] ??
              json['engenharia_propagacao'] ??
              {})),
      ecossistema: InteligenciaEcossistema.fromJson(Map<dynamic, dynamic>.from(
          json['care_instructions']?['ecosystem_intelligence'] ??
              json['ecosystem_intelligence'] ??
              json['inteligencia_ecossistema'] ??
              {})),
      lifestyle: LifestyleEFengShui.fromJson(Map<dynamic, dynamic>.from(
          json['care_instructions']?['lifestyle_and_feng_shui'] ??
              json['lifestyle_and_feng_shui'] ??
              json['lifestyle_e_feng_shui'] ??
              {})),
      alertasSazonais: AlertasSazonais.fromJson(Map<dynamic, dynamic>.from(
          json['seasonal_alerts'] ?? json['alertas_sazonais'] ?? {})),
    );
  }
}

class Identificacao {
  final String nomeCientifico;
  final List<String> nomesPopulares;
  final String familia;
  final String origemGeografica;

  Identificacao({
    required this.nomeCientifico,
    required this.nomesPopulares,
    required this.familia,
    required this.origemGeografica,
  });

  Map<String, dynamic> toJson() => {
        'scientific_name': nomeCientifico,
        'common_name': nomesPopulares.isNotEmpty ? nomesPopulares.first : 'N/A',
        'common_names': nomesPopulares,
        'family': familia,
        'origin': origemGeografica,
      };

  factory Identificacao.fromJson(Map<dynamic, dynamic> json) {
    List<String> pops = [];
    if (json['common_names'] != null) {
      pops = (json['common_names'] as List).map((e) => e.toString()).toList();
    } else if (json['nomes_populares'] != null) {
      pops =
          (json['nomes_populares'] as List).map((e) => e.toString()).toList();
    } else if (json['common_name'] != null) {
      pops = [json['common_name'].toString()];
    }

    return Identificacao(
      nomeCientifico: json['scientific_name']?.toString() ??
          json['nome_cientifico']?.toString() ??
          'N/A',
      nomesPopulares: pops,
      familia:
          json['family']?.toString() ?? json['familia']?.toString() ?? 'N/A',
      origemGeografica: json['origin']?.toString() ??
          json['origem_geografica']?.toString() ??
          'N/A',
    );
  }
}

class EsteticaViva {
  final String epocaFloracao;
  final String corDasFlores;
  final String tamanhoMaximo;
  final String velocidadeCrescimento;

  EsteticaViva({
    required this.epocaFloracao,
    required this.corDasFlores,
    required this.tamanhoMaximo,
    required this.velocidadeCrescimento,
  });

  Map<String, dynamic> toJson() => {
        'flowering_season': epocaFloracao,
        'flower_colors': corDasFlores,
        'max_size': tamanhoMaximo,
        'growth_speed': velocidadeCrescimento,
      };

  factory EsteticaViva.fromJson(Map<dynamic, dynamic> json) {
    return EsteticaViva(
      epocaFloracao: json['flowering_season']?.toString() ??
          json['epoca_floracao']?.toString() ??
          'N/A',
      corDasFlores: json['flower_colors']?.toString() ??
          json['cor_das_flores']?.toString() ??
          'N/A',
      tamanhoMaximo: json['max_size']?.toString() ??
          json['tamanho_maximo_estimado']?.toString() ??
          'N/A',
      velocidadeCrescimento: json['growth_speed']?.toString() ??
          json['velocidade_crescimento']?.toString() ??
          'N/A',
    );
  }
}

class DiagnosticoSaude {
  final String condicao;
  final String detalhes;
  final String urgencia;
  final String planoRecuperacao;

  DiagnosticoSaude({
    required this.condicao,
    required this.detalhes,
    required this.urgencia,
    required this.planoRecuperacao,
  });

  Map<String, dynamic> toJson() => {
        'health_status': condicao,
        'clinical_details': detalhes,
        'urgency_level': urgencia,
        'recovery_guide': planoRecuperacao,
      };

  factory DiagnosticoSaude.fromJson(Map<dynamic, dynamic> json) {
    return DiagnosticoSaude(
      condicao: PlantAnalysisModel._translateFallback(
          json['health_status'] ?? json['condicao'] ?? 'Saudável'),
      detalhes: json['clinical_details']?.toString() ??
          json['detalhes']?.toString() ??
          'Sem diagnóstico específico.',
      urgencia: PlantAnalysisModel._translateFallback(
          json['urgency_level'] ?? json['urgencia'] ?? 'low'),
      planoRecuperacao: json['recovery_guide']?.toString() ??
          json['plano_recuperacao']?.toString() ??
          'Nenhum tratamento necessário.',
    );
  }
}

class GuiaSobrevivencia {
  final Map<String, dynamic> luminosidade;
  final Map<String, dynamic> regimeHidrico;
  final Map<String, dynamic> soloENutricao;

  GuiaSobrevivencia({
    required this.luminosidade,
    required this.regimeHidrico,
    required this.soloENutricao,
  });

  Map<String, dynamic> toJson() => {
        'light_needs': luminosidade,
        'watering_regime': regimeHidrico,
        'soil_and_nutrition': soloENutricao,
      };

  factory GuiaSobrevivencia.fromJson(Map<dynamic, dynamic> json) {
    final light = Map<String, dynamic>.from(
        json['light_needs'] ?? json['luminosidade'] ?? {});
    if (light.containsKey('type')) {
      light['type'] = PlantAnalysisModel._translateFallback(light['type']);
    }
    if (light.containsKey('details')) light['explanation'] = light['details'];

    final water = Map<String, dynamic>.from(
        json['watering_regime'] ?? json['regime_hidrico'] ?? {});
    if (water.containsKey('frequency')) {
      water['frequency'] =
          PlantAnalysisModel._translateFallback(water['frequency']);
    }

    final soil = Map<String, dynamic>.from(
        json['soil_and_nutrition'] ?? json['solo_e_nutricao'] ?? {});
    if (soil.containsKey('soil_composition')) {
      soil['soil_type'] = soil['soil_composition'];
    }
    if (soil.containsKey('fertilizer_recommendation')) {
      soil['fertilizer'] = soil['fertilizer_recommendation'];
    }

    return GuiaSobrevivencia(
      luminosidade: light,
      regimeHidrico: water,
      soloENutricao: soil,
    );
  }
}

class SegurancaEBiofilia {
  final Map<String, dynamic> segurancaDomestica;
  final Map<String, dynamic> poderesBiofilicos;

  SegurancaEBiofilia({
    required this.segurancaDomestica,
    required this.poderesBiofilicos,
  });

  Map<String, dynamic> toJson() => {
        'home_safety': segurancaDomestica,
        'biofillic_benefits': poderesBiofilicos,
      };

  factory SegurancaEBiofilia.fromJson(Map<dynamic, dynamic> json) {
    return SegurancaEBiofilia(
      segurancaDomestica: Map<String, dynamic>.from(
          json['home_safety'] ?? json['seguranca_domestica'] ?? {}),
      poderesBiofilicos: Map<String, dynamic>.from(
          json['biofillic_benefits'] ?? json['poderes_biofilicos'] ?? {}),
    );
  }
}

class EngenhariaPropagacao {
  final String metodo;
  final String passoAPasso;
  final String dificuldade;

  EngenhariaPropagacao({
    required this.metodo,
    required this.passoAPasso,
    required this.dificuldade,
  });

  Map<String, dynamic> toJson() => {
        'method': metodo,
        'step_by_step': passoAPasso,
        'difficulty': dificuldade,
      };

  factory EngenhariaPropagacao.fromJson(Map<dynamic, dynamic> json) {
    return EngenhariaPropagacao(
      metodo: json['method']?.toString() ?? json['metodo']?.toString() ?? 'N/A',
      passoAPasso: json['step_by_step']?.toString() ??
          json['passo_a_passo']?.toString() ??
          'N/A',
      dificuldade: PlantAnalysisModel._translateFallback(
          json['difficulty'] ?? json['dificuldade_reproducao'] ?? 'N/A'),
    );
  }
}

class InteligenciaEcossistema {
  final List<String> plantasParceiras;
  final List<String> plantasConflitantes;
  final String repelenteNatural;

  InteligenciaEcossistema({
    required this.plantasParceiras,
    required this.plantasConflitantes,
    required this.repelenteNatural,
  });

  Map<String, dynamic> toJson() => {
        'companion_planting': plantasParceiras,
        'natural_repellent': repelenteNatural,
      };

  factory InteligenciaEcossistema.fromJson(Map<dynamic, dynamic> json) {
    return InteligenciaEcossistema(
      plantasParceiras: (json['companion_planting'] as List? ??
              json['plantas_parceiras'] as List? ??
              [])
          .map((e) => e.toString())
          .toList(),
      plantasConflitantes: (json['plantas_conflitantes'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      repelenteNatural: json['natural_repellent']?.toString() ??
          json['repelente_natural']?.toString() ??
          'N/A',
    );
  }
}

class LifestyleEFengShui {
  final String posicionamentoIdeal;
  final String simbolismo;

  LifestyleEFengShui({
    required this.posicionamentoIdeal,
    required this.simbolismo,
  });

  Map<String, dynamic> toJson() => {
        'ideal_positioning': posicionamentoIdeal,
        'symbolism': simbolismo,
      };

  factory LifestyleEFengShui.fromJson(Map<dynamic, dynamic> json) {
    return LifestyleEFengShui(
      posicionamentoIdeal: json['ideal_positioning']?.toString() ??
          json['posicionamento_ideal']?.toString() ??
          'N/A',
      simbolismo: json['symbolism']?.toString() ??
          json['simbolismo']?.toString() ??
          'N/A',
    );
  }
}

class AlertasSazonais {
  final String inverno;
  final String verao;

  AlertasSazonais({
    required this.inverno,
    required this.verao,
  });

  Map<String, dynamic> toJson() => {
        'winter': inverno,
        'summer': verao,
      };

  factory AlertasSazonais.fromJson(Map<dynamic, dynamic> json) {
    return AlertasSazonais(
      inverno:
          json['winter']?.toString() ?? json['inverno']?.toString() ?? 'N/A',
      verao: json['summer']?.toString() ?? json['verao']?.toString() ?? 'N/A',
    );
  }
}
