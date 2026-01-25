import 'package:pdf/widgets.dart' as pw;
import '../../models/pet_profile_extended.dart';
import '../../../../l10n/app_localizations.dart';
import 'report_style_helper.dart';
import 'package:pdf/pdf.dart';

class GalleryReportEngine {
  static Future<pw.Document> generate(
      PetProfileExtended profile, AppLocalizations l10n) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (context) => ReportStyleHelper.buildHeader(
          title: 'Dossiê Fotográfico',
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
          final galleryImages = profile.galleryAttachments;

          return [
            ReportStyleHelper.buildSectionTitle(
                'Evidências Visuais e Documentação',
                icon: const pw.IconData(0xe410)),
            if (galleryImages.isEmpty)
              ReportStyleHelper.buildCard(
                  child: pw.Center(
                      child: pw.Text(
                          'Nenhum registro fotográfico disponível na galeria.',
                          style: const pw.TextStyle(
                              color: ReportStyleHelper.grey))))
            else
              pw.GridView(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: galleryImages.map((file) {
                  if (!file.existsSync()) return pw.Container();
                  return pw.Container(
                    decoration: pw.BoxDecoration(
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(8)),
                      border:
                          pw.Border.all(color: PdfColors.grey200, width: 0.5),
                    ),
                    child: pw.ClipRRect(
                      horizontalRadius: 8,
                      verticalRadius: 8,
                      child: pw.Image(
                        pw.MemoryImage(file.readAsBytesSync()),
                        fit: pw.BoxFit.cover,
                      ),
                    ),
                  );
                }).toList(),
              ),
            if (profile.observacoesGaleria.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              ReportStyleHelper.buildSectionTitle('Notas Adicionais da Galeria',
                  icon: const pw.IconData(0xe873)),
              ReportStyleHelper.buildCard(
                child: pw.Text(profile.observacoesGaleria,
                    style: const pw.TextStyle(fontSize: 10.0)),
              ),
            ],
          ];
        },
      ),
    );

    return pdf;
  }
}
