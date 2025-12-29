import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class PdfPreviewScreen extends StatelessWidget {
  final String title;
  final Future<Uint8List> Function(PdfPageFormat format) buildPdf;

  const PdfPreviewScreen({
    Key? key,
    required this.title,
    required this.buildPdf,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: PdfPreview(
        build: buildPdf,
        canChangeOrientation: false,
        canChangePageFormat: false,
        allowPrinting: false, // Hidden to use custom bottom buttons
        allowSharing: false,  // Hidden to use custom bottom buttons
        canDebug: false,
        pdfFileName: '${title.replaceAll(' ', '_')}.pdf',
        maxPageWidth: 700,
        actions: const [], // Hide default top actions
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
                icon: Icons.open_in_new,
                tooltip: 'Abrir no Visualizador',
                onPressed: () async {
                  final bytes = await buildPdf(PdfPageFormat.a4);
                  final tempDir = await getTemporaryDirectory();
                  final file = File('${tempDir.path}/${title.replaceAll(' ', '_')}.pdf');
                  await file.writeAsBytes(bytes);
                  await OpenFilex.open(file.path);
                },
              ),
              _buildBottomAction(
                icon: Icons.share,
                tooltip: 'Compartilhar',
                onPressed: () async {
                  final bytes = await buildPdf(PdfPageFormat.a4);
                  final tempDir = await getTemporaryDirectory();
                  final file = File('${tempDir.path}/${title.replaceAll(' ', '_')}.pdf');
                  await file.writeAsBytes(bytes);
                  await Share.shareXFiles([XFile(file.path)], text: title);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAction({required IconData icon, required String tooltip, required VoidCallback onPressed}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.white, size: 28),
          onPressed: onPressed,
          tooltip: tooltip,
        ),
      ],
    );
  }
}
