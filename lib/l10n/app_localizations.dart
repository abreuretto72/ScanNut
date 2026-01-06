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
  /// **'ScanNut'**
  String get appTitle;

  /// No description provided for @splashPoweredBy.
  ///
  /// In pt, this message translates to:
  /// **'Tecnologia AI Vision'**
  String get splashPoweredBy;

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

  /// No description provided for @petUnknown.
  ///
  /// In pt, this message translates to:
  /// **'Pet Desconhecido'**
  String get petUnknown;

  /// No description provided for @homeHintFood.
  ///
  /// In pt, this message translates to:
  /// **'Aponte a câmera para a comida/refeição'**
  String get homeHintFood;

  /// No description provided for @homeHintPlant.
  ///
  /// In pt, this message translates to:
  /// **'Aponte a câmera para a planta ou doença'**
  String get homeHintPlant;

  /// No description provided for @homeHintPet.
  ///
  /// In pt, this message translates to:
  /// **'Aponte a câmera para o pet'**
  String get homeHintPet;

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
  /// **'Prontuário'**
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
  /// **'Hub de Apoio'**
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
  /// **'Esta análise é informativa e baseada em processamento automático. Consulte sempre o veterinário vinculado na aba Parc. para um diagnóstico preciso.'**
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

  /// No description provided for @analysisErrorInvalidCategory.
  ///
  /// In pt, this message translates to:
  /// **'A foto difere da categoria. A IA pode errar!'**
  String get analysisErrorInvalidCategory;

  /// No description provided for @analysisErrorNotDetected.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma alteração ou problema detectado na imagem.'**
  String get analysisErrorNotDetected;

  /// No description provided for @errorNoInternet.
  ///
  /// In pt, this message translates to:
  /// **'Sem conexão com a internet. Verifique sua rede.'**
  String get errorNoInternet;

  /// No description provided for @errorTimeout.
  ///
  /// In pt, this message translates to:
  /// **'A operação demorou muito. Tente novamente.'**
  String get errorTimeout;

  /// No description provided for @errorAuthentication.
  ///
  /// In pt, this message translates to:
  /// **'Erro de autenticação. Verifique suas credenciais.'**
  String get errorAuthentication;

  /// No description provided for @errorNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Recurso não encontrado. Tente novamente.'**
  String get errorNotFound;

  /// No description provided for @errorServer.
  ///
  /// In pt, this message translates to:
  /// **'Erro no servidor. Tente novamente em alguns instantes.'**
  String get errorServer;

  /// No description provided for @errorImageTooLarge.
  ///
  /// In pt, this message translates to:
  /// **'Imagem muito grande. Tente com uma foto menor.'**
  String get errorImageTooLarge;

  /// No description provided for @errorInvalidImage.
  ///
  /// In pt, this message translates to:
  /// **'Imagem inválida. Tire uma nova foto.'**
  String get errorInvalidImage;

  /// No description provided for @errorConfiguration.
  ///
  /// In pt, this message translates to:
  /// **'Erro de configuração. Entre em contato com o suporte.'**
  String get errorConfiguration;

  /// No description provided for @errorPermissionDenied.
  ///
  /// In pt, this message translates to:
  /// **'Permissão negada. Verifique as configurações.'**
  String get errorPermissionDenied;

  /// No description provided for @errorNoStorage.
  ///
  /// In pt, this message translates to:
  /// **'Espaço insuficiente no dispositivo.'**
  String get errorNoStorage;

  /// No description provided for @errorCamera.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao acessar a câmera.'**
  String get errorCamera;

  /// No description provided for @errorLocation.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao acessar localização.'**
  String get errorLocation;

  /// No description provided for @errorDatabase.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao salvar dados localmente.'**
  String get errorDatabase;

  /// No description provided for @errorJsonParse.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao processar resposta da IA.'**
  String get errorJsonParse;

  /// No description provided for @errorIncompleteData.
  ///
  /// In pt, this message translates to:
  /// **'Dados incompletos recebidos.'**
  String get errorIncompleteData;

  /// No description provided for @errorGeneric.
  ///
  /// In pt, this message translates to:
  /// **'Ops! Algo deu errado. Seus dados estão seguros. Tente novamente.'**
  String get errorGeneric;

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
  /// **'Calculando métricas personalizadas e identificando raça...'**
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

  /// No description provided for @partnersTitle.
  ///
  /// In pt, this message translates to:
  /// **'Futuros Parceiros'**
  String get partnersTitle;

  /// No description provided for @partnersSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Parceiros cadastrados no ecossistema'**
  String get partnersSubtitle;

  /// No description provided for @partnersFilterAll.
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get partnersFilterAll;

  /// No description provided for @partnersFilterVet.
  ///
  /// In pt, this message translates to:
  /// **'Veterinário'**
  String get partnersFilterVet;

  /// No description provided for @partnersFilterPetShop.
  ///
  /// In pt, this message translates to:
  /// **'Pet Shop'**
  String get partnersFilterPetShop;

  /// No description provided for @partnersFilterPharmacy.
  ///
  /// In pt, this message translates to:
  /// **'Farmácia'**
  String get partnersFilterPharmacy;

  /// No description provided for @partnersFilterHotel.
  ///
  /// In pt, this message translates to:
  /// **'Hotel'**
  String get partnersFilterHotel;

  /// No description provided for @partnersFilterGrooming.
  ///
  /// In pt, this message translates to:
  /// **'Banho e Tosa'**
  String get partnersFilterGrooming;

  /// No description provided for @partnersFilterLab.
  ///
  /// In pt, this message translates to:
  /// **'Laboratório'**
  String get partnersFilterLab;

  /// No description provided for @deletePetTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir Pet'**
  String get deletePetTitle;

  /// No description provided for @deletePetConfirmation.
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza que deseja excluir este pet permanentemente? Esta ação não pode ser desfeita.'**
  String get deletePetConfirmation;

  /// No description provided for @deletePlantTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir Planta'**
  String get deletePlantTitle;

  /// No description provided for @deletePlantConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza que deseja excluir esta planta? Esta ação não pode ser desfeita.'**
  String get deletePlantConfirm;

  /// No description provided for @delete.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get delete;

  /// No description provided for @petActivityLow.
  ///
  /// In pt, this message translates to:
  /// **'Baixo'**
  String get petActivityLow;

  /// No description provided for @petActivityHigh.
  ///
  /// In pt, this message translates to:
  /// **'Alto'**
  String get petActivityHigh;

  /// No description provided for @petActivityAthlete.
  ///
  /// In pt, this message translates to:
  /// **'Atleta'**
  String get petActivityAthlete;

  /// No description provided for @petBathWeekly.
  ///
  /// In pt, this message translates to:
  /// **'Semanal'**
  String get petBathWeekly;

  /// No description provided for @petBathMonthly.
  ///
  /// In pt, this message translates to:
  /// **'Mensal'**
  String get petBathMonthly;

  /// No description provided for @petNotOffice.
  ///
  /// In pt, this message translates to:
  /// **'Tipo de dieta não especificado'**
  String get petNotOffice;

  /// No description provided for @whatsappInitialMessage.
  ///
  /// In pt, this message translates to:
  /// **'Olá! Vi seu perfil no ScanNut e gostaria de mais informações.'**
  String get whatsappInitialMessage;

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
  /// **'Deseja realmente sair do ScanNut?'**
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
  /// **'Análise de saúde de {petName} salva com sucesso!'**
  String healthAnalysisSaved(String petName);

  /// No description provided for @errorSavingAnalysis.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao salvar análise: {error}'**
  String errorSavingAnalysis(String error);

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
  /// **'Assistente IA ScanNut'**
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

  /// No description provided for @logoutTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sair e Desconectar'**
  String get logoutTitle;

  /// No description provided for @logoutSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Encerrar sessão no ScanNut'**
  String get logoutSubtitle;

  /// No description provided for @contactSubject.
  ///
  /// In pt, this message translates to:
  /// **'Contato ScanNut'**
  String get contactSubject;

  /// No description provided for @helpWelcomeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Bem-vindo ao ScanNut!'**
  String get helpWelcomeTitle;

  /// No description provided for @helpWelcomeSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Seu assistente visual de IA para alimentos, plantas e pets'**
  String get helpWelcomeSubtitle;

  /// No description provided for @helpDisclaimerTitle.
  ///
  /// In pt, this message translates to:
  /// **'⚠️ AVISO IMPORTANTE'**
  String get helpDisclaimerTitle;

  /// No description provided for @helpDisclaimerBody.
  ///
  /// In pt, this message translates to:
  /// **'A Inteligência Artificial pode cometer erros na análise de imagens. O ScanNut NÃO se responsabiliza pelas informações geradas pela IA.\n\n• Análises são apenas ORIENTATIVAS\n• NÃO substituem profissionais qualificados\n• Sempre consulte veterinários, nutricionistas ou botânicos\n• Use o app como ferramenta de apoio, não como diagnóstico final'**
  String get helpDisclaimerBody;

  /// No description provided for @helpFooter.
  ///
  /// In pt, this message translates to:
  /// **'Desenvolvido com ❤️ por Abreu Retto\n© 2026 ScanNut'**
  String get helpFooter;

  /// No description provided for @footerDevelopedBy.
  ///
  /// In pt, this message translates to:
  /// **'Desenvolvido por Abreu Retto'**
  String get footerDevelopedBy;

  /// No description provided for @footerMadeWith.
  ///
  /// In pt, this message translates to:
  /// **'Feito com ❤️ usando Gemini AI'**
  String get footerMadeWith;

  /// No description provided for @aboutTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sobre o ScanNut'**
  String get aboutTitle;

  /// No description provided for @aboutSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'ScanNut IA Visual Assistant'**
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
  /// **'Vincule o pet a um Veterinário ou Pet Shop na aba \'Parceiros\' para usar a agenda.'**
  String get petLinkPartnerError;

  /// No description provided for @petNoRecentMenu.
  ///
  /// In pt, this message translates to:
  /// **'O pet ainda não tem cardápio gerado'**
  String get petNoRecentMenu;

  /// No description provided for @petEditSaved.
  ///
  /// In pt, this message translates to:
  /// **'Alterações salvas.'**
  String get petEditSaved;

  /// No description provided for @petVisualDescription.
  ///
  /// In pt, this message translates to:
  /// **'Descrição Visual'**
  String get petVisualDescription;

  /// No description provided for @petPossibleCauses.
  ///
  /// In pt, this message translates to:
  /// **'Causas Prováveis'**
  String get petPossibleCauses;

  /// No description provided for @petSpecialistOrientation.
  ///
  /// In pt, this message translates to:
  /// **'Orientação do Especialista'**
  String get petSpecialistOrientation;

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

  /// No description provided for @commonYes.
  ///
  /// In pt, this message translates to:
  /// **'Sim'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In pt, this message translates to:
  /// **'Não'**
  String get commonNo;

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
  /// **'Gerado em {date} por {owner}'**
  String pdfGeneratedBy(Object date, Object owner);

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

  /// No description provided for @periodTypeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Período do Cardápio'**
  String get periodTypeTitle;

  /// No description provided for @periodWeekly.
  ///
  /// In pt, this message translates to:
  /// **'Semanal (7 dias)'**
  String get periodWeekly;

  /// No description provided for @periodMonthly.
  ///
  /// In pt, this message translates to:
  /// **'Mensal (28 dias)'**
  String get periodMonthly;

  /// No description provided for @objectiveTitle.
  ///
  /// In pt, this message translates to:
  /// **'Objetivo'**
  String get objectiveTitle;

  /// No description provided for @objMaintenance.
  ///
  /// In pt, this message translates to:
  /// **'Manter peso'**
  String get objMaintenance;

  /// No description provided for @objWeightLoss.
  ///
  /// In pt, this message translates to:
  /// **'Emagrecimento'**
  String get objWeightLoss;

  /// No description provided for @objBalanced.
  ///
  /// In pt, this message translates to:
  /// **'Alimentação equilibrada'**
  String get objBalanced;

  /// No description provided for @periodSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Para quando?'**
  String get periodSectionTitle;

  /// No description provided for @periodSectionDesc.
  ///
  /// In pt, this message translates to:
  /// **'Escolha o período do cardápio que será gerado.'**
  String get periodSectionDesc;

  /// No description provided for @periodThisWeek.
  ///
  /// In pt, this message translates to:
  /// **'Esta semana'**
  String get periodThisWeek;

  /// No description provided for @periodNextWeek.
  ///
  /// In pt, this message translates to:
  /// **'Próxima semana'**
  String get periodNextWeek;

  /// No description provided for @period28Days.
  ///
  /// In pt, this message translates to:
  /// **'Próximos 28 dias'**
  String get period28Days;

  /// No description provided for @objectiveSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Objetivo do cardápio'**
  String get objectiveSectionTitle;

  /// No description provided for @objectiveSectionDesc.
  ///
  /// In pt, this message translates to:
  /// **'O objetivo influencia a escolha dos alimentos e calorias.'**
  String get objectiveSectionDesc;

  /// No description provided for @preferencesSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Preferências alimentares'**
  String get preferencesSectionTitle;

  /// No description provided for @preferencesSectionDesc.
  ///
  /// In pt, this message translates to:
  /// **'Opcional. Se não marcar nada, o cardápio será padrão.'**
  String get preferencesSectionDesc;

  /// No description provided for @confirmationSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Resumo da escolha'**
  String get confirmationSectionTitle;

  /// No description provided for @confirmationSummaryLead.
  ///
  /// In pt, this message translates to:
  /// **'Você vai gerar:'**
  String get confirmationSummaryLead;

  /// No description provided for @confirmationPeriodPrefix.
  ///
  /// In pt, this message translates to:
  /// **'• Cardápio: '**
  String get confirmationPeriodPrefix;

  /// No description provided for @confirmationObjectivePrefix.
  ///
  /// In pt, this message translates to:
  /// **'• Objetivo: '**
  String get confirmationObjectivePrefix;

  /// No description provided for @generateMenuAction.
  ///
  /// In pt, this message translates to:
  /// **'GERAR CARDÁPIO'**
  String get generateMenuAction;

  /// No description provided for @selectPeriodError.
  ///
  /// In pt, this message translates to:
  /// **'Escolha o período do cardápio.'**
  String get selectPeriodError;

  /// No description provided for @generatingMenu.
  ///
  /// In pt, this message translates to:
  /// **'Gerando seu cardápio...'**
  String get generatingMenu;

  /// No description provided for @redoPlanAction.
  ///
  /// In pt, this message translates to:
  /// **'Refazer esta semana'**
  String get redoPlanAction;

  /// No description provided for @generateNextWeekAction.
  ///
  /// In pt, this message translates to:
  /// **'Gerar próxima semana'**
  String get generateNextWeekAction;

  /// No description provided for @generate28DaysAction.
  ///
  /// In pt, this message translates to:
  /// **'Gerar próximos 28 dias'**
  String get generate28DaysAction;

  /// No description provided for @createNewVersion.
  ///
  /// In pt, this message translates to:
  /// **'Criar nova versão'**
  String get createNewVersion;

  /// No description provided for @replaceExisting.
  ///
  /// In pt, this message translates to:
  /// **'Substituir atual'**
  String get replaceExisting;

  /// No description provided for @redoPlanPrompt.
  ///
  /// In pt, this message translates to:
  /// **'Como você deseja refazer este cardápio?'**
  String get redoPlanPrompt;

  /// No description provided for @historyFilter.
  ///
  /// In pt, this message translates to:
  /// **'Filtrar Histórico'**
  String get historyFilter;

  /// No description provided for @allPeriods.
  ///
  /// In pt, this message translates to:
  /// **'Todos os Períodos'**
  String get allPeriods;

  /// No description provided for @activeStatus.
  ///
  /// In pt, this message translates to:
  /// **'Ativo'**
  String get activeStatus;

  /// No description provided for @archivedStatus.
  ///
  /// In pt, this message translates to:
  /// **'Arquivado'**
  String get archivedStatus;

  /// No description provided for @editMeal.
  ///
  /// In pt, this message translates to:
  /// **'Editar Refeição'**
  String get editMeal;

  /// No description provided for @saveChanges.
  ///
  /// In pt, this message translates to:
  /// **'Salvar Alterações'**
  String get saveChanges;

  /// No description provided for @deletePlanSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Cardápio excluído com sucesso.'**
  String get deletePlanSuccess;

  /// No description provided for @mealRemoved.
  ///
  /// In pt, this message translates to:
  /// **'Cardápio removido.'**
  String get mealRemoved;

  /// No description provided for @statusActive.
  ///
  /// In pt, this message translates to:
  /// **'Ativo'**
  String get statusActive;

  /// No description provided for @statusArchived.
  ///
  /// In pt, this message translates to:
  /// **'Arquivado'**
  String get statusArchived;

  /// No description provided for @versionLabel.
  ///
  /// In pt, this message translates to:
  /// **'Versão'**
  String get versionLabel;

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
  /// **'RELATÓRIO DE NUTRIÇÃO SEMANAL GERADO POR ScanNut AI'**
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
  /// **'Análise visual de ferida ou lesão detectada'**
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

  /// No description provided for @editPetTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar Perfil'**
  String get editPetTitle;

  /// No description provided for @newPetTitle.
  ///
  /// In pt, this message translates to:
  /// **'Novo Pet'**
  String get newPetTitle;

  /// No description provided for @petNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome do Pet'**
  String get petNameLabel;

  /// No description provided for @petNameRequired.
  ///
  /// In pt, this message translates to:
  /// **'Nome do pet é obrigatório.'**
  String get petNameRequired;

  /// No description provided for @petBreedLabel.
  ///
  /// In pt, this message translates to:
  /// **'Raça'**
  String get petBreedLabel;

  /// No description provided for @petAgeLabel.
  ///
  /// In pt, this message translates to:
  /// **'Idade Exata (ex: 2 anos 3 meses)'**
  String get petAgeLabel;

  /// No description provided for @petBiologicalProfile.
  ///
  /// In pt, this message translates to:
  /// **'Perfil Biológico'**
  String get petBiologicalProfile;

  /// No description provided for @petActivityLevelLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nível de Atividade'**
  String get petActivityLevelLabel;

  /// No description provided for @petReproductiveStatusLabel.
  ///
  /// In pt, this message translates to:
  /// **'Status Reprodutivo'**
  String get petReproductiveStatusLabel;

  /// No description provided for @petIdentity.
  ///
  /// In pt, this message translates to:
  /// **'Identidade'**
  String get petIdentity;

  /// No description provided for @petHealth.
  ///
  /// In pt, this message translates to:
  /// **'💉 Saúde'**
  String get petHealth;

  /// No description provided for @petNutrition.
  ///
  /// In pt, this message translates to:
  /// **'🍖 Alimentação'**
  String get petNutrition;

  /// No description provided for @petGallery.
  ///
  /// In pt, this message translates to:
  /// **'Galeria'**
  String get petGallery;

  /// No description provided for @petPartners.
  ///
  /// In pt, this message translates to:
  /// **'Parceiros'**
  String get petPartners;

  /// No description provided for @petWeightControl.
  ///
  /// In pt, this message translates to:
  /// **'Controle de Peso Inteligente'**
  String get petWeightControl;

  /// No description provided for @petWeightAutoAnalysis.
  ///
  /// In pt, this message translates to:
  /// **'Análise automática baseada na raça e porte'**
  String get petWeightAutoAnalysis;

  /// No description provided for @petCurrentWeight.
  ///
  /// In pt, this message translates to:
  /// **'Peso Atual (kg)'**
  String get petCurrentWeight;

  /// No description provided for @petVaccinationHistory.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de Vacinas'**
  String get petVaccinationHistory;

  /// No description provided for @petLastV10.
  ///
  /// In pt, this message translates to:
  /// **'Última V10/V8'**
  String get petLastV10;

  /// No description provided for @petLastRabies.
  ///
  /// In pt, this message translates to:
  /// **'Última Antirrábica'**
  String get petLastRabies;

  /// No description provided for @petHygiene.
  ///
  /// In pt, this message translates to:
  /// **'🛁 Higiene'**
  String get petHygiene;

  /// No description provided for @petBathFrequency.
  ///
  /// In pt, this message translates to:
  /// **'Frequência de Banho'**
  String get petBathFrequency;

  /// No description provided for @petMedicalDocs.
  ///
  /// In pt, this message translates to:
  /// **'Outros Documentos Médicos'**
  String get petMedicalDocs;

  /// No description provided for @petPrescriptions.
  ///
  /// In pt, this message translates to:
  /// **'Receitas Veterinárias'**
  String get petPrescriptions;

  /// No description provided for @petVaccineCard.
  ///
  /// In pt, this message translates to:
  /// **'Carteira de Vacinação'**
  String get petVaccineCard;

  /// No description provided for @petWoundHistory.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de Análises de Feridas'**
  String get petWoundHistory;

  /// No description provided for @petNoWounds.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma análise de ferida registrada ainda.'**
  String get petNoWounds;

  /// No description provided for @petWoundsCount.
  ///
  /// In pt, this message translates to:
  /// **'{count} análise(s) registrada(s)'**
  String petWoundsCount(int count);

  /// No description provided for @petFoodAllergies.
  ///
  /// In pt, this message translates to:
  /// **'Alergias Alimentares'**
  String get petFoodAllergies;

  /// No description provided for @petFoodAllergiesDesc.
  ///
  /// In pt, this message translates to:
  /// **'Ingredientes que devem ser evitados'**
  String get petFoodAllergiesDesc;

  /// No description provided for @petAddAllergy.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar Alergia'**
  String get petAddAllergy;

  /// No description provided for @petFoodPreferences.
  ///
  /// In pt, this message translates to:
  /// **'Preferências Alimentares'**
  String get petFoodPreferences;

  /// No description provided for @petFoodPreferencesDesc.
  ///
  /// In pt, this message translates to:
  /// **'Alimentos que o pet mais gosta'**
  String get petFoodPreferencesDesc;

  /// No description provided for @petAddPreference.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar Preferência'**
  String get petAddPreference;

  /// No description provided for @petDietRecipes.
  ///
  /// In pt, this message translates to:
  /// **'Receitas e Dietas'**
  String get petDietRecipes;

  /// No description provided for @petDeleteTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir Pet?'**
  String get petDeleteTitle;

  /// No description provided for @petDeleteContent.
  ///
  /// In pt, this message translates to:
  /// **'Deseja remover {name} e todo o seu histórico? Esta ação não pode ser desfeita.'**
  String petDeleteContent(Object name);

  /// No description provided for @petDeleteConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Excluir Definitivamente'**
  String get petDeleteConfirm;

  /// No description provided for @petChangePhoto.
  ///
  /// In pt, this message translates to:
  /// **'Alterar Foto do Perfil'**
  String get petChangePhoto;

  /// No description provided for @petTakePhoto.
  ///
  /// In pt, this message translates to:
  /// **'Tirar Foto'**
  String get petTakePhoto;

  /// No description provided for @petChooseGallery.
  ///
  /// In pt, this message translates to:
  /// **'Escolher da Galeria'**
  String get petChooseGallery;

  /// No description provided for @petAddMedia.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar Mídia'**
  String get petAddMedia;

  /// No description provided for @petAttachDoc.
  ///
  /// In pt, this message translates to:
  /// **'Anexar Documento'**
  String get petAttachDoc;

  /// No description provided for @petCameraPhoto.
  ///
  /// In pt, this message translates to:
  /// **'Câmera (Foto)'**
  String get petCameraPhoto;

  /// No description provided for @petGalleryPhoto.
  ///
  /// In pt, this message translates to:
  /// **'Galeria (Foto)'**
  String get petGalleryPhoto;

  /// No description provided for @petCameraVideo.
  ///
  /// In pt, this message translates to:
  /// **'Câmera (Vídeo)'**
  String get petCameraVideo;

  /// No description provided for @petGalleryVideo.
  ///
  /// In pt, this message translates to:
  /// **'Galeria (Vídeo)'**
  String get petGalleryVideo;

  /// No description provided for @petEmptyGallery.
  ///
  /// In pt, this message translates to:
  /// **'A galeria está vazia'**
  String get petEmptyGallery;

  /// No description provided for @petEmptyGalleryDesc.
  ///
  /// In pt, this message translates to:
  /// **'Fotos e vídeos dos melhores momentos'**
  String get petEmptyGalleryDesc;

  /// No description provided for @petAddToGallery.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar à Galeria'**
  String get petAddToGallery;

  /// No description provided for @petDocAttached.
  ///
  /// In pt, this message translates to:
  /// **'Documento anexado!'**
  String get petDocAttached;

  /// No description provided for @petDeleteAttachment.
  ///
  /// In pt, this message translates to:
  /// **'Excluir Anexo?'**
  String get petDeleteAttachment;

  /// No description provided for @petDeleteAttachmentContent.
  ///
  /// In pt, this message translates to:
  /// **'Esta ação não pode ser desfeita.'**
  String get petDeleteAttachmentContent;

  /// No description provided for @petSaveSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Salvo!'**
  String get petSaveSuccess;

  /// No description provided for @petUndoChanges.
  ///
  /// In pt, this message translates to:
  /// **'Desfazer alterações'**
  String get petUndoChanges;

  /// No description provided for @petAllSaved.
  ///
  /// In pt, this message translates to:
  /// **'Tudo salvo'**
  String get petAllSaved;

  /// No description provided for @petBasicInfo.
  ///
  /// In pt, this message translates to:
  /// **'Informações Básicas'**
  String get petBasicInfo;

  /// No description provided for @petPartnersNoPartners.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum parceiro cadastrado. Adicione parceiros através do Hub de Parceiros na tela inicial.'**
  String get petPartnersNoPartners;

  /// No description provided for @petPartnersNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum parceiro encontrado nesta categoria.'**
  String get petPartnersNotFound;

  /// No description provided for @petPartnersLinked.
  ///
  /// In pt, this message translates to:
  /// **'Vinculado'**
  String get petPartnersLinked;

  /// No description provided for @petPartnersNoAddress.
  ///
  /// In pt, this message translates to:
  /// **'Endereço não informado'**
  String get petPartnersNoAddress;

  /// No description provided for @petPartnersPhoneHint.
  ///
  /// In pt, this message translates to:
  /// **'Digite o telefone'**
  String get petPartnersPhoneHint;

  /// No description provided for @petPartnersCall.
  ///
  /// In pt, this message translates to:
  /// **'Ligar'**
  String get petPartnersCall;

  /// No description provided for @petPartnersSchedule.
  ///
  /// In pt, this message translates to:
  /// **'Agenda'**
  String get petPartnersSchedule;

  /// No description provided for @petPartnersObs.
  ///
  /// In pt, this message translates to:
  /// **'Prac (Rede de Apoio)'**
  String get petPartnersObs;

  /// No description provided for @agendaToday.
  ///
  /// In pt, this message translates to:
  /// **'Hoje'**
  String get agendaToday;

  /// No description provided for @agendaYesterday.
  ///
  /// In pt, this message translates to:
  /// **'Ontem'**
  String get agendaYesterday;

  /// No description provided for @agendaNewEvent.
  ///
  /// In pt, this message translates to:
  /// **'Novo Evento'**
  String get agendaNewEvent;

  /// No description provided for @agendaTitle.
  ///
  /// In pt, this message translates to:
  /// **'Agenda'**
  String get agendaTitle;

  /// No description provided for @agendaDate.
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get agendaDate;

  /// No description provided for @agendaTime.
  ///
  /// In pt, this message translates to:
  /// **'Hora'**
  String get agendaTime;

  /// No description provided for @agendaObservations.
  ///
  /// In pt, this message translates to:
  /// **'Observações'**
  String get agendaObservations;

  /// No description provided for @agendaAdd.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar Evento'**
  String get agendaAdd;

  /// No description provided for @agendaTitleHint.
  ///
  /// In pt, this message translates to:
  /// **'Título (ex: Consulta, Banho)'**
  String get agendaTitleHint;

  /// No description provided for @agendaEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum evento registrado.\nAdicione agendamentos, vacinas ou notas.'**
  String get agendaEmpty;

  /// No description provided for @petDiagnosis.
  ///
  /// In pt, this message translates to:
  /// **'Diagnóstico'**
  String get petDiagnosis;

  /// No description provided for @petSeverity.
  ///
  /// In pt, this message translates to:
  /// **'Gravidade'**
  String get petSeverity;

  /// No description provided for @petRecommendations.
  ///
  /// In pt, this message translates to:
  /// **'Recomendações'**
  String get petRecommendations;

  /// No description provided for @petBiometricAnalysis.
  ///
  /// In pt, this message translates to:
  /// **'Análise Biométrica'**
  String get petBiometricAnalysis;

  /// No description provided for @petLineage.
  ///
  /// In pt, this message translates to:
  /// **'Linhagem'**
  String get petLineage;

  /// No description provided for @petSize.
  ///
  /// In pt, this message translates to:
  /// **'Porte'**
  String get petSize;

  /// No description provided for @petLongevity.
  ///
  /// In pt, this message translates to:
  /// **'Longevidade'**
  String get petLongevity;

  /// No description provided for @petGrowthCurve.
  ///
  /// In pt, this message translates to:
  /// **'Curva de Crescimento Estimada'**
  String get petGrowthCurve;

  /// No description provided for @petMonth3.
  ///
  /// In pt, this message translates to:
  /// **'3 Meses'**
  String get petMonth3;

  /// No description provided for @petMonth6.
  ///
  /// In pt, this message translates to:
  /// **'6 Meses'**
  String get petMonth6;

  /// No description provided for @petMonth12.
  ///
  /// In pt, this message translates to:
  /// **'12 Meses'**
  String get petMonth12;

  /// No description provided for @petAdult.
  ///
  /// In pt, this message translates to:
  /// **'Adulto'**
  String get petAdult;

  /// No description provided for @petEnergy.
  ///
  /// In pt, this message translates to:
  /// **'Energia'**
  String get petEnergy;

  /// No description provided for @petIntelligence.
  ///
  /// In pt, this message translates to:
  /// **'Inteligência'**
  String get petIntelligence;

  /// No description provided for @petSociability.
  ///
  /// In pt, this message translates to:
  /// **'Sociabilidade'**
  String get petSociability;

  /// No description provided for @petDrive.
  ///
  /// In pt, this message translates to:
  /// **'Drive Ancestral'**
  String get petDrive;

  /// No description provided for @petSuggestedPlan.
  ///
  /// In pt, this message translates to:
  /// **'Plano Alimentar Sugerido'**
  String get petSuggestedPlan;

  /// No description provided for @petDailyCaloricGoals.
  ///
  /// In pt, this message translates to:
  /// **'Metas Calóricas Diárias'**
  String get petDailyCaloricGoals;

  /// No description provided for @petPuppy.
  ///
  /// In pt, this message translates to:
  /// **'Filhote'**
  String get petPuppy;

  /// No description provided for @petSenior.
  ///
  /// In pt, this message translates to:
  /// **'Sênior'**
  String get petSenior;

  /// No description provided for @petSecuritySupplements.
  ///
  /// In pt, this message translates to:
  /// **'Segurança & Suplementos'**
  String get petSecuritySupplements;

  /// No description provided for @petTargetNutrients.
  ///
  /// In pt, this message translates to:
  /// **'Nutrientes Alvo'**
  String get petTargetNutrients;

  /// No description provided for @petSupplementation.
  ///
  /// In pt, this message translates to:
  /// **'Suplementação'**
  String get petSupplementation;

  /// No description provided for @petObesityTendency.
  ///
  /// In pt, this message translates to:
  /// **'Tendência Obesidade'**
  String get petObesityTendency;

  /// No description provided for @petCoatGrooming.
  ///
  /// In pt, this message translates to:
  /// **'Pelagem & Tosa'**
  String get petCoatGrooming;

  /// No description provided for @petType.
  ///
  /// In pt, this message translates to:
  /// **'Tipo'**
  String get petType;

  /// No description provided for @petFrequency.
  ///
  /// In pt, this message translates to:
  /// **'Frequência'**
  String get petFrequency;

  /// No description provided for @petPreventiveHealth.
  ///
  /// In pt, this message translates to:
  /// **'Saúde Preventiva'**
  String get petPreventiveHealth;

  /// No description provided for @petPredisposition.
  ///
  /// In pt, this message translates to:
  /// **'Predisposição'**
  String get petPredisposition;

  /// No description provided for @petCheckup.
  ///
  /// In pt, this message translates to:
  /// **'Checkup'**
  String get petCheckup;

  /// No description provided for @petTrainingEnvironment.
  ///
  /// In pt, this message translates to:
  /// **'Treino & Ambiente'**
  String get petTrainingEnvironment;

  /// No description provided for @petTraining.
  ///
  /// In pt, this message translates to:
  /// **'Treino'**
  String get petTraining;

  /// No description provided for @petApartmentRef.
  ///
  /// In pt, this message translates to:
  /// **'Apartamento'**
  String get petApartmentRef;

  /// No description provided for @petExclusiveInsight.
  ///
  /// In pt, this message translates to:
  /// **'Insight Exclusivo'**
  String get petExclusiveInsight;

  /// No description provided for @petRaceAnalysis.
  ///
  /// In pt, this message translates to:
  /// **'Análise da Raça'**
  String get petRaceAnalysis;

  /// No description provided for @petReliability.
  ///
  /// In pt, this message translates to:
  /// **'Confiabilidade'**
  String get petReliability;

  /// No description provided for @petReliabilityLow.
  ///
  /// In pt, this message translates to:
  /// **'Baixa'**
  String get petReliabilityLow;

  /// No description provided for @petReliabilityMedium.
  ///
  /// In pt, this message translates to:
  /// **'Média'**
  String get petReliabilityMedium;

  /// No description provided for @petReliabilityHigh.
  ///
  /// In pt, this message translates to:
  /// **'Alta'**
  String get petReliabilityHigh;

  /// No description provided for @petNotIdentified.
  ///
  /// In pt, this message translates to:
  /// **'Não identificado'**
  String get petNotIdentified;

  /// No description provided for @petNotEstimated.
  ///
  /// In pt, this message translates to:
  /// **'Não estimada'**
  String get petNotEstimated;

  /// No description provided for @petVariable.
  ///
  /// In pt, this message translates to:
  /// **'Variável'**
  String get petVariable;

  /// No description provided for @petNeutered.
  ///
  /// In pt, this message translates to:
  /// **'Castrado'**
  String get petNeutered;

  /// No description provided for @petIntact.
  ///
  /// In pt, this message translates to:
  /// **'Intacto'**
  String get petIntact;

  /// No description provided for @petActivityModerate.
  ///
  /// In pt, this message translates to:
  /// **'Moderado'**
  String get petActivityModerate;

  /// No description provided for @petBathBiweekly.
  ///
  /// In pt, this message translates to:
  /// **'Quinzenal'**
  String get petBathBiweekly;

  /// No description provided for @petGenerateWeeklyMenu.
  ///
  /// In pt, this message translates to:
  /// **'Gerar Cardápio Semanal'**
  String get petGenerateWeeklyMenu;

  /// No description provided for @petNoDocumentsAttached.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum documento anexado'**
  String get petNoDocumentsAttached;

  /// No description provided for @petSeeFull.
  ///
  /// In pt, this message translates to:
  /// **'Ver Completo'**
  String get petSeeFull;

  /// No description provided for @petObservationsHistory.
  ///
  /// In pt, this message translates to:
  /// **'Observações e Histórico'**
  String get petObservationsHistory;

  /// No description provided for @petRegisterObservations.
  ///
  /// In pt, this message translates to:
  /// **'Registre observações importantes aqui...'**
  String get petRegisterObservations;

  /// No description provided for @petNoObservations.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma observação registrada ainda.'**
  String get petNoObservations;

  /// No description provided for @commonAddText.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar Texto'**
  String get commonAddText;

  /// No description provided for @commonVoice.
  ///
  /// In pt, this message translates to:
  /// **'Voz'**
  String get commonVoice;

  /// No description provided for @commonListening.
  ///
  /// In pt, this message translates to:
  /// **'Ouvindo...'**
  String get commonListening;

  /// No description provided for @commonLoadMore.
  ///
  /// In pt, this message translates to:
  /// **'Carregar antigas ({count} restantes)'**
  String commonLoadMore(Object count);

  /// No description provided for @petWeeklyPlanTitle.
  ///
  /// In pt, this message translates to:
  /// **'Plano Alimentar Semanal'**
  String get petWeeklyPlanTitle;

  /// No description provided for @petNutritionPillarsDesc.
  ///
  /// In pt, this message translates to:
  /// **'Cada refeição foca nos 5 Pilares (Protéina, Gordura, Fibras, Minerais e Hidratação)'**
  String get petNutritionPillarsDesc;

  /// No description provided for @backButton.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get backButton;

  /// No description provided for @generateReportButton.
  ///
  /// In pt, this message translates to:
  /// **'Gerar Relatório'**
  String get generateReportButton;

  /// No description provided for @reportDetailLevelLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nível de Detalhe'**
  String get reportDetailLevelLabel;

  /// No description provided for @reportHubTitle.
  ///
  /// In pt, this message translates to:
  /// **'Relatório de Parceiros'**
  String get reportHubTitle;

  /// No description provided for @noPartnersForFilters.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum parceiro encontrado neste filtro'**
  String get noPartnersForFilters;

  /// No description provided for @reportSummary.
  ///
  /// In pt, this message translates to:
  /// **'Resumo'**
  String get reportSummary;

  /// No description provided for @reportDetailed.
  ///
  /// In pt, this message translates to:
  /// **'Detalhado'**
  String get reportDetailed;

  /// No description provided for @reportDescription.
  ///
  /// In pt, this message translates to:
  /// **'Relatório PDF completo da rede de parceiros.'**
  String get reportDescription;

  /// No description provided for @exportPdfTitle.
  ///
  /// In pt, this message translates to:
  /// **'Exportar PDF'**
  String get exportPdfTitle;

  /// No description provided for @partnerTypeLabel.
  ///
  /// In pt, this message translates to:
  /// **'Categoria'**
  String get partnerTypeLabel;

  /// No description provided for @petActivityLevel.
  ///
  /// In pt, this message translates to:
  /// **'Nível de Atividade'**
  String get petActivityLevel;

  /// No description provided for @petReproductiveStatus.
  ///
  /// In pt, this message translates to:
  /// **'Status Reprodutivo'**
  String get petReproductiveStatus;

  /// No description provided for @errorBadPhoto.
  ///
  /// In pt, this message translates to:
  /// **'Ops! A foto não ficou clara o suficiente. Tente um novo ângulo!'**
  String get errorBadPhoto;

  /// No description provided for @errorAiTimeout.
  ///
  /// In pt, this message translates to:
  /// **'Nossa IA está analisando com cuidado... só mais um momento!'**
  String get errorAiTimeout;

  /// No description provided for @aiCalculatingMetrics.
  ///
  /// In pt, this message translates to:
  /// **'Gerando cardápio da semana...'**
  String get aiCalculatingMetrics;

  /// No description provided for @examBlood.
  ///
  /// In pt, this message translates to:
  /// **'Exame de Sangue'**
  String get examBlood;

  /// No description provided for @examUrine.
  ///
  /// In pt, this message translates to:
  /// **'Exame de Urina'**
  String get examUrine;

  /// No description provided for @examFeces.
  ///
  /// In pt, this message translates to:
  /// **'Exame de Fezes'**
  String get examFeces;

  /// No description provided for @examOther.
  ///
  /// In pt, this message translates to:
  /// **'Outros Exames'**
  String get examOther;

  /// No description provided for @petSeverityLow.
  ///
  /// In pt, this message translates to:
  /// **'Baixa'**
  String get petSeverityLow;

  /// No description provided for @petSeverityMedium.
  ///
  /// In pt, this message translates to:
  /// **'Média'**
  String get petSeverityMedium;

  /// No description provided for @petSeverityHigh.
  ///
  /// In pt, this message translates to:
  /// **'Alta'**
  String get petSeverityHigh;

  /// No description provided for @petDiagnosisDefault.
  ///
  /// In pt, this message translates to:
  /// **'Sem diagnóstico'**
  String get petDiagnosisDefault;

  /// No description provided for @examDeleteTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir Exame'**
  String get examDeleteTitle;

  /// No description provided for @examDeleteContent.
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza que deseja excluir este exame? Esta ação não pode ser desfeita.'**
  String get examDeleteContent;

  /// No description provided for @petLifeExpectancy.
  ///
  /// In pt, this message translates to:
  /// **'Expectativa de Vida'**
  String get petLifeExpectancy;

  /// No description provided for @petTypicalWeight.
  ///
  /// In pt, this message translates to:
  /// **'Peso Típico'**
  String get petTypicalWeight;

  /// No description provided for @petTemperament.
  ///
  /// In pt, this message translates to:
  /// **'Temperamento'**
  String get petTemperament;

  /// No description provided for @petOrigin.
  ///
  /// In pt, this message translates to:
  /// **'Origem & História'**
  String get petOrigin;

  /// No description provided for @petCuriosities.
  ///
  /// In pt, this message translates to:
  /// **'Curiosidades'**
  String get petCuriosities;

  /// No description provided for @errorAddingExam.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao adicionar exame: {error}'**
  String errorAddingExam(Object error);

  /// No description provided for @ocrSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Texto extraído com sucesso! Clique em \'Explicar Exame\' para análise.'**
  String get ocrSuccess;

  /// No description provided for @errorGeneratingExplanation.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao gerar explicação: {error}'**
  String errorGeneratingExplanation(Object error);

  /// No description provided for @petEstimatedByBreed.
  ///
  /// In pt, this message translates to:
  /// **'Estimado pela raça'**
  String get petEstimatedByBreed;

  /// No description provided for @menuTitle.
  ///
  /// In pt, this message translates to:
  /// **'Cardápio de {petName}'**
  String menuTitle(String petName);

  /// No description provided for @menuLastWeek.
  ///
  /// In pt, this message translates to:
  /// **'Semana Passada'**
  String get menuLastWeek;

  /// No description provided for @menuCurrentWeek.
  ///
  /// In pt, this message translates to:
  /// **'Semana Atual'**
  String get menuCurrentWeek;

  /// No description provided for @menuNextWeek.
  ///
  /// In pt, this message translates to:
  /// **'Próxima Semana'**
  String get menuNextWeek;

  /// No description provided for @menuNoHistory.
  ///
  /// In pt, this message translates to:
  /// **'Sem histórico disponível.'**
  String get menuNoHistory;

  /// No description provided for @menuNoCurrent.
  ///
  /// In pt, this message translates to:
  /// **'Sem cardápio para esta semana.'**
  String get menuNoCurrent;

  /// No description provided for @menuNoFuture.
  ///
  /// In pt, this message translates to:
  /// **'Sem cardápio futuro planejado.'**
  String get menuNoFuture;

  /// No description provided for @menuGenerateEdit.
  ///
  /// In pt, this message translates to:
  /// **'Gerar/Editar Cardápio'**
  String get menuGenerateEdit;

  /// No description provided for @menuMainNutrients.
  ///
  /// In pt, this message translates to:
  /// **'Nutrientes Principais'**
  String get menuMainNutrients;

  /// No description provided for @menuNoDetails.
  ///
  /// In pt, this message translates to:
  /// **'Sem detalhes disponíveis.'**
  String get menuNoDetails;

  /// No description provided for @menuExportTitle.
  ///
  /// In pt, this message translates to:
  /// **'Exportar Cardápio'**
  String get menuExportTitle;

  /// No description provided for @menuExportSelectPeriod.
  ///
  /// In pt, this message translates to:
  /// **'Selecione os períodos'**
  String get menuExportSelectPeriod;

  /// No description provided for @menuExportReport.
  ///
  /// In pt, this message translates to:
  /// **'Exportar Relatório'**
  String get menuExportReport;

  /// No description provided for @menuNoPeriodSelected.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum período selecionado.'**
  String get menuNoPeriodSelected;

  /// No description provided for @menuPeriodCustom.
  ///
  /// In pt, this message translates to:
  /// **'Personalizado'**
  String get menuPeriodCustom;

  /// No description provided for @menuPeriodFull.
  ///
  /// In pt, this message translates to:
  /// **'Plano Completo'**
  String get menuPeriodFull;

  /// No description provided for @petChangesDiscarded.
  ///
  /// In pt, this message translates to:
  /// **'Alterações desfeitas.'**
  String get petChangesDiscarded;

  /// No description provided for @agendaNoEventsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum evento registrado.\nAdicione agendamentos, vacinas ou notas.'**
  String get agendaNoEventsTitle;

  /// No description provided for @errorOpeningApp.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir o aplicativo'**
  String get errorOpeningApp;

  /// No description provided for @pdfFieldLabel.
  ///
  /// In pt, this message translates to:
  /// **'Campo'**
  String get pdfFieldLabel;

  /// No description provided for @pdfFieldValue.
  ///
  /// In pt, this message translates to:
  /// **'Informação'**
  String get pdfFieldValue;

  /// No description provided for @pdfFieldName.
  ///
  /// In pt, this message translates to:
  /// **'Nome Completo'**
  String get pdfFieldName;

  /// No description provided for @pdfFieldBreed.
  ///
  /// In pt, this message translates to:
  /// **'Raça'**
  String get pdfFieldBreed;

  /// No description provided for @pdfFieldAge.
  ///
  /// In pt, this message translates to:
  /// **'Idade Exata'**
  String get pdfFieldAge;

  /// No description provided for @pdfFieldSex.
  ///
  /// In pt, this message translates to:
  /// **'Sexo'**
  String get pdfFieldSex;

  /// No description provided for @pdfFieldMicrochip.
  ///
  /// In pt, this message translates to:
  /// **'Microchip'**
  String get pdfFieldMicrochip;

  /// No description provided for @pdfFieldCurrentWeight.
  ///
  /// In pt, this message translates to:
  /// **'Peso Atual'**
  String get pdfFieldCurrentWeight;

  /// No description provided for @pdfFieldIdealWeight.
  ///
  /// In pt, this message translates to:
  /// **'Peso Ideal'**
  String get pdfFieldIdealWeight;

  /// No description provided for @pdfFieldReproductiveStatus.
  ///
  /// In pt, this message translates to:
  /// **'Status Reprodutivo'**
  String get pdfFieldReproductiveStatus;

  /// No description provided for @pdfFieldActivityLevel.
  ///
  /// In pt, this message translates to:
  /// **'Nível de Atividade'**
  String get pdfFieldActivityLevel;

  /// No description provided for @pdfFieldBathFrequency.
  ///
  /// In pt, this message translates to:
  /// **'Frequência de Banho'**
  String get pdfFieldBathFrequency;

  /// No description provided for @pdfPreferenciasAlimentares.
  ///
  /// In pt, this message translates to:
  /// **'Preferências Alimentares'**
  String get pdfPreferenciasAlimentares;

  /// No description provided for @pdfHistClinico.
  ///
  /// In pt, this message translates to:
  /// **'Histórico Clínico (Vacinas, Meds, Procedimentos)'**
  String get pdfHistClinico;

  /// No description provided for @pdfExamesLab.
  ///
  /// In pt, this message translates to:
  /// **'Exames Laboratoriais'**
  String get pdfExamesLab;

  /// No description provided for @pdfAnaliseFeridas.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de Análises de Feridas'**
  String get pdfAnaliseFeridas;

  /// No description provided for @pdfCardapioDetalhado.
  ///
  /// In pt, this message translates to:
  /// **'Cardápio Semanal Detalhado'**
  String get pdfCardapioDetalhado;

  /// No description provided for @pdfRefeicao.
  ///
  /// In pt, this message translates to:
  /// **'Refeição'**
  String get pdfRefeicao;

  /// No description provided for @pdfKcal.
  ///
  /// In pt, this message translates to:
  /// **'kcal'**
  String get pdfKcal;

  /// No description provided for @pdfSemDescricao.
  ///
  /// In pt, this message translates to:
  /// **'Sem descrição'**
  String get pdfSemDescricao;

  /// No description provided for @pdfPesoStatusUnder.
  ///
  /// In pt, this message translates to:
  /// **'Abaixo do ideal'**
  String get pdfPesoStatusUnder;

  /// No description provided for @pdfPesoStatusOver.
  ///
  /// In pt, this message translates to:
  /// **'Acima do ideal'**
  String get pdfPesoStatusOver;

  /// No description provided for @pdfPesoStatusIdeal.
  ///
  /// In pt, this message translates to:
  /// **'Ideal'**
  String get pdfPesoStatusIdeal;

  /// No description provided for @pdfPesoStatusNormal.
  ///
  /// In pt, this message translates to:
  /// **'Peso normal'**
  String get pdfPesoStatusNormal;

  /// No description provided for @pdfPesoStatusMeta.
  ///
  /// In pt, this message translates to:
  /// **'Meta'**
  String get pdfPesoStatusMeta;

  /// No description provided for @pdfVacinaV10.
  ///
  /// In pt, this message translates to:
  /// **'V10/V8 (Polivalente)'**
  String get pdfVacinaV10;

  /// No description provided for @pdfVacinaAntirrabica.
  ///
  /// In pt, this message translates to:
  /// **'Antirrábica'**
  String get pdfVacinaAntirrabica;

  /// No description provided for @pdfVacinaNaoRegistrada.
  ///
  /// In pt, this message translates to:
  /// **'Não registrado'**
  String get pdfVacinaNaoRegistrada;

  /// No description provided for @pdfAlergiasAviso.
  ///
  /// In pt, this message translates to:
  /// **'⚠️ ATENÇÃO: {allergies}'**
  String pdfAlergiasAviso(Object allergies);

  /// No description provided for @pdfAlergiasNenhuma.
  ///
  /// In pt, this message translates to:
  /// **'✓ Nenhuma alergia conhecida registrada'**
  String get pdfAlergiasNenhuma;

  /// No description provided for @pdfExtractedText.
  ///
  /// In pt, this message translates to:
  /// **'Texto extraído: {text}'**
  String pdfExtractedText(Object text);

  /// No description provided for @pdfAiAnalysis.
  ///
  /// In pt, this message translates to:
  /// **'Análise IA: {analysis}'**
  String pdfAiAnalysis(Object analysis);

  /// No description provided for @pdfDiagnosis.
  ///
  /// In pt, this message translates to:
  /// **'Diagnóstico: {diagnosis}'**
  String pdfDiagnosis(Object diagnosis);

  /// No description provided for @pdfRecommendations.
  ///
  /// In pt, this message translates to:
  /// **'Recomendações'**
  String get pdfRecommendations;

  /// No description provided for @pdfAgendaTitle.
  ///
  /// In pt, this message translates to:
  /// **'Check de Agenda'**
  String get pdfAgendaTitle;

  /// No description provided for @pdfObservationsTitle.
  ///
  /// In pt, this message translates to:
  /// **'HISTÓRICO DE OBSERVAÇÕES:'**
  String get pdfObservationsTitle;

  /// No description provided for @pdfMetric.
  ///
  /// In pt, this message translates to:
  /// **'Métrica'**
  String get pdfMetric;

  /// No description provided for @pdfStatus.
  ///
  /// In pt, this message translates to:
  /// **'Status'**
  String get pdfStatus;

  /// No description provided for @pdfWeightControl.
  ///
  /// In pt, this message translates to:
  /// **'Controle de Peso'**
  String get pdfWeightControl;

  /// No description provided for @pdfWeightHistory.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de Pesagens'**
  String get pdfWeightHistory;

  /// No description provided for @pdfType.
  ///
  /// In pt, this message translates to:
  /// **'Tipo'**
  String get pdfType;

  /// No description provided for @pdfDescription.
  ///
  /// In pt, this message translates to:
  /// **'Descrição'**
  String get pdfDescription;

  /// No description provided for @pdfCompleted.
  ///
  /// In pt, this message translates to:
  /// **'Realizado'**
  String get pdfCompleted;

  /// No description provided for @pdfPending.
  ///
  /// In pt, this message translates to:
  /// **'Pendente'**
  String get pdfPending;

  /// No description provided for @pdfEstimatedNote.
  ///
  /// In pt, this message translates to:
  /// **'* Estimado/Calculado'**
  String get pdfEstimatedNote;

  /// No description provided for @pdfNoPlan.
  ///
  /// In pt, this message translates to:
  /// **'Sem plano alimentar registrado.'**
  String get pdfNoPlan;

  /// No description provided for @pdfAgendaReport.
  ///
  /// In pt, this message translates to:
  /// **'Relatório de Agenda Pet'**
  String get pdfAgendaReport;

  /// No description provided for @pdfTotalEvents.
  ///
  /// In pt, this message translates to:
  /// **'Total de Eventos'**
  String get pdfTotalEvents;

  /// No description provided for @pdfCompletedEvents.
  ///
  /// In pt, this message translates to:
  /// **'Concluídos'**
  String get pdfCompletedEvents;

  /// No description provided for @pdfPendingEvents.
  ///
  /// In pt, this message translates to:
  /// **'Pendentes'**
  String get pdfPendingEvents;

  /// No description provided for @pdfFieldTime.
  ///
  /// In pt, this message translates to:
  /// **'Hora'**
  String get pdfFieldTime;

  /// No description provided for @pdfFieldEvent.
  ///
  /// In pt, this message translates to:
  /// **'Evento'**
  String get pdfFieldEvent;

  /// No description provided for @pdfFieldPet.
  ///
  /// In pt, this message translates to:
  /// **'Pet'**
  String get pdfFieldPet;

  /// No description provided for @pdfFieldCategory.
  ///
  /// In pt, this message translates to:
  /// **'Categoria'**
  String get pdfFieldCategory;

  /// No description provided for @pdfPartnersGuide.
  ///
  /// In pt, this message translates to:
  /// **'Guia de Parceiros'**
  String get pdfPartnersGuide;

  /// No description provided for @pdfRegion.
  ///
  /// In pt, this message translates to:
  /// **'Região'**
  String get pdfRegion;

  /// No description provided for @pdfTotalFound.
  ///
  /// In pt, this message translates to:
  /// **'Total Encontrado'**
  String get pdfTotalFound;

  /// No description provided for @pdfEstablishment.
  ///
  /// In pt, this message translates to:
  /// **'Estabelecimento'**
  String get pdfEstablishment;

  /// No description provided for @pdfPhone.
  ///
  /// In pt, this message translates to:
  /// **'Telefone'**
  String get pdfPhone;

  /// No description provided for @pdfRating.
  ///
  /// In pt, this message translates to:
  /// **'Avaliação'**
  String get pdfRating;

  /// No description provided for @pdfStars.
  ///
  /// In pt, this message translates to:
  /// **'Estrelas'**
  String get pdfStars;

  /// No description provided for @pdfAgendaToday.
  ///
  /// In pt, this message translates to:
  /// **'Hoje'**
  String get pdfAgendaToday;

  /// No description provided for @pdfObservations.
  ///
  /// In pt, this message translates to:
  /// **'Observações'**
  String get pdfObservations;

  /// No description provided for @pdfSummaryReport.
  ///
  /// In pt, this message translates to:
  /// **'Relatório Resumido - Tabela Omitida'**
  String get pdfSummaryReport;

  /// No description provided for @pdfNoImages.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma imagem encontrada na galeria.'**
  String get pdfNoImages;

  /// No description provided for @pdfAttachedDocs.
  ///
  /// In pt, this message translates to:
  /// **'Documentos Anexados (PDFs/Arquivos):'**
  String get pdfAttachedDocs;

  /// No description provided for @pdfLinkedPartners.
  ///
  /// In pt, this message translates to:
  /// **'Parceiros Vinculados:'**
  String get pdfLinkedPartners;

  /// No description provided for @pdfPartnerLoadError.
  ///
  /// In pt, this message translates to:
  /// **'⚠️ {count} parceiro(s) vinculado(s), mas não foi possível carregar os detalhes.'**
  String pdfPartnerLoadError(Object count);

  /// No description provided for @pdfServiceHistory.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de Atendimentos:'**
  String get pdfServiceHistory;

  /// No description provided for @pdfNoPartners.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum parceiro vinculado a este perfil.'**
  String get pdfNoPartners;

  /// No description provided for @pdfAgendaEvents.
  ///
  /// In pt, this message translates to:
  /// **'Agenda e Eventos'**
  String get pdfAgendaEvents;

  /// No description provided for @pdfHistoryUpcoming.
  ///
  /// In pt, this message translates to:
  /// **'Histórico e Próximos Compromissos'**
  String get pdfHistoryUpcoming;

  /// No description provided for @pdfUpcomingEvents.
  ///
  /// In pt, this message translates to:
  /// **'Próximos Eventos'**
  String get pdfUpcomingEvents;

  /// No description provided for @pdfRecentHistory.
  ///
  /// In pt, this message translates to:
  /// **'Histórico Recente'**
  String get pdfRecentHistory;

  /// No description provided for @partnersSelectTitle.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar Parceiro'**
  String get partnersSelectTitle;

  /// No description provided for @partnersExportPdf.
  ///
  /// In pt, this message translates to:
  /// **'Exportar PDF'**
  String get partnersExportPdf;

  /// No description provided for @partnersCategory.
  ///
  /// In pt, this message translates to:
  /// **'Categoria'**
  String get partnersCategory;

  /// No description provided for @partnersDetailLevel.
  ///
  /// In pt, this message translates to:
  /// **'Nível de Detalhe'**
  String get partnersDetailLevel;

  /// No description provided for @partnersSummary.
  ///
  /// In pt, this message translates to:
  /// **'Resumo'**
  String get partnersSummary;

  /// No description provided for @partnersDetailed.
  ///
  /// In pt, this message translates to:
  /// **'Detalhado'**
  String get partnersDetailed;

  /// No description provided for @partnersExportDisclaimer.
  ///
  /// In pt, this message translates to:
  /// **'Relatório PDF completo da rede de parceiros.'**
  String get partnersExportDisclaimer;

  /// No description provided for @partnersGenerateReport.
  ///
  /// In pt, this message translates to:
  /// **'Gerar Relatório'**
  String get partnersGenerateReport;

  /// No description provided for @partnersBack.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get partnersBack;

  /// No description provided for @partnersRegister.
  ///
  /// In pt, this message translates to:
  /// **'Cadastrar'**
  String get partnersRegister;

  /// No description provided for @partnersNoneFound.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum parceiro encontrado na base.'**
  String get partnersNoneFound;

  /// No description provided for @partnersNoneInCategory.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum parceiro na categoria {category}.'**
  String partnersNoneInCategory(Object category);

  /// No description provided for @partnersRadarHint.
  ///
  /// In pt, this message translates to:
  /// **'Use o botão \'Radar\' para buscar locais reais.'**
  String get partnersRadarHint;

  /// No description provided for @partnersLocationDenied.
  ///
  /// In pt, this message translates to:
  /// **'Permissão de localização negada.'**
  String get partnersLocationDenied;

  /// No description provided for @partnersLocationPermanentlyDenied.
  ///
  /// In pt, this message translates to:
  /// **'Permissão negada permanentemente nas configurações.'**
  String get partnersLocationPermanentlyDenied;

  /// No description provided for @partnersLocationError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível obter sua localização atual.'**
  String get partnersLocationError;

  /// No description provided for @partnersRadarDetecting.
  ///
  /// In pt, this message translates to:
  /// **'Detectamos estabelecimentos reais na sua região'**
  String get partnersRadarDetecting;

  /// No description provided for @partnersRadarTracking.
  ///
  /// In pt, this message translates to:
  /// **'Rastreando estabelecimentos via GPS...'**
  String get partnersRadarTracking;

  /// No description provided for @partnersRadarNoResults.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum local nesta categoria.'**
  String get partnersRadarNoResults;

  /// No description provided for @menuDietType.
  ///
  /// In pt, this message translates to:
  /// **'Tipo de Dieta'**
  String get menuDietType;

  /// No description provided for @pdfError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao gerar PDF:'**
  String get pdfError;

  /// No description provided for @pdfFieldPhone.
  ///
  /// In pt, this message translates to:
  /// **'Telefone'**
  String get pdfFieldPhone;

  /// No description provided for @pdfFieldEmail.
  ///
  /// In pt, this message translates to:
  /// **'E-mail'**
  String get pdfFieldEmail;

  /// No description provided for @pdfFieldAddress.
  ///
  /// In pt, this message translates to:
  /// **'Endereço'**
  String get pdfFieldAddress;

  /// No description provided for @pdfFieldDetails.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes e Especialidades'**
  String get pdfFieldDetails;

  /// No description provided for @partnerTeamMembers.
  ///
  /// In pt, this message translates to:
  /// **'Integrantes da Equipe/Corpo Clínico'**
  String get partnerTeamMembers;

  /// No description provided for @partnerNotesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Notas e Observações'**
  String get partnerNotesTitle;

  /// No description provided for @partnerNotesEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma anotação ainda.\nEscreva ou grave lembretes sobre este parceiro.'**
  String get partnerNotesEmpty;

  /// No description provided for @petWoundDeleteTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir Análise'**
  String get petWoundDeleteTitle;

  /// No description provided for @petWoundDeleteConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza que deseja excluir esta análise de ferida? Esta ação não pode ser desfeita.'**
  String get petWoundDeleteConfirm;

  /// No description provided for @petWoundDeleteSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Análise de ferida excluída com sucesso'**
  String get petWoundDeleteSuccess;

  /// No description provided for @petWoundDeleteError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao excluir análise:'**
  String get petWoundDeleteError;

  /// No description provided for @selectRegime.
  ///
  /// In pt, this message translates to:
  /// **'Selecione ao menos um regime.'**
  String get selectRegime;

  /// No description provided for @selectDatesError.
  ///
  /// In pt, this message translates to:
  /// **'Selecione as datas.'**
  String get selectDatesError;

  /// No description provided for @menuPlannedSuccess.
  ///
  /// In pt, this message translates to:
  /// **'✅ Cardápio Inteligente Planejado!'**
  String get menuPlannedSuccess;

  /// No description provided for @goalWeightMaintenance.
  ///
  /// In pt, this message translates to:
  /// **'Manutenção de Peso'**
  String get goalWeightMaintenance;

  /// No description provided for @goalWeightLoss.
  ///
  /// In pt, this message translates to:
  /// **'Perda de Peso'**
  String get goalWeightLoss;

  /// No description provided for @goalMuscleGain.
  ///
  /// In pt, this message translates to:
  /// **'Ganho de Massa'**
  String get goalMuscleGain;

  /// No description provided for @goalRecovery.
  ///
  /// In pt, this message translates to:
  /// **'Recuperação/Convalescença'**
  String get goalRecovery;

  /// No description provided for @menuProfileHeader.
  ///
  /// In pt, this message translates to:
  /// **'⚠️ PERFIL ESPECÍFICO DO PET:'**
  String get menuProfileHeader;

  /// No description provided for @menuAllergiesForbidden.
  ///
  /// In pt, this message translates to:
  /// **'- ALERGIAS (PROIBIDO)'**
  String get menuAllergiesForbidden;

  /// No description provided for @menuPreferences.
  ///
  /// In pt, this message translates to:
  /// **'- PREFERÊNCIAS'**
  String get menuPreferences;

  /// No description provided for @menuRecentMeals.
  ///
  /// In pt, this message translates to:
  /// **'- ÚLTIMAS REFEIÇÕES (PARA VARIAÇÃO)'**
  String get menuRecentMeals;

  /// No description provided for @petSizeSmall.
  ///
  /// In pt, this message translates to:
  /// **'Pequeno'**
  String get petSizeSmall;

  /// No description provided for @petSizeMedium.
  ///
  /// In pt, this message translates to:
  /// **'Médio'**
  String get petSizeMedium;

  /// No description provided for @petSizeLarge.
  ///
  /// In pt, this message translates to:
  /// **'Grande'**
  String get petSizeLarge;

  /// No description provided for @petSizeGiant.
  ///
  /// In pt, this message translates to:
  /// **'Gigante'**
  String get petSizeGiant;

  /// No description provided for @petCoatShort.
  ///
  /// In pt, this message translates to:
  /// **'Pelo Curto'**
  String get petCoatShort;

  /// No description provided for @petCoatLong.
  ///
  /// In pt, this message translates to:
  /// **'Pelo Longo'**
  String get petCoatLong;

  /// No description provided for @petCoatDouble.
  ///
  /// In pt, this message translates to:
  /// **'Pelo Duplo'**
  String get petCoatDouble;

  /// No description provided for @petCoatWire.
  ///
  /// In pt, this message translates to:
  /// **'Pelo Duro'**
  String get petCoatWire;

  /// No description provided for @petCoatCurly.
  ///
  /// In pt, this message translates to:
  /// **'Pelo Encaracolado'**
  String get petCoatCurly;

  /// No description provided for @petFullAnalysisTitle.
  ///
  /// In pt, this message translates to:
  /// **'Análise Completa da Raça'**
  String get petFullAnalysisTitle;

  /// No description provided for @petGeneticAnalysisSub.
  ///
  /// In pt, this message translates to:
  /// **'Análise Genética Detalhada'**
  String get petGeneticAnalysisSub;

  /// No description provided for @petGeneticId.
  ///
  /// In pt, this message translates to:
  /// **'🧬 Identificação Genética'**
  String get petGeneticId;

  /// No description provided for @petPrimaryRace.
  ///
  /// In pt, this message translates to:
  /// **'Raça Predominante'**
  String get petPrimaryRace;

  /// No description provided for @petSecondaryRaces.
  ///
  /// In pt, this message translates to:
  /// **'Raças Secundárias'**
  String get petSecondaryRaces;

  /// No description provided for @petPhysicalChars.
  ///
  /// In pt, this message translates to:
  /// **'📏 Características Físicas'**
  String get petPhysicalChars;

  /// No description provided for @petWeightEstimated.
  ///
  /// In pt, this message translates to:
  /// **'Peso Estimado'**
  String get petWeightEstimated;

  /// No description provided for @petHeight.
  ///
  /// In pt, this message translates to:
  /// **'Altura'**
  String get petHeight;

  /// No description provided for @petExpectancy.
  ///
  /// In pt, this message translates to:
  /// **'Expectativa de Vida'**
  String get petExpectancy;

  /// No description provided for @petCoatType.
  ///
  /// In pt, this message translates to:
  /// **'Tipo de Pelagem'**
  String get petCoatType;

  /// No description provided for @petCommonColors.
  ///
  /// In pt, this message translates to:
  /// **'Cores Comuns'**
  String get petCommonColors;

  /// No description provided for @petTemperamentTitle.
  ///
  /// In pt, this message translates to:
  /// **'🎭 Temperamento e Personalidade'**
  String get petTemperamentTitle;

  /// No description provided for @petPersonality.
  ///
  /// In pt, this message translates to:
  /// **'Personalidade'**
  String get petPersonality;

  /// No description provided for @petSocialBehavior.
  ///
  /// In pt, this message translates to:
  /// **'Comportamento Social'**
  String get petSocialBehavior;

  /// No description provided for @petEnergyLevel.
  ///
  /// In pt, this message translates to:
  /// **'Nível de Energia'**
  String get petEnergyLevel;

  /// No description provided for @petRecommendedCare.
  ///
  /// In pt, this message translates to:
  /// **'💚 Cuidados Recomendados'**
  String get petRecommendedCare;

  /// No description provided for @petExercise.
  ///
  /// In pt, this message translates to:
  /// **'🏃 Exercício'**
  String get petExercise;

  /// No description provided for @petOriginHistory.
  ///
  /// In pt, this message translates to:
  /// **'📜 Origem e História'**
  String get petOriginHistory;

  /// No description provided for @petCuriositiesTitle.
  ///
  /// In pt, this message translates to:
  /// **'✨ Curiosidades'**
  String get petCuriositiesTitle;

  /// No description provided for @petNotIdentifiedPlural.
  ///
  /// In pt, this message translates to:
  /// **'Não identificadas'**
  String get petNotIdentifiedPlural;

  /// No description provided for @petVaried.
  ///
  /// In pt, this message translates to:
  /// **'Variadas'**
  String get petVaried;

  /// No description provided for @petDetailsUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes completos indisponíveis. Realize uma nova análise.'**
  String get petDetailsUnavailable;

  /// No description provided for @agendaExportTitle.
  ///
  /// In pt, this message translates to:
  /// **'Exportar Agenda'**
  String get agendaExportTitle;

  /// No description provided for @agendaReportType.
  ///
  /// In pt, this message translates to:
  /// **'Tipo de Relatório:'**
  String get agendaReportType;

  /// No description provided for @agendaReportSummary.
  ///
  /// In pt, this message translates to:
  /// **'Resumo'**
  String get agendaReportSummary;

  /// No description provided for @agendaReportDetail.
  ///
  /// In pt, this message translates to:
  /// **'Detalhamento'**
  String get agendaReportDetail;

  /// No description provided for @agendaNoEventsDay.
  ///
  /// In pt, this message translates to:
  /// **'Sem eventos neste dia'**
  String get agendaNoEventsDay;

  /// No description provided for @agendaEventsCount.
  ///
  /// In pt, this message translates to:
  /// **'{count} eventos'**
  String agendaEventsCount(Object count);

  /// No description provided for @agendaGeneratePDF.
  ///
  /// In pt, this message translates to:
  /// **'Gerar PDF'**
  String get agendaGeneratePDF;

  /// No description provided for @agendaGlobalTitle.
  ///
  /// In pt, this message translates to:
  /// **'Agenda Geral'**
  String get agendaGlobalTitle;

  /// No description provided for @agendaViewCalendar.
  ///
  /// In pt, this message translates to:
  /// **'Ver Calendário'**
  String get agendaViewCalendar;

  /// No description provided for @agendaViewAll.
  ///
  /// In pt, this message translates to:
  /// **'Ver Todos os Eventos'**
  String get agendaViewAll;

  /// No description provided for @agendaNoEventsRegistered.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum evento registrado.'**
  String get agendaNoEventsRegistered;

  /// No description provided for @agendaNoEventsTodayDetail.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum evento para este dia.'**
  String get agendaNoEventsTodayDetail;

  /// No description provided for @agendaAllPets.
  ///
  /// In pt, this message translates to:
  /// **'Todos os Pets'**
  String get agendaAllPets;

  /// No description provided for @agendaExportPDF.
  ///
  /// In pt, this message translates to:
  /// **'Exportar Relatório PDF'**
  String get agendaExportPDF;

  /// No description provided for @agendaReportingPeriod.
  ///
  /// In pt, this message translates to:
  /// **'Período de Apuração'**
  String get agendaReportingPeriod;

  /// No description provided for @agendaFilterPet.
  ///
  /// In pt, this message translates to:
  /// **'Filtrar por Pet'**
  String get agendaFilterPet;

  /// No description provided for @agendaFilterCategory.
  ///
  /// In pt, this message translates to:
  /// **'Filtrar por Categoria'**
  String get agendaFilterCategory;

  /// No description provided for @agendaDetailLevel.
  ///
  /// In pt, this message translates to:
  /// **'Nível de Detalhamento'**
  String get agendaDetailLevel;

  /// No description provided for @agendaDetailedTable.
  ///
  /// In pt, this message translates to:
  /// **'Detalhado (Com Tabela)'**
  String get agendaDetailedTable;

  /// No description provided for @agendaSummaryOnly.
  ///
  /// In pt, this message translates to:
  /// **'Resumo (Apenas Indicadores)'**
  String get agendaSummaryOnly;

  /// No description provided for @agendaButtonGenerate.
  ///
  /// In pt, this message translates to:
  /// **'GERAR RELATÓRIO'**
  String get agendaButtonGenerate;

  /// No description provided for @agendaAllCategories.
  ///
  /// In pt, this message translates to:
  /// **'Todas as Categorias'**
  String get agendaAllCategories;

  /// No description provided for @agendaNoPartnerLinked.
  ///
  /// In pt, this message translates to:
  /// **'Este evento não tem parceiro vinculado para exibir detalhes.'**
  String get agendaNoPartnerLinked;

  /// No description provided for @agendaProfileNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Perfil de {name} não encontrado.'**
  String agendaProfileNotFound(Object name);

  /// No description provided for @agendaServiceRecord.
  ///
  /// In pt, this message translates to:
  /// **'Ficha do Atendimento'**
  String get agendaServiceRecord;

  /// No description provided for @agendaAppointmentDetails.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes do Agendamento'**
  String get agendaAppointmentDetails;

  /// No description provided for @agendaResponsiblePartner.
  ///
  /// In pt, this message translates to:
  /// **'Parceiro Responsável'**
  String get agendaResponsiblePartner;

  /// No description provided for @agendaPartnerNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Parceiro não encontrado ou excluído.'**
  String get agendaPartnerNotFound;

  /// No description provided for @agendaMarkCompleted.
  ///
  /// In pt, this message translates to:
  /// **'MARCAR COMO CONCLUÍDO'**
  String get agendaMarkCompleted;

  /// No description provided for @agendaEventCompleted.
  ///
  /// In pt, this message translates to:
  /// **'Evento marcado como concluído!'**
  String get agendaEventCompleted;

  /// No description provided for @agendaEventUpdated.
  ///
  /// In pt, this message translates to:
  /// **'Evento atualizado com sucesso!'**
  String get agendaEventUpdated;

  /// No description provided for @agendaViewRegistration.
  ///
  /// In pt, this message translates to:
  /// **'Toque para ver o cadastro'**
  String get agendaViewRegistration;

  /// No description provided for @agendaWhatsAppChat.
  ///
  /// In pt, this message translates to:
  /// **'Falar pelo WhatsApp'**
  String get agendaWhatsAppChat;

  /// No description provided for @agendaWebsiteError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao abrir site'**
  String get agendaWebsiteError;

  /// No description provided for @agendaViewProfile.
  ///
  /// In pt, this message translates to:
  /// **'(Toque para ver o perfil)'**
  String get agendaViewProfile;

  /// No description provided for @agendaOriginalDataMissing.
  ///
  /// In pt, this message translates to:
  /// **'Dados originais do evento não encontrados para edição.'**
  String get agendaOriginalDataMissing;

  /// No description provided for @agendaEditEvent.
  ///
  /// In pt, this message translates to:
  /// **'Editar Evento'**
  String get agendaEditEvent;

  /// No description provided for @agendaChange.
  ///
  /// In pt, this message translates to:
  /// **'Alterar'**
  String get agendaChange;

  /// No description provided for @agendaAttendantSpecialist.
  ///
  /// In pt, this message translates to:
  /// **'Atendente / Especialista'**
  String get agendaAttendantSpecialist;

  /// No description provided for @agendaSelectAttendant.
  ///
  /// In pt, this message translates to:
  /// **'Selecione o atendente'**
  String get agendaSelectAttendant;

  /// No description provided for @agendaEventTitle.
  ///
  /// In pt, this message translates to:
  /// **'Título do Evento'**
  String get agendaEventTitle;

  /// No description provided for @agendaTitleExample.
  ///
  /// In pt, this message translates to:
  /// **'ex: Vacina Polivalente V10'**
  String get agendaTitleExample;

  /// No description provided for @agendaObservationsHint.
  ///
  /// In pt, this message translates to:
  /// **'Digite ou use o microfone...'**
  String get agendaObservationsHint;

  /// No description provided for @agendaAttachmentsFull.
  ///
  /// In pt, this message translates to:
  /// **'Anexos (PDF ou Fotos)'**
  String get agendaAttachmentsFull;

  /// No description provided for @agendaEnterTitle.
  ///
  /// In pt, this message translates to:
  /// **'Por favor, insira um título'**
  String get agendaEnterTitle;

  /// No description provided for @agendaSaveChanges.
  ///
  /// In pt, this message translates to:
  /// **'SALVAR ALTERAÇÕES'**
  String get agendaSaveChanges;

  /// No description provided for @agendaConfirmEvent.
  ///
  /// In pt, this message translates to:
  /// **'CONFIRMAR EVENTO'**
  String get agendaConfirmEvent;

  /// No description provided for @commonCamera.
  ///
  /// In pt, this message translates to:
  /// **'Câmera'**
  String get commonCamera;

  /// No description provided for @commonGallery.
  ///
  /// In pt, this message translates to:
  /// **'Galeria'**
  String get commonGallery;

  /// No description provided for @commonPDFFile.
  ///
  /// In pt, this message translates to:
  /// **'Arquivo PDF'**
  String get commonPDFFile;

  /// No description provided for @petConsultVet.
  ///
  /// In pt, this message translates to:
  /// **'Consulte veterinário para predisposições específicas'**
  String get petConsultVet;

  /// No description provided for @petHemogramaCheckup.
  ///
  /// In pt, this message translates to:
  /// **'Hemograma e Checkup Geral'**
  String get petHemogramaCheckup;

  /// No description provided for @petPositiveReinforcement.
  ///
  /// In pt, this message translates to:
  /// **'Reforço positivo'**
  String get petPositiveReinforcement;

  /// No description provided for @petInteractiveToys.
  ///
  /// In pt, this message translates to:
  /// **'Brinquedos interativos e passeios'**
  String get petInteractiveToys;

  /// No description provided for @petConsultVetCare.
  ///
  /// In pt, this message translates to:
  /// **'Consulte um Vet.'**
  String get petConsultVetCare;

  /// No description provided for @pdfFieldObservations.
  ///
  /// In pt, this message translates to:
  /// **'Observações'**
  String get pdfFieldObservations;

  /// No description provided for @petBreedMixed.
  ///
  /// In pt, this message translates to:
  /// **'Raça Mista'**
  String get petBreedMixed;

  /// No description provided for @petAllergies.
  ///
  /// In pt, this message translates to:
  /// **'Alergias'**
  String get petAllergies;

  /// No description provided for @explainExam.
  ///
  /// In pt, this message translates to:
  /// **'Explicar Exame'**
  String get explainExam;

  /// No description provided for @attendantName.
  ///
  /// In pt, this message translates to:
  /// **'Nome do Atendente'**
  String get attendantName;

  /// No description provided for @partnerDetailsRole.
  ///
  /// In pt, this message translates to:
  /// **'Função'**
  String get partnerDetailsRole;

  /// No description provided for @pdfDiagnosisTriage.
  ///
  /// In pt, this message translates to:
  /// **'Triage Veterinária'**
  String get pdfDiagnosisTriage;

  /// No description provided for @pdfFieldBreedSpecies.
  ///
  /// In pt, this message translates to:
  /// **'Raça/Espécie'**
  String get pdfFieldBreedSpecies;

  /// No description provided for @pdfFieldUrgency.
  ///
  /// In pt, this message translates to:
  /// **'Urgência'**
  String get pdfFieldUrgency;

  /// No description provided for @pdfFieldProfessionalRecommendation.
  ///
  /// In pt, this message translates to:
  /// **'Recomendação Profissional'**
  String get pdfFieldProfessionalRecommendation;

  /// No description provided for @pdfDossierTitle.
  ///
  /// In pt, this message translates to:
  /// **'Dossiê 360º de Pet'**
  String get pdfDossierTitle;

  /// No description provided for @pdfSectionIdentity.
  ///
  /// In pt, this message translates to:
  /// **'1. IDENTIDADE E PERFIL'**
  String get pdfSectionIdentity;

  /// No description provided for @pdfSectionNutrition.
  ///
  /// In pt, this message translates to:
  /// **'2. NUTRIÇÃO E DIETA ESTRATÉGICA'**
  String get pdfSectionNutrition;

  /// No description provided for @pdfSectionGrooming.
  ///
  /// In pt, this message translates to:
  /// **'3. GROOMING & HIGIENE'**
  String get pdfSectionGrooming;

  /// No description provided for @pdfSectionHealth.
  ///
  /// In pt, this message translates to:
  /// **'4. SAÚDE PREVENTIVA'**
  String get pdfSectionHealth;

  /// No description provided for @pdfSectionLifestyle.
  ///
  /// In pt, this message translates to:
  /// **'5. LIFESTYLE & EDUCAÇÃO'**
  String get pdfSectionLifestyle;

  /// No description provided for @pdfFieldPredominantBreed.
  ///
  /// In pt, this message translates to:
  /// **'Raça Predominante'**
  String get pdfFieldPredominantBreed;

  /// No description provided for @pdfFieldBehavioralProfile.
  ///
  /// In pt, this message translates to:
  /// **'Perfil Comportamental'**
  String get pdfFieldBehavioralProfile;

  /// No description provided for @pdfFieldEnergyLevel.
  ///
  /// In pt, this message translates to:
  /// **'Nível de Energia'**
  String get pdfFieldEnergyLevel;

  /// No description provided for @pdfFieldIntelligence.
  ///
  /// In pt, this message translates to:
  /// **'Inteligência'**
  String get pdfFieldIntelligence;

  /// No description provided for @pdfFieldSociability.
  ///
  /// In pt, this message translates to:
  /// **'Sociabilidade'**
  String get pdfFieldSociability;

  /// No description provided for @pdfFieldAncestralDrive.
  ///
  /// In pt, this message translates to:
  /// **'Drive Ancestral'**
  String get pdfFieldAncestralDrive;

  /// No description provided for @pdfFieldEstimatedGrowthCurve.
  ///
  /// In pt, this message translates to:
  /// **'Curva de Crescimento Estimada'**
  String get pdfFieldEstimatedGrowthCurve;

  /// No description provided for @pdfFieldDailyCaloricGoals.
  ///
  /// In pt, this message translates to:
  /// **'Metas Calóricas Diárias'**
  String get pdfFieldDailyCaloricGoals;

  /// No description provided for @pdfFieldPuppy.
  ///
  /// In pt, this message translates to:
  /// **'Filhote'**
  String get pdfFieldPuppy;

  /// No description provided for @pdfFieldAdult.
  ///
  /// In pt, this message translates to:
  /// **'Adulto'**
  String get pdfFieldAdult;

  /// No description provided for @pdfFieldSenior.
  ///
  /// In pt, this message translates to:
  /// **'Sênior'**
  String get pdfFieldSenior;

  /// No description provided for @pdfFieldTargetNutrients.
  ///
  /// In pt, this message translates to:
  /// **'Nutrientes Alvo'**
  String get pdfFieldTargetNutrients;

  /// No description provided for @pdfFieldSuggestedSupplementation.
  ///
  /// In pt, this message translates to:
  /// **'Suplementação Sugerida'**
  String get pdfFieldSuggestedSupplementation;

  /// No description provided for @pdfFieldFoodSafety.
  ///
  /// In pt, this message translates to:
  /// **'Segurança Alimentar'**
  String get pdfFieldFoodSafety;

  /// No description provided for @pdfAlertObesity.
  ///
  /// In pt, this message translates to:
  /// **'⚠️ ALERTA: Tendência à obesidade detectada'**
  String get pdfAlertObesity;

  /// No description provided for @pdfFieldSafeFoods.
  ///
  /// In pt, this message translates to:
  /// **'Alimentos Seguros (Benigna)'**
  String get pdfFieldSafeFoods;

  /// No description provided for @pdfFieldToxicFoods.
  ///
  /// In pt, this message translates to:
  /// **'Alimentos Tóxicos (Maligna)'**
  String get pdfFieldToxicFoods;

  /// No description provided for @pdfFieldFoodName.
  ///
  /// In pt, this message translates to:
  /// **'Alimento'**
  String get pdfFieldFoodName;

  /// No description provided for @pdfFieldBenefit.
  ///
  /// In pt, this message translates to:
  /// **'Benefício'**
  String get pdfFieldBenefit;

  /// No description provided for @pdfFieldRisk.
  ///
  /// In pt, this message translates to:
  /// **'Risco'**
  String get pdfFieldRisk;

  /// No description provided for @pdfFieldWeeklyMenu.
  ///
  /// In pt, this message translates to:
  /// **'Cardápio Semanal (Dieta Natural)'**
  String get pdfFieldWeeklyMenu;

  /// No description provided for @pdfFieldReason.
  ///
  /// In pt, this message translates to:
  /// **'Motivo'**
  String get pdfFieldReason;

  /// No description provided for @pdfFieldCoatType.
  ///
  /// In pt, this message translates to:
  /// **'Tipo de Pelo'**
  String get pdfFieldCoatType;

  /// No description provided for @pdfFieldBrushingFrequency.
  ///
  /// In pt, this message translates to:
  /// **'Frequência de Escovação'**
  String get pdfFieldBrushingFrequency;

  /// No description provided for @pdfFieldRecommendedProducts.
  ///
  /// In pt, this message translates to:
  /// **'Produtos Recomendados'**
  String get pdfFieldRecommendedProducts;

  /// No description provided for @pdfFieldDiseasePredisposition.
  ///
  /// In pt, this message translates to:
  /// **'Predisposição a Doenças'**
  String get pdfFieldDiseasePredisposition;

  /// No description provided for @pdfFieldAnatomicalCriticalPoints.
  ///
  /// In pt, this message translates to:
  /// **'Pontos Críticos Anatômicos'**
  String get pdfFieldAnatomicalCriticalPoints;

  /// No description provided for @pdfFieldVeterinaryCheckup.
  ///
  /// In pt, this message translates to:
  /// **'Checkup Veterinário'**
  String get pdfFieldVeterinaryCheckup;

  /// No description provided for @pdfFieldMandatoryExams.
  ///
  /// In pt, this message translates to:
  /// **'Exames'**
  String get pdfFieldMandatoryExams;

  /// No description provided for @pdfFieldClimateSensitivity.
  ///
  /// In pt, this message translates to:
  /// **'Sensibilidade Climática'**
  String get pdfFieldClimateSensitivity;

  /// No description provided for @pdfFieldHeat.
  ///
  /// In pt, this message translates to:
  /// **'Calor'**
  String get pdfFieldHeat;

  /// No description provided for @pdfFieldCold.
  ///
  /// In pt, this message translates to:
  /// **'Frio'**
  String get pdfFieldCold;

  /// No description provided for @pdfSectionImmunization.
  ///
  /// In pt, this message translates to:
  /// **'4.1 Protocolo de Imunização'**
  String get pdfSectionImmunization;

  /// No description provided for @pdfFieldEssentialVaccines.
  ///
  /// In pt, this message translates to:
  /// **'Vacinas Essenciais'**
  String get pdfFieldEssentialVaccines;

  /// No description provided for @pdfFieldVaccineGoal.
  ///
  /// In pt, this message translates to:
  /// **'Objetivo'**
  String get pdfFieldVaccineGoal;

  /// No description provided for @pdfFieldFirstDose.
  ///
  /// In pt, this message translates to:
  /// **'1ª dose'**
  String get pdfFieldFirstDose;

  /// No description provided for @pdfFieldBooster.
  ///
  /// In pt, this message translates to:
  /// **'Reforço'**
  String get pdfFieldBooster;

  /// No description provided for @pdfFieldPreventiveCalendar.
  ///
  /// In pt, this message translates to:
  /// **'Calendário Preventivo'**
  String get pdfFieldPreventiveCalendar;

  /// No description provided for @pdfFieldPuppies.
  ///
  /// In pt, this message translates to:
  /// **'Filhotes'**
  String get pdfFieldPuppies;

  /// No description provided for @pdfFieldAdults.
  ///
  /// In pt, this message translates to:
  /// **'Adultos'**
  String get pdfFieldAdults;

  /// No description provided for @pdfFieldParasitePrevention.
  ///
  /// In pt, this message translates to:
  /// **'Prevenção Parasitária'**
  String get pdfFieldParasitePrevention;

  /// No description provided for @pdfFieldDewormer.
  ///
  /// In pt, this message translates to:
  /// **'Vermífugo'**
  String get pdfFieldDewormer;

  /// No description provided for @pdfFieldTickFlea.
  ///
  /// In pt, this message translates to:
  /// **'Pulgas/Carrapatos'**
  String get pdfFieldTickFlea;

  /// No description provided for @pdfFieldOralBoneHealth.
  ///
  /// In pt, this message translates to:
  /// **'Saúde Bucal e Óssea'**
  String get pdfFieldOralBoneHealth;

  /// No description provided for @pdfFieldPermittedBones.
  ///
  /// In pt, this message translates to:
  /// **'Ossos Permitidos'**
  String get pdfFieldPermittedBones;

  /// No description provided for @pdfFieldFrequency.
  ///
  /// In pt, this message translates to:
  /// **'Frequência'**
  String get pdfFieldFrequency;

  /// No description provided for @pdfFieldTraining.
  ///
  /// In pt, this message translates to:
  /// **'Treinamento'**
  String get pdfFieldTraining;

  /// No description provided for @pdfFieldTrainingDifficulty.
  ///
  /// In pt, this message translates to:
  /// **'Dificuldade de Adestramento'**
  String get pdfFieldTrainingDifficulty;

  /// No description provided for @pdfFieldRecommendedMethods.
  ///
  /// In pt, this message translates to:
  /// **'Métodos Recomendados'**
  String get pdfFieldRecommendedMethods;

  /// No description provided for @pdfFieldIdealEnvironment.
  ///
  /// In pt, this message translates to:
  /// **'Ambiente Ideal'**
  String get pdfFieldIdealEnvironment;

  /// No description provided for @pdfFieldOpenSpace.
  ///
  /// In pt, this message translates to:
  /// **'Espaço Aberto'**
  String get pdfFieldOpenSpace;

  /// No description provided for @pdfFieldApartmentAdaptation.
  ///
  /// In pt, this message translates to:
  /// **'Adaptação Apartamento'**
  String get pdfFieldApartmentAdaptation;

  /// No description provided for @pdfFieldPeriod.
  ///
  /// In pt, this message translates to:
  /// **'Período'**
  String get pdfFieldPeriod;

  /// No description provided for @pdfFieldRegime.
  ///
  /// In pt, this message translates to:
  /// **'Regime'**
  String get pdfFieldRegime;

  /// No description provided for @pdfFieldDailyKcalMeta.
  ///
  /// In pt, this message translates to:
  /// **'Meta Calórica Diária'**
  String get pdfFieldDailyKcalMeta;

  /// No description provided for @pdfFieldDetailsComposition.
  ///
  /// In pt, this message translates to:
  /// **'COMPOSIÇÃO E DETALHAMENTO (5 PILARES):'**
  String get pdfFieldDetailsComposition;

  /// No description provided for @pdfPeriodWeekly.
  ///
  /// In pt, this message translates to:
  /// **'Semanal'**
  String get pdfPeriodWeekly;

  /// No description provided for @pdfNoMealsPlanned.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma refeição planejada.'**
  String get pdfNoMealsPlanned;

  /// No description provided for @pdfFieldGeneralGuidelines.
  ///
  /// In pt, this message translates to:
  /// **'ORIENTAÇÕES GERAIS'**
  String get pdfFieldGeneralGuidelines;

  /// No description provided for @pdfFieldMainNutrients.
  ///
  /// In pt, this message translates to:
  /// **'Principais Nutrientes'**
  String get pdfFieldMainNutrients;

  /// No description provided for @pdfLastDose.
  ///
  /// In pt, this message translates to:
  /// **'Última Aplicação'**
  String get pdfLastDose;

  /// No description provided for @pdfNextDose.
  ///
  /// In pt, this message translates to:
  /// **'Próxima Dose'**
  String get pdfNextDose;

  /// No description provided for @eventVaccine.
  ///
  /// In pt, this message translates to:
  /// **'Vacina'**
  String get eventVaccine;

  /// No description provided for @eventBath.
  ///
  /// In pt, this message translates to:
  /// **'Banho'**
  String get eventBath;

  /// No description provided for @eventGrooming.
  ///
  /// In pt, this message translates to:
  /// **'Tosa'**
  String get eventGrooming;

  /// No description provided for @eventVeterinary.
  ///
  /// In pt, this message translates to:
  /// **'Veterinário'**
  String get eventVeterinary;

  /// No description provided for @eventMedication.
  ///
  /// In pt, this message translates to:
  /// **'Medicamento'**
  String get eventMedication;

  /// No description provided for @eventOther.
  ///
  /// In pt, this message translates to:
  /// **'Outro'**
  String get eventOther;

  /// No description provided for @pdfFieldMentalStimulus.
  ///
  /// In pt, this message translates to:
  /// **'Estímulo Mental'**
  String get pdfFieldMentalStimulus;

  /// No description provided for @pdfFieldSuggestedActivities.
  ///
  /// In pt, this message translates to:
  /// **'Atividades'**
  String get pdfFieldSuggestedActivities;

  /// No description provided for @pdfFieldExpertInsight.
  ///
  /// In pt, this message translates to:
  /// **'INSIGHT DO ESPECIALISTA'**
  String get pdfFieldExpertInsight;

  /// No description provided for @pdfDisclaimer.
  ///
  /// In pt, this message translates to:
  /// **'Aviso: Este relatório foi gerado por IA e não substitui consulta veterinária profissional.'**
  String get pdfDisclaimer;

  /// No description provided for @btnCancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get btnCancel;

  /// No description provided for @processingAnalysis.
  ///
  /// In pt, this message translates to:
  /// **'Processando Análise...'**
  String get processingAnalysis;

  /// No description provided for @labExamsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Histórico e Resultados'**
  String get labExamsSubtitle;

  /// No description provided for @labExamsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Exames Laboratoriais'**
  String get labExamsTitle;

  /// No description provided for @pdfFilterTitle.
  ///
  /// In pt, this message translates to:
  /// **'Filtrar Seções do PDF'**
  String get pdfFilterTitle;

  /// No description provided for @pdfFilterSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Selecione as seções que deseja incluir no relatório:'**
  String get pdfFilterSubtitle;

  /// No description provided for @pdfFilterDisclaimer.
  ///
  /// In pt, this message translates to:
  /// **'O relatório incluirá apenas as seções selecionadas'**
  String get pdfFilterDisclaimer;

  /// No description provided for @pdfSelectAll.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar Tudo'**
  String get pdfSelectAll;

  /// No description provided for @pdfGenerate.
  ///
  /// In pt, this message translates to:
  /// **'Gerar PDF'**
  String get pdfGenerate;

  /// No description provided for @sectionIdentity.
  ///
  /// In pt, this message translates to:
  /// **'Identidade'**
  String get sectionIdentity;

  /// No description provided for @sectionHealth.
  ///
  /// In pt, this message translates to:
  /// **'Saúde'**
  String get sectionHealth;

  /// No description provided for @sectionNutrition.
  ///
  /// In pt, this message translates to:
  /// **'Nutrição'**
  String get sectionNutrition;

  /// No description provided for @sectionGallery.
  ///
  /// In pt, this message translates to:
  /// **'Galeria'**
  String get sectionGallery;

  /// No description provided for @sectionPartners.
  ///
  /// In pt, this message translates to:
  /// **'Parceiros'**
  String get sectionPartners;

  /// No description provided for @sectionDescIdentity.
  ///
  /// In pt, this message translates to:
  /// **'Informações básicas e perfil biológico'**
  String get sectionDescIdentity;

  /// No description provided for @sectionDescHealth.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de vacinas, peso e exames'**
  String get sectionDescHealth;

  /// No description provided for @sectionDescNutrition.
  ///
  /// In pt, this message translates to:
  /// **'Plano alimentar semanal e preferências'**
  String get sectionDescNutrition;

  /// No description provided for @sectionDescGallery.
  ///
  /// In pt, this message translates to:
  /// **'Fotos e documentos anexados'**
  String get sectionDescGallery;

  /// No description provided for @sectionDescPartners.
  ///
  /// In pt, this message translates to:
  /// **'Rede de apoio e parceiros vinculados'**
  String get sectionDescPartners;

  /// No description provided for @observationNew.
  ///
  /// In pt, this message translates to:
  /// **'Nova Observação'**
  String get observationNew;

  /// No description provided for @observationHint.
  ///
  /// In pt, this message translates to:
  /// **'Digite sua observação...'**
  String get observationHint;

  /// No description provided for @commonAdd.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar'**
  String get commonAdd;

  /// No description provided for @voiceNotAvailable.
  ///
  /// In pt, this message translates to:
  /// **'Reconhecimento de voz não disponível'**
  String get voiceNotAvailable;

  /// No description provided for @shopItems.
  ///
  /// In pt, this message translates to:
  /// **'{count} Itens'**
  String shopItems(int count);

  /// No description provided for @shopSyncPlan.
  ///
  /// In pt, this message translates to:
  /// **'Sincronizar Plano'**
  String get shopSyncPlan;

  /// No description provided for @shopClearDone.
  ///
  /// In pt, this message translates to:
  /// **'Limpar Concluídos'**
  String get shopClearDone;

  /// No description provided for @shopEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sua lista está vazia'**
  String get shopEmptyTitle;

  /// No description provided for @shopEmptySubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Adicione itens manualmente ou\ngere a partir do seu cardápio.'**
  String get shopEmptySubtitle;

  /// No description provided for @shopGenerateFromMenu.
  ///
  /// In pt, this message translates to:
  /// **'Gerar do Cardápio Semanal'**
  String get shopGenerateFromMenu;

  /// No description provided for @shopNoMenuError.
  ///
  /// In pt, this message translates to:
  /// **'Crie um cardápio primeiro!'**
  String get shopNoMenuError;

  /// No description provided for @shopReplaceTitle.
  ///
  /// In pt, this message translates to:
  /// **'Substituir lista?'**
  String get shopReplaceTitle;

  /// No description provided for @shopReplaceContent.
  ///
  /// In pt, this message translates to:
  /// **'Isso vai apagar a lista atual e criar uma nova baseada no cardápio.'**
  String get shopReplaceContent;

  /// No description provided for @shopGenerateBtn.
  ///
  /// In pt, this message translates to:
  /// **'Gerar Lista'**
  String get shopGenerateBtn;

  /// No description provided for @shopGeneratedSuccess.
  ///
  /// In pt, this message translates to:
  /// **'✅ Lista gerada com sucesso!'**
  String get shopGeneratedSuccess;

  /// No description provided for @shopAddItemTitle.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar Item'**
  String get shopAddItemTitle;

  /// No description provided for @shopItemName.
  ///
  /// In pt, this message translates to:
  /// **'Nome do Item'**
  String get shopItemName;

  /// No description provided for @shopItemQty.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade (ex: 2kg, 1 un)'**
  String get shopItemQty;

  /// No description provided for @shopDefaultQty.
  ///
  /// In pt, this message translates to:
  /// **'1 porção'**
  String get shopDefaultQty;

  /// No description provided for @backupOptimizeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Backup e Otimização'**
  String get backupOptimizeTitle;

  /// No description provided for @backupOptimizeDesc.
  ///
  /// In pt, this message translates to:
  /// **'Gera um PDF completo com todo o histórico do pet (incluindo fotos e anexos) e permite limpar registros antigos para liberar espaço.'**
  String get backupOptimizeDesc;

  /// No description provided for @backupNoPets.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum pet encontrado.'**
  String get backupNoPets;

  /// No description provided for @backupSelectPet.
  ///
  /// In pt, this message translates to:
  /// **'Selecione o Pet'**
  String get backupSelectPet;

  /// No description provided for @backupProcessing.
  ///
  /// In pt, this message translates to:
  /// **'Processando...'**
  String get backupProcessing;

  /// No description provided for @backupGenerateBtn.
  ///
  /// In pt, this message translates to:
  /// **'Gerar e Otimizar'**
  String get backupGenerateBtn;

  /// No description provided for @backupOptimizationTitle.
  ///
  /// In pt, this message translates to:
  /// **'Otimização de Armazenamento'**
  String get backupOptimizationTitle;

  /// No description provided for @backupOptimizationContent.
  ///
  /// In pt, this message translates to:
  /// **'Backup PDF gerado com sucesso!\n\nDeseja remover registros com mais de 2 anos (Observações e Feridas) para liberar espaço no dispositivo? O histórico antigo permanecerá salvo no PDF que você acabou de exportar.'**
  String get backupOptimizationContent;

  /// No description provided for @backupKeepAll.
  ///
  /// In pt, this message translates to:
  /// **'Manter Tudo'**
  String get backupKeepAll;

  /// No description provided for @backupCleanOld.
  ///
  /// In pt, this message translates to:
  /// **'Limpar Antigos'**
  String get backupCleanOld;

  /// No description provided for @backupSuccessClean.
  ///
  /// In pt, this message translates to:
  /// **'Limpeza concluída! App otimizado.'**
  String get backupSuccessClean;

  /// No description provided for @backupNoDataClean.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum dado antigo encontrado para limpeza.'**
  String get backupNoDataClean;

  /// No description provided for @backupProfileNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Perfil não encontrado'**
  String get backupProfileNotFound;

  /// No description provided for @commonSyncError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao sincronizar: {error}'**
  String commonSyncError(String error);

  /// No description provided for @petDefaultName.
  ///
  /// In pt, this message translates to:
  /// **'este pet'**
  String get petDefaultName;

  /// No description provided for @diagnosisPending.
  ///
  /// In pt, this message translates to:
  /// **'Sem diagnóstico'**
  String get diagnosisPending;

  /// No description provided for @severityLow.
  ///
  /// In pt, this message translates to:
  /// **'Baixa'**
  String get severityLow;

  /// No description provided for @severityMedium.
  ///
  /// In pt, this message translates to:
  /// **'Média'**
  String get severityMedium;

  /// No description provided for @severityHigh.
  ///
  /// In pt, this message translates to:
  /// **'Alta'**
  String get severityHigh;

  /// No description provided for @commonSaveNameFirst.
  ///
  /// In pt, this message translates to:
  /// **'Salve o pet ou insira o nome primeiro.'**
  String get commonSaveNameFirst;

  /// No description provided for @commonFilePrefix.
  ///
  /// In pt, this message translates to:
  /// **'Arquivo: '**
  String get commonFilePrefix;

  /// No description provided for @commonNoAttachments.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum documento anexado.'**
  String get commonNoAttachments;

  /// No description provided for @commonView.
  ///
  /// In pt, this message translates to:
  /// **'Visualizar'**
  String get commonView;

  /// No description provided for @aiAnalysis.
  ///
  /// In pt, this message translates to:
  /// **'Análise Assistida'**
  String get aiAnalysis;

  /// No description provided for @commonError.
  ///
  /// In pt, this message translates to:
  /// **'Erro'**
  String get commonError;

  /// No description provided for @commonEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get commonEdit;

  /// No description provided for @agendaTabUpcoming.
  ///
  /// In pt, this message translates to:
  /// **'Próximos'**
  String get agendaTabUpcoming;

  /// No description provided for @agendaTabPast.
  ///
  /// In pt, this message translates to:
  /// **'Passados'**
  String get agendaTabPast;

  /// No description provided for @agendaTabAll.
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get agendaTabAll;

  /// No description provided for @agendaNoUpcoming.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum evento próximo'**
  String get agendaNoUpcoming;

  /// No description provided for @agendaNoPast.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum evento passado'**
  String get agendaNoPast;

  /// No description provided for @agendaNoEvents.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum evento cadastrado'**
  String get agendaNoEvents;

  /// No description provided for @agendaNoFiltered.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum evento deste tipo'**
  String get agendaNoFiltered;

  /// No description provided for @agendaDeleteTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir Evento?'**
  String get agendaDeleteTitle;

  /// No description provided for @agendaDeleteContent.
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza que deseja excluir \"{title}\"?'**
  String agendaDeleteContent(String title);

  /// No description provided for @agendaDeleted.
  ///
  /// In pt, this message translates to:
  /// **'Evento excluído'**
  String get agendaDeleted;

  /// No description provided for @agendaCreated.
  ///
  /// In pt, this message translates to:
  /// **'Evento criado!'**
  String get agendaCreated;

  /// No description provided for @agendaUpdated.
  ///
  /// In pt, this message translates to:
  /// **'Evento atualizado!'**
  String get agendaUpdated;

  /// No description provided for @agendaStatusOverdue.
  ///
  /// In pt, this message translates to:
  /// **'ATRASADO'**
  String get agendaStatusOverdue;

  /// No description provided for @agendaStatusToday.
  ///
  /// In pt, this message translates to:
  /// **'HOJE'**
  String get agendaStatusToday;

  /// No description provided for @agendaFieldTitle.
  ///
  /// In pt, this message translates to:
  /// **'Título'**
  String get agendaFieldTitle;

  /// No description provided for @agendaFieldType.
  ///
  /// In pt, this message translates to:
  /// **'Tipo'**
  String get agendaFieldType;

  /// No description provided for @agendaFieldVaccineSelect.
  ///
  /// In pt, this message translates to:
  /// **'Selecione a Vacina'**
  String get agendaFieldVaccineSelect;

  /// No description provided for @agendaFieldVaccineName.
  ///
  /// In pt, this message translates to:
  /// **'Nome da Vacina'**
  String get agendaFieldVaccineName;

  /// No description provided for @agendaVaccineOther.
  ///
  /// In pt, this message translates to:
  /// **'Outra vacina'**
  String get agendaVaccineOther;

  /// No description provided for @agendaRequired.
  ///
  /// In pt, this message translates to:
  /// **'Obrigatório'**
  String get agendaRequired;

  /// No description provided for @btnDelete.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get btnDelete;

  /// No description provided for @partnerRegisterTitle.
  ///
  /// In pt, this message translates to:
  /// **'Cadastrar Parceiro'**
  String get partnerRegisterTitle;

  /// No description provided for @partnerEditTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar Parceiro'**
  String get partnerEditTitle;

  /// No description provided for @partnerDeleteTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir Parceiro'**
  String get partnerDeleteTitle;

  /// No description provided for @partnerDeleteContent.
  ///
  /// In pt, this message translates to:
  /// **'Deseja remover \"{name}\" da sua rede de apoio?'**
  String partnerDeleteContent(String name);

  /// No description provided for @partnerDeleted.
  ///
  /// In pt, this message translates to:
  /// **'Parceiro removido.'**
  String get partnerDeleted;

  /// No description provided for @partnerSaved.
  ///
  /// In pt, this message translates to:
  /// **'Parceiro \"{name}\" salvo com sucesso!'**
  String partnerSaved(String name);

  /// No description provided for @partnerSaveError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao salvar: {error}'**
  String partnerSaveError(String error);

  /// No description provided for @partnerCantDeleteLinked.
  ///
  /// In pt, this message translates to:
  /// **'Não é possível excluir: Este parceiro está vinculado a um Pet.'**
  String get partnerCantDeleteLinked;

  /// No description provided for @partnerBtnSave.
  ///
  /// In pt, this message translates to:
  /// **'SALVAR PARCEIRO'**
  String get partnerBtnSave;

  /// No description provided for @partnerBtnDelete.
  ///
  /// In pt, this message translates to:
  /// **'EXCLUIR PARCEIRO'**
  String get partnerBtnDelete;

  /// No description provided for @partnerDangerZone.
  ///
  /// In pt, this message translates to:
  /// **'Zona de Perigo'**
  String get partnerDangerZone;

  /// No description provided for @partnerDangerZoneDesc.
  ///
  /// In pt, this message translates to:
  /// **'Ao excluir este parceiro, ele será removido permanentemente. Esta ação é irreversível.'**
  String get partnerDangerZoneDesc;

  /// No description provided for @partnerRadarTitle.
  ///
  /// In pt, this message translates to:
  /// **'Radar Geo'**
  String get partnerRadarTitle;

  /// No description provided for @partnerRadarHint.
  ///
  /// In pt, this message translates to:
  /// **'Toque para alterar o raio de busca'**
  String get partnerRadarHint;

  /// No description provided for @partnerRadarScanning.
  ///
  /// In pt, this message translates to:
  /// **'Sintonizando Radar e GPS...'**
  String get partnerRadarScanning;

  /// No description provided for @partnerRadarNoResults.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum local encontrado.'**
  String get partnerRadarNoResults;

  /// No description provided for @partnerRadarPermission.
  ///
  /// In pt, this message translates to:
  /// **'Permissão de localização necessária.'**
  String get partnerRadarPermission;

  /// No description provided for @partnerRadarGPSCallbackError.
  ///
  /// In pt, this message translates to:
  /// **'GPS não retornou coordenadas válidas. Verifique as permissões.'**
  String get partnerRadarGPSCallbackError;

  /// No description provided for @partnerRadarFoundTitle.
  ///
  /// In pt, this message translates to:
  /// **'Estabelecimentos reais detectados na sua região:'**
  String get partnerRadarFoundTitle;

  /// No description provided for @partnerFieldEstablishment.
  ///
  /// In pt, this message translates to:
  /// **'Nome do Estabelecimento'**
  String get partnerFieldEstablishment;

  /// No description provided for @partnerFieldPhone.
  ///
  /// In pt, this message translates to:
  /// **'Telefone / WhatsApp'**
  String get partnerFieldPhone;

  /// No description provided for @partnerFieldInstagram.
  ///
  /// In pt, this message translates to:
  /// **'Instagram (ex: @meupet)'**
  String get partnerFieldInstagram;

  /// No description provided for @partnerFieldHours.
  ///
  /// In pt, this message translates to:
  /// **'Horário de Funcionamento'**
  String get partnerFieldHours;

  /// No description provided for @partnerField24h.
  ///
  /// In pt, this message translates to:
  /// **'Plantão 24h / Emergência'**
  String get partnerField24h;

  /// No description provided for @partnerField24hSub.
  ///
  /// In pt, this message translates to:
  /// **'Local funciona ininterruptamente'**
  String get partnerField24hSub;

  /// No description provided for @partnerFieldSpecialties.
  ///
  /// In pt, this message translates to:
  /// **'Especialidades (separe por vírgula)'**
  String get partnerFieldSpecialties;

  /// No description provided for @partnerFieldWebsite.
  ///
  /// In pt, this message translates to:
  /// **'Website'**
  String get partnerFieldWebsite;

  /// No description provided for @partnerFieldEmail.
  ///
  /// In pt, this message translates to:
  /// **'E-mail'**
  String get partnerFieldEmail;

  /// No description provided for @partnerFieldAddress.
  ///
  /// In pt, this message translates to:
  /// **'Endereço Completo'**
  String get partnerFieldAddress;

  /// No description provided for @partnerTeamTitle.
  ///
  /// In pt, this message translates to:
  /// **'Corpo Clínico / Equipe'**
  String get partnerTeamTitle;

  /// No description provided for @partnerTeamAddHint.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar nome (ex: Dra. Ana)'**
  String get partnerTeamAddHint;

  /// No description provided for @partnerCategory.
  ///
  /// In pt, this message translates to:
  /// **'Categoria'**
  String get partnerCategory;

  /// No description provided for @partnerNotesHint.
  ///
  /// In pt, this message translates to:
  /// **'Nova observação...'**
  String get partnerNotesHint;

  /// No description provided for @partnerRadarButtonTitle.
  ///
  /// In pt, this message translates to:
  /// **'Busca Inteligente por Radar'**
  String get partnerRadarButtonTitle;

  /// No description provided for @partnerRadarButtonDesc.
  ///
  /// In pt, this message translates to:
  /// **'Encontre e import dados via GPS'**
  String get partnerRadarButtonDesc;

  /// No description provided for @partnersRadiusInfo.
  ///
  /// In pt, this message translates to:
  /// **'Mostrando parceiros em um raio de {radius}km'**
  String partnersRadiusInfo(String radius);

  /// No description provided for @partnersEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum parceiro encontrado\nneste raio de busca.'**
  String get partnersEmpty;

  /// No description provided for @partnersIncreaseRadius.
  ///
  /// In pt, this message translates to:
  /// **'Aumentar Raio de Busca'**
  String get partnersIncreaseRadius;

  /// No description provided for @partnersSuggestion.
  ///
  /// In pt, this message translates to:
  /// **'Baseado na análise do seu pet, encontramos estes especialistas para você.'**
  String get partnersSuggestion;

  /// No description provided for @partnersKmFromYou.
  ///
  /// In pt, this message translates to:
  /// **'{dist} km de você'**
  String partnersKmFromYou(String dist);

  /// No description provided for @partnersCall.
  ///
  /// In pt, this message translates to:
  /// **'Ligar'**
  String get partnersCall;

  /// No description provided for @partnersMap.
  ///
  /// In pt, this message translates to:
  /// **'Mapa'**
  String get partnersMap;

  /// No description provided for @partnersLinkTitle.
  ///
  /// In pt, this message translates to:
  /// **'Vincular Parceiro'**
  String get partnersLinkTitle;

  /// No description provided for @partnersLinkContent.
  ///
  /// In pt, this message translates to:
  /// **'Deseja adicionar \"{name}\" à sua Rede de Apoio personalizada?'**
  String partnersLinkContent(String name);

  /// No description provided for @partnersLinkSuccess.
  ///
  /// In pt, this message translates to:
  /// **'\"{name}\" vinculado com sucesso!'**
  String partnersLinkSuccess(String name);

  /// No description provided for @partnersBtnLink.
  ///
  /// In pt, this message translates to:
  /// **'Vincular'**
  String get partnersBtnLink;

  /// No description provided for @backupGoogleDrive.
  ///
  /// In pt, this message translates to:
  /// **'Backup no Google Drive'**
  String get backupGoogleDrive;

  /// No description provided for @backupSignIn.
  ///
  /// In pt, this message translates to:
  /// **'Conectar ao Google Drive'**
  String get backupSignIn;

  /// No description provided for @backupSignOut.
  ///
  /// In pt, this message translates to:
  /// **'Desconectar'**
  String get backupSignOut;

  /// No description provided for @backupCreate.
  ///
  /// In pt, this message translates to:
  /// **'Fazer Backup Agora'**
  String get backupCreate;

  /// No description provided for @backupRestore.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar Dados'**
  String get backupRestore;

  /// No description provided for @backupDelete.
  ///
  /// In pt, this message translates to:
  /// **'Eliminar Backup'**
  String get backupDelete;

  /// No description provided for @backupDeleteAll.
  ///
  /// In pt, this message translates to:
  /// **'Eliminar Todos os Dados'**
  String get backupDeleteAll;

  /// No description provided for @backupStatus.
  ///
  /// In pt, this message translates to:
  /// **'Status do Backup'**
  String get backupStatus;

  /// No description provided for @backupLastBackup.
  ///
  /// In pt, this message translates to:
  /// **'Último backup'**
  String get backupLastBackup;

  /// No description provided for @backupNoBackup.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum backup encontrado'**
  String get backupNoBackup;

  /// No description provided for @backupSignedInAs.
  ///
  /// In pt, this message translates to:
  /// **'Conectado como'**
  String get backupSignedInAs;

  /// No description provided for @backupNotSignedIn.
  ///
  /// In pt, this message translates to:
  /// **'Não conectado'**
  String get backupNotSignedIn;

  /// No description provided for @backupInProgress.
  ///
  /// In pt, this message translates to:
  /// **'Fazendo backup...'**
  String get backupInProgress;

  /// No description provided for @backupSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Backup concluído com sucesso!'**
  String get backupSuccess;

  /// No description provided for @backupFailed.
  ///
  /// In pt, this message translates to:
  /// **'Falha no backup. Tente novamente.'**
  String get backupFailed;

  /// No description provided for @backupRestoreInProgress.
  ///
  /// In pt, this message translates to:
  /// **'Restaurando dados...'**
  String get backupRestoreInProgress;

  /// No description provided for @backupRestoreSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Dados restaurados com sucesso! Reinicie o app para garantir total integridade.'**
  String get backupRestoreSuccess;

  /// No description provided for @backupRestoreFailed.
  ///
  /// In pt, this message translates to:
  /// **'Falha na restauração. Tente novamente.'**
  String get backupRestoreFailed;

  /// No description provided for @backupDeleteConfirmTitle.
  ///
  /// In pt, this message translates to:
  /// **'Eliminar Backup?'**
  String get backupDeleteConfirmTitle;

  /// No description provided for @backupDeleteConfirmBody.
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza que deseja eliminar o backup do Google Drive?'**
  String get backupDeleteConfirmBody;

  /// No description provided for @backupDeleteSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Backup eliminado do Google Drive'**
  String get backupDeleteSuccess;

  /// No description provided for @backupDeleteFailed.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao eliminar backup'**
  String get backupDeleteFailed;

  /// No description provided for @backupDeleteAllConfirmTitle.
  ///
  /// In pt, this message translates to:
  /// **'Eliminar TODOS os Dados?'**
  String get backupDeleteAllConfirmTitle;

  /// No description provided for @backupDeleteAllConfirmBody.
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza? Esta ação apagará permanentemente todos os seus pets e histórico do telemóvel e do Google Drive. Esta ação não pode ser desfeita.'**
  String get backupDeleteAllConfirmBody;

  /// No description provided for @backupDeleteAllSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Todos os dados foram eliminados'**
  String get backupDeleteAllSuccess;

  /// No description provided for @backupDeleteAllFailed.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao eliminar dados'**
  String get backupDeleteAllFailed;

  /// No description provided for @backupLoginCancelled.
  ///
  /// In pt, this message translates to:
  /// **'Login cancelado'**
  String get backupLoginCancelled;

  /// No description provided for @backupDriveFullError.
  ///
  /// In pt, this message translates to:
  /// **'Google Drive cheio. Libere espaço e tente novamente.'**
  String get backupDriveFullError;

  /// No description provided for @backupNetworkError.
  ///
  /// In pt, this message translates to:
  /// **'Sem conexão com a internet. Verifique sua rede.'**
  String get backupNetworkError;

  /// No description provided for @backupDescription.
  ///
  /// In pt, this message translates to:
  /// **'Seus dados são salvos de forma segura e privada na pasta oculta do app no seu Google Drive. Apenas você tem acesso.'**
  String get backupDescription;

  /// No description provided for @petBreedUnknown.
  ///
  /// In pt, this message translates to:
  /// **'Raça não identificada'**
  String get petBreedUnknown;

  /// No description provided for @petSRD.
  ///
  /// In pt, this message translates to:
  /// **'Sem Raça Definida (SRD)'**
  String get petSRD;

  /// No description provided for @agendaNoAttendants.
  ///
  /// In pt, this message translates to:
  /// **'Sem membros na equipe'**
  String get agendaNoAttendants;

  /// No description provided for @petAnalysisResults.
  ///
  /// In pt, this message translates to:
  /// **'Resultados Análise'**
  String get petAnalysisResults;

  /// No description provided for @petAnalysisEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma análise registrada.'**
  String get petAnalysisEmpty;

  /// No description provided for @petAnalysisDateUnknown.
  ///
  /// In pt, this message translates to:
  /// **'Data não registrada'**
  String get petAnalysisDateUnknown;

  /// No description provided for @petAnalysisProfileDate.
  ///
  /// In pt, this message translates to:
  /// **' (Data do Perfil)'**
  String get petAnalysisProfileDate;

  /// No description provided for @petAnalysisViewImage.
  ///
  /// In pt, this message translates to:
  /// **'Ver Imagem Analisada'**
  String get petAnalysisViewImage;

  /// No description provided for @commonFileNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Arquivo não encontrado no dispositivo.'**
  String get commonFileNotFound;

  /// No description provided for @petAnalysisDefaultTitle.
  ///
  /// In pt, this message translates to:
  /// **'ANÁLISE'**
  String get petAnalysisDefaultTitle;

  /// No description provided for @errorScreenTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ops! Tivemos um imprevisto.'**
  String get errorScreenTitle;

  /// No description provided for @errorScreenBody.
  ///
  /// In pt, this message translates to:
  /// **'Ocorreu um erro ao processar sua solicitação. Não se preocupe, seus dados estão seguros.'**
  String get errorScreenBody;

  /// No description provided for @errorScreenButton.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get errorScreenButton;

  /// No description provided for @errorScreenTechnicalDetails.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes técnicos:'**
  String get errorScreenTechnicalDetails;

  /// No description provided for @backupSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'💾 Backup do Banco de Dados'**
  String get backupSectionTitle;

  /// No description provided for @helpBackupRestoreSecurity.
  ///
  /// In pt, this message translates to:
  /// **'🔒 Segurança: O backup está criptografado. Para restaurar, você deve estar logado com a mesma conta que criou o arquivo.'**
  String get helpBackupRestoreSecurity;

  /// No description provided for @helpSecurityEndToEnd.
  ///
  /// In pt, this message translates to:
  /// **'Criptografia de Ponta a Ponta'**
  String get helpSecurityEndToEnd;

  /// No description provided for @helpSecurityAes.
  ///
  /// In pt, this message translates to:
  /// **'✅ Banco de Dados AES-256 (Padrão Bancário)'**
  String get helpSecurityAes;

  /// No description provided for @helpSecurityKey.
  ///
  /// In pt, this message translates to:
  /// **'✅ Chave derivada da sua senha pessoal'**
  String get helpSecurityKey;

  /// No description provided for @helpSecurityAccess.
  ///
  /// In pt, this message translates to:
  /// **'✅ Somente você (o proprietário do login) acessa os dados'**
  String get helpSecurityAccess;

  /// No description provided for @helpSecurityBackupProtection.
  ///
  /// In pt, this message translates to:
  /// **'✅ Mesma proteção aplicada aos backups exportados'**
  String get helpSecurityBackupProtection;

  /// No description provided for @backupSuccessTitle.
  ///
  /// In pt, this message translates to:
  /// **'Backup Concluído!'**
  String get backupSuccessTitle;

  /// No description provided for @backupSuccessBody.
  ///
  /// In pt, this message translates to:
  /// **'Seu arquivo de backup foi salvo com sucesso. Você pode encontrá-lo na pasta que selecionou.'**
  String get backupSuccessBody;

  /// No description provided for @backupErrorGeneric.
  ///
  /// In pt, this message translates to:
  /// **'Operação cancelada ou falha. Tente selecionar outra pasta (como Downloads) ou use Compartilhar.'**
  String get backupErrorGeneric;

  /// No description provided for @backupSecurityNotice.
  ///
  /// In pt, this message translates to:
  /// **'Os backups são criptografados com sua senha atual. Apenas o proprietário do login original pode restaurar estes dados.'**
  String get backupSecurityNotice;

  /// No description provided for @backupTechnicalErrorTitle.
  ///
  /// In pt, this message translates to:
  /// **'Erro Técnico'**
  String get backupTechnicalErrorTitle;

  /// No description provided for @backupTechnicalErrorBody.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao exportar:\n\n{error}\n\nVerifique as permissões do sistema.'**
  String backupTechnicalErrorBody(String error);

  /// No description provided for @backupExcellent.
  ///
  /// In pt, this message translates to:
  /// **'Excelente'**
  String get backupExcellent;

  /// No description provided for @backupShare.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar'**
  String get backupShare;

  /// No description provided for @backupSave.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get backupSave;

  /// No description provided for @backupImport.
  ///
  /// In pt, this message translates to:
  /// **'Importar Backup'**
  String get backupImport;

  /// No description provided for @backupLocalTitle.
  ///
  /// In pt, this message translates to:
  /// **'Backup Local'**
  String get backupLocalTitle;

  /// No description provided for @backupDescriptionText.
  ///
  /// In pt, this message translates to:
  /// **'Exporte seus dados para um arquivo ou restaure de um backup anterior. Recomendamos salvar na pasta Downloads.'**
  String get backupDescriptionText;

  /// No description provided for @backupPermissionError.
  ///
  /// In pt, this message translates to:
  /// **'Permissão de arquivos necessária para exportar.'**
  String get backupPermissionError;

  /// No description provided for @backupRestoreConfirmTitle.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar Backup?'**
  String get backupRestoreConfirmTitle;

  /// No description provided for @backupRestoreConfirmBody.
  ///
  /// In pt, this message translates to:
  /// **'Esta ação irá substituir todos os dados atuais pelos dados do arquivo. Deseja continuar?'**
  String get backupRestoreConfirmBody;

  /// No description provided for @backupRestoreError.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao importar backup. Verifique se o arquivo é válido.'**
  String get backupRestoreError;

  /// No description provided for @helpBackupExportTitle.
  ///
  /// In pt, this message translates to:
  /// **'Exportar Backup'**
  String get helpBackupExportTitle;

  /// No description provided for @helpBackupExportDesc.
  ///
  /// In pt, this message translates to:
  /// **'1. Vá em Ajustes → Backup Local\n2. Clique em \"Exportar\"\n3. Escolha a pasta \"Downloads\" e salve o arquivo .scannut\n\n✅ Seus dados ficam salvos em um arquivo seguro no seu celular'**
  String get helpBackupExportDesc;

  /// No description provided for @helpBackupImportTitle.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar Backup'**
  String get helpBackupImportTitle;

  /// No description provided for @helpBackupImportDesc.
  ///
  /// In pt, this message translates to:
  /// **'1. Vá em Ajustes → Backup Local\n2. Clique em \"Importar\"\n3. Selecione o arquivo .scannut'**
  String get helpBackupImportDesc;

  /// No description provided for @helpSecurityTitle.
  ///
  /// In pt, this message translates to:
  /// **'PROTEÇÃO E CRIPTOGRAFIA'**
  String get helpSecurityTitle;

  /// No description provided for @helpSecuritySubtitle.
  ///
  /// In pt, this message translates to:
  /// **'O banco de dados é protegido localmente. Mantenha seu backup em dia para evitar perda da chave de acesso.'**
  String get helpSecuritySubtitle;

  /// No description provided for @helpSecurityAesItem.
  ///
  /// In pt, this message translates to:
  /// **'🔒 Criptografia AES-256: Seus dados são embaralhados para garantir que ninguém consiga ler o arquivo fora deste app.'**
  String get helpSecurityAesItem;

  /// No description provided for @helpSecurityKeyItem.
  ///
  /// In pt, this message translates to:
  /// **'🔑 Chave de Segurança: O app gera uma chave única salva no armazenamento seguro do seu celular.'**
  String get helpSecurityKeyItem;

  /// No description provided for @helpSecurityWarningItem.
  ///
  /// In pt, this message translates to:
  /// **'⚠️ Atenção: Se você limpar todos os dados do sistema ou formatar o celular sem um backup externo, a chave pode ser perdida e os dados ficarão inacessíveis.'**
  String get helpSecurityWarningItem;

  /// No description provided for @helpProSection.
  ///
  /// In pt, this message translates to:
  /// **'💎 ScanNut Pro'**
  String get helpProSection;

  /// No description provided for @helpPrivacySection.
  ///
  /// In pt, this message translates to:
  /// **'🔒 Privacidade e Segurança'**
  String get helpPrivacySection;

  /// No description provided for @helpProBenefitsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Benefícios da Assinatura'**
  String get helpProBenefitsTitle;

  /// No description provided for @helpProBenefitsList.
  ///
  /// In pt, this message translates to:
  /// **'✅ Análises ilimitadas\n✅ Relatórios PDF completos\n✅ Planos alimentares personalizados\n✅ Rede de parceiros expandida\n✅ Suporte prioritário'**
  String get helpProBenefitsList;

  /// No description provided for @helpAppBarTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ajuda e Documentação'**
  String get helpAppBarTitle;

  /// No description provided for @helpPetModule.
  ///
  /// In pt, this message translates to:
  /// **'🐾 Módulo Pet'**
  String get helpPetModule;

  /// No description provided for @helpPlantModule.
  ///
  /// In pt, this message translates to:
  /// **'🌿 Módulo Plantas'**
  String get helpPlantModule;

  /// No description provided for @helpFoodModule.
  ///
  /// In pt, this message translates to:
  /// **'🍎 Módulo Alimentos'**
  String get helpFoodModule;

  /// No description provided for @helpFaqSection.
  ///
  /// In pt, this message translates to:
  /// **'❓ Perguntas Frequentes'**
  String get helpFaqSection;

  /// No description provided for @helpSupportSection.
  ///
  /// In pt, this message translates to:
  /// **'📞 Suporte'**
  String get helpSupportSection;

  /// No description provided for @helpPetBreedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Identificação de Raça'**
  String get helpPetBreedTitle;

  /// No description provided for @helpPetBreedDesc.
  ///
  /// In pt, this message translates to:
  /// **'Tire uma foto do seu pet e receba:\n• Identificação da raça\n• Perfil biológico completo\n• Recomendações de cuidados\n• Plano alimentar personalizado'**
  String get helpPetBreedDesc;

  /// No description provided for @helpPetWoundTitle.
  ///
  /// In pt, this message translates to:
  /// **'Análise de Feridas'**
  String get helpPetWoundTitle;

  /// No description provided for @helpPetWoundDesc.
  ///
  /// In pt, this message translates to:
  /// **'Triagem visual de lesões:\n• Descrição clínica detalhada\n• Possíveis causas\n• Nível de urgência (Verde/Amarelo/Vermelho)\n• Primeiros socorros\n⚠️ NÃO substitui consulta veterinária!'**
  String get helpPetWoundDesc;

  /// No description provided for @helpPetDossierTitle.
  ///
  /// In pt, this message translates to:
  /// **'Prontuário Completo'**
  String get helpPetDossierTitle;

  /// No description provided for @helpPetDossierDesc.
  ///
  /// In pt, this message translates to:
  /// **'Gerencie a saúde do seu pet:\n• Histórico de vacinas\n• Controle de peso\n• Exames laboratoriais (OCR)\n• Agenda de eventos\n• Rede de parceiros (vets, pet shops)'**
  String get helpPetDossierDesc;

  /// No description provided for @helpPlantIdTitle.
  ///
  /// In pt, this message translates to:
  /// **'Identificação Botânica'**
  String get helpPlantIdTitle;

  /// No description provided for @helpPlantIdDesc.
  ///
  /// In pt, this message translates to:
  /// **'Descubra tudo sobre plantas:\n• Nome científico e popular\n• Família botânica\n• Cuidados necessários (água, luz, solo)\n• Toxicidade para pets e crianças\n• Poderes biofílicos'**
  String get helpPlantIdDesc;

  /// No description provided for @helpFoodAnalysisTitle.
  ///
  /// In pt, this message translates to:
  /// **'Análise Nutricional'**
  String get helpFoodAnalysisTitle;

  /// No description provided for @helpFoodAnalysisDesc.
  ///
  /// In pt, this message translates to:
  /// **'Informações nutricionais instantâneas:\n• Calorias, proteínas, carboidratos, gorduras\n• Comparação com metas diárias\n• Histórico de análises\n• Planejamento semanal'**
  String get helpFoodAnalysisDesc;

  /// No description provided for @helpNeedSupportTitle.
  ///
  /// In pt, this message translates to:
  /// **'Precisa de Ajuda?'**
  String get helpNeedSupportTitle;

  /// No description provided for @helpSupportDesc.
  ///
  /// In pt, this message translates to:
  /// **'📧 Email: abreuretto72@gmail.com\n🌐 GitHub: github.com/abreuretto72/ScanNut\n📱 Versão: 1.0.0'**
  String get helpSupportDesc;

  /// No description provided for @faqOfflineQ.
  ///
  /// In pt, this message translates to:
  /// **'O app funciona offline?'**
  String get faqOfflineQ;

  /// No description provided for @faqOfflineA.
  ///
  /// In pt, this message translates to:
  /// **'Não. O ScanNut precisa de internet para enviar as fotos para a IA do Google Gemini e receber as análises.'**
  String get faqOfflineA;

  /// No description provided for @faqPhotosQ.
  ///
  /// In pt, this message translates to:
  /// **'Minhas fotos ficam salvas?'**
  String get faqPhotosQ;

  /// No description provided for @faqPhotosA.
  ///
  /// In pt, this message translates to:
  /// **'Não. As fotos são enviadas para análise e deletadas automaticamente após o processamento. Apenas os resultados são salvos no histórico.'**
  String get faqPhotosA;

  /// No description provided for @faqDevicesQ.
  ///
  /// In pt, this message translates to:
  /// **'Posso usar em vários celulares?'**
  String get faqDevicesQ;

  /// No description provided for @faqDevicesA.
  ///
  /// In pt, this message translates to:
  /// **'No momento, o ScanNut salva os dados localmente no seu dispositivo.'**
  String get faqDevicesA;

  /// No description provided for @faqWoundQ.
  ///
  /// In pt, this message translates to:
  /// **'A análise de feridas substitui o veterinário?'**
  String get faqWoundQ;

  /// No description provided for @faqWoundA.
  ///
  /// In pt, this message translates to:
  /// **'NÃO! A análise é apenas uma triagem informativa. SEMPRE consulte um veterinário para diagnóstico e tratamento.'**
  String get faqWoundA;

  /// No description provided for @privacySecurityTitle.
  ///
  /// In pt, this message translates to:
  /// **'Segurança e Proteção de Dados'**
  String get privacySecurityTitle;

  /// No description provided for @privacySecurityBody.
  ///
  /// In pt, this message translates to:
  /// **'O ScanNut prioriza a privacidade do usuário através de uma arquitetura de dados local. Utilizamos criptografia de nível militar (AES-256) para cifrar o banco de dados armazenado no seu dispositivo. As chaves de segurança são mantidas em ambiente isolado (Keystore/Keychain), garantindo que, mesmo em caso de perda do aparelho, os dados permaneçam inacessíveis sem as devidas credenciais ou chaves do sistema.\n\nO usuário está ciente de que, por não utilizarmos armazenamento em nuvem (Cloud), a manutenção e segurança dos arquivos de Backup Local exportados são de sua inteira responsabilidade.'**
  String get privacySecurityBody;

  /// No description provided for @helpMenuTitle.
  ///
  /// In pt, this message translates to:
  /// **'Cardápios e Lista de Compras'**
  String get helpMenuTitle;

  /// No description provided for @helpMenuGenTitle.
  ///
  /// In pt, this message translates to:
  /// **'🗓️ Geração de Cardápios'**
  String get helpMenuGenTitle;

  /// No description provided for @helpMenuGenDesc.
  ///
  /// In pt, this message translates to:
  /// **'No ScanNut, você tem total controle sobre como e quando seu cardápio é gerado.\n\nVocê pode escolher entre três modos de geração:\n• Cardápio semanal — para 7 dias a partir da data escolhida\n• Cardápio mensal — para 30 dias consecutivos\n• Cardápio personalizado — escolha a data de início e a data de fim (até 60 dias)\n\nSempre que você gerar um cardápio, o app mostrará um filtro para que você possa confirmar ou ajustar suas escolhas antes da geração.'**
  String get helpMenuGenDesc;

  /// No description provided for @helpMenuHistTitle.
  ///
  /// In pt, this message translates to:
  /// **'💾 Histórico de Cardápios'**
  String get helpMenuHistTitle;

  /// No description provided for @helpMenuHistDesc.
  ///
  /// In pt, this message translates to:
  /// **'Todos os cardápios gerados ficam salvos no histórico do app.\n\nIsso permite que você:\n• Consulte cardápios antigos\n• Gere novas versões sem perder as anteriores\n• Edite cardápios já criados\n• Exclua cardápios que não deseja mais manter\n\nNada é apagado automaticamente sem a sua confirmação.'**
  String get helpMenuHistDesc;

  /// No description provided for @helpMenuObjTitle.
  ///
  /// In pt, this message translates to:
  /// **'🎯 Objetivos Nutricionais'**
  String get helpMenuObjTitle;

  /// No description provided for @helpMenuObjDesc.
  ///
  /// In pt, this message translates to:
  /// **'Ao gerar um cardápio, você pode escolher o objetivo nutricional, como:\n• Manter o peso\n• Emagrecimento\n• Alimentação equilibrada\n\nO objetivo influencia a escolha dos alimentos e a distribuição das calorias.'**
  String get helpMenuObjDesc;

  /// No description provided for @helpMenuPrefTitle.
  ///
  /// In pt, this message translates to:
  /// **'🥗 Preferências Alimentares'**
  String get helpMenuPrefTitle;

  /// No description provided for @helpMenuPrefDesc.
  ///
  /// In pt, this message translates to:
  /// **'Você também pode informar preferências alimentares, como:\n• Sem glúten\n• Sem lactose\n• Vegetariano\n\nEssas opções são opcionais. Se nenhuma for selecionada, o cardápio será gerado no formato padrão.'**
  String get helpMenuPrefDesc;

  /// No description provided for @helpMenuEditTitle.
  ///
  /// In pt, this message translates to:
  /// **'✏️ Edição de Ingredientes'**
  String get helpMenuEditTitle;

  /// No description provided for @helpMenuEditDesc.
  ///
  /// In pt, this message translates to:
  /// **'Após gerar um cardápio, você pode editar os ingredientes de qualquer dia.\n\nÉ possível:\n• Ajustar ingredientes\n• Alterar quantidades\n• Adicionar ou remover itens\n\nSempre que um ingrediente é alterado, as listas de compras são atualizadas automaticamente.'**
  String get helpMenuEditDesc;

  /// No description provided for @helpMenuShopTitle.
  ///
  /// In pt, this message translates to:
  /// **'🛒 Lista de Compras Semanal'**
  String get helpMenuShopTitle;

  /// No description provided for @helpMenuShopDesc.
  ///
  /// In pt, this message translates to:
  /// **'O ScanNut gera listas de compras organizadas para facilitar sua ida ao mercado.\n\nImportante:\n• As listas de compras são sempre SEMANAIS\n• Mesmo em cardápios mensais ou personalizados\n• Os itens são consolidados (não se repetem)\n• A quantidade total a comprar é sempre exibida\n• A lista pode ser impressa em PDF com checkbox para marcar os itens'**
  String get helpMenuShopDesc;

  /// No description provided for @helpMenuPdfTitle.
  ///
  /// In pt, this message translates to:
  /// **'📄 PDF do Cardápio'**
  String get helpMenuPdfTitle;

  /// No description provided for @helpMenuPdfDesc.
  ///
  /// In pt, this message translates to:
  /// **'Ao gerar o PDF:\n• O cardápio é organizado por semanas\n• Cada semana possui sua própria lista de compras\n• Ideal para imprimir e usar no dia a dia'**
  String get helpMenuPdfDesc;

  /// No description provided for @helpMenuTipTitle.
  ///
  /// In pt, this message translates to:
  /// **'ℹ️ Dica Importante'**
  String get helpMenuTipTitle;

  /// No description provided for @helpMenuTipDesc.
  ///
  /// In pt, this message translates to:
  /// **'Sempre revise o resumo antes de gerar um cardápio.\nAssim você garante que o período, o objetivo e as preferências estão corretos.'**
  String get helpMenuTipDesc;
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
