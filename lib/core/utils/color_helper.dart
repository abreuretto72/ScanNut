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
    final level = urgencyLevel.toLowerCase();
    if (level.contains('vermelho') || level.contains('red') || level.contains('rojo')) {
      return Colors.redAccent;
    } else if (level.contains('amarelo') || level.contains('yellow') || level.contains('amarillo')) {
      return Colors.amber;
    } else if (level.contains('verde') || level.contains('green')) {
      return const Color(0xFF00E676);
    }
    return const Color(0xFF00E676); // Default to safe green
  }

  /// Get urgency icon based on level
  static IconData getUrgencyIcon(String urgencyLevel) {
    final level = urgencyLevel.toLowerCase();
    if (level.contains('vermelho') || level.contains('red') || level.contains('rojo') || level.contains('high')) {
      return Icons.warning_amber_rounded;
    } else if (level.contains('amarelo') || level.contains('yellow') || level.contains('amarillo') || level.contains('medium')) {
      return Icons.info_outline;
    } else {
      return Icons.check_circle_outline;
    }
  }
}
