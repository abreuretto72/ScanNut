import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/food_config_model.dart';
import 'food_logger.dart';

class FoodRemoteConfigRepository {
  static const String _configUrl = 'https://multiversodigital.com.br/scannut/config/food_config.json';
  static const String _boxName = 'food_config_box';

  /// Fetches the remote config from Multiverso Digital server
  Future<FoodConfigModel> fetchRemoteConfig() async {
    FoodLogger().logInfo('fetching_remote_config', data: {'url': _configUrl});
    
    try {
      final response = await http.get(Uri.parse(_configUrl)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final config = FoodConfigModel.fromJson(data);
        
        // Data Guarantee: Save to Hive for offline use or fallback
        final box = await _ensureBox();
        await box.put('current_config', data);
        
        FoodLogger().logInfo('food_ai_endpoint_synced_with_multiverso_digital', data: {'model': config.activeModel, 'endpoint': config.apiEndpoint});
        return config;
      } else {
        FoodLogger().logError('remote_config_http_error', error: 'Status: ${response.statusCode}');
        return await _loadLocalConfig();
      }
    } catch (e) {
      FoodLogger().logError('remote_config_exception', error: e.toString());
      return await _loadLocalConfig();
    }
  }

  Future<FoodConfigModel> _loadLocalConfig() async {
    try {
      final box = await _ensureBox();
      final cachedData = box.get('current_config');

      if (cachedData != null) {
        FoodLogger().logInfo('using_cached_config');
        return FoodConfigModel.fromJson(Map<String, dynamic>.from(cachedData));
      }
    } catch (e) {
      FoodLogger().logCritical('hive_config_box_corrupted', error: e);
      // Immediate Reconstruction
      await Hive.deleteBoxFromDisk(_boxName);
    }
    
    FoodLogger().logInfo('using_default_config_fallback');
    return FoodConfigModel.defaultConfig(); 
  }

  Future<Box> _ensureBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }
}
