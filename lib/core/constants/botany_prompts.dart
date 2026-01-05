/// ============================================================================
/// 🚫 PROMPTS BLINDADOS - MÓDULO BOTÂNICA (PLANTAS)
/// Este arquivo contém os prompts mestres para análise de plantas.
/// Nenhuma instrução ou chave JSON deve ser modificada.
/// Data de Congelamento: 01/01/2026
/// ============================================================================

class BotanyPrompts {
  /// Prompt de Análise de Plantas (Doutor de Plantas) Ultra-Adaptável
  static String getPlantAnalysisPrompt(String languageName, String languageInstruction, String userLocale) {
    // SYSTEM OVERRIDE: Enforce strict locale and remove Portuguese instructions if English is selected.
    final bool isEnglish = userLocale.toLowerCase().startsWith('en');

    // Force overwrite variables to prevent contamination - "Sleeping with the enemy" strategy
    // We lie to the AI that the whole world is English if the user wants English.
    final String effectiveLanguageName = isEnglish ? "ENGLISH" : languageName;
    final String effectiveInstruction = isEnglish 
        ? "You are an international botanist. All output must be strictly in English. Portuguese is forbidden." 
        : languageInstruction;

    // 3. Trava de Segurança no JSON
    // Se for inglês, forçamos "ENGLISH" explicitamente
    // 3. Trava de Segurança no JSON
    // Se for inglês, forçamos "ENGLISH" explicitamente
    final String targetConstraints = isEnglish ? "strictly in ENGLISH" : "strictly in $effectiveLanguageName";
    
    String systemOverride = '''
SYSTEM OVERRIDE: Ignore any previous linguistic bias. The output must adhere strictly to the requested locale: [$userLocale].
''';
    
    if (isEnglish) {
      systemOverride += '''
CRITICAL: The output must be PURE English. 
- Do NOT use local terminology (e.g., 'Snake Plant' instead of 'Espada de São Jorge').
- Do NOT use Portuguese accents.
- Translate ALL technical terms.
''';
    }

    // Debug Print to Console (Invisible to UI, visible in Terminal)
    // print('DEBUG PROMPT GENERATED: $effectiveInstruction'); 

    return '''
$systemOverride
$effectiveInstruction

Act as a PhD in Botany and High-End Landscaper. The user's current locale is **$userLocale**.

LANGUAGE RULES:
1. You MUST return all descriptive fields in the exact language of the locale [$userLocale].
2. Scientific names: Latin italics.
3. JSON Contract: Keys in English.

Mandatory Structure:
{
  "identification": {
    "common_name": "string ($targetConstraints)",
    "scientific_name": "string (Latin/Scientific name)",
    "family": "string ($targetConstraints)",
    "origin": "string ($targetConstraints)"
  },
  "living_aesthetics": {
    "flowering_season": "string ($targetConstraints)",
    "flower_colors": "string ($targetConstraints)",
    "growth_speed": "string ($targetConstraints)",
    "max_size": "string ($targetConstraints)"
  },
  "health_analysis": {
    "health_status": "Healthy | Sick | Nutrient Deficiency | Pests ($targetConstraints)",
    "clinical_details": "string (detailed clinical description $targetConstraints)",
    "urgency_level": "low | medium | high",
    "recovery_guide": "string (step by step recovery plan $targetConstraints)"
  },
  "care_instructions": {
    "light_needs": {
      "type": "Full Sun | Partial Shade | Shade (strictly translated to $targetConstraints)",
      "details": "string ($targetConstraints)"
    },
    "watering_regime": {
      "frequency": "string ($targetConstraints)",
      "method": "string ($targetConstraints)",
      "thirst_signs": "string ($targetConstraints)"
    },
    "soil_and_nutrition": {
      "ideal_ph": "string",
      "soil_composition": "string ($targetConstraints)",
      "fertilizer_recommendation": "string ($targetConstraints)"
    }
  },
  "safety_and_biofillia": {
    "home_safety": {
      "is_toxic_to_pets": boolean,
      "is_toxic_to_children": boolean,
      "toxicity_details": "string (symptoms and alerts $targetConstraints)"
    },
    "biofillic_benefits": {
      "air_purification_score": integer (1-10),
      "wellness_impact": "string ($targetConstraints)"
    }
  },
  "propagation_engineering": {
    "method": "string ($targetConstraints)",
    "step_by_step": "string ($targetConstraints)",
    "difficulty": "Easy | Moderate | Challenging (strictly translated to $targetConstraints)"
  },
  "ecosystem_intelligence": {
    "companion_planting": ["string ($targetConstraints)"],
    "natural_repellent": "string (pests it repels - $targetConstraints)"
  },
  "lifestyle_and_feng_shui": {
    "ideal_positioning": "string (best place in the house - $targetConstraints)",
    "symbolism": "string (cultural/spiritual meaning - $targetConstraints)"
  },
  "seasonal_alerts": {
    "winter": "string (dormancy - $targetConstraints)",
    "summer": "string (growth - $targetConstraints)"
  }
}

If the image is not a plant, return {"error": "not_plant"}.
If the image has no detectable features or information (e.g., a blank wall), return {"error": "not_detected"}.
''';
  }
}
