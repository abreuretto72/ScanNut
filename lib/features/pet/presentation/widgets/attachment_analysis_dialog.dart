import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../l10n/app_localizations.dart';

class AttachmentAnalysisDialog extends StatelessWidget {
  final String jsonString;

  const AttachmentAnalysisDialog({super.key, required this.jsonString});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    Map<String, dynamic> data = {};
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic>) {
         data = decoded;
      } else {
         data = {'details': decoded.toString()};
      }
    } catch (e) {
      data = {'details': jsonString};
    }

    return AlertDialog(
        backgroundColor: AppDesign.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
           const Icon(Icons.auto_awesome, color: Colors.greenAccent),
           const SizedBox(width: 8),
           Expanded(child: Text(l10n.analysis_title ?? 'Resultado da Análise IA', style: const TextStyle(color: Colors.white, fontSize: 16))),
        ]),
        content: SingleChildScrollView(
          child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             mainAxisSize: MainAxisSize.min,
             children: [
                if (data['summary'] != null) ...[
                   const Text("RESUMO", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                   Text(data['summary'].toString(), style: const TextStyle(color: Colors.white, fontSize: 13)),
                   const SizedBox(height: 12),
                ],
                if (data['alerts'] != null && (data['alerts'] is List) && (data['alerts'] as List).isNotEmpty) ...[
                   const Text("ALERTAS", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                   ...(data['alerts'] as List).map((a) => Text("• $a", style: TextStyle(color: Colors.red.shade100, fontSize: 13))),
                   const SizedBox(height: 12),
                ],
                if (data['details'] != null) ...[
                   const Text("DETALHES", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
                   Text(data['details'].toString(), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
                if (data.isEmpty)
                   const Text("Sem dados estruturados.", style: TextStyle(color: Colors.white30)),
             ],
          ),
        ),
        actions: [
          TextButton(
             onPressed: () => Navigator.pop(context), 
             child: Text(l10n.btn_close ?? "Entendi", style: const TextStyle(color: AppDesign.petPink, fontWeight: FontWeight.bold))
          ),
        ],
    );
  }
  
  static void show(BuildContext context, String jsonString) {
    showDialog(
      context: context,
      builder: (ctx) => AttachmentAnalysisDialog(jsonString: jsonString),
    );
  }
}
