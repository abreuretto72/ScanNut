import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'hive_atomic_manager.dart';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

/// Serviço de Backup Permanente - Sobrevive a desinstalações
/// Salva dados em pasta pública do dispositivo
class PermanentBackupService {
  static final PermanentBackupService _instance = PermanentBackupService._internal();
  factory PermanentBackupService() => _instance;
  PermanentBackupService._internal();

  static const String _backupFolderName = 'ScanNut_Backup';
  static const String _backupFileName = 'auto_backup.scannut';
  
  /// Lista de boxes que devem ser salvos
  static const List<String> _criticalBoxes = [
    'box_auth_local',
    'settings',
    'user_profiles',
    'processed_images_box',
    'box_pets_master',
    'pet_events',
    'pet_events_journal',
    'vaccine_status',
    'pet_health_records',
    'lab_exams',
    'weekly_meal_plans',
    'box_nutrition_human',
    'nutrition_user_profile',
    'nutrition_weekly_plans',
    'nutrition_meal_logs',
    'nutrition_shopping_list',
    'menu_filter_settings',
    'recipe_history_box',
    'box_plants_history',
    'box_botany_intel',
    'scannut_history',
    'scannut_meal_history',
    'partners_box',
    'box_workouts',
  ];

  /// Obtém o diretório de backup permanente
  /// Android: /storage/emulated/0/Documents/ScanNut_Backup/
  /// iOS: Documents folder (acessível via Files app)
  Future<Directory> _getBackupDirectory() async {
    Directory baseDir;
    
    if (Platform.isAndroid) {
      // Android: Usar pasta Documents pública
      final externalDir = await getExternalStorageDirectory();
      if (externalDir == null) {
        throw Exception('Não foi possível acessar armazenamento externo');
      }
      
      // Navegar para a raiz do armazenamento público
      // De: /storage/emulated/0/Android/data/com.app/files
      // Para: /storage/emulated/0/Documents/ScanNut_Backup
      final storagePath = externalDir.path.split('/Android/').first;
      baseDir = Directory('$storagePath/Documents/$_backupFolderName');
    } else {
      // iOS: Usar Documents directory (acessível via Files app)
      final appDocDir = await getApplicationDocumentsDirectory();
      baseDir = Directory('${appDocDir.path}/$_backupFolderName');
    }
    
    if (!await baseDir.exists()) {
      await baseDir.create(recursive: true);
      debugPrint('📁 Pasta de backup criada: ${baseDir.path}');
    }
    
    return baseDir;
  }

  /// Cria backup automático de todos os dados críticos
  Future<bool> createAutoBackup() async {
    try {
      debugPrint('🔄 Iniciando auto-backup permanente...');
      
      final backupData = <String, dynamic>{
        'version': '2.0.0', // Nova versão com suporte a auto-recovery
        'timestamp': DateTime.now().toIso8601String(),
        'boxes': {},
      };

      // Coletar dados de todos os boxes críticos
      for (final boxName in _criticalBoxes) {
        try {
          Box box = await HiveAtomicManager().ensureBoxOpen(boxName);
          await box.compact();

          final boxData = <String, dynamic>{};
          for (var key in box.keys) {
            boxData[key.toString()] = box.get(key);
          }
          
          backupData['boxes'][boxName] = boxData;
          debugPrint('  ✅ Box "$boxName" salvo (${boxData.length} itens)');
        } catch (e) {
          debugPrint('  ⚠️ Erro no box "$boxName": $e');
        }
      }

      // Comprimir dados
      final jsonString = jsonEncode(backupData);
      final jsonBytes = utf8.encode(jsonString);
      final compressed = const GZipEncoder().encode(jsonBytes);

      // Salvar em pasta permanente
      final backupDir = await _getBackupDirectory();
      final backupFile = File('${backupDir.path}/$_backupFileName');
      await backupFile.writeAsBytes(compressed);
      
      debugPrint('✅ Auto-backup salvo: ${backupFile.path}');
      debugPrint('📊 Tamanho: ${compressed.length} bytes');
      
      return true;
    } catch (e, stack) {
      debugPrint('❌ Erro no auto-backup: $e');
      debugPrint(stack.toString());
      return false;
    }
  }

