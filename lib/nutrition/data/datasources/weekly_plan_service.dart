import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/weekly_plan.dart';
import '../../../../core/services/hive_atomic_manager.dart';

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
    _box = await HiveAtomicManager().ensureBoxOpen<WeeklyPlan>(_boxName, cipher: cipher);
    return _box!;
  }

  /// Inicializa o box
  Future<void> init({HiveCipher? cipher}) async {
    await _ensureBox(cipher: cipher);
  }

  /// Salva um plano
  Future<void> savePlan(WeeklyPlan plan) async {
    try {
      final box = await _ensureBox();
      
      // Gerar ID se não tiver
      plan.id ??= DateTime.now().millisecondsSinceEpoch.toString(); 
      plan.atualizadoEm = DateTime.now();
      
      // Regra de Versão: Se estivermos salvando um novo plano 'Ativo' para este período,
      // devemos arquivar os anteriores do mesmo período.
      if (plan.status == 'active') {
         final existing = getAllPlans().where((p) => 
            p.weekStartDate == plan.weekStartDate && 
            p.id != plan.id && 
            p.status == 'active'
         ).toList();
         
         for (var p in existing) {
            p.status = 'archived';
            await p.save(); // HiveObject.save() works if it was already in box
            // If not in box (which shouldn't happen here), we'd use box.put
         }
      }

      await box.put(plan.id, plan);
      debugPrint('[WeeklyMenu] SAVE id=${plan.id} start=${plan.weekStartDate} status=${plan.status}');
    } catch (e) {
      debugPrint('❌ Error saving plan: $e');
      rethrow;
    }
  }

  /// Soft Delete
  Future<void> softDeletePlan(String id) async {
    try {
      final box = await _ensureBox();
      final plan = box.get(id);
      if (plan != null) {
        plan.status = 'deleted';
        await box.put(id, plan);
        debugPrint('🗑️ Soft deleted plan: $id');
      }
    } catch (e) {
      debugPrint('❌ Error soft deleting plan: $e');
      rethrow;
    }
  }

  /// Get plan by ID
  WeeklyPlan? getPlanById(String id) {
    if (_box == null || !_box!.isOpen) return null;
    return _box!.get(id);
  }

  /// Retorna o plano da semana atual (Ativo)
  WeeklyPlan? getCurrentWeekPlan() {
    if (_box == null || !_box!.isOpen) {
       debugPrint('⚠️ [WeeklyPlanService] Sync access to closed box. Returning null.');
       return null; 
    }
    
    try {
      final now = DateTime.now();
      final monday = getMonday(now);
      
      final activePlans = getAllActivePlans();
      if (activePlans.isEmpty) return null;

      // Try exact match first
      try {
        return activePlans.firstWhere((p) => isSameDay(p.weekStartDate, monday));
      } catch (_) {
        // Try period overlap
        try {
          return activePlans.firstWhere((p) => 
            p.weekStartDate.isBefore(now.add(const Duration(seconds: 1))) && 
            (p.endDate?.isAfter(now.subtract(const Duration(seconds: 1))) ?? false)
          );
        } catch (_) {
          return null;
        }
      }
    } catch (e) {
      debugPrint('❌ Error getting current week plan: $e');
      return null;
    }
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Retorna o plano de uma semana específica (Ativo)
  WeeklyPlan? getPlanByDate(DateTime date) {
    if (_box == null || !_box!.isOpen) return null;
    try {
      final monday = getMonday(date);
      return getAllActivePlans().firstWhere(
        (p) => isSameDay(p.weekStartDate, monday),
      );
    } catch (e) {
      return null;
    }
  }

  /// Retorna todos os planos (exclui deletados)
  List<WeeklyPlan> getAllPlans() {
    if (_box == null || !_box!.isOpen) return [];
    try {
      final all = _box!.values.toList();
      final filtered = all.where((p) => p.status != 'deleted').toList();
      debugPrint('[WeeklyPlanService] getAllPlans: total=${all.length}, filtered=${filtered.length} (deleted=${all.length - filtered.length})');
      return filtered;
    } catch (e) {
      debugPrint('❌ Error getting all plans: $e');
      return [];
    }
  }

  /// Retorna apenas planos ativos
  List<WeeklyPlan> getAllActivePlans() {
    return getAllPlans().where((p) => p.status == 'active').toList();
  }

  /// Remove um plano (Fisicamente)
  Future<void> deletePlan(String id) async {
    try {
      final box = await _ensureBox();
      await box.delete(id);
      debugPrint('🗑️ Weekly plan deleted: $id');
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
  DateTime getMonday(DateTime date) {
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
