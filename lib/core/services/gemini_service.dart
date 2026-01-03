import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import '../enums/scannut_mode.dart';
import '../utils/prompt_factory.dart';

class GeminiService {
  late final Dio _dio;
  final String _apiKey;
  final String _baseUrl = 'https://generativelanguage.googleapis.com';

  GeminiService()
      : _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '' {
    
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ));
  }

  /// Find working model
  Future<String?> _findWorkingModel() async {
    final modelsToTry = [
      'gemini-1.5-flash',
      'gemini-2.0-flash-exp',
      'gemini-1.5-pro',
    ];

    for (final model in modelsToTry) {
      try {
        final response = await _dio.post(
          '/v1beta/models/$model:generateContent',
          queryParameters: {'key': _apiKey},
          data: {
            'contents': [
              {
                'parts': [
                  {'text': 'Test'}
                ]
              }
            ],
          },
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          debugPrint('✅ Modelo disponível: $model');
          return model;
        }
      } catch (e) {
        continue;
      }
    }

    return null;
  }

  /// Analyze image with robust error handling
  Future<Map<String, dynamic>> analyzeImage({
    required File imageFile,
    required ScannutMode mode,
    List<String> excludedBases = const [],
    String locale = 'pt', // Default to Portuguese
  }) async {
    try {
      if (_apiKey.isEmpty) {
        throw GeminiException(
          'API Key não configurada. Verifique o arquivo .env',
          type: GeminiErrorType.configuration,
        );
      }
      debugPrint('🚀 Iniciando análise...');
      
      // Validate image file
      if (!await imageFile.exists()) {
        throw GeminiException(
          'Arquivo de imagem não encontrado',
          type: GeminiErrorType.invalidImage,
        );
      }

      // Read and validate image
      final imageBytes = await imageFile.readAsBytes();
      if (imageBytes.isEmpty) {
        throw GeminiException(
          'Imagem vazia ou corrompida',
          type: GeminiErrorType.invalidImage,
        );
      }

      final sizeKB = imageBytes.length / 1024;
      if (sizeKB > 4096) {
        throw GeminiException(
          'Imagem muito grande (${sizeKB.toStringAsFixed(0)}KB). Máximo: 4MB',
          type: GeminiErrorType.invalidImage,
        );
      }

      debugPrint('📦 Imagem: ${sizeKB.toStringAsFixed(2)} KB');

      // Find working model
      final workingModel = await _findWorkingModel();
      if (workingModel == null) {
        throw GeminiException(
          'Nenhum modelo Gemini disponível',
          type: GeminiErrorType.serviceUnavailable,
        );
      }

      debugPrint('🤖 Modelo: $workingModel');

      // Encode image
      final base64Image = base64Encode(imageBytes);
      String prompt = PromptFactory.getPrompt(mode, locale: locale);
      
      // Inject meal rotation restriction if applicable
      if (mode == ScannutMode.petIdentification && excludedBases.isNotEmpty) {
        final restriction = '\n\nRESTRIÇÃO DE ROTAÇÃO NUTRICIONAL: O pet já consumiu recentemente as seguintes bases alimentares: ${excludedBases.join(", ")}. Para o plano_semanal, priorize ingredientes DIFERENTES para garantir variedade nutricional.';
        prompt += restriction;
        debugPrint('🔄 Rotação ativada: ${excludedBases.length} ingredientes excluídos');
      }

      // LOG 1: REQUEST PROMPT
      debugPrint('\n================ [ LOG 1: REQUEST PROMPT ] ================\n');
      debugPrint(prompt);
      debugPrint('\n===========================================================\n');

      // Prepare request
      final requestData = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Image,
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': mode == ScannutMode.plant ? 0.0 : 0.5,
          'maxOutputTokens': 4096,
        },
      };

      debugPrint('⏳ Enviando para Gemini...');
      final startTime = DateTime.now();

      // Make request with timeout
      final response = await _dio.post(
        '/v1beta/models/$workingModel:generateContent',
        queryParameters: {'key': _apiKey},
        data: requestData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept-Language': locale,
          },
        ),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Tempo limite excedido');
        },
      );

      final duration = DateTime.now().difference(startTime);
      debugPrint('⚡ Resposta em: ${duration.inMilliseconds}ms');

      // Validate response
      if (response.statusCode != 200) {
        if (response.statusCode == 400) {
          throw GeminiException(
             'Bad Request',
             type: GeminiErrorType.badRequest, // Maps to errorBadPhoto
          );
        }
        throw GeminiException(
          'Erro HTTP: ${response.statusCode}',
          type: GeminiErrorType.serverError,
        );
      }

      final text = response.data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      
      // LOG 2: RAW RESPONSE
      debugPrint('\n================ [ LOG 2: RESPONSE RAW ] ================\n');
      debugPrint(text?.toString() ?? 'NULL RESPONSE');
      debugPrint('\n===========================================================\n');
      
      if (text == null || text.isEmpty) {
        throw GeminiException(
          'Resposta vazia da IA',
          type: GeminiErrorType.emptyResponse,
        );
      }

      debugPrint('✅ Resposta recebida');

      // Parse JSON with error handling
      try {
        String jsonString = text;
        
        if (jsonString.contains('```json')) {
          jsonString = jsonString.split('```json').last.split('```').first.trim();
        } else if (jsonString.contains('```')) {
          jsonString = jsonString.split('```').last.split('```').first.trim();
        } else {
          jsonString = jsonString.trim();
        }


        final jsonResponse = jsonDecode(jsonString) as Map<String, dynamic>;

        if (jsonResponse.containsKey('error')) {
          throw GeminiException(
            'Erro da IA: ${jsonResponse['error']}',
            type: GeminiErrorType.aiError,
          );
        }

        debugPrint('✅ JSON parseado com sucesso');
        return jsonResponse;

      } on FormatException catch (e, stackTrace) {
        debugPrint('❌ Erro ao parsear JSON: $e');
        debugPrint('Stack: $stackTrace');
        throw GeminiException(
          'Formato de resposta inválido',
          type: GeminiErrorType.parseError,
        );
      }
      
    } on TimeoutException catch (e, stackTrace) {
      debugPrint('❌ Timeout: $e');
      debugPrint('Stack: $stackTrace');
      throw GeminiException(
        'A conexão demorou muito. Verifique sua internet.',
        type: GeminiErrorType.timeout,
      );
      
    } on SocketException catch (e, stackTrace) {
      debugPrint('❌ Erro de rede: $e');
      debugPrint('Stack: $stackTrace');
      throw GeminiException(
        'Sem conexão com a internet',
        type: GeminiErrorType.network,
      );
      
    } on DioException catch (e, stackTrace) {
      debugPrint('❌ Erro Dio: ${e.type}');
      debugPrint('Status: ${e.response?.statusCode}');
      debugPrint('Stack: $stackTrace');
      
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw GeminiException(
          'Tempo limite excedido. Tente novamente.',
          type: GeminiErrorType.timeout,
        );
      }
      
      if (e.response?.statusCode == 404) {
        throw GeminiException(
          'Modelo não encontrado',
          type: GeminiErrorType.notFound,
        );
      }
      
      if (e.response?.statusCode == 429) {
        throw GeminiException(
          'Muitas requisições. Aguarde um momento.',
          type: GeminiErrorType.rateLimitExceeded,
        );
      }
      
      if (e.response?.statusCode == 500 || e.response?.statusCode == 503) {
        throw GeminiException(
          'Serviço temporariamente indisponível',
          type: GeminiErrorType.serverError,
        );
      }
      
      throw GeminiException(
        'Erro de comunicação: ${e.message}',
        type: GeminiErrorType.network,
      );
      
    } on GeminiException {
      rethrow;
      
    } catch (e, stackTrace) {
      debugPrint('❌ Erro inesperado: $e');
      debugPrint('Stack: $stackTrace');
      throw GeminiException(
        'Erro inesperado. Tente novamente.',
        type: GeminiErrorType.unknown,
      );
    }
  }

  /// Test connection
  Future<bool> testConnection() async {
    try {
      final model = await _findWorkingModel();
      return model != null;
    } catch (e) {
      return false;
    }
  }

  /// Generate content from text-only prompt (no image)
  Future<Map<String, dynamic>> generateTextContent(String prompt) async {
    try {
      if (_apiKey.isEmpty) {
        throw GeminiException(
          'API Key não configurada. Verifique o arquivo .env',
          type: GeminiErrorType.configuration,
        );
      }

      debugPrint('🚀 Iniciando geração de texto...');

      // Find working model
      final workingModel = await _findWorkingModel();
      if (workingModel == null) {
        throw GeminiException(
          'Nenhum modelo Gemini disponível',
          type: GeminiErrorType.serviceUnavailable,
        );
      }

      debugPrint('🤖 Modelo: $workingModel');

      // Prepare request (text-only)
      final requestData = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ]
          }
        ],
         'generationConfig': {
           'temperature': 0.4,
           'maxOutputTokens': 2048,
         },
      };

      debugPrint('⏳ Enviando para Gemini...');
      final startTime = DateTime.now();

      // Make request with timeout
      final response = await _dio.post(
        '/v1beta/models/$workingModel:generateContent',
        queryParameters: {'key': _apiKey},
        data: requestData,
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Tempo limite excedido');
        },
      );

      final duration = DateTime.now().difference(startTime);
      debugPrint('⚡ Resposta em: ${duration.inMilliseconds}ms');

      // Validate response
      if (response.statusCode != 200) {
        throw GeminiException(
          'Erro HTTP: ${response.statusCode}',
          type: GeminiErrorType.serverError,
        );
      }

      final text = response.data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      
      if (text == null || text.isEmpty) {
        throw GeminiException(
          'Resposta vazia da IA',
          type: GeminiErrorType.emptyResponse,
        );
      }

      debugPrint('✅ Resposta recebida');

      // Parse JSON with error handling
      try {
        String jsonString = text;
        
        if (jsonString.contains('```json')) {
          jsonString = jsonString.split('```json').last.split('```').first.trim();
        } else if (jsonString.contains('```')) {
          jsonString = jsonString.split('```').last.split('```').first.trim();
        } else {
          jsonString = jsonString.trim();
        }


        final jsonResponse = jsonDecode(jsonString) as Map<String, dynamic>;

        if (jsonResponse.containsKey('error')) {
          throw GeminiException(
            'Erro da IA: ${jsonResponse['error']}',
            type: GeminiErrorType.aiError,
          );
        }

        debugPrint('✅ JSON parseado com sucesso');
        return jsonResponse;

      } on FormatException catch (e, stackTrace) {
        debugPrint('❌ Erro ao parsear JSON: $e');
        debugPrint('Stack: $stackTrace');
        throw GeminiException(
          'Formato de resposta inválido',
          type: GeminiErrorType.parseError,
        );
      }
      
    } on TimeoutException catch (e, stackTrace) {
      debugPrint('❌ Timeout: $e');
      debugPrint('Stack: $stackTrace');
      throw GeminiException(
        'A conexão demorou muito. Verifique sua internet.',
        type: GeminiErrorType.timeout,
      );
      
    } on SocketException catch (e, stackTrace) {
      debugPrint('❌ Erro de rede: $e');
      debugPrint('Stack: $stackTrace');
      throw GeminiException(
        'Sem conexão com a internet',
        type: GeminiErrorType.network,
      );
      
    } on DioException catch (e, stackTrace) {
      debugPrint('❌ Erro Dio: ${e.type}');
      debugPrint('Status: ${e.response?.statusCode}');
      debugPrint('Stack: $stackTrace');
      
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw GeminiException(
          'Tempo limite excedido. Tente novamente.',
          type: GeminiErrorType.timeout,
        );
      }
      
      if (e.response?.statusCode == 404) {
        throw GeminiException(
          'Modelo não encontrado',
          type: GeminiErrorType.notFound,
        );
      }
      
      if (e.response?.statusCode == 429) {
        throw GeminiException(
          'Muitas requisições. Aguarde um momento.',
          type: GeminiErrorType.rateLimitExceeded,
        );
      }
      
      if (e.response?.statusCode == 500 || e.response?.statusCode == 503) {
        throw GeminiException(
          'Serviço temporariamente indisponível',
          type: GeminiErrorType.serverError,
        );
      }
      
      throw GeminiException(
        'Erro de comunicação: ${e.message}',
        type: GeminiErrorType.network,
      );
      
    } on GeminiException {
      rethrow;
      
    } catch (e, stackTrace) {
      debugPrint('❌ Erro inesperado: $e');
      debugPrint('Stack: $stackTrace');
      throw GeminiException(
        'Erro inesperado. Tente novamente.',
        type: GeminiErrorType.unknown,
      );
    }
  }
  /// Generate a new weekly diet plan
  Future<Map<String, dynamic>> generateDietPlan({
    required String petName,
    required String raca,
    required String idade,
    required double peso,
    required String nivelAtividade,
    required List<String> alergias,
  }) async {
    if (_apiKey.isEmpty) throw Exception('API Key missing');

    final model = await _findWorkingModel() ?? 'gemini-1.5-flash';

    final prompt = """
    Atue como nutricionista veterinário. Crie um cardápio semanal VARIADO e saudável para:
    Pet: $petName
    Raça: $raca
    Idade: $idade
    Peso: $peso kg
    Nível de Atividade: $nivelAtividade
    Alergias/Restrições: ${alergias.isEmpty ? 'Nenhuma' : alergias.join(', ')}

    Retorne APENAS um JSON válido com este formato EXATO (respeite as chaves minúsculas sem acento):
    {
      "plano_semanal": [
        {"dia": "Segunda-feira", "manha": "Descrição detalhada...", "tarde": "...", "noite": "..."},
        {"dia": "Terça-feira", ...},
        ...até Domingo
      ],
      "orientacoes_gerais": "Resumo das recomendações."
    }
    Sem markdown, sem texto extra.
    """;

    try {
      final response = await _dio.post(
        '/v1beta/models/$model:generateContent',
        queryParameters: {'key': _apiKey},
        data: {
          "contents": [{"parts": [{"text": prompt}]}]
        },
      );

      final text = response.data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      if (text == null) throw Exception('Empty response');
      
      var jsonStr = text.toString();
      if (jsonStr.contains('```json')) {
        jsonStr = jsonStr.split('```json').last.split('```').first.trim();
      } else if (jsonStr.contains('```')) {
        jsonStr = jsonStr.split('```').last.split('```').first.trim();
      } else {
        jsonStr = jsonStr.trim();
      }
      
      return jsonDecode(jsonStr);
    } catch (e) {
      debugPrint('Error generating diet: $e');
      throw GeminiException('Erro ao gerar dieta: $e', type: GeminiErrorType.serverError);
    }
  }
  
  /// Generate plain text response (not JSON)
  Future<String> generatePlainText(String prompt) async {
    if (_apiKey.isEmpty) {
      throw GeminiException(
        'API Key não configurada. Verifique o arquivo .env',
        type: GeminiErrorType.configuration,
      );
    }

    try {
      debugPrint('🚀 Gerando texto com Gemini...');

      // Find working model
      final workingModel = await _findWorkingModel();
      if (workingModel == null) {
        throw GeminiException(
          'Nenhum modelo Gemini disponível',
          type: GeminiErrorType.serviceUnavailable,
        );
      }

      debugPrint('🤖 Modelo: $workingModel');

      // Make request
      final response = await _dio.post(
        '/v1beta/models/$workingModel:generateContent',
        queryParameters: {'key': _apiKey},
        data: {
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Tempo limite excedido');
        },
      );

      if (response.statusCode != 200) {
        throw GeminiException(
          'Erro HTTP: ${response.statusCode}',
          type: GeminiErrorType.serverError,
        );
      }

      final text = response.data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      
      if (text == null || text.isEmpty) {
        throw GeminiException(
          'Resposta vazia da IA',
          type: GeminiErrorType.emptyResponse,
        );
      }

      debugPrint('✅ Texto gerado com sucesso');
      return text.toString();

    } on TimeoutException catch (e) {
      debugPrint('❌ Timeout: $e');
      throw GeminiException(
        'A conexão demorou muito. Verifique sua internet.',
        type: GeminiErrorType.timeout,
      );
    } on DioException catch (e) {
      debugPrint('❌ Erro Dio: ${e.type}');
      
      if (e.response?.statusCode == 429) {
        throw GeminiException(
          'Muitas requisições. Aguarde um momento.',
          type: GeminiErrorType.rateLimitExceeded,
        );
      }
      
      throw GeminiException(
        'Erro de comunicação: ${e.message}',
        type: GeminiErrorType.network,
      );
    } catch (e) {
      debugPrint('❌ Erro inesperado: $e');
      throw GeminiException(
        'Erro inesperado. Tente novamente.',
        type: GeminiErrorType.unknown,
      );
    }
  }
}

