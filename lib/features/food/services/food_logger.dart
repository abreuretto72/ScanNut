import 'package:flutter/foundation.dart';

class FoodLogger {
  static final FoodLogger _instance = FoodLogger._internal();
  factory FoodLogger() => _instance;
  FoodLogger._internal();

  static const String TAG = '[FoodMicroApp]';

  void logInfo(String event, {Map<String, dynamic>? data}) {
    if (kDebugMode) {
      debugPrint('ℹ️ $TAG INFO: $event | Data: $data');
    }
  }

  void logDebug(String event, {Map<String, dynamic>? data}) {
    if (kDebugMode) {
      debugPrint('🐛 $TAG DEBUG: $event | Data: $data');
    }
  }

  void logError(String event, {dynamic error, StackTrace? stackTrace}) {
    debugPrint('❌ $TAG ERROR: $event');
    if (error != null) debugPrint('   Caused by: $error');
    if (stackTrace != null) debugPrint('   Stack Trace: $stackTrace');
  }

  void logCritical(String event, {dynamic error}) {
    debugPrint('🚨 $TAG CRITICAL: $event');
    if (error != null) debugPrint('   FATAL ERROR: $error');
  }

  // Specialized Traces
  void traceRecipeGenerationValues(String foodName, int requestedQty) {
    logInfo('recipe_generation_start', data: {
      'food_target': foodName,
      'requested_qty': requestedQty,
      'timestamp': DateTime.now().toIso8601String()
    });
  }

  void traceHiveAppend(String boxName, String key, bool success) {
    if (success) {
      logInfo('hive_save_success', data: {'box': boxName, 'key': key});
    } else {
      logError('hive_save_failed', error: 'Failed to write to box $boxName at key $key');
    }
  }
}
