import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_analysis_model.dart';
import '../data/food_constants.dart';

final foodAnalysisServiceProvider = Provider<FoodAnalysisService>((ref) {
  final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  return FoodAnalysisService(apiKey);
});

class FoodAnalysisService {
  final String _apiKey;
  late final Dio _dio;

  FoodAnalysisService(this._apiKey) {
    // 🛡️ ISOLAMENTO TOTAL: Cliente HTTP exclusivo para o Módulo de Comida
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 45),
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': _apiKey, // Autenticação direta
      },
      validateStatus: (status) => status! < 500,
    ));
  }

  Future<FoodAnalysisModel> analyzeFood(File image) async {
    try {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes).replaceAll(RegExp(r'\s+'), '');

      final requestBody = {
        "contents": [
          {
            "parts": [
              {"text": FoodConstants.systemPrompt},
              {
                "inlineData": {
                  "mimeType": "image/jpeg",
                  "data": base64Image
                }
              }
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.1, // Precisão clínica
          "responseMimeType": "application/json"
        }
      };

      final response = await _dio.post(
        FoodConstants.endpoint, 
        data: requestBody
      );

      if (response.statusCode == 200) {
        final rawText = response.data['candidates'][0]['content']['parts'][0]['text'];
        final Map<String, dynamic> json = _safeJsonDecode(rawText);
        
        // 🛡️ DEBUG LOG: Rastreamento de Resposta da IA
        // ignore: avoid_print
        print('DEBUG_FOOD_RAW: $json');

        // 🛡️ USO DO ESCUDO DE MAPEAMENTO
        return FoodAnalysisModel.fromGemini(json);
      } else {
        throw Exception('Food Analysis Failed: ${response.statusCode}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ [FoodModule] Critical Error: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _safeJsonDecode(String text) {
     try {
       final clean = text.replaceAll('```json', '').replaceAll('```', '').trim();
       return jsonDecode(clean);
     } catch (e) {
       return {'error': 'parse_error', 'raw': text};
     }
  }
}

