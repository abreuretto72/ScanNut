import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// 🛡️ V70.1: IMAGE OPTIMIZATION SERVICE FOR PDF GENERATION
/// Prevents memory crashes by downsampling images before PDF rendering
class ImageOptimizationService {
  static final ImageOptimizationService _instance =
      ImageOptimizationService._internal();
  factory ImageOptimizationService() => _instance;
  ImageOptimizationService._internal();

  // Configuration
  static const int maxImageWidth = 800;
  static const int maxImageHeight = 800;
  static const int jpegQuality = 70; // 70% quality = good visual + 90% smaller

  /// Optimize image for PDF rendering
  /// Returns optimized file path or null if optimization fails
  Future<File?> optimizeForPDF({
    required String originalPath,
    String? customName,
  }) async {
    try {
      debugPrint(
          '🔄 [V70.1-IMG] Optimizing image: ${path.basename(originalPath)}');

      final originalFile = File(originalPath);
      if (!await originalFile.exists()) {
        debugPrint('⚠️ [V70.1-IMG] Original file not found: $originalPath');
        return null;
      }

      // Get original file size
      final originalSize = await originalFile.length();
      debugPrint(
          '📊 [V70.1-IMG] Original size: ${(originalSize / 1024 / 1024).toStringAsFixed(2)} MB');

      // Create temp directory for optimized images
      final tempDir = await getTemporaryDirectory();
      final optimizedDir = Directory('${tempDir.path}/pdf_optimized');
      if (!await optimizedDir.exists()) {
        await optimizedDir.create(recursive: true);
      }

      // Generate output path
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = customName ?? 'optimized_$timestamp.jpg';
      final outputPath = '${optimizedDir.path}/$fileName';

      // Compress and resize image
      final result = await FlutterImageCompress.compressAndGetFile(
        originalPath,
        outputPath,
        quality: jpegQuality,
        minWidth: maxImageWidth,
        minHeight: maxImageHeight,
        format: CompressFormat.jpeg,
      );

      if (result == null) {
        debugPrint('❌ [V70.1-IMG] Compression failed');
        return null;
      }

      // Get optimized file size
      final optimizedSize = await result.length();
      final reduction =
          ((1 - (optimizedSize / originalSize)) * 100).toStringAsFixed(1);

      debugPrint(
          '✅ [V70.1-IMG] Optimized size: ${(optimizedSize / 1024).toStringAsFixed(2)} KB');
      debugPrint('📉 [V70.1-IMG] Size reduction: $reduction%');

      return File(result.path);
    } catch (e) {
      debugPrint('❌ [V70.1-IMG] Error optimizing image: $e');
      return null;
    }
  }

  /// Optimize multiple images in batch
  /// Returns map of original path -> optimized path
  Future<Map<String, String>> optimizeBatch({
    required List<String> imagePaths,
    Function(int current, int total)? onProgress,
  }) async {
    debugPrint(
        '🔄 [V70.1-IMG] Starting batch optimization: ${imagePaths.length} images');

    final Map<String, String> optimizedPaths = {};
    int processed = 0;

    for (final originalPath in imagePaths) {
      processed++;
      onProgress?.call(processed, imagePaths.length);

      final optimized = await optimizeForPDF(
        originalPath: originalPath,
        customName:
            'batch_${processed}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      if (optimized != null) {
        optimizedPaths[originalPath] = optimized.path;
      } else {
        debugPrint(
            '⚠️ [V70.1-IMG] Skipping failed optimization: $originalPath');
      }
    }

    debugPrint(
        '✅ [V70.1-IMG] Batch complete: ${optimizedPaths.length}/${imagePaths.length} successful');
    return optimizedPaths;
  }

  /// Load optimized image as bytes for PDF
  /// Includes automatic memory cleanup
  Future<Uint8List?> loadOptimizedBytes({
    required String originalPath,
    bool autoCleanup = true,
  }) async {
    try {
      // Optimize first
      final optimized = await optimizeForPDF(originalPath: originalPath);
      if (optimized == null) {
        debugPrint('⚠️ [V70.1-IMG] Using original file (optimization failed)');
        final original = File(originalPath);
        if (await original.exists()) {
          return await original.readAsBytes();
        }
        return null;
      }

      // Read optimized bytes
      final bytes = await optimized.readAsBytes();

      // V70.1: GARBAGE COLLECTION - Force memory cleanup
      if (autoCleanup) {
        await _forceMemoryCleanup();
      }

      // Delete temp file
      try {
        await optimized.delete();
      } catch (e) {
        debugPrint('⚠️ [V70.1-IMG] Could not delete temp file: $e');
      }

      return bytes;
    } catch (e) {
      debugPrint('❌ [V70.1-IMG] Error loading optimized bytes: $e');
      return null;
    }
  }

  /// Force garbage collection and clear image cache
  Future<void> _forceMemoryCleanup() async {
    try {
      // Clear Flutter's image cache
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      debugPrint('🧹 [V70.1-IMG] Memory cleanup executed');
    } catch (e) {
      debugPrint('⚠️ [V70.1-IMG] Memory cleanup warning: $e');
    }
  }

  /// Clean up all temporary optimized images
  Future<void> cleanupTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final optimizedDir = Directory('${tempDir.path}/pdf_optimized');

      if (await optimizedDir.exists()) {
        await optimizedDir.delete(recursive: true);
        debugPrint('🧹 [V70.1-IMG] Cleaned up temp optimized images');
      }
    } catch (e) {
      debugPrint('⚠️ [V70.1-IMG] Cleanup warning: $e');
    }
  }

  /// Get placeholder image bytes for corrupted/missing files
  Uint8List getPlaceholderBytes() {
    // Simple 1x1 transparent pixel as placeholder
    // In production, you could use a proper "image not found" icon
    return Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1 dimensions
      0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
      0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
      0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
      0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
      0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
      0x42, 0x60, 0x82,
    ]);
  }

  /// Estimate memory usage for image list
  Future<double> estimateMemoryUsageMB(List<String> imagePaths) async {
    double totalMB = 0;

    for (final imagePath in imagePaths) {
      try {
        final file = File(imagePath);
        if (await file.exists()) {
          final sizeBytes = await file.length();
          totalMB += sizeBytes / 1024 / 1024;
        }
      } catch (e) {
        // Skip
      }
    }

    return totalMB;
  }
}

// Global singleton instance
final imageOptimizer = ImageOptimizationService();
