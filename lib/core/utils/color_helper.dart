import 'package:flutter/material.dart';

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
      return Colors.orangeAccent; // Warning
    } else if (benefitScore > riskScore) {
      return const Color(0xFF00E676); // Healthy green
    }
    
    return Colors.amber; // Neutral
  }

  /// Determine theme color based on plant urgency
  static Color getPlantThemeColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'high':
        return Colors.redAccent;
      case 'medium':
        return Colors.orangeAccent;
      case 'low':
      default:
        return const Color(0xFF00E676);
    }
  }

  /// Determine theme color based on pet urgency level
  static Color getPetThemeColor(String urgencyLevel) {
    switch (urgencyLevel.toLowerCase()) {
      case 'vermelho':
        return Colors.redAccent;
      case 'amarelo':
        return Colors.amber;
      case 'verde':
      default:
        return const Color(0xFF00E676);
    }
  }

  /// Get urgency icon based on level
  static IconData getUrgencyIcon(String urgencyLevel) {
    switch (urgencyLevel.toLowerCase()) {
      case 'vermelho':
      case 'high':
        return Icons.warning_amber_rounded;
      case 'amarelo':
      case 'medium':
        return Icons.info_outline;
      case 'verde':
      case 'low':
      default:
        return Icons.check_circle_outline;
    }
  }
}
