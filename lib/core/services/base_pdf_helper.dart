import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:scannut/l10n/app_localizations.dart';
import 'image_optimization_service.dart';

/// Standard PDF Helper for ScanNut 2026 reports.
/// Adheres to the "Iron Law" of stability and isolation.
class BasePdfHelper {
  // Domain Colors
  static final PdfColor colorPet = PdfColor.fromHex('#FFD1DC'); // Pastel Pink
  static final PdfColor colorPetLight = PdfColor.fromHex('#FFE4E9');
  static final PdfColor colorPetUltraLight = PdfColor.fromHex('#FFF5F7');
  
  static const PdfColor colorFood = PdfColor.fromInt(0xFFFF9800); // Orange
  static const PdfColor colorPlant = PdfColor.fromInt(0xFF10AC84); // Green

  /// Helper to save PDF document to temporary file
  static Future<File> saveDocument({required String name, required pw.Document pdf}) async {
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/$name");
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// 🛡️ VACCINE: Safe Text Splitter (Sanitization & Fragmentation)
  /// Removes invisible noise (U+FE0F) and splits gigantic blocks.
  static List<String> safeSplitText(String text) {
    if (text.isEmpty) return [];

    // 1. Remove Noise (Keep ASCII + Latin-1 + Space)
    // RegExp(r'[^\x20-\x7E\s\u00C0-\u00FF]')
    final clean = text.replaceAll(RegExp(r'[^\x20-\x7E\s\u00C0-\u00FF]'), '').trim();

    // 2. Fragment Blocks > 1000 chars
    final List<String> result = [];
    final lines = clean.split('\n');

    for (var line in lines) {
      if (line.trim().isEmpty) continue;
      
      if (line.length <= 1000) {
        result.add(line.trim());
      } else {
        // Split huge lines by period
        final sentences = line.split('. ');
        for (var s in sentences) {
           final chunk = s.trim();
           if (chunk.isNotEmpty) {
             // Re-append period if simplified split removed it, or just trat as chunk
             result.add(chunk);
           }
        }
      }
    }
    return result;
  }

  /// Memory-optimized image loading for PDF.
  /// Downsamples and optimizes for Samsung A25 compatibility.
  static Future<pw.ImageProvider?> safeLoadImage(String? path) async {
    if (path == null || path.isEmpty) return null;

    try {
      final file = File(path);
      if (!await file.exists()) {
        debugPrint('⚠️ [BasePdfHelper] Image file not found: $path');
        return null;
      }

      final optimizedBytes = await ImageOptimizationService().loadOptimizedBytes(
        originalPath: path,
        autoCleanup: true,
      );

      if (optimizedBytes != null) {
        return pw.MemoryImage(optimizedBytes);
      }

      final bytes = await file.readAsBytes();
      return pw.MemoryImage(bytes);
    } catch (e) {
      debugPrint('❌ [BasePdfHelper] Error loading image: $path | $e');
      final placeholder = ImageOptimizationService().getPlaceholderBytes();
      return pw.MemoryImage(placeholder);
    }
  }

  /// Standard Institutional Header.
  static pw.Widget buildHeader(
    String title, 
    String timestamp, {
    required String appName,
    String dateLabel = 'Data', 
    PdfColor? color,
  }) {
    final bool isPet = color == colorPet;
    final PdfColor textColor = isPet ? PdfColors.black : (color != null ? PdfColors.white : PdfColors.black);

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: color,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              border: pw.Border.all(color: color ?? PdfColors.black, width: 1),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Text(
                    title.toUpperCase(),
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      appName,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                        color: textColor,
                      ),
                    ),
                    pw.Text(
                      '$dateLabel: $timestamp',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: isPet ? PdfColors.black : (color != null ? PdfColors.white : PdfColors.grey700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Container(height: 1.5, color: color ?? PdfColors.black),
          pw.SizedBox(height: 10),
        ],
      ),
    );
  }

  /// Standard Multi-page Footer with Paging and Optional Institutional Footer.
  static pw.Widget buildFooter(
    pw.Context context, {
    AppLocalizations? strings,
    String? institutionalText,
    String supportEmail = 'contato@multiversodigital.com.br',
  }) {
    final pageText = strings?.pdfPage(context.pageNumber, context.pagesCount) ??
        'Página ${context.pageNumber} de ${context.pagesCount}';

    final footerLabel = institutionalText ?? '© 2026 Multiverso Digital | $supportEmail';

    return pw.Column(
      children: [
        pw.Divider(thickness: 0.5, color: PdfColors.grey300),
        pw.SizedBox(height: 5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(footerLabel,
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
            pw.Text(pageText,
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          ],
        ),
      ],
    );
  }

  /// Standard Section Header with Color Theme.
  static pw.Widget buildSectionHeader(
    String title, {
    PdfColor? color, 
    PdfColor? textColor,
  }) {
    final bool isPet = color == colorPet;
    final PdfColor effectiveTextColor = textColor ?? (isPet ? PdfColors.black : (color != null ? PdfColors.white : PdfColors.black));

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10, top: 15),
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: color ?? PdfColors.black, width: 0.5),
      ),
      child: pw.Center(
        child: pw.Text(
          title.toUpperCase(),
          style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 13,
              color: effectiveTextColor),
        ),
      ),
    );
  }

  /// KPI / Indicator block with ± formatting.
  static pw.Widget buildIndicator(String label, String value, PdfColor color) {
    String cleaned = value;
    bool isEstimated = false;

    if (cleaned.contains('[ESTIMATED]')) {
      cleaned = cleaned.replaceAll('[ESTIMATED]', '');
      isEstimated = true;
    }

    cleaned = cleaned
        .replaceAll('aproximadamente', '±')
        .replaceAll('Aproximadamente', '±')
        .trim();

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        color: PdfColors.white,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Text(label,
                  style: const pw.TextStyle(
                      fontSize: 8, color: PdfColors.grey700)),
              if (isEstimated) ...[
                pw.SizedBox(width: 4),
                pw.Text('*',
                    style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black)),
              ]
            ],
          ),
          pw.SizedBox(height: 2),
          pw.Text(cleaned,
              style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black)),
        ],
      ),
    );
  }
}
