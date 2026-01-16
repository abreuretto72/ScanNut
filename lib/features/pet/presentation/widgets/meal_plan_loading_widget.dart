import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_design.dart';

/// Progressive Loading Widget for AI Meal Plan Generation
/// Shows dynamic messages to keep user engaged during long processing
class MealPlanLoadingWidget extends StatefulWidget {
  final String petName;
  
  const MealPlanLoadingWidget({
    Key? key,
    required this.petName,
  }) : super(key: key);

  @override
  State<MealPlanLoadingWidget> createState() => _MealPlanLoadingWidgetState();
}

class _MealPlanLoadingWidgetState extends State<MealPlanLoadingWidget> {
  int _currentStepIndex = 0;
  Timer? _timer;
  
  late final List<LoadingStep> _steps;

  @override
  void initState() {
    super.initState();
    
    _steps = [
      LoadingStep(
        icon: Icons.pets_rounded,
        message: 'Analisando perfil biométrico de ${widget.petName}...',
        duration: 15,
      ),
      LoadingStep(
        icon: Icons.calculate_rounded,
        message: 'Calculando calorias e macronutrientes...',
        duration: 15,
      ),
      LoadingStep(
        icon: Icons.restaurant_menu_rounded,
        message: 'Selecionando melhores alimentos e porções...',
        duration: 20,
      ),
      LoadingStep(
        icon: Icons.check_circle_outline_rounded,
        message: 'Finalizando seu cardápio personalizado...',
        duration: 999, // Will stay until completion
      ),
    ];
    
    _startProgressiveLoading();
  }

  void _startProgressiveLoading() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final currentStep = _steps[_currentStepIndex];
      
      if (timer.tick >= currentStep.duration && _currentStepIndex < _steps.length - 1) {
        if (mounted) {
          setState(() {
            _currentStepIndex++;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = _steps[_currentStepIndex];
    
    return Container(
      color: AppDesign.backgroundDark,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Icon
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.8 + (value * 0.2),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppDesign.petPink.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        currentStep.icon,
                        size: 50,
                        color: AppDesign.petPink,
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 32),
              
              // Progress Indicator
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppDesign.petPink),
                  minHeight: 4,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Dynamic Message
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.1),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  currentStep.message,
                  key: ValueKey<int>(_currentStepIndex),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Step Indicator
              Text(
                'Etapa ${_currentStepIndex + 1} de ${_steps.length}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Subtle hint
              Text(
                'Isso pode levar até 90 segundos...',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.white38,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoadingStep {
  final IconData icon;
  final String message;
  final int duration; // in seconds
  
  LoadingStep({
    required this.icon,
    required this.message,
    required this.duration,
  });
}
