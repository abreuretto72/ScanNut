// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get petChatTitle => 'Hablar con ScanNut AI';

  @override
  String get petChatPrompt => 'Pregunta algo sobre tu mascota...';

  @override
  String get petChatDangerousAlert => '⚠️ Alerta de Peligro';

  @override
  String get petChatSafeAlert => '✅ Información Confirmada';

  @override
  String petChatNoData(Object domain) {
    return 'Aún no tengo registros de $domain para esta mascota.';
  }

  @override
  String get petChatIdentity => 'identidad';

  @override
  String get petChatHealth => 'salud';

  @override
  String get petChatNutrition => 'nutrición';

  @override
  String get petChatTravel => 'viajes';

  @override
  String get petChatAgenda => 'agenda';

  @override
  String get petChatPlans => 'planes';

  @override
  String get appTitle => 'ScanNut';

  @override
  String get splashPoweredBy => 'Tecnología AI Vision';

  @override
  String get developed_by => 'Desenvolvido por';

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
      'Esta aplicación realiza únicamente un cribado informativo y NO sustituye el consejo profesional de Nutricionistas, Agrónomos o Veterinarios.';

  @override
  String get disclaimerButton => 'Entendido';

  @override
  String get emergencyCall => 'Llamar a Veterinario Cercano';

  @override
  String get cameraPermission =>
      'Necesitamos la cámara para analizar. Puedes activarla en los ajustes.';

  @override
  String get petNamePromptTitle => 'Nombre de la Mascota';

  @override
  String get petNamePromptHint => 'Escribe el nombre de tu mascota';

  @override
  String get petNamePromptCancel => 'Cancelar';

  @override
  String get petNameEmptyError =>
      'Nombre de la mascota no proporcionado. Modo Mascota cancelado.';

  @override
  String get petUnknown => 'Mascota Desconocida';

  @override
  String get homeHintFood => 'Apunta la cámara a la comida/plato';

  @override
  String get homeHintPlant => 'Apunta la cámara a la planta o enfermedad';

  @override
  String get homeHintPetBreed => 'Apunta la cámara a la mascota';

  @override
  String get homeHintPetHealth => 'Apunta la cámara a la herida de la mascota';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsLanguage => 'Idioma / Language';

  @override
  String get settingsProfile => 'Perfil';

  @override
  String get settingsNutrition => 'Metas Nutricionales Humanas';

  @override
  String get settingsDangerZone => 'Zona de Peligro';

  @override
  String get pdfReportTitle => 'HISTORIAL VETERINARIO COMPLETO';

  @override
  String get pdfAnaliseFezes => 'Análisis Coprológico (Heces)';

  @override
  String get pdfGeneratedOn => 'Generado el';

  @override
  String get pdfIdentitySection => 'Identidad y Perfil Biológico';

  @override
  String get pdfHealthSection => 'Salud e Historial Médico';

  @override
  String get pdfClinicalSigns => 'Evaluación de Signos Clínicos y Triaje';

  @override
  String get pdfEyes => 'Ojos';

  @override
  String get pdfTeeth => 'Dientes';

  @override
  String get pdfSkin => 'Piel/Pelaje';

  @override
  String get pdfNutritionSection => 'Nutrición y Plan Alimentario';

  @override
  String get pdfGallerySection => 'Galería y Documentos';

  @override
  String get pdfParcSection => 'Centro de Red de Apoyo';

  @override
  String get pdfDisclaimerTitle => 'AVISO LEGAL IMPORTANTE';

  @override
  String get pdfDisclaimerBody =>
      'Este informe es una herramienta de apoyo. NO sustituye las consultas veterinarias.';

  @override
  String get termScreen => 'Pantalla';

  @override
  String get termMobile => 'Móvil';

  @override
  String get termFood => 'Pienso';

  @override
  String get breedMixed => 'Raza Mixta (Mestizo)';

  @override
  String get porteSmall => 'Pequeño';

  @override
  String get porteMedium => 'Mediano';

  @override
  String get porteLarge => 'Grande';

  @override
  String get porteGiant => 'Gigante';

  @override
  String get weightStatusUnderweight => 'Bajo peso';

  @override
  String get weightStatusOverweight => 'Sobrepeso';

  @override
  String get weightStatusNormal => 'Peso Normal';

  @override
  String get weightRecUnderweight =>
      'Considere consultar al veterinario para evaluar la nutrición y salud general de la mascota.';

  @override
  String get weightRecOverweight =>
      'Programe una cita con el veterinario para ajustar la dieta y el ejercicio.';

  @override
  String get weightRecNormal =>
      '¡Siga con los cuidados actuales! Mantenga la rutina de alimentación y ejercicio.';

  @override
  String get termSeverity => 'Gravedad';

  @override
  String get termDiagnosis => 'Diagnóstico';

  @override
  String get termRecommendations => 'Recomendaciones';

  @override
  String get tabIdentity => 'IDENTIDAD';

  @override
  String get tabNutrition => 'NUTRICIÓN';

  @override
  String get tabGrooming => 'ESTÉTICA';

  @override
  String get tabHealth => 'SALUD';

  @override
  String get tabLifestyle => 'ESTILO DE VIDA';

  @override
  String get emptyPastWeek => 'Sin historial reciente.';

  @override
  String get emptyCurrentWeek => 'Sin menú para esta semana.';

  @override
  String get emptyNextWeek => 'Sin planificación futura.';

  @override
  String get tabPastWeek => 'Semana Pasada';

  @override
  String get tabCurrentWeek => 'Semana Actual';

  @override
  String get tabNextWeek => 'Próxima Semana';

  @override
  String get menuPlanTitle => 'Planificar Menú Inteligente';

  @override
  String get menuPeriod => 'Período del Menú';

  @override
  String get dietType => 'Régimen Alimentario';

  @override
  String get dietNatural => 'Comida Natural';

  @override
  String get dietKibble => 'Pienso Comercial';

  @override
  String get dietHybrid => 'Modo Híbrido Activado';

  @override
  String get nutritionalGoal => 'Meta Nutricional';

  @override
  String get generateMenu => 'Generar Menú';

  @override
  String get selectDates => 'Seleccionar Fechas';

  @override
  String get cancel => 'Cancelar';

  @override
  String get commonBack => 'Volver';

  @override
  String get permissionCameraDisclosureTitle => 'Uso de la Cámara';

  @override
  String get permissionCameraDisclosureBody =>
      'ScanNut necesita acceder a su cámara para analizar la salud de la piel, pelaje y ojos de su mascota, además de registrar documentos veterinarios.';

  @override
  String get permissionMicrophoneDisclosureTitle => 'Uso del Micrófono';

  @override
  String get permissionMicrophoneDisclosureBody =>
      'ScanNut solicita acceso al micrófono para permitirle tomar notas de voz sobre las observaciones de su mascota.';

  @override
  String get continueButton => 'Continuar';

  @override
  String get deleteAccount => 'Eliminar Cuenta y Datos';

  @override
  String get deleteAccountConfirmTitle => '¿Eliminar todo?';

  @override
  String get deleteAccountConfirmBody =>
      'Esto eliminará permanentemente todos sus menús e historial.';

  @override
  String get deleteAccountButton => 'Eliminar Todo';

  @override
  String get privacyPolicy => 'Política de Privacidad';

  @override
  String get aiDisclaimer =>
      'Este análisis es informativo y se basa en el procesamiento automático. Consulte siempre al veterinario vinculado en la pestaña Socios para obtener un diagnóstico preciso.';

  @override
  String get onboardingTitle1 => 'Transforme su Nutrición';

  @override
  String get onboardingBody1 =>
      'Utilice nuestra IA para analizar alimentos en segundos. Descubra calorías, macronutrientes y reciba consejos de biohacking y recetas rápidas para su alto rendimiento.';

  @override
  String get onboardingTitle2 => 'Domine su Ecosistema';

  @override
  String get onboardingBody2 =>
      'Identifique plantas, diagnostique enfermedades y aprenda sobre propagación. Sepa al instante si una planta es segura para humanos con nuestro Semáforo de Supervivencia.';

  @override
  String get onboardingTitle3 => 'El Historial Clínico Definitivo';

  @override
  String get onboardingBody3 =>
      'Siga la salud de su mascota con análisis de piel por IA, historial de vacunas y análisis de laboratorio explicados. Todo listo para exportar en PDF.';

  @override
  String get onboardingTitle4 => 'Sus datos son suyos';

  @override
  String get onboardingBody4 =>
      'En ScanNut, su privacidad es prioridad. Todos sus registros se guardan localmente en su móvil (Hive) e no en nubes externas.';

  @override
  String get onboardingAcceptTerms =>
      'He leído y acepto los Términos de Uso y Política de Privacidad de Multiverso Digital';

  @override
  String get onboardingGetStarted => 'Empezar';

  @override
  String get error_image_already_analyzed =>
      'Esta imagen ya ha sido analizada recientemente.';

  @override
  String get analysisErrorAiFailure =>
      'Todas las IAs fallaron al analizar la imagen.';

  @override
  String get analysisErrorJsonFormat => 'Error al procesar datos de la IA.';

  @override
  String get analysisErrorUnexpected => 'Error inesperado. Inténtelo de nuevo.';

  @override
  String get analysisErrorInvalidCategory =>
      '¡La foto difiere de la categoría. La IA puede fallar!';

  @override
  String get analysisErrorNotDetected =>
      'No se detectaron cambios o problemas en la imagen.';

  @override
  String get errorNoInternet => 'Sin conexión a internet. Verifique su red.';

  @override
  String get errorTimeout => 'La operación tardó demasiado. Inténtelo de novo.';

  @override
  String get errorAuthentication =>
      'Error de autenticación. Verifique sus credenciais.';

  @override
  String get errorNotFound => 'Recurso no encontrado. Inténtelo de novo.';

  @override
  String get errorServer =>
      'Error en el servidor. Inténtelo de novo en unos momentos.';

  @override
  String get errorImageTooLarge =>
      'Imagen demasiado grande. Intente con una foto más pequeña.';

  @override
  String get errorInvalidImage => 'Imagen inválida. Tome una nueva foto.';

  @override
  String get errorConfiguration =>
      'Error de configuración. Contacte con soporte.';

  @override
  String get errorPermissionDenied =>
      'Permiso denegado. Verifique la configuración.';

  @override
  String get errorNoStorage => 'Espacio insuficiente en el dispositivo.';

  @override
  String get errorCamera => 'Error al acceder a la cámara.';

  @override
  String get errorLocation => 'Error al acceder a la ubicación.';

  @override
  String get errorDatabase => 'Error al guardar datos localmente.';

  @override
  String get errorJsonParse => 'Error al procesar la respuesta de la IA.';

  @override
  String get errorIncompleteData => 'Datos incompletos recibidos.';

  @override
  String get errorGeneric =>
      '¡Ups! Algo salió mal. Sus datos están seguros. Inténtelo de novo.';

  @override
  String get loadingFood => 'Analizando alimento...';

  @override
  String get loadingPlant => 'Diagnosticando planta...';

  @override
  String get loadingPetBreed => 'Identificando raza...';

  @override
  String get loadingPetHealth => 'Analizando salud...';

  @override
  String get nutrientsAdvancedMacros => 'Macronutrientes Avanzados';

  @override
  String get nutrientsProteins => 'Proteínas';

  @override
  String get nutrientsCarbs => 'Carbohidratos';

  @override
  String get nutrientsFats => 'Grasas';

  @override
  String get nutrientsMinerals => 'Minerales y Vitaminas';

  @override
  String get nutrientsSynergy => 'Sinergia';

  @override
  String get recipesQuick => 'Recetas Rápidas (menos de 15 min)';

  @override
  String get recipesCulinaryIntel => 'Inteligencia Culinaria';

  @override
  String get recipesExpertTip => 'Consejo del Experto';

  @override
  String get labelGlycemicImpact => 'Impacto Glucémico';

  @override
  String get labelFattyAcids => 'Ácidos Grasos';

  @override
  String get labelAminoProfile => 'Perfil de Aminoácidos';

  @override
  String get foodSafetyBio => 'Seguridad y Bioquímica';

  @override
  String get foodIdealMoment => 'Momento Ideal';

  @override
  String get foodCriticalAlerts => 'Alertas Críticas';

  @override
  String get foodBioChem => 'Bioquímica y Neutralización';

  @override
  String get foodPreservation => 'Preservación';

  @override
  String get foodSmartSwap => 'Cambio Inteligente (Smart Swap)';

  @override
  String get foodDisclaimer =>
      'Nota: La información nutricional es estimada. Consulte siempre a un profesional de salud.';

  @override
  String get foodVerdict => 'Veredicto de la IA';

  @override
  String get foodPros => 'Puntos Positivos';

  @override
  String get foodCons => 'Puntos de Atención';

  @override
  String get foodBiohacking => 'Rendimiento Biohacking';

  @override
  String get foodSatietyIndex => 'Índice de Saciedad';

  @override
  String get foodBodyBenefits => 'Beneficios para el Cuerpo';

  @override
  String get foodAttention => 'Atención';

  @override
  String get foodFocusEnergy => 'Foco y Energía';

  @override
  String get paywallTitle => 'Desbloquee el Poder Total';

  @override
  String get paywallSubtitle =>
      'Obtenga acceso ilimitado a todas las herramientas de IA y análisis detallados.';

  @override
  String get paywallSubscribeButton => 'Suscribirse Ahora';

  @override
  String get paywallSelectPlan => 'Seleccione un plan';

  @override
  String get paywallRestore => 'Restaurar Compras';

  @override
  String get paywallTerms => 'Términos';

  @override
  String get paywallMonthly => 'Mensual';

  @override
  String get paywallYearly => 'Anual';

  @override
  String get paywallBestValue => 'MEJOR VALOR';

  @override
  String get paywallSuccess =>
      '¡Suscripción activada con éxito! ¡Bienvenido a Pro! 🚀';

  @override
  String get paywallError => 'La compra no se completó. Inténtelo de nuevo.';

  @override
  String get paywallRestoreSuccess => '¡Compras restauradas con éxito!';

  @override
  String get paywallRestoreFail =>
      'No se encontró ninguna suscripción activa para restaurar.';

  @override
  String get paywallLoadingOfferings =>
      'No se han podido cargar las ofertas en este momento.';

  @override
  String get drawerProTitle => 'ScanNut Pro';

  @override
  String get drawerProSubtitle => 'Desbloquear todo';

  @override
  String get settingsNameLabel => 'Nombre';

  @override
  String get settingsNameHint => '¿Cómo le gustaría ser llamado?';

  @override
  String get settingsWeightUnit => 'Unidad de Peso';

  @override
  String get settingsKg => 'Kilogramos (kg)';

  @override
  String get settingsLbs => 'Libras (lbs)';

  @override
  String get settingsPreferences => 'Preferencias';

  @override
  String get settingsShowTips => 'Mostrar Consejos';

  @override
  String get settingsShowTipsSubtitle =>
      'Mostrar consejos nutricionales en análisis';

  @override
  String get settingsPartnerManagement => 'Gestión de Socios';

  @override
  String get settingsSearchRadius => 'Radio de Búsqueda Estándar';

  @override
  String get settingsSearchRadiusSubtitle =>
      'Sugiere socios cercanos a su mascota según este límite.';

  @override
  String get settingsSystemMaintenance => 'Mantenimiento del Sistema';

  @override
  String get settingsBackupOptimize => 'Generar Copia y Optimizar';

  @override
  String get settingsBackupOptimizeSubtitle =>
      'Genera PDF completo y libera espacio.';

  @override
  String get settingsDeletePets => 'Borrar Historial de Mascotas';

  @override
  String get settingsDeletePetsSubtitle =>
      'Borrar todas las mascotas permanentemente.';

  @override
  String get settingsDeletePlants => 'Borrar Historial de Plantas';

  @override
  String get settingsDeletePlantsSubtitle =>
      'Borrar todas las plantas permanentemente.';

  @override
  String get settingsDeleteFood => 'Borrar Historial de Alimentos';

  @override
  String get settingsDeleteFoodSubtitle =>
      'Borrar todos los alimentos permanentemente.';

  @override
  String get settingsClearPartners => 'Borrar Red de Apoyo';

  @override
  String get settingsClearPartnersSubtitle =>
      'Eliminar todos los socios permanentemente.';

  @override
  String get partnersTitle => 'Futuros Socios';

  @override
  String get partnersSubtitle => 'Socios registrados en el ecosistema';

  @override
  String get partnersFilterAll => 'Todos';

  @override
  String get partnersFilterVet => 'Veterinaria';

  @override
  String get partnersFilterPetShop => 'PetShop';

  @override
  String get partnersFilterPharmacy => 'Farmacia';

  @override
  String get partnersFilterHotel => 'Hotel/Guardería';

  @override
  String get partnersFilterGrooming => 'Estética';

  @override
  String get partnersFilterLab => 'Laboratorio';

  @override
  String get partnersFilterDogWalker => 'Paseador de Perros';

  @override
  String get catHeaderHealth => '🏥 SALUD Y BIENESTAR';

  @override
  String get catVet => 'Veterinario General';

  @override
  String get catVetEmergency => 'Veterinario de Urgencia (24h)';

  @override
  String get catVetSpecialist => 'Especialista (Cardio/Urgencias)';

  @override
  String get catPhysio => 'Fisioterapia/Rehabilitación';

  @override
  String get catHomeo => 'Homeopatía/Acupuntura';

  @override
  String get catNutri => 'Nutricionista Veterinario';

  @override
  String get catAnest => 'Anestesiólogo';

  @override
  String get catOnco => 'Oncólogo';

  @override
  String get catDentist => 'Dentista Veterinario';

  @override
  String get catHeaderDaily => '🛏️ CUIDADOS DIARIOS Y HOTELES';

  @override
  String get catSitter => 'Pet Sitter';

  @override
  String get catWalker => 'Paseador de Perros';

  @override
  String get catNanny => 'Niñera de Mascotas';

  @override
  String get catHotel => 'Hotel/Alojamiento';

  @override
  String get catDaycare => 'Guardería';

  @override
  String get catHeaderGrooming => '🧼 ESTÉTICA Y ASEO';

  @override
  String get catBath => 'Baño y Peluquería';

  @override
  String get catStylist => 'Estilista de Mascotas';

  @override
  String get catGroomerBreed => 'Especialista en Razas';

  @override
  String get catHeaderTraining => '🦮 COMPORTAMIENTO Y ENTRENAMIENTO';

  @override
  String get catTrainer => 'Adiestrador';

  @override
  String get catBehaviorist => 'Etólogo/Comportamiento';

  @override
  String get catCatSultant => 'Consultor Felino';

  @override
  String get catHeaderRetail => '🛒 TIENDAS Y SERVICIOS';

  @override
  String get catPetShop => 'Tienda de Mascotas';

  @override
  String get catSupplies => 'Alimentos y Accesorios';

  @override
  String get catTransport => 'Taxi de Mascotas';

  @override
  String get catPharm => 'Farmacia Veterinaria';

  @override
  String get catHeaderOther => '🧬 OTROS';

  @override
  String get catNgo => 'ONG / Refugio';

  @override
  String get catBreeder => 'Criador';

  @override
  String get catLab => 'Laboratorio';

  @override
  String get catInsurance => 'Seguro de Mascotas';

  @override
  String get catFuneralPlan => 'Plan de Asist. Funeraria';

  @override
  String get catCemeterie => 'Cementerio de Mascotas';

  @override
  String get catCremation => 'Crematorio';

  @override
  String get catFuneral => 'Servicios Funerarios y Velatorio';

  @override
  String get deletePetTitle => 'Eliminar Mascota';

  @override
  String get deletePetConfirmation =>
      '¿Está seguro de que desea eliminar permanentemente esta mascota? Esta acción no se puede deshacer.';

  @override
  String get deletePlantTitle => 'Eliminar Planta';

  @override
  String get deletePlantConfirm =>
      '¿Está seguro de que desea eliminar esta planta? Esta acción no se puede deshacer.';

  @override
  String get delete => 'Excluir';

  @override
  String get petActivityLow => 'Bajo';

  @override
  String get petActivityHigh => 'Alto';

  @override
  String get petActivityAthlete => 'Atleta';

  @override
  String get petBathWeekly => 'Semanal';

  @override
  String get petBathMonthly => 'Mensual';

  @override
  String get petNotOffice => 'Tipo de dieta no especificado';

  @override
  String get whatsappInitialMessage =>
      '¡Hola! Vi su perfil en ScanNut y me gustaría más información.';

  @override
  String get settingsResetDefaults => 'Restaurar Valores';

  @override
  String get settingsResetDialogTitle => 'Restaurar Valores';

  @override
  String get settingsResetDialogContent =>
      '¿Seguro que desea restaurar toda la configuración?';

  @override
  String get settingsResetSuccess => 'Configuración restaurada';

  @override
  String get settingsAutoSaveInfo =>
      'Su configuración se guarda automáticamente';

  @override
  String get settingsConfirmDeleteTitle => 'Confirmar Eliminación';

  @override
  String settingsConfirmDeleteContent(Object itemType) {
    return '¿Seguro que desea borrar todo el historial de $itemType? Esta acción es irreversible.';
  }

  @override
  String settingsDeleteSuccess(Object itemType) {
    return 'Historial de $itemType borrado con éxito.';
  }

  @override
  String get modePetIdentification => 'Raza e ID';

  @override
  String get modePetHealth => 'Salud';

  @override
  String get instructionPetBody => 'Apunte cámara al cuerpo completo';

  @override
  String get instructionPetWound => 'Apunte cámara a la herida';

  @override
  String get tooltipNutritionHistory => 'Historial Nutrición';

  @override
  String get tooltipNutritionManagement => 'Gestión Nutrición';

  @override
  String get tooltipBotanyHistory => 'Historial Botánica';

  @override
  String get exitDialogTitle => 'Salir de la App';

  @override
  String get exitDialogContent => '¿Realmente desea salir?';

  @override
  String get exit => 'Salir';

  @override
  String get redirectShop => 'Redirigiendo a tienda...';

  @override
  String get cameraError => 'Error al iniciar cámara: ';

  @override
  String petSavedSuccess(Object petName) {
    return '¡Expediente de $petName guardado!';
  }

  @override
  String savedSuccess(Object type) {
    return '$type guardado en boxes!';
  }

  @override
  String get errorPetNameNotFound => 'Error: Nombre no encontrado.';

  @override
  String healthAnalysisSaved(String petName) {
    return '¡Análisis de salud de $petName guardado con éxito!';
  }

  @override
  String errorSavingAnalysis(String error) {
    return 'Error al guardar análisis: $error';
  }

  @override
  String get errorNavigationPrefix => 'Error de Navegación: ';

  @override
  String get error_image_not_found =>
      'Imagen no encontrada. Asegúrese de que la foto se capturó correctamente.';

  @override
  String get errorSaveHiveTitle => 'Error al Guardar';

  @override
  String errorSaveHiveBody(String error) {
    return 'Ocurrió un error al persistir los datos en la base de datos local: $error';
  }

  @override
  String get menuHello => '¡Hola!';

  @override
  String menuHelloUser(Object userName) {
    return '¡Hola, $userName!';
  }

  @override
  String get menuAiAssistant => 'Asistente IA ScanNut';

  @override
  String get menuSettings => 'Configuración';

  @override
  String menuSettingsSubtitle(Object calories) {
    return 'Meta diaria: $calories kcal';
  }

  @override
  String get menuNutritionalPillars => 'Pilares Nutricionales';

  @override
  String get menuNutritionalPillarsSubtitle => 'Conceptos de ScanNut';

  @override
  String get menuEnergyBalance => 'Balance Energético';

  @override
  String get menuEnergyBalanceSubtitle => 'Panel Fitness & Biohacking';

  @override
  String get menuNutritionHistory => 'Historial Nutrición';

  @override
  String get menuNutritionHistorySubtitle => 'Análisis de Alimentos';

  @override
  String get menuBotanyHistory => 'Historial Botánico';

  @override
  String get menuBotanyHistorySubtitle => 'Salud y Guía de Cultivo';

  @override
  String get menuPetHistory => 'Historial de Mascotas';

  @override
  String get menuPetHistorySubtitle => 'Expedientes y Exámenes';

  @override
  String get menuHelp => 'Ayuda';

  @override
  String get menuHelpSubtitle => 'Cómo usar la app';

  @override
  String get menuAbout => 'Acerca de';

  @override
  String get menuPrivacySubtitle => 'Consultar términos y datos';

  @override
  String get menuDeleteAccountSubtitle => 'Eliminar todos los registros';

  @override
  String get menuExit => 'Salir';

  @override
  String get menuExitSubtitle => 'Cerrar la aplicación';

  @override
  String get logoutTitle => 'Cerrar sesión y desconectar';

  @override
  String get logoutSubtitle => 'Finalizar sesión en ScanNut';

  @override
  String get contactSubject => 'Contacto ScanNut';

  @override
  String get helpWelcomeTitle => '¡Bienvenido a ScanNut!';

  @override
  String get helpWelcomeSubtitle =>
      'Su asistente visual de IA para alimentos, plantas y mascotas';

  @override
  String get helpDisclaimerTitle => '⚠️ AVISO IMPORTANTE';

  @override
  String get helpDisclaimerBody =>
      'La Inteligencia Artificial puede cometer errores en el análisis de imágenes. ScanNut NO se responsabiliza por la información generada por la IA.\n\n• Los análisis son solo ORIENTATIVAS\n• NO sustituyen a profesionales cualificados\n• Consulte siempre a veterinarios, nutricionistas o botánicos\n• Use la app como herramienta de apoyo, no como diagnóstico final';

  @override
  String get helpFooter =>
      'Desarrollado con ❤️ por Abreu Retto\n© 2026 ScanNut';

  @override
  String get footerDevelopedBy => 'Desarrollado por Abreu Retto';

  @override
  String get footerMadeWith => 'Hecho con ❤️ usando Gemini AI';

  @override
  String get aboutTitle => 'Acerca de ScanNut';

  @override
  String get aboutSubtitle => 'ScanNut IA Visual Assistant';

  @override
  String get aboutPoweredBy => 'Powered by Google Gemini 2.5 Flash';

  @override
  String get aboutDescription =>
      'Análisis inteligente de:\n• Alimentos 🍎\n• Plantas 🌿\n• Mascotas 🐾';

  @override
  String get nutritionGuideTitle => 'Guía Nutrición Animal ScanNut';

  @override
  String get nutritionIntro =>
      'A diferencia de los humanos, perros y gatos tienen metabolismo acelerado y requisitos nutricionales únicos. ScanNut usa IA para equilibrar estos 5 pilares vitales para la longevidad de su mascota.';

  @override
  String get ngProteinTitle => 'Proteína Animal';

  @override
  String get ngProteinSubtitle => 'La Fuerza de la Mascota';

  @override
  String get ngProteinWhatIs =>
      'Las mascotas son carnívoras. Necesitan aminoácidos específicos encontrados en la carne que sus cuerpos no producen.';

  @override
  String get ngProteinAction =>
      'Priorizamos fuentes como pollo, res, pescado, huevos o proteínas seleccionadas en piensos premium.';

  @override
  String get ngFatsTitle => 'Grasas Específicas';

  @override
  String get ngFatsSubtitle => 'La Protección';

  @override
  String get ngFatsWhatIs =>
      'Más allá de energía, la grasa correcta previene dermatitis y asegura absorción de vitaminas A, D, E y K. El Omega 3 es el mayor aliado contra inflamaciones.';

  @override
  String get ngFatsAction =>
      'Sugerimos equilibrar Omegas 3 y 6, de aceites de pescado o grasas buenas.';

  @override
  String get ngCarbsTitle => 'Fibras y Carbohidratos';

  @override
  String get ngCarbsSubtitle => 'El Intestino';

  @override
  String get ngCarbsWhatIs =>
      'El sistema digestivo es más corto. Usamos carbohidratos de fácil digestión (como camote o arroz) y fibras para la formación correcta de heces.';

  @override
  String get ngCarbsAction =>
      'Sugerimos vegetales como calabaza y zanahoria, y granos como arroz integral o avena.';

  @override
  String get ngVitaminsTitle => 'Minerales y Vitaminas';

  @override
  String get ngVitaminsSubtitle => 'Cuidado con la Dosis';

  @override
  String get ngVitaminsWhatIs =>
      'Crucial: El exceso de calcio daña cachorros y la falta debilita ancianos. ScanNut se enfoca en el equilibrio mineral exacto para huesos caninos y felinos.';

  @override
  String get ngVitaminsAction =>
      'La app señala necesidad de suplementación, especialmente en dietas Naturales, para evitar carencias.';

  @override
  String get ngHydrationTitle => 'Hidratación Biológica';

  @override
  String get ngHydrationSubtitle => 'El Punto Débil';

  @override
  String get ngHydrationWhatIs =>
      'Muchas mascotas no sienten sed proporcional a su necesidad. Fomentamos alimentos húmedos para evitar cálculos renales, mayor causa de muerte en gatos y perros viejos.';

  @override
  String get ngHydrationAction =>
      'Sugerimos alimentos húmedos, caldos o añadir agua al pienso para proteger riñones.';

  @override
  String get ngWarningTitle => 'ATENCIÓN:';

  @override
  String get ngWarningText =>
      'Nunca ofrezca alimentos prohibidos (como chocolate, uvas, cebolla y xilitol). Las sugerencias de ScanNut respetan estas restricciones.';

  @override
  String get ngSectionWhatIs => 'Qué es:';

  @override
  String get ngSectionScanNut => 'En ScanNut:';

  @override
  String get fitnessDashboardTitle => 'Panel Fitness';

  @override
  String get fitnessBalanceKcal => 'Saldo kcal';

  @override
  String fitnessMetaDaily(Object goal) {
    return 'Meta diaria: $goal kcal';
  }

  @override
  String get fitnessConsumed => 'Consumido';

  @override
  String get fitnessBurned => 'Quemado';

  @override
  String get fitnessPerformance => 'Rendimiento Biohacking';

  @override
  String get fitnessTip =>
      'Consejo: Entrene en ayunas hoy para optimizar quema de grasa según su último consumo de carbohidratos.';

  @override
  String get fitnessAddWorkout => 'Añadir Entreno';

  @override
  String get fitnessRegWorkout => 'Registrar Entreno';

  @override
  String get fitnessExerciseHint => 'Ejercicio (ej: Correr)';

  @override
  String get fitnessCaloriesHint => 'Calorías Quemadas';

  @override
  String get fitnessDurationHint => 'Duración (min)';

  @override
  String get botanyTitle => 'Inteligencia Botánica';

  @override
  String get botanyEmpty => 'Ninguna planta analizada aún.';

  @override
  String get botanyStatus => 'ESTADO';

  @override
  String get botanyToxicHuman => 'TÓXICA para humanos';

  @override
  String get botanyDangerousPet => 'PELIGROSA para mascotas';

  @override
  String get botanyRecovery => 'Recuperación';

  @override
  String get botanyRecoveryPlan => 'Plan de Recuperación';

  @override
  String get botanyFengShui => 'Feng Shui y Simbolismo';

  @override
  String botanyDossierTitle(String plantName) {
    return 'Expediente Botánico: $plantName';
  }

  @override
  String get petHistoryTitle => 'Mis Mascotas Guardadas';

  @override
  String get petHistoryEmpty => 'Ninguna mascota guardada aún.';

  @override
  String get petBreed => 'N/A';

  @override
  String get petLinkPartnerError =>
      'Vincule un socio en la pestaña \"Socios\" para acceder a la agenda';

  @override
  String get petNoRecentMenu => 'La mascota aún no tiene un menú generado';

  @override
  String get petEditSaved => 'Cambios guardados.';

  @override
  String get petVisualDescription => 'Descripción Visual';

  @override
  String get petPossibleCauses => 'Causas Probables';

  @override
  String get petSpecialistOrientation => 'Orientación del Especialista';

  @override
  String get foodHistoryTitle => 'Historial de Alimentos';

  @override
  String get foodHistoryEmpty => 'Ningún análisis guardado aún.';

  @override
  String get foodReload => 'Recargar';

  @override
  String get foodKcalPer100g => 'kcal / 100g';

  @override
  String get foodProt => 'Prot.';

  @override
  String get foodCarb => 'Carb.';

  @override
  String get foodFat => 'Grasa';

  @override
  String get foodDeleteConfirmTitle => '¿Eliminar Análisis?';

  @override
  String get foodDeleteConfirmContent => 'Esta acción no se puede deshacer.';

  @override
  String get commonUnderstand => 'Entendido';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonYes => 'Sí';

  @override
  String get commonNo => 'No';

  @override
  String get linkError => 'No se pudo abrir el enlace.';

  @override
  String get helpTitle => 'Ayuda y Soporte';

  @override
  String get helpCommonQuestions => 'Preguntas Frecuentes';

  @override
  String get helpContactUs => 'Contáctenos';

  @override
  String get helpTutorials => 'Video Tutoriales';

  @override
  String get helpAppVersion => 'Versión de la Aplicación';

  @override
  String get helpUserGuide => 'Guía del Usuario';

  @override
  String get helpTermsPrivacy => 'Términos y Privacidad';

  @override
  String get guideVitalsTitle => 'SECCIONES DEL PERFIL';

  @override
  String get guideIdentity => 'Identidad';

  @override
  String get guideIdentityDesc =>
      'Gestione datos vitales: peso, raza, edad y análisis conductual genético completo.';

  @override
  String get guideHealth => 'Salud';

  @override
  String get guideHealthDesc =>
      'Historial médico completo con control de vacunas, desparasitación, exámenes y recordatorios.';

  @override
  String get guideNutrition => 'Nutrición';

  @override
  String get guideNutritionDesc =>
      'Planificación semanal detallada con cálculos de Kcal, fechas y los 5 pilares nutricionales.';

  @override
  String get guideGallery => 'Galería';

  @override
  String get guideGalleryDesc =>
      'Documente visualmente la evolución y momentos especiales de su mascota con fotos y videos.';

  @override
  String get guidePrac => 'Prac';

  @override
  String get guidePracDesc =>
      'Registro de Seguimiento Conductual para rutinas, cambios de hábito y red de apoyo.';

  @override
  String get guideObservationsTitle => 'OBSERVACIONES E HISTORIAL';

  @override
  String get guideHistory => 'Historial Acumulativo';

  @override
  String get guideHistoryDesc =>
      'Cada sección tiene un campo de observaciones. Las nuevas notas NO borran las antiguas - ¡todo queda registrado!';

  @override
  String get guideTimestamps => 'Marcas de Tiempo Automáticas';

  @override
  String get guideTimestampsDesc =>
      'El sistema inserta automáticamente Fecha y Hora en cada entrada, creando un historial cronológico completo.';

  @override
  String get guideOrder => 'Orden Inteligente';

  @override
  String get guideOrderDesc =>
      'La entrada más reciente siempre aparece arriba, facilitando la lectura y seguimiento.';

  @override
  String get guideVoice => 'Dictado por Voz';

  @override
  String get guideVoiceDesc =>
      'Use el ícono del micrófono para dictar notas en lugar de escribir. ¡Más rápido y práctico!';

  @override
  String get guideExportTitle => 'EXPORTACIÓN EN PDF';

  @override
  String get guidePdfTitle => 'Registro Veterinario Completo';

  @override
  String get guidePdfDesc =>
      'Generado automáticamente con TODA la información (Perfil + Salud + Nutrición + Observaciones). ¡Ideal para llevar al veterinario!';

  @override
  String get guideBotanyTitle => 'ANÁLISIS DE PLANTAS';

  @override
  String get guideBotanyLeaf => 'Icono de Hoja (Verde)';

  @override
  String get guideBotanyLeafDesc =>
      'Indica que la planta está SALUDABLE. No se necesita intervención urgente.';

  @override
  String get guideBotanyAlert => 'Icono de Alerta (Amarillo/Naranja)';

  @override
  String get guideBotanyAlertDesc =>
      'La planta necesita ATENCIÓN. Puede tener deficiencias nutricionales o estrés hídrico.';

  @override
  String get guideBotanyCritical => 'Icono de Emergencia (Rojo)';

  @override
  String get guideBotanyCriticalDesc =>
      'Estado CRÍTICO. La planta necesita tratamiento inmediato para sobrevivir.';

  @override
  String get guideBotanyTraffic => 'Semáforo de Supervivencia';

  @override
  String get guideBotanyTrafficDesc =>
      'Verde = Ideal | Amarillo = Atención | Rojo = Urgente. Aparece en las tarjetas de historial.';

  @override
  String get guideFinalTip =>
      '¡ScanNut es una herramienta a largo plazo para acompañar toda la vida de su mascota!';

  @override
  String get tabSummary => 'RESUMEN';

  @override
  String get tabNutrients => 'NUTRIENTES';

  @override
  String get tabGastronomy => 'GASTRONOMÍA';

  @override
  String get labelTrafficLight => 'Semáforo';

  @override
  String get tabHardware => 'Hardware';

  @override
  String get tabBios => 'Bios';

  @override
  String get tabPropagation => 'Propagação';

  @override
  String get cardTapForRecipes => 'Toca para ver recetas ✨';

  @override
  String get cardScore => 'Puntuación';

  @override
  String get cardTabOverview => 'Visión General';

  @override
  String get cardTabDetails => 'Detalles';

  @override
  String get cardTabTips => 'Consejos';

  @override
  String get cardTotalCalories => 'Calorías Totales';

  @override
  String get cardDailyGoal => 'de la meta diaria';

  @override
  String get cardMacroDist => 'Distribución de Macronutrientes';

  @override
  String get cardQuickSummary => 'Resumen Rápido';

  @override
  String get cardBenefits => 'Beneficios';

  @override
  String get cardAlerts => 'Alertas';

  @override
  String get cardVitalityScore => 'Puntuación de Vitalidad';

  @override
  String get cardDetailedInfo => 'Información Detallada';

  @override
  String get cardDisclaimer =>
      'Nota: Este es un análisis de IA y no reemplaza el diagnóstico de un nutricionista.';

  @override
  String get pdfFoodTitle => 'Informe Nutricional y Biohacking';

  @override
  String get pdfDate => 'Fecha';

  @override
  String get pdfCalories => 'Calorías';

  @override
  String get pdfTrafficLight => 'Semáforo';

  @override
  String get pdfProcessing => 'Procesamiento';

  @override
  String get pdfExSummary => 'Resumen Ejecutivo';

  @override
  String get pdfAiVerdict => 'Veredicto de IA';

  @override
  String get pdfPros => 'Puntos Positivos';

  @override
  String get pdfCons => 'Puntos de Atención';

  @override
  String get pdfDetailedNutrition => 'Nutrición Detallada';

  @override
  String get pdfMacros => 'Macronutrientes';

  @override
  String get pdfNutrient => 'Nutriente';

  @override
  String get pdfQuantity => 'Cantidad';

  @override
  String get pdfDetails => 'Detalles';

  @override
  String get pdfMicros => 'Micronutrientes y Vitaminas';

  @override
  String get pdfSynergy => 'Sinergia Nutricional';

  @override
  String get pdfBiohacking => 'Biohacking y Salud';

  @override
  String get pdfPerformance => 'Rendimiento';

  @override
  String get pdfSatiety => 'Índice de Saciedad';

  @override
  String get pdfFocus => 'Enfoque y Energía';

  @override
  String get pdfIdealMoment => 'Momento Ideal';

  @override
  String get pdfSecurity => 'Seguridad';

  @override
  String get pdfAlerts => 'Alertas';

  @override
  String get pdfBiochem => 'Bioquímica';

  @override
  String get pdfGastronomy => 'Gastronomía y Consejos';

  @override
  String get pdfQuickRecipes => 'Recetas Rápidas';

  @override
  String pdfGeneratedBy(Object date, Object owner) {
    return 'Generado el $date por $owner';
  }

  @override
  String pdfPage(Object current, Object total) {
    return 'Página $current de $total';
  }

  @override
  String get pdfEstablishment => 'Establecimiento';

  @override
  String get pdfFieldCategory => 'Categoría';

  @override
  String get pdfPhone => 'Teléfono';

  @override
  String get pdfRating => 'Calificación';

  @override
  String get pdfStars => 'Estrellas';

  @override
  String get pdfStatus => 'Estado';

  @override
  String get pdfTotalFound => 'Total Encontrados';

  @override
  String get pdfRegion => 'Región';

  @override
  String get pdfPartnersGuide => 'Guía de Socios';

  @override
  String get distanceLabel => 'Distância';

  @override
  String get ratingLabel => 'Avaliação';

  @override
  String get nutritionMgmtTitle => 'Gestión de Nutrición';

  @override
  String get dailyMealPlan => 'Plan de Comidas Diario';

  @override
  String get recommendedIntake => 'Ingesta Recomendada';

  @override
  String get weightMonitoring => 'Monitoreo de Peso';

  @override
  String get labelProteins => 'Proteínas';

  @override
  String get labelCarbs => 'Carbohidratos';

  @override
  String weeklyPlanTitle(Object date) {
    return 'Semana del $date';
  }

  @override
  String weeklyPlanSubtitle(Object count) {
    return 'Lo que comerás en los próximos $count días';
  }

  @override
  String get tipsTitle => 'Consejos de Preparación (Batch Cooking)';

  @override
  String get caloriesEstimated => 'kcal estimadas para el día';

  @override
  String get todayLabel => 'HOY';

  @override
  String get mealBreakfast => 'Desayuno';

  @override
  String get mealLunch => 'Almuerzo';

  @override
  String get mealSnack => 'Merienda';

  @override
  String get mealDinner => 'Cena';

  @override
  String get regeneratePlanTitle => '¿Rehacer la semana?';

  @override
  String get regeneratePlanBody =>
      'Esto creará un nuevo menú para la semana. El actual será reemplazado.';

  @override
  String get regenerateAction => 'Rehacer';

  @override
  String get regenerateSuccess => '¡Menú semanal rehecho!';

  @override
  String get planError => 'Error al cargar el menú';

  @override
  String get tryAgain => 'Intentar de nuevo';

  @override
  String get noPlanTitle => 'Aún no tienes un menú';

  @override
  String get createPlanButton => 'Crear Menú';

  @override
  String get historyTitle => 'Historial de Menús';

  @override
  String get noHistory => 'Sin historial';

  @override
  String daysPlanned(Object count) {
    return '$count días planificados';
  }

  @override
  String get deletePlanTitle => '¿Eliminar menú?';

  @override
  String get deletePlanBody => 'Esta acción no se puede deshacer.';

  @override
  String get ingredientsTitle => 'INGREDIENTES';

  @override
  String get mealDefault => 'Comida';

  @override
  String get creatingProfile => 'Perfil básico creado automáticamente.';

  @override
  String get planCreatedSuccess => '¡Menú creado con éxito!';

  @override
  String get openingConfig => 'Abriendo configuración...';

  @override
  String get pdfMenuPlanTitle => 'Plan Nutricional Semanal';

  @override
  String get menuCreationTitle => 'Crear Menú Semanal';

  @override
  String get menuCreationSubtitle => 'Configura cómo quieres tu menú';

  @override
  String get mealsPerDay => 'Comidas por día';

  @override
  String get mealsUnit => 'comidas';

  @override
  String get menuStyleTitle => 'Estilo de menú';

  @override
  String get styleSimple => 'Simple';

  @override
  String get styleBudget => 'Económico';

  @override
  String get styleQuick => 'Rápido';

  @override
  String get styleHealthy => 'Saludable';

  @override
  String get dietaryRestrictions => 'Restricciones dietéticas';

  @override
  String get allowRepetition => 'Permitir repetición de recetas';

  @override
  String get allowRepetitionSubtitle =>
      'Si está desactivado, cada receta aparece solo una vez';

  @override
  String get restVegetarian => 'Vegetariano';

  @override
  String get restVegan => 'Vegano';

  @override
  String get restLactoseFree => 'Sin Lactosa';

  @override
  String get restGlutenFree => 'Sin Gluten';

  @override
  String get restDiabetes => 'Diabetes';

  @override
  String get restHypertension => 'Hipertensión';

  @override
  String get periodTypeTitle => 'Período do Cardápio';

  @override
  String get periodWeekly => 'Semanal (7 dias)';

  @override
  String get periodMonthly => 'Mensal (28 dias)';

  @override
  String get objectiveTitle => 'Objetivo';

  @override
  String get objMaintenance => 'Manter peso';

  @override
  String get objWeightLoss => 'Emagrecimento';

  @override
  String get objBalanced => 'Alimentação equilibrada';

  @override
  String get periodSectionTitle => 'Para quando?';

  @override
  String get periodSectionDesc =>
      'Escolha o período do cardápio que será gerado.';

  @override
  String get periodThisWeek => 'Esta semana';

  @override
  String get periodNextWeek => 'Próxima semana';

  @override
  String get period28Days => 'Próximos 28 dias';

  @override
  String get objectiveSectionTitle => 'Objetivo do cardápio';

  @override
  String get objectiveSectionDesc =>
      'O objetivo influencia a escolha dos alimentos e calorias.';

  @override
  String get preferencesSectionTitle => 'Preferências alimentares';

  @override
  String get preferencesSectionDesc =>
      'Opcional. Se não marcar nada, o cardápio será padrão.';

  @override
  String get confirmationSectionTitle => 'Resumo da escolha';

  @override
  String get confirmationSummaryLead => 'Você vai gerar:';

  @override
  String get confirmationPeriodPrefix => '• Cardápio: ';

  @override
  String get confirmationObjectivePrefix => '• Objetivo: ';

  @override
  String get generateMenuAction => 'GERAR CARDÁPIO';

  @override
  String get selectPeriodError => 'Escolha o período do cardápio.';

  @override
  String get generatingMenu => 'Gerando seu cardápio...';

  @override
  String get redoPlanAction => 'Refazer esta semana';

  @override
  String get generateNextWeekAction => 'Gerar próxima semana';

  @override
  String get generate28DaysAction => 'Gerar próximos 28 dias';

  @override
  String get createNewVersion => 'Criar nova versão';

  @override
  String get replaceExisting => 'Substituir atual';

  @override
  String get redoPlanPrompt => 'Como você deseja refazer este cardápio?';

  @override
  String get historyFilter => 'Filtrar Histórico';

  @override
  String get allPeriods => 'Todos os Períodos';

  @override
  String get activeStatus => 'Ativo';

  @override
  String get archivedStatus => 'Arquivado';

  @override
  String get editMeal => 'Editar Refeição';

  @override
  String get saveChanges => 'Salvar Alterações';

  @override
  String get deletePlanSuccess => 'Cardápio excluído com sucesso.';

  @override
  String get mealRemoved => 'Cardápio removido.';

  @override
  String get statusActive => 'Ativo';

  @override
  String get statusArchived => 'Arquivado';

  @override
  String get versionLabel => 'Versão';

  @override
  String get pdfPersonalizedPlanTitle => 'PLAN NUTRICIONAL PERSONALIZADO';

  @override
  String get pdfGoalLabel => 'OBJETIVO';

  @override
  String get pdfGeneratedByLine =>
      'INFORME DE NUTRICIÓN SEMANAL GENERADO POR ScanNut AI';

  @override
  String get pdfBatchCookingTips =>
      '💡 CONSEJOS DE BATCH COOKING Y PREPARACIÓN';

  @override
  String get tipBeans =>
      '💡 Cocina una olla grande de frijoles al inicio de la semana y congela porciones para ahorrar gas y tiempo.';

  @override
  String get tipRice =>
      '💡 Mantén una base de arroz blanco lista en la nevera; es el acompañamiento comodín para casi todas tus comidas.';

  @override
  String get tipChicken =>
      '💡 Cocina y desmenuza el pollo de una vez. Úsalo en sándwiches naturales, wraps y revueltos del viernes.';

  @override
  String get tipEggs =>
      '💡 Los huevos son tu proteína económica y rápida. Tenlos siempre a mano para sustituir carnes en días ajetreados.';

  @override
  String get tipVeggies =>
      '💡 Lava y pica todos los vegetales de temporada apenas llegues del mercado. Guárdalos en recipientes herméticos para que duren más.';

  @override
  String get tipRoots =>
      '💡 Raíces como yuca y batata pueden cocinarse en gran cantidad y guardarse en agua en la nevera por 3 días.';

  @override
  String get tipGroundMeat =>
      '💡 La carne molida es la base perfecta: úsala sola en el almuerzo y en rellenos de panqueques o sándwiches al día siguiente.';

  @override
  String get tipFruits =>
      '💡 ¿Frutas muy maduras? Congélalas en trozos para potenciar tus vitaminas y batidos matutinos.';

  @override
  String get tipDefault =>
      'Planifica tus compras enfocándote en artículos de temporada para ahorrar y ganar salud.';

  @override
  String get foodRice => 'Arroz';

  @override
  String get foodBeans => 'Frijoles';

  @override
  String get foodChicken => 'Pollo';

  @override
  String get foodMeat => 'Carne';

  @override
  String get foodFish => 'Pescado';

  @override
  String get foodEgg => 'Huevo';

  @override
  String get foodBread => 'Pan';

  @override
  String get foodMilk => 'Leche';

  @override
  String get foodCoffee => 'Café';

  @override
  String get foodYogurt => 'Yogur';

  @override
  String get foodFruit => 'Fruta';

  @override
  String get foodSalad => 'Ensalada';

  @override
  String get foodVegetables => 'Vegetales';

  @override
  String get foodPasta => 'Pasta';

  @override
  String get foodPotato => 'Patata';

  @override
  String get foodCassava => 'Yuca';

  @override
  String get foodCheese => 'Queso';

  @override
  String get foodJuice => 'Zumo';

  @override
  String get foodWater => 'Agua';

  @override
  String get defaultWoundAnalysis =>
      'Análisis visual de herida o lesión detectada';

  @override
  String get petSelectionTitle => '¿Para qué mascota es este análisis?';

  @override
  String get petNew => 'Nueva Mascota';

  @override
  String get petQuickAnalysis => 'Análisis rápido sin guardar';

  @override
  String get paywallBenefit1 => 'Acceso ilimitado a todas las funciones';

  @override
  String get paywallBenefit2 => 'Análisis detallados y avanzados';

  @override
  String get paywallBenefit3 => 'Informes PDF completos sin restricciones';

  @override
  String get paywallBenefit4 => 'Soporte prioritario';

  @override
  String get featureMicrosTitle => 'Micronutrientes y Sinergia';

  @override
  String get featureMicrosDesc =>
      'Obtenga análisis completo de vitaminas, minerales y cómo interactúan.';

  @override
  String get foodApple => 'Manzana';

  @override
  String get foodBanana => 'Plátano';

  @override
  String get foodCorn => 'Maíz';

  @override
  String get foodPeas => 'Guisantes';

  @override
  String get foodCarrot => 'Zanahoria';

  @override
  String get foodTomato => 'Tomate';

  @override
  String get foodOnion => 'Cebolla';

  @override
  String get foodGarlic => 'Ajo';

  @override
  String get foodOrange => 'Naranja';

  @override
  String get foodPineapple => 'Piña';

  @override
  String get unknownFood => 'Alimento Desconocido';

  @override
  String get actionDelete => 'Borrar';

  @override
  String get plantCareGuide => 'Guía de Cuidados';

  @override
  String get toxicityWarning => 'Atención: Tóxica para Mascotas';

  @override
  String get featureMenuPlanTitle => 'Planificación Inteligente de Menús';

  @override
  String get featureMenuPlanDesc =>
      'Cree menús semanales personalizados basados en sus objetivos y restricciones de dieta.';

  @override
  String get plantHomeSafety => 'Seguridad en el Hogar';

  @override
  String get plantDangerPets => 'Peligro para Mascotas';

  @override
  String get plantDangerKids => 'Peligro para Niños';

  @override
  String get plantNoAlerts => 'Sin alertas críticas.';

  @override
  String get plantBioPower => 'Poderes Biofílicos';

  @override
  String get plantAirScore => 'Puntuación de Purificación';

  @override
  String get plantHumidification => 'Humidificación';

  @override
  String get plantWellness => 'Impacto en el Bienestar';

  @override
  String get plantPropagationEngine => 'Ingeniería de Propagación';

  @override
  String get plantMethod => 'Método';

  @override
  String get plantDifficulty => 'Dificultad';

  @override
  String get plantStepByStep => 'Paso a Paso';

  @override
  String get plantEcoIntel => 'Inteligencia del Ecosistema';

  @override
  String get plantCompanions => 'Compañeros Ideales';

  @override
  String get plantAvoid => 'Evitar Cerca';

  @override
  String get plantRepellent => 'Repelente Natural';

  @override
  String get plantFengShui => 'Feng Shui Botánico';

  @override
  String get plantPlacement => 'Dónde Colocar';

  @override
  String get plantSymbolism => 'Simbolismo';

  @override
  String get plantLivingAesthetic => 'Estética Viva';

  @override
  String get plantFlowering => 'Floración';

  @override
  String get plantFlowerColor => 'Color de la Flor';

  @override
  String get plantGrowth => 'Velocidad de Crecimiento';

  @override
  String get plantMaxSize => 'Tamaño Máximo';

  @override
  String get plantNeedSun => 'LUZ';

  @override
  String get plantNeedWater => 'AGUA';

  @override
  String get plantNeedSoil => 'SUELO';

  @override
  String get plantSeasonAdjust => 'Ajustes Estacionales';

  @override
  String get seasonWinter => 'Invierno (Dormancia)';

  @override
  String get seasonSummer => 'Verano (Crecimiento)';

  @override
  String get plantClinicalDiagnosis => 'Diagnóstico Clínico';

  @override
  String get plantRecoveryPlan => 'Plan de Recuperación';

  @override
  String get plantUrgency => 'Urgencia';

  @override
  String get plantBuyTreatment => 'COMPRAR TRATAMIENTO SUGERIDO';

  @override
  String get fallbackNoInfo => 'Sin información';

  @override
  String get fallbackDirectWatering => 'Riego directo';

  @override
  String get fallbackAsNeeded => 'Según sea necesario';

  @override
  String get advancedDiagnosis => 'Diagnóstico Avanzado';

  @override
  String get advancedDiagnosisDesc =>
      'Acceda a diagnósticos clínicos detallados y guías de recuperación paso a paso.';

  @override
  String get biosTitle => 'Seguridad y Biofilia';

  @override
  String get biosDesc =>
      'Conozca detalles sobre toxicidad para mascotas/niños y beneficios biofílicos de la planta.';

  @override
  String get noInformation => 'Sin información';

  @override
  String get directSoilWatering => 'Riego directo al suelo';

  @override
  String get asNeeded => 'Según sea necesario';

  @override
  String get plantFamily => 'Família';

  @override
  String get plantIdentificationTaxonomy => 'Identificação e Taxonomia';

  @override
  String get plantPopularNames => 'Nomes Populares';

  @override
  String get plantScientificName => 'Nome Científico';

  @override
  String get plantOrigin => 'Origem';

  @override
  String get plantDetails => 'Detalhes';

  @override
  String get plantSubstrate => 'Substrato';

  @override
  String get plantFertilizer => 'Fertilizante';

  @override
  String get plantIdealPh => 'pH Ideal';

  @override
  String get plantToxicityDetails => 'Detalhes de Toxicidade';

  @override
  String get safetyAlert => 'Alerta de Seguridad';

  @override
  String get close => 'Cerrar';

  @override
  String get editPetTitle => 'Editar Perfil';

  @override
  String get newPetTitle => 'Nueva Mascota';

  @override
  String get petNameLabel => 'Nombre de la Mascota';

  @override
  String get petNameRequired => 'El nombre es obligatorio';

  @override
  String get petBreedLabel => 'Raza';

  @override
  String get petOriginRegion => 'Región de Origen';

  @override
  String get petMorphology => 'Tipo Morfológico';

  @override
  String get unknownRegion => 'Región Desconocida';

  @override
  String get unknownMorphology => 'Morfología N/A';

  @override
  String get petAgeLabel => 'Edad Exacta (ej: 2 años 3 meses)';

  @override
  String get petBiologicalProfile => 'Perfil Biológico';

  @override
  String get petActivityLevelLabel => 'Nivel de Actividad';

  @override
  String get petReproductiveStatusLabel => 'Estado Reproductivo';

  @override
  String get petIdentity => 'Identidad';

  @override
  String get petHealth => '💉 Salud';

  @override
  String get petNutrition => '🍖 Nutrición';

  @override
  String get petGallery => 'Galería';

  @override
  String get petPartners => 'Red de Apoyo';

  @override
  String get petWeightControl => 'Control de Peso Inteligente';

  @override
  String get petWeightAutoAnalysis =>
      'Análisis automático basado en raza y tamaño';

  @override
  String get petCurrentWeight => 'Peso Actual (kg)';

  @override
  String get petVaccinationHistory => 'Historial de Vacunación';

  @override
  String get petLastV10 => 'Última V10/V8';

  @override
  String get petLastRabies => 'Última Rabia';

  @override
  String get petHygiene => '🛁 Higiene';

  @override
  String get petBathFrequency => 'Frecuencia de Baños';

  @override
  String get petMedicalDocs => 'Otros Documentos Médicos';

  @override
  String get petPrescriptions => 'Recetas Veterinarias';

  @override
  String get petVaccineCard => 'Carnet de Vacunación';

  @override
  String get petWoundHistory => 'Historial de Análisis de Heridas';

  @override
  String get petDiseaseHistory => 'Historial de Análisis de Enfermedades';

  @override
  String get petNoWounds => 'Ningún análisis de herida registrado aún.';

  @override
  String petWoundsCount(int count) {
    return '$count análisis registrado(s)';
  }

  @override
  String get petFoodAllergies => 'Alergias Alimentarias';

  @override
  String get petFoodAllergiesDesc => 'Ingredientes a evitar';

  @override
  String get petAddAllergy => 'Añadir Alergia';

  @override
  String get petFoodPreferences => 'Preferencias Alimentarias';

  @override
  String get petFoodPreferencesDesc => 'Alimentos que la mascota más ama';

  @override
  String get petAddPreference => 'Añadir Preferencia';

  @override
  String get petDietRecipes => 'Recetas y Dietas';

  @override
  String get petDeleteTitle => '¿Eliminar Mascota?';

  @override
  String petDeleteContent(Object name) {
    return '¿Desea eliminar a $name y todo su historial? Esta acción no se puede deshacer.';
  }

  @override
  String get petDeleteConfirm => 'Eliminar Permanentemente';

  @override
  String get petChangePhoto => 'Cambiar Foto de Perfil';

  @override
  String get petTakePhoto => 'Tomar Foto';

  @override
  String get petChooseGallery => 'Elegir de la Galería';

  @override
  String get petAddMedia => 'Añadir Multimedia';

  @override
  String get petAttachDoc => 'Adjuntar Documento';

  @override
  String get petCameraPhoto => 'Cámara (Foto)';

  @override
  String get petGalleryPhoto => 'Galería (Foto)';

  @override
  String get petCameraVideo => 'Cámara (Video)';

  @override
  String get petGalleryVideo => 'Galería (Video)';

  @override
  String get petEmptyGallery => 'La galería está vacía';

  @override
  String get petEmptyGalleryDesc => 'Fotos y videos de los mejores momentos';

  @override
  String get petAddToGallery => 'Añadir a la Galería';

  @override
  String get petDocAttached => '¡Documento adjuntado!';

  @override
  String get petDeleteAttachment => '¿Eliminar Adjunto?';

  @override
  String get petDeleteAttachmentContent => 'Esta acción no se puede deshacer.';

  @override
  String get petSaveSuccess => '¡Guardado!';

  @override
  String get petUndoChanges => 'Deshacer cambios';

  @override
  String get petAllSaved => 'Todo guardado';

  @override
  String get petBasicInfo => 'Información Básica';

  @override
  String get petPartnersNoPartners =>
      'No hay socios registrados. Añada socios mediante el Partners Hub en la pantalla principal.';

  @override
  String get petPartnersNotFound =>
      'No se encontraron socios en esta categoría.';

  @override
  String get petPartnersLinked => 'Vinculado';

  @override
  String get petPartnersNoAddress => 'Dirección no informada';

  @override
  String get petPartnersPhoneHint => 'Teléfono';

  @override
  String get petPartnersCall => 'Llamar';

  @override
  String get petPartnersSchedule => 'Programar';

  @override
  String get petPartnersObs => 'Prac (Red de Apoyo)';

  @override
  String get agendaToday => 'Hoy';

  @override
  String get agendaYesterday => 'Ayer';

  @override
  String get agendaNewEvent => 'Nuevo Evento';

  @override
  String get agendaTitle => 'Agenda';

  @override
  String get agendaDate => 'Fecha';

  @override
  String get agendaTime => 'Hora';

  @override
  String get agendaObservations => 'Observaciones';

  @override
  String get agendaAdd => 'Añadir Evento';

  @override
  String get agendaTitleHint => 'Título (ej: Consulta, Baño)';

  @override
  String get agendaEmpty =>
      'Sin eventos registrados.\nAñada citas, vacunas o notas.';

  @override
  String get petDiagnosis => 'Diagnóstico';

  @override
  String get petSeverity => 'Gravedad';

  @override
  String get petRecommendations => 'Recomendaciones';

  @override
  String get petBiometricAnalysis => 'Análisis Biométrico';

  @override
  String get petLineage => 'Linaje';

  @override
  String get petSize => 'Tamaño';

  @override
  String get petLongevity => 'Longevidad';

  @override
  String get petGrowthCurve => 'Curva de Crecimiento Estimada';

  @override
  String get petMonth3 => '3 Meses';

  @override
  String get petMonth6 => '6 Meses';

  @override
  String get petMonth12 => '12 Meses';

  @override
  String get petAdult => 'Adulto';

  @override
  String get petEnergy => 'Energía';

  @override
  String get petIntelligence => 'Inteligencia';

  @override
  String get petSociability => 'Sociabilidad';

  @override
  String get petDrive => 'Impulso Ancestral';

  @override
  String get petSuggestedPlan => 'Plan Alimentario Sugerido';

  @override
  String get petResultTitle => 'Análise Veterinária 360°';

  @override
  String get petResultViewProfile => 'VER PERFIL DO PET';

  @override
  String get petResultSave => 'Salvar apenas';

  @override
  String get petResultGeneratePDF => 'Gerar PDF';

  @override
  String get petResultDossier => 'Dossiê 360°';

  @override
  String get petSectionObservedSigns => 'Sinais Observados';

  @override
  String get petSectionNutrition => 'Nutrición';

  @override
  String get petSectionGrooming => 'Higiene';

  @override
  String get petSectionHealth => 'Saúde Preventiva';

  @override
  String get petSectionLifestyle => 'Estilo de Vida';

  @override
  String get petInsightSpecialist => 'Insight do Especialista';

  @override
  String get petDisclaimerAI =>
      'Conteúdo gerado por IA. Não substitui diagnóstico veterinário.';

  @override
  String get petMetaPuppy => 'Meta Filhote';

  @override
  String get petMetaAdult => 'Meta Adulto';

  @override
  String get petMetaSenior => 'Meta Sênior';

  @override
  String get petTargetNutrients => 'Nutrientes Objetivo';

  @override
  String get petCoatType => 'Tipo de Pelaje';

  @override
  String get petBrushingFreq => 'Escovação';

  @override
  String get petBathSug => 'Banho Sugerido';

  @override
  String get petPredispositions => 'Predisposições';

  @override
  String get petCheckup => 'Checkup';

  @override
  String get petNoData => '--';

  @override
  String get petSavingProfile => 'Salvando no Histórico...';

  @override
  String get petSavedHistory => 'Salvo no Histórico!';

  @override
  String get petProfileCreated => 'Perfil criado com sucesso!';

  @override
  String get petSaveError => 'Erro ao salvar perfil. Tente novamente.';

  @override
  String get petGeneratingPDF => 'Gerando PDF... (Simulação)';

  @override
  String get petUrgencyRed => 'Urgência Veterinária';

  @override
  String get petUrgencyYellow => 'Atenção Necessária';

  @override
  String get petUrgencyGreen => 'Observação';

  @override
  String get petSignCritical => 'Sinais clínicos de risco detectados.';

  @override
  String get petImmediateOrientation => 'Orientação Imediata:';

  @override
  String get petDailyCaloricGoals => 'Metas Calóricas Diarias';

  @override
  String get petPuppy => 'Cachorro';

  @override
  String get petSenior => 'Senior';

  @override
  String get petSecuritySupplements => 'Seguridad y Suplementos';

  @override
  String get petSupplementation => 'Suplementación';

  @override
  String get petObesityTendency => 'Tendencia a la Obesidad';

  @override
  String get petCoatGrooming => 'Pelaje y Estética';

  @override
  String get petType => 'Tipo';

  @override
  String get petFrequency => 'Frecuencia';

  @override
  String get petPreventiveHealth => 'Salud Preventiva';

  @override
  String get petPredisposition => 'Predisposición';

  @override
  String get petTrainingEnvironment => 'Entrenamiento y Entorno';

  @override
  String get petTraining => 'Entrenamiento';

  @override
  String get petApartmentRef => 'Apartamento';

  @override
  String get petExclusiveInsight => 'Insight Exclusivo';

  @override
  String get petRaceAnalysis => 'Análisis de Raza';

  @override
  String get petReliability => 'Fiabilidad';

  @override
  String get petReliabilityLow => 'Baja';

  @override
  String get petReliabilityMedium => 'Media';

  @override
  String get petReliabilityHigh => 'Alta';

  @override
  String get petNotIdentified => 'No identificado';

  @override
  String get petNotEstimated => 'No estimado';

  @override
  String get petVariable => 'Variable';

  @override
  String get petNeutered => 'Castrado';

  @override
  String get petIntact => 'Entero';

  @override
  String get petActivityModerate => 'Moderado';

  @override
  String get petBathBiweekly => 'Quincenal';

  @override
  String get petGenerateWeeklyMenu => 'Generar Menú Semanal';

  @override
  String get petNoDocumentsAttached => 'Sin documentos adjuntos';

  @override
  String get petSeeFull => 'Ver Completo';

  @override
  String get petObservationsHistory => 'Historial de Observaciones';

  @override
  String get petRegisterObservations =>
      'Registre observaciones importantes aquí...';

  @override
  String get petNoObservations => 'Aún no hay observaciones registradas.';

  @override
  String get commonAddText => 'Añadir Texto';

  @override
  String get commonVoice => 'Voz';

  @override
  String get commonListening => 'Escuchando...';

  @override
  String commonLoadMore(Object count) {
    return 'Cargar anteriores ($count restantes)';
  }

  @override
  String get petWeeklyPlanTitle => 'Plan Alimentario Semanal';

  @override
  String get petNutritionPillarsDesc =>
      'Cada comida se enfoca en los 5 Pilares (Proteína, Grasa, Fibra, Minerales, Hidratación)';

  @override
  String get backButton => 'Volver';

  @override
  String get generateReportButton => 'Generar Informe';

  @override
  String get reportDetailLevelLabel => 'Nivel de Detalle';

  @override
  String get reportHubTitle => 'Informe de Socios';

  @override
  String get noPartnersForFilters =>
      'No se encontraron socios para este filtro';

  @override
  String get reportSummary => 'Resumen';

  @override
  String get reportDetailed => 'Detallado';

  @override
  String get reportDescription => 'Informe PDF completo de la red de socios.';

  @override
  String get exportPdfTitle => 'Exportar PDF';

  @override
  String get partnerTypeLabel => 'Categoría';

  @override
  String get petActivityLevel => 'Nivel de Actividad';

  @override
  String get petReproductiveStatus => 'Estado Reproductivo';

  @override
  String get errorBadPhoto =>
      '¡Ups! La foto no fue lo suficientemente clara. ¡Pruebe un nuevo ángulo!';

  @override
  String get errorAiTimeout =>
      'Nuestra IA está analizando cuidadosamente... ¡un momento!';

  @override
  String get aiCalculatingMetrics => 'Generando menú semanal...';

  @override
  String get examBlood => 'Análisis de Sangre';

  @override
  String get examUrine => 'Análisis de Orina';

  @override
  String get examFeces => 'Análisis de Heces';

  @override
  String get examOther => 'Otros Exámenes';

  @override
  String get petSeverityLow => 'Baja';

  @override
  String get petSeverityMedium => 'Media';

  @override
  String get petSeverityHigh => 'Alta';

  @override
  String get petDiagnosisDefault => 'Sin diagnóstico';

  @override
  String get examDeleteTitle => 'Eliminar Examen';

  @override
  String get examDeleteContent =>
      '¿Está seguro de que desea eliminar este examen? Esta acción no se puede deshacer.';

  @override
  String get petLifeExpectancy => 'Esperanza de Vida';

  @override
  String get petTypicalWeight => 'Peso Típico';

  @override
  String get petTemperament => 'Temperamento';

  @override
  String get petOrigin => 'Origen e Historia';

  @override
  String get petCuriosities => 'Curiosidades';

  @override
  String errorAddingExam(Object error) {
    return 'Erro ao adicionar exame: $error';
  }

  @override
  String get ocrSuccess =>
      'Texto extraído com sucesso! Clique em \'Explicar Exame\' para análise.';

  @override
  String errorGeneratingExplanation(Object error) {
    return 'Erro ao gerar explicação: $error';
  }

  @override
  String get petEstimatedByBreed => 'Estimado según la raza';

  @override
  String menuTitle(String petName) {
    return 'Menú de $petName';
  }

  @override
  String get menuLastWeek => 'Semana Pasada';

  @override
  String get menuCurrentWeek => 'Semana Actual';

  @override
  String get menuNextWeek => 'Próxima Semana';

  @override
  String get menuNoHistory => 'No hay historial disponible.';

  @override
  String get menuNoCurrent => 'No hay menú para esta semana.';

  @override
  String get menuNoFuture => 'No hay menú futuro planeado.';

  @override
  String get menuGenerateEdit => 'Generar/Editar Menú';

  @override
  String get menuMainNutrients => 'Nutrientes Principales';

  @override
  String get menuNoDetails => 'No hay detalles disponibles.';

  @override
  String get menuExportTitle => 'Exportar Menú';

  @override
  String get menuExportSelectPeriod => 'Seleccionar períodos';

  @override
  String get menuExportReport => 'Exportar Informe';

  @override
  String get menuNoPeriodSelected => 'Ningún período seleccionado.';

  @override
  String get menuPeriodCustom => 'Personalizado';

  @override
  String get menuPeriodFull => 'Plan Completo';

  @override
  String get petChangesDiscarded => 'Cambios descartados.';

  @override
  String get agendaNoEventsTitle =>
      'Sin eventos registrados.\nAñada citas, vacunas o notas.';

  @override
  String get errorOpeningApp => 'No se pudo abrir la aplicación';

  @override
  String get pdfFieldLabel => 'Campo';

  @override
  String get pdfFieldValue => 'Información';

  @override
  String get pdfFieldName => 'Nombre Completo';

  @override
  String get pdfFieldBreed => 'Raza';

  @override
  String get pdfFieldAge => 'Edad Exacta';

  @override
  String get pdfFieldSex => 'Sexo';

  @override
  String get pdfFieldMicrochip => 'Microchip';

  @override
  String get pdfFieldCurrentWeight => 'Peso Actual';

  @override
  String get pdfFieldIdealWeight => 'Peso Ideal';

  @override
  String get pdfFieldReproductiveStatus => 'Estado Reproductivo';

  @override
  String get pdfFieldActivityLevel => 'Nivel de Actividad';

  @override
  String get pdfFieldBathFrequency => 'Frecuencia de Baño';

  @override
  String get pdfPreferenciasAlimentares => 'Preferencias Alimentarias';

  @override
  String get pdfHistClinico =>
      'Historial Clínico (Vacunas, Meds, Procedimientos)';

  @override
  String get pdfExamesLab => 'Exámenes de Laboratorio';

  @override
  String get pdfAnaliseFeridas => 'Historial de Análisis de Heridas';

  @override
  String get pdfCardapioDetalhado => 'Menú Semanal Detallado';

  @override
  String get pdfRefeicao => 'Comida';

  @override
  String get pdfKcal => 'kcal';

  @override
  String get pdfSemDescricao => 'Sin descripción';

  @override
  String get pdfPesoStatusUnder => 'Bajo peso';

  @override
  String get pdfPesoStatusOver => 'Sobrepeso';

  @override
  String get pdfPesoStatusIdeal => 'Ideal';

  @override
  String get pdfPesoStatusNormal => 'Peso normal';

  @override
  String get pdfPesoStatusMeta => 'Meta';

  @override
  String get pdfVacinaV10 => 'V10/V8 (Polivalente)';

  @override
  String get pdfVacinaAntirrabica => 'Antirrábica';

  @override
  String get pdfVacinaNaoRegistrada => 'No registrada';

  @override
  String pdfAlergiasAviso(Object allergies) {
    return 'ATENCIÓN: $allergies';
  }

  @override
  String get pdfAlergiasNenhuma => '✓ No hay alergias conocidas registradas';

  @override
  String pdfExtractedText(Object text) {
    return 'Texto extraído: $text';
  }

  @override
  String pdfAiAnalysis(Object analysis) {
    return 'Análisis de IA: $analysis';
  }

  @override
  String pdfDiagnosis(Object diagnosis) {
    return 'Diagnóstico: $diagnosis';
  }

  @override
  String get pdfRecommendations => 'Recomendaciones';

  @override
  String get pdfAgendaTitle => 'Control de Agenda';

  @override
  String get pdfObservationsTitle => 'HISTORIAL DE OBSERVACIONES:';

  @override
  String get pdfMetric => 'Métrica';

  @override
  String get pdfWeightControl => 'Control de Peso';

  @override
  String get pdfWeightHistory => 'Historial de Peso';

  @override
  String get pdfType => 'Tipo';

  @override
  String get pdfDescription => 'Descripción';

  @override
  String get pdfCompleted => 'Completado';

  @override
  String get pdfPending => 'Pendiente';

  @override
  String get pdfEstimatedNote => '* Estimado/Calculado';

  @override
  String get pdfNoPlan => 'No hay plan de alimentación registrado.';

  @override
  String get pdfAgendaReport => 'Informe de Agenda de la Mascota';

  @override
  String get pdfTotalEvents => 'Eventos Totales';

  @override
  String get pdfCompletedEvents => 'Completados';

  @override
  String get pdfPendingEvents => 'Pendientes';

  @override
  String get pdfFieldTime => 'Hora';

  @override
  String get pdfFieldEvent => 'Evento';

  @override
  String get pdfFieldPet => 'Mascota';

  @override
  String get pdfAgendaToday => 'Hoy';

  @override
  String get pdfObservations => 'Observaciones';

  @override
  String get pdfSummaryReport => 'Informe Resumido - Tabla Omitida';

  @override
  String get pdfNoImages => 'No se encontraron imágenes en la galería.';

  @override
  String get pdfAttachedDocs => 'Documentos Adjuntos (PDFs/Archivos):';

  @override
  String get pdfLinkedPartners => 'Socios Vinculados:';

  @override
  String pdfPartnerLoadError(Object count) {
    return '⚠️ $count socio(s) vinculado(s), pero no se pudieron cargar los detalles.';
  }

  @override
  String get pdfServiceHistory => 'Historial de Servicios:';

  @override
  String get pdfNoPartners => 'No hay socios vinculados a este perfil.';

  @override
  String get pdfAgendaEvents => 'Agenda y Eventos';

  @override
  String get pdfHistoryUpcoming => 'Historial y Citas Próximas';

  @override
  String get pdfUpcomingEvents => 'Próximos Eventos';

  @override
  String get pdfRecentHistory => 'Historial Reciente';

  @override
  String get partnersSelectTitle => 'Seleccionar Socio';

  @override
  String get partnersExportPdf => 'Exportar PDF';

  @override
  String get partnersCategory => 'Categoría';

  @override
  String get partnersDetailLevel => 'Nivel de Detalle';

  @override
  String get partnersSummary => 'Resumen';

  @override
  String get partnersDetailed => 'Detallado';

  @override
  String get partnersExportDisclaimer =>
      'Informe PDF completo de su red de socios.';

  @override
  String get partnersGenerateReport => 'Generar Informe';

  @override
  String get partnersBack => 'Volver';

  @override
  String get partnersRegister => 'Registrar';

  @override
  String get partnersNoneFound =>
      'No se encontraron socios en la base de datos.';

  @override
  String partnersNoneInCategory(Object category) {
    return 'No hay socios en la categoría $category.';
  }

  @override
  String get partnersRadarHint =>
      'Use el botón \'Radar\' para encontrar ubicaciones reales.';

  @override
  String get partnersLocationDenied => 'Permiso de ubicación denegado.';

  @override
  String get partnersLocationPermanentlyDenied =>
      'Permiso denegado permanentemente en ajustes.';

  @override
  String get partnersLocationError => 'No se pudo obtener su ubicación actual.';

  @override
  String get partnersRadarDetecting =>
      'Detectando establecimientos reales en su región...';

  @override
  String get partnersRadarTracking => 'Rastreando establecimientos vía GPS...';

  @override
  String get partnersRadarNoResults => 'Sin ubicaciones en esta categoría.';

  @override
  String get menuDietType => 'Tipo de Dieta';

  @override
  String get pdfError => 'Error al generar PDF:';

  @override
  String get pdfFieldPhone => 'Teléfono';

  @override
  String get pdfFieldEmail => 'Correo electrónico';

  @override
  String get pdfFieldAddress => 'Dirección';

  @override
  String get pdfFieldDetails => 'Detalles y Especialidades';

  @override
  String get partnerTeamMembers => 'Integrantes del Equipo / Cuerpo Clínico';

  @override
  String get partnerNotesTitle => 'Notas y Observaciones';

  @override
  String get partnerNotesEmpty =>
      'Sin notas aún.\nEscriba o grabe recordatorios sobre este socio.';

  @override
  String get petWoundDeleteTitle => 'Eliminar Análisis';

  @override
  String get petWoundDeleteConfirm =>
      '¿Está seguro de que desea eliminar este análisis de herida? Esta acción no se puede deshacer.';

  @override
  String get petWoundDeleteSuccess => 'Análisis de herida eliminado con éxito';

  @override
  String get petWoundDeleteError => 'Error al eliminar análisis:';

  @override
  String get selectRegime => 'Seleccione al menos un régimen.';

  @override
  String get selectDatesError => 'Seleccione las fechas.';

  @override
  String get menuPlannedSuccess => '✅ ¡Menú Inteligente Planificado!';

  @override
  String get goalWeightMaintenance => 'Mantenimiento de Peso';

  @override
  String get goalWeightLoss => 'Pérdida de Peso';

  @override
  String get goalMuscleGain => 'Ganancia Muscular';

  @override
  String get goalRecovery => 'Recuperación/Convalecencia';

  @override
  String get menuProfileHeader => '⚠️ PERFIL ESPECÍFICO DE LA MASCOTA:';

  @override
  String get menuAllergiesForbidden => '- ALERGIAS (PROHIBIDO)';

  @override
  String get menuPreferences => '- PREFERENCIAS';

  @override
  String get menuRecentMeals => '- COMIDAS RECIENTES (PARA VARIACIÓN)';

  @override
  String get petSizeSmall => 'Pequeño';

  @override
  String get petSizeMedium => 'Mediano';

  @override
  String get petSizeLarge => 'Grande';

  @override
  String get petSizeGiant => 'Gigante';

  @override
  String get petCoatShort => 'Pelo corto';

  @override
  String get petCoatLong => 'Pelo largo';

  @override
  String get petCoatDouble => 'Manto doble';

  @override
  String get petCoatWire => 'Pelo duro';

  @override
  String get petCoatCurly => 'Pelo rizado';

  @override
  String get petFullAnalysisTitle => 'Análisis Completo de Raza';

  @override
  String get petGeneticAnalysisSub => 'Análisis Genético Detallado';

  @override
  String get petGeneticId => '🧬 Identificación Genética';

  @override
  String get petPrimaryRace => 'Raza Predominante';

  @override
  String get petSecondaryRaces => 'Razas Secundarias';

  @override
  String get petPhysicalChars => '📏 Características Físicas';

  @override
  String get petWeightEstimated => 'Peso Estimado';

  @override
  String get petHeight => 'Altura';

  @override
  String get petExpectancy => 'Esperanza de Vida';

  @override
  String get petCommonColors => 'Colores Comunes';

  @override
  String get petTemperamentTitle => '🎭 Temperamento y Personalidad';

  @override
  String get petPersonality => 'Personalidad';

  @override
  String get petSocialBehavior => 'Comportamiento Social';

  @override
  String get petEnergyLevel => 'Nivel de Energía';

  @override
  String get petRecommendedCare => '💚 Cuidados Recomendados';

  @override
  String get petExercise => '🏃 Ejercicio';

  @override
  String get petOriginHistory => '📜 Origen e Historia';

  @override
  String get petCuriositiesTitle => '✨ Curiosidades';

  @override
  String get petNotIdentifiedPlural => 'No identificados';

  @override
  String get petVaried => 'Variado';

  @override
  String get petDetailsUnavailable =>
      'Detalles completos no disponibles. Realice un nuevo análisis.';

  @override
  String get agendaExportTitle => 'Exportar Agenda';

  @override
  String get agendaReportType => 'Tipo de Informe:';

  @override
  String get agendaReportSummary => 'Resumen';

  @override
  String get agendaReportDetail => 'Detallado';

  @override
  String get agendaNoEventsDay => 'Sin eventos en este día';

  @override
  String agendaEventsCount(Object count) {
    return '$count eventos';
  }

  @override
  String get agendaGeneratePDF => 'Generar PDF';

  @override
  String get agendaGlobalTitle => 'Agenda Global';

  @override
  String get agendaViewCalendar => 'Ver Calendario';

  @override
  String get agendaViewAll => 'Ver Todos los Eventos';

  @override
  String get agendaNoEventsRegistered => 'Sin eventos registrados.';

  @override
  String get agendaNoEventsTodayDetail => 'Sin eventos para este día.';

  @override
  String get agendaAllPets => 'Todas las Mascotas';

  @override
  String get agendaExportPDF => 'Exportar Informe PDF';

  @override
  String get agendaReportingPeriod => 'Período del Informe';

  @override
  String get agendaFilterPet => 'Filtrar por Mascota';

  @override
  String get agendaFilterCategory => 'Filtrar por Categoría';

  @override
  String get agendaDetailLevel => 'Nivel de Detalle';

  @override
  String get agendaDetailedTable => 'Detallado (Con Tabla)';

  @override
  String get agendaSummaryOnly => 'Resumen (Solo Indicadores)';

  @override
  String get agendaButtonGenerate => 'GENERAR INFORME';

  @override
  String get agendaAllCategories => 'Todas las Categorías';

  @override
  String get agendaNoPartnerLinked =>
      'Este evento no tiene un socio vinculado para mostrar detalles.';

  @override
  String agendaProfileNotFound(Object name, Object petName) {
    return 'Perfil de $name no encontrado.';
  }

  @override
  String get agendaServiceRecord => 'Registro de Servicio';

  @override
  String get agendaAppointmentDetails => 'Detalles de la Cita';

  @override
  String get agendaResponsiblePartner => 'Socio Responsable';

  @override
  String get agendaPartnerNotFound => 'Socio no encontrado o eliminado.';

  @override
  String get agendaMarkCompleted => 'MARCAR COMO COMPLETADO';

  @override
  String get agendaEventCompleted => '¡Evento marcado como completado!';

  @override
  String get agendaEventUpdated => '¡Evento actualizado con éxito!';

  @override
  String get agendaViewRegistration => 'Toque para ver el registro';

  @override
  String get agendaWhatsAppChat => 'Chat vía WhatsApp';

  @override
  String get agendaWebsiteError => 'Error al abrir el sitio web';

  @override
  String get agendaViewProfile => '(Toque para ver el perfil)';

  @override
  String get agendaOriginalDataMissing =>
      'Datos originales del evento no encontrados para edición.';

  @override
  String get agendaEditEvent => 'Editar Evento';

  @override
  String get agendaChange => 'Cambiar';

  @override
  String get agendaAttendantSpecialist => 'Especialista / Atendente';

  @override
  String get agendaSelectAttendant => 'Seleccione el atendente';

  @override
  String get agendaEventTitle => 'Título del Evento';

  @override
  String get agendaTitleExample => 'ej: Vacuna Polivalente V10';

  @override
  String get agendaObservationsHint => 'Escriba o use el micrófono...';

  @override
  String get agendaAttachmentsFull => 'Adjuntos (PDF o Fotos)';

  @override
  String get agendaEnterTitle => 'Por favor, ingrese un título';

  @override
  String get agendaSaveChanges => 'GUARDAR CAMBIOS';

  @override
  String get agendaConfirmEvent => 'CONFIRMAR EVENTO';

  @override
  String get commonCamera => 'Cámara';

  @override
  String get commonGallery => 'Galería';

  @override
  String get commonPDFFile => 'Archivo PDF';

  @override
  String get petConsultVet =>
      'Consulte al veterinario para predisposiciones específicas';

  @override
  String get petHemogramaCheckup => 'Hemograma y chequeo general';

  @override
  String get petPositiveReinforcement => 'Refuerzo positivo';

  @override
  String get petInteractiveToys => 'Juguetes interactivos y paseos';

  @override
  String get petConsultVetCare => 'Consulte a un Vet.';

  @override
  String get pdfFieldObservations => 'Observaciones';

  @override
  String get petBreedMixed => 'Raza Mixta';

  @override
  String get petAllergies => 'Alergias';

  @override
  String get explainExam => 'Explicar Examen';

  @override
  String get attendantName => 'Nombre del Asistente';

  @override
  String get partnerDetailsRole => 'Rol';

  @override
  String get pdfDiagnosisTriage => 'Triaje Veterinario';

  @override
  String get pdfFieldBreedSpecies => 'Raza/Especie';

  @override
  String get pdfFieldUrgency => 'Urgencia';

  @override
  String get pdfFieldProfessionalRecommendation => 'Recomendación Profesional';

  @override
  String get pdfDossierTitle => 'Dossier 360º de Mascota';

  @override
  String get pdfSectionIdentity => '1. IDENTIDAD Y PERFIL';

  @override
  String get pdfSectionNutrition => '2. NUTRICIÓN Y DIETA ESTRATÉGICA';

  @override
  String get pdfSectionGrooming => '3. GROOMING Y HIGIENE';

  @override
  String get pdfSectionHealth => '4. SALUD PREVENTIVA';

  @override
  String get pdfSectionLifestyle => '5. ESTILO DE VIDA Y EDUCACIÓN';

  @override
  String get pdfFieldPredominantBreed => 'Raza Predominante';

  @override
  String get pdfFieldBehavioralProfile => 'Perfil de Comportamiento';

  @override
  String get pdfFieldEnergyLevel => 'Nivel de Energía';

  @override
  String get pdfFieldIntelligence => 'Inteligencia';

  @override
  String get pdfFieldSociability => 'Sociabilidad';

  @override
  String get pdfFieldAncestralDrive => 'Impulso Ancestral';

  @override
  String get pdfFieldEstimatedGrowthCurve => 'Curva de Crecimiento Estimada';

  @override
  String get pdfFieldDailyCaloricGoals => 'Metas Calóricas Diarias';

  @override
  String get pdfFieldPuppy => 'Cachorro';

  @override
  String get pdfFieldAdult => 'Adulto';

  @override
  String get pdfFieldSenior => 'Sénior';

  @override
  String get pdfFieldTargetNutrients => 'Nutrientes Objetivo';

  @override
  String get pdfFieldSuggestedSupplementation => 'Suplementación Sugerida';

  @override
  String get pdfFieldFoodSafety => 'Seguridad Alimentaria';

  @override
  String get pdfAlertObesity => '⚠️ ALERTA: Tendencia a la obesidad detectada';

  @override
  String get pdfFieldSafeFoods => 'Alimentos Seguros (Benigna)';

  @override
  String get pdfFieldToxicFoods => 'Alimentos Tóxicos (Maligna)';

  @override
  String get pdfFieldFoodName => 'Alimento';

  @override
  String get pdfFieldBenefit => 'Beneficio';

  @override
  String get pdfFieldRisk => 'Riesgo';

  @override
  String get pdfFieldWeeklyMenu => 'Menú Semanal (Dieta Natural)';

  @override
  String get pdfFieldReason => 'Motivo';

  @override
  String get pdfFieldCoatType => 'Tipo de Pelo';

  @override
  String get pdfFieldBrushingFrequency => 'Frecuencia de Cepillado';

  @override
  String get pdfFieldRecommendedProducts => 'Productos Recomendados';

  @override
  String get pdfFieldDiseasePredisposition => 'Predisposición a Enfermedades';

  @override
  String get pdfFieldAnatomicalCriticalPoints => 'Puntos Críticos Anatómicos';

  @override
  String get pdfFieldVeterinaryCheckup => 'Chequeo Veterinario';

  @override
  String get pdfFieldMandatoryExams => 'Exámenes';

  @override
  String get pdfFieldClimateSensitivity => 'Sensibilidad Climática';

  @override
  String get pdfFieldHeat => 'Calor';

  @override
  String get pdfFieldCold => 'Frío';

  @override
  String get pdfSectionImmunization => '4.1 Protocolo de Inmunización';

  @override
  String get pdfFieldEssentialVaccines => 'Vacunas Esenciales';

  @override
  String get pdfFieldVaccineGoal => 'Objetivo';

  @override
  String get pdfFieldFirstDose => '1ª dosis';

  @override
  String get pdfFieldBooster => 'Refuerzo';

  @override
  String get pdfFieldPreventiveCalendar => 'Calendario Preventivo';

  @override
  String get pdfFieldPuppies => 'Cachorros';

  @override
  String get pdfFieldAdults => 'Adultos';

  @override
  String get pdfFieldParasitePrevention => 'Prevención Parasitaria';

  @override
  String get pdfFieldDewormer => 'Vermífugo';

  @override
  String get pdfFieldTickFlea => 'Pulgas/Garrapatas';

  @override
  String get pdfFieldOralBoneHealth => 'Salud Bucal y Ósea';

  @override
  String get pdfFieldPermittedBones => 'Huesos Permitidos';

  @override
  String get pdfFieldFrequency => 'Frecuencia';

  @override
  String get pdfFieldTraining => 'Entrenamiento';

  @override
  String get pdfFieldTrainingDifficulty => 'Dificultad de Adiestramiento';

  @override
  String get pdfFieldRecommendedMethods => 'Métodos Recomendados';

  @override
  String get pdfFieldIdealEnvironment => 'Ambiente Ideal';

  @override
  String get pdfFieldOpenSpace => 'Espacio Abierto';

  @override
  String get pdfFieldApartmentAdaptation => 'Adaptación Apartamento';

  @override
  String get pdfFieldPeriod => 'Periodo';

  @override
  String get pdfFieldRegime => 'Régimen';

  @override
  String get pdfFieldDailyKcalMeta => 'Meta Calórica Diaria';

  @override
  String get pdfFieldDetailsComposition => 'COMPOSICIÓN Y DETALLE (5 PILARES):';

  @override
  String get pdfPeriodWeekly => 'Semanal';

  @override
  String get pdfNoMealsPlanned => 'Ninguna comida planificada.';

  @override
  String get pdfFieldGeneralGuidelines => 'ORIENTACIONES GENERALES';

  @override
  String get pdfFieldMainNutrients => 'Principales Nutrientes';

  @override
  String get pdfLastDose => 'Última Aplicación';

  @override
  String get pdfNextDose => 'Próxima Dosis';

  @override
  String get eventVaccine => 'Vacuna';

  @override
  String get eventBath => 'Baño';

  @override
  String get eventGrooming => 'Peluquería';

  @override
  String get eventVeterinary => 'Veterinario';

  @override
  String get eventMedication => 'Medicamento';

  @override
  String get eventOther => 'Otro';

  @override
  String get pdfFieldMentalStimulus => 'Estímulo Mental';

  @override
  String get pdfFieldSuggestedActivities => 'Actividades';

  @override
  String get pdfFieldExpertInsight => 'INSIGHT DEL ESPECIALISTA';

  @override
  String get pdfDisclaimer =>
      'Aviso: Este informe fue generado por IA y no sustituye la consulta veterinaria profesional.';

  @override
  String get btnCancel => 'Cancelar';

  @override
  String get processingAnalysis => 'Procesando Análisis...';

  @override
  String get labExamsSubtitle => 'Historial y Resultados';

  @override
  String get labExamsTitle => 'Exámenes de Laboratorio';

  @override
  String get pdfFilterTitle => 'Filtrar Secciones PDF';

  @override
  String get pdfFilterSubtitle =>
      'Seleccione las secciones a incluir en el informe:';

  @override
  String get pdfFilterDisclaimer =>
      'El informe incluirá solo las secciones seleccionadas';

  @override
  String get pdfSelectAll => 'Seleccionar Todo';

  @override
  String get pdfGenerate => 'Generar PDF';

  @override
  String get sectionIdentity => 'Identidad';

  @override
  String get sectionHealth => 'Salud';

  @override
  String get sectionNutrition => 'Nutrición';

  @override
  String get sectionGallery => 'Galería';

  @override
  String get sectionPartners => 'Socios';

  @override
  String get sectionDescIdentity => 'Información básica y perfil biológico';

  @override
  String get sectionDescHealth => 'Historial de vacunas, peso y exámenes';

  @override
  String get sectionDescNutrition =>
      'Plan de alimentación semanal y preferencias';

  @override
  String get sectionDescGallery => 'Fotos y documentos adjuntos';

  @override
  String get sectionDescPartners => 'Red de apoyo y socios vinculados';

  @override
  String get observationNew => 'Nueva Observación';

  @override
  String get observationHint => 'Escriba su observación...';

  @override
  String get commonAdd => 'Añadir';

  @override
  String get voiceNotAvailable => 'Reconocimiento de voz no disponible';

  @override
  String shopItems(int count) {
    return '$count Ítems';
  }

  @override
  String get shopSyncPlan => 'Sincronizar Plan';

  @override
  String get shopClearDone => 'Limpiar Completados';

  @override
  String get shopEmptyTitle => 'Tu lista está vacía';

  @override
  String get shopEmptySubtitle =>
      'Añade ítems manualmente o\ngenera desde tu menú.';

  @override
  String get shopGenerateFromMenu => 'Generar del Menú Semanal';

  @override
  String get shopNoMenuError => '¡Crea un menú primero!';

  @override
  String get shopReplaceTitle => '¿Reemplazar lista?';

  @override
  String get shopReplaceContent =>
      'Esto borrará la lista actual y creará una nueva basada en el menú.';

  @override
  String get shopGenerateBtn => 'Generar Lista';

  @override
  String get shopGeneratedSuccess => '✅ ¡Lista generada con éxito!';

  @override
  String get shopAddItemTitle => 'Añadir Ítem';

  @override
  String get shopItemName => 'Nombre del Ítem';

  @override
  String get shopItemQty => 'Cantidad (ej: 2kg, 1 un)';

  @override
  String get shopDefaultQty => '1 porción';

  @override
  String get backupOptimizeTitle => 'Respaldo y Optimización';

  @override
  String get backupOptimizeDesc =>
      'Genera un PDF completo con todo el historial de la mascota (incluyendo fotos) y permite limpiar registros antiguos para liberar espacio.';

  @override
  String get backupNoPets => 'No se encontraron mascotas.';

  @override
  String get backupSelectPet => 'Seleccionar Mascota';

  @override
  String get backupProcessing => 'Procesando...';

  @override
  String get backupGenerateBtn => 'Generar y Optimizar';

  @override
  String get backupOptimizationTitle => 'Optimización de Almacenamiento';

  @override
  String get backupOptimizationContent =>
      '¡Respaldo PDF generado con éxito!\n\n¿Desea eliminar registros de más de 2 años (Observaciones y Heridas) para liberar espacio? El historial antiguo permanecerá guardado en el PDF exportado.';

  @override
  String get backupKeepAll => 'Mantener Todo';

  @override
  String get backupCleanOld => 'Limpiar Antiguos';

  @override
  String get backupSuccessClean => '¡Limpieza completa! App optimizada.';

  @override
  String get backupNoDataClean =>
      'No se encontraron datos antiguos para limpiar.';

  @override
  String get backupProfileNotFound => 'Perfil no encontrado';

  @override
  String commonSyncError(String error) {
    return 'Error de sincronización: $error';
  }

  @override
  String get petDefaultName => 'esta mascota';

  @override
  String get diagnosisPending => 'Sin diagnóstico';

  @override
  String get severityLow => 'Baja';

  @override
  String get severityMedium => 'Media';

  @override
  String get severityHigh => 'Alta';

  @override
  String get commonSaveNameFirst =>
      'Guarde la mascota o ingrese el nombre primero.';

  @override
  String get commonFilePrefix => 'Archivo: ';

  @override
  String get commonNoAttachments => 'Ningún documento adjunto.';

  @override
  String get commonView => 'Ver';

  @override
  String get aiAnalysis => 'Análisis de IA';

  @override
  String get commonError => 'Error';

  @override
  String get commonEdit => 'Editar';

  @override
  String get agendaTabUpcoming => 'Próximos';

  @override
  String get agendaTabPast => 'Pasados';

  @override
  String get agendaTabAll => 'Todos';

  @override
  String get agendaNoUpcoming => 'No hay eventos próximos';

  @override
  String get agendaNoPast => 'No hay eventos pasados';

  @override
  String get agendaNoEvents => 'No hay eventos registrados';

  @override
  String get agendaNoFiltered => 'No hay eventos de este tipo';

  @override
  String get agendaDeleteTitle => '¿Eliminar Evento?';

  @override
  String agendaDeleteContent(String title) {
    return '¿Seguro que desea eliminar \"$title\"?';
  }

  @override
  String get agendaDeleted => 'Evento eliminado';

  @override
  String get agendaCreated => '¡Evento creado!';

  @override
  String get agendaUpdated => '¡Evento actualizado!';

  @override
  String get agendaStatusOverdue => 'ATRASADO';

  @override
  String get agendaStatusToday => 'HOY';

  @override
  String get agendaFieldTitle => 'Título';

  @override
  String get agendaFieldType => 'Tipo';

  @override
  String get agendaFieldVaccineSelect => 'Seleccionar Vacuna';

  @override
  String get agendaFieldVaccineName => 'Nombre de la Vacuna';

  @override
  String get agendaVaccineOther => 'Otra vacuna';

  @override
  String get agendaRequired => 'Obligatorio';

  @override
  String get btnDelete => 'Eliminar';

  @override
  String get partnerRegisterTitle => 'Registrar Socio';

  @override
  String get partnerEditTitle => 'Editar Socio';

  @override
  String get partnerDeleteTitle => 'Eliminar Socio';

  @override
  String partnerDeleteContent(String name) {
    return '¿Desea eliminar \"$name\" de su red de apoyo?';
  }

  @override
  String get partnerDeleted => 'Socio eliminado.';

  @override
  String partnerSaved(String name) {
    return '¡Socio \"$name\" guardado con éxito!';
  }

  @override
  String partnerSaveError(String error) {
    return 'Error al guardar: $error';
  }

  @override
  String get partnerCantDeleteLinked =>
      'No se puede eliminar: Este socio está vinculado a una mascota.';

  @override
  String get partnerBtnSave => 'GUARDAR SOCIO';

  @override
  String get partnerBtnDelete => 'ELIMINAR SOCIO';

  @override
  String get partnerDangerZone => 'Zona de Peligro';

  @override
  String get partnerDangerZoneDesc => 'Eliminar este socio es irreversible.';

  @override
  String get partnerRadarTitle => 'Radar Geo';

  @override
  String get partnerRadarHint => 'Toque para cambiar el radio de búsqueda';

  @override
  String get partnerRadarScanning => 'Sintonizando Radar y GPS...';

  @override
  String get partnerRadarNoResults => 'No se encontraron lugares.';

  @override
  String get partnerRadarPermission => 'Permiso de ubicación requerido.';

  @override
  String get partnerRadarGPSCallbackError =>
      'GPS devolvió coordenadas inválidas. Verifique permisos.';

  @override
  String get partnerRadarFoundTitle =>
      'Establecimientos reales detectados en su región:';

  @override
  String get partnerFieldEstablishment => 'Nombre del Establecimiento';

  @override
  String get partnerFieldPhone => 'Teléfono / WhatsApp';

  @override
  String get partnerFieldInstagram => 'Instagram (ej: @mipet)';

  @override
  String get partnerFieldHours => 'Horario de Atención';

  @override
  String get partnerField24h => '24h / Emergencia';

  @override
  String get partnerField24hSub => 'Local funciona ininterrumpidamente';

  @override
  String get partnerFieldSpecialties => 'Especialidades (separar por coma)';

  @override
  String get partnerFieldWebsite => 'Sitio Web';

  @override
  String get partnerFieldEmail => 'E-mail';

  @override
  String get partnerFieldAddress => 'Dirección Completa';

  @override
  String get partnerTeamTitle => 'Cuerpo Clínico / Equipo';

  @override
  String get partnerTeamAddHint => 'Añadir nombre (ej: Dra. Ana)';

  @override
  String get partnerCategory => 'Categoría';

  @override
  String get partnerNotesHint => 'Nueva observación...';

  @override
  String get partnerRadarButtonTitle => 'Búsqueda Inteligente por Radar';

  @override
  String get partnerRadarButtonDesc => 'Encuentre e importe datos vía GPS';

  @override
  String partnersRadiusInfo(String radius) {
    return 'Mostrando socios en un radio de ${radius}km';
  }

  @override
  String get partnersEmpty =>
      'No se encontraron socios\nen este radio de búsqueda.';

  @override
  String get partnersIncreaseRadius => 'Aumentar Radio de Búsqueda';

  @override
  String get partnersSuggestion =>
      'Basado en el análisis de su mascota, encontramos estos especialistas.';

  @override
  String partnersKmFromYou(String dist) {
    return '$dist km de usted';
  }

  @override
  String get partnersCall => 'Llamar';

  @override
  String get partnersMap => 'Mapa';

  @override
  String get partnersLinkTitle => 'Vincular Socio';

  @override
  String partnersLinkContent(String name) {
    return '¿Desea añadir \"$name\" a su Red de Apoyo personalizada?';
  }

  @override
  String partnersLinkSuccess(String name) {
    return '¡\"$name\" vinculado con éxito!';
  }

  @override
  String get partnersBtnLink => 'Vincular';

  @override
  String get backupGoogleDrive => 'Copia de Seguridad en Google Drive';

  @override
  String get backupSignIn => 'Conectar a Google Drive';

  @override
  String get backupSignOut => 'Desconectar';

  @override
  String get backupCreate => 'Hacer Copia Ahora';

  @override
  String get backupRestore => 'Restaurar Datos';

  @override
  String get backupDelete => 'Eliminar Copia';

  @override
  String get backupDeleteAll => 'Eliminar Todos los Datos';

  @override
  String get backupStatus => 'Estado de la Copia';

  @override
  String get backupLastBackup => 'Última copia';

  @override
  String get backupNoBackup => 'No se encontró ninguna copia';

  @override
  String get backupSignedInAs => 'Conectado como';

  @override
  String get backupNotSignedIn => 'No conectado';

  @override
  String get backupInProgress => 'Haciendo copia...';

  @override
  String get backupSuccess => '¡Copia completada con éxito!';

  @override
  String get backupFailed => 'Fallo en la copia. Inténtelo de nuevo.';

  @override
  String get backupRestoreInProgress => 'Restaurando datos...';

  @override
  String get backupRestoreSuccess =>
      '¡Datos restaurados con éxito! Reinicie la aplicación para garantizar la integridad total.';

  @override
  String get backupRestoreFailed =>
      'Fallo en la restauración. Inténtelo de nuevo.';

  @override
  String get backupDeleteConfirmTitle => '¿Eliminar Copia?';

  @override
  String get backupDeleteConfirmBody =>
      '¿Está seguro de que desea eliminar la copia de Google Drive?';

  @override
  String get backupDeleteSuccess => 'Copia eliminada de Google Drive';

  @override
  String get backupDeleteFailed => 'Fallo al eliminar copia';

  @override
  String get backupDeleteAllConfirmTitle => '¿Eliminar TODOS los Datos?';

  @override
  String get backupDeleteAllConfirmBody =>
      '¿Está seguro? Esta acción eliminará permanentemente todas sus mascotas e historial del móvil y de Google Drive. Esta acción no se puede deshacer.';

  @override
  String get backupDeleteAllSuccess => 'Todos los datos han sido eliminados';

  @override
  String get backupDeleteAllFailed => 'Fallo al eliminar datos';

  @override
  String get backupLoginCancelled => 'Login cancelado';

  @override
  String get backupDriveFullError =>
      'Google Drive lleno. Libere espacio e inténtelo de nuevo.';

  @override
  String get backupNetworkError => 'Sin conexión a internet. Verifique su red.';

  @override
  String get backupDescription =>
      'Sus datos se guardan de forma segura y privada en la carpeta oculta de la app en su Google Drive. Solo usted tiene acceso.';

  @override
  String get petBreedUnknown => 'Raça não identificada';

  @override
  String get petSRD => 'Sem Raça Definida (SRD)';

  @override
  String get agendaNoAttendants => 'Sem membros na equipe';

  @override
  String get petAnalysisResults => 'Resultados del Análisis';

  @override
  String get petAnalysisEmpty => 'Nenhuma análise registrada.';

  @override
  String get petAnalysisDateUnknown => 'Data não registrada';

  @override
  String get petAnalysisProfileDate => ' (Data do Perfil)';

  @override
  String get petAnalysisViewImage => 'Ver Imagem Analisada';

  @override
  String get commonFileNotFound => 'Arquivo não encontrado no dispositivo.';

  @override
  String get petAnalysisDefaultTitle => 'ANÁLISIS';

  @override
  String get errorScreenTitle => '¡Vaya! Algo salió mal.';

  @override
  String get errorScreenBody =>
      'Se produjo un error al procesar su solicitud. No se preocupe, sus datos están seguros.';

  @override
  String get errorScreenButton => 'Volver';

  @override
  String get errorScreenTechnicalDetails => 'Detalles técnicos:';

  @override
  String get backupSectionTitle => '💾 Copia de Seguridad';

  @override
  String get helpBackupRestoreSecurity =>
      '🔒 Seguridad: La copia está cifrada. Para restaurar, debe haber iniciado sesión con la misma cuenta que creó el archivo.';

  @override
  String get helpSecurityEndToEnd => 'Cifrado de Extremo a Extremo';

  @override
  String get helpSecurityAes => '✅ Base de Datos AES-256 (Estándar Bancario)';

  @override
  String get helpSecurityKey => '✅ Clave derivada de su contraseña personal';

  @override
  String get helpSecurityAccess =>
      '✅ Solo usted (el propietario del inicio de sesión) accede a los datos';

  @override
  String get helpSecurityBackupProtection =>
      '✅ Misma protección aplicada a las copias exportadas';

  @override
  String get backupSuccessTitle => '¡Copia de Seguridad Completada!';

  @override
  String get backupSuccessBody =>
      'Su archivo de copia de seguridad se ha guardado correctamente. Puede encontrarlo en la carpeta seleccionada.';

  @override
  String get backupErrorGeneric =>
      'Operación cancelada o fallida. Intente seleccionar otra carpeta (como Descargas) o use Compartir.';

  @override
  String get backupSecurityNotice =>
      'Las copias están cifradas con su contraseña actual. Solo el propietario del inicio de sesión original puede restaurar estos datos.';

  @override
  String get backupTechnicalErrorTitle => 'Error Técnico';

  @override
  String backupTechnicalErrorBody(String error) {
    return 'Error al exportar:\n\n$error\n\nVerifique los permisos del sistema.';
  }

  @override
  String get backupExcellent => 'Excelente';

  @override
  String get backupShare => 'Compartir';

  @override
  String get backupSave => 'Guardar';

  @override
  String get backupImport => 'Importar Copia';

  @override
  String get backupLocalTitle => 'Copia de Seguridad Local';

  @override
  String get backupDescriptionText =>
      'Exporte sus datos a un archivo o restaure desde una copia anterior. Recomendamos guardar en la carpeta Descargas.';

  @override
  String get backupPermissionError =>
      'Se requiere permiso de archivos para exportar.';

  @override
  String get backupRestoreConfirmTitle => '¿Restaurar Copia?';

  @override
  String get backupRestoreConfirmBody =>
      'Esta acción reemplazará todos los datos actuales con los datos do arquivo. ¿Desea continuar?';

  @override
  String get backupRestoreError =>
      'Error al importar la copia de seguridad. Verifique si el archivo es válido.';

  @override
  String get helpBackupExportTitle => 'Exportar Copia de Seguridad';

  @override
  String get helpBackupExportDesc =>
      '1. Vaya a Ajustes → Copia de Seguridad\n2. Haga clic en \"Exportar\"\n3. Elija la carpeta \"Descargas\" y guarde el archivo .scannut\n\n✅ Sus datos están guardados en un archivo seguro en su móvil';

  @override
  String get helpBackupImportTitle => 'Restaurar Copia de Seguridad';

  @override
  String get helpBackupImportDesc =>
      '1. Vaya a Ajustes → Copia de Seguridad\n2. Haga clic en \"Importar\"\n3. Seleccione el archivo .scannut';

  @override
  String get helpSecurityTitle => 'PROTECCIÓN Y CIFRADO';

  @override
  String get helpSecuritySubtitle =>
      'La base de datos está protegida localmente. Mantenga su copia de seguridad actualizada para evitar la pérdida de la clave de acceso.';

  @override
  String get helpSecurityAesItem =>
      '🔒 Cifrado AES-256: Sus datos se mezclan para garantizar que nadie pueda leer el archivo fuera de esta aplicación.';

  @override
  String get helpSecurityKeyItem =>
      '🔑 Clave de Seguridad: La aplicación genera una clave única guardada en el almacenamiento seguro de su teléfono.';

  @override
  String get helpSecurityWarningItem =>
      '⚠️ Atención: Si borra todos los datos del sistema o formatea el teléfono sin una copia de seguridad externa, la clave puede perderse y los datos serán inaccesibles.';

  @override
  String get helpProSection => '💎 ScanNut Pro';

  @override
  String get helpPrivacySection => '🔒 Privacidad y Seguridad';

  @override
  String get helpProBenefitsTitle => 'Beneficios de la Suscripción';

  @override
  String get helpProBenefitsList =>
      '✅ Análisis ilimitados\n✅ Informes PDF completos\n✅ Planes de alimentación personalizados\n✅ Red de socios ampliada\n✅ Soporte prioritario';

  @override
  String get helpAppBarTitle => 'Ayuda y Documentación';

  @override
  String get helpPetModule => '🐾 Módulo de Mascotas';

  @override
  String get helpPlantModule => '🌿 Módulo de Plantas';

  @override
  String get helpFoodModule => '🍎 Módulo de Alimentos';

  @override
  String get helpFaqSection => '❓ Preguntas Frecuentes';

  @override
  String get helpSupportSection => '📞 Soporte';

  @override
  String get helpPetBreedTitle => 'Identificación de Raza';

  @override
  String get helpPetBreedDesc =>
      'Tome una foto de su mascota y reciba:\n• Identificación de la raza\n• Perfil biológico completo\n• Recomendaciones de cuidado\n• Plan de alimentación personalizado';

  @override
  String get helpPetWoundTitle => 'Análisis de Heridas';

  @override
  String get helpPetWoundDesc =>
      'Triaje visual de lesiones:\n• Descripción clínica detallada\n• Posibles causas\n• Nivel de urgencia (Verde/Amarillo/Rojo)\n• Primeros auxilios\n⚠️ ¡NO sustituye la consulta veterinaria!';

  @override
  String get helpPetDossierTitle => 'Expediente Médico Completo';

  @override
  String get helpPetDossierDesc =>
      'Gestione la salud de su mascota:\n• Historial de vacunas\n• Monitoreo de peso\n• Análisis de laboratorio (OCR)\n• Agenda de eventos\n• Red de apoyo (vets, pet shops)';

  @override
  String get helpPlantIdTitle => 'Identificación Botánica';

  @override
  String get helpPlantIdDesc =>
      'Descubra todo sobre las plantas:\n• Nombre científico y popular\n• Familia botánica\n• Cuidados necesarios (agua, luz, suelo)\n• Toxicidad para mascotas y niños\n• Poderes biofílicos';

  @override
  String get helpFoodAnalysisTitle => 'Análisis Nutricional';

  @override
  String get helpFoodAnalysisDesc =>
      'Información nutricional instantánea:\n• Calorías, proteínas, carbohidratos, grasas\n• Comparación con metas diarias\n• Historial de análisis\n• Planificación semanal';

  @override
  String get helpNeedSupportTitle => '¿Necesita Ayuda?';

  @override
  String get helpSupportDesc =>
      '📧 Email: abreuretto72@gmail.com\n🌐 GitHub: github.com/abreuretto72/ScanNut\n📱 Versión: 1.0.0';

  @override
  String get faqOfflineQ => '¿La aplicación funciona sin conexión?';

  @override
  String get faqOfflineA =>
      'No. ScanNut necesita internet para enviar fotos a la IA de Google Gemini y recibir análisis.';

  @override
  String get faqPhotosQ => '¿Se guardan mis fotos?';

  @override
  String get faqPhotosA =>
      'No. Las fotos se envían para su análisis y se eliminan automáticamente después del procesamiento. Solo los resultados se guardan en el historial.';

  @override
  String get faqDevicesQ => '¿Puedo usarlo en varios teléfonos?';

  @override
  String get faqDevicesA =>
      'Actualmente, ScanNut guarda los datos localmente en su dispositivo.';

  @override
  String get faqWoundQ => '¿El análisis de heridas sustituye al veterinario?';

  @override
  String get faqWoundA =>
      '¡NO! El análisis es solo un triaje informativo. SIEMPRE consulte a un veterinario para el diagnóstico y tratamiento.';

  @override
  String get privacySecurityTitle => 'Seguridad y Protección de Datos';

  @override
  String get privacySecurityBody =>
      'ScanNut prioriza la privacidad del usuario a través de una arquitectura de datos local. Utilizamos cifrado de grado militar (AES-256) para cifrar la base de datos almacenada en su dispositivo. Las claves de seguridad se mantienen en un entorno aislado (Keystore/Keychain), lo que garantiza que, incluso en caso de pérdida del dispositivo, los datos permaneciam inaccesibles sin las credenciales o claves del sistema adecuadas.\n\nEl usuario es consciente de que, dado que no utilizamos almacenamiento en la nube, el mantenimiento y la seguridad de los archivos de Copia de Seguridad Local exportados son de su exclusiva responsabilidad.';

  @override
  String get helpMenuTitle => 'Cardápios e Lista de Compras';

  @override
  String get helpMenuGenTitle => '🗓️ Geração de Cardápios';

  @override
  String get helpMenuGenDesc =>
      'No ScanNut, você tem total controle sobre como e quando seu cardápio é gerado.\n\nVocê pode escolher entre três modos de geração:\n• Cardápio semanal — para 7 dias a partir da data escolhida\n• Cardápio mensal — para 30 dias consecutivos\n• Cardápio personalizado — escolha a data de início e a data de fim (até 60 dias)\n\nSempre que você gerar um cardápio, o app mostrará um filtro para que você possa confirmar ou ajustar suas escolhas antes da geração.';

  @override
  String get helpMenuHistTitle => '💾 Histórico de Cardápios';

  @override
  String get helpMenuHistDesc =>
      'Todos os cardápios gerados ficam salvos no histórico do app.\n\nIsso permite que você:\n• Consulte cardápios antigos\n• Gere novas versões sem perder as anteriores\n• Edite cardápios já criados\n• Exclua cardápios que não deseja mais manter\n\nNada é apagado automaticamente sem a sua confirmação.';

  @override
  String get helpMenuObjTitle => '🎯 Objetivos Nutricionais';

  @override
  String get helpMenuObjDesc =>
      'Ao gerar um cardápio, você pode escolher o objetivo nutricional, como:\n• Manter o peso\n• Emagrecimento\n• Alimentação equilibrada\n\nO objetivo influencia a escolha dos alimentos e a distribuição das calorias.';

  @override
  String get helpMenuPrefTitle => '🥗 Preferências Alimentares';

  @override
  String get helpMenuPrefDesc =>
      'Você também pode informar preferências alimentares, como:\n• Sem glúten\n• Sem lactose\n• Vegetariano\n\nEssas opções são opcionais. Se nenhuma for selecionada, o cardápio será gerado no formato padrão.';

  @override
  String get helpMenuEditTitle => '✏️ Edição de Ingredientes';

  @override
  String get helpMenuEditDesc =>
      'Após gerar um cardápio, você pode editar os ingredientes de qualquer dia.\n\nÉ possível:\n• Ajustar ingredientes\n• Alterar quantidades\n• Adicionar ou remover itens\n\nSempre que um ingrediente é alterado, as listas de compras são atualizadas automaticamente.';

  @override
  String get helpMenuShopTitle => '🛒 Lista de Compras Semanal';

  @override
  String get helpMenuShopDesc =>
      'O ScanNut gera listas de compras organizadas para facilitar sua ida ao mercado.\n\nImportante:\n• As listas de compras são sempre SEMANAIS\n• Mesmo em cardápios mensais ou personalizados\n• Os itens são consolidados (não se repetem)\n• A quantidade total a comprar é sempre exibida\n• A lista pode ser impressa em PDF com checkbox para marcar os itens';

  @override
  String get helpMenuPdfTitle => '📄 PDF do Cardápio';

  @override
  String get helpMenuPdfDesc =>
      'Ao gerar o PDF:\n• O cardápio é organizado por semanas\n• Cada semana possui sua própria lista de compras\n• Ideal para imprimir e usar no dia a dia';

  @override
  String get helpMenuTipTitle => 'ℹ️ Dica Importante';

  @override
  String get petTechnicalDetails => 'Detalhes Técnicos';

  @override
  String get petObservedSigns => 'Sinais Observados';

  @override
  String get petHomeCare => 'Cuidados em Casa';

  @override
  String get petVetCare => 'Cuidados Veterinários';

  @override
  String get petResult => 'Resultado';

  @override
  String get petNoRelevantChanges => 'Nenhuma alteração relevante detectada';

  @override
  String get commonNormal => 'Normal';

  @override
  String get commonModerate => 'Moderado';

  @override
  String get commonShare => 'Compartilhar';

  @override
  String get petResult_viewProfile => 'Ver Perfil do Pet';

  @override
  String get helpMenuTipDesc =>
      'Sempre revise o resumo antes de gerar um cardápio.\nAssim você garante que o período, o objetivo e as preferências estão corretos.';

  @override
  String get petAnalysisDisclaimer =>
      'Este contenido es generado por IA y debe usarse solo como referencia informativa. No sustituye el diagnóstico veterinario profesional.';

  @override
  String get petLabelUrgencyLevel => 'Nivel de Urgencia';

  @override
  String get petLabelConfidence => 'Confiabilidad';

  @override
  String get petLabelDiagnosis => 'Diagnóstico';

  @override
  String get petLabelVisualAspects => 'Aspectos Visuales';

  @override
  String get petLabelPossibleCauses => 'Causas Posibles';

  @override
  String get petLabelRecommendations => 'Recomendaciones';

  @override
  String get petLabelBreed => 'Raza';

  @override
  String get petLabelSpecies => 'Especie';

  @override
  String get petLabelColor => 'Color';

  @override
  String get petLabelCoatType => 'Tipo de Pelaje';

  @override
  String get petLabelSize => 'Tamaño';

  @override
  String get petLabelLifeExpectancy => 'Esperanza de Vida';

  @override
  String get petLabelOrigin => 'Origen';

  @override
  String get petLabelTemperament => 'Temperamento';

  @override
  String get petLabelPersonality => 'Personalidad';

  @override
  String get petLabelSocialBehavior => 'Comportamento Social';

  @override
  String get petLabelIdentification => 'Identificación';

  @override
  String get petLabelGrowthCurve => 'Curva de Crecimiento';

  @override
  String get petLabelNutrition => 'Nutrición';

  @override
  String get petLabelGrooming => 'Higiene';

  @override
  String get petLabelHealth => 'Salud';

  @override
  String get petLabelLifestyle => 'Estilo de Vida';

  @override
  String get petLabelBehavior => 'Comportamiento';

  @override
  String get petMenuFilterTitle => 'Generar Menú de Mascota';

  @override
  String get petMenuModeWeekly => 'Semanal (7 días)';

  @override
  String get petMenuModeMonthly => 'Mensual (28 días)';

  @override
  String get petMenuModeCustom => 'Personalizado';

  @override
  String get petMenuStartDate => 'Fecha de Inicio';

  @override
  String get petMenuEndDate => 'Fecha de Fin';

  @override
  String get petMenuGenerateBtn => 'Generar Menú';

  @override
  String get petMenuDateRangeError =>
      'El período no puede exceder los 60 días.';

  @override
  String get petMenuSuccess => '¡Menú generado con éxito!';

  @override
  String get petMenuShoppingList => 'Lista de Compras';

  @override
  String get petMenuShoppingListEmpty => 'Ningún artículo en la lista.';

  @override
  String get petTabGenerate => 'Gerar Cardápio';

  @override
  String get petTabHistory => 'Histórico';

  @override
  String get petMenuDeleteWeekConfirm => 'Excluir esta semana do histórico?';

  @override
  String get petMenuDeleteDayConfirm => 'Excluir o cardápio deste dia?';

  @override
  String get petMenuEditDayTitle => 'Editar Refeições do Dia';

  @override
  String petMenuGeneratePdfMulti(int count) {
    return 'Gerar PDF ($count semanas)';
  }

  @override
  String get petMenuSelectionClear => 'Limpar seleção';

  @override
  String get petMenuEmptyHistory =>
      'Nenhum histórico encontrado. Gere um cardápio para começar!';

  @override
  String get petMenuEditIngredientsHint =>
      'Edite os ingredientes ou descrição...';

  @override
  String get petMenuSaveSuccess => 'Alterações salvas com sucesso!';

  @override
  String get petMenuDeletedSuccess => 'Item excluído com sucesso!';

  @override
  String get petMenuPdfGenerated => 'PDF gerado com sucesso!';

  @override
  String get petViewMenu => 'Ver Cardápio';

  @override
  String get commonItem => 'Item';

  @override
  String get commonQuantity => 'Quantidade';

  @override
  String get commonCategory => 'Categoria';

  @override
  String get dietTypeLabel => 'Tipo de Dieta';

  @override
  String get petDietGeneral => 'Geral (Sem restrição)';

  @override
  String get dietRenal => 'Renal';

  @override
  String get dietHepatic => 'Hepática';

  @override
  String get dietGastrointestinal => 'Gastrointestinal';

  @override
  String get dietHypoallergenic => 'Hipoalergênica';

  @override
  String get dietObesity => 'Obesidade (Perda de peso)';

  @override
  String get dietDiabetes => 'Diabetes';

  @override
  String get dietCardiac => 'Cardíaca';

  @override
  String get dietUrinary => 'Urinária';

  @override
  String get dietMuscleGain => 'Ganho muscular';

  @override
  String get dietPediatric => 'Infantil';

  @override
  String get dietGrowth => 'Crescimento';

  @override
  String get dietOther => 'Outra';

  @override
  String get dietOtherHint => 'Especifique (máx 60 caracteres)';

  @override
  String get dietRequiredError => 'Selecione um tipo de dieta';

  @override
  String get dietOtherRequiredError => 'Especifique a dieta';

  @override
  String get petEvent_addTitle => 'Registrar Evento';

  @override
  String get petEvent_notes => 'Notas/Observações';

  @override
  String get petEvent_save => 'Salvar Evento';

  @override
  String get petEvent_cancel => 'Cancelar';

  @override
  String get petEvent_details => 'Detalhes Adicionais';

  @override
  String get petEvent_group_food => 'Alimentação';

  @override
  String get petEvent_group_health => 'Saúde';

  @override
  String get petEvent_group_elimination => 'Fezes/Urina';

  @override
  String get petEvent_group_grooming => 'Higiene';

  @override
  String get petEvent_group_activity => 'Atividade';

  @override
  String get petEvent_group_behavior => 'Comportamento';

  @override
  String get petEvent_group_schedule => 'Agenda';

  @override
  String get petEvent_group_media => 'Mídia';

  @override
  String get petEvent_group_metrics => 'Métricas';

  @override
  String get petEvent_group_medication => 'Medicação';

  @override
  String get petEvent_group_documents => 'Documentos';

  @override
  String get petEvent_group_exams => 'Exames';

  @override
  String get petEvent_group_allergies => 'Alergias';

  @override
  String get petEvent_group_dentistry => 'Odontologia';

  @override
  String get petEvent_group_other => 'Outros';

  @override
  String get petEvent_savedSuccess => 'Evento registrado ✅';

  @override
  String get petEvent_saveError => 'Não foi possível salvar. Tente novamente.';

  @override
  String get petEvent_attachError => 'Não foi possível anexar este arquivo.';

  @override
  String get petEvent_todayCount => 'Hoje';

  @override
  String get petEvent_historyTitle => 'Linha do Tempo';

  @override
  String get petEvent_includeInPdf => 'Incluir no Relatório PDF';

  @override
  String get petEvent_emptyHistory => 'Nenhum evento registrado ainda.';

  @override
  String get petEvent_group => 'Grupo';

  @override
  String get petEvent_type => 'Subtipo';

  @override
  String get petEvent_reportTitle => 'Relatório de Eventos do Pet';

  @override
  String get petEvent_generateReport => 'Gerar Relatório (PDF)';

  @override
  String get petEvent_reportCustom => 'Personalizado';

  @override
  String get petEvent_reportWeekly => 'Semanal';

  @override
  String get petEvent_reportMonthly => 'Mensal';

  @override
  String get petEvent_reportStartDate => 'Data Inicial';

  @override
  String get petEvent_reportEndDate => 'Data Final';

  @override
  String get petEvent_reportFilterGroup => 'Filtrar por Grupo';

  @override
  String get petEvent_reportIncludesOnlyPdf => 'Apenas marcados para PDF';

  @override
  String get petEvent_reportSuccess => 'PDF gerado e salvo em Downloads ✅';

  @override
  String get petEvent_reportError => 'Erro ao gerar PDF';

  @override
  String get petEvent_reportShare => 'Compartilhar Relatório';

  @override
  String get petEvent_reportSummary => 'Resumo do Período';

  @override
  String get petEvent_reportTotal => 'Total de Eventos';

  @override
  String get petEvent_reportPeriod => 'Período';

  @override
  String get lastUpdated => 'Atualizado em';

  @override
  String get petEdit => 'Editar Perfil';

  @override
  String get petDelete => 'Excluir Pet';

  @override
  String get petMenuGenerate => 'Gerar Cardápio';

  @override
  String get feedingEventGroupLabel => 'Grupo de Evento';

  @override
  String get feedingEventTypeLabel => 'Tipo de Ocorrência';

  @override
  String get feedingEventSeverityLabel => 'Gravidade';

  @override
  String get feedingEventAcceptanceLabel => 'Aceitação';

  @override
  String get feedingEventQuantityLabel => 'Quantidade Ingerida';

  @override
  String get feedingEventRelatedToMeal => 'Relacionado à Refeição';

  @override
  String get feedingGroup_normalFeeding => 'Alimentação Normal';

  @override
  String get feedingGroup_behavioralOccurrence => 'Ocorrência Comportamental';

  @override
  String get feedingGroup_digestiveIntercurrence => 'Intercorrência Digestiva';

  @override
  String get feedingGroup_intestinalIntercurrence =>
      'Intercorrência Intestinal';

  @override
  String get feedingGroup_nutritionalMetabolic => 'Nutricional/Metabólica';

  @override
  String get feedingGroup_therapeuticDiet => 'Dieta Terapêutica';

  @override
  String get feedingType_mealCompleted => 'Refeição realizada';

  @override
  String get feedingType_mealDelayed => 'Refeição atrasada';

  @override
  String get feedingType_mealSkipped => 'Refeição pulada';

  @override
  String get feedingType_foodChange => 'Troca de alimento';

  @override
  String get feedingType_reducedIntake => 'Redução da ingestão';

  @override
  String get feedingType_increasedAppetite => 'Aumento do apetite';

  @override
  String get feedingType_reluctantToEat => 'Relutância em comer';

  @override
  String get feedingType_eatsSlowly => 'Come devagar';

  @override
  String get feedingType_eatsTooFast => 'Come muito rápido';

  @override
  String get feedingType_selectiveEating => 'Seleciona alimento';

  @override
  String get feedingType_hidesFood => 'Esconde comida';

  @override
  String get feedingType_aggressiveWhileEating => 'Agressividade ao comer';

  @override
  String get feedingType_anxietyWhileEating => 'Ansiedade ao se alimentar';

  @override
  String get feedingType_vomitingImmediate => 'Vômito imediato';

  @override
  String get feedingType_vomitingDelayed => 'Vômito tardio';

  @override
  String get feedingType_nausea => 'Náusea';

  @override
  String get feedingType_choking => 'Engasgo';

  @override
  String get feedingType_regurgitation => 'Regurgitação';

  @override
  String get feedingType_excessiveFlatulence => 'Flatulência excessiva';

  @override
  String get feedingType_apparentAbdominalPain => 'Dor abdominal aparente';

  @override
  String get feedingType_diarrhea => 'Diarreia';

  @override
  String get feedingType_softStool => 'Fezes amolecidas';

  @override
  String get feedingType_constipation => 'Constipação';

  @override
  String get feedingType_stoolWithMucus => 'Fezes com muco';

  @override
  String get feedingType_stoolWithBlood => 'Fezes com sangue';

  @override
  String get feedingType_stoolColorChange => 'Alteração de cor das fezes';

  @override
  String get feedingType_abnormalStoolOdor => 'Odor fecal anormal';

  @override
  String get feedingType_weightGain => 'Ganho de peso';

  @override
  String get feedingType_weightLoss => 'Perda de peso';

  @override
  String get feedingType_excessiveThirst => 'Sede excessiva';

  @override
  String get feedingType_lowWaterIntake => 'Baixa ingestão de água';

  @override
  String get feedingType_suspectedFoodIntolerance =>
      'Suspeita de intolerância alimentar';

  @override
  String get feedingType_suspectedFoodAllergy =>
      'Suspeita de alergia alimentar';

  @override
  String get feedingType_adverseFoodReaction => 'Reação adversa ao alimento';

  @override
  String get feedingType_dietNotTolerated => 'Dieta não tolerada';

  @override
  String get feedingType_therapeuticDietRefusal =>
      'Recusa de dieta terapêutica';

  @override
  String get feedingType_clinicalImprovementWithDiet =>
      'Melhora clínica com dieta';

  @override
  String get feedingType_clinicalWorseningAfterMeal =>
      'Piora clínica após refeição';

  @override
  String get feedingType_needForDietAdjustment =>
      'Necessidade de ajuste de dieta';

  @override
  String get feedingType_feedingWithMedication =>
      'Alimentação associada a medicamento';

  @override
  String get feedingType_assistedFeeding =>
      'Alimentação assistida (seringa/sonda)';

  @override
  String get feedingSeverity_none => 'Sem gravidade';

  @override
  String get feedingSeverity_mild => 'Leve';

  @override
  String get feedingSeverity_moderate => 'Moderada';

  @override
  String get feedingSeverity_severe => 'Grave';

  @override
  String get feedingAcceptance_good => 'Boa';

  @override
  String get feedingAcceptance_partial => 'Parcial';

  @override
  String get feedingAcceptance_refused => 'Recusou';

  @override
  String get feedingClinicalIntercurrence => 'Intercorrência Clínica';

  @override
  String get feedingMarkAsClinical => 'Marcar como intercorrência clínica';

  @override
  String get feedingClinicalAlert =>
      '⚠️ Este evento será destacado no PDF como intercorrência clínica';

  @override
  String get healthEventTitle => 'Registrar Saúde';

  @override
  String get healthEventSelectType => 'Selecione o tipo de ocorrência';

  @override
  String get healthEventSeverityLabel => 'Gravidade';

  @override
  String get healthEventEmergencyToggle => 'Marcar como emergência';

  @override
  String get healthEventEmergencyAlert =>
      '🚨 Se o pet estiver em risco, procure atendimento veterinário imediatamente.';

  @override
  String get healthEventDetailsHint => 'Registrar a ocorrência em detalhes';

  @override
  String get healthEventSpeechToText => 'Usar voz para registrar';

  @override
  String get healthEventListening => 'Ouvindo...';

  @override
  String get healthEventSpeechError =>
      'Erro ao reconhecer voz. Tente novamente.';

  @override
  String get health_group_daily_monitoring => 'Monitoramento Diário';

  @override
  String get health_group_acute_symptoms => 'Sintomas Agudos';

  @override
  String get health_group_infectious => 'Infeccioso/Parasitário';

  @override
  String get health_group_dermatological => 'Dermatológico';

  @override
  String get health_group_mobility => 'Mobilidade/Ortopédico';

  @override
  String get health_group_neurological => 'Neurológico/Sensorial';

  @override
  String get health_group_treatment => 'Tratamento/Procedimento';

  @override
  String get health_type_temperature_check => 'Verificação de Temperatura';

  @override
  String get health_type_weight_check => 'Verificação de Peso';

  @override
  String get health_type_appetite_monitoring => 'Monitoramento de Apetite';

  @override
  String get health_type_hydration_check => 'Verificação de Hidratação';

  @override
  String get health_type_energy_level => 'Nível de Energia';

  @override
  String get health_type_behavior_observation => 'Observação de Comportamento';

  @override
  String get health_type_fever => 'Febre';

  @override
  String get health_type_vomiting => 'Vômito';

  @override
  String get health_type_diarrhea => 'Diarreia';

  @override
  String get health_type_lethargy => 'Letargia';

  @override
  String get health_type_loss_of_appetite => 'Perda de Apetite';

  @override
  String get health_type_excessive_thirst => 'Sede Excessiva';

  @override
  String get health_type_difficulty_breathing => 'Dificuldade Respiratória';

  @override
  String get health_type_coughing => 'Tosse';

  @override
  String get health_type_sneezing => 'Espirros';

  @override
  String get health_type_nasal_discharge => 'Secreção Nasal';

  @override
  String get health_type_suspected_infection => 'Suspeita de Infecção';

  @override
  String get health_type_wound_infection => 'Infecção em Ferida';

  @override
  String get health_type_ear_infection => 'Infecção de Ouvido';

  @override
  String get health_type_eye_infection => 'Infecção Ocular';

  @override
  String get health_type_urinary_infection => 'Infecção Urinária';

  @override
  String get health_type_parasite_detected => 'Parasita Detectado';

  @override
  String get health_type_tick_found => 'Carrapato Encontrado';

  @override
  String get health_type_flea_infestation => 'Infestação de Pulgas';

  @override
  String get health_type_skin_rash => 'Erupção Cutânea';

  @override
  String get health_type_itching => 'Coceira';

  @override
  String get health_type_hair_loss => 'Queda de Pelo';

  @override
  String get health_type_hot_spot => 'Hot Spot';

  @override
  String get health_type_wound => 'Ferida';

  @override
  String get health_type_abscess => 'Abscesso';

  @override
  String get health_type_allergic_reaction => 'Reação Alérgica';

  @override
  String get health_type_swelling => 'Inchaço';

  @override
  String get health_type_limping => 'Manqueira';

  @override
  String get health_type_joint_pain => 'Dor Articular';

  @override
  String get health_type_difficulty_walking => 'Dificuldade para Andar';

  @override
  String get health_type_stiffness => 'Rigidez';

  @override
  String get health_type_muscle_weakness => 'Fraqueza Muscular';

  @override
  String get health_type_fall => 'Queda';

  @override
  String get health_type_fracture_suspected => 'Suspeita de Fratura';

  @override
  String get health_type_seizure => 'Convulsão';

  @override
  String get health_type_tremors => 'Tremores';

  @override
  String get health_type_disorientation => 'Desorientação';

  @override
  String get health_type_loss_of_balance => 'Perda de Equilíbrio';

  @override
  String get health_type_vision_problems => 'Problemas de Visão';

  @override
  String get health_type_hearing_problems => 'Problemas de Audição';

  @override
  String get health_type_head_tilt => 'Inclinação da Cabeça';

  @override
  String get health_type_medication_administered => 'Medicamento Administrado';

  @override
  String get health_type_vaccine_given => 'Vacina Aplicada';

  @override
  String get health_type_wound_cleaning => 'Limpeza de Ferida';

  @override
  String get health_type_bandage_change => 'Troca de Curativo';

  @override
  String get health_type_vet_visit => 'Consulta Veterinária';

  @override
  String get health_type_surgery => 'Cirurgia';

  @override
  String get health_type_emergency_care => 'Atendimento de Emergência';

  @override
  String get health_type_hospitalization => 'Internação';

  @override
  String get petActionAgenda => 'Ocorrência';

  @override
  String get petActionMenu => 'Cardápio';

  @override
  String get petAgendaTitle => 'Agenda do Pet';

  @override
  String get foodHelpTitle => 'Exemplos de Ocorrências';

  @override
  String get foodHelpRoutine =>
      '• Rotina: Alimentação normal, recusa ou aumento de apetite';

  @override
  String get foodHelpAcute =>
      '• Agudo: Vômito pós-refeição, engasgo ou dificuldade';

  @override
  String get foodHelpDietChange =>
      '• Dieta: Troca de ração, início de AN ou ingestão indevida';

  @override
  String get foodHelpSupplements => '• Suplementos: Vitaminas ou probióticos';

  @override
  String get foodHelpHydration =>
      '• Hidratação: Consumo excessivo ou recusa de água';

  @override
  String get petAttachmentAnalyzeTitle => 'Análise Inteligente';

  @override
  String get petAttachmentAnalyzeQuestion => 'Como deseja analisar este anexo?';

  @override
  String get petAttachmentOptionPhoto => 'Analisar Foto (Visual)';

  @override
  String get petAttachmentOptionOCR => 'Ler Documento (OCR)';

  @override
  String get petAttachmentAnalyzeButton => 'Analisar';

  @override
  String get petAttachmentAnalysing => 'C.Ai analisando...';

  @override
  String get petAttachmentAnalysisSuccess => 'Análise concluída!';

  @override
  String get petAttachmentAnalysisError => 'Falha na análise.';

  @override
  String get petAnalysisViewResult => 'Ver Análise IA';

  @override
  String get petAttachmentNameTitle => 'Nomear Anexo';

  @override
  String get petAttachmentNameHint => 'Ex: Exame, Receita...';

  @override
  String get analysis_title => 'Resultado da Análise IA';

  @override
  String get btn_close => 'Entendi';

  @override
  String get petEvent_errorRequired => 'Por favor, descreva a ocorrência.';

  @override
  String get petProfile_breed => 'Raça';

  @override
  String get petProfile_breedHint => 'Ex: Labrador/SRD';

  @override
  String get petProfile_reproductiveStatus => 'Status Reprodutivo';

  @override
  String get petProfile_neutered => 'Castrado';

  @override
  String get petProfile_intact => 'Não Castrado (Inteiro)';

  @override
  String get petProfile_errorBreed => 'Informe a raça.';

  @override
  String get petProfile_errorReproductive => 'Informe o status reprodutivo.';

  @override
  String get petProfile_errorGender => 'Selecione o sexo.';

  @override
  String get gender_male => 'Macho';

  @override
  String get gender_female => 'Fêmea';

  @override
  String get gender_required => 'Selecione o sexo do pet';

  @override
  String get breed_required => 'Informe a raça';

  @override
  String get petProfile_male => 'Macho';

  @override
  String get petProfile_female => 'Fêmea';

  @override
  String get showEvents => 'Mostrar Eventos';

  @override
  String petMenuCalculating(String name) {
    return 'Calculando a melhor dieta para $name...';
  }

  @override
  String get petMenuIncompleteTitle => 'Perfil Incompleto';

  @override
  String get petMenuIncompleteProfile =>
      'Dados incompletos. Por favor, preencha o perfil do pet (Peso, Idade, Sexo, Status Reprodutivo) para garantir uma dieta segura.';

  @override
  String get commonRequired => 'Campo obrigatório';

  @override
  String get detecting_pet => 'Identificando seu pet...';

  @override
  String get auto_fill_success => 'Campos preenchidos automaticamente!';

  @override
  String is_pet_breed_correct(Object breed) {
    return 'Identificamos que seu pet é um $breed. Isso está correto?';
  }

  @override
  String get species_label => 'Espécie';

  @override
  String get species_dog => 'Cão';

  @override
  String get species_cat => 'Gato';

  @override
  String get petMenuSpeciesRequired =>
      'Selecione se o seu pet é um cão ou gato para continuar.';

  @override
  String get missing_species_alert =>
      'Selecione se o seu pet é um cão ou gato para continuar.';

  @override
  String get reliability_label => 'Confiança da Análise';

  @override
  String get activitySedentary => 'Sedentário';

  @override
  String get activityModerate => 'Moderado';

  @override
  String get activityActive => 'Ativo';

  @override
  String get activityVeryActive => 'Muito Ativo';

  @override
  String get bathFrequencyWeekly => 'Semanal';

  @override
  String get bathFrequencyBiweekly => 'Quinzenal';

  @override
  String get bathFrequencyMonthly => 'Mensal';

  @override
  String get bathFrequencyAsNeeded => 'Sob Demanda';

  @override
  String get reproductiveNeutered => 'Castrado';

  @override
  String get reproductiveIntact => 'Inteiro';

  @override
  String get reproductiveNursing => 'Gesta/Lactante';

  @override
  String get petFoodRestrictions => 'Restricciones Alimentarias';

  @override
  String get petFoodRestrictionsDesc =>
      'Ingredientes prohibidos o a evitar (ej: sin pollo, sin gluten).';

  @override
  String get petAddRestriction => 'Añadir restricción';

  @override
  String get petDossierTitle => 'Expediente Veterinario 360°';

  @override
  String get petDossierDisclaimer =>
      'Este informe se basa en análisis de imagen por IA y no reemplaza la consulta veterinaria profesional.';

  @override
  String get petDossierAnalyzedImage => 'Imagen Analizada';

  @override
  String get petDossierViewFull => 'Ver completo';

  @override
  String get petDossierSignals => 'Señales';

  @override
  String get petDossierRisk => 'Riesgo';

  @override
  String get petDossierPrecision => 'Precisión';

  @override
  String get petDossierStatus => 'Estado';

  @override
  String get petSectionIdentity => 'Identidad';

  @override
  String get petSectionPreventive => 'Salud Preventiva';

  @override
  String get petSectionGrowth => 'Crecimiento';

  @override
  String get petActionViewProfile => 'Ver Perfil Completo';

  @override
  String get petActionSharePDF => 'Compartilhar PDF';

  @override
  String petIndexing_aiTitle(Object type) {
    return 'Análisis de IA: $type';
  }

  @override
  String get petIndexing_aiNotes =>
      'Análisis clínico generado por Inteligencia Artificial.';

  @override
  String petIndexing_occurrenceTitle(Object title) {
    return 'Ocurrencia: $title';
  }

  @override
  String petIndexing_agendaTitle(Object attendant, Object pet) {
    return '$attendant + $pet';
  }

  @override
  String petIndexing_partnerFavorited(Object name) {
    return 'Socio Favorito: $name';
  }

  @override
  String petIndexing_partnerScheduled(Object name) {
    return 'Interacción programada con $name';
  }

  @override
  String petIndexing_partnerContacted(Object name) {
    return 'Contactado vía WhatsApp/GPS: $name';
  }

  @override
  String petIndexing_partnerLinked(Object name) {
    return 'Socio vinculado al perfil: $name';
  }

  @override
  String get petIndexing_partnerInteractionNotes =>
      'Interacción registrada vía Radar Geo.';

  @override
  String petIndexing_vaultTitle(Object name) {
    return 'Archivo: $name';
  }

  @override
  String get petIndexing_vaultNotes => 'Documento indexado en Media Vault.';

  @override
  String get petEvent_tapToViewDetails => 'Toque para ver detalles';

  @override
  String petIndexing_taskCompleted(Object task) {
    return 'Tarea completada: $task';
  }

  @override
  String get agendaLoadError => 'Erro ao carregar a agenda. Tente novamente.';

  @override
  String get pdfPrecision => 'Precisión';

  @override
  String get soundAnalysisTitle => 'Análisis Vocal';

  @override
  String get soundAnalysisDesc =>
      'Identifique emociones y necesidades a través del ladrido o maullido.';

  @override
  String get soundRecording => 'Grabando...';

  @override
  String get soundProcessing => 'Analizando...';

  @override
  String get soundStartRecord => 'Toque para grabar';

  @override
  String get soundResultType => 'Tipo';

  @override
  String get soundResultEmotion => 'Emoción';

  @override
  String get soundResultAction => 'Recomendación';

  @override
  String get soundError => 'Error al analizar';

  @override
  String get soundEmotionSimple => 'Lo que siente';

  @override
  String get soundReasonSimple => 'Motivo probable';

  @override
  String get soundActionTip => 'Consejo rápido';

  @override
  String get soundUploadBtn => 'Subir Audio';

  @override
  String get petFoodCardTitle => 'Análisis de Etiqueta';

  @override
  String get petFoodVerdict => 'Veredicto';

  @override
  String get petFoodReason => 'Motivo';

  @override
  String get petFoodTip => 'Consejo Diario';

  @override
  String get petFoodStart => 'Analizar Etiqueta';

  @override
  String get petFoodError => 'Error de lectura';

  @override
  String get plansTabTitle => 'Planes';

  @override
  String get plansTabSubtitle =>
      'Información sobre planes, seguros y asistencia de salud de su mascota.';

  @override
  String get healthPlanToggle => '¿Tiene plan de salud veterinaria?';

  @override
  String get healthPlanOperator => 'Nombre del plan / operadora';

  @override
  String get healthPlanCoverage => '¿Qué cubre el plan?';

  @override
  String get healthPlanType => 'Tipo de atención';

  @override
  String get healthPlanNetwork => 'Red acreditada';

  @override
  String get healthPlanReimbursement => 'Reembolso';

  @override
  String get healthPlanValue => 'Valor mensual do plano (opcional)';

  @override
  String get healthPlanConsultations => 'Consultas';

  @override
  String get healthPlanExams => 'Exámenes';

  @override
  String get healthPlanSurgeries => 'Cirugías';

  @override
  String get healthPlanEmergencies => 'Emergencias';

  @override
  String get healthPlanHospitalization => 'Internación';

  @override
  String get healthPlanVaccines => 'Vacunas';

  @override
  String get healthPlanHelpText =>
      'Ayuda a reducir costos con consultas, exámenes y emergencias veterinarias.';

  @override
  String get assistancePlanToggle => '¿Tiene plan de asistencia o reembolso?';

  @override
  String get assistancePlanOperator => 'Nombre de la empresa / plan';

  @override
  String get assistancePlanReimbursementType => 'Tipo de reembolso';

  @override
  String get assistancePlanTotal => 'Total';

  @override
  String get assistancePlanPartial => 'Parcial';

  @override
  String get assistancePlanMaxValue =>
      'Valor máximo de reembolso (mensual o anual)';

  @override
  String get assistancePlanNeedsInvoice => '¿Exige factura para reembolso?';

  @override
  String get assistancePlanHelpText =>
      'Ideal para quien utiliza el veterinario de confianza y solicita reembolso posteriormente.';

  @override
  String get funeralPlanToggle => '¿Tiene plan funerario para mascotas?';

  @override
  String get funeralPlanOperator => 'Empresa / plan funerario';

  @override
  String get funeralPlanServices => 'Servicios incluidos';

  @override
  String get funeralPlanWake => 'Velatorio';

  @override
  String get funeralPlanIndivCremation => 'Cremación individual';

  @override
  String get funeralPlanCollCremation => 'Cremación colectiva';

  @override
  String get funeralPlanTransport => 'Traslado';

  @override
  String get funeralPlanMemorial => 'Urna o memorial';

  @override
  String get funeralPlan24h => '¿Atención 24h?';

  @override
  String get funeralPlanEmergencyContact => 'Contacto de emergencia';

  @override
  String get funeralPlanHelpText =>
      'Garantiza organización y apoyo en momentos delicados.';

  @override
  String get lifeInsurancePlanToggle =>
      '¿Tiene seguro de vida para la mascota?';

  @override
  String get lifeInsuranceInsurer => 'Aseguradora';

  @override
  String get lifeInsuranceInsuredValue => 'Valor asegurado';

  @override
  String get lifeInsuranceCoverages => 'Coberturas incluidas';

  @override
  String get lifeInsuranceDeath => 'Fallecimiento';

  @override
  String get lifeInsuranceGraveIllness => 'Enfermedad grave';

  @override
  String get lifeInsuranceEuthanasia =>
      'Eutanasia (cuando sea indicada por veterinario)';

  @override
  String get lifeInsuranceEconomicValue =>
      '¿La mascota tiene valor económico especial? (ej: competición)';

  @override
  String get lifeInsuranceHelpText =>
      'Indicado para mascotas con alto valor económico o funcional.';

  @override
  String get planTitleHealth => 'Salud de la Mascota';

  @override
  String get planTitleAssistance => 'Asistencia / Reembolso';

  @override
  String get planTitleFuneral => 'Plan Funerario';

  @override
  String get planTitleLife => 'Seguro de Vida';

  @override
  String get planObservations => 'Observaciones';

  @override
  String get petBodyAnalysisTitle => 'Analise Corporal & Postural';

  @override
  String get petBodyAnalysisDesc =>
      'Avalie o bem-estar fisico e sinais de dor atraves da postura.';

  @override
  String get petBodyHealthScore => 'Nivel de Bem-Estar';

  @override
  String get petBodySignals => 'Sinais Observados';

  @override
  String get petBodyAdvice => 'Dica de Cuidado';

  @override
  String get petBodyRelaxed => 'Relaxado & Saudavel';

  @override
  String get petBodyDiscomfort => 'Sinais de Desconforto';

  @override
  String get petBodyPain => 'Sinais de Dor ou Estresse';

  @override
  String get petBodyProcessing => 'Lendo Linguagem Corporal...';

  @override
  String get petBodyError => 'Falha na analise postural';

  @override
  String get petBodyDeleteConfirm => 'Excluir esta analise corporal?';

  @override
  String get labelSun => 'Sol';

  @override
  String get labelWater => 'Rega';

  @override
  String get labelSoil => 'Solo';

  @override
  String get pdfClinicalNotes => 'DETALHES DA ANÁLISE CLÍNICA';

  @override
  String get pdfPlansInsurance => 'PLANOS E SEGUROS';

  @override
  String get pdfNoInfo => 'Sem informação';

  @override
  String get pdfGeneralAnalysisHistory => 'HISTÓRICO DE ANÁLISES (IA)';

  @override
  String get pdfLabExams => 'EXAMES LABORATORIAIS';

  @override
  String get pdfDietType => 'Tipo de Dieta';

  @override
  String get pdfCaloricGoal => 'Meta Calórica Estimada';

  @override
  String get pdfWeeklyPlan => 'PLANO SEMANAL';

  @override
  String get pdfDay => 'Dia';

  @override
  String get pdfMeal => 'Refeição';

  @override
  String get pdfBrandSuggestions => 'SUGESTÕES DE MARCAS (INFORMATIVO)';

  @override
  String get pdfLegalDisclaimer =>
      '⚠️ AVISO LEGAL: Consulte sempre um veterinário antes de trocar a ração. Estas sugestões são baseadas no perfil do pet e não substituem uma consulta presencial.';

  @override
  String get pdfKnownAllergies => 'ALERGIAS CONHECIDAS';

  @override
  String get pdfPossibleDiagnosis => 'Diagnósticos';

  @override
  String get pdfPossibleCauses => 'Causas';

  @override
  String get pdfPartnerName => 'Nome';

  @override
  String get pdfPartnerSpecialty => 'Especialidade';

  @override
  String get pdfPartnerContact => 'Contato / Notas';

  @override
  String get pdfPartnerPhone => 'Tel';

  @override
  String get pdfPartnerEmail => 'Email';

  @override
  String get pdfPartnerNotes => 'Notas';

  @override
  String get pdfRadarTitle => 'RADAR GEO - SCANNUT';

  @override
  String get pdfRadarResults => 'RESULTADOS PRÓXIMOS';

  @override
  String get pdfDistanceLabel => 'DISTÂNCIA';

  @override
  String get pdfAddressLabel => 'ENDEREÇO';

  @override
  String get pdfDateLabel => 'Data';

  @override
  String get pdfShoppingListTitle => 'LISTA DE COMPRAS';

  @override
  String get pdfToxicPetsCats => 'TÓXICA: CÃES E GATOS';

  @override
  String get pdfToxicCats => 'TÓXICA: GATOS';

  @override
  String get pdfToxicDogs => 'TÓXICA: CÃES';

  @override
  String get pdfToxicAnimals => 'TÓXICA: ANIMAIS (PETS)';

  @override
  String get pdfToxicHumans => 'TÓXICA: HUMANOS';

  @override
  String get pdfCareLegendTitle => 'LEGENDA DE CUIDADOS (REQUISITOS)';

  @override
  String get pdfCareLegendLevels => 'Níveis de preenchimento:';

  @override
  String get pdfCareLegendDescription =>
      '1/4 Preenchido = Baixo | 2/4 Preenchido = Médio | Totalmente Preenchido = Alto';

  @override
  String get errorCapturePrefix => 'Erro na captura: ';

  @override
  String get errorGalleryPrefix => 'Erro ao abrir galeria: ';

  @override
  String get errorProcessingPrefix => 'Erro no processamento: ';

  @override
  String get pdfClinicalHistorySection => 'Histórico Clínico e Feridas';

  @override
  String get commonGeneral => 'Geral';

  @override
  String get pdfDiagnoses => 'Diagnósticos';

  @override
  String get pdfRecommendation => 'Recomendação';

  @override
  String get pdfFooterBranding => 'ScanNut App - Inteligência Animal';

  @override
  String get petUnknownBreed => 'Raça Desconhecida';

  @override
  String get plantNoSpecificDiagnosis => 'Sem diagnóstico específico.';

  @override
  String pdfShoppingListDescription(Object week) {
    return 'Esta lista consolidada refere-se aos itens necessários para a $week. Quantidades somadas e organizadas por setor.';
  }

  @override
  String get planSaveError =>
      'Não foi possível salvar o cardápio. Tente novamente.';

  @override
  String get plantAnalysisList => 'Ir para a lista de análises';

  @override
  String get commonAlert => 'ALERTA';

  @override
  String get commonGreen => 'Verde';

  @override
  String get commonYellow => 'Amarelo';

  @override
  String get commonRed => 'Vermelho';

  @override
  String get foodInNatura => 'In natura';

  @override
  String get commonNone => 'Nenhum';

  @override
  String petClinicalSignsCount(Object count) {
    return '$count sinais identificados';
  }

  @override
  String get deepAnalysisTitle => 'Análise Profunda 360°';

  @override
  String get labelIdentification => 'Identificação';

  @override
  String get labelBreed => 'Raça';

  @override
  String get labelOriginRegion => 'Região de Origem';

  @override
  String get labelMorphologyType => 'Tipo Morfológico';

  @override
  String get labelLineage => 'Linhagem';

  @override
  String get labelSize => 'Porte';

  @override
  String get labelLifespan => 'Expectativa de Vida';

  @override
  String get labelGrowthCurve => 'Curva de Crescimento';

  @override
  String get labelNutrition => 'Nutrição';

  @override
  String get labelKcalPuppy => 'Kcal Filhote';

  @override
  String get labelKcalAdult => 'Kcal Adulto';

  @override
  String get labelKcalSenior => 'Kcal Sênior';

  @override
  String get kcalPerDay => 'Kcal/dia';

  @override
  String get labelTargetNutrients => 'Nutrientes Alvo';

  @override
  String get labelWeight => 'Peso';

  @override
  String get labelHeight => 'Altura';

  @override
  String get labelCoat => 'Pelagem';

  @override
  String get labelColor => 'Cor';

  @override
  String get labelTemperament => 'Temperamento';

  @override
  String get labelEnergyLevel => 'Nível de Energia';

  @override
  String get labelSocialBehavior => 'Comportamento Social';

  @override
  String get labelClinicalSigns => 'Sinais Clínicos';

  @override
  String get labelGrooming => 'Cuidados & Higiene';

  @override
  String get labelCoatType => 'Tipo de Pelagem';

  @override
  String get labelGroomingFrequency => 'Frequência de Escovação';

  @override
  String get labelHealth => 'Saúde';

  @override
  String get labelPredispositions => 'Predisposições';

  @override
  String get labelPreventiveCheckup => 'Check-up Preventivo';

  @override
  String get labelLifestyle => 'Estilo de Vida';

  @override
  String get labelTrainingIntelligence => 'Inteligência / Treinamento';

  @override
  String get labelEnvironmentType => 'Ambiente Ideal';

  @override
  String get labelActivityLevel => 'Nível de Atividade';

  @override
  String get labelPersonality => 'Personalidade';

  @override
  String get labelEyes => 'Olhos';

  @override
  String get labelSkin => 'Pele';

  @override
  String get labelDental => 'Dental';

  @override
  String get labelOral => 'Oral';

  @override
  String get labelStool => 'Fezes';

  @override
  String get labelWounds => 'Feridas';

  @override
  String get pdfPlantDossierTitle => 'Dossiê Botânico';

  @override
  String get errorGeneratingPdf => 'Erro ao gerar PDF';

  @override
  String get plantSunFull => 'Sol Pleno';

  @override
  String get plantSunPartial => 'Meia Sombra';

  @override
  String get plantSunShade => 'Sombra Total';

  @override
  String get plantSunIndirect => 'Luz Indireta';

  @override
  String get tabDiagnosis => 'Diagnóstico';

  @override
  String get tabBiometrics => 'Biometria';

  @override
  String get tabEvolution => 'Evolução';

  @override
  String get sectionVisualDesc => 'Descrição Visual';

  @override
  String get sectionObservedFeatures => 'Características Observadas';

  @override
  String get sectionClinicalSigns => 'Sinais Clínicos';

  @override
  String get sectionProbableDiagnosis => 'Diagnóstico Provável';

  @override
  String get noDiagnosisListed => 'Nenhum diagnóstico listado';

  @override
  String get sectionRecommendation => 'Recomendação';

  @override
  String get sectionDepthAnalysis => 'Análise em Profundidade';

  @override
  String get analysis3DUnavailable => 'Análise 3D indisponível';

  @override
  String get sectionDetailedBiometrics => 'Biometria Detalhada';

  @override
  String get noBiometricsListed => 'Nenhuma biometria listada';

  @override
  String get analysisFirstRecord => 'Este é o primeiro registro de análise';

  @override
  String get paywallPerMonth => 'por mês';

  @override
  String get petProfileIncomplete => 'Perfil do pet incompleto';

  @override
  String pdfFoodAnalysisTitle(Object name) {
    return 'Análise Nutricional Completa';
  }

  @override
  String pdfErrorGeneration(Object error) {
    return 'Erro ao gerar PDF';
  }

  @override
  String get tooltipSavedRecipes => 'Receitas salvas';

  @override
  String get tooltipAutoSaved => 'Salvo automaticamente';

  @override
  String get historyTitleRecipes => 'Histórico de Receitas';

  @override
  String get tooltipExportPdf => 'Exportar PDF';

  @override
  String historyErrorLoading(Object error) {
    return 'Erro ao carregar histórico';
  }

  @override
  String get historyEmptyRecipes => 'Nenhuma receita salva ainda';

  @override
  String get btnViewDetails => 'Ver Detalhes';

  @override
  String labelMainIngredient(Object name) {
    return 'Ingrediente Principal';
  }

  @override
  String get labelFortnightly => 'Quinzenal';

  @override
  String get labCategoryBlood => 'Exame de Sangue';

  @override
  String get labCategoryUrine => 'Exame de Urina';

  @override
  String get labCategoryFeces => 'Exame de Fezes';

  @override
  String get labCategoryImaging => 'Exame de Imagem';

  @override
  String get btnGoToList => 'Ir para a lista';

  @override
  String get tooltipGenerateRecipes => 'Gerar receitas';

  @override
  String get foodConsultingChef => 'Consultando chef...';

  @override
  String get analysisSavedSuccess => 'Análise salva com sucesso!';

  @override
  String errorSaving(String error) {
    return 'Erro ao salvar: $error';
  }

  @override
  String get msgNoHistoryToExport => 'Nenhum histórico para exportar';

  @override
  String get pdfTitleRecipeBook => 'Caderno de Receitas';

  @override
  String get dialogClearHistoryTitle => 'Limpar Histórico?';

  @override
  String get dialogClearHistoryBody =>
      'Isso removerá todas as receitas salvas. Esta ação não pode ser desfeita.';

  @override
  String get homeBiometricTitle => 'Biometria';

  @override
  String get homeBiometricBody => 'Autentique-se para continuar';

  @override
  String get homeBiometricSuccess => 'Autenticação bem-sucedida';

  @override
  String get homeBiometricAction => 'Autenticar';

  @override
  String get loadingMsgDiet => 'Analisando dieta...';

  @override
  String get loadingMsgPlant => 'Analisando planta...';

  @override
  String get loadingMsgClinical => 'Analisando sinais clínicos...';

  @override
  String get loadingMsgStool => 'Analisando fezes...';

  @override
  String get loadingMsgPetId => 'Identificando pet...';

  @override
  String get loadingMsgWait => 'Aguarde...';

  @override
  String get errorGoogleAuth => 'Error de autenticación de Google';

  @override
  String errorGoogleAuthDetailMsg(String errorMessage) {
    return 'Detalles: $errorMessage';
  }

  @override
  String errorSearchFailed(String error) {
    return 'Busca falhou: $error';
  }

  @override
  String get radarTapToChangeRadius => 'Toque para alterar o raio';

  @override
  String get diagnosticTrace => 'Rastreamento de diagnóstico';

  @override
  String get tooltipHistoryReport => 'Informe del historial';

  @override
  String get errorMetadataMissing => 'Metadatos ausentes';

  @override
  String pdfTitleFoodHistory(String date) {
    return 'Historial Alimentario - $date';
  }

  @override
  String get logsCopied => 'Logs copiados';

  @override
  String get actionCopy => 'Copiar';

  @override
  String get viewTechDetails => 'Ver detalles técnicos';

  @override
  String get petTypeHealth => 'Salud';

  @override
  String get petTypeID => 'Identificación';

  @override
  String get errorOpenAnalysis => 'Error al abrir análisis';

  @override
  String get petNoName => 'Sin nombre';

  @override
  String get titleBotanyIntelligence => 'Inteligencia Botánica';

  @override
  String get petSelectRecordType => 'Seleccione el tipo de registro';

  @override
  String get petShowAll => 'Mostrar todos';

  @override
  String get vaccineV8V10 => 'V8/V10 (Polivalente)';

  @override
  String get vaccineRabies => 'Antirrábica';

  @override
  String get vaccineFlu => 'Gripe';

  @override
  String get vaccineGiardia => 'Giardia';

  @override
  String get vaccineLeishmania => 'Leishmaniosis';

  @override
  String get vaccineV3V4V5 => 'V3/V4/V5 (Polivalente)';

  @override
  String get vaccineFivFelv => 'VIF/ViLeF';

  @override
  String get vaccinationGuideTitle => 'Guía de Vacunación';

  @override
  String get vaccinationMandatory => 'Obligatorias';

  @override
  String get vaccinationOptional => 'Eventuales / Opcionales';

  @override
  String get vaccinationHelpBody =>
      'Consulte la tabla a continuación para comprender qué vacunas son esenciales.';

  @override
  String get pdfFooterText =>
      'Desarrollado por Multiverso Digital Copyright 2026';

  @override
  String vet360ReportTitle(String petName) {
    return 'Historial Veterinario 360° - $petName';
  }

  @override
  String get labelProfile => 'Perfil';

  @override
  String get labelPhone => 'Teléfono';

  @override
  String get labelEmail => 'Correo electrónico';

  @override
  String get labelNotes => 'Observaciones';

  @override
  String get petRegimeLabel => 'Régimen';

  @override
  String get settingsSectionAccount => 'Cuenta';

  @override
  String get settingsChangePassword => 'Cambiar contraseña';

  @override
  String get settingsKeepSignedIn => 'Mantener sesión';

  @override
  String get settingsKeepSignedInSubOn => 'Activado';

  @override
  String get settingsKeepSignedInSubOff => 'Desactivado';

  @override
  String get settingsMsgSessionKept => 'Sesión mantenida';

  @override
  String get settingsMsgLoginRequired => 'Inicio de sesión requerido';

  @override
  String get settingsUseBiometrics => 'Usar biometría';

  @override
  String get settingsBiometricsOn => 'Activado';

  @override
  String get settingsBiometricsOff => 'Desactivado';

  @override
  String get settingsSectionPreferences => 'Preferencias';

  @override
  String get settingsLabelAutomatic => 'Automático';

  @override
  String get settingsSectionBackup => 'Copia de seguridad';

  @override
  String get settingsActionRestore => 'Restaurar';

  @override
  String get settingsWipeSuccess => 'Datos borrados con éxito';

  @override
  String settingsWipeError(Object error) {
    return 'Error al borrar datos: $error';
  }

  @override
  String get settingsWipeConfirmBody =>
      '¿Está seguro de que desea borrar todos los datos?';

  @override
  String get settingsActionWipeAll => 'Borrar todo';

  @override
  String get categoryGeneral => 'General';

  @override
  String get commonDays => 'días';

  @override
  String get diagnosisAllergy => 'Alergia';

  @override
  String get diagnosisAnemia => 'Anemia';

  @override
  String get diagnosisDermatitis => 'Dermatitis';

  @override
  String get diagnosisDysbiosis => 'Disbiosis';

  @override
  String get diagnosisFracture => 'Fractura';

  @override
  String get diagnosisGingivitis => 'Gingivitis';

  @override
  String get diagnosisInfection => 'Infección';

  @override
  String get diagnosisInflammation => 'Inflamación';

  @override
  String get diagnosisMass => 'Masa';

  @override
  String get diagnosisObesity => 'Obesidad';

  @override
  String get diagnosisOverweight => 'Sobrepeso';

  @override
  String get diagnosisPain => 'Dolor';

  @override
  String get diagnosisParasites => 'Parásitos';

  @override
  String get diagnosisPlaque => 'Placa';

  @override
  String get diagnosisTartar => 'Sarro';

  @override
  String get diagnosisTumor => 'Tumor';

  @override
  String get diagnosisUnderweight => 'Bajo peso';

  @override
  String errorGeneratePdf(Object error) {
    return 'Error al generar PDF';
  }

  @override
  String errorLoadDetails(Object error) {
    return 'Error al cargar detalles';
  }

  @override
  String get errorNoPlantsToExport => 'No hay plantas para exportar';

  @override
  String get errorPdfGeneration => 'Error en la generación del PDF';

  @override
  String get labelSafe => 'Seguro';

  @override
  String get labelToxicCats => 'Tóxico para gatos';

  @override
  String get labelToxicDogs => 'Tóxico para perros';

  @override
  String get labelToxicDogsCats => 'Tóxico para perros y gatos';

  @override
  String get pdfCauses => 'Causas';

  @override
  String get petDietLabel => 'Dieta';

  @override
  String get petFoodTypeLabel => 'Tipo de Alimento';

  @override
  String get petProfileIncompleteBody =>
      'Complete el perfil de la mascota para generar el plan nutricional';

  @override
  String get petProfileIncompleteTitle => 'Perfil Incompleto';

  @override
  String petSelectedDays(Object count) {
    return 'Días seleccionados';
  }

  @override
  String get statusCritical => 'Crítico';

  @override
  String get statusHealthy => 'Saludable';

  @override
  String get statusWarning => 'Advertencia';

  @override
  String get tooltipFengShui => 'Feng Shui';

  @override
  String get tooltipGeneratePdf => 'Generar PDF';

  @override
  String get unitKcalPerDay => 'kcal/día';

  @override
  String errorAutoSave(String error) {
    return 'Error en guardado automático: $error';
  }

  @override
  String get petTravelTitle => 'Viagem';

  @override
  String get petTravelMode => 'Modalidade';

  @override
  String get petTravelCar => 'Carro';

  @override
  String get petTravelPlane => 'Avião';

  @override
  String get petTravelShip => 'Navio';

  @override
  String get petTravelScope => 'Escopo';

  @override
  String get petTravelNational => 'Nacional';

  @override
  String get petTravelInternational => 'Internacional';

  @override
  String get petTravelChecklist => 'Checklist Essencial';

  @override
  String get petTravelSafetyBelt => 'Cinto de Segurança / Caixa';

  @override
  String get petTravelVaccines => 'Vacinas em Dia';

  @override
  String get petTravelCZI => 'CZI (Certificado Zoossanitário)';

  @override
  String get petTravelHealthCert => 'Atestado de Saúde';

  @override
  String get petTravelMicrochip => 'Microchipagem';

  @override
  String get petTravelTips => 'Dicas para Viagem Segura';

  @override
  String get petTravelStatusReady => 'Pronto para Viajar';

  @override
  String get petTravelStatusPending => 'Documento Faltando';

  @override
  String get petTravelVaccineStatusOk => 'Vacinas em dia';

  @override
  String get petTravelVaccineStatusPending => 'Vacinas pendentes';

  @override
  String get intl_travel_tips =>
      'Consulte o veterinário pelo menos 30 dias antes de viagens internacionais para garantir que toda a documentação (CZI, etc) esteja pronta a tempo.';

  @override
  String get travel_section_car => 'Viagem de Carro';

  @override
  String get travel_section_plane => 'Viagem de Avião';

  @override
  String get travel_section_ship => 'Viagem de Navio';

  @override
  String get travel_health_data_missing =>
      'Dados de saúde não encontrados. Verifique o histórico do pet.';

  @override
  String get travel_ship_tips =>
      'Verifique a disponibilidade de canil de bordo. Alguns cruzeiros permitem apenas cães-guia. Consulte sobre medicação para enjoo marítimo.';

  @override
  String get travel_plane_checklist =>
      'Caixa IATA, Microchip ISO e CZI (Certificado Internacional) são obrigatórios.';

  @override
  String get travel_car_tips =>
      'Use sempre cinto peitoral ou caixa de transporte. Planeje paradas para hidratação e necessidades a cada 2 horas.';

  @override
  String get travel_car_checklist_1 => 'Cinto Peitoral / Caixa';

  @override
  String get travel_car_checklist_2 => 'Kit Primeiro Socorros';

  @override
  String get travel_car_checklist_3 => 'Identificação na Coleira';

  @override
  String get travel_plane_checklist_1 => 'Caixa de Transporte IATA';

  @override
  String get travel_plane_checklist_2 => 'Reserva Antecipada';

  @override
  String get travel_plane_checklist_3 => 'Sedação (sob prescrição)';

  @override
  String get travel_ship_checklist_1 => 'Acesso ao Canil';

  @override
  String get travel_ship_checklist_2 => 'Documentação Extra';

  @override
  String get travel_ship_checklist_3 => 'Regras de Circulação';

  @override
  String get petTravelMedicationActive => 'Medicação de Ciclo Ativo';

  @override
  String get petTravelMedicationActiveDesc =>
      'Interrupções em tratamentos durante viagens podem causar recidivas e resistência bacteriana ou parasitária.';

  @override
  String get petTravelWaterMineral => 'Água Mineral e Soro';

  @override
  String get petTravelWaterMineralDesc =>
      'Mudanças no pH da água de diferentes cidades podem causar distúrbios gastrointestinais em pets sensíveis.';

  @override
  String get petTravelTacticalStops => 'Paradas Táticas (A cada 2h)';

  @override
  String get petTravelTacticalStopsDesc =>
      'Essencial para circulação, alívio de estresse e para evitar retenção urinária, que favorece infecções.';

  @override
  String get petTravelV8V10Desc =>
      'Protege contra Cinomose e Parvovirose. Áreas de descanso e postos de gasolina são focos de contaminação por outros animais.';

  @override
  String get petTravelV3V4V5Desc =>
      'Protege contra Complexo Respiratório e FelV. O estresse da viagem baixa a imunidade, tornando o gato mais suscetível.';

  @override
  String get petTravelRabiesDesc =>
      'É a única exigida por lei para circulação em território nacional. Protege contra uma zoonose fatal.';

  @override
  String get petTravelGripeDesc =>
      'Crucial para cães que frequentarão hotéis pet ou ambientes com ar-condicionado central.';

  @override
  String get petTravelLeishDesc =>
      'Indispensável para viagens rumo ao litoral ou interior com áreas de mata.';

  @override
  String get petTravelHealthCheckup =>
      'Calendário de Saúde não preenchido - Recomenda-se Check-up pré-viagem';

  @override
  String get petTravelHygieneKit => 'Kit de Higiene e Medicação Parasitária';

  @override
  String get petTravelHydrationMonitoring =>
      'Hidratação e Monitoramento de Micção';

  @override
  String get petTravelRestSupport => 'Suporte Hídrico e Repouso';

  @override
  String get petTravelPremiumFoodKit => 'Kit Alimentar Super Premium';

  @override
  String get petTravelVaccineGuide => 'Guia de Vacinação Vital';

  @override
  String get petTravelSpecificCares => 'Cuidados Específicos';

  @override
  String get travelDocHealthTitle => 'Atestado de Saúde';

  @override
  String get travelDocHealthDesc =>
      'Emitido pelo veterinário em até 10 dias antes da viagem.';

  @override
  String get travelDocVaccineTitle => 'Comprovante de Vacinação';

  @override
  String get travelDocVaccineDesc =>
      'A vacina antirrábica deve ter sido aplicada há mais de 30 dias.';

  @override
  String get travelDocMicrochipTitle => 'Certificado de Microchip';

  @override
  String get travelDocMicrochipDesc =>
      'Obrigatório para identificação permanente e viagens internacionais.';

  @override
  String get travelDocCrateTitle => 'Gaiola/Caixa de Transporte';

  @override
  String get travelDocCrateDesc =>
      'Foto da etiqueta de identificação ou certificado da caixa.';

  @override
  String get travelDocLeishTitle => 'Vacina Leishmaniose';

  @override
  String get travelDocLeishDesc =>
      'Recomendada para trânsito em áreas endêmicas.';

  @override
  String get travelDocFelvTitle => 'Teste FeLV/FiV';

  @override
  String get travelDocFelvDesc =>
      'Importante para estadias em hotéis pet e segurança do felino.';

  @override
  String get tabScanWalk => 'ScanWalk';

  @override
  String get scanWalkNoPetError =>
      'Es necesario tener al menos una mascota registrada para iniciar un paseo.';

  @override
  String get scanWalkTitle => 'Paseos Inteligentes';

  @override
  String get scanWalkMap => 'Mapa Interactivo';

  @override
  String get scanWalkFriends => 'Amigos Encontrados';

  @override
  String get scanWalkAlerts => 'Zonas de Riesgo';

  @override
  String get scanWalkStart => 'Iniciar Paseo';

  @override
  String get scanWalkDistance => 'Distancia';

  @override
  String get scanWalkDuration => 'Duración';

  @override
  String get walkXixi => 'Pipi';

  @override
  String get walkFezes => 'Heces';

  @override
  String get walkAgua => 'Agua';

  @override
  String get walkOutros => 'Otros';

  @override
  String get walkAmigo => 'Amigo';

  @override
  String get walkLatido => 'Ladrido';

  @override
  String get walkPerigo => 'Peligro';

  @override
  String get walkBrigas => 'Peleas';

  @override
  String get walkBristolScore => 'Escala Bristol';

  @override
  String get walkFriendDesc => 'Nombre del Amigo';

  @override
  String get walkHazardDesc => 'Tipo de Peligro';

  @override
  String get walkFightDesc => 'Detalles de la Pelea';

  @override
  String get walkDemoBtn => 'Demostración';

  @override
  String get walkMicRec => 'Escuchando...';

  @override
  String get walkCamRec => 'Foto capturada';

  @override
  String get walkBristolIdeal => 'Ideal';

  @override
  String get walkBristolConstipated => 'Duro';

  @override
  String get walkBristolLiquid => 'Líquido';

  @override
  String get walkExitConfirm => '¿Deseas finalizar el paseo?';

  @override
  String get walkSaveSuccess => '¡Registro guardado en el 9º Informe!';

  @override
  String get walkVoicePromptFriend => 'Di el nombre, sexo y edad del amigo.';

  @override
  String get walkVoicePromptDanger =>
      'Di qué es el peligro (ej: vidrio, veneno).';

  @override
  String get walkVoicePromptFight => 'Di la raza y sexo del agresor.';

  @override
  String get walkAnalysisStool => 'Analizando Heces (IA)...';

  @override
  String get walkAnalysisBark => 'Analizando Ladridos (IA)...';
}
