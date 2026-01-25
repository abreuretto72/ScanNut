import 'package:pdf/widgets.dart' as pw;
import '../../models/pet_profile_extended.dart';
import '../../../../l10n/app_localizations.dart';
import 'report_style_helper.dart';
import 'package:pdf/pdf.dart';

class AgendaPartnersReportEngine {
  static Future<pw.Document> generate(
      PetProfileExtended profile, AppLocalizations l10n) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (context) => ReportStyleHelper.buildHeader(
          title: 'Agenda & Parceiros',
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
                'Hub de Apoio e Telemetria (Parceiros)',
                icon: const pw.IconData(0xe7fd)),
            ReportStyleHelper.buildCard(
              child: pw.Column(
                children: [
                  _buildPartnerEntry(
                    'CLÍNICA / VETERINÁRIO PRINCIPAL',
                    'Sagrado PET Healthcare',
                    '(12) 98765-5444',
                    'Rua das Flores, 123 - Centro, São José dos Campos/SP',
                    isActive: true,
                  ),
                  pw.Divider(color: PdfColors.grey100),
                  _buildPartnerEntry(
                    'EMERGÊNCIA 24H',
                    'Hospital Pet Care',
                    '(12) 3344-5566',
                    'Unidade Leste - Av. das Nações, 500',
                    isActive: false,
                  ),
                ],
              ),
            ),
            ReportStyleHelper.buildSectionTitle('Agenda Tática e Compromissos',
                icon: const pw.IconData(0xe916)),
            ReportStyleHelper.buildCard(
              child: pw.Column(
                children: [
                  _buildAgendaRow('30/01/2026', '14:30', 'Consulta Retorno',
                      'Sagrado PET', ReportStyleHelper.accent),
                  _buildAgendaRow(
                      '15/02/2026',
                      '09:00',
                      'Reforço de Imunizante',
                      'Clínica Municipal',
                      ReportStyleHelper.success),
                  _buildAgendaRow('25/02/2026', '11:00', 'Checkup de Rotina',
                      'Home Visit', ReportStyleHelper.primary),
                ],
              ),
            ),
            if (profile.partnerNotes.isNotEmpty) ...[
              ReportStyleHelper.buildSectionTitle(
                  'Instruções Particulares de Parceiros',
                  icon: const pw.IconData(0xe873)),
              ReportStyleHelper.buildCard(
                child: pw.Text(
                  'Instruções específicas de manuseio e preferências registradas pela rede de apoio vinculada ao ScanNut Hub.',
                  style: const pw.TextStyle(
                      fontSize: 9.0, color: ReportStyleHelper.grey),
                ),
              ),
            ],
            pw.Spacer(),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: const pw.BoxDecoration(
                  color: ReportStyleHelper.cardBg,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(8))),
              child: pw.Row(
                children: [
                  pw.Icon(const pw.IconData(0xe88e),
                      color: ReportStyleHelper.accent, size: 14),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: pw.Text(
                        'Este HUB garante a integração de dados entre o tutor e a clínica através do QR Code Inteligente ScanNut.',
                        style: const pw.TextStyle(
                            fontSize: 8.0, color: ReportStyleHelper.grey)),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildPartnerEntry(
      String cat, String name, String phone, String addr,
      {required bool isActive}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(cat,
                    style: const pw.TextStyle(
                        fontSize: 7.0, color: ReportStyleHelper.grey)),
                pw.SizedBox(height: 2),
                pw.Text(name,
                    style: const pw.TextStyle(
                        fontSize: 11.0, color: ReportStyleHelper.primary)),
                pw.SizedBox(height: 2),
                pw.Text(addr,
                    style: const pw.TextStyle(
                        fontSize: 8.0, color: ReportStyleHelper.grey)),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(phone,
                  style: const pw.TextStyle(
                      fontSize: 10.0, color: ReportStyleHelper.accent)),
              pw.SizedBox(height: 4),
              if (isActive)
                ReportStyleHelper.buildBadge(
                    'PRINCIPAL', ReportStyleHelper.success),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildAgendaRow(
      String date, String time, String title, String loc, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        children: [
          pw.Container(
            width: 45,
            padding: const pw.EdgeInsets.symmetric(vertical: 5),
            decoration: pw.BoxDecoration(
                color: ReportStyleHelper.opacify(color, 0.1),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6))),
            child: pw.Center(
                child: pw.Text(date.substring(0, 5),
                    style: pw.TextStyle(color: color, fontSize: 10.0))),
          ),
          pw.SizedBox(width: 15),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(title,
                    style: const pw.TextStyle(
                        fontSize: 10.0, color: ReportStyleHelper.primary)),
                pw.Text('$loc • $time',
                    style: const pw.TextStyle(
                        fontSize: 8.0, color: ReportStyleHelper.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
