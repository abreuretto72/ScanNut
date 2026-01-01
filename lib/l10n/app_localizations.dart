import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt'),
    Locale('pt', 'PT')
  ];

  /// No description provided for @appTitle.
  ///
  /// In pt, this message translates to:
  /// **'Scannut'**
  String get appTitle;

  /// No description provided for @tabFood.
  ///
  /// In pt, this message translates to:
  /// **'Comida'**
  String get tabFood;

  /// No description provided for @tabPlants.
  ///
  /// In pt, this message translates to:
  /// **'Plantas'**
  String get tabPlants;

  /// No description provided for @tabPets.
  ///
  /// In pt, this message translates to:
  /// **'Pets'**
  String get tabPets;

  /// No description provided for @disclaimerTitle.
  ///
  /// In pt, this message translates to:
  /// **'Aviso Importante'**
  String get disclaimerTitle;

  /// No description provided for @disclaimerBody.
  ///
  /// In pt, this message translates to:
  /// **'Este aplicativo realiza apenas triagem informativa e NÃO substitui o conselho profissional de Nutricionistas, Agronômos ou Veterinários.'**
  String get disclaimerBody;

  /// No description provided for @disclaimerButton.
  ///
  /// In pt, this message translates to:
  /// **'Entendi'**
  String get disclaimerButton;

  /// No description provided for @emergencyCall.
  ///
  /// In pt, this message translates to:
  /// **'Ligar para Veterinário Próximo'**
  String get emergencyCall;

  /// No description provided for @cameraPermission.
  ///
  /// In pt, this message translates to:
  /// **'Precisamos da câmera para analisar. Você pode ativar nas configurações.'**
  String get cameraPermission;

  /// No description provided for @petNamePromptTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nome do Pet'**
  String get petNamePromptTitle;

  /// No description provided for @petNamePromptHint.
  ///
  /// In pt, this message translates to:
  /// **'Digite o nome do seu pet'**
  String get petNamePromptHint;

  /// No description provided for @petNamePromptCancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get petNamePromptCancel;

  /// No description provided for @petNameEmptyError.
  ///
  /// In pt, this message translates to:
  /// **'Nome do pet não fornecido. Pet mode cancelado.'**
  String get petNameEmptyError;

  /// No description provided for @settingsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Configurações'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In pt, this message translates to:
  /// **'Idioma / Language'**
  String get settingsLanguage;

  /// No description provided for @settingsProfile.
  ///
  /// In pt, this message translates to:
  /// **'Perfil'**
  String get settingsProfile;

  /// No description provided for @settingsNutrition.
  ///
  /// In pt, this message translates to:
  /// **'Metas Nutricionais Humanas'**
  String get settingsNutrition;

  /// No description provided for @settingsDangerZone.
  ///
  /// In pt, this message translates to:
  /// **'Zona de Perigo'**
  String get settingsDangerZone;

  /// No description provided for @pdfReportTitle.
  ///
  /// In pt, this message translates to:
  /// **'PRONTUÁRIO VETERINÁRIO COMPLETO'**
  String get pdfReportTitle;

  /// No description provided for @pdfGeneratedOn.
  ///
  /// In pt, this message translates to:
  /// **'Gerado em'**
  String get pdfGeneratedOn;

  /// No description provided for @pdfIdentitySection.
  ///
  /// In pt, this message translates to:
  /// **'Identidade e Perfil Biológico'**
  String get pdfIdentitySection;

  /// No description provided for @pdfHealthSection.
  ///
  /// In pt, this message translates to:
  /// **'Saúde e Histórico Médico'**
  String get pdfHealthSection;

  /// No description provided for @pdfNutritionSection.
  ///
  /// In pt, this message translates to:
  /// **'Nutrição e Plano Alimentar'**
  String get pdfNutritionSection;

  /// No description provided for @pdfGallerySection.
  ///
  /// In pt, this message translates to:
  /// **'Galeria e Documentos'**
  String get pdfGallerySection;

  /// No description provided for @pdfParcSection.
  ///
  /// In pt, this message translates to:
  /// **'Rede de Apoio e Comportamento'**
  String get pdfParcSection;

  /// No description provided for @pdfDisclaimerTitle.
  ///
  /// In pt, this message translates to:
  /// **'AVISO LEGAL IMPORTANTE'**
  String get pdfDisclaimerTitle;

  /// No description provided for @pdfDisclaimerBody.
  ///
  /// In pt, this message translates to:
  /// **'Este relatório é uma ferramenta de apoio. NÃO substitui consultas veterinárias.'**
  String get pdfDisclaimerBody;

  /// No description provided for @termScreen.
  ///
  /// In pt, this message translates to:
  /// **'Tela'**
  String get termScreen;

  /// No description provided for @termMobile.
  ///
  /// In pt, this message translates to:
  /// **'Celular'**
  String get termMobile;

  /// No description provided for @termFood.
  ///
  /// In pt, this message translates to:
  /// **'Ração'**
  String get termFood;

  /// No description provided for @breedMixed.
  ///
  /// In pt, this message translates to:
  /// **'Sem Raça Definida (Vira-lata)'**
  String get breedMixed;

  /// No description provided for @porteSmall.
  ///
  /// In pt, this message translates to:
  /// **'Pequeno'**
  String get porteSmall;

  /// No description provided for @porteMedium.
  ///
  /// In pt, this message translates to:
  /// **'Médio'**
  String get porteMedium;

  /// No description provided for @porteLarge.
  ///
  /// In pt, this message translates to:
  /// **'Grande'**
  String get porteLarge;

  /// No description provided for @porteGiant.
  ///
  /// In pt, this message translates to:
  /// **'Gigante'**
  String get porteGiant;

  /// No description provided for @weightStatusUnderweight.
  ///
  /// In pt, this message translates to:
  /// **'Abaixo do ideal'**
  String get weightStatusUnderweight;

  /// No description provided for @weightStatusOverweight.
  ///
  /// In pt, this message translates to:
  /// **'Acima do ideal'**
  String get weightStatusOverweight;

  /// No description provided for @weightStatusNormal.
  ///
  /// In pt, this message translates to:
  /// **'Peso Normal'**
  String get weightStatusNormal;

  /// No description provided for @weightRecUnderweight.
  ///
  /// In pt, this message translates to:
  /// **'Considere consultar o veterinário para avaliar a nutrição e saúde geral do pet.'**
  String get weightRecUnderweight;

  /// No description provided for @weightRecOverweight.
  ///
  /// In pt, this message translates to:
  /// **'Agende uma consulta com o veterinário na aba \'Parc.\' para ajustar a dieta e exercícios.'**
  String get weightRecOverweight;

  /// No description provided for @weightRecNormal.
  ///
  /// In pt, this message translates to:
  /// **'Continue com os cuidados atuais! Mantenha a rotina de alimentação e exercícios.'**
  String get weightRecNormal;

  /// No description provided for @termSeverity.
  ///
  /// In pt, this message translates to:
  /// **'Gravidade'**
  String get termSeverity;

  /// No description provided for @termDiagnosis.
  ///
  /// In pt, this message translates to:
  /// **'Diagnóstico'**
  String get termDiagnosis;

  /// No description provided for @termRecommendations.
  ///
  /// In pt, this message translates to:
  /// **'Recomendações'**
  String get termRecommendations;

  /// No description provided for @tabIdentity.
  ///
  /// In pt, this message translates to:
  /// **'IDENTIDADE'**
  String get tabIdentity;

  /// No description provided for @tabNutrition.
  ///
  /// In pt, this message translates to:
  /// **'NUTRIÇÃO'**
  String get tabNutrition;

  /// No description provided for @tabGrooming.
  ///
  /// In pt, this message translates to:
  /// **'GROOMING'**
  String get tabGrooming;

  /// No description provided for @tabHealth.
  ///
  /// In pt, this message translates to:
  /// **'SAÚDE'**
  String get tabHealth;

  /// No description provided for @tabLifestyle.
  ///
  /// In pt, this message translates to:
  /// **'LIFESTYLE'**
  String get tabLifestyle;

  /// No description provided for @emptyPastWeek.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum histórico recente.'**
  String get emptyPastWeek;

  /// No description provided for @emptyCurrentWeek.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum cardápio para esta semana.'**
  String get emptyCurrentWeek;

  /// No description provided for @emptyNextWeek.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum planejamento futuro.'**
  String get emptyNextWeek;

  /// No description provided for @tabPastWeek.
  ///
  /// In pt, this message translates to:
  /// **'Semana Passada'**
  String get tabPastWeek;

  /// No description provided for @tabCurrentWeek.
  ///
  /// In pt, this message translates to:
  /// **'Semana Atual'**
  String get tabCurrentWeek;

  /// No description provided for @tabNextWeek.
  ///
  /// In pt, this message translates to:
  /// **'Próxima Semana'**
  String get tabNextWeek;

  /// No description provided for @menuPlanTitle.
  ///
  /// In pt, this message translates to:
  /// **'Planejar Cardápio Inteligente'**
  String get menuPlanTitle;

  /// No description provided for @menuPeriod.
  ///
  /// In pt, this message translates to:
  /// **'Período do Cardápio'**
  String get menuPeriod;

  /// No description provided for @dietType.
  ///
  /// In pt, this message translates to:
  /// **'Regime Alimentar'**
  String get dietType;

  /// No description provided for @dietNatural.
  ///
  /// In pt, this message translates to:
  /// **'Alimentação Natural'**
  String get dietNatural;

  /// No description provided for @dietKibble.
  ///
  /// In pt, this message translates to:
  /// **'Ração Comercial'**
  String get dietKibble;

  /// No description provided for @dietHybrid.
  ///
  /// In pt, this message translates to:
  /// **'Modo Híbrido Ativado'**
  String get dietHybrid;

  /// No description provided for @nutritionalGoal.
  ///
  /// In pt, this message translates to:
  /// **'Meta Nutricional'**
  String get nutritionalGoal;

  /// No description provided for @generateMenu.
  ///
  /// In pt, this message translates to:
  /// **'Gerar Cardápio'**
  String get generateMenu;

  /// No description provided for @selectDates.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar Datas'**
  String get selectDates;

  /// No description provided for @cancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @permissionCameraDisclosureTitle.
  ///
  /// In pt, this message translates to:
  /// **'Uso da Câmera'**
  String get permissionCameraDisclosureTitle;

  /// No description provided for @permissionCameraDisclosureBody.
  ///
  /// In pt, this message translates to:
  /// **'O ScanNut precisa acessar sua câmera para analisar a saúde da pele, pelo e olhos do seu pet, além de permitir o registro de documentos veterinários.'**
  String get permissionCameraDisclosureBody;

  /// No description provided for @permissionMicrophoneDisclosureTitle.
  ///
  /// In pt, this message translates to:
  /// **'Uso do Microfone'**
  String get permissionMicrophoneDisclosureTitle;

  /// No description provided for @permissionMicrophoneDisclosureBody.
  ///
  /// In pt, this message translates to:
  /// **'O ScanNut solicita acesso ao microfone para permitir que você faça anotações por voz sobre as observações do seu pet.'**
  String get permissionMicrophoneDisclosureBody;

  /// No description provided for @continueButton.
  ///
  /// In pt, this message translates to:
  /// **'Continuar'**
  String get continueButton;

  /// No description provided for @deleteAccount.
  ///
  /// In pt, this message translates to:
  /// **'Excluir Conta e Dados'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirmTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir tudo?'**
  String get deleteAccountConfirmTitle;

  /// No description provided for @deleteAccountConfirmBody.
  ///
  /// In pt, this message translates to:
  /// **'Isso apagará permanentemente todos os seus cardápios e históricos.'**
  String get deleteAccountConfirmBody;

  /// No description provided for @deleteAccountButton.
  ///
  /// In pt, this message translates to:
  /// **'Excluir Tudo'**
  String get deleteAccountButton;

  /// No description provided for @privacyPolicy.
  ///
  /// In pt, this message translates to:
  /// **'Política de Privacidade'**
  String get privacyPolicy;

  /// No description provided for @aiDisclaimer.
  ///
  /// In pt, this message translates to:
  /// **'Aviso da IA'**
  String get aiDisclaimer;

  /// No description provided for @onboardingTitle1.
  ///
  /// In pt, this message translates to:
  /// **'Transforme a sua Nutrição'**
  String get onboardingTitle1;

  /// No description provided for @onboardingBody1.
  ///
  /// In pt, this message translates to:
  /// **'Utilize a nossa IA para analisar alimentos em segundos. Descubra calorias, macronutrientes e receba dicas de biohacking e receitas rápidas de 15 minutos para a sua alta performance.'**
  String get onboardingBody1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In pt, this message translates to:
  /// **'Domine o seu Ecossistema'**
  String get onboardingTitle2;

  /// No description provided for @onboardingBody2.
  ///
  /// In pt, this message translates to:
  /// **'Identifique plantas, diagnostique doenças e aprenda sobre propagação. Saiba instantaneamente se uma planta é segura para humanos através do nosso Semáforo de Sobrevivência.'**
  String get onboardingBody2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In pt, this message translates to:
  /// **'O Prontuário Clínico Definitivo'**
  String get onboardingTitle3;

  /// No description provided for @onboardingBody3.
  ///
  /// In pt, this message translates to:
  /// **'Acompanhe a saúde do seu pet com análise de pele por IA, histórico de vacinas e exames laboratoriais explicados. Tudo organizado e pronto para exportar em PDF para o seu veterinário.'**
  String get onboardingBody3;

  /// No description provided for @onboardingTitle4.
  ///
  /// In pt, this message translates to:
  /// **'Os seus dados são seus'**
  String get onboardingTitle4;

  /// No description provided for @onboardingBody4.
  ///
  /// In pt, this message translates to:
  /// **'No ScanNut, a sua privacidade é prioridade. Todos os seus registos são guardados localmente no seu telemóvel (Hive) e não em nuvens externas.'**
  String get onboardingBody4;

  /// No description provided for @onboardingAcceptTerms.
  ///
  /// In pt, this message translates to:
  /// **'Li e aceito os Termos de Uso e Política de Privacidade da Multiverso Digital'**
  String get onboardingAcceptTerms;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In pt, this message translates to:
  /// **'Começar'**
  String get onboardingGetStarted;

  /// No description provided for @analysisErrorAiFailure.
  ///
  /// In pt, this message translates to:
  /// **'Todas as IAs falharam em analisar a imagem.'**
  String get analysisErrorAiFailure;

  /// No description provided for @analysisErrorJsonFormat.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao processar dados da IA.'**
  String get analysisErrorJsonFormat;

  /// No description provided for @analysisErrorUnexpected.
  ///
  /// In pt, this message translates to:
  /// **'Erro inesperado. Tente novamente.'**
  String get analysisErrorUnexpected;

  /// No description provided for @loadingFood.
  ///
  /// In pt, this message translates to:
  /// **'Analisando alimento...'**
  String get loadingFood;

  /// No description provided for @loadingPlant.
  ///
  /// In pt, this message translates to:
  /// **'Diagnosticando planta...'**
  String get loadingPlant;

  /// No description provided for @loadingPetBreed.
  ///
  /// In pt, this message translates to:
  /// **'Identificando raça...'**
  String get loadingPetBreed;

  /// No description provided for @loadingPetHealth.
  ///
  /// In pt, this message translates to:
  /// **'Analisando saúde...'**
  String get loadingPetHealth;

  /// No description provided for @nutrientsAdvancedMacros.
  ///
  /// In pt, this message translates to:
  /// **'Macronutrientes Avançados'**
  String get nutrientsAdvancedMacros;

  /// No description provided for @nutrientsProteins.
  ///
  /// In pt, this message translates to:
  /// **'Proteínas'**
  String get nutrientsProteins;

  /// No description provided for @nutrientsCarbs.
  ///
  /// In pt, this message translates to:
  /// **'Carboidratos'**
  String get nutrientsCarbs;

  /// No description provided for @nutrientsFats.
  ///
  /// In pt, this message translates to:
  /// **'Gorduras'**
  String get nutrientsFats;

  /// No description provided for @nutrientsMinerals.
  ///
  /// In pt, this message translates to:
  /// **'Minerais e Vitaminas'**
  String get nutrientsMinerals;

  /// No description provided for @nutrientsSynergy.
  ///
  /// In pt, this message translates to:
  /// **'Sinergia'**
  String get nutrientsSynergy;

  /// No description provided for @recipesQuick.
  ///
  /// In pt, this message translates to:
  /// **'Receitas Rápidas (até 15 min)'**
  String get recipesQuick;

  /// No description provided for @recipesCulinaryIntel.
  ///
  /// In pt, this message translates to:
  /// **'Inteligência Culinária'**
  String get recipesCulinaryIntel;

  /// No description provided for @recipesExpertTip.
  ///
  /// In pt, this message translates to:
  /// **'Dica do Especialista'**
  String get recipesExpertTip;

  /// No description provided for @labelGlycemicImpact.
  ///
  /// In pt, this message translates to:
  /// **'Impacto Glicêmico'**
  String get labelGlycemicImpact;

  /// No description provided for @labelFattyAcids.
  ///
  /// In pt, this message translates to:
  /// **'Ácidos Graxos'**
  String get labelFattyAcids;

  /// No description provided for @labelAminoProfile.
  ///
  /// In pt, this message translates to:
  /// **'Perfil de Aminoácidos'**
  String get labelAminoProfile;

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

  /// No description provided for @paywallTitle.
  ///
  /// In pt, this message translates to:
  /// **'Desbloqueie o Poder Total'**
  String get paywallTitle;

  /// No description provided for @paywallSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Obtenha acesso ilimitado a todas as ferramentas de IA e análises detalhadas.'**
  String get paywallSubtitle;

  /// No description provided for @paywallSubscribeButton.
  ///
  /// In pt, this message translates to:
  /// **'Assinar Agora'**
  String get paywallSubscribeButton;

  /// No description provided for @paywallSelectPlan.
  ///
  /// In pt, this message translates to:
  /// **'Selecione um plano'**
  String get paywallSelectPlan;

  /// No description provided for @paywallRestore.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar Compras'**
  String get paywallRestore;

  /// No description provided for @paywallTerms.
  ///
  /// In pt, this message translates to:
  /// **'Termos'**
  String get paywallTerms;

  /// No description provided for @paywallMonthly.
  ///
  /// In pt, this message translates to:
  /// **'Mensal'**
  String get paywallMonthly;

  /// No description provided for @paywallYearly.
  ///
  /// In pt, this message translates to:
  /// **'Anual'**
  String get paywallYearly;

  /// No description provided for @paywallBestValue.
  ///
  /// In pt, this message translates to:
  /// **'MELHOR VALOR'**
  String get paywallBestValue;

  /// No description provided for @paywallSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Assinatura ativada com sucesso! Bem-vindo ao Pro! 🚀'**
  String get paywallSuccess;

  /// No description provided for @paywallError.
  ///
  /// In pt, this message translates to:
  /// **'A compra não foi concluída. Tente novamente.'**
  String get paywallError;

  /// No description provided for @paywallRestoreSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Compras restauradas com sucesso!'**
  String get paywallRestoreSuccess;

  /// No description provided for @paywallRestoreFail.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma assinatura ativa encontrada para restaurar.'**
  String get paywallRestoreFail;

  /// No description provided for @paywallLoadingOfferings.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar as ofertas no momento.'**
  String get paywallLoadingOfferings;

  /// No description provided for @drawerProTitle.
  ///
  /// In pt, this message translates to:
  /// **'ScanNut Pro'**
  String get drawerProTitle;

  /// No description provided for @drawerProSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Desbloqueie tudo'**
  String get drawerProSubtitle;

  /// No description provided for @settingsNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get settingsNameLabel;

  /// No description provided for @settingsNameHint.
  ///
  /// In pt, this message translates to:
  /// **'Como você gostaria de ser chamado?'**
  String get settingsNameHint;

  /// No description provided for @settingsWeightUnit.
  ///
  /// In pt, this message translates to:
  /// **'Unidade de Peso'**
  String get settingsWeightUnit;

  /// No description provided for @settingsKg.
  ///
  /// In pt, this message translates to:
  /// **'Kilogramas (kg)'**
  String get settingsKg;

  /// No description provided for @settingsLbs.
  ///
  /// In pt, this message translates to:
  /// **'Libras (lbs)'**
  String get settingsLbs;

  /// No description provided for @settingsPreferences.
  ///
  /// In pt, this message translates to:
  /// **'Preferências'**
  String get settingsPreferences;

  /// No description provided for @settingsShowTips.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar Dicas'**
  String get settingsShowTips;

  /// No description provided for @settingsShowTipsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Exibir dicas nutricionais nas análises'**
  String get settingsShowTipsSubtitle;

  /// No description provided for @settingsPartnerManagement.
  ///
  /// In pt, this message translates to:
  /// **'Gestão de Parceiros'**
  String get settingsPartnerManagement;

  /// No description provided for @settingsSearchRadius.
  ///
  /// In pt, this message translates to:
  /// **'Raio de Busca Padrão'**
  String get settingsSearchRadius;

  /// No description provided for @settingsSearchRadiusSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Sugere parceiros próximos ao seu pet baseando-se neste limite.'**
  String get settingsSearchRadiusSubtitle;

  /// No description provided for @settingsSystemMaintenance.
  ///
  /// In pt, this message translates to:
  /// **'Manutenção do Sistema'**
  String get settingsSystemMaintenance;

  /// No description provided for @settingsBackupOptimize.
  ///
  /// In pt, this message translates to:
  /// **'Gerar Backup e Otimizar'**
  String get settingsBackupOptimize;

  /// No description provided for @settingsBackupOptimizeSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Gera PDF completo e libera espaço antigo.'**
  String get settingsBackupOptimizeSubtitle;

  /// No description provided for @settingsDeletePets.
  ///
  /// In pt, this message translates to:
  /// **'Excluir Histórico de Pets'**
  String get settingsDeletePets;

  /// No description provided for @settingsDeletePetsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Apagar todos os pets salvos permanentemente.'**
  String get settingsDeletePetsSubtitle;

  /// No description provided for @settingsDeletePlants.
  ///
  /// In pt, this message translates to:
  /// **'Excluir Histórico de Plantas'**
  String get settingsDeletePlants;

  /// No description provided for @settingsDeletePlantsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Apagar todas as plantas salvas permanentemente.'**
  String get settingsDeletePlantsSubtitle;

  /// No description provided for @settingsDeleteFood.
  ///
  /// In pt, this message translates to:
  /// **'Excluir Histórico de Alimentos'**
  String get settingsDeleteFood;

  /// No description provided for @settingsDeleteFoodSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Apagar todos os alimentos salvos permanentemente.'**
  String get settingsDeleteFoodSubtitle;

  /// No description provided for @settingsClearPartners.
  ///
  /// In pt, this message translates to:
  /// **'Limpar Rede de Apoio'**
  String get settingsClearPartners;

  /// No description provided for @settingsClearPartnersSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Remover todos os parceiros cadastrados permanentemente.'**
  String get settingsClearPartnersSubtitle;

  /// No description provided for @settingsResetDefaults.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar Padrões'**
  String get settingsResetDefaults;

  /// No description provided for @settingsResetDialogTitle.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar Padrões'**
  String get settingsResetDialogTitle;

  /// No description provided for @settingsResetDialogContent.
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza que deseja restaurar todas as configurações para os valores padrão?'**
  String get settingsResetDialogContent;

  /// No description provided for @settingsResetSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Configurações restauradas'**
  String get settingsResetSuccess;

  /// No description provided for @settingsAutoSaveInfo.
  ///
  /// In pt, this message translates to:
  /// **'Suas configurações são salvas automaticamente'**
  String get settingsAutoSaveInfo;

  /// No description provided for @settingsConfirmDeleteTitle.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar Exclusão'**
  String get settingsConfirmDeleteTitle;

  /// No description provided for @settingsConfirmDeleteContent.
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza que deseja apagar permanentemente todo o histórico de {itemType}? Essa ação não pode ser desfeita.'**
  String settingsConfirmDeleteContent(Object itemType);

  /// No description provided for @settingsDeleteSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de {itemType} apagado com sucesso.'**
  String settingsDeleteSuccess(Object itemType);

  /// No description provided for @modePetIdentification.
  ///
  /// In pt, this message translates to:
  /// **'Raça & ID'**
  String get modePetIdentification;

  /// No description provided for @modePetHealth.
  ///
  /// In pt, this message translates to:
  /// **'Saúde'**
  String get modePetHealth;

  /// No description provided for @instructionPetBody.
  ///
  /// In pt, this message translates to:
  /// **'Aponte a câmera para o corpo inteiro do seu pet'**
  String get instructionPetBody;

  /// No description provided for @instructionPetWound.
  ///
  /// In pt, this message translates to:
  /// **'Aponte a câmera para a ferida do seu pet'**
  String get instructionPetWound;

  /// No description provided for @tooltipNutritionHistory.
  ///
  /// In pt, this message translates to:
  /// **'Histórico Alimentar'**
  String get tooltipNutritionHistory;

  /// No description provided for @tooltipNutritionManagement.
  ///
  /// In pt, this message translates to:
  /// **'Gestão da Nutrição'**
  String get tooltipNutritionManagement;

  /// No description provided for @tooltipBotanyHistory.
  ///
  /// In pt, this message translates to:
  /// **'Histórico Botânico'**
  String get tooltipBotanyHistory;

  /// No description provided for @exitDialogTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sair do App'**
  String get exitDialogTitle;

  /// No description provided for @exitDialogContent.
  ///
  /// In pt, this message translates to:
  /// **'Deseja realmente sair do Scannut?'**
  String get exitDialogContent;

  /// No description provided for @exit.
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get exit;

  /// No description provided for @redirectShop.
  ///
  /// In pt, this message translates to:
  /// **'Redirecionando para loja parceira...'**
  String get redirectShop;

  /// No description provided for @cameraError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao iniciar câmera: '**
  String get cameraError;

  /// No description provided for @petSavedSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Dossiê do {petName} salvo/atualizado com sucesso!'**
  String petSavedSuccess(Object petName);

  /// No description provided for @savedSuccess.
  ///
  /// In pt, this message translates to:
  /// **'{type} salvo nas boxes especializadas!'**
  String savedSuccess(Object type);

  /// No description provided for @errorPetNameNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Erro: Nome do pet não encontrado.'**
  String get errorPetNameNotFound;

  /// No description provided for @healthAnalysisSaved.
  ///
  /// In pt, this message translates to:
  /// **'Análise salva no histórico de saúde de {petName}'**
  String healthAnalysisSaved(Object petName);

  /// No description provided for @errorSavingAnalysis.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao salvar análise: {error}'**
  String errorSavingAnalysis(Object error);

  /// No description provided for @menuHello.
  ///
  /// In pt, this message translates to:
  /// **'Olá!'**
  String get menuHello;

  /// No description provided for @menuHelloUser.
  ///
  /// In pt, this message translates to:
  /// **'Olá, {userName}!'**
  String menuHelloUser(Object userName);

  /// No description provided for @menuAiAssistant.
  ///
  /// In pt, this message translates to:
  /// **'Assistente IA Scannut'**
  String get menuAiAssistant;

  /// No description provided for @menuSettings.
  ///
  /// In pt, this message translates to:
  /// **'Configuração'**
  String get menuSettings;

  /// No description provided for @menuSettingsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Meta diária: {calories} kcal'**
  String menuSettingsSubtitle(Object calories);

  /// No description provided for @menuNutritionalPillars.
  ///
  /// In pt, this message translates to:
  /// **'Pilares da Nutrição'**
  String get menuNutritionalPillars;

  /// No description provided for @menuNutritionalPillarsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Conceitos do ScanNut'**
  String get menuNutritionalPillarsSubtitle;

  /// No description provided for @menuEnergyBalance.
  ///
  /// In pt, this message translates to:
  /// **'Balanço Energético'**
  String get menuEnergyBalance;

  /// No description provided for @menuEnergyBalanceSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Dashboard Fitness & Biohacking'**
  String get menuEnergyBalanceSubtitle;

  /// No description provided for @menuNutritionHistory.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de Nutrição'**
  String get menuNutritionHistory;

  /// No description provided for @menuNutritionHistorySubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Análises de Alimentos'**
  String get menuNutritionHistorySubtitle;

  /// No description provided for @menuBotanyHistory.
  ///
  /// In pt, this message translates to:
  /// **'Histórico Botânico'**
  String get menuBotanyHistory;

  /// No description provided for @menuBotanyHistorySubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Saúde e Guia de Cultivo'**
  String get menuBotanyHistorySubtitle;

  /// No description provided for @menuPetHistory.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de Pets'**
  String get menuPetHistory;

  /// No description provided for @menuPetHistorySubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Dossiês e Exames'**
  String get menuPetHistorySubtitle;

  /// No description provided for @menuHelp.
  ///
  /// In pt, this message translates to:
  /// **'Ajuda'**
  String get menuHelp;

  /// No description provided for @menuHelpSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Como usar o app'**
  String get menuHelpSubtitle;

  /// No description provided for @menuAbout.
  ///
  /// In pt, this message translates to:
  /// **'Sobre'**
  String get menuAbout;

  /// No description provided for @menuPrivacySubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Consultar termos e dados'**
  String get menuPrivacySubtitle;

  /// No description provided for @menuDeleteAccountSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Remover todos os registros'**
  String get menuDeleteAccountSubtitle;

  /// No description provided for @menuExit.
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get menuExit;

  /// No description provided for @menuExitSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Fechar o aplicativo'**
  String get menuExitSubtitle;

  /// No description provided for @footerMadeWith.
  ///
  /// In pt, this message translates to:
  /// **'Feito com ❤️ usando Gemini AI'**
  String get footerMadeWith;

  /// No description provided for @aboutTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sobre o Scannut'**
  String get aboutTitle;

  /// No description provided for @aboutSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Scannut IA Visual Assistant'**
  String get aboutSubtitle;

  /// No description provided for @aboutPoweredBy.
  ///
  /// In pt, this message translates to:
  /// **'Powered by Google Gemini 2.5 Flash'**
  String get aboutPoweredBy;

  /// No description provided for @aboutDescription.
  ///
  /// In pt, this message translates to:
  /// **'Análise inteligente de:\n• Alimentos 🍎\n• Plantas 🌿\n• Pets 🐾'**
  String get aboutDescription;

  /// No description provided for @nutritionGuideTitle.
  ///
  /// In pt, this message translates to:
  /// **'Guia de Nutrição Animal ScanNut'**
  String get nutritionGuideTitle;

  /// No description provided for @nutritionIntro.
  ///
  /// In pt, this message translates to:
  /// **'Diferente dos humanos, os cães e gatos possuem um metabolismo acelerado e exigências nutricionais únicas. O ScanNut utiliza IA para equilibrar estes 5 pilares vitais para a longevidade do seu pet.'**
  String get nutritionIntro;

  /// No description provided for @ngProteinTitle.
  ///
  /// In pt, this message translates to:
  /// **'Proteína Animal'**
  String get ngProteinTitle;

  /// No description provided for @ngProteinSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'A Força do Pet'**
  String get ngProteinSubtitle;

  /// No description provided for @ngProteinWhatIs.
  ///
  /// In pt, this message translates to:
  /// **'Pets são carnívoros (estritos como gatos ou facultativos como cães). Eles precisam de aminoácidos específicos encontrados na carne que o corpo deles não produz.'**
  String get ngProteinWhatIs;

  /// No description provided for @ngProteinAction.
  ///
  /// In pt, this message translates to:
  /// **'Priorizamos fontes como frango, carne bovina, peixes, ovos ou proteínas selecionadas em rações premium.'**
  String get ngProteinAction;

  /// No description provided for @ngFatsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Gorduras Específicas'**
  String get ngFatsTitle;

  /// No description provided for @ngFatsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'A Proteção'**
  String get ngFatsSubtitle;

  /// No description provided for @ngFatsWhatIs.
  ///
  /// In pt, this message translates to:
  /// **'Além da energia, a gordura correta previne dermatites e garante que o pet absorva as vitaminas A, D, E e K. O Ômega 3 é o maior aliado contra inflamações.'**
  String get ngFatsWhatIs;

  /// No description provided for @ngFatsAction.
  ///
  /// In pt, this message translates to:
  /// **'Sugerimos o equilíbrio de Ômegas 3 e 6, provenientes de óleos de peixe ou gorduras boas.'**
  String get ngFatsAction;

  /// No description provided for @ngCarbsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Fibras e Carboidratos Selecionados'**
  String get ngCarbsTitle;

  /// No description provided for @ngCarbsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'O Intestino'**
  String get ngCarbsSubtitle;

  /// No description provided for @ngCarbsWhatIs.
  ///
  /// In pt, this message translates to:
  /// **'O sistema digestivo do pet é mais curto. Usamos carboidratos de fácil digestão (como batata-doce ou arroz) e fibras que auxiliam na formação correta das fezes.'**
  String get ngCarbsWhatIs;

  /// No description provided for @ngCarbsAction.
  ///
  /// In pt, this message translates to:
  /// **'Sugerimos vegetais como abóbora e cenoura, e grãos como arroz integral ou aveia.'**
  String get ngCarbsAction;

  /// No description provided for @ngVitaminsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Minerais e Vitaminas'**
  String get ngVitaminsTitle;

  /// No description provided for @ngVitaminsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Cuidado com a Dose'**
  String get ngVitaminsSubtitle;

  /// No description provided for @ngVitaminsWhatIs.
  ///
  /// In pt, this message translates to:
  /// **'Crucial: O excesso de cálcio pode prejudicar filhotes e a falta pode fragilizar idosos. O ScanNut foca no equilíbrio mineral exato para a estrutura óssea canina e felina.'**
  String get ngVitaminsWhatIs;

  /// No description provided for @ngVitaminsAction.
  ///
  /// In pt, this message translates to:
  /// **'O app sinaliza a necessidade de suplementação, especialmente em dietas Naturais, para evitar carências.'**
  String get ngVitaminsAction;

  /// No description provided for @ngHydrationTitle.
  ///
  /// In pt, this message translates to:
  /// **'Hidratação Biológica'**
  String get ngHydrationTitle;

  /// No description provided for @ngHydrationSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'O Ponto Fraco'**
  String get ngHydrationSubtitle;

  /// No description provided for @ngHydrationWhatIs.
  ///
  /// In pt, this message translates to:
  /// **'Muitos pets não sentem sede proporcional à necessidade. O app incentiva alimentos úmidos para evitar cálculos renais, uma das maiores causas de óbito em gatos e cães idosos.'**
  String get ngHydrationWhatIs;

  /// No description provided for @ngHydrationAction.
  ///
  /// In pt, this message translates to:
  /// **'Sugerimos a inclusão de alimentos úmidos, caldos ou adição de água na ração para proteger os rins.'**
  String get ngHydrationAction;

  /// No description provided for @ngWarningTitle.
  ///
  /// In pt, this message translates to:
  /// **'ATENÇÃO:'**
  String get ngWarningTitle;

  /// No description provided for @ngWarningText.
  ///
  /// In pt, this message translates to:
  /// **'Nunca ofereça alimentos proibidos para pets (como chocolate, uvas, cebola e xilitol). As sugestões do ScanNut respeitam estas restrições de segurança.'**
  String get ngWarningText;

  /// No description provided for @ngSectionWhatIs.
  ///
  /// In pt, this message translates to:
  /// **'O que é:'**
  String get ngSectionWhatIs;

  /// No description provided for @ngSectionScanNut.
  ///
  /// In pt, this message translates to:
  /// **'No ScanNut:'**
  String get ngSectionScanNut;

  /// No description provided for @fitnessDashboardTitle.
  ///
  /// In pt, this message translates to:
  /// **'Dashboard Fitness'**
  String get fitnessDashboardTitle;

  /// No description provided for @fitnessBalanceKcal.
  ///
  /// In pt, this message translates to:
  /// **'Saldo kcal'**
  String get fitnessBalanceKcal;

  /// No description provided for @fitnessMetaDaily.
  ///
  /// In pt, this message translates to:
  /// **'Meta diária: {goal} kcal'**
  String fitnessMetaDaily(Object goal);

  /// No description provided for @fitnessConsumed.
  ///
  /// In pt, this message translates to:
  /// **'Consumido'**
  String get fitnessConsumed;

  /// No description provided for @fitnessBurned.
  ///
  /// In pt, this message translates to:
  /// **'Queimado'**
  String get fitnessBurned;

  /// No description provided for @fitnessPerformance.
  ///
  /// In pt, this message translates to:
  /// **'Performance Biohacking'**
  String get fitnessPerformance;

  /// No description provided for @fitnessTip.
  ///
  /// In pt, this message translates to:
  /// **'Dica do Dia: Treine em jejum hoje para otimizar a queima de gordura de acordo com o seu último consumo de carboidratos.'**
  String get fitnessTip;

  /// No description provided for @fitnessAddWorkout.
  ///
  /// In pt, this message translates to:
  /// **'Add Treino'**
  String get fitnessAddWorkout;

  /// No description provided for @fitnessRegWorkout.
  ///
  /// In pt, this message translates to:
  /// **'Registrar Treino'**
  String get fitnessRegWorkout;

  /// No description provided for @fitnessExerciseHint.
  ///
  /// In pt, this message translates to:
  /// **'Exercício (ex: Corrida)'**
  String get fitnessExerciseHint;

  /// No description provided for @fitnessCaloriesHint.
  ///
  /// In pt, this message translates to:
  /// **'Calorias Queimadas'**
  String get fitnessCaloriesHint;

  /// No description provided for @fitnessDurationHint.
  ///
  /// In pt, this message translates to:
  /// **'Duração (min)'**
  String get fitnessDurationHint;

  /// No description provided for @botanyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Inteligência Botânica'**
  String get botanyTitle;

  /// No description provided for @botanyEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma planta analisada ainda.'**
  String get botanyEmpty;

  /// No description provided for @botanyStatus.
  ///
  /// In pt, this message translates to:
  /// **'STATUS'**
  String get botanyStatus;

  /// No description provided for @botanyToxicHuman.
  ///
  /// In pt, this message translates to:
  /// **'Tóxico para Humanos'**
  String get botanyToxicHuman;

  /// No description provided for @botanyDangerousPet.
  ///
  /// In pt, this message translates to:
  /// **'Perigoso para Pets'**
  String get botanyDangerousPet;

  /// No description provided for @botanyRecovery.
  ///
  /// In pt, this message translates to:
  /// **'Recuperação'**
  String get botanyRecovery;

  /// No description provided for @botanyRecoveryPlan.
  ///
  /// In pt, this message translates to:
  /// **'Plano de Recuperação'**
  String get botanyRecoveryPlan;

  /// No description provided for @botanyFengShui.
  ///
  /// In pt, this message translates to:
  /// **'Feng Shui & Simbolismo'**
  String get botanyFengShui;

  /// No description provided for @botanyDossierTitle.
  ///
  /// In pt, this message translates to:
  /// **'Dossiê Botânico: {plantName}'**
  String botanyDossierTitle(String plantName);

  /// No description provided for @petHistoryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Meus Pets Salvos'**
  String get petHistoryTitle;

  /// No description provided for @petHistoryEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum pet salvo ainda.'**
  String get petHistoryEmpty;

  /// No description provided for @petBreed.
  ///
  /// In pt, this message translates to:
  /// **'N/A'**
  String get petBreed;

  /// No description provided for @petLinkPartnerError.
  ///
  /// In pt, this message translates to:
  /// **'Vincule um parceiro na aba \"Parc.\" para acessar a agenda'**
  String get petLinkPartnerError;

  /// No description provided for @petNoRecentMenu.
  ///
  /// In pt, this message translates to:
  /// **'Sem cardápio recente.'**
  String get petNoRecentMenu;

  /// No description provided for @petEditSaved.
  ///
  /// In pt, this message translates to:
  /// **'Alterações salvas.'**
  String get petEditSaved;

  /// No description provided for @foodHistoryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de Alimentos'**
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

  /// No description provided for @commonUnderstand.
  ///
  /// In pt, this message translates to:
  /// **'Entendi'**
  String get commonUnderstand;

  /// No description provided for @commonClose.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get commonClose;

  /// No description provided for @commonCancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get commonDelete;

  /// No description provided for @linkError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir o link.'**
  String get linkError;

  /// No description provided for @helpTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ajuda e Suporte'**
  String get helpTitle;

  /// No description provided for @helpCommonQuestions.
  ///
  /// In pt, this message translates to:
  /// **'Perguntas Frequentes'**
  String get helpCommonQuestions;

  /// No description provided for @helpContactUs.
  ///
  /// In pt, this message translates to:
  /// **'Entre em Contato'**
  String get helpContactUs;

  /// No description provided for @helpTutorials.
  ///
  /// In pt, this message translates to:
  /// **'Tutoriais em Vídeo'**
  String get helpTutorials;

  /// No description provided for @helpAppVersion.
  ///
  /// In pt, this message translates to:
  /// **'Versão do Aplicativo'**
  String get helpAppVersion;

  /// No description provided for @helpUserGuide.
  ///
  /// In pt, this message translates to:
  /// **'Guia do Usuário'**
  String get helpUserGuide;

  /// No description provided for @helpTermsPrivacy.
  ///
  /// In pt, this message translates to:
  /// **'Termos e Privacidade'**
  String get helpTermsPrivacy;

  /// No description provided for @guideVitalsTitle.
  ///
  /// In pt, this message translates to:
  /// **'SEÇÕES DO PERFIL DO PET'**
  String get guideVitalsTitle;

  /// No description provided for @guideIdentity.
  ///
  /// In pt, this message translates to:
  /// **'Identidade'**
  String get guideIdentity;

  /// No description provided for @guideIdentityDesc.
  ///
  /// In pt, this message translates to:
  /// **'Gerencie os dados vitais do pet: peso, raça, idade e análise comportamental genética completa.'**
  String get guideIdentityDesc;

  /// No description provided for @guideHealth.
  ///
  /// In pt, this message translates to:
  /// **'Saúde'**
  String get guideHealth;

  /// No description provided for @guideHealthDesc.
  ///
  /// In pt, this message translates to:
  /// **'Histórico médico completo com controle de vacinas, vermífugos, exames laboratoriais e lembretes de consultas.'**
  String get guideHealthDesc;

  /// No description provided for @guideNutrition.
  ///
  /// In pt, this message translates to:
  /// **'Nutrição'**
  String get guideNutrition;

  /// No description provided for @guideNutritionDesc.
  ///
  /// In pt, this message translates to:
  /// **'Planejamento alimentar semanal detalhado com cálculos de Kcal, datas (DD/MM) e os 5 pilares nutricionais.'**
  String get guideNutritionDesc;

  /// No description provided for @guideGallery.
  ///
  /// In pt, this message translates to:
  /// **'Galeria'**
  String get guideGallery;

  /// No description provided for @guideGalleryDesc.
  ///
  /// In pt, this message translates to:
  /// **'Documente visualmente a evolução e momentos especiais do seu pet com fotos e vídeos.'**
  String get guideGalleryDesc;

  /// No description provided for @guidePrac.
  ///
  /// In pt, this message translates to:
  /// **'Prac'**
  String get guidePrac;

  /// No description provided for @guidePracDesc.
  ///
  /// In pt, this message translates to:
  /// **'Prontuário de Acompanhamento Comportamental para registrar rotinas, mudanças de hábito e rede de apoio.'**
  String get guidePracDesc;

  /// No description provided for @guideObservationsTitle.
  ///
  /// In pt, this message translates to:
  /// **'OBSERVAÇÕES E HISTÓRICO'**
  String get guideObservationsTitle;

  /// No description provided for @guideHistory.
  ///
  /// In pt, this message translates to:
  /// **'Histórico Cumulativo'**
  String get guideHistory;

  /// No description provided for @guideHistoryDesc.
  ///
  /// In pt, this message translates to:
  /// **'Cada seção possui um campo de observações. Novas anotações NÃO apagam as antigas - tudo fica registrado!'**
  String get guideHistoryDesc;

  /// No description provided for @guideTimestamps.
  ///
  /// In pt, this message translates to:
  /// **'Timestamps Automáticos'**
  String get guideTimestamps;

  /// No description provided for @guideTimestampsDesc.
  ///
  /// In pt, this message translates to:
  /// **'O sistema insere automaticamente Data e Hora em cada entrada, criando um histórico cronológico completo.'**
  String get guideTimestampsDesc;

  /// No description provided for @guideOrder.
  ///
  /// In pt, this message translates to:
  /// **'Ordem Inteligente'**
  String get guideOrder;

  /// No description provided for @guideOrderDesc.
  ///
  /// In pt, this message translates to:
  /// **'A entrada mais recente sempre aparece no topo, facilitando a leitura e acompanhamento.'**
  String get guideOrderDesc;

  /// No description provided for @guideVoice.
  ///
  /// In pt, this message translates to:
  /// **'Ditado por Voz'**
  String get guideVoice;

  /// No description provided for @guideVoiceDesc.
  ///
  /// In pt, this message translates to:
  /// **'Use o ícone de microfone para ditar observações em vez de digitar. Mais rápido e prático!'**
  String get guideVoiceDesc;

  /// No description provided for @guideExportTitle.
  ///
  /// In pt, this message translates to:
  /// **'EXPORTAÇÃO EM PDF'**
  String get guideExportTitle;

  /// No description provided for @guidePdfTitle.
  ///
  /// In pt, this message translates to:
  /// **'Prontuário Veterinário Completo'**
  String get guidePdfTitle;

  /// No description provided for @guidePdfDesc.
  ///
  /// In pt, this message translates to:
  /// **'É gerado automaticamente com TODAS as informações (Perfil + Saúde + Nutrição + Observações). Ideal para levar ao veterinário!'**
  String get guidePdfDesc;

  /// No description provided for @guideBotanyTitle.
  ///
  /// In pt, this message translates to:
  /// **'ANÁLISE DE PLANTAS'**
  String get guideBotanyTitle;

  /// No description provided for @guideBotanyLeaf.
  ///
  /// In pt, this message translates to:
  /// **'Ícone de Folha (Verde)'**
  String get guideBotanyLeaf;

  /// No description provided for @guideBotanyLeafDesc.
  ///
  /// In pt, this message translates to:
  /// **'Indica que a planta está SAUDÁVEL. Nenhuma intervenção urgente necessária.'**
  String get guideBotanyLeafDesc;

  /// No description provided for @guideBotanyAlert.
  ///
  /// In pt, this message translates to:
  /// **'Ícone de Alerta (Amarelo/Laranja)'**
  String get guideBotanyAlert;

  /// No description provided for @guideBotanyAlertDesc.
  ///
  /// In pt, this message translates to:
  /// **'Planta requer ATENÇÃO. Pode estar com deficiências nutricionais ou estresse hídrico.'**
  String get guideBotanyAlertDesc;

  /// No description provided for @guideBotanyCritical.
  ///
  /// In pt, this message translates to:
  /// **'Ícone de Emergência (Vermelho)'**
  String get guideBotanyCritical;

  /// No description provided for @guideBotanyCriticalDesc.
  ///
  /// In pt, this message translates to:
  /// **'Estado CRÍTICO. A planta necessita de tratamento imediato para sobreviver.'**
  String get guideBotanyCriticalDesc;

  /// No description provided for @guideBotanyTraffic.
  ///
  /// In pt, this message translates to:
  /// **'Semáforo de Sobrevivência'**
  String get guideBotanyTraffic;

  /// No description provided for @guideBotanyTrafficDesc.
  ///
  /// In pt, this message translates to:
  /// **'Verde = Ideal | Amarelo = Atenção | Vermelho = Urgente. Aparece nos cards de histórico.'**
  String get guideBotanyTrafficDesc;

  /// No description provided for @guideFinalTip.
  ///
  /// In pt, this message translates to:
  /// **'O ScanNut é uma ferramenta de longo prazo para acompanhar toda a vida do seu pet!'**
  String get guideFinalTip;

  /// No description provided for @tabSummary.
  ///
  /// In pt, this message translates to:
  /// **'RESUMO'**
  String get tabSummary;

  /// No description provided for @tabNutrients.
  ///
  /// In pt, this message translates to:
  /// **'NUTRIENTES'**
  String get tabNutrients;

  /// No description provided for @tabGastronomy.
  ///
  /// In pt, this message translates to:
  /// **'GASTRONOMIA'**
  String get tabGastronomy;

  /// No description provided for @labelTrafficLight.
  ///
  /// In pt, this message translates to:
  /// **'Semáforo (Luz, Água, Solo)'**
  String get labelTrafficLight;

  /// No description provided for @tabHardware.
  ///
  /// In pt, this message translates to:
  /// **'Hardware'**
  String get tabHardware;

  /// No description provided for @tabBios.
  ///
  /// In pt, this message translates to:
  /// **'Bios'**
  String get tabBios;

  /// No description provided for @tabPropagation.
  ///
  /// In pt, this message translates to:
  /// **'Propagação'**
  String get tabPropagation;

  /// No description provided for @cardTapForRecipes.
  ///
  /// In pt, this message translates to:
  /// **'Toque para ver receitas ✨'**
  String get cardTapForRecipes;

  /// No description provided for @cardScore.
  ///
  /// In pt, this message translates to:
  /// **'Score'**
  String get cardScore;

  /// No description provided for @cardTabOverview.
  ///
  /// In pt, this message translates to:
  /// **'Visão Geral'**
  String get cardTabOverview;

  /// No description provided for @cardTabDetails.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes'**
  String get cardTabDetails;

  /// No description provided for @cardTabTips.
  ///
  /// In pt, this message translates to:
  /// **'Dicas'**
  String get cardTabTips;

  /// No description provided for @cardTotalCalories.
  ///
  /// In pt, this message translates to:
  /// **'Calorias Totais'**
  String get cardTotalCalories;

  /// No description provided for @cardDailyGoal.
  ///
  /// In pt, this message translates to:
  /// **'da meta diária'**
  String get cardDailyGoal;

  /// No description provided for @cardMacroDist.
  ///
  /// In pt, this message translates to:
  /// **'Distribuição de Macronutrientes'**
  String get cardMacroDist;

  /// No description provided for @cardQuickSummary.
  ///
  /// In pt, this message translates to:
  /// **'Resumo Rápido'**
  String get cardQuickSummary;

  /// No description provided for @cardBenefits.
  ///
  /// In pt, this message translates to:
  /// **'Benefícios'**
  String get cardBenefits;

  /// No description provided for @cardAlerts.
  ///
  /// In pt, this message translates to:
  /// **'Alertas'**
  String get cardAlerts;

  /// No description provided for @cardVitalityScore.
  ///
  /// In pt, this message translates to:
  /// **'Score de Vitalidade'**
  String get cardVitalityScore;

  /// No description provided for @cardDetailedInfo.
  ///
  /// In pt, this message translates to:
  /// **'Informações Detalhadas'**
  String get cardDetailedInfo;

  /// No description provided for @cardDisclaimer.
  ///
  /// In pt, this message translates to:
  /// **'Nota: Esta é uma análise feita por IA e não substitui um diagnóstico de nutricionista.'**
  String get cardDisclaimer;

  /// No description provided for @pdfFoodTitle.
  ///
  /// In pt, this message translates to:
  /// **'Análise Nutricional & Biohacking'**
  String get pdfFoodTitle;

  /// No description provided for @pdfDate.
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get pdfDate;

  /// No description provided for @pdfCalories.
  ///
  /// In pt, this message translates to:
  /// **'Calorias'**
  String get pdfCalories;

  /// No description provided for @pdfTrafficLight.
  ///
  /// In pt, this message translates to:
  /// **'Semáforo'**
  String get pdfTrafficLight;

  /// No description provided for @pdfProcessing.
  ///
  /// In pt, this message translates to:
  /// **'Processamento'**
  String get pdfProcessing;

  /// No description provided for @pdfExSummary.
  ///
  /// In pt, this message translates to:
  /// **'Resumo Executivo'**
  String get pdfExSummary;

  /// No description provided for @pdfAiVerdict.
  ///
  /// In pt, this message translates to:
  /// **'Veredito da IA'**
  String get pdfAiVerdict;

  /// No description provided for @pdfPros.
  ///
  /// In pt, this message translates to:
  /// **'Pontos Positivos'**
  String get pdfPros;

  /// No description provided for @pdfCons.
  ///
  /// In pt, this message translates to:
  /// **'Pontos de Atenção'**
  String get pdfCons;

  /// No description provided for @pdfDetailedNutrition.
  ///
  /// In pt, this message translates to:
  /// **'Nutrição Detalhada'**
  String get pdfDetailedNutrition;

  /// No description provided for @pdfMacros.
  ///
  /// In pt, this message translates to:
  /// **'Macronutrientes'**
  String get pdfMacros;

  /// No description provided for @pdfNutrient.
  ///
  /// In pt, this message translates to:
  /// **'Nutriente'**
  String get pdfNutrient;

  /// No description provided for @pdfQuantity.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade'**
  String get pdfQuantity;

  /// No description provided for @pdfDetails.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes'**
  String get pdfDetails;

  /// No description provided for @pdfMicros.
  ///
  /// In pt, this message translates to:
  /// **'Micronutrientes e Vitaminas'**
  String get pdfMicros;

  /// No description provided for @pdfSynergy.
  ///
  /// In pt, this message translates to:
  /// **'Sinergia Nutricional'**
  String get pdfSynergy;

  /// No description provided for @pdfBiohacking.
  ///
  /// In pt, this message translates to:
  /// **'Biohacking e Saúde'**
  String get pdfBiohacking;

  /// No description provided for @pdfPerformance.
  ///
  /// In pt, this message translates to:
  /// **'Performance'**
  String get pdfPerformance;

  /// No description provided for @pdfSatiety.
  ///
  /// In pt, this message translates to:
  /// **'Índice de Saciedade'**
  String get pdfSatiety;

  /// No description provided for @pdfFocus.
  ///
  /// In pt, this message translates to:
  /// **'Foco e Energia'**
  String get pdfFocus;

  /// No description provided for @pdfIdealMoment.
  ///
  /// In pt, this message translates to:
  /// **'Momento Ideal'**
  String get pdfIdealMoment;

  /// No description provided for @pdfSecurity.
  ///
  /// In pt, this message translates to:
  /// **'Segurança'**
  String get pdfSecurity;

  /// No description provided for @pdfAlerts.
  ///
  /// In pt, this message translates to:
  /// **'Alertas'**
  String get pdfAlerts;

  /// No description provided for @pdfBiochem.
  ///
  /// In pt, this message translates to:
  /// **'Bioquímica'**
  String get pdfBiochem;

  /// No description provided for @pdfGastronomy.
  ///
  /// In pt, this message translates to:
  /// **'Gastronomia e Dicas'**
  String get pdfGastronomy;

  /// No description provided for @pdfQuickRecipes.
  ///
  /// In pt, this message translates to:
  /// **'Receitas Rápidas'**
  String get pdfQuickRecipes;

  /// No description provided for @pdfGeneratedBy.
  ///
  /// In pt, this message translates to:
  /// **'Gerado por ScanNut'**
  String get pdfGeneratedBy;

  /// No description provided for @pdfPage.
  ///
  /// In pt, this message translates to:
  /// **'Página {current} de {total}'**
  String pdfPage(Object current, Object total);

  /// No description provided for @nutritionMgmtTitle.
  ///
  /// In pt, this message translates to:
  /// **'Gestão de Nutrição'**
  String get nutritionMgmtTitle;

  /// No description provided for @dailyMealPlan.
  ///
  /// In pt, this message translates to:
  /// **'Plano Alimentar Diário'**
  String get dailyMealPlan;

  /// No description provided for @recommendedIntake.
  ///
  /// In pt, this message translates to:
  /// **'Ingestão Recomendada'**
  String get recommendedIntake;

  /// No description provided for @weightMonitoring.
  ///
  /// In pt, this message translates to:
  /// **'Monitoramento de Peso'**
  String get weightMonitoring;

  /// No description provided for @labelProteins.
  ///
  /// In pt, this message translates to:
  /// **'Proteínas'**
  String get labelProteins;

  /// No description provided for @labelCarbs.
  ///
  /// In pt, this message translates to:
  /// **'Carboidratos'**
  String get labelCarbs;

  /// No description provided for @weeklyPlanTitle.
  ///
  /// In pt, this message translates to:
  /// **'Semana de {date}'**
  String weeklyPlanTitle(Object date);

  /// No description provided for @weeklyPlanSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'O que você vai comer nos próximos {count} dias'**
  String weeklyPlanSubtitle(Object count);

  /// No description provided for @tipsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Dicas de Preparo (Batch Cooking)'**
  String get tipsTitle;

  /// No description provided for @caloriesEstimated.
  ///
  /// In pt, this message translates to:
  /// **'kcal estimados para o dia'**
  String get caloriesEstimated;

  /// No description provided for @todayLabel.
  ///
  /// In pt, this message translates to:
  /// **'HOJE'**
  String get todayLabel;

  /// No description provided for @mealBreakfast.
  ///
  /// In pt, this message translates to:
  /// **'Café'**
  String get mealBreakfast;

  /// No description provided for @mealLunch.
  ///
  /// In pt, this message translates to:
  /// **'Almoço'**
  String get mealLunch;

  /// No description provided for @mealSnack.
  ///
  /// In pt, this message translates to:
  /// **'Lanche'**
  String get mealSnack;

  /// No description provided for @mealDinner.
  ///
  /// In pt, this message translates to:
  /// **'Jantar'**
  String get mealDinner;

  /// No description provided for @regeneratePlanTitle.
  ///
  /// In pt, this message translates to:
  /// **'Refazer a semana?'**
  String get regeneratePlanTitle;

  /// No description provided for @regeneratePlanBody.
  ///
  /// In pt, this message translates to:
  /// **'Isso vai criar um novo cardápio para a semana. O atual será substituído.'**
  String get regeneratePlanBody;

  /// No description provided for @regenerateAction.
  ///
  /// In pt, this message translates to:
  /// **'Refazer'**
  String get regenerateAction;

  /// No description provided for @regenerateSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Cardápio da semana refeito!'**
  String get regenerateSuccess;

  /// No description provided for @planError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar o cardápio'**
  String get planError;

  /// No description provided for @tryAgain.
  ///
  /// In pt, this message translates to:
  /// **'Tentar Novamente'**
  String get tryAgain;

  /// No description provided for @noPlanTitle.
  ///
  /// In pt, this message translates to:
  /// **'Você ainda não tem um cardápio'**
  String get noPlanTitle;

  /// No description provided for @createPlanButton.
  ///
  /// In pt, this message translates to:
  /// **'Criar Cardápio'**
  String get createPlanButton;

  /// No description provided for @historyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de Cardápios'**
  String get historyTitle;

  /// No description provided for @noHistory.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum histórico'**
  String get noHistory;

  /// No description provided for @daysPlanned.
  ///
  /// In pt, this message translates to:
  /// **'{count} dias planejados'**
  String daysPlanned(Object count);

  /// No description provided for @deletePlanTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir cardápio?'**
  String get deletePlanTitle;

  /// No description provided for @deletePlanBody.
  ///
  /// In pt, this message translates to:
  /// **'Esta ação não pode ser desfeita.'**
  String get deletePlanBody;

  /// No description provided for @ingredientsTitle.
  ///
  /// In pt, this message translates to:
  /// **'INGREDIENTES'**
  String get ingredientsTitle;

  /// No description provided for @mealDefault.
  ///
  /// In pt, this message translates to:
  /// **'Refeição'**
  String get mealDefault;

  /// No description provided for @creatingProfile.
  ///
  /// In pt, this message translates to:
  /// **'Perfil básico criado automaticamente.'**
  String get creatingProfile;

  /// No description provided for @planCreatedSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Cardápio criado com sucesso!'**
  String get planCreatedSuccess;

  /// No description provided for @openingConfig.
  ///
  /// In pt, this message translates to:
  /// **'Abrindo configuração...'**
  String get openingConfig;

  /// No description provided for @pdfMenuPlanTitle.
  ///
  /// In pt, this message translates to:
  /// **'Plano Alimentar Semanal'**
  String get pdfMenuPlanTitle;

  /// No description provided for @menuCreationTitle.
  ///
  /// In pt, this message translates to:
  /// **'Criar Cardápio da Semana'**
  String get menuCreationTitle;

  /// No description provided for @menuCreationSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Configure como você quer seu cardápio'**
  String get menuCreationSubtitle;

  /// No description provided for @mealsPerDay.
  ///
  /// In pt, this message translates to:
  /// **'Refeições por dia'**
  String get mealsPerDay;

  /// No description provided for @mealsUnit.
  ///
  /// In pt, this message translates to:
  /// **'refeições'**
  String get mealsUnit;

  /// No description provided for @menuStyleTitle.
  ///
  /// In pt, this message translates to:
  /// **'Estilo do cardápio'**
  String get menuStyleTitle;

  /// No description provided for @styleSimple.
  ///
  /// In pt, this message translates to:
  /// **'Simples'**
  String get styleSimple;

  /// No description provided for @styleBudget.
  ///
  /// In pt, this message translates to:
  /// **'Econômico'**
  String get styleBudget;

  /// No description provided for @styleQuick.
  ///
  /// In pt, this message translates to:
  /// **'Rápido'**
  String get styleQuick;

  /// No description provided for @styleHealthy.
  ///
  /// In pt, this message translates to:
  /// **'Saudável'**
  String get styleHealthy;

  /// No description provided for @dietaryRestrictions.
  ///
  /// In pt, this message translates to:
  /// **'Restrições alimentares'**
  String get dietaryRestrictions;

  /// No description provided for @allowRepetition.
  ///
  /// In pt, this message translates to:
  /// **'Pode repetir receitas na semana'**
  String get allowRepetition;

  /// No description provided for @allowRepetitionSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Se desligado, cada receita aparece apenas 1 vez'**
  String get allowRepetitionSubtitle;

  /// No description provided for @restVegetarian.
  ///
  /// In pt, this message translates to:
  /// **'Vegetariano'**
  String get restVegetarian;

  /// No description provided for @restVegan.
  ///
  /// In pt, this message translates to:
  /// **'Vegano'**
  String get restVegan;

  /// No description provided for @restLactoseFree.
  ///
  /// In pt, this message translates to:
  /// **'Sem Lactose'**
  String get restLactoseFree;

  /// No description provided for @restGlutenFree.
  ///
  /// In pt, this message translates to:
  /// **'Sem Glúten'**
  String get restGlutenFree;

  /// No description provided for @restDiabetes.
  ///
  /// In pt, this message translates to:
  /// **'Diabetes'**
  String get restDiabetes;

  /// No description provided for @restHypertension.
  ///
  /// In pt, this message translates to:
  /// **'Hipertensão'**
  String get restHypertension;

  /// No description provided for @pdfPersonalizedPlanTitle.
  ///
  /// In pt, this message translates to:
  /// **'PLANO ALIMENTAR PERSONALIZADO'**
  String get pdfPersonalizedPlanTitle;

  /// No description provided for @pdfGoalLabel.
  ///
  /// In pt, this message translates to:
  /// **'OBJETIVO'**
  String get pdfGoalLabel;

  /// No description provided for @pdfGeneratedByLine.
  ///
  /// In pt, this message translates to:
  /// **'RELATÓRIO DE NUTRIÇÃO SEMANAL GERADO POR SCAN NUT AI'**
  String get pdfGeneratedByLine;

  /// No description provided for @pdfBatchCookingTips.
  ///
  /// In pt, this message translates to:
  /// **'💡 DICAS DE BATCH COOKING & PREPARO'**
  String get pdfBatchCookingTips;

  /// No description provided for @tipBeans.
  ///
  /// In pt, this message translates to:
  /// **'💡 Cozinhe uma panela grande de feijão logo no início da semana e congele porções para economizar gás e tempo.'**
  String get tipBeans;

  /// No description provided for @tipRice.
  ///
  /// In pt, this message translates to:
  /// **'💡 Mantenha uma base de arroz branco pronta na geladeira; ele é o acompanhamento coringa para quase todos os seus PFs.'**
  String get tipRice;

  /// No description provided for @tipChicken.
  ///
  /// In pt, this message translates to:
  /// **'💡 Cozinhe e desfie o frango de uma única vez. Use-o no sanduíche natural, no wrap e no mexidão de sexta.'**
  String get tipChicken;

  /// No description provided for @tipEggs.
  ///
  /// In pt, this message translates to:
  /// **'💡 Ovos são sua proteína econômica e rápida. Mantenha-os sempre à mão para substituir carnes em dias corridos.'**
  String get tipEggs;

  /// No description provided for @tipVeggies.
  ///
  /// In pt, this message translates to:
  /// **'💡 Lave e pique todos os vegetais da estação assim que chegar do mercado. Guarde-os em potes herméticos para durarem mais.'**
  String get tipVeggies;

  /// No description provided for @tipRoots.
  ///
  /// In pt, this message translates to:
  /// **'💡 Raízes como mandioca e batata doce podem ser cozidas em grande quantidade e guardadas na água na geladeira por 3 dias.'**
  String get tipRoots;

  /// No description provided for @tipGroundMeat.
  ///
  /// In pt, this message translates to:
  /// **'💡 A carne moída é a base perfeita: use-a pura no almoço e no recheio da panqueca ou sanduíche no dia seguinte.'**
  String get tipGroundMeat;

  /// No description provided for @tipFruits.
  ///
  /// In pt, this message translates to:
  /// **'💡 Frutas muito maduras? Congele-as em pedaços para turbinar suas vitaminas e smoothies matinais.'**
  String get tipFruits;

  /// No description provided for @tipDefault.
  ///
  /// In pt, this message translates to:
  /// **'Planeje suas compras com foco em itens da estação para economizar e ganhar saúde.'**
  String get tipDefault;

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

  /// No description provided for @defaultWoundAnalysis.
  ///
  /// In pt, this message translates to:
  /// **'Análise de Ferida/Lesão'**
  String get defaultWoundAnalysis;

  /// No description provided for @petSelectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'De qual pet é esta análise?'**
  String get petSelectionTitle;

  /// No description provided for @petNew.
  ///
  /// In pt, this message translates to:
  /// **'Novo Pet'**
  String get petNew;

  /// No description provided for @petQuickAnalysis.
  ///
  /// In pt, this message translates to:
  /// **'Análise rápida sem salvar'**
  String get petQuickAnalysis;

  /// No description provided for @paywallBenefit1.
  ///
  /// In pt, this message translates to:
  /// **'Acesso ilimitado a todos os recursos'**
  String get paywallBenefit1;

  /// No description provided for @paywallBenefit2.
  ///
  /// In pt, this message translates to:
  /// **'Análises detalhadas e avançadas'**
  String get paywallBenefit2;

  /// No description provided for @paywallBenefit3.
  ///
  /// In pt, this message translates to:
  /// **'PDFs completos sem restrições'**
  String get paywallBenefit3;

  /// No description provided for @paywallBenefit4.
  ///
  /// In pt, this message translates to:
  /// **'Suporte prioritário'**
  String get paywallBenefit4;

  /// No description provided for @featureMicrosTitle.
  ///
  /// In pt, this message translates to:
  /// **'Micronutrientes e Sinergia'**
  String get featureMicrosTitle;

  /// No description provided for @featureMicrosDesc.
  ///
  /// In pt, this message translates to:
  /// **'Obtenha análise completa de vitaminas, minerais e como eles interagem.'**
  String get featureMicrosDesc;

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

  /// No description provided for @unknownFood.
  ///
  /// In pt, this message translates to:
  /// **'Alimento Desconhecido'**
  String get unknownFood;

  /// No description provided for @actionDelete.
  ///
  /// In pt, this message translates to:
  /// **'Apagar'**
  String get actionDelete;

  /// No description provided for @plantCareGuide.
  ///
  /// In pt, this message translates to:
  /// **'Guia de Cuidados'**
  String get plantCareGuide;

  /// No description provided for @toxicityWarning.
  ///
  /// In pt, this message translates to:
  /// **'Alerta de Toxicidade'**
  String get toxicityWarning;

  /// No description provided for @featureMenuPlanTitle.
  ///
  /// In pt, this message translates to:
  /// **'Planeamento de Cardápio Inteligente'**
  String get featureMenuPlanTitle;

  /// No description provided for @featureMenuPlanDesc.
  ///
  /// In pt, this message translates to:
  /// **'Crie cardápios semanais personalizados baseados nas suas metas e restrições alimentares.'**
  String get featureMenuPlanDesc;

  /// No description provided for @plantHomeSafety.
  ///
  /// In pt, this message translates to:
  /// **'Segurança Doméstica'**
  String get plantHomeSafety;

  /// No description provided for @plantDangerPets.
  ///
  /// In pt, this message translates to:
  /// **'Pode ser perigoso para animais de estimação.'**
  String get plantDangerPets;

  /// No description provided for @plantDangerKids.
  ///
  /// In pt, this message translates to:
  /// **'Perigoso para Crianças'**
  String get plantDangerKids;

  /// No description provided for @plantNoAlerts.
  ///
  /// In pt, this message translates to:
  /// **'Sem alertas específicos.'**
  String get plantNoAlerts;

  /// No description provided for @plantBioPower.
  ///
  /// In pt, this message translates to:
  /// **'Poderes Biofílicos'**
  String get plantBioPower;

  /// No description provided for @plantAirScore.
  ///
  /// In pt, this message translates to:
  /// **'Pontuação de Ar'**
  String get plantAirScore;

  /// No description provided for @plantHumidification.
  ///
  /// In pt, this message translates to:
  /// **'Umidificação'**
  String get plantHumidification;

  /// No description provided for @plantWellness.
  ///
  /// In pt, this message translates to:
  /// **'Bem-estar'**
  String get plantWellness;

  /// No description provided for @plantPropagationEngine.
  ///
  /// In pt, this message translates to:
  /// **'Engenharia de Propagação'**
  String get plantPropagationEngine;

  /// No description provided for @plantMethod.
  ///
  /// In pt, this message translates to:
  /// **'Método'**
  String get plantMethod;

  /// No description provided for @plantDifficulty.
  ///
  /// In pt, this message translates to:
  /// **'Dificuldade'**
  String get plantDifficulty;

  /// No description provided for @plantStepByStep.
  ///
  /// In pt, this message translates to:
  /// **'Passo a Passo'**
  String get plantStepByStep;

  /// No description provided for @plantEcoIntel.
  ///
  /// In pt, this message translates to:
  /// **'Inteligência de Ecossistema'**
  String get plantEcoIntel;

  /// No description provided for @plantCompanions.
  ///
  /// In pt, this message translates to:
  /// **'Plantas Companheiras'**
  String get plantCompanions;

  /// No description provided for @plantAvoid.
  ///
  /// In pt, this message translates to:
  /// **'Evitar'**
  String get plantAvoid;

  /// No description provided for @plantRepellent.
  ///
  /// In pt, this message translates to:
  /// **'Repelente'**
  String get plantRepellent;

  /// No description provided for @plantFengShui.
  ///
  /// In pt, this message translates to:
  /// **'Feng Shui'**
  String get plantFengShui;

  /// No description provided for @plantPlacement.
  ///
  /// In pt, this message translates to:
  /// **'Posicionamento'**
  String get plantPlacement;

  /// No description provided for @plantSymbolism.
  ///
  /// In pt, this message translates to:
  /// **'Simbolismo'**
  String get plantSymbolism;

  /// No description provided for @plantLivingAesthetic.
  ///
  /// In pt, this message translates to:
  /// **'Estética Viva'**
  String get plantLivingAesthetic;

  /// No description provided for @plantFlowering.
  ///
  /// In pt, this message translates to:
  /// **'Floração'**
  String get plantFlowering;

  /// No description provided for @plantFlowerColor.
  ///
  /// In pt, this message translates to:
  /// **'Cor das Flores'**
  String get plantFlowerColor;

  /// No description provided for @plantGrowth.
  ///
  /// In pt, this message translates to:
  /// **'Crescimento'**
  String get plantGrowth;

  /// No description provided for @plantMaxSize.
  ///
  /// In pt, this message translates to:
  /// **'Tamanho Máximo'**
  String get plantMaxSize;

  /// No description provided for @plantNeedSun.
  ///
  /// In pt, this message translates to:
  /// **'Luminosidade'**
  String get plantNeedSun;

  /// No description provided for @plantNeedWater.
  ///
  /// In pt, this message translates to:
  /// **'Rega'**
  String get plantNeedWater;

  /// No description provided for @plantNeedSoil.
  ///
  /// In pt, this message translates to:
  /// **'Solo'**
  String get plantNeedSoil;

  /// No description provided for @plantSeasonAdjust.
  ///
  /// In pt, this message translates to:
  /// **'Ajuste Sazonal'**
  String get plantSeasonAdjust;

  /// No description provided for @seasonWinter.
  ///
  /// In pt, this message translates to:
  /// **'Inverno'**
  String get seasonWinter;

  /// No description provided for @seasonSummer.
  ///
  /// In pt, this message translates to:
  /// **'Verão'**
  String get seasonSummer;

  /// No description provided for @plantClinicalDiagnosis.
  ///
  /// In pt, this message translates to:
  /// **'Diagnóstico Clínico'**
  String get plantClinicalDiagnosis;

  /// No description provided for @plantRecoveryPlan.
  ///
  /// In pt, this message translates to:
  /// **'Plano de Recuperação'**
  String get plantRecoveryPlan;

  /// No description provided for @plantUrgency.
  ///
  /// In pt, this message translates to:
  /// **'Urgência'**
  String get plantUrgency;

  /// No description provided for @plantBuyTreatment.
  ///
  /// In pt, this message translates to:
  /// **'Comprar Tratamento'**
  String get plantBuyTreatment;

  /// No description provided for @fallbackNoInfo.
  ///
  /// In pt, this message translates to:
  /// **'Sem informação'**
  String get fallbackNoInfo;

  /// No description provided for @fallbackDirectWatering.
  ///
  /// In pt, this message translates to:
  /// **'Rega direta no solo'**
  String get fallbackDirectWatering;

  /// No description provided for @fallbackAsNeeded.
  ///
  /// In pt, this message translates to:
  /// **'Conforme necessário'**
  String get fallbackAsNeeded;

  /// No description provided for @advancedDiagnosis.
  ///
  /// In pt, this message translates to:
  /// **'Diagnóstico Avançado'**
  String get advancedDiagnosis;

  /// No description provided for @advancedDiagnosisDesc.
  ///
  /// In pt, this message translates to:
  /// **'Acesse diagnósticos clínicos detalhados e guias de recuperação passo a passo.'**
  String get advancedDiagnosisDesc;

  /// No description provided for @biosTitle.
  ///
  /// In pt, this message translates to:
  /// **'Segurança e Biofília'**
  String get biosTitle;

  /// No description provided for @biosDesc.
  ///
  /// In pt, this message translates to:
  /// **'Saiba detalhes sobre toxicidade para pets/crianças e benefícios biófilicos da planta.'**
  String get biosDesc;

  /// No description provided for @noInformation.
  ///
  /// In pt, this message translates to:
  /// **'Sem informação'**
  String get noInformation;

  /// No description provided for @directSoilWatering.
  ///
  /// In pt, this message translates to:
  /// **'Rega direta no solo'**
  String get directSoilWatering;

  /// No description provided for @asNeeded.
  ///
  /// In pt, this message translates to:
  /// **'Conforme necessário'**
  String get asNeeded;

  /// No description provided for @plantFamily.
  ///
  /// In pt, this message translates to:
  /// **'Família'**
  String get plantFamily;

  /// No description provided for @plantIdentificationTaxonomy.
  ///
  /// In pt, this message translates to:
  /// **'Identificação e Taxonomia'**
  String get plantIdentificationTaxonomy;

  /// No description provided for @plantPopularNames.
  ///
  /// In pt, this message translates to:
  /// **'Nomes Populares'**
  String get plantPopularNames;

  /// No description provided for @plantScientificName.
  ///
  /// In pt, this message translates to:
  /// **'Nome Científico'**
  String get plantScientificName;

  /// No description provided for @plantOrigin.
  ///
  /// In pt, this message translates to:
  /// **'Origem'**
  String get plantOrigin;

  /// No description provided for @plantDetails.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes'**
  String get plantDetails;

  /// No description provided for @plantSubstrate.
  ///
  /// In pt, this message translates to:
  /// **'Substrato'**
  String get plantSubstrate;

  /// No description provided for @plantFertilizer.
  ///
  /// In pt, this message translates to:
  /// **'Fertilizante'**
  String get plantFertilizer;

  /// No description provided for @plantIdealPh.
  ///
  /// In pt, this message translates to:
  /// **'pH Ideal'**
  String get plantIdealPh;

  /// No description provided for @plantToxicityDetails.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes de Toxicidade'**
  String get plantToxicityDetails;

  /// No description provided for @safetyAlert.
  ///
  /// In pt, this message translates to:
  /// **'Alerta de Segurança'**
  String get safetyAlert;

  /// No description provided for @close.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get close;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'PT':
            return AppLocalizationsPtPt();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
