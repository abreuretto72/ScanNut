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
  /// **'A permissão da câmera é necessária para usar este recurso.'**
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
  /// **'Excluir permanentemente?'**
  String get deleteAccountConfirmTitle;

  /// No description provided for @deleteAccountConfirmBody.
  ///
  /// In pt, this message translates to:
  /// **'Esta ação removerá todos os seus pets, fotos, históricos e dados do nosso sistema de forma irreversível. Deseja continuar?'**
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
  /// **'Esta análise é informativa e baseada em IA. Não substitui o diagnóstico de um médico veterinário.'**
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
