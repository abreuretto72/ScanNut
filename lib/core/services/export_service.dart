import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../features/pet/models/pet_event.dart';
import '../../features/pet/models/pet_profile_extended.dart';
import '../../features/food/models/food_analysis_model.dart';
import '../../features/pet/models/lab_exam.dart';
import '../../core/models/partner_model.dart';
import 'dart:io';

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

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

  /// RIGOROUS HEADER: Consistent across all reports
  pw.Widget _buildHeader(String title, String timestamp) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: const pw.BoxDecoration(
              color: PdfColors.blue800,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  title.toUpperCase(),
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 16,
                    color: PdfColors.white,
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
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
              cellStyle: const pw.TextStyle(fontSize: 7.5), // Ligeiramente menor para caber todas as colunas
              headers: ['Data/Hora', 'Evento', 'Pet', 'Parceiro/Local', 'Observações', 'Status'],
              data: events.map((e) => [
                DateFormat('dd/MM HH:mm').format(e.dateTime),
                e.title,
                e.petName,
                e.attendant ?? ' - ',
                e.notes ?? ' - ',
                e.completed ? 'OK' : 'Pendente',
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

  /// 3. WEEKLY MENU REPORT (UNIFIED LAYOUT)
  Future<pw.Document> generateWeeklyMenuReport({
    required String petName, 
    required String raceName, 
    required List<Map<String, String>> plan, 
    String? guidelines
  }) async {
    final pdf = pw.Document();
    final String timestampStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (context) => _buildHeader('Plano Alimentar para $petName', timestampStr),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildIndicator('Pet:', petName, PdfColors.black),
              _buildIndicator('Raça:', raceName, PdfColors.blue700),
            ],
          ),
          pw.SizedBox(height: 25),
          pw.Table.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.black, width: 1.0),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue),
            headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headers: ['Dia', 'Refeição', 'Composição', 'Porção'],
            data: plan.map((p) => [
              p['dia'] ?? '',
              p['refeicao'] ?? '',
              p['composicao'] ?? '',
              p['porcao'] ?? '',
            ]).toList(),
          ),
          if (guidelines != null) ...[
            pw.SizedBox(height: 20),
            pw.Text('Orientações Nutricionais:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            pw.SizedBox(height: 5),
            pw.Text(guidelines, style: const pw.TextStyle(fontSize: 10)),
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

  /// 5. PET PROFILE REPORT (UNIFIED LAYOUT)
  Future<pw.Document> generatePetProfileReport({required PetProfileExtended profile}) async {
    final pdf = pw.Document();
    final String timestampStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (context) => _buildHeader('Prontuário Digital: ${profile.petName}', timestampStr),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildIndicator('Pet:', profile.petName, PdfColors.black),
              _buildIndicator('Raça:', profile.raca ?? 'N/A', PdfColors.green700),
              _buildIndicator('Status:', 'Ativo', PdfColors.blue700),
            ],
          ),
          pw.SizedBox(height: 25),
          pw.Table.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.black, width: 1.0),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue),
            headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headers: ['Informação', 'Detalhe'],
            data: [
              ['Idade Estimada', profile.idadeExata ?? 'Não informado'],
              ['Peso Atual', '${profile.pesoAtual ?? '---'} kg'],
              ['Status Reprodutivo', profile.statusReprodutivo ?? 'Não informado'],
              ['Nível de Atividade', profile.nivelAtividade ?? 'Moderado'],
            ],
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
