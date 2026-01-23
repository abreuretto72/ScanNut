import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'media_vault_service.dart';

/// Service for uploading and managing medical document files
class FileUploadService {
  final ImagePicker _imagePicker = ImagePicker();

  /// Pick image from camera
  Future<File?> pickFromCamera() async {
    try {
      /* Permission check removed - managed by image_picker or manifest */

      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (photo != null) {
        return File(photo.path);
      }
    } catch (e) {
      debugPrint('❌ Error picking from camera: $e');
    }
    return null;
  }

  /// Pick image from gallery
  Future<File?> pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        return File(image.path);
      }
    } catch (e) {
      debugPrint('❌ Error picking from gallery: $e');
    }
    return null;
  }

  /// Pick video from camera
  Future<File?> pickVideoFromCamera() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 2),
      );

      if (video != null) {
        return File(video.path);
      }
    } catch (e) {
      debugPrint('❌ Error picking video from camera: $e');
    }
    return null;
  }

  /// Pick video from gallery
  Future<File?> pickVideoFromGallery() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );

      if (video != null) {
        return File(video.path);
      }
    } catch (e) {
      debugPrint('❌ Error picking video from gallery: $e');
    }
    return null;
  }

  /// Pick PDF file
  Future<File?> pickPdfFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.first.path;
        if (filePath != null) {
          return File(filePath);
        }
      }
    } catch (e) {
      debugPrint('❌ Error picking PDF: $e');
    }
    return null;
  }

  /// Pick image, optimize and return file
  Future<File?> pickAndOptimizeImage({required ImageSource source}) async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: source,
        imageQuality: 70, // 🛡️ V_FIX: Enforce compression for storage efficiency
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (photo != null) {
        return File(photo.path);
      }
    } catch (e) {
      debugPrint('❌ Error picking and optimizing image: $e');
    }
    return null;
  }

  /// MEDIA ARCHIVIST: Securely save document to Media Vault
  Future<String?> saveMedicalDocument({
    required File file,
    required String petName,
    required String attachmentType,
    bool skipIndexing = false,
  }) async {
    try {
      final vault = MediaVaultService();
      
      // 🛡️ V124: Fix category selection
      // All pet-related attachments (including health) go to PETS_DIR
      // Only standalone wound analysis goes to WOUNDS_DIR
      String category = MediaVaultService.PETS_DIR;
      if (attachmentType.contains('food')) {
        category = MediaVaultService.FOOD_DIR;
      } else if (attachmentType.contains('plant')) {
        category = MediaVaultService.BOTANY_DIR;
      } else if (attachmentType.startsWith('travel_')) {
        // 🛡️ V_FIX: Travel documents categorized for later bulk treatment if needed
        category = MediaVaultService.PETS_DIR; 
      }
      // Note: health_prescriptions, health_vaccines, etc. stay in PETS_DIR

      // 🛡️ V119: Add type prefix to filename for proper filtering
      final originalName = path.basename(file.path);
      final extension = path.extension(originalName);
      final nameWithoutExt = path.basenameWithoutExtension(originalName);
      final prefixedName = '${attachmentType}_$nameWithoutExt$extension';
      
      // Create temporary file with prefixed name
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$prefixedName');
      await file.copy(tempFile.path);
      
      debugPrint('📎 [V124] Prefixed filename: $prefixedName (type: $attachmentType, category: $category)');

      final result = await vault.secureClone(
        tempFile, 
        category, 
        petName.replaceAll(RegExp(r'\s+'), '_').toLowerCase(),
        skipIndexing
      );
      
      // Clean up temp file
      try {
        await tempFile.delete();
      } catch (e) {
        debugPrint('⚠️ Failed to delete temp file: $e');
      }
      
      return result;
    } catch (e) {
      debugPrint('❌ MediaVault Error: $e');
      return null;
    }
  }

  /// Backup legacy save (for fallback)
  Future<String?> _legacySaveMedicalDocument(File file, String petName, String attachmentType) async {
       // ... simplified legacy logic or just fail safely
       try {
          final appDir = await getApplicationDocumentsDirectory();
          final dir = Directory('${appDir.path}/medical_docs/$petName');
          if (!await dir.exists()) await dir.create(recursive: true);
          final newPath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}_legacy_${path.basename(file.path)}';
          await file.copy(newPath);
          return newPath;
       } catch (e) {
          return null;
       }
  }

  /// Get all medical documents (Vault + Legacy)
  Future<List<File>> getMedicalDocuments(String petName) async {
    List<File> allFiles = [];
    try {
      // 1. Check Vault
      final appDir = await getApplicationSupportDirectory();
      final safePetName = petName.replaceAll(RegExp(r'\s+'), '_').toLowerCase();
      final vaultDir = Directory('${appDir.path}/media_vault/pets/$safePetName');
      
      if (await vaultDir.exists()) {
        allFiles.addAll(vaultDir.listSync().whereType<File>());
      }

      // 2. Check Legacy (Documents)
      final docDir = await getApplicationDocumentsDirectory();
      final legacyDir = Directory('${docDir.path}/medical_docs/$petName');
      if (await legacyDir.exists()) {
         allFiles.addAll(legacyDir.listSync().whereType<File>());
      }
      
    } catch (e) {
      debugPrint('❌ Error getting vault/legacy documents: $e');
    }
    return allFiles;
  }

  /// Delete medical document
  Future<bool> deleteMedicalDocument(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('🗑️ File deleted: $filePath');
        return true;
      }
    } catch (e) {
      debugPrint('❌ Error deleting file: $e');
    }
    return false;
  }

  /// Save image for food or plant analysis to Vault
  Future<String?> saveAnalysisImage({
    required File file,
    required String type, // 'food' or 'plant'
    required String name,
  }) async {
    try {
      final appDir = await getApplicationSupportDirectory();
      final category = type == 'food' ? 'food' : 'plants';
      final vaultDir = Directory('${appDir.path}/media_vault/$category');
      
      if (!await vaultDir.exists()) {
        await vaultDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(file.path);
      final safeName = name.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
      final fileName = '${safeName}_$timestamp$extension';
      final newPath = '${vaultDir.path}/$fileName';

      final savedFile = await file.copy(newPath);
      debugPrint('🔐 MediaVault: Securely archived $type image at $newPath');
      
      return savedFile.path;
    } catch (e) {
      debugPrint('❌ MediaVault Analysis Error: $e');
      return null;
    }
  }

  /// Cleanup temporary images from picker
  Future<void> cleanupTemporaryCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        final List<FileSystemEntity> entities = tempDir.listSync();
        int deletedCount = 0;
        
        for (var entity in entities) {
          if (entity is File) {
            final fileName = path.basename(entity.path);
            if (fileName.contains('image_picker') || fileName.contains('scaled_') || 
                ((fileName.endsWith('.jpg') || fileName.endsWith('.png')) && !fileName.contains('vault'))) {
              final stat = await entity.stat();
              if (DateTime.now().difference(stat.modified).inMinutes > 30) {
                await entity.delete();
                deletedCount++;
              }
            }
          }
        }
        debugPrint('🧹 Cache Cleanup: $deletedCount temporary files removed.');
      }
    } catch (e) {
      debugPrint('⚠️ Cache Cleanup Warning: $e');
    }
  }
}
