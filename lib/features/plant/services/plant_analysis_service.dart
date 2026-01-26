import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/enums/scannut_mode.dart';
import '../models/plant_analysis_model.dart';

final plantAnalysisServiceProvider = Provider<PlantAnalysisService>((ref) {
  final geminiService = ref.watch(geminiServiceProvider);
  return PlantAnalysisService(geminiService);
});

class PlantAnalysisService {
  final GeminiService _geminiService;

  PlantAnalysisService(this._geminiService);

  Future<PlantAnalysisModel> analyzePlant(File image,
      {String locale = 'pt_BR'}) async {
    // 3. Alinhamento de Idioma (Locale)
    String normalizedLocale = locale;
    if (locale.toLowerCase().startsWith('en')) {
      normalizedLocale = 'en';
    }

    int retries = 1;
    while (retries >= 0) {
      try {
        final data = await _geminiService.analyzeImage(
          imageFile: image,
          mode: ScannutMode.plant,
          locale: normalizedLocale,
        );

        return PlantAnalysisModel.fromJson(data);
      } catch (e) {
        // ERROR HANDLING (Recuperação de Crash)
        debugPrint('⚠️ Plant Analysis Critical Failure: $e');

        if (e.toString().contains("Null check operator")) {
          throw Exception(
              "Ops! Não conseguimos ler todos os detalhes da planta. Tente uma foto mais nítida.");
        }

        if (retries == 0) {
          rethrow;
        }
        retries--;
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    throw Exception("Erro desconhecido na análise.");
  }
}
