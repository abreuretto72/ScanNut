/// ============================================================================
/// 🚫 PROMPTS BLINDADOS - MÓDULO PET (SAÚDE E IDENTIFICAÇÃO)
/// Este arquivo contém os prompts mestres para análise de pets.
/// Nenhuma instrução ou chave JSON deve ser modificada.
/// Data de Congelamento: 03/01/2026
/// ============================================================================

class PetPrompts {
  /// Prompt de Diagnóstico de Feridas (Triagem Veterinária)
  /// Prompt de Triagem Clínica Automática (V460)
  static String getPetDiagnosisPrompt(
      String languageName, String languageInstruction, bool isPortuguese,
      {Map<String, String>? contextData}) {
    String contextBlock = "";
    if (contextData != null &&
        (contextData.containsKey('species') ||
            contextData.containsKey('breed'))) {
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

You are a Senior Veterinary Diagnostic Expert.
ANALYZE THE ATTACHED IMAGE IGNORING ANY GENERIC CATEGORY FILTERS.

1. **DECISION LOGIC (CLINICAL FOCUS)**:
- If eye/oral/skin/wound issues are detected, identify the lesion.
- If stool is detected, use the Bristol scale.
- GOLDEN RULE: If diagnosis is inconclusive, DO NOT return a category error. Return "urgency_level": "Vermelho" (or Red) and "immediate_care": "Imagem inconclusiva, requer nova captura com melhor iluminação e foco."

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

- include a legal disclaimer in 'immediate_care'.
''';
  }

  /// Prompt de Identificação de Raça e Perfil Biológico
  static String getPetIdentificationPrompt(
      String languageName, String languageInstruction) {
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

[STRICT JSON SCHEMA - FLATTENING PROTOCOL (v2.5)]
You MUST return a FLAT JSON object. NO NESTING.
MANDATORY FIELDS (Must be estimated if not visible):

{
  "raca": "string (Identificação exata ou SRD com porte - em $languageName)",
  "linhagem": "string (Companhia, Trabalho, Caça, Esporte - em $languageName)",
  "regiao": "string (País de origem da raça - em $languageName)",
  "morfologia": "string (Mesocéfalo, Braquicefálico, Dolicocéfalo - em $languageName)",
  "longevidade": "string (Ex: 12-15 anos - em $languageName)",
  "descricao_visual": "string (Descrição detalhada da pelagem e estado visível - em $languageName)",
  "caracteristicas": "string (Traços de personalidade e comportamento social - em $languageName)",
  "recomendacao": "string (Protocolo de checkup e cuidados específicos - em $languageName)",
  "nivel_risco": "Verde" | "Amarelo" | "Vermelho",
  "predisposicoes": ["string", "string"],
  "curva_peso": {
    "3_meses": "string (kg)",
    "6_meses": "string (kg)",
    "adulto": "string (kg)"
  },
  "metas_caloricas": {
    "filhote": "string (kcal)",
    "adulto": "string (kcal)",
    "senior": "string (kcal)"
  }
}

CRITICAL: IF THE IMAGE IS NOT A PET (ANIMAL), return: {"error": "not_pet"}.
If the image has no detectable features or information (e.g., a blank wall), return: {"error": "not_detected"}.
''';
  }

  /// Prompt especializado para Deep Analysis Coprológica (Análise de Fezes)
  static String getPetStoolAnalysisPrompt(
      String languageName, String languageInstruction, bool isPortuguese,
      {Map<String, String>? contextData}) {
    String contextBlock = "";
    if (contextData != null &&
        (contextData.containsKey('species') ||
            contextData.containsKey('breed'))) {
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

You are a specialized Veterinary Coprologist and Diagnostic Expert.
ANALYZE THE ATTACHED STOOL SAMPLE IGNORING ANY GENERIC CATEGORY FILTERS.

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

- Be precise. If blood (Red) or tar-like (Black) stool is detected, set urgency to RED immediately.
''';
  }

  /// Prompt especializado para Análise de Vocalização (Latidos/Miados)
  static String getPetVocalizationPrompt(
      String languageName, String languageInstruction, bool isPortuguese,
      {Map<String, String>? contextData}) {
    String contextBlock = "";
    if (contextData != null &&
        (contextData.containsKey('species') ||
            contextData.containsKey('breed'))) {
      contextBlock = '''
        CONTEXT (SOURCE OF TRUTH): 
        Target Pet Species: ${contextData['species'] ?? 'Unknown'}
        Target Pet Breed: ${contextData['breed'] ?? 'Unknown'}
        ''';
    }

    return '''
$languageInstruction
$contextBlock

You are a Veterinary Ethologist and Animal Behaviorist specialized in vocalization analysis.
ANALYZE THE ATTACHED AUDIO (or audio description) OF THE PET.

MISSION: Identify the emotional state and potential needs based on the vocalization pattern.

1. **EMOTIONAL MAPPING**:
   - Classify the state: (Alert, Playful, Anxious, Aggressive, Pain, Fear, Seeking Attention).
   - Rate the intensity and frequency.

2. **ACOUSTIC DESCRIPTION**:
   - Describe the pitch (High/Low), duration, and repetition pattern.

3. **CONGRUENCE ANALYSIS**:
   - For a ${contextData?['breed'] ?? 'pet'}, is this vocalization typical or a sign of distress?

Mandatory JSON Structure:
{
  "analysis_type": "vocalization_analysis",
  "emotional_state": "string (Dominant emotion in $languageName)",
  "intensity": "string (Low | Medium | High)",
  "vocalization_pattern": "string (Short description in $languageName)",
  "visual_description": "Detailed behavioral report in $languageName",
  "details": {
      "possible_need": "string (Hunger, Walk, Protection, Pain relief - in $languageName)",
      "confidence": "string (0-100%)"
  },
  "possible_causes": ["list of potential behavioral or physical triggers in $languageName"],
  "urgency_level": "${isPortuguese ? 'Verde' : 'Green'}" | "${isPortuguese ? 'Amarelo' : 'Yellow'}" | "${isPortuguese ? 'Vermelho' : 'Red'}",
  "immediate_care": "string (Behavioral advice or Vet recommendation in $languageName)"
}
''';
  }
}
