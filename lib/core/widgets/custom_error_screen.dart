import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomErrorScreen extends StatelessWidget {
  final FlutterErrorDetails? details;

  const CustomErrorScreen({Key? key, this.details}) : super(key: key);

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

    // 🛡️ PROTEÇÃO TOTAL - Não depende de nada externo
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
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
                      color: Colors.green.withOpacity(0.1),
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
                        // Tenta fechar o erro e voltar
                        try {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          // Se falhar, não faz nada (já está na tela de erro)
                          debugPrint('Cannot navigate: $e');
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
                      style: GoogleFonts.poppins(color: Colors.white24, fontSize: 10),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        details!.exception.toString(),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
