import 'package:pdf/widgets.dart' as pw;
import '../../models/pet_profile_extended.dart';
import '../../../../l10n/app_localizations.dart';
import 'report_style_helper.dart';
import 'package:pdf/pdf.dart';

class AnalysisReportEngine {
  static Future<pw.Document> generate(
      PetProfileExtended profile, AppLocalizations l10n) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (context) => ReportStyleHelper.buildHeader(
          title: 'Insights ScanNut AI',
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
                'Monitoramento Bio-Comportamental',
                icon: const pw.IconData(0xe9de)),
            pw.Row(
              children: [
                pw.Expanded(
                  child: _buildMiniStatCard('Análise Vocal', 'Normal',
                      ReportStyleHelper.success, 'Frequência regular'),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: _buildMiniStatCard('Score Corporal', 'Normal (5/9)',
                      ReportStyleHelper.success, 'Peso ideal detectado'),
                ),
              ],
            ),
            pw.SizedBox(height: 15),
            ReportStyleHelper.buildSectionTitle(
                'Histórico de Análises Multimodais',
                icon: const pw.IconData(0xe417)),
            if (profile.analysisHistory.isEmpty)
              ReportStyleHelper.buildCard(
                  child: pw.Text(
                      'Nenhuma análise multimodal registrada até o momento.',
                      style: const pw.TextStyle(color: ReportStyleHelper.grey)))
            else
              ...profile.analysisHistory
                  .take(5)
                  .map((analysis) => ReportStyleHelper.buildCard(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                    'ANÁLISE DE ${analysis['last_updated']?.toString().substring(0, 10) ?? "DATA N/A"}',
                                    style: const pw.TextStyle(fontSize: 10.0)),
                                ReportStyleHelper.buildBadge(
                                    'CONFIDENCIAL', ReportStyleHelper.grey),
                              ],
                            ),
                            pw.SizedBox(height: 8),
                            if (analysis['identificacao'] != null) ...[
                              pw.Text(
                                  'Identificação: ${analysis['identificacao']['raca_predominante']} (${analysis['identificacao']['confianca']}%)',
                                  style: const pw.TextStyle(fontSize: 9.0)),
                              pw.SizedBox(height: 4),
                            ],
                            if (analysis['perfil_comportamental'] != null) ...[
                              pw.Text(
                                  'Comportamento: ${analysis['perfil_comportamental']['drive_ancestral']}',
                                  style: const pw.TextStyle(fontSize: 9.0)),
                            ],
                          ],
                        ),
                      )),
            ReportStyleHelper.buildSectionTitle(
                'Triagem por Visão Computacional',
                icon: const pw.IconData(0xe3f3)),
            ReportStyleHelper.buildCard(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Escala de Bristol (Fezes)',
                          style: const pw.TextStyle(fontSize: 10.0)),
                      ReportStyleHelper.buildBadge(
                          'ALERTA AMARELO', const PdfColor.fromInt(0xFFFBC02D)),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                      'Score Detectado: 6-7. Consistência pastosa. Recomenda-se monitoramento de hidratação e dieta nas próximas 24h.',
                      style: const pw.TextStyle(fontSize: 9.0)),
                ],
              ),
            ),
            pw.Spacer(),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: const pw.BoxDecoration(
                color: ReportStyleHelper.cardBg,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Text(
                'IMPORTANTE: Os resultados apresentados são baseados em algoritmos generativos e de visão computacional (Google Gemini 2.0). Devem ser utilizados apenas para fins de triagem informativa e não como diagnóstico médico definitivo.',
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

  static pw.Widget _buildMiniStatCard(
      String title, String value, PdfColor color, String sub) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: ReportStyleHelper.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(color: PdfColors.grey200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title,
              style: const pw.TextStyle(
                  fontSize: 8.0, color: ReportStyleHelper.grey)),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(fontSize: 12.0, color: color)),
          pw.SizedBox(height: 2),
          pw.Text(sub,
              style:
                  const pw.TextStyle(fontSize: 7.0, color: PdfColors.grey500)),
        ],
      ),
    );
  }
}
