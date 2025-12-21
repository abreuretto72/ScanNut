import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'features/splash/splash_screen.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/services/history_service.dart';

import 'core/services/meal_history_service.dart';
import 'features/pet/models/pet_event.dart';
import 'features/pet/services/pet_event_service.dart';
import 'features/pet/models/vaccine_status.dart';
import 'features/pet/services/vaccine_status_service.dart';
import 'features/pet/services/pet_profile_service.dart';
import 'features/pet/services/pet_health_service.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  
  await HistoryService().init();
  await MealHistoryService().init();
  await PetEventService().init();
  await VaccineStatusService().init();
  
  // Initialize new unified pet data services
  await PetProfileService().init();
  await PetHealthService().init();
  
  // Debug: Show loaded environment variables
  debugPrint('🔑 === ENVIRONMENT VARIABLES LOADED ===');
  debugPrint('GROQ_API_KEY: ${dotenv.env['GROQ_API_KEY']?.substring(0, 10) ?? 'NOT FOUND'}...');
  debugPrint('GEMINI_API_KEY: ${dotenv.env['GEMINI_API_KEY']?.substring(0, 10) ?? 'NOT FOUND'}...');
  debugPrint('BASE_URL: ${dotenv.env['BASE_URL'] ?? 'NOT FOUND'}');
  debugPrint('🔑 =====================================');
  
  runApp(const ProviderScope(child: ScannutApp()));
}

class ScannutApp extends ConsumerWidget {
  const ScannutApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Scannut',
      scaffoldMessengerKey: scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
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
        Locale('pt'), // Default
        Locale('en'),
        Locale('es'),
      ],
      home: const SplashScreen(),
    );
  }
}    
