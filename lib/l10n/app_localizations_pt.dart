// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Scannut';

  @override
  String get tabFood => 'Comida';

  @override
  String get tabPlants => 'Plantas';

  @override
  String get tabPets => 'Pets';

  @override
  String get disclaimerTitle => 'Aviso Importante';

  @override
  String get disclaimerBody =>
      'Este aplicativo realiza apenas triagem informativa e NÃO substitui o conselho profissional de Nutricionistas, Agrônomos ou Veterinários.';

  @override
  String get disclaimerButton => 'Entendi';

  @override
  String get emergencyCall => 'Ligar para Veterinário Próximo';

  @override
  String get cameraPermission =>
      'A permissão da câmera é necessária para usar este recurso.';

  @override
  String get petNamePromptTitle => 'Nome do Pet';

  @override
  String get petNamePromptHint => 'Digite o nome do seu pet';

  @override
  String get petNamePromptCancel => 'Cancelar';

  @override
  String get petNameEmptyError =>
      'Nome do pet não fornecido. Pet mode cancelado.';
}
