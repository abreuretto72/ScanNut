import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../enums/scannut_mode.dart';
import '../utils/prompt_factory.dart';

final geminiServiceProvider = Provider<GeminiService>((ref) => GeminiService());

class GeminiService {
  late final Dio _dio;
  static String? _cachedModel;
  final String _apiKey;
  final String _baseUrl = 'https://generativelanguage.googleapis.com';

  GeminiService() : _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '' {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout:
          const Duration(seconds: 90), // Increased for meal plan generation
      sendTimeout: const Duration(seconds: 30),
    ));
  }

  /// Find working model
  Future<String?> _findWorkingModel() async {
    if (_cachedModel != null) return _cachedModel;

    final modelsToTry = [
      'gemini-2.0-flash',
      'gemini-1.5-flash',
      'gemini-2.0-flash-exp',
      'gemini-1.5-pro',
    ];

    for (final model in modelsToTry) {
      try {
        debugPrint('🔍 Testando modelo: $model');
        final response = await _dio.post(
          '/v1/models/$model:generateContent',
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
  Future<Uint8List> _compressImage(
      File imageFile, Uint8List originalBytes) async {
    try {
      final sizeKB = originalBytes.length / 1024;

      debugPrint(
          '🗜️ Comprimindo imagem de ${sizeKB.toStringAsFixed(2)} KB...');

      // 🛡️ SEMPRE comprimir para 1024px para evitar erro 400
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        quality: 85,
        minWidth: 1024, // ← Reduzido de 1920 para 1024
        minHeight: 1024, // ← Reduzido de 1920 para 1024
        format: CompressFormat.jpeg,
      );

      if (compressedBytes == null) {
        debugPrint('⚠️ Falha na compressão, usando original');
        return originalBytes;
      }

      final newSizeKB = compressedBytes.length / 1024;
      final reduction =
          ((sizeKB - newSizeKB) / sizeKB * 100).toStringAsFixed(1);
      debugPrint(
          '✅ Comprimido para ${newSizeKB.toStringAsFixed(2)} KB ($reduction% redução)');

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
    Map<String, String>? contextData, // 🛡️ NEW: Context Injection
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
      String prompt = PromptFactory.getPrompt(mode,
          locale: locale, contextData: contextData);

      // Inject meal rotation restriction if applicable
      if (mode == ScannutMode.petIdentification && excludedBases.isNotEmpty) {
        final restriction =
            '\n\nRESTRIÇÃO DE ROTAÇÃO NUTRICIONAL: O pet já consumiu recentemente as seguintes bases alimentares: ${excludedBases.join(", ")}. Para o plano_semanal, priorize ingredientes DIFERENTES para garantir variedade nutricional.';
        prompt += restriction;
        debugPrint(
            '🔄 Rotação ativada: ${excludedBases.length} ingredientes excluídos');
      }

      // LOG 1: REQUEST PROMPT
      debugPrint(
          '\n================ [ LOG 1: REQUEST PROMPT ] ================\n');
      debugPrint(prompt);
      debugPrint(
          '\n===========================================================\n');

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
      final response = await _dio
          .post(
        '/v1/models/$workingModel:generateContent',
        queryParameters: {'key': _apiKey},
        data: requestData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept-Language': locale,
          },
        ),
      )
          .timeout(
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
            userMessage =
                'A foto não ficou clara o suficiente. Tente tirar outra com mais luz e foco!';
            errorType = GeminiErrorType.badRequest;
            break;
          case 401:
          case 403:
            userMessage =
                'Erro de autenticação. Verifique sua conexão e tente novamente.';
            errorType = GeminiErrorType.authError;
            break;
          case 404:
            userMessage =
                'Serviço temporariamente indisponível. Tente novamente em alguns instantes.';
            errorType = GeminiErrorType.serverError;
            break;
          case 429:
            userMessage =
                'Muitas requisições. Aguarde alguns segundos e tente novamente.';
            errorType = GeminiErrorType.rateLimitError;
            break;
          case 500:
          case 502:
          case 503:
            userMessage =
                'Servidor temporariamente indisponível. Tente novamente em alguns instantes.';
            errorType = GeminiErrorType.serverError;
            break;
          default:
            userMessage =
                'Não foi possível completar a análise. Verifique sua conexão e tente novamente.';
            errorType = GeminiErrorType.serverError;
        }

        throw GeminiException(userMessage, type: errorType);
      }

      final text =
          response.data['candidates']?[0]?['content']?['parts']?[0]?['text'];

      // LOG 2: RAW RESPONSE
      debugPrint(
          '\n================ [ LOG 2: RESPONSE RAW ] ================\n');
      debugPrint(text?.toString() ?? 'NULL RESPONSE');
      debugPrint(
          '\n===========================================================\n');

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
      final response = await _dio
          .post(
        '/v1beta/models/$workingModel:generateContent',
        queryParameters: {'key': _apiKey},
        data: requestData,
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      )
          .timeout(
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

      final text =
          response.data['candidates']?[0]?['content']?['parts']?[0]?['text'];

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
        '/v1/models/$model:generateContent',
        queryParameters: {'key': _apiKey},
        data: {
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        },
      );

      final text =
          response.data['candidates']?[0]?['content']?['parts']?[0]?['text'];
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
      throw GeminiException('Erro ao gerar dieta: $e',
          type: GeminiErrorType.serverError);
    }
  }

  /// Specialized generation for Pet Meal Plan (Phase 2 & 3)
  Future<Map<String, dynamic>> generatePetMealPlan(String prompt) async {
    if (_apiKey.isEmpty) {
      throw GeminiException('API Key missing',
          type: GeminiErrorType.configuration);
    }

    // Use dynamic model selection for improved reliability
    final workingModel = await _findWorkingModel() ?? 'gemini-1.5-flash';

    final requestData = {
      "contents": [
        {
          "role": "user",
          "parts": [
            {"text": prompt}
          ]
        }
      ],
      "generationConfig": {"temperature": 0.1, "maxOutputTokens": 8192}
    };

    String rawText = '';
    try {
      debugPrint('🚀 [Gemini] PetMenu Generation - Model: $workingModel');

      final response = await _dio
          .post(
            '/v1/models/$workingModel:generateContent',
            queryParameters: {'key': _apiKey},
            data: requestData,
            options: Options(
              headers: {'Content-Type': 'application/json'},
            ),
          )
          .timeout(const Duration(seconds: 90));

      final fetchedText =
          response.data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      if (fetchedText == null) {
        throw Exception('Empty response parts from Gemini');
      }
      rawText = fetchedText.toString();

      return _extractJson(rawText);
    } on DioException catch (e) {
      debugPrint('🚨 [Gemini] DIO ERROR: ${e.response?.data}');
      rethrow;
    } catch (e) {
      // Diagnostic Logging (Phase 1 of user request)
      if (rawText.isNotEmpty) {
        debugPrint('🚨 [Gemini] Diagnostics: raw length=${rawText.length}');
        final tail = rawText.length > 200
            ? rawText.substring(rawText.length - 200)
            : rawText;
        debugPrint(
            '🚨 [Gemini] Diagnostics: raw tail=${tail.replaceAll('\n', '\\n')}');
      }

      debugPrint('🚨 [Gemini] Parse Error, attempting repair: $e');

      // Phase 2: JSON Repair Retry
      try {
        const repairPrompt =
            "Você me enviou um JSON inválido ou incompleto. Por favor, corrija-o para que seja um JSON válido de acordo com o formato solicitado anteriormente. Retorne APENAS o JSON corrigido.";

        final repairResponse = await _dio.post(
          '/v1/models/$workingModel:generateContent',
          queryParameters: {'key': _apiKey},
          data: {
            "contents": [
              {
                "role": "user",
                "parts": [
                  {"text": prompt}
                ]
              },
              {
                "role": "model",
                "parts": [
                  {"text": "Aqui está o JSON inválido que gerei..."}
                ]
              },
              {
                "role": "user",
                "parts": [
                  {"text": repairPrompt}
                ]
              }
            ],
            "generationConfig": {
              "temperature": 0.0, // Stable retry
              "maxOutputTokens": 8192
            }
          },
        ).timeout(const Duration(seconds: 60));

        final repairText = repairResponse.data['candidates']?[0]?['content']
            ?['parts']?[0]?['text'];
        if (repairText != null) {
          return _extractJson(repairText.toString());
        }
      } catch (repairError) {
        debugPrint('🚨 [Gemini] Repair failed: $repairError');
      }

      rethrow;
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
      final response = await _dio
          .post(
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
      )
          .timeout(
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

      final text =
          response.data['candidates']?[0]?['content']?['parts']?[0]?['text'];

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

      // 2. Remove sentinel if present
      jsonString = jsonString.split('__END_JSON__').first;

      // 3. Remove markdown code blocks if still present
      jsonString =
          jsonString.replaceAll('```json', '').replaceAll('```', '').trim();

      // 4. 🛡️ Sanitization: Remove comments and trailing commas (Common AI Errors)
      // Remove single-line comments //...
      jsonString = jsonString.replaceAll(RegExp(r'\/\/.*'), '');
      // Remove multi-line comments /*...*/
      jsonString = jsonString.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
      // Remove trailing commas before closing braces/brackets
      jsonString = jsonString.replaceAll(RegExp(r',(?=\s*[\}\]])'), '');

      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint(
          '❌ Failed to extract/decode JSON. String sample: ${text.length > 200 ? text.substring(0, 200) : text}');
      throw const FormatException('Invalid JSON format');
    }
  }

  // --- SOUND ANALYSIS (Agente de Áudio) ---
  Future<Map<String, dynamic>> analyzeAudio(String path) async {
    if (_apiKey.isEmpty) {
      throw GeminiException(
        'API Key não configurada. Verifique o arquivo .env',
        type: GeminiErrorType.configuration,
      );
    }
    debugPrint('🎙️ [Gemini] Iniciando análise de áudio: $path');
    try {
      final file = File(path);
      if (!await file.exists()) {
        debugPrint('❌ [Gemini] Arquivo de áudio não encontrado: $path');
        throw Exception('Audio file not found');
      }

      final bytes = await file.readAsBytes();
      final base64Audio = base64Encode(bytes);
      debugPrint(
          '📊 [Gemini] Tamanho áudio: ${bytes.length} bytes (Base64: ${base64Audio.length})');

      // Use dynamic model selection
      final model = await _findWorkingModel() ?? 'gemini-1.5-flash';

      const prompt =
          "Analise este áudio de pet. Identifique o que o animal está tentando comunicar. "
          "NÃO use termos técnicos médicos ou biológicos. Explique de forma simples para o dono: "
          "1. O que ele está sentindo ('emotion_simple'); "
          "2. O motivo provável ('reason_simple'); "
          "3. O que fazer ('action_tip'). "
          "Retorne estritamente um JSON com estas chaves exatas.";

      String mimeType = 'audio/mp4'; // Default
      final ext = path.toLowerCase();
      if (ext.endsWith('.mp3')) {
        mimeType = 'audio/mpeg';
      } else if (ext.endsWith('.wav'))
        mimeType = 'audio/wav';
      else if (ext.endsWith('.aac'))
        mimeType = 'audio/aac';
      else if (ext.endsWith('.ogg'))
        mimeType = 'audio/ogg';
      else if (ext.endsWith('.m4a')) mimeType = 'audio/mp4';

      final requestData = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {
                'inline_data': {'mime_type': mimeType, 'data': base64Audio}
              }
            ]
          }
        ]
      };

      debugPrint(
          '⏳ [Gemini] Enviando áudio para API (modelo: $model, mime: $mimeType, path: $path)...');

      final response = await _dio
          .post(
            '/v1/models/$model:generateContent',
            queryParameters: {'key': _apiKey},
            data: requestData,
          )
          .timeout(const Duration(seconds: 45));

      debugPrint(
          '✅ [Gemini] Resposta recebida. Status: ${response.statusCode}');

      final text =
          response.data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      debugPrint('📄 [Gemini] Resposta bruta ÁUDIO: $text');

      if (text == null) {
        debugPrint('🚨 [Gemini] Resposta sem texto. Body: ${response.data}');
        throw Exception('Empty response from AI');
      }

      return _extractJson(text);
    } catch (e) {
      if (e is DioException) {
        debugPrint('🚨 [Gemini] DioError na análise de áudio:');
        debugPrint('   Status: ${e.response?.statusCode}');
        debugPrint('   Body: ${e.response?.data}');
        throw GeminiException(
            'Erro na API (${e.response?.statusCode}): ${e.response?.data?['error']?['message'] ?? e.message}',
            type: GeminiErrorType.serverError);
      }
      debugPrint('🚨 [Gemini] Audio Analysis Error: $e');
      throw GeminiException('Falha na análise de áudio: $e',
          type: GeminiErrorType.serverError);
    }
  }

  // --- PET BODY ANALYSIS (Saúde & Postura) ---
  Future<Map<String, dynamic>> analyzePetBody(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) throw Exception('Image file not found');

      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);
      final model = await _findWorkingModel() ?? 'gemini-1.5-flash';

      const prompt = """
Você é um especialista em comportamento e saúde animal. Analise esta imagem do pet usando marcadores biométricos e contextuais ESPECÍFICOS.

**1. MARCADORES DE LINGUAGEM CORPORAL (Sinais Primários):**
- **Orelhas:** Orientação (para frente = curiosidade/alerta, para trás = medo/submissão, achatadas = medo extremo/agressividade, em pé = atenção)
- **Olhos e Pupilas:** Dilatação pupilar (dilatadas = estresse/medo/excitação, contraídas = relaxamento), visibilidade do branco do olho ("olhar de baleia" = desconforto/alerta)
- **Focinho e Boca:** Tensão labial (lábios tensos = estresse, relaxados = calma), boca entreaberta (relaxamento), exibição de dentes (alerta/agressividade)
- **Cauda:** Posição (entre as pernas = medo/submissão, erguida = confiança/alerta, na linha do dorso = equilíbrio/neutralidade)

**2. POSTURA E TENSÃO MUSCULAR:**
- **Eixo de Gravidade:** Peso deslocado para trás (medo/fuga/insegurança) ou para frente (curiosidade/dominância/interesse)
- **Curvatura da Coluna:** Arqueada (possível dor/desconforto ou tentativa de parecer menor), reta (confiança/neutralidade)
- **Rigidez Corporal:** Músculos tensos (estresse/alerta) ou relaxados (conforto/segurança)
- **Piloreção:** Pelos arrepiados no dorso (alta excitação/defesa/medo)

**3. CONTEXTO AMBIENTAL (Análise de Cena):**
- **Interações:** Presença de outros animais, pessoas ou brinquedos e a reação do pet a esses estímulos
- **Território:** Pet em espaço aberto (confiança) ou acuado em canto (insegurança/medo)
- **Ambiente:** Local familiar ou desconhecido, presença de estímulos estressantes

**INSTRUÇÕES DE RESPOSTA:**
Use linguagem SIMPLES e CLARA para tutores leigos. Traduza os sinais técnicos em explicações compreensíveis.

Retorne ESTRITAMENTE um JSON válido com:
{
  "health_score": [número de 1 a 10, onde 10 = pet completamente relaxado e saudável, 1 = sinais graves de dor/estresse],
  "body_signals": "[descrição DETALHADA dos sinais observados, mencionando orelhas, olhos, cauda, postura, etc.]",
  "simple_advice": "[conselho PRÁTICO e ESPECÍFICO para o tutor, baseado nos sinais identificados]"
}

**IMPORTANTE:** Se a foto for parcial ou de baixa qualidade, use o padrão comportamental da raça para sugerir o estado provável, mas SEMPRE mencione a limitação da análise.
""";

      final requestData = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {
                'inline_data': {'mime_type': 'image/jpeg', 'data': base64Image}
              }
            ]
          }
        ]
      };

      final response = await _dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_apiKey',
        data: requestData,
      );

      final text =
          response.data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      if (text == null) throw Exception('Empty response from AI');

      return _extractJson(text);
    } catch (e) {
      debugPrint('🚨 [Gemini] Body Analysis Error: $e');
      throw GeminiException('Falha na análise corporal: $e',
          type: GeminiErrorType.serverError);
    }
  }

  /// --- PET FOOD ANALYSIS (Agente Nutricional) ---
  Future<Map<String, dynamic>> analyzePetFood(
    String path, {
    String? age,
    String? breedSpecies,
    String? weight,
  }) async {
    try {
      final file = File(path);
      if (!await file.exists()) throw Exception('Image file not found');

      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);
      final model = await _findWorkingModel() ?? 'gemini-1.5-flash';

      final petContext =
          "Idade: ${age ?? 'Não informada'}, Espécie/Raça: ${breedSpecies ?? 'Não informada'}, Peso: ${weight ?? 'Não informado'}";

      final prompt = """
Contexto: Você é o especialista em nutrição animal do ScanNut. Analise a imagem do rótulo da ração enviada e forneça uma resposta estritamente em formato JSON.
Parâmetros do Pet (Contexto do Usuário): $petContext.

Diretrizes de Análise:
1. Identificação Técnica: Extraia os níveis de proteína, gordura, fibras e a presença de conservantes (BHA/BHT) ou corantes artificiais.
2. Classificação de Qualidade: Classifique a ração atual em: Super Premium, Premium ou Standard.
3. Sugestão Inteligente: Se a ração atual possuir pontos críticos (ex: baixo nível de proteína para a idade), sugira 2 ou 3 marcas reconhecidas que melhor atendam ao perfil nutricional deste pet específico.
4. Isenção de Responsabilidade Obrigatória: Inclua um campo de aviso reforçando que o desenvolvedor não se responsabiliza pela perda de dados ou decisões alimentares, e que a consulta ao Veterinário é indispensável.

JSON Schema Invariável:
{
  "analise_rotulo": {
    "marca": "Nome Identificado",
    "qualidade": "Super Premium | Premium | Standard",
    "nutrientes": { "proteina": "X%", "gordura": "Y%", "fibras": "Z%" },
    "alertas": ["lista de ingredientes nocivos ou baixos"]
  },
  "sugestoes": [
    { "marca": "Marca Sugerida 1", "motivo": "Por que é boa para este pet" },
    { "marca": "Marca Sugerida 2", "motivo": "Por que é boa para este pet" }
  ],
  "feedback_visual": "saudavel | alerta | critico",
  "aviso_legal": "O ScanNut apresenta sugestões informativas que não substituem o parecer do Médico Veterinário. O desenvolvedor não se responsabiliza pelos dados ou pela perda deles."
}
""";

      final requestData = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {
                'inline_data': {'mime_type': 'image/jpeg', 'data': base64Image}
              }
            ]
          }
        ]
      };

      final response = await _dio.post(
        '/v1/models/$model:generateContent',
        queryParameters: {'key': _apiKey},
        data: requestData,
      );

      final text =
          response.data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      if (text == null) throw Exception('Empty response from AI');

      return _extractJson(text);
    } catch (e) {
      debugPrint('🚨 [Gemini] Food Analysis Error: $e');
      throw GeminiException('Falha na análise de ração: $e',
          type: GeminiErrorType.serverError);
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
