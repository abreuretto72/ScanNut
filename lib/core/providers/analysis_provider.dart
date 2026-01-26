import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/analysis_state.dart';
import '../services/gemini_service.dart';
import '../enums/scannut_mode.dart';
import '../../features/plant/models/plant_analysis_model.dart';
import '../../features/pet/models/pet_analysis_result.dart';

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

final analysisNotifierProvider = StateNotifierProvider<AnalysisNotifier, AnalysisState>((ref) {
  return AnalysisNotifier(ref.read(geminiServiceProvider));
});

class AnalysisNotifier extends StateNotifier<AnalysisState> {
  final GeminiService _geminiService;

  AnalysisNotifier(this._geminiService) : super(AnalysisIdle());

  Future<AnalysisState> analyzeImage({
    required File imageFile,
    required ScannutMode mode,
    String? petName,
    String? petId,
    List<String> excludedBases = const [],
    String locale = 'pt',
    Map<String, String>? contextData,
  }) async {
    state = AnalysisLoading(message: 'Analisando...', imagePath: imageFile.path);

    try {
      final jsonResponse = await _geminiService.analyzeImage(
        imageFile: imageFile,
        mode: mode,
        excludedBases: excludedBases,
        locale: locale,
        contextData: contextData,
      );

      switch (mode) {
        // 🛡️ ISOLAMENTO: Modo FOOD removido do Core (Transfira para food_analysis_provider.dart)
          
        case ScannutMode.plant:
          final plantAnalysis = PlantAnalysisModel.fromJson(jsonResponse);
          state = AnalysisSuccess<PlantAnalysisModel>(plantAnalysis);
          break;

        case ScannutMode.petIdentification:
        case ScannutMode.petDiagnosis:
        case ScannutMode.petStoolAnalysis:
          final petAnalysis = PetAnalysisResult.fromJson({
            ...jsonResponse,
            if (petName != null) 'pet_name': petName,
            if (petId != null) 'pet_id': petId,
          });
          state = AnalysisSuccess<PetAnalysisResult>(petAnalysis);
          break;

        default:
          throw Exception('Modo não suportado no Core (Verifique isolamento de domínio): $mode');
      }
      return state;
    } catch (e) {
      state = AnalysisError("Falha na análise: $e");
      return state;
    }
  }

  void reset() {
    state = AnalysisIdle();
  }
}