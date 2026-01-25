import 'package:pdf/widgets.dart' as pw;
import '../../models/pet_profile_extended.dart';
import '../../../../l10n/app_localizations.dart';
import 'report_style_helper.dart';
import 'package:pdf/pdf.dart';

class TravelReportEngine {
  static Future<pw.Document> generate(
      PetProfileExtended profile, AppLocalizations l10n) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (context) => ReportStyleHelper.buildHeader(
          title: 'Passaporte ScanNut Travel',
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
          final hasMicrochip =
              profile.microchip != null && profile.microchip!.isNotEmpty;
          final isRabiesOk = profile.dataUltimaAntirrabica != null &&
              DateTime.now().difference(profile.dataUltimaAntirrabica!).inDays <
                  365;

          return [
            ReportStyleHelper.buildSectionTitle(
                'Dossiê de Prontidão (International Compliance)',
                icon: const pw.IconData(0xe539)),
            pw.Row(
              children: [
                pw.Expanded(
                    child: _buildReadyCard(
                        'Microchip ISO',
                        hasMicrochip ? 'ATIVO' : 'PENDENTE',
                        hasMicrochip
                            ? ReportStyleHelper.success
                            : ReportStyleHelper.danger)),
                pw.SizedBox(width: 10),
                pw.Expanded(
                    child: _buildReadyCard('IATA Compliant', 'VALIDADO',
                        ReportStyleHelper.success)),
                pw.SizedBox(width: 10),
                pw.Expanded(
                    child: _buildReadyCard(
                        'Vacina Raiva',
                        isRabiesOk ? 'EM DIA' : 'ATRASADA',
                        isRabiesOk
                            ? ReportStyleHelper.success
                            : ReportStyleHelper.danger)),
              ],
            ),
            pw.SizedBox(height: 15),
            ReportStyleHelper.buildSectionTitle(
                'Checklist Logístico (IATA Standards)',
                icon: const pw.IconData(0xe877)),
            ReportStyleHelper.buildCard(
              child: pw.Column(
                children: [
                  _buildCheckItem(
                      'Caixa de transporte ventilada (Padrão IATA)'),
                  _buildCheckItem('Absorvente de urina no fundo da caixa'),
                  _buildCheckItem('Identificação externa com foto e contatos'),
                  _buildCheckItem(
                      'Certificado Veterinário Internacional (CVI)'),
                  _buildCheckItem(
                      'Atestado de Saúde (emitido há no máx. 10 dias)'),
                ],
              ),
            ),
            ReportStyleHelper.buildSectionTitle(
                'Diretrizes Sanitárias e Legais',
                icon: const pw.IconData(0xeea1a)),
            ReportStyleHelper.buildCard(
              color: ReportStyleHelper.opacify(ReportStyleHelper.danger, 0.05),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('REGRA DOS 30 DIAS (RAIVA)',
                      style:
                          const pw.TextStyle(color: ReportStyleHelper.danger)),
                  pw.SizedBox(height: 6),
                  pw.Text(
                      'A vacina antirrábica deve ter sido aplicada há mais de 30 dias e menos de 1 ano do momento do embarque internacional.',
                      style: const pw.TextStyle(fontSize: 9.0)),
                  pw.SizedBox(height: 10),
                  pw.Text('SOROLOGIA DE ANTICORPOS',
                      style: const pw.TextStyle(
                          color: ReportStyleHelper.primary, fontSize: 10)),
                  pw.Text(
                      'Para destino na UE/Japão, a sorologia deve ser feita 90 dias antes do embarque.',
                      style: const pw.TextStyle(
                          fontSize: 8.0, color: ReportStyleHelper.grey)),
                ],
              ),
            ),
            if (profile.travelPreferences.isNotEmpty) ...[
              ReportStyleHelper.buildSectionTitle('Preferências de Logística',
                  icon: const pw.IconData(0xe530)),
              ReportStyleHelper.buildCard(
                child: pw.Text(
                  profile.travelPreferences.entries
                      .map((e) => '${e.key.toUpperCase()}: ${e.value}')
                      .join('\n'),
                  style: const pw.TextStyle(fontSize: 9.0),
                ),
              ),
            ],
            pw.Spacer(),
            pw.Text(
                'Relatório gerado para fins de planejamento logístico. O tutor deve confirmar as regras específicas da companhia aérea contratada.',
                style: const pw.TextStyle(
                    fontSize: 7.0, color: ReportStyleHelper.grey)),
          ];
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildReadyCard(
      String label, String status, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: ReportStyleHelper.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(color: PdfColors.grey200),
      ),
      child: pw.Column(
        children: [
          pw.Text(label,
              style: const pw.TextStyle(
                  fontSize: 8.0, color: ReportStyleHelper.grey)),
          pw.SizedBox(height: 5),
          ReportStyleHelper.buildBadge(status, color),
        ],
      ),
    );
  }

  static pw.Widget _buildCheckItem(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.Container(
              width: 8,
              height: 8,
              decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  color:
                      ReportStyleHelper.opacify(ReportStyleHelper.success, 0.2),
                  border: pw.Border.all(
                      color: ReportStyleHelper.success, width: 0.5))),
          pw.SizedBox(width: 8),
          pw.Text(text, style: const pw.TextStyle(fontSize: 9.0)),
        ],
      ),
    );
  }
}
