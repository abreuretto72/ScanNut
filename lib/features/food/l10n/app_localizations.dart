import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of FoodLocalizations
/// returned by `FoodLocalizations.of(context)`.
///
/// Applications need to include `FoodLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: FoodLocalizations.localizationsDelegates,
///   supportedLocales: FoodLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the FoodLocalizations.supportedLocales
/// property.
abstract class FoodLocalizations {
  FoodLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static FoodLocalizations? of(BuildContext context) {
    return Localizations.of<FoodLocalizations>(context, FoodLocalizations);
  }

  static const LocalizationsDelegate<FoodLocalizations> delegate = _FoodLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt')
  ];

  /// No description provided for @foodTabTitle.
  ///
  /// In pt, this message translates to:
  /// **'Comida'**
  String get foodTabTitle;

  /// No description provided for @foodHint.
  ///
  /// In pt, this message translates to:
  /// **'Aponte a câmera para a comida/refeição'**
  String get foodHint;

  /// No description provided for @foodLoading.
  ///
  /// In pt, this message translates to:
  /// **'Analisando a imagem de comida...'**
  String get foodLoading;

  /// No description provided for @foodNutrientsAdvanced.
  ///
  /// In pt, this message translates to:
  /// **'Macronutrientes Avançados'**
  String get foodNutrientsAdvanced;

  /// No description provided for @foodNutrientsProteins.
  ///
  /// In pt, this message translates to:
  /// **'Proteínas'**
  String get foodNutrientsProteins;

  /// No description provided for @foodNutrientsCarbs.
  ///
  /// In pt, this message translates to:
  /// **'Carboidratos'**
  String get foodNutrientsCarbs;

  /// No description provided for @foodNutrientsFats.
  ///
  /// In pt, this message translates to:
  /// **'Gorduras'**
  String get foodNutrientsFats;

  /// No description provided for @foodNutrientsMinerals.
  ///
  /// In pt, this message translates to:
  /// **'Minerais e Vitaminas'**
  String get foodNutrientsMinerals;

  /// No description provided for @foodNutrientsSynergy.
  ///
  /// In pt, this message translates to:
  /// **'Sinergia'**
  String get foodNutrientsSynergy;

  /// No description provided for @foodRecipesQuick.
  ///
  /// In pt, this message translates to:
  /// **'Receitas Rápidas (até 15 min)'**
  String get foodRecipesQuick;

  /// No description provided for @foodRecipesCulinaryIntel.
  ///
  /// In pt, this message translates to:
  /// **'Inteligência Culinária'**
  String get foodRecipesCulinaryIntel;

  /// No description provided for @foodRecipesExpertTip.
  ///
  /// In pt, this message translates to:
  /// **'Dica do Especialista'**
  String get foodRecipesExpertTip;

  /// No description provided for @foodLabelGlycemicImpact.
  ///
  /// In pt, this message translates to:
  /// **'Impacto Glicêmico'**
  String get foodLabelGlycemicImpact;

  /// No description provided for @foodLabelFattyAcids.
  ///
  /// In pt, this message translates to:
  /// **'Ácidos Graxos'**
  String get foodLabelFattyAcids;

  /// No description provided for @foodLabelAminoProfile.
  ///
  /// In pt, this message translates to:
  /// **'Perfil de Aminoácidos'**
  String get foodLabelAminoProfile;

  /// No description provided for @foodSafetyBio.
  ///
  /// In pt, this message translates to:
  /// **'Segurança & Bioquímica'**
  String get foodSafetyBio;

  /// No description provided for @foodIdealMoment.
  ///
  /// In pt, this message translates to:
  /// **'Momento Ideal'**
  String get foodIdealMoment;

  /// No description provided for @foodCriticalAlerts.
  ///
  /// In pt, this message translates to:
  /// **'Alertas Críticos'**
  String get foodCriticalAlerts;

  /// No description provided for @foodBioChem.
  ///
  /// In pt, this message translates to:
  /// **'Bioquímica e Neutralização'**
  String get foodBioChem;

  /// No description provided for @foodPreservation.
  ///
  /// In pt, this message translates to:
  /// **'Preservação'**
  String get foodPreservation;

  /// No description provided for @foodSmartSwap.
  ///
  /// In pt, this message translates to:
  /// **'Smart Swap (Troca)'**
  String get foodSmartSwap;

  /// No description provided for @foodDisclaimer.
  ///
  /// In pt, this message translates to:
  /// **'Nota: As informações nutricionais são estimadas. Consulte sempre um profissional de saúde.'**
  String get foodDisclaimer;

  /// No description provided for @foodVerdict.
  ///
  /// In pt, this message translates to:
  /// **'Veredito da IA'**
  String get foodVerdict;

  /// No description provided for @foodPros.
  ///
  /// In pt, this message translates to:
  /// **'Pontos Positivos'**
  String get foodPros;

  /// No description provided for @foodCons.
  ///
  /// In pt, this message translates to:
  /// **'Pontos de Atenção'**
  String get foodCons;

  /// No description provided for @foodBiohacking.
  ///
  /// In pt, this message translates to:
  /// **'Performance Biohacking'**
  String get foodBiohacking;

  /// No description provided for @foodSatietyIndex.
  ///
  /// In pt, this message translates to:
  /// **'Índice de Saciedade'**
  String get foodSatietyIndex;

  /// No description provided for @foodBodyBenefits.
  ///
  /// In pt, this message translates to:
  /// **'Benefícios para o Corpo'**
  String get foodBodyBenefits;

  /// No description provided for @foodAttention.
  ///
  /// In pt, this message translates to:
  /// **'Atenção'**
  String get foodAttention;

  /// No description provided for @foodFocusEnergy.
  ///
  /// In pt, this message translates to:
  /// **'Foco e Energia'**
  String get foodFocusEnergy;

  /// No description provided for @foodHistoryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Histórico das Comidas'**
  String get foodHistoryTitle;

  /// No description provided for @foodHistoryEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma análise salva ainda.'**
  String get foodHistoryEmpty;

  /// No description provided for @foodReload.
  ///
  /// In pt, this message translates to:
  /// **'Recarregar'**
  String get foodReload;

  /// No description provided for @foodKcalPer100g.
  ///
  /// In pt, this message translates to:
  /// **'kcal / 100g'**
  String get foodKcalPer100g;

  /// No description provided for @foodProt.
  ///
  /// In pt, this message translates to:
  /// **'Prot.'**
  String get foodProt;

  /// No description provided for @foodCarb.
  ///
  /// In pt, this message translates to:
  /// **'Carb.'**
  String get foodCarb;

  /// No description provided for @foodFat.
  ///
  /// In pt, this message translates to:
  /// **'Gord.'**
  String get foodFat;

  /// No description provided for @foodDeleteConfirmTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir Análise?'**
  String get foodDeleteConfirmTitle;

  /// No description provided for @foodDeleteConfirmContent.
  ///
  /// In pt, this message translates to:
  /// **'Esta ação não pode ser desfeita.'**
  String get foodDeleteConfirmContent;

  /// No description provided for @foodRice.
  ///
  /// In pt, this message translates to:
  /// **'Arroz'**
  String get foodRice;

  /// No description provided for @foodBeans.
  ///
  /// In pt, this message translates to:
  /// **'Feijão'**
  String get foodBeans;

  /// No description provided for @foodChicken.
  ///
  /// In pt, this message translates to:
  /// **'Frango'**
  String get foodChicken;

  /// No description provided for @foodMeat.
  ///
  /// In pt, this message translates to:
  /// **'Carne'**
  String get foodMeat;

  /// No description provided for @foodFish.
  ///
  /// In pt, this message translates to:
  /// **'Peixe'**
  String get foodFish;

  /// No description provided for @foodEgg.
  ///
  /// In pt, this message translates to:
  /// **'Ovo'**
  String get foodEgg;

  /// No description provided for @foodBread.
  ///
  /// In pt, this message translates to:
  /// **'Pão'**
  String get foodBread;

  /// No description provided for @foodMilk.
  ///
  /// In pt, this message translates to:
  /// **'Leite'**
  String get foodMilk;

  /// No description provided for @foodCoffee.
  ///
  /// In pt, this message translates to:
  /// **'Café'**
  String get foodCoffee;

  /// No description provided for @foodYogurt.
  ///
  /// In pt, this message translates to:
  /// **'Iogurte'**
  String get foodYogurt;

  /// No description provided for @foodFruit.
  ///
  /// In pt, this message translates to:
  /// **'Fruta'**
  String get foodFruit;

  /// No description provided for @foodSalad.
  ///
  /// In pt, this message translates to:
  /// **'Salada'**
  String get foodSalad;

  /// No description provided for @foodVegetables.
  ///
  /// In pt, this message translates to:
  /// **'Legumes'**
  String get foodVegetables;

  /// No description provided for @foodPasta.
  ///
  /// In pt, this message translates to:
  /// **'Macarrão'**
  String get foodPasta;

  /// No description provided for @foodPotato.
  ///
  /// In pt, this message translates to:
  /// **'Batata'**
  String get foodPotato;

  /// No description provided for @foodCassava.
  ///
  /// In pt, this message translates to:
  /// **'Mandioca'**
  String get foodCassava;

  /// No description provided for @foodCheese.
  ///
  /// In pt, this message translates to:
  /// **'Queijo'**
  String get foodCheese;

  /// No description provided for @foodJuice.
  ///
  /// In pt, this message translates to:
  /// **'Suco'**
  String get foodJuice;

  /// No description provided for @foodWater.
  ///
  /// In pt, this message translates to:
  /// **'Água'**
  String get foodWater;

  /// No description provided for @foodApple.
  ///
  /// In pt, this message translates to:
  /// **'Maçã'**
  String get foodApple;

  /// No description provided for @foodBanana.
  ///
  /// In pt, this message translates to:
  /// **'Banana'**
  String get foodBanana;

  /// No description provided for @foodCorn.
  ///
  /// In pt, this message translates to:
  /// **'Milho'**
  String get foodCorn;

  /// No description provided for @foodPeas.
  ///
  /// In pt, this message translates to:
  /// **'Ervilha'**
  String get foodPeas;

  /// No description provided for @foodCarrot.
  ///
  /// In pt, this message translates to:
  /// **'Cenoura'**
  String get foodCarrot;

  /// No description provided for @foodTomato.
  ///
  /// In pt, this message translates to:
  /// **'Tomate'**
  String get foodTomato;

  /// No description provided for @foodOnion.
  ///
  /// In pt, this message translates to:
  /// **'Cebola'**
  String get foodOnion;

  /// No description provided for @foodGarlic.
  ///
  /// In pt, this message translates to:
  /// **'Alho'**
  String get foodGarlic;

  /// No description provided for @foodOrange.
  ///
  /// In pt, this message translates to:
  /// **'Laranja'**
  String get foodOrange;

  /// No description provided for @foodPineapple.
  ///
  /// In pt, this message translates to:
  /// **'Abacaxi'**
  String get foodPineapple;

  /// No description provided for @foodUnknown.
  ///
  /// In pt, this message translates to:
  /// **'Alimento Desconhecido'**
  String get foodUnknown;

  /// No description provided for @foodDate.
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get foodDate;

  /// No description provided for @foodCalories.
  ///
  /// In pt, this message translates to:
  /// **'Calorias'**
  String get foodCalories;

  /// No description provided for @foodTrafficLight.
  ///
  /// In pt, this message translates to:
  /// **'Semáforo'**
  String get foodTrafficLight;

  /// No description provided for @foodProcessing.
  ///
  /// In pt, this message translates to:
  /// **'Processamento'**
  String get foodProcessing;

  /// No description provided for @foodExSummary.
  ///
  /// In pt, this message translates to:
  /// **'Resumo Executivo'**
  String get foodExSummary;

  /// No description provided for @foodAiVerdict.
  ///
  /// In pt, this message translates to:
  /// **'Veredito da IA'**
  String get foodAiVerdict;

  /// No description provided for @foodDetailedNutrition.
  ///
  /// In pt, this message translates to:
  /// **'Nutrição Detalhada'**
  String get foodDetailedNutrition;

  /// No description provided for @foodMacros.
  ///
  /// In pt, this message translates to:
  /// **'Macronutrientes'**
  String get foodMacros;

  /// No description provided for @foodNutrient.
  ///
  /// In pt, this message translates to:
  /// **'Nutriente'**
  String get foodNutrient;

  /// No description provided for @foodQuantity.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade'**
  String get foodQuantity;

  /// No description provided for @foodDetails.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes'**
  String get foodDetails;

  /// No description provided for @foodMicros.
  ///
  /// In pt, this message translates to:
  /// **'Micronutrientes e Vitaminas'**
  String get foodMicros;

  /// No description provided for @foodSynergy.
  ///
  /// In pt, this message translates to:
  /// **'Sinergia Nutricional'**
  String get foodSynergy;

  /// No description provided for @foodPerformance.
  ///
  /// In pt, this message translates to:
  /// **'Performance'**
  String get foodPerformance;

  /// No description provided for @foodSatiety.
  ///
  /// In pt, this message translates to:
  /// **'Índice de Saciedade'**
  String get foodSatiety;

  /// No description provided for @foodFocus.
  ///
  /// In pt, this message translates to:
  /// **'Foco e Energia'**
  String get foodFocus;

  /// No description provided for @foodSecurity.
  ///
  /// In pt, this message translates to:
  /// **'Segurança'**
  String get foodSecurity;

  /// No description provided for @foodAlerts.
  ///
  /// In pt, this message translates to:
  /// **'Alertas'**
  String get foodAlerts;

  /// No description provided for @foodBiochem.
  ///
  /// In pt, this message translates to:
  /// **'Bioquímica'**
  String get foodBiochem;

  /// No description provided for @foodGastronomy.
  ///
  /// In pt, this message translates to:
  /// **'Gastronomia e Dicas'**
  String get foodGastronomy;

  /// No description provided for @foodQuickRecipes.
  ///
  /// In pt, this message translates to:
  /// **'Receitas Rápidas'**
  String get foodQuickRecipes;

  /// No description provided for @foodGeneratedBy.
  ///
  /// In pt, this message translates to:
  /// **'Gerado por ScanNut'**
  String get foodGeneratedBy;

  /// No description provided for @foodPage.
  ///
  /// In pt, this message translates to:
  /// **'Página {current} de {total}'**
  String foodPage(Object current, Object total);

  /// No description provided for @foodMenuPlanTitle.
  ///
  /// In pt, this message translates to:
  /// **'Planejamento de Cardápio Inteligente'**
  String get foodMenuPlanTitle;

  /// No description provided for @foodMenuPlanDesc.
  ///
  /// In pt, this message translates to:
  /// **'Crie cardápios semanais personalizados baseados nas suas metas e restrições alimentares.'**
  String get foodMenuPlanDesc;

  /// No description provided for @foodPersonalizedPlanTitle.
  ///
  /// In pt, this message translates to:
  /// **'PLANO ALIMENTAR PERSONALIZADO'**
  String get foodPersonalizedPlanTitle;

  /// No description provided for @foodGoalLabel.
  ///
  /// In pt, this message translates to:
  /// **'OBJETIVO'**
  String get foodGoalLabel;

  /// No description provided for @foodGeneratedByLine.
  ///
  /// In pt, this message translates to:
  /// **'RELATÓRIO DE NUTRIÇÃO SEMANAL GERADO POR ScanNut AI'**
  String get foodGeneratedByLine;

  /// No description provided for @foodBatchCookingTips.
  ///
  /// In pt, this message translates to:
  /// **'💡 DICAS DE BATCH COOKING & PREPARO'**
  String get foodBatchCookingTips;

  /// No description provided for @foodTipBeans.
  ///
  /// In pt, this message translates to:
  /// **'💡 Cozinhe uma panela grande de feijão logo no início da semana e congele porções para economizar gás e tempo.'**
  String get foodTipBeans;

  /// No description provided for @foodTipRice.
  ///
  /// In pt, this message translates to:
  /// **'💡 Mantenha uma base de arroz branco pronta na geladeira; ele é o acompanhamento coringa para quase todos os seus PFs.'**
  String get foodTipRice;

  /// No description provided for @foodTipChicken.
  ///
  /// In pt, this message translates to:
  /// **'💡 Cozinhe e desfie o frango de uma única vez. Use-o no sanduíche natural, no wrap e no mexidão de sexta.'**
  String get foodTipChicken;

  /// No description provided for @foodTipEggs.
  ///
  /// In pt, this message translates to:
  /// **'💡 Ovos são sua proteína econômica e rápida. Mantenha-os sempre à mão para substituir carnes em dias corridos.'**
  String get foodTipEggs;

  /// No description provided for @foodTipVeggies.
  ///
  /// In pt, this message translates to:
  /// **'💡 Lave e pique todos os vegetais da estação assim que chegar do mercado. Guarde-os em potes herméticos para durarem mais.'**
  String get foodTipVeggies;

  /// No description provided for @foodTipRoots.
  ///
  /// In pt, this message translates to:
  /// **'💡 Raízes como mandioca e batata doce podem ser cozidas em grande quantidade e guardadas na água na geladeira por 3 dias.'**
  String get foodTipRoots;

  /// No description provided for @foodTipGroundMeat.
  ///
  /// In pt, this message translates to:
  /// **'💡 A carne moída é a base perfeita: use-a pura no almoço e no recheio da panqueca ou sanduíche no dia seguinte.'**
  String get foodTipGroundMeat;

  /// No description provided for @foodTipFruits.
  ///
  /// In pt, this message translates to:
  /// **'💡 Frutas muito maduras? Congele-as em pedaços para turbinar suas vitaminas e smoothies matinais.'**
  String get foodTipFruits;

  /// No description provided for @foodTipDefault.
  ///
  /// In pt, this message translates to:
  /// **'Planeje suas compras com foco em itens da estação para economizar e ganhar saúde.'**
  String get foodTipDefault;

  /// No description provided for @foodMenuCreationTitle.
  ///
  /// In pt, this message translates to:
  /// **'Criar Cardápio da Semana'**
  String get foodMenuCreationTitle;

  /// No description provided for @foodMenuCreationSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Configure como você quer seu cardápio'**
  String get foodMenuCreationSubtitle;

  /// No description provided for @foodMealsPerDay.
  ///
  /// In pt, this message translates to:
  /// **'Refeições por dia'**
  String get foodMealsPerDay;

  /// No description provided for @foodMealsUnit.
  ///
  /// In pt, this message translates to:
  /// **'refeições'**
  String get foodMealsUnit;

  /// No description provided for @foodMenuStyleTitle.
  ///
  /// In pt, this message translates to:
  /// **'Estilo do cardápio'**
  String get foodMenuStyleTitle;

  /// No description provided for @foodStyleSimple.
  ///
  /// In pt, this message translates to:
  /// **'Simples'**
  String get foodStyleSimple;

  /// No description provided for @foodStyleBudget.
  ///
  /// In pt, this message translates to:
  /// **'Econômico'**
  String get foodStyleBudget;

  /// No description provided for @foodStyleQuick.
  ///
  /// In pt, this message translates to:
  /// **'Rápido'**
  String get foodStyleQuick;

  /// No description provided for @foodStyleHealthy.
  ///
  /// In pt, this message translates to:
  /// **'Saudável'**
  String get foodStyleHealthy;

  /// No description provided for @foodDietaryRestrictions.
  ///
  /// In pt, this message translates to:
  /// **'Restrições alimentares'**
  String get foodDietaryRestrictions;

  /// No description provided for @foodAllowRepetition.
  ///
  /// In pt, this message translates to:
  /// **'Pode repetir receitas na semana'**
  String get foodAllowRepetition;

  /// No description provided for @foodAllowRepetitionSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Se desligado, cada receita aparece apenas 1 vez'**
  String get foodAllowRepetitionSubtitle;

  /// No description provided for @foodRestVegetarian.
  ///
  /// In pt, this message translates to:
  /// **'Vegetariano'**
  String get foodRestVegetarian;

  /// No description provided for @foodRestVegan.
  ///
  /// In pt, this message translates to:
  /// **'Vegano'**
  String get foodRestVegan;

  /// No description provided for @foodRestLactoseFree.
  ///
  /// In pt, this message translates to:
  /// **'Sem Lactose'**
  String get foodRestLactoseFree;

  /// No description provided for @foodRestGlutenFree.
  ///
  /// In pt, this message translates to:
  /// **'Sem Glúten'**
  String get foodRestGlutenFree;

  /// No description provided for @foodRestDiabetes.
  ///
  /// In pt, this message translates to:
  /// **'Diabetes'**
  String get foodRestDiabetes;

  /// No description provided for @foodRestHypertension.
  ///
  /// In pt, this message translates to:
  /// **'Hipertensão'**
  String get foodRestHypertension;

  /// No description provided for @foodPeriodTypeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Período do Cardápio'**
  String get foodPeriodTypeTitle;

  /// No description provided for @foodPeriodWeekly.
  ///
  /// In pt, this message translates to:
  /// **'Semanal (7 dias)'**
  String get foodPeriodWeekly;

  /// No description provided for @foodPeriodMonthly.
  ///
  /// In pt, this message translates to:
  /// **'Mensal (28 dias)'**
  String get foodPeriodMonthly;

  /// No description provided for @foodObjectiveTitle.
  ///
  /// In pt, this message translates to:
  /// **'Objetivo'**
  String get foodObjectiveTitle;

  /// No description provided for @foodObjMaintenance.
  ///
  /// In pt, this message translates to:
  /// **'Manter peso'**
  String get foodObjMaintenance;

  /// No description provided for @foodObjWeightLoss.
  ///
  /// In pt, this message translates to:
  /// **'Emagrecimento'**
  String get foodObjWeightLoss;

  /// No description provided for @foodObjBalanced.
  ///
  /// In pt, this message translates to:
  /// **'Alimentação equilibrada'**
  String get foodObjBalanced;

  /// No description provided for @foodPeriodSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Para quando?'**
  String get foodPeriodSectionTitle;

  /// No description provided for @foodPeriodSectionDesc.
  ///
  /// In pt, this message translates to:
  /// **'Escolha o período do cardápio que será gerado.'**
  String get foodPeriodSectionDesc;

  /// No description provided for @foodPeriodThisWeek.
  ///
  /// In pt, this message translates to:
  /// **'Esta semana'**
  String get foodPeriodThisWeek;

  /// No description provided for @foodPeriodNextWeek.
  ///
  /// In pt, this message translates to:
  /// **'Próxima semana'**
  String get foodPeriodNextWeek;

  /// No description provided for @foodPeriod28Days.
  ///
  /// In pt, this message translates to:
  /// **'Próximos 28 dias'**
  String get foodPeriod28Days;

  /// No description provided for @foodObjectiveSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Objetivo do cardápio'**
  String get foodObjectiveSectionTitle;

  /// No description provided for @foodObjectiveSectionDesc.
  ///
  /// In pt, this message translates to:
  /// **'O objetivo influencia a escolha dos alimentos e calorias.'**
  String get foodObjectiveSectionDesc;

  /// No description provided for @foodPreferencesSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Preferências alimentares'**
  String get foodPreferencesSectionTitle;

  /// No description provided for @foodPreferencesSectionDesc.
  ///
  /// In pt, this message translates to:
  /// **'Opcional. Se não marcar nada, o cardápio será padrão.'**
  String get foodPreferencesSectionDesc;

  /// No description provided for @foodConfirmationSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Resumo da escolha'**
  String get foodConfirmationSectionTitle;

  /// No description provided for @foodConfirmationSummaryLead.
  ///
  /// In pt, this message translates to:
  /// **'Você vai gerar:'**
  String get foodConfirmationSummaryLead;

  /// No description provided for @foodConfirmationPeriodPrefix.
  ///
  /// In pt, this message translates to:
  /// **'• Cardápio: '**
  String get foodConfirmationPeriodPrefix;

  /// No description provided for @foodConfirmationObjectivePrefix.
  ///
  /// In pt, this message translates to:
  /// **'• Objetivo: '**
  String get foodConfirmationObjectivePrefix;

  /// No description provided for @foodGenerateMenuAction.
  ///
  /// In pt, this message translates to:
  /// **'GERAR CARDÁPIO'**
  String get foodGenerateMenuAction;

  /// No description provided for @foodSelectPeriodError.
  ///
  /// In pt, this message translates to:
  /// **'Escolha o período do cardápio.'**
  String get foodSelectPeriodError;

  /// No description provided for @foodGeneratingMenu.
  ///
  /// In pt, this message translates to:
  /// **'Gerando seu cardápio...'**
  String get foodGeneratingMenu;

  /// No description provided for @foodRedoPlanAction.
  ///
  /// In pt, this message translates to:
  /// **'Refazer esta semana'**
  String get foodRedoPlanAction;

  /// No description provided for @foodGenerateNextWeekAction.
  ///
  /// In pt, this message translates to:
  /// **'Gerar próxima semana'**
  String get foodGenerateNextWeekAction;

  /// No description provided for @foodGenerate28DaysAction.
  ///
  /// In pt, this message translates to:
  /// **'Gerar próximos 28 dias'**
  String get foodGenerate28DaysAction;

  /// No description provided for @foodCreateNewVersion.
  ///
  /// In pt, this message translates to:
  /// **'Criar nova versão'**
  String get foodCreateNewVersion;

  /// No description provided for @foodReplaceExisting.
  ///
  /// In pt, this message translates to:
  /// **'Substituir atual'**
  String get foodReplaceExisting;

  /// No description provided for @foodRedoPlanPrompt.
  ///
  /// In pt, this message translates to:
  /// **'Como você deseja refazer este cardápio?'**
  String get foodRedoPlanPrompt;

  /// No description provided for @foodHistoryFilter.
  ///
  /// In pt, this message translates to:
  /// **'Filtrar Histórico'**
  String get foodHistoryFilter;

  /// No description provided for @foodAllPeriods.
  ///
  /// In pt, this message translates to:
  /// **'Todos os Períodos'**
  String get foodAllPeriods;

  /// No description provided for @foodActiveStatus.
  ///
  /// In pt, this message translates to:
  /// **'Ativo'**
  String get foodActiveStatus;

  /// No description provided for @foodArchivedStatus.
  ///
  /// In pt, this message translates to:
  /// **'Arquivado'**
  String get foodArchivedStatus;

  /// No description provided for @foodEditMeal.
  ///
  /// In pt, this message translates to:
  /// **'Editar Refeição'**
  String get foodEditMeal;

  /// No description provided for @foodSaveChanges.
  ///
  /// In pt, this message translates to:
  /// **'Salvar Alterações'**
  String get foodSaveChanges;

  /// No description provided for @foodDeletePlanSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Cardápio excluído com sucesso.'**
  String get foodDeletePlanSuccess;

  /// No description provided for @foodMealRemoved.
  ///
  /// In pt, this message translates to:
  /// **'Cardápio removido.'**
  String get foodMealRemoved;

  /// No description provided for @foodStatusActive.
  ///
  /// In pt, this message translates to:
  /// **'Ativo'**
  String get foodStatusActive;

  /// No description provided for @foodStatusArchived.
  ///
  /// In pt, this message translates to:
  /// **'Arquivado'**
  String get foodStatusArchived;

  /// No description provided for @foodVersionLabel.
  ///
  /// In pt, this message translates to:
  /// **'Versão'**
  String get foodVersionLabel;

  /// No description provided for @foodWeeklyPlanTitle.
  ///
  /// In pt, this message translates to:
  /// **'Semana de {date}'**
  String foodWeeklyPlanTitle(String date);

  /// No description provided for @foodWeeklyPlanSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'O que você vai comer nos próximos {count} dias'**
  String foodWeeklyPlanSubtitle(int count);

  /// No description provided for @foodTipsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Dicas de Preparo (Batch Cooking)'**
  String get foodTipsTitle;

  /// No description provided for @foodCaloriesEstimated.
  ///
  /// In pt, this message translates to:
  /// **'kcal estimados para o dia'**
  String get foodCaloriesEstimated;

  /// No description provided for @foodTodayLabel.
  ///
  /// In pt, this message translates to:
  /// **'HOJE'**
  String get foodTodayLabel;

  /// No description provided for @foodMealBreakfast.
  ///
  /// In pt, this message translates to:
  /// **'Café'**
  String get foodMealBreakfast;

  /// No description provided for @foodMealLunch.
  ///
  /// In pt, this message translates to:
  /// **'Almoço'**
  String get foodMealLunch;

  /// No description provided for @foodMealSnack.
  ///
  /// In pt, this message translates to:
  /// **'Lanche'**
  String get foodMealSnack;

  /// No description provided for @foodMealDinner.
  ///
  /// In pt, this message translates to:
  /// **'Jantar'**
  String get foodMealDinner;

  /// No description provided for @foodRegeneratePlanTitle.
  ///
  /// In pt, this message translates to:
  /// **'Refazer a semana?'**
  String get foodRegeneratePlanTitle;

  /// No description provided for @foodRegeneratePlanBody.
  ///
  /// In pt, this message translates to:
  /// **'Isso vai criar um novo cardápio para a semana. O atual será substituído.'**
  String get foodRegeneratePlanBody;

  /// No description provided for @foodRegenerateAction.
  ///
  /// In pt, this message translates to:
  /// **'Refazer'**
  String get foodRegenerateAction;

  /// No description provided for @foodRegenerateSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Cardápio da semana refeito!'**
  String get foodRegenerateSuccess;

  /// No description provided for @foodPlanError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar o cardápio'**
  String get foodPlanError;

  /// No description provided for @foodTryAgain.
  ///
  /// In pt, this message translates to:
  /// **'Tentar Novamente'**
  String get foodTryAgain;

  /// No description provided for @foodNoPlanTitle.
  ///
  /// In pt, this message translates to:
  /// **'Você ainda não tem um cardápio'**
  String get foodNoPlanTitle;

  /// No description provided for @foodCreatePlanButton.
  ///
  /// In pt, this message translates to:
  /// **'Criar Cardápio'**
  String get foodCreatePlanButton;

  /// No description provided for @foodHistoryTitleMenu.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de Cardápios'**
  String get foodHistoryTitleMenu;

  /// No description provided for @foodNoHistory.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum histórico'**
  String get foodNoHistory;

  /// No description provided for @foodDaysPlanned.
  ///
  /// In pt, this message translates to:
  /// **'{count} dias planejados'**
  String foodDaysPlanned(int count);

  /// No description provided for @foodDeletePlanTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir cardápio?'**
  String get foodDeletePlanTitle;

  /// No description provided for @foodDeletePlanBody.
  ///
  /// In pt, this message translates to:
  /// **'Esta ação não pode ser desfeita.'**
  String get foodDeletePlanBody;

  /// No description provided for @foodIngredientsTitle.
  ///
  /// In pt, this message translates to:
  /// **'INGREDIENTES'**
  String get foodIngredientsTitle;

  /// No description provided for @foodMealDefault.
  ///
  /// In pt, this message translates to:
  /// **'Refeição'**
  String get foodMealDefault;

  /// No description provided for @foodCreatingProfile.
  ///
  /// In pt, this message translates to:
  /// **'Perfil básico criado automaticamente.'**
  String get foodCreatingProfile;

  /// No description provided for @foodPlanCreatedSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Cardápio criado com sucesso!'**
  String get foodPlanCreatedSuccess;

  /// No description provided for @foodOpeningConfig.
  ///
  /// In pt, this message translates to:
  /// **'Abrindo configuração...'**
  String get foodOpeningConfig;

  /// No description provided for @foodTooltipNutritionHistory.
  ///
  /// In pt, this message translates to:
  /// **'Histórico Alimentar'**
  String get foodTooltipNutritionHistory;

  /// No description provided for @foodTooltipNutritionManagement.
  ///
  /// In pt, this message translates to:
  /// **'Gestão da Nutrição'**
  String get foodTooltipNutritionManagement;

  /// No description provided for @foodRecipesTitle.
  ///
  /// In pt, this message translates to:
  /// **'RECEITAS'**
  String get foodRecipesTitle;

  /// No description provided for @foodJustificationLabel.
  ///
  /// In pt, this message translates to:
  /// **'Justificativa'**
  String get foodJustificationLabel;

  /// No description provided for @foodDifficultyLabel.
  ///
  /// In pt, this message translates to:
  /// **'Dificuldade'**
  String get foodDifficultyLabel;

  /// No description provided for @foodInstructionsLabel.
  ///
  /// In pt, this message translates to:
  /// **'Modo de Preparo'**
  String get foodInstructionsLabel;

  /// No description provided for @foodShoppingListTitle.
  ///
  /// In pt, this message translates to:
  /// **'Lista de Compras'**
  String get foodShoppingListTitle;

  /// No description provided for @foodShoppingListDescription.
  ///
  /// In pt, this message translates to:
  /// **'Lista de compras para a {week} organizados por categoria.'**
  String foodShoppingListDescription(String week);

  /// No description provided for @foodDateLabel.
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get foodDateLabel;

  /// No description provided for @foodNutrientsTable.
  ///
  /// In pt, this message translates to:
  /// **'Tabela Nutricional'**
  String get foodNutrientsTable;

  /// No description provided for @foodClinicalRec.
  ///
  /// In pt, this message translates to:
  /// **'Recomendação Clínica'**
  String get foodClinicalRec;

  /// No description provided for @foodRecipesTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Ver Receitas'**
  String get foodRecipesTooltip;

  /// No description provided for @foodExportPdfTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Exportar PDF'**
  String get foodExportPdfTooltip;

  /// No description provided for @foodGenerateMoreRecipes.
  ///
  /// In pt, this message translates to:
  /// **'Gerar mais receitas'**
  String get foodGenerateMoreRecipes;

  /// No description provided for @foodFallbackMessage.
  ///
  /// In pt, this message translates to:
  /// **'Gerando receitas padrão (modo offline).'**
  String get foodFallbackMessage;

  /// No description provided for @food_generating_recipes.
  ///
  /// In pt, this message translates to:
  /// **'Criando receitas exclusivas...'**
  String get food_generating_recipes;

  /// No description provided for @food_error_maintenance.
  ///
  /// In pt, this message translates to:
  /// **'Serviço em manutenção momentânea.'**
  String get food_error_maintenance;

  /// No description provided for @food_delete_confirm_title.
  ///
  /// In pt, this message translates to:
  /// **'Excluir Receita?'**
  String get food_delete_confirm_title;

  /// No description provided for @food_delete_confirm_body.
  ///
  /// In pt, this message translates to:
  /// **'Esta ação removerá a receita permanentemente.'**
  String get food_delete_confirm_body;

  /// No description provided for @food_delete_confirm_action.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get food_delete_confirm_action;

  /// No description provided for @food_cancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get food_cancel;

  /// No description provided for @foodRecipeBookTitle.
  ///
  /// In pt, this message translates to:
  /// **'Livro de Receitas'**
  String get foodRecipeBookTitle;

  /// No description provided for @foodChatWelcome.
  ///
  /// In pt, this message translates to:
  /// **'Olá! Sou sua assistente nutricional. Como posso ajudar com sua dieta hoje?'**
  String get foodChatWelcome;

  /// No description provided for @foodChatPrompt.
  ///
  /// In pt, this message translates to:
  /// **'Pergunte sobre seus alimentos...'**
  String get foodChatPrompt;

  /// No description provided for @foodChatMicUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Microfone indisponível.'**
  String get foodChatMicUnavailable;

  /// No description provided for @foodChatStartListening.
  ///
  /// In pt, this message translates to:
  /// **'Toque para falar'**
  String get foodChatStartListening;

  /// No description provided for @foodChatStopListening.
  ///
  /// In pt, this message translates to:
  /// **'Parar gravação'**
  String get foodChatStopListening;

  /// No description provided for @foodChatExportTitle.
  ///
  /// In pt, this message translates to:
  /// **'Evolução Nutricional - {date}'**
  String foodChatExportTitle(String date);

  /// No description provided for @foodChatDisclaimer.
  ///
  /// In pt, this message translates to:
  /// **'Este é um chat informativo. Consulte um nutricionista.'**
  String get foodChatDisclaimer;

  /// No description provided for @foodChatTitle.
  ///
  /// In pt, this message translates to:
  /// **'NutriChat IA'**
  String get foodChatTitle;

  /// No description provided for @foodChatClear.
  ///
  /// In pt, this message translates to:
  /// **'Limpar Chat'**
  String get foodChatClear;

  /// No description provided for @foodChatRAGProcessing.
  ///
  /// In pt, this message translates to:
  /// **'Consultando base de conhecimento...'**
  String get foodChatRAGProcessing;

  /// No description provided for @foodMainIngredient.
  ///
  /// In pt, this message translates to:
  /// **'Ingrediente Principal: {ingredient}'**
  String foodMainIngredient(String ingredient);

  /// No description provided for @foodClose.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get foodClose;

  /// No description provided for @foodViewDetails.
  ///
  /// In pt, this message translates to:
  /// **'Ver Detalhes'**
  String get foodViewDetails;

  /// No description provided for @foodOrigin.
  ///
  /// In pt, this message translates to:
  /// **'Gerado a partir de: {name}'**
  String foodOrigin(String name);

  /// No description provided for @foodPdfTitle.
  ///
  /// In pt, this message translates to:
  /// **'Análise Nutricional & Biohacking'**
  String get foodPdfTitle;

  /// No description provided for @tooltipHistoryReport.
  ///
  /// In pt, this message translates to:
  /// **'Exportar Relatório'**
  String get tooltipHistoryReport;

  /// No description provided for @foodCancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get foodCancel;

  /// No description provided for @foodDelete.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get foodDelete;
}

class _FoodLocalizationsDelegate extends LocalizationsDelegate<FoodLocalizations> {
  const _FoodLocalizationsDelegate();

  @override
  Future<FoodLocalizations> load(Locale locale) {
    return SynchronousFuture<FoodLocalizations>(lookupFoodLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_FoodLocalizationsDelegate old) => false;
}

FoodLocalizations lookupFoodLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return FoodLocalizationsEn();
    case 'pt': return FoodLocalizationsPt();
  }

  throw FlutterError(
    'FoodLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
