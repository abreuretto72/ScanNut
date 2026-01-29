import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/menu_creation_params.dart';
import 'package:scannut/core/services/hive_atomic_manager.dart';

/// Serviço para persistir a última configuração do filtro de cardápio
class MenuFilterService {
  static const String _boxName = 'menu_filter_settings';
  static const String _lastKey = 'last_menu_filter_config';

  static final MenuFilterService _instance = MenuFilterService._internal();
  factory MenuFilterService() => _instance;
  MenuFilterService._internal();

  Box? _box;

  Future<void> init({HiveCipher? cipher}) async {
    _box = await HiveAtomicManager().ensureBoxOpen(_boxName, cipher: cipher);
  }

  /// Salva a configuração atual
  Future<void> saveLastConfig(MenuCreationParams params,
      {String? selectedPeriodId}) async {
    if (_box == null) await init();

    final data = {
      'mealsPerDay': params.mealsPerDay,
      'style': params.style,
      'restrictions': params.restrictions,
      'allowRepetition': params.allowRepetition,
      'periodType': params.periodType,
      'objective': params.objective,
      'customDays': params.customDays,
      'selectedPeriodId': selectedPeriodId, // Persist the UI choice ID
    };

    await _box!.put(_lastKey, jsonEncode(data));
  }

  /// Recupera a última configuração salva
  Map<String, dynamic>? getLastConfig() {
    if (_box == null || !_box!.isOpen) return null;
    final String? json = _box!.get(_lastKey);
    if (json == null) return null;
    try {
      return jsonDecode(json);
    } catch (e) {
      return null;
    }
  }
}
