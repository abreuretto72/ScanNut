import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Configuração genérica de IA para qualquer domínio
class AiConfig {
  final String activeModel;
  final String apiEndpoint;
  final Map<String, dynamic> extras;

  AiConfig({
    required this.activeModel,
    required this.apiEndpoint,
    this.extras = const {},
  });

  factory AiConfig.fromJson(Map<String, dynamic> json) {
    return AiConfig(
      activeModel: json['active_model'] as String? ?? 'gemini-1.5-flash',
      apiEndpoint: json['api_endpoint'] as String? ?? 'https://generativelanguage.googleapis.com/v1beta/',
      extras: json,
    );
  }

  factory AiConfig.fallback() {
    return AiConfig(
      activeModel: 'gemini-1.5-flash',
      apiEndpoint: 'https://generativelanguage.googleapis.com/v1beta/',
    );
  }

  // Helpers de compatibilidade e leitura de extras
  bool get enforceOrangeTheme => extras['enforce_orange_theme'] as bool? ?? false;
}

/// Alias para manter compatibilidade com código existente de Food
typedef FoodConfig = AiConfig;

/// Serviço Centralizado de Configuração Remota (Soberania de Dados)
class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  final Dio _dio = Dio();
  static const String _baseUrl = 'https://multiversodigital.com.br/scannut/config';
  
  // Cache por domínio
  final Map<String, AiConfig> _cache = {};

  /// Busca configuração específica para Comida
  Future<AiConfig> getFoodConfig() async {
    return _fetchConfig('food_config.json', 'food');
  }

  /// Busca configuração específica para Pet
  Future<AiConfig> getPetConfig() async {
    return _fetchConfig('pet_config.json', 'pet');
  }

  /// Busca configuração específica para Plantas
  Future<AiConfig> getPlantConfig() async {
    return _fetchConfig('plant_config.json', 'plant');
  }

  Future<AiConfig> _fetchConfig(String fileName, String cacheKey) async {
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    try {
      final url = '$_baseUrl/$fileName';
      // Timeout agressivo para não bloquear a UI
      final response = await _dio.get(
        url,
        options: Options(
          receiveTimeout: const Duration(seconds: 4),
          sendTimeout: const Duration(seconds: 4),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final config = AiConfig.fromJson(response.data);
        _cache[cacheKey] = config;
        debugPrint('✅ [RemoteConfig] Loaded $cacheKey config: ${config.activeModel}');
        return config;
      }
    } catch (e) {
      debugPrint('⚠️ [RemoteConfig] Failed to fetch $fileName, using fallback: $e');
    }

    // Fallback Rígido (Lei de Ferro)
    final fallback = AiConfig.fallback();
    _cache[cacheKey] = fallback;
    return fallback;
  }
  
  /// Limpa o cache para forçar nova busca
  void invalidateCache() {
    _cache.clear();
  }
}