  /// Verifica se existe backup permanente e restaura automaticamente
  /// Retorna true se dados foram restaurados
  Future<bool> autoRecovery() async {
    try {
      debugPrint('🔍 Verificando backup permanente...');
      
      final backupDir = await _getBackupDirectory();
      final backupFile = File('${backupDir.path}/$_backupFileName');
      
      if (!await backupFile.exists()) {
        debugPrint('ℹ️ Nenhum backup encontrado');
        return false;
      }

      debugPrint('📦 Backup encontrado! Iniciando auto-recovery...');
      
      final bytes = await backupFile.readAsBytes();
      final decompressed = const GZipDecoder().decodeBytes(bytes);
      final jsonString = utf8.decode(decompressed);
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      if (backupData['version'] == null || backupData['boxes'] == null) {
        debugPrint('❌ Backup corrompido ou inválido');
        return false;
      }

      debugPrint('📅 Restaurando backup de ${backupData['timestamp']}');

      final boxes = backupData['boxes'] as Map<String, dynamic>;
      int restoredBoxes = 0;
      
      for (var entry in boxes.entries) {
        final boxName = entry.key;
        final boxData = entry.value as Map<String, dynamic>;

        try {
          Box box = await HiveAtomicManager().ensureBoxOpen(boxName);

          // Só restaurar se o box estiver vazio (evita sobrescrever dados novos)
          if (box.isEmpty) {
            for (var dataEntry in boxData.entries) {
              await box.put(dataEntry.key, dataEntry.value);
            }
            await box.flush();
            restoredBoxes++;
            debugPrint('  ✅ Box "$boxName" restaurado (${boxData.length} itens)');
          } else {
            debugPrint('  ⏭️ Box "$boxName" já contém dados, pulando');
          }
        } catch (e) {
          debugPrint('  ❌ Erro ao restaurar "$boxName": $e');
        }
      }

      debugPrint('✅ Auto-recovery concluído! $restoredBoxes boxes restaurados');
      return restoredBoxes > 0;
    } catch (e, stack) {
      debugPrint('❌ Erro no auto-recovery: $e');
      debugPrint(stack.toString());
      return false;
    }
  }

  /// Cria backup com timestamp (para manter histórico)
  Future<String?> createTimestampedBackup() async {
    try {
      final backupDir = await _getBackupDirectory();
      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'backup_$dateStr.scannut';
      
      // Usar mesma lógica de createAutoBackup mas com nome diferente
      final backupData = <String, dynamic>{
        'version': '2.0.0',
        'timestamp': DateTime.now().toIso8601String(),
        'boxes': {},
      };

      for (final boxName in _criticalBoxes) {
        try {
          Box box = await HiveAtomicManager().ensureBoxOpen(boxName);

          final boxData = <String, dynamic>{};
          for (var key in box.keys) {
            boxData[key.toString()] = box.get(key);
          }
          backupData['boxes'][boxName] = boxData;
        } catch (e) {
          debugPrint('⚠️ Erro no box "$boxName": $e');
        }
      }

      final jsonString = jsonEncode(backupData);
      final jsonBytes = utf8.encode(jsonString);
      final compressed = const GZipEncoder().encode(jsonBytes);

      final backupFile = File('${backupDir.path}/$fileName');
      await backupFile.writeAsBytes(compressed);
      
      debugPrint('✅ Backup timestamped criado: ${backupFile.path}');
      return backupFile.path;
    } catch (e) {
      debugPrint('❌ Erro ao criar backup timestamped: $e');
      return null;
    }
  }

  /// Retorna o caminho da pasta de backup (para exibir ao usuário)
  Future<String> getBackupPath() async {
    final dir = await _getBackupDirectory();
    return dir.path;
  }

  /// Remove o backup permanente (Usado no Factory Reset)
  Future<void> clearBackup() async {
    try {
      final backupDir = await _getBackupDirectory();
      final backupFile = File('${backupDir.path}/$_backupFileName');
      
      if (await backupFile.exists()) {
        await backupFile.delete();
        debugPrint('🗑️ Backup permanente excluído com sucesso.');
      }
    } catch (e) {
      debugPrint('⚠️ Erro ao excluir backup permanente: $e');
    }
  }
}
