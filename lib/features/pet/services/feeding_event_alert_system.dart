/// Feeding Event Alert System
/// Implements intelligent alert rules for clinical feeding events
/// 
/// This system analyzes feeding event patterns and triggers alerts
/// when concerning combinations or frequencies are detected

import 'package:flutter/material.dart';
import '../models/pet_event_model.dart';
import '../models/feeding_event_types.dart';
import '../models/feeding_event_constants.dart';

/// Alert severity levels
enum AlertSeverity {
  info,      // Informational - no action needed
  warning,   // Warning - monitor closely
  urgent,    // Urgent - schedule vet visit
  emergency, // Emergency - immediate vet attention
}

/// Alert type
class FeedingAlert {
  final AlertSeverity severity;
  final String title;
  final String message;
  final String recommendation;
  final List<String> relatedEventIds;
  final DateTime detectedAt;
  final IconData icon;
  final Color color;

  FeedingAlert({
    required this.severity,
    required this.title,
    required this.message,
    required this.recommendation,
    required this.relatedEventIds,
    DateTime? detectedAt,
  })  : detectedAt = detectedAt ?? DateTime.now(),
        icon = _getIconForSeverity(severity),
        color = _getColorForSeverity(severity);

  static IconData _getIconForSeverity(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.info:
        return Icons.info_outline;
      case AlertSeverity.warning:
        return Icons.warning_amber;
      case AlertSeverity.urgent:
        return Icons.error_outline;
      case AlertSeverity.emergency:
        return Icons.emergency;
    }
  }

  static Color _getColorForSeverity(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.info:
        return Colors.blue;
      case AlertSeverity.warning:
        return Colors.orange;
      case AlertSeverity.urgent:
        return Colors.deepOrange;
      case AlertSeverity.emergency:
        return Colors.red;
    }
  }
}

/// Feeding Event Alert Analyzer
class FeedingEventAlertSystem {
  
  /// Analyze events and generate alerts
  static List<FeedingAlert> analyzeEvents(List<PetEventModel> events) {
    final alerts = <FeedingAlert>[];
    
    // Filter only feeding events from last 7 days
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final recentFeedingEvents = events.where((e) {
      return e.group == 'food' && 
             e.timestamp.isAfter(sevenDaysAgo) &&
             !e.isDeleted;
    }).toList();

    if (recentFeedingEvents.isEmpty) return alerts;

    // Rule 1: Vomiting + Diarrhea in same day
    alerts.addAll(_checkVomitingDiarrheaCombination(recentFeedingEvents));

    // Rule 2: Multiple vomiting episodes
    alerts.addAll(_checkRepeatedVomiting(recentFeedingEvents));

    // Rule 3: Blood in stool
    alerts.addAll(_checkBloodInStool(recentFeedingEvents));

    // Rule 4: Persistent food refusal
    alerts.addAll(_checkPersistentRefusal(recentFeedingEvents));

    // Rule 5: Weight loss pattern
    alerts.addAll(_checkWeightLossPattern(recentFeedingEvents));

    // Rule 6: Choking incidents
    alerts.addAll(_checkChokingIncidents(recentFeedingEvents));

    // Rule 7: Therapeutic diet issues
    alerts.addAll(_checkTherapeuticDietIssues(recentFeedingEvents));

    // Rule 8: Suspected allergy pattern
    alerts.addAll(_checkAllergyPattern(recentFeedingEvents));

    // Rule 9: Dehydration risk
    alerts.addAll(_checkDehydrationRisk(recentFeedingEvents));

    // Rule 10: Severe clinical events
    alerts.addAll(_checkSevereClinicalEvents(recentFeedingEvents));

    return alerts;
  }

  /// Rule 1: Vomiting + Diarrhea in same day = Emergency
  static List<FeedingAlert> _checkVomitingDiarrheaCombination(List<PetEventModel> events) {
    final alerts = <FeedingAlert>[];
    
    // Group events by date
    final eventsByDate = <DateTime, List<PetEventModel>>{};
    for (final event in events) {
      final date = DateTime(event.timestamp.year, event.timestamp.month, event.timestamp.day);
      eventsByDate.putIfAbsent(date, () => []).add(event);
    }

    // Check each day
    for (final entry in eventsByDate.entries) {
      final dayEvents = entry.value;
      final hasVomiting = dayEvents.any((e) {
        final type = e.data['feeding_event_type'] as String?;
        return type == 'vomitingImmediate' || type == 'vomitingDelayed';
      });
      final hasDiarrhea = dayEvents.any((e) {
        final type = e.data['feeding_event_type'] as String?;
        return type == 'diarrhea';
      });

      if (hasVomiting && hasDiarrhea) {
        alerts.add(FeedingAlert(
          severity: AlertSeverity.emergency,
          title: '🚨 EMERGÊNCIA: Vômito + Diarreia',
          message: 'Detectado vômito E diarreia no mesmo dia. Risco de desidratação grave.',
          recommendation: 'AÇÃO IMEDIATA: Levar ao veterinário AGORA. Risco de desidratação severa.',
          relatedEventIds: dayEvents.map((e) => e.id).toList(),
        ));
      }
    }

    return alerts;
  }

