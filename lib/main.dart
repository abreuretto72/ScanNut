import 'package:flutter/material.dart';
import 'dart:async';
import 'core/widgets/custom_error_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'features/splash/splash_screen.dart';
import 'core/providers/settings_provider.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/services/history_service.dart';
import 'core/services/file_upload_service.dart';
import 'core/services/simple_auth_service.dart';

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
    
    runApp(const ProviderScope(child: ScannutApp()));
  }, (error, stack) {
    // Zona de Captura de Erros Não Tratados (Assíncronos)
    debugPrint('🔴 ERRO CRÍTICO CAPTURADO (runZoned): $error');
    debugPrint('Stacktrace: $stack');
    // Aqui você conectaria Crashlytics/Sentry no futuro
  });
}

class ScannutApp extends ConsumerWidget {
  const ScannutApp({Key? key}) : super(key: key);

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
      title: 'Scannut',
      scaffoldMessengerKey: scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      locale: _resolveLocale(settings.languageCode),
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00E676),
          brightness: Brightness.dark,
          surface: Colors.black,
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
      home: const SplashScreen(),
    );
  }
}
