/// Feeding Event Constants and Utilities
/// Provides helper methods for feeding event classification and display
/// 
/// This file complements feeding_event_types.dart with practical utilities

import 'package:flutter/material.dart';
import 'feeding_event_types.dart';

/// Helper class for feeding event utilities
class FeedingEventHelper {
  
  /// Get Material Icon for event type
  static IconData getIconForEventType(FeedingEventType eventType) {
    switch (eventType.group) {
      case FeedingEventGroup.normalFeeding:
        return Icons.restaurant_menu;
      case FeedingEventGroup.behavioralOccurrence:
        return Icons.pets;
      case FeedingEventGroup.digestiveIntercurrence:
        return Icons.warning_amber_rounded;
      case FeedingEventGroup.intestinalIntercurrence:
        return Icons.health_and_safety;
      case FeedingEventGroup.nutritionalMetabolic:
        return Icons.monitor_weight;
      case FeedingEventGroup.therapeuticDiet:
        return Icons.medical_services;
    }
  }

  /// Get specific icon for individual event types
  static IconData getSpecificIcon(FeedingEventType eventType) {
    switch (eventType) {
      // Normal Feeding
      case FeedingEventType.mealCompleted:
        return Icons.check_circle;
      case FeedingEventType.mealDelayed:
        return Icons.schedule;
      case FeedingEventType.mealSkipped:
        return Icons.cancel;
      case FeedingEventType.foodChange:
        return Icons.swap_horiz;
      case FeedingEventType.reducedIntake:
        return Icons.trending_down;
      case FeedingEventType.increasedAppetite:
        return Icons.trending_up;

      // Behavioral
      case FeedingEventType.reluctantToEat:
        return Icons.sentiment_dissatisfied;
      case FeedingEventType.eatsSlowly:
        return Icons.slow_motion_video;
      case FeedingEventType.eatsTooFast:
        return Icons.fast_forward;
      case FeedingEventType.selectiveEating:
        return Icons.filter_list;
      case FeedingEventType.hidesFood:
        return Icons.visibility_off;
      case FeedingEventType.aggressiveWhileEating:
        return Icons.warning;
      case FeedingEventType.anxietyWhileEating:
        return Icons.psychology;

      // Digestive Intercurrences
      case FeedingEventType.vomitingImmediate:
        return Icons.emergency;
      case FeedingEventType.vomitingDelayed:
        return Icons.access_time;
      case FeedingEventType.nausea:
        return Icons.sick;
      case FeedingEventType.choking:
        return Icons.error_outline;
      case FeedingEventType.regurgitation:
        return Icons.replay;
      case FeedingEventType.excessiveFlatulence:
        return Icons.air;
      case FeedingEventType.apparentAbdominalPain:
        return Icons.healing;

      // Intestinal Intercurrences
      case FeedingEventType.diarrhea:
        return Icons.water_drop;
      case FeedingEventType.softStool:
        return Icons.opacity;
      case FeedingEventType.constipation:
        return Icons.block;
      case FeedingEventType.stoolWithMucus:
        return Icons.bubble_chart;
      case FeedingEventType.stoolWithBlood:
        return Icons.bloodtype;
      case FeedingEventType.stoolColorChange:
        return Icons.palette;
      case FeedingEventType.abnormalStoolOdor:
        return Icons.air_outlined;

      // Nutritional/Metabolic
      case FeedingEventType.weightGain:
        return Icons.arrow_upward;
      case FeedingEventType.weightLoss:
        return Icons.arrow_downward;
      case FeedingEventType.excessiveThirst:
        return Icons.local_drink;
      case FeedingEventType.lowWaterIntake:
        return Icons.water_damage;
      case FeedingEventType.suspectedFoodIntolerance:
        return Icons.report_problem;
      case FeedingEventType.suspectedFoodAllergy:
        return Icons.coronavirus;
      case FeedingEventType.adverseFoodReaction:
        return Icons.dangerous;

      // Therapeutic Diet
      case FeedingEventType.dietNotTolerated:
        return Icons.thumb_down;
      case FeedingEventType.therapeuticDietRefusal:
        return Icons.do_not_disturb;
      case FeedingEventType.clinicalImprovementWithDiet:
        return Icons.thumb_up;
      case FeedingEventType.clinicalWorseningAfterMeal:
        return Icons.trending_down;
      case FeedingEventType.needForDietAdjustment:
        return Icons.tune;
      case FeedingEventType.feedingWithMedication:
        return Icons.medication;
      case FeedingEventType.assistedFeeding:
        return Icons.support;
    }
  }

