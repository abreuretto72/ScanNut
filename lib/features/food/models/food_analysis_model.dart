import 'package:flutter/foundation.dart';

class FoodAnalysisModel {
  final IdentidadeESeguranca identidade;
  final MacronutrientesPro macros;
  final VitaminasEMinerais micronutrientes;
  final AnaliseProsContras analise;
  final BiohackingPerformance performance;
  final InteligenciaCulinaria gastronomia;
  final String dicaEspecialista;

  FoodAnalysisModel({
    required this.identidade,
    required this.macros,
    required this.micronutrientes,
    required this.analise,
    required this.performance,
    required this.gastronomia,
    required this.dicaEspecialista,
  });

  // Backward compatibility getters for simple usage
  String get itemName => identidade.nome;
  int get estimatedCalories => macros.calorias;
  MacronutrientesPro get macronutrients => macros;
  String get advice => analise.vereditoIa;
  List<String> get benefits => analise.pontosPositivos;
  List<String> get risks => analise.pontosNegativos;
  List<dynamic> get recipes => [];

  factory FoodAnalysisModel.fromJson(Map<String, dynamic> json) {
    return FoodAnalysisModel(
      identidade: IdentidadeESeguranca.fromJson(json['identidade_e_seguranca'] ?? {}),
      macros: MacronutrientesPro.fromJson(json['macronutrientes_pro'] ?? {}),
      micronutrientes: VitaminasEMinerais.fromJson(json['mapa_de_vitaminas_e_minerais'] ?? {}),
      analise: AnaliseProsContras.fromJson(json['analise_pros_e_contras'] ?? {}),
      performance: BiohackingPerformance.fromJson(json['biohacking_e_performance'] ?? {}),
      gastronomia: InteligenciaCulinaria.fromJson(json['inteligencia_culinaria'] ?? {}),
      dicaEspecialista: json['dica_do_especialista'] ?? '',
    );
  }
}

class IdentidadeESeguranca {
  final String nome;
  final String categoria;
  final String alertaCritico;
  final String bioquimicaAlert;

  IdentidadeESeguranca({
    required this.nome,
    required this.categoria,
    required this.alertaCritico,
    required this.bioquimicaAlert,
  });

  factory IdentidadeESeguranca.fromJson(Map<String, dynamic> json) {
    return IdentidadeESeguranca(
      nome: json['nome']?.toString() ?? 'Alimento Desconhecido',
      categoria: json['categoria']?.toString() ?? 'N/A',
      alertaCritico: json['alerta_critico']?.toString() ?? 'Nenhum',
      bioquimicaAlert: json['bioquimica_alert']?.toString() ?? '',
    );
  }
}

class MacronutrientesPro {
  final int calorias;
  final Map<String, String> proteinas;
  final Map<String, String> carboidratos;
  final Map<String, String> fibras;
  final Map<String, String> gorduras;
  final Map<String, dynamic> indiceGlicemico;

  MacronutrientesPro({
    required this.calorias,
    required this.proteinas,
    required this.carboidratos,
    required this.fibras,
    required this.gorduras,
    required this.indiceGlicemico,
  });

  factory MacronutrientesPro.fromJson(Map<String, dynamic> json) {
    return MacronutrientesPro(
      calorias: (json['calorias'] is int) ? json['calorias'] : int.tryParse(json['calorias']?.toString() ?? '0') ?? 0,
      proteinas: _toStringMap(json['proteinas']),
      carboidratos: _toStringMap(json['carboidratos']),
      fibras: _toStringMap(json['fibras']),
      gorduras: _toStringMap(json['gorduras']),
      indiceGlicemico: json['indice_glicemico'] is Map ? Map<String, dynamic>.from(json['indice_glicemico']) : {},
    );
  }

  static Map<String, String> _toStringMap(dynamic input) {
    if (input is! Map) return {};
    return input.map((key, value) => MapEntry(key.toString(), value.toString()));
  }

  // Simple getters for existing UI compatibility
  String get protein => proteinas['valor'] ?? '0g';
  String get carbs => carboidratos['total'] ?? '0g';
  String get fats => gorduras['total'] ?? '0g';
}

class VitaminasEMinerais {
  final List<NutrienteItem> lista;
  final String sinergiaNutricional;

  VitaminasEMinerais({
    required this.lista,
    required this.sinergiaNutricional,
  });

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

  factory AnaliseProsContras.fromJson(Map<String, dynamic> json) {
    return AnaliseProsContras(
      pontosPositivos: (json['pontos_positivos'] as List? ?? []).map((e) => e.toString()).toList(),
      pontosNegativos: (json['pontos_negativos'] as List? ?? []).map((e) => e.toString()).toList(),
      vereditoIa: json['veredito_ia']?.toString() ?? '',
    );
  }
}

class BiohackingPerformance {
  final int indiceSaciedade;
  final String impactoNoFoco;
  final String momentoIdeal;

  BiohackingPerformance({
    required this.indiceSaciedade,
    required this.impactoNoFoco,
    required this.momentoIdeal,
  });

  factory BiohackingPerformance.fromJson(Map<String, dynamic> json) {
    return BiohackingPerformance(
      indiceSaciedade: (json['indice_saciedade'] is int) ? json['indice_saciedade'] : int.tryParse(json['indice_saciedade']?.toString() ?? '3') ?? 3,
      impactoNoFoco: json['impacto_no_foco']?.toString() ?? '',
      momentoIdeal: json['momento_ideal']?.toString() ?? '',
    );
  }
}

class InteligenciaCulinaria {
  final String preservacaoNutrientes;
  final String smartSwap;

  InteligenciaCulinaria({
    required this.preservacaoNutrientes,
    required this.smartSwap,
  });

  factory InteligenciaCulinaria.fromJson(Map<String, dynamic> json) {
    return InteligenciaCulinaria(
      preservacaoNutrientes: json['preservacao_nutrientes']?.toString() ?? '',
      smartSwap: json['smart_swap']?.toString() ?? '',
    );
  }
}
