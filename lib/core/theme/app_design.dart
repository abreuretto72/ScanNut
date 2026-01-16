
import 'package:flutter/material.dart';

class AppDesign {
  AppDesign._();

  // ========================
  // 🎨 CORES (SEM shadeXXX)
  // ========================
  static const Color primary = Color(0xFF57315D);
  static const Color accent  = Color(0xFF5E4B6B);

  static const Color primaryDark  = Color(0xFF3F2444);
  static const Color primaryLight = Color(0xFFA47DA8);

  static Color accentSoft = accent.withOpacity(0.8);
  static Color disabled   = primary.withOpacity(0.45);

  // FUNDOS
  static const Color backgroundLight = Color(0xFFF6F3F7);
  static const Color surfaceLight    = Color(0xFFFFFFFF);
  static const Color backgroundDark  = Color(0xFF121212);
  static const Color surfaceDark     = Color(0xFF1E1E1E);

  // TEXTO
  static const Color textPrimaryLight   = Color(0xFF1E1E1E);
  static const Color textSecondaryLight = Color(0xFF5F5F5F);
  static const Color textPrimaryDark    = Color(0xFFFFFFFF);
  static const Color textSecondaryDark  = Color(0xFFCFCFCF);

  // ESTADOS E FEEDBACK (V115)
  static const Color success = Color(0xFF00E676); // Verde Sucesso
  static const Color warning = Color(0xFFFFA000); // Âmbar Atenção
  static const Color error   = Color(0xFFFF5252); // Vermelho Erro
  static const Color info    = Color(0xFF1976D2); // Azul Info

  // COMPONENTES
  static const Color messageBackground = accent;
  static const Color progress          = accent;
  static const Color iconActive        = accent;

  // CORES DOS DOMÍNIOS
  static const Color foodOrange = Color(0xFFFF9800); // Laranja Comida (Corrected)
  static const Color plantGreen = Color(0xFF4CAF50); // Verde Plantas
  static const Color petPink    = Color(0xFFFFD1DC); // Rosa Pastel (Protocol V63 Standard)

  static Color getModeColor(int modeIndex) {
    switch (modeIndex) {
      case 0: return foodOrange;  // Food (Laranja)
      case 1: return plantGreen;  // Plant (Verde)
      case 2: return petPink;     // Pet (Rosa)
      default: return textPrimaryDark; // Neutro se nenhum selecionado
    }
  }

  // ========================
  // 🧩 ÍCONES DO APP
  // ========================
  static const IconData iconFood   = Icons.restaurant;
  static const IconData iconPlant  = Icons.local_florist;
  static const IconData iconPet    = Icons.pets;
  static const IconData iconScan   = Icons.camera_alt_rounded;
  static const IconData iconMenu   = Icons.menu;
  static const IconData iconConfig = Icons.settings;
  static const IconData iconDelete = Icons.delete_forever;
  static const IconData iconBackup = Icons.backup;
  static const IconData iconRestore = Icons.restore;
  static const IconData iconAlert  = Icons.warning_amber_rounded;
  static const IconData iconInfo   = Icons.info_outline;

  // ========================
  // 🖼 LOGOS E IMAGENS
  // ========================
  static const String logoApp = 'assets/images/logo_app.png';
  static const String logoSplash = 'assets/images/logo_app.png';
  static const String logoIcon = 'assets/images/ic_launcher.png';

  static const String illustrationEmpty = 'assets/images/empty_state.png';
}
