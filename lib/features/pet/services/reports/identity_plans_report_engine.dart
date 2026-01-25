import 'package:pdf/widgets.dart' as pw;
import '../../models/pet_profile_extended.dart';
import '../../../../l10n/app_localizations.dart';
import 'report_style_helper.dart';
import 'package:pdf/pdf.dart';

class IdentityPlansReportEngine {
  static Future<pw.Document> generate(
      PetProfileExtended profile, AppLocalizations l10n) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (context) => ReportStyleHelper.buildHeader(
          title: 'Identidade & Planos',
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
                'Dossiê Biológico e Reconhecimento',
                icon: const pw.IconData(0xe85e)),
            ReportStyleHelper.buildCard(
              child: pw.Column(
                children: [
                  _buildDetailRow('Espécie', profile.especie ?? 'N/A'),
                  _buildDetailRow('Sexo', profile.sex ?? 'N/A'),
                  _buildDetailRow(
                      'Status Reprodutivo', profile.statusReprodutivo ?? 'N/A'),
                  _buildDetailRow('Porte Detectado', profile.porte ?? 'N/A'),
                  if (profile.microchip != null)
                    _buildDetailRow('ID Digital (ISO)', profile.microchip!),
                ],
              ),
            ),

            ReportStyleHelper.buildSectionTitle(
                'Gestão de Planos e Apólices Seguro',
                icon: const pw.IconData(0xe8ad)),

            // Health Plan Card
            _buildPolicyCard(
              title: 'Plano de Saúde',
              name: profile.healthPlan?['nome'] ?? 'Plano Mana (Essential)',
              valueLabel: 'Investimento:',
              value: 'R\$ 180,00',
              status: 'ATIVO',
              color: PdfColors.blue700,
            ),

            // Life Insurance Card
            _buildPolicyCard(
              title: 'Seguro de Vida',
              name: profile.lifeInsurance?['nome'] ?? 'Seguro Meu Porto',
              valueLabel: 'Capital Segurado:',
              value: 'R\$ 50.000,00',
              status: 'VIGENTE',
              color: PdfColors.teal700,
            ),

            // Funeral Plan Card
            _buildPolicyCard(
              title: 'Plano Assistencial / Funeral',
              name: profile.funeralPlan?['nome'] ??
                  'ScanNut Funeral (Assistencia 24h)',
              valueLabel: 'Cobertura:',
              value: 'Nacional',
              status: 'ATIVO',
              color: ReportStyleHelper.grey,
            ),

            if (profile.observacoesPlanos.isNotEmpty) ...[
              ReportStyleHelper.buildSectionTitle('Notas de Gestão de Apólices',
                  icon: const pw.IconData(0xe873)),
              ReportStyleHelper.buildCard(
                child: pw.Text(profile.observacoesPlanos,
                    style: const pw.TextStyle(fontSize: 9.0)),
              ),
            ],

            pw.Spacer(),
            pw.Text(
                'Relatório certificado pelo sistema ScanNut de gestão de apólices e identificação biométrica.',
                style: const pw.TextStyle(
                    fontSize: 7.0, color: ReportStyleHelper.grey)),
          ];
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: const pw.TextStyle(
                  fontSize: 10.0, color: ReportStyleHelper.grey)),
          pw.Text(value.toUpperCase(),
              style: const pw.TextStyle(
                  fontSize: 10.0, color: ReportStyleHelper.primary)),
        ],
      ),
    );
  }

  static pw.Widget _buildPolicyCard({
    required String title,
    required String name,
    required String valueLabel,
    required String value,
    required String status,
    required PdfColor color,
  }) {
    return ReportStyleHelper.buildCard(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(title.toUpperCase(),
                  style: const pw.TextStyle(
                      fontSize: 8.0, color: ReportStyleHelper.grey)),
              ReportStyleHelper.buildBadge(status, color),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Text(name,
              style: const pw.TextStyle(
                  fontSize: 12.0, color: ReportStyleHelper.primary)),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(valueLabel,
                  style: const pw.TextStyle(
                      fontSize: 9.0, color: ReportStyleHelper.grey)),
              pw.Text(value,
                  style: const pw.TextStyle(
                      fontSize: 10.0, color: ReportStyleHelper.accent)),
            ],
          ),
        ],
      ),
    );
  }
}
