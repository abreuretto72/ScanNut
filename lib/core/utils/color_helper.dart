import 'package:flutter/material.dart';

import '../theme/app_design.dart';

class ColorHelper {
  /// Determine theme color based on food health score
  static Color getFoodThemeColor({
    required int calories,
    required List<String> risks,
    required List<String> benefits,
  }) {
    // Calculate health score
    final riskScore = risks.length;
    final benefitScore = benefits.length;

    // High calories or more risks than benefits = warning
    if (calories > 600 || riskScore > benefitScore) {
      return AppDesign.warning; // Warning
    } else if (benefitScore > riskScore) {
      return AppDesign.success; // Healthy green
    }

    return AppDesign.warning; // Neutral
  }

  /// Determine theme color based on plant urgency
  static Color getPlantThemeColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'high':
        return AppDesign.error;
      case 'medium':
        return AppDesign.warning;
      case 'low':
      default:
        return AppDesign.success;
    }
  }

  /// Determine theme color based on pet urgency level
  static Color getPetThemeColor(String urgencyLevel) {
    final level = urgencyLevel.toLowerCase();
    if (level.contains('vermelho') ||
        level.contains('red') ||
        level.contains('rojo')) {
      return AppDesign.error;
    } else if (level.contains('amarelo') ||
        level.contains('yellow') ||
        level.contains('amarillo')) {
      return AppDesign.warning;
    } else if (level.contains('verde') || level.contains('green')) {
      return AppDesign.success;
    }
    return AppDesign.success; // Default to safe green
  }

  /// Get urgency icon based on level
  static IconData getUrgencyIcon(String urgencyLevel) {
    final level = urgencyLevel.toLowerCase();
    if (level.contains('vermelho') ||
        level.contains('red') ||
        level.contains('rojo') ||
        level.contains('high')) {
      return Icons.warning_amber_rounded;
    } else if (level.contains('amarelo') ||
        level.contains('yellow') ||
        level.contains('amarillo') ||
        level.contains('medium')) {
      return Icons.info_outline;
    } else {
      return Icons.check_circle_outline;
    }
  }
}
