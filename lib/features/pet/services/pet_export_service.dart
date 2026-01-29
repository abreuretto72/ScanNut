import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:scannut/l10n/app_localizations.dart';
import '../models/pet_profile_extended.dart';
import '../models/pet_analysis_result.dart';
import '../models/pet_event.dart';
import '../models/analise_ferida_model.dart';
import '../../../core/models/partner_model.dart';
import '../../../core/services/base_pdf_helper.dart';

/// Refined Service for Pet-specific PDF exports.
/// Part of the Micro-Apps strategy and Iron Law of isolation.
class PetExportService {
  static final PetExportService _instance = PetExportService._internal();
  factory PetExportService() => _instance;
  PetExportService._internal();

  static final PdfColor themeColor = BasePdfHelper.colorPet;
  static final PdfColor lightColor = BasePdfHelper.colorPetLight;

  /// 🐾 1. PET PROFILE REPORT (Full Medical Record)
  Future<pw.Document> generatePetProfileReport({
    required PetProfileExtended profile,
    required AppLocalizations strings,
  }) async {
    final pdf = pw.Document();
    final String timestampStr = DateFormat.yMd(strings.localeName).add_Hm().format(DateTime.now());
    pw.ImageProvider? profileImage;
    if (profile.imagePath != null) {
      profileImage = await BasePdfHelper.safeLoadImage(profile.imagePath!);
    }

    // Cover Page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              if (profileImage != null)
                pw.Container(
                  width: 200, height: 200,
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 4), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(100))),
                  child: pw.ClipRRect(horizontalRadius: 100, verticalRadius: 100, child: pw.Image(profileImage, fit: pw.BoxFit.cover)),
                ),
              pw.SizedBox(height: 30),
              pw.Text(profile.petName.toUpperCase(), style: pw.TextStyle(fontSize: 42, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text(strings.pdfReportTitle, style: const pw.TextStyle(fontSize: 16, color: PdfColors.grey700, letterSpacing: 2)),
              pw.SizedBox(height: 40),
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(color: PdfColors.white, border: pw.Border.all(color: PdfColors.black, width: 2), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12))),
                child: pw.Column(
                  children: [
                    pw.Text(profile.raca ?? 'SRD', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 8),
                    pw.Text('${strings.pdfGeneratedOn}: $timestampStr', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Detail Page
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (context) => BasePdfHelper.buildHeader('${strings.pdfReportTitle}: ${profile.petName}', timestampStr, color: themeColor, appName: 'ScanNut'),
        footer: (context) => BasePdfHelper.buildFooter(context, strings: strings),
        build: (context) => [
          BasePdfHelper.buildSectionHeader(strings.pdfIdentitySection, color: themeColor),
          pw.Table(children: [
            _buildTableRow(strings.pdfFieldName, profile.petName),
            _buildTableRow(strings.pdfFieldBreed, profile.raca ?? '---'),
            _buildTableRow(strings.pdfFieldAge, profile.idadeExata ?? '---'),
            _buildTableRow('Peso', '${profile.pesoAtual ?? "---"} kg'),
          ]),
          // Content...
        ],
      ),
    );
    return pdf;
  }

  /// 🏥 2. VETERINARY 360 REPORT (Dossier)
  Future<pw.Document> generateVeterinary360Report({
    required PetAnalysisResult analysis,
    required String imagePath,
    required AppLocalizations strings,
  }) async {
    final pdf = pw.Document();
    final String timestampStr = DateFormat.yMd(strings.localeName).add_Hm().format(DateTime.now());
    pw.ImageProvider? analysisImage = await BasePdfHelper.safeLoadImage(imagePath);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (context) => BasePdfHelper.buildHeader('DOSSIÊ VETERINÁRIO 360º', timestampStr, color: themeColor, appName: 'ScanNut'),
        footer: (context) => BasePdfHelper.buildFooter(context, strings: strings),
        build: (context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (analysisImage != null)
                pw.Container(
                  width: 120, height: 120, margin: const pw.EdgeInsets.only(right: 20),
                  decoration: pw.BoxDecoration(borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)), border: pw.Border.all(color: themeColor, width: 2)),
                  child: pw.ClipRRect(horizontalRadius: 6, verticalRadius: 6, child: pw.Image(analysisImage, fit: pw.BoxFit.cover)),
                ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text((analysis.petName ?? '').toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
                    pw.SizedBox(height: 5),
                    BasePdfHelper.buildIndicator('Espécie:', analysis.especie, themeColor),
                    BasePdfHelper.buildIndicator('Condição:', analysis.urgenciaNivel, themeColor),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          BasePdfHelper.buildSectionHeader('ORIENTAÇÃO IMEDIATA', color: themeColor),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(color: PdfColors.grey100, border: pw.Border.all(color: themeColor, width: 0.5)),
            child: pw.Text(analysis.orientacaoImediata, style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
    return pdf;
  }

  /// 🍽️ 3. WEEKLY MENU REPORT
  Future<pw.Document> generateWeeklyMenuReport({
    required String petName,
    required String raceName,
    required String dietType,
    required List<Map<String, dynamic>> plan,
    required AppLocalizations strings,
    Map<String, List<Map<String, dynamic>>>? shoppingLists,
    List<dynamic>? recommendedBrands,
    String? period,
  }) async {
    final pdf = pw.Document();
    final String timestampStr = DateFormat.yMd(strings.localeName).add_Hm().format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (context) => BasePdfHelper.buildHeader(strings.pdfNutritionSection, timestampStr, color: themeColor, appName: 'ScanNut'),
        footer: (context) => BasePdfHelper.buildFooter(context, strings: strings),
        build: (context) {
          final List<pw.Widget> content = [];
          
          content.add(
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(color: lightColor, border: pw.Border.all(color: PdfColors.black, width: 0.8), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))),
              child: pw.Column(
                children: [
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                    pw.Text('PET: $petName', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                    pw.Text('PERÍODO: ${period ?? "Semanal"}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  ]),
                  pw.SizedBox(height: 4),
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                    pw.Text('RAÇA: $raceName', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('DIETA: $dietType', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  ]),
                ],
              ),
            )
          );
          
          content.add(pw.SizedBox(height: 20));
          
          for (var item in plan) {
             content.add(
               pw.Container(
                 margin: const pw.EdgeInsets.only(bottom: 10),
                 padding: const pw.EdgeInsets.all(8),
                 decoration: pw.BoxDecoration(border: pw.Border.all(color: themeColor, width: 0.5)),
                 child: pw.Column(
                   crossAxisAlignment: pw.CrossAxisAlignment.start,
                   children: [
                     pw.Text(item['dia'], style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: themeColor)),
                     pw.Text('${item['hora']} - ${item['titulo']}', style: const pw.TextStyle(fontSize: 10)),
                     pw.Text(item['descricao'], style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                   ],
                 ),
               )
             );
          }
          
          return content;
        },
      ),
    );
    return pdf;
  }

  // --- REPORT GENERATORS ---

  /// 📅 4. AGENDA REPORT (UNIFIED LAYOUT)
  Future<pw.Document> generateAgendaReport({
    required List<PetEvent> events,
    required DateTime start,
    required DateTime end,
    String? petFilter,
    String? categoryFilter,
    required String reportType,
    required AppLocalizations strings,
  }) async {
    final pdf = pw.Document();
    final String timestampStr =
        DateFormat.yMd(strings.localeName).add_Hm().format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (context) => BasePdfHelper.buildHeader(strings.pdfAgendaReport, timestampStr,
            color: themeColor, dateLabel: strings.pdfDateLabel, appName: 'ScanNut'),
        footer: (context) => BasePdfHelper.buildFooter(context, strings: strings),
        build: (context) => [
          if (reportType == 'Detalhamento' ||
              reportType == 'Somente Agendamentos')
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
              headerDecoration: pw.BoxDecoration(color: themeColor),
              headerStyle: pw.TextStyle(
                  color: PdfColors.black,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9),
              cellStyle:
                  const pw.TextStyle(fontSize: 7.5, color: PdfColors.black),
              headers: [
                strings.pdfDate,
                strings.pdfFieldEvent,
                strings.pdfFieldPet,
                strings.pdfFieldCategory,
                strings.pdfObservations,
                strings.pdfStatus
              ],
              data: events
                  .map((e) => [
                        DateFormat.yMd(strings.localeName)
                            .add_Hm()
                            .format(e.dateTime),
                        e.title,
                        e.petName,
                        e.getLocalizedTypeLabel(strings), // Assuming this exists on PetEvent
                        e.notes ?? ' - ',
                        e.completed ? strings.pdfCompleted : strings.pdfPending,
                      ])
                  .toList(),
            )
          else
            pw.Center(
              child: pw.Text(strings.pdfSummaryReport,
                  style: pw.TextStyle(
                      color: PdfColors.grey500,
                      fontStyle: pw.FontStyle.italic,
                      fontSize: 10)),
            ),
        ],
      ),
    );
    return pdf;
  }

  // --- PRIVATE HELPERS ---

  pw.TableRow _buildTableRow(String label, String value) {
    return pw.TableRow(children: [
      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4), child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4), child: pw.Text(value, style: const pw.TextStyle(fontSize: 10))),
    ]);
  }
}
