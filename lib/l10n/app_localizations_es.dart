// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Scannut';

  @override
  String get tabFood => 'Comida';

  @override
  String get tabPlants => 'Plantas';

  @override
  String get tabPets => 'Mascotas';

  @override
  String get disclaimerTitle => 'Aviso Importante';

  @override
  String get disclaimerBody =>
      'Esta aplicación proporciona información solo con fines de detección y NO reemplaza el consejo profesional de Nutricionistas, Agrónomos o Veterinarios.';

  @override
  String get disclaimerButton => 'Entendido';

  @override
  String get emergencyCall => 'Llamar al Veterinario Cercano';

  @override
  String get cameraPermission =>
      'Se requiere permiso de cámara para usar esta función.';

  @override
  String get petNamePromptTitle => 'Nombre de la mascota';

  @override
  String get petNamePromptHint => 'Ingrese el nombre de su mascota';

  @override
  String get petNamePromptCancel => 'Cancelar';

  @override
  String get petNameEmptyError =>
      'Nombre de la mascota no proporcionado. Modo mascota cancelado.';
}
