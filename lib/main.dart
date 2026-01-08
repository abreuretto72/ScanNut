import 'package:flutter/material.dart';
import 'dart:async';
import 'core/theme/app_design.dart';
import 'core/widgets/custom_error_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/widgets/app_watermark_footer.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'features/splash/splash_screen.dart';
import 'core/providers/settings_provider.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/services/history_service.dart';
import 'core/services/file_upload_service.dart';
import 'core/services/simple_auth_service.dart';
import 'core/services/permanent_backup_service.dart';
import 'core/services/media_vault_service.dart';

import 'core/services/meal_history_service.dart';
import 'features/pet/models/pet_event.dart';
import 'features/pet/services/pet_event_service.dart';
import 'features/pet/models/vaccine_status.dart';
import 'features/pet/services/vaccine_status_service.dart';
import 'features/pet/services/pet_profile_service.dart';
import 'features/pet/services/pet_health_service.dart';
import 'features/pet/services/meal_plan_service.dart';
import 'features/food/services/nutrition_service.dart';
import 'features/plant/services/botany_service.dart';
import 'features/food/services/workout_service.dart';
import 'core/services/user_profile_service.dart';
import 'core/services/subscription_service.dart';
import 'nutrition/nutrition_hive_adapters.dart';
import 'nutrition/data/datasources/nutrition_profile_service.dart';
import 'nutrition/data/datasources/weekly_plan_service.dart';
import 'nutrition/data/datasources/meal_log_service.dart';
import 'nutrition/data/datasources/shopping_list_service.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // 🛡️ PROTEÇÃO GLOBAL CONTRA CRASHES - Erros Síncronos do Flutter
    FlutterError.onError = (FlutterErrorDetails details) {
      // Log detalhado do erro
      debugPrint('🔴 FLUTTER ERROR CAPTURADO:');
      debugPrint('Exception: ${details.exception}');
      debugPrint('Library: ${details.library}');
      debugPrint('Context: ${details.context}');
      debugPrint('Stack: ${details.stack}');
      
      // Previne crash mostrando tela de erro customizada
      FlutterError.presentError(details);
      
      // TODO: Enviar para Crashlytics/Sentry em produção
    };
    
    // 🛡️ PROTEÇÃO GLOBAL CONTRA CRASHES - Widget Errors
    ErrorWidget.builder = (FlutterErrorDetails details) {
      // Retorna nossa tela customizada em vez da tela vermelha
      return CustomErrorScreen(details: details);
    };

    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await dotenv.load(fileName: ".env");
    
    // Initialize Hive
    await Hive.initFlutter();
    
    // 🔐 MEDIA VAULT: Secure Storage & Migration (Priority 1)
    try {
       await MediaVaultService().init();
       debugPrint('✅ Media Vault Initialized & Optimized.');
    } catch (e) {
       debugPrint('❌ Media Vault Init Failed: $e');
    }

    // 🔄 AUTO-RECOVERY: Restaurar dados de backup permanente (se existir)
    try {
      final permanentBackup = PermanentBackupService();
      final recovered = await permanentBackup.autoRecovery();
      if (recovered) {
        debugPrint('✅ Dados restaurados automaticamente do backup permanente!');
      }
    } catch (e) {
      debugPrint('⚠️ Auto-recovery falhou (primeira instalação ou erro): $e');
    }
    
    // Register Hive adapters for PetEvent
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(EventTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(RecurrenceTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(PetEventAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(VaccineStatusAdapter());
    }
    
    // Register Nutrition module adapters (TypeIds 24-30)
    NutritionHiveAdapters.registerAdapters();
    
    // STARTUP SEQUENTIAL: 
    // 1. Initialize Auth only (the ONLY box open at start)
    await simpleAuthService.init();

    // 🛡️ PROACTIVE BOX OPENING (As requested by user to prevent "Box not found" errors)
    try {
        await Hive.openBox('box_pets_master'); // Correct master box for pet profiles
        await Hive.openBox('scannut_history');  // Correct box for analysis history
        // Optional/Requested by prompt:
        await Hive.openBox('pets'); 
        await Hive.openBox('settings');
        debugPrint('📦 Pre-emptive Hive boxes opened.');
    } catch (e) {
        debugPrint('⚠️ Pre-emptive boxes failed (likely already open or encrypted): $e');
    }
    
    // Cleanup temporary files
    await FileUploadService().cleanupTemporaryCache();
    
    // Note: All other data services (History, Pets, Nutrition, etc.) 
    // will be initialized inside SimpleAuthService.initializeSecureData()
    // once the master key is derived from the user's password.
    
    // Initialize Subscription Service (RevenueCat) - Public and doesn't need cipher
    try {
      await SubscriptionService().init();
    } catch (e) {
       debugPrint('⚠️ RevenueCat init failed: $e');
    }
    
    // Debug: Show loaded environment variables
    debugPrint('🔑 === ENVIRONMENT VARIABLES LOADED ===');
    debugPrint('GROQ_API_KEY: ${dotenv.env['GROQ_API_KEY']?.substring(0, 10) ?? 'NOT FOUND'}...');
    debugPrint('GEMINI_API_KEY: ${dotenv.env['GEMINI_API_KEY']?.substring(0, 10) ?? 'NOT FOUND'}...');
    debugPrint('REVENUECAT_API_KEY: ${dotenv.env['REVENUECAT_API_KEY']?.substring(0, 10) ?? 'NOT FOUND'}...');
    debugPrint('BASE_URL: ${dotenv.env['BASE_URL'] ?? 'NOT FOUND'}');
    debugPrint('🔑 =====================================');
    
    runApp(const ProviderScope(child: ScanNutApp()));
  }, (error, stack) {
    // Zona de Captura de Erros Não Tratados (Assíncronos)
    debugPrint('🔴 ERRO CRÍTICO CAPTURADO (runZoned): $error');
    debugPrint('Stacktrace: $stack');
    // Aqui você conectaria Crashlytics/Sentry no futuro
  });
}

class ScanNutApp extends ConsumerWidget {
  const ScanNutApp({Key? key}) : super(key: key);

  Locale? _resolveLocale(String? code) {
    if (code == null) return null;
    final parts = code.split('_');
    if (parts.length == 2) return Locale(parts[0], parts[1]);
    return Locale(parts[0]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    
    return MaterialApp(
      title: 'ScanNut',
      scaffoldMessengerKey: scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      locale: _resolveLocale(settings.languageCode),
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppDesign.backgroundDark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppDesign.accent, // Using accent as seed as before
          brightness: Brightness.dark,
          surface: AppDesign.backgroundDark,
          primary: AppDesign.primary,
          secondary: AppDesign.accent,
          error: AppDesign.error,
        ),
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('pt', 'BR'), // Portuguese Brazil
        Locale('pt', 'PT'), // Portuguese Portugal
        Locale('es'),       // Spanish
      ],
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) child,
            const AppWatermarkFooter(),
          ],
        );
      },
      home: const SplashScreen(),
    );
  }
}
