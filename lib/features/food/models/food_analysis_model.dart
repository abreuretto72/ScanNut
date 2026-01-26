/// Nota: Este modelo é referido internamente como "FoodModel" nos planos de blindagem.
import '../data/food_constants.dart';

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

  // 🛡️ ESCUDO DE MAPEAMENTO (Factory Sovereign)
  // Converte o JSON caótico da IA para a estrutura cristalina do App
  factory FoodAnalysisModel.fromGemini(Map<String, dynamic> raw) {
    if (raw['error'] == 'not_food' ||
        raw['food_name'] == 'not_food') {
      throw Exception('NOT_FOOD_DETECTED');
    }

    // 🛡️ V135: Nova Extração Categorizada
    final resumo = raw['resumo'] ?? {};
    final saude = raw['saude_biohacking'] ?? {};
    final nutre = raw['nutrientes_detalhado'] ?? {};
    final gastro = raw['gastronomia'] ?? {};

    // Helper para buscar em categorias ou no root (fallback)
    dynamic get(String key, {Map? category}) {
       if (category != null && category.containsKey(key)) return category[key];
       if (raw.containsKey(key)) return raw[key];
       final synonyms = FoodConstants.keySynonyms[key] ?? [];
       for (final s in synonyms) {
         if (raw.containsKey(s)) return raw[s];
         if (resumo.containsKey(s)) return resumo[s];
         if (nutre.containsKey(s)) return nutre[s];
       }
       return null;
    }

    // Mapeamento de Identidade
    final nome = get('food_name', category: resumo)?.toString() ?? 'Alimento Detectado';
    final cal = get('calories_kcal', category: resumo);
    final score = get('health_score', category: resumo);
    final rec = get('recommendation', category: resumo) ?? saude['recommendation'] ?? "Equilíbrio é a chave.";
    
    final labels = resumo['allergens'] as List? ?? raw['allergens'] as List? ?? [];
    final alerta = labels.isNotEmpty ? "Contém: ${labels.join(', ')}" : "Nenhum alerta crítico";

    final identidadeMap = {
      'nome': nome,
      'status_processamento': 'Analisado com IA v135',
      'semaforo_saude': _mapTrafficLight(score),
      'alerta_critico': alerta,
      'bioquimica_alert': '',
      'estimativa_peso': 'Porção Padrão (100g)'
    };

    // Mapeamento de Macros
    final m = nutre['macros'] ?? raw['macros'] ?? {};
    final macrosMap = {
      'calorias_100g': _parseCal(cal),
      'proteinas': "${m['protein_g'] ?? 0}g",
      'carboidratos_liquidos': "${m['carbs_g'] ?? 0}g",
      'gorduras_perfil': "${m['fat_g'] ?? 0}g",
      'indice_glicemico': 'Estimado'
    };

    // Mapeamento de Micronutrientes
    final microsRaw = nutre['micros'] as List? ?? [];
    final nutriList = microsRaw.map((mi) => NutrienteItem(
      nome: mi['name']?.toString() ?? 'Nutriente',
      quantidade: mi['value']?.toString() ?? '0',
      percentualDv: mi['dv_percent'] ?? 0,
      funcao: mi['function']?.toString() ?? 'Manutenção'
    )).toList();

    return FoodAnalysisModel(
      identidade: IdentidadeESeguranca.fromJson(identidadeMap),
      macros: MacronutrientesPro.fromJson(macrosMap),
      micronutrientes: VitaminasEMinerais(
        lista: nutriList,
        sinergiaNutricional: nutre['synergy']?.toString() ?? 'Absorção Normal',
      ),
      analise: AnaliseProsContras(
        pontosPositivos: List<String>.from(saude['pros'] ?? raw['pros'] ?? []),
        pontosNegativos: List<String>.from(saude['cons'] ?? raw['cons'] ?? []),
        vereditoIa: rec,
      ),
      performance: BiohackingPerformance.fromJson({
        'satiety_index': saude['satiety_index'],
        'focus_energy_impact': saude['focus_impact'],
        'ideal_consumption_moment': saude['ideal_moment'],
        'pontos_positivos_corpo': List<String>.from(saude['pros'] ?? []),
      }),
      gastronomia: InteligenciaCulinaria.fromJson({
        'nutrient_preservation': gastro['prep_tip'],
        'smart_swap': gastro['smart_swap'],
        'expert_tip': rec
      }),
      receitas: (gastro['recipes'] as List? ?? []).map((r) => ReceitaRapida.fromJson(r)).toList(),
      dicaEspecialista: rec,
    );
  }

  static int _parseCal(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    final s = val.toString().replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(s) ?? 0;
  }

  static String _mapTrafficLight(dynamic score) {
    final s = int.tryParse(score.toString()) ?? 5;
    if (s >= 8) return 'Verde';
    if (s >= 5) return 'Amarelo';
    return 'Vermelho';
  }
  factory FoodAnalysisModel.fromJson(Map<String, dynamic> json) {
    // 🛡️ ESCUDO DE AUTO-DETECÇÃO: Se o JSON for plano ou categorizado (vinda direta da IA), usa o fromGemini.
    // Se for estruturado (vindo do Cache/Hive), usa o mapeamento hierárquico.
    if (json.containsKey('resumo') || 
        json.containsKey('saude_biohacking') || 
        json.containsKey('nutrientes_detalhado') ||
        json.containsKey('food_name') || 
        json.containsKey('calories_kcal')) {
       return FoodAnalysisModel.fromGemini(json);
    }

    return FoodAnalysisModel(
      identidade: IdentidadeESeguranca.fromJson(
          json['identity_and_safety'] ?? json['identidade_e_seguranca'] ?? {}),
      macros: MacronutrientesPro.fromJson(
          json['macronutrients_pro'] ?? json['macronutrientes_pro'] ?? {}),
      micronutrientes: VitaminasEMinerais.fromJson(
          json['vitamins_minerals_map'] ??
              json['mapa_de_vitaminas_e_minerais'] ??
              {}),
      analise: AnaliseProsContras.fromJson(
          json['pros_cons_analysis'] ?? json['analise_pros_e_contras'] ?? {}),
      performance: BiohackingPerformance.fromJson(
          json['biohacking_performance'] ??
              json['biohacking_e_performance'] ??
              {}),
      gastronomia: InteligenciaCulinaria.fromJson(
          json['culinary_intelligence'] ??
              json['inteligencia_culinaria'] ??
              {}),
      receitas: ((json['quick_recipes_15min'] ?? json['receitas_rapidas_15min'])
                  as List? ??
              [])
          .map((e) => ReceitaRapida.fromJson(e))
          .toList(),
      dicaEspecialista: json['dica_do_especialista'] ??
          json['expert_tip'] ??
          // Try extracting from culinary_intelligence if top-level is missing
          (json['culinary_intelligence'] != null
              ? json['culinary_intelligence']['expert_tip']
              : null) ??
          (json['inteligencia_culinaria'] != null
              ? json['inteligencia_culinaria']['dica_especialista']
              : null) ??
          '',
    );
  }
}

