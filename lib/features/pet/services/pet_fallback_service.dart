class PetFallbackService {
  /// Default growth curve data based on size category
  static Map<String, dynamic> getGrowthCurve(String size) {
    String s = size.toLowerCase();

    if (s.contains('pequen') || s.contains('small')) {
      return {
        'weight_3_months': '2-3 kg',
        'weight_6_months': '4-5 kg',
        'weight_12_months': '6-8 kg',
        'adult_weight': '8-10 kg'
      };
    } else if (s.contains('grande') || s.contains('large')) {
      return {
        'weight_3_months': '10-12 kg',
        'weight_6_months': '20-25 kg',
        'weight_12_months': '30-35 kg',
        'adult_weight': '35-45 kg'
      };
    } else if (s.contains('gigante') || s.contains('giant')) {
      return {
        'weight_3_months': '15-20 kg',
        'weight_6_months': '30-40 kg',
        'weight_12_months': '50-60 kg',
        'adult_weight': '60-80 kg'
      };
    }

    // Default to Medium
    return {
      'weight_3_months': '5-7 kg',
      'weight_6_months': '10-12 kg',
      'weight_12_months': '15-18 kg',
      'adult_weight': '15-20 kg'
    };
  }

  /// Default nutritional targets based on size
  static Map<String, String> getNutritionalTargets(String size) {
    String s = size.toLowerCase();

    if (s.contains('pequen') || s.contains('small')) {
      return {
        'kcal_filhote': '600-800 kcal', // High metabolism
        'kcal_adulto': '400-500 kcal',
        'kcal_senior': '350-450 kcal'
      };
    } else if (s.contains('grande') || s.contains('large')) {
      return {
        'kcal_filhote': '1800-2200 kcal',
        'kcal_adulto': '1400-1600 kcal',
        'kcal_senior': '1100-1300 kcal'
      };
    } else if (s.contains('gigante') || s.contains('giant')) {
      return {
        'kcal_filhote': '2800-3500 kcal',
        'kcal_adulto': '2200-2600 kcal',
        'kcal_senior': '1800-2200 kcal'
      };
    }

    // Default to Medium
    return {
      'kcal_filhote': '1000-1200 kcal',
      'kcal_adulto': '800-1000 kcal',
      'kcal_senior': '700-900 kcal'
    };
  }

  /// Default grooming frequency based on coat type inference or default
  static String getGroomingFrequency(String coatType) {
    String c = coatType.toLowerCase();
    if (c.contains('long') ||
        c.contains('curly') ||
        c.contains('encaracolado')) {
      return 'Diária / Daily';
    } else if (c.contains('curt') || c.contains('short')) {
      return 'Semanal / Weekly';
    } else if (c.contains('dupl') || c.contains('double')) {
      return '2-3x Semana';
    }
    return 'Semanal / Weekly';
  }
}
