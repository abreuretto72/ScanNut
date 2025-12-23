import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

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
      appBar: AppBar(title: Text(title)),
      body: PdfPreview(
        build: buildPdf,
        canChangeOrientation: false,
        canChangePageFormat: false,
        allowPrinting: true,
        allowSharing: true,
        canDebug: false,
        pdfFileName: '${title.replaceAll(' ', '_')}.pdf',
        // Standard icons are handled by default in PdfPreview's toolbar
      ),
    );
  }
}
