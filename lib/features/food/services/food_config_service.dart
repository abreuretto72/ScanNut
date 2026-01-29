import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/food_config_model.dart';
import 'food_logger.dart';

/// 🛡️ FOOD CONFIG SERVICE (V135) - Isolamento de IA com Persistência
class FoodConfigService {
  static final FoodConfigService _instance = FoodConfigService._internal();
  factory FoodConfigService() => _instance;
  FoodConfigService._internal();

  final Dio _dio = Dio();
  static const String _configUrl = 'https://multiversodigital.com.br/scannut/config/food_config.json';
  static const String _boxName = 'food_config_box';
  
  FoodConfigModel? _cachedConfig;

  /// Busca a configuração ativa (Remoto -> Local -> Default)
  Future<FoodConfigModel> getFoodConfig() async {
    if (_cachedConfig != null) return _cachedConfig!;

    // 1. Tenta buscar remoto
    try {
      final response = await _dio.get(
        _configUrl,
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final dynamic data = response.data;
        final json = data is String ? jsonDecode(data) : data;
        final config = FoodConfigModel.fromJson(json);
        
        // Salva no Hive para uso offline
        final box = await _ensureBox();
        await box.put('current_config', json);
        
        _cachedConfig = config;
        return config;
      }
    } catch (e) {
      FoodLogger().logError('food_config_remote_fail', error: e.toString());
    }

    // 2. Fallback para Local (Hive)
    try {
      final box = await _ensureBox();
      final cachedData = box.get('current_config');
      if (cachedData != null) {
        _cachedConfig = FoodConfigModel.fromJson(Map<String, dynamic>.from(cachedData));
        return _cachedConfig!;
      }
    } catch (e) {
      FoodLogger().logError('food_config_local_fail', error: e.toString());
    }

    // 3. Fallback Rígido (Lei de Ferro)
    return FoodConfigModel.defaultConfig();
  }

  Future<Box> _ensureBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  void invalidateCache() => _cachedConfig = null;
}
