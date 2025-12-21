import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/pet_event.dart';

class PetEventService {
  static const String _boxName = 'pet_events';
  Box<PetEvent>? _box;

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<PetEvent>(_boxName);
    } else {
      _box = Hive.box<PetEvent>(_boxName);
    }
  }

  Box<PetEvent> get box {
    if (_box == null || !_box!.isOpen) {
      throw Exception('PetEventService not initialized. Call init() first.');
    }
    return _box!;
  }

  // Create
  Future<void> addEvent(PetEvent event) async {
    await box.put(event.id, event);
    debugPrint('✅ Event added: ${event.title} for ${event.petName}');
  }

  // Read
  List<PetEvent> getAllEvents() {
    return box.values.toList();
  }

  List<PetEvent> getEventsByPet(String petName) {
    return box.values.where((event) => event.petName == petName).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  List<PetEvent> getUpcomingEvents(String petName) {
    final now = DateTime.now();
    return box.values
        .where((event) =>
            event.petName == petName &&
            !event.completed &&
            event.dateTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  List<PetEvent> getPastEvents(String petName) {
    final now = DateTime.now();
    return box.values
        .where((event) =>
            event.petName == petName &&
            event.dateTime.isBefore(now))
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  List<PetEvent> getEventsByType(String petName, EventType type) {
    return box.values
        .where((event) => event.petName == petName && event.type == type)
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  List<PetEvent> getEventsForDate(String petName, DateTime date) {
    return box.values
        .where((event) =>
            event.petName == petName &&
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
    debugPrint('✅ Event updated: ${event.title}');
  }

  Future<void> markAsCompleted(String eventId) async {
    final event = box.get(eventId);
    if (event != null) {
      event.completed = true;
      await event.save();
      debugPrint('✅ Event marked as completed: ${event.title}');
    }
  }

  // Delete
  Future<void> deleteEvent(String eventId) async {
    await box.delete(eventId);
    debugPrint('🗑️ Event deleted: $eventId');
  }

  Future<void> deleteAllEventsForPet(String petName) async {
    final events = getEventsByPet(petName);
    for (var event in events) {
      await box.delete(event.id);
    }
    debugPrint('🗑️ All events deleted for: $petName');
  }

  // Statistics
  int getEventCount(String petName) {
    return getEventsByPet(petName).length;
  }

  int getUpcomingEventCount(String petName) {
    return getUpcomingEvents(petName).length;
  }

  Map<EventType, int> getEventCountByType(String petName) {
    final events = getEventsByPet(petName);
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
