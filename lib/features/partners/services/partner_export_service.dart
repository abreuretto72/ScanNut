import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:scannut/l10n/app_localizations.dart';
import '../../../core/models/partner_model.dart';
import '../../../core/services/base_pdf_helper.dart';

/// 🤝 Partner-specific PDF Service.
/// Handles generation of reports for partners, hubs, and singular queries.
class PartnerExportService {
  static final PartnerExportService _instance = PartnerExportService._internal();
  factory PartnerExportService() => _instance;
  PartnerExportService._internal();

  static final PdfColor themeColor = PdfColors.purple500; // Distinct from Pet (Pink)

  /// 🏢 1. Single Partner Report (Registration/Details)
  Future<pw.Document> generateSinglePartnerReport({
    required PartnerModel partner,
    required AppLocalizations strings,
  }) async {
    final pdf = pw.Document();
    final String timestampStr = DateFormat.yMd(strings.localeName).add_Hm().format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (context) => BasePdfHelper.buildHeader('${strings.pdfReportTitle} - ${partner.name}', timestampStr, color: themeColor, appName: 'ScanNut'),
        footer: (context) => BasePdfHelper.buildFooter(context, strings: strings),
        build: (context) => [
          // Header Info
          pw.Text(partner.name.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
          pw.SizedBox(height: 10),
          BasePdfHelper.buildIndicator(strings.partnersCategory, partner.category, themeColor),
          BasePdfHelper.buildIndicator(strings.partnerFieldAddress, partner.address, themeColor),
          BasePdfHelper.buildIndicator(strings.partnerFieldPhone, partner.phone, themeColor),
          
          if (partner.instagram != null) 
            BasePdfHelper.buildIndicator(strings.partnerFieldInstagram, partner.instagram!, themeColor),
            
          if (partner.email != null) 
            BasePdfHelper.buildIndicator(strings.partnerFieldEmail, partner.email!, themeColor),

          pw.SizedBox(height: 20),
          
          if (partner.openingHours.isNotEmpty) ...[
             BasePdfHelper.buildSectionHeader(strings.partnerFieldHours, color: themeColor),
             pw.Text(partner.openingHours['raw'] ?? '', style: const pw.TextStyle(fontSize: 10)),
             pw.SizedBox(height: 10),
          ],
          
          if (partner.specialties.isNotEmpty) ...[
             BasePdfHelper.buildSectionHeader(strings.partnerFieldSpecialties, color: themeColor),
             pw.Wrap(
                spacing: 5,
                children: partner.specialties.map((s) => pw.Container(
                   padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                   decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
                   child: pw.Text(s, style: const pw.TextStyle(fontSize: 9))
                )).toList()
             ),
             pw.SizedBox(height: 10),
          ],
        ],
      ),
    );
    return pdf;
  }

  /// 🌐 2. Hub Report (Filtered List)
  Future<pw.Document> generatePartnersHubReport({
    required List<PartnerModel> partners,
    required String reportType,
    required AppLocalizations strings,
  }) async {
    return _generateListReport(partners, strings, title: strings.partnersTitle, subTitle: 'Relatório: $reportType');
  }

  /// 📍 3. Location/Radius Report
  Future<pw.Document> generatePartnersReport({
    required List<PartnerModel> partners,
    required String region,
    required AppLocalizations strings,
  }) async {
    return _generateListReport(partners, strings, title: 'Guia de Parceiros', subTitle: 'Região: $region');
  }

  /// 📡 3. RADAR REPORT (Discoveries)
  Future<pw.Document> generateRadarReport({
    required List<PartnerModel> partners,
    required double userLat,
    required double userLng,
    required AppLocalizations strings,
  }) async {
    return _generateListReport(
      partners, 
      strings, 
      title: 'Relatório de Radar', 
      subTitle: 'Localização: $userLat, $userLng'
    );
  }

  // Shared List Generator
  Future<pw.Document> _generateListReport(
    List<PartnerModel> partners, 
    AppLocalizations strings, 
    {required String title, String? subTitle}
  ) async {
    final pdf = pw.Document();
    final String timestampStr = DateFormat.yMd(strings.localeName).add_Hm().format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (context) => BasePdfHelper.buildHeader(title, timestampStr, color: themeColor, appName: 'ScanNut'),
        footer: (context) => BasePdfHelper.buildFooter(context, strings: strings),
        build: (context) => [
          if (subTitle != null)
            pw.Text(subTitle, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
          pw.SizedBox(height: 20),
          
          pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
              headerDecoration: pw.BoxDecoration(color: themeColor),
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
              cellStyle: const pw.TextStyle(fontSize: 8, color: PdfColors.black),
              headers: [
                strings.partnersCategory,
                'Nome',
                strings.partnerFieldAddress,
                strings.partnerFieldPhone,
              ],
              data: partners.map((p) => [
                p.category,
                p.name,
                p.address,
                p.phone
              ]).toList(),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(4),
                3: const pw.FlexColumnWidth(2),
              }
          )
        ],
      ),
    );
    return pdf;
  }
}
