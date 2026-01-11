import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import '../models/meal_log.dart';

/// Serviço para gerenciar logs de refeições
/// Box: nutrition_meal_logs
class MealLogService {
  static const String _boxName = 'nutrition_meal_logs';
  
  Box<MealLog>? _box;

  /// Inicializa o box
  Future<void> init({HiveCipher? cipher}) async {
    final isOpen = Hive.isBoxOpen(_boxName);
    debugPrint('🔍 [V61-TRACE] MealLogService checking box "$_boxName": open=$isOpen');

    if (isOpen) {
      try {
        _box = Hive.box<MealLog>(_boxName);
        debugPrint('✅ [V61-TRACE] MealLog box already open with correct type.');
      } catch (e) {
        debugPrint('⚠️ [V61-TRACE] Type mismatch in MealLog box. Closing dynamic instance...');
        await Hive.box(_boxName).close();
      }
    }

    if (_box == null || !_box!.isOpen) {
      try {
        debugPrint('📂 [V61-TRACE] Opening MealLog box tipada...');
        _box = await Hive.openBox<MealLog>(_boxName, encryptionCipher: cipher);
        debugPrint('✅ [V61-TRACE] MealLogService initialized (Secure). Box Open: ${_box?.isOpen}');
      } catch (e) {
        debugPrint('❌ [V61-TRACE] FATAL: Error initializing Secure MealLogService: $e');
        rethrow;
      }
    }
  }

  /// Adiciona um log de refeição
  Future<void> addLog(MealLog log) async {
    try {
      await _box?.add(log);
      debugPrint('✅ Meal log added: ${log.tipo} - ${log.origem}');
    } catch (e) {
      debugPrint('❌ Error adding meal log: $e');
      rethrow;
    }
  }

  /// Retorna logs de um dia específico
  List<MealLog> getLogsByDate(DateTime date) {
    try {
      return _box?.values.where((log) {
        return log.dateTime.year == date.year &&
               log.dateTime.month == date.month &&
               log.dateTime.day == date.day;
      }).toList() ?? [];
    } catch (e) {
      debugPrint('❌ Error getting logs by date: $e');
      return [];
    }
  }

  /// Retorna logs de hoje
  List<MealLog> getTodayLogs() {
    return getLogsByDate(DateTime.now());
  }

  /// Retorna logs de um período
  List<MealLog> getLogsByPeriod(DateTime start, DateTime end) {
    try {
      return _box?.values.where((log) {
        return log.dateTime.isAfter(start.subtract(const Duration(days: 1))) &&
               log.dateTime.isBefore(end.add(const Duration(days: 1)));
      }).toList() ?? [];
    } catch (e) {
      debugPrint('❌ Error getting logs by period: $e');
      return [];
    }
  }

  /// Retorna logs da última semana
  List<MealLog> getLastWeekLogs() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return getLogsByPeriod(weekAgo, now);
  }

  /// Retorna todos os logs
  List<MealLog> getAllLogs() {
    try {
      return _box?.values.toList() ?? [];
    } catch (e) {
      debugPrint('❌ Error getting all logs: $e');
      return [];
    }
  }

  /// Remove um log
  Future<void> deleteLog(int index) async {
    try {
      await _box?.deleteAt(index);
      debugPrint('🗑️ Meal log deleted at index: $index');
    } catch (e) {
      debugPrint('❌ Error deleting meal log: $e');
      rethrow;
    }
  }

  /// Calcula aderência ao plano (%)
  double calculateAdherence(DateTime start, DateTime end) {
    try {
      final logs = getLogsByPeriod(start, end);
      if (logs.isEmpty) return 0.0;
      
      final adherentLogs = logs.where((log) => log.aderenteAoPlano).length;
      return (adherentLogs / logs.length) * 100;
    } catch (e) {
      debugPrint('❌ Error calculating adherence: $e');
      return 0.0;
    }
  }

  /// Calcula aderência da última semana
  double getWeeklyAdherence() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return calculateAdherence(weekAgo, now);
  }

  /// Limpa todos os logs
  Future<void> clearAll() async {
    try {
      await _box?.clear();
      debugPrint('🧹 MealLogService cleared');
    } catch (e) {
      debugPrint('❌ Error clearing MealLogService: $e');
      rethrow;
    }
  }

  /// Fecha o box
  Future<void> close() async {
    try {
      await _box?.close();
      debugPrint('📦 MealLogService closed');
    } catch (e) {
      debugPrint('❌ Error closing MealLogService: $e');
    }
  }
}
