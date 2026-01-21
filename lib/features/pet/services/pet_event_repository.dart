import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/pet_event_model.dart';
import '../models/attachment_model.dart';
import '../models/pet_event.dart';
import 'pet_event_service.dart';
import 'pet_indexing_service.dart';
import '../../../core/services/hive_atomic_manager.dart';

class PetEventRepository {
  static final PetEventRepository _instance = PetEventRepository._internal();
  factory PetEventRepository() => _instance;
  PetEventRepository._internal();

  static const String _boxName = 'pet_events_journal';
  Box<PetEventModel>? _box;

  Future<void> init({HiveCipher? cipher}) async {
    if (_box != null && _box!.isOpen) return;
    try {
      if (!Hive.isAdapterRegistered(40)) {
        Hive.registerAdapter(AttachmentModelAdapter());
      }
      if (!Hive.isAdapterRegistered(41)) {
        Hive.registerAdapter(PetEventModelAdapter());
      }
      
      _box = await HiveAtomicManager().ensureBoxOpen<PetEventModel>(_boxName, cipher: cipher);
      
      // 🚀 MIGRATION SCRIPT: Reset volatile cache paths to avoid 'Photo Not Found' errors
      await _sanitizeOrphanedCachePaths();
      
      debugPrint('✅ PET_EVENTS: Repository initialized. Items: ${_box?.length}');
    } catch (e, stack) {
      debugPrint('❌ PET_EVENTS: Failed to initialize Repository: $e\n$stack');
    }
  }

  /// 🧹 RESET TÉCNICO: Limpeza de Paths Órfãos (Cache) conforme PROMPT V6
  Future<void> _sanitizeOrphanedCachePaths() async {
    if (_box == null) return;
    
    bool changedGlobal = false;
    for (var key in _box!.keys) {
      final event = _box!.get(key);
      if (event != null) {
        bool eventChanged = false;
        final updatedAttachments = event.attachments.map((a) {
          if (a.path.contains('/cache/') || a.path.contains('/tmp/')) {
            eventChanged = true;
            debugPrint('🧹 [SANITIZER] Clearing volatile path for event ${event.id}: ${a.path}');
            // We return a "placeholder" or null-path as per user instruction (Icone neutro)
            // But AttachmentModel.path is usually required. Let's set it to an empty but detectable string.
            return a.copyWith(path: 'REMOVED_BY_SANITIZER');
          }
          return a;
        }).toList();

        if (eventChanged) {
          await _box!.put(key, event.copyWith(attachments: updatedAttachments));
          changedGlobal = true;
        }
      }
    }
    if (changedGlobal) {
      await _box!.flush();
      debugPrint('✨ [SANITIZER] Pet Event pathways cleaned and reset to safe defaults.');
    }
  }

  Box<PetEventModel> get box => _openBox;

  Box<PetEventModel> get _openBox {
    if (_box == null || !_box!.isOpen) {
      throw Exception('PetEventRepository not initialized. Call init() first.');
    }
    return _box!;
  }

  ValueListenable<Box<PetEventModel>> get listenable => _openBox.listenable();

  Future<void> addEvent(PetEventModel event) async {
    try {
      await _openBox.put(event.id, event);
      await _openBox.flush();
      debugPrint('✅ PET_EVENTS: Event saved: ${event.id} [${event.group}]');

      // 🔄 MIRROR TO GLOBAL AGENDA
      await _mirrorToAgenda(event);

      // 🧠 AUTOMATIC INDEXING (MUO Logic)
      // If the event is NOT an automatic index (differentiated by idx_ prefix), we index it
      if (!event.id.startsWith('idx_')) {
          try {
              final indexer = PetIndexingService();
              // Don't await to avoid recursive loop if indexing engine uses repository (which it does)
              // But we have the 'idx_' check to prevent loop.
              await indexer.indexOccurrence(
                  petId: event.petId,
                  petName: event.petId, // Defaulting to ID as Name
                  group: event.group,
                  title: event.title,
                  notes: event.notes,
                  extraData: {
                    'original_event_id': event.id,
                    'type': event.type,
                  },
              );
          } catch (e) {
              debugPrint('⚠️ Occurrence indexing failed: $e');
          }
      }
    } catch (e) {
      debugPrint('❌ PET_EVENTS: Save error: $e');
      rethrow;
    }
  }

