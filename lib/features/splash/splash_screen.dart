import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../home/presentation/home_view.dart';
import '../onboarding/presentation/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

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

    // Navigate to Onboarding or Home after animation
    Timer(const Duration(milliseconds: 3000), () async {
      if (mounted) {
        final prefs = await SharedPreferences.getInstance();
        final bool onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => 
                onboardingCompleted ? const HomeView() : const OnboardingScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
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
    return Scaffold(
      backgroundColor: Colors.black, // Safety background
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black,
              Colors.grey.shade900,
              Colors.black,
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
                               const Color(0xFF00E676),
                               const Color(0xFF00E676).withValues(alpha: 0.6),
                             ],
                           ),
                           boxShadow: [
                             BoxShadow(
                               color: const Color(0xFF00E676).withValues(alpha: 0.5),
                               blurRadius: 40,
                               spreadRadius: 10,
                             ),
                           ],
                         ),
                         child: const Icon(
                           Icons.camera_alt_rounded,
                           size: 60,
                           color: Colors.black,
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
                         color: Colors.white,
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
                         _buildTag('🍎', 'Food'),
                         const SizedBox(width: 8),
                         Container(
                           width: 4,
                           height: 4,
                           decoration: const BoxDecoration(
                             color: Color(0xFF00E676),
                             shape: BoxShape.circle,
                           ),
                         ),
                         const SizedBox(width: 8),
                         _buildTag('🌿', 'Plants'),
                         const SizedBox(width: 8),
                         Container(
                           width: 4,
                           height: 4,
                           decoration: const BoxDecoration(
                             color: Color(0xFF00E676),
                             shape: BoxShape.circle,
                           ),
                         ),
                         const SizedBox(width: 8),
                         _buildTag('🐾', 'Pets'),
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
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E676)),
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
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome, color: Color(0xFF00E676), size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Powered by AI Vision',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white70,
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


  Widget _buildTag(String emoji, String label) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.white70,
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
            color: const Color(0xFF00E676).withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
