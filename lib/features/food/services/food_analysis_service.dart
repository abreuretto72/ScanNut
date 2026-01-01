/// ============================================================================
/// 🚫 COMPONENTE BLINDADO E CONGELADO - NÃO ALTERAR
/// Este módulo de Análise de Comida foi concluído e validado.
/// Nenhuma rotina ou lógica interna deve ser modificada.
/// Data de Congelamento: 29/12/2025
/// ============================================================================

import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/groq_api_service.dart';
import '../../../core/utils/prompt_factory.dart';
import '../../../core/enums/scannut_mode.dart';
import '../models/food_analysis_model.dart';

final foodAnalysisServiceProvider = Provider<FoodAnalysisService>((ref) {
  final groqService = ref.watch(groqApiServiceProvider);
  return FoodAnalysisService(groqService);
});

class FoodAnalysisService {
  final GroqApiService _groqService;

  FoodAnalysisService(this._groqService);

  Future<FoodAnalysisModel> analyzeFood(File image) async {
    final prompt = PromptFactory.getPrompt(ScannutMode.food);

    try {
      final jsonString = await _groqService.analyzeImage(image, prompt);
      
      if (jsonString == null) {
        throw Exception("Não foi possível analisar o alimento.");
      }

      // DEBUG: Print raw response to debug parsing issues
      // ignore: avoid_print
      print('🔍 RAW IA RESPONSE: $jsonString');

      final cleanJson = jsonString
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .replaceAll('json', '') // Extra safety for loose "json" text
          .trim();

      final Map<String, dynamic> data = jsonDecode(cleanJson);
      
      // Handle potential API response errors
      if (data.containsKey('error')) {
        throw Exception("Erro da IA: ${data['error']}");
      }

      return FoodAnalysisModel.fromJson(data);
    } catch (e) {
      // Log specific parsing error
      // ignore: avoid_print
      print('❌ Error parsing food analysis: $e');
      rethrow;
    }
  }
}
