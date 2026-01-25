import 'package:pdf/widgets.dart' as pw;
import '../../models/pet_profile_extended.dart';
import '../../../../l10n/app_localizations.dart';
import 'report_style_helper.dart';
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';

class HealthReportEngine {
  static Future<pw.Document> generate(
      PetProfileExtended profile, AppLocalizations l10n) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (context) => ReportStyleHelper.buildHeader(
          title: 'Saúde & Bem-estar',
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
                'Protocolo Vacinal (Vigilância Sanitária)',
                icon: const pw.IconData(0xe3f3)),
            ReportStyleHelper.buildCard(
              child: pw.Table(
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                        border: pw.Border(
                            bottom: pw.BorderSide(color: PdfColors.grey200))),
                    children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 8),
                          child: pw.Text('IMUNIZANTE',
                              style: const pw.TextStyle(fontSize: 10.0))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 8),
                          child: pw.Text('DATA ÚLTIMA',
                              style: const pw.TextStyle(fontSize: 10.0))),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 8),
                        child: pw.Text(
                          'STATUS',
                          textAlign: pw.TextAlign.right, // ✔ aqui
                          style: const pw.TextStyle(fontSize: 10.0),
                        ),
                      ),
                    ],
                  ),
                  _buildVaccineRow(
                      'V8 / V10 (Polivalente)',
                      profile.dataUltimaV10 != null
                          ? dateFormat.format(profile.dataUltimaV10!)
                          : 'N/A',
                      profile.dataUltimaV10 != null),
                  _buildVaccineRow(
                      'Antirrábica (Raiva)',
                      profile.dataUltimaAntirrabica != null
                          ? dateFormat.format(profile.dataUltimaAntirrabica!)
                          : 'N/A',
                      profile.dataUltimaAntirrabica != null),
                  _buildVaccineRow('Gripe / Tosse dos Canis', '---', false),
                  _buildVaccineRow('Giárdia', '---', false),
                  _buildVaccineRow('Leishmaniose', '---', false),
                ],
              ),
            ),
            ReportStyleHelper.buildSectionTitle(
                'Exames Laboratoriais (Análise Técnica)',
                icon: const pw.IconData(0xe3f3)),
            if (profile.labExams.isEmpty)
              ReportStyleHelper.buildCard(
                  child: pw.Padding(
                      padding: const pw.EdgeInsets.all(10),
                      child: pw.Text(
                          'Nenhum exame cadastrado no dossiê científico.',
                          style: const pw.TextStyle(
                              color: ReportStyleHelper.grey))))
            else
              ...profile.labExams.map((exam) => ReportStyleHelper.buildCard(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                                exam['category']?.toString().toUpperCase() ??
                                    'EXAME',
                                style: const pw.TextStyle(
                                    color: ReportStyleHelper.accent)),
                            ReportStyleHelper.buildBadge(
                                'ANALISADO IA', ReportStyleHelper.success),
                          ],
                        ),
                        pw.SizedBox(height: 8),
                        if (exam['ai_explanation'] != null)
                          pw.Text(exam['ai_explanation'].toString(),
                              style: const pw.TextStyle(fontSize: 10.0)),
                        pw.SizedBox(height: 8),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                                'Data: ${exam['upload_date']?.toString().substring(0, 10) ?? 'N/A'}',
                                style: const pw.TextStyle(
                                    fontSize: 8.0,
                                    color: ReportStyleHelper.grey)),
                            pw.Text('Sistema ScanNut AI Vision Health',
                                style: const pw.TextStyle(
                                    fontSize: 8.0,
                                    color: ReportStyleHelper.grey)),
                          ],
                        ),
                      ],
                    ),
                  )),
            if (profile.observacoesSaude.isNotEmpty) ...[
              ReportStyleHelper.buildSectionTitle(
                  'Observações Clínicas (Tutor)',
                  icon: const pw.IconData(0xe3f3)),
              ReportStyleHelper.buildCard(
                child: pw.Text(profile.observacoesSaude,
                    style: const pw.TextStyle(fontSize: 10.0)),
              ),
            ],
          ];
        },
      ),
    );

    return pdf;
  }

  static pw.TableRow _buildVaccineRow(String name, String date, bool isOk) {
    return pw.TableRow(
      children: [
        pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 8),
            child: pw.Text(name, style: const pw.TextStyle(fontSize: 9.0))),
        pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 8),
            child: pw.Text(date, style: const pw.TextStyle(fontSize: 9.0))),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 8),
          child: pw.Container(
            alignment: pw.Alignment.centerRight,
            child: ReportStyleHelper.buildBadge(isOk ? 'EM DIA' : 'PENDENTE',
                isOk ? ReportStyleHelper.success : ReportStyleHelper.danger),
          ),
        ),
      ],
    );
  }
}
