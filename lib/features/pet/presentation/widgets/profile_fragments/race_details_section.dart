import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_design.dart';
import '../../../../../l10n/app_localizations.dart';
import 'profile_design_system.dart';
import 'weight_feedback_section.dart';

class RaceDetailsSection extends StatelessWidget {
  final TextEditingController? racaController;
  final TextEditingController? pesoController;
  final String? porte;
  final Map<String, dynamic>? currentRawAnalysis;
  final String Function(String?, {bool isReliability}) localizeValue;

  const RaceDetailsSection({
    super.key,
    this.racaController,
    this.pesoController,
    this.porte,
    required this.currentRawAnalysis,
    required this.localizeValue,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // Always render structure if controller is present (for editing), or if we have analysis data
    final hasAnalysis = currentRawAnalysis != null;
    
    return Card(
      color: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             // 0. Title at Top
             ProfileDesignSystem.buildSectionTitle(l10n.petRaceAnalysis, icon: Icons.analytics),
             const SizedBox(height: 16),
             
             // 1. Breed Input Field (Always show if controller provided)
             if (racaController != null) ...[
                ProfileDesignSystem.buildTextField(
                  controller: racaController!,
                  label: l10n.petProfile_breed,
                  icon: Icons.category,
                  isRequired: true,
                ),
                if (hasAnalysis) const SizedBox(height: 16),
             ],

             // 2. Analysis Details (Only if available)
             if (hasAnalysis) 
               _buildAnalysisContent(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisContent(BuildContext context, AppLocalizations l10n) {
    final raw = currentRawAnalysis!;
    final ident = raw['identificacao'] as Map?;
    final temp = raw['temperamento'] as Map?;
    final fisica = raw['caracteristicas_fisicas'] as Map?;
    final origem = raw['origem_historia'] as String?;
    final curiosidades = raw['curiosidades'] as List?;
    
    if (ident == null && temp == null && fisica == null && origem == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Divider(color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 12),
        
        if (ident != null) ...[
          _buildInfoRow(l10n.petRaceAnalysis, localizeValue(ident['raca_predominante']?.toString())),
        ],
        
        if (fisica != null) ...[
          _buildInfoRow(l10n.petLifeExpectancy, fisica['expectativa_vida']?.toString() ?? l10n.petNotEstimated),
          _buildInfoRow(l10n.petSize, fisica['porte']?.toString() ?? l10n.petNotIdentified),
          if (pesoController != null)
             WeightFeedbackSection(
               pesoController: pesoController!, 
               raca: racaController?.text ?? ident?['raca_predominante']?.toString(), 
               porte: porte ?? fisica['porte']?.toString()
             )
          else
             _buildInfoRow(l10n.petTypicalWeight, fisica['peso_estimado']?.toString() ?? l10n.petVariable),
        ],

        /*
        if (temp != null) ...[
        // Temperament and Social Behavior removed as per request
        ],
        */
        
        if (origem != null) ...[
          const SizedBox(height: 12),
          ExpansionTile(
            title: Text(l10n.petOrigin, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
            collapsedIconColor: Colors.white54,
            iconColor: AppDesign.petPink,
            children: [
              Padding(
                padding: const EdgeInsets.all(8), 
                child: Text(origem, style: const TextStyle(color: Colors.white70))
              )
            ],
          )
        ],

        if (curiosidades != null && curiosidades.isNotEmpty) ...[
          const SizedBox(height: 12),
          ExpansionTile(
            title: Text(l10n.petCuriosities, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
            collapsedIconColor: Colors.white54,
            iconColor: Colors.amber,
            children: curiosidades.map((c) => ListTile(
              leading: const Icon(Icons.star, color: Colors.amber, size: 16),
              title: Text(c.toString(), style: const TextStyle(color: Colors.white70, fontSize: 13)),
            )).toList(),
          )
        ]
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text('$label:', style: const TextStyle(color: Colors.white54, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13))),
        ],
      ),
    );
  }
}
