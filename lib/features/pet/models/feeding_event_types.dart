/// Feeding Event Types for Pet Module
/// Defines all possible feeding occurrences, behavioral events, and clinical intercurrences
///
/// This file is part of the ScanNut Pet Module feeding event system.
/// It provides a comprehensive classification system for all feeding-related events.

enum FeedingEventGroup {
  normalFeeding,
  behavioralOccurrence,
  digestiveIntercurrence,
  intestinalIntercurrence,
  nutritionalMetabolic,
  therapeuticDiet,
}

enum FeedingEventType {
  // GRUPO 1 — Eventos normais de alimentação
  mealCompleted('normal_feeding', FeedingEventGroup.normalFeeding),
  mealDelayed('normal_feeding', FeedingEventGroup.normalFeeding),
  mealSkipped('normal_feeding', FeedingEventGroup.normalFeeding),
  foodChange('normal_feeding', FeedingEventGroup.normalFeeding),
  reducedIntake('normal_feeding', FeedingEventGroup.normalFeeding),
  increasedAppetite('normal_feeding', FeedingEventGroup.normalFeeding),

  // GRUPO 2 — Ocorrências comportamentais
  reluctantToEat('behavioral', FeedingEventGroup.behavioralOccurrence),
  eatsSlowly('behavioral', FeedingEventGroup.behavioralOccurrence),
  eatsTooFast('behavioral', FeedingEventGroup.behavioralOccurrence),
  selectiveEating('behavioral', FeedingEventGroup.behavioralOccurrence),
  hidesFood('behavioral', FeedingEventGroup.behavioralOccurrence),
  aggressiveWhileEating('behavioral', FeedingEventGroup.behavioralOccurrence),
  anxietyWhileEating('behavioral', FeedingEventGroup.behavioralOccurrence),

  // GRUPO 3 — Intercorrências digestivas imediatas
  vomitingImmediate(
      'digestive_intercurrence', FeedingEventGroup.digestiveIntercurrence),
  vomitingDelayed(
      'digestive_intercurrence', FeedingEventGroup.digestiveIntercurrence),
  nausea('digestive_intercurrence', FeedingEventGroup.digestiveIntercurrence),
  choking('digestive_intercurrence', FeedingEventGroup.digestiveIntercurrence),
  regurgitation(
      'digestive_intercurrence', FeedingEventGroup.digestiveIntercurrence),
  excessiveFlatulence(
      'digestive_intercurrence', FeedingEventGroup.digestiveIntercurrence),
  apparentAbdominalPain(
      'digestive_intercurrence', FeedingEventGroup.digestiveIntercurrence),

  // GRUPO 4 — Intercorrências intestinais associadas
  diarrhea(
      'intestinal_intercurrence', FeedingEventGroup.intestinalIntercurrence),
  softStool(
      'intestinal_intercurrence', FeedingEventGroup.intestinalIntercurrence),
  constipation(
      'intestinal_intercurrence', FeedingEventGroup.intestinalIntercurrence),
  stoolWithMucus(
      'intestinal_intercurrence', FeedingEventGroup.intestinalIntercurrence),
  stoolWithBlood(
      'intestinal_intercurrence', FeedingEventGroup.intestinalIntercurrence),
  stoolColorChange(
      'intestinal_intercurrence', FeedingEventGroup.intestinalIntercurrence),
  abnormalStoolOdor(
      'intestinal_intercurrence', FeedingEventGroup.intestinalIntercurrence),

  // GRUPO 5 — Ocorrências nutricionais / metabólicas
  weightGain('nutritional_metabolic', FeedingEventGroup.nutritionalMetabolic),
  weightLoss('nutritional_metabolic', FeedingEventGroup.nutritionalMetabolic),
  excessiveThirst(
      'nutritional_metabolic', FeedingEventGroup.nutritionalMetabolic),
  lowWaterIntake(
      'nutritional_metabolic', FeedingEventGroup.nutritionalMetabolic),
  suspectedFoodIntolerance(
      'nutritional_metabolic', FeedingEventGroup.nutritionalMetabolic),
  suspectedFoodAllergy(
      'nutritional_metabolic', FeedingEventGroup.nutritionalMetabolic),
  adverseFoodReaction(
      'nutritional_metabolic', FeedingEventGroup.nutritionalMetabolic),

  // GRUPO 6 — Eventos clínicos ligados à dieta terapêutica
  dietNotTolerated('therapeutic_diet', FeedingEventGroup.therapeuticDiet),
  therapeuticDietRefusal('therapeutic_diet', FeedingEventGroup.therapeuticDiet),
  clinicalImprovementWithDiet(
      'therapeutic_diet', FeedingEventGroup.therapeuticDiet),
  clinicalWorseningAfterMeal(
      'therapeutic_diet', FeedingEventGroup.therapeuticDiet),
  needForDietAdjustment('therapeutic_diet', FeedingEventGroup.therapeuticDiet),
  feedingWithMedication('therapeutic_diet', FeedingEventGroup.therapeuticDiet),
  assistedFeeding('therapeutic_diet', FeedingEventGroup.therapeuticDiet);

  final String category;
  final FeedingEventGroup group;

  const FeedingEventType(this.category, this.group);

  /// Returns true if this event type is a clinical intercurrence
  bool get isClinicalIntercurrence {
    return group == FeedingEventGroup.digestiveIntercurrence ||
        group == FeedingEventGroup.intestinalIntercurrence ||
        group == FeedingEventGroup.therapeuticDiet;
  }

  /// Returns severity level for clinical events
  String get defaultSeverity {
    if (!isClinicalIntercurrence) return 'none';

    // High severity events
    if (this == FeedingEventType.vomitingImmediate ||
        this == FeedingEventType.choking ||
        this == FeedingEventType.stoolWithBlood ||
        this == FeedingEventType.apparentAbdominalPain) {
      return 'severe';
    }

    // Moderate severity events
    if (this == FeedingEventType.diarrhea ||
        this == FeedingEventType.vomitingDelayed ||
        this == FeedingEventType.regurgitation ||
        this == FeedingEventType.suspectedFoodAllergy) {
      return 'moderate';
    }

    return 'mild';
  }

  /// Get icon for event type
  String get icon {
    switch (group) {
      case FeedingEventGroup.normalFeeding:
        return '🍽️';
      case FeedingEventGroup.behavioralOccurrence:
        return '🐾';
      case FeedingEventGroup.digestiveIntercurrence:
        return '⚠️';
      case FeedingEventGroup.intestinalIntercurrence:
        return '🩺';
      case FeedingEventGroup.nutritionalMetabolic:
        return '📊';
      case FeedingEventGroup.therapeuticDiet:
        return '💊';
    }
  }
}

/// Extension to get FeedingEventType from string (for backward compatibility)
extension FeedingEventTypeExtension on String {
  FeedingEventType? toFeedingEventType() {
    try {
      return FeedingEventType.values.firstWhere(
        (e) => e.name == this,
      );
    } catch (_) {
      return null;
    }
  }
}