class IdentidadeESeguranca {
  final String nome;
  final String statusProcessamento;
  final String semaforoSaude;
  final String alertaCritico;
  final String bioquimicaAlert;
  // 🛡️ [V135] Novos Campos para Human Food
  final String? estimativaPeso;
  final String? metodoPreparo;

  IdentidadeESeguranca({
    required this.nome,
    required this.statusProcessamento,
    required this.semaforoSaude,
    required this.alertaCritico,
    required this.bioquimicaAlert,
    this.estimativaPeso,
    this.metodoPreparo,
  });

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'status_processamento': statusProcessamento,
        'semaforo_saude': semaforoSaude,
        'alerta_critico': alertaCritico,
        'bioquimica_alert': bioquimicaAlert,
        'estimativa_peso': estimativaPeso,
        'metodo_preparo': metodoPreparo,
      };

  factory IdentidadeESeguranca.fromJson(Map<String, dynamic> json) {
    return IdentidadeESeguranca(
      nome: json['name']?.toString() ??
          json['nome']?.toString() ??
          'UNKNOWN_FOOD',
      statusProcessamento: json['processing_status']?.toString() ??
          json['status_processamento']?.toString() ??
          'In natura',
      semaforoSaude: json['health_traffic_light']?.toString() ??
          json['semaforo_saude']?.toString() ??
          'Verde',
      alertaCritico: json['critical_alert']?.toString() ??
          json['alerta_critico']?.toString() ??
          'Nenhum',
      bioquimicaAlert: json['biochemistry_alert']?.toString() ??
          json['bioquimica_alert']?.toString() ??
          '',
      estimativaPeso: json['weight_estimate']?.toString() ??
          json['estimativa_peso']?.toString(),
      metodoPreparo: json['preparation_method']?.toString() ??
          json['metodo_preparo']?.toString(),
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
      calorias100g: json['calories_100g'] ?? json['calorias_100g'] ?? 0,
      proteinas:
          json['proteins']?.toString() ?? json['proteinas']?.toString() ?? '',
      carboidratosLiquidos: json['net_carbs']?.toString() ??
          json['carboidratos_liquidos']?.toString() ??
          '',
      gordurasPerfil: json['fat_profile']?.toString() ??
          json['gorduras_perfil']?.toString() ??
          '',
      indiceGlicemico: json['glycemic_index']?.toString() ??
          json['indice_glicemico']?.toString() ??
          '',
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
      lista: ((json['list'] ?? json['lista']) as List? ?? [])
          .map((e) => NutrienteItem.fromJson(e))
          .toList(),
      sinergiaNutricional: json['nutritional_synergy']?.toString() ??
          json['sinergia_nutricional']?.toString() ??
          '',
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
      nome: json['name']?.toString() ?? json['nome']?.toString() ?? '',
      quantidade:
          json['amount']?.toString() ?? json['quantidade']?.toString() ?? '',
      percentualDv: ((json['dv_percent'] ?? json['percentual_dv']) is int)
          ? (json['dv_percent'] ?? json['percentual_dv'])
          : int.tryParse(
                  (json['dv_percent'] ?? json['percentual_dv'])?.toString() ??
                      '0') ??
              0,
      funcao: json['function']?.toString() ?? json['funcao']?.toString() ?? '',
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
      pontosPositivos:
          ((json['positives'] ?? json['pontos_positivos']) as List? ?? [])
              .map((e) => e.toString())
              .toList(),
      pontosNegativos:
          ((json['negatives'] ?? json['pontos_negativos']) as List? ?? [])
              .map((e) => e.toString())
              .toList(),
      vereditoIa: json['ia_verdict']?.toString() ??
          json['veredito_ia']?.toString() ??
          '',
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
      pontosPositivosCorpo: ((json['body_positives'] ??
                  json['pontos_positivos_corpo']) as List? ??
              [])
          .map((e) => e.toString())
          .toList(),
      pontosAtencaoCorpo: ((json['body_attention_points'] ??
                  json['pontos_atencao_corpo']) as List? ??
              [])
          .map((e) => e.toString())
          .toList(),
      indiceSaciedade:
          ((json['satiety_index'] ?? json['indice_saciedade']) is int)
              ? (json['satiety_index'] ?? json['indice_saciedade'])
              : int.tryParse((json['satiety_index'] ?? json['indice_saciedade'])
                          ?.toString() ??
                      '3') ??
                  3,
      impactoFocoEnergia: json['focus_energy_impact']?.toString() ??
          json['impacto_foco_energia']?.toString() ??
          '',
      momentoIdealConsumo: json['ideal_consumption_moment']?.toString() ??
          json['momento_ideal_consumo']?.toString() ??
          '',
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
      nome: json['name']?.toString() ?? json['nome']?.toString() ?? '',
      instrucoes: json['instructions']?.toString() ??
          json['instrucoes']?.toString() ??
          '',
      tempoPreparo: json['prep_time']?.toString() ??
          json['tempo_preparo']?.toString() ??
          '15 min',
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
      preservacaoNutrientes: json['nutrient_preservation']?.toString() ??
          json['preservacao_nutrientes']?.toString() ??
          '',
      smartSwap: json['smart_swap']?.toString() ?? '',
      dicaEspecialista: json['expert_tip']?.toString() ??
          json['dica_especialista']?.toString() ??
          '',
    );
  }
}
