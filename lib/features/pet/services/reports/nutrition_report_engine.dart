import 'package:pdf/widgets.dart' as pw;
import '../../models/pet_profile_extended.dart';
import '../../../../l10n/app_localizations.dart';
import 'report_style_helper.dart';
import 'package:pdf/pdf.dart';

class NutritionReportEngine {
  static Future<pw.Document> generate(
      PetProfileExtended profile, AppLocalizations l10n) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (context) => ReportStyleHelper.buildHeader(
          title: 'Nutrição & Dieta',
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
                'Plano Alimentar Semanal (AI Balanced)',
                icon: const pw.IconData(0xe556)),
            ReportStyleHelper.buildCard(
              color: ReportStyleHelper.cardBg,
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Meta Diária Estimada:',
                          style: const pw.TextStyle(fontSize: 10.0)),
                      pw.Text(
                          '${profile.pesoAtual != null ? (profile.pesoAtual! * 30).toStringAsFixed(0) : "---"} kcal',
                          style: const pw.TextStyle(
                              color: ReportStyleHelper.success,
                              fontSize: 14.0)),
                    ],
                  ),
                  pw.Divider(color: PdfColors.grey200),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Gramagem Recomendada:',
                          style: const pw.TextStyle(fontSize: 10.0)),
                      pw.Text('120g / refeição',
                          style: const pw.TextStyle(
                              color: ReportStyleHelper.primary,
                              fontSize: 12.0)),
                    ],
                  ),
                ],
              ),
            ),
            ReportStyleHelper.buildSectionTitle('Grade Nutricional Semanal',
                icon: const pw.IconData(0xe85d)),
            ReportStyleHelper.buildCard(
              child: pw.Table(
                border:
                    pw.TableBorder.all(color: PdfColors.grey100, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('DIA',
                              style: const pw.TextStyle(fontSize: 8.0))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('MANHÃ',
                              style: const pw.TextStyle(fontSize: 8.0))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('TARDE',
                              style: const pw.TextStyle(fontSize: 8.0))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('NOITE',
                              style: const pw.TextStyle(fontSize: 8.0))),
                    ],
                  ),
                  _buildDayRow(
                      'SEG', 'Natural + Mix', 'Snack Fruta', 'Natural + Ômega'),
                  _buildDayRow(
                      'TER', 'Natural + Mix', 'Snack Fruta', 'Natural + Ômega'),
                  _buildDayRow('QUA', 'Natural + Mix', 'Cenoura Baby',
                      'Natural + Ômega'),
                  _buildDayRow(
                      'QUI', 'Natural + Mix', 'Snack Fruta', 'Natural + Ômega'),
                  _buildDayRow(
                      'SEX', 'Natural + Mix', 'Ovo Cozido', 'Natural + Ômega'),
                  _buildDayRow('SÁB', 'Ração Premium', 'Iogurte Natural',
                      'Natural + Mix'),
                  _buildDayRow('DOM', 'Natural Especial', 'Passeio + Água',
                      'Natural Especial'),
                ],
              ),
            ),
            ReportStyleHelper.buildSectionTitle(
                'ZONA DE PERIGO: RESTRIÇÕES & ALERGIAS',
                icon: const pw.IconData(0xe002)),
            ReportStyleHelper.buildCard(
              color: ReportStyleHelper.opacify(ReportStyleHelper.danger, 0.05),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Icon(const pw.IconData(0xe002),
                          color: ReportStyleHelper.danger, size: 16),
                      pw.SizedBox(width: 8),
                      pw.Text('BLOQUEIO ABSOLUTO',
                          style: const pw.TextStyle(
                              color: ReportStyleHelper.danger)),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...profile.restricoes.map((r) =>
                          ReportStyleHelper.buildBadge(
                              r, ReportStyleHelper.danger)),
                      ...profile.alergiasConhecidas.map((a) =>
                          ReportStyleHelper.buildBadge(
                              'ALERGIA: $a', ReportStyleHelper.danger)),
                      if (profile.restricoes.isEmpty &&
                          profile.alergiasConhecidas.isEmpty)
                        ReportStyleHelper.buildBadge(
                            'Chocolate 72% / Uvas', ReportStyleHelper.danger),
                    ],
                  ),
                ],
              ),
            ),
            if (profile.observacoesNutricao.isNotEmpty) ...[
              ReportStyleHelper.buildSectionTitle('Observações Nutricionais',
                  icon: const pw.IconData(0xe873)),
              ReportStyleHelper.buildCard(
                child: pw.Text(profile.observacoesNutricao,
                    style: const pw.TextStyle(fontSize: 10.0)),
              ),
            ],
          ];
        },
      ),
    );

    return pdf;
  }

  static pw.TableRow _buildDayRow(String day, String m, String t, String n) {
    return pw.TableRow(
      children: [
        pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Text(day, style: const pw.TextStyle(fontSize: 8.0))),
        pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Text(m, style: const pw.TextStyle(fontSize: 7.0))),
        pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Text(t, style: const pw.TextStyle(fontSize: 7.0))),
        pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Text(n, style: const pw.TextStyle(fontSize: 7.0))),
      ],
    );
  }
}