  /// Get color for event severity
  static Color getColorForSeverity(String severity) {
    switch (severity.toLowerCase()) {
      case 'mild':
      case 'leve':
        return Colors.yellow.shade700;
      case 'moderate':
      case 'moderada':
        return Colors.orange.shade700;
      case 'severe':
      case 'grave':
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }

  /// Get color for event group
  static Color getColorForGroup(FeedingEventGroup group) {
    switch (group) {
      case FeedingEventGroup.normalFeeding:
        return Colors.green.shade400;
      case FeedingEventGroup.behavioralOccurrence:
        return Colors.blue.shade400;
      case FeedingEventGroup.digestiveIntercurrence:
        return Colors.orange.shade600;
      case FeedingEventGroup.intestinalIntercurrence:
        return Colors.red.shade600;
      case FeedingEventGroup.nutritionalMetabolic:
        return Colors.purple.shade400;
      case FeedingEventGroup.therapeuticDiet:
        return Colors.teal.shade400;
    }
  }

  /// Check if event requires immediate veterinary attention
  static bool requiresImmediateAttention(FeedingEventType eventType, String? severity) {
    // Critical events
    final criticalEvents = [
      FeedingEventType.choking,
      FeedingEventType.stoolWithBlood,
      FeedingEventType.apparentAbdominalPain,
    ];

    if (criticalEvents.contains(eventType)) return true;

    // Severe events
    if (severity?.toLowerCase() == 'severe' || severity?.toLowerCase() == 'grave') {
      return eventType.isClinicalIntercurrence;
    }

    return false;
  }

  /// Get recommended action for event type
  static String getRecommendedAction(FeedingEventType eventType, String? severity) {
    if (requiresImmediateAttention(eventType, severity)) {
      return 'URGENTE: Consultar veterinário imediatamente';
    }

    if (eventType.isClinicalIntercurrence) {
      if (severity?.toLowerCase() == 'moderate' || severity?.toLowerCase() == 'moderada') {
        return 'Agendar consulta veterinária em 24-48h';
      }
      return 'Monitorar e registrar. Consultar vet se persistir';
    }

    return 'Continuar monitorando';
  }

  /// Get all event types for a specific group
  static List<FeedingEventType> getEventTypesForGroup(FeedingEventGroup group) {
    return FeedingEventType.values.where((e) => e.group == group).toList();
  }

  /// Convert string to FeedingEventType (safe)
  static FeedingEventType? fromString(String? value) {
    if (value == null) return null;
    try {
      return FeedingEventType.values.firstWhere(
        (e) => e.name == value,
      );
    } catch (_) {
      return null;
    }
  }

  /// Get display priority (for sorting in lists)
  /// Higher number = higher priority (shown first)
  static int getDisplayPriority(FeedingEventType eventType) {
    if (eventType.isClinicalIntercurrence) {
      switch (eventType.defaultSeverity) {
        case 'severe':
          return 100;
        case 'moderate':
          return 75;
        case 'mild':
          return 50;
        default:
          return 25;
      }
    }
    return 10; // Normal events
  }
}

/// Extension methods for FeedingEventType
extension FeedingEventTypeExtensions on FeedingEventType {
  /// Get Material Icon
  IconData get icon => FeedingEventHelper.getSpecificIcon(this);
  
  /// Get group icon
  IconData get groupIcon => FeedingEventHelper.getIconForEventType(this);
  
  /// Get group color
  Color get groupColor => FeedingEventHelper.getColorForGroup(group);
  
  /// Get display priority
  int get displayPriority => FeedingEventHelper.getDisplayPriority(this);
  
  /// Check if requires immediate attention
  bool requiresImmediateAttention([String? severity]) {
    return FeedingEventHelper.requiresImmediateAttention(this, severity);
  }
  
  /// Get recommended action
  String getRecommendedAction([String? severity]) {
    return FeedingEventHelper.getRecommendedAction(this, severity);
  }
}
