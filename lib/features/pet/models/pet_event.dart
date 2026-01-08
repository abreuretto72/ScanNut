import 'package:hive/hive.dart';
import 'package:scannut/l10n/app_localizations.dart';

part 'pet_event.g.dart';

@HiveType(typeId: 4)
enum EventType {
  @HiveField(0)
  vaccine,
  @HiveField(1)
  bath,
  @HiveField(2)
  grooming,
  @HiveField(3)
  veterinary,
  @HiveField(4)
  medication,
  @HiveField(5)
  other,
  @HiveField(6)
  food,
  @HiveField(7)
  elimination,
  @HiveField(8)
  activity,
  @HiveField(9)
  behavior,
  @HiveField(10)
  media,
  @HiveField(11)
  metrics,
  @HiveField(12)
  documents,
  @HiveField(13)
  exams,
  @HiveField(14)
  dentistry,
  @HiveField(15)
  parasite,
  @HiveField(16)
  surgery,
}

@HiveType(typeId: 5)
enum RecurrenceType {
  @HiveField(0)
  once,
  @HiveField(1)
  daily,
  @HiveField(2)
  weekly,
  @HiveField(3)
  monthly,
  @HiveField(4)
  yearly,
}

@HiveType(typeId: 6)
class PetEvent extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String petName;

  @HiveField(2)
  String title;

  @HiveField(3)
  EventType type;

  @HiveField(4)
  DateTime dateTime;

  @HiveField(5)
  RecurrenceType recurrence;

  @HiveField(6)
  int notificationMinutes; // Minutes before event to notify

  @HiveField(7)
  String? notes;

  @HiveField(8)
  bool completed;

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  String? attendant;

  @HiveField(11)
  String? partnerId;

  PetEvent({
    required this.id,
    required this.petName,
    required this.title,
    required this.type,
    required this.dateTime,
    this.recurrence = RecurrenceType.once,
    this.notificationMinutes = 1440, // 1 day default
    this.notes,
    this.completed = false,
    DateTime? createdAt,
    this.attendant,
    this.partnerId,
  }) : createdAt = createdAt ?? DateTime.now();

  // Helper methods
  String get typeLabel => _getLegacyTypeLabel(); // Keep for legacy if needed

  String _getLegacyTypeLabel() {
    switch (type) {
      case EventType.vaccine: return 'Vacina';
      case EventType.bath: return 'Banho';
      case EventType.grooming: return 'Tosa';
      case EventType.veterinary: return 'Veterinário';
      case EventType.medication: return 'Medicamento';
      case EventType.food: return 'Alimentação';
      case EventType.elimination: return 'Fezes/Urina';
      case EventType.activity: return 'Atividade';
      case EventType.behavior: return 'Comportamento';
      case EventType.media: return 'Mídia';
      case EventType.metrics: return 'Métricas';
      case EventType.documents: return 'Documentos';
      case EventType.exams: return 'Exames';
      case EventType.dentistry: return 'Odontologia';
      case EventType.parasite: return 'Parasitas';
      case EventType.surgery: return 'Cirurgia';
      case EventType.other: return 'Outro';
      default: return 'Outro';
    }
  }

  String getLocalizedTypeLabel(AppLocalizations strings) {
    switch (type) {
      case EventType.vaccine: return strings.eventVaccine;
      case EventType.bath: return strings.eventBath;
      case EventType.grooming: return strings.eventGrooming;
      case EventType.veterinary: return strings.eventVeterinary;
      case EventType.medication: return strings.eventMedication;
      case EventType.food: return strings.petEvent_group_food;
      case EventType.elimination: return strings.petEvent_group_elimination;
      case EventType.activity: return strings.petEvent_group_activity;
      case EventType.behavior: return strings.petEvent_group_behavior;
      case EventType.media: return strings.petEvent_group_media;
      case EventType.metrics: return strings.petEvent_group_metrics;
      case EventType.documents: return strings.petEvent_group_documents ?? 'Documentos';
      case EventType.exams: return strings.petEvent_group_exams ?? 'Exames';
      case EventType.dentistry: return strings.petEvent_group_dentistry ?? 'Dentição';
      case EventType.parasite: return 'Antiparasitário';
      case EventType.surgery: return 'Cirurgia';
      case EventType.other: return strings.eventOther;
      default: return strings.eventOther;
    }
  }

  String get typeEmoji {
    switch (type) {
      case EventType.vaccine: return '💉';
      case EventType.bath: return '🛁';
      case EventType.grooming: return '✂️';
      case EventType.veterinary: return '🏥';
      case EventType.medication: return '💊';
      case EventType.food: return '🍴';
      case EventType.elimination: return '🚽';
      case EventType.activity: return '🐕';
      case EventType.behavior: return '🧠';
      case EventType.media: return '📸';
      case EventType.metrics: return '📏';
      case EventType.documents: return '📄';
      case EventType.exams: return '🧪';
      case EventType.dentistry: return '🦷';
      case EventType.parasite: return '🐛';
      case EventType.surgery: return '🔪';
      case EventType.other: return '📌';
      default: return '📌';
    }
  }

  String get recurrenceLabel {
    switch (recurrence) {
      case RecurrenceType.once:
        return 'Única';
      case RecurrenceType.daily:
        return 'Diária';
      case RecurrenceType.weekly:
        return 'Semanal';
      case RecurrenceType.monthly:
        return 'Mensal';
      case RecurrenceType.yearly:
        return 'Anual';
    }
  }

  bool get isPast => dateTime.isBefore(DateTime.now());
  bool get isToday {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  bool get isUpcoming {
    final now = DateTime.now();
    final diff = dateTime.difference(now);
    return diff.inDays >= 0 && diff.inDays <= 7;
  }

  // Get next occurrence for recurring events
  DateTime? getNextOccurrence() {
    if (recurrence == RecurrenceType.once) return null;
    
    final now = DateTime.now();
    var next = dateTime;
    
    while (next.isBefore(now)) {
      switch (recurrence) {
        case RecurrenceType.daily:
          next = next.add(const Duration(days: 1));
          break;
        case RecurrenceType.weekly:
          next = next.add(const Duration(days: 7));
          break;
        case RecurrenceType.monthly:
          next = DateTime(next.year, next.month + 1, next.day, next.hour, next.minute);
          break;
        case RecurrenceType.yearly:
          next = DateTime(next.year + 1, next.month, next.day, next.hour, next.minute);
          break;
        case RecurrenceType.once:
          return null;
      }
    }
    
    return next;
  }
}
