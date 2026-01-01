import 'dart:typed_data';
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

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  // --- SAFETY HELPERS ---
  Future<pw.ImageProvider?> _safeLoadImage(String? path) async {
    if (path == null || path.isEmpty) return null;
    try {
      final file = File(path);
      if (await file.exists()) {
         final bytes = await file.readAsBytes();
         // Validação básica de header se necessário, mas o try-catch captura erros de decodificação do pdf package
         return pw.MemoryImage(bytes);
      }
    } catch (e) {
      debugPrint('⚠️ [ExportService] Skipped corrupted/missing image: $path | Error: $e');
    }
    return null;
  }

  pw.Widget _buildSectionHeader(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10, top: 15),
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border.symmetric(
          horizontal: pw.BorderSide(color: PdfColors.black, width: 0.5),
        ),
      ),
      child: pw.Center(
        child: pw.Text(
          title.toUpperCase(),
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColors.black),
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
  pw.Widget _buildHeader(String title, String timestamp, {String dateLabel = 'Data'}) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: const pw.BoxDecoration(
               border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  title.toUpperCase(),
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 16,
                    color: PdfColors.black,
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      appName.toUpperCase(),
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.Text(
                      '$dateLabel: $timestamp',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Container(height: 1.5, color: PdfColors.black), // Black line requested by user
          pw.SizedBox(height: 10),
        ],
      ),
    );
  }

  /// RIGOROUS FOOTER: Consistent across all reports
  pw.Widget _buildFooter(pw.Context context, {AppLocalizations? strings}) {
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
  pw.Widget _buildIndicator(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        color: PdfColors.grey100,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          pw.SizedBox(height: 2),
          pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  pw.Widget _buildObservationsBlock(String observations) {
    if (observations.isEmpty) return pw.SizedBox.shrink();

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'HISTÓRICO DE OBSERVAÇÕES:',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            observations,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
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
    String reportType = 'Detalhamento',
  }) async {
    final pdf = pw.Document();
    final String timestampStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final int totalCount = events.length;
    final int completedCount = events.where((e) => e.completed).length;
    final int pendingCount = totalCount - completedCount;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (context) => _buildHeader('Relatório de Agenda Pet', timestampStr),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildIndicator('Total de Eventos:', totalCount.toString(), PdfColors.black),
              _buildIndicator('Concluídos:', completedCount.toString(), PdfColors.green700),
              _buildIndicator('Pendentes:', pendingCount.toString(), PdfColors.red700),
            ],
          ),
          pw.SizedBox(height: 25),
          if (reportType == 'Detalhamento')
            pw.Table.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
              cellStyle: const pw.TextStyle(fontSize: 7.5),
              headers: ['Data/Hora', 'Título do Evento', 'Nome do Pet', 'Parceiro/Local', 'Observações', 'Status'],
              data: events.map((e) => [
                DateFormat('dd/MM HH:mm').format(e.dateTime),
                e.title,
                e.petName,
                e.attendant ?? ' - ',
                e.notes ?? ' - ',
                e.completed ? 'Concluído' : 'Pendente',
              ]).toList(),
            )
          else
            pw.Center(
              child: pw.Text('Relatório Resumido - Tabela Omitida', 
                style: pw.TextStyle(color: PdfColors.grey500, fontStyle: pw.FontStyle.italic, fontSize: 10)),
            ),
        ],
      ),
    );
    return pdf;
  }

  /// 2. PARTNERS REPORT (UNIFIED LAYOUT)
  Future<pw.Document> generatePartnersReport({required List<PartnerModel> partners, required String region}) async {
    final pdf = pw.Document();
    final String timestampStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (context) => _buildHeader('Guia de Parceiros', timestampStr),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildIndicator('Região:', region, PdfColors.black),
              _buildIndicator('Total Encontrado:', partners.length.toString(), PdfColors.blue700),
            ],
          ),
          pw.SizedBox(height: 25),
          pw.Table.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.black, width: 1.0),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue),
            headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headers: ['Estabelecimento', 'Categoria', 'Telefone', 'Avaliação'],
            data: partners.map((p) => [
              p.name,
              p.category,
              p.phone,
              '${p.rating} Estrelas',
            ]).toList(),
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
  }) async {
    final pdf = pw.Document();
    final String timestampStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (context) => _buildHeader(strings.pdfNutritionSection, timestampStr),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // Header Info Card
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              border: pw.Border.all(color: PdfColors.blue800, width: 0.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('PET: $petName', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.Text('PERÍODO: ${period ?? 'Semanal'}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.blue700)),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('RAÇA: $raceName', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('REGIME: $dietType', style: pw.TextStyle(color: PdfColors.blue900, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  ],
                ),
                if (dailyKcal != null) ...[
                  pw.SizedBox(height: 5),
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text('META CALÓRICA DIÁRIA: $dailyKcal', style: pw.TextStyle(color: PdfColors.red800, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  ),
                ],
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Detailed Plan
          ...plan.map((day) {
            final String dia = day['dia']?.toString() ?? 'Dia';
            final List<dynamic> meals = day['refeicoes'] as List? ?? [];

            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 15),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.blue800, width: 1.0),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                   // Day Title Section (Blue Header)
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    color: PdfColors.blue800,
                    child: pw.Text(
                      dia.toUpperCase(),
                      style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 11),
                    ),
                  ),
                  
                  // Meals for this day
                  ...meals.map((m) {
                    final meal = m as Map<String, dynamic>;
                    return pw.Container(
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blue800, width: 0.5)),
                      ),
                      padding: const pw.EdgeInsets.all(10),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // Time, Title and Kcal in the same row
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Row(
                                children: [
                                  pw.Container(
                                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: const pw.BoxDecoration(color: PdfColors.blue100),
                                    child: pw.Text(meal['hora'] ?? '--:--', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                                  ),
                                  pw.SizedBox(width: 10),
                                  pw.Text(meal['titulo'] ?? 'Refeição', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.blue900)),
                                ],
                              ),
                             // Kcal align right + Principais Nutrientes label
                              if (dailyKcal != null)
                                pw.RichText(text: pw.TextSpan(children: [
                                   pw.TextSpan(text: 'Principais Nutrientes: ', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                                   pw.TextSpan(text: dailyKcal, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
                                ])),
                            ],
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text(
                            'COMPOSIÇÃO E DETALHAMENTO (5 PILARES):',
                            style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            meal['descricao']?.toString() ?? '',
                            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.black),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  if (meals.isEmpty)
                    pw.Padding(padding: const pw.EdgeInsets.all(10), child: pw.Text('Nenhuma refeição planejada.', style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 8))),
                ],
              ),
            );
          }).toList(),

          if (guidelines != null) ...[
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('ORIENTAÇÕES GERAIS:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.blue900)),
                  pw.SizedBox(height: 5),
                  pw.Text(guidelines, style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ),
          ],
        ],
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
  }) async {
    final pdf = pw.Document();
    final String timestampStr = DateFormat('dd/MM/yyyy HH:mm', strings.localeName).format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (context) => _buildHeader(strings.pdfMenuPlanTitle, timestampStr),
        footer: (context) => _buildFooter(context, strings: strings),
        build: (context) => [
          // Header Info Card
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.green50,
              border: pw.Border.all(color: PdfColors.green800, width: 0.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(strings.pdfPersonalizedPlanTitle, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.Text('${strings.pdfGoalLabel}: $goal', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.green700)),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Text(strings.pdfGeneratedByLine, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Detailed Plan
          ...days.map((day) {
            final String diaStr = DateFormat('EEEE, dd/MM', strings.localeName).format(day.date).toUpperCase();
            
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 20),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.green800, width: 1.0),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    color: PdfColors.green800,
                    child: pw.Text(
                      diaStr,
                      style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 11),
                    ),
                  ),
                  
                  ...day.meals.map((meal) {
                    return pw.Container(
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.green800, width: 0.5)),
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
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.green900),
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
                                pw.Container(width: 3, height: 3, decoration: const pw.BoxDecoration(color: PdfColors.green700, shape: pw.BoxShape.circle)),
                                pw.SizedBox(width: 6),
                                pw.Expanded(child: pw.Text(item.nome, style: const pw.TextStyle(fontSize: 9))),
                                pw.Text(item.quantidadeTexto, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                              ],
                            ),
                          )).toList(),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          }).toList(),

          if (batchCookingTips != null && batchCookingTips.isNotEmpty) ...[
            pw.NewPage(),
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.orange50,
                border: pw.Border.all(color: PdfColors.orange800, width: 0.5),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Text(strings.pdfBatchCookingTips, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.orange900)),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(batchCookingTips, style: const pw.TextStyle(fontSize: 10, height: 1.4)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
    return pdf;
  }

  String _getMealLabel(String tipo, AppLocalizations strings) {
    switch (tipo) {
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
      foodImage = await _safeLoadImage(imageFile.path);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (context) => _buildHeader(strings.pdfFoodTitle, timestampStr, dateLabel: strings.pdfDate),
        footer: (context) => _buildFooter(context, strings: strings),
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
                        _buildIndicator('${strings.pdfCalories}:', '${analysis.macros.calorias100g} kcal/100g', PdfColors.red700),
                        pw.SizedBox(width: 10),
                         _buildIndicator('${strings.pdfTrafficLight}:', analysis.identidade.semaforoSaude, 
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
          _buildSectionHeader(strings.pdfExSummary),
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
          _buildSectionHeader(strings.pdfDetailedNutrition),
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
          _buildSectionHeader(strings.pdfBiohacking),
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
          _buildSectionHeader(strings.pdfGastronomy),
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
              pw.Expanded(child: _buildIndicator('Preservação', analysis.gastronomia.preservacaoNutrientes, PdfColors.black)),
              pw.SizedBox(width: 10),
              pw.Expanded(child: _buildIndicator('Smart Swap', analysis.gastronomia.smartSwap, PdfColors.black)),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.amber, width: 1), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
            child: pw.Column(
               crossAxisAlignment: pw.CrossAxisAlignment.start,
               children: [
                 pw.Row(children: [pw.Icon(const pw.IconData(0xe80e), color: PdfColors.amber, size: 12), pw.SizedBox(width: 5), pw.Text('Dica do Especialista', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.amber800))]),
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
      plantImage = await _safeLoadImage(imageFile.path);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (context) => _buildHeader(strings.botanyDossierTitle(analysis.plantName), timestampStr),
        footer: (context) => _buildFooter(context, strings: strings),
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
                        _buildIndicator(strings.tabHealth + ':', analysis.saude.condicao, analysis.isHealthy ? PdfColors.green700 : PdfColors.red700),
                        pw.SizedBox(width: 10),
                         _buildIndicator(strings.plantFamily + ':', analysis.identificacao.familia, PdfColors.black),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          pw.SizedBox(height: 20),

          // 1. IDENTIFICAÇÃO E TAXONOMIA
          _buildSectionHeader('1. ${strings.plantIdentificationTaxonomy}'),
          pw.Text('${strings.plantPopularNames}: ${analysis.identificacao.nomesPopulares.join(', ')}'),
          pw.Text('${strings.plantScientificName}: ${analysis.identificacao.nomeCientifico}'),
          pw.Text('${strings.plantFamily}: ${analysis.identificacao.familia}'),
          pw.Text('${strings.plantOrigin}: ${analysis.identificacao.origemGeografica}'),
          pw.SizedBox(height: 10),

          // 2. DIAGNÓSTICO DE SAÚDE
          _buildSectionHeader('2. ${strings.plantClinicalDiagnosis}'),
          pw.Text('${strings.plantClinicalDiagnosis}: ${analysis.saude.condicao}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text('${strings.plantDetails}: ${analysis.saude.detalhes}'),
          pw.Text('${strings.plantRecoveryPlan}: ${analysis.saude.planoRecuperacao}'),
          if (!analysis.isHealthy)
             pw.Text('${strings.plantUrgency}: ${analysis.saude.urgencia}', style: pw.TextStyle(color: PdfColors.red700, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),

          // 3. GUIA DE SOBREVIVÊNCIA (HARDWARE)
          _buildSectionHeader('3. ${strings.tabHardware} (${strings.labelTrafficLight})'),
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
          _buildSectionHeader('4. ${strings.tabBios} (${strings.plantHomeSafety})'),
          pw.Row(children: [
            pw.Expanded(child: pw.Text('${strings.plantDangerPets}: ${(analysis.segurancaBiofilia.segurancaDomestica['is_toxic_to_pets'] == true || analysis.segurancaBiofilia.segurancaDomestica['toxica_para_pets'] == true) ? "YES ⚠️" : "NO ✅"}')),
            pw.Expanded(child: pw.Text('${strings.plantDangerKids}: ${(analysis.segurancaBiofilia.segurancaDomestica['is_toxic_to_children'] == true || analysis.segurancaBiofilia.segurancaDomestica['toxica_para_criancas'] == true) ? "YES ⚠️" : "NO ✅"}')),
          ]),
          pw.Text('${strings.plantToxicityDetails}: ${analysis.segurancaBiofilia.segurancaDomestica['toxicity_details'] ?? analysis.segurancaBiofilia.segurancaDomestica['sintomas_ingestao'] ?? strings.plantNoAlerts}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.red700)),
          pw.SizedBox(height: 10),
          pw.Text(strings.plantBioPower, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.Text('${strings.plantAirScore}: ${analysis.segurancaBiofilia.poderesBiofilicos['air_purification_score'] ?? analysis.segurancaBiofilia.poderesBiofilicos['purificacao_ar_score'] ?? 5}/10'),
          pw.Text('${strings.plantWellness}: ${analysis.segurancaBiofilia.poderesBiofilicos['wellness_impact'] ?? analysis.segurancaBiofilia.poderesBiofilicos['impacto_bem_estar'] ?? strings.noInformation}'),

          // 5. ENGENHARIA DE PROPAGAÇÃO
          _buildSectionHeader('5. ${strings.plantPropagationEngine}'),
          pw.Text('${strings.plantMethod}: ${analysis.propagacao.metodo}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text('${strings.plantDifficulty}: ${analysis.propagacao.dificuldade}'),
          pw.Text('${strings.plantStepByStep}: ${analysis.propagacao.passoAPasso}'),

          // 6. INTELIGÊNCIA DE ECOSSISTEMA
          _buildSectionHeader('6. ${strings.plantEcoIntel}'),
          pw.Text('${strings.plantCompanions}: ${analysis.ecossistema.plantasParceiras.join(", ")}'),
          pw.Text('${strings.plantAvoid}: ${analysis.ecossistema.plantasConflitantes.join(", ")}'),
          pw.Text('${strings.plantRepellent}: ${analysis.ecossistema.repelenteNatural}'),

          // 7. ESTÉTICA E LIFESTYLE (FENG SHUI)
          _buildSectionHeader('7. ${strings.tabLifestyle}'),
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

  /// 5. COMPREHENSIVE PET PROFILE REPORT - COMPLETE VETERINARY DOSSIER
   Future<pw.Document> generatePetProfileReport({
     required PetProfileExtended profile,
     required AppLocalizations strings,
     Map<String, bool>? selectedSections,
   }) async {
    final pdf = pw.Document();
    final String timestampStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    
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
                    final memImg = await _safeLoadImage(file.path);
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
    pw.ImageProvider? profileImage = await _safeLoadImage(profile.imagePath);
    
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
             ..sort((a, b) => DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
        
        for (var w in sortedWounds) {
            final img = await _safeLoadImage(w['imagePath']?.toString());
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
                      border: pw.Border.all(color: PdfColors.blue900, width: 4),
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
                      color: PdfColors.grey100,
                      border: pw.Border.all(color: PdfColors.blue900, width: 4),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(100)),
                    ),
                    child: pw.Center(
                      child: pw.Icon(
                        pw.IconData(0xe91f), 
                        color: PdfColors.blue900, 
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
                    color: PdfColors.blue900,
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
                    border: pw.Border.all(color: PdfColors.blue900, width: 2),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        profile.raca ?? 'Raça não especificada',
                        style: pw.TextStyle(
                          fontSize: 18,
                          color: PdfColors.blue900,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Gerado em: $timestampStr',
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
                  'ScanNut - Nutrição Inteligente para Pets',
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

    // ========== CONTENT PAGES ==========
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (context) => _buildHeader('Dossiê Digital: ${profile.petName}', timestampStr),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // ========== IDENTITY SECTION ==========
          if (sections['identity'] == true) ...[
            _buildSectionHeader(strings.pdfIdentitySection),
            
            pw.Table.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey700, width: 0.5),
              headerStyle: pw.TextStyle(color: PdfColors.black, fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellPadding: const pw.EdgeInsets.all(6),
              headers: ['Campo', 'Informação'],
              data: [
                ['Nome Completo', profile.petName],
                ['Raça', profile.raca ?? 'Não informado'],
                ['Idade Exata', profile.idadeExata ?? 'Não informado'],
                ['Sexo', profile.rawAnalysis?['identificacao']?['sexo'] ?? profile.statusReprodutivo ?? 'Não informado'],
                ['Microchip', profile.rawAnalysis?['identificacao']?['microchip'] ?? 'Não informado'],
                ['Peso Atual', profile.pesoAtual != null ? '${profile.pesoAtual} kg' : 'Não informado'],
                ['Peso Ideal', profile.pesoIdeal != null ? '${profile.pesoIdeal} kg' : 'Não informado'],
                ['Status Reprodutivo', profile.statusReprodutivo ?? 'Não informado'],
                ['Nível de Atividade', profile.nivelAtividade ?? 'Moderado'],
                ['Frequência de Banho', profile.frequenciaBanho ?? 'Não informado'],
              ],
            ),
            
            // Preferências Alimentares
            if (profile.preferencias.isNotEmpty) ...[
              pw.SizedBox(height: 15),
              pw.Text('Preferências Alimentares:', 
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
              pw.SizedBox(height: 5),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green50,
                  border: pw.Border.all(color: PdfColors.green200),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  profile.preferencias.join(', '),
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
            ],
            
            // Análise da Raça e Perfil (Dados Estendidos)
            if (profile.rawAnalysis != null) ...[
                 pw.SizedBox(height: 10),
                 ...profile.rawAnalysis!.entries.where((e) {
                      final key = e.key.toLowerCase();
                      final val = e.value;
                      if (['identificacao', 'plano_semanal', 'analise_nutricional', 'data_inicio_semana'].contains(key)) return false;
                      if (val is String && val.length > 5) return true;
                      if (val is Map) return true; 
                      return false;
                 }).expand((e) {
                      if (e.value is Map) {
                          return (e.value as Map).entries.map((sub) => pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                  pw.Text('${e.key.replaceAll('_', ' ').toUpperCase()} - ${sub.key.replaceAll('_', ' ').toUpperCase()}:', 
                                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                                  pw.Text(sub.value.toString(), style: const pw.TextStyle(fontSize: 9)),
                                  pw.SizedBox(height: 4),
                              ]
                          ));
                      } else {
                          return [
                              pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  children: [
                                      pw.Text('${e.key.replaceAll('_', ' ').toUpperCase()}:', 
                                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                                      pw.Text(e.value.toString(), style: const pw.TextStyle(fontSize: 9)),
                                      pw.SizedBox(height: 4),
                                  ]
                              )
                          ];
                      }
                 }).toList(),
                 pw.SizedBox(height: 10),
            ],

            _buildObservationsBlock(profile.observacoesIdentidade),
            pw.SizedBox(height: 20),
          ],
          
          // ========== HEALTH SECTION ==========
          if (sections['health'] == true) ...[
            _buildSectionHeader(strings.pdfHealthSection),
            
            // Controle de Peso
            pw.Text('Controle de Peso:', 
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
            pw.SizedBox(height: 5),
            pw.Table.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey700, width: 0.5),
              headerStyle: pw.TextStyle(color: PdfColors.black, fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellPadding: const pw.EdgeInsets.all(6),
              headers: ['Métrica', 'Valor', 'Status'],
              data: [
                [
                  'Peso Atual',
                  profile.pesoAtual != null ? '${profile.pesoAtual} kg' : 'Não informado',
                  profile.pesoAtual != null && profile.pesoIdeal != null
                    ? (profile.pesoAtual! > profile.pesoIdeal! ? 'Acima do ideal' : 
                       profile.pesoAtual! < profile.pesoIdeal! ? 'Abaixo do ideal' : 'Ideal')
                    : 'N/A'
                ],
                [
                  'Peso Ideal',
                  profile.pesoIdeal != null ? '${profile.pesoIdeal} kg' : 'Não informado',
                  'Meta'
                ],
              ],
            ),
            
            // Histórico de Peso
            if (profile.weightHistory.isNotEmpty) ...[
              pw.SizedBox(height: 10),
              pw.Text('Histórico de Pesagens:', 
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              pw.Table.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellPadding: const pw.EdgeInsets.all(4),
                headers: ['Data', 'Peso (kg)', 'Status'],
                data: profile.weightHistory.take(10).map((entry) => [
                  DateFormat('dd/MM/yyyy').format(DateTime.parse(entry['date'])),
                  '${entry['weight']} kg',
                  entry['status_label'] ?? 'Normal',
                ]).toList(),
              ),
            ],
            
            pw.SizedBox(height: 15),
            
            // Vacinas
            pw.Text('Histórico de Vacinas:', 
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700)),
            pw.SizedBox(height: 5),
            pw.Table.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.blue800, width: 0.8),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellPadding: const pw.EdgeInsets.all(6),
              headers: ['Vacina', 'Última Aplicação', 'Próxima Dose'],
              data: [
                [
                  'V10/V8 (Polivalente)',
                  profile.dataUltimaV10 != null 
                    ? DateFormat('dd/MM/yyyy').format(profile.dataUltimaV10!)
                    : 'Não registrado',
                  profile.dataUltimaV10 != null
                    ? DateFormat('dd/MM/yyyy').format(profile.dataUltimaV10!.add(const Duration(days: 365)))
                    : 'N/A',
                ],
                [
                  'Antirrábica',
                  profile.dataUltimaAntirrabica != null
                    ? DateFormat('dd/MM/yyyy').format(profile.dataUltimaAntirrabica!)
                    : 'Não registrado',
                  profile.dataUltimaAntirrabica != null
                    ? DateFormat('dd/MM/yyyy').format(profile.dataUltimaAntirrabica!.add(const Duration(days: 365)))
                    : 'N/A',
                ],
              ],
            ),
            
            pw.SizedBox(height: 15),
            
            // Alergias e Restrições
            pw.Text('Alergias e Restrições Alimentares:', 
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
            pw.SizedBox(height: 5),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: profile.alergiasConhecidas.isEmpty ? PdfColors.green50 : PdfColors.red50,
                border: pw.Border.all(
                  color: profile.alergiasConhecidas.isEmpty ? PdfColors.green200 : PdfColors.red200,
                  width: 1.5,
                ),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text(
                profile.alergiasConhecidas.isEmpty 
                  ? '✓ Nenhuma alergia conhecida registrada'
                  : '⚠️ ATENÇÃO: ${profile.alergiasConhecidas.join(', ')}',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: profile.alergiasConhecidas.isEmpty ? PdfColors.green900 : PdfColors.red900,
                ),
              ),
            ),
            
            // Exames Laboratoriais
            // --- Histórico Clínico ---
            if (medicalEvents.isNotEmpty) ...[
                pw.SizedBox(height: 15),
                pw.Text('Histórico Clínico (Vacinas, Medicamentos, Procedimentos):', 
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                pw.SizedBox(height: 5),
                pw.Table.fromTextArray(
                    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                    headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.black),
                    cellStyle: const pw.TextStyle(fontSize: 9),
                    cellPadding: const pw.EdgeInsets.all(4),
                    headers: ['Data', 'Tipo', 'Descrição', 'Status'],
                    data: medicalEvents.map((e) => [
                        DateFormat('dd/MM/yy').format(e.dateTime),
                        e.typeLabel,
                        e.title,
                        e.completed ? 'Realizado' : 'Pendente'
                    ]).toList(),
                ),
                pw.SizedBox(height: 15),
            ],

            if (profile.labExams.isNotEmpty) ...[
              pw.SizedBox(height: 15),
              pw.Text('Exames Laboratoriais:', 
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700)),
              pw.SizedBox(height: 5),
              ...profile.labExams.map((examJson) {
                final exam = LabExam.fromJson(examJson);
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    border: pw.Border.all(color: PdfColors.blue200),
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
                            DateFormat('dd/MM/yyyy').format(exam.uploadDate),
                            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                          ),
                        ],
                      ),
                      if (exam.extractedText != null && exam.extractedText!.isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Texto extraído: ${exam.extractedText!.substring(0, exam.extractedText!.length > 200 ? 200 : exam.extractedText!.length)}${exam.extractedText!.length > 200 ? '...' : ''}',
                          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey800),
                        ),
                      ],
                      if (exam.aiExplanation != null && exam.aiExplanation!.isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(4),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.green50,
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                          ),
                          child: pw.Text(
                            'Análise IA: ${exam.aiExplanation}',
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
              pw.Text('Histórico de Análises de Feridas:', 
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
              pw.SizedBox(height: 5),
              ...woundsWithImages.map((analysis) {
                final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(analysis['date']));
                final severity = analysis['severity'] ?? 'N/A';
                final diagnosis = analysis['diagnosis'] ?? 'Sem diagnóstico';
                final recommendations = (analysis['recommendations'] as List?)?.cast<String>() ?? [];
                
                final pdfImage = analysis['pdfImage'] as pw.ImageProvider?;
                
                PdfColor severityColor = PdfColors.green700;
                if (severity == 'Alta') severityColor = PdfColors.red700;
                else if (severity == 'Média') severityColor = PdfColors.orange700;

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.red50,
                    border: pw.Border.all(color: PdfColors.red200),
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
                                          color: severityColor,
                                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                                        ),
                                        child: pw.Text(
                                          severity.toUpperCase(),
                                          style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  pw.SizedBox(height: 4),
                                  pw.Text('Diagnóstico: $diagnosis', style: const pw.TextStyle(fontSize: 9)),
                                  if (recommendations.isNotEmpty) ...[
                                    pw.SizedBox(height: 4),
                                    pw.Text('Recomendações:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
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
            
            _buildObservationsBlock(profile.observacoesSaude),
            pw.SizedBox(height: 20),
          ],
          
          // ========== NUTRITION SECTION ==========
          if (sections['nutrition'] == true) ...[
             _buildSectionHeader(strings.pdfNutritionSection),
            
            // Meta Nutricional
            if (profile.rawAnalysis != null) ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  // Eco-mode
                  border: pw.Border.all(color: PdfColors.grey700),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Tipo de Dieta:',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      profile.rawAnalysis!['tipo_dieta']?.toString() ?? 'Não especificado',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
            ],
            
            // Plano Semanal Completo
            if (profile.rawAnalysis != null && profile.rawAnalysis!['plano_semanal'] != null) ...[
              pw.Text('Cardápio Semanal Detalhado:', 
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700)),
              pw.SizedBox(height: 8),
              
              ...(profile.rawAnalysis!['plano_semanal'] as List).asMap().entries.map((entry) {
                  final index = entry.key;
                  final dayData = entry.value as Map;
                  
                  final dateForDay = startData.add(Duration(days: index));
                  final dateStr = DateFormat('dd/MM').format(dateForDay);
                  final weekDayName = DateFormat('EEEE', 'pt_BR').format(dateForDay);
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

                  return pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 12),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.blue800, width: 1),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                              // Cabeçalho do Dia
                              pw.Container(
                                  padding: const pw.EdgeInsets.all(8),
                                  decoration: const pw.BoxDecoration(
                                      border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 0.5)),
                                  ),
                                  width: double.infinity,
                                  child: pw.Text(
                                    diaLabel.toUpperCase(),
                                    style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 10,
                                      color: PdfColors.black,
                                    ),
                                  ),
                              ),
                              // Refeições do Dia
                              ...refeicoes.asMap().entries.map((mealEntry) {
                                final meal = mealEntry.value;
                                final isLast = mealEntry.key == refeicoes.length - 1;
                                
                                return pw.Container(
                                  padding: const pw.EdgeInsets.all(8),
                                  decoration: pw.BoxDecoration(
                                    border: isLast ? null : const pw.Border(
                                      bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                                    ),
                                  ),
                                  child: pw.Column(
                                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                                    children: [
                                      // Hora e Kcal
                                      pw.Row(
                                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                        children: [
                                          pw.Text(
                                            '${meal['hora'] ?? 'REFEIÇÃO'}${meal['titulo'] != null ? ' - ${meal['titulo']}' : ''}',
                                            style: pw.TextStyle(
                                              fontWeight: pw.FontWeight.bold,
                                              fontSize: 9,
                                              color: PdfColors.blue900,
                                            ),
                                          ),
                                          if (meal['kcal'] != null)
                                            pw.Container(
                                              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: pw.BoxDecoration(
                                                border: pw.Border.all(color: PdfColors.black, width: 0.5),
                                                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                                              ),
                                              child: pw.Text(
                                                '${meal['kcal']} Kcal',
                                                style: pw.TextStyle(
                                                  fontSize: 8,
                                                  fontWeight: pw.FontWeight.bold,
                                                  color: PdfColors.black,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      pw.SizedBox(height: 4),
                                      // Descrição Completa
                                      pw.Text(
                                        meal['descricao']?.toString() ?? 'Sem descrição',
                                        style: const pw.TextStyle(fontSize: 8),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                          ]
                      )
                  );
              }).toList(),
            ] else ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  'Nenhum plano alimentar cadastrado.',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
              ),
            ],
            
            _buildObservationsBlock(profile.observacoesNutricao),
            pw.SizedBox(height: 20),
          ],
          
          // ========== GALLERY SECTION ==========
          if (sections['gallery'] == true) ...[
             _buildSectionHeader(strings.pdfGallerySection),

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
                                        color: PdfColors.grey200,
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
                    'Nenhuma imagem encontrada na galeria.',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                  ),
                ),
            ],
            
            if (otherDocNames.isNotEmpty) ...[
                pw.SizedBox(height: 15),
                pw.Text('Documentos Anexados (PDFs/Arquivos):', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.blue900)),
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

            _buildObservationsBlock(profile.observacoesGaleria),
            pw.SizedBox(height: 20),
          ],
          
          // ========== PARC (PARTNERS/BEHAVIOR) SECTION ==========
          if (sections['parc'] == true) ...[
             _buildSectionHeader(strings.pdfParcSection),
            
            // Parceiros Vinculados
            if (profile.linkedPartnerIds.isNotEmpty) ...[
              pw.Text('Parceiros Vinculados:', 
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700)),
              pw.SizedBox(height: 8),
              
              // Display pre-loaded partner data
              if (linkedPartnersData.isNotEmpty) ...[
                ...linkedPartnersData.map((partnerData) {
                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 8),
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue50,
                      border: pw.Border.all(color: PdfColors.blue200),
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
                                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                              ),
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.blue700,
                                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                              ),
                              child: pw.Text(
                                partnerData['category'] ?? 'Parceiro',
                                style: const pw.TextStyle(fontSize: 7, color: PdfColors.white),
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
                    color: PdfColors.orange50,
                    border: pw.Border.all(color: PdfColors.orange200),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Text(
                    '⚠️ ${profile.linkedPartnerIds.length} parceiro(s) vinculado(s), mas não foi possível carregar os detalhes.',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
              ],
              
              // Notas dos Parceiros
              if (profile.partnerNotes.isNotEmpty) ...[
                pw.SizedBox(height: 12),
                pw.Text('Histórico de Atendimentos:', 
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
                              note['title'] ?? 'Atendimento',
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
                  'Nenhum parceiro vinculado a este perfil.',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
              ),
            ],
            
            _buildObservationsBlock(profile.observacoesPrac),
            pw.SizedBox(height: 20),
          ],
          
          // ========== AGENDA & EVENTS SECTION ==========
          if (allAgendaEvents.isNotEmpty) ...[
            _buildSectionHeader('📅 Agenda e Eventos'),
            
            pw.Text(
              'Histórico e Próximos Compromissos',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700),
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
                      color: PdfColors.green50,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    ),
                    child: pw.Text(
                      '🔔 Próximos Eventos (${upcomingEvents.length})',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.green900),
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  ...upcomingEvents.take(10).map((event) => _buildEventItem(event, isUpcoming: true)),
                  pw.SizedBox(height: 12),
                ],
                
                // Past Events
                if (pastEvents.isNotEmpty) ...[
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    ),
                    child: pw.Text(
                      '📋 Histórico Recente (${pastEvents.length > 15 ? '15 de ${pastEvents.length}' : pastEvents.length})',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  ...pastEvents.take(15).map((event) => _buildEventItem(event, isUpcoming: false)),
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
    required String reportType, // 'Resumo' ou 'Detalhamento'
  }) async {
    final pdf = pw.Document();
    final String timestampStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    
    // Contagem por tipo
    Map<String, int> counts = {};
    for (var p in partners) {
      counts[p.category] = (counts[p.category] ?? 0) + 1;
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
        header: (context) => _buildHeader('Relatório: Hub de Apoio', timestampStr),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // INDICADORES
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildIndicator('Total de Parceiros', partners.length.toString(), PdfColors.blue800),
              ...counts.entries.take(2).map((e) => _buildIndicator(e.key, e.value.toString(), PdfColors.black)).toList(),
            ],
          ),
          if (counts.length > 2) ...[
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.start,
              children: counts.entries.skip(2).take(3).map((e) => pw.Padding(
                padding: const pw.EdgeInsets.only(right: 10),
                child: _buildIndicator(e.key, e.value.toString(), PdfColors.black),
              )).toList(),
            ),
          ],
          
          pw.SizedBox(height: 25),
          
          // TABELA
          pw.Table.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headers: reportType == 'Resumo' 
              ? ['Nome do Parceiro', 'Tipo / Categoria', 'Telefone']
              : ['Nome', 'Tipo', 'Telefone', 'Endereço', 'E-mail', 'Observações'],
            data: sortedPartners.map((p) {
              if (reportType == 'Resumo') {
                return [p.name, p.category, p.phone];
              } else {
                return [
                  p.name,
                  p.category,
                  p.phone,
                  p.address,
                  p.email ?? '---',
                  p.specialties.join(', ') + (p.metadata.isNotEmpty ? '\nInfo: ${p.metadata}' : ''),
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
  pw.Widget _buildEventItem(PetEvent event, {required bool isUpcoming}) {
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
    
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(event.dateTime);
    
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: isUpcoming ? PdfColors.green50 : PdfColors.grey50,
        border: pw.Border.all(
          color: isUpcoming ? PdfColors.green200 : PdfColors.grey300,
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
                          color: color,
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
}
