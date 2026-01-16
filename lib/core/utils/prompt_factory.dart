import '../constants/botany_prompts.dart';
import '../constants/nutrition_prompts.dart';
import '../constants/pet_prompts.dart';
import '../enums/scannut_mode.dart';

class PromptFactory {
  /// Master System Prompt - Data Architecture and Routing Logic
  static String getMasterSystemPrompt({String locale = 'pt'}) {
    final normalizedLocale = locale.replaceAll('-', '_');
    String title = "VOCÊ É O ARQUITETO DE DADOS E MOTOR DE IA DO ScanNut.";
    String mission = "**MISSÃO CRÍTICA:** Processar imagens de pets e categorizá-las nos CONJUNTOS DE DADOS corretos, garantindo SEMPRE o vínculo pelo nome_do_pet.";
    String langInstr = "Responda SEMPRE em Português do Brasil (PT-BR) para os valores.";

    if (normalizedLocale.startsWith('en')) {
      title = "YOU ARE THE DATA ARCHITECT AND AI ENGINE OF ScanNut.";
      mission = "**CRITICAL MISSION:** Process pet images and categorize them into the CORRECT DATA SETS, ALWAYS ensuring the link via name_of_pet.";
      langInstr = "ALWAYS respond in English for the values.";
    } else if (normalizedLocale.startsWith('es')) {
      title = "ERES EL ARQUITECTO DE DATOS Y MOTOR DE IA DE ScanNut.";
      mission = "**MISIÓN CRÍTICA:** Procesar imágenes de mascotas y categorizarlas en los CONJUNTOS DE DATOS correctos, garantizando SIEMPRE el vínculo por el nombre_de_la_mascota.";
      langInstr = "Responda SIEMPRE en Español para los valores.";
    }

    return '''
$title

$mission

═══════════════════════════════════════════════════════════════
📋 ROUTING LOGIC (Input Analysis)
═══════════════════════════════════════════════════════════════

1️⃣ BREED & ID (Healthy animal/full body)
   → Extract breed features and ID information
   → Check if pet name already exists
   → If YES: Update BREED_ID set
   → If NO: Create new profile
   
2️⃣ HEALTH (Wounds/Symptoms/Diagnosis)
   → Generate diagnosis, urgency level and recovery plan
   → MANDATORY link to pet name
   → Use pre-existing BREED_ID data for personalization
   
3️⃣ MENU (Meal plan request)
   → Generate 7-day plan (Natural Food)
   → Consult ingredient history to NOT REPEAT
   → Record in MENU set linked to pet
   
4️⃣ AGENDA (Vaccine dates/deworming/exercises)
   → Extract dates and events
   → Record in AGENDA set linked to pet

═══════════════════════════════════════════════════════════════
📦 OUTPUT STRUCTURE (Unified JSON)
═══════════════════════════════════════════════════════════════

ALWAYS return this unified envelope:

{
  "target_pet": "Pet Name",
  "category": "RACA_ID | SAUDE | CARDAPIO | AGENDA",
  "data_payload": {
    // Category specific data here
  },
  "metadata": {
    "has_existing_profile": true|false,
    "timestamp": "ISO-8601",
    "linked_breed_data": "Breed info if health scan",
    "confidence_score": 0.0-1.0
  }
}

═══════════════════════════════════════════════════════════════
🔗 INTEGRATION RULES
═══════════════════════════════════════════════════════════════

✅ Dashboard queries join the 4 sets where target_pet matches
✅ If HEALTH scan without BREED_ID: Suggest ID scan
✅ Use breed data to personalize diagnoses and menus
✅ NEVER lose the link to the pet name

$langInstr
Mantenha as chaves JSON em inglês conforme especificado.
''';
  }

