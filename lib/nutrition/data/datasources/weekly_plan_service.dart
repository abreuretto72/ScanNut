import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import '../models/weekly_plan.dart';

/// Serviço para gerenciar planos semanais
/// Box: nutrition_weekly_plans
/// SINGLETON - sempre retorna a mesma instância
class WeeklyPlanService {
  static const String _boxName = 'nutrition_weekly_plans';
  
  // SINGLETON PATTERN
  static final WeeklyPlanService _instance = WeeklyPlanService._internal();
  factory WeeklyPlanService() => _instance;
  WeeklyPlanService._internal();
  
  Box<WeeklyPlan>? _box;

  /// Inicializa o box
  Future<void> init() async {
    try {
      if (_box?.isOpen == true) {
        debugPrint('✅ WeeklyPlanService already initialized');
        return;
      }
      _box = await Hive.openBox<WeeklyPlan>(_boxName);
      debugPrint('✅ WeeklyPlanService initialized. Box Open: ${_box?.isOpen}');
    } catch (e) {
      debugPrint('❌ Error initializing WeeklyPlanService: $e');
      rethrow;
    }
  }

  /// Salva um plano semanal
  Future<void> savePlan(WeeklyPlan plan) async {
    try {
      final key = _getWeekKey(plan.weekStartDate);
      plan.atualizadoEm = DateTime.now();
      
      debugPrint('[WeeklyMenu] SAVE key=$key days=${plan.days.length}');
      await _box?.put(key, plan);
      
      // READBACK para validar
      final saved = _box?.get(key);
      debugPrint('[WeeklyMenu] READBACK savedNull=${saved == null} days=${saved?.days.length}');
      
      if (saved == null) {
        throw Exception('Hive readback failed for key: $key');
      }
    } catch (e) {
      debugPrint('❌ Error saving weekly plan: $e');
      rethrow;
    }
  }

  /// Retorna o plano da semana atual
  WeeklyPlan? getCurrentWeekPlan() {
    try {
      final now = DateTime.now();
      final monday = _getMonday(now);
      final key = _getWeekKey(monday);
      final menu = _box?.get(key);
      debugPrint('[WeeklyMenu] LOAD key=$key menuNull=${menu == null} days=${menu?.days.length}');
      return menu;
    } catch (e) {
      debugPrint('❌ Error getting current week plan: $e');
      return null;
    }
  }

  /// Retorna o plano de uma semana específica
  WeeklyPlan? getPlanByDate(DateTime date) {
    try {
      final monday = _getMonday(date);
      final key = _getWeekKey(monday);
      return _box?.get(key);
    } catch (e) {
      debugPrint('❌ Error getting plan by date: $e');
      return null;
    }
  }

  /// Retorna todos os planos
  List<WeeklyPlan> getAllPlans() {
    try {
      return _box?.values.toList() ?? [];
    } catch (e) {
      debugPrint('❌ Error getting all plans: $e');
      return [];
    }
  }

  /// Remove um plano
  Future<void> deletePlan(DateTime weekStartDate) async {
    try {
      final key = _getWeekKey(weekStartDate);
      await _box?.delete(key);
      debugPrint('🗑️ Weekly plan deleted for week: $key');
    } catch (e) {
      debugPrint('❌ Error deleting weekly plan: $e');
      rethrow;
    }
  }

  /// Limpa todos os planos
  Future<void> clearAll() async {
    try {
      await _box?.clear();
      debugPrint('🧹 WeeklyPlanService cleared');
    } catch (e) {
      debugPrint('❌ Error clearing WeeklyPlanService: $e');
      rethrow;
    }
  }

  /// Retorna a segunda-feira da semana às 00:00 (NORMALIZADO)
  DateTime _getMonday(DateTime date) {
    final weekday = date.weekday; // 1 = Monday, 7 = Sunday
    final monday = date.subtract(Duration(days: weekday - 1));
    // NORMALIZAR para 00:00:00
    return DateTime(monday.year, monday.month, monday.day);
  }

  /// Gera chave única para a semana (formato: YYYY-MM-DD)
  String _getWeekKey(DateTime monday) {
    return '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
  }

  /// Fecha o box
  Future<void> close() async {
    try {
      await _box?.close();
      debugPrint('📦 WeeklyPlanService closed');
    } catch (e) {
      debugPrint('❌ Error closing WeeklyPlanService: $e');
    }
  }
}
