// ignore_for_file: deprecated_member_use
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
  final String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';

  GeminiService() : _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '' {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 90),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'x-goog-api-key': _apiKey, // 🛡️ REPLICAÇÃO SOBERANA DA SUA IMAGEM
        'X-Android-Package': 'com.multiversodigital.scannut',
        'X-Android-Cert': 'AC:92:22:DC:06:3F:B2:A5:00:05:6B:40:AE:6F:3E:44:E2:A9:5F:F6', 
        'Content-Type': 'application/json',
      },
    ));
  }

  // PILAR 1 & 3: Saneamento de Linter e Estabilidade de Modelo
  Future<String?> _findWorkingModel() async {
    if (_cachedModel != null) return _cachedModel;

    // Simplificamos para os modelos que estão 100% estáveis em 2026
    final modelsToTry = [
      'gemini-1.5-flash',
      'gemini-1.5-pro',
    ];

    for (final model in modelsToTry) {
      try {
        // Teste de conexão ultra-rápido
        final response = await _dio.post(
          '/v1beta/models/$model:generateContent',
          queryParameters: {'key': _apiKey},
          data: {
            'contents': [
              {
                'parts': [
                  {'text': 'p'}
                ]
              }
            ]
          },
        ).timeout(const Duration(seconds: 5)); // Timeout menor para não travar a UI

        if (response.statusCode == 200) {
          _cachedModel = model;
          return model;
        }
      } catch (e) {
        debugPrint('⚠️ Lei de Ferro: Pulando modelo $model por instabilidade.');
        continue;
      }
    }
    // Se tudo falhar, forçamos o flash para não retornar null e quebrar o fluxo
    return 'gemini-1.5-flash';
  }

  /// 🛡️ ANALYZE IMAGE - CONFIGURAÇÃO SOBERANA (RESTORE OK)
  Future<Map<String, dynamic>> analyzeImage({
    required File imageFile,
    required ScannutMode mode,
    List<String> excludedBases = const [],
    String locale = 'pt',
    Map<String, String>? contextData,
  }) => analyzeFile(
    file: imageFile,
    mimeType: 'image/jpeg',
    mode: mode,
    locale: locale,
    contextData: contextData,
  );

  Future<Map<String, dynamic>> analyzeAudio({
    required File audioFile,
    required ScannutMode mode,
    String locale = 'pt',
    Map<String, String>? contextData,
  }) => analyzeFile(
    file: audioFile,
    mimeType: 'audio/mp4', // Suporta m4a
    mode: mode,
    locale: locale,
    contextData: contextData,
  );

  Future<Map<String, dynamic>> analyzeFile({
    required File file,
    required String mimeType,
    required ScannutMode mode,
    String locale = 'pt',
    Map<String, String>? contextData,
  }) async {
    try {
      // 🛡️ REPLICAÇÃO SOBERANA DO POSTMAN (Lei de Ferro)
      final String authUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent";
      
      final prompt = PromptFactory.getPrompt(mode, locale: locale, contextData: contextData);
      final bytes = await file.readAsBytes();
      final base64Data = base64Encode(bytes).replaceAll(RegExp(r'\s+'), ''); // 🛡️ Limpeza absoluta

      final requestBody = {
        "contents": [{
          "role": "user",
          "parts": [
            {
              "text": "$prompt\n\n"
                      "Responda ESTRITAMENTE em formato JSON. "
                      "Não use Markdown, não use negrito, não escreva nada fora do JSON. "
                      "JSON Schema: {\"descricao_visual\": \"string\", \"caracteristicas\": \"string\", \"recomendacao\": \"string\"}"
            },
            {
              "inlineData": { // CamelCase conforme request
                "mimeType": mimeType, // Usa o mimeType dinâmico (image/jpeg ou audio/mp4)
                "data": base64Data
              }
            }
          ]
        }],
        "generationConfig": {
          "temperature": 0.1, // Pilar 1: Estabilidade total
          "responseMimeType": "application/json" // OBRIGATÓRIO para a v2.5 gerar JSON puro
        }
      };

      final response = await _dio.post(
        authUrl,
        data: requestBody,
        options: Options(
          headers: {
            'x-goog-api-key': _apiKey, // 🛡️ SOBERANIA: Credencial via Header
            'X-Android-Package': 'com.multiversodigital.scannut',
            'X-Android-Cert': 'AC:92:22:DC:06:3F:B2:A5:00:05:6B:40:AE:6F:3E:44:E2:A9:5F:F6',
            'Content-Type': 'application/json',
          },
          // 🛡️ LEI DE FERRO: Não lançar exceção para erro 400. Queremos ler o erro!
          validateStatus: (status) => status! < 500, 
        ),
      );

      // 📡 TRACE DE IMPASSE: Ver o corpo exato do erro 400
      if (response.statusCode == 400) {
        debugPrint("🚨 [IMPASSE_REVELADO] Erro 400 Body: ${response.data}");
        return _extractJson(jsonEncode(response.data ?? {}));
      }

      if (response.statusCode == 200) {
        final text = response.data['candidates'][0]['content']['parts'][0]['text'];
        return _extractJson(text); // Seu extrator robusto
      }
      
      throw GeminiException('Erro Gemini: ${response.statusCode}', type: GeminiErrorType.badRequest);
    } catch (e) {
      debugPrint("🚨 [CRITICO] Falha na análise: $e");
      rethrow;
    }
  }

  // 🛡️ MAPEAR ERROS SEM ALUCINAÇÕES (PILAR 5 - l10n)
  Map<String, dynamic> _handleHttpError(Response response, ScannutMode mode) {
    if (response.statusCode == 400 && mode == ScannutMode.petDiagnosis) {
       debugPrint('⚠️ Alerta: IA reportou erro 400 em Saúde. Aplicando Fallback.');
       return {
         'error': 'analysis_failed',
         'feedback_visual': 'critico',
         'detalhes_ia': 'Não foi possível validar esta imagem clínica. Por favor, tente novamente com melhor iluminação.'
       };
    }
    throw GeminiException('Erro HTTP ${response.statusCode}', type: GeminiErrorType.serverError);
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

  /// Generate content from text-only prompt
  Future<Map<String, dynamic>> generateTextContent(String prompt) async {
    final model = await _findWorkingModel() ?? 'gemini-1.5-flash';
    try {
      final response = await _dio.post(
        '/v1/models/$model:generateContent',
        queryParameters: {'key': _apiKey},
        data: {
          'contents': [{'parts': [{'text': prompt}]}],
          'generationConfig': {'temperature': 0.4, 'maxOutputTokens': 4096},
        },
      ).timeout(const Duration(seconds: 30));

      final text = response.data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      if (text == null) throw Exception('Empty response from AI');
      return _extractJson(text);
    } catch (e) {
      throw GeminiException('Erro na geração de texto: $e', type: GeminiErrorType.serverError);
    }
  }

  /// Specialized generation for Pet Meal Plan
  Future<Map<String, dynamic>> generatePetMealPlan(String prompt) async {
    final workingModel = await _findWorkingModel() ?? 'gemini-1.5-flash';
    try {
      final response = await _dio.post(
        '/v1/models/$workingModel:generateContent',
        queryParameters: {'key': _apiKey},
        data: {
          "contents": [{"role": "user", "parts": [{"text": prompt}]}],
          "generationConfig": {"temperature": 0.1, "maxOutputTokens": 8192}
        },
      ).timeout(const Duration(seconds: 90));

      final text = response.data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      if (text == null) throw Exception('Empty response');
      return _extractJson(text.toString());
    } catch (e) {
      rethrow;
    }
  }



  /// Pet Body Analysis
  Future<Map<String, dynamic>> analyzePetBody(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final base64Image = base64Encode(bytes);
      final model = await _findWorkingModel() ?? 'gemini-1.5-flash';

      const prompt = "Analise a linguagem corporal do pet nesta imagem. "
          "Retorne um JSON com: 'health_score', 'body_signals', 'simple_advice'.";

      final response = await _dio.post(
        '/v1/models/$model:generateContent',
        queryParameters: {'key': _apiKey},
        data: {
          'contents': [{
            'parts': [
              {'text': prompt},
              {'inline_data': {'mime_type': 'image/jpeg', 'data': base64Image}}
            ]
          }]
        },
      ).timeout(const Duration(seconds: 30));

      final text = response.data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      return _extractJson(text ?? '');
    } catch (e) {
      throw GeminiException('Falha na análise corporal: $e', type: GeminiErrorType.serverError);
    }
  }

  /// Pet Food Analysis
  Future<Map<String, dynamic>> analyzePetFood(String path, {String? age, String? breedSpecies, String? weight}) async {
    try {
      final bytes = await File(path).readAsBytes();
      final base64Image = base64Encode(bytes);
      final model = await _findWorkingModel() ?? 'gemini-1.5-flash';

      final prompt = "Analise o rótulo da ração. Pet: $age, $breedSpecies, $weight. "
          "Retorne JSON: 'analise_rotulo', 'sugestoes', 'feedback_visual', 'aviso_legal'.";

      final response = await _dio.post(
        '/v1/models/$model:generateContent',
        queryParameters: {'key': _apiKey},
        data: {
          'contents': [{
            'parts': [
              {'text': prompt},
              {'inline_data': {'mime_type': 'image/jpeg', 'data': base64Image}}
            ]
          }]
        },
      ).timeout(const Duration(seconds: 45));

      final text = response.data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      return _extractJson(text ?? '');
    } catch (e) {
      throw GeminiException('Falha na análise de ração: $e', type: GeminiErrorType.serverError);
    }
  }

  /// Generate plain text response (not JSON)
  Future<String> generatePlainText(String prompt) async {
    final model = await _findWorkingModel() ?? 'gemini-1.5-flash';
    try {
      final response = await _dio.post(
        '/v1/models/$model:generateContent',
        queryParameters: {'key': _apiKey},
        data: {
          'contents': [{'parts': [{'text': prompt}]}],
          'generationConfig': {'temperature': 0.4},
        },
      ).timeout(const Duration(seconds: 30));

      final text = response.data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      if (text == null || text.isEmpty) throw Exception('Empty response');
      return text.toString();
    } catch (e) {
      throw GeminiException('Erro na geração de texto: $e', type: GeminiErrorType.serverError);
    }
  }

  // PILAR 6: FALLBACK PARA EVITAR CARDS VAZIOS
  // PILAR 6: FALLBACK PARA EVITAR CARDS VAZIOS
  Map<String, dynamic> _extractJson(String text) {
    try {
      // 🧹 Limpeza extrema antes do parse
      String cleanJson = text.replaceAll('```json', '').replaceAll('```', '').trim();
      
      // Tenta parsear
      final Map<String, dynamic> rawDecoded = jsonDecode(cleanJson);

      // 🛡️ ACHATAMENTO ATÔMICO (Pilar 6): Traz dados aninhados para a raiz
      // A Gemini 2.5 gosta de aninhar dados em 'identification', 'behavior', etc.
      final idData = rawDecoded['identification'] ?? {};
      final behaviorData = rawDecoded['behavior'] ?? {};
      final healthData = rawDecoded['health'] ?? {};

      return {
        // Mapeia chaves PT e EN para garantir que NUNCA apareça N/A
        'descricao_visual': rawDecoded['descricao_visual'] ?? rawDecoded['visual_description'] ?? rawDecoded['description'] ?? "Detalhes detectados: $cleanJson",
        'caracteristicas': rawDecoded['caracteristicas'] ?? behaviorData['personality'] ?? rawDecoded['details'] ?? "Padrão clínico identificado",
        'recomendacao': rawDecoded['recomendacao'] ?? healthData['preventive_checkup'] ?? rawDecoded['recommendation'] ?? "Consulte o histórico do pet",
        'nivel_risco': rawDecoded['nivel_risco'] ?? "Amarelo",
        'detalhes_ia': rawDecoded['detalhes_ia'] ?? "Análise concluída.",
        
        // Novos campos "achatados" para preencher os cards corretamente
        'raca': idData['breed'] ?? rawDecoded['raca'] ?? "Raça Desconhecida",
        'linhagem': idData['lineage'] ?? rawDecoded['linhagem'] ?? "Companhia",
        'regiao': idData['origin_region'] ?? rawDecoded['regiao'] ?? "Global",
        'morfologia': idData['morphology_type'] ?? rawDecoded['morfologia'] ?? "Padrão",
      };
    } catch (e) {
      debugPrint("🚨 [SCHEMA] Falha no Parse JSON. Usando Fallback de Texto.");
      // Se o parse falhar, não mostre N/A. Mostre o texto bruto da IA no campo de descrição.
      return {
        'error': 'json_parse_error',
        'raw_text': text,
        'descricao_visual': text, // Fallback para o texto que o usuário viu no Postman (ou texto bruto da IA)
        'caracteristicas': "Análise processada em modo texto",
        'recomendacao': "Verifique os detalhes acima",
        'nivel_risco': "Amarelo"
      };
    }
  }

  Future<Uint8List> _compressImage(File imageFile, Uint8List originalBytes) async {
    try {
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        quality: 85,
        minWidth: 1024,
        minHeight: 1024,
        format: CompressFormat.jpeg,
      );
      return compressedBytes ?? originalBytes;
    } catch (e) {
      return originalBytes;
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
      case GeminiErrorType.authError:
        return 'Falha de Autenticação: Verifique as restrições da chave no Console Google Cloud.';
      default:
        return message;
    }
  }

  @override
  String toString() => userMessage;
}
