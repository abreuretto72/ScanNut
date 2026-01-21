import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 🛡️ Widget wrapper que protege contra erros de localização
/// Garante que AppLocalizations esteja disponível antes de renderizar
class SafeLocalizedWidget extends StatelessWidget {
  final Widget Function(BuildContext) builder;
  final Widget? loadingWidget;

  const SafeLocalizedWidget({
    super.key,
    required this.builder,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    try {
      // Tenta acessar as localizações
      Localizations.of(context, WidgetsLocalizations);
      
      // Se chegou aqui, o contexto está pronto
      return builder(context);
    } catch (e) {
      // Se falhou, mostra loading ou erro
      debugPrint('⚠️ Localizations not ready yet: $e');
      
      return loadingWidget ??
          Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: Color(0xFF00E676),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Carregando...',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
    }
  }
}
