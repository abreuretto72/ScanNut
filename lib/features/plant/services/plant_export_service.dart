import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:scannut/l10n/app_localizations.dart';
import '../models/plant_analysis_model.dart';
import '../models/botany_history_item.dart';
import '../../../core/services/base_pdf_helper.dart';

/// Refined Service for Plant-specific PDF exports.
/// Part of the Micro-Apps strategy and Iron Law of isolation.
class PlantExportService {
  static final PlantExportService _instance = PlantExportService._internal();
  factory PlantExportService() => _instance;
  PlantExportService._internal();

  static const PdfColor themeColor = BasePdfHelper.colorPlant;

  /// 🌿 1. PLANT ANALYSIS REPORT
  Future<pw.Document> generatePlantAnalysisReport({
    required PlantAnalysisModel analysis,
    required AppLocalizations strings,
    File? imageFile,
  }) async {
    final pdf = pw.Document();
    final String timestampStr = DateFormat('dd/MM/yyyy HH:mm', strings.localeName).format(DateTime.now());

    pw.ImageProvider? plantImage;
    if (imageFile != null) {
      plantImage = await BasePdfHelper.safeLoadImage(imageFile.path);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (context) => BasePdfHelper.buildHeader(
            strings.botanyDossierTitle(analysis.plantName), timestampStr,
            color: themeColor,
            appName: 'ScanNut'),
        footer: (context) => BasePdfHelper.buildFooter(context, strings: strings),
        build: (context) => [
          if (plantImage != null)
            pw.Container(
              height: 150, width: double.infinity, margin: const pw.EdgeInsets.only(bottom: 20),
              decoration: pw.BoxDecoration(borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)), border: pw.Border.all(color: themeColor, width: 2)),
              child: pw.ClipRRect(horizontalRadius: 6, verticalRadius: 6, child: pw.Image(plantImage, fit: pw.BoxFit.cover)),
            ),
          
          BasePdfHelper.buildSectionHeader('IDENTIFICAÇÃO BOTÂNICA', color: themeColor),
          pw.Text('Nome Científico: ${analysis.identificacao.nomeCientifico}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.Text('Nomes Populares: ${analysis.identificacao.nomesPopulares.join(", ")}', style: const pw.TextStyle(fontSize: 10)),
          
          pw.SizedBox(height: 20),
          BasePdfHelper.buildSectionHeader('DIAGNÓSTICO DE SAÚDE', color: themeColor),
          pw.Text('Condição: ${analysis.saude.condicao}', style: const pw.TextStyle(fontSize: 10)),
          pw.Text('Diagnóstico: ${analysis.saude.detalhes}', style: const pw.TextStyle(fontSize: 10)),
          
          pw.SizedBox(height: 20),
          BasePdfHelper.buildSectionHeader('GUIA DE SOBREVIVÊNCIA', color: themeColor),
          pw.Text(analysis.saude.planoRecuperacao, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
    return pdf;
  }

  /// 📖 2. PLANT HISTORY REPORT
  Future<pw.Document> generatePlantHistoryReport({
    required List<BotanyHistoryItem> items,
    required AppLocalizations strings,
  }) async {
    final pdf = pw.Document();
    final String timestampStr = DateFormat('dd/MM/yyyy HH:mm', strings.localeName).format(DateTime.now());

    for (var item in items) {
      pw.ImageProvider? plantImage = await BasePdfHelper.safeLoadImage(item.imagePath);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(35),
          header: (context) => BasePdfHelper.buildHeader("HISTÓRICO - ${item.plantName.toUpperCase()}", timestampStr, color: themeColor, appName: 'ScanNut'),
          footer: (context) => BasePdfHelper.buildFooter(context, strings: strings),
          build: (context) => [
            pw.Center(child: pw.Text(item.plantName.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18))),
            pw.SizedBox(height: 10),
            if (plantImage != null)
              pw.Container(height: 200, width: double.infinity, margin: const pw.EdgeInsets.only(bottom: 20), child: pw.Image(plantImage, fit: pw.BoxFit.cover)),
            
            BasePdfHelper.buildSectionHeader("STATUS DE SAÚDE", color: themeColor),
            pw.Text('Estado: ${item.healthStatus}', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 20),
            BasePdfHelper.buildSectionHeader("TOXICIDADE", color: themeColor),
            pw.Text('Nível: ${item.toxicityStatus.toUpperCase()}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: item.toxicityStatus == 'safe' ? PdfColors.green : PdfColors.red)),
          ],
        ),
      );
    }
    return pdf;
  }
}
