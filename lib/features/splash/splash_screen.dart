import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Added
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../home/presentation/home_view.dart';
import '../onboarding/presentation/onboarding_screen.dart';
import '../auth/presentation/login_screen.dart';
import '../../core/services/simple_auth_service.dart';
import '../../core/theme/app_design.dart';
import '../../../l10n/app_localizations.dart';

// Test Suite Imports
import '../pet/services/pet_profile_service.dart';
import '../pet/services/pet_menu_generator_service.dart';
import '../pet/services/meal_plan_service.dart';
import '../pet/services/cardapio_stress_test.dart';

class SplashScreen extends ConsumerStatefulWidget { // Changed
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState(); // Changed
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin { // Changed
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  // DEBUG SWITCH: Set to true to force login screen logic ignoring stored session
  static const bool FORCE_LOGIN_DEBUG = false; 
  
  // 🛡️ STRESS TEST SWITCH: Set to true to run V710 validation on startup
  static const bool RUN_STRESS_TEST = false; // ❌ Desabilitado conforme solicitado

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 0.8, curve: Curves.easeOut)),
    );

    _controller.forward();

    debugPrint('🕒 Splash Timer scheduled for 1000ms');
    Timer(const Duration(milliseconds: 1000), () async {
      debugPrint('🔔 Splash Timer fired! Checking mounted...');
      
      // 🛡️ RUN STRESS TEST (V710)
      if (RUN_STRESS_TEST && mounted) {
          debugPrint('🧪 [Splash] Triggering CardapioStressTest (Background)...');
          final tester = CardapioStressTest(
              ref.read(petProfileServiceProvider),
              ref.read(petMenuGeneratorProvider),
              ref.read(mealPlanServiceProvider)
          );
          // Fire and forget - Check debug console for results
          tester.runStressTest(); 
      }

      if (mounted) {
        debugPrint('📦 Loading SharedPreferences...');
        final prefs = await SharedPreferences.getInstance();
        final bool onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
        
        debugPrint('👤 Checking session...');
        if (mounted) {
           debugPrint('🛡️ [Splash] Calling simpleAuthService.checkPersistentSession()...');
           // Tenta recuperar sessão persistente e chave mestra
           final bool isLoggedIn = await simpleAuthService.checkPersistentSession();
           debugPrint('✅ [Splash] Session check complete. Result: $isLoggedIn');

           // -------------------------------------------------------------
           // DEBUG DIAGNOSTICS LOGS
           debugPrint('\n🔍 === SPLASH SCREEN DIAGNOSTICS ===');
           debugPrint('Origins: SplashScreen (Timer finished)');
           debugPrint('Prefs: onboarding_completed = $onboardingCompleted');
           debugPrint('Auth: hasPersistentSession = $isLoggedIn');
           debugPrint('Auth: loggedUserEmail = ${simpleAuthService.loggedUserEmail}');
           debugPrint('DEBUG MODE: FORCE_LOGIN_DEBUG = $FORCE_LOGIN_DEBUG');
           // -------------------------------------------------------------
           
           Widget nextScreen;
           String decisionLog = "";

           if (FORCE_LOGIN_DEBUG) {
             nextScreen = const LoginScreen();
             decisionLog = "NAVIGATE_TO_LOGIN (Forced by Debug)";
           } else if (!onboardingCompleted) {
             nextScreen = const OnboardingScreen();
             decisionLog = "NAVIGATE_TO_ONBOARDING";
           } else if (!isLoggedIn) {
             nextScreen = const LoginScreen();
             decisionLog = "NAVIGATE_TO_LOGIN (No valid session)";
           } else {
             // Session is active/persistent. Check biometrics requirement.
             if (simpleAuthService.isBiometricEnabled) {
                // Prompt Bio right here
                final bioResult = await simpleAuthService.authenticateWithBiometrics();
                if (bioResult == AuthResult.success) {
                   nextScreen = const HomeView();
                   decisionLog = "NAVIGATE_TO_HOME (Biometric Success)";
                } else {
                   // If bio fails or cancelled, user must login manually
                   nextScreen = const LoginScreen();
                   decisionLog = "NAVIGATE_TO_LOGIN (Biometric Rejection/Cancel/MissingKey)";
                }
             } else {
                nextScreen = const HomeView();
                decisionLog = "NAVIGATE_TO_HOME (Session active, No Bio)";
             }
           }

           debugPrint('🚀 DECISION: $decisionLog');
           debugPrint('=====================================\n');

           debugPrint('🎬 Starting pushReplacement to next screen...');
           Navigator.of(context).pushReplacement(
             PageRouteBuilder(
               pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
               transitionsBuilder: (context, animation, secondaryAnimation, child) {
                 return FadeTransition(opacity: animation, child: child);
               },
               transitionDuration: const Duration(milliseconds: 500),
             ),
           ).then((_) => debugPrint('🏁 Navigation complete.'));
        }
      }
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Note: Splash Screen runs before standard localization delegate might be fully ready in some setups,
    // but since we are inside MaterialApp, this generally works if locale is resolved.
    // Fallback to English if something goes wrong is implicit or we can handle null.
    // AppLocalizations.of(context) returns nullable, so we use '!' or '??'.
    final l10n = AppLocalizations.of(context);
    
    // Safety fallback strings in case context isn't ready (rare in this architecture)
    final food = l10n?.tabFood ?? 'Food';
    final plants = l10n?.tabPlants ?? 'Plants';
    final pets = l10n?.tabPets ?? 'Pets';
    final poweredBy = l10n?.splashPoweredBy ?? 'Powered by AI Vision';

    return Scaffold(
      backgroundColor: AppDesign.backgroundDark, // Safety background
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppDesign.backgroundDark,
              AppDesign.surfaceDark,
              AppDesign.backgroundDark,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background particles
            ...List.generate(20, (index) => _buildParticle(index)),
            
            // Main content - Centered
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min, // Keep it compact in center
                children: [
                   // Logo/Icon
                   ScaleTransition(
                     scale: _scaleAnimation,
                     child: FadeTransition(
                       opacity: _fadeAnimation,
                       child: Container(
                         width: 120,
                         height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Colors.white,
                                Colors.white.withOpacity(0.9),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.3),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Image.asset(
                              'imagens/icone_app.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                       ),
                     ),
                   ),
                   
                   const SizedBox(height: 30),
                   
                   // App Name
                   AnimatedBuilder(
                     animation: _slideAnimation,
                     builder: (context, child) {
                       return Transform.translate(
                         offset: Offset(0, _slideAnimation.value),
                         child: FadeTransition(
                           opacity: _fadeAnimation,
                           child: child,
                         ),
                       );
                     },
                     child: Text(
                       'ScanNut',
                       style: GoogleFonts.poppins(
                         fontSize: 48,
                         fontWeight: FontWeight.bold,
                         color: AppDesign.textPrimaryDark,
                         letterSpacing: 2,
                       ),
                     ),
                   ),
                   
                   const SizedBox(height: 12),
                   
                   // Tagline
                   AnimatedBuilder(
                     animation: _slideAnimation,
                     builder: (context, child) {
                       return Transform.translate(
                         offset: Offset(0, _slideAnimation.value + 20),
                         child: FadeTransition(
                           opacity: _fadeAnimation,
                           child: child,
                         ),
                       );
                     },
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         _buildTag('🍎', food),
                         const SizedBox(width: 8),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: AppDesign.foodOrange,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildTag('🌿', plants),
                          const SizedBox(width: 8),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: AppDesign.foodOrange,
                              shape: BoxShape.circle,
                            ),
                          ),
                         const SizedBox(width: 8),
                         _buildTag('', pets, icon: Icons.pets, iconColor: AppDesign.petPink),
                       ],
                     ),
                   ),
                   
                   const SizedBox(height: 60),

                   // Loading indicator (linked to main content)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: const SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFFFF69B4)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Footer - Bottom Pinned
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppDesign.textPrimaryDark.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppDesign.textPrimaryDark.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome, color: AppDesign.foodOrange, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          poweredBy,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppDesign.textSecondaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildTag(String emoji, String label, {IconData? icon, Color? iconColor}) {
    return Row(
      children: [
        if (icon != null)
          Icon(icon, size: 16, color: iconColor ?? AppDesign.textSecondaryDark)
        else
          Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppDesign.textSecondaryDark,
          ),
        ),
      ],
    );
  }

  Widget _buildParticle(int index) {
    final random = (index * 37) % 100;
    final size = 2.0 + (random % 4);
    final left = (random * 3.7) % 100;
    final top = (random * 5.3) % 100;

    return Positioned(
      left: MediaQuery.of(context).size.width * (left / 100),
      top: MediaQuery.of(context).size.height * (top / 100),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFFFF69B4).withOpacity(0.3),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
