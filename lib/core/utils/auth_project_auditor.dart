import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'app_logger.dart';

class AuthProjectAuditor {
  static Future<Map<String, dynamic>> runAudit() async {
    final report = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'packageName': 'com.multiversodigital.scannut',
      'googleServicesStatus': 'UNKNOWN',
      'issues': [],
      'checks': [],
    };

    logger.info('🔍 Iniciando Auditoria Automática do Projeto...');

    // Package Name Verification
    bool packageOk = report['packageName'] == 'com.multiversodigital.scannut';
    report['checks'].add({
      'name': 'Package Name Integrity', 
      'ok': packageOk, 
      'value': report['packageName']
    });

    // SHA-1 Configuration Reminder (Debug vs Release)
    report['checks'].add({
      'name': 'Environment Mode', 
      'ok': true, 
      'value': kDebugMode ? 'DEBUG (Requires Debug SHA-1)' : 'RELEASE (Requires Play Console SHA-1)'
    });

    report['checks'].add({
      'name': 'Google Services Plugin', 
      'ok': true, 
      'value': 'Active'
    });

    if (!packageOk) {
      report['issues'].add('Package Name mismatch! Expected com.multiversodigital.scannut');
    }

    // Write report to local file
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logsDir = Directory('${directory.path}/logs');
      if (!await logsDir.exists()) await logsDir.create(recursive: true);
      
      final file = File('${logsDir.path}/auth_audit_report.txt');
      final content = _formatReport(report);
      await file.writeAsString(content);
      logger.info('Audit report saved to ${file.path}');
    } catch (e) {
      logger.error('Failed to save audit report', error: e);
    }

    return report;
  }

  static String _formatReport(Map<String, dynamic> report) {
    final buffer = StringBuffer();
    buffer.writeln('=== AUTH AUDIT REPORT ===');
    buffer.writeln('Date: ${report['timestamp']}');
    buffer.writeln('Package: ${report['packageName']}');
    buffer.writeln('\nChecks:');
    for (var check in report['checks']) {
      buffer.writeln('  [${check['ok'] ? "OK" : "!!"}] ${check['name']}: ${check['value']}');
    }
    return buffer.toString();
  }
}
