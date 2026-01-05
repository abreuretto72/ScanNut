import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'app_logger.dart';

class AuthTraceLogger {
  static final AuthTraceLogger _instance = AuthTraceLogger._internal();
  factory AuthTraceLogger() => _instance;
  AuthTraceLogger._internal();

  final Map<String, DateTime> _steps = {};
  final List<String> _trace = [];

  void startStep(String stepName) {
    _steps[stepName] = DateTime.now();
    final message = '[TRACE] START: $stepName';
    _trace.add('${DateTime.now().toIso8601String()} $message');
    logger.info(message);
  }

  void endStep(String stepName, {bool success = true, String? details}) {
    if (!_steps.containsKey(stepName)) return;

    final start = _steps[stepName]!;
    final duration = DateTime.now().difference(start);
    final status = success ? 'SUCCESS' : 'FAILED';
    final message = '[TRACE] END: $stepName | Status: $status | Duration: ${duration.inMilliseconds}ms${details != null ? " | Details: $details" : ""}';
    
    _trace.add('${DateTime.now().toIso8601String()} $message');
    if (success) {
      logger.info(message);
    } else {
      logger.error(message);
    }
  }

  void addLog(String message) {
    _trace.add('${DateTime.now().toIso8601String()} [LOG] $message');
    logger.debug(message);
  }

  Future<void> saveTraceToFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logsDir = Directory('${directory.path}/logs');
      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${logsDir.path}/auth_trace_$timestamp.txt');
      await file.writeAsString(_trace.join('\n'));
      logger.info('Auth trace saved to ${file.path}');
    } catch (e) {
      logger.error('Failed to save auth trace', error: e);
    }
  }

  String getTraceAsString() => _trace.join('\n');
  
  void clearTrace() {
    _steps.clear();
    _trace.clear();
  }
}

final authTrace = AuthTraceLogger();
