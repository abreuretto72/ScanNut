import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../enums/scannut_mode.dart';
import '../utils/prompt_factory.dart';

class GroqService {
  late final Dio _dio;
  final String _baseUrl;
  final String _apiKey;

  GroqService()
      : _baseUrl = dotenv.env['BASE_URL'] ?? 'https://api.groq.com/openai/v1',
        _apiKey = dotenv.env['GROQ_API_KEY'] ?? '' {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
    ));

    // Add logging interceptor for debugging
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: false, // Don't log base64 images
        responseBody: true,
        error: true,
        requestHeader: true,
        responseHeader: false,
      ));
    }
  }

  /// Analyze image using Groq's vision model
  Future<Map<String, dynamic>> analyzeImage({
    required File imageFile,
    required ScannutMode mode,
  }) async {
    try {
      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      debugPrint('🚀 Sending request to Groq API...');
      debugPrint(
          '📦 Image size: ${(bytes.length / 1024).toStringAsFixed(2)} KB');

      // Get appropriate prompt for the mode
      final prompt = PromptFactory.getPrompt(mode);

      // Try vision model first
      try {
        return await _analyzeWithVision(base64Image, prompt);
      } catch (e) {
        debugPrint('⚠️ Vision model failed: $e');
        debugPrint('🔄 Falling back to mock analysis...');

        // Fallback to mock data for demonstration
        return _getMockAnalysis(mode);
      }
    } catch (e) {
      debugPrint('❌ Unexpected Error: $e');
      throw GroqException('Erro inesperado: $e');
    }
  }

  Future<Map<String, dynamic>> _analyzeWithVision(
      String base64Image, String prompt) async {
    final payload = {
      'model': 'llava-v1.5-7b-4096-preview',
      'messages': [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': prompt},
            {
              'type': 'image_url',
              'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
            },
          ],
        }
      ],
      'temperature': 0.5,
      'max_tokens': 1024,
    };

    final response = await _dio.post('/chat/completions', data: payload);

    if (response.statusCode == 200) {
      final content = response.data['choices'][0]['message']['content'];
      debugPrint('✅ Received response from Groq API');

      // Extract JSON from response
      String jsonString = content;
      if (content.contains('```json')) {
        final start = content.indexOf('```json') + 7;
        final end = content.lastIndexOf('```');
        if (end > start) jsonString = content.substring(start, end).trim();
      } else if (content.contains('```')) {
        final start = content.indexOf('```') + 3;
        final end = content.lastIndexOf('```');
        if (end > start) jsonString = content.substring(start, end).trim();
      }

      final jsonResponse = jsonDecode(jsonString) as Map<String, dynamic>;
      if (jsonResponse.containsKey('error')) {
        throw GroqException('AI Error: ${jsonResponse['error']}');
      }

      return jsonResponse;
    } else {
      throw GroqException('API returned status code: ${response.statusCode}');
    }
  }

  Map<String, dynamic> _getMockAnalysis(ScannutMode mode) {
    switch (mode) {
      case ScannutMode.food:
        return {
          'item_name': 'Alimento Detectado',
          'estimated_calories': 250,
          'macronutrients': {
            'protein': '15g',
            'carbs': '30g',
            'fats': '8g',
          },
          'benefits': [
            'Rico em nutrientes essenciais',
            'Fonte de energia',
          ],
          'risks': [
            'Consumir com moderação',
          ],
          'advice':
              'Análise visual em desenvolvimento. Por favor, consulte um nutricionista para informações precisas.',
        };

      case ScannutMode.plant:
        return {
          'plant_name': 'Planta Detectada',
          'condition': 'Análise visual',
          'diagnosis':
              'Sistema de visão em desenvolvimento. Consulte um especialista em botânica.',
          'organic_treatment':
              'Mantenha a planta bem hidratada e com boa exposição solar.',
          'urgency': 'low',
        };

      case ScannutMode.petIdentification:
      case ScannutMode.petDiagnosis:
      case ScannutMode.petVisualAnalysis:
      case ScannutMode.petDocumentOCR:
      case ScannutMode.petStoolAnalysis:
        return {
          'especie': 'Animal Detectado',
          'descricao_visual': 'Sistema de visão em desenvolvimento.',
          'possiveis_causas': [
            'Análise visual em desenvolvimento',
          ],
          'urgencia_nivel': 'Verde',
          'orientacao_imediata':
              'Consulte um veterinário para avaliação profissional. Este sistema está em desenvolvimento.',
        };
      default:
        return {'error': 'Modo desconhecido'};
    }
  }

  /// Test connection to Groq API
  Future<bool> testConnection() async {
    try {
      final response = await _dio.get('/models');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Connection test failed: $e');
      return false;
    }
  }
}

/// Custom exception for Groq API errors
class GroqException implements Exception {
  final String message;
  GroqException(this.message);

  @override
  String toString() => message;
}
