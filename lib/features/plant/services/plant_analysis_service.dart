// ═══════════════════════════════════════════════════════════════════════════════
// 🚫 MÓDULO BLINDADO E CONGELADO - NÃO ALTERAR SEM AUTORIZAÇÃO EXPLÍCITA
// Data de Congelamento: 29/12/2025
// Este serviço contém a lógica de análise botânica via IA com 7 camadas de inteligência.
// Qualquer modificação pode comprometer a precisão dos diagnósticos e recomendações.
// ═══════════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
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

  Future<PlantAnalysisModel> analyzePlant(File image,
      {String locale = 'pt_BR'}) async {
    // 3. Alinhamento de Idioma (Locale)
    String normalizedLocale = locale;
    if (locale.toLowerCase().startsWith('en')) {
      normalizedLocale = 'en';
    }

    final prompt =
        PromptFactory.getPrompt(ScannutMode.plant, locale: normalizedLocale);

    int retries = 1;
    while (retries >= 0) {
      try {
        final jsonString = await _groqService.analyzeImage(image, prompt);

        if (jsonString == null) {
          throw Exception("Não foi possível analisar a planta.");
        }

        // 2. Validação do JSON (Sanitização)
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
          throw Exception("Erro da IA: ${data['error']}");
        }

        return PlantAnalysisModel.fromJson(data);
      } catch (e) {
        // ERROR HANDLING (Recuperação de Crash)
        debugPrint('⚠️ Plant Analysis Critical Failure: $e');

        // Se for erro de Null Check, lançar mensagem amigável
        if (e.toString().contains("Null check operator")) {
          throw Exception(
              "Ops! Não conseguimos ler todos os detalhes da planta. Tente uma foto mais nítida.");
        }

        // 5. Logs de Debug
        debugPrint('Plant Analysis Error (Retries left: $retries): $e');

        if (retries == 0) {
          rethrow;
        }
        retries--;
        // Small delay before retry
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    throw Exception("Erro desconhecido na análise.");
  }
}
