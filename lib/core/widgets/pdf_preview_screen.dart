import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../theme/app_design.dart';

class PdfPreviewScreen extends StatelessWidget {
  final String title;
  final Future<Uint8List> Function(PdfPageFormat format) buildPdf;
  final bool showShare;

  const PdfPreviewScreen({
    super.key,
    required this.title,
    required this.buildPdf,
    this.showShare = true,
  });

  @override
  Widget build(BuildContext context) {
    // Nome do arquivo para exportação
    final fileName = 'ScanNut_${title.replaceAll(' ', '_')}.pdf';

    return Scaffold(
      backgroundColor: Colors.grey[900], // 🛡️ Background Preto Institucional
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black, // 🛡️ AppBar Preta
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Theme(
        // 🛡️ Força tema claro interno para o PDF não bugar cores
        data: ThemeData.light(),
        child: PdfPreview(
          build: buildPdf,
          // 🛡️ Configuração Blindada: Remove controles extras
          canDebug: false,
          canChangePageFormat: false,
          canChangeOrientation: false,
          allowPrinting: false, 
          allowSharing: false,
          loadingWidget: const Center(
            child: CircularProgressIndicator(color: AppDesign.foodOrange),
          ),
          pdfFileName: fileName,
          maxPageWidth: 700,
          actions: const [], 
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBottomAction(
                icon: Icons.print,
                tooltip: 'Imprimir',
                onPressed: () async {
                  final bytes = await buildPdf(PdfPageFormat.a4);
                  await Printing.layoutPdf(onLayout: (format) async => bytes);
                },
              ),
              _buildBottomAction(
                icon: Icons.open_in_new, // Vis. Externa
                tooltip: 'Abrir Externamente',
                onPressed: () async {
                  final bytes = await buildPdf(PdfPageFormat.a4);
                  await Printing.sharePdf(bytes: bytes, filename: fileName);
                },
              ),
              if (showShare)
                _buildBottomAction(
                  icon: Icons.share,
                  tooltip: 'Compartilhar',
                  onPressed: () async {
                    // 🛡️ Compartilhamento Nativo Blindado
                    final bytes = await buildPdf(PdfPageFormat.a4);
                    await Printing.sharePdf(bytes: bytes, filename: fileName);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, color: Colors.white, size: 28),
      onPressed: onPressed,
      tooltip: tooltip,
    );
  }
}

