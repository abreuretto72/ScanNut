/// ============================================================================
/// 🚫 PROMPTS BLINDADOS - MÓDULO PET (SAÚDE E IDENTIFICAÇÃO)
/// Este arquivo contém os prompts mestres para análise de pets.
/// Nenhuma instrução ou chave JSON deve ser modificada.
/// Data de Congelamento: 03/01/2026
/// ============================================================================

class PetPrompts {
  /// Prompt de Diagnóstico de Feridas (Triagem Veterinária)
  /// Prompt de Triagem Clínica Automática (V460)
  static String getPetDiagnosisPrompt(String languageName, String languageInstruction, bool isPortuguese, {Map<String, String>? contextData}) {
    String contextBlock = "";
    if (contextData != null && (contextData.containsKey('species') || contextData.containsKey('breed'))) {
        contextBlock = '''
        CONTEXT (SOURCE OF TRUTH): 
        Target Pet Species: ${contextData['species'] ?? 'Unknown'}
        Target Pet Breed: ${contextData['breed'] ?? 'Unknown'}
        Target Pet Weight: ${contextData['weight'] ?? 'N/A'} kg
        
        INSTRUCTION: You are analyzing THIS specific pet. Focus on the identified condition.
        ''';
    }

    return '''
$languageInstruction
$contextBlock

Act as a Senior Veterinary Diagnostic Expert. 
You are performing an AUTOMATIC CLINICAL TRIAGE.

1. **LÓGICA DE DECISÃO (VISUAL MATCH)**:
Identify the region in the image and process accordingly:
- **Ocular Area**: Eye analysis (Hyperemia, Opacity, Secretion).
- **Oral Area**: Dental analysis (Tartar, Gingivitis, Halitosis).
- **Cutaneous Area**: Skin analysis (Alopecia, Ectoparasites, Scaling).
- **Exposed Lesion**: Wound analysis (Depth, Secretion, Edges).
- **Organic Waste (Stool)**: Coprological analysis (Bristol Score, Color, Inclusions).

2. **PROTOCOL**:
- Return ONLY the relevant specialist details object based on the detected category.
- If 'Olhos' is detected, 'dental_details' should be null.
- Set 'urgency_level' based on clinical findings (Red = Emergency).

Mandatory JSON Structure:
{
  "analysis_type": "diagnosis",
  "category": "olhos" | "dentes" | "pele" | "ferida" | "fezes",
  "characteristics": "string (Summary of findings in $languageName)",
  "visual_description": "string (Deep clinical report in $languageName)",
  
  "eye_details": {
      "hiperemia": "string (Redness level)",
      "opacidade": "string (Corneal status)",
      "secrecao": "string (Discharge description)"
  },
  "dental_details": {
      "tartaro_index": "string (% cover)",
      "gengivite": "string (Inflammation level)",
      "halitose": "string (Estimated odor)"
  },
  "skin_details": {
      "alopecias": "string (Hair loss areas)",
      "ectoparasitas": "string (Ticks/Fleas detected)",
      "descamacao": "string (Scaling/Dandruff)"
  },
  "wound_details": {
      "profundidade": "string (Superficial/Deep)",
      "secrecao": "string (Exudate type)",
      "bordas": "string (Healing status)"
  },
  "stool_details": {
      "consistency_bristol_scale": "1-7",
      "color_hex": "string (Hex code)",
      "color_name": "string",
      "clinical_color_meaning": "string",
      "foreign_bodies": ["string"],
      "parasites_detected": "boolean"
  },

  "possible_causes": ["list of strings in $languageName"], 
  "urgency_level": "${isPortuguese ? 'Verde' : 'Green'}" | "${isPortuguese ? 'Amarelo' : 'Yellow'}" | "${isPortuguese ? 'Vermelho' : 'Red'}", 
  "immediate_care": "string (First aid + Vet recommendation in $languageName)"
}

IMPORTANT:
- Use only the detected category's detail object. The others should be omitted or null.
- Include a legal disclaimer in 'immediate_care'.
- IF THE IMAGE IS NOT A PET, return: {"error": "not_pet"}.
''';
  }

