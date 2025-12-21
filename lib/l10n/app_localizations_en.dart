// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Scannut';

  @override
  String get tabFood => 'Food';

  @override
  String get tabPlants => 'Plants';

  @override
  String get tabPets => 'Pets';

  @override
  String get disclaimerTitle => 'Important Disclaimer';

  @override
  String get disclaimerBody =>
      'This app provides information for screening purposes only and does NOT replace professional advice from Nutritionists, Agronomists, or Veterinarians.';

  @override
  String get disclaimerButton => 'I Understand';

  @override
  String get emergencyCall => 'Call Nearby Vet';

  @override
  String get cameraPermission =>
      'Camera permission is required to use this feature.';

  @override
  String get petNamePromptTitle => 'Pet Name';

  @override
  String get petNamePromptHint => 'Enter your pet\'s name';

  @override
  String get petNamePromptCancel => 'Cancel';

  @override
  String get petNameEmptyError =>
      'Pet\'s name not provided. Pet mode canceled.';
}
