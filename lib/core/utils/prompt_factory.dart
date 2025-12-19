import '../enums/scannut_mode.dart';

class PromptFactory {
  static String getPrompt(ScannutMode mode) {
    const languageInstruction = "IMPORTANT: Answer all string values in the JSON in Portuguese (pt-BR). Keep the JSON keys exactly as requested in English.";

    switch (mode) {
      case ScannutMode.food:
        return '''
Act as a professional nutritionist. Analyze the provided image. Identify all food items. Estimate portion sizes. 
Return a STRICT JSON object (no markdown) with: 
{
  "item_name": "string", 
  "estimated_calories": integer, 
  "macronutrients": {
    "protein": "string", 
    "carbs": "string", 
    "fats": "string"
  }, 
  "benefits": ["list of strings"], 
  "risks": ["list of strings"], 
  "advice": "string"
}. 
Use a friendly but scientific tone. If the image is not food, return {"error": "not_food"}.
$languageInstruction
''';

      case ScannutMode.plant:
        return '''
Act as a botanist and plant pathologist. Analyze the leaf in the image. Identify the plant species and detect any signs of disease, pests, or nutrient deficiency. 
Return a STRICT JSON object (no markdown) with: 
{
  "plant_name": "string", 
  "condition": "string", 
  "diagnosis": "string", 
  "organic_treatment": "string", 
  "urgency": "low" | "medium" | "high"
}. 
If the plant is healthy, celebrate it in the condition field. If not a plant, return {"error": "not_plant"}.
$languageInstruction
''';

      case ScannutMode.pet:
        return '''
Act as a veterinary triage assistant. Analyze the visible wound or skin condition in the pet's photo. Describe the visual patterns. 
Return a STRICT JSON object (no markdown) with: 
{
  "species": "string", 
  "visual_description": "string", 
  "possible_causes": ["list of strings"], 
  "urgency_level": "Verde" | "Amarelo" | "Vermelho", 
  "immediate_care": "string"
}. 
IMPORTANT: Include a disclaimer in the immediate_care that this is not a medical diagnosis. 
Rules for Urgency Level:
- Verde: Observation (aesthetic or mild).
- Amarelo: Attention (monitor or non-urgent consult).
- Vermelho: Emergency (seek vet immediately).
If no pet/wound is found, return {"error": "not_detected"}.
$languageInstruction
''';
    }
  }
}