  /// Prompt de Identificação de Raça e Perfil Biológico
  static String getPetIdentificationPrompt(String languageName, String languageInstruction) {
    return '''
$languageInstruction

[ROLE]
You are an expert Veterinary AI and Animal Nutritionist. Your task is to analyze the pet image and generate a COMPLETE biological profile.

[STRICT ZERO N/A POLICY - CRITICAL]
1. You must Return a Valid JSON. Use $languageName.
2. "N/A", "Unknown", "Not Estimated", "Não informado", "Desc", "Non-specified" are STRICTLY FORBIDDEN.
3. MANDATORY INFERENCE: If a value is not visible, you MUST ESTIMATE it based on the breed ($languageName standards).
4. CONSISTENCY RULES & TRANSLATIONS:
   A. IF LANGUAGE IS ENGLISH:
      - activity_level: Use ONLY "Low", "Moderate", "High", "Athlete".
      - reproductive_status: Use ONLY "Neutered" or "Intact".
      - coat_type: Use "Short", "Long", "Double", "Wire", "Curly".
      - grooming_frequency: Use "Daily", "Weekly", "Bi-weekly", "Monthly".
   B. IF LANGUAGE IS PORTUGUESE:
      - activity_level: Use APENAS "Baixo", "Moderado", "Alto", "Atleta".
      - reproductive_status: Use APENAS "Castrado" ou "Inteiro".
      - coat_type: Use "Curto", "Longo", "Duplo", "Duro", "Encaracolado".
      - grooming_frequency: Use "Diária", "Semanal", "Quinzenal", "Mensal".
   C. IF LANGUAGE IS SPANISH:
      - activity_level: Use SOLO "Bajo", "Moderado", "Alto", "Atleta".
      - reproductive_status: Use SOLO "Castrado" o "Entero".
      - coat_type: Use "Corto", "Largo", "Doble", "Duro", "Rizado".
      - grooming_frequency: Use "Diaria", "Semanal", "Quincenal", "Mensual".

[STRUCTURE]
{
  "identification": {
    "species": "string (Identify species in $languageName - e.g. Cão/Gato)",
    "breed": "string (Identify breed in $languageName)",
    "lineage": "string (Classification: Trabalho/Companhia/Show/Esporte - in $languageName)", 
    "origin_region": "string (Country/Region of origin - e.g. Alemanha, Reino Unido - in $languageName)",
    "morphology_type": "string (e.g. Mesocéfalo, Braquicefálico, Dolicocéfalo - in $languageName)",
    "size": "string (Small/Medium/Large/Giant - translated to $languageName)",
    "longevity": "string (e.g. 12-15 years - in $languageName)"
  },
  "growth_curve": {
    "weight_3_months": "string (Estimated kg)",
    "weight_6_months": "string (Estimated kg)",
    "weight_12_months": "string (Estimated kg)",
    "adult_weight": "string (Estimated kg)"
  },
  "grooming": {
    "coat_type": "string (in $languageName)",
    "grooming_frequency": "string (in $languageName)"
  },
  "nutrition": {
    "kcal_puppy": "string (Estimated daily kcal)",
    "kcal_adult": "string (Estimated daily kcal)",
    "kcal_senior": "string (Estimated daily kcal)",
    "target_nutrients": ["string in $languageName"]
  },
  "health": {
    "predispositions": ["string in $languageName", "string in $languageName"],
    "preventive_checkup": "string (in $languageName)"
  },
  "lifestyle": {
    "activity_level": "string (strictly in $languageName)",
    "environment_type": "string (strictly in $languageName)",
    "training_intelligence": "string (in $languageName)"
  },
  "behavior": {
    "personality": "string (Descriptive personality traits inferred from breed/expression in $languageName)",
    "social_behavior": "string (How they interact with humans/pets in $languageName)", 
    "energy_level_desc": "string (Detailed description of energy needs in $languageName)"
  },
  "metadata": {
    "reliability": "string (e.g. '98%' or 'Alta' - estimate AI confidence)"
  }
}

CRITICAL: IF THE IMAGE IS NOT A PET (ANIMAL), return: {"error": "not_pet"}.
If the image has no detectable features or information (e.g., a blank wall), return: {"error": "not_detected"}.
''';
  }

