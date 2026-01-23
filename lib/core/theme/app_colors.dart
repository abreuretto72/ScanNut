import 'package:flutter/material.dart';

class AppColors {
  // Cores Oficiais
  static const Color primary = Color(0xFF57315D); // Roxo Primário
  static const Color accent = Color(0xFF5E4B6B);  // Roxo Destaque (substituto do verde)

  // Variações de Opacidade (Safe)
  static Color get primarySoft => primary.withValues(alpha: 0.8);
  static Color get accentSoft => accent.withValues(alpha: 0.8);
  
  // Estados
  static const Color success = accent; // Sucesso agora usa o tom de destaque/roxo
  static const Color disabled = Color(0xFF9E9E9E); // Cinza padrão para desabilitado
  
  // Superfícies
  static const Color surfaceDark = Colors.black;
  static const Color cardSurface = Color(0xFF1E1E1E); // Aproximação de dark mode padrão se necessário
}
