import 'package:pdf/widgets.dart' as pw;
import '../../models/pet_profile_extended.dart';
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';
import 'report_style_helper.dart';
import 'package:pdf/pdf.dart';

import '../../models/walk_models.dart';

class OccurrencesReportEngine {
  static Future<pw.Document> generateWalkReport({
    required PetProfileExtended profile,
    required WalkSession session,
    required AppLocalizations l10n,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (context) => ReportStyleHelper.buildHeader(
          title: '9º Relatório de Passeio',
          petName: profile.petName,
          breed: profile.raca ?? 'SRD',
          age: profile.idadeExata ?? 'Idade N/A',
          microchip: profile.microchip ?? '',
          imagePath: profile.imagePath,
          l10n: l10n,
        ),
        footer: (context) => ReportStyleHelper.buildFooter(
            context.pageNumber, context.pagesCount),
        build: (context) {
          final duration = session.endTime != null
              ? session.endTime!.difference(session.startTime)
              : Duration.zero;

          return [
            // 1. STATS BANNER
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color:
                    ReportStyleHelper.opacify(ReportStyleHelper.primary, 0.05),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildStat('Distância',
                      '${session.distanceKm.toStringAsFixed(2)} km'),
                  _buildStat('Duração',
                      '${duration.inMinutes}m ${duration.inSeconds % 60}s'),
                  _buildStat('Calorias', '${session.caloriesBurned} kcal'),
                ],
              ),
            ),
            pw.SizedBox(height: 25),

            ReportStyleHelper.buildSectionTitle('Eventos do Passeio (Timeline)',
                icon: const pw.IconData(0xe192)),
            pw.SizedBox(height: 15),

            // 2. TIMELINE ITEMS
            ...session.events.map((e) => _buildWalkTimelineItem(e, l10n)),

            pw.Spacer(),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: const pw.BoxDecoration(
                color: PdfColors.grey50,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
              ),
              child: pw.Text(
                'Nota Técnica: Este documento integra dados de telemetria GPS e análise multimodal (IA) para monitoramento do bem-estar animal 360°.',
                style: pw.TextStyle(
                    fontSize: 7.0,
                    color: PdfColors.grey600,
                    fontStyle: pw.FontStyle.italic),
              ),
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildStat(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 14.0,
                fontWeight: pw.FontWeight.bold,
                color: ReportStyleHelper.primary)),
        pw.Text(label,
            style: const pw.TextStyle(fontSize: 8.0, color: PdfColors.grey600)),
      ],
    );
  }

  static pw.Widget _buildWalkTimelineItem(
      WalkEvent event, AppLocalizations l10n) {
    PdfColor color = ReportStyleHelper.grey;
    pw.IconData icon = const pw.IconData(0xe84f); // pets

    switch (event.type) {
      case WalkEventType.pee:
        color = PdfColors.blue;
        icon = const pw.IconData(0xe798);
        break;
      case WalkEventType.poo:
        color = PdfColors.brown;
        icon = const pw.IconData(0xef4a);
        break;
      case WalkEventType.water:
        color = PdfColors.lightBlue;
        icon = const pw.IconData(0xe8b5);
        break;
      case WalkEventType.friend:
        color = PdfColors.purple;
        icon = const pw.IconData(0xe7fe);
        break;
      case WalkEventType.bark:
        color = PdfColors.green;
        icon = const pw.IconData(0xe029);
        break;
      case WalkEventType.hazard:
        color = PdfColors.orange;
        icon = const pw.IconData(0xe002);
        break;
      case WalkEventType.fight:
        color = PdfColors.red;
        icon = const pw.IconData(0xeb91);
        break;
      default:
        break;
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 15),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            children: [
              pw.Container(
                width: 24,
                height: 24,
                decoration:
                    pw.BoxDecoration(color: color, shape: pw.BoxShape.circle),
                child: pw.Center(
                    child: pw.Icon(icon, color: PdfColors.white, size: 10)),
              ),
              pw.Container(width: 0.5, height: 40, color: PdfColors.grey200),
            ],
          ),
          pw.SizedBox(width: 15),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(event.type.toString().split('.').last.toUpperCase(),
                        style: pw.TextStyle(
                            fontSize: 9.0,
                            fontWeight: pw.FontWeight.bold,
                            color: color)),
                    pw.Text(DateFormat('HH:mm').format(event.timestamp),
                        style: const pw.TextStyle(
                            fontSize: 8.0, color: PdfColors.grey400)),
                  ],
                ),
                pw.SizedBox(height: 4),
                if (event.description != null)
                  pw.Text(event.description!,
                      style: const pw.TextStyle(
                          fontSize: 9.0, color: PdfColors.grey700)),
                if (event.type == WalkEventType.poo &&
                    event.bristolScore != null) ...[
                  pw.SizedBox(height: 5),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: pw.BoxDecoration(
                      color:
                          (event.bristolScore! >= 3 && event.bristolScore! <= 5)
                              ? PdfColors.green50
                              : PdfColors.red50,
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Text(
                      'Score Bristol: ${event.bristolScore}',
                      style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: (event.bristolScore! >= 3 &&
                                  event.bristolScore! <= 5)
                              ? PdfColors.green
                              : PdfColors.red),
                    ),
                  ),
                ],
                if (event.photoPath != null) ...[
                  pw.SizedBox(height: 8),
                  pw.Text('[Fotografia em anexo digital]',
                      style: pw.TextStyle(
                          fontSize: 7,
                          color: PdfColors.grey400,
                          fontStyle: pw.FontStyle.italic)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Future<pw.Document> generate(
      PetProfileExtended profile, AppLocalizations l10n) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (context) => ReportStyleHelper.buildHeader(
          title: 'Dossiê de Ocorrências',
          petName: profile.petName,
          breed: profile.raca ?? 'SRD',
          age: profile.idadeExata ?? 'Idade N/A',
          microchip: profile.microchip ?? '',
          imagePath: profile.imagePath,
          l10n: l10n,
        ),
        footer: (context) => ReportStyleHelper.buildFooter(
            context.pageNumber, context.pagesCount),
        build: (context) {
          return [
            ReportStyleHelper.buildSectionTitle(
                'Linha do Tempo de Intercorrências',
                icon: const pw.IconData(0xe192)),
            _buildTimelineItem(
              '23/01/2026',
              'Indiscreção Alimentar / Fezes',
              'Sinais de fezes pastosas detectados. Aplicado protocolo de observação e hidratação oral.',
              ReportStyleHelper.danger,
              icon: const pw.IconData(0xe002),
            ),
            _buildTimelineItem(
              '22/01/2026',
              'Padrão de Latido Elevado (AI)',
              'Análise vocal detectou frequência sônica compatível com medo/ansiedade durante a manhã.',
              ReportStyleHelper.grey,
              icon: const pw.IconData(0xe029),
            ),
            _buildTimelineItem(
              '20/01/2026',
              'Vômito Esporádico',
              'Episódio isolado às 08:30 após ingestão de grama no jardim. Atitude normal após evento.',
              ReportStyleHelper.primary,
              icon: const pw.IconData(0xeb91),
            ),
            _buildTimelineItem(
              '15/01/2026',
              'Transição de Dieta',
              'Início do mix de ração natural com alimentação caseira. Sem intercorrências gastrointestinais.',
              ReportStyleHelper.success,
              icon: const pw.IconData(0xe556),
            ),
            if (profile.rawAnalysis != null &&
                profile.rawAnalysis!.containsKey('weight_analysis')) ...[
              ReportStyleHelper.buildSectionTitle(
                  'Nota Técnica IA sobre Evolução',
                  icon: const pw.IconData(0xe85e)),
              ReportStyleHelper.buildCard(
                child: pw.Text(
                  profile.rawAnalysis!['weight_analysis'].toString(),
                  style: const pw.TextStyle(
                      fontSize: 10.0, color: ReportStyleHelper.primary),
                ),
              ),
            ],
            pw.Spacer(),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color:
                    ReportStyleHelper.opacify(ReportStyleHelper.primary, 0.03),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              ),
              child: pw.Text(
                'Nota: Este relatório compila eventos registrados por telemetria e inserção manual. Em caso de repetição de episódios graves, procure assistência médica imediata.',
                style: const pw.TextStyle(
                    fontSize: 7.0, color: ReportStyleHelper.grey),
              ),
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildTimelineItem(
      String date, String title, String desc, PdfColor color,
      {pw.IconData? icon}) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            children: [
              pw.Container(
                width: 30,
                height: 30,
                decoration:
                    pw.BoxDecoration(color: color, shape: pw.BoxShape.circle),
                child: icon != null
                    ? pw.Center(
                        child: pw.Icon(icon, color: PdfColors.white, size: 14))
                    : null,
              ),
              pw.Container(width: 1, height: 40, color: PdfColors.grey200),
            ],
          ),
          pw.SizedBox(width: 15),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(title,
                        style: const pw.TextStyle(
                            fontSize: 11.0, color: ReportStyleHelper.primary)),
                    pw.Text(date,
                        style: const pw.TextStyle(
                            fontSize: 8.0, color: ReportStyleHelper.grey)),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Text(desc,
                    style: const pw.TextStyle(
                        fontSize: 9.0, color: ReportStyleHelper.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
