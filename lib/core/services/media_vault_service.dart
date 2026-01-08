import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/history_service.dart';
import '../../features/plant/models/botany_history_item.dart';
import '../../features/food/models/nutrition_history_item.dart';

/// 🔐 MEDIA VAULT SERVICE
/// Responsible for secure, long-term storage of media assets.
/// Migrates unsafe legacy files to ApplicationSupportDirectory/media_vault.
class MediaVaultService {
  static final MediaVaultService _instance = MediaVaultService._internal();
  factory MediaVaultService() => _instance;
  MediaVaultService._internal();

  static const String VAULT_ROOT = 'media_vault';
  
  // Folders
  static const String PETS_DIR = 'pets';
  static const String FOOD_DIR = 'food';
  static const String BOTANY_DIR = 'plants';
  static const String WOUNDS_DIR = 'wounds';

  /// Initializes the vault and runs migration if needed
  Future<void> init() async {
    await _ensureVaultStructure();
    // Running migration in background to not block startup significantly
    // But for critical data, we might want to await.
    // For now, let's run it and await, it shouldn't take long for small datasets.
    await _migrateLegacyFiles();
  }

  Future<void> _ensureVaultStructure() async {
    final appDir = await getApplicationSupportDirectory();
    final root = Directory('${appDir.path}/$VAULT_ROOT');
    
    if (!await root.exists()) await root.create();
    
    await _ensureDir(root, PETS_DIR);
    await _ensureDir(root, FOOD_DIR);
    await _ensureDir(root, BOTANY_DIR);
    await _ensureDir(root, WOUNDS_DIR);
  }

  Future<void> _ensureDir(Directory root, String sub) async {
    final d = Directory('${root.path}/$sub');
    if (!await d.exists()) await d.create();
  }

  /// 🛡️ MIGRATION LOGIC
  /// Moves files from /files/medical_docs -> /support/media_vault/pets
  /// Moves files from /files/nutrition_images -> /support/media_vault/food
  /// Moves files from /files/botany_images -> /support/media_vault/plants
  Future<void> _migrateLegacyFiles() async {
      try {
          final docDir = await getApplicationDocumentsDirectory();
          final supportDir = await getApplicationSupportDirectory();
          final vaultRoot = Directory('${supportDir.path}/$VAULT_ROOT');

          // 1. MIGRATE NUTRITION
          await _migrateFolder(
              source: Directory('${docDir.path}/nutrition_images'),
              dest: Directory('${vaultRoot.path}/$FOOD_DIR'),
              boxName: 'box_nutrition_history'
          );

          // 2. MIGRATE BOTANY
          await _migrateFolder(
              source: Directory('${docDir.path}/botany_images'),
              dest: Directory('${vaultRoot.path}/$BOTANY_DIR'),
              boxName: 'box_plants_history'
          );
          
          // 3. MIGRATE PETS (Complex structure: medical_docs/PetName)
          final medicalDocs = Directory('${docDir.path}/medical_docs');
          if (await medicalDocs.exists()) {
              final contents = medicalDocs.listSync();
              for (var entity in contents) {
                  if (entity is Directory) {
                      // It's a Pet Folder
                      final petName = path.basename(entity.path);
                      final destPetDir = Directory('${vaultRoot.path}/$PETS_DIR/$petName');
                      if (!await destPetDir.exists()) await destPetDir.create(recursive: true);
                      
                      // Move files
                      final files = entity.listSync();
                      for (var f in files) {
                          if (f is File) {
                            try {
                                final destPath = '${destPetDir.path}/${path.basename(f.path)}';
                                if (!File(destPath).existsSync()) {
                                    await f.copy(destPath);
                                    // Optional: f.delete(); // Keep legacy for safety for now
                                    debugPrint('📦 Migrated pet file: ${path.basename(f.path)}');
                                }
                            } catch (e) {
                                debugPrint('⚠️ Failed to migrate pet file: $e');
                            }
                          }
                      }
                  }
              }
          }
          
      } catch (e) {
          debugPrint('❌ Migration Error: $e');
      }
  }

