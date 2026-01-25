/// Health Event Types for Pet Module
/// Defines all possible health occurrences organized in 7 clinical groups
///
/// This file provides a comprehensive classification system for health events

enum HealthEventGroup {
  dailyMonitoring, // Grupo A: Monitoramento Diário
  acuteSymptoms, // Grupo B: Sintomas Agudos
  infectiousDisease, // Grupo C: Infeccioso/Parasitário
  dermatological, // Grupo D: Dermatológico
  mobility, // Grupo E: Mobilidade/Ortopédico
  neurological, // Grupo F: Neurológico/Sensorial
  treatment, // Grupo G: Tratamento/Procedimento
}

enum HealthEventType {
  // GRUPO A — Monitoramento Diário
  temperature_check(
      'daily_monitoring', HealthEventGroup.dailyMonitoring, false),
  weight_check('daily_monitoring', HealthEventGroup.dailyMonitoring, false),
  appetite_monitoring(
      'daily_monitoring', HealthEventGroup.dailyMonitoring, false),
  hydration_check('daily_monitoring', HealthEventGroup.dailyMonitoring, false),
  energy_level('daily_monitoring', HealthEventGroup.dailyMonitoring, false),
  behavior_observation(
      'daily_monitoring', HealthEventGroup.dailyMonitoring, false),

  // GRUPO B — Sintomas Agudos
  fever('acute_symptoms', HealthEventGroup.acuteSymptoms, false),
  vomiting('acute_symptoms', HealthEventGroup.acuteSymptoms, true),
  diarrhea('acute_symptoms', HealthEventGroup.acuteSymptoms, true),
  lethargy('acute_symptoms', HealthEventGroup.acuteSymptoms, false),
  loss_of_appetite('acute_symptoms', HealthEventGroup.acuteSymptoms, false),
  excessive_thirst('acute_symptoms', HealthEventGroup.acuteSymptoms, false),
  difficulty_breathing('acute_symptoms', HealthEventGroup.acuteSymptoms, true),
  coughing('acute_symptoms', HealthEventGroup.acuteSymptoms, false),
  sneezing('acute_symptoms', HealthEventGroup.acuteSymptoms, false),
  nasal_discharge('acute_symptoms', HealthEventGroup.acuteSymptoms, false),

  // GRUPO C — Infeccioso/Parasitário
  suspected_infection('infectious', HealthEventGroup.infectiousDisease, true),
  wound_infection('infectious', HealthEventGroup.infectiousDisease, true),
  ear_infection('infectious', HealthEventGroup.infectiousDisease, false),
  eye_infection('infectious', HealthEventGroup.infectiousDisease, false),
  urinary_infection('infectious', HealthEventGroup.infectiousDisease, true),
  parasite_detected('infectious', HealthEventGroup.infectiousDisease, false),
  tick_found('infectious', HealthEventGroup.infectiousDisease, false),
  flea_infestation('infectious', HealthEventGroup.infectiousDisease, false),

  // GRUPO D — Dermatológico
  skin_rash('dermatological', HealthEventGroup.dermatological, false),
  itching('dermatological', HealthEventGroup.dermatological, false),
  hair_loss('dermatological', HealthEventGroup.dermatological, false),
  hot_spot('dermatological', HealthEventGroup.dermatological, false),
  wound('dermatological', HealthEventGroup.dermatological, true),
  abscess('dermatological', HealthEventGroup.dermatological, true),
  allergic_reaction('dermatological', HealthEventGroup.dermatological, true),
  swelling('dermatological', HealthEventGroup.dermatological, true),

  // GRUPO E — Mobilidade/Ortopédico
  limping('mobility', HealthEventGroup.mobility, false),
  joint_pain('mobility', HealthEventGroup.mobility, false),
  difficulty_walking('mobility', HealthEventGroup.mobility, true),
  stiffness('mobility', HealthEventGroup.mobility, false),
  muscle_weakness('mobility', HealthEventGroup.mobility, false),
  fall('mobility', HealthEventGroup.mobility, true),
  fracture_suspected('mobility', HealthEventGroup.mobility, true),

  // GRUPO F — Neurológico/Sensorial
  seizure('neurological', HealthEventGroup.neurological, true),
  tremors('neurological', HealthEventGroup.neurological, true),
  disorientation('neurological', HealthEventGroup.neurological, true),
  loss_of_balance('neurological', HealthEventGroup.neurological, true),
  vision_problems('neurological', HealthEventGroup.neurological, false),
  hearing_problems('neurological', HealthEventGroup.neurological, false),
  head_tilt('neurological', HealthEventGroup.neurological, true),

  // GRUPO G — Tratamento/Procedimento
  medication_administered('treatment', HealthEventGroup.treatment, false),
  vaccine_given('treatment', HealthEventGroup.treatment, false),
  wound_cleaning('treatment', HealthEventGroup.treatment, false),
  bandage_change('treatment', HealthEventGroup.treatment, false),
  vet_visit('treatment', HealthEventGroup.treatment, false),
  surgery('treatment', HealthEventGroup.treatment, false),
  emergency_care('treatment', HealthEventGroup.treatment, true),
  hospitalization('treatment', HealthEventGroup.treatment, true);

  final String category;
  final HealthEventGroup group;
  final bool isEmergency;

  const HealthEventType(this.category, this.group, this.isEmergency);

  /// Returns true if this event requires immediate veterinary attention
  bool get requiresImmediateAttention => isEmergency;

  /// Get default severity for emergency events
  String get defaultSeverity {
    if (isEmergency) return 'severe';
    return 'mild';
  }

  /// Get icon emoji for event type
  String get icon {
    switch (group) {
      case HealthEventGroup.dailyMonitoring:
        return '📊';
      case HealthEventGroup.acuteSymptoms:
        return '🌡️';
      case HealthEventGroup.infectiousDisease:
        return '🦠';
      case HealthEventGroup.dermatological:
        return '🩹';
      case HealthEventGroup.mobility:
        return '🦴';
      case HealthEventGroup.neurological:
        return '🧠';
      case HealthEventGroup.treatment:
        return '💉';
    }
  }
}

/// Extension to get HealthEventType from string (for backward compatibility)
extension HealthEventTypeExtension on String {
  HealthEventType? toHealthEventType() {
    try {
      return HealthEventType.values.firstWhere(
        (e) => e.name == this,
      );
    } catch (_) {
      return null;
    }
  }
}
