import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../l10n/app_localizations.dart';
import '../../models/pet_profile_extended.dart';
import '../../services/reports/report_micro_apps.dart';
import '../../../../core/widgets/pdf_preview_screen.dart';

class ReportSelectorModal extends StatelessWidget {
  final PetProfileExtended profile;

  const ReportSelectorModal({super.key, required this.profile});

  static void show(BuildContext context, PetProfileExtended profile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ReportSelectorModal(profile: profile),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final viewPadding = MediaQuery.of(context).viewPadding;

    return Container(
      decoration: const BoxDecoration(
        color: AppDesign.backgroundDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + viewPadding.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Central de Relatórios PDF',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Selecione um domínio para gerar o dossiê especializado',
              style: GoogleFonts.poppins(
                color: Colors.white54,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildReportCard(
                  context,
                  title: 'Saúde',
                  icon: Icons.health_and_safety,
                  color: Colors.greenAccent,
                  onTap: () => _generateReport(context, ReportType.health),
                ),
                _buildReportCard(
                  context,
                  title: 'Nutrição',
                  icon: Icons.restaurant,
                  color: Colors.orangeAccent,
                  onTap: () => _generateReport(context, ReportType.nutrition),
                ),
                _buildReportCard(
                  context,
                  title: 'Análises',
                  icon: Icons.analytics,
                  color: Colors.blueAccent,
                  onTap: () => _generateReport(context, ReportType.analysis),
                ),
                _buildReportCard(
                  context,
                  title: 'Viagens',
                  icon: Icons.flight_takeoff,
                  color: Colors.deepPurpleAccent,
                  onTap: () => _generateReport(context, ReportType.travel),
                ),
                _buildReportCard(
                  context,
                  title: 'Identidade & Planos',
                  icon: Icons.badge,
                  color: Colors.tealAccent,
                  onTap: () =>
                      _generateReport(context, ReportType.identityPlans),
                ),
                _buildReportCard(
                  context,
                  title: 'Galeria',
                  icon: Icons.photo_library,
                  color: Colors.pinkAccent,
                  onTap: () => _generateReport(context, ReportType.gallery),
                ),
                _buildReportCard(
                  context,
                  title: 'Agenda & Parceiros',
                  icon: Icons.connect_without_contact,
                  color: Colors.cyanAccent,
                  onTap: () =>
                      _generateReport(context, ReportType.agendaPartners),
                ),
                _buildReportCard(
                  context,
                  title: 'Ocorrências',
                  icon: Icons.history,
                  color: Colors.redAccent,
                  onTap: () => _generateReport(context, ReportType.occurrences),
                ),
                _buildReportCard(
                  context,
                  title: 'Passeios (ScanWalk)',
                  icon: Icons.map,
                  color: Colors.indigoAccent,
                  onTap: () => _generateReport(context, ReportType.walk),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(76)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _generateReport(BuildContext context, ReportType type) {
    Navigator.pop(context); // Close modal

    final l10n = AppLocalizations.of(context)!;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfPreviewScreen(
          title: 'Relatório ScanNut - ${type.name.toUpperCase()}',
          buildPdf: (format) async {
            final doc = await ReportMicroApps.generate(
              type: type,
              profile: profile,
              l10n: l10n,
            );
            return doc.save();
          },
        ),
      ),
    );
  }
}
