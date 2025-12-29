/// ============================================================================
/// 🚫 COMPONENTE BLINDADO E CONGELADO - NÃO ALTERAR
/// Este módulo de Biometria e Peso do Pet foi concluído e validado.
/// Nenhuma rotina ou lógica interna deve ser modificada.
/// Data de Congelamento: 29/12/2025
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Database de referência de pesos ideais por raça e porte
class PetWeightDatabase {
  // Pesos médios por porte (em kg)
  static const Map<String, Map<String, double>> porteWeights = {
    'Pequeno': {'min': 2.0, 'ideal': 5.0, 'max': 10.0},
    'Médio': {'min': 10.0, 'ideal': 15.0, 'max': 25.0},
    'Grande': {'min': 25.0, 'ideal': 35.0, 'max': 45.0},
    'Gigante': {'min': 45.0, 'ideal': 60.0, 'max': 80.0},
  };

  // Database de raças específicas (peso ideal médio em kg)
  static const Map<String, Map<String, dynamic>> breedWeights = {
    // Pequeno Porte
    'Chihuahua': {'ideal': 2.5, 'porte': 'Pequeno'},
    'Yorkshire': {'ideal': 3.0, 'porte': 'Pequeno'},
    'Pinscher': {'ideal': 4.0, 'porte': 'Pequeno'},
    'Maltês': {'ideal': 3.5, 'porte': 'Pequeno'},
    'Shih Tzu': {'ideal': 6.0, 'porte': 'Pequeno'},
    'Pug': {'ideal': 7.0, 'porte': 'Pequeno'},
    'Lhasa Apso': {'ideal': 6.5, 'porte': 'Pequeno'},
    'Poodle Toy': {'ideal': 3.0, 'porte': 'Pequeno'},
    'Spitz Alemão': {'ideal': 4.5, 'porte': 'Pequeno'},
    'Dachshund': {'ideal': 9.0, 'porte': 'Pequeno'},
    
    // Médio Porte
    'Beagle': {'ideal': 12.0, 'porte': 'Médio'},
    'Cocker Spaniel': {'ideal': 14.0, 'porte': 'Médio'},
    'Bulldog Francês': {'ideal': 11.0, 'porte': 'Médio'},
    'Bulldog Inglês': {'ideal': 23.0, 'porte': 'Médio'},
    'Border Collie': {'ideal': 18.0, 'porte': 'Médio'},
    'Poodle Médio': {'ideal': 12.0, 'porte': 'Médio'},
    'Schnauzer': {'ideal': 16.0, 'porte': 'Médio'},
    'Basset Hound': {'ideal': 25.0, 'porte': 'Médio'},
    'Shar Pei': {'ideal': 22.0, 'porte': 'Médio'},
    'Corgi': {'ideal': 12.0, 'porte': 'Médio'},
    
    // Grande Porte
    'Labrador': {'ideal': 32.0, 'porte': 'Grande'},
    'Golden Retriever': {'ideal': 32.0, 'porte': 'Grande'},
    'Pastor Alemão': {'ideal': 35.0, 'porte': 'Grande'},
    'Rottweiler': {'ideal': 45.0, 'porte': 'Grande'},
    'Boxer': {'ideal': 30.0, 'porte': 'Grande'},
    'Husky Siberiano': {'ideal': 23.0, 'porte': 'Grande'},
    'Dálmata': {'ideal': 27.0, 'porte': 'Grande'},
    'Doberman': {'ideal': 38.0, 'porte': 'Grande'},
    'Weimaraner': {'ideal': 32.0, 'porte': 'Grande'},
    'Akita': {'ideal': 40.0, 'porte': 'Grande'},
    
    // Gigante
    'São Bernardo': {'ideal': 70.0, 'porte': 'Gigante'},
    'Dogue Alemão': {'ideal': 65.0, 'porte': 'Gigante'},
    'Mastiff': {'ideal': 80.0, 'porte': 'Gigante'},
    'Fila Brasileiro': {'ideal': 55.0, 'porte': 'Gigante'},
    'Terra Nova': {'ideal': 60.0, 'porte': 'Gigante'},
    'Bernese': {'ideal': 45.0, 'porte': 'Gigante'},
    'Leonberger': {'ideal': 65.0, 'porte': 'Gigante'},
    
    // Gatos (peso em kg)
    'Persa': {'ideal': 4.5, 'porte': 'Pequeno', 'species': 'cat'},
    'Siamês': {'ideal': 4.0, 'porte': 'Pequeno', 'species': 'cat'},
    'Maine Coon': {'ideal': 7.0, 'porte': 'Médio', 'species': 'cat'},
    'Ragdoll': {'ideal': 6.5, 'porte': 'Médio', 'species': 'cat'},
    'Bengal': {'ideal': 5.5, 'porte': 'Pequeno', 'species': 'cat'},
    'Sphynx': {'ideal': 4.0, 'porte': 'Pequeno', 'species': 'cat'},
    'British Shorthair': {'ideal': 5.5, 'porte': 'Médio', 'species': 'cat'},
    'Vira-lata': {'ideal': 4.5, 'porte': 'Pequeno', 'species': 'cat'},
  };

