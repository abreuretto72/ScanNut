
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../../core/services/remote_config_service.dart';
import '../../../../core/services/gemini_service.dart';
import 'nutrition_service.dart';
import '../models/nutrition_history_item.dart';

/// 🧠 FOOD AI CHAT SERVICE (RAG ISOLADO)
/// Serviço de inteligência artificial focado exclusivamente no domínio de comida.
/// Utiliza RAG (Retrieval-Augmented Generation) baseado no histórico do usuário.
class FoodAiChatService {
  static final FoodAiChatService _instance = FoodAiChatService._internal();
  factory FoodAiChatService() => _instance;
  FoodAiChatService._internal();

  final NutritionService _nutritionService = NutritionService();
  final GeminiService _geminiService = GeminiService();
  
  // Histórico de Conversa
  List<Map<String, String>> _chatHistory = [];

  void addToHistory(String role, String text) => _chatHistory.add({'role': role, 'text': text});
  void clearHistory() => _chatHistory.clear();
  final RemoteConfigService _remoteConfig = RemoteConfigService();

  /// Envia a pergunta do usuário enriquecida com RAG
  Future<String> sendQuery(String userQuery, {String locale = 'pt'}) async {
    try {
      // 0. Obter Configuração Remota (ou Fallback)
      final config = await _remoteConfig.getFoodConfig();
      debugPrint('🧠 [FoodAiChat] Using Model: ${config.activeModel}');

      // 1. RAG: Buscar contexto do histórico alimentar
      final ragContext = await _buildRagContext();
      
      // 2. Construir Prompt de Sistema (System Prompt)
      final systemPrompt = _buildSystemPrompt(locale);

      // 3. Montar o prompt final
      final fullPrompt = """
$systemPrompt

CONTEXTO DO USUÁRIO (RAG - Histórico Recente):
$ragContext

HISTÓRICO DA CONVERSA:
${_formatChatHistory()}

PERGUNTA DO USUÁRIO:
$userQuery

Responda como uma nutricionista IA amigável e técnica. Use o contexto fornecido para personalizar a resposta.
""";
      
      // 4. Invocar Gemini com Configuração Dinâmica
      final response = await _geminiService.generateWithModel(
        prompt: fullPrompt, 
        model: config.activeModel,
        apiEndpoint: config.apiEndpoint.endsWith('/') ? config.apiEndpoint : '${config.apiEndpoint}/', // Garante slash
      );
      
      return response;
    } catch (e) {
      debugPrint('❌ [FoodAiChat] Erro: $e');
      return "Desculpe, meu sistema neural nutricional encontrou uma falha momentânea ($e). Tente novamente.";
    }
  }

  /// Constrói o contexto RAG a partir das últimas refeições
  Future<String> _buildRagContext() async {
    try {
      // Busca últimos 20 itens para não estourar tokens
      final history = await _nutritionService.getHistory();
      final recentItems = history.take(20).toList();

      if (recentItems.isEmpty) {
        return "O usuário ainda não registrou nenhuma refeição.";
      }

      StringBuffer buffer = StringBuffer();
      buffer.writeln("Últimas refeições registradas:");
      for (var item in recentItems) {
        final date = DateFormat('dd/MM HH:mm').format(item.timestamp);
        buffer.writeln("- $date: ${item.foodName} (${item.calories} kcal). Macros: P:${item.proteins}, C:${item.carbs}, G:${item.fats}. Processado: ${item.isUltraprocessed}.");
      }
      
      // Adiciona resumo do dia atual
      final now = DateTime.now();
      final summary = await _nutritionService.getDailySummary(now);
      buffer.writeln("\nResumo do dia hoje (${DateFormat('dd/MM').format(now)}):");
      buffer.writeln("Total Calorias: ${summary['calories']?.toStringAsFixed(0)} kcal");
      buffer.writeln("Proteínas: ${summary['proteins']?.toStringAsFixed(1)}g");
      
      return buffer.toString();
    } catch (e) {
      return "Erro ao recuperar histórico alimentar: $e";
    }
  }

  /// Define a persona da IA
  String _buildSystemPrompt(String locale) {
    if (locale.contains('pt')) {
      return "Você é a ScanNut AI, uma assistente especializada em nutrição e gastronomia humana. "
          "Seu objetivo é analisar o histórico do usuário e dar dicas, receitas e análises de saúde. "
          "IMPORTANTE: Você NÃO responde sobre Pets (cachorros, gatos) ou Jardinagem. "
          "Se a pergunta for sobre outro domínio, recuse educadamente e diga que é especialista apenas em comida humana. "
          "Use a formatação Markdown para deixar o texto bonito (negrito, listas).";
    }
    return "You are ScanNut AI, an expert assistant in human nutrition and gastronomy. "
        "Your goal is to analyze user history and provide tips, recipes, and health analysis. "
        "IMPORTANT: You do NOT answer about Pets or Gardening. "
        "If asked about other domains, politely refuse and state you are a human food specialist. "
        "Use Markdown formatting.";
  }

  String _formatChatHistory() {
    // Pega as últimas 6 mensagens para manter contexto sem gastar muito token
    final recent = _chatHistory.length > 6 
        ? _chatHistory.sublist(_chatHistory.length - 6) 
        : _chatHistory;
    
    return recent.map((m) => "${m['role']?.toUpperCase()}: ${m['text']}").join("\n");
  }
}
