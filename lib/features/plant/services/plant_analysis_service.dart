// ═══════════════════════════════════════════════════════════════════════════════
// 🚫 MÓDULO BLINDADO E CONGELADO - NÃO ALTERAR SEM AUTORIZAÇÃO EXPLÍCITA
// Data de Congelamento: 29/12/2025
// Este serviço contém a lógica de análise botânica via IA com 7 camadas de inteligência.
// Qualquer modificação pode comprometer a precisão dos diagnósticos e recomendações.
// ═══════════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/groq_api_service.dart';
import '../../../core/utils/prompt_factory.dart';
import '../../../core/enums/scannut_mode.dart';
import '../models/plant_analysis_model.dart';

final plantAnalysisServiceProvider = Provider<PlantAnalysisService>((ref) {
  final groqService = ref.watch(groqApiServiceProvider);
  return PlantAnalysisService(groqService);
});

class PlantAnalysisService {
  final GroqApiService _groqService;

  PlantAnalysisService(this._groqService);

  Future<PlantAnalysisModel> analyzePlant(File image) async {
    final prompt = PromptFactory.getPrompt(ScannutMode.plant);

    try {
      final jsonString = await _groqService.analyzeImage(image, prompt);
      
      if (jsonString == null) {
        throw Exception("Não foi possível analisar a planta.");
      }

      final cleanJson = jsonString
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final Map<String, dynamic> data = jsonDecode(cleanJson);
      
      if (data.containsKey('error')) {
        throw Exception("Erro da IA: ${data['error']}");
      }

      return PlantAnalysisModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }
}
