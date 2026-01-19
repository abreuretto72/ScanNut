import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_design.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/widgets/cumulative_observations_field.dart';
import 'profile_design_system.dart';
import 'chips_input_field.dart';
import 'weight_feedback_section.dart';
import 'attachment_section.dart';
import 'dart:io';

class NutritionFragment extends StatelessWidget {
  final TextEditingController alergiasController;
  final List<String> alergiasConhecidas;
  final TextEditingController restricoesController;
  final List<String> restricoes;
  final TextEditingController preferenciasController;
  final List<String> preferencias;
  final String observacoesNutricao;
  
  final Function(String) onAddAlergia;
  final Function(int) onDeleteAlergia;
  final Function(String) onAddRestricao;
  final Function(int) onDeleteRestricao;
  final Function(String) onAddPreferencial;
  final Function(int) onDeletePreferencial;
  final Function(String) onObservacoesChanged;
  
  final TextEditingController pesoController;
  final String? raca;
  final String? porte;
  final List<File> attachments;
  final Widget weeklyPlanSection;
  final VoidCallback onAddAttachment;
  final Function(File) onDeleteAttachment;

  const NutritionFragment({
    Key? key,
    required this.alergiasController,
    required this.alergiasConhecidas,
    required this.restricoesController,
    required this.restricoes,
    required this.preferenciasController,
    required this.preferencias,
    required this.observacoesNutricao,
    required this.onAddAlergia,
    required this.onDeleteAlergia,
    required this.onAddRestricao,
    required this.onDeleteRestricao,
    required this.onAddPreferencial,
    required this.onDeletePreferencial,
    required this.onObservacoesChanged,
    required this.pesoController,
    required this.raca,
    required this.porte,
    required this.attachments,
    required this.weeklyPlanSection,
    required this.onAddAttachment,
    required this.onDeleteAttachment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        ProfileDesignSystem.buildSectionTitle('⚠️ ${l10n.petFoodAllergies}'),
        const SizedBox(height: 8),
        Text(
          l10n.petFoodAllergiesDesc,
          style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12),
        ),
        const SizedBox(height: 16),
        
        ChipsInputField(
          controller: alergiasController,
          label: l10n.petAddAllergy,
          icon: Icons.warning,
          chips: alergiasConhecidas,
          onAdd: onAddAlergia,
          onDelete: onDeleteAlergia,
        ),

        const SizedBox(height: 24),
        ProfileDesignSystem.buildSectionTitle('🚫 ${l10n.petFoodRestrictions ?? 'Restrições'}'),
        const SizedBox(height: 8),
        Text(
          l10n.petFoodRestrictionsDesc ?? 'Ingredientes proibidos ou a evitar (ex: sem frango, sem glúten).',
          style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12),
        ),
        const SizedBox(height: 16),
        
        ChipsInputField(
          controller: restricoesController,
          label: l10n.petAddRestriction ?? 'Adicionar restrição',
          icon: Icons.block,
          chips: restricoes,
          chipColor: AppDesign.petPink.withOpacity(0.8),
          onAdd: onAddRestricao,
          onDelete: onDeleteRestricao,
        ),
        
        const SizedBox(height: 24),
        ProfileDesignSystem.buildSectionTitle('❤️ ${l10n.petFoodPreferences}'),
        const SizedBox(height: 8),
        Text(
          l10n.petFoodPreferencesDesc,
          style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12),
        ),
        const SizedBox(height: 16),
        
        ChipsInputField(
          controller: preferenciasController,
          label: l10n.petAddPreference,
          icon: Icons.favorite,
          chips: preferencias,
          chipColor: AppDesign.petPink,
          onAdd: onAddPreferencial,
          onDelete: onDeletePreferencial,
        ),

        WeightFeedbackSection(
          pesoController: pesoController,
          raca: raca,
          porte: porte,
        ),
        weeklyPlanSection,

        AttachmentSection(
          title: l10n.petDietRecipes,
          files: attachments,
          onAdd: onAddAttachment,
          onDelete: onDeleteAttachment,
        ),
        
        const SizedBox(height: 24),
        CumulativeObservationsField(
          sectionName: 'Nutrição',
          initialValue: observacoesNutricao,
          onChanged: onObservacoesChanged,
          icon: Icons.restaurant,
          accentColor: AppDesign.petPink,
        ),
      ],
      ),
    );
  }
}
