import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/app_logger.dart';
import '../../../l10n/app_localizations.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  Map<String, dynamic>? _diagnosticResults;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    logger.setDeveloperMode(true);
  }

  Future<void> _runTests() async {
    setState(() => _isRunning = true);

    final results = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'steps': [],
    };

    try {
      final connectivity = await InternetAddress.lookup('google.com');
      results['steps'].add({
        'name': 'Conectividade',
        'success': connectivity.isNotEmpty,
        'detail': connectivity.isNotEmpty
            ? 'Conectado a google.com'
            : 'Sem acesso a google.com',
      });
    } catch (e) {
      results['steps'].add({
        'name': 'Conectividade',
        'success': false,
        'detail': 'Erro de rede: $e',
      });
    }

    setState(() {
      _diagnosticResults = results;
      _isRunning = false;
    });
  }

  void _copyLogs() {
    Clipboard.setData(ClipboardData(text: logger.getLogsAsString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Logs copiados para a área de transferência')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
        title: Text('Diagnóstico Técnico', style: GoogleFonts.poppins()),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyLogs,
            tooltip: 'Copiar Logs',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildInfoCard(),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isRunning ? null : _runTests,
            icon: const Icon(Icons.play_arrow),
            label: Text('Executar Testes de Conectividade',
                style: GoogleFonts.poppins()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E676).withValues(alpha: 0.2),
              foregroundColor: const Color(0xFF00E676),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 24),
          if (_isRunning)
            const Center(
                child: CircularProgressIndicator(color: Color(0xFF00E676)))
          else if (_diagnosticResults != null)
            _buildResultsList(),
          const SizedBox(height: 32),
          Text(
            'Timeline de Logs:',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildLogsView(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Package:', 'com.multiversodigital.scannut'),
          _buildInfoRow('Build Type:', kDebugMode ? 'DEBUG' : 'RELEASE'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(value,
                  style:
                      GoogleFonts.poppins(color: Colors.white, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    final steps = _diagnosticResults!['steps'] as List;
    return Column(
      children: steps.map<Widget>((step) {
        final success = step['success'] as bool;
        return ListTile(
          leading: Icon(
            success ? Icons.check_circle : Icons.error,
            color: success ? Colors.green : Colors.red,
          ),
          title: Text(step['name'],
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
          subtitle: Text(step['detail'],
              style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12)),
        );
      }).toList(),
    );
  }

  Widget _buildLogsView() {
    final logs = logger.logs.reversed.toList();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      constraints: const BoxConstraints(maxHeight: 400),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: logs.length,
        itemBuilder: (context, index) {
          final log = logs[index];
          Color textColor = Colors.white70;
          if (log.contains('[ERROR]')) textColor = Colors.redAccent;
          if (log.contains('[WARNING]')) textColor = Colors.orangeAccent;
          if (log.contains('[DEBUG]')) textColor = Colors.blueAccent;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              log,
              style: GoogleFonts.robotoMono(fontSize: 10, color: textColor),
            ),
          );
        },
      ),
    );
  }
}
