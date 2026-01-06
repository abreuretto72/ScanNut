import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/pet_event_model.dart';
import 'pet_event_repository.dart';

class PetEventsSelfTest {
  static Future<void> run() async {
    if (!kDebugMode) return;
    
    debugPrint('🧪 PET_EVENTS_TEST: Starting Self Test...');
    final repo = PetEventRepository();
    final petId = 'test_pet_${DateTime.now().millisecondsSinceEpoch}';

    try {
      // Ensure initialized (usually done by SimpleAuthService, but for tests we ensure)
      await repo.init();
      
      // 1. Add events for each group
      final groups = ['food', 'health', 'elimination', 'grooming', 'activity', 'behavior', 'schedule', 'media', 'metrics'];
      for (final g in groups) {
         final event = PetEventModel(
           id: const Uuid().v4(),
           petId: petId,
           group: g,
           type: 'test',
           title: 'Test Event $g',
           notes: 'This is a test event for group $g',
           timestamp: DateTime.now(),
           data: {'test_key': 'test_value'},
           createdAt: DateTime.now(),
           updatedAt: DateTime.now(),
         );
         await repo.addEvent(event);
      }
      debugPrint('✅ PET_EVENTS_TEST: 9 events added.');

      // 2. List today's count
      final counts = repo.listTodayCountByGroup(petId);
      debugPrint('📊 PET_EVENTS_TEST: Today counts: $counts');
      if (counts.length != 9) throw Exception('Expected 9 groups in counts, got ${counts.length}');

      // 3. List and Update
      final events = repo.listEventsByPet(petId);
      if (events.isEmpty) throw Exception('No events found for test pet');
      
      final first = events.first;
      final updated = first.copyWith(title: 'Updated Test Event');
      await repo.updateEvent(updated);
      debugPrint('✅ PET_EVENTS_TEST: Event updated.');

      // 4. Soft Delete
      await repo.deleteEventSoft(first.id);
      final afterDelete = repo.listEventsByPet(petId);
      if (afterDelete.length != 8) throw Exception('Expected 8 events after soft delete, got ${afterDelete.length}');
      debugPrint('✅ PET_EVENTS_TEST: Event soft-deleted.');

      debugPrint('✨ PET_EVENTS_TEST: Completed successfully!');
    } catch (e, stack) {
      debugPrint('❌ PET_EVENTS_TEST: FAILED: $e\n$stack');
    }
  }
}
