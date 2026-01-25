import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../l10n/app_localizations.dart';

class ReportStyleHelper {
  static const PdfColor primary = PdfColor.fromInt(0xFF212121);
  static const PdfColor accent = PdfColor.fromInt(0xFFE91E63);
  static const PdfColor success = PdfColor.fromInt(0xFF2E7D32);
  static const PdfColor danger = PdfColor.fromInt(0xFFC62828);
  static const PdfColor grey = PdfColor.fromInt(0xFF757575);
  static const PdfColor white = PdfColor.fromInt(0xFFFFFFFF);
  static const PdfColor cardBg = PdfColor.fromInt(0xFFFAFAFA);

  static PdfColor opacify(PdfColor color, double alpha) {
    return PdfColor(color.red, color.green, color.blue, alpha);
  }

  static pw.Widget buildHeader({
    required String title,
    required String petName,
    required String breed,
    required String age,
    required String microchip,
    String? imagePath,
    required AppLocalizations l10n,
  }) {
    pw.ImageProvider? profileImage;
    if (imagePath != null && File(imagePath).existsSync()) {
      profileImage = pw.MemoryImage(File(imagePath).readAsBytesSync());
    }

    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Row(
        children: [
          // Pet Photo (Circular)
          pw.Container(
            width: 70,
            height: 70,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              color: PdfColors.grey300,
              image: profileImage != null
                  ? pw.DecorationImage(
                      image: profileImage, fit: pw.BoxFit.cover)
                  : null,
              border: pw.Border.all(color: accent, width: 2),
            ),
            child: profileImage == null
                ? pw.Center(
                    child: pw.Icon(const pw.IconData(0xe84f),
                        color: PdfColors.white, size: 30))
                : null,
          ),
          pw.SizedBox(width: 20),
          // Pet Info
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(petName.toUpperCase(),
                    style: const pw.TextStyle(fontSize: 24.0, color: primary)),
                pw.Row(
                  children: [
                    pw.Text(breed,
                        style: const pw.TextStyle(fontSize: 12.0, color: grey)),
                    pw.Text(' • ',
                        style: const pw.TextStyle(fontSize: 12.0, color: grey)),
                    pw.Text(age,
                        style: const pw.TextStyle(fontSize: 12.0, color: grey)),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Text('MICROCHIP: ${microchip.isEmpty ? "N/A" : microchip}',
                    style: const pw.TextStyle(fontSize: 10.0, color: grey)),
              ],
            ),
          ),
          // Report Type Badge
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: const pw.BoxDecoration(
                  color: accent,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Text(title.toUpperCase(),
                    style: const pw.TextStyle(color: white, fontSize: 10.0)),
              ),
              pw.SizedBox(height: 4),
              pw.Text('ScanNut Professional Dash',
                  style: const pw.TextStyle(fontSize: 8.0, color: grey)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget buildCard({required pw.Widget child, PdfColor? color}) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 15),
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: color ?? white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
        border: pw.Border.all(color: PdfColors.grey200, width: 1),
      ),
      child: child,
    );
  }

  static pw.Widget buildSectionTitle(String title, {pw.IconData? icon}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 10, bottom: 8),
      child: pw.Row(
        children: [
          if (icon != null) ...[
            pw.Icon(icon, color: accent, size: 14),
            pw.SizedBox(width: 8),
          ],
          pw.Text(title.toUpperCase(),
              style: const pw.TextStyle(fontSize: 12.0, color: primary)),
        ],
      ),
    );
  }

  static pw.Widget buildBadge(String text, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: pw.BoxDecoration(
        color: opacify(color, 0.1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: color, width: 0.5),
      ),
      child: pw.Text(
        text.toUpperCase(),
        style: pw.TextStyle(color: color, fontSize: 8),
      ),
    );
  }

  static pw.Widget buildFooter(int pageNumber, int totalPages) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Multiverso Digital 2026 © Todos os direitos reservados.',
              style: const pw.TextStyle(fontSize: 8.0, color: grey)),
          pw.Text('Página $pageNumber de $totalPages',
              style: const pw.TextStyle(fontSize: 8.0, color: grey)),
        ],
      ),
    );
  }
}
