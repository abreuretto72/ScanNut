import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_analysis_model.dart';
import '../data/food_constants.dart';
import 'food_config_service.dart';

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
        'x-goog-api-key': _apiKey,
        'X-Android-Package': 'com.multiversodigital.scannut',
        'X-Android-Cert': 'AC:92:22:DC:06:3F:B2:A5:00:05:6B:40:AE:6F:3E:44:E2:A9:5F:F6',
      },
      validateStatus: (status) => status! < 500,
    ));
  }

  Future<FoodAnalysisModel> analyzeFood(File image) async {
    return _analyzeGeneric(image, FoodConstants.systemPrompt);
  }

  Future<FoodAnalysisModel> analyzeMeal(File image) async {
    return _analyzeGeneric(image, FoodConstants.mealSystemPrompt);
  }

  // 🧑‍🍳 CHEF VISION
  Future<FoodAnalysisModel> analyzeChefVision(File image, {String? constraints}) async {
    String finalPrompt = FoodConstants.chefVisionSystemPrompt;
    if (constraints != null && constraints.isNotEmpty) {
      finalPrompt += "\n\nRESTRIÇÃO/PEDIDO DO USUÁRIO (RAG): $constraints. AJUSTE AS RECEITAS PARA ATENDER A ESTE PEDIDO.";
    }
    return _analyzeGeneric(image, finalPrompt);
  }


  Future<FoodAnalysisModel> _analyzeGeneric(File image, String prompt) async {
    debugPrint('🔍 [FoodTrace] Starting Analysis. Prompt length: ${prompt.length}');
    try {
      // 🛡️ DYNAMIC CONFIG: Fetch latest endpoint/model from Remote Config
      final configService = FoodConfigService();
      final config = await configService.getFoodConfig();
      // Construct URL: base + model + :generateContent
      // Ensure slash handling if needed, but config default assumes '.../models/'
      final endpointUrl = '${config.apiEndpoint}${config.activeModel}:generateContent';

      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes).replaceAll(RegExp(r'\s+'), '');

      final requestBody = {
        "contents": [
          {
            "parts": [
              {"text": prompt},
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
        endpointUrl, // Dynamic Endpoint
        data: requestBody
      );

      if (response.statusCode == 200) {
        final candidates = response.data['candidates'] as List?;
        if (candidates == null || candidates.isEmpty) {
           throw Exception('IA retornou uma resposta vazia (Provável filtro de segurança).');
        }

        final firstCandidate = candidates[0];
        final parts = firstCandidate['content']?['parts'] as List?;
        if (parts == null || parts.isEmpty) {
           throw Exception('IA não gerou texto válido.');
        }

        final rawText = parts[0]['text']?.toString() ?? '';
        print('DEBUG_CHEF: Resposta bruta da IA: $rawText');
        final Map<String, dynamic> json = _safeJsonDecode(rawText);
        
        // 🛡️ [ALERTA 2.5] JSON BRUTO (Protocolo de Visibilidade)
        debugPrint('--- [ALERTA 2.5] RAW TEXT: $rawText');
        debugPrint('--- [ALERTA 2.5] JSON OBJ: $json');
        
        // ignore: avoid_print
        print('DEBUG_FOOD_RAW: $json');

        if (json.containsKey('error') && json['error'] == 'parse_error') {
           throw Exception('Erro ao processar JSON da IA: ${json['raw']}');
        }

        // 🛡️ USO DO ESCUDO DE MAPEAMENTO
        return FoodAnalysisModel.fromGemini(json);
      } else {
        final errorMsg = response.data?['error']?['message'] ?? 'Status ${response.statusCode}';
        throw Exception('Food Analysis Failed: $errorMsg');
      }
    } catch (e) {
      // ignore: avoid_print
      debugPrint('❌ [FoodTrace] Critical Error in Service: $e');
      print('❌ [FoodModule] Critical Error: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _safeJsonDecode(String text) {
     try {
       // 🛡️ REPARO DO PARSER (Lei de Ferro): Limpeza de Markdown do Gemini 2.5
       final clean = text.replaceAll('```json', '').replaceAll('```', '').trim();
       if (clean.isEmpty) return {};
       
       dynamic decoded = jsonDecode(clean);
       
       // Handle double-encoded JSON strings which Gemini sometimes returns
       if (decoded is String) {
          try {
            decoded = jsonDecode(decoded);
          } catch (e) {
            debugPrint('⚠️ [FoodService] Failed to parse inner JSON string: $e');
            // Continue with original decoded string if second parse fails, though likely wrong
          }
       }
       
       if (decoded is Map<String, dynamic>) {
         return decoded;
       } else if (decoded is Map) {
         return Map<String, dynamic>.from(decoded);
       } else {
         debugPrint('⚠️ [FoodService] JSON is not a Map: ${decoded.runtimeType}');
         return {'error': 'parse_error', 'raw': text};
       }
     } catch (e) {
       print('DEBUG_CHEF: Erro ao parsear JSON: $e');
       debugPrint('⚠️ [FoodService] JSON Parse Error: $e');
       return {'error': 'parse_error', 'raw': text};
     }
  }
}

