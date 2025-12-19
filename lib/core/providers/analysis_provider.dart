import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/analysis_state.dart';
import '../services/groq_service.dart';
import '../enums/scannut_mode.dart';
import '../../features/food/models/food_analysis_model.dart';
import '../../features/plant/models/plant_analysis_model.dart';
import '../../features/pet/models/pet_analysis_result.dart';

// Provider for GroqService
final groqServiceProvider = Provider<GroqService>((ref) {
  return GroqService();
});

// StateNotifier for managing analysis state
class AnalysisNotifier extends StateNotifier<AnalysisState> {
  final GroqService _groqService;

  AnalysisNotifier(this._groqService) : super(AnalysisIdle());

  /// Analyze image based on selected mode
  Future<void> analyzeImage({
    required File imageFile,
    required ScannutMode mode,
  }) async {
    state = AnalysisLoading(message: _getLoadingMessage(mode));

    try {
      final jsonResponse = await _groqService.analyzeImage(
        imageFile: imageFile,
        mode: mode,
      );

      // Parse response based on mode
      switch (mode) {
        case ScannutMode.food:
          final foodAnalysis = FoodAnalysisModel.fromJson(jsonResponse);
          state = AnalysisSuccess<FoodAnalysisModel>(foodAnalysis);
          break;

        case ScannutMode.plant:
          final plantAnalysis = PlantAnalysisModel.fromJson(jsonResponse);
          state = AnalysisSuccess<PlantAnalysisModel>(plantAnalysis);
          break;

        case ScannutMode.pet:
          final petAnalysis = PetAnalysisResult.fromJson(jsonResponse);
          state = AnalysisSuccess<PetAnalysisResult>(petAnalysis);
          break;
      }
    } on GroqException catch (e) {
      state = AnalysisError(e.message);
    } catch (e) {
      state = AnalysisError('Erro ao processar análise: $e');
    }
  }

  /// Reset state to idle
  void reset() {
    state = AnalysisIdle();
  }

  String _getLoadingMessage(ScannutMode mode) {
    switch (mode) {
      case ScannutMode.food:
        return 'Analisando alimento...';
      case ScannutMode.plant:
        return 'Diagnosticando planta...';
      case ScannutMode.pet:
        return 'Avaliando pet...';
    }
  }
}

// Provider for AnalysisNotifier
final analysisNotifierProvider =
    StateNotifierProvider<AnalysisNotifier, AnalysisState>((ref) {
  final groqService = ref.watch(groqServiceProvider);
  return AnalysisNotifier(groqService);
});
