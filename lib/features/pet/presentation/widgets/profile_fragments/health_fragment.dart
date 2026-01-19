import 'package:flutter/material.dart';
import '../../../../../core/theme/app_design.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/widgets/cumulative_observations_field.dart';
import '../../../models/lab_exam.dart';
import 'profile_design_system.dart';
import 'attachment_section.dart';
import 'dart:io';

class HealthFragment extends StatelessWidget {
  final DateTime? dataUltimaV10;
  final DateTime? dataUltimaAntirrabica;
  final String frequenciaBanho;
  final List<String> bathOptions;
  final List<LabExam> labExams;
  final String observacoesSaude;
  
  final Function(DateTime) onV10DateSelected;
  final Function(DateTime) onAntirrabicaDateSelected;
  final Function(String) onFrequenciaBanhoChanged;
  final Function(String) onObservacoesChanged;
  
  final Map<String, List<File>> attachments;
  final Widget labExamsSection;
  final Widget woundAnalysisHistory;
  final VoidCallback onAddAttachmentPrescription;
  final VoidCallback onAddAttachmentVaccine;
  final Function(File) onDeleteAttachment;

  const HealthFragment({
    Key? key,
    required this.dataUltimaV10,
    required this.dataUltimaAntirrabica,
    required this.frequenciaBanho,
    required this.bathOptions,
    required this.labExams,
    required this.observacoesSaude,
    required this.onV10DateSelected,
    required this.onAntirrabicaDateSelected,
    required this.onFrequenciaBanhoChanged,
    required this.onObservacoesChanged,
    required this.attachments,
    required this.labExamsSection,
    required this.woundAnalysisHistory,
    required this.onAddAttachmentPrescription,
    required this.onAddAttachmentVaccine,
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
        ProfileDesignSystem.buildSectionTitle('💉 ${l10n.petVaccinationHistory}'),
        const SizedBox(height: 16),
        
        ProfileDesignSystem.buildDatePicker(
          context: context,
          label: l10n.petLastV10,
          icon: Icons.vaccines,
          selectedDate: dataUltimaV10,
          onDateSelected: onV10DateSelected,
        ),
        
        ProfileDesignSystem.buildDatePicker(
          context: context,
          label: l10n.petLastRabies,
          icon: Icons.coronavirus,
          selectedDate: dataUltimaAntirrabica,
          onDateSelected: onAntirrabicaDateSelected,
        ),
        
        const SizedBox(height: 24),
        ProfileDesignSystem.buildSectionTitle('🛁 ${l10n.petHygiene}'),
        const SizedBox(height: 16),
        
        ProfileDesignSystem.buildOptionSelector(
          value: frequenciaBanho,
          label: l10n.petBathFrequency,
          icon: Icons.water_drop,
          options: bathOptions,
          onChanged: (val) => onFrequenciaBanhoChanged(val!),
        ),

        const SizedBox(height: 24),
        labExamsSection,
        
        const SizedBox(height: 24),
        ProfileDesignSystem.buildSectionTitle('📄 ${l10n.petMedicalDocs}'),
        const SizedBox(height: 8),
        
        AttachmentSection(
          title: '📝 ${l10n.petPrescriptions}',
          files: attachments['health_prescriptions'] ?? [],
          onAdd: onAddAttachmentPrescription,
          onDelete: onDeleteAttachment,
        ),
        AttachmentSection(
          title: '💉 ${l10n.petVaccineCard}',
          files: attachments['health_vaccines'] ?? [],
          onAdd: onAddAttachmentVaccine,
          onDelete: onDeleteAttachment,
        ),

        const SizedBox(height: 24),
        woundAnalysisHistory,

        const SizedBox(height: 24),
        CumulativeObservationsField(
          sectionName: 'Saúde',
          initialValue: observacoesSaude,
          onChanged: onObservacoesChanged,
          icon: Icons.medical_services,
          accentColor: AppDesign.petPink,
        ),
      ],
      ),
    );
  }
}
