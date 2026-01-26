// 🛡️ CONSTANTES BLINDADAS - MÓDULO ALIMENTARV 1.0
// "O Cofre": Nenhuma importação externa permitida.

class FoodConstants {
  // 1. Definições de Rede (Imunidade)
  static const String endpoint = 
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent';
  
  static const String packageName = 'com.multiversodigital.scannut';
  static const String sha1Fingerprint = 'AC:92:22:DC:06:3F:B2:A5:00:05:6B:40:AE:6F:3E:44:E2:A9:5F:F6';

  // 2. O Prompt Soberano de Nutrição (Lei de Ferro)
  static const String systemPrompt = '''
ATUE COMO UM NUTRICIONISTA CLÍNICO E ESPECIALISTA EM BIOHACKING.
Analise a imagem da refeição e retorne ESTRITAMENTE um JSON plano com alta precisão técnica.

REGRAS DE OURO:
1. Identifique o alimento principal e acompanhamentos.
2. Estime as calorias para uma porção padrão (100g ou unidade).
3. Seja preciso nos macros (Proteína, Carbo, Gordura).
4. Identifique alérgenos (Glúten, Lactose, Amendoim, etc).
5. Forneça o "Biohacking Score": Saciedade (1-10), Impacto no Foco (Ex: Estável, Pico, Queda) e Momento Ideal (Ex: Pré-treino, Jantar).
6. Inteligência Culinária: Dica de conservação de nutrientes e "Smart Swap" (troca saudável).
7. Prós (ex: Rico em fibras) e Contras (ex: Alto sódio).

SCHEMA JSON OBRIGATÓRIO (Sem Markdown, Sem Negrito):
{
  "resumo": {
    "food_name": "Nome do prato",
    "calories_kcal": 0,
    "health_score": 0,
    "recommendation": "Dica rápida",
    "allergens": []
  },
  "saude_biohacking": {
    "satiety_index": 0,
    "focus_impact": "impacto",
    "ideal_moment": "momento",
    "pros": [],
    "cons": []
  },
  "nutrientes_detalhado": {
    "macros": {"protein_g": 0.0, "carbs_g": 0.0, "fat_g": 0.0},
    "micros": [
      {"name": "Ferro", "value": "10mg", "dv_percent": 15},
      {"name": "Sódio", "value": "200mg", "dv_percent": 8}
    ],
    "synergy": "Texto sobre absorção"
  },
  "gastronomia": {
    "prep_tip": "dica preservação",
    "smart_swap": "troca",
    "recipes": [
      {
        "name": "nome",
        "instructions": "passos (máx 3 etapas)",
        "prep_time": "15 min",
        "justification": "justificativa nutricional",
        "difficulty": "Fácil",
        "calories": "200kcal"
      },
      { "name": ".", "instructions": ".", "prep_time": ".", "justification": ".", "difficulty": ".", "calories": "." },
      { "name": ".", "instructions": ".", "prep_time": ".", "justification": ".", "difficulty": ".", "calories": "." }
    ]
  }
}
''';

  // 3. Mapeamento de Sinônimos (Dicionário de Defesa)
  // Usado pelo Model.fromGemini para pescar valores mesmo se a IA mudar o idioma
  static const Map<String, List<String>> keySynonyms = {
    'food_name': ['alimento', 'prato', 'item', 'name', 'nome'],
    'calories_kcal': ['kcal', 'calorias', 'calories', 'energy', 'valor_energetico'],
    'protein_g': ['proteinas', 'protein', 'prot', 'proteina'],
    'carbs_g': ['carboidratos', 'carbs', 'carb', 'hco'],
    'fat_g': ['gorduras', 'fat', 'lipidios', 'gordura'],
    'health_score': ['nivel_saude', 'score', 'nota', 'saudabilidade'],
  };
}
