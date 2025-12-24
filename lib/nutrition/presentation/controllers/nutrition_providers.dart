import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_nutrition_profile.dart';
import '../../data/models/weekly_plan.dart';
import '../../data/models/meal_log.dart';
import '../../data/models/shopping_list_item.dart';
import '../../data/datasources/nutrition_profile_service.dart';
import '../../data/datasources/weekly_plan_service.dart';
import '../../data/datasources/meal_log_service.dart';
import '../../data/datasources/shopping_list_service.dart';
import '../../data/datasources/nutrition_data_service.dart';
import '../../domain/usecases/weekly_plan_generator.dart';
import '../../domain/usecases/shopping_list_generator.dart';

/// Provider para o perfil nutricional
final nutritionProfileProvider = StateNotifierProvider<NutritionProfileNotifier, UserNutritionProfile?>((ref) {
  return NutritionProfileNotifier();
});

class NutritionProfileNotifier extends StateNotifier<UserNutritionProfile?> {
  final NutritionProfileService _service = NutritionProfileService();

  NutritionProfileNotifier() : super(null) {
    _loadProfile();
  }

  void _loadProfile() {
    state = _service.getProfile();
  }

  Future<void> updateProfile(UserNutritionProfile profile) async {
    await _service.saveProfile(profile);
    state = profile;
  }

  Future<void> updateObjetivo(String objetivo) async {
    await _service.updateObjetivo(objetivo);
    _loadProfile();
  }

  Future<void> addRestricao(String restricao) async {
    await _service.addRestricao(restricao);
    _loadProfile();
  }

  Future<void> removeRestricao(String restricao) async {
    await _service.removeRestricao(restricao);
    _loadProfile();
  }
}

/// Provider para o plano semanal atual
final currentWeekPlanProvider = StateNotifierProvider<WeeklyPlanNotifier, WeeklyPlan?>((ref) {
  return WeeklyPlanNotifier();
});

class WeeklyPlanNotifier extends StateNotifier<WeeklyPlan?> {
  final WeeklyPlanService _service = WeeklyPlanService();
  final WeeklyPlanGenerator _generator = WeeklyPlanGenerator();

  WeeklyPlanNotifier() : super(null) {
    _loadCurrentWeekPlan();
  }

  void _loadCurrentWeekPlan() {
    state = _service.getCurrentWeekPlan();
  }

  Future<void> generateNewPlan(UserNutritionProfile profile) async {
    final plan = await _generator.generateWeeklyPlan(profile: profile);
    if (plan != null) {
      await _service.savePlan(plan);
      state = plan;
    }
  }

  Future<void> regeneratePlan(UserNutritionProfile profile) async {
    final newSeed = DateTime.now().millisecondsSinceEpoch;
    final plan = await _generator.generateWeeklyPlan(profile: profile, seed: newSeed);
    if (plan != null) {
      await _service.savePlan(plan);
      state = plan;
    }
  }

  void refresh() {
    _loadCurrentWeekPlan();
  }
}

/// Provider para logs de refeições
final mealLogsProvider = StateNotifierProvider<MealLogsNotifier, List<MealLog>>((ref) {
  return MealLogsNotifier();
});

class MealLogsNotifier extends StateNotifier<List<MealLog>> {
  final MealLogService _service = MealLogService();

  MealLogsNotifier() : super([]) {
    _loadTodayLogs();
  }

  void _loadTodayLogs() {
    state = _service.getTodayLogs();
  }

  Future<void> addLog(MealLog log) async {
    await _service.addLog(log);
    _loadTodayLogs();
  }

  Future<void> deleteLog(int index) async {
    await _service.deleteLog(index);
    _loadTodayLogs();
  }

  void loadLogsForDate(DateTime date) {
    state = _service.getLogsByDate(date);
  }

  void refresh() {
    _loadTodayLogs();
  }
}

/// Provider para lista de compras
final shoppingListProvider = StateNotifierProvider<ShoppingListNotifier, List<ShoppingListItem>>((ref) {
  return ShoppingListNotifier();
});

class ShoppingListNotifier extends StateNotifier<List<ShoppingListItem>> {
  final ShoppingListService _service = ShoppingListService();
  final ShoppingListGenerator _generator = ShoppingListGenerator();

  ShoppingListNotifier() : super([]) {
    _loadList();
  }

  void _loadList() {
    state = _service.getAllItems();
  }

  Future<void> generateFromPlan(WeeklyPlan plan) async {
    await _service.clearAll();
    final items = _generator.generateFromWeeklyPlan(plan);
    await _service.addItems(items);
    _loadList();
  }

  Future<void> toggleItem(int index) async {
    await _service.toggleItem(index);
    _loadList();
  }

  Future<void> deleteItem(int index) async {
    await _service.deleteItem(index);
    _loadList();
  }

  Future<void> clearCompleted() async {
    await _service.clearCompleted();
    _loadList();
  }

  void refresh() {
    _loadList();
  }
}

/// Provider para aderência semanal
final weeklyAdherenceProvider = Provider<double>((ref) {
  final service = MealLogService();
  return service.getWeeklyAdherence();
});

/// Provider para dados offline (alimentos e receitas)
final nutritionDataProvider = Provider<NutritionDataService>((ref) {
  return NutritionDataService();
});
