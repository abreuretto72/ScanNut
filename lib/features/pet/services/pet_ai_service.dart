
import 'package:flutter/foundation.dart';
import '../../../../core/services/remote_config_service.dart';
import '../../../../core/services/gemini_service.dart';
import 'chat/context_aggregator_service.dart';

/// 🐾 PET AI SERVICE (ISOLADO DO DOMÍNIO FOOD)
/// Foco exclusivo em saúde, nutrição e comportamento animal.
/// Utiliza configuração remota para definição de modelo.
class PetAiService {
  static final PetAiService _instance = PetAiService._internal();
  factory PetAiService() => _instance;
  PetAiService._internal();

  final GeminiService _geminiService = GeminiService();
  final RemoteConfigService _remoteConfig = RemoteConfigService();

  // Histórico de Conversa
  final List<Map<String, String>> _chatHistory = [];

  void addToHistory(String role, String text) => _chatHistory.add({'role': role, 'text': text});
  void clearHistory() => _chatHistory.clear();

  /// Analisa sintomas ou dúvidas veterinárias
  // Renomeado para manter consistência com FoodAiChatService, mas mantendo alias se necessário
  Future<String> sendQuery(String query, String petId, {String locale = 'pt'}) async {
    try {
      // 1. Configuração Remota
      final config = await _remoteConfig.getPetConfig();
      debugPrint('🐾 [PetAi] Using Model: ${config.activeModel}');

      // 2. RAG Context (Contexto Agregado do Pet)
      final petContext = await ContextAggregatorService.aggregateForRag(petId);

      // 3. System Prompt Específico
      final systemPrompt = _buildSystemPrompt(locale);

      // 4. Montagem do Prompt
      final fullPrompt = """
$systemPrompt

CONTEXTO DO PET (PRONTUÁRIO):
$petContext

HISTÓRICO DA CONVERSA:
${_formatChatHistory()}

DÚVIDA DO TUTOR:
$query

DICAS DE RESPOSTA:
1. FOCO TOTAL NO CONTEXTO: Analise cuidadosamente as abas de SAÚDE e exames laboratoriais.
2. ALERTAS CRÍTICOS: Se a pergunta envolver venenos, chocolate, uva ou qualquer perigo alimentar, comece com "🚨 [DANGER]".
3. STATUS POSITIVO: Se confirmar saúde perfeita, vacinas em dia ou peso ideal, comece com "✅ [SAFE]".
4. TRANSPARÊNCIA: Se a informação não estiver no contexto, diga que não encontrou registro específico.
""";

      // 5. Geração
      String response = await _geminiService.generateWithModel(
        prompt: fullPrompt,
        model: config.activeModel,
        apiEndpoint: config.apiEndpoint.endsWith('/') ? config.apiEndpoint : '${config.apiEndpoint}/',
      );

      // Limpeza de tags internas se necessário (o UI lida com elas, mas podemos limpar se o prompt pedir)
      // O prompt original do PetChatScreen pedia para limpar, mas aqui vamos retornar raw e o UI decide
      // ou podemos limpar aqui. O PetChatScreen antigo limpava.
      // Vamos manter as tags para o UI processar (danger/safe).

      return response;

    } catch (e) {
      debugPrint('❌ [PetAi] Erro: $e');
      return locale.contains('pt') 
          ? "Não consegui processar sua dúvida no momento. Consulte um veterinário real para emergências."
          : "Could not process your query. Please consult a real vet for emergencies.";
    }
  }

  String _formatChatHistory() {
    final recent = _chatHistory.length > 6 
        ? _chatHistory.sublist(_chatHistory.length - 6) 
        : _chatHistory;
    return recent.map((m) => "${m['role']?.toUpperCase()}: ${m['text']}").join("\n");
  }

  String _buildSystemPrompt(String locale) {
    if (locale.contains('pt')) {
      return "VOCÊ É O ASSISTENTE DE INTELIGÊNCIA VETERINÁRIA DO SCANNUT (ScanNut Pet AI). "
          "Você é especialista em clínica médica de pequenos animais, nutrição e comportamento. "
          "Seu objetivo é orientar tutores com base nos dados fornecidos. "
          "IMPORTANTE: Você NÃO responde sobre dieta humana, plantas (exceto toxicidade) ou assuntos aleatórios. "
          "Se a pergunta fugir do tema Pet, recuse educadamente. "
          "Use Markdown.";
    }
    return "You are ScanNut Pet AI, a specialist in animal health and nutrition. "
        "Do NOT answer questions about human diet or general gardening. "
        "Use Markdown.";
  }
}
