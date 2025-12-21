/// Medical attachment types
enum MedicalAttachmentType {
  receita,    // Prescription
  exame,      // Exam/Test
  laudo,      // Medical report/diagnosis
}

/// Medical attachment model
class MedicalAttachment {
  final String id;
  final String petName;
  final MedicalAttachmentType type;
  final String fileUrl;
  final DateTime date;
  final String summary;
  final Map<String, dynamic> extractedDetails;
  final VeterinarianInfo? veterinarian;
  final DateTime addedAt;
  final double? ocrConfidence;

  MedicalAttachment({
    required this.id,
    required this.petName,
    required this.type,
    required this.fileUrl,
    required this.date,
    required this.summary,
    required this.extractedDetails,
    this.veterinarian,
    required this.addedAt,
    this.ocrConfidence,
  });

  factory MedicalAttachment.fromJson(Map<String, dynamic> json) {
    return MedicalAttachment(
      id: json['id'] as String,
      petName: json['pet_name'] as String,
      type: _parseType(json['type'] as String),
      fileUrl: json['file_url'] as String,
      date: DateTime.parse(json['date'] as String),
      summary: json['summary'] as String,
      extractedDetails: json['extracted_details'] as Map<String, dynamic>,
      veterinarian: json['veterinarian'] != null
          ? VeterinarianInfo.fromJson(json['veterinarian'] as Map<String, dynamic>)
          : null,
      addedAt: DateTime.parse(json['added_at'] as String),
      ocrConfidence: (json['ocr_confidence'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_name': petName,
      'type': type.name.toUpperCase(),
      'file_url': fileUrl,
      'date': date.toIso8601String(),
      'summary': summary,
      'extracted_details': extractedDetails,
      if (veterinarian != null) 'veterinarian': veterinarian!.toJson(),
      'added_at': addedAt.toIso8601String(),
      if (ocrConfidence != null) 'ocr_confidence': ocrConfidence,
    };
  }

  static MedicalAttachmentType _parseType(String typeStr) {
    switch (typeStr.toUpperCase()) {
      case 'RECEITA':
        return MedicalAttachmentType.receita;
      case 'EXAME':
        return MedicalAttachmentType.exame;
      case 'LAUDO':
        return MedicalAttachmentType.laudo;
      default:
        return MedicalAttachmentType.laudo;
    }
  }

  /// Get icon for attachment type
  String getIcon() {
    switch (type) {
      case MedicalAttachmentType.receita:
        return '💊';
      case MedicalAttachmentType.exame:
        return '🔬';
      case MedicalAttachmentType.laudo:
        return '📋';
    }
  }

  /// Get color for attachment type
  String getColorHex() {
    switch (type) {
      case MedicalAttachmentType.receita:
        return '#00E676'; // Green
      case MedicalAttachmentType.exame:
        return '#2196F3'; // Blue
      case MedicalAttachmentType.laudo:
        return '#FF9800'; // Orange
    }
  }
}

/// Veterinarian information
class VeterinarianInfo {
  final String name;
  final String? crmv;

  VeterinarianInfo({
    required this.name,
    this.crmv,
  });

  factory VeterinarianInfo.fromJson(Map<String, dynamic> json) {
    return VeterinarianInfo(
      name: json['name'] as String,
      crmv: json['crmv'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (crmv != null) 'crmv': crmv,
    };
  }
}

/// Medication from prescription
class Medication {
  final String nome;
  final String dosagem;
  final String frequencia;
  final String duracao;
  final String via;
  final String? observacoes;

  Medication({
    required this.nome,
    required this.dosagem,
    required this.frequencia,
    required this.duracao,
    required this.via,
    this.observacoes,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      nome: json['nome'] as String,
      dosagem: json['dosagem'] as String,
      frequencia: json['frequencia'] as String,
      duracao: json['duracao'] as String,
      via: json['via'] as String,
      observacoes: json['observacoes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'dosagem': dosagem,
      'frequencia': frequencia,
      'duracao': duracao,
      'via': via,
      if (observacoes != null) 'observacoes': observacoes,
    };
  }
}

/// Exam result
class ExamResult {
  final String parametro;
  final String valor;
  final String referencia;
  final String status; // NORMAL, ALTERADO

  ExamResult({
    required this.parametro,
    required this.valor,
    required this.referencia,
    required this.status,
  });

  factory ExamResult.fromJson(Map<String, dynamic> json) {
    return ExamResult(
      parametro: json['parametro'] as String,
      valor: json['valor'] as String,
      referencia: json['referencia'] as String,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'parametro': parametro,
      'valor': valor,
      'referencia': referencia,
      'status': status,
    };
  }

  bool isAbnormal() => status.toUpperCase() == 'ALTERADO';
}

/// Response from medical attachment processing
class MedicalAttachmentResponse {
  final String targetPet;
  final MedicalAttachment attachment;
  final AgendaSyncData? agendaSync;
  final TimelineEvent? timelineEvent;
  final Map<String, dynamic> metadata;

  MedicalAttachmentResponse({
    required this.targetPet,
    required this.attachment,
    this.agendaSync,
    this.timelineEvent,
    required this.metadata,
  });

  factory MedicalAttachmentResponse.fromJson(Map<String, dynamic> json) {
    return MedicalAttachmentResponse(
      targetPet: json['target_pet'] as String,
      attachment: MedicalAttachment.fromJson(json['attachment_data'] as Map<String, dynamic>),
      agendaSync: json['sync_agenda'] != null
          ? AgendaSyncData.fromJson(json['sync_agenda'] as Map<String, dynamic>)
          : null,
      timelineEvent: json['timeline_event'] != null
          ? TimelineEvent.fromJson(json['timeline_event'] as Map<String, dynamic>)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>,
    );
  }
}

/// Agenda sync data for medication reminders
class AgendaSyncData {
  final bool createReminder;
  final List<MedicationReminder> reminders;

  AgendaSyncData({
    required this.createReminder,
    required this.reminders,
  });

  factory AgendaSyncData.fromJson(Map<String, dynamic> json) {
    return AgendaSyncData(
      createReminder: json['create_reminder'] as bool? ?? false,
      reminders: (json['reminders'] as List?)
              ?.map((r) => MedicationReminder.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Medication reminder
class MedicationReminder {
  final String title;
  final String description;
  final String frequency;
  final int durationDays;
  final DateTime startDate;

  MedicationReminder({
    required this.title,
    required this.description,
    required this.frequency,
    required this.durationDays,
    required this.startDate,
  });

  factory MedicationReminder.fromJson(Map<String, dynamic> json) {
    return MedicationReminder(
      title: json['title'] as String,
      description: json['description'] as String,
      frequency: json['frequency'] as String,
      durationDays: json['duration_days'] as int,
      startDate: DateTime.parse(json['start_date'] as String),
    );
  }
}

/// Timeline event
class TimelineEvent {
  final String title;
  final DateTime date;
  final String category; // medication, exam, diagnosis

  TimelineEvent({
    required this.title,
    required this.date,
    required this.category,
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      title: json['title'] as String,
      date: DateTime.parse(json['date'] as String),
      category: json['category'] as String,
    );
  }
}
