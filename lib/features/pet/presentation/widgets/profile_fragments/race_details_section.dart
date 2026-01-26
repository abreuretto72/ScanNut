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
            ProfileDesignSystem.buildSectionTitle(l10n.petRaceAnalysis,
                icon: Icons.analytics),
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
            if (hasAnalysis) _buildAnalysisContent(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisContent(BuildContext context, AppLocalizations l10n) {
    final raw = currentRawAnalysis!;
    // 🛡️ V2.5 FLATTENING MAPPING RECOVERY
    final ident = raw['identificacao'] as Map?;
    final fisica = raw['caracteristicas_fisicas'] as Map?;
    final racaRoot = raw['raca']?.toString();
    
    // Recovery of detailed Keys
    final linhagem = raw['linhagem']?.toString() ?? ident?['linhagemSrdProvavel']?.toString() ?? ident?['lineage']?.toString();
    final morfologia = fisica?['morfologia']?.toString() ?? ident?['morfologia']?.toString() ?? ident?['morfologiaBase']?.toString();
    final origem = fisica?['origem']?.toString() ?? ident?['origemGeografica']?.toString() ?? ident?['origin_region']?.toString();
    final longevidade = raw['longevidade']?.toString() ?? fisica?['expectativa_vida']?.toString() ?? ident?['expectativaVidaMedia']?.toString();

    // If minimal data is missing, shrink
    if (racaRoot == null && ident == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: Colors.white.withValues(alpha: 0.1)),
        const SizedBox(height: 12),
        
        // 1. LINHAGEM (Lineage)
         if (linhagem != null && linhagem != 'N/A')
          _buildInfoRow('Linhagem', linhagem),

        // 2. MORFOLOGIA (Morphology)
        if (morfologia != null && morfologia != 'N/A')
          _buildInfoRow('Morfologia', morfologia),

         // 3. ORIGEM (Origin)
        if (origem != null && origem != 'N/A')
          _buildInfoRow('Região de Origem', origem),

        // 4. LONGEVIDADE (Longevity)
        if (longevidade != null && longevidade != 'N/A')
           _buildInfoRow(l10n.petLifeExpectancy, longevidade),

        // 5. PORTE (Size)
        if (fisica?['porte'] != null || porte != null)
           _buildInfoRow(l10n.petSize,
              porte ?? fisica?['porte']?.toString() ?? l10n.petNotIdentified),

        // 6. PESO (Weight Feedback)
        if (pesoController != null)
            WeightFeedbackSection(
                pesoController: pesoController!,
                raca: racaController?.text ?? racaRoot ?? 'SRD',
                porte: porte ?? fisica?['porte']?.toString())
        else if (fisica?['peso_estimado'] != null)
            _buildInfoRow(l10n.petTypicalWeight,
                fisica!['peso_estimado']?.toString() ?? l10n.petVariable),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 140, // Expanded label width for "Região de Origem"
              child: Text('$label:',
                  style: const TextStyle(color: Colors.white54, fontSize: 13))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
