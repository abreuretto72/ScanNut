import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

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

  /// Save file to app's medical documents directory
  Future<String?> saveMedicalDocument({
    required File file,
    required String petName,
    required String attachmentType,
  }) async {
    try {
      // Get app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final medicalDocsDir = Directory('${appDir.path}/medical_docs/$petName');
      
      // Create directory if doesn't exist
      if (!await medicalDocsDir.exists()) {
        await medicalDocsDir.create(recursive: true);
      }

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(file.path);
      final newFileName = '${attachmentType}_${timestamp}$extension';
      final newPath = '${medicalDocsDir.path}/$newFileName';

      // Copy file
      final savedFile = await file.copy(newPath);
      debugPrint('✅ Medical document saved: $newPath');
      
      return savedFile.path;
    } catch (e) {
      debugPrint('❌ Error saving medical document: $e');
      return null;
    }
  }

  /// Get all medical documents for a pet
  Future<List<File>> getMedicalDocuments(String petName) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final medicalDocsDir = Directory('${appDir.path}/medical_docs/$petName');
      
      if (await medicalDocsDir.exists()) {
        return medicalDocsDir
            .listSync()
            .whereType<File>()
            .toList();
      }
    } catch (e) {
      debugPrint('❌ Error getting medical documents: $e');
    }
    return [];
  }

  /// Delete medical document
  Future<bool> deleteMedicalDocument(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('✅ Medical document deleted: $filePath');
        return true;
      }
    } catch (e) {
      debugPrint('❌ Error deleting medical document: $e');
    }
    return false;
  }

  /// Save image for food or plant analysis
  Future<String?> saveAnalysisImage({
    required File file,
    required String type, // 'food' or 'plant'
    required String name,
  }) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final subDir = type == 'food' ? 'nutrition_images' : 'botany_images';
      final dir = Directory('${appDir.path}/$subDir');
      
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(file.path);
      final fileName = '${name.replaceAll(' ', '_')}_$timestamp$extension';
      final newPath = '${dir.path}/$fileName';

      final savedFile = await file.copy(newPath);
      debugPrint('✅ Analysis image saved: $newPath');
      
      return savedFile.path;
    } catch (e) {
      debugPrint('❌ Error saving analysis image: $e');
      return null;
    }
  }

  /// Cleanup temporary images from picker that were not saved
  Future<void> cleanupTemporaryCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        final List<FileSystemEntity> entities = tempDir.listSync();
        int deletedCount = 0;
        
        for (var entity in entities) {
          if (entity is File) {
            final fileName = path.basename(entity.path);
            // image_picker files usually start with 'image_picker' or 'scaled_'
            if (fileName.contains('image_picker') || fileName.contains('scaled_') || fileName.endsWith('.jpg') || fileName.endsWith('.png')) {
              // Only delete if older than 30 minutes to avoid deleting a currently being processed image
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
