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
        requestBody: true,
        responseBody: true,
        error: true,
      ));
    }
  }

  /// Main method to analyze images using Groq's LLaVA vision model
  Future<Map<String, dynamic>> analyzeImage({
    required File imageFile,
    required ScannutMode mode,
  }) async {
    try {
      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      final imageUrl = 'data:image/jpeg;base64,$base64Image';

      // Get appropriate prompt for the mode
      final prompt = PromptFactory.getPrompt(mode);

      // Prepare the request payload
      final payload = {
        'model': 'llava-v1.5-7b-4096-preview',
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': prompt,
              },
              {
                'type': 'image_url',
                'image_url': {
                  'url': imageUrl,
                },
              },
            ],
          }
        ],
        'temperature': 0.3,
        'max_tokens': 2048,
        'top_p': 1,
        'stream': false,
        'response_format': {'type': 'json_object'},
      };

      debugPrint('🚀 Sending request to Groq API...');

      // Make the API call
      final response = await _dio.post(
        '/chat/completions',
        data: payload,
      );

      if (response.statusCode == 200) {
        final content = response.data['choices'][0]['message']['content'];
        debugPrint('✅ Received response from Groq API');
        
        // Parse JSON response
        final jsonResponse = jsonDecode(content) as Map<String, dynamic>;
        
        // Check for error field in response
        if (jsonResponse.containsKey('error')) {
          throw GroqException('AI Error: ${jsonResponse['error']}');
        }
        
        return jsonResponse;
      } else {
        throw GroqException('API returned status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('❌ Dio Error: ${e.message}');
      
      if (e.type == DioExceptionType.connectionTimeout) {
        throw GroqException('Tempo de conexão esgotado. Verifique sua internet.');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw GroqException('Tempo de resposta esgotado. Tente novamente.');
      } else if (e.response?.statusCode == 401) {
        throw GroqException('Chave de API inválida ou expirada.');
      } else if (e.response?.statusCode == 429) {
        throw GroqException('Limite de requisições atingido. Aguarde alguns instantes.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw GroqException('Sem conexão com a internet.');
      } else {
        throw GroqException('Erro de rede: ${e.message}');
      }
    } catch (e) {
      debugPrint('❌ Unexpected Error: $e');
      throw GroqException('Erro inesperado: $e');
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
