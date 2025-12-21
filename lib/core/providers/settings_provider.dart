import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings model
class AppSettings {
  final int dailyCalorieGoal;
  final String userName;
  final bool showTips;
  final bool showFoodButton;
  final bool showPlantButton;
  final bool showPetButton;
  final double partnerSearchRadius;

  const AppSettings({
    this.dailyCalorieGoal = 2000,
    this.userName = '',
    this.showTips = true,
    this.showFoodButton = true,
    this.showPlantButton = true,
    this.showPetButton = true,
    this.partnerSearchRadius = 10.0,
  });

  AppSettings copyWith({
    int? dailyCalorieGoal,
    String? userName,
    bool? showTips,
    bool? showFoodButton,
    bool? showPlantButton,
    bool? showPetButton,
    double? partnerSearchRadius,
  }) {
    return AppSettings(
      dailyCalorieGoal: dailyCalorieGoal ?? this.dailyCalorieGoal,
      userName: userName ?? this.userName,
      showTips: showTips ?? this.showTips,
      showFoodButton: showFoodButton ?? this.showFoodButton,
      showPlantButton: showPlantButton ?? this.showPlantButton,
      showPetButton: showPetButton ?? this.showPetButton,
      partnerSearchRadius: partnerSearchRadius ?? this.partnerSearchRadius,
    );
  }
}

/// Settings notifier
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppSettings(
      dailyCalorieGoal: prefs.getInt('dailyCalorieGoal') ?? 2000,
      userName: prefs.getString('userName') ?? '',
      showTips: prefs.getBool('showTips') ?? true,
      showFoodButton: prefs.getBool('showFoodButton') ?? true,
      showPlantButton: prefs.getBool('showPlantButton') ?? true,
      showPetButton: prefs.getBool('showPetButton') ?? true,
      partnerSearchRadius: (prefs.getDouble('partnerSearchRadius') ?? 10.0).clamp(1.0, 20.0),
    );
  }

  Future<void> setDailyCalorieGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dailyCalorieGoal', goal);
    state = state.copyWith(dailyCalorieGoal: goal);
  }

  Future<void> setUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
    state = state.copyWith(userName: name);
  }

  Future<void> setShowTips(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showTips', show);
    state = state.copyWith(showTips: show);
  }

  Future<void> setShowFoodButton(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showFoodButton', show);
    state = state.copyWith(showFoodButton: show);
  }

  Future<void> setShowPlantButton(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showPlantButton', show);
    state = state.copyWith(showPlantButton: show);
  }

  Future<void> setShowPetButton(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showPetButton', show);
    state = state.copyWith(showPetButton: show);
  }

  Future<void> setPartnerSearchRadius(double radius) async {
    final clampedRadius = radius.clamp(1.0, 20.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('partnerSearchRadius', clampedRadius);
    state = state.copyWith(partnerSearchRadius: clampedRadius);
  }

  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    state = const AppSettings();
  }
}

/// Settings provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});
