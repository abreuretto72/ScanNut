import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_design.dart';

class NutritionalPillarsScreen extends StatelessWidget {
  const NutritionalPillarsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          l10n.nutritionGuideTitle,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold
          ),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // INTRO TEXT
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Text(
                l10n.nutritionIntro,
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            _buildPillarCard(
              context,
              title: l10n.ngProteinTitle,
              subtitle: l10n.ngProteinSubtitle,
              icon: Icons.fitness_center,
              color: Colors.redAccent,
              whatIs: l10n.ngProteinWhatIs,
              scanNutAction: l10n.ngProteinAction,
            ),
            const SizedBox(height: 16),
            _buildPillarCard(
              context,
              title: l10n.ngFatsTitle,
              subtitle: l10n.ngFatsSubtitle,
              icon: Icons.bolt,
              color: Colors.amber,
              whatIs: l10n.ngFatsWhatIs,
              scanNutAction: l10n.ngFatsAction,
            ),
            const SizedBox(height: 16),
            _buildPillarCard(
              context,
              title: l10n.ngCarbsTitle,
              subtitle: l10n.ngCarbsSubtitle,
              icon: Icons.grass,
              color: AppDesign.petPink,
              whatIs: l10n.ngCarbsWhatIs,
              scanNutAction: l10n.ngCarbsAction,
            ),
            const SizedBox(height: 16),
            _buildPillarCard(
              context,
              title: l10n.ngVitaminsTitle,
              subtitle: l10n.ngVitaminsSubtitle,
              icon: Icons.science,
              color: Colors.purpleAccent,
              whatIs: l10n.ngVitaminsWhatIs,
              scanNutAction: l10n.ngVitaminsAction,
            ),
            const SizedBox(height: 16),
            _buildPillarCard(
              context,
              title: l10n.ngHydrationTitle,
              subtitle: l10n.ngHydrationSubtitle,
              icon: Icons.water_drop,
              color: Colors.blueAccent,
              whatIs: l10n.ngHydrationWhatIs,
              scanNutAction: l10n.ngHydrationAction,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.4
                        ),
                        children: [
                          TextSpan(
                            text: '${l10n.ngWarningTitle} ',
                            style: GoogleFonts.poppins(
                              color: Colors.orangeAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: l10n.ngWarningText,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPillarCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String whatIs,
    required String scanNutAction,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.poppins(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 12),
                  _buildSectionTitle(l10n.ngSectionWhatIs, color),
                  const SizedBox(height: 4),
                  Text(
                    whatIs,
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle(l10n.ngSectionScanNut, AppDesign.petPink),
                  const SizedBox(height: 4),
                  Text(
                    scanNutAction,
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text, Color color) {
    return Row(
      children: [
        Icon(Icons.arrow_right, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.poppins(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
