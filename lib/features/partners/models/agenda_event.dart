import 'package:flutter/material.dart';

/// Categoria de evento da agenda
class EventCategory {
  final String name;
  final String label;
  final IconData icon;
  final Color color;

  const EventCategory._(this.name, this.label, this.icon, this.color);

  // Categoria especial para ocorrências atípicas
  static const ocorrencias = EventCategory._('ocorrencias', '⚠️ Ocorrências', Icons.warning_amber, Color(0xFFFF6B6B));
  
  // Categorias de Saúde
  static const saude = EventCategory._('saude', 'Saúde', Icons.medical_services, Color(0xFFE91E63));
  static const consulta = EventCategory._('consulta', 'Consulta', Icons.local_hospital, Color(0xFF9C27B0));
  static const vacina = EventCategory._('vacina', 'Vacina', Icons.vaccines, Color(0xFF3F51B5));
  static const cirurgia = EventCategory._('cirurgia', 'Cirurgia', Icons.healing, Color(0xFFFF5722));
  static const exame = EventCategory._('exame', 'Exame', Icons.science, Color(0xFF00BCD4));
  static const emergencia = EventCategory._('emergencia', 'Emergência', Icons.emergency, Color(0xFFD32F2F));
  
  // Categorias de Estética
  static const estetica = EventCategory._('estetica', 'Estética', Icons.content_cut, Color(0xFFFF9800));
  static const banho = EventCategory._('banho', 'Banho', Icons.shower, Color(0xFF2196F3));
  static const tosa = EventCategory._('tosa', 'Tosa', Icons.cut, Color(0xFF03A9F4));
  static const unhas = EventCategory._('unhas', 'Unhas', Icons.cut, Color(0xFF00ACC1));
  static const orelhas = EventCategory._('orelhas', 'Limpeza de Orelhas', Icons.hearing, Color(0xFF0097A7));
  
  // Categorias de Cuidados
  static const cuidados = EventCategory._('cuidados', 'Cuidados Diários', Icons.pets, Color(0xFF4CAF50));
  static const passeador = EventCategory._('passeador', 'Passeador', Icons.directions_walk, Color(0xFF8BC34A));
  static const daycare = EventCategory._('daycare', 'Daycare', Icons.home_work, Color(0xFFCDDC39));
  static const adestramento = EventCategory._('adestramento', 'Adestramento', Icons.psychology, Color(0xFF9E9D24));
  static const hospedagem = EventCategory._('hospedagem', 'Hospedagem', Icons.hotel, Color(0xFFFFC107));
  
  // Categorias de Extras
  static const educacao = EventCategory._('educacao', 'Educação', Icons.school, Color(0xFF673AB7));
  static const extras = EventCategory._('extras', 'Extras', Icons.add_circle, Color(0xFF607D8B));
  static const transporte = EventCategory._('transporte', 'Transporte', Icons.directions_car, Color(0xFF795548));
  static const nutricao = EventCategory._('nutricao', 'Nutrição', Icons.restaurant, Color(0xFFFF5722));
  static const fisioterapia = EventCategory._('fisioterapia', 'Fisioterapia', Icons.accessibility_new, Color(0xFF7B1FA2));
  static const remedios = EventCategory._('remedios', 'Remédios', Icons.medication, Color(0xFFE91E63));

  static const List<EventCategory> values = [
    ocorrencias, // Primeira categoria - destaque
    saude, consulta, vacina, cirurgia, exame, emergencia,
    estetica, banho, tosa, unhas, orelhas,
    cuidados, passeador, daycare, adestramento, hospedagem,
    educacao, extras, transporte, nutricao, fisioterapia, remedios,
  ];

  static EventCategory fromString(String value) {
    return values.firstWhere(
      (e) => e.name == value,
      orElse: () => extras,
    );
  }
}

/// Modelo de evento da agenda
class AgendaEvent {
  final String id;
  final String partnerId;
  final String? petId;
  final EventCategory category;
  final String title;
  final String description;
  final DateTime dateTime;
  final String? attendant; // Nome do atendente/veterinário
  final List<String> attachments; // Caminhos dos arquivos anexados
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  AgendaEvent({
    required this.id,
    required this.partnerId,
    this.petId,
    required this.category,
    required this.title,
    required this.description,
    required this.dateTime,
    this.attendant,
    this.attachments = const [],
    required this.createdAt,
    this.metadata = const {},
  });

  factory AgendaEvent.fromJson(Map<String, dynamic> json) {
    return AgendaEvent(
      id: json['id'] ?? '',
      partnerId: json['partnerId'] ?? json['partner_id'] ?? '',
      petId: json['petId'] ?? json['pet_id'],
      category: EventCategory.fromString(json['category'] ?? 'extras'),
      title: json['title'] ?? '',
      description: json['description'] ?? json['content'] ?? '',
      dateTime: DateTime.parse(json['dateTime'] ?? json['date'] ?? DateTime.now().toIso8601String()),
      attendant: json['attendant'],
      attachments: List<String>.from(json['attachments'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partnerId': partnerId,
      'petId': petId,
      'category': category.name,
      'title': title,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
      'attendant': attendant,
      'attachments': attachments,
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
      // Compatibilidade com formato antigo
      'partner_id': partnerId,
      'pet_id': petId,
      'content': description,
      'date': dateTime.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'type': 'event',
    };
  }

  AgendaEvent copyWith({
    String? id,
    String? partnerId,
    String? petId,
    EventCategory? category,
    String? title,
    String? description,
    DateTime? dateTime,
    String? attendant,
    List<String>? attachments,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return AgendaEvent(
      id: id ?? this.id,
      partnerId: partnerId ?? this.partnerId,
      petId: petId ?? this.petId,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      attendant: attendant ?? this.attendant,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }
}
