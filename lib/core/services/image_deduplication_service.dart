import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'hive_atomic_manager.dart';

/// 🛡️ V180: IMAGE DEDUPLICATION SERVICE
/// Uses SHA-256 hashing to prevent redundant analysis of the same image.
class ImageDeduplicationService {
  static const String boxName = 'processed_images_box';

  static final ImageDeduplicationService _instance =
      ImageDeduplicationService._internal();
  factory ImageDeduplicationService() => _instance;
  ImageDeduplicationService._internal();

  Box? _box;

  /// Initialize and ensure box is open
  Future<void> _init() async {
    if (_box != null && _box!.isOpen) return;
    try {
      _box = await HiveAtomicManager().ensureBoxOpen(boxName);
    } catch (e) {
      debugPrint('☢️ [DEDUPLICATION] Error opening box: $e. Recreating...');
      await HiveAtomicManager().recreateBox(boxName);
      _box = await Hive.openBox(boxName);
    }
  }

  /// Generates a SHA-256 hash from image bytes
  Future<String> calculateHash(File imageFile) async {
    try {
      final Uint8List bytes = await imageFile.readAsBytes();

      // Use compute for large files to avoid UI jank if not on web
      if (!kIsWeb && bytes.length > 1024 * 1024) {
        // > 1MB
        return await compute(_generateHash, bytes);
      }

      return _generateHash(bytes);
    } catch (e) {
      debugPrint('❌ [DEDUPLICATION] Hash calculation failed: $e');
      return '';
    }
  }

  static String _generateHash(Uint8List bytes) {
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Checks if an image hash already exists in history
  /// Returns the associated data (metadata) if found, otherwise null.
  Future<Map<String, dynamic>?> checkDeduplication(String hash) async {
    if (hash.isEmpty) return null;
    await _init();

    final result = _box?.get(hash);
    if (result != null) {
      debugPrint('🎯 [DEDUPLICATION] Match found for hash: $hash');
      return Map<String, dynamic>.from(result as Map);
    }
    return null;
  }

  /// Records a processed image hash with metadata
  Future<void> registerProcessedImage({
    required String hash,
    required String type, // 'pet_health', 'pet_food', 'human_food', 'botany'
    String? petId,
    String? petName,
    Map<String, dynamic>? extraMetadata,
  }) async {
    if (hash.isEmpty) return;
    await _init();

    final entry = {
      'timestamp': DateTime.now().toIso8601String(),
      'type': type,
      'petId': petId,
      'petName': petName,
      ...?extraMetadata,
    };

    await _box!.put(hash, entry);
    await _box!.flush();
    debugPrint('💾 [DEDUPLICATION] Recorded new hash: $hash ($type)');
  }

  /// Clears the deduplication history (Danger Zone)
  Future<void> clearHistory() async {
    await _init();
    await _box!.clear();
    debugPrint('🗑️ [DEDUPLICATION] History cleared.');
  }
}