  /// Prompt especializado para Deep Analysis Coprológica (Análise de Fezes)
  static String getPetStoolAnalysisPrompt(String languageName, String languageInstruction, bool isPortuguese, {Map<String, String>? contextData}) {
    String contextBlock = "";
    if (contextData != null && (contextData.containsKey('species') || contextData.containsKey('breed'))) {
        contextBlock = '''
        CONTEXT (SOURCE OF TRUTH): 
        Target Pet Species: ${contextData['species'] ?? 'Unknown'}
        Target Pet Breed: ${contextData['breed'] ?? 'Unknown'}
        Target Pet Weight: ${contextData['weight'] ?? '3.1'} kg
        ''';
    }

    return '''
$languageInstruction
$contextBlock

Act as a specialized Veterinary Coprologist and Diagnostic Expert. 
You are performing a DEEP COPROLOGICAL ANALYSIS on a pet stool sample image.

MISSION: Segment the sample into data layers:

1. **BIOMETRICS & CONSISTENCY (Scale 1 to 7)**:
   - Identify consistency based on the Bristol Stool Scale (1: Hard lumps, 4: Ideal, 7: Liquid).
   - Rate 'firmness' and 'hydration' level (presence of mucus or shine).

2. **CHROMATOLOGY (Color Analysis)**:
   - Specific color identification (Brown, Black/Tar, Red, Yellow/Orange, White/Gray).
   - Clinical meaning of the color for the pet's health.

3. **FOREIGN BODIES & INCLUSIONS**:
   - Parasitology: Visual segments of worms (like tapeworm proglottids).
   - Inadequate Ingestion: Bone fragments, plastic, grass, hair.
   - Steatorrhea/Mucus: Visible fat or excessive mucus coating.

4. **VOLUME & FREQUENCY ESTIMATION**:
   - Cross-reference sample size with the pet's weight (${contextData?['weight'] ?? '3.1'} kg) to calculate if volume is compatible with caloric intake.

Mandatory JSON Structure:
{
  "analysis_type": "stool_analysis",
  "characteristics": "Brief summary of stool status (e.g. 'Ideal', 'Diarrhea', 'Steatorrhea') in $languageName",
  "visual_description": "Detailed clinical report addressing consistency, color, and inclusions in $languageName",
  "stool_details": {
      "consistency_bristol_scale": "1-7 (Int)",
      "firmness": "string (Detailed assessment)",
      "hydration_mucus": "string (Assessment of shine/mucus)",
      "color_hex": "string (Hex code of dominant color)",
      "color_name": "string (Name of color in $languageName)",
      "clinical_color_meaning": "string (Explanation of color in $languageName)",
      "foreign_bodies": ["list of findings"],
      "parasites_detected": "boolean (Visible only)",
      "volume_assessment": "string (Compatible | High | Low - with explanation relative to ${contextData?['weight'] ?? '3.1'}kg)"
  },
  "possible_causes": ["list of potential causes in $languageName"],
  "urgency_level": "${isPortuguese ? 'Verde' : 'Green'}" | "${isPortuguese ? 'Amarelo' : 'Yellow'}" | "${isPortuguese ? 'Vermelho' : 'Red'}",
  "immediate_care": "string (Home care advice + disclaimer in $languageName)"
}

IMPORTANT:
- IF THE IMAGE IS NOT STOOL/FEZES, return: {"error": "not_stool"}.
- Be precise. If blood (Red) or tar-like (Black) stool is detected, set urgency to RED immediately.
''';
  }
}