  Future<void> _migrateFolder({required Directory source, required Directory dest, required String boxName}) async {
      if (!await source.exists()) return;

      final files = source.listSync().whereType<File>();
      for (var f in files) {
          try {
              final filename = path.basename(f.path);
              final destPath = '${dest.path}/$filename';
              
              if (!File(destPath).existsSync()) {
                  await f.copy(destPath);
                  debugPrint('📦 Migrated: $filename');
              }
          } catch (e) {
             debugPrint('⚠️ File migration failed: $e');
          }
      }
  }

  /// Securely Clones a file to the Vault with Compression (80% Quality, Max 1920x1080)
  /// Returns the NEW path.
  /// Throws exception if verification fails.
  Future<String> secureClone(File sourceFile, String category, [String? subFolder]) async {
      final appDir = await getApplicationSupportDirectory();
      String targetPath = '${appDir.path}/$VAULT_ROOT/$category';
      
      if (subFolder != null) {
          targetPath += '/$subFolder';
      }
      
      final dir = Directory(targetPath);
      if (!await dir.exists()) await dir.create(recursive: true);

      final filename = path.basename(sourceFile.path);
      // Ensure unique name if collision
      String safeFilename = filename;
      if (File('${dir.path}/$filename').existsSync()) {
         safeFilename = '${DateTime.now().millisecondsSinceEpoch}_$filename';
      }
      
      // Enforce .jpg extension for uniformity if compressing
      if (!safeFilename.toLowerCase().endsWith('.jpg') && !safeFilename.toLowerCase().endsWith('.jpeg')) {
          safeFilename = '${path.basenameWithoutExtension(safeFilename)}.jpg';
      }
      
      final destFile = File('${dir.path}/$safeFilename');
      
      try {
        debugPrint('🗜️ Compressing & Cloning to Vault: $safeFilename');
        // COMPRESS AND CLONE
        final compressedFile = await FlutterImageCompress.compressAndGetFile(
          sourceFile.absolute.path,
          destFile.absolute.path,
          quality: 80,
          minWidth: 1920,
          minHeight: 1080,
        );

        if (compressedFile == null) {
             debugPrint('⚠️ Compression returned null, falling back to raw copy.');
             await sourceFile.copy(destFile.path);
        }
      } catch (e) {
          debugPrint('⚠️ Compression failed ($e), falling back to raw copy.');
          // Fallback to simple copy if compression fails
          await sourceFile.copy(destFile.path);
      }
      
      // VERIFICATION
      if (!await destFile.exists()) {
          throw Exception("Vault Clone Failed: File not found after copy at ${destFile.path}");
      }
      
      final length = await destFile.length();
      if (length == 0) {
           throw Exception("Vault Clone Failed: File is empty at ${destFile.path}");
      }
      
      debugPrint('✅ Vault Secure Clone Success: ${destFile.path} ($length bytes)');
      
      // 🛡️ ATOMIC MIRRORING (PUBLIC BACKUP)
      try {
          ignoreErrors(() async {
              final backupDir = await _getPublicBackupDir(category, subFolder);
              final backupFile = File('${backupDir.path}/$safeFilename');
              if (!backupFile.existsSync()) {
                  await destFile.copy(backupFile.path);
                  debugPrint('🛡️ Mirror created at: ${backupFile.path}');
              }
          });
      } catch (e) {
          debugPrint('⚠️ Mirroring failed (non-critical): $e');
      }

      return destFile.path;
  }

