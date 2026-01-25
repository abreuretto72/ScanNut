import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';

/// 🛡️ PROTEÇÃO GLOBAL CONTRA CRASHES
/// Wrapper universal para exibir erros de forma amigável ao usuário
class ErrorHandler {
  /// Exibe um SnackBar amigável para qualquer tipo de erro
  static void showError(
    BuildContext context, {
    required dynamic error,
    String? customMessage,
    Duration duration = const Duration(seconds: 4),
  }) {
    final l10n = AppLocalizations.of(context)!;

    // Mensagem padrão amigável
    String userMessage = customMessage ?? _getUserFriendlyMessage(error, l10n);

    // Log técnico para debug
    debugPrint('🔴 ERRO CAPTURADO: $error');

    // Exibe SnackBar amigável
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  userMessage,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          duration: duration,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  /// Converte erros técnicos em mensagens amigáveis
  static String _getUserFriendlyMessage(dynamic error, AppLocalizations l10n) {
    final errorString = error.toString().toLowerCase();

    // Erros de rede
    if (errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('connection')) {
      return l10n.errorNoInternet;
    }

    // Timeout
    if (errorString.contains('timeout') ||
        errorString.contains('tempo limite')) {
      return l10n.errorTimeout;
    }

    // Erro 400 - Bad Request
    if (errorString.contains('400') || errorString.contains('bad request')) {
      return l10n.analysisErrorInvalidCategory;
    }

    // Erro 401/403 - Autenticação
    if (errorString.contains('401') ||
        errorString.contains('403') ||
        errorString.contains('unauthorized')) {
      return l10n.errorAuthentication;
    }

    // Erro 404
    if (errorString.contains('404') || errorString.contains('not found')) {
      return l10n.errorNotFound;
    }

    // Erro 500 - Servidor
    if (errorString.contains('500') ||
        errorString.contains('server error') ||
        errorString.contains('internal server')) {
      return l10n.errorServer;
    }

    // Imagem muito grande
    if (errorString.contains('muito grande') ||
        errorString.contains('too large') ||
        errorString.contains('size')) {
      return l10n.errorImageTooLarge;
    }

    // Imagem corrompida
    if (errorString.contains('corrompida') ||
        errorString.contains('corrupted') ||
        errorString.contains('invalid image')) {
      return l10n.errorInvalidImage;
    }

    // API Key
    if (errorString.contains('api key') || errorString.contains('api_key')) {
      return l10n.errorConfiguration;
    }

    // Permissões
    if (errorString.contains('permission') ||
        errorString.contains('permissão')) {
      return l10n.errorPermissionDenied;
    }

    // Armazenamento
    if (errorString.contains('storage') ||
        errorString.contains('disk') ||
        errorString.contains('space')) {
      return l10n.errorNoStorage;
    }

    // Câmera
    if (errorString.contains('camera') || errorString.contains('câmera')) {
      return l10n.errorCamera;
    }

    // Localização
    if (errorString.contains('location') ||
        errorString.contains('localização')) {
      return l10n.errorLocation;
    }

    // Hive/Database
    if (errorString.contains('hive') ||
        errorString.contains('database') ||
        errorString.contains('banco de dados')) {
      return l10n.errorDatabase;
    }

    // JSON Parse
    if (errorString.contains('json') ||
        errorString.contains('parse') ||
        errorString.contains('format')) {
      return l10n.errorJsonParse;
    }

    // Null/Empty
    if (errorString.contains('null') || errorString.contains('empty')) {
      return l10n.errorIncompleteData;
    }

    // Mensagem genérica amigável
    return l10n.errorGeneric;
  }

  /// Executa uma função com tratamento automático de erros
  static Future<T?> safeExecute<T>(
    BuildContext context, {
    required Future<T> Function() function,
    String? errorMessage,
    T? defaultValue,
  }) async {
    try {
      return await function();
    } catch (e, stack) {
      debugPrint('🔴 ERRO EM safeExecute: $e');
      debugPrint('Stack: $stack');

      if (context.mounted) {
        showError(context, error: e, customMessage: errorMessage);
      }

      return defaultValue;
    }
  }

  /// Executa uma função síncrona com tratamento automático de erros
  static T? safeExecuteSync<T>(
    BuildContext context, {
    required T Function() function,
    String? errorMessage,
    T? defaultValue,
  }) {
    try {
      return function();
    } catch (e, stack) {
      debugPrint('🔴 ERRO EM safeExecuteSync: $e');
      debugPrint('Stack: $stack');

      if (context.mounted) {
        showError(context, error: e, customMessage: errorMessage);
      }

      return defaultValue;
    }
  }
}
