import 'package:flutter/foundation.dart';
import '../models/user_nutrition_profile.dart';
import '../../../../core/services/hive_atomic_manager.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Serviço para gerenciar o perfil nutricional do usuário
/// Box: nutrition_user_profile
class NutritionProfileService {
  static const String _boxName = 'nutrition_user_profile';
  static const String _profileKey = 'current_profile';
  
  Box<UserNutritionProfile>? _box;

  /// Inicializa o box
  Future<void> init({HiveCipher? cipher}) async {
    _box = await HiveAtomicManager().ensureBoxOpen<UserNutritionProfile>(_boxName, cipher: cipher);
    
    // Criar perfil padrão se não existir
    if (_box != null && _box!.isEmpty) {
      await saveProfile(UserNutritionProfile.padrao());
      debugPrint('📝 Created default nutrition profile');
    }
  }

  /// Retorna o perfil atual
  UserNutritionProfile? getProfile() {
    try {
      return _box?.get(_profileKey);
    } catch (e) {
      debugPrint('❌ Error getting profile: $e');
      return null;
    }
  }

  /// Salva o perfil
  Future<void> saveProfile(UserNutritionProfile profile) async {
    try {
      profile.atualizadoEm = DateTime.now();
      await _box?.put(_profileKey, profile);
      debugPrint('✅ Profile saved successfully');
    } catch (e) {
      debugPrint('❌ Error saving profile: $e');
      rethrow;
    }
  }

  /// Atualiza objetivo
  Future<void> updateObjetivo(String objetivo) async {
    try {
      final profile = getProfile();
      if (profile != null) {
        profile.objetivo = objetivo;
        await saveProfile(profile);
      }
    } catch (e) {
      debugPrint('❌ Error updating objetivo: $e');
      rethrow;
    }
  }

  /// Adiciona restrição
  Future<void> addRestricao(String restricao) async {
    try {
      final profile = getProfile();
      if (profile != null && !profile.restricoes.contains(restricao)) {
        profile.restricoes.add(restricao);
        await saveProfile(profile);
      }
    } catch (e) {
      debugPrint('❌ Error adding restricao: $e');
      rethrow;
    }
  }

  /// Remove restrição
  Future<void> removeRestricao(String restricao) async {
    try {
      final profile = getProfile();
      if (profile != null) {
        profile.restricoes.remove(restricao);
        await saveProfile(profile);
      }
    } catch (e) {
      debugPrint('❌ Error removing restricao: $e');
      rethrow;
    }
  }

  /// Limpa todos os dados do box
  Future<void> clearAll() async {
    try {
      await _box?.clear();
      debugPrint('🧹 NutritionProfileService cleared');
    } catch (e) {
      debugPrint('❌ Error clearing NutritionProfileService: $e');
      rethrow;
    }
  }

  /// Fecha o box
  Future<void> close() async {
    try {
      await _box?.close();
      debugPrint('📦 NutritionProfileService closed');
    } catch (e) {
      debugPrint('❌ Error closing NutritionProfileService: $e');
    }
  }
}
