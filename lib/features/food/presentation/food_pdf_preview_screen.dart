import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import '../services/food_export_service.dart';
import '../models/food_analysis_model.dart';
import '../../../../core/widgets/pdf_preview_screen.dart';

class FoodPdfPreviewScreen extends StatelessWidget {
  final FoodAnalysisModel? analysis;
  final FoodPdfLabels labels;
  final bool isRecipesOnly;
  final Future<Uint8List> Function(PdfPageFormat format)? buildPdf;

  const FoodPdfPreviewScreen({
    super.key,
    this.analysis,
    required this.labels,
    this.isRecipesOnly = false,
    this.buildPdf,
  });

  @override
  Widget build(BuildContext context) {
    final reportTitle = analysis != null ? analysis!.identidade.nome : labels.title;

    return PdfPreviewScreen(
      title: "Relatório: $reportTitle",
      buildPdf: (format) async {
        if (buildPdf != null) return await buildPdf!(format);
        if (analysis == null) throw Exception("Dados insuficientes");

        return isRecipesOnly 
          ? await FoodExportService().generateRecipeBookPdf(analysis!, labels)
          : await FoodExportService().generateFullAnalysisPdf(analysis!, labels);
      },
      showShare: true,
    );
  }

}
