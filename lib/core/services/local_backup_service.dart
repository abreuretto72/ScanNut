import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:file_picker/file_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'hive_atomic_manager.dart';
import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/app_logger.dart';

class LocalBackupService {
  static final LocalBackupService _instance = LocalBackupService._internal();
  factory LocalBackupService() => _instance;
  LocalBackupService._internal();

  static const String _backupFileNamePrefix = 'scannut_backup_';

  /// Exports all relevant Hive data to a compressed JSON file
  Future<bool> exportBackup() async {
    developer.log('🚀 Iniciando Trace de Exportação...', name: 'BackupTrace');
    try {
      final backupData = <String, dynamic>{
        'version': '1.0.0',
        'timestamp': DateTime.now().toIso8601String(),
        'boxes': {},
      };

      // All relevant boxes in the app
      final boxNames = [
        'box_pets_master',
        'pet_health_records',
        'weekly_meal_plans',
        'pet_events',
        'vaccine_status',
        'box_nutrition_human',
        'nutrition_weekly_plans',
        'meal_log',
        'nutrition_shopping_list',
        'box_botany_intel',
        'box_plants_history',
        'user_profile',
        'partners',
        'box_auth_local'
      ];

      developer.log('📦 Lendo e compactando ${boxNames.length} boxes...', name: 'BackupTrace');
      for (final boxName in boxNames) {
        try {
          Box box = await HiveAtomicManager().ensureBoxOpen(boxName);
          developer.log('  ✅ Box "$boxName" garantido/aberto', name: 'BackupTrace');
          await box.compact();

          final boxData = <String, dynamic>{};
          for (var key in box.keys) {
            boxData[key.toString()] = box.get(key);
          }
          
          backupData['boxes'][boxName] = boxData;
          developer.log('  ✅ Box "$boxName" lido (${boxData.length} itens)', name: 'BackupTrace');
        } catch (e) {
          developer.log('  ❌ Erro no box "$boxName"', name: 'BackupTrace', error: e);
        }
      }

      final jsonString = jsonEncode(backupData);
      final jsonBytes = utf8.encode(jsonString);
      developer.log('📊 JSON gerado: ${jsonBytes.length} bytes', name: 'BackupTrace');

      final compressed = const GZipEncoder().encode(jsonBytes);
      developer.log('🗜️ Compressão concluída: ${compressed.length} bytes', name: 'BackupTrace');

      final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final fileName = '$_backupFileNamePrefix$dateStr.scannut';

      developer.log('💾 Solicitando local para salvar (FilePicker)...', name: 'BackupTrace');
      String? path;
      try {
        // No Android/iOS, passar os bytes diretamente resolve o erro de 'Bytes are required'
        // e permite ao sistema salvar em pastas protegidas com segurança.
        path = await FilePicker.platform.saveFile(
          dialogTitle: 'Salvar Backup',
          fileName: fileName,
          type: FileType.any,
          bytes: Uint8List.fromList(compressed),
        ).timeout(const Duration(seconds: 45));
      } catch (e) {
        developer.log('❌ Erro no FilePicker.saveFile', name: 'BackupTrace', error: e, level: 1000);
        rethrow;
      }

      if (path != null) {
        developer.log('✅ EXPORTAÇÃO CONCLUÍDA: $path', name: 'BackupTrace');
        return true;
      } else {
        developer.log('⚠️ Operação cancelada pelo usuário (caminho nulo)', name: 'BackupTrace');
        return false;
      }
    } catch (e, stack) {
      developer.log('❌ FALHA NA EXPORTAÇÃO', name: 'BackupTrace', error: e, stackTrace: stack, level: 1000);
      rethrow;
    }
  }

