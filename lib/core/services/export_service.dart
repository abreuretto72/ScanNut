import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
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
      print('⚠️ [ExportService] Skipped corrupted/missing image: $path | Error: $e');
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
  pw.Widget _buildHeader(String title, String timestamp) {
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
                      'Data: $timestamp',
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
  pw.Widget _buildFooter(pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(thickness: 0.5, color: PdfColors.grey300),
        pw.SizedBox(height: 5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(appName, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
            pw.Text('Página ${context.pageNumber} de ${context.pagesCount}', 
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
                    final meal = Map<String, dynamic>.from(m);
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

  /// 4. FOOD ANALYSIS REPORT (UNIFIED LAYOUT)
  Future<pw.Document> generateFoodAnalysisReport({required FoodAnalysisModel analysis, File? imageFile}) async {
    final pdf = pw.Document();
    final String timestampStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (context) => _buildHeader('Análise Nutricional IA', timestampStr),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildIndicator('Item:', analysis.identidade.nome, PdfColors.black),
              _buildIndicator('Calorias:', '${analysis.macros.calorias} kcal', PdfColors.red700),
            ],
          ),
          pw.SizedBox(height: 25),
          pw.Table.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.black, width: 1.0),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue),
            headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headers: ['Nutriente', 'Valor', 'Observação'],
            data: [
              ['Proteínas', analysis.macros.proteinas['valor'] ?? '', 'Essencial'],
              ['Carboidratos', analysis.macros.carboidratos['total'] ?? '', 'Energia'],
              ['Fibras', analysis.macros.fibras['total'] ?? '', 'Digestão'],
              ['Gorduras', analysis.macros.gorduras['total'] ?? '', 'Saudável'],
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text('Veredito da IA:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.SizedBox(height: 5),
          pw.Text(analysis.analise.vereditoIa, style: const pw.TextStyle(fontSize: 10)),
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
    try {
        await PetEventService().init();
        final allEvents = PetEventService().getEventsByPet(profile.petName);
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
    } catch(e) { print('Error loading events: $e'); }

    // 2. Gallery Images & Docs
    final List<Map<String, dynamic>> galleryImages = [];
    final List<String> otherDocNames = []; 
    if (sections['gallery'] == true) {
        try {
            final allDocs = await FileUploadService().getMedicalDocuments(profile.petName);
            for (var file in allDocs) {
                final ext = path.extension(file.path).toLowerCase();
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
                    }
                } else {
                    otherDocNames.add(path.basename(file.path));
                }
            }
        } catch(e) { print('Error loading gallery: $e'); }
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
              pw.SizedBox(height: 5),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  border: pw.Border.all(color: PdfColors.blue200),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  '${profile.linkedPartnerIds.length} parceiro(s) cadastrado(s)',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
              
              // Notas dos Parceiros
              if (profile.partnerNotes.isNotEmpty) ...[
                pw.SizedBox(height: 10),
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
}
