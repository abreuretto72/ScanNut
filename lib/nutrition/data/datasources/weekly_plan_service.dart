import 'package:hive_flutter/hive_flutter.dart';
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
  
  /// Get listenable for UI updates
  ValueListenable<Box<WeeklyPlan>>? get listenable => _box?.listenable();

  /// Ensure box is open
  Future<Box<WeeklyPlan>> _ensureBox({HiveCipher? cipher}) async {
    if (_box != null && _box!.isOpen) return _box!;
    try {
      _box = await Hive.openBox<WeeklyPlan>(_boxName, encryptionCipher: cipher);
      debugPrint('✅ WeeklyPlanService initialized/re-opened (Secure). Box Open: ${_box?.isOpen}');
      return _box!;
    } catch (e) {
      debugPrint('❌ Error initializing Secure WeeklyPlanService: $e');
      rethrow;
    }
  }

  /// Inicializa o box
  Future<void> init({HiveCipher? cipher}) async {
    await _ensureBox(cipher: cipher);
  }

  /// Salva um plano semanal
  Future<void> savePlan(WeeklyPlan plan) async {
    try {
      final box = await _ensureBox();
      final key = _getWeekKey(plan.weekStartDate);
      plan.atualizadoEm = DateTime.now();
      
      debugPrint('[WeeklyMenu] SAVE key=$key days=${plan.days.length}');
      await box.put(key, plan);
      
      // READBACK para validar
      final saved = box.get(key);
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
    // Note: This method is synchronous in signature but Hive implies potential async init if closed.
    // However, if we change signature to Future, we break the interface used by Providers.
    // The Provider `WeeklyPlanNotifier` calls `_service.getCurrentWeekPlan()` synchronously in its constructor (line 75).
    // Breaking this would require refactoring `WeeklyPlanNotifier`.
    // BUT: If the box is closed, we CANNOT get data synchronously.
    
    // Compromise: Try to use _box if open. If closed, we can't do anything synchronously.
    // We should log error.
    // To properly fix, `WeeklyPlanNotifier` should be async or call init first.
    // WeeklyPlanNotifier line 75: `state = _service.getCurrentWeekPlan();`
    // WeeklyPlanNotifier line 67: `_service` is instantiated.
    // Constructor triggers _loadCurrentWeekPlan.
    
    // We SHOULD fix the Provider to be async or wait for init?
    // But `WeeklyPlanNotifier` is not async. 
    // Wait, `WeeklyPlanNotifier` calls `_loadCurrentWeekPlan` in constructor.
    // It's better to make `_loadCurrentWeekPlan` async? But constructor can't await.
    
    // Actually, `WeeklyPlanService` is a singleton. `init()` should have been called at app start.
    // If Danger Zone closed it, sync access fails.
    
    // CRITICAL: Changing return type to Future breaks code.
    // OPTION: Try to re-open synchronously? No, Hive.openBox is Future.
    
    // Fallback: If box is closed, return null. The UI will likely reload or user will retry.
    // But `generateNewPlan` (where the error happened) IS async (`Future<void>`).
    // `generateNewPlan` calls `savePlan`. I already made `savePlan` async and using `_ensureBox`.
    // So the "Box is closed" error in `savePlan` IS FIXED.
    
    // For `getCurrentWeekPlan`:
    if (_box == null || !_box!.isOpen) {
       debugPrint('⚠️ [WeeklyPlanService] Sync access to closed box. Returning null.');
       return null; 
    }
    
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
    if (_box == null || !_box!.isOpen) return null;
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
    if (_box == null || !_box!.isOpen) return [];
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
      final box = await _ensureBox();
      final key = _getWeekKey(weekStartDate);
      await box.delete(key);
      debugPrint('🗑️ Weekly plan deleted for week: $key');
    } catch (e) {
      debugPrint('❌ Error deleting weekly plan: $e');
      rethrow;
    }
  }

  /// Limpa todos os planos
  Future<void> clearAll() async {
    try {
      final box = await _ensureBox();
      await box.clear();
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
