class FoodAnalysisModel {
  final IdentidadeESeguranca identidade;
  final MacronutrientesPro macros;
  final VitaminasEMinerais micronutrientes;
  final AnaliseProsContras analise;
  final BiohackingPerformance performance;
  final InteligenciaCulinaria gastronomia;
  final List<ReceitaRapida> receitas;
  final String dicaEspecialista;

  FoodAnalysisModel({
    required this.identidade,
    required this.macros,
    required this.micronutrientes,
    required this.analise,
    required this.performance,
    required this.gastronomia,
    required this.receitas,
    required this.dicaEspecialista,
  });

  // Backward compatibility getters
  String get itemName => identidade.nome;
  int get estimatedCalories => macros.calorias100g;
  String get advice => analise.vereditoIa;
  List<String> get benefits => analise.pontosPositivos;
  List<String> get risks => analise.pontosNegativos;
  List<ReceitaRapida> get recipes => receitas;
  MacronutrientesPro get macronutrients => macros;

  Map<String, dynamic> toJson() {
    return {
      'identidade_e_seguranca': identidade.toJson(),
      'macronutrientes_pro': macros.toJson(),
      'mapa_de_vitaminas_e_minerais': micronutrientes.toJson(),
      'analise_pros_e_contras': analise.toJson(),
      'biohacking_e_performance': performance.toJson(),
      'receitas_rapidas_15min': receitas.map((r) => r.toJson()).toList(),
      'inteligencia_culinaria': gastronomia.toJson(),
      'dica_do_especialista': dicaEspecialista,
    };
  }

  factory FoodAnalysisModel.fromJson(Map<String, dynamic> json) {
    return FoodAnalysisModel(
      identidade: IdentidadeESeguranca.fromJson(json['identidade_e_seguranca'] ?? {}),
      macros: MacronutrientesPro.fromJson(json['macronutrientes_pro'] ?? {}),
      micronutrientes: VitaminasEMinerais.fromJson(json['mapa_de_vitaminas_e_minerais'] ?? {}),
      analise: AnaliseProsContras.fromJson(json['analise_pros_e_contras'] ?? {}),
      performance: BiohackingPerformance.fromJson(json['biohacking_e_performance'] ?? {}),
      gastronomia: InteligenciaCulinaria.fromJson(json['inteligencia_culinaria'] ?? {}),
      receitas: (json['receitas_rapidas_15min'] as List? ?? [])
          .map((e) => ReceitaRapida.fromJson(e))
          .toList(),
      dicaEspecialista: json['dica_do_especialista'] ?? json['dica_especialista'] ?? '',
    );
  }
}

class IdentidadeESeguranca {
  final String nome;
  final String statusProcessamento;
  final String semaforoSaude;
  final String alertaCritico;
  final String bioquimicaAlert;

  IdentidadeESeguranca({
    required this.nome,
    required this.statusProcessamento,
    required this.semaforoSaude,
    required this.alertaCritico,
    required this.bioquimicaAlert,
  });

  Map<String, dynamic> toJson() => {
    'nome': nome,
    'status_processamento': statusProcessamento,
    'semaforo_saude': semaforoSaude,
    'alerta_critico': alertaCritico,
    'bioquimica_alert': bioquimicaAlert,
  };

  factory IdentidadeESeguranca.fromJson(Map<String, dynamic> json) {
    return IdentidadeESeguranca(
      nome: json['nome']?.toString() ?? 'Alimento Desconhecido',
      statusProcessamento: json['status_processamento']?.toString() ?? json['categoria']?.toString() ?? 'In natura',
      semaforoSaude: json['semaforo_saude']?.toString() ?? 'Verde',
      alertaCritico: json['alerta_critico']?.toString() ?? 'Nenhum',
      bioquimicaAlert: json['bioquimica_alert']?.toString() ?? '',
    );
  }
}

class MacronutrientesPro {
  final int calorias100g;
  final String proteinas;
  final String carboidratosLiquidos;
  final String gordurasPerfil;
  final String indiceGlicemico;

  MacronutrientesPro({
    required this.calorias100g,
    required this.proteinas,
    required this.carboidratosLiquidos,
    required this.gordurasPerfil,
    required this.indiceGlicemico,
  });

  Map<String, dynamic> toJson() => {
    'calorias_100g': calorias100g,
    'proteinas': proteinas,
    'carboidratos_liquidos': carboidratosLiquidos,
    'gorduras_perfil': gordurasPerfil,
    'indice_glicemico': indiceGlicemico,
  };

  // Compatibility getters
  String get protein => proteinas;
  String get carbs => carboidratosLiquidos;
  String get fats => gordurasPerfil;
  int get calorias => calorias100g;

  factory MacronutrientesPro.fromJson(Map<String, dynamic> json) {
    return MacronutrientesPro(
      calorias100g: json['calorias_100g'] ?? json['calorias'] ?? 0,
      proteinas: json['proteinas']?.toString() ?? '',
      carboidratosLiquidos: json['carboidratos_liquidos'] ?? json['carboidratos']?['total'] ?? '',
      gordurasPerfil: json['gorduras_perfil'] ?? json['gorduras']?['total'] ?? '',
      indiceGlicemico: json['indice_glicemico']?.toString() ?? '',
    );
  }
}

class VitaminasEMinerais {
  final List<NutrienteItem> lista;
  final String sinergiaNutricional;

  VitaminasEMinerais({
    required this.lista,
    required this.sinergiaNutricional,
  });