  /// Rule 2: Multiple vomiting episodes (3+ in 24h)
  static List<FeedingAlert> _checkRepeatedVomiting(List<PetEventModel> events) {
    final alerts = <FeedingAlert>[];
    final now = DateTime.now();
    final last24h = now.subtract(const Duration(hours: 24));

    final vomitingEvents = events.where((e) {
      final type = e.data['feeding_event_type'] as String?;
      return (type == 'vomitingImmediate' || type == 'vomitingDelayed') &&
             e.timestamp.isAfter(last24h);
    }).toList();

    if (vomitingEvents.length >= 3) {
      alerts.add(FeedingAlert(
        severity: AlertSeverity.urgent,
        title: '⚠️ URGENTE: Vômitos Repetidos',
        message: '${vomitingEvents.length} episódios de vômito nas últimas 24h.',
        recommendation: 'Consultar veterinário HOJE. Suspender alimentação e oferecer apenas água.',
        relatedEventIds: vomitingEvents.map((e) => e.id).toList(),
      ));
    }

    return alerts;
  }

  /// Rule 3: Blood in stool = Emergency
  static List<FeedingAlert> _checkBloodInStool(List<PetEventModel> events) {
    final alerts = <FeedingAlert>[];
    
    final bloodStoolEvents = events.where((e) {
      final type = e.data['feeding_event_type'] as String?;
      return type == 'stoolWithBlood';
    }).toList();

    if (bloodStoolEvents.isNotEmpty) {
      alerts.add(FeedingAlert(
        severity: AlertSeverity.emergency,
        title: '🚨 EMERGÊNCIA: Sangue nas Fezes',
        message: 'Detectado sangue nas fezes. Pode indicar problema grave.',
        recommendation: 'AÇÃO IMEDIATA: Levar ao veterinário AGORA. Pode ser hemorragia interna.',
        relatedEventIds: bloodStoolEvents.map((e) => e.id).toList(),
      ));
    }

    return alerts;
  }

  /// Rule 4: Persistent food refusal (3+ days)
  static List<FeedingAlert> _checkPersistentRefusal(List<PetEventModel> events) {
    final alerts = <FeedingAlert>[];
    
    // Check last 3 days for refusal pattern
    final refusalEvents = events.where((e) {
      final type = e.data['feeding_event_type'] as String?;
      final acceptance = e.data['acceptance'] as String?;
      return type == 'mealSkipped' || 
             type == 'reluctantToEat' ||
             acceptance?.toLowerCase().contains('recus') == true;
    }).toList();

    // Group by day
    final refusalDays = <DateTime>{};
    for (final event in refusalEvents) {
      final date = DateTime(event.timestamp.year, event.timestamp.month, event.timestamp.day);
      refusalDays.add(date);
    }

    if (refusalDays.length >= 3) {
      alerts.add(FeedingAlert(
        severity: AlertSeverity.urgent,
        title: '⚠️ URGENTE: Recusa Alimentar Persistente',
        message: 'Pet recusando alimento por ${refusalDays.length} dias.',
        recommendation: 'Consultar veterinário em 24h. Risco de desnutrição e doenças subjacentes.',
        relatedEventIds: refusalEvents.map((e) => e.id).toList(),
      ));
    }

    return alerts;
  }

  /// Rule 5: Weight loss pattern
  static List<FeedingAlert> _checkWeightLossPattern(List<PetEventModel> events) {
    final alerts = <FeedingAlert>[];
    
    final weightLossEvents = events.where((e) {
      final type = e.data['feeding_event_type'] as String?;
      return type == 'weightLoss';
    }).toList();

    if (weightLossEvents.length >= 2) {
      alerts.add(FeedingAlert(
        severity: AlertSeverity.warning,
        title: '⚠️ ATENÇÃO: Padrão de Perda de Peso',
        message: 'Múltiplos registros de perda de peso detectados.',
        recommendation: 'Agendar consulta veterinária. Avaliar dieta e descartar doenças.',
        relatedEventIds: weightLossEvents.map((e) => e.id).toList(),
      ));
    }

    return alerts;
  }

  /// Rule 6: Choking incidents
  static List<FeedingAlert> _checkChokingIncidents(List<PetEventModel> events) {
    final alerts = <FeedingAlert>[];
    
    final chokingEvents = events.where((e) {
      final type = e.data['feeding_event_type'] as String?;
      return type == 'choking';
    }).toList();

    if (chokingEvents.isNotEmpty) {
      alerts.add(FeedingAlert(
        severity: AlertSeverity.emergency,
        title: '🚨 EMERGÊNCIA: Engasgo Detectado',
        message: 'Episódio de engasgo registrado. Risco de asfixia.',
        recommendation: 'Se ainda engasgado: MANOBRA DE HEIMLICH. Consultar vet IMEDIATAMENTE após.',
        relatedEventIds: chokingEvents.map((e) => e.id).toList(),
      ));
    }

    return alerts;
  }

