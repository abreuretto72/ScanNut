import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:scannut/l10n/app_localizations.dart';
import '../../features/pet/models/pet_event.dart';
import '../../features/pet/models/pet_profile_extended.dart';
import '../../features/pet/models/pet_analysis_result.dart';
import '../../features/pet/models/analise_ferida_model.dart';
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
                      color: (color == colorPet) ? PdfColors.black : (color != null ? PdfColors.white : PdfColors.grey700),
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

    final pageText = strings?.pdfPage(context.pageNumber, context.pagesCount) ?? 'Página ${context.pageNumber} de ${context.pagesCount}';

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
    if (safeObs.length > 1000) safeObs = '${safeObs.substring(0, 1000)}...';

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
    // Totals removed as per user request

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (context) => buildHeader(strings.pdfAgendaReport, timestampStr, color: colorPet, dateLabel: strings.pdfDateLabel),
        footer: (context) => buildFooter(context),
        build: (context) => [
          // Indicators removed
          if (reportType == 'Detalhamento' || reportType == 'Somente Agendamentos')
            pw.TableHelper.fromTextArray(
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
        header: (context) => buildHeader(strings.pdfPartnersGuide, timestampStr, color: colorPet, dateLabel: strings.pdfDateLabel),
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
          pw.TableHelper.fromTextArray(
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
        header: (context) => buildHeader(strings.pdfRadarTitle, timestampStr, color: colorPet, dateLabel: strings.pdfDateLabel),
        footer: (context) => buildFooter(context, strings: strings),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              buildIndicator('${strings.pdfStatus}:', strings.pdfRadarResults, colorPet),
              buildIndicator('${strings.pdfTotalFound}:', partners.length.toString(), colorPet),
            ],
          ),
          pw.SizedBox(height: 25),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: colorPet, width: 0.5),
            headerDecoration: pw.BoxDecoration(color: colorPet),
            headerStyle: pw.TextStyle(color: PdfColors.black, fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 7.5, color: PdfColors.black),
            headers: [
                strings.pdfEstablishment.toUpperCase(), 
                strings.pdfDistanceLabel.toUpperCase(), 
                strings.ratingLabel.toUpperCase() ?? (strings.localeName == 'pt' ? 'AVALIAÇÃO' : 'RATING'), 
                strings.pdfAddressLabel.toUpperCase(), 
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
    List<dynamic>? recommendedBrands, // NEW: Brand suggestions (can be String or BrandSuggestion)
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
        header: (context) => buildHeader(strings.pdfNutritionSection, timestampStr, color: colorPet, dateLabel: strings.pdfDateLabel),
        footer: (context) => _buildFooter(context, strings),
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
                      }),
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
                         content.add(pw.TableHelper.fromTextArray(
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
                    content.add(pw.TableHelper.fromTextArray(
                        border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
                        headerDecoration: pw.BoxDecoration(color: colorPet),
                        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.black),
                        cellStyle: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
                        headers: [strings.commonItem, strings.commonQuantity, strings.commonCategory],
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

          // NEW: Brand Suggestions Section
          if (recommendedBrands != null && recommendedBrands.isNotEmpty) {
            content.add(pw.SizedBox(height: 20));
            content.add(pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                 color: PdfColor.fromHex('#E8F5E9'), // Light green background
                 border: pw.Border.all(color: PdfColor.fromHex('#4CAF50'), width: 1.0),
                 borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 16,
                        height: 16,
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#4CAF50'),
                          shape: pw.BoxShape.circle,
                        ),
                        child: pw.Center(
                          child: pw.Text('i', style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Text(strings.pdfBrandSuggestions, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColor.fromHex('#2E7D32'))),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  ...recommendedBrands.map((item) {
                    // 🛡️ Handle both legacy (String) and new (BrandSuggestion) formats
                    String brandName;
                    String? reason;
                    
                    if (item is String) {
                      brandName = item;
                      reason = null;
                    } else if (item is Map) {
                      brandName = item['brand']?.toString() ?? item['marca']?.toString() ?? '';
                      reason = item['reason']?.toString() ?? item['por_que_escolhemos']?.toString();
                    } else {
                      // BrandSuggestion object
                      brandName = (item as dynamic).brand ?? ''; // Cast to dynamic or typed if possible
                      reason = (item as dynamic).reason;
                    }
                    
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 8, left: 24),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('• ', style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('#4CAF50'), fontWeight: pw.FontWeight.bold)),
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                // Brand name in bold green
                                pw.Text(
                                  brandName, 
                                  style: pw.TextStyle(
                                    fontSize: 10, 
                                    color: PdfColor.fromHex('#2E7D32'),
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                if (reason != null && reason.isNotEmpty) ...[
                                  pw.SizedBox(height: 2),
                                  // Technical justification in italic
                                  pw.Text(
                                    reason,
                                    style: pw.TextStyle(
                                      fontSize: 9,
                                      color: PdfColors.grey800,
                                      fontStyle: pw.FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  pw.SizedBox(height: 10),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#FFF9C4'), // Light yellow for disclaimer
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Text(
                      strings.pdfLegalDisclaimer,
                      style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: PdfColors.black),
                    ),
                  ),
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
                                )),
                              ],
                            ),
                          )
                        ]
                      );
                    }),
                  ],
                ),
              );
            }),
            
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
             header: (context) => buildHeader('${strings.pdfShoppingListTitle}${weekLabel.toUpperCase()}', timestampStr, color: colorFood),
             footer: (context) => buildFooter(context, strings: strings),
             build: (context) => [
               pw.Text(
                 strings.pdfShoppingListDescription(weekShopping.weekLabel),
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
               }),
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
          // Safety & Toxicity Header Block
          if (analysis.segurancaBiofilia.segurancaDomestica['is_toxic_to_pets'] == true ||
              analysis.segurancaBiofilia.segurancaDomestica['toxica_para_pets'] == true ||
              analysis.segurancaBiofilia.segurancaDomestica['toxica_para_criancas'] == true ||
              analysis.segurancaBiofilia.segurancaDomestica['is_toxic_to_children'] == true) ...[
            
            // Logic to determine Specific Toxicity Label
            (() {
               String label = strings.toxicityWarning.toUpperCase(); // Default generic
               final sec = analysis.segurancaBiofilia.segurancaDomestica;
               final details = (sec['toxicity_details'] ?? sec['sintomas_ingestao'] ?? '').toString().toLowerCase();
               final bool toxicKids = sec['toxica_para_criancas'] == true || sec['is_toxic_to_children'] == true;

               // Specific Detection
               if (details.contains('gato') && details.contains('cão')) {
                  label = strings.pdfToxicPetsCats;
               } else if (details.contains('gato') || details.contains('felino')) {
                  label = strings.pdfToxicCats;
               } else if (details.contains('cão') || details.contains('cachorro') || details.contains('canino')) {
                  label = strings.pdfToxicDogs;
               } else if (sec['toxica_para_pets'] == true || sec['is_toxic_to_pets'] == true || details.contains('animais') || details.contains('pets')) {
                  label = strings.pdfToxicAnimals;
               } else if (toxicKids) {
                  label = strings.pdfToxicHumans;
               }
               
               return pw.Container(
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
                             pw.Text(label, style: pw.TextStyle(color: PdfColors.red900, fontWeight: pw.FontWeight.bold, fontSize: 14)),
                             pw.Text(analysis.segurancaBiofilia.segurancaDomestica['toxicity_details'] ?? analysis.segurancaBiofilia.segurancaDomestica['sintomas_ingestao'] ?? strings.plantDangerPets, style: const pw.TextStyle(color: PdfColors.red900, fontSize: 10)),
                           ],
                         ),
                       ),
                    ],
                  ),
               );
            })(),
          ],
            
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
                        buildIndicator('${strings.tabHealth}:', analysis.saude.condicao, analysis.isHealthy ? PdfColors.green700 : PdfColors.red700),
                        pw.SizedBox(width: 10),
                         buildIndicator('${strings.plantFamily}:', analysis.identificacao.familia, PdfColors.black),
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
                pw.Row(
                  children: [
                    _buildCareIcon('sun', _parsePlantCareLevel(analysis.sobrevivencia.luminosidade['type'] ?? analysis.sobrevivencia.luminosidade['tipo'], 'sun')),
                    pw.SizedBox(width: 5),
                    pw.Text(strings.labelSun.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  ]
                ),
                pw.SizedBox(height: 4),
                pw.Text(analysis.sobrevivencia.luminosidade['type'] ?? analysis.sobrevivencia.luminosidade['tipo'] ?? strings.noInformation),
                pw.Text(analysis.sobrevivencia.luminosidade['explanation'] ?? analysis.sobrevivencia.luminosidade['explicacao'] ?? '', style: const pw.TextStyle(fontSize: 8)),
              ])),
              pw.SizedBox(width: 20),
              pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Row(
                  children: [
                    _buildCareIcon('water', _parsePlantCareLevel(analysis.sobrevivencia.regimeHidrico['frequency'] ?? analysis.sobrevivencia.regimeHidrico['frequencia_ideal'], 'water')),
                    pw.SizedBox(width: 5),
                    pw.Text(strings.labelWater.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  ]
                ),
                pw.SizedBox(height: 4),
                pw.Text(analysis.sobrevivencia.regimeHidrico['frequency'] ?? analysis.sobrevivencia.regimeHidrico['frequencia_ideal'] ?? strings.noInformation),
                pw.Text(analysis.sobrevivencia.regimeHidrico['thirst_signs'] ?? analysis.sobrevivencia.regimeHidrico['sinais_sede'] ?? '', style: const pw.TextStyle(fontSize: 8)),
              ])),
            ]
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
               _buildCareIcon('soil', _parsePlantCareLevel(analysis.sobrevivencia.soloENutricao['type'] ?? analysis.sobrevivencia.soloENutricao['tipo'], 'soil')),
               pw.SizedBox(width: 5),
               pw.Text('${strings.labelSoil.toUpperCase() ?? strings.plantNeedSoil} & ${strings.tabNutrition}:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            ]
          ),
          pw.SizedBox(height: 4),
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

          // 📚 CARE LEGEND (Requested)
          _buildCareLegend(strings),
        ],
      ),
    );
    return pdf;
  }

  pw.Widget _buildCareLegend(AppLocalizations strings) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(strings.pdfCareLegendTitle, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.green900)),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildLegendItem('sun', strings.plantNeedSun, 'Nível de intensidade de luz solar necessária.', PdfColors.orange),
              _buildLegendItem('water', strings.plantNeedWater, 'Frequência de hidratação do solo.', PdfColors.blue),
              _buildLegendItem('soil', strings.plantNeedSoil, 'Riqueza e drenagem do substrato.', PdfColors.brown),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Divider(color: PdfColors.grey300, thickness: 0.5),
          pw.SizedBox(height: 5),
          pw.Text(strings.pdfCareLegendLevels, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
          pw.Text(strings.pdfCareLegendDescription, style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    );
  }

  pw.Widget _buildLegendItem(String type, String title, String desc, PdfColor color) {
    return pw.Expanded(
      child: pw.Row(
        children: [
          _buildCareIcon(type, 3, size: 15),
          pw.SizedBox(width: 8),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: color)),
              pw.SizedBox(width: 100, child: pw.Text(desc, style: const pw.TextStyle(fontSize: 7))),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCareIcon(String type, int level, {double size = 15}) {
    PdfColor color;
    if (type == 'sun') {
      color = PdfColors.orange;
    } else if (type == 'water') {
      color = PdfColors.blue;
    } else {
      color = PdfColors.brown;
    }

    double fillRatio = 0.25;
    if (level == 2) fillRatio = 0.5;
    if (level >= 3) fillRatio = 1.0;

    return pw.CustomPaint(
      size: PdfPoint(size, size),
      painter: (PdfGraphics canvas, PdfPoint size) {
        // --- 1. SET STROKE STYLE ---
        canvas
          ..setLineWidth(1)
          ..setStrokeColor(color);

        // --- 2. DEFINE SHAPE PATH ---
        // Note: PDF coordinate system (0,0) is BOTTOM-LEFT.
        // UI coordinate system (0,0) is TOP-LEFT.
        // To match UI:
        // Top Edge in UI (Y=0) is Y=size.y in PDF.
        // Bottom Edge in UI (Y=height) is Y=0 in PDF.

        void definePath() {
          if (type == 'sun') {
            canvas.drawEllipse(size.x / 2, size.y / 2, size.x / 2, size.y / 2);
          } else if (type == 'soil') {
            // Rounded square simulation or simple rect
            canvas.drawRect(0, 0, size.x, size.y);
          } else {
            // Cup (Trapezoid from UI)
            // UI: top (15% to 85%), bottom (30% to 70%)
            // PDF: top Y=size.y, bottom Y=0
            canvas
              ..moveTo(size.x * 0.30, 0)        // Bottom Left
              ..lineTo(size.x * 0.70, 0)        // Bottom Right
              ..lineTo(size.x * 0.85, size.y)   // Top Right
              ..lineTo(size.x * 0.15, size.y)   // Top Left
              ..closePath();
          }
        }

        // --- 3. DRAW OUTLINE ---
        definePath();
        canvas.strokePath();

        // --- 4. DRAW FILL (FROM BOTTOM) ---
        if (fillRatio > 0) {
          canvas
            ..saveContext()
            ..setFillColor(color);

          definePath();
          canvas.clipPath();

          // Fill rectangle from Y=0 to Y=fillRatio * size.y
          canvas.drawRect(0, 0, size.x, size.y * fillRatio);
          canvas.fillPath();

          canvas.restoreContext();
        }
      },
    );
  }

  int _parsePlantCareLevel(String? value, String type) {
    if (value == null) return 1;
    final s = value.toLowerCase();

    if (type == 'sun') {
      if (s.contains('pleno') || s.contains('full') || s.contains('direta')) return 3;
      if (s.contains('meia') || s.contains('partial') || s.contains('indireta')) return 2;
      return 1;
    }
    if (type == 'water') {
      if (s.contains('abundante') || s.contains('high') || s.contains('frequente') || s.contains('muito')) return 3;
      if (s.contains('moderada') || s.contains('average') || s.contains('regular') || s.contains('semanal')) return 2;
      return 1;
    }
    if (type == 'soil') {
      if (s.contains('rico') || s.contains('rich') || s.contains('fértil')) return 3;
      if (s.contains('drenado') || s.contains('drain') || s.contains('arenoso')) return 1;
      return 2;
    }
    return 1;
  }

  // 📝 TRANSLATION MAP (English AI Keys -> Portuguese PDF)
  static final Map<String, String> _keyTranslations = {
    'IDENTIFICATION': 'IDENTIFICAÇÃO',
    'BREED_NAME': 'RAÇA',
    'BREED NAME': 'RAÇA',
    'ORIGIN_REGION': 'REGIÃO DE ORIGEM',
    'ORIGIN REGION': 'REGIÃO DE ORIGEM',
    'MORPHOLOGY_TYPE': 'TIPO MORFOLÓGICO',
    'MORPHOLOGY TYPE': 'TIPO MORFOLÓGICO',
    'LINEAGE': 'LINHAGEM',
    'SIZE': 'PORTE',
    'LIFESPAN': 'EXPECTATIVA DE VIDA',
    'GROWTH_CURVE': 'CURVA DE CRESCIMENTO', 
    'GROWTH CURVE': 'CURVA DE CRESCIMENTO',
    'NUTRITION': 'NUTRIÇÃO',
    'KCAL_PUPPY': 'KCAL FILHOTE',
    'KCAL PUPPY': 'KCAL FILHOTE',
    'KCAL_ADULT': 'KCAL ADULTO', 
    'KCAL ADULT': 'KCAL ADULTO',
    'KCAL_SENIOR': 'KCAL SENIOR',
    'TARGET_NUTRIENTS': 'NUTRIENTES ALVO',
    'TARGET NUTRIENTS': 'NUTRIENTES ALVO',
    'WEIGHT': 'PESO',
    'HEIGHT': 'ALTURA',
    'COAT': 'PELAGEM',
    'COLOR': 'COR',
    'TEMPERAMENT': 'TEMPERAMENTO',
    'ENERGY_LEVEL': 'NÍVEL DE ENERGIA',
    'SOCIAL_BEHAVIOR': 'COMPORTAMENTO SOCIAL',
    'CLINICAL_SIGNS': 'SINAIS CLÍNICOS',
    'CLINICAL SIGNS': 'SINAIS CLÍNICOS',
    
    // Additional Keys from Analysis
    'GROOMING': 'CUIDADOS & HIGIENE',
    'COAT_TYPE': 'TIPO DE PELAGEM',
    'COAT TYPE': 'TIPO DE PELAGEM',
    'GROOMING_FREQUENCY': 'FREQUÊNCIA DE ESCOVAÇÃO',
    'GROOMING FREQUENCY': 'FREQUÊNCIA DE ESCOVAÇÃO',
    'HEALTH': 'SAÚDE',
    'PREDISPOSITIONS': 'PREDISPOSIÇÕES',
    'PREVENTIVE_CHECKUP': 'CHECK-UP PREVENTIVO',
    'PREVENTIVE CHECKUP': 'CHECK-UP PREVENTIVO',
    'LIFESTYLE': 'ESTILO DE VIDA',
    'TRAINING_INTELLIGENCE': 'INTELIGÊNCIA / TREINAMENTO',
    'TRAINING INTELLIGENCE': 'INTELIGÊNCIA / TREINAMENTO',
    'ENVIRONMENT_TYPE': 'AMBIENTE IDEAL',
    'ENVIRONMENT TYPE': 'AMBIENTE IDEAL',
    'ACTIVITY_LEVEL': 'NÍVEL DE ATIVIDADE',
    'ACTIVITY LEVEL': 'NÍVEL DE ATIVIDADE',
    'PERSONALITY': 'PERSONALIDADE',
    'SOCIAL_BEHAVIOR': 'COMPORTAMENTO SOCIAL',
  };

  String _translateKey(String key) {
    final upper = key.toUpperCase();
    if (_keyTranslations.containsKey(upper)) return _keyTranslations[upper]!;
    
    final withUnderscore = upper.replaceAll(' ', '_');
    if (_keyTranslations.containsKey(withUnderscore)) return _keyTranslations[withUnderscore]!;
    
    final withSpace = upper.replaceAll('_', ' ');
    if (_keyTranslations.containsKey(withSpace)) return _keyTranslations[withSpace]!;

    return withSpace; 
  }

  String _translateSex(String? val, AppLocalizations str) {
      if (val == null) return str.petNotOffice; 
      final v = val.toLowerCase().trim();
      if (v.contains('fêmea') || v.contains('femea') || v.contains('female')) return 'Fêmea';
      if (v.contains('macho') || v.contains('male')) return 'Macho';
      return val; 
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
               _translateKey(key),
               style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.black) // V64: Consistent Black Titles
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
        if (val.length > 500) val = '${val.substring(0, 500)}...';
        
        yield pw.Padding(
          padding: pw.EdgeInsets.only(left: indent, bottom: 3),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
               pw.SizedBox(
                 width: 120, 
                 child: pw.Text('${_translateKey(key)}:',  
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
        final allEvents = PetEventService().getEventsByPet(profile.id);
        
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

    // 2. Gallery Images & Docs (Smart Deduplication & Formatting)
    final List<Map<String, dynamic>> galleryImages = [];
    final List<String> otherDocNames = []; 
    if (sections['gallery'] == true) {
        try {
            debugPrint('📸 Loading gallery for pet: ${profile.petName}');
            final allDocs = await FileUploadService().getMedicalDocuments(profile.petName);
            debugPrint('📸 Found ${allDocs.length} raw documents');

            // 🧠 DEDUPLICATION ENGINE (V130: Aggressive Size-Based)
            final Map<String, File> uniqueImages = {}; // Key can be timestamp OR file size hash
            final Set<int> processedSizes = {};
            final List<File> sortedFiles = [];

            // 1. Group by "Event ID" (Timestamp)
            // Regex to find 13-digit timestamps: 1768457048289
            final RegExp timestampRegex = RegExp(r'(\d{13})');

            for (var file in allDocs) {
                final ext = path.extension(file.path).toLowerCase();
                if (!['.jpg', '.jpeg', '.png', '.webp'].contains(ext)) {
                     otherDocNames.add(path.basename(file.path));
                     continue;
                }
                
                // 🛡️ V130: Check exact file size for content deduplication
                // This prevents "copy.jpg" and "original.jpg" from both appearing
                try {
                    final size = file.lengthSync();
                    if (processedSizes.contains(size)) {
                         // Check if this is an "OPT_" version upgrade for an existing file?
                         // For simplicity, we assume duplicate size = duplicate image and skip.
                         // Optimization: If current name starts with OPT_ and previous didn't, we might want to swap. 
                         // But since we can't easily find the *previous* file by size in a Set, let's look at the implementation below.
                    }
                } catch (e) {
                   debugPrint('Error reading file size: $e');
                }

                final name = path.basename(file.path);
                final match = timestampRegex.firstMatch(name);
                
                if (match != null) {
                    final timestamp = match.group(0)!;
                    
                    if (uniqueImages.containsKey(timestamp)) {
                        final existing = uniqueImages[timestamp]!;
                        final existingName = path.basename(existing.path);
                        // Upgrade to OPT_
                        if (!existingName.startsWith('OPT_') && name.startsWith('OPT_')) {
                             uniqueImages[timestamp] = file; 
                             // Update size index? Complex. Let's rely on timestamp mostly.
                        }
                    } else {
                        // Check size collision BEFORE adding
                        final size = file.lengthSync();
                        if (!processedSizes.contains(size)) {
                            uniqueImages[timestamp] = file;
                            processedSizes.add(size);
                        }
                    }
                } else {
                    // No timestamp: Rely pureley on size deduplication
                    final size = file.lengthSync();
                    if (!processedSizes.contains(size)) {
                        sortedFiles.add(file);
                        processedSizes.add(size);
                    }
                }
            }
            
            // Add unique timestamped images to list
            sortedFiles.addAll(uniqueImages.values);

            // Sort by Date (Newest First)
            sortedFiles.sort((a, b) {
                 final statA = a.lastModifiedSync();
                 final statB = b.lastModifiedSync();
                 return statB.compareTo(statA);
            });

            for (var file in sortedFiles) {
                 final memImg = await safeLoadImage(file.path);
                 if (memImg != null) {
                     final name = path.basename(file.path);
                     String caption = name;
                     
                     // 🎨 SMART CAPTIONING
                     final match = timestampRegex.firstMatch(name);
                     if (match != null) {
                         try {
                             final ts = int.parse(match.group(0)!);
                             final date = DateTime.fromMillisecondsSinceEpoch(ts);
                             caption = DateFormat('dd/MM/yy HH:mm').format(date);
                         } catch (_) {}
                     } else {
                         // Fallback clean
                         caption = caption.replaceAll('OPT_', '').replaceAll('.jpg', '').replaceAll('.png', '');
                         if (caption.length > 20) caption = '${caption.substring(0, 17)}...';
                     }
                     
                     galleryImages.add({
                         'image': memImg,
                         'caption': caption,
                     });
                 }
            }
            debugPrint('📸 Gallery final: ${galleryImages.length} unique images');
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

    // 🛡️ V_FIX_PDF: Use Unified History (historicoAnaliseFeridas)
    if (sections['health'] == true) {
        // Source 1: Unified History (Priority)
        if (profile.historicoAnaliseFeridas.isNotEmpty) {
             final sorted = List<AnaliseFeridaModel>.from(profile.historicoAnaliseFeridas)
                ..sort((a,b) => b.dataAnalise.compareTo(a.dataAnalise));
             
             for (var item in sorted) {
                 final img = await safeLoadImage(item.imagemRef);
                 woundsWithImages.add({
                     'date': item.dataAnalise.toIso8601String(),
                     'severity': item.nivelRisco,
                     'diagnosis': item.diagnosticosProvaveis.join(', '), 
                     'recommendations': [item.recomendacao], 
                     'pdfImage': img,
                     'category': item.categoria,
                     'achadosVisuais': item.achadosVisuais,
                 });
             }
        } 
        // Source 2: Legacy History (Fallback)
        else if (profile.woundAnalysisHistory.isNotEmpty) {
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
                        const pw.IconData(0xe91f), 
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
                  style: const pw.TextStyle(
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
                        style: const pw.TextStyle(
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
                  style: const pw.TextStyle(
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

    // --- Helper Styles for Tables ---
    final headerStyle = pw.TextStyle(color: PdfColors.black, fontWeight: pw.FontWeight.bold, fontSize: 10);
    const cellStyle = pw.TextStyle(fontSize: 9);
    final boldCellStyle = pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold);
    const padding = pw.EdgeInsets.all(6);

    // --- Data Extraction Logic for Identity ---
    String pesoIdealDisplay = strings.petNotOffice;
    if (profile.pesoIdeal != null) {
        pesoIdealDisplay = '${profile.pesoIdeal} kg';
    } else if (profile.rawAnalysis != null) {
          // Try deep extraction from raw analysis
          final rawGrowth = profile.rawAnalysis!['identificacao'] != null 
              ? (profile.rawAnalysis!['identificacao']['curva_crescimento'] as Map?) 
              : null;
          
          if (rawGrowth != null && rawGrowth['peso_adulto'] != null) {
              pesoIdealDisplay = '${rawGrowth['peso_adulto']} (Est.)';
          }
    }

    final growthData = (profile.rawAnalysis?['identificacao'] != null && profile.rawAnalysis!['identificacao']['curva_crescimento'] != null)
        ? (profile.rawAnalysis!['identificacao']['curva_crescimento'] as Map)
        : {};

    // ========== CONTENT PAGES ==========
    // 🛡️ V140: Pre-build Lab Exam Widgets (Async) to handle File existence checks
    List<pw.Widget> labExamsWidgets = [];
    if (profile.labExams.isNotEmpty) {
      labExamsWidgets.add(pw.SizedBox(height: 15));
      labExamsWidgets.add(
          pw.Text('${strings.pdfExamesLab}:', 
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black))
      );
      labExamsWidgets.add(pw.SizedBox(height: 5));

      for (var examJson in profile.labExams) {
         final exam = LabExam.fromJson(examJson);
         
         String categoryLabel = exam.category;
         switch(exam.category.toLowerCase()) {
             case 'blood': categoryLabel = 'Exame de Sangue'; break;
             case 'urine': categoryLabel = 'Exame de Urina'; break;
             case 'feces': categoryLabel = 'Exame de Fezes'; break;
             case 'other': categoryLabel = 'Outro Exame'; break;
         }

         // Header
         labExamsWidgets.add(
            pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border(
                      top: pw.BorderSide(color: PdfColors.grey400),
                      bottom: pw.BorderSide(color: PdfColors.grey400),
                  )
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(categoryLabel.toUpperCase(), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                    pw.Text(DateFormat.yMd(strings.localeName).format(exam.uploadDate), style: const pw.TextStyle(fontSize: 9, color: PdfColors.black)),
                  ],
                ),
            )
         );

         // Image (Async Check)
         final file = File(exam.filePath);
         if (await file.exists()) {
             labExamsWidgets.add(
                 pw.Container(
                    alignment: pw.Alignment.center,
                    height: 300, 
                    margin: const pw.EdgeInsets.symmetric(vertical: 8),
                    child: pw.Image(
                        pw.MemoryImage(file.readAsBytesSync()),
                        fit: pw.BoxFit.contain
                    )
                 )
             );
         }

         // Extracted Text (Removed as per user request V141)
         
         // AI Analysis
         if (exam.aiExplanation != null && exam.aiExplanation!.isNotEmpty) {
             labExamsWidgets.add(pw.SizedBox(height: 4));
             labExamsWidgets.add(pw.Text('ANÁLISE DA IA:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.purple900)));
             labExamsWidgets.add(pw.SizedBox(height: 2));

             final lines = exam.aiExplanation!.split('\n');
             for (var line in lines) {
                 if (line.trim().isEmpty) {
                     labExamsWidgets.add(pw.SizedBox(height: 2));
                     continue;
                 }
                 labExamsWidgets.add(
                     pw.Padding(
                         padding: const pw.EdgeInsets.only(bottom: 2),
                         child: pw.Text(line, style: const pw.TextStyle(fontSize: 8, color: PdfColors.black))
                     )
                 );
             }
        }

        labExamsWidgets.add(pw.Divider(color: PdfColors.grey300));
        labExamsWidgets.add(pw.SizedBox(height: 10));
      }
    }

    // 🛡️ V142: Pre-build Feces Analysis Widgets (Async Image Loading)

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        maxPages: 100, // 🛡️ V133: Increased limit for full medical records
        margin: const pw.EdgeInsets.all(35),
        header: (context) => buildHeader('${strings.pdfReportTitle}: ${profile.petName}', timestampStr, dateLabel: strings.pdfGeneratedOn, color: colorPet),
        footer: (context) => buildFooter(context),
        build: (context) => [
          // ========== IDENTITY SECTION ==========
          if (sections['identity'] == true) ...[
            buildSectionHeader(strings.pdfIdentitySection, color: colorPet),
            
            // --- Identity Table ---
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey700, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(1), // Label
                1: const pw.FlexColumnWidth(2), // Value
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(padding: padding, child: pw.Text(strings.pdfFieldLabel, style: headerStyle)),
                    pw.Padding(padding: padding, child: pw.Text(strings.pdfFieldValue, style: headerStyle)),
                  ],
                ),
                // Pet Name (Bold!)
                pw.TableRow(
                  children: [
                    pw.Padding(padding: padding, child: pw.Text(strings.pdfFieldName, style: cellStyle)),
                    pw.Padding(padding: padding, child: pw.Text(profile.petName, style: boldCellStyle)), 
                  ],
                ),
                // Other Standard Rows
                for (var row in [
                    [strings.pdfFieldBreed, profile.raca ?? strings.petNotIdentified],
                    [strings.pdfFieldAge, profile.idadeExata ?? strings.petNotOffice],
                    [strings.pdfFieldSex, _translateSex(profile.sex ?? profile.rawAnalysis?['identificacao']?['sexo'], strings)],
                    [strings.pdfFieldMicrochip, profile.rawAnalysis?['identificacao']?['microchip'] ?? strings.petNotOffice],
                    [strings.pdfFieldCurrentWeight, profile.pesoAtual != null ? '${profile.pesoAtual} kg' : strings.petNotOffice],
                    [strings.pdfFieldIdealWeight, pesoIdealDisplay],
                    [strings.pdfFieldReproductiveStatus, profile.statusReprodutivo ?? strings.petNotOffice],
                    [strings.pdfFieldActivityLevel, profile.nivelAtividade ?? strings.petActivityModerate],
                    [strings.pdfFieldBathFrequency, profile.frequenciaBanho ?? strings.petNotOffice],
                    ['Porte', profile.porte ?? strings.petNotIdentified], // 🛡️ V128: Add Porte
                ]) 
                pw.TableRow(
                  children: [
                     pw.Padding(padding: padding, child: pw.Text(row[0].toString(), style: cellStyle)),
                     pw.Padding(padding: padding, child: pw.Text(row[1].toString(), style: cellStyle)),
                  ]
                )
              ],
            ),

            // --- Growth Curve Section (If data exists) ---
            if (growthData.isNotEmpty) ...[
                pw.SizedBox(height: 15),
                pw.Text('${strings.petGrowthCurve}:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                pw.SizedBox(height: 5),
                pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                    children: [
                        pw.TableRow(
                            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                            children: [
                                pw.Padding(padding: padding, child: pw.Text('3 Meses', style: headerStyle)),
                                pw.Padding(padding: padding, child: pw.Text('6 Meses', style: headerStyle)),
                                pw.Padding(padding: padding, child: pw.Text('12 Meses', style: headerStyle)),
                                pw.Padding(padding: padding, child: pw.Text('Adulto (Est.)', style: headerStyle)),
                            ]
                        ),
                        pw.TableRow(
                            children: [
                                pw.Padding(padding: padding, child: pw.Text(growthData['peso_3_meses']?.toString() ?? '-', style: cellStyle)),
                                pw.Padding(padding: padding, child: pw.Text(growthData['peso_6_meses']?.toString() ?? '-', style: cellStyle)),
                                pw.Padding(padding: padding, child: pw.Text(growthData['peso_12_meses']?.toString() ?? '-', style: cellStyle)),
                                pw.Padding(padding: padding, child: pw.Text(growthData['peso_adulto']?.toString() ?? '-', style: cellStyle)),
                            ]
                        )
                    ]
                )
            ],
            
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

            // 🛡️ V128: Restrições Alimentares (Missing Field)
            if (profile.restricoes.isNotEmpty) ...[
              pw.SizedBox(height: 15),
              pw.Text('Restrições Alimentares:', // TODO: Localize
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
              pw.SizedBox(height: 5),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.red50,
                  border: pw.Border.all(color: PdfColors.red200),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  profile.restricoes.join(', '),
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.red900),
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
            pw.TableHelper.fromTextArray(
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
              pw.TableHelper.fromTextArray(
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
            pw.TableHelper.fromTextArray(
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
                pw.TableHelper.fromTextArray(
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

            // 🏥 Histórico de Sinais Clínicos e Triagem (Clinical Signs & Triage)
            if (profile.analysisHistory.any((a) => (a['clinical_signs'] ?? a['clinicalSigns']) != null)) ...[
                pw.SizedBox(height: 15),
                pw.Text('${strings.pdfClinicalSigns}:', 
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                pw.SizedBox(height: 5),
                ...profile.analysisHistory.where((a) => (a['clinical_signs'] ?? a['clinicalSigns']) != null).map((analysis) {
                    final dateStr = DateFormat.yMd(strings.localeName).format(
                        DateTime.tryParse(analysis['last_updated']?.toString() ?? analysis['created_at']?.toString() ?? '') ?? DateTime.now()
                    );
                    
                    final signs = (analysis['clinical_signs'] ?? analysis['clinicalSigns'] ?? {}) as Map;
                    // Handle diagnosis list or string
                    String diagnosis = 'N/A';
                    if (analysis['possiveis_causas'] != null) {
                       if (analysis['possiveis_causas'] is List) {
                          diagnosis = (analysis['possiveis_causas'] as List).join(', ');
                       } else {
                          diagnosis = analysis['possiveis_causas'].toString();
                       }
                    } else if (analysis['diagnosis'] != null) {
                       diagnosis = analysis['diagnosis'].toString();
                    }

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
                                       pw.Text(dateStr, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                                       pw.Expanded(child: pw.Text(diagnosis, textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700))),
                                    ]
                                 ),
                                 pw.SizedBox(height: 4),
                                 pw.Divider(color: PdfColors.grey300, thickness: 0.5),
                                 pw.SizedBox(height: 4),
                                 
                                 // Grid of signs
                                 pw.Row(
                                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                                    children: [
                                        // Eyes
                                        if (signs['eyes'] != null)
                                            pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                                                pw.Text(strings.pdfEyes, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                                                pw.Text(signs['eyes'].toString(), style: const pw.TextStyle(fontSize: 8)),
                                            ])),
                                        if (signs['eyes'] != null) pw.SizedBox(width: 8),

                                        // Teeth
                                        if (signs['dental'] != null || signs['teeth'] != null)
                                            pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                                                pw.Text(strings.pdfTeeth, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                                                pw.Text((signs['dental'] ?? signs['teeth']).toString(), style: const pw.TextStyle(fontSize: 8)),
                                            ])),
                                        if (signs['dental'] != null || signs['teeth'] != null) pw.SizedBox(width: 8),

                                        // Skin (General)
                                        if (signs['skin'] != null)
                                            pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                                                pw.Text(strings.pdfSkin, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                                                pw.Text(signs['skin'].toString(), style: const pw.TextStyle(fontSize: 8)),
                                            ])),
                                    ]
                                 )
                             ]
                         )
                    );
                }),
            ],

              // 🛡️ V140: Inject Pre-built Lab Exam Widgets
              ...labExamsWidgets,


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
              }),
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
                        )),
                    ];
                  } catch (e) {
                    debugPrint('⚠️ [V72-PDF] Error rendering meal plan day ${entry.key}: $e');
                    return <pw.Widget>[];
                  }
              }),
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
                )),
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
                }),
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
                }),
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
              ...counts.entries.take(2).map((e) => buildIndicator(e.key, e.value.toString(), colorPetLight)),
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
          pw.TableHelper.fromTextArray(
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
              }),
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
          header: (context) => buildHeader("${strings.pdfFoodTitle} - ${item.foodName}", timestampStr, dateLabel: strings.pdfDate, color: colorFood),
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
              decoration: const pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.all(pw.Radius.circular(5))),
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
            pw.TableHelper.fromTextArray(
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
       String toxicityLabel = item.toxicityStatus == 'harmful_pets' ? 'TÓXICA: ANIMAIS' : 'POTENCIALMENTE TÓXICA';
       
       if (isToxic) {
          final meta = item.rawMetadata;
          if (meta != null && meta['seguranca_biofilia'] != null) {
             final sec = meta['seguranca_biofilia']['seguranca_domestica'];
             if (sec != null) {
                final details = (sec['sintomas_ingestao'] ?? sec['toxicity_details'] ?? '').toString().toLowerCase();
                final bool toxicPets = sec['toxica_para_pets'] == true || sec['is_toxic_to_pets'] == true;
                final bool toxicKids = sec['toxica_para_criancas'] == true || sec['is_toxic_to_children'] == true;
                
                // Specific Detection
                if (details.contains('gato') && details.contains('cão')) {
                   toxicityLabel = 'TÓXICA: CÃES E GATOS';
                } else if (details.contains('gato') || details.contains('felino')) {
                   toxicityLabel = 'TÓXICA: GATOS';
                } else if (details.contains('cão') || details.contains('cachorro') || details.contains('canino')) {
                   toxicityLabel = 'TÓXICA: CÃES';
                } else if (toxicPets || details.contains('animais') || details.contains('pets')) {
                   toxicityLabel = 'TÓXICA: ANIMAIS';
                } else if (toxicKids) {
                   toxicityLabel = 'TÓXICA: HUMANOS';
                }
             }
          }
       }
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
                 child: pw.Column(
                   crossAxisAlignment: pw.CrossAxisAlignment.start,
                   children: [
                      pw.Text(
                       'ATENÇÃO: Esta planta apresenta toxicidade.',
                       style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.red900),
                      ),
                      pw.Text(
                       _getBotanyHistoryToxicityText(item),
                       style: const pw.TextStyle(fontSize: 10, height: 1.5, color: PdfColors.black)
                      ),
                   ],
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
                            _buildCareIcon('sun', _parsePlantCareLevel(item.lightWaterSoilNeeds['luz'], 'sun'), size: 10),
                            pw.SizedBox(width: 5),
                            pw.Text('${strings.labelSun}: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                            pw.Expanded(child: pw.Text(item.lightWaterSoilNeeds['luz']!, style: const pw.TextStyle(fontSize: 10))),
                          ],
                        ),
                      ),
                    if (item.lightWaterSoilNeeds['agua'] != null)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 6),
                        child: pw.Row(
                          children: [
                            _buildCareIcon('water', _parsePlantCareLevel(item.lightWaterSoilNeeds['agua'], 'water'), size: 10),
                            pw.SizedBox(width: 5),
                            pw.Text('${strings.labelWater}: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                            pw.Expanded(child: pw.Text(item.lightWaterSoilNeeds['agua']!, style: const pw.TextStyle(fontSize: 10))),
                          ],
                        ),
                      ),
                    if (item.lightWaterSoilNeeds['solo'] != null)
                      pw.Row(
                        children: [
                          _buildCareIcon('soil', _parsePlantCareLevel(item.lightWaterSoilNeeds['solo'], 'soil'), size: 10),
                          pw.SizedBox(width: 5),
                          pw.Text('${strings.labelSoil}: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                          pw.Expanded(child: pw.Text(item.lightWaterSoilNeeds['solo']!, style: const pw.TextStyle(fontSize: 10))),
                        ],
                      ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              _buildCareLegend(strings),
           ],
        ),
      );
    }
    return pdf;
  }

  /// 6. VETERINARY 360 REPORT (SCANNUT STANDARD V116)
  Future<pw.Document> generateVeterinary360Report({
    required PetAnalysisResult analysis,
    required String imagePath,
    required AppLocalizations strings,
    PetProfileExtended? profile, // 🛡️ V180
  }) async {
    debugPrint('🔍 [V116-PDF] Iniciando renderização via pdfpreview...');
    final pdf = pw.Document();
    final String timestampStr = DateFormat.yMd(strings.localeName).add_Hm().format(DateTime.now());
    
    // Load Pet Image
    pw.ImageProvider? petImage = await safeLoadImage(imagePath);

    // 🛡️ V_FIX_PDF: Consolidated History (New + Legacy)
    debugPrint('[PDF-DEBUG] Starting History Merge in Vet360. Profile: ${profile?.petName}');
    List<AnaliseFeridaModel> fullHistory = [];
    if (profile != null) {
         debugPrint('[PDF-DEBUG] Raw Unified History Count: ${profile.historicoAnaliseFeridas.length}');
         fullHistory.addAll(profile.historicoAnaliseFeridas);
         
         // Merge Legacy
         debugPrint('[PDF-DEBUG] Raw Legacy History Count: ${profile.woundAnalysisHistory.length}');
         if (profile.woundAnalysisHistory.isNotEmpty) {
             for (var w in profile.woundAnalysisHistory) {
                 try {
                   fullHistory.add(AnaliseFeridaModel(
                       dataAnalise: DateTime.tryParse(w['date']?.toString() ?? '') ?? DateTime.now(),
                       imagemRef: w['imagePath']?.toString() ?? '',
                       achadosVisuais: {},
                       nivelRisco: w['severity']?.toString() ?? 'Geral',
                       recomendacao: (w['recommendations'] as List?)?.join(', ') ?? '',
                       diagnosticosProvaveis: w['diagnosis'] != null ? [w['diagnosis'].toString()] : [],
                       categoria: 'Historico'
                   ));
                 } catch (e) {
                    debugPrint('⚠️ Error merging legacy history item: $e');
                 }
             }
         }
         // Sort
         fullHistory.sort((a, b) => b.dataAnalise.compareTo(a.dataAnalise));
         debugPrint('[PDF-DEBUG] Total Merged History Items: ${fullHistory.length}');
    }

    // Pre-load history images (V_FIX_PDF)
    final Map<int, pw.ImageProvider> historyImages = {};
    if (fullHistory.isNotEmpty) {
       for (int i = 0; i < fullHistory.length; i++) {
           final item = fullHistory[i];
           debugPrint('[PDF-DEBUG] Processing Item $i: Date=${item.dataAnalise}, Ref="${item.imagemRef}"');
           
           if (item.imagemRef.isNotEmpty) {
               final img = await safeLoadImage(item.imagemRef);
               debugPrint('[PDF-DEBUG] Image Load $i: ${img != null ? "SUCCESS" : "FAIL (null returned)"}');
               if (img != null) {
                   historyImages[i] = img;
               }
           } else {
               debugPrint('[PDF-DEBUG] Image Load $i: SKIPPED (Empty Ref)');
           }
       }
    }
    
    // Extract Metadata
    final petName = analysis.petName ?? strings.petUnknown;
    final breed = analysis.raca;
    final size = analysis.identificacao.porteEstimado;
    final reliability = analysis.reliability ?? '90%';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (context) => buildHeader('${strings.petDossierTitle.toUpperCase()} - $petName', timestampStr, color: colorPet),
        footer: (context) => buildFooter(context, strings: strings),
        build: (context) => [
          // 🛡️ V116: IDENTITY BLOCK
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (petImage != null)
                pw.Container(
                  width: 120,
                  height: 120,
                  margin: const pw.EdgeInsets.only(right: 20),
                  decoration: pw.BoxDecoration(
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    border: pw.Border.all(color: colorPet, width: 2),
                  ),
                  child: pw.ClipRRect(
                    horizontalRadius: 6,
                    verticalRadius: 6,
                    child: pw.Image(petImage, fit: pw.BoxFit.cover),
                  ),
                ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(petName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 24, color: PdfColors.black)),
                    pw.SizedBox(height: 5),
                    pw.Text('$breed • $size', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                    pw.SizedBox(height: 15),
                    
                    // PRECISION SEAL (V116)
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: pw.BoxDecoration(
                        color: colorPetLight,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
                        border: pw.Border.all(color: colorPet, width: 1),
                      ),
                      child: pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Text('🛡️', style: const pw.TextStyle(fontSize: 12)),
                          pw.SizedBox(width: 5),
                          pw.Text('${strings.pdfPrecision.toUpperCase() ?? "PRECISÃO"}: $reliability', 
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.black)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          pw.SizedBox(height: 30),

          // 🛡️ V116: BIO-VISUAL SIGNAL DETAILS
          buildSectionHeader(strings.petAnalysisResults.toUpperCase(), color: colorPet),
          pw.SizedBox(height: 10),
          
          // Identity Details
          pw.Text('1. ${strings.petSectionIdentity.toUpperCase()}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
          pw.SizedBox(height: 5),
          pw.Bullet(text: '${strings.pdfFieldBreed}: ${analysis.identificacao.racaPredominante}'),
          pw.Bullet(text: 'Linhagem: ${analysis.identificacao.linhagemSrdProvavel}'),
          // V470: Morphology & Origin (Re-enabled)
          if (analysis.identificacao.origemGeografica.trim().isNotEmpty && analysis.identificacao.origemGeografica != 'N/A')
             pw.Bullet(text: '${strings.petOriginRegion}: ${analysis.identificacao.origemGeografica}'),
          if (analysis.identificacao.morfologiaBase.trim().isNotEmpty && analysis.identificacao.morfologiaBase != 'N/A')
             pw.Bullet(text: '${strings.petMorphology}: ${analysis.identificacao.morfologiaBase}'),

          // V472: Growth Curve Table
          if (analysis.identificacao.curvaCrescimento.isNotEmpty) ...[
               pw.SizedBox(height: 8),
               pw.Text(strings.petGrowthCurve, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.grey800)),
               pw.SizedBox(height: 4),
               pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                  children: [
                      pw.TableRow(
                          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                          children: [
                              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('3 Meses', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('6 Meses', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('12 Meses', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Adulto (Est.)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                          ]
                      ),
                      pw.TableRow(
                          children: [
                              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(analysis.identificacao.curvaCrescimento['peso_3_meses']?.toString() ?? '-', style: const pw.TextStyle(fontSize: 8))),
                              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(analysis.identificacao.curvaCrescimento['peso_6_meses']?.toString() ?? '-', style: const pw.TextStyle(fontSize: 8))),
                              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(analysis.identificacao.curvaCrescimento['peso_12_meses']?.toString() ?? '-', style: const pw.TextStyle(fontSize: 8))),
                              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(analysis.identificacao.curvaCrescimento['peso_adulto']?.toString() ?? '-', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                          ]
                      )
                  ]
               ),
               pw.SizedBox(height: 5),
          ],
          pw.SizedBox(height: 10),

          // Health Details
          pw.Text('2. ${strings.petSectionPreventive.toUpperCase()}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
          pw.SizedBox(height: 5),
          if (analysis.saude.predisposicoesGeneticas.isNotEmpty)
             pw.Text('Genética: ${analysis.saude.predisposicoesGeneticas}', style: const pw.TextStyle(fontSize: 10)),
          if (analysis.saude.sinaisAlertaPrecoce.isNotEmpty)
             pw.Text('Sinais de Alerta: ${analysis.saude.sinaisAlertaPrecoce}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.red900)),
          pw.SizedBox(height: 10),

          // V472: Clinical Signs Logic (Eyes/Teeth/Skin)
          if (analysis.eyeDetails != null || analysis.dentalDetails != null || analysis.skinDetails != null) ...[
              pw.Text(strings.pdfClinicalSigns, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.SizedBox(height: 4),
              pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                  columnWidths: {
                      0: const pw.FlexColumnWidth(1),
                      1: const pw.FlexColumnWidth(3),
                  },
                  children: [
                      if (analysis.eyeDetails != null)
                          pw.TableRow(children: [
                              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(strings.pdfEyes, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(analysis.eyeDetails!['characteristics']?.toString() ?? 'N/A', style: const pw.TextStyle(fontSize: 9))),
                          ]),
                      if (analysis.dentalDetails != null)
                          pw.TableRow(children: [
                              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(strings.pdfTeeth, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(analysis.dentalDetails!['characteristics']?.toString() ?? 'N/A', style: const pw.TextStyle(fontSize: 9))),
                          ]),
                      if (analysis.skinDetails != null)
                          pw.TableRow(children: [
                              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(strings.pdfSkin, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(analysis.skinDetails!['characteristics']?.toString() ?? 'N/A', style: const pw.TextStyle(fontSize: 9))),
                          ]),
                  ]
              ),
              pw.SizedBox(height: 10),
          ],
          
          // Nutrition
          pw.Text('3. ${strings.petSectionNutrition.toUpperCase()}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
          pw.SizedBox(height: 5),
          pw.Bullet(text: 'Metas Calóricas: Adulto (${analysis.nutricao.metaCalorica['kcal_adulto']}), Filhote (${analysis.nutricao.metaCalorica['kcal_filhote']})'),
          pw.Bullet(text: 'Nutrientes Alvo: ${analysis.nutricao.nutrientesAlvo.join(", ")}'),
          
          pw.SizedBox(height: 15),
          
          // Lifestyle
          pw.Text('4. ${strings.petSectionLifestyle.toUpperCase()}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
          pw.SizedBox(height: 5),
          pw.Bullet(text: 'Ambiente Ideal: ${analysis.lifestyle.ambienteIdeal['necessidade_de_espaco_aberto']}'),
          pw.Bullet(text: 'Nível de Atividade: ${analysis.lifestyle.estimuloMental['necessidade_estimulo_mental']}'),
          
          pw.SizedBox(height: 15),

          // 🛡️ V231: STOOL ANALYSIS DETAILS (ROBUST CHECK)
          if (analysis.analysisType == 'stool_analysis' || (analysis.category?.toLowerCase().contains('fezes') ?? false) || analysis.stoolAnalysis != null) ...[
             _buildStoolAnalysisSection(analysis, strings),
          ],

          // 🛡️ V180: WOUND EVOLUTION HISTORY
          // 🛡️ V180: WOUND EVOLUTION HISTORY (Unified)
          if (fullHistory.isNotEmpty) ...[
             pw.Text('5. ${strings.pdfAnaliseFeridas.toUpperCase()}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
             pw.SizedBox(height: 5),
             
             ...fullHistory.asMap().entries.map((entry) {
                 final index = entry.key;
                 final h = entry.value;
                 final dateStr = DateFormat.yMd(strings.localeName).format(h.dataAnalise);
                 final historyImg = historyImages[index];

                 return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 12),
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                         // IMAGE THUMBNAIL
                         if (historyImg != null)
                             pw.Container(
                               width: 60,
                               height: 60,
                               margin: const pw.EdgeInsets.only(right: 8),
                               decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
                               child: pw.Image(historyImg, fit: pw.BoxFit.cover)
                             ),

                         pw.Expanded(
                           child: pw.Column(
                             crossAxisAlignment: pw.CrossAxisAlignment.start,
                             children: [
                                // HEADER ROW
                                pw.Row(
                                  children: [
                                      pw.Text(dateStr, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                                      pw.SizedBox(width: 8),
                                      pw.Container(
                                        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        decoration: pw.BoxDecoration(
                                          color: h.nivelRisco.toLowerCase().contains('alto') ? PdfColors.red : 
                                                 (h.nivelRisco.toLowerCase().contains('médio') ? PdfColors.orange : PdfColors.green),
                                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                                        ),
                                        child: pw.Text(
                                          (h.nivelRisco.isEmpty ? 'Geral' : h.nivelRisco).toUpperCase(),
                                          style: pw.TextStyle(color: PdfColors.white, fontSize: 7, fontWeight: pw.FontWeight.bold)
                                        ),
                                      ),
                                       pw.SizedBox(width: 8),
                                      pw.Text((h.categoria ?? 'Geral').toUpperCase(), style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
                                  ]
                                ),
                                pw.SizedBox(height: 4),
                                
                                // DIAGNOSES
                                if (h.diagnosticosProvaveis.isNotEmpty)
                                   pw.Text('Diagnósticos: ${h.diagnosticosProvaveis.join(", ")}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                                
                                // RECOMMENDATION
                                pw.Padding(
                                   padding: const pw.EdgeInsets.only(top: 2),
                                   child: pw.Text(h.recomendacao, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800))
                                )
                             ]
                           )
                         )
                      ]
                    )
                 );
             }),
          ] else if (analysis.analysisType == 'diagnosis') ...[
             // Fallback for current analysis implies first
             pw.SizedBox(height: 5),
             pw.Text('5. ${strings.pdfAnaliseFeridas.toUpperCase()}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
             pw.Text("Primeira Análise Registrada", style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic, color: PdfColors.grey600)),
          ],

          pw.SizedBox(height: 30),

          // 🛡️ V116: LEGAL DISCLAIMER
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
            ),
            child: pw.Row(
              children: [
                pw.Text('⚠️', style: const pw.TextStyle(fontSize: 18)),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Text(
                    strings.petDossierDisclaimer,
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    debugPrint('✅ [V116-PDF] Relatório gerado com sucesso para o pet: $petName.');
    return pdf;
  }

  /// 🛡️ V231: Build Stool Analysis Section for PDF
  pw.Widget _buildStoolAnalysisSection(PetAnalysisResult analysis, AppLocalizations strings) {
    final details = analysis.stoolAnalysis ?? {};
    final PdfColor pdfRiskColor = analysis.urgenciaNivel.toLowerCase().contains('vermelho') ? PdfColors.red : 
                            (analysis.urgenciaNivel.toLowerCase().contains('amarelo') ? PdfColors.orange : PdfColors.green);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 15),
        pw.Text('5. ANÁLISE COPROLÓGICA (STOOL ANALYSIS)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
        pw.SizedBox(height: 8),
        
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                   pw.Text('STATUS:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                   pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: pw.BoxDecoration(color: pdfRiskColor, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
                      child: pw.Text(analysis.urgenciaNivel.toUpperCase(), style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8)),
                   ),
                ],
              ),
              pw.SizedBox(height: 10),
              
              _buildReportRow('Consistência (Bristol):', 'Escala ${details['consistency_bristol_scale'] ?? "-"}'),
              _buildReportRow('Textura/Firmeza:', details['firmness']?.toString() ?? '-'),
              _buildReportRow('Hidratação/Muco:', details['hydration_mucus']?.toString() ?? '-'),
              _buildReportRow('Cor:', '${details['color_name'] ?? "-"} (${details['color_hex'] ?? ""})'),
              _buildReportRow('Significado Clínico:', details['clinical_color_meaning']?.toString() ?? '-'),
              _buildReportRow('Corpos Estranhos:', (details['foreign_bodies'] as List?)?.join(", ") ?? 'Nenhum detectado'),
              _buildReportRow('Parasitas Visíveis:', (details['parasites_detected'] == true) ? 'SIM' : 'Não detectados'),
              _buildReportRow('Avaliação de Volume:', details['volume_assessment']?.toString() ?? '-'),
              
              pw.Divider(thickness: 0.5, color: PdfColors.grey400, height: 16),
              
              pw.Text('DESCRIÇÃO VISUAL COMPLETA:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
              pw.SizedBox(height: 4),
              pw.Text(analysis.descricaoVisual, style: const pw.TextStyle(fontSize: 8.5)),
            ],
          ),
        ),
        
        if (analysis.possiveisCausas.isNotEmpty) ...[
          pw.SizedBox(height: 10),
           pw.Text('DIAGNÓSTICOS DIFERENCIAIS:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
           ...analysis.possiveisCausas.map((c) => pw.Bullet(text: c, style: const pw.TextStyle(fontSize: 8.5))),
        ],
        
        pw.SizedBox(height: 10),
        pw.Container(
           padding: const pw.EdgeInsets.all(8),
           decoration: pw.BoxDecoration(color: colorPetUltraLight, border: pw.Border.all(color: colorPet, width: 0.5)),
           child: pw.Column(
             crossAxisAlignment: pw.CrossAxisAlignment.start,
             children: [
                pw.Text('CONSELHO DO ESPECIALISTA:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.black)),
                pw.SizedBox(height: 4),
                pw.Text(analysis.orientacaoImediata, style: pw.TextStyle(fontSize: 8.5, fontStyle: pw.FontStyle.italic)),
             ],
           ),
        ),
      ],
    );
  }

  pw.Widget _buildReportRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 120, child: pw.Text(label, style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 8))),
          pw.Expanded(child: pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5))),
        ],
      ),
    );
  }

  pw.Widget _buildSafeBullet(String text, {double fontSize = 9, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
             width: 4, height: 4, 
             margin: const pw.EdgeInsets.only(top: 3, right: 6),
             decoration: pw.BoxDecoration(color: color ?? PdfColors.black, shape: pw.BoxShape.circle)
          ),
          pw.Expanded(child: pw.Text(text, style: pw.TextStyle(fontSize: fontSize, color: PdfColors.black)))
        ]
      )
    );
  }

  /// 8. HUMAN FOOD ANALYSIS REPORT (SCANNUT STANDARD V136)
  Future<pw.Document> generateFoodAnalysisReport({
    required FoodAnalysisModel analysis,
    File? imageFile,
    required AppLocalizations strings,
  }) async {
    final pdf = pw.Document();
    final String timestampStr = DateFormat('dd/MM/yyyy HH:mm', strings.localeName).format(DateTime.now());

    pw.ImageProvider? foodImage;
    if (imageFile != null) {
      foodImage = await safeLoadImage(imageFile.path);
    }
    
    // 🛡️ V136: DATA EXTRACTION & SAFETY
    final String dishName = analysis.identidade.nome;
    final String processing = analysis.identidade.statusProcessamento;
    final String trafficLight = analysis.identidade.semaforoSaude;
    final String? weight = analysis.identidade.estimativaPeso;
    final String? method = analysis.identidade.metodoPreparo;
    
    final int kcal = analysis.macros.calorias100g;
    final String carbs = analysis.macros.carboidratosLiquidos;
    final String protein = analysis.macros.proteinas;
    final String fats = analysis.macros.gordurasPerfil;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (context) => buildHeader('${strings.pdfFoodTitle} - 360º', timestampStr, color: colorFood),
        footer: (context) => buildFooter(context, strings: strings),
        build: (context) => [
          // 1. HEADER IMAGE & BASIC INFO
          pw.Row(
             crossAxisAlignment: pw.CrossAxisAlignment.start,
             children: [
                if (foodImage != null)
                   pw.Container(
                     width: 100,
                     height: 100,
                     margin: const pw.EdgeInsets.only(right: 15),
                     decoration: pw.BoxDecoration(
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                        border: pw.Border.all(color: colorFood, width: 2),
                     ),
                     child: pw.ClipRRect(
                        horizontalRadius: 6,
                        verticalRadius: 6,
                        child: pw.Image(foodImage, fit: pw.BoxFit.cover),
                     ),
                   ),
                pw.Expanded(
                   child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                         pw.Text(dishName.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, color: PdfColors.black)),
                         pw.SizedBox(height: 5),
                         pw.Text('$processing • $trafficLight', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                         if (weight != null)
                            pw.Text('Peso Est.: $weight', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                         if (method != null)
                            pw.Text('Preparo: $method', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      ]
                   )
                )
             ]
          ),
          
          pw.SizedBox(height: 20),
          
          // 2. MACROS GRID
          buildSectionHeader(strings.pdfDetailedNutrition, color: colorFood),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
               buildIndicator('Calorias (100g)', '$kcal kcal', colorFood),
               buildIndicator(strings.nutrientsCarbs, carbs, PdfColors.orange),
               buildIndicator(strings.nutrientsProteins, protein, PdfColors.red),
               buildIndicator(strings.nutrientsFats, fats, PdfColors.yellow),
            ]
          ),
          
          pw.SizedBox(height: 20),
          
          // 3. IA VERDICT & PROS/CONS
          buildSectionHeader(strings.pdfExSummary, color: colorFood),
          pw.Container(
             padding: const pw.EdgeInsets.all(12),
             decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: PdfColors.grey300),
             ),
             child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                   pw.Text('VEREDITO DA IA:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                   pw.Text(analysis.analise.vereditoIa, style: const pw.TextStyle(fontSize: 10)),
                   pw.SizedBox(height: 8),
                   if (analysis.analise.pontosPositivos.isNotEmpty) ...[
                      pw.Text('PONTOS POSITIVOS:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.green700)),
                      ...analysis.analise.pontosPositivos.map((e) => _buildSafeBullet(e, color: PdfColors.green700)),
                   ],
                   if (analysis.analise.pontosNegativos.isNotEmpty) ...[
                      pw.SizedBox(height: 8),
                      pw.Text('PONTOS DE ATENÇÃO:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.red700)),
                      ...analysis.analise.pontosNegativos.map((e) => _buildSafeBullet(e, color: PdfColors.red700)),
                   ]
                ]
             )
          ),

          pw.SizedBox(height: 20),

          // 4. BIOHACKING & PERFORMANCE
          buildSectionHeader((strings.foodBiohacking ?? 'BIOHACKING').toUpperCase(), color: colorFood),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
               pw.Expanded(
                 child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text('BENEFÍCIOS AO CORPO:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ...analysis.performance.pontosPositivosCorpo.map((e) => _buildSafeBullet(e, color: colorFood)),
                    pw.SizedBox(height: 10),
                    pw.Text('ATENÇÃO AO CORPO:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    if (analysis.performance.pontosAtencaoCorpo.isEmpty)
                       pw.Text(' - Nenhum ponto crítico.', style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic))
                    else
                       ...analysis.performance.pontosAtencaoCorpo.map((e) => _buildSafeBullet(e, color: PdfColors.orange)),
                 ])
               ),
               pw.SizedBox(width: 15),
               pw.Expanded(
                 child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    buildIndicator(strings.foodSatietyIndex ?? 'Saciedade', '${analysis.performance.indiceSaciedade}/10', PdfColors.teal),
                    pw.SizedBox(height: 10),
                    pw.Text('FOCO & ENERGIA:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.Text(analysis.performance.impactoFocoEnergia, style: const pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(height: 10),
                    pw.Text('MOMENTO IDEAL:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.Text(analysis.performance.momentoIdealConsumo, style: const pw.TextStyle(fontSize: 9)),
                 ])
               ),
            ]
          ),

          pw.SizedBox(height: 20),

          // 5. SAFETY & MICROS
          pw.Row(
             crossAxisAlignment: pw.CrossAxisAlignment.start,
             children: [
                pw.Expanded(
                   child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                       buildSectionHeader(strings.foodSafetyBio ?? 'SEGURANÇA', color: colorFood),
                       if (analysis.identidade.alertaCritico.isNotEmpty && analysis.identidade.alertaCritico != 'Nenhum')
                          pw.Container(
                             padding: const pw.EdgeInsets.all(8),
                             decoration: pw.BoxDecoration(color: PdfColors.red50, border: pw.Border.all(color: PdfColors.red)),
                             child: pw.Text('⚠️ ${analysis.identidade.alertaCritico}', style: pw.TextStyle(color: PdfColors.red900, fontSize: 9, fontWeight: pw.FontWeight.bold)),
                          ),
                       pw.SizedBox(height: 5),
                       pw.Text('BIOQUÍMICA:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                       pw.Text(analysis.identidade.bioquimicaAlert, style: const pw.TextStyle(fontSize: 9)),
                   ])
                ),
                pw.SizedBox(width: 15),
                pw.Expanded(
                   child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                       buildSectionHeader((strings.featureMicrosTitle ?? 'MICRONUTRIENTES').toUpperCase(), color: colorFood),
                       pw.Text('SINERGIA NUTRICIONAL:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                       pw.Text(analysis.micronutrientes.sinergiaNutricional, style: const pw.TextStyle(fontSize: 9)),
                       pw.SizedBox(height: 5),
                       pw.Wrap(
                          spacing: 4, runSpacing: 4,
                          children: analysis.micronutrientes.lista.map((m) {
                             return pw.Container(
                                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: const pw.BoxDecoration(color: PdfColors.grey200, borderRadius: pw.BorderRadius.all(pw.Radius.circular(2))),
                                child: pw.Text('${m.nome} (${m.percentualDv ?? "?"}%)', style: const pw.TextStyle(fontSize: 8))
                             );
                          }).toList()
                       )
                   ])
                ),
             ]
          ),

          pw.SizedBox(height: 20),

          // 6. CULINARY INTELLIGENCE
          buildSectionHeader(strings.recipesCulinaryIntel ?? 'GASTRONOMIA', color: colorFood),
          pw.Row(
             children: [
                pw.Expanded(child: _buildReportRow('Dica do Expert:', analysis.gastronomia.dicaEspecialista)),
                pw.SizedBox(width: 10),
                pw.Expanded(child: _buildReportRow('Smart Swap:', analysis.gastronomia.smartSwap)),
             ]
          ),
          pw.SizedBox(height: 5),
          _buildReportRow('Preservação:', analysis.gastronomia.preservacaoNutrientes),

          if (analysis.receitas.isNotEmpty) ...[
             pw.SizedBox(height: 10),
             pw.Text((strings.recipesQuick ?? 'RECEITAS SUGERIDAS').toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
             pw.SizedBox(height: 5),
             ...analysis.receitas.map((r) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 6),
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                   pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                      pw.Text(r.nome, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      pw.Text(r.tempoPreparo, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                   ]),
                   pw.Text(r.instrucoes, style: const pw.TextStyle(fontSize: 8), maxLines: 2),
                ])
             )),
          ]
        ]
      ),
    );
    return pdf;
  }

  String _getBotanyHistoryToxicityText(BotanyHistoryItem item) {
    String warning = 'Mantenha fora do alcance de crianças e animais de estimação. Em caso de ingestão, procure atendimento médico imediatamente.';
    final meta = item.rawMetadata;
    if (meta != null && meta['seguranca_biofilia'] != null) {
      final sec = meta['seguranca_biofilia']['seguranca_domestica'];
      if (sec != null) {
        final details = (sec['sintomas_ingestao'] ?? sec['toxicity_details'] ?? '').toString().toLowerCase();
        if (details.contains('gato') && details.contains('cão')) {
          warning = 'ALERTA: Esta planta é TÓXICA para CÃES e GATOS. Mantenha em locais inacessíveis (prateleiras altas ou suspensas).';
        } else if (details.contains('gato') || details.contains('felino')) {
          warning = 'ALERTA: Esta planta é TÓXICA para GATOS. Evite tê-la em casa se possuir felinos, pois o contato pode causar insuficiência renal grave.';
        } else if (details.contains('cão') || details.contains('cachorro')) {
          warning = 'ALERTA: Esta planta é TÓXICA para CÃES. Mantenha fora do alcance do seu cachorro.';
        }
      }
    }
    return warning;
  }

  pw.Widget _buildFooter(pw.Context context, AppLocalizations l10n) {
    const fontSize = 9.0;
    
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Column(
        children: [
          pw.Divider(thickness: 0.5, color: PdfColors.black),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              // Left: Author & Copyright
              pw.Text(
                '${l10n.developed_by} Multiverso Digital Copyright 2026',
                style: const pw.TextStyle(fontSize: fontSize), 
              ),
              // Right: Pagination
              pw.Text(
                '${context.pageNumber} / ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: fontSize),
              ),
            ],
          ),
        ]
      )
    );
  }
}

