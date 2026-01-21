import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Um widget global que exibe uma marca d'água sutil no rodapé.
/// Deve ser usado via MaterialApp.builder para envolver todas as telas.
class AppWatermarkFooter extends StatelessWidget {
  const AppWatermarkFooter({super.key});

  @override
  Widget build(BuildContext context) {
    // Cor neutra baseada no brilho do tema com baixa opacidade (20% para visibilidade sutil em screenshots)
    final Color textColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withOpacity(0.20)
        : Colors.black.withOpacity(0.20);

    return IgnorePointer(
      ignoring: true,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          alignment: Alignment.bottomCenter,
          padding: const EdgeInsets.only(bottom: 12),
          child: SafeArea(
            bottom: true,
            top: false,
            child: Text(
              'ScanNut © 2026 Multiverso Digital',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: textColor,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