  /// 🔄 CONSOLIDATION MOTOR: Mirrors journal entry to Global Agenda
  Future<void> _mirrorToAgenda(PetEventModel model) async {
    try {
      final agendaService = PetEventService();
      await agendaService.init();

      EventType type = EventType.other;
      switch (model.group) {
        case 'food': type = EventType.food; break;
        case 'health': type = EventType.veterinary; break;
        case 'elimination': type = EventType.elimination; break;
        case 'grooming': type = EventType.grooming; break;
        case 'activity': type = EventType.activity; break;
        case 'behavior': type = EventType.behavior; break;
        case 'medication': type = EventType.medication; break;
        case 'documents': type = EventType.documents; break;
        case 'exams': type = EventType.exams; break;
        case 'dentistry': type = EventType.dentistry; break;
        case 'metrics': type = EventType.metrics; break;
        case 'media': type = EventType.media; break;
        case 'allergies': type = EventType.veterinary; break; // Health related
        case 'schedule': type = EventType.other; break;
        default: type = EventType.other; break;
      }

      final agendaEvent = PetEvent(
        id: model.id, // Keep same ID for easy sync/delete
        petId: model.petId,
        petName: model.data['pet_name']?.toString() ?? model.petId,
        title: model.title,
        type: type,
        dateTime: model.timestamp,
        notes: model.notes,
      );

      await agendaService.addEvent(agendaEvent);
      debugPrint('🔗 PET_EVENTS: Agenda Mirrored for ${model.id}');
    } catch (e) {
       debugPrint('⚠️ PET_EVENTS: Mirror Agenda failed: $e');
    }
  }

  List<PetEventModel> listEventsByPet(String petId, {DateTime? from, DateTime? to}) {
    try {
      // 🛡️ HYBRID QUERY: Matches either ID (UUID) OR Name (Legacy/Data)
      var events = _openBox.values.where((e) => 
        (e.petId == petId || e.data['pet_name'] == petId) && 
        !e.isDeleted
      ).toList();
      
      if (from != null) {
        events = events.where((e) => e.timestamp.isAfter(from) || e.timestamp.isAtSameMomentAs(from)).toList();
      }
      if (to != null) {
        events = events.where((e) => e.timestamp.isBefore(to) || e.timestamp.isAtSameMomentAs(to)).toList();
      }
      
      events.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Newest first
      return events;
    } catch (e) {
      debugPrint('❌ PET_EVENTS: List error: $e');
      return [];
    }
  }

  Map<String, int> listTotalCountByGroup(String petId) {
    final counts = <String, int>{};
    final events = _openBox.values.where((e) => 
      (e.petId == petId || e.data['pet_name'] == petId) && 
      !e.isDeleted
    );

    for (var e in events) {
      counts[e.group] = (counts[e.group] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, int> listTodayCountByGroup(String petId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final counts = <String, int>{};
    final events = _openBox.values.where((e) => 
      (e.petId == petId || e.data['pet_name'] == petId) && 
      !e.isDeleted &&
      (e.timestamp.isAfter(today) || e.timestamp.isAtSameMomentAs(today)) &&
      e.timestamp.isBefore(tomorrow)
    );

    for (var e in events) {
      counts[e.group] = (counts[e.group] ?? 0) + 1;
    }
    return counts;
  }

  Future<void> updateEvent(PetEventModel event) async {
    try {
      await _openBox.put(event.id, event);
      await _openBox.flush();
      debugPrint('✅ PET_EVENTS: Event updated: ${event.id}');
      await _mirrorToAgenda(event);
    } catch (e) {
       debugPrint('❌ PET_EVENTS: Update error: $e');
       rethrow;
    }
  }

  Future<void> deleteEventSoft(String eventId) async {
    final event = _openBox.get(eventId);
    if (event != null) {
      final deleted = event.copyWith(isDeleted: true);
      await _openBox.put(eventId, deleted);
      await _openBox.flush();
      debugPrint('🗑️ PET_EVENTS: Event soft-deleted: $eventId');
      
      // Cleanup Agenda
      try {
        final agendaService = PetEventService();
        await agendaService.init();
        await agendaService.deleteEvent(eventId);
      } catch (e) {
        debugPrint('⚠️ PET_EVENTS: Failed to cleanup mirroring agenda: $e');
      }
    }
  }

  Future<void> deleteEventsByWeek(String petId, DateTime weekStart) async {
    final weekEnd = weekStart.add(const Duration(days: 7));
    final toDelete = _openBox.values.where((e) => 
      e.petId == petId && 
      (e.timestamp.isAfter(weekStart) || e.timestamp.isAtSameMomentAs(weekStart)) &&
      e.timestamp.isBefore(weekEnd)
    ).toList();

    for (var e in toDelete) {
      await deleteEventSoft(e.id);
    }
    debugPrint('🗑️ PET_EVENTS: Weekly events soft-deleted for $petId starting $weekStart');
  }
}
