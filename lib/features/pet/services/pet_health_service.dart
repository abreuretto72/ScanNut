import 'package:hive_flutter/hive_flutter.dart';
/// ============================================================================
/// 🚫 COMPONENTE BLINDADO E CONGELADO - NÃO ALTERAR
/// Este módulo de Saúde Geral do Pet foi concluído e validado.
/// Nenhuma rotina ou lógica interna deve ser modificada.
/// Data de Congelamento: 29/12/2025
/// ============================================================================

import 'package:flutter/material.dart';

/// Service for managing pet health records
class PetHealthService {
  static const String _healthBoxName = 'pet_health_records';
  Box? _healthBox;

  Future<void> init({HiveCipher? cipher}) async {
    final isOpen = Hive.isBoxOpen(_healthBoxName);
    debugPrint('🔍 [V61-TRACE] PetHealthService checking box "$_healthBoxName": open=$isOpen');

    if (isOpen) {
      _healthBox = Hive.box(_healthBoxName);
      debugPrint('✅ [V61-TRACE] PetHealth box already open.');
    } else {
      try {
        debugPrint('📂 [V61-TRACE] Opening PetHealth box...');
        _healthBox = await Hive.openBox(_healthBoxName, encryptionCipher: cipher);
        debugPrint('✅ [V61-TRACE] PetHealthService initialized (Secure)');
      } catch (e, stack) {
        debugPrint('❌ [V61-TRACE] FATAL: Failed to open Secure Pet Health Box: $e\n$stack');
      }
    }
  }

  /// Add a health record for a pet
  Future<void> addHealthRecord(String petName, Map<String, dynamic> healthData) async {
    try {
      final key = '${petName}_${DateTime.now().millisecondsSinceEpoch}';
      await _healthBox?.put(key, {
        'pet_name': petName,
        'timestamp': DateTime.now().toIso8601String(),
        'data': healthData,
      });
      debugPrint('✅ Health record saved for $petName');
    } catch (e) {
      debugPrint('❌ Error saving health record: $e');
    }
  }

  /// Get all health records for a pet
  Future<List<Map<String, dynamic>>> getHealthRecords(String petName) async {
    try {
      final allRecords = _healthBox?.values.toList() ?? [];
      return allRecords
          .where((record) => (record as Map)['pet_name'] == petName)
          .map((record) => Map<String, dynamic>.from(record as Map))
          .toList()
        ..sort((a, b) => (b['timestamp'] as String).compareTo(a['timestamp'] as String));
    } catch (e) {
      debugPrint('❌ Error getting health records: $e');
      return [];
    }
  }

  /// Get the latest health record for a pet
  Future<Map<String, dynamic>?> getLatestHealthRecord(String petName) async {
    final records = await getHealthRecords(petName);
    return records.isNotEmpty ? records.first : null;
  }
}
