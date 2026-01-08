/// Feeding Events PDF Generator
/// Generates professional clinical PDF reports for feeding events
/// 
/// This service creates veterinary-grade PDF reports with:
/// - Chronological event timeline
/// - Clinical intercurrence highlighting
/// - Severity-based color coding
/// - Alert summaries
/// - Recommendations

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/pet_event_model.dart';
import '../models/feeding_event_types.dart';
import '../models/feeding_event_constants.dart';
import 'feeding_event_alert_system.dart';

class FeedingEventsPdfService {
  
  /// Generate comprehensive feeding events PDF report
  static Future<File> generateFeedingReport({
    required String petName,
    required String petBreed,
    required List<PetEventModel> feedingEvents,
    required DateTime startDate,
    required DateTime endDate,
    required String outputPath,
  }) async {
    final pdf = pw.Document();
    
    // Filter and sort events
    final events = feedingEvents.where((e) {
      return e.group == 'food' &&
             e.timestamp.isAfter(startDate.subtract(const Duration(days: 1))) &&
             e.timestamp.isBefore(endDate.add(const Duration(days: 1))) &&
             !e.isDeleted;
    }).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Most recent first

    // Analyze events for alerts
    final alerts = FeedingEventAlertSystem.analyzeEvents(events);
    final alertSummary = FeedingEventAlertSystem.getAlertSummary(alerts);

    // Build PDF pages
    pdf.addPage(_buildCoverPage(petName, petBreed, startDate, endDate));
    pdf.addPage(_buildAlertSummaryPage(alerts, alertSummary));
    
    for (final p in _buildEventTimelinePages(events)) {
      pdf.addPage(p);
    }
    
    pdf.addPage(_buildStatisticsPage(events));
    pdf.addPage(_buildRecommendationsPage(events, alerts));

    // Save PDF
    final file = File(outputPath);
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Build cover page
  static pw.Page _buildCoverPage(
    String petName,
    String petBreed,
    DateTime startDate,
    DateTime endDate,
  ) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return pw.Container(
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [PdfColors.pink300, PdfColors.pink700],
              begin: pw.Alignment.topLeft,
              end: pw.Alignment.bottomRight,
            ),
          ),
          child: pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Icon(
                  const pw.IconData(0xe57f), // restaurant icon
                  size: 80,
                  color: PdfColors.white,
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'RELATÓRIO CLÍNICO',
                  style: pw.TextStyle(
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.Text(
                  'Eventos de Alimentação',
                  style: pw.TextStyle(
                    fontSize: 24,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 40),
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        petName,
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.pink700,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        petBreed,
                        style: const pw.TextStyle(
                          fontSize: 16,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 20),
                      pw.Divider(color: PdfColors.grey300),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'Período: ${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
                        style: const pw.TextStyle(fontSize: 14),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Gerado em: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 40),
                pw.Text(
                  '🐾 ScanNut Pet Health System',
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build alert summary page
  static pw.Page _buildAlertSummaryPage(
    List<FeedingAlert> alerts,
    Map<AlertSeverity, int> summary,
  ) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('⚠️ RESUMO DE ALERTAS CLÍNICOS'),
            pw.SizedBox(height: 20),
            
            // Alert summary boxes
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: [
                _buildAlertBox('EMERGÊNCIA', summary[AlertSeverity.emergency] ?? 0, PdfColors.red),
                _buildAlertBox('URGENTE', summary[AlertSeverity.urgent] ?? 0, PdfColors.orange),
                _buildAlertBox('ATENÇÃO', summary[AlertSeverity.warning] ?? 0, PdfColors.yellow800),
              ],
            ),
            
            pw.SizedBox(height: 30),
            
            // Detailed alerts
            if (alerts.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green50,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.green300),
                ),
                child: pw.Row(
                  children: [
                    pw.Icon(const pw.IconData(0xe86c), color: PdfColors.green, size: 24),
                    pw.SizedBox(width: 12),
                    pw.Text(
                      'Nenhum alerta detectado. Padrão alimentar normal.',
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.green900,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...alerts.map((alert) => _buildAlertCard(alert)),
          ],
        );
      },
    );
  }

  /// Build alert summary box
  static pw.Widget _buildAlertBox(String label, int count, PdfColor color) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: color.shade(0.1),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color, width: 2),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            '$count',
            style: pw.TextStyle(
              fontSize: 36,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Build alert card
  static pw.Widget _buildAlertCard(FeedingAlert alert) {
    final color = _getPdfColorForSeverity(alert.severity);
    
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: color.shade(0.05),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color, width: 2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            alert.title,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(alert.message, style: const pw.TextStyle(fontSize: 11)),
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              '📋 ${alert.recommendation}',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build event timeline pages
  static List<pw.Page> _buildEventTimelinePages(List<PetEventModel> events) {
    final pages = <pw.Page>[];
    const eventsPerPage = 8;
    
    for (var i = 0; i < events.length; i += eventsPerPage) {
      final pageEvents = events.skip(i).take(eventsPerPage).toList();
      
      pages.add(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('📅 LINHA DO TEMPO - EVENTOS DE ALIMENTAÇÃO'),
                pw.SizedBox(height: 20),
                ...pageEvents.map((event) => _buildEventCard(event)),
              ],
            );
          },
        ),
      );
    }
    
    return pages;
  }

  /// Build event card
  static pw.Widget _buildEventCard(PetEventModel event) {
    final eventType = event.data['feeding_event_type'] as String?;
    final severity = event.data['severity'] as String?;
    final isClinical = event.data['is_clinical_intercurrence'] as bool? ?? false;
    final acceptance = event.data['acceptance'] as String?;
    final quantity = event.data['quantity'] as String?;
    
    final borderColor = isClinical 
        ? (severity != null ? FeedingEventHelper.getColorForSeverity(severity) : PdfColors.orange)
        : PdfColors.grey400;
    
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: isClinical ? PdfColors.red50 : PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(
          color: _convertFlutterColorToPdf(borderColor),
          width: isClinical ? 2 : 1,
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
                  eventType ?? 'Evento de Alimentação',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: isClinical ? PdfColors.red900 : PdfColors.grey900,
                  ),
                ),
              ),
              pw.Text(
                DateFormat('dd/MM/yyyy HH:mm').format(event.timestamp),
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            ],
          ),
          
          if (isClinical) ...[
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: pw.BoxDecoration(
                color: PdfColors.red,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                '⚠️ INTERCORRÊNCIA CLÍNICA',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.white,
                ),
              ),
            ),
          ],
          
          if (severity != null) ...[
            pw.SizedBox(height: 6),
            pw.Text(
              'Gravidade: $severity',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: _convertFlutterColorToPdf(FeedingEventHelper.getColorForSeverity(severity)),
              ),
            ),
          ],
          
          if (quantity != null || acceptance != null) ...[
            pw.SizedBox(height: 6),
            pw.Row(
              children: [
                if (quantity != null)
                  pw.Text('Quantidade: $quantity', style: const pw.TextStyle(fontSize: 10)),
                if (quantity != null && acceptance != null)
                  pw.SizedBox(width: 12),
                if (acceptance != null)
                  pw.Text('Aceitação: $acceptance', style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ],
          
          if (event.notes.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                event.notes,
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build statistics page
  static pw.Page _buildStatisticsPage(List<PetEventModel> events) {
    // Calculate statistics
    final totalEvents = events.length;
    final clinicalEvents = events.where((e) => e.data['is_clinical_intercurrence'] == true).length;
    final normalEvents = totalEvents - clinicalEvents;
    
    // Group by event type
    final eventTypeCounts = <String, int>{};
    for (final event in events) {
      final type = event.data['feeding_event_type'] as String? ?? 'unknown';
      eventTypeCounts[type] = (eventTypeCounts[type] ?? 0) + 1;
    }
    
    final topEvents = eventTypeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('📊 ESTATÍSTICAS DO PERÍODO'),
            pw.SizedBox(height: 20),
            
            // Summary boxes
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatBox('Total de Eventos', '$totalEvents', PdfColors.blue),
                _buildStatBox('Eventos Normais', '$normalEvents', PdfColors.green),
                _buildStatBox('Intercorrências', '$clinicalEvents', PdfColors.red),
              ],
            ),
            
            pw.SizedBox(height: 30),
            
            // Top events table
            pw.Text(
              'Eventos Mais Frequentes',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _buildTableCell('Tipo de Evento', isHeader: true),
                    _buildTableCell('Ocorrências', isHeader: true),
                    _buildTableCell('%', isHeader: true),
                  ],
                ),
                ...topEvents.take(10).map((entry) {
                  final percentage = ((entry.value / totalEvents) * 100).toStringAsFixed(1);
                  return pw.TableRow(
                    children: [
                      _buildTableCell(entry.key),
                      _buildTableCell('${entry.value}'),
                      _buildTableCell('$percentage%'),
                    ],
                  );
                }),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Build statistics box
  static pw.Widget _buildStatBox(String label, String value, PdfColor color) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: color.shade(0.1),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color, width: 2),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 32,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            label,
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  /// Build recommendations page
  static pw.Page _buildRecommendationsPage(
    List<PetEventModel> events,
    List<FeedingAlert> alerts,
  ) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('💡 RECOMENDAÇÕES CLÍNICAS'),
            pw.SizedBox(height: 20),
            
            if (alerts.any((a) => a.severity == AlertSeverity.emergency))
              _buildRecommendationBox(
                '🚨 AÇÃO IMEDIATA NECESSÁRIA',
                'Foram detectadas intercorrências clínicas GRAVES que requerem atendimento veterinário IMEDIATO.',
                PdfColors.red,
              ),
            
            if (alerts.any((a) => a.severity == AlertSeverity.urgent))
              _buildRecommendationBox(
                '⚠️ CONSULTA URGENTE',
                'Agendar consulta veterinária nas próximas 24-48h para avaliação dos eventos registrados.',
                PdfColors.orange,
              ),
            
            _buildRecommendationBox(
              '📋 MONITORAMENTO CONTÍNUO',
              'Continuar registrando todos os eventos de alimentação, especialmente:\n• Recusas alimentares\n• Vômitos ou diarreias\n• Mudanças no apetite\n• Reações adversas a alimentos',
              PdfColors.blue,
            ),
            
            _buildRecommendationBox(
              '🏥 ACOMPANHAMENTO VETERINÁRIO',
              'Levar este relatório nas consultas veterinárias para auxiliar no diagnóstico e tratamento.',
              PdfColors.green,
            ),
            
            pw.SizedBox(height: 30),
            
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text(
                '⚠️ AVISO IMPORTANTE: Este relatório é gerado automaticamente com base nos eventos registrados e NÃO substitui a avaliação de um médico veterinário. Sempre consulte um profissional qualificado para diagnóstico e tratamento.',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                textAlign: pw.TextAlign.justify,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Build recommendation box
  static pw.Widget _buildRecommendationBox(String title, String content, PdfColor color) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: color.shade(0.05),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color, width: 2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            content,
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  /// Build section header
  static pw.Widget _buildSectionHeader(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: const pw.BoxDecoration(
        color: PdfColors.pink700,
        borderRadius: pw.BorderRadius.only(
          topLeft: pw.Radius.circular(8),
          topRight: pw.Radius.circular(8),
        ),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 18,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  /// Build table cell
  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 11 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  /// Helper: Convert Flutter Color to PdfColor
  static PdfColor _convertFlutterColorToPdf(dynamic color) {
    if (color is PdfColor) return color;
    // Default fallback
    return PdfColors.grey;
  }

  /// Helper: Get PDF color for alert severity
  static PdfColor _getPdfColorForSeverity(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.emergency:
        return PdfColors.red;
      case AlertSeverity.urgent:
        return PdfColors.orange;
      case AlertSeverity.warning:
        return PdfColors.yellow800;
      case AlertSeverity.info:
        return PdfColors.blue;
    }
  }
}
