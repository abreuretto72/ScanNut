import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import '../../../core/utils/auth_trace_logger.dart';
import '../../../core/utils/auth_project_auditor.dart';

class AuthCertificatesScreen extends StatefulWidget {
  const AuthCertificatesScreen({super.key});

  @override
  State<AuthCertificatesScreen> createState() => _AuthCertificatesScreenState();
}

class _AuthCertificatesScreenState extends State<AuthCertificatesScreen> {
  Map<String, dynamic>? _auditResults;
  bool _isAuditing = false;

  @override
  void initState() {
    super.initState();
    _runAudit();
  }

  Future<void> _runAudit() async {
    setState(() => _isAuditing = true);
    final results = await AuthProjectAuditor.runAudit();
    setState(() {
      _auditResults = results;
      _isAuditing = false;
    });
  }

  void _copyCommand(String cmd) {
    Clipboard.setData(ClipboardData(text: cmd));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Comando copiado!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
        title: Text('Diagnóstico > Certificados', style: GoogleFonts.poppins()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildInfoSection(),
          const SizedBox(height: 24),
          _buildAuditSection(),
          const SizedBox(height: 24),
          _buildInstructionSection(),
          const SizedBox(height: 24),
          _buildTraceSection(),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRow('Package Name:', 'com.multiversodigital.scannut'),
          _buildRow('Build Type:', kDebugMode ? 'DEBUG' : 'RELEASE'),
          _buildRow('Device:', defaultTargetPlatform.toString().split('.').last),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
          Text(value, style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAuditSection() {
    if (_isAuditing) return const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Relatório de Auditoria', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (_auditResults != null)
          ...(_auditResults!['checks'] as List).map((check) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: check['ok'] ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: check['ok'] ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(check['ok'] ? Icons.check_circle : Icons.error, color: check['ok'] ? Colors.green : Colors.red, size: 16),
                const SizedBox(width: 12),
                Expanded(child: Text(check['name'], style: GoogleFonts.poppins(color: Colors.white, fontSize: 13))),
                Text(check['value'], style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11)),
              ],
            ),
          )),
      ],
    );
  }

  Widget _buildInstructionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text('Instruções SHA-1', style: GoogleFonts.poppins(color: Colors.amber, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Para obter os certificados oficiais do seu ambiente, execute no terminal:',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'cd android && ./gradlew signingReport',
                    style: GoogleFonts.robotoMono(color: Colors.greenAccent, fontSize: 11),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, color: Colors.white54, size: 18),
                  onPressed: () => _copyCommand('cd android && ./gradlew signingReport'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '⚠️ Registre os certificados SHA-1 e SHA-256 no Firebase e no Google Cloud Console para evitar erros "10" e "12500".',
            style: GoogleFonts.poppins(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTraceSection() {
    final trace = authTrace.getTraceAsString();
    if (trace.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Último Trace de Auth', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
            TextButton(onPressed: () => setState(() => authTrace.clearTrace()), child: const Text('Limpar')),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.grey.shade900, borderRadius: BorderRadius.circular(12)),
          height: 250,
          child: SingleChildScrollView(
            child: Text(trace, style: GoogleFonts.robotoMono(color: Colors.white70, fontSize: 10)),
          ),
        ),
      ],
    );
  }
}
