import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/groq_api_service.dart';
import '../models/pet_analysis_result.dart';

final petAnalysisServiceProvider = Provider<PetAnalysisService>((ref) {
  final groqService = ref.watch(groqApiServiceProvider);
  return PetAnalysisService(groqService);
});

class PetAnalysisService {
  final GroqApiService _groqService;

  PetAnalysisService(this._groqService);

  Future<PetAnalysisResult> analyzePet(File image) async {
import '../../../core/utils/prompt_factory.dart';
import '../../../core/enums/scannut_mode.dart';

    final prompt = PromptFactory.getPrompt(ScannutMode.pet);

    try {
      final jsonString = await _groqService.analyzeImage(image, prompt);
      
      if (jsonString == null) {
        throw Exception("Não foi possível analisar a imagem.");
      }

      // Clean up markdown code blocks if present
      final cleanJson = jsonString
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final Map<String, dynamic> data = jsonDecode(cleanJson);
      return PetAnalysisResult.fromJson(data);
    } catch (e) {
      // Fallback for parsing errors or API errors
      return PetAnalysisResult(
        especie: "Não identificado",
        descricaoVisual: "Erro ao processar a resposta da IA.",
        possiveisCausas: ["Erro de conexão ou formato inválido"],
        urgenciaNivel: "Amarelo", // Default to caution
        orientacaoImediata: "Tente novamente ou procure um veterinário se houver dúvidas.",
      );
    }
  }
}
