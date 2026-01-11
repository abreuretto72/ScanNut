import 'dart:typed_data';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:scannut/l10n/app_localizations.dart';
import '../../features/pet/models/pet_event.dart';
import '../../features/pet/models/pet_profile_extended.dart';
import '../../features/food/models/food_analysis_model.dart';
import '../../features/pet/models/lab_exam.dart';
import '../../core/models/partner_model.dart';
import 'dart:io';
import '../../features/pet/services/pet_event_service.dart';
import '../services/file_upload_service.dart'; // import relative to core/services
import 'package:path/path.dart' as path;
import '../../nutrition/data/models/plan_day.dart';
import '../../features/plant/models/plant_analysis_model.dart';
import '../services/partner_service.dart';
import '../../nutrition/data/datasources/shopping_list_service.dart';
import '../../nutrition/data/models/shopping_list_model.dart';
import '../../features/food/models/nutrition_history_item.dart';
import '../../features/food/models/recipe_history_item.dart';
import '../../features/plant/models/botany_history_item.dart';
import 'image_optimization_service.dart';

// Helper class to replace record syntax for Dart compatibility
class _CleanedValue {
  final String value;
  final bool isEstimated;
  _CleanedValue(this.value, this.isEstimated);
}

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  // --- DOMAIN COLORS ---
  static final PdfColor colorPet = PdfColor.fromHex('#FFD1DC'); // Rosa Pastel (Protocol V62)
  static final PdfColor colorPetLight = PdfColor.fromHex('#FFE4E9'); // Lighter pink
  static final PdfColor colorPetUltraLight = PdfColor.fromHex('#FFF5F7'); // Very light pink
  static const PdfColor colorFood = PdfColor.fromInt(0xFFFF9800);
  static const PdfColor colorPlant = PdfColor.fromInt(0xFF10AC84);

  // --- SAFETY HELPERS ---
  Future<pw.ImageProvider?> safeLoadImage(String? path) async {

    if (path == null || path.isEmpty) return null;
    
    try {
      final file = File(path);
      if (!await file.exists()) {
        debugPrint('⚠️ [V70.1-PDF] Image file not found: $path');
        return null;
      }

      // 🛡️ V70.1: OPTIMIZE IMAGE BEFORE PDF RENDERING
      // Prevents memory crashes by downsampling to 800px max @ 70% quality
      debugPrint('🔄 [V70.1-PDF] Loading optimized image: ${path.split('/').last}');
      
      final optimizedBytes = await ImageOptimizationService().loadOptimizedBytes(
        originalPath: path,
        autoCleanup: true, // Force garbage collection after load
      );

      if (optimizedBytes != null) {
        debugPrint('✅ [V70.1-PDF] Image optimized: ${(optimizedBytes.length / 1024).toStringAsFixed(2)} KB');
        return pw.MemoryImage(optimizedBytes);
      }

      // Fallback: try original if optimization fails
      debugPrint('⚠️ [V70.1-PDF] Optimization failed, using original');
      final bytes = await file.readAsBytes();
      return pw.MemoryImage(bytes);
      
    } catch (e) {
      debugPrint('❌ [V70.1-PDF] Error loading image: $path | Error: $e');
      
      // V70.1: SELF-HEALING - Return placeholder instead of crashing
      debugPrint('🛡️ [V70.1-PDF] Using placeholder for corrupted image');
      final placeholder = ImageOptimizationService().getPlaceholderBytes();
      return pw.MemoryImage(placeholder);
    }
  }

  pw.Widget buildSectionHeader(String title, {PdfColor? color, PdfColor? textColor}) {
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
            color: textColor ?? ((color == colorPet) ? PdfColors.black : (color != null ? PdfColors.white : PdfColors.black))
          ),
        ),
      ),
    );
  }

  static const String appName = 'ScanNut';
  static const String supportEmail = 'contato@multiversodigital.com.br';

  /// Standard method for direct PDF output if needed (legacy or debug)
  Future<void> saveAndShow({
    required pw.Document pdf,
    required String fileName,
  }) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: fileName,
    );
  }

  /// RIGOROUS HEADER: Consistent across all reports (Eco-Friendly)
  pw.Widget buildHeader(String title, String timestamp, {String dateLabel = 'Data', PdfColor? color}) {
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
                      color: (color == colorPet) ? PdfColors.black : (color != null ? PdfColors.white : PdfColors.black),
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
                        color: (color == colorPet) ? PdfColors.black : (color != null ? PdfColors.white : PdfColors.black),
                      ),
                    ),
                    pw.Text(
                      '$dateLabel: $timestamp',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: color != null ? PdfColors.white : PdfColors.grey700,
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

  /// RIGOROUS FOOTER: Consistent across all reports
  pw.Widget buildFooter(pw.Context context, {AppLocalizations? strings}) {

    final pageText = strings != null 
        ? strings.pdfPage(context.pageNumber, context.pagesCount)
        : 'Página ${context.pageNumber} de ${context.pagesCount}';

    return pw.Column(
      children: [
        pw.Divider(thickness: 0.5, color: PdfColors.grey300),
        pw.SizedBox(height: 5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(appName, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
            pw.Text(pageText, 
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
            pw.Text(supportEmail, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          ],
        ),
      ],
    );
  }

  /// INDICATOR BLOCK HELPER
  pw.Widget buildIndicator(String label, String value, PdfColor color) {

    final cleaned = _cleanValue(value);
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        color: PdfColors.white, // No background color
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
             children: [
                pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                if (cleaned.isEstimated) ...[
                   pw.SizedBox(width: 4),
                   pw.Text('*', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.black)), // Black asterisk
                ]
             ],
          ),
          pw.SizedBox(height: 2),
          pw.Text(cleaned.value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.black)), // Always black text
        ],
      ),
    );
  }

  _CleanedValue _cleanValue(String? value) {
    if (value == null) return _CleanedValue('---', false);
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

    return _CleanedValue(cleaned, isEstimated);
  }

  Iterable<pw.Widget> _buildObservationsBlock(String observations, AppLocalizations strings) sync* {
    if (observations.isEmpty) return;

    // V64: Strict Truncation
    String safeObs = observations;
    if (safeObs.length > 1000) safeObs = safeObs.substring(0, 1000) + '...';

    yield pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: colorPetUltraLight, 
        border: pw.Border.all(color: colorPet, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            strings.pdfObservationsTitle,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            safeObs,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
          ),
        ],
      ),
    );
  }

  // --- REPORT GENERATORS ---

  /// 1. AGENDA REPORT (UNIFIED LAYOUT)
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
    final String timestampStr = DateFormat.yMd(strings.localeName).add_Hm().format(DateTime.now());
    final int totalCount = events.length;
    final int completedCount = events.where((e) => e.completed).length;
    final int pendingCount = totalCount - completedCount;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (context) => buildHeader(strings.pdfAgendaReport, timestampStr, color: colorPet),
        footer: (context) => buildFooter(context),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              buildIndicator('${strings.pdfTotalEvents}:', totalCount.toString(), PdfColors.black),
              buildIndicator('${strings.pdfCompletedEvents}:', completedCount.toString(), PdfColors.green700),
              buildIndicator('${strings.pdfPendingEvents}:', pendingCount.toString(), PdfColors.red700),
            ],
          ),
          pw.SizedBox(height: 25),
          if (reportType == 'Detalhamento')
            pw.Table.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
              headerDecoration: pw.BoxDecoration(color: colorPet),
              headerStyle: pw.TextStyle(color: PdfColors.black, fontWeight: pw.FontWeight.bold, fontSize: 9),
              cellStyle: const pw.TextStyle(fontSize: 7.5, color: PdfColors.black),
              headers: [strings.pdfDate, strings.pdfFieldEvent, strings.pdfFieldPet, strings.pdfFieldCategory, strings.pdfObservations, strings.pdfStatus],
              data: events.map((e) => [
                DateFormat.yMd(strings.localeName).add_Hm().format(e.dateTime),
                e.title,
                e.petName,
                e.getLocalizedTypeLabel(strings),
                e.notes ?? ' - ',
                e.completed ? strings.pdfCompleted : strings.pdfPending,
              ]).toList(),
            )
          else
            pw.Center(
              child: pw.Text(strings.pdfSummaryReport, 
                style: pw.TextStyle(color: PdfColors.grey500, fontStyle: pw.FontStyle.italic, fontSize: 10)),
            ),
        ],
      ),
    );
    return pdf;
  }

  /// 2. PARTNERS REPORT (UNIFIED LAYOUT)
  Future<pw.Document> generatePartnersReport({
    required List<PartnerModel> partners, 
    required String region,
    required AppLocalizations strings,
  }) async {
    final pdf = pw.Document();
    final String timestampStr = DateFormat.yMd(strings.localeName).add_Hm().format(DateTime.now());
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (context) => buildHeader(strings.pdfPartnersGuide, timestampStr, color: colorPet),
        footer: (context) => buildFooter(context),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              buildIndicator('${strings.pdfRegion}:', region, PdfColors.black),
              buildIndicator('${strings.pdfTotalFound}:', partners.length.toString(), PdfColors.blue700),
            ],
          ),
          pw.SizedBox(height: 25),
          pw.Table.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
            headerDecoration: pw.BoxDecoration(color: colorPet),
            headerStyle: pw.TextStyle(color: PdfColors.black, fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
            headers: [strings.pdfEstablishment, strings.pdfFieldCategory, strings.pdfPhone, strings.pdfRating],
            data: partners.map((p) => [
              p.name,
              p.category,
              p.phone,
              '${p.rating} ${strings.pdfStars}',
            ]).toList(),
          ),
        ],
      ),
    );
    return pdf;
  }

  /// 4. RADAR REPORT (GEO DISCOVERY)
  Future<pw.Document> generateRadarReport({
    required List<PartnerModel> partners,
    required double userLat,
    required double userLng,
    required AppLocalizations strings,
  }) async {
    final pdf = pw.Document();
    final String timestampStr = DateFormat.yMd(strings.localeName).add_Hm().format(DateTime.now());
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (context) => buildHeader('RADAR GEO - SCANNUT', timestampStr, color: colorPet, dateLabel: strings.pdfDate),
        footer: (context) => buildFooter(context, strings: strings),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              buildIndicator('${strings.pdfStatus}:', 'RESULTADOS PRÓXIMOS', colorPet),
              buildIndicator('${strings.pdfTotalFound}:', partners.length.toString(), colorPet),
            ],
          ),
          pw.SizedBox(height: 25),
          pw.Table.fromTextArray(
            border: pw.TableBorder.all(color: colorPet, width: 0.5),
            headerDecoration: pw.BoxDecoration(color: colorPet),
            headerStyle: pw.TextStyle(color: PdfColors.black, fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 7.5, color: PdfColors.black),
            headers: [
                strings.pdfEstablishment.toUpperCase(), 
                strings.distanceLabel?.toUpperCase() ?? 'DISTÂNCIA', 
                strings.ratingLabel?.toUpperCase() ?? 'AVALIAÇÃO', 
                strings.pdfFieldAddress?.toUpperCase() ?? 'ENDEREÇO', 
                strings.pdfPhone.toUpperCase()
            ],
            data: partners.map((p) {
              final dist = PartnerService().calculateDistance(userLat, userLng, p.latitude, p.longitude);
              return [
                p.name,
                '${dist.toStringAsFixed(1)} km',
                '${p.rating} ${strings.pdfStars}',
                p.address,
                p.phone.isNotEmpty ? p.phone : (p.whatsapp ?? ' - '),
              ];
            }).toList(),
          ),
        ],
      ),
    );
    return pdf;
  }

  /// 3. WEEKLY MENU REPORT (SCANNUT STANDARD)
  Future<pw.Document> generateWeeklyMenuReport({
    required String petName, 
    required String raceName,
    required String dietType,
    required List<Map<String, dynamic>> plan, 
    required AppLocalizations strings,
    String? guidelines,
    String? dailyKcal,
    String? period, // Added period
    Map<String, List<Map<String, dynamic>>>? shoppingLists,
  }) async {
    debugPrint('🚀 [V62-TRACE] Iniciando build do PDF: Nome do Pet: $petName');
    debugPrint('🎨 [V62-TRACE] Carregando cores do tema de Domínio Pet: Rosa Pastel (#FFD1DC)');
    debugPrint('📊 [V62-TRACE] Verificando dados do cardápio: ${plan.length} itens encontrados');

    final pdf = pw.Document();
    final String timestampStr = DateFormat.yMd(strings.localeName).add_Hm().format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (context) => buildHeader(strings.pdfNutritionSection, timestampStr, color: colorPet),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(thickness: 0.5, color: PdfColors.black),
            pw.SizedBox(height: 5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Gerado por ScanNut - Governança Pet & Inteligência Artificial', 
                       style: pw.TextStyle(fontSize: 7, fontStyle: pw.FontStyle.italic, color: PdfColors.black)),
                pw.Text('${strings.pdfPage(context.pageNumber, context.pagesCount)}', 
                       style: const pw.TextStyle(fontSize: 7, color: PdfColors.black)),
              ],
            ),
          ],
        ),
        build: (context) {
          final List<pw.Widget> content = [];
          
          // Header Info Card - Protocol V62: Background Rosa Pastel, Border Black
          content.add(
            pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: colorPetLight, // Rosa Suave
              border: pw.Border.all(color: PdfColors.black, width: 0.8),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('${strings.pdfFieldPet.toUpperCase()}: $petName', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColors.black)),
                    pw.Text('${strings.pdfFieldPeriod.toUpperCase()}: ${period ?? strings.pdfPeriodWeekly}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.black)),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('${strings.pdfFieldBreed.toUpperCase()}: $raceName', style: const pw.TextStyle(fontSize: 10, color: PdfColors.black)),
                    pw.Text('${strings.pdfFieldRegime.toUpperCase()}: $dietType', style: pw.TextStyle(color: PdfColors.black, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  ],
                ),
                if (dailyKcal != null) ...[
                  pw.SizedBox(height: 6),
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text('${strings.pdfFieldDailyKcalMeta.toUpperCase()}: $dailyKcal', style: pw.TextStyle(color: PdfColors.black, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  ),
                ],
              ],
            ),
          ));
          content.add(pw.SizedBox(height: 25));

          // HELPER for Days - Protocol V62 Layout
          List<pw.Widget> renderDays(List<Map<String, dynamic>> chunk) {
             return chunk.map((day) {
                final String dia = day['dia']?.toString() ?? 'Dia';
                final List<dynamic> meals = day['refeicoes'] as List? ?? [];
                
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 20),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 1.0),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                       pw.Container(
                        width: double.infinity,
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        color: colorPet, // Background Rosa Pastel
                        child: pw.Text(dia.toUpperCase(), style: pw.TextStyle(color: PdfColors.black, fontWeight: pw.FontWeight.bold, fontSize: 11)),
                      ),
                      ...meals.map((m) {
                        final meal = m as Map<String, dynamic>;
                        return pw.Container(
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 0.5)),
                          ),
                          padding: const pw.EdgeInsets.all(10),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Row(
                                    children: [
                                      pw.Container(
                                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: pw.BoxDecoration(color: colorPetLight),
                                        child: pw.Text(meal['hora'] ?? '--:--', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.black)),
                                      ),
                                      pw.SizedBox(width: 10),
                                      pw.Text(meal['titulo'] ?? 'Refeição', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.black)),
                                    ],
                                  ),
                                  if (dailyKcal != null)
                                    pw.Text(dailyKcal, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                                ],
                              ),
                              pw.SizedBox(height: 10),
                              pw.Text(strings.pdfFieldDetailsComposition, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                              pw.SizedBox(height: 4),
                              pw.Text(meal['descricao']?.toString() ?? '', style: const pw.TextStyle(fontSize: 9, color: PdfColors.black)),
                            ],
                          ),
                        );
                      }).toList(),
                      if (meals.isEmpty)
                        pw.Padding(padding: const pw.EdgeInsets.all(10), child: pw.Text(strings.pdfNoMealsPlanned, style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 9, color: PdfColors.black))),
                    ],
                  ),
                );
             }).toList();
          }

          // PROCESSING
          String? currentId;
          List<Map<String, dynamic>> buffer = [];
          
          if (plan.isNotEmpty) currentId = plan.first['planId'] as String? ?? plan.first['plan_id'] as String?;

          for (var item in plan) {
               final id = item['planId'] as String? ?? item['plan_id'] as String?;
               if (id != currentId && buffer.isNotEmpty) {
                    content.addAll(renderDays(buffer));
                    if (currentId != null && shoppingLists != null && shoppingLists[currentId] != null) {
                         content.add(pw.SizedBox(height: 20));
                         content.add(pw.Text(strings.petMenuShoppingList.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.black)));
                         content.add(pw.SizedBox(height: 10));
                         final list = shoppingLists[currentId]!;
                         content.add(pw.Table.fromTextArray(
                             border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
                             headerDecoration: pw.BoxDecoration(color: colorPet),
                             headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.black),
                             cellStyle: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
                             headers: [strings.commonItem ?? 'Item', strings.commonQuantity ?? 'Qtd', strings.commonCategory ?? 'Info'],
                             data: list.map((i) => [
                                i['item']?.toString() ?? i['name']?.toString() ?? '',
                                i['quantity']?.toString() ?? '',
                                i['category']?.toString() ?? ''
                             ]).toList()
                         ));
                         content.add(pw.NewPage()); // Break for next week
                    }
                    buffer = [];
                    currentId = id;
               }
               currentId = id; 
               buffer.add(item);
          }
          if (buffer.isNotEmpty) {
               content.addAll(renderDays(buffer));
               if (currentId != null && shoppingLists != null && shoppingLists[currentId] != null) {
                    content.add(pw.SizedBox(height: 20));
                    content.add(pw.Text(strings.petMenuShoppingList.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.black)));
                    content.add(pw.SizedBox(height: 10));
                    final list = shoppingLists[currentId]!;
                    content.add(pw.Table.fromTextArray(
                        border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
                        headerDecoration: pw.BoxDecoration(color: colorPet),
                        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.black),
                        cellStyle: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
                        headers: [strings.commonItem ?? 'Item', strings.commonQuantity ?? 'Qtd', strings.commonCategory ?? 'Info'],
                        data: list.map((i) => [
                           i['item']?.toString() ?? i['name']?.toString() ?? '',
                           i['quantity']?.toString() ?? '',
                           i['category']?.toString() ?? ''
                        ]).toList()
                    ));
               }
          }

          if (guidelines != null && guidelines.isNotEmpty) {
            content.add(pw.SizedBox(height: 25));
            content.add(pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                 color: colorPetUltraLight,
                 border: pw.Border.all(color: PdfColors.black, width: 0.5)
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('${strings.pdfFieldGeneralGuidelines}:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.black)),
                  pw.SizedBox(height: 6),
                  pw.Text(guidelines, style: const pw.TextStyle(fontSize: 10, color: PdfColors.black)),
                ],
              ),
            ));
          }

          debugPrint('✅ [DEBUG] Renderização do PDF concluída sem perdas');
          return content;
        }
      ),
    );
    return pdf;
  }

  /// 3.1 NUTRITION PLAN REPORT (HUMAN STANDARD)
  Future<pw.Document> generateHumanNutritionPlanReport({
    required String goal,
    required List<PlanDay> days,
    required AppLocalizations strings,
    String? batchCookingTips,
    String? shoppingListJson,
  }) async {
    final pdf = pw.Document();
    final String timestampStr = DateFormat('dd/MM/yyyy HH:mm', strings.localeName).format(DateTime.now());

    // Decode Shopping Lists
    final List<WeeklyShoppingList> weeklyShoppingLists = [];
    if (shoppingListJson != null && shoppingListJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(shoppingListJson);
        if (decoded is List) {
          for (var item in decoded) {
            if (item is Map) {
              weeklyShoppingLists.add(WeeklyShoppingList.fromJson(Map<String, dynamic>.from(item)));
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error decoding shopping list JSON for PDF: $e');
      }
    }

    // Determine how many weeks to print
    int numWeeks = (days.length / 7).ceil();

    // 🛡️ V80: CHROMATIC PURIFICATION - REAL ORANGE
    final orangeScanNut = PdfColor.fromHex('#FF9800');

    // ... (logic for loop)

    for (int w = 0; w < numWeeks; w++) {
      final startIdx = w * 7;
      final endIdx = (startIdx + 7) > days.length ? days.length : (startIdx + 7);
      final weekDays = days.sublist(startIdx, endIdx);
      final weekLabel = numWeeks > 1 ? ' - SEMANA ${w + 1}' : '';

      // --- WEEK MENU PAGE ---
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(35),
          header: (context) => buildHeader('${strings.pdfMenuPlanTitle}${weekLabel.toUpperCase()}', timestampStr, color: orangeScanNut),
          footer: (context) => buildFooter(context, strings: strings),
          build: (context) => [
            // Header Info Card - White Bg, Orange Border
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: null, // Transparent/White
                border: pw.Border.all(color: orangeScanNut, width: 0.5),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(strings.pdfPersonalizedPlanTitle, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                      pw.Text('${strings.pdfGoalLabel}: $goal', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: orangeScanNut)),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(strings.pdfGeneratedByLine, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Detailed Days
            ...weekDays.map((day) {
              final String diaStr = DateFormat.MMMEd(strings.localeName).format(day.date).toUpperCase();
              
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 20),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: orangeScanNut, width: 1.0),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Day Header - Orange Solid Bg
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      color: orangeScanNut,
                      child: pw.Text(
                        diaStr,
                        style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 11),
                      ),
                    ),
                    
                    // Meals with Partition Protection (V80)
                    ...day.meals.map((meal) {
                      return pw.Wrap( // 🛡️ V80: Wrap to prevent infinite layout loop
                        children: [
                          pw.Container(
                            decoration: pw.BoxDecoration(
                              border: pw.Border(bottom: pw.BorderSide(color: orangeScanNut, width: 0.5)),
                            ),
                            padding: const pw.EdgeInsets.all(12),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Text(
                                      _getMealLabel(meal.tipo, strings).toUpperCase(),
                                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: orangeScanNut),
                                    ),
                                    if (meal.nomePrato != null)
                                      pw.Text(
                                        meal.nomePrato!,
                                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.black),
                                      ),
                                  ],
                                ),
                                if (meal.observacoes.isNotEmpty) ...[
                                  pw.SizedBox(height: 8),
                                  pw.Text(
                                    meal.observacoes,
                                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                                  ),
                                ],
                                pw.SizedBox(height: 10),
                                pw.Text(strings.ingredientsTitle, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                                pw.SizedBox(height: 4),
                                ...meal.itens.map((item) => pw.Padding(
                                  padding: const pw.EdgeInsets.only(left: 10, bottom: 2),
                                  child: pw.Row(
                                    children: [
                                      pw.Container(width: 3, height: 3, decoration: pw.BoxDecoration(color: orangeScanNut, shape: pw.BoxShape.circle)),
                                      pw.SizedBox(width: 6),
                                      pw.Expanded(child: pw.Text(item.nome, style: const pw.TextStyle(fontSize: 9))),
                                      pw.Text(item.quantidadeTexto, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                                    ],
                                  ),
                                )).toList(),
                              ],
                            ),
                          )
                        ]
                      );
                    }).toList(),
                  ],
                ),
              );
            }).toList(),
            
            if (w == 0 && batchCookingTips != null && batchCookingTips.isNotEmpty) ...[
               pw.SizedBox(height: 10),
               pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: null, // White
                  border: pw.Border.all(color: orangeScanNut, width: 0.5),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(strings.pdfBatchCookingTips, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: orangeScanNut)),
                    pw.SizedBox(height: 8),
                    pw.Text(batchCookingTips, style: const pw.TextStyle(fontSize: 10, height: 1.3)),
                  ],
                ),
              ),
            ],
          ],
        ),
      );

      // --- WEEK SHOPPING LIST PAGE ---
      if (w < weeklyShoppingLists.length) {
         final weekShopping = weeklyShoppingLists[w];
         pdf.addPage(
           pw.MultiPage(
             pageFormat: PdfPageFormat.a4,
             margin: const pw.EdgeInsets.all(35),
             header: (context) => buildHeader('LISTA DE COMPRAS${weekLabel.toUpperCase()}', timestampStr, color: colorFood),
             footer: (context) => buildFooter(context, strings: strings),
             build: (context) => [
               pw.Text(
                 'Esta lista consolidada refere-se aos itens necessários para a ${weekShopping.weekLabel}. Quantidades somadas e organizadas por setor.',
                 style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
               ),
               pw.SizedBox(height: 15),

               ...weekShopping.categories.map((cat) {
                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                       pw.Container(
                         width: double.infinity,
                         margin: const pw.EdgeInsets.only(top: 10, bottom: 8),
                         padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          decoration: const pw.BoxDecoration(
                             color: PdfColors.grey200,
                             borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                          ),
                         child: pw.Text(
                           cat.title.toUpperCase(), 
                           style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.black)
                         ),
                       ),
                       
                       pw.Wrap(
                         spacing: 20,
                         runSpacing: 10,
                         children: cat.items.map((item) {
                            return pw.Container(
                              width: 230,
                              child: pw.Row(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Container(
                                    width: 12, height: 12,
                                    margin: const pw.EdgeInsets.only(top: 1),
                                    decoration: pw.BoxDecoration(
                                       border: pw.Border.all(color: PdfColors.black, width: 1), 
                                       borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2))
                                    ),
                                  ),
                                  pw.SizedBox(width: 8),
                                  pw.Expanded(
                                    child: pw.RichText(
                                      text: pw.TextSpan(
                                        children: [
                                           pw.TextSpan(
                                             text: '${item.quantityDisplay} · ', 
                                             style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.black)
                                           ),
                                           pw.TextSpan(
                                             text: item.name, 
                                             style: const pw.TextStyle(fontSize: 10, color: PdfColors.black)
                                           ),
                                           if (item.kcalTotal > 0)
                                             pw.TextSpan(
                                               text: ' — ${item.kcalTotal} kcal', 
                                               style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)
                                             ),
                                        ]
                                      )
                                    )
                                  )
                                ]
                              )
                            );
                         }).toList(),
                       ),
                       pw.SizedBox(height: 5),
                    ],
                  );
               }).toList(),
             ],
           ),
         );
      }
    }
    return pdf;
  }

  String _getMealLabel(String? tipo, AppLocalizations strings) {
    if (tipo == null) return '';
    switch (tipo.toLowerCase()) {
      case 'cafe': return strings.mealBreakfast;
      case 'almoco': return strings.mealLunch;
      case 'lanche': return strings.mealSnack;
      case 'jantar': return strings.mealDinner;
      default: return tipo;
    }
  }

  /// 4. FOOD ANALYSIS REPORT (UNIFIED LAYOUT)
  Future<pw.Document> generateFoodAnalysisReport({required FoodAnalysisModel analysis, required AppLocalizations strings, File? imageFile}) async {
    final pdf = pw.Document();
    final String timestampStr = DateFormat('dd/MM/yyyy HH:mm', strings.localeName).format(DateTime.now());
    
    // Carregar imagem se disponível
    pw.ImageProvider? foodImage;
    if (imageFile != null) {
      foodImage = await safeLoadImage(imageFile.path);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (context) => buildHeader(strings.pdfFoodTitle, timestampStr, dateLabel: strings.pdfDate, color: colorFood),
        footer: (context) => buildFooter(context, strings: strings),
        build: (context) => [
          // --- HEADER COM IMAGEM E DADOS BÁSICOS ---
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (foodImage != null)
                pw.Container(
                  width: 80,
                  height: 80,
                  margin: const pw.EdgeInsets.only(right: 15),
                  decoration: pw.BoxDecoration(
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    border: pw.Border.all(color: PdfColors.grey400),
                  ),
                  child: pw.ClipRRect(
                    horizontalRadius: 8,
                    verticalRadius: 8,
                    child: pw.Image(foodImage, fit: pw.BoxFit.cover),
                  ),
                ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(analysis.identidade.nome, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, color: PdfColors.black)),
                    pw.SizedBox(height: 5),
                    pw.Row(

                      children: [
                        buildIndicator('${strings.pdfCalories}:', '${analysis.macros.calorias100g} kcal/100g', PdfColors.red700),
                        pw.SizedBox(width: 10),
                         buildIndicator('${strings.pdfTrafficLight}:', analysis.identidade.semaforoSaude, 
                          analysis.identidade.semaforoSaude.toLowerCase() == 'verde' || analysis.identidade.semaforoSaude.toLowerCase() == 'green' ? PdfColors.green700 : 
                          (analysis.identidade.semaforoSaude.toLowerCase() == 'amarelo' || analysis.identidade.semaforoSaude.toLowerCase() == 'yellow' ? PdfColors.amber700 : PdfColors.red700)),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text('${strings.pdfProcessing}: ${analysis.identidade.statusProcessamento}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
              ),
            ],
          ),
          
          pw.SizedBox(height: 20),

          // --- 1. RESUMO EXECUTIVO ---
          buildSectionHeader(strings.pdfExSummary, color: colorFood),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5))),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('${strings.pdfAiVerdict}:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.Text(analysis.analise.vereditoIa, style: const pw.TextStyle(fontSize: 9)), // Removed italic
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('${strings.pdfPros}:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.green700)),
                    ...analysis.analise.pontosPositivos.map((p) => pw.Bullet(text: p, style: const pw.TextStyle(fontSize: 8))),
                  ],
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('${strings.pdfCons}:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.amber700)),
                    ...analysis.analise.pontosNegativos.map((p) => pw.Bullet(text: p, style: const pw.TextStyle(fontSize: 8))),
                  ],
                ),
              ),
            ],
          ),

          // --- 2. NUTRIÇÃO DETALHADA ---
          buildSectionHeader(strings.pdfDetailedNutrition, color: colorFood),
          pw.Text('${strings.pdfMacros}:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.SizedBox(height: 5),
          pw.Table.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headers: [strings.pdfNutrient, strings.pdfQuantity, strings.pdfDetails],
            data: [
              [strings.nutrientsProteins, analysis.macros.proteinas, strings.labelAminoProfile],
              [strings.nutrientsCarbs, analysis.macros.carboidratosLiquidos, '${strings.labelGlycemicImpact}: ${analysis.macros.indiceGlicemico}'],
              [strings.nutrientsFats, analysis.macros.gordurasPerfil, strings.labelFattyAcids],
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Text('${strings.pdfMicros}:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
           pw.Wrap(
            spacing: 10,
            runSpacing: 5,
            children: analysis.micronutrientes.lista.map((n) => 
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
                child: pw.Text('${n.nome}: ${n.quantidade} (${n.percentualDv}%)', style: const pw.TextStyle(fontSize: 8)),
              )
            ).toList(),
          ),
          pw.SizedBox(height: 5),
          pw.Text('${strings.pdfSynergy}: ${analysis.micronutrientes.sinergiaNutricional}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.blue700)), // Removed italic

          // --- 3. BIOHACKING & SAÚDE ---
          buildSectionHeader(strings.pdfBiohacking, color: colorFood),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
               pw.Expanded(
                 child: pw.Column(
                   crossAxisAlignment: pw.CrossAxisAlignment.start,
                   children: [
                     pw.Text('${strings.pdfPerformance}:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                     pw.Bullet(text: '${strings.pdfSatiety}: ${analysis.performance.indiceSaciedade}/5', style: const pw.TextStyle(fontSize: 8)),
                     pw.Bullet(text: '${strings.pdfFocus}: ${analysis.performance.impactoFocoEnergia}', style: const pw.TextStyle(fontSize: 8)),
                     pw.Bullet(text: '${strings.pdfIdealMoment}: ${analysis.performance.momentoIdealConsumo}', style: const pw.TextStyle(fontSize: 8)),
                   ]
                 ),
               ),
               pw.SizedBox(width: 10),
               pw.Expanded(
                 child: pw.Column(
                   crossAxisAlignment: pw.CrossAxisAlignment.start,
                   children: [
                     pw.Text('${strings.pdfSecurity}:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                     pw.Bullet(text: '${strings.pdfAlerts}: ${analysis.identidade.alertaCritico}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.red700)),
                     pw.Bullet(text: '${strings.pdfBiochem}: ${analysis.identidade.bioquimicaAlert}', style: const pw.TextStyle(fontSize: 8)),
                   ]
                 ),
               ),
            ],
          ),

          // --- 4. GASTRONOMIA ---
          buildSectionHeader(strings.pdfGastronomy, color: colorFood),
          if (analysis.receitas.isNotEmpty) ...[
              pw.Text('${strings.pdfQuickRecipes}:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              ...analysis.receitas.map((r) => pw.Container(
                  margin: const pw.EdgeInsets.symmetric(vertical: 4),
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(color: PdfColors.orange50, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
                  child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(r.nome, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                              pw.Text(r.tempoPreparo, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.orange800)),
                            ]
                          ),
                          pw.Text(r.instrucoes, style: const pw.TextStyle(fontSize: 8)),
                      ]
                  )
              )).toList(),
              pw.SizedBox(height: 10),
          ],
          
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: buildIndicator(strings.foodPreservation, analysis.gastronomia.preservacaoNutrientes, PdfColors.black)),
              pw.SizedBox(width: 10),
              pw.Expanded(child: buildIndicator(strings.foodSmartSwap, analysis.gastronomia.smartSwap, PdfColors.black)),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.amber, width: 1), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
            child: pw.Column(
               crossAxisAlignment: pw.CrossAxisAlignment.start,
               children: [
                 pw.Row(children: [pw.Icon(const pw.IconData(0xe80e), color: PdfColors.amber, size: 12), pw.SizedBox(width: 5), pw.Text(strings.recipesExpertTip, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.amber800))]),
                 pw.SizedBox(height: 4),
                 pw.Text(analysis.gastronomia.dicaEspecialista, style: const pw.TextStyle(fontSize: 9)),
               ]
            ),
          ),
        ],
      ),
    );
    return pdf;
  }

  /// 4.1 PLANT ANALYSIS REPORT (SCANNUT BOTANY STANDARD)
  Future<pw.Document> generatePlantAnalysisReport({
    required PlantAnalysisModel analysis, 
    required AppLocalizations strings,
    File? imageFile
  }) async {
    final pdf = pw.Document();
    final String timestampStr = DateFormat('dd/MM/yyyy HH:mm', strings.localeName).format(DateTime.now());
    
    pw.ImageProvider? plantImage;
    if (imageFile != null) {
      plantImage = await safeLoadImage(imageFile.path);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (context) => buildHeader(strings.botanyDossierTitle(analysis.plantName), timestampStr, color: colorPlant),
        footer: (context) => buildFooter(context, strings: strings),
        build: (context) => [
          // Header with image and basic info
          if (analysis.segurancaBiofilia.segurancaDomestica['is_toxic_to_pets'] == true ||
              analysis.segurancaBiofilia.segurancaDomestica['toxica_para_pets'] == true ||
              analysis.segurancaBiofilia.segurancaDomestica['toxica_para_criancas'] == true ||
              analysis.segurancaBiofilia.segurancaDomestica['is_toxic_to_children'] == true)
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 20),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.red50,
                border: pw.Border.all(color: PdfColors.red, width: 2),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                children: [
                   pw.Text('⚠️', style: const pw.TextStyle(fontSize: 24)),
                   pw.SizedBox(width: 10),
                   pw.Expanded(
                     child: pw.Column(
                       crossAxisAlignment: pw.CrossAxisAlignment.start,
                       children: [
                         pw.Text(strings.toxicityWarning.toUpperCase(), style: pw.TextStyle(color: PdfColors.red900, fontWeight: pw.FontWeight.bold, fontSize: 14)),
                         pw.Text(analysis.segurancaBiofilia.segurancaDomestica['toxicity_details'] ?? analysis.segurancaBiofilia.segurancaDomestica['sintomas_ingestao'] ?? strings.plantDangerPets, style: const pw.TextStyle(color: PdfColors.red900, fontSize: 10)),
                       ],
                     ),
                   ),
                ],
              ),
            ),
            
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (plantImage != null)
                pw.Container(
                  width: 100,
                  height: 100,
                  margin: const pw.EdgeInsets.only(right: 15),
                  decoration: pw.BoxDecoration(
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    border: pw.Border.all(color: PdfColors.green700, width: 2),
                  ),
                  child: pw.ClipRRect(
                    horizontalRadius: 6,
                    verticalRadius: 6,
                    child: pw.Image(plantImage, fit: pw.BoxFit.cover),
                  ),
                ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(analysis.identificacao.nomesPopulares.isNotEmpty ? analysis.identificacao.nomesPopulares.join(', ') : analysis.identificacao.nomeCientifico, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, color: PdfColors.green900)),
                    pw.Text(analysis.identificacao.nomeCientifico, style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 14, color: PdfColors.green700)),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      children: [
                        buildIndicator(strings.tabHealth + ':', analysis.saude.condicao, analysis.isHealthy ? PdfColors.green700 : PdfColors.red700),
                        pw.SizedBox(width: 10),
                         buildIndicator(strings.plantFamily + ':', analysis.identificacao.familia, PdfColors.black),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          pw.SizedBox(height: 20),

          // 1. IDENTIFICAÇÃO E TAXONOMIA
          buildSectionHeader('1. ${strings.plantIdentificationTaxonomy}', color: colorPlant),
          pw.Text('${strings.plantPopularNames}: ${analysis.identificacao.nomesPopulares.join(', ')}'),
          pw.Text('${strings.plantScientificName}: ${analysis.identificacao.nomeCientifico}'),
          pw.Text('${strings.plantFamily}: ${analysis.identificacao.familia}'),
          pw.Text('${strings.plantOrigin}: ${analysis.identificacao.origemGeografica}'),
          pw.SizedBox(height: 10),

          // 2. DIAGNÓSTICO DE SAÚDE
          buildSectionHeader('2. ${strings.plantClinicalDiagnosis}', color: colorPlant),
          pw.Text('${strings.plantClinicalDiagnosis}: ${analysis.saude.condicao}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text('${strings.plantDetails}: ${analysis.saude.detalhes}'),
          pw.Text('${strings.plantRecoveryPlan}: ${analysis.saude.planoRecuperacao}'),
          if (!analysis.isHealthy)
             pw.Text('${strings.plantUrgency}: ${analysis.saude.urgencia}', style: pw.TextStyle(color: PdfColors.red700, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),

          // 3. GUIA DE SOBREVIVÊNCIA (HARDWARE)
          buildSectionHeader('3. ${strings.tabHardware} (${strings.labelTrafficLight})', color: colorPlant),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text(strings.plantNeedSun, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.Text(analysis.sobrevivencia.luminosidade['type'] ?? analysis.sobrevivencia.luminosidade['tipo'] ?? strings.noInformation),
                pw.Text(analysis.sobrevivencia.luminosidade['explanation'] ?? analysis.sobrevivencia.luminosidade['explicacao'] ?? '', style: const pw.TextStyle(fontSize: 8)),
              ])),
              pw.SizedBox(width: 20),
              pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text(strings.plantNeedWater, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.Text(analysis.sobrevivencia.regimeHidrico['frequency'] ?? analysis.sobrevivencia.regimeHidrico['frequencia_ideal'] ?? strings.noInformation),
                pw.Text(analysis.sobrevivencia.regimeHidrico['thirst_signs'] ?? analysis.sobrevivencia.regimeHidrico['sinais_sede'] ?? '', style: const pw.TextStyle(fontSize: 8)),
              ])),
            ]
          ),
          pw.SizedBox(height: 10),
          pw.Text('${strings.plantNeedSoil} & ${strings.tabNutrition}:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.Text('${strings.plantSubstrate}: ${analysis.sobrevivencia.soloENutricao['soil_type'] ?? analysis.sobrevivencia.soloENutricao['composicao_substrato'] ?? strings.noInformation}'),
          pw.Text('${strings.plantFertilizer}: ${analysis.sobrevivencia.soloENutricao['fertilizer'] ?? analysis.sobrevivencia.soloENutricao['adubo_recomendado'] ?? strings.noInformation}'),
          if (analysis.sobrevivencia.soloENutricao['ideal_ph'] != null)
             pw.Text('${strings.plantIdealPh}: ${analysis.sobrevivencia.soloENutricao['ideal_ph']}'),

          // 4. SEGURANÇA E BIOFILIA (BIOS)
          buildSectionHeader('4. ${strings.tabBios} (${strings.plantHomeSafety})', color: colorPlant),
          pw.Row(children: [
            pw.Expanded(child: pw.Text('${strings.plantDangerPets}: ${(analysis.segurancaBiofilia.segurancaDomestica['is_toxic_to_pets'] == true || analysis.segurancaBiofilia.segurancaDomestica['toxica_para_pets'] == true) ? "${strings.commonYes} ⚠️" : "${strings.commonNo} ✅"}')),
            pw.Expanded(child: pw.Text('${strings.plantDangerKids}: ${(analysis.segurancaBiofilia.segurancaDomestica['is_toxic_to_children'] == true || analysis.segurancaBiofilia.segurancaDomestica['toxica_para_criancas'] == true) ? "${strings.commonYes} ⚠️" : "${strings.commonNo} ✅"}')),
          ]),
          pw.Text('${strings.plantToxicityDetails}: ${analysis.segurancaBiofilia.segurancaDomestica['toxicity_details'] ?? analysis.segurancaBiofilia.segurancaDomestica['sintomas_ingestao'] ?? strings.plantNoAlerts}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.red700)),
          pw.SizedBox(height: 10),
          pw.Text(strings.plantBioPower, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.Text('${strings.plantAirScore}: ${analysis.segurancaBiofilia.poderesBiofilicos['air_purification_score'] ?? analysis.segurancaBiofilia.poderesBiofilicos['purificacao_ar_score'] ?? 5}/10'),
          pw.Text('${strings.plantWellness}: ${analysis.segurancaBiofilia.poderesBiofilicos['wellness_impact'] ?? analysis.segurancaBiofilia.poderesBiofilicos['impacto_bem_estar'] ?? strings.noInformation}'),

          // 5. ENGENHARIA DE PROPAGAÇÃO
          buildSectionHeader('5. ${strings.plantPropagationEngine}', color: colorPlant),
          pw.Text('${strings.plantMethod}: ${analysis.propagacao.metodo}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text('${strings.plantDifficulty}: ${analysis.propagacao.dificuldade}'),
          pw.Text('${strings.plantStepByStep}: ${analysis.propagacao.passoAPasso}'),

          // 6. INTELIGÊNCIA DE ECOSSISTEMA
          buildSectionHeader('6. ${strings.plantEcoIntel}', color: colorPlant),
          pw.Text('${strings.plantCompanions}: ${analysis.ecossistema.plantasParceiras.join(", ")}'),
          pw.Text('${strings.plantAvoid}: ${analysis.ecossistema.plantasConflitantes.join(", ")}'),
          pw.Text('${strings.plantRepellent}: ${analysis.ecossistema.repelenteNatural}'),

          // 7. ESTÉTICA E LIFESTYLE (FENG SHUI)
          buildSectionHeader('7. ${strings.tabLifestyle}', color: colorPlant),
          pw.Text('${strings.plantPlacement}: ${analysis.lifestyle.posicionamentoIdeal}'),
          pw.Text('${strings.plantSymbolism}: ${analysis.lifestyle.simbolismo}'),
          pw.SizedBox(height: 10),
          pw.Text(strings.plantLivingAesthetic, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.Text('${strings.plantFlowering}: ${analysis.estetica.epocaFloracao}'),
          pw.Text('${strings.plantFlowerColor}: ${analysis.estetica.corDasFlores}'),
          pw.Text('${strings.plantGrowth}: ${analysis.estetica.velocidadeCrescimento}'),
          pw.Text('${strings.plantMaxSize}: ${analysis.estetica.tamanhoMaximo}'),
        ],
      ),
    );
    return pdf;
  }

  Iterable<pw.Widget> _buildRecursivePDFMap(Map<dynamic, dynamic> map, {double indent = 0}) sync* {
     for (var e in map.entries.where((e) => e.value != null)) {
        final key = e.key.toString();
        // Filter technical/redundant keys inside sub-maps if needed
        if (['tabela_benigna', 'tabela_maligna'].contains(key)) continue;
        
        if (e.value is Map) {
           yield pw.SizedBox(height: 4);
           yield pw.Padding(
             padding: pw.EdgeInsets.only(left: indent),
             child: pw.Text(
               key.replaceAll('_', ' ').toUpperCase(),
               style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: colorPet) // V64: Consistent Pink
             )
           );
           yield pw.Divider(color: PdfColors.grey300, thickness: 0.5, indent: indent, endIndent: 20);
           yield* _buildRecursivePDFMap(e.value as Map, indent: indent + 10);
           yield pw.SizedBox(height: 6);
           continue;
        }

        // Simple Value
        String val = e.value.toString();
        // V64: Strict Truncation (Safety First)
        if (val.length > 500) val = val.substring(0, 500) + '...';
        
        yield pw.Padding(
          padding: pw.EdgeInsets.only(left: indent, bottom: 3),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
               pw.SizedBox(
                 width: 120, 
                 child: pw.Text('${key.replaceAll('_', ' ').toUpperCase()}:', 
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.black))
               ),
               pw.Expanded(child: pw.Text(val, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800))),
            ]
          )
        );
     }
  }

  Iterable<pw.Widget> _buildAnalysisResultSection(Map<String, dynamic> data, AppLocalizations strings) sync* {
    // Filter top-level
    final filteredData = Map<String, dynamic>.from(data);
    filteredData.removeWhere((key, value) => 
        ['pet_name', 'analysis_type', 'last_updated', 'image_path', 'plano_semanal', 'tabela_benigna', 'tabela_maligna'].contains(key));

    yield buildSectionHeader(strings.petAnalysisResults.toUpperCase(), color: colorPet);
    yield pw.SizedBox(height: 10);
    yield* _buildRecursivePDFMap(filteredData);
    yield pw.SizedBox(height: 20);
  }

  /// 5. COMPREHENSIVE PET PROFILE REPORT - COMPLETE VETERINARY DOSSIER
   Future<pw.Document> generatePetProfileReport({
     required PetProfileExtended profile,
     required AppLocalizations strings,
     Map<String, bool>? selectedSections,
   }) async {
    final pdf = pw.Document();
    final String timestampStr = DateFormat.yMd(strings.localeName).add_Hm().format(DateTime.now());
    
    // Default: all sections enabled if not specified
    final sections = selectedSections ?? {
      'identity': true,
      'health': true,
      'nutrition': true,
      'gallery': true,
      'parc': true,
    };

    // --- CRITICAL DATA LOADING ---
    // 1. Medical Events (Vaccines, Meds, etc.)
    List<PetEvent> medicalEvents = [];
    List<PetEvent> allAgendaEvents = [];
    try {
        await PetEventService().init();
        final allEvents = PetEventService().getEventsByPet(profile.petName);
        
        // Separate medical events for health section
         medicalEvents = allEvents.where((e) {
            final t = e.type;
            final title = e.title.toLowerCase();
            return t == EventType.vaccine || 
                   t == EventType.medication || 
                   t == EventType.veterinary ||
                   t == EventType.bath || 
                   t == EventType.grooming ||
                   title.contains('verm') || 
                   title.contains('vacina') ||
                   title.contains('cirurgia') ||
                   title.contains('pulga') ||
                   title.contains('carrapato');
        }).toList();
        medicalEvents.sort((a,b) => b.dateTime.compareTo(a.dateTime));
        
        // All events for agenda section (sorted by date, most recent first)
        allAgendaEvents = List.from(allEvents);
        allAgendaEvents.sort((a,b) => b.dateTime.compareTo(a.dateTime));
        
        debugPrint('📅 Loaded ${allAgendaEvents.length} total agenda events, ${medicalEvents.length} medical events');
    } catch(e) { 
        debugPrint('❌ Error loading events: $e'); 
    }

    // 2. Gallery Images & Docs
    final List<Map<String, dynamic>> galleryImages = [];
    final List<String> otherDocNames = []; 
    if (sections['gallery'] == true) {
        try {
            debugPrint('📸 Loading gallery for pet: ${profile.petName}');
            final allDocs = await FileUploadService().getMedicalDocuments(profile.petName);
            debugPrint('📸 Found ${allDocs.length} documents');
            for (var file in allDocs) {
                final ext = path.extension(file.path).toLowerCase();
                debugPrint('📸 Processing file: ${file.path} (ext: $ext)');
                if (['.jpg', '.jpeg', '.png', '.webp'].contains(ext)) {
                    final memImg = await safeLoadImage(file.path);
                    if (memImg != null) {
                        final name = path.basename(file.path);
                        String caption = name;
                        if (name.contains('_')) caption = name.split('_').first.toUpperCase();
                        
                        galleryImages.add({
                            'image': memImg,
                            'caption': caption,
                        });
                        debugPrint('✅ Added image to gallery: $caption');
                    } else {
                        debugPrint('❌ Failed to load image: ${file.path}');
                    }
                } else {
                    otherDocNames.add(path.basename(file.path));
                    debugPrint('📄 Added document: ${path.basename(file.path)}');
                }
            }
            debugPrint('📸 Gallery loading complete: ${galleryImages.length} images, ${otherDocNames.length} docs');
        } catch(e) { 
            debugPrint('❌ Error loading gallery: $e'); 
        }
    }
    // ----------------------------
    
    // Load pet profile image if available
    pw.ImageProvider? profileImage = await safeLoadImage(profile.imagePath);
    
    // Calcular data base para o cardápio (Segunda-feira)
    final DateTime? savedStart = profile.rawAnalysis?['data_inicio_semana'] != null 
        ? DateTime.tryParse(profile.rawAnalysis!['data_inicio_semana']) 
        : null;
    
    DateTime startData;
    if (savedStart != null) {
        startData = savedStart;
    } else {
        final baseDate = profile.lastUpdated;
        startData = DateTime(baseDate.year, baseDate.month, baseDate.day).subtract(Duration(days: baseDate.weekday - 1));
    }

    // Pre-load wound images for Health Section if enabled
    final List<Map<String, dynamic>> woundsWithImages = [];
    if (sections['health'] == true && profile.woundAnalysisHistory.isNotEmpty) {
        final sortedWounds = List<Map<String, dynamic>>.from(profile.woundAnalysisHistory)
             ..sort((a, b) {
                try {
                  final da = DateTime.tryParse(a['date']?.toString() ?? '') ?? DateTime(2000);
                  final db = DateTime.tryParse(b['date']?.toString() ?? '') ?? DateTime(2000);
                  return db.compareTo(da);
                } catch (_) {
                  return 0;
                }
             });
        
        for (var w in sortedWounds) {
            final img = await safeLoadImage(w['imagePath']?.toString());
            woundsWithImages.add({
                ...w,
                'pdfImage': img
            });
        }
    }

    // Pre-load partner data for PARC Section
    final List<Map<String, dynamic>> linkedPartnersData = [];
    if (sections['parc'] == true && profile.linkedPartnerIds.isNotEmpty) {
        try {
            debugPrint('👥 Loading partner data for ${profile.linkedPartnerIds.length} partners');
            final partnerService = PartnerService();
            await partnerService.init();
            
            for (var partnerId in profile.linkedPartnerIds) {
                try {
                    final partner = partnerService.getPartner(partnerId);
                    if (partner != null) {
                        linkedPartnersData.add({
                            'id': partner.id,
                            'name': partner.name,
                            'category': partner.category,
                            'specialties': partner.specialties.join(', '),
                            'phone': partner.phone,
                            'address': partner.address,
                        });
                        debugPrint('✅ Loaded partner: ${partner.name}');
                    } else {
                        debugPrint('⚠️ Partner not found: $partnerId');
                    }
                } catch (e) {
                    debugPrint('❌ Error loading partner $partnerId: $e');
                }
            }
            debugPrint('👥 Partner loading complete: ${linkedPartnersData.length} partners loaded');
        } catch (e) {
            debugPrint('❌ Error initializing PartnerService: $e');
        }
    }

    // ========== COVER PAGE ==========
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                // Pet Photo
                if (profileImage != null)
                  pw.Container(
                    width: 200,
                    height: 200,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.black, width: 4), // Black border
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(100)),
                    ),
                    child: pw.ClipRRect(
                      horizontalRadius: 100,
                      verticalRadius: 100,
                      child: pw.Image(profileImage, fit: pw.BoxFit.cover),
                    ),
                  )
                else
                  pw.Container(
                    width: 200,
                    height: 200,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white, // White background
                      border: pw.Border.all(color: PdfColors.black, width: 4), // Black border
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(100)),
                    ),
                    child: pw.Center(
                      child: pw.Icon(
                        pw.IconData(0xe91f), 
                        color: PdfColors.black, 
                        size: 80,
                      ),
                    ),
                  ),
                pw.SizedBox(height: 30),
                // Pet Name
                pw.Text(
                  // profile.petName.toUpperCase(), // Name is universal
                  profile.petName.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 42,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
                pw.SizedBox(height: 10),
                // Subtitle
                pw.Text(
                  strings.pdfReportTitle,
                  style: pw.TextStyle(
                    fontSize: 16,
                    color: PdfColors.grey700,
                    letterSpacing: 2,
                  ),
                ),
                pw.SizedBox(height: 40),
                // Info Box
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    border: pw.Border.all(color: PdfColors.black, width: 2), // Black border
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        profile.raca ?? strings.petBreedMixed,
                        style: pw.TextStyle(
                          fontSize: 18,
                          color: PdfColors.black, // Black text
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        '${strings.pdfGeneratedOn}: $timestampStr',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Spacer(),
                // Footer
                pw.Text(
                  'ScanNut - ${strings.appTitle}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.SizedBox(height: 20),
              ],
            ),
        ),
      ),
    );

    // 🔍 [V64-TRACE] Calculando altura do conteúdo para o Pet: ${profile.petName}
    debugPrint('[V64-TRACE] Calculando altura do conteúdo para o Pet: ${profile.petName}');

    // ========== CONTENT PAGES ==========
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        maxPages: 20, // 🛡️ V64: Limite de Segurança
        margin: const pw.EdgeInsets.all(35),
        header: (context) => buildHeader('${strings.pdfReportTitle}: ${profile.petName}', timestampStr, dateLabel: strings.pdfGeneratedOn, color: colorPet),
        footer: (context) => buildFooter(context),
        build: (context) => [
          // ========== IDENTITY SECTION ==========
          if (sections['identity'] == true) ...[
            buildSectionHeader(strings.pdfIdentitySection, color: colorPet),
            
            pw.Table.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey700, width: 0.5),
              headerStyle: pw.TextStyle(color: PdfColors.black, fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellPadding: const pw.EdgeInsets.all(6),
              headers: [strings.pdfFieldLabel, strings.pdfFieldValue],
              data: [
                [strings.pdfFieldName, profile.petName],
                [strings.pdfFieldBreed, profile.raca ?? strings.petNotIdentified],
                [strings.pdfFieldAge, profile.idadeExata ?? strings.petNotOffice],
                [strings.pdfFieldSex, profile.rawAnalysis?['identificacao']?['sexo'] ?? profile.statusReprodutivo ?? strings.petNotOffice],
                [strings.pdfFieldMicrochip, profile.rawAnalysis?['identificacao']?['microchip'] ?? strings.petNotOffice],
                [strings.pdfFieldCurrentWeight, profile.pesoAtual != null ? '${profile.pesoAtual} kg' : strings.petNotOffice],
                [strings.pdfFieldIdealWeight, profile.pesoIdeal != null ? '${profile.pesoIdeal} kg' : strings.petNotOffice],
                [strings.pdfFieldReproductiveStatus, profile.statusReprodutivo ?? strings.petNotOffice],
                [strings.pdfFieldActivityLevel, profile.nivelAtividade ?? strings.petActivityModerate],
                [strings.pdfFieldBathFrequency, profile.frequenciaBanho ?? strings.petNotOffice],
              ],
            ),
            
            // Preferências Alimentares
            if (profile.preferencias.isNotEmpty) ...[
              pw.SizedBox(height: 15),
              pw.Text('${strings.pdfPreferenciasAlimentares}:', 
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
              pw.SizedBox(height: 5),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  profile.preferencias.join(', '),
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
            ],
            
            // Análise da Raça e Perfil (Dados Estendidos)
            if (profile.analysisHistory.isNotEmpty || profile.rawAnalysis != null) ...[
                 ..._buildAnalysisResultSection(
                     profile.analysisHistory.isNotEmpty ? profile.analysisHistory.last : profile.rawAnalysis!, 
                     strings
                 ),
            ],

            ..._buildObservationsBlock(profile.observacoesIdentidade, strings),
            pw.SizedBox(height: 20),
          ],
          
          // ========== HEALTH SECTION ==========
          if (sections['health'] == true) ...[
            buildSectionHeader(strings.pdfHealthSection, color: colorPet),
            
            // Controle de Peso
            pw.Text('${strings.pdfWeightControl}:', 
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
            pw.SizedBox(height: 5),
            pw.Table.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey700, width: 0.5),
              headerStyle: pw.TextStyle(color: PdfColors.black, fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellPadding: const pw.EdgeInsets.all(6),
              headers: [strings.pdfMetric, strings.pdfFieldValue, strings.pdfStatus],
              data: [
                [
                  strings.pdfFieldCurrentWeight,
                  profile.pesoAtual != null ? '${profile.pesoAtual} kg' : strings.petNotOffice,
                  profile.pesoAtual != null && profile.pesoIdeal != null
                    ? (profile.pesoAtual! > profile.pesoIdeal! ? strings.pdfPesoStatusOver : 
                       profile.pesoAtual! < profile.pesoIdeal! ? strings.pdfPesoStatusUnder : strings.pdfPesoStatusIdeal)
                    : 'N/A'
                ],
                [
                  strings.pdfFieldIdealWeight,
                  profile.pesoIdeal != null ? '${profile.pesoIdeal} kg' : strings.petNotOffice,
                  strings.pdfPesoStatusMeta
                ],
              ],
            ),
            
            // Histórico de Peso
            if (profile.weightHistory.isNotEmpty) ...[
              pw.SizedBox(height: 10),
              pw.Text('${strings.pdfWeightHistory}:', 
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              pw.Table.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                headerDecoration: pw.BoxDecoration(color: colorPet),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellPadding: const pw.EdgeInsets.all(4),
                headers: [strings.pdfDate, '${strings.pdfFieldCurrentWeight} (kg)', strings.pdfStatus],
                data: profile.weightHistory.take(10).map((entry) => [
                  DateFormat.yMd(strings.localeName).format(DateTime.tryParse(entry['date']?.toString() ?? '') ?? DateTime.now()),
                  '${entry['weight']} kg',
                  entry['status_label'] ?? strings.pdfPesoStatusNormal,
                ]).toList(),
              ),
            ],
            
            pw.SizedBox(height: 15),
            
            // Vacinas
            pw.Text('${strings.pdfVacinaV10} & ${strings.pdfVacinaAntirrabica}:', 
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
            pw.SizedBox(height: 5),
            pw.Table.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
              headerDecoration: pw.BoxDecoration(color: colorPet),
              headerStyle: pw.TextStyle(color: PdfColors.black, fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellPadding: const pw.EdgeInsets.all(6),
              headers: [strings.pdfFieldLabel, strings.pdfLastDose, strings.pdfNextDose],
              data: [
                [
                  strings.pdfVacinaV10,
                  profile.dataUltimaV10 != null 
                    ? DateFormat.yMd(strings.localeName).format(profile.dataUltimaV10!)
                    : strings.pdfVacinaNaoRegistrada,
                  profile.dataUltimaV10 != null
                    ? DateFormat.yMd(strings.localeName).format(profile.dataUltimaV10!.add(const Duration(days: 365)))
                    : 'N/A',
                ],
                [
                  strings.pdfVacinaAntirrabica,
                  profile.dataUltimaAntirrabica != null
                    ? DateFormat.yMd(strings.localeName).format(profile.dataUltimaAntirrabica!)
                    : strings.pdfVacinaNaoRegistrada,
                  profile.dataUltimaAntirrabica != null
                    ? DateFormat.yMd(strings.localeName).format(profile.dataUltimaAntirrabica!.add(const Duration(days: 365)))
                    : 'N/A',
                ],
              ],
            ),
            
            pw.SizedBox(height: 15),
            
            // Alergias e Restrições
            pw.Text('${strings.petAllergies}:', 
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
            pw.SizedBox(height: 5),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                border: pw.Border.all(
                  color: PdfColors.grey400,
                  width: 1.5,
                ),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text(
                profile.alergiasConhecidas.isEmpty 
                  ? strings.pdfAlergiasNenhuma
                  : strings.pdfAlergiasAviso(profile.alergiasConhecidas.join(', ')),
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
            ),
            
            // Exames Laboratoriais
            // --- Histórico Clínico ---
            if (medicalEvents.isNotEmpty) ...[
                pw.SizedBox(height: 15),
                pw.Text('${strings.pdfHistClinico}:', 
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                pw.SizedBox(height: 5),
                pw.Table.fromTextArray(
                    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                    headerDecoration: pw.BoxDecoration(color: colorPet),
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.black),
                    cellStyle: const pw.TextStyle(fontSize: 9),
                    cellPadding: const pw.EdgeInsets.all(4),
                    headers: [strings.pdfDate, strings.pdfType, strings.pdfDescription, strings.pdfStatus],
                    data: medicalEvents.map((e) => [
                        DateFormat.yMd(strings.localeName).format(e.dateTime),
                        e.getLocalizedTypeLabel(strings),
                        e.title,
                        e.completed ? strings.pdfCompleted : strings.pdfPending
                    ]).toList(),
                ),
                pw.SizedBox(height: 15),
            ],

            if (profile.labExams.isNotEmpty) ...[
              pw.SizedBox(height: 15),
              pw.Text('${strings.pdfExamesLab}:', 
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
              pw.SizedBox(height: 5),
              ...profile.labExams.map((examJson) {
                final exam = LabExam.fromJson(examJson);
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            exam.category,
                            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(
                            DateFormat.yMd(strings.localeName).format(exam.uploadDate),
                            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                          ),
                        ],
                      ),
                      if (exam.extractedText != null && exam.extractedText!.isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(
                          strings.pdfExtractedText(exam.extractedText!.substring(0, exam.extractedText!.length > 200 ? 200 : exam.extractedText!.length) + (exam.extractedText!.length > 200 ? '...' : '')),
                          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey800),
                        ),
                      ],
                      if (exam.aiExplanation != null && exam.aiExplanation!.isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(4),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.white,
                            border: pw.Border.all(color: PdfColors.grey400),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                          ),
                          child: pw.Text(
                            strings.pdfAiAnalysis(exam.aiExplanation!),
                            style: const pw.TextStyle(fontSize: 7),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ],

            // Histórico de Análises de Feridas
            if (woundsWithImages.isNotEmpty) ...[
              pw.SizedBox(height: 15),
              pw.Text('${strings.pdfAnaliseFeridas}:', 
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
              pw.SizedBox(height: 5),
              ...woundsWithImages.map((analysis) {
                final dateStr = DateFormat.yMd(strings.localeName).add_Hm().format(DateTime.tryParse(analysis['date']?.toString() ?? '') ?? DateTime.now());
                final severity = analysis['severity'] ?? 'N/A';
                final diagnosis = analysis['diagnosis'] ?? strings.petDiagnosisDefault;
                final recommendations = (analysis['recommendations'] as List?)?.cast<String>() ?? [];
                
                final pdfImage = analysis['pdfImage'] as pw.ImageProvider?;
                
                PdfColor severityColor = PdfColors.black;
                // No colors for severity

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                        if (pdfImage != null)
                             pw.Container(
                                 width: 70,
                                 height: 70,
                                 margin: const pw.EdgeInsets.only(right: 10),
                                 decoration: pw.BoxDecoration(
                                     borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                                     border: pw.Border.all(color: PdfColors.grey400),
                                     color: PdfColors.white,
                                 ),
                                 child: pw.ClipRRect(
                                     horizontalRadius: 4, verticalRadius: 4,
                                     child: pw.Image(pdfImage, fit: pw.BoxFit.cover),
                                 ),
                             ),

                        pw.Expanded(
                            child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Row(
                                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                    children: [
                                      pw.Text(
                                        dateStr,
                                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                                      ),
                                      pw.Container(
                                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: pw.BoxDecoration(
                                          color: colorPet,
                                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                                        ),
                                        child: pw.Text(
                                          severity.toUpperCase(),
                                          style: pw.TextStyle(color: PdfColors.black, fontSize: 8, fontWeight: pw.FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  pw.SizedBox(height: 4),
                                  pw.Text(strings.pdfDiagnosis(diagnosis), style: const pw.TextStyle(fontSize: 9)),
                                  if (recommendations.isNotEmpty) ...[
                                    pw.SizedBox(height: 4),
                                    pw.Text('${strings.pdfRecommendations}:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                                    ...recommendations.map((rec) => pw.Padding(
                                      padding: const pw.EdgeInsets.only(left: 4, top: 1),
                                      child: pw.Text('• $rec', style: const pw.TextStyle(fontSize: 8)),
                                    )),
                                  ],
                                ],
                            ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ],
            
            ..._buildObservationsBlock(profile.observacoesSaude, strings),
            pw.SizedBox(height: 20),
          ],
          
          // ========== NUTRITION SECTION ==========
          if (sections['nutrition'] == true) ...[
             buildSectionHeader(strings.pdfNutritionSection, color: colorPet),
            
            // Meta Nutricional
            if (profile.rawAnalysis != null) ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey700),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '${strings.dietType}:',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      profile.rawAnalysis!['tipo_dieta']?.toString() ?? strings.petNotOffice,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
            ],
            
            // Plano Semanal Completo
            if (profile.rawAnalysis != null && profile.rawAnalysis!['plano_semanal'] != null) ...[
              pw.Text('${strings.pdfCardapioDetalhado}:', 
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
              pw.SizedBox(height: 8),
              
              // V72: Atomic breakdown by day with error handling
              ...(profile.rawAnalysis!['plano_semanal'] as List).asMap().entries.expand((entry) {
                  try {
                    final index = entry.key;
                    final dayData = entry.value as Map;
                    
                    final dateForDay = startData.add(Duration(days: index));
                    final dateStr = DateFormat('dd/MM').format(dateForDay);
                    final weekDayName = DateFormat('EEEE', strings.localeName).format(dateForDay);
                    final weekDayCap = weekDayName[0].toUpperCase() + weekDayName.substring(1);
                    final diaLabel = "$weekDayCap - $dateStr";
                    
                    // Refeições
                    List<dynamic> refeicoes = [];
                    if (dayData.containsKey('refeicoes')) {
                        refeicoes = dayData['refeicoes'] as List;
                    } else {
                        final keys = ['manha', 'manhã', 'tarde', 'noite', 'refeicao'];
                        for(var k in keys) {
                          if(dayData[k] != null) {
                            refeicoes.add({
                              'hora': k.toUpperCase(),
                              'descricao': dayData[k],
                              'titulo': dayData['${k}_titulo'],
                              'kcal': dayData['${k}_kcal'],
                            });
                          }
                        }
                    }

                    return [
                        pw.Container(
                            margin: const pw.EdgeInsets.only(bottom: 2, top: 8),
                            padding: const pw.EdgeInsets.all(6),
                            decoration: pw.BoxDecoration(color: colorPet),
                            width: double.infinity,
                            child: pw.Text(
                              diaLabel.toUpperCase(),
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.black),
                            ),
                        ),
                        ...refeicoes.map((meal) => pw.Container(
                            padding: const pw.EdgeInsets.all(8),
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(
                                bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                                left: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                                right: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                              ),
                            ),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Expanded(
                                      child: pw.Text(
                                        '${meal['hora'] ?? strings.pdfRefeicao}${meal['titulo'] != null ? ' - ${meal['titulo']}' : ''}',
                                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.black),
                                      ),
                                    ),
                                    if (meal['kcal'] != null)
                                      pw.Text('${meal['kcal']} ${strings.pdfKcal}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                                  ],
                                ),
                                pw.SizedBox(height: 2),
                                pw.Text(meal['descricao']?.toString() ?? strings.pdfSemDescricao, style: const pw.TextStyle(fontSize: 8)),
                              ],
                            ),
                        )).toList(),
                    ];
                  } catch (e) {
                    debugPrint('⚠️ [V72-PDF] Error rendering meal plan day ${entry.key}: $e');
                    return <pw.Widget>[];
                  }
              }).toList(),
            ]
 else ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: colorPetUltraLight,
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  strings.pdfNoPlan,
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
              ),
            ],
            
            ..._buildObservationsBlock(profile.observacoesNutricao, strings),
            pw.SizedBox(height: 20),
          ],
          
          // ========== GALLERY SECTION ==========
          if (sections['gallery'] == true) ...[
             buildSectionHeader(strings.pdfGallerySection, color: colorPet),

             if (galleryImages.isNotEmpty) ...[
                pw.GridView(
                    crossAxisCount: 3,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: galleryImages.map((item) {
                        return pw.Container(
                            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)),
                            child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                                children: [
                                    pw.Expanded(child: pw.Image(item['image'], fit: pw.BoxFit.cover)),
                                    pw.Container(
                                        padding: const pw.EdgeInsets.all(2),
                                        color: colorPetLight,
                                        child: pw.Text(item['caption'], 
                                            style: const pw.TextStyle(fontSize: 8), 
                                            textAlign: pw.TextAlign.center,
                                            maxLines: 1, 
                                        ),
                                    ),
                                ]
                            )
                        );
                    }).toList(),
                ),
            ] else ...[
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Text(
                    strings.pdfNoImages,
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                  ),
                ),
            ],
            
            if (otherDocNames.isNotEmpty) ...[
                pw.SizedBox(height: 15),
                pw.Text(strings.pdfAttachedDocs, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.black)),
                pw.SizedBox(height: 5),
                ...otherDocNames.map((name) => pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Row(
                        children: [
                            pw.Text('📄 ', style: const pw.TextStyle(fontSize: 10)),
                            pw.Text(name, style: const pw.TextStyle(fontSize: 9)),
                        ]
                    )
                )).toList(),
                pw.SizedBox(height: 10),
            ],

            ..._buildObservationsBlock(profile.observacoesGaleria, strings),
            pw.SizedBox(height: 20),
          ],
          
          // ========== PARC (PARTNERS/BEHAVIOR) SECTION ==========
          if (sections['parc'] == true) ...[
             buildSectionHeader(strings.pdfParcSection, color: colorPet),
            
            // Parceiros Vinculados
            if (profile.linkedPartnerIds.isNotEmpty) ...[
              pw.Text(strings.pdfLinkedPartners, 
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
              pw.SizedBox(height: 8),
              
              // Display pre-loaded partner data
              if (linkedPartnersData.isNotEmpty) ...[
                ...linkedPartnersData.map((partnerData) {
                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 8),
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Expanded(
                              child: pw.Text(
                                partnerData['name'] ?? 'Parceiro',
                                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                              ),
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: pw.BoxDecoration(
                                color: colorPet,
                                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                              ),
                              child: pw.Text(
                                partnerData['category'] ?? 'Parceiro',
                                style: const pw.TextStyle(fontSize: 7, color: PdfColors.black),
                              ),
                            ),
                          ],
                        ),
                        if (partnerData['specialties'] != null && partnerData['specialties'].toString().isNotEmpty) ...[
                          pw.SizedBox(height: 4),
                          pw.Text(
                            '🎯 ${partnerData['specialties']}',
                            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                          ),
                        ],
                        if (partnerData['phone'] != null && partnerData['phone'].toString().isNotEmpty) ...[
                          pw.SizedBox(height: 4),
                          pw.Row(
                            children: [
                              pw.Text('📞 ', style: const pw.TextStyle(fontSize: 8)),
                              pw.Text(partnerData['phone'], style: const pw.TextStyle(fontSize: 8)),
                            ],
                          ),
                        ],
                        if (partnerData['address'] != null && partnerData['address'].toString().isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          pw.Row(
                            children: [
                              pw.Text('📍 ', style: const pw.TextStyle(fontSize: 8)),
                              pw.Expanded(
                                child: pw.Text(partnerData['address'], style: const pw.TextStyle(fontSize: 8)),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ] else ...[
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Text(
                    strings.pdfPartnerLoadError(profile.linkedPartnerIds.length),
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
              ],
              
              // Notas dos Parceiros
              if (profile.partnerNotes.isNotEmpty) ...[
                pw.SizedBox(height: 12),
                pw.Text(strings.pdfServiceHistory, 
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 5),
                ...profile.partnerNotes.entries.expand((entry) {
                  final partnerId = entry.key;
                  final notes = entry.value as List;
                  
                  return notes.map((note) => pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 6),
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey50,
                      border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              note['title'] ?? strings.petPartnersSchedule,
                              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.Text(
                              note['date'] ?? '',
                              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                            ),
                          ],
                        ),
                        if (note['description'] != null) ...[
                          pw.SizedBox(height: 3),
                          pw.Text(
                            note['description'],
                            style: const pw.TextStyle(fontSize: 7),
                          ),
                        ],
                      ],
                    ),
                  ));
                }).toList(),
              ],
            ] else ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  strings.pdfNoPartners,
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
              ),
            ],
            
            ..._buildObservationsBlock(profile.observacoesPrac, strings),
            pw.SizedBox(height: 20),
          ],
          
          // ========== AGENDA & EVENTS SECTION ==========
          if (allAgendaEvents.isNotEmpty) ...[
            buildSectionHeader(strings.pdfAgendaEvents, color: colorPet),
            
            pw.Text(
              strings.pdfHistoryUpcoming,
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
            ),
            pw.SizedBox(height: 8),
            
            // Group events by upcoming vs past
            ...() {
              final now = DateTime.now();
              final upcomingEvents = allAgendaEvents.where((e) => e.dateTime.isAfter(now)).toList();
              final pastEvents = allAgendaEvents.where((e) => !e.dateTime.isAfter(now)).toList();
              
              return [
                // Upcoming Events
                if (upcomingEvents.isNotEmpty) ...[
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    ),
                    child: pw.Text(
                      '🔔 ${strings.pdfUpcomingEvents} (${upcomingEvents.length})',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  ...upcomingEvents.take(10).map((event) => _buildEventItem(event, strings, isUpcoming: true)),
                  pw.SizedBox(height: 12),
                ],
                
                // Past Events
                if (pastEvents.isNotEmpty) ...[
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    ),
                    child: pw.Text(
                      '📋 ${strings.pdfRecentHistory} (${pastEvents.length > 15 ? '15 de ${pastEvents.length}' : pastEvents.length})',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  ...pastEvents.take(15).map((event) => _buildEventItem(event, strings, isUpcoming: false)),
                ],
              ];
            }(),
            
            pw.SizedBox(height: 20),
          ],
          
          // ========== LEGAL DISCLAIMER ==========
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              // Eco-mode
              border: pw.Border.all(color: PdfColors.black, width: 1),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  strings.pdfDisclaimerTitle,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  strings.pdfDisclaimerBody,
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey800,
                    fontStyle: pw.FontStyle.italic,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
    
    return pdf;
  }

  /// 6. PARTNERS HUB REPORT (UNIFIED LAYOUT)
  Future<pw.Document> generatePartnersHubReport({
    required List<PartnerModel> partners,
    required String reportType,
    required AppLocalizations strings,
  }) async {
    final pdf = pw.Document();
    final String timestampStr = DateFormat.yMd(strings.localeName).add_Hm().format(DateTime.now());
    
    // Contagem por tipo (LOCALIZED)
    Map<String, int> counts = {};
    for (var p in partners) {
      final localizedCat = _localizeCategory(p.category, strings);
      counts[localizedCat] = (counts[localizedCat] ?? 0) + 1;
    }

    // ORDENAÇÃO OBRIGATÓRIA: Primeiro por Tipo, depois por Nome
    final sortedPartners = List<PartnerModel>.from(partners)
      ..sort((a, b) {
        int comp = a.category.compareTo(b.category);
        if (comp != 0) return comp;
        return a.name.compareTo(b.name);
      });

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (context) => buildHeader('${strings.pdfReportTitle}: ${strings.pdfParcSection}', timestampStr, dateLabel: strings.pdfGeneratedOn, color: colorPet),
        footer: (context) => buildFooter(context),
        build: (context) => [
          // INDICADORES
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              buildIndicator(strings.partnersTitle, partners.length.toString(), colorPet),
              ...counts.entries.take(2).map((e) => buildIndicator(e.key, e.value.toString(), colorPetLight)).toList(),
            ],
          ),
          if (counts.length > 2) ...[
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.start,
              children: counts.entries.skip(2).take(3).map((e) => pw.Padding(
                padding: const pw.EdgeInsets.only(right: 10),
                child: buildIndicator(e.key, e.value.toString(), PdfColors.black),
              )).toList(),
            ),
          ],
          
          pw.SizedBox(height: 25),
          
          // TABELA
          pw.Table.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
            headerDecoration: pw.BoxDecoration(color: colorPet), // Pink header
            headerStyle: pw.TextStyle(color: PdfColors.black, fontWeight: pw.FontWeight.bold, fontSize: 9), // Black text
            cellStyle: const pw.TextStyle(fontSize: 8),
            headers: reportType == strings.partnersSummary 
              ? [strings.pdfFieldName, strings.partnersCategory, strings.pdfFieldPhone]
              : [strings.pdfFieldName, strings.partnersCategory, strings.pdfFieldPhone, strings.pdfFieldAddress, strings.pdfFieldEmail, strings.pdfFieldObservations],
            data: sortedPartners.map((p) {
              if (reportType == strings.partnersSummary) {
                return [p.name, _localizeCategory(p.category, strings), p.phone];
              } else {
                final metadataStr = p.metadata.isNotEmpty ? '\nInfo: ${p.metadata.toString()}' : '';
                return [
                  p.name,
                  _localizeCategory(p.category, strings),
                  p.phone,
                  p.address,
                  p.email ?? '---',
                  p.specialties.join(', ') + metadataStr,
                ];
              }
            }).toList(),
          ),
        ],
      ),
    );
    return pdf;
  }

  // Helper method to build event items for PDF
  /// 7. SINGLE PARTNER DOSSIER (DETAILED LAYOUT)
  Future<pw.Document> generateSinglePartnerReport({
    required PartnerModel partner,
    required AppLocalizations strings,
  }) async {
    final pdf = pw.Document();
    final String timestampStr = DateFormat.yMd(strings.localeName).add_Hm().format(DateTime.now());

    // Extract notes from metadata if present
    final List<Map<String, dynamic>> notes = [];
    if (partner.metadata['notes'] != null) {
        notes.addAll(List<Map<String, dynamic>>.from(partner.metadata['notes']));
        // Sort notes by date descending
        notes.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (context) => buildHeader('${strings.pdfReportTitle}: ${partner.name}', timestampStr, dateLabel: strings.pdfGeneratedOn, color: colorPet),
        footer: (context) => buildFooter(context),
        build: (context) => [
          // HEADER INFO
          pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                  buildIndicator(strings.partnersCategory, partner.category, colorPet),
                  if (partner.rating > 0) buildIndicator(strings.pdfRating, '${partner.rating} ${strings.pdfStars}', colorPetLight),
              ]
          ),
          pw.SizedBox(height: 20),

          // DETAILS SECTION
          buildSectionHeader(strings.petBasicInfo, color: colorPet),
          pw.SizedBox(height: 10),
          pw.Table(
            columnWidths: {
                0: const pw.FixedColumnWidth(120),
                1: const pw.FlexColumnWidth(),
            },
            children: [
                _buildTableRow(strings.pdfFieldName, partner.name),
                if (partner.cnpj != null && partner.cnpj!.isNotEmpty) _buildTableRow('CNPJ:', partner.cnpj!),
                _buildTableRow(strings.pdfFieldPhone, partner.phone),
                if (partner.whatsapp != null && partner.whatsapp!.isNotEmpty && partner.whatsapp != partner.phone) 
                  _buildTableRow('WhatsApp:', partner.whatsapp!),
                if (partner.email != null && partner.email!.isNotEmpty) _buildTableRow(strings.pdfFieldEmail, partner.email!),
                if (partner.website != null && partner.website!.isNotEmpty) _buildTableRow('Website:', partner.website!),
                if (partner.instagram != null && partner.instagram!.isNotEmpty) _buildTableRow('Instagram:', partner.instagram!),
                _buildTableRow(strings.pdfFieldAddress, partner.address),
                if (partner.openingHours['raw'] != null && partner.openingHours['raw'].toString().isNotEmpty)
                  _buildTableRow(strings.partnerFieldHours, partner.openingHours['raw']),
            ]
          ),
          pw.SizedBox(height: 15),
          if (partner.openingHours['plantao24h'] == true) 
            pw.Row(
              children: [
                buildIndicator(strings.partnerField24h, 'ATIVO / ACTIVE', PdfColors.red700),
              ]
            ),
          pw.SizedBox(height: 20),

          // TEAM SECTION
          if (partner.teamMembers.isNotEmpty) ...[
              buildSectionHeader(strings.partnerTeamMembers, color: colorPet),
              pw.SizedBox(height: 10),
              pw.Bullet(text: partner.teamMembers.join(', '), style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 20),
          ],

          // NOTES SECTION
          if (notes.isNotEmpty) ...[
              buildSectionHeader(strings.partnerNotesTitle, color: colorPet),
              pw.SizedBox(height: 10),
              ...notes.map((n) {
                  final date = DateTime.parse(n['date']);
                  final formattedDate = DateFormat.yMd(strings.localeName).add_Hm().format(date);
                  return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 15),
                      child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                              pw.Text(formattedDate, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.blue800)),
                              pw.SizedBox(height: 4),
                              pw.Text(n['content'], style: const pw.TextStyle(fontSize: 10)),
                              pw.Divider(color: PdfColors.grey300),
                          ]
                      )
                  );
              }).toList(),
          ],

          // SPECIALTIES
          if (partner.specialties.isNotEmpty) ...[
               pw.SizedBox(height: 10),
               buildSectionHeader(strings.pdfFieldDetails, color: colorPet),
               pw.SizedBox(height: 10),
               pw.Text(partner.specialties.join(', '), style: const pw.TextStyle(fontSize: 10)),
          ]
        ],
      ),
    );
    return pdf;
  }

  pw.TableRow _buildTableRow(String label, String value) {
      return pw.TableRow(
          children: [
              pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              ),
              pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
              ),
          ]
      );
  }

  pw.Widget _buildEventItem(PetEvent event, AppLocalizations strings, {required bool isUpcoming}) {
    // Get event icon and color based on type
    String icon;
    PdfColor color;
    
    switch (event.type) {
      case EventType.vaccine:
        icon = '💉';
        color = PdfColors.blue700;
        break;
      case EventType.medication:
        icon = '💊';
        color = PdfColors.purple700;
        break;
      case EventType.veterinary:
        icon = '🏥';
        color = PdfColors.red700;
        break;
      case EventType.bath:
        icon = '🛁';
        color = PdfColors.cyan700;
        break;
      case EventType.grooming:
        icon = '✂️';
        color = PdfColors.pink700;
        break;
      case EventType.other:
      default:
        icon = '📌';
        color = PdfColors.grey700;
    }
    
    final dateStr = DateFormat.yMd(strings.localeName).add_Hm().format(event.dateTime);
    
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.white, // No background
        border: pw.Border.all(
          color: PdfColors.grey400,
          width: 0.5,
        ),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Icon
          pw.Container(
            width: 20,
            child: pw.Text(
              icon,
              style: const pw.TextStyle(fontSize: 12),
            ),
          ),
          pw.SizedBox(width: 8),
          // Content
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        event.title,
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                    ),
                    pw.Text(
                      dateStr,
                      style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                    ),
                  ],
                ),
                if (event.notes != null && event.notes!.isNotEmpty) ...[
                  pw.SizedBox(height: 3),
                  pw.Text(
                    event.notes!,
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                    maxLines: 2,
                  ),
                ],
                if (event.attendant != null && event.attendant!.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Row(
                    children: [
                      pw.Text('👤 ', style: const pw.TextStyle(fontSize: 7)),
                      pw.Expanded(
                        child: pw.Text(
                          event.attendant!,
                          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _localizeCategory(String category, AppLocalizations strings) {
    final c = category.toLowerCase();
    if (c.contains('vet')) return strings.partnersFilterVet;
    if (c.contains('farm') || c.contains('pharm')) return strings.partnersFilterPharmacy;
    if (c.contains('shop') || c.contains('tienda')) return strings.partnersFilterPetShop;
    if (c.contains('banho') || c.contains('grooming') || c.contains('peluquer')) return strings.partnersFilterGrooming;
    if (c.contains('hotel')) return strings.partnersFilterHotel;
    if (c.contains('lab') || c.contains('laboratório') || c.contains('laboratory')) return strings.partnersFilterLab;
    return category;
  }

  // --- FOOD HISTORY EXPORT ---
  dynamic _deepFixMaps(dynamic value) {
    if (value is Map) {
      return value.map<String, dynamic>((k, v) => MapEntry(k.toString(), _deepFixMaps(v)));
    }
    if (value is List) {
      return value.map((e) => _deepFixMaps(e)).toList();
    }
    return value;
  }

  PdfColor _getTrafficLightColor(String semaforo) {
    final s = semaforo.toLowerCase();
    if (s.contains('verde') || s.contains('green')) return PdfColors.green;
    if (s.contains('amarelo') || s.contains('yellow')) return PdfColors.orange;
    return PdfColors.red;
  }

  Future<pw.Document> generateFoodHistoryReport({
    required List<NutritionHistoryItem> items,
    required AppLocalizations strings,
  }) async {
    final pdf = pw.Document();

    for (var item in items) {
       FoodAnalysisModel? rawAnalysis;
       pw.ImageProvider? foodImage;
       
       foodImage = await safeLoadImage(item.imagePath);

       if (item.rawMetadata != null) {
          try {
             final fixedMap = _deepFixMaps(item.rawMetadata);
             if (fixedMap is Map<String, dynamic>) {
                 rawAnalysis = FoodAnalysisModel.fromJson(fixedMap);
             }
          } catch (e) {
             debugPrint('⚠️ Error parsing history item ${item.foodName} for PDF: $e');
          }
       }

       if (rawAnalysis == null) continue;
       final analysis = rawAnalysis;

       final String timestampStr = DateFormat('dd/MM/yyyy HH:mm', strings.localeName).format(item.timestamp);
       
       pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(35),
          header: (context) => buildHeader(strings.pdfFoodTitle + " - ${item.foodName}", timestampStr, dateLabel: strings.pdfDate, color: colorFood),
          footer: (context) => buildFooter(context, strings: strings),
          build: (context) => [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (foodImage != null)
                  pw.Container(
                    width: 80,
                    height: 80,
                    margin: const pw.EdgeInsets.only(right: 15),
                    decoration: pw.BoxDecoration(
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      border: pw.Border.all(color: PdfColors.grey400),
                    ),
                    child: pw.ClipRRect(
                      horizontalRadius: 8,
                      verticalRadius: 8,
                      child: pw.Image(foodImage, fit: pw.BoxFit.cover),
                    ),
                  ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(analysis.identidade.nome, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, color: PdfColors.black)),
                      pw.SizedBox(height: 5),
                      pw.Row(
                        children: [
                          buildIndicator('${strings.pdfCalories}:', '${analysis.macros.calorias100g} kcal/100g', PdfColors.red700),
                          pw.SizedBox(width: 10),
                           buildIndicator(
                            '${strings.pdfTrafficLight}:', 
                            analysis.identidade.semaforoSaude, 
                            _getTrafficLightColor(analysis.identidade.semaforoSaude),
                          ),
                          pw.SizedBox(width: 10),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            pw.SizedBox(height: 20),

            buildSectionHeader(strings.pdfExSummary, color: colorFood),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5))),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('${strings.pdfAiVerdict}:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.Text(analysis.analise.vereditoIa, style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            
            buildSectionHeader(strings.pdfDetailedNutrition, color: colorFood),
            pw.Table.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headers: [strings.pdfNutrient, strings.pdfQuantity, strings.pdfDetails],
              data: [
                [strings.nutrientsProteins, analysis.macros.proteinas, strings.labelAminoProfile],
                [strings.nutrientsCarbs, analysis.macros.carboidratosLiquidos, '${strings.labelGlycemicImpact}: ${analysis.macros.indiceGlicemico}'],
                [strings.nutrientsFats, analysis.macros.gordurasPerfil, strings.labelFattyAcids],
              ],
            ),
          ],
        ),
      );
    }
    return pdf;
  }

  Future<pw.Document> generateRecipeBookReport({
    required List<RecipeHistoryItem> items,
    required AppLocalizations strings,
  }) async {
    final pdf = pw.Document();
    final String timestampStr = DateFormat('dd/MM/yyyy HH:mm', strings.localeName).format(DateTime.now());

    for (var item in items) {
       pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(35),
          header: (context) => buildHeader("RECEITA - ${item.recipeName.toUpperCase()}", timestampStr, dateLabel: strings.pdfDate, color: colorFood),
          footer: (context) => buildFooter(context, strings: strings),
          build: (context) => [
             pw.Center(
               child: pw.Text(item.recipeName.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, color: PdfColors.black), textAlign: pw.TextAlign.center),
             ),
             pw.SizedBox(height: 5),
             pw.Center(
                child: pw.Text("${item.foodName}  |  ${item.prepTime}", 
                   style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
             ),
             pw.SizedBox(height: 20),
             
             // DECORATIVE SEPARATOR
             pw.Center(
               child: pw.Container(
                 width: 50,
                 height: 4,
                 decoration: const pw.BoxDecoration(
                   color: colorFood,
                   borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
                 ),
               ),
             ),
             pw.SizedBox(height: 20),

             buildSectionHeader("MODO DE PREPARO", color: colorFood),
             pw.Container(
               padding: const pw.EdgeInsets.all(12),
               decoration: pw.BoxDecoration(
                 color: PdfColors.grey100,
                 borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                 border: pw.Border.all(color: PdfColors.grey300),
               ),
               child: pw.Text(
                 item.instructions,
                 style: const pw.TextStyle(fontSize: 10, height: 1.5, color: PdfColors.black),
               ),
             ),
             pw.SizedBox(height: 20),
          ],
        ),
      );
    }
    return pdf;
  }

  Future<pw.Document> generatePlantHistoryReport({
    required List<BotanyHistoryItem> items,
    required AppLocalizations strings,
  }) async {
    final pdf = pw.Document();
    final String timestampStr = DateFormat('dd/MM/yyyy HH:mm', strings.localeName).format(DateTime.now());

    for (var item in items) {
       pw.ImageProvider? plantImage;
       plantImage = await safeLoadImage(item.imagePath);

       // Determine toxicity info
       final isToxic = item.toxicityStatus != 'safe';
       final toxicityLabel = isToxic ? 'TÓXICA' : 'SEGURA';
       final toxicityColor = isToxic ? PdfColors.red : PdfColors.green;

       pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(35),
          header: (context) => buildHeader("PLANTA - ${item.plantName.toUpperCase()}", timestampStr, dateLabel: strings.pdfDate, color: colorPlant),
          footer: (context) => buildFooter(context, strings: strings),
          build: (context) => [
             // Plant Name
             pw.Center(
               child: pw.Text(item.plantName.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, color: PdfColors.black), textAlign: pw.TextAlign.center),
             ),
             pw.SizedBox(height: 5),
             
             // Date
             pw.Center(
                child: pw.Text(DateFormat('dd/MM/yyyy HH:mm').format(item.timestamp), 
                   style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
             ),
             pw.SizedBox(height: 20),
             
             // Plant Image
             if (plantImage != null)
                pw.Container(
                   height: 250,
                   width: double.infinity,
                   margin: const pw.EdgeInsets.only(bottom: 20),
                   decoration: pw.BoxDecoration(
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      border: pw.Border.all(color: PdfColors.grey400),
                   ),
                   child: pw.ClipRRect(
                      horizontalRadius: 8,
                      verticalRadius: 8,
                      child: pw.Image(plantImage, fit: pw.BoxFit.cover),
                   ),
                ),

             // Toxicity Status
             buildSectionHeader("NÍVEL DE TOXICIDADE", color: colorPlant),
             pw.Container(
               padding: const pw.EdgeInsets.all(12),
               decoration: pw.BoxDecoration(
                 color: toxicityColor.shade(0.9),
                 borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                 border: pw.Border.all(color: toxicityColor),
               ),
               child: pw.Row(
                 mainAxisAlignment: pw.MainAxisAlignment.center,
                 children: [
                   pw.Text(
                     toxicityLabel,
                     style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: toxicityColor),
                   ),
                 ],
               ),
             ),
             pw.SizedBox(height: 20),

             // Health Status
             buildSectionHeader("STATUS DE SAÚDE", color: colorPlant),
             pw.Container(
               padding: const pw.EdgeInsets.all(12),
               decoration: pw.BoxDecoration(
                 color: PdfColors.grey100,
                 borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                 border: pw.Border.all(color: PdfColors.grey300),
               ),
               child: pw.Column(
                 crossAxisAlignment: pw.CrossAxisAlignment.start,
                 children: [
                   pw.Text(
                     'Estado: ${item.healthStatus}',
                     style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                   ),
                   pw.SizedBox(height: 4),
                   pw.Text(
                     'Semáforo: ${item.survivalSemaphore.toUpperCase()}',
                     style: const pw.TextStyle(fontSize: 10, color: PdfColors.black),
                   ),
                   if (item.diseaseDiagnosis != null) ...[
                     pw.SizedBox(height: 4),
                     pw.Text(
                       'Diagnóstico: ${item.diseaseDiagnosis}',
                       style: const pw.TextStyle(fontSize: 10, color: PdfColors.black),
                     ),
                   ],
                 ],
               ),
             ),
             pw.SizedBox(height: 20),

             // Prevention Tips (if toxic)
             if (isToxic) ...[
               buildSectionHeader("DICAS DE PREVENÇÃO", color: colorPlant),
               pw.Container(
                 padding: const pw.EdgeInsets.all(12),
                 decoration: pw.BoxDecoration(
                   color: PdfColors.red50,
                   borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                   border: pw.Border.all(color: PdfColors.red300),
                 ),
                 child: pw.Text(
                   'ATENÇÃO: Esta planta apresenta toxicidade. Mantenha fora do alcance de crianças e animais de estimação. Em caso de ingestão, procure atendimento médico imediatamente.',
                   style: const pw.TextStyle(fontSize: 10, height: 1.5, color: PdfColors.black),
                 ),
               ),
               pw.SizedBox(height: 20),
             ],

             // Recovery Plan
             buildSectionHeader("PLANO DE RECUPERAÇÃO", color: colorPlant),
             pw.Container(
               padding: const pw.EdgeInsets.all(12),
               decoration: pw.BoxDecoration(
                 color: PdfColors.grey100,
                 borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                 border: pw.Border.all(color: PdfColors.grey300),
               ),
               child: pw.Text(
                 item.recoveryPlan,
                 style: const pw.TextStyle(fontSize: 10, height: 1.5, color: PdfColors.black),
               ),
             ),
             pw.SizedBox(height: 20),

             // Care Needs
             buildSectionHeader("NECESSIDADES DE CUIDADO", color: colorPlant),
             pw.Container(
               padding: const pw.EdgeInsets.all(12),
               decoration: pw.BoxDecoration(
                 color: PdfColors.grey100,
                 borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                 border: pw.Border.all(color: PdfColors.grey300),
               ),
               child: pw.Column(
                 crossAxisAlignment: pw.CrossAxisAlignment.start,
                 children: [
                   if (item.lightWaterSoilNeeds['luz'] != null)
                     pw.Padding(
                       padding: const pw.EdgeInsets.only(bottom: 6),
                       child: pw.Row(
                         children: [
                           pw.Text('☀️ Luz: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                           pw.Expanded(child: pw.Text(item.lightWaterSoilNeeds['luz']!, style: const pw.TextStyle(fontSize: 10))),
                         ],
                       ),
                     ),
                   if (item.lightWaterSoilNeeds['agua'] != null)
                     pw.Padding(
                       padding: const pw.EdgeInsets.only(bottom: 6),
                       child: pw.Row(
                         children: [
                           pw.Text('💧 Água: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                           pw.Expanded(child: pw.Text(item.lightWaterSoilNeeds['agua']!, style: const pw.TextStyle(fontSize: 10))),
                         ],
                       ),
                     ),
                   if (item.lightWaterSoilNeeds['solo'] != null)
                     pw.Row(
                       children: [
                         pw.Text('🌱 Solo: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                         pw.Expanded(child: pw.Text(item.lightWaterSoilNeeds['solo']!, style: const pw.TextStyle(fontSize: 10))),
                       ],
                     ),
                 ],
               ),
             ),
             pw.SizedBox(height: 20),
          ],
        ),
      );
    }
    return pdf;
  }
}

