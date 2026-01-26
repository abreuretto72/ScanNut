
import 'package:flutter/foundation.dart';
import '../../../../core/services/remote_config_service.dart';
import '../../../../core/services/gemini_service.dart';

/// 🌿 PLANT AI SERVICE (ISOLADO DO DOMÍNIO PET/FOOD)
/// Foco exclusivo em botânica, identificação e fitopatologia.
class PlantAiService {
  static final PlantAiService _instance = PlantAiService._internal();
  factory PlantAiService() => _instance;
  PlantAiService._internal();

  final GeminiService _geminiService = GeminiService();
  final RemoteConfigService _remoteConfig = RemoteConfigService();

  /// Consulta sobre cuidados ou identificação botânica
  Future<String> askBotanistAi(String query, {String locale = 'pt'}) async {
    try {
      // 1. Configuração Remota
      final config = await _remoteConfig.getPlantConfig();
      debugPrint('🌿 [PlantAi] Using Model: ${config.activeModel}');

      // 2. System Prompt
      final systemPrompt = _buildSystemPrompt(locale);

      final fullPrompt = """
$systemPrompt

PERGUNTA DE JARDINAGEM:
$query

Responda como uma IA Botânica (ScanNut Plant). Foco em cuidados, rega, luz e solo.
""";

      return await _geminiService.generateWithModel(
        prompt: fullPrompt,
        model: config.activeModel,
        apiEndpoint: config.apiEndpoint.endsWith('/') ? config.apiEndpoint : '${config.apiEndpoint}/',
      );

    } catch (e) {
      debugPrint('❌ [PlantAi] Erro: $e');
      return "Erro no sistema de botânica. Tente novamente.";
    }
  }

  String _buildSystemPrompt(String locale) {
    if (locale.contains('pt')) {
      return "Você é a ScanNut Plant AI, especialista em botânica, agricultura urbana e paisagismo. "
          "Sua missão é ajudar a cuidar de plantas. "
          "Se perguntarem sobre pets ou comida humana, diga que seu foco é apenas PLANTA. "
          "Use Markdown.";
    }
    return "You are ScanNut Plant AI, a botany specialist. "
        "Focus only on plants. Use Markdown.";
  }
}