  /// Rule 7: Therapeutic diet issues
  static List<FeedingAlert> _checkTherapeuticDietIssues(List<PetEventModel> events) {
    final alerts = <FeedingAlert>[];
    
    final dietIssues = events.where((e) {
      final type = e.data['feeding_event_type'] as String?;
      return type == 'dietNotTolerated' || 
             type == 'therapeuticDietRefusal' ||
             type == 'clinicalWorseningAfterMeal';
    }).toList();

    if (dietIssues.isNotEmpty) {
      alerts.add(FeedingAlert(
        severity: AlertSeverity.urgent,
        title: '⚠️ URGENTE: Problema com Dieta Terapêutica',
        message: 'Pet não está tolerando a dieta prescrita.',
        recommendation: 'Contatar veterinário que prescreveu a dieta para ajuste URGENTE.',
        relatedEventIds: dietIssues.map((e) => e.id).toList(),
      ));
    }

    return alerts;
  }

  /// Rule 8: Suspected allergy pattern
  static List<FeedingAlert> _checkAllergyPattern(List<PetEventModel> events) {
    final alerts = <FeedingAlert>[];
    
    final allergyEvents = events.where((e) {
      final type = e.data['feeding_event_type'] as String?;
      return type == 'suspectedFoodAllergy' || 
             type == 'suspectedFoodIntolerance' ||
             type == 'adverseFoodReaction';
    }).toList();

    if (allergyEvents.length >= 2) {
      alerts.add(FeedingAlert(
        severity: AlertSeverity.warning,
        title: '⚠️ ATENÇÃO: Padrão de Alergia/Intolerância',
        message: 'Múltiplas reações adversas a alimentos detectadas.',
        recommendation: 'Agendar consulta para teste de alergia. Considerar dieta hipoalergênica.',
        relatedEventIds: allergyEvents.map((e) => e.id).toList(),
      ));
    }

    return alerts;
  }

  /// Rule 9: Dehydration risk
  static List<FeedingAlert> _checkDehydrationRisk(List<PetEventModel> events) {
    final alerts = <FeedingAlert>[];
    
    final lowWaterEvents = events.where((e) {
      final type = e.data['feeding_event_type'] as String?;
      return type == 'lowWaterIntake';
    }).toList();

    final vomitingDiarrhea = events.where((e) {
      final type = e.data['feeding_event_type'] as String?;
      return type == 'vomitingImmediate' || 
             type == 'vomitingDelayed' ||
             type == 'diarrhea';
    }).toList();

    if (lowWaterEvents.isNotEmpty && vomitingDiarrhea.isNotEmpty) {
      alerts.add(FeedingAlert(
        severity: AlertSeverity.urgent,
        title: '⚠️ URGENTE: Risco de Desidratação',
        message: 'Baixa ingestão de água + perda de fluidos (vômito/diarreia).',
        recommendation: 'Consultar veterinário HOJE. Pode precisar de fluidoterapia.',
        relatedEventIds: [...lowWaterEvents, ...vomitingDiarrhea].map((e) => e.id).toList(),
      ));
    }

    return alerts;
  }

  /// Rule 10: Severe clinical events
  static List<FeedingAlert> _checkSevereClinicalEvents(List<PetEventModel> events) {
    final alerts = <FeedingAlert>[];
    
    final severeEvents = events.where((e) {
      final severity = e.data['severity'] as String?;
      final isClinical = e.data['is_clinical_intercurrence'] as bool? ?? false;
      return isClinical && 
             (severity?.toLowerCase() == 'severe' || severity?.toLowerCase() == 'grave');
    }).toList();

    if (severeEvents.isNotEmpty) {
      alerts.add(FeedingAlert(
        severity: AlertSeverity.emergency,
        title: '🚨 EMERGÊNCIA: Evento Clínico Grave',
        message: 'Intercorrência clínica de severidade GRAVE detectada.',
        recommendation: 'AÇÃO IMEDIATA: Levar ao veterinário AGORA.',
        relatedEventIds: severeEvents.map((e) => e.id).toList(),
      ));
    }

    return alerts;
  }

  /// Get alert summary for dashboard
  static Map<AlertSeverity, int> getAlertSummary(List<FeedingAlert> alerts) {
    return {
      AlertSeverity.emergency: alerts.where((a) => a.severity == AlertSeverity.emergency).length,
      AlertSeverity.urgent: alerts.where((a) => a.severity == AlertSeverity.urgent).length,
      AlertSeverity.warning: alerts.where((a) => a.severity == AlertSeverity.warning).length,
      AlertSeverity.info: alerts.where((a) => a.severity == AlertSeverity.info).length,
    };
  }
}
