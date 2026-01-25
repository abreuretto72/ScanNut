import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_design.dart';

enum FeedbackType { success, error, warning, info }

/// Classe centralizada para exibição padronizada de feedback ao usuário.
///
/// Uso:
/// AppFeedback.showSuccess(context, 'Operação realizada com sucesso!');
/// AppFeedback.showError(context, 'Falha ao conectar.');
class AppFeedback {
  AppFeedback._();

  static void showSuccess(BuildContext context, String message) {
    _showSnackBar(context, message, FeedbackType.success);
  }

  static void showError(BuildContext context, String message) {
    _showSnackBar(context, message, FeedbackType.error);
  }

  static void showWarning(BuildContext context, String message) {
    _showSnackBar(context, message, FeedbackType.warning);
  }

  static void showInfo(BuildContext context, String message) {
    _showSnackBar(context, message, FeedbackType.info);
  }

  static void _showSnackBar(
      BuildContext context, String message, FeedbackType type) {
    final messenger = ScaffoldMessenger.of(context);

    // Remove snackbars anteriores para evitar fila longa
    messenger.hideCurrentSnackBar();

    Color backgroundColor;
    IconData icon;
    Color textColor = Colors.white;
    Duration duration = const Duration(seconds: 4);

    switch (type) {
      case FeedbackType.success:
        backgroundColor = AppDesign.success;
        icon = Icons.check_circle_outline;
        duration = const Duration(seconds: 2);
        break;
      case FeedbackType.error:
        backgroundColor = AppDesign.error;
        icon = Icons.error_outline;
        break;
      case FeedbackType.warning:
        backgroundColor = AppDesign.warning;
        icon = Icons.warning_amber_rounded;
        textColor = Colors.black87; // Contraste melhor no amarelo
        break;
      case FeedbackType.info:
        backgroundColor = AppDesign.info;
        icon = Icons.info_outline;
        break;
    }

    messenger.showSnackBar(
      SnackBar(
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
        duration: duration,
        content: Row(
          children: [
            Icon(icon, color: textColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
