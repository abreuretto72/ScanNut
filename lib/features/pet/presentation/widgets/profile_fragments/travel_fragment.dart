import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_design.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../models/analise_ferida_model.dart';
import 'attachment_section.dart';

void _noop(String k, dynamic v) {}

class TravelFragment extends StatelessWidget {
  final String? especie;
  final Map<String, dynamic> prefsMap;
  final Function(String, dynamic) onPreferenceChanged;
  final DateTime? rabiesDate;
  final String? microchip;
  final List<Map<String, dynamic>> analysisHistory;
  final List<Map<String, dynamic>> labExams;
  final List<AnaliseFeridaModel> historicoAnaliseFeridas;
  final Map<String, List<File>> attachments;
  final Function(String) onAddAttachment;
  final Function(File) onDeleteAttachment;

  const TravelFragment({
    super.key,
    this.prefsMap = const {},
    this.onPreferenceChanged = _noop,
    this.rabiesDate,
    this.microchip,
    this.especie,
    this.analysisHistory = const [],
    this.labExams = const [],
    this.historicoAnaliseFeridas = const [],
    required this.attachments,
    required this.onAddAttachment,
    required this.onDeleteAttachment,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // Logic for Rabies status: < 1 year and > 30 days
    bool isRabiesVaxValid = false;
    if (rabiesDate != null) {
      final now = DateTime.now();
      final diff = now.difference(rabiesDate!);
      isRabiesVaxValid = diff.inDays > 30 && diff.inDays < 365;
    }

    // Logic for Microchip status
    final hasMicrochip = microchip != null && microchip!.trim().isNotEmpty;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100), // Padding lower 100.0 to avoid footer
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 3. Validation Cards
          _buildValidationCard(
            context, 
            l10n.petTravelVaccines, 
            isRabiesVaxValid, 
            isRabiesVaxValid 
              ? l10n.petTravelVaccineStatusOk 
              : '${l10n.petTravelVaccineStatusPending} (É necessário aguardar 30 dias após a vacina)',
            Icons.vaccines
          ),

          const SizedBox(height: 12),
          _buildValidationCard(
            context, 
            l10n.petTravelMicrochip, 
            hasMicrochip, 
            hasMicrochip ? microchip! : l10n.travel_health_data_missing,
            Icons.qr_code_scanner
          ),
          
          if (!isRabiesVaxValid && rabiesDate != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Regra dos 30 dias (Viagem): Para fins de transporte (especialmente aéreo/internacional), a vacina antirrábica só é válida após 30 dias da aplicação (Quarentena Obrigatória).',
                      style: TextStyle(color: Colors.amber[100], fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 24),


          // 🛡️ NEW: Interactive Selectors for PDF generation
          Text(
            l10n.petTravelTitle.toUpperCase(),
            style: const TextStyle(color: AppDesign.petPink, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2),
          ),
          const SizedBox(height: 16),
          
          _buildChoiceRow(
            context,
            l10n.petTravelMode,
            ['carro', 'avião', 'navio'],
            prefsMap['mode']?.toString(),
            (val) => onPreferenceChanged('mode', val),
            {
              'carro': l10n.petTravelCar,
              'avião': l10n.petTravelPlane,
              'navio': l10n.petTravelShip,
            }
          ),
          
          const SizedBox(height: 16),
          
          _buildChoiceRow(
            context,
            l10n.petTravelScope,
            ['nacional', 'internacional'],
            prefsMap['scope']?.toString(),
            (val) => onPreferenceChanged('scope', val),
            {
              'nacional': l10n.petTravelNational,
              'internacional': l10n.petTravelInternational,
            }
          ),

          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 12),
          
          // 🛡️ MOTOR DE CHECKLISTS INTELIGENTES
          Text(
            'CHECKLIST INTELIGENTE (BASEADO NA SAÚDE)',
            style: const TextStyle(color: AppDesign.petPink, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          ..._buildIntelligentChecklist(context, l10n),
          
          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 12),

          // 🛡️ GUIA DE VACINAÇÃO VITAL
          Text(
            l10n.petTravelVaccineGuide.toUpperCase(),
            style: const TextStyle(color: AppDesign.petPink, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          ..._buildVaccinationGuide(context, l10n),
          
          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 12),
          
          Text(
            'DOCUMENTOS OBRIGATÓRIOS',
            style: const TextStyle(color: AppDesign.petPink, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2),
          ),
          const SizedBox(height: 16),
          
          Card(
            color: Colors.white.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  AttachmentSection(
                    title: l10n.travelDocHealthTitle,
                    subtitle: l10n.travelDocHealthDesc,
                    files: attachments['travel_health_cert'] ?? [],
                    onAdd: () => onAddAttachment('travel_health_cert'),
                    onDelete: onDeleteAttachment,
                  ),
                  const Divider(color: Colors.white10, height: 32),
                  AttachmentSection(
                    title: l10n.travelDocVaccineTitle,
                    subtitle: l10n.travelDocVaccineDesc,
                    files: attachments['travel_vaccination_card'] ?? [],
                    onAdd: () => onAddAttachment('travel_vaccination_card'),
                    onDelete: onDeleteAttachment,
                  ),
                  const Divider(color: Colors.white10, height: 32),
                  AttachmentSection(
                    title: l10n.travelDocMicrochipTitle,
                    subtitle: l10n.travelDocMicrochipDesc,
                    files: attachments['travel_microchip_cert'] ?? [],
                    onAdd: () => onAddAttachment('travel_microchip_cert'),
                    onDelete: onDeleteAttachment,
                  ),
                  const Divider(color: Colors.white10, height: 32),
                  AttachmentSection(
                    title: l10n.travelDocCrateTitle,
                    subtitle: l10n.travelDocCrateDesc,
                    files: attachments['travel_crate_id'] ?? [],
                    onAdd: () => onAddAttachment('travel_crate_id'),
                    onDelete: onDeleteAttachment,
                  ),
                  
                  // Species Specific Sections
                  if (especie?.toLowerCase().contains('cão') == true || especie?.toLowerCase().contains('cao') == true || especie?.toLowerCase().contains('dog') == true) ...[
                    const Divider(color: Colors.white10, height: 32),
                    AttachmentSection(
                        title: l10n.travelDocLeishTitle,
                        subtitle: l10n.travelDocLeishDesc,
                        files: attachments['travel_leish_vax'] ?? [],
                        onAdd: () => onAddAttachment('travel_leish_vax'),
                        onDelete: onDeleteAttachment,
                      ),
                  ] else if (especie?.toLowerCase().contains('gato') == true || especie?.toLowerCase().contains('cat') == true) ...[
                    const Divider(color: Colors.white10, height: 32),
                    AttachmentSection(
                      title: l10n.travelDocFelvTitle,
                      subtitle: l10n.travelDocFelvDesc,
                      files: attachments['travel_felv_test'] ?? [],
                      onAdd: () => onAddAttachment('travel_felv_test'),
                      onDelete: onDeleteAttachment,
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 12),


          
          // 4. Sections using ExpansionTile for clarity
          _buildTravelSection(
            context,
            l10n.travel_section_car,
            Icons.directions_car,
            l10n.travel_car_tips,
            [
              l10n.travel_car_checklist_1,
              l10n.travel_car_checklist_2,
              l10n.travel_car_checklist_3
            ]
          ),
          
          const SizedBox(height: 12),
          
          _buildTravelSection(
            context,
            l10n.travel_section_plane,
            Icons.airplanemode_active,
            l10n.travel_plane_checklist,
            [
              l10n.travel_plane_checklist_1,
              l10n.travel_plane_checklist_2,
              l10n.travel_plane_checklist_3
            ]
          ),
          
          const SizedBox(height: 12),
          
          _buildTravelSection(
            context,
            l10n.travel_section_ship,
            Icons.directions_boat,
            l10n.travel_ship_tips,
            [
              l10n.travel_ship_checklist_1,
              l10n.travel_ship_checklist_2,
              l10n.travel_ship_checklist_3
            ]
          ),
        ],
      ),
    );
  }

  Widget _buildValidationCard(BuildContext context, String title, bool isValid, String subtitle, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isValid 
            ? Colors.green.withValues(alpha: 0.2) 
            : Colors.red.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isValid ? Colors.green.withValues(alpha: 0.5) : Colors.red.withValues(alpha: 0.5), 
          width: 1
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: isValid ? Colors.green : Colors.red, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(
            isValid ? Icons.check_circle : Icons.error, 
            color: isValid ? Colors.green : Colors.red,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildTravelSection(BuildContext context, String title, IconData icon, String tips, List<String> checklist) {
    return Card(
      color: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        leading: Icon(icon, color: AppDesign.petPink),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        iconColor: AppDesign.petPink,
        collapsedIconColor: Colors.white30,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(color: Colors.white12),
                const SizedBox(height: 8),
                Text(
                  tips,
                  style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),
                ...checklist.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.check_box_outlined, color: AppDesign.petPink, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveCheck(BuildContext context, String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: value ? AppDesign.petPink.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: value ? AppDesign.petPink.withValues(alpha: 0.3) : Colors.white10),
          ),
          child: Row(
            children: [
              Icon(
                value ? Icons.check_box : Icons.check_box_outline_blank,
                color: value ? AppDesign.petPink : Colors.white30,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: value ? Colors.white : Colors.white60,
                    fontSize: 13,
                    fontWeight: value ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildIntelligentChecklist(BuildContext context, AppLocalizations l10n) {
    final List<Widget> items = [];

    // Fallback: No Data
    if (analysisHistory.isEmpty && labExams.isEmpty && historicoAnaliseFeridas.isEmpty) {
      items.add(_buildStaticCheck(context, l10n.petTravelHealthCheckup, false, isWarning: true));
    } else {
      // 1. Parasites
      bool hasParasites = false;
      for (var a in analysisHistory) {
        final diag = a['diagnostico_provavel']?.toString().toLowerCase() ?? '';
        if (diag.contains('parasita') || diag.contains('giárdia') || diag.contains('pulga') || diag.contains('verme')) {
          hasParasites = true;
          break;
        }
      }
      for (var w in historicoAnaliseFeridas) {
        if (w.categoria == 'fezes' || w.categoria == 'stool') {
            final desc = w.diagnosticosProvaveis.join(' ').toLowerCase();
            if (desc.contains('parasita') || desc.contains('giárdia') || desc.contains('verme')) {
                hasParasites = true;
                break;
            }
        }
      }
      if (hasParasites) {
        items.add(_buildStaticCheck(context, l10n.petTravelHygieneKit, true, isWarning: true, subtitle: 'Identificado no historial recente'));
      }

      // 2. Infection/Inflammation
      bool hasInfection = false;
      for (var lab in labExams) {
        final findings = lab['achados']?.toString().toLowerCase() ?? '';
        if (findings.contains('leucocitose') || findings.contains('hematúria') || findings.contains('infecção') || findings.contains('inflamação')) {
          hasInfection = true;
          break;
        }
      }
      if (hasInfection) {
        items.add(_buildStaticCheck(context, l10n.petTravelHydrationMonitoring, true, isWarning: true, subtitle: 'Baseado em exames laboratoriais'));
      }

      // 3. Health Score / Dehydration
      bool needsRest = false;
      for (var a in analysisHistory) {
        final score = int.tryParse(a['reliability']?.toString().replaceAll('%', '') ?? '100') ?? 100; // Simplified score check
        final recommendations = a['orientacao_imediata']?.toString().toLowerCase() ?? '';
        if (recommendations.contains('desidratação') || recommendations.contains('repouso')) {
          needsRest = true;
          break;
        }
      }
      if (needsRest) {
        items.add(_buildStaticCheck(context, l10n.petTravelRestSupport, true, isWarning: true));
      }

      // 4. Diet
      bool needsPremiumFood = false;
      for (var a in analysisHistory) {
        final diet = a['nutricao']?['regime_alimentar']?.toString().toLowerCase() ?? '';
        if (diet.contains('standard') || diet.contains('desbalanceada')) {
          needsPremiumFood = true;
          break;
        }
      }
      if (needsPremiumFood) {
        items.add(_buildStaticCheck(context, l10n.petTravelPremiumFoodKit, true));
      }
    }

    // 5. Standard Educational Items
    items.add(_buildStaticCheck(context, l10n.petTravelMedicationActive, false, subtitle: l10n.petTravelMedicationActiveDesc));
    items.add(_buildStaticCheck(context, l10n.petTravelWaterMineral, false, subtitle: l10n.petTravelWaterMineralDesc));
    items.add(_buildStaticCheck(context, l10n.petTravelTacticalStops, false, subtitle: l10n.petTravelTacticalStopsDesc));

    // 6. Basic Checklist Items (Interactive)
    items.add(_buildInteractiveCheck(context, l10n.petTravelSafetyBelt, prefsMap['has_safety_belt'] == true, (val) => onPreferenceChanged('has_safety_belt', val)));
    items.add(_buildInteractiveCheck(context, l10n.petTravelHealthCert, prefsMap['has_health_cert'] == true, (val) => onPreferenceChanged('has_health_cert', val)));
    items.add(_buildInteractiveCheck(context, l10n.petTravelCZI, prefsMap['has_czi'] == true, (val) => onPreferenceChanged('has_czi', val)));

    return items;
  }

  List<Widget> _buildVaccinationGuide(BuildContext context, AppLocalizations l10n) {
    final List<Widget> items = [];
    final bool isDog = especie?.toLowerCase().contains('cão') == true || especie?.toLowerCase().contains('cao') == true || especie?.toLowerCase().contains('dog') == true;
    final bool isCat = especie?.toLowerCase().contains('gato') == true || especie?.toLowerCase().contains('cat') == true;

    if (isDog) {
      items.add(_buildEducationalInfo(context, 'V8/V10 (Cães)', l10n.petTravelV8V10Desc, Icons.shield));
      items.add(_buildEducationalInfo(context, 'Gripe/Bordetella', l10n.petTravelGripeDesc, Icons.air));
      items.add(_buildEducationalInfo(context, 'Leishmaniose', l10n.petTravelLeishDesc, Icons.bug_report));
    } else if (isCat) {
      items.add(_buildEducationalInfo(context, 'V3/V4/V5 (Gatos)', l10n.petTravelV3V4V5Desc, Icons.shield));
    }

    // Both
    items.add(_buildEducationalInfo(context, 'Antirrábica', l10n.petTravelRabiesDesc, Icons.gavel, isMandatory: true));

    return items;
  }

  Widget _buildStaticCheck(BuildContext context, String label, bool isAutomated, {bool isWarning = false, String? subtitle}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWarning ? Colors.red.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isWarning ? Colors.red.withValues(alpha: 0.3) : Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isWarning ? Icons.error_outline : Icons.info_outline,
                color: isWarning ? Colors.red[300] : AppDesign.petPink,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isWarning ? Colors.red[100] : Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isAutomated)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppDesign.petPink.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                  child: const Text('AUTO', style: TextStyle(color: AppDesign.petPink, fontSize: 8, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEducationalInfo(BuildContext context, String title, String description, IconData icon, {bool isMandatory = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppDesign.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isMandatory ? AppDesign.petPink.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: isMandatory ? AppDesign.petPink : Colors.white38, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              if (isMandatory)
                const Icon(Icons.star, color: AppDesign.petPink, size: 14),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceRow(BuildContext context, String label, List<String> options, String? currentValue, Function(String) onSelected, Map<String, String> localizationMap) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: options.map((opt) {
            final isSelected = currentValue == opt;
            return ChoiceChip(
              label: Text(localizationMap[opt] ?? opt),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) onSelected(opt);
              },
              selectedColor: AppDesign.petPink.withValues(alpha: 0.2),
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              labelStyle: TextStyle(
                color: isSelected ? AppDesign.petPink : Colors.white60,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isSelected ? AppDesign.petPink : Colors.white12)
              ),
              showCheckmark: false,
            );
          }).toList(),
        ),
      ],
    );
  }
}
