import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class FoodPdfPreviewScreen extends StatelessWidget {
  final String foodName;
  final String? pdfPath;
  final Future<Uint8List> Function(PdfPageFormat)? buildPdf;

  const FoodPdfPreviewScreen({
    super.key,
    required this.foodName,
    this.pdfPath,
    this.buildPdf,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Relatório: $foodName"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: PdfPreview(
        build: (format) async {
          if (buildPdf != null) {
            return buildPdf!(format);
          } else if (pdfPath != null) {
            return File(pdfPath!).readAsBytes();
          }
          return Uint8List(0);
        },
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
      ),
    );
  }
}
