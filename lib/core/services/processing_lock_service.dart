import 'package:flutter/foundation.dart';

/// 🛡️ V70: ATOMIC PROCESSING LOCK SERVICE
/// Prevents multiple simultaneous operations that could cause UI/Hive conflicts
class ProcessingLockService {
  static final ProcessingLockService _instance = ProcessingLockService._internal();
  factory ProcessingLockService() => _instance;
  ProcessingLockService._internal();

  // Lock flags for different operation types
  bool _isProcessingAI = false;
  bool _isProcessingPDF = false;
  bool _isProcessingHive = false;
  bool _isProcessingImage = false;

  // Getters
  bool get isProcessingAI => _isProcessingAI;
  bool get isProcessingPDF => _isProcessingPDF;
  bool get isProcessingHive => _isProcessingHive;
  bool get isProcessingImage => _isProcessingImage;
  bool get isAnyProcessing => _isProcessingAI || _isProcessingPDF || _isProcessingHive || _isProcessingImage;

  /// Lock AI processing
  bool lockAI() {
    if (_isProcessingAI) {
      debugPrint('⚠️ [V70-LOCK] AI processing already in progress. Ignoring request.');
      return false;
    }
    _isProcessingAI = true;
    debugPrint('🔒 [V70-LOCK] Step 1: AI Processing LOCKED');
    return true;
  }

  /// Unlock AI processing
  void unlockAI() {
    _isProcessingAI = false;
    debugPrint('🔓 [V70-LOCK] Step 4: AI Processing UNLOCKED');
  }

  /// Lock PDF generation
  bool lockPDF() {
    if (_isProcessingPDF) {
      debugPrint('⚠️ [V70-LOCK] PDF generation already in progress. Ignoring request.');
      return false;
    }
    _isProcessingPDF = true;
    debugPrint('🔒 [V70-LOCK] Step 1: PDF Generation LOCKED');
    return true;
  }

  /// Unlock PDF generation
  void unlockPDF() {
    _isProcessingPDF = false;
    debugPrint('🔓 [V70-LOCK] Step 4: PDF Generation UNLOCKED');
  }

  /// Lock Hive operations
  bool lockHive() {
    if (_isProcessingHive) {
      debugPrint('⚠️ [V70-LOCK] Hive operation already in progress. Ignoring request.');
      return false;
    }
    _isProcessingHive = true;
    debugPrint('🔒 [V70-LOCK] Step 1: Hive Operation LOCKED');
    return true;
  }

  /// Unlock Hive operations
  void unlockHive() {
    _isProcessingHive = false;
    debugPrint('🔓 [V70-LOCK] Step 4: Hive Operation UNLOCKED');
  }

  /// Lock Image processing
  bool lockImage() {
    if (_isProcessingImage) {
      debugPrint('⚠️ [V70-LOCK] Image processing already in progress. Ignoring request.');
      return false;
    }
    _isProcessingImage = true;
    debugPrint('🔒 [V70-LOCK] Step 1: Image Processing LOCKED');
    return true;
  }

  /// Unlock Image processing
  void unlockImage() {
    _isProcessingImage = false;
    debugPrint('🔓 [V70-LOCK] Step 4: Image Processing UNLOCKED');
  }

  /// Emergency unlock all (use only in error handlers)
  void unlockAll() {
    _isProcessingAI = false;
    _isProcessingPDF = false;
    _isProcessingHive = false;
    _isProcessingImage = false;
    debugPrint('🚨 [V70-LOCK] EMERGENCY: All locks released');
  }

  /// Execute operation with automatic lock/unlock
  Future<T?> executeWithLock<T>({
    required String operationType,
    required Future<T> Function() operation,
  }) async {
    bool locked = false;
    
    try {
      // Acquire lock based on operation type
      switch (operationType.toLowerCase()) {
        case 'ai':
          locked = lockAI();
          break;
        case 'pdf':
          locked = lockPDF();
          break;
        case 'hive':
          locked = lockHive();
          break;
        case 'image':
          locked = lockImage();
          break;
        default:
          debugPrint('⚠️ [V70-LOCK] Unknown operation type: $operationType');
          return null;
      }

      if (!locked) return null;

      debugPrint('🔄 [V70-LOCK] Step 2: Executing $operationType operation...');
      final result = await operation();
      debugPrint('✅ [V70-LOCK] Step 3: $operationType operation completed successfully');
      
      return result;
    } catch (e) {
      debugPrint('❌ [V70-LOCK] Error in $operationType operation: $e');
      rethrow;
    } finally {
      // Always unlock, even if operation fails
      if (locked) {
        switch (operationType.toLowerCase()) {
          case 'ai':
            unlockAI();
            break;
          case 'pdf':
            unlockPDF();
            break;
          case 'hive':
            unlockHive();
            break;
          case 'image':
            unlockImage();
            break;
        }
      }
    }
  }
}

// Global singleton instance
final processingLock = ProcessingLockService();
