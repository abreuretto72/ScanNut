import '../models/food_recipe_suggestion.dart';

class EmergencyRecipes {
  static List<RecipeSuggestion> getFallback(String foodName) {
    final lower = foodName.toLowerCase();
    
    // 1. Protein/Meat Fallback
    if (lower.contains('frango') || lower.contains('carne') || lower.contains('peixe') || lower.contains('ovo')) {
      return [
        _build("Grelhado com Ervas Finas", "Tempere com azeite, alecrim e limão. Grelhe por 5-7 min de cada lado.", "20 min", "Baixa", "Proteína Pura", "200", foodName),
        _build("Salada Proteica Rápida", "Desfie/Corte em cubos, misture com folhas verdes, tomate e pepino.", "10 min", "Baixa", "Leve e nutritivo", "250", foodName),
        _build("Wrap Funcional", "Use folha de couve ou wrap integral, adicione o item com ricota e cenoura.", "15 min", "Média", "Rico em fibras", "300", foodName),
      ];
    }

    // 2. Veggies/Fruits Fallback
    if (lower.contains('salada') || lower.contains('legume') || lower.contains('fruta') || lower.contains('folha')) {
      return [
        _build("Bowl Nutritivo", "Misture com quinoa, sementes de abóbora e um fio de azeite.", "10 min", "Baixa", "Antioxidante", "150", foodName),
        _build("Assado Rústico", "Corte em pedaços, tempere com sal rosa e asse a 200°C por 20 min.", "30 min", "Média", "Sabor intenso", "180", foodName),
        _build("Suco Detox Potente", "Bata com gengibre, limão e água de coco.", "5 min", "Baixa", "Hidratação", "90", foodName),
      ];
    }

    // 3. Carbs/Grains Fallback
    if (lower.contains('arroz') || lower.contains('pão') || lower.contains('massa') || lower.contains('batata')) {
      return [
        _build("Salada de Grãos", "Combine com vegetais picados e azeite de oliva.", "15 min", "Baixa", "Energia estável", "250", foodName),
        _build("Bolinho Assado Fit", "Misture com ovo e aveia, modele e asse até dourar.", "25 min", "Média", "Snack saudável", "180", foodName),
        _build("Refogado Colorido", "Salteie com espinafre, alho e cebola roxa.", "15 min", "Baixa", "Rico em micronutrientes", "200", foodName),
      ];
    }

    // 4. Generic/Fat/Other Fallback
    return [
      _build("Mix Inteligente", "Combine pequena porção com castanhas ou frutas para equilíbrio.", "5 min", "Baixa", "Controle glicêmico", "150", foodName),
      _build("Topping Funcional", "Adicione sobre uma salada ou iogurte natural.", "2 min", "Baixa", "Sabor extra", "100", foodName),
      _build("Preparo Grelhado Simples", "Use pouco óleo, prefira grill ou airfryer para reduzir gorduras.", "15 min", "Baixa", "Redução calórica", "200", foodName),
    ];
  }

  static RecipeSuggestion _build(String name, String instr, String time, String diff, String just, String cal, String source) {
    String formattedCal = cal;
    if (!formattedCal.contains('\u00B1')) {
      formattedCal = '\u00B1 $formattedCal';
    }
    if (!formattedCal.toLowerCase().contains('kcal')) {
      formattedCal = '$formattedCal kcal';
    }

    return RecipeSuggestion(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: source.isNotEmpty ? "$source: $name" : name,
      instructions: instr,
      prepTime: time,
      difficulty: diff,
      justification: just,
      calories: formattedCal,
      sourceFood: source,
    );
  }
}
