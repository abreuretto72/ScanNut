/// ============================================================================
/// 🚫 COMPONENTE BLINDADO E CONGELADO - NÃO ALTERAR
/// Este módulo de Análise de Imagem Pet foi concluído e validado.
/// Nenhuma rotina ou lógica interna deve ser modificada.
/// Data de Congelamento: 29/12/2025
/// ============================================================================

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
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
      debugPrint('🚀 [PetAnalysis] Sending request to IA...');
      debugPrint('📝 [PetAnalysis] Prompt Preview: ${prompt.substring(0, prompt.length > 200 ? 200 : prompt.length)}...');
      
      final jsonString = await _groqService.analyzeImage(image, prompt);
      
      debugPrint('📥 [PetAnalysis] Raw Response: $jsonString');
      
      if (jsonString == null) {
        throw Exception("Não foi possível analisar a imagem (Resposta vazia).");
      }

      // Robust JSON Sanitization (matching PlantAnalysisService)
      String cleanJson = jsonString;
      if (cleanJson.contains('```json')) {
        cleanJson = cleanJson.split('```json').last.split('```').first.trim();
      } else if (cleanJson.contains('```')) {
        cleanJson = cleanJson.split('```').last.split('```').first.trim();
      } else {
        cleanJson = cleanJson.trim();
      }

      final Map<String, dynamic> data = jsonDecode(cleanJson);
      
      if (data.containsKey('error')) {
         throw Exception("Erro retornado pela IA: ${data['error']}");
      }
      
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
        possiveisCausasDiag: ["Imagem difere da categoria ou sem conexão"],
        urgenciaNivelDiag: "Amarelo",
        orientacaoImediataDiag: "Tente novamente ou procure um veterinário se houver dúvidas.",
      );
    }
  }
}
