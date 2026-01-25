import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

enum LogLevel { info, warning, error, debug }

class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  static const int _maxLogs = 1000;
  final List<String> _logs = [];
  bool _developerMode = kDebugMode;

  bool get developerMode => _developerMode;
  void setDeveloperMode(bool value) => _developerMode = value;

  List<String> get logs => List.unmodifiable(_logs);

  void info(String message) => _log(LogLevel.info, message);
  void warning(String message) => _log(LogLevel.warning, message);
  void error(String message, {dynamic error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, error: error, stackTrace: stackTrace);
  }

  void debug(String message) => _log(LogLevel.debug, message);

  void _log(LogLevel level, String message,
      {dynamic error, StackTrace? stackTrace}) {
    final timestamp = DateTime.now().toIso8601String();
    final prefix = level.toString().split('.').last.toUpperCase();

    // Mask sensitive info (very basic implementation)
    final maskedMessage = _maskSecrets(message);

    final logEntry = '[$timestamp] [$prefix] $maskedMessage';

    if (_logs.length >= _maxLogs) {
      _logs.removeAt(0);
    }
    _logs.add(logEntry);

    if (error != null) {
      _logs.add('   Error: $error');
    }
    if (stackTrace != null) {
      _logs.add('   StackTrace: $stackTrace');
    }

    if (developerMode) {
      debugPrint(logEntry);
      if (error != null) debugPrint('   Error: $error');
      // Stacktrace usually too long for debugPrint in some consoles
    }
  }

  String _maskSecrets(String message) {
    // Mask potential tokens/keys
    return message
        .replaceAll(RegExp(r'AIza[0-9A-Za-z-_]{35}'), 'AIza...[MASKED]')
        .replaceAll(RegExp(r'ya29\.[0-9A-Za-z-_]+'), 'ya29...[MASKED]');
  }

  void clearLogs() {
    _logs.clear();
  }

  Future<void> exportLogs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/app_logs.txt');
      await file.writeAsString(_logs.join('\n'));
      info('Logs exported to ${file.path}');
    } catch (e) {
      error('Failed to export logs', error: e);
    }
  }

  String getLogsAsString() {
    return _logs.join('\n');
  }
}

final logger = AppLogger();
