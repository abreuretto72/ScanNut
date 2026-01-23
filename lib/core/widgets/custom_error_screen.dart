import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomErrorScreen extends StatelessWidget {
  final FlutterErrorDetails? details;

  const CustomErrorScreen({super.key, this.details});

  @override
  Widget build(BuildContext context) {
    // Determine language from system locale
    final String locale = Platform.localeName.split('_')[0];
    
    String title = 'Ops! Tivemos um imprevisto.';
    String message = 'Ocorreu um erro ao processar sua solicitação. Não se preocupe, seus dados estão seguros.';
    String buttonText = 'Voltar';
    String techDetailsLabel = 'Detalhes técnicos:';

    if (locale == 'en') {
      title = 'Oops! Something went wrong.';
      message = 'An error occurred while processing your request. Don\'t worry, your data is safe.';
      buttonText = 'Go Back';
      techDetailsLabel = 'Technical details:';
    } else if (locale == 'es') {
      title = '¡Vaya! Algo salió mal.';
      message = 'Se produjo un error al procesar su solicitud. No se preocupe, sus datos están seguros.';
      buttonText = 'Volver';
      techDetailsLabel = 'Detalles técnicos:';
    }

    // 🛡️ PROTEÇÃO TOTAL - Usa o Scaffold diretamente para se integrar ao Navigator do App
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.pets, size: 64, color: Color(0xFF00E676)),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      // 🛡️ FIX: Always reset to home screen to avoid frozen error overlay
                      try {
                        // Clear all routes and go back to home
                        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                      } catch (e) {
                        // Last resort: try to pop if pushNamedAndRemoveUntil fails
                        debugPrint('Navigation recovery failed: $e');
                        try {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        } catch (e2) {
                          debugPrint('Pop also failed: $e2');
                        }
                      }
                    },
                    child: Text(
                      buttonText,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                if (details != null) ...[
                  const SizedBox(height: 40),
                  Text(
                    techDetailsLabel,
                    style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      details!.exception.toString(),
                      maxLines: 5,
                      overflow: TextOverflow.visible,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontFamily: 'monospace', height: 1.4),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Versão simplificada da marca d'água para a tela de erro (sem dependência de contexto de tema complexo)

