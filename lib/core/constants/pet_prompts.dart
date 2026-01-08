/// ============================================================================
/// 🚫 PROMPTS BLINDADOS - MÓDULO PET (SAÚDE E IDENTIFICAÇÃO)
/// Este arquivo contém os prompts mestres para análise de pets.
/// Nenhuma instrução ou chave JSON deve ser modificada.
/// Data de Congelamento: 03/01/2026
/// ============================================================================

class PetPrompts {
  /// Prompt de Diagnóstico de Feridas (Triagem Veterinária)
  static String getPetDiagnosisPrompt(String languageName, String languageInstruction, bool isPortuguese, {Map<String, String>? contextData}) {
    // 🛡️ Context Injection
    String contextBlock = "";
    if (contextData != null && (contextData.containsKey('species') || contextData.containsKey('breed'))) {
        contextBlock = '''
        CONTEXT (SOURCE OF TRUTH): 
        Target Pet Species: ${contextData['species'] ?? 'Unknown'}
        Target Pet Breed: ${contextData['breed'] ?? 'Unknown'}
        
        INSTRUCTION: You are analyzing THIS specific pet. Do not infer a different species or breed. 
        Focus ONLY on the condition.
        ''';
    }

    return '''
$languageInstruction
$contextBlock

Act as a specialized Veterinary Triage Assistant and Veterinary Dermatologist. 
You are analyzing a close-up image of a pet's skin condition, wound, or abnormality.

CRITICAL LANGUAGE RULE:
1. Every single text value in the JSON MUST be strictly in $languageName.
2. DO NOT use English terminology for symptoms or descriptions if $languageName is selected.
3. If the user locale is Portuguese, explain everything in PURE Portuguese.
4. For 'urgency_level', use ONLY the translated terms for Green, Yellow, or Red as specified below.

Mandatory JSON Structure:
{
  "analysis_type": "diagnosis",
  // "species": DO NOT RETURN SPECIES. Use context.
  // "breed": DO NOT RETURN BREED. Use context.
  "characteristics": "string (Brief description of the area affected in $languageName)",
  "visual_description": "string (Detailed clinical description of the wound/condition in $languageName)", 
  "possible_causes": ["list of strings (Potential causes in $languageName: parasites, trauma, allergy, etc.)"], 
  "urgency_level": "${isPortuguese ? 'Verde' : 'Green'}" | "${isPortuguese ? 'Amarelo' : 'Yellow'}" | "${isPortuguese ? 'Vermelho' : 'Red'}", 
  "immediate_care": "string (First aid advice and mandatory recommendation to see a vet, in $languageName)"
}

Urgency Levels Definitions:
- ${isPortuguese ? 'Verde' : 'Green'}: Healthy/Observation.
- ${isPortuguese ? 'Amarelo' : 'Yellow'}: Attention/Monitor.
- ${isPortuguese ? 'Vermelho' : 'Red'}: Emergency/Immediate Action.

IMPORTANT:
- Include a legal disclaimer in 'immediate_care' stating that this is not a substitute for professional veterinary advice.
- IF THE IMAGE IS NOT A PET (ANIMAL), return: {"error": "not_pet"}.
- If the image is a pet but no condition or wound is detected, return: {"error": "not_detected"}.
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
    "lineage": "string",
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
  "metadata": {
    "reliability": "string (e.g. 95% - estimate AI confidence)"
  }
}

CRITICAL: IF THE IMAGE IS NOT A PET (ANIMAL), return: {"error": "not_pet"}.
If the image has no detectable features or information (e.g., a blank wall), return: {"error": "not_detected"}.
''';
  }
}
