import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/gemini_service.dart';
import '../models/pet_analysis_result.dart';
import '../../../core/enums/scannut_mode.dart';

final petAnalysisServiceProvider = Provider<PetAnalysisService>((ref) {
  final geminiService = ref.watch(geminiServiceProvider);
  return PetAnalysisService(geminiService);
});

class PetAnalysisService {
  final GeminiService _geminiService;

  PetAnalysisService(this._geminiService);

  Future<PetAnalysisResult> analyzePet(File image, ScannutMode mode) async {
    try {
      debugPrint('🚀 [PetAnalysis] Migrating to Gemini Engine...');
      
      final data = await _geminiService.analyzeImage(
        imageFile: image,
        mode: mode,
      );

      return PetAnalysisResult.fromJson(data);
    } catch (e) {
      debugPrint('🚨 [PetAnalysis] Failure: $e');
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
        possiveisCausasDiag: ["Possível inconsistência na análise ou falha de conexão. Verifique se a foto está clara."],
        urgenciaNivelDiag: "Amarelo",
        orientacaoImediataDiag:
            "A IA não conseguiu processar todos os detalhes desta vez. Tente tirar uma foto com iluminação diferente ou de outro ângulo.",
      );
    }
  }
}