  /// Busca o peso ideal baseado na raça ou porte
  static double? getIdealWeight({String? raca, String? porte}) {
    // Prioridade 1: Buscar por raça específica
    if (raca != null && raca.isNotEmpty) {
      // Busca exata
      if (breedWeights.containsKey(raca)) {
        return breedWeights[raca]!['ideal'] as double;
      }
      
      // Busca fuzzy (case insensitive, partial match)
      final racaLower = raca.toLowerCase();
      for (var entry in breedWeights.entries) {
        if (entry.key.toLowerCase().contains(racaLower) || 
            racaLower.contains(entry.key.toLowerCase())) {
          return entry.value['ideal'] as double;
        }
      }
    }
    
    // Prioridade 2: Buscar por porte
    if (porte != null && porte.isNotEmpty && porteWeights.containsKey(porte)) {
      return porteWeights[porte]!['ideal'];
    }
    
    // Fallback: Médio porte
    return porteWeights['Médio']!['ideal'];
  }

  /// Detecta o porte baseado na raça
  static String? getPorteFromRaca(String? raca) {
    if (raca == null || raca.isEmpty) return null;
    
    final racaLower = raca.toLowerCase();
    for (var entry in breedWeights.entries) {
      if (entry.key.toLowerCase().contains(racaLower) || 
          racaLower.contains(entry.key.toLowerCase())) {
        return entry.value['porte'] as String?;
      }
    }
    
    return null;
  }

  /// Calcula o status do peso
  static WeightStatus calculateWeightStatus({
    required double currentWeight,
    required double idealWeight,
    required dynamic strings, // AppLocalizations
  }) {
    final ratio = currentWeight / idealWeight;
    final suffix = 'kg'; // Fallback ou passar via settings
    
    if (ratio < 0.90) {
      return WeightStatus(
        status: WeightStatusType.underweight,
        message: '${strings.weightStatusUnderweight}: ${idealWeight.toStringAsFixed(1)} $suffix.',
        color: Colors.blue,
        icon: Icons.trending_down,
        percentage: (ratio * 100).toInt(),
      );
    } else if (ratio > 1.10) {
      return WeightStatus(
        status: WeightStatusType.overweight,
        message: '${strings.weightStatusOverweight}: ${idealWeight.toStringAsFixed(1)} $suffix.',
        color: Colors.orange,
        icon: Icons.trending_up,
        percentage: (ratio * 100).toInt(),
      );
    } else {
      return WeightStatus(
        status: WeightStatusType.normal,
        message: strings.weightStatusNormal,
        color: const Color(0xFF00E676),
        icon: Icons.check_circle,
        percentage: (ratio * 100).toInt(),
      );
    }
  }

  /// Lista de raças disponíveis para autocomplete
  static List<String> get allBreeds => breedWeights.keys.toList()..sort();
  
  /// Lista de portes disponíveis
  static List<String> get allPortes => porteWeights.keys.toList();
}

/// Tipos de status de peso
enum WeightStatusType {
  underweight,
  normal,
  overweight,
}

/// Modelo de status de peso
class WeightStatus {
  final WeightStatusType status;
  final String message;
  final Color color;
  final IconData icon;
  final int percentage; // Percentual em relação ao ideal

  WeightStatus({
    required this.status,
    required this.message,
    required this.color,
    required this.icon,
    required this.percentage,
  });

  /// Retorna recomendação baseada no status
  String getRecommendation(dynamic strings) {
    switch (status) {
      case WeightStatusType.underweight:
        return strings.weightRecUnderweight;
      case WeightStatusType.overweight:
        return strings.weightRecOverweight;
      case WeightStatusType.normal:
        return strings.weightRecNormal;
    }
  }
}
