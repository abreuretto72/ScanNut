/// ARQUITETURA DE DADOS DO PET (PROTOCOLO SCANNUT)
/// 4 Conjuntos de Dados Vinculados, indexados pela Chave Primária `petName`.

class PetModel {
  final String id; // Gerado ou igual ao nome normalizado
  final PetIdentitySet identity;
  final PetHealthSet health;
  final PetMenuSet menu;
  final PetAgendaSet agenda;
  final DateTime lastUpdated;

  PetModel({
    required this.id,
    required this.identity,
    required this.health,
    required this.menu,
    required this.agenda,
    required this.lastUpdated,
  });

  // Factory para criar um novo Pet a partir do zero
  factory PetModel.create({
    required String name,
    required String species,
    String? breed,
    String? sex,
    bool isNeutered = false,
  }) {
    return PetModel(
      id: 'pet_${name.trim().toLowerCase()}',
      identity: PetIdentitySet(
        name: name,
        species: species,
        breed: breed,
        sex: sex,
        isNeutered: isNeutered,
      ),
      health: PetHealthSet.empty(),
      menu: PetMenuSet.empty(),
      agenda: PetAgendaSet.empty(),
      lastUpdated: DateTime.now(),
    );
  }

  // 🛡️ Pattern copyWith para atualizações imutáveis e atômicas
  PetModel copyWith({
    String? id,
    PetIdentitySet? identity,
    PetHealthSet? health,
    PetMenuSet? menu,
    PetAgendaSet? agenda,
    DateTime? lastUpdated,
  }) {
    return PetModel(
      id: id ?? this.id,
      identity: identity ?? this.identity,
      health: health ?? this.health,
      menu: menu ?? this.menu,
      agenda: agenda ?? this.agenda,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'identity': identity.toJson(),
        'health': health.toJson(),
        'menu': menu.toJson(),
        'agenda': agenda.toJson(),
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory PetModel.fromJson(Map<String, dynamic> json) => PetModel(
        id: json['id'],
        identity: PetIdentitySet.fromJson(json['identity']),
        health: PetHealthSet.fromJson(json['health']),
        menu: PetMenuSet.fromJson(json['menu']),
        agenda: PetAgendaSet.fromJson(json['agenda']),
        lastUpdated: DateTime.parse(json['lastUpdated']),
      );
}

// 1. CONJUNTO: RAÇA & ID (ESTÁTICO/IDENTIDADE)
class PetIdentitySet {
  final String name;
  final String species; // Canina, Felina
  final String? breed; // Vinculada a predisposições
  final String? sex;
  final bool isNeutered;
  final String? microchip;
  final DateTime? birthDate;
  // 🛡️ V2.5: Novos Campos Biométricos
  final String? longevity; // Longevidade estimada
  final String? originRegion; // Região de origem
  final String? lineage; // Linhagem
  final String? morphology; // Morfologia

  PetIdentitySet({
    required this.name,
    required this.species,
    this.breed,
    this.sex,
    this.isNeutered = false,
    this.microchip,
    this.birthDate,
    this.longevity,
    this.originRegion,
    this.lineage,
    this.morphology,
  });

  PetIdentitySet copyWith({
    String? name,
    String? species,
    String? breed,
    String? sex,
    bool? isNeutered,
    String? microchip,
    DateTime? birthDate,
    String? longevity,
    String? originRegion,
    String? lineage,
    String? morphology,
  }) {
    return PetIdentitySet(
      name: name ?? this.name,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      sex: sex ?? this.sex,
      isNeutered: isNeutered ?? this.isNeutered,
      microchip: microchip ?? this.microchip,
      birthDate: birthDate ?? this.birthDate,
      longevity: longevity ?? this.longevity,
      originRegion: originRegion ?? this.originRegion,
      lineage: lineage ?? this.lineage,
      morphology: morphology ?? this.morphology,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'species': species,
        'breed': breed,
        'sex': sex,
        'isNeutered': isNeutered,
        'microchip': microchip,
        'birthDate': birthDate?.toIso8601String(),
        'longevity': longevity,
        'originRegion': originRegion,
        'lineage': lineage,
        'morphology': morphology,
      };

  factory PetIdentitySet.fromJson(Map<String, dynamic> json) => PetIdentitySet(
        name: json['name'],
        species: json['species'],
        breed: json['breed'],
        sex: json['sex'],
        isNeutered: json['isNeutered'] ?? false,
        microchip: json['microchip'],
        birthDate: json['birthDate'] != null
            ? DateTime.parse(json['birthDate'])
            : null,
        longevity: json['longevity'],
        originRegion: json['originRegion'],
        lineage: json['lineage'],
        morphology: json['morphology'],
      );
}

// 2. CONJUNTO: SAÚDE (TEMPORAL & DOCUMENTAL)
class PetHealthSet {
  final List<BiometricEntry> biometricsHistory;
  final List<ConditionEntry> conditions; // Feridas, diagnósticos
  final List<MedicalAttachment> attachments;
  // 🛡️ V2.5: Predisposições Genéticas
  final List<String> predispositions;

  PetHealthSet({
    required this.biometricsHistory,
    required this.conditions,
    required this.attachments,
    this.predispositions = const [],
  });

  PetHealthSet copyWith({
    List<BiometricEntry>? biometricsHistory,
    List<ConditionEntry>? conditions,
    List<MedicalAttachment>? attachments,
    List<String>? predispositions,
  }) {
    return PetHealthSet(
      biometricsHistory: biometricsHistory ?? this.biometricsHistory,
      conditions: conditions ?? this.conditions,
      attachments: attachments ?? this.attachments,
      predispositions: predispositions ?? this.predispositions,
    );
  }

  factory PetHealthSet.empty() => PetHealthSet(
        biometricsHistory: [],
        conditions: [],
        attachments: [],
        predispositions: [],
      );

  Map<String, dynamic> toJson() => {
        'biometricsHistory': biometricsHistory.map((e) => e.toJson()).toList(),
        'conditions': conditions.map((e) => e.toJson()).toList(),
        'attachments': attachments.map((e) => e.toJson()).toList(),
        'predispositions': predispositions,
      };

  factory PetHealthSet.fromJson(Map<String, dynamic> json) => PetHealthSet(
        biometricsHistory: (json['biometricsHistory'] as List?)
                ?.map((e) => BiometricEntry.fromJson(e))
                .toList() ??
            [],
        conditions: (json['conditions'] as List?)
                ?.map((e) => ConditionEntry.fromJson(e))
                .toList() ??
            [],
        attachments: (json['attachments'] as List?)
                ?.map((e) => MedicalAttachment.fromJson(e))
                .toList() ??
            [],
        predispositions: List<String>.from(json['predispositions'] ?? []),
      );

  // Helper to add biometric data without overwriting
  void addBiometric(double weight, int? conditionScore) {
    biometricsHistory.add(BiometricEntry(
      date: DateTime.now(),
      weightKg: weight,
      bodyConditionScore: conditionScore,
    ));
    // Sort logic could be added here
  }
}

class BiometricEntry {
  final DateTime date;
  final double weightKg;
  final int? bodyConditionScore; // 1-9 scale

  BiometricEntry(
      {required this.date, required this.weightKg, this.bodyConditionScore});

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'weightKg': weightKg,
        'bodyConditionScore': bodyConditionScore,
      };

  factory BiometricEntry.fromJson(Map<String, dynamic> json) => BiometricEntry(
        date: DateTime.parse(json['date']),
        weightKg: json['weightKg'].toDouble(),
        bodyConditionScore: json['bodyConditionScore'],
      );
}

class ConditionEntry {
  final String title;
  final String status; // Resolvido, Em Tratamento, Crônico
  final DateTime diagnosedAt;
  final String? severity; // Verde, Amarelo, Laranja, Vermelho
  final String? notes;

  ConditionEntry({
    required this.title,
    required this.status,
    required this.diagnosedAt,
    this.severity,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'status': status,
        'diagnosedAt': diagnosedAt.toIso8601String(),
        'severity': severity,
        'notes': notes,
      };

  factory ConditionEntry.fromJson(Map<String, dynamic> json) => ConditionEntry(
        title: json['title'],
        status: json['status'],
        diagnosedAt: DateTime.parse(json['diagnosedAt']),
        severity: json['severity'],
        notes: json['notes'],
      );
}

class MedicalAttachment {
  final String type; // Receita, Exame, Laudo, Foto
  final String filePath;
  final Map<String, dynamic>? ocrData;
  final DateTime addedAt;

  MedicalAttachment({
    required this.type,
    required this.filePath,
    this.ocrData,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'filePath': filePath,
        'ocrData': ocrData,
        'addedAt': addedAt.toIso8601String(),
      };

  factory MedicalAttachment.fromJson(Map<String, dynamic> json) =>
      MedicalAttachment(
        type: json['type'],
        filePath: json['filePath'],
        ocrData: json['ocrData'],
        addedAt: DateTime.parse(json['addedAt']),
      );
}

// 3. CONJUNTO: CARDÁPIO (ALIMENTAÇÃO NATURAL - AN)
class PetMenuSet {
  final String dietType; // AN Crua com Ossos, AN Cozida, etc. NÃO RAÇÃO.
  final List<MenuCycle> history;
  final MenuCycle? currentPlan;
  final List<String> restrictions;
  final List<String> preferences;

  PetMenuSet({
    this.dietType = 'Alimentação Natural',
    required this.history,
    this.currentPlan,
    required this.restrictions,
    required this.preferences,
  });

  PetMenuSet copyWith({
    String? dietType,
    List<MenuCycle>? history,
    MenuCycle? currentPlan,
    List<String>? restrictions,
    List<String>? preferences,
  }) {
    return PetMenuSet(
      dietType: dietType ?? this.dietType,
      history: history ?? this.history,
      currentPlan: currentPlan ?? this.currentPlan,
      restrictions: restrictions ?? this.restrictions,
      preferences: preferences ?? this.preferences,
    );
  }

  factory PetMenuSet.empty() => PetMenuSet(
        history: [],
        restrictions: [],
        preferences: [],
      );

  Map<String, dynamic> toJson() => {
        'dietType': dietType,
        'history': history.map((e) => e.toJson()).toList(),
        'currentPlan': currentPlan?.toJson(),
        'restrictions': restrictions,
        'preferences': preferences,
      };

  factory PetMenuSet.fromJson(Map<String, dynamic> json) => PetMenuSet(
        dietType: json['dietType'] ?? 'Alimentação Natural',
        history: (json['history'] as List?)
                ?.map((e) => MenuCycle.fromJson(e))
                .toList() ??
            [],
        currentPlan: json['currentPlan'] != null
            ? MenuCycle.fromJson(json['currentPlan'])
            : null,
        restrictions: List<String>.from(json['restrictions'] ?? []),
        preferences: List<String>.from(json['preferences'] ?? []),
      );
}

class MenuCycle {
  final String weekId; // Ex: 2025-W50
  final List<String> proteins;
  final List<String> vegetables;
  final List<String> supplements;
  final Map<String, dynamic> caloricGoal;

  MenuCycle({
    required this.weekId,
    required this.proteins,
    required this.vegetables,
    required this.supplements,
    required this.caloricGoal,
  });

  Map<String, dynamic> toJson() => {
        'weekId': weekId,
        'proteins': proteins,
        'vegetables': vegetables,
        'supplements': supplements,
        'caloricGoal': caloricGoal,
      };

  factory MenuCycle.fromJson(Map<String, dynamic> json) => MenuCycle(
        weekId: json['weekId'],
        proteins: List<String>.from(json['proteins'] ?? []),
        vegetables: List<String>.from(json['vegetables'] ?? []),
        supplements: List<String>.from(json['supplements'] ?? []),
        caloricGoal: Map<String, dynamic>.from(json['caloricGoal'] ?? {}),
      );
}

// 4. CONJUNTO: AGENDA (PREVENTIVA & ROTINA)
class PetAgendaSet {
  final Map<String, DateTime> vaccines; // Nome: Data da última dose
  final List<AgendaEvent> events;

  PetAgendaSet({
    required this.vaccines,
    required this.events,
  });

  PetAgendaSet copyWith({
    Map<String, DateTime>? vaccines,
    List<AgendaEvent>? events,
  }) {
    return PetAgendaSet(
      vaccines: vaccines ?? this.vaccines,
      events: events ?? this.events,
    );
  }

  factory PetAgendaSet.empty() => PetAgendaSet(
        vaccines: {},
        events: [],
      );

  Map<String, dynamic> toJson() => {
        'vaccines': vaccines.map((k, v) => MapEntry(k, v.toIso8601String())),
        'events': events.map((e) => e.toJson()).toList(),
      };

  factory PetAgendaSet.fromJson(Map<String, dynamic> json) {
    final vaccinesMap = <String, DateTime>{};
    if (json['vaccines'] != null) {
      (json['vaccines'] as Map).forEach((k, v) {
        vaccinesMap[k.toString()] = DateTime.parse(v);
      });
    }

    return PetAgendaSet(
      vaccines: vaccinesMap,
      events: (json['events'] as List?)
              ?.map((e) => AgendaEvent.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class AgendaEvent {
  final String title;
  final String category; // Vacina, Medicamento, Higiene, Veterinário
  final DateTime date;
  final bool isRecurring;
  final String? recurrenceRule;

  AgendaEvent({
    required this.title,
    required this.category,
    required this.date,
    this.isRecurring = false,
    this.recurrenceRule,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'category': category,
        'date': date.toIso8601String(),
        'isRecurring': isRecurring,
        'recurrenceRule': recurrenceRule,
      };

  factory AgendaEvent.fromJson(Map<String, dynamic> json) => AgendaEvent(
        title: json['title'],
        category: json['category'],
        date: DateTime.parse(json['date']),
        isRecurring: json['isRecurring'] ?? false,
        recurrenceRule: json['recurrenceRule'],
      );
}
