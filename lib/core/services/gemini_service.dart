import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../enums/scannut_mode.dart';
import '../utils/prompt_factory.dart';

class GeminiService {
  late final Dio _dio;
  static String? _cachedModel;
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
    if (_cachedModel != null) return _cachedModel;

    final modelsToTry = [
      'gemini-1.5-flash',
      'gemini-2.0-flash-exp',
      'gemini-1.5-pro',
    ];

    for (final model in modelsToTry) {
      try {
        debugPrint('🔍 Testando modelo: $model');
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
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          debugPrint('✅ Modelo selecionado e cacheado: $model');
          _cachedModel = model;
          return model;
        }
      } catch (e) {
        debugPrint('⚠️ Modelo $model indisponível: $e');
        continue;
      }
    }

    return null;
  }

  /// 🛡️ Compress image ALWAYS to prevent 400 errors
  Future<Uint8List> _compressImage(File imageFile, Uint8List originalBytes) async {
    try {
      final sizeKB = originalBytes.length / 1024;
      
      debugPrint('🗜️ Comprimindo imagem de ${sizeKB.toStringAsFixed(2)} KB...');
      
      // 🛡️ SEMPRE comprimir para 1024px para evitar erro 400
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        quality: 85,
        minWidth: 1024,  // ← Reduzido de 1920 para 1024
        minHeight: 1024, // ← Reduzido de 1920 para 1024
        format: CompressFormat.jpeg,
      );

      if (compressedBytes == null) {
        debugPrint('⚠️ Falha na compressão, usando original');
        return originalBytes;
      }

      final newSizeKB = compressedBytes.length / 1024;
      final reduction = ((sizeKB - newSizeKB) / sizeKB * 100).toStringAsFixed(1);
      debugPrint('✅ Comprimido para ${newSizeKB.toStringAsFixed(2)} KB (${reduction}% redução)');
      
      return compressedBytes;
    } catch (e) {
      debugPrint('⚠️ Erro na compressão: $e. Usando imagem original.');
      return originalBytes;
    }
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
      var imageBytes = await imageFile.readAsBytes();
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

      debugPrint('📦 Imagem original: ${sizeKB.toStringAsFixed(2)} KB');

      // Compress image if larger than 1MB
      imageBytes = await _compressImage(imageFile, imageBytes);

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

      // 🛡️ BLINDAGEM TOTAL - Nunca expor códigos técnicos
      if (response.statusCode != 200) {
        debugPrint('❌ HTTP Error: ${response.statusCode}');
        
        // Mapear TODOS os códigos para mensagens amigáveis
        String userMessage;
        GeminiErrorType errorType;
        
        switch (response.statusCode) {
          case 400:
            userMessage = 'A foto não ficou clara o suficiente. Tente tirar outra com mais luz e foco!';
            errorType = GeminiErrorType.badRequest;
            break;
          case 401:
          case 403:
            userMessage = 'Erro de autenticação. Verifique sua conexão e tente novamente.';
            errorType = GeminiErrorType.authError;
            break;
          case 404:
            userMessage = 'Serviço temporariamente indisponível. Tente novamente em alguns instantes.';
            errorType = GeminiErrorType.serverError;
            break;
          case 429:
            userMessage = 'Muitas requisições. Aguarde alguns segundos e tente novamente.';
            errorType = GeminiErrorType.rateLimitError;
            break;
          case 500:
          case 502:
          case 503:
            userMessage = 'Servidor temporariamente indisponível. Tente novamente em alguns instantes.';
            errorType = GeminiErrorType.serverError;
            break;
          default:
            userMessage = 'Não foi possível completar a análise. Verifique sua conexão e tente novamente.';
            errorType = GeminiErrorType.serverError;
        }
        
        throw GeminiException(userMessage, type: errorType);
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
        final jsonResponse = _extractJson(text);

        if (jsonResponse.containsKey('error')) {
          debugPrint('⚠️ domain error: ${jsonResponse['error']}');
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
          'Serviço temporariamente indisponível. Tente novamente em alguns instantes.',
          type: GeminiErrorType.serverError,
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
           'maxOutputTokens': 4096, // Increased for longer menus
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
        final jsonResponse = _extractJson(text);

        if (jsonResponse.containsKey('error')) {
          debugPrint('⚠️ domain error: ${jsonResponse['error']}');
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
          'Serviço temporariamente indisponível. Tente novamente em alguns instantes.',
          type: GeminiErrorType.serverError,
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

  /// 📐 Robust JSON Extraction Helper
  Map<String, dynamic> _extractJson(String text) {
    try {
      String jsonString = text;
      
      // 1. Try to find content between first { and last }
      if (jsonString.contains('{')) {
        final firstBrace = jsonString.indexOf('{');
        final lastBrace = jsonString.lastIndexOf('}');
        if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
          jsonString = jsonString.substring(firstBrace, lastBrace + 1);
        }
      }
      
      // 2. Remove markdown code blocks if still present
      jsonString = jsonString
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ Failed to extract/decode JSON: $e');
      throw const FormatException('Invalid JSON format');
    }
  }
}

/// Error types
enum GeminiErrorType {
  configuration,
  invalidImage,
  timeout,
  network,
  emptyResponse,
  parseError,
  serverError,
  rateLimitExceeded,
  rateLimitError, // Alias para rateLimitExceeded
  authError, // Erro de autenticação
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
        return 'Erro ao processar resposta da IA. Tente novamente.';
      case GeminiErrorType.badRequest:
        return 'errorBadPhoto'; // Localized key for image issues
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