  /// 🏥 SELF-HEALING: Attempts to recover a missing file from Vault (Migration) or Backup
  Future<String> attemptRecovery(String filePath, {String? category}) async {
      debugPrint('🔍 [VAULT_TRACE] START Recovery for path: "$filePath"');
      
      final file = File(filePath);
      if (await file.exists()) {
          debugPrint('   [VAULT_TRACE] ✅ File actually exists at original path. No recovery needed.');
          return filePath;
      } else {
          debugPrint('   [VAULT_TRACE] ❌ File MISSING at original path.');
      }

      final filename = path.basename(filePath);
      debugPrint('   [VAULT_TRACE] Filename extracted: "$filename"');

      // 1. CHECK VAULT (Did we migrate it?)
      try {
          final appDir = await getApplicationSupportDirectory();
          final vaultRoot = Directory('${appDir.path}/$VAULT_ROOT');
          debugPrint('   [VAULT_TRACE] Checking Internal Vault at: ${vaultRoot.path}');
          
          if (await vaultRoot.exists()) {
              final matches = vaultRoot.listSync(recursive: true).where((fs) => path.basename(fs.path) == filename);
              debugPrint('   [VAULT_TRACE] Vault matches found: ${matches.length}');
              
              if (matches.isNotEmpty) {
                   final recoveredPath = matches.first.path;
                   debugPrint('✅ [VAULT_TRACE] FOUND in Vault! Recovered path: $recoveredPath');
                   return recoveredPath;
              }
          } else {
              debugPrint('   [VAULT_TRACE] Internal Vault directory does not exist.');
          }
      } catch (e) {
          debugPrint('⚠️ [VAULT_TRACE] Vault check error: $e');
      }
      
      // 2. CHECK PUBLIC BACKUP MIRROR
      try {
          final backupRoot = await _getPublicBackupRoot();
          debugPrint('   [VAULT_TRACE] Checking Backup Mirror at: ${backupRoot.path}');
          
          // Deep search in backup root
          final matches = backupRoot.listSync(recursive: true).where((fs) => path.basename(fs.path) == filename);
           debugPrint('   [VAULT_TRACE] Backup matches found: ${matches.length}');
          
          if (matches.isNotEmpty) {
               final backupFile = matches.first as File;
               debugPrint('   [VAULT_TRACE] Found backup file: ${backupFile.path}');
               
               // Restore to a valid internal location (Vault) instead of original broken path
               // We don't want to restore to cache. We want to restore to Vault.
               // Default to 'recovered' folder or try to guess category.
               final targetCat = category ?? 'recovered'; 
               final vaultDir = Directory('${(await getApplicationSupportDirectory()).path}/$VAULT_ROOT/$targetCat');
               if (!await vaultDir.exists()) await vaultDir.create(recursive: true);
               
               final destPath = '${vaultDir.path}/$filename';
               await backupFile.copy(destPath);
               
               debugPrint('✨ [VAULT_TRACE] SELF-HEALING SUCCESS: Restored to $destPath');
               return destPath;
               
          } else {
               debugPrint('💀 [VAULT_TRACE] FATAL: File not found in backup mirror.');
          }
      } catch (e) {
          debugPrint('❌ [VAULT_TRACE] Self-Healing Error: $e');
      }
      
      debugPrint('🛑 [VAULT_TRACE] FAILED. Returning original path.');
      return filePath; // Return original (it will fail to load, triggering UI placeholder)
  }
  
  Future<Directory> _getPublicBackupRoot() async {
      // Use external storage or documents based on platform
      // For this environment (likely Android emulator or device), we use generic documents.
      
      Directory? root;
      if (Platform.isAndroid) {
          root = await getExternalStorageDirectory(); // Android/data/package...
          // Try to go up/out if possible, but safe default is App External
      }
      
      if (root == null) {
          root = await getApplicationDocumentsDirectory();
      }
      
      final backup = Directory('${root.path}/ScanNut_Safe_Backup'); // Updated as per "Intervention" prompt
      if (!await backup.exists()) await backup.create();
      return backup;
  }

  Future<Directory> _getPublicBackupDir(String category, [String? subFolder]) async {
      final root = await _getPublicBackupRoot();
      String pathStr = '${root.path}/$category';
      if (subFolder != null) pathStr += '/$subFolder';
      
      final d = Directory(pathStr);
      if (!await d.exists()) await d.create(recursive: true);
      return d;
  }

  Future<void> ignoreErrors(Future<void> Function() action) async {
      try { await action(); } catch (_) {}
  }

  /// 🧹 DANGER ZONE: Clears all files in a specific vault category
  Future<void> clearDomain(String category) async {
       final appDir = await getApplicationSupportDirectory();
       final dir = Directory('${appDir.path}/$VAULT_ROOT/$category');
       if (await dir.exists()) {
           try {
              await dir.delete(recursive: true);
              debugPrint('💣 [Vault] Deleted domain: $category');
           } catch (e) {
              debugPrint('⚠️ [Vault] Error deleting domain $category: $e');
           }
       }
       // Re-create immediately to avoid errors
       await dir.create(recursive: true);
  }

  /// Checks if a path is theoretically secure (inside vault)
  bool isPathSecure(String filePath) {
      return filePath.contains(VAULT_ROOT) && !filePath.contains('cache');
  }
}

