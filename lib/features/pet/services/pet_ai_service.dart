
import 'package:flutter/foundation.dart';
import '../../../../core/services/remote_config_service.dart';
import '../../../../core/services/gemini_service.dart';

/// 🐾 PET AI SERVICE (ISOLADO DO DOMÍNIO FOOD)
/// Foco exclusivo em saúde, nutrição e comportamento animal.
/// Utiliza configuração remota para definição de modelo.
class PetAiService {
  static final PetAiService _instance = PetAiService._internal();
  factory PetAiService() => _instance;
  PetAiService._internal();

  final GeminiService _geminiService = GeminiService();
  final RemoteConfigService _remoteConfig = RemoteConfigService();

  /// Analisa sintomas ou dúvidas veterinárias
  Future<String> askVetAi(String query, {String locale = 'pt'}) async {
    try {
      // 1. Configuração Remota
      final config = await _remoteConfig.getPetConfig();
      debugPrint('🐾 [PetAi] Using Model: ${config.activeModel}');

      // 2. System Prompt Específico
      final systemPrompt = _buildSystemPrompt(locale);

      // 3. Montagem do Prompt
      final fullPrompt = """
$systemPrompt

DÚVIDA DO TUTOR:
$query

Responda como uma IA Assistente Veterinária (ScanNut Pet). Seja empática, técnica mas acessível.
Sempre inclua um aviso de que você é uma IA e não substitui uma consulta clínica presencial.
""";

      // 4. Geração
      return await _geminiService.generateWithModel(
        prompt: fullPrompt,
        model: config.activeModel,
        apiEndpoint: config.apiEndpoint.endsWith('/') ? config.apiEndpoint : '${config.apiEndpoint}/',
      );

    } catch (e) {
      debugPrint('❌ [PetAi] Erro: $e');
      return locale.contains('pt') 
          ? "Não consegui processar sua dúvida no momento. Consulte um veterinário real para emergências."
          : "Could not process your query. Please consult a real vet for emergencies.";
    }
  }

  String _buildSystemPrompt(String locale) {
    if (locale.contains('pt')) {
      return "Você é a ScanNut Pet AI, especialista em saúde, nutrição e comportamento animal (Cães e Gatos). "
          "Seu objetivo é orientar tutores. "
          "IMPORTANTE: Você NÃO responde sobre dieta humana ou plantas (exceto toxicidade para pets). "
          "Se a pergunta fugir do tema Pet, recuse educadamente. "
          "Use Markdown.";
    }
    return "You are ScanNut Pet AI, a specialist in animal health and nutrition. "
        "Do NOT answer questions about human diet or general gardening. "
        "Use Markdown.";
  }
}
