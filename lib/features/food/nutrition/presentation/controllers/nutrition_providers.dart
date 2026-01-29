import 'package:flutter/foundation.dart';
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
import '../../data/models/meal.dart';
import '../../data/models/plan_day.dart';
import '../../data/models/menu_creation_params.dart';

/// Provider para o perfil nutricional
final nutritionProfileProvider =
    StateNotifierProvider<NutritionProfileNotifier, UserNutritionProfile?>(
        (ref) {
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

/// Provider para histórico de planos semanais
final weeklyPlanHistoryProvider = FutureProvider<List<WeeklyPlan>>((ref) async {
  final service = WeeklyPlanService();
  await service.init();
  return service.getAllPlans()
    ..sort(
        (a, b) => b.weekStartDate.compareTo(a.weekStartDate)); // Newest first
});

/// Provider para o plano semanal atual
final currentWeekPlanProvider =
    StateNotifierProvider<WeeklyPlanNotifier, WeeklyPlan?>((ref) {
  return WeeklyPlanNotifier(ref);
});

class WeeklyPlanNotifier extends StateNotifier<WeeklyPlan?> {
  final Ref ref;
  final WeeklyPlanService _service = WeeklyPlanService();
  final WeeklyPlanGenerator _generator = WeeklyPlanGenerator();
  final ShoppingListService _shoppingService = ShoppingListService();

  WeeklyPlanNotifier(this.ref) : super(null) {
    _loadCurrentWeekPlan();
  }

  void _loadCurrentWeekPlan() {
    state = _service.getCurrentWeekPlan();
  }

  Future<void> generateNewPlan(
    UserNutritionProfile profile, {
    MenuCreationParams? params,
    DateTime? startDate,
    String? languageCode,
    bool replace = false,
  }) async {
    try {
      debugPrint('🚀 [MenuGen] Iniciando geração no Notifier...');
      
      // Check if a plan already exists for this date to determine version
      final targetStart =
          startDate ?? params?.startDate ?? _service.getMonday(DateTime.now());
      final existingPlans = _service
          .getAllPlans()
          .where((p) => _service.isSameDay(p.weekStartDate, targetStart))
          .toList();
      final nextVersion = existingPlans.isEmpty
          ? 1
          : (existingPlans.map((p) => p.version).reduce((a, b) => a > b ? a : b) +
              1);

      debugPrint('📥 [MenuGen] Chamando Generator...');
      final plan = await _generator.generateWeeklyPlan(
          profile: profile,
          params: params,
          startDate: startDate ?? params?.startDate,
          languageCode: languageCode);

      if (plan != null) {
        debugPrint('📥 [MenuGen] Sucesso na Geração (Simulada). Configurando metadados...');
        plan.version = nextVersion;
        plan.objective = params?.objective ?? profile.objetivo ?? 'maintenance';
        plan.periodType = params?.periodType ?? 'weekly';

        // Generate and save shopping list JSON
        plan.shoppingListJson =
            _shoppingService.generateMainShoppingListJson(plan);

        if (replace) {
          // Soft delete all active plans in this slot before saving new one
          for (var p in existingPlans) {
            if (p.id != null && p.status == 'active') {
              await _service.softDeletePlan(p.id!);
            }
          }
        }

        debugPrint('💾 [MenuGen] Tentando persistir no Hive box_weekly_plans...');
        await _service.savePlan(plan);
        debugPrint('💾 [MenuGen] Persistência OK!');
        
        state = plan;

        // Sync shopping list automatically
        await ref.read(shoppingListProvider.notifier).generateFromPlan(plan);
      }
    } catch (e, stack) {
      debugPrint('❌ [CRITICAL_MENU_ERROR]: $e');
      debugPrint('📚 [STACKTRACE]: $stack');
      rethrow; // Pass error to UI to display Red Card
    }
  }

  Future<void> regeneratePlan(UserNutritionProfile profile,
      {String? languageCode}) async {
    if (state == null) return;

    final currentPlan = state!;
    final nextVersion = currentPlan.version + 1;

    final newSeed = DateTime.now().millisecondsSinceEpoch;
    final plan = await _generator.generateWeeklyPlan(
      profile: profile,
      seed: newSeed,
      startDate: currentPlan.weekStartDate,
      languageCode: languageCode,
      params: MenuCreationParams(
        periodType: currentPlan.periodType ?? 'weekly',
        objective: currentPlan.objective ?? 'maintenance',
      ),
    );

    if (plan != null) {
      plan.version = nextVersion;
      plan.objective = currentPlan.objective;
      plan.periodType = currentPlan.periodType;

      // Generate and save shopping list JSON
      plan.shoppingListJson =
          _shoppingService.generateMainShoppingListJson(plan);

      await _service.savePlan(plan);
      state = plan;
    }
  }

  Future<void> updateMeal(PlanDay day, Meal oldMeal, Meal newMeal) async {
    if (state == null) return;
    final plan = state!;
    final dayIndex = plan.days.indexWhere((d) => d.date == day.date);
    if (dayIndex != -1) {
      final meals = List<Meal>.from(plan.days[dayIndex].meals);
      final mealIndex = meals.indexOf(oldMeal);
      if (mealIndex != -1) {
        meals[mealIndex] = newMeal;
        plan.days[dayIndex].meals = meals;
        plan.atualizadoEm = DateTime.now();

        // Regenerate shopping list since ingredients changed
        plan.shoppingListJson =
            _shoppingService.generateMainShoppingListJson(plan);

        await _service.savePlan(plan);
        state = WeeklyPlan.fromJson(plan.toJson()); // Rebuild UI
      }
    }
  }

  void setPlan(WeeklyPlan plan) {
    state = plan;
  }

  Future<void> swapMeal(
      PlanDay day, Meal oldMeal, UserNutritionProfile profile) async {
    final newMeal = await _generator.swapMeal(
      tipo: oldMeal.tipo,
      profile: profile,
      excludedRecipeIds: oldMeal.recipeId != null ? [oldMeal.recipeId!] : [],
      objective: state?.objective,
    );

    if (newMeal != null && state != null) {
      await updateMeal(day, oldMeal, newMeal);
    }
  }

  Future<void> deletePlan(WeeklyPlan plan) async {
    if (plan.id != null) {
      await _service.softDeletePlan(plan.id!);
      if (state?.id == plan.id) {
        state = _service.getCurrentWeekPlan();
      }
    }
  }

  void refresh() {
    _loadCurrentWeekPlan();
  }
}

/// Provider para logs de refeições
final mealLogsProvider =
    StateNotifierProvider<MealLogsNotifier, List<MealLog>>((ref) {
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
final shoppingListProvider =
    StateNotifierProvider<ShoppingListNotifier, List<ShoppingListItem>>((ref) {
  return ShoppingListNotifier();
});

class ShoppingListNotifier extends StateNotifier<List<ShoppingListItem>> {
  final ShoppingListService _service = ShoppingListService();

  ShoppingListNotifier() : super([]) {
    _loadList();
  }

  void _loadList() {
    state = _service.getAllItems();
  }

  Future<void> generateFromPlan(WeeklyPlan plan) async {
    await _service.clearAll();

    // Use the new professional generation (returns one list per week)
    final weeklyLists = _service.generateWeeklyListsFromPlan(plan);
    if (weeklyLists.isEmpty) return;

    // For the UI (Interactive List), we populate the first week
    final List<ShoppingListItem> hiveItems = [];
    final now = DateTime.now();

    for (var cat in weeklyLists.first.categories) {
      for (var item in cat.items) {
        hiveItems.add(ShoppingListItem(
          nome: item.name,
          quantidadeTexto: item.quantityDisplay,
          criadoEm: now,
          marcado: false,
        ));
      }
    }

    await _service.addItems(hiveItems);
    _loadList();
  }

  Future<void> addItem(String nome, String quantidade) async {
    final item = ShoppingListItem(
      nome: nome,
      quantidadeTexto: quantidade,
      criadoEm: DateTime.now(),
    );
    await _service.addItem(item);
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
