import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/app_logger.dart';

/// 🛡️ V115: HIVE ATOMIC MANAGER (Motor de Estabilidade ScanNut)
/// Responsável pela gestão industrial de boxes, garantindo imunidadade a crashes.
class HiveAtomicManager {
  static final HiveAtomicManager _instance = HiveAtomicManager._internal();
  factory HiveAtomicManager() => _instance;
  HiveAtomicManager._internal();

  /// 🧬 RECONSTRUÇÃO ATÔMICA (V111)
  /// Salva o DNA do box, fecha, deleta físico e reabre vazio com segurança.
  Future<void> recreateBox<T>(String boxName, {HiveCipher? cipher}) async {
    logger.info('🧬 [V115-HIVE] Iniciando Reconstrução Atômica: $boxName');

    try {
      // 1. Verificar se a box está aberta e fechar
      if (Hive.isBoxOpen(boxName)) {
        debugPrint('🧹 [V115-HIVE] Fechando box ativa: $boxName');
        try {
          await Hive.box(boxName).close();
        } catch (e) {
          debugPrint(
              '⚠️ [V115-HIVE] Type mismatch during closure of $boxName. Falling back to global close.');
          await Hive.close();
        }
      }

      // 2. Deletar físico do disco (Blindagem V111)
      debugPrint('🔥 [V115-HIVE] Deletando arquivos físicos de $boxName');
      await Hive.deleteBoxFromDisk(boxName);

      // 3. Reabrir vazio com o Cipher correto
      debugPrint('🌱 [V115-HIVE] Reabrindo box virgem: $boxName');
      if (cipher != null) {
        await Hive.openBox<T>(boxName, encryptionCipher: cipher);
      } else {
        await Hive.openBox<T>(boxName);
      }

      logger.info('✅ [V115-HIVE] Reconstrução Atômica concluída: $boxName');
    } catch (e) {
      logger
          .error('❌ [V115-HIVE] Falha na Reconstrução Atômica de $boxName: $e');
      // Tentar garantir que a box está aberta mesmo com erro
      await ensureBoxOpen<T>(boxName, cipher: cipher);
    }
  }

  /// 🛡️ PROTEÇÃO TOTAL: Garante que a box esteja aberta antes de qualquer operação
  Future<Box<T>> ensureBoxOpen<T>(String boxName, {HiveCipher? cipher}) async {
    if (Hive.isBoxOpen(boxName)) {
      try {
        // Try to retrieve strictly typed
        final box = Hive.box<T>(boxName);
        if (box.isOpen) return box;
      } catch (e) {
        debugPrint(
            '⚠️ [V115-HIVE] Type conflict for $boxName. Resolving via specific closure. Error: $e');
        try {
          // 🛡️ V135: Tenta fechar apenas o box problemático em vez de todo o sistema
          if (Hive.isBoxOpen(boxName)) {
            await Hive.box(boxName).close();
          }
        } catch (inner) {
          debugPrint('☢️ [V115-HIVE] Nuclear fallback: closing all boxes for $boxName');
          await Hive.close();
        }
        // After close, we continue to open with requested type below
      }
    }

    debugPrint('🛡️ [V115-HIVE] Auto-cura: Abrindo box sob demanda: $boxName');
    if (cipher != null) {
      return await Hive.openBox<T>(boxName, encryptionCipher: cipher);
    } else {
      return await Hive.openBox<T>(boxName);
    }
  }

  /// 🧹 NUCLEAR PURGE: Limpeza total de todos os dados do sistema
  Future<void> nuclearPurge({HiveCipher? cipher}) async {
    logger.warning(
        '⚠️ [V115-HIVE] NUCLEAR PURGE ATIVADO. Destruindo todos os dados...');

    final List<String> allBoxes = [
      'box_auth_local',
      'box_pets_master',
      'pet_events',
      'vaccine_status',
      'lab_exams',
      'weekly_meal_plans',
      'scannut_history',
      'meal_history',
      'box_plants_history',
      'settings',
      'user_profiles',
      'nutrition_profiles',
      'weekly_plans',
      'meal_logs',
      'shopping_lists',
      'menu_filters',
      'partners'
    ];

    for (final box in allBoxes) {
      await recreateBox(box, cipher: box == 'box_auth_local' ? null : cipher);
    }

    logger.info('✅ [V115-HIVE] Sistema resetado com sucesso.');
  }
}

final hiveAtomicManager = HiveAtomicManager();
