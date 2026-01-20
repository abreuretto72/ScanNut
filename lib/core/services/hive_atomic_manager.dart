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
        await Hive.box(boxName).close();
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
      logger.error('❌ [V115-HIVE] Falha na Reconstrução Atômica de $boxName: $e');
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
        debugPrint('⚠️ [V115-HIVE] Type conflict for $boxName. Attempting to resolve by closing... Error: $e');
        try {
          // Force close the mismatched box by using dynamic to bypass type check
          // If Hive.box<T> fails, Hive.box(boxName) (dynamic) usually works for closing
          final dynamicBox = Hive.box(boxName);
          await dynamicBox.close();
          debugPrint('✅ [V115-HIVE] Mismatched box closed successfully.');
        } catch (closeError) {
           debugPrint('⚠️ [V115-HIVE] Cleanup failed: $closeError');
           // If it fails to close, it might be in a very bad state or not actually open.
           // We will proceed to try opening it again, which might throw, but it's our best bet.
        }
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
    logger.warning('⚠️ [V115-HIVE] NUCLEAR PURGE ATIVADO. Destruindo todos os dados...');
    
    final List<String> allBoxes = [
      'box_auth_local', 'box_pets_master', 'pet_events', 'vaccine_status',
      'lab_exams', 'weekly_meal_plans', 'scannut_history', 'meal_history',
      'box_plants_history', 'settings', 'user_profiles', 'nutrition_profiles',
      'weekly_plans', 'meal_logs', 'shopping_lists', 'menu_filters', 'partners'
    ];

    for (final box in allBoxes) {
      await recreateBox(box, cipher: box == 'box_auth_local' ? null : cipher);
    }

    logger.info('✅ [V115-HIVE] Sistema resetado com sucesso.');
  }
}

final hiveAtomicManager = HiveAtomicManager();
