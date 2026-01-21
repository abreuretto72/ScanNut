import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../home/presentation/home_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_design.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _termsAccepted = false;

  final List<OnboardingData> _onboardingPages = [
    // Ecrã 1: Biohacking & Performance Humana
    OnboardingData(
      titleKey: 'onboardingTitle1',
      bodyKey: 'onboardingBody1',
      icon: Icons.restaurant_menu_rounded,
      color: AppDesign.warning, // Laranja vibrante para comida
    ),
    // Ecrã 2: Engenharia Botânica & Sobrevivência
    OnboardingData(
      titleKey: 'onboardingTitle2',
      bodyKey: 'onboardingBody2',
      icon: Icons.eco_rounded,
      color: AppDesign.success, // Verde para plantas
    ),
    // Ecrã 3: Gestão Digital de Pets
    OnboardingData(
      titleKey: 'onboardingTitle3',
      bodyKey: 'onboardingBody3',
      icon: Icons.pets_rounded,
      color: AppDesign.primary, // Roxo para pets
    ),
    // Ecrã 4: Privacidade & Compromisso Local
    OnboardingData(
      titleKey: 'onboardingTitle4',
      bodyKey: 'onboardingBody4',
      icon: Icons.shield_rounded,
      color: AppDesign.info, // Azul para segurança
    ),
  ];

  Future<void> _completeOnboarding() async {
    if (!_termsAccepted && _currentPage == _onboardingPages.length - 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.onboardingAcceptTerms),
          backgroundColor: AppDesign.error,
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    await prefs.setBool('disclaimer_accepted', true); // Onboarding already covers disclaimer

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppDesign.backgroundDark,
      body: Container(
        decoration: const BoxDecoration(
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
            // Floating particles or subtle accents could go here
          PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemCount: _onboardingPages.length,
            itemBuilder: (context, index) {
              return _buildPage(_onboardingPages[index], l10n);
            },
          ),
          
          // Navigation Bottom Area
          Positioned(
            bottom: 50,
            left: 30,
            right: 30,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Page Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _onboardingPages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 8),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index 
                            ? AppDesign.accent 
                            : AppDesign.textPrimaryDark.withOpacity(0.24),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Continuous Action (Terms or Button)
                if (_currentPage == _onboardingPages.length - 1) ...[
                  GestureDetector(
                    onTap: () => setState(() => _termsAccepted = !_termsAccepted),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _termsAccepted,
                            onChanged: (val) => setState(() => _termsAccepted = val ?? false),
                            activeColor: AppDesign.accent,
                            side: const BorderSide(color: AppDesign.textSecondaryDark),
                          ),
                          Expanded(
                            child: Text(
                              l10n.onboardingAcceptTerms,
                              style: GoogleFonts.poppins(color: AppDesign.textSecondaryDark, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _onboardingPages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.ease,
                        );
                      } else {
                        _completeOnboarding();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentPage == _onboardingPages.length - 1 && !_termsAccepted
                          ? AppDesign.disabled
                          : AppDesign.accent,
                      foregroundColor: AppDesign.backgroundDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      _currentPage == _onboardingPages.length - 1 
                          ? l10n.onboardingGetStarted
                          : l10n.continueButton,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildPage(OnboardingData data, AppLocalizations l10n) {
    // Get translated strings
    String title = "";
    String body = "";
    
    switch (data.titleKey) {
      case 'onboardingTitle1': title = l10n.onboardingTitle1; break;
      case 'onboardingTitle2': title = l10n.onboardingTitle2; break;
      case 'onboardingTitle3': title = l10n.onboardingTitle3; break;
      case 'onboardingTitle4': title = l10n.onboardingTitle4; break;
    }
    
    switch (data.bodyKey) {
      case 'onboardingBody1': body = l10n.onboardingBody1; break;
      case 'onboardingBody2': body = l10n.onboardingBody2; break;
      case 'onboardingBody3': body = l10n.onboardingBody3; break;
      case 'onboardingBody4': body = l10n.onboardingBody4; break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with Bloom Effect
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: data.color.withOpacity(0.1),
              boxShadow: [
                BoxShadow(color: data.color.withOpacity(0.2), blurRadius: 40, spreadRadius: 10),
              ],
            ),
            child: Icon(data.icon, size: 100, color: data.color),
          ),
          const SizedBox(height: 60),
          
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppDesign.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 24),
          
          Text(
            body,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppDesign.textSecondaryDark,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 100), // Space for indicator/button
        ],
      ),
    );
  }
}

class OnboardingData {
  final String titleKey;
  final String bodyKey;
  final IconData icon;
  final Color color;

  OnboardingData({
    required this.titleKey,
    required this.bodyKey,
    required this.icon,
    required this.color,
  });
}
