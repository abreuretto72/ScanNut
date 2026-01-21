/// ============================================================================
/// 🛡️ COMPONENTE BLINDADO (V104 - ATOMIC SYNC)
/// Este módulo utiliza o protocolo de sincronização atômica V104.
/// Gerenciamento de estado: HiveAtomicManager
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/pet_event.dart';
import '../../../core/services/hive_atomic_manager.dart';

class PetEventService {
  static final PetEventService _instance = PetEventService._internal();
  factory PetEventService() => _instance;
  PetEventService._internal();

  static const String _boxName = 'pet_events';
  Box<PetEvent>? _box;

  static bool get isInitialized => _instance._box != null && _instance._box!.isOpen;

  // 🛡️ [V104] ATOMIC READY CHECK
  // static method to ensure service is ready before UI attempts access
  static Future<void> ensureReady() async {
     await _instance.init();
  }

  Future<void> init({HiveCipher? cipher}) async {
    if (_box != null && _box!.isOpen) return;
    
    // 🛡️ [V104] ATOMIC MANAGER DELEGATION
    try {
        _box = await HiveAtomicManager().ensureBoxOpen<PetEvent>(_boxName, cipher: cipher);
        debugPrint('✅ [V104] PetEventService initialized via Atomic Manager.');
    } catch (e) {
        debugPrint('❌ [V104] Critical: Failed to open Pet Event Box: $e. Attempting Atomic Reset...');
        try {
           await HiveAtomicManager().recreateBox<PetEvent>(_boxName, cipher: cipher);
           _box = await HiveAtomicManager().ensureBoxOpen<PetEvent>(_boxName, cipher: cipher);
           debugPrint('✅ [V104] PetEventService recovered via Atomic Reset.');
        } catch (resetErr) {
           debugPrint('☠️ [V104] FATAL: Could not recover PetEvent Box: $resetErr');
           rethrow;
        }
    }
  }

  Box<PetEvent> get box {
    if (_box == null || !_box!.isOpen) {
      // 🛡️ [V104] FAIL-SAFE ACCESS
      // If accessed before init, try one last sync attempt
      throw Exception('PetEventService not initialized. Use ensureReady() first.'); 
    }
    return _box!;
  }

  // Create
  Future<void> addEvent(PetEvent event) async {
    debugPrint('TRACE [A]: Preparando para salvar análise');
    if (_box == null || !_box!.isOpen) {
      debugPrint('TRACE [B]: Alerta! Box fechada. Reabrindo de emergência...');
      await init(); // Chamada do init() que gerencia a abertura segura
    }
    
    final boxToUse = box;
    debugPrint('TRACE [C]: Box pronta. Gravando dados...');
    
    await boxToUse.put(event.id, event);
    await boxToUse.flush(); // FORCE DISK WRITE
    debugPrint('TRACE [D]: Dados gravados com sucesso.');
  }

  // Read
  List<PetEvent> getAllEvents() {
    return box.values.toList();
  }

  List<PetEvent> getEventsByPet(String petId) {
    return box.values.where((event) => event.petId == petId).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  List<PetEvent> getUpcomingEvents(String petId) {
    final now = DateTime.now();
    return box.values
        .where((event) =>
            event.petId == petId &&
            !event.completed &&
            event.dateTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  List<PetEvent> getPastEvents(String petId) {
    final now = DateTime.now();
    return box.values
        .where((event) =>
            event.petId == petId &&
            event.dateTime.isBefore(now))
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  List<PetEvent> getEventsByType(String petId, EventType type) {
    return box.values
        .where((event) => event.petId == petId && event.type == type)
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  List<PetEvent> getEventsForDate(String petId, DateTime date) {
    return box.values
        .where((event) =>
            event.petId == petId &&
            event.dateTime.year == date.year &&
            event.dateTime.month == date.month &&
            event.dateTime.day == date.day)
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  // Get events that need notification soon
  List<PetEvent> getEventsNeedingNotification() {
    final now = DateTime.now();
    return box.values.where((event) {
      if (event.completed) return false;
      final notificationTime = event.dateTime.subtract(
        Duration(minutes: event.notificationMinutes),
      );
      return notificationTime.isBefore(now) && event.dateTime.isAfter(now);
    }).toList();
  }

  // Update
  Future<void> updateEvent(PetEvent event) async {
    await box.put(event.id, event);
    await box.flush(); // FORCE DISK WRITE
    debugPrint('✅ Event updated and flushed: ${event.title}');
  }

  Future<void> markAsCompleted(String eventId) async {
    final event = box.get(eventId);
    if (event != null) {
      event.completed = true;
      await event.save();
      await box.flush(); // FORCE DISK WRITE
      debugPrint('✅ Event marked as completed and flushed: ${event.title}');
    }
  }

  // Delete
  Future<void> deleteEvent(String eventId) async {
    await box.delete(eventId);
    await box.flush(); // FORCE DISK WRITE
    debugPrint('🗑️ Event deleted and flushed: $eventId');
  }

  Future<void> deleteAllEventsForPet(String petId) async {
    final events = getEventsByPet(petId);
    for (var event in events) {
      await box.delete(event.id);
    }
    await box.flush(); // FORCE DISK WRITE
    debugPrint('🗑️ All events deleted for UUID: $petId');
  }

  // Statistics
  int getEventCount(String petId) {
    return getEventsByPet(petId).length;
  }

  int getUpcomingEventCount(String petId) {
    return getUpcomingEvents(petId).length;
  }

  Map<EventType, int> getEventCountByType(String petId) {
    final events = getEventsByPet(petId);
    final counts = <EventType, int>{};
    
    for (var type in EventType.values) {
      counts[type] = events.where((e) => e.type == type).length;
    }
    
    return counts;
  }

  // Close
  Future<void> close() async {
    await _box?.close();
  }
}
