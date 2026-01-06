import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../main.dart'; // To access scaffoldMessengerKey

final groqApiServiceProvider = Provider<GroqApiService>((ref) {
  return GroqApiService();
});

class GroqApiService {
  late final Dio _dio;

  GroqApiService() {
    final baseUrl = dotenv.env['BASE_URL'] ?? 'https://api.groq.com/openai/v1';
    final apiKey = dotenv.env['GROQ_API_KEY'] ?? '';

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException e, ErrorInterceptorHandler handler) {
          _showErrorSnackBar(e);
          return handler.next(e);
        },
      ),
    );
  }

  Future<String?> analyzeImage(File image, String prompt) async {
    try {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      final dataUrl = 'data:image/jpeg;base64,$base64Image';

      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': 'llava-v1.5-7b-4096-preview', 
          'messages': [
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': prompt},
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': dataUrl,
                  },
                },
              ],
            }
          ],
          'temperature': 0.1,
          'max_tokens': 2048,
        },
      );

      if (response.statusCode == 200) {
        final content = response.data['choices'][0]['message']['content'];
        return content.toString();
      }
      return null;
    } catch (e) {
      debugPrint('Error analyzing image: $e');
      rethrow;
    }
  }

  Future<String?> generateText(String prompt) async {
    try {
      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': 'llama3-70b-8192', 
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature': 0.1,
          'max_tokens': 4096,
        },
      );

      if (response.statusCode == 200) {
        final content = response.data['choices'][0]['message']['content'];
        return content.toString();
      }
      return null;
    } catch (e) {
      debugPrint('Error generating text: $e');
      rethrow;
    }
  }

  void _showErrorSnackBar(DioException e) {
    String message = 'Imagem difere da categoria ou sem conexão';
    if (e.type == DioExceptionType.connectionTimeout) {
      message = 'Tempo de conexão esgotado. Verifique sua internet.';
    } else if (e.response?.statusCode == 401) {
      message = 'Chave de API inválida ou expirada.';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'Sem conexão com a internet.';
    }

    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
