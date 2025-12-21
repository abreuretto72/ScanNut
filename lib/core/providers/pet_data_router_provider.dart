import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/pet_data_router.dart';
import '../../features/pet/services/pet_profile_service.dart';
import '../../features/pet/services/pet_health_service.dart';
import '../services/meal_history_service.dart';
import '../../features/pet/services/pet_event_service.dart';

// Individual service providers
final petProfileServiceProvider = Provider<PetProfileService>((ref) {
  return PetProfileService();
});

final petHealthServiceProvider = Provider<PetHealthService>((ref) {
  return PetHealthService();
});

final mealHistoryServiceProvider = Provider<MealHistoryService>((ref) {
  return MealHistoryService();
});

// Pet Data Router provider - combines all services
final petDataRouterProvider = Provider<PetDataRouter>((ref) {
  return PetDataRouter(
    profileService: ref.read(petProfileServiceProvider),
    healthService: ref.read(petHealthServiceProvider),
    mealService: ref.read(mealHistoryServiceProvider),
    eventService: PetEventService(), // Already has its own provider
  );
});
