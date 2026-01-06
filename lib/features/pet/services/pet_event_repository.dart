import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/pet_event_model.dart';
import '../models/attachment_model.dart';

class PetEventRepository {
  static final PetEventRepository _instance = PetEventRepository._internal();
  factory PetEventRepository() => _instance;
  PetEventRepository._internal();

  static const String _boxName = 'pet_events_journal';
  Box<PetEventModel>? _box;

  Future<void> init({HiveCipher? cipher}) async {
    if (_box != null && _box!.isOpen) return;
    try {
      // Adapters are usually registered in main.dart, but we ensure here if needed
      // Check if already registered to avoid errors (typeIds 40, 41)
      if (!Hive.isAdapterRegistered(40)) {
        Hive.registerAdapter(AttachmentModelAdapter());
      }
      if (!Hive.isAdapterRegistered(41)) {
        Hive.registerAdapter(PetEventModelAdapter());
      }
      
      _box = await Hive.openBox<PetEventModel>(_boxName, encryptionCipher: cipher);
      debugPrint('✅ PET_EVENTS: Repository initialized (Box: $_boxName). Items: ${_box?.length}');
    } catch (e, stack) {
      debugPrint('❌ PET_EVENTS: Failed to initialize Repository: $e\n$stack');
    }
  }

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
    } catch (e) {
      debugPrint('❌ PET_EVENTS: Save error: $e');
      rethrow;
    }
  }

  List<PetEventModel> listEventsByPet(String petId, {DateTime? from, DateTime? to}) {
    try {
      var events = _openBox.values.where((e) => e.petId == petId && !e.isDeleted).toList();
      
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

  Map<String, int> listTodayCountByGroup(String petId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final counts = <String, int>{};
    final events = _openBox.values.where((e) => 
      e.petId == petId && 
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
