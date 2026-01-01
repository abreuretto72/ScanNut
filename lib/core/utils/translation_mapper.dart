import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class TranslationMapper {
  /// Maps food names/categories to localized strings
  static String localizeFoodName(String rawName, AppLocalizations l10n) {
    final key = rawName.toLowerCase().trim();

    // English specific overrides for WeeklyPlanGenerator hardcoded strings
    if (l10n.localeName.startsWith('en')) {
       if (rawName.contains(' com Acompanhamentos')) {
          final main = rawName.split(' com ')[0];
          return '${localizeFoodName(main, l10n)} with Sides';
       }
       if (key.contains('pizza caseira')) return 'Homemade Skillet Pizza';
       if (key.contains('rap10') || key.contains('tortilha')) return 'Tortilla Wrap';
       if (key.contains('bife de alcatra')) return 'Rump Steak';
       if (key.contains('bife')) return 'Steak';
       if (key.contains('molho de tomate')) return 'Tomato Sauce';
       
       // Smoothies and Breakfast
       if (key.contains('vitamina de abacate')) return 'Avocado Smoothie with Oats';
       if (key.contains('vitamina')) return 'Smoothie';
       if (key.contains('aveia')) return 'Oats';
       if (key.contains('mel')) return 'Honey';
       if (key.contains('shoyu')) return 'Soy Sauce';
       
       if (key.contains('refeição livre')) return 'Free Meal';
       if (key.contains('café simples')) return 'Simple Breakfast';
       if (key.contains('prato feito')) return 'Balanced Meal';
       if (key.contains('iogurte com acompanhamento')) return 'Yogurt with Side';
       if (key.contains('sanduíche')) return 'Sandwich';
       if (key.contains('salada de frutas')) return 'Fruit Salad';
       if (key.contains('cafézinho')) return 'Coffee';
    }

    // Map common items
    if (key.contains('arroz') || key.contains('rice')) return l10n.foodRice;
    if (key.contains('feijão') || key.contains('feijao') || key.contains('beans')) return l10n.foodBeans;
    if (key.contains('frango') || key.contains('chicken') || key.contains('pollo')) return l10n.foodChicken;
    if (key.contains('carne') || key.contains('meat') || key.contains('carne de res')) return l10n.foodMeat;
    if (key.contains('peixe') || key.contains('fish') || key.contains('pescado')) return l10n.foodFish;
    if (key.contains('ovo') || key.contains('egg') || key.contains('huevo')) return l10n.foodEgg;
    if (key.contains('pão') || key.contains('pao') || key.contains('bread') || key.contains('pan')) return l10n.foodBread;
    if (key.contains('leite') || key.contains('milk') || key.contains('leche')) return l10n.foodMilk;
    if (key.contains('café') || key.contains('cafe') || key.contains('coffee')) return l10n.foodCoffee;
    if (key.contains('iogurte') || key.contains('yogurt') || key.contains('yogur')) return l10n.foodYogurt;
    if (key.contains('fruta') || key.contains('fruit')) return l10n.foodFruit;
    if (key.contains('salada') || key.contains('salad') || key.contains('ensalada')) return l10n.foodSalad;
    if (key.contains('legume') || key.contains('vegetable') || key.contains('verdura')) return l10n.foodVegetables;
    if (key.contains('macarrão') || key.contains('macarrao') || key.contains('pasta')) return l10n.foodPasta;
    if (key.contains('batata') || key.contains('potato') || key.contains('papa')) return l10n.foodPotato;
    if (key.contains('mandioca') || key.contains('cassava') || key.contains('yuca')) return l10n.foodCassava;
    if (key.contains('queijo') || key.contains('cheese') || key.contains('queso')) return l10n.foodCheese;
    if (key.contains('suco') || key.contains('juice') || key.contains('zumo')) return l10n.foodJuice;
    if (key.contains('água') || key.contains('agua') || key.contains('water')) return l10n.foodWater;
    
    // New mappings for common ingredients
    if (key.contains('maçã') || key.contains('maca') || key.contains('apple')) return l10n.foodApple;
    if (key.contains('banana')) return l10n.foodBanana;
    if (key.contains('milho') || key.contains('corn')) return l10n.foodCorn;
    if (key.contains('ervilha') || key.contains('pea')) return l10n.foodPeas;
    if (key.contains('cenoura') || key.contains('carrot')) return l10n.foodCarrot;
    if (key.contains('tomate') || key.contains('tomato')) return l10n.foodTomato;
    if (key.contains('cebola') || key.contains('onion')) return l10n.foodOnion;
    if (key.contains('alho') || key.contains('garlic')) return l10n.foodGarlic;
    if (key.contains('laranja') || key.contains('orange')) return l10n.foodOrange;
    if (key.contains('abacaxi') || key.contains('pineapple')) return l10n.foodPineapple;

    // Fallback: Return capitalized raw name if no match found
    return rawName; // Or wrap in a "Needs Translation" indicator if strict mode needed
  }

  /// Maps loading states to localized strings
  static String localizeLoadingMessage(String key, AppLocalizations l10n) {
    switch (key) {
      case 'loadingFood': return l10n.loadingFood;
      case 'loadingPlant': return l10n.loadingPlant;
      case 'loadingPetBreed': return l10n.loadingPetBreed;
      case 'loadingPetHealth': return l10n.loadingPetHealth;
      default: return key;
    }
  }

  /// Helper to translate batch cooking tips directly from keys
  static String localizeTip(String tipKey, AppLocalizations l10n) {
    switch (tipKey) {
      case 'tipBeans': return l10n.tipBeans;
      case 'tipRice': return l10n.tipRice;
      case 'tipChicken': return l10n.tipChicken;
      case 'tipEggs': return l10n.tipEggs;
      case 'tipVeggies': return l10n.tipVeggies;
      case 'tipRoots': return l10n.tipRoots;
      case 'tipGroundMeat': return l10n.tipGroundMeat;
      case 'tipFruits': return l10n.tipFruits;
      case 'tipDefault': return l10n.tipDefault;
      default: return tipKey;
    }
  }
}