  Map<String, dynamic> toJson() => {
    'lista': lista.map((e) => e.toJson()).toList(),
    'sinergia_nutricional': sinergiaNutricional,
  };

  factory VitaminasEMinerais.fromJson(Map<String, dynamic> json) {
    return VitaminasEMinerais(
      lista: (json['lista'] as List? ?? [])
          .map((e) => NutrienteItem.fromJson(e))
          .toList(),
      sinergiaNutricional: json['sinergia_nutricional']?.toString() ?? '',
    );
  }
}

class NutrienteItem {
  final String nome;
  final String quantidade;
  final int percentualDv;
  final String funcao;

  NutrienteItem({
    required this.nome,
    required this.quantidade,
    required this.percentualDv,
    required this.funcao,
  });

  Map<String, dynamic> toJson() => {
    'nome': nome,
    'quantidade': quantidade,
    'percentual_dv': percentualDv,
    'funcao': funcao,
  };

  factory NutrienteItem.fromJson(Map<String, dynamic> json) {
    return NutrienteItem(
      nome: json['nome']?.toString() ?? '',
      quantidade: json['quantidade']?.toString() ?? '',
      percentualDv: (json['percentual_dv'] is int) ? json['percentual_dv'] : int.tryParse(json['percentual_dv']?.toString() ?? '0') ?? 0,
      funcao: json['funcao']?.toString() ?? '',
    );
  }
}

class AnaliseProsContras {
  final List<String> pontosPositivos;
  final List<String> pontosNegativos;
  final String vereditoIa;

  AnaliseProsContras({
    required this.pontosPositivos,
    required this.pontosNegativos,
    required this.vereditoIa,
  });

  Map<String, dynamic> toJson() => {
    'pontos_positivos': pontosPositivos,
    'pontos_negativos': pontosNegativos,
    'veredito_ia': vereditoIa,
  };

  factory AnaliseProsContras.fromJson(Map<String, dynamic> json) {
    return AnaliseProsContras(
      pontosPositivos: (json['pontos_positivos'] as List? ?? []).map((e) => e.toString()).toList(),
      pontosNegativos: (json['pontos_negativos'] as List? ?? []).map((e) => e.toString()).toList(),
      vereditoIa: json['veredito_ia']?.toString() ?? '',
    );
  }
}

class BiohackingPerformance {
  final List<String> pontosPositivosCorpo;
  final List<String> pontosAtencaoCorpo;
  final int indiceSaciedade;
  final String impactoFocoEnergia;
  final String momentoIdealConsumo;

  BiohackingPerformance({
    required this.pontosPositivosCorpo,
    required this.pontosAtencaoCorpo,
    required this.indiceSaciedade,
    required this.impactoFocoEnergia,
    required this.momentoIdealConsumo,
  });

  Map<String, dynamic> toJson() => {
    'pontos_positivos_corpo': pontosPositivosCorpo,
    'pontos_atencao_corpo': pontosAtencaoCorpo,
    'indice_saciedade': indiceSaciedade,
    'impacto_foco_energia': impactoFocoEnergia,
    'momento_ideal_consumo': momentoIdealConsumo,
  };

  factory BiohackingPerformance.fromJson(Map<String, dynamic> json) {
    return BiohackingPerformance(
      pontosPositivosCorpo: (json['pontos_positivos_corpo'] as List? ?? []).map((e) => e.toString()).toList(),
      pontosAtencaoCorpo: (json['pontos_atencao_corpo'] as List? ?? []).map((e) => e.toString()).toList(),
      indiceSaciedade: (json['indice_saciedade'] is int) ? json['indice_saciedade'] : int.tryParse(json['indice_saciedade']?.toString() ?? '3') ?? 3,
      impactoFocoEnergia: json['impacto_foco_energia']?.toString() ?? json['impacto_no_foco']?.toString() ?? '',
      momentoIdealConsumo: json['momento_ideal_consumo']?.toString() ?? json['momento_ideal']?.toString() ?? '',
    );
  }
}

class ReceitaRapida {
  final String nome;
  final String instrucoes;
  final String tempoPreparo;

  ReceitaRapida({
    required this.nome,
    required this.instrucoes,
    required this.tempoPreparo,
  });

  Map<String, dynamic> toJson() => {
    'nome': nome,
    'instrucoes': instrucoes,
    'tempo_preparo': tempoPreparo,
  };

  factory ReceitaRapida.fromJson(Map<String, dynamic> json) {
    return ReceitaRapida(
      nome: json['nome']?.toString() ?? '',
      instrucoes: json['instrucoes']?.toString() ?? '',
      tempoPreparo: json['tempo_preparo']?.toString() ?? '15 min',
    );
  }
}

class InteligenciaCulinaria {
  final String preservacaoNutrientes;
  final String smartSwap;
  final String dicaEspecialista;

  InteligenciaCulinaria({
    required this.preservacaoNutrientes,
    required this.smartSwap,
    required this.dicaEspecialista,
  });

  Map<String, dynamic> toJson() => {
    'preservacao_nutrientes': preservacaoNutrientes,
    'smart_swap': smartSwap,
    'dica_especialista': dicaEspecialista,
  };

  factory InteligenciaCulinaria.fromJson(Map<String, dynamic> json) {
    return InteligenciaCulinaria(
      preservacaoNutrientes: json['preservacao_nutrientes']?.toString() ?? '',
      smartSwap: json['smart_swap']?.toString() ?? '',
      dicaEspecialista: json['dica_especialista']?.toString() ?? json['dica_do_especialista']?.toString() ?? '',
    );
  }
}
