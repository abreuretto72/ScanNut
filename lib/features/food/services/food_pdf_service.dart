import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/food_analysis_model.dart';
// 🛡️ ISOLAMENTO: Nenhuma dependência de core/utils/pdf_helper.dart

// 🛡️ DTO para Strings Localizadas (Sanitização)
class FoodPdfLabels {
  final String title;
  final String date;
  final String nutrientsTable;
  final String qty;
  final String dailyGoal;
  final String calories;
  final String proteins;
  final String carbs;
  final String fats;
  final String healthRating;
  final String clinicalRec;
  final String disclaimer;

  FoodPdfLabels({
    required this.title,
    required this.date,
    required this.nutrientsTable,
    required this.qty,
    required this.dailyGoal,
    required this.calories,
    required this.proteins,
    required this.carbs,
    required this.fats,
    required this.healthRating,
    required this.clinicalRec,
    required this.disclaimer,
  });
}

class FoodPdfService {
  /// Gera e visualiza o PDF Nutricional
  Future<void> generateAndPreview(FoodAnalysisModel data, FoodPdfLabels labels) async {
    final pdf = await _buildDoc(data, labels);
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Relatorio_Nutricional_${data.identidade.nome.replaceAll(' ', '_')}',
    );
  }

  Future<Uint8List> generateBytes(FoodAnalysisModel data, FoodPdfLabels labels) async {
    final pdf = await _buildDoc(data, labels);
    return pdf.save();
  }

  Future<pw.Document> _buildDoc(FoodAnalysisModel data, FoodPdfLabels labels) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(labels),
          pw.SizedBox(height: 20),
          _buildTitle(data.identidade.nome),
          pw.Divider(),
          _buildNutritionalTable(data, labels),
          pw.SizedBox(height: 20),
          _buildTrafficLight(data.identidade.semaforoSaude, labels),
          pw.SizedBox(height: 20),
          _buildRecommendation(data.analise.vereditoIa, labels),
          pw.SizedBox(height: 30),
          _buildDisclaimer(labels),
        ],
      ),
    );
    return pdf;
  }

  pw.Widget _buildHeader(FoodPdfLabels labels) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('ScanNut Nutrition', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
        pw.Text(labels.date),
      ],
    );
  }

  pw.Widget _buildTitle(String title) {
    return pw.Center(
      child: pw.Text(
        title, 
        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)
      ),
    );
  }

  pw.Widget _buildNutritionalTable(FoodAnalysisModel data, FoodPdfLabels labels) {
    final macros = data.macros;
    return pw.Table.fromTextArray(
      headers: [labels.nutrientsTable, labels.qty, labels.dailyGoal],
      data: [
        [labels.calories, '${macros.calorias100g} kcal', _calcPercent(macros.calorias100g, 2000)],
        [labels.proteins, macros.proteinas, '-'],
        [labels.carbs, macros.carboidratosLiquidos, '-'],
        [labels.fats, macros.gordurasPerfil, '-'],
      ],
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.green700),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
    );
  }

  pw.Widget _buildTrafficLight(String status, FoodPdfLabels labels) {
    PdfColor color;
    if (status == 'Verde') color = PdfColors.green;
    else if (status == 'Amarelo') color = PdfColors.amber;
    else color = PdfColors.red;

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColor(color.red, color.green, color.blue, 0.1),
        border: pw.Border.all(color: color, width: 2),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 20, height: 20,
            decoration: pw.BoxDecoration(shape: pw.BoxShape.circle, color: color),
          ),
          pw.SizedBox(width: 10),
          pw.Text('${labels.healthRating}: $status', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  pw.Widget _buildRecommendation(String text, FoodPdfLabels labels) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(labels.clinicalRec, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 5),
        pw.Text(text, style: const pw.TextStyle(fontSize: 12)),
      ],
    );
  }

  pw.Widget _buildDisclaimer(FoodPdfLabels labels) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.Text(
          labels.disclaimer,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  // Helper local (sem dependência externa)
  String _calcPercent(num val, num total) {
    return '${((val / total) * 100).toStringAsFixed(1)}%';
  }
}
