import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_design.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/widgets/cumulative_observations_field.dart';
import 'profile_design_system.dart';
import 'race_details_section.dart';
import 'attachment_section.dart';

class IdentityFragment extends StatelessWidget {
  final TextEditingController nameController;
  final String? especie;
  final TextEditingController racaController;
  final TextEditingController idadeController;
  final TextEditingController? pesoController;
  final TextEditingController? microchipController;
  final String? porte;
  final String? sexo;
  final String nivelAtividade;
  final String statusReprodutivo;
  final String? reliability;
  final String observacoesIdentidade;
  final List<String> activityOptions;
  final Map<String, List<File>> attachments;
  final Map<String, dynamic>? currentRawAnalysis;

  final Function(String) onEspecieChanged;
  final Function(String) onSexoChanged;
  final Function(String?) onPorteChanged;
  final Function(String) onNivelAtividadeChanged;
  final Function(String) onStatusReprodutivoChanged;
  final Function(String) onObservacoesChanged;
  final VoidCallback onUserTyping;
  final VoidCallback onUserInteractionGeneric;
  final String Function(String?, {bool isReliability}) localizeValue;
  final VoidCallback onAddAttachment;
  final Function(File) onDeleteAttachment;

  const IdentityFragment({
    super.key,
    required this.nameController,
    required this.especie,
    required this.racaController,
    required this.idadeController,
    required this.pesoController,
    this.microchipController,
    required this.porte,
    required this.sexo,
    required this.nivelAtividade,
    required this.statusReprodutivo,
    required this.reliability,
    required this.observacoesIdentidade,
    required this.activityOptions,
    required this.attachments,
    required this.currentRawAnalysis,
    required this.onEspecieChanged,
    required this.onSexoChanged,
    required this.onPorteChanged,
    required this.onNivelAtividadeChanged,
    required this.onStatusReprodutivoChanged,
    required this.onObservacoesChanged,
    required this.onUserTyping,
    required this.onUserInteractionGeneric,
    required this.localizeValue,
    required this.onAddAttachment,
    required this.onDeleteAttachment,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. NAME CARD
          Card(
            color: Colors.white.withValues(alpha: 0.05),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfileDesignSystem.buildSectionTitle('Nome do Pet',
                      icon: Icons.pets),
                  const SizedBox(height: 12),
                  ProfileDesignSystem.buildTextField(
                    controller: nameController,
                    label: 'Nome',
                    icon: Icons.edit,
                    isRequired: false,
                    fontSize: 18,
                    onChanged: onUserTyping,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 2. SPECIES
          // 2. SPECIES (Card Wrapped)
          Card(
            color: Colors.white.withValues(alpha: 0.05),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfileDesignSystem.buildSectionTitle(l10n.species_label,
                      icon: Icons.pets),
                  const SizedBox(height: 12),
                  _buildSpeciesSelector(l10n),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          /*
        // 3. BREED (Moved inside RaceDetailsSection for grouping)
        */
          RaceDetailsSection(
            racaController: racaController,
            pesoController: pesoController,
            porte: porte,
            currentRawAnalysis: currentRawAnalysis,
            localizeValue: localizeValue,
          ),

          const SizedBox(height: 12),

          const SizedBox(height: 24),

          // 4. CHARACTERISTICS GROUP (Age, Weight, Size, Sex, Repro)
          Card(
            color: Colors.white.withValues(alpha: 0.05),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfileDesignSystem.buildSectionTitle('Características *',
                      icon: Icons.badge),
                  const SizedBox(height: 16),

                  // Row 1: Age & Weight
                  Row(
                    children: [
                      Expanded(
                        child: ProfileDesignSystem.buildTextField(
                          controller: idadeController,
                          label: 'Idade',
                          icon: Icons.cake,
                          isRequired: false,
                        ),
                      ),
                      if (pesoController != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: ProfileDesignSystem.buildTextField(
                            controller: pesoController!,
                            label: 'Peso',
                            icon: Icons.monitor_weight,
                            isRequired: false,
                          ),
                        ),
                      ]
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Row 3: Sex (no title, icon only on first option)
                  _buildSexSelector(l10n),

                  const SizedBox(height: 16),

                  // Row 4: Reproductive Status (no title, icon only on first option)
                  _buildReproStatusSelector(l10n),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // BIOLOGICAL PROFILE CARD
          Card(
            color: Colors.white.withValues(alpha: 0.05),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfileDesignSystem.buildSectionTitle(
                      l10n.petBiologicalProfile,
                      icon: Icons.science),
                  const SizedBox(height: 16),

                  // 8. ACTIVITY
                  ProfileDesignSystem.buildOptionSelector(
                    value: nivelAtividade,
                    label: l10n.petActivityLevel,
                    icon: Icons.directions_run,
                    options: activityOptions,
                    onChanged: (val) => onNivelAtividadeChanged(val!),
                    isRequired: false,
                  ),

                  const SizedBox(height: 16),

                  // 9. MICROCHIP
                  if (microchipController != null)
                    ProfileDesignSystem.buildTextField(
                      controller: microchipController!,
                      label: 'Código do Microchip',
                      icon: Icons.qr_code_2,
                      keyboardType: TextInputType.number,
                      onChanged: onUserTyping,
                    ),

                  if (microchipController != null) const SizedBox(height: 16),

                  // 10. IDENTITY ATTACHMENTS
                  Divider(color: Colors.white.withValues(alpha: 0.1)),
                  const SizedBox(height: 12),
                  AttachmentSection(
                    title: l10n.pdfIdentitySection,
                    files: attachments['identity'] ?? [],
                    onAdd: onAddAttachment,
                    onDelete: onDeleteAttachment,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          CumulativeObservationsField(
            sectionName: 'Identidade',
            initialValue: observacoesIdentidade,
            onChanged: onObservacoesChanged,
            icon: Icons.pets,
            accentColor: AppDesign.petPink,
          ),
        ],
      ),
    );
  }

  Widget _buildSpeciesSelector(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppDesign.backgroundDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildSpeciesOption(l10n.species_dog, 'Cão'),
          const SizedBox(width: 8),
          _buildSpeciesOption(l10n.species_cat, 'Gato'),
        ],
      ),
    );
  }

  Widget _buildSpeciesOption(String label, String value) {
    bool selected = especie == value;
    return Expanded(
      child: InkWell(
        onTap: () => onEspecieChanged(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppDesign.petPink.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Radio<String>(
                value: value,
                groupValue: especie,
                activeColor: AppDesign.petPink,
                onChanged: (val) => onEspecieChanged(val!),
              ),
              Text(label,
                  style: TextStyle(
                      color: selected ? Colors.white : Colors.white60,
                      fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReliabilityBadge(AppLocalizations l10n) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppDesign.petPink.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppDesign.petPink.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified, color: AppDesign.petPink, size: 14),
            const SizedBox(width: 4),
            Text(
              '${l10n.reliability_label}: $reliability',
              style: const TextStyle(
                  color: AppDesign.petPink,
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSexSelector(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppDesign.backgroundDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildSexOption(l10n.gender_male, 'Male'),
          const SizedBox(width: 8),
          _buildSexOption(l10n.gender_female, 'Female'),
        ],
      ),
    );
  }

  Widget _buildSexOption(String label, String value) {
    bool selected = sexo == value;
    return Expanded(
      child: InkWell(
        onTap: () => onSexoChanged(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppDesign.petPink.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Radio<String>(
                value: value,
                groupValue: sexo,
                activeColor: AppDesign.petPink,
                onChanged: (val) => onSexoChanged(val!),
              ),
              Expanded(
                  child: Text(label,
                      style: TextStyle(
                          color: selected ? Colors.white : Colors.white60,
                          fontSize: 13))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReproStatusSelector(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppDesign.backgroundDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildReproOption(l10n.petNeutered, l10n.petNeutered, l10n),
          const SizedBox(width: 8),
          _buildReproOption(l10n.petIntact, l10n.petIntact, l10n),
        ],
      ),
    );
  }

  Widget _buildReproOption(String label, String value, AppLocalizations l10n) {
    bool selected = localizeValue(statusReprodutivo) == value;
    return Expanded(
      child: InkWell(
        onTap: () => onStatusReprodutivoChanged(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppDesign.petPink.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Radio<String>(
                value: value,
                groupValue: localizeValue(statusReprodutivo),
                activeColor: AppDesign.petPink,
                onChanged: (val) => onStatusReprodutivoChanged(val!),
              ),
              Expanded(
                  child: Text(label,
                      style: TextStyle(
                          color: selected ? Colors.white : Colors.white60,
                          fontSize: 13))),
            ],
          ),
        ),
      ),
    );
  }
}