  /// Create a temporary backup file and open the system share dialog
  Future<bool> shareBackup() async {
    try {
      logger.info('📦 Preparando backup para compartilhamento...');

      final backupData = <String, dynamic>{
        'version': '1.0.0',
        'timestamp': DateTime.now().toIso8601String(),
        'boxes': {},
      };

      // All relevant boxes (same list as export)
      final boxNames = [
        'box_pets_master', 'pet_health_records', 'weekly_meal_plans', 'pet_events',
        'vaccine_status', 'box_nutrition_human', 'nutrition_weekly_plans', 'meal_log',
        'nutrition_shopping_list', 'box_botany_intel', 'box_plants_history', 'user_profile', 'partners',
        'box_auth_local' // Added auth box too
      ];

      for (final boxName in boxNames) {
        try {
          Box box = await HiveAtomicManager().ensureBoxOpen(boxName);
          await box.compact();

          final boxData = <String, dynamic>{};
          for (var key in box.keys) {
            boxData[key.toString()] = box.get(key);
          }
          backupData['boxes'][boxName] = boxData;
        } catch (e) {
          logger.warning('  ⚠️ Erro no box "$boxName": $e');
        }
      }

      final jsonString = jsonEncode(backupData);
      final jsonBytes = utf8.encode(jsonString);
      final compressed = const GZipEncoder().encode(jsonBytes);

      final tempDir = await getTemporaryDirectory();
      final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final fileName = '$_backupFileNamePrefix$dateStr.scannut';
      final tempFile = File('${tempDir.path}/$fileName');

      await tempFile.writeAsBytes(compressed);

      logger.info('📤 Abrindo seletor de compartilhamento...');
      final result = await Share.shareXFiles(
        [XFile(tempFile.path)],
        subject: 'Backup ScanNut - $dateStr',
      );

      return result.status == ShareResultStatus.success;
    } catch (e, stack) {
      logger.error('❌ ERRO AO COMPARTILHAR: $e', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Import a backup from a local file
  Future<bool> importBackup() async {
    try {
      logger.info('📥 Iniciando importação de backup local...');

      FilePickerResult? result;
      try {
        result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          dialogTitle: 'Selecionar arquivo de backup ScanNut',
        ).timeout(const Duration(seconds: 45));
      } catch (e) {
        logger.error('❌ Erro no FilePicker.pickFiles: $e');
        rethrow;
      }

      if (result == null || result.files.single.path == null) {
        logger.warning('⚠️ Operação cancelada ou nenhum arquivo selecionado');
        return false;
      }

      final path = result.files.single.path!;
      logger.debug('Arquivo selecionado: $path');
      final file = File(path);
      final bytes = await file.readAsBytes();

      logger.info('📦 Descomprimindo backup (${bytes.length} bytes)...');
      final decompressed = const GZipDecoder().decodeBytes(bytes);
      final jsonString = utf8.decode(decompressed);
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      if (backupData['version'] == null || backupData['boxes'] == null) {
        logger.error('❌ Formato de arquivo Inválido: Cabeçalhos ausentes');
        throw Exception('Arquivo de backup inválido ou corrompido');
      }

      logger.info('📋 Restaurando dados do backup de ${backupData['timestamp']}');

      final boxes = backupData['boxes'] as Map<String, dynamic>;
      
      for (var entry in boxes.entries) {
        final boxName = entry.key;
        final boxData = entry.value as Map<String, dynamic>;

        try {
          Box box = await HiveAtomicManager().ensureBoxOpen(boxName);

          // Importante: Limpar antes de restaurar para evitar duplicidades ou lixo
          await box.clear();

          for (var dataEntry in boxData.entries) {
            await box.put(dataEntry.key, dataEntry.value);
          }

          await box.flush();
          logger.debug('  ✅ Box "$boxName" restaurado (${boxData.length} itens)');
        } catch (e) {
          logger.error('  ❌ Erro ao restaurar box "$boxName"', error: e);
        }
      }

      logger.info('✅ Restauração concluída com sucesso!');
      return true;
    } catch (e, stack) {
      logger.error('❌ ERRO NA IMPORTAÇÃO: $e', error: e, stackTrace: stack);
      return false;
    }
  }
}