/// Error types
enum GeminiErrorType {
  configuration,
  invalidImage,
  timeout,
  network,
  serverError,
  notFound,
  rateLimitExceeded,
  emptyResponse,
  parseError,
  aiError,
  serviceUnavailable,
  badRequest,
  unknown,
}

/// Custom exception with type
class GeminiException implements Exception {
  final String message;
  final GeminiErrorType type;

  GeminiException(this.message, {required this.type});

  String get userMessage {
    switch (type) {
      case GeminiErrorType.timeout:
        return 'errorAiTimeout'; // Localized key
      case GeminiErrorType.network:
        return 'Sem conexão com a internet. Verifique sua rede.';
      case GeminiErrorType.parseError:
      case GeminiErrorType.badRequest:
        return 'errorBadPhoto'; // Localized key
      case GeminiErrorType.serverError:
        return 'Serviço temporariamente indisponível. Tente mais tarde.';
      case GeminiErrorType.invalidImage:
        return message;
      case GeminiErrorType.rateLimitExceeded:
        return 'Muitas requisições. Aguarde um momento e tente novamente.';
      case GeminiErrorType.serviceUnavailable:
        return 'Serviço de IA indisponível no momento.';
      default:
        return message;
    }
  }

  @override
  String toString() => userMessage;
}