  /// Edit Profile Mode - Structured data collection and intelligent recalculation
  static String getEditProfilePrompt(Map<String, dynamic> currentData, {String locale = 'pt'}) {
    final normalizedLocale = locale.replaceAll('-', '_');
    String langInstr = "Responda em Português do Brasil (PT-BR).";
    
    if (normalizedLocale.startsWith('en')) {
      langInstr = "Respond in English.";
    } else if (normalizedLocale.startsWith('es')) {
      langInstr = "Responda en Español.";
    }

    return '''
MODE: ScanNut PROFILE MANAGER - STRUCTURED EDIT

**MISSION**: Collect and organize complete pet information for biological profile refinement.

═══════════════════════════════════════════════════════════════
📋 CURRENT PET DATA
═══════════════════════════════════════════════════════════════

${_formatCurrentData(currentData)}

═══════════════════════════════════════════════════════════════
🔬 CRITICAL BIO-INFORMATION (Collect/Update)
═══════════════════════════════════════════════════════════════

1. Biological Identity:
   - exact_age: (Months or years - precision for vaccines)
   - current_weight: (In kg)
   - activity_level: (Sedentary|Moderate|Active)
   - reproductive_status: (Neutered|Intact)

2. Dietary Restrictions:
   - known_allergies: [List of proteins/vegetables to ban]
   - preferences: [Favorite foods to prioritize]

3. Lifestyle Settings:
   - last_v10_date: (For automatic Agenda alert)
   - last_rabies_date: (For automatic Agenda alert)
   - bath_frequency: (For grooming suggestions)

═══════════════════════════════════════════════════════════════
🧠 INTELLIGENT RECALCULATION LOGIC
═══════════════════════════════════════════════════════════════

**Analysis of Changes:**
- If WEIGHT changed significantly (>10%):
  → Suggest portion adjustment
  → Health alert if outside ideal
- If BREED was altered:
  → Update breed sensitivities
- If ALLERGIES were added:
  → Filter banned ingredients from next menu
- If VACCINE DATE is near (30 days):
  → Create event in Agenda automatically

═══════════════════════════════════════════════════════════════
📦 OUTPUT STRUCTURE
═══════════════════════════════════════════════════════════════

{
  "mode": "EDIT_PROFILE",
  "target_pet": "Pet Name",
  "updated_data": {
    // Fields updated by user
  },
  "triggers": {
    "recalculate_menu": true|false,
    "regenerate_allergen_table": true|false,
    "schedule_vaccine_alert": true|false
  },
  "recommendations": [
    "Smart message about the change"
  ],
  "metadata": {
    "fields_changed": ["current_weight", "known_allergies"],
    "timestamp": "ISO-8601"
  }
}

$langInstr
Mantenha as chaves JSON em inglês.
''';
  }

  static String _formatCurrentData(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    data.forEach((key, value) {
      buffer.writeln('$key: $value');
    });
    return buffer.toString();
  }

  /// Medical Attachment Management - OCR and Document Indexing
  static String getMedicalAttachmentPrompt(String type, String petName, {String locale = 'pt'}) {
    final normalizedLocale = locale.replaceAll('-', '_');
    String langInstr = "Responda em Português do Brasil (PT-BR).";
    
    if (normalizedLocale.startsWith('en')) {
      langInstr = "Respond in English.";
    } else if (normalizedLocale.startsWith('es')) {
      langInstr = "Responda en Español.";
    }

    return '''
MODE: ScanNut MEDICAL DOCUMENT PROCESSOR

**MISSION**: Extract medical technical information from documents attached to the pet's profile ($petName).

DOCUMENT CATEGORY: $type

═══════════════════════════════════════════════════════════════
📋 EXTRACTION LOGIC
═══════════════════════════════════════════════════════════════

1. VACCINES:
   - Identify Name, Date and Batch
   - Identify Expiration/Next Dose
2. LAB EXAMS (OCR Context):
   - Extract altered values (High/Low)
   - Explain what each marker means for the pet
3. PRESCRIPTIONS:
   - Identify Drug, Dosage and Duration
   - Detect if it's for a current symptom (Wound/Health Scan)

═══════════════════════════════════════════════════════════════
📦 OUTPUT STRUCTURE
═══════════════════════════════════════════════════════════════

{
  "category": "$type",
  "extracted_data": {
    // Structured data here
  },
  "explanation": "Clear explanation for the owner",
  "alerts": ["Clinical alerts if values are critical"]
}

$langInstr
Mantenha as chaves JSON em inglês.
''';
  }

  /// Biometric Time Series - Weight/Height tracking and trend analysis
  static String getBiometricTimeSeriesPrompt(List<Map<String, dynamic>> weightHistory, {String locale = 'pt'}) {
    final normalizedLocale = locale.replaceAll('-', '_');
    String langInstr = "Responda em Português do Brasil (PT-BR).";
    
    if (normalizedLocale.startsWith('en')) {
      langInstr = "Respond in English.";
    } else if (normalizedLocale.startsWith('es')) {
      langInstr = "Responda en Español.";
    }

    return '''
MODE: ScanNut BIOMETRIC ENGINE - WEIGHT TREND ANALYSIS

**MISSION**: Analyze the history of weight variations and generate health projections.

═══════════════════════════════════════════════════════════════
📊 DATA FOR ANALYSIS
═══════════════════════════════════════════════════════════════

$weightHistory

═══════════════════════════════════════════════════════════════
📈 ANALYSIS LOGIC
═══════════════════════════════════════════════════════════════

1. TREND: (Gaining | Losing | Stable)
2. VELOCITY: (% of change per month)
3. PROJECTION: Estimated weight in 3 months if trend continues
4. CALORIC ADJUSTMENT: Recommended change in % of daily kcal

═══════════════════════════════════════════════════════════════
📦 OUTPUT STRUCTURE
═══════════════════════════════════════════════════════════════

{
  "trend": "Gaining | Losing | Stable",
  "percentage_change": "X%",
  "health_status": "Healthy | Warning | Critical",
  "recommendations": ["Advice based on trend"],
  "next_target_weight": "Value in kg"
}

$langInstr
Mantenha as chaves JSON em inglês.
''';
  }

