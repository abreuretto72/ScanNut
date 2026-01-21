import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// 🛡️ V70: FIXED-SIZE LOADING OVERLAY
/// Prevents "Cannot hit test a render box with no size" error
class AtomicLoadingOverlay {
  static OverlayEntry? _currentOverlay;

  /// Show loading overlay with explicit size
  static void show(
    BuildContext context, {
    String message = 'Processando...',
    String? animationPath,
  }) {
    // Prevent multiple overlays
    if (_currentOverlay != null) {
      debugPrint('⚠️ [V70-OVERLAY] Loading already visible. Ignoring request.');
      return;
    }

    debugPrint('🔄 [V70-OVERLAY] Showing loading: $message');

    _currentOverlay = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black54,
        child: Center(
          child: Container(
            // 🛡️ V70: EXPLICIT SIZE to prevent hit test errors
            width: 280,
            height: 320,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animation or spinner
                if (animationPath != null)
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: Lottie.asset(
                      animationPath,
                      fit: BoxFit.contain,
                    ),
                  )
                else
                  const SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      strokeWidth: 6,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFFF4081), // Pink accent
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Aguarde...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_currentOverlay!);
  }

  /// Hide loading overlay
  static void hide() {
    if (_currentOverlay != null) {
      debugPrint('✅ [V70-OVERLAY] Hiding loading');
      _currentOverlay?.remove();
      _currentOverlay = null;
    }
  }

  /// Show loading for AI analysis
  static void showAIAnalysis(BuildContext context, {String petName = 'pet'}) {
    show(
      context,
      message: 'Analisando imagem de $petName',
      animationPath: 'assets/animations/loading.json',
    );
  }

  /// Show loading for PDF generation
  static void showPDFGeneration(BuildContext context, {String petName = 'pet'}) {
    show(
      context,
      message: 'Gerando prontuário de $petName',
      animationPath: 'assets/animations/loading.json',
    );
  }

  /// Show loading for meal plan generation
  static void showMealPlanGeneration(BuildContext context, {String petName = 'pet'}) {
    show(
      context,
      message: 'Criando cardápio para $petName',
      animationPath: 'assets/animations/loading.json',
    );
  }

  /// Execute operation with loading overlay
  static Future<T?> executeWithLoading<T>({
    required BuildContext context,
    required String message,
    required Future<T> Function() operation,
    String? animationPath,
  }) async {
    try {
      show(context, message: message, animationPath: animationPath);
      final result = await operation();
      return result;
    } catch (e) {
      debugPrint('❌ [V70-OVERLAY] Error during operation: $e');
      rethrow;
    } finally {
      hide();
    }
  }
}
