import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/pet_data_envelope.dart';
import '../../features/pet/services/pet_profile_service.dart';
import '../../features/pet/services/pet_health_service.dart';
import '../services/meal_history_service.dart';
import '../../features/pet/services/pet_event_service.dart';

/// Service for automatic distribution of pet data to correct data buckets
class PetDataRouter {
  final PetProfileService _profileService;
  final PetHealthService _healthService;
  final MealHistoryService _mealService;
  final PetEventService _eventService;

  PetDataRouter({
    required PetProfileService profileService,
    required PetHealthService healthService,
    required MealHistoryService mealService,
    required PetEventService eventService,
  })  : _profileService = profileService,
        _healthService = healthService,
        _mealService = mealService,
        _eventService = eventService;

  /// Routes and saves pet data to the correct bucket based on category
  Future<bool> savePetData(Map<String, dynamic> unifiedJson) async {
    try {
      debugPrint('🔀 [PetDataRouter] Processing unified JSON...');
      
      final envelope = PetDataEnvelope.fromJson(unifiedJson);
      debugPrint('📦 Target Pet: ${envelope.targetPet}');
      debugPrint('📂 Category: ${envelope.category}');
      debugPrint('🔗 Has Existing Profile: ${envelope.metadata.hasExistingProfile}');

      switch (envelope.category) {
        case PetDataCategory.racaId:
          return await _saveRaceIdData(envelope);
        
        case PetDataCategory.saude:
          return await _saveHealthData(envelope);
        
        case PetDataCategory.cardapio:
          return await _saveMenuData(envelope);
        
        case PetDataCategory.agenda:
          return await _saveAgendaData(envelope);
        
        default:
          debugPrint('❌ Unknown category: ${envelope.category}');
          return false;
      }
    } catch (e, stackTrace) {
      debugPrint('❌❌❌ ERROR in savePetData: $e');
      debugPrint('Stack: $stackTrace');
      return false;
    }
  }

  Future<bool> _saveRaceIdData(PetDataEnvelope envelope) async {
    debugPrint('🐾 Saving RACA_ID data for ${envelope.targetPet}');
    // TODO: Implement when PetProfileService is ready
    // await _profileService.saveOrUpdateProfile(envelope.targetPet, envelope.dataPayload);
    return true;
  }

  Future<bool> _saveHealthData(PetDataEnvelope envelope) async {
    debugPrint('🏥 Saving SAUDE data for ${envelope.targetPet}');
    
    // Check if breed data exists for personalization
    if (envelope.metadata.linkedBreedData != null) {
      debugPrint('🔗 Using linked breed data for diagnosis');
    }
    
    // TODO: Implement when PetHealthService is ready
    // await _healthService.addHealthRecord(envelope.targetPet, envelope.dataPayload);
    return true;
  }

  Future<bool> _saveMenuData(PetDataEnvelope envelope) async {
    debugPrint('🍖 Saving CARDAPIO data for ${envelope.targetPet}');
    
    // Save menu to MealHistoryService
    await _mealService.saveIngredients(
      envelope.targetPet, 
      envelope.dataPayload['plano_semanal'] ?? [],
    );
    
    return true;
  }

  Future<bool> _saveAgendaData(PetDataEnvelope envelope) async {
    debugPrint('📅 Saving AGENDA data for ${envelope.targetPet}');
    
    // TODO: Implement when we have structured agenda events in payload
    // final events = envelope.dataPayload['events'] as List?;
    // if (events != null) {
    //   for (var event in events) {
    //     await _eventService.addEvent(PetEvent.fromJson(event));
    //   }
    // }
    
    return true;
  }

  /// Query unified pet data across all 4 buckets
  Future<Map<String, dynamic>> getUnifiedPetData(String petName) async {
    debugPrint('🔍 Querying unified data for: $petName');
    
    return {
      'pet_name': petName,
      'raca_id': {}, // await _profileService.getProfile(petName),
      'saude': [], // await _healthService.getHealthRecords(petName),
      'cardapio': await _mealService.getRecentIngredients(petName),
      'agenda': await _eventService.getEventsByPet(petName),
    };
  }
}