  /// Weekly Menu Generation - Specialized Nutritionist Prompt
  static String getWeeklyMenuPrompt({
    required String petName,
    required String breed,
    required String age,
    required String weight,
    required String goal,
    required String dietType,
    required String startStr,
    required String endStr,
    required int duration,
    required String historyContext,
    required String languageName,
    required String languageInstruction,
  }) {
    return '''
            $languageInstruction
            
            [ROLE]
            ACT AS AN EXCLUSIVE VETERINARY NUTRITIONIST SPECIALIST (ScanNut METHOD).
            Generate a personalized menu for: $petName ($breed, $age, $weight kg).
            Nutritional Goal: $goal.
            Established Diet: $dietType.
            Planning Period: $startStr to $endStr ($duration days).
           
            $historyContext
           
            ⚠️ STRICTOR RULES (ScanNut PROTOCOLS):
            1. Maintain biological consistency. Do not suggest toxic foods (grapes, onions, chocolate, etc.).
            2. The plan must be daily and cover EXACTLY $duration days.
            3. The 'refeicoes' field must be filled for EVERY day.
            4. Mandatory Detailing in the 5 PET HEALTH PILLARS in ALL meals:
               - PROTEIN (Ex: Chicken, Beef, Egg, Fish)
               - HEALTHY FAT (Ex: Olive Oil, Fish Oil)
               - FIBER (Ex: Pumpkin, Zucchini, Carrot)
               - MINERALS (Ex: Specific supplementation, processed eggshell)
               - HYDRATION (Ex: Water, homemade sugar-free broths)
           
            MANDATORY JSON STRUCTURE:
            {
              "plano_semanal": [
                {
                  "dia": "Day of the Week - DD/MM", 
                  "refeicoes": [
                     {
                       "hora": "HH:MM", 
                       "titulo": "Short Meal Name", 
                       "descricao": "Detailed text including the 5 Pillars mentioned above.", 
                       "tipo_dieta": "$dietType"
                     }
                  ]
                }
              ],
              "orientacoes_gerais": "Strategic summary focused on the goal of $goal."
            }
            
            ALL CONTENT (Meal names, descriptions, orientations) MUST BE IN $languageName.
            DO NOT ADD TEXT OUTSIDE THE JSON.
        ''';
  }

  static String getPrompt(ScannutMode mode, {String locale = 'pt', Map<String, String>? contextData}) {
    // Map locale code to full language name and strict instruction
    String languageName;
    String languageInstruction;
    
    // Normalize locale string
    final normalizedLocale = locale.replaceAll('-', '_');
    
    if (normalizedLocale.startsWith('en')) {
      languageName = "English";
      languageInstruction = "Respond in English. CRITICAL: Do not use any Portuguese terms. Translate all plant names and technical symptoms.";
    } else if (normalizedLocale.startsWith('es')) {
      languageName = "Spanish";
      languageInstruction = "Responda en Español. CRITICAL: Traduzca todos los nombres de plantas y términos técnicos.";
    } else if (normalizedLocale == 'pt_PT') {
      languageName = "Portuguese-PT";
      languageInstruction = "Responda em Português de Portugal (ex: telemóvel, frigorífico, sumo).";
    } else {
      // Default to pt_BR
      languageName = "Portuguese-BR";
      languageInstruction = "Responda em Português do Brasil.";
    }
    
    final isPortuguese = languageName.contains('Portuguese');

    switch (mode) {
      case ScannutMode.food:
        return NutritionPrompts.getFoodAnalysisPrompt(languageName, languageInstruction);

      case ScannutMode.plant:
        return BotanyPrompts.getPlantAnalysisPrompt(languageName, languageInstruction, normalizedLocale);

      case ScannutMode.petIdentification:
        return PetPrompts.getPetIdentificationPrompt(languageName, languageInstruction);

      case ScannutMode.petDiagnosis:
        return PetPrompts.getPetDiagnosisPrompt(languageName, languageInstruction, isPortuguese, contextData: contextData);

      case ScannutMode.petVisualAnalysis:
        return getPetVisualPrompt(languageName, languageInstruction, contextData: contextData);

      case ScannutMode.petDocumentOCR:
        return getPetOCRPrompt(languageName, languageInstruction);

      case ScannutMode.petStoolAnalysis:
        return PetPrompts.getPetStoolAnalysisPrompt(languageName, languageInstruction, isPortuguese, contextData: contextData);
    }
  }

