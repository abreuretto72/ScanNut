
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/remote_config_service.dart';
import '../../../../core/services/gemini_service.dart';
import 'botany_service.dart';

/// 🌿 PLANT AI SERVICE (ISOLADO DO DOMÍNIO PET/FOOD)
/// Foco exclusivo em botânica, identificação e fitopatologia.
/// Utiliza RAG baseada no histórico de plantas do usuário.
class PlantAiService {
  static final PlantAiService _instance = PlantAiService._internal();
  factory PlantAiService() => _instance;
  PlantAiService._internal();

  final GeminiService _geminiService = GeminiService();
  final RemoteConfigService _remoteConfig = RemoteConfigService();
  final BotanyService _botanyService = BotanyService();

  // Histórico de Conversa
  final List<Map<String, String>> _chatHistory = [];

  void addToHistory(String role, String text) => _chatHistory.add({'role': role, 'text': text});
  void clearHistory() => _chatHistory.clear();

  /// Consulta sobre cuidados ou identificação botânica
  Future<String> sendQuery(String query, {String locale = 'pt'}) async {
    try {
      // 1. Configuração Remota
      final config = await _remoteConfig.getPlantConfig();
      debugPrint('🌿 [PlantAi] Using Model: ${config.activeModel}');

      // 2. RAG Context (Histórico de Plantas)
      final ragContext = await _buildRagContext();

      // 3. System Prompt
      final systemPrompt = _buildSystemPrompt(locale);

      // 4. Montagem do Prompt
      final fullPrompt = """
$systemPrompt

MEU JARDIM (CONTEXTO RAG - ÚLTIMAS PLANTAS ANALISADAS):
$ragContext

HISTÓRICO DA CONVERSA:
${_formatChatHistory()}

PERGUNTA DE JARDINAGEM:
$query

Responda como uma IA Botânica (ScanNut Plant). Foco em cuidados, rega, luz e solo.
""";

      // 5. Geração
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

  Future<String> _buildRagContext() async {
    try {
      final history = await _botanyService.getHistory();
      final recentItems = history.take(15).toList();

      if (recentItems.isEmpty) {
        return "O usuário ainda não registrou nenhuma planta.";
      }

      StringBuffer buffer = StringBuffer();
      buffer.writeln("Minhas Plantas Recentes:");
      for (var item in recentItems) {
        final date = DateFormat('dd/MM/yy').format(item.timestamp);
        final saude = item.healthStatus;
        final needs = item.lightWaterSoilNeeds;
        buffer.writeln("- $date: ${item.plantName} (Saúde: $saude). Luz: ${needs['luz']}. Rega: ${needs['agua']}.");
      }
      return buffer.toString();
    } catch (e) {
      return "Erro ao recuperar jardim: $e";
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
      return "Você é a ScanNut Plant AI, especialista em botânica, agricultura urbana e paisagismo. "
          "Sua missão é ajudar a cuidar de plantas e diagnosticar problemas. "
          "Se perguntarem sobre pets ou comida humana, diga que seu foco é apenas PLANTA. "
          "Use Markdown.";
    }
    return "You are ScanNut Plant AI, a botany specialist. "
        "Focus only on plants. Use Markdown.";
  }
}
