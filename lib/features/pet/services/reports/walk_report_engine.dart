import 'package:pdf/widgets.dart' as pw;
import '../../models/pet_profile_extended.dart';
import '../../../../l10n/app_localizations.dart';
import 'report_style_helper.dart';
import 'package:pdf/pdf.dart';

class ScanWalkReportEngine {
  static Future<pw.Document> generate(
      PetProfileExtended profile, AppLocalizations l10n) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (context) => ReportStyleHelper.buildHeader(
          title: 'ScanWalk - Passeio Inteligente',
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
          final hasHistory =
              profile.walkHistory != null && profile.walkHistory!.isNotEmpty;

          return [
            ReportStyleHelper.buildSectionTitle(
                'Resumo Estratégico do Passeio (Waze Pet)',
                icon: const pw.IconData(0xe55b)),
            hasHistory
                ? _buildStrategicSummary(profile.walkHistory!.last)
                : ReportStyleHelper.buildCard(
                    child: pw.Center(
                        child: pw.Text(
                            "Nenhum histórico de passeio registrado.",
                            style: const pw.TextStyle(
                                color: ReportStyleHelper.grey)))),
            if (hasHistory) ...[_buildSocialWalkSection(profile.walkHistory!)],
            ReportStyleHelper.buildSectionTitle(
                'Dicas de Especialista (Baseado na Saúde)',
                icon: const pw.IconData(0xe83e)),
            ReportStyleHelper.buildCard(
              color: ReportStyleHelper.cardBg,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('DICA PARA ${profile.petName.toUpperCase()}:',
                      style: const pw.TextStyle(
                          color: ReportStyleHelper.accent, fontSize: 10)),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'Considerando o porte (${profile.porte ?? "não informado"}) e as pendências vacinais (Gripe/Leishmaniose), evite áreas com alta densidade de mosquitos ou contato com pets sem histórico vacinal conhecido.',
                    style: const pw.TextStyle(fontSize: 9.0),
                  ),
                ],
              ),
            ),
            ReportStyleHelper.buildSectionTitle(
                'Log de Ocorrências no Percurso',
                icon: const pw.IconData(0xe192)),
            hasHistory
                ? _buildOccurrenceLog(profile.walkHistory!.last)
                : ReportStyleHelper.buildCard(
                    child: pw.Text("Nenhum registro.")),
            pw.Spacer(),
            pw.Text(
                'Relatório gerado via telemetria ScanWalk GPS System. Monitoramento em tempo real.',
                style: const pw.TextStyle(
                    fontSize: 7.0, color: ReportStyleHelper.grey)),
          ];
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildStrategicSummary(Map<String, dynamic> lastSession) {
    final events = (lastSession['events'] as List).cast<Map<String, dynamic>>();
    final friends = events.where((e) => e['type'] == 'friend').length;
    final hazards = events.where((e) => e['type'] == 'hazard').length;
    final dist = (lastSession['distance_km'] as num).toDouble();

    return ReportStyleHelper.buildCard(
      child: pw.Column(
        children: [
          _buildMetricRow('Distância Percorrida (Última)',
              '${dist.toStringAsFixed(2)} km', ReportStyleHelper.primary),
          _buildMetricRow(
              'Amigos Encontrados', '$friends Pets', ReportStyleHelper.success),
          _buildMetricRow('Zonas de Risco Identificadas', '$hazards Áreas',
              ReportStyleHelper.danger),
        ],
      ),
    );
  }

  static pw.Widget _buildSocialWalkSection(List<Map<String, dynamic>> history) {
    final allEvents = history
        .expand((s) => (s['events'] as List).cast<Map<String, dynamic>>())
        .toList();
    final friendEvents =
        allEvents.where((e) => e['type'] == 'friend').take(4).toList();

    if (friendEvents.isEmpty) return pw.SizedBox();

    return pw.Column(children: [
      ReportStyleHelper.buildSectionTitle('Amigos da Vizinhança (Social Walk)',
          icon: const pw.IconData(0xe7fb)),
      ReportStyleHelper.buildCard(
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: friendEvents.map((e) {
            final desc = e['description']?.toString() ?? 'Amigo';
            final name = desc
                .replaceAll('Encontrou: ', '')
                .replaceAll('Manual: ', '')
                .split('(')
                .first
                .split('•')
                .first
                .trim();
            return _buildFriendCircle(name, 'Pet');
          }).toList(),
        ),
      )
    ]);
  }

  static pw.Widget _buildOccurrenceLog(Map<String, dynamic> lastSession) {
    final events = (lastSession['events'] as List).cast<Map<String, dynamic>>();

    if (events.isEmpty) {
      return ReportStyleHelper.buildCard(child: pw.Text("Sem ocorrências."));
    }

    return ReportStyleHelper.buildCard(
      child: pw.Column(
        children: events.take(10).map((e) {
          final date = DateTime.parse(e['timestamp']);
          final timeStr =
              '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
          final type = e['type'].toString().toUpperCase();
          final desc = e['description'] ?? type;
          PdfColor color = ReportStyleHelper.grey;
          if (type == 'HAZARD') color = ReportStyleHelper.danger;
          if (type == 'FRIEND') color = ReportStyleHelper.success;
          if (type == 'WATER') color = ReportStyleHelper.accent;

          return _buildLogItem(timeStr, desc, color);
        }).toList(),
      ),
    );
  }

  static pw.Widget _buildMetricRow(String label, String value, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: const pw.TextStyle(
                  fontSize: 10.0, color: ReportStyleHelper.grey)),
          pw.Text(value, style: pw.TextStyle(fontSize: 11.0, color: color)),
        ],
      ),
    );
  }

  static pw.Widget _buildFriendCircle(String name, String breed) {
    return pw.Column(
      children: [
        pw.Container(
          width: 35,
          height: 35,
          decoration: const pw.BoxDecoration(
              color: PdfColors.grey200, shape: pw.BoxShape.circle),
          child: pw.Center(
              child: pw.Icon(const pw.IconData(0xe84f),
                  size: 15, color: PdfColors.grey600)),
        ),
        pw.SizedBox(height: 4),
        pw.Text(name, style: const pw.TextStyle(fontSize: 8.0)),
        pw.Text(breed,
            style: const pw.TextStyle(
                fontSize: 6.0, color: ReportStyleHelper.grey)),
      ],
    );
  }

  static pw.Widget _buildLogItem(String time, String event, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Row(
        children: [
          pw.Text(time,
              style: const pw.TextStyle(
                  fontSize: 8.0, color: ReportStyleHelper.grey)),
          pw.SizedBox(width: 10),
          pw.Container(
              width: 6,
              height: 6,
              decoration:
                  pw.BoxDecoration(color: color, shape: pw.BoxShape.circle)),
          pw.SizedBox(width: 8),
          pw.Text(event, style: const pw.TextStyle(fontSize: 9.0)),
        ],
      ),
    );
  }
}