  static String getPetVisualPrompt(String languageName, String languageInstruction, {Map<String, String>? contextData}) {
    // 🛡️ Context Injection
    String contextBlock = "";
    final groupId = contextData?['groupId'] ?? 'generic';
    
    // Domain Specific Contextual Instructions
    String specializedInstr = "";
    switch (groupId) {
      case 'food':
      case 'dentistry':
        specializedInstr = "ANALYSIS FOCUS: Objects, food items, bones, or oral tools. EXPLICITLY FORBIDDEN: Do not attempt to identify pet breeds or animals in this specific analysis. Focus on the condition of the object or food quality.";
        break;
      case 'exams':
      case 'medication':
      case 'documents':
        specializedInstr = "ANALYSIS FOCUS: OCR (Text reading). Extract technical terms, dosages, numerical values from charts, and specific medical findings. Precision in text transcription is the priority.";
        break;
      case 'health':
      case 'allergies':
        specializedInstr = "ANALYSIS FOCUS: Clinical symptoms, skin lesions, wounds, or allergic reactions. Describe texture, color, and level of inflammation. Provide urgency level based on clinical appearance.";
        break;
      case 'behavior':
        specializedInstr = "ANALYSIS FOCUS: Posture, facial expression, and behavioral cues. Infer emotional state or physical discomfort from the pet's body language.";
        break;
      case 'grooming':
        specializedInstr = "ANALYSIS FOCUS: Coat condition, cleanliness, nail length, and hygiene highlights. Identify areas that need attention.";
        break;
      default:
        specializedInstr = "ANALYSIS FOCUS: General pet observation. Identify the subject and any noteworthy details relevant to the event category: $groupId.";
    }

    if (contextData != null && (contextData.containsKey('species') || contextData.containsKey('breed'))) {
        contextBlock = '''
        CONTEXT (SOURCE OF TRUTH): 
        Target Pet Species: ${contextData['species'] ?? 'Unknown'}
        Target Pet Breed: ${contextData['breed'] ?? 'Unknown'}
        Category Context: $groupId
        
        $specializedInstr
        
        INSTRUCTION: You are analyzing THIS specific pet. Do not infer a different species or breed unless the image clearly shows otherwise (and even then, stay focused on the clinical/category context).
        Customize your analysis for a ${contextData['breed']}.
        ''';
    } else {
        contextBlock = '''
        Category Context: $groupId
        $specializedInstr
        ''';
    }

    return '''
            $languageInstruction
            $contextBlock
            
            [ROLE]
            ACT AS A VETERINARY SPECIALIST (ScanNut OMNI-ENGINE).
            Analyze the attached image based on the specific CATEGORY CONTEXT provided.
            
            MISSION:
            1. Describe VISUAL FINDINGS accurately for the category: $groupId.
            2. Identify potential CAUSES or technical data if it's a document/test.
            3. Suggest immediate ACTIONS and urgency level.
            
            OUTPUT FORMAT (JSON):
            {
              "type": "Visual Analysis ($groupId)",
              "summary": "Short context-aware summary",
              "details": "Detailed visual or technical description",
              "alerts": ["Urgency level", "Critical findings"]
            }
            Respond in $languageName. Keep keys in English.
    ''';
  }

  static String getPetOCRPrompt(String languageName, String languageInstruction, {Map<String, String>? contextData}) {
    final groupId = contextData?['groupId'] ?? 'documents';
    
    return '''
            $languageInstruction
            
            [ROLE]
            ACT AS A MEDICAL DATA EXTRACTION SPECIALIST (ScanNut OCR ENGINE).
            Extract text from the attached document (Lab Result, Prescription, Invoice).
            Category context: $groupId.
            
            MISSION:
            1. Transcribe formatted text accurately.
            2. Extract NUMERICAL VALUES and UNITS (especially for blood/urine tests).
            3. Identify MEDICATIONS, DOSAGES and DURATION from prescriptions.
            
            OUTPUT FORMAT (JSON):
            {
              "type": "Document/OCR ($groupId)",
              "summary": "Document type and main finding",
              "details": "Full extracted text or structured values",
              "alerts": ["Abnormal values (High/Low)", "Warnings/Interactions"]
            }
            Respond in $languageName. Keep keys in English.
    ''';
  }

}
