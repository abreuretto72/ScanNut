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
  String get plantName => identificacao.nomesPopulares.isNotEmpty ? identificacao.nomesPopulares.first : identificacao.nomeCientifico;
  String get condition => saude.condicao;
  String get diagnosis => saude.detalhes;
  String get organicTreatment => saude.planoRecuperacao;
  String get urgency => saude.urgencia;

  bool get isHealthy => saude.condicao.toLowerCase().contains('saudável');
  
  Map<String, dynamic> toJson() {
    return {
      'identificacao': identificacao.toJson(),
      'estetica_viva': estetica.toJson(),
      'diagnostico_saude': saude.toJson(),
      'guia_sobrevivencia': sobrevivencia.toJson(),
      'seguranca_e_biofilia': segurancaBiofilia.toJson(),
      'engenharia_propagacao': propagacao.toJson(),
      'inteligencia_ecossistema': ecossistema.toJson(),
      'lifestyle_e_feng_shui': lifestyle.toJson(),
      'alertas_sazonais': alertasSazonais.toJson(),
    };
  }

  factory PlantAnalysisModel.fromJson(Map<String, dynamic> json) {
    return PlantAnalysisModel(
      identificacao: Identificacao.fromJson(json['identificacao'] ?? {}),
      estetica: EsteticaViva.fromJson(json['estetica_viva'] ?? {}),
      saude: DiagnosticoSaude.fromJson(json['diagnostico_saude'] ?? {}),
      sobrevivencia: GuiaSobrevivencia.fromJson(json['guia_sobrevivencia'] ?? {}),
      segurancaBiofilia: SegurancaEBiofilia.fromJson(json['seguranca_e_biofilia'] ?? {}),
      propagacao: EngenhariaPropagacao.fromJson(json['engenharia_propagacao'] ?? {}),
      ecossistema: InteligenciaEcossistema.fromJson(json['inteligencia_ecossistema'] ?? {}),
      lifestyle: LifestyleEFengShui.fromJson(json['lifestyle_e_feng_shui'] ?? {}),
      alertasSazonais: AlertasSazonais.fromJson(json['alertas_sazonais'] ?? {}),
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
    'nome_cientifico': nomeCientifico,
    'nomes_populares': nomesPopulares,
    'familia': familia,
    'origem_geografica': origemGeografica,
  };

  factory Identificacao.fromJson(Map<String, dynamic> json) {
    return Identificacao(
      nomeCientifico: json['nome_cientifico']?.toString() ?? 'N/A',
      nomesPopulares: (json['nomes_populares'] as List? ?? []).map((e) => e.toString()).toList(),
      familia: json['familia']?.toString() ?? 'N/A',
      origemGeografica: json['origem_geografica']?.toString() ?? 'N/A',
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
    'epoca_floracao': epocaFloracao,
    'cor_das_flores': corDasFlores,
    'tamanho_maximo_estimado': tamanhoMaximo,
    'velocidade_crescimento': velocidadeCrescimento,
  };

  factory EsteticaViva.fromJson(Map<String, dynamic> json) {
    return EsteticaViva(
      epocaFloracao: json['epoca_floracao']?.toString() ?? 'N/A',
      corDasFlores: json['cor_das_flores']?.toString() ?? 'N/A',
      tamanhoMaximo: json['tamanho_maximo_estimado']?.toString() ?? 'N/A',
      velocidadeCrescimento: json['velocidade_crescimento']?.toString() ?? 'N/A',
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
    'condicao': condicao,
    'detalhes': detalhes,
    'urgencia': urgencia,
    'plano_recuperacao': planoRecuperacao,
  };

  factory DiagnosticoSaude.fromJson(Map<String, dynamic> json) {
    return DiagnosticoSaude(
      condicao: json['condicao']?.toString() ?? 'Saudável',
      detalhes: json['detalhes']?.toString() ?? 'Sem diagnóstico específico.',
      urgencia: json['urgencia']?.toString() ?? 'low',
      planoRecuperacao: json['plano_recuperacao']?.toString() ?? 'Nenhum tratamento necessário.',
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
    'luminosidade': luminosidade,
    'regime_hidrico': regimeHidrico,
    'solo_e_nutricao': soloENutricao,
  };

  factory GuiaSobrevivencia.fromJson(Map<String, dynamic> json) {
    return GuiaSobrevivencia(
      luminosidade: Map<String, dynamic>.from(json['luminosidade'] ?? {}),
      regimeHidrico: Map<String, dynamic>.from(json['regime_hidrico'] ?? {}),
      soloENutricao: Map<String, dynamic>.from(json['solo_e_nutricao'] ?? {}),
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
    'seguranca_domestica': segurancaDomestica,
    'poderes_biofilicos': poderesBiofilicos,
  };

  factory SegurancaEBiofilia.fromJson(Map<String, dynamic> json) {
    return SegurancaEBiofilia(
      segurancaDomestica: Map<String, dynamic>.from(json['seguranca_domestica'] ?? {}),
      poderesBiofilicos: Map<String, dynamic>.from(json['poderes_biofilicos'] ?? {}),
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
    'metodo': metodo,
    'passo_a_passo': passoAPasso,
    'dificuldade_reproducao': dificuldade,
  };

  factory EngenhariaPropagacao.fromJson(Map<String, dynamic> json) {
    return EngenhariaPropagacao(
      metodo: json['metodo']?.toString() ?? 'N/A',
      passoAPasso: json['passo_a_passo']?.toString() ?? 'N/A',
      dificuldade: json['dificuldade_reproducao']?.toString() ?? 'N/A',
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
    'companion_planting': {
      'plantas_parceiras': plantasParceiras,
      'plantas_conflitantes': plantasConflitantes,
    },
    'repelente_natural': repelenteNatural,
  };

  factory InteligenciaEcossistema.fromJson(Map<String, dynamic> json) {
    final companion = json['companion_planting'] ?? {};
    return InteligenciaEcossistema(
      plantasParceiras: (companion['plantas_parceiras'] as List? ?? []).map((e) => e.toString()).toList(),
      plantasConflitantes: (companion['plantas_conflitantes'] as List? ?? []).map((e) => e.toString()).toList(),
      repelenteNatural: json['repelente_natural']?.toString() ?? 'N/A',
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
    'posicionamento_ideal': posicionamentoIdeal,
    'simbolismo': simbolismo,
  };

  factory LifestyleEFengShui.fromJson(Map<String, dynamic> json) {
    return LifestyleEFengShui(
      posicionamentoIdeal: json['posicionamento_ideal']?.toString() ?? 'N/A',
      simbolismo: json['simbolismo']?.toString() ?? 'N/A',
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
    'inverno': inverno,
    'verao': verao,
  };

  factory AlertasSazonais.fromJson(Map<String, dynamic> json) {
    return AlertasSazonais(
      inverno: json['inverno']?.toString() ?? 'N/A',
      verao: json['verao']?.toString() ?? 'N/A',
    );
  }
}
