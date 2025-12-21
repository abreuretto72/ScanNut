import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/groq_api_service.dart';
import '../models/pet_analysis_result.dart';
import '../../../core/utils/prompt_factory.dart';
import '../../../core/enums/scannut_mode.dart';

final petAnalysisServiceProvider = Provider<PetAnalysisService>((ref) {
  final groqService = ref.watch(groqApiServiceProvider);
  return PetAnalysisService(groqService);
});

class PetAnalysisService {
  final GroqApiService _groqService;

  PetAnalysisService(this._groqService);

  Future<PetAnalysisResult> analyzePet(File image, ScannutMode mode) async {
    final prompt = PromptFactory.getPrompt(mode);

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
        analysisType: 'identification',
        identificacao: IdentificacaoPet.empty(),
        perfilComportamental: PerfilComportamental.empty(),
        nutricao: NutricaoEStrutura.empty(),
        higiene: Grooming.empty(),
        saude: SaudePreventiva.empty(),
        lifestyle: LifestyleEEducacao.empty(),
        dica: DicaEspecialista.empty(),
        especieDiag: "Não identificado",
        racaDiag: "Não identificada",
        caracteristicasDiag: "Erro na análise",
        descricaoVisualDiag: "Erro ao processar a resposta da IA.",
        possiveisCausasDiag: ["Erro de conexão ou formato inválido"],
        urgenciaNivelDiag: "Amarelo",
        orientacaoImediataDiag: "Tente novamente ou procure um veterinário se houver dúvidas.",
      );
    }
  }
}
