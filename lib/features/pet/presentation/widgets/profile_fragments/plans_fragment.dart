import 'package:flutter/material.dart';
import '../../../../../core/theme/app_design.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/widgets/cumulative_observations_field.dart';
import 'profile_design_system.dart';
import 'package:google_fonts/google_fonts.dart';

class PlansFragment extends StatefulWidget {
  final Map<String, dynamic>? healthPlan;
  final Map<String, dynamic>? assistancePlan;
  final Map<String, dynamic>? funeralPlan;
  final Map<String, dynamic>? lifeInsurance;
  final TextEditingController observacoesController;
  
  final Function(Map<String, dynamic>?) onHealthPlanChanged;
  final Function(Map<String, dynamic>?) onAssistancePlanChanged;
  final Function(Map<String, dynamic>?) onFuneralPlanChanged;
  final Function(Map<String, dynamic>?) onLifeInsuranceChanged;
  final VoidCallback onUserInteraction;

  const PlansFragment({
    super.key,
    required this.healthPlan,
    required this.assistancePlan,
    required this.funeralPlan,
    required this.lifeInsurance,
    required this.observacoesController,
    required this.onHealthPlanChanged,
    required this.onAssistancePlanChanged,
    required this.onFuneralPlanChanged,
    required this.onLifeInsuranceChanged,
    required this.onUserInteraction,
  });

  @override
  State<PlansFragment> createState() => _PlansFragmentState();
}

class _PlansFragmentState extends State<PlansFragment> {
  // Controllers cached locally to avoid disposal issues
  late final TextEditingController _hpNameController;
  late final TextEditingController _hpValueController;
  late final TextEditingController _apNameController;
  late final TextEditingController _apMaxValueController;
  late final TextEditingController _fpNameController;
  late final TextEditingController _fpContactController;
  late final TextEditingController _liInsurerController;
  late final TextEditingController _liValueController;

  @override
  void initState() {
    super.initState();
    _hpNameController = TextEditingController(text: widget.healthPlan?['name'] ?? '');
    _hpValueController = TextEditingController(text: widget.healthPlan?['monthly_value']?.toString() ?? '');
    _apNameController = TextEditingController(text: widget.assistancePlan?['name'] ?? '');
    _apMaxValueController = TextEditingController(text: widget.assistancePlan?['max_value']?.toString() ?? '');
    _fpNameController = TextEditingController(text: widget.funeralPlan?['name'] ?? '');
    _fpContactController = TextEditingController(text: widget.funeralPlan?['emergency_contact'] ?? '');
    _liInsurerController = TextEditingController(text: widget.lifeInsurance?['insurer'] ?? '');
    _liValueController = TextEditingController(text: widget.lifeInsurance?['insured_value']?.toString() ?? '');
  }

  @override
  void dispose() {
    _hpNameController.dispose();
    _hpValueController.dispose();
    _apNameController.dispose();
    _apMaxValueController.dispose();
    _fpNameController.dispose();
    _fpContactController.dispose();
    _liInsurerController.dispose();
    _liValueController.dispose();
    super.dispose();
  }

  void _notifyInteraction() {
    widget.onUserInteraction();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Informativo
          Text(
            l10n.plansTabSubtitle,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // SEÇÃO 1: Saúde Veterinária
          _buildPlanSection(
            title: l10n.planTitleHealth,
            icon: Icons.health_and_safety,
            isActive: widget.healthPlan?['active'] == true,
            helpText: l10n.healthPlanHelpText,
            onToggle: (v) {
              final current = widget.healthPlan ?? {};
              widget.onHealthPlanChanged({...current, 'active': v});
            },
            children: [
              ProfileDesignSystem.buildTextField(
                controller: _hpNameController,
                label: l10n.healthPlanOperator,
                icon: Icons.business,
                onChanged: () {
                  final current = widget.healthPlan ?? {};
                  widget.onHealthPlanChanged({...current, 'name': _hpNameController.text});
                },
              ),
              const SizedBox(height: 16),
              _buildSubsectionTitle(l10n.healthPlanCoverage),
              _buildCheckboxGrid([
                 _buildCheckboxItem(l10n.healthPlanConsultations, 'covers_consults', widget.healthPlan),
                 _buildCheckboxItem(l10n.healthPlanExams, 'covers_exams', widget.healthPlan),
                 _buildCheckboxItem(l10n.healthPlanSurgeries, 'covers_surgeries', widget.healthPlan),
                 _buildCheckboxItem(l10n.healthPlanEmergencies, 'covers_emergencies', widget.healthPlan),
                 _buildCheckboxItem(l10n.healthPlanHospitalization, 'covers_hospitalization', widget.healthPlan),
                 _buildCheckboxItem(l10n.healthPlanVaccines, 'covers_vaccines', widget.healthPlan),
              ]),
              const SizedBox(height: 16),
              _buildSubsectionTitle(l10n.healthPlanType),
              Row(
                children: [
                  _buildRadioItem(l10n.healthPlanNetwork, 'network', widget.healthPlan?['type'], (v) {
                    final current = widget.healthPlan ?? {};
                    widget.onHealthPlanChanged({...current, 'type': 'network'});
                  }),
                  _buildRadioItem(l10n.healthPlanReimbursement, 'reimbursement', widget.healthPlan?['type'], (v) {
                    final current = widget.healthPlan ?? {};
                    widget.onHealthPlanChanged({...current, 'type': 'reimbursement'});
                  }),
                ],
              ),
              const SizedBox(height: 16),
              ProfileDesignSystem.buildTextField(
                controller: _hpValueController,
                label: l10n.healthPlanValue,
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
                onChanged: () {
                  final current = widget.healthPlan ?? {};
                  widget.onHealthPlanChanged({...current, 'monthly_value': _hpValueController.text});
                },
              ),
            ],
          ),

          // SEÇÃO 2: Assistência / Reembolso
          _buildPlanSection(
            title: l10n.planTitleAssistance,
            icon: Icons.payments,
            isActive: widget.assistancePlan?['active'] == true,
            helpText: l10n.assistancePlanHelpText,
            onToggle: (v) {
              final current = widget.assistancePlan ?? {};
              widget.onAssistancePlanChanged({...current, 'active': v});
            },
            children: [
              ProfileDesignSystem.buildTextField(
                controller: _apNameController,
                label: l10n.assistancePlanOperator,
                icon: Icons.business,
                onChanged: () {
                  final current = widget.assistancePlan ?? {};
                  widget.onAssistancePlanChanged({...current, 'name': _apNameController.text});
                },
              ),
              const SizedBox(height: 16),
              _buildSubsectionTitle(l10n.assistancePlanReimbursementType),
              Row(
                children: [
                  _buildRadioItem(l10n.assistancePlanTotal, 'total', widget.assistancePlan?['reimbursement_type'], (v) {
                    final current = widget.assistancePlan ?? {};
                    widget.onAssistancePlanChanged({...current, 'reimbursement_type': 'total'});
                  }),
                  _buildRadioItem(l10n.assistancePlanPartial, 'partial', widget.assistancePlan?['reimbursement_type'], (v) {
                    final current = widget.assistancePlan ?? {};
                    widget.onAssistancePlanChanged({...current, 'reimbursement_type': 'partial'});
                  }),
                ],
              ),
              const SizedBox(height: 16),
              ProfileDesignSystem.buildTextField(
                controller: _apMaxValueController,
                label: l10n.assistancePlanMaxValue,
                icon: Icons.money_off,
                keyboardType: TextInputType.number,
                onChanged: () {
                  final current = widget.assistancePlan ?? {};
                  widget.onAssistancePlanChanged({...current, 'max_value': _apMaxValueController.text});
                },
              ),
              const SizedBox(height: 12),
              _buildSwitchItem(l10n.assistancePlanNeedsInvoice, 'needs_invoice', widget.assistancePlan, (v) {
                final current = widget.assistancePlan ?? {};
                widget.onAssistancePlanChanged({...current, 'needs_invoice': v});
              }),
            ],
          ),

          // SEÇÃO 3: Funerário
          _buildPlanSection(
            title: l10n.planTitleFuneral,
            icon: Icons.church,
            isActive: widget.funeralPlan?['active'] == true,
            helpText: l10n.funeralPlanHelpText,
            onToggle: (v) {
              final current = widget.funeralPlan ?? {};
              widget.onFuneralPlanChanged({...current, 'active': v});
            },
            children: [
              ProfileDesignSystem.buildTextField(
                controller: _fpNameController,
                label: l10n.funeralPlanOperator,
                icon: Icons.business,
                onChanged: () {
                  final current = widget.funeralPlan ?? {};
                  widget.onFuneralPlanChanged({...current, 'name': _fpNameController.text});
                },
              ),
              const SizedBox(height: 16),
              _buildSubsectionTitle(l10n.funeralPlanServices),
              _buildCheckboxGrid([
                 _buildCheckboxItem(l10n.funeralPlanWake, 'incl_wake', widget.funeralPlan, (v, field) {
                   final current = widget.funeralPlan ?? {};
                   widget.onFuneralPlanChanged({...current, field: v});
                 }),
                 _buildCheckboxItem(l10n.funeralPlanIndivCremation, 'incl_crem_indiv', widget.funeralPlan, (v, field) {
                   final current = widget.funeralPlan ?? {};
                   widget.onFuneralPlanChanged({...current, field: v});
                 }),
                 _buildCheckboxItem(l10n.funeralPlanCollCremation, 'incl_crem_coll', widget.funeralPlan, (v, field) {
                   final current = widget.funeralPlan ?? {};
                   widget.onFuneralPlanChanged({...current, field: v});
                 }),
                 _buildCheckboxItem(l10n.funeralPlanTransport, 'incl_transport', widget.funeralPlan, (v, field) {
                   final current = widget.funeralPlan ?? {};
                   widget.onFuneralPlanChanged({...current, field: v});
                 }),
                 _buildCheckboxItem(l10n.funeralPlanMemorial, 'incl_memorial', widget.funeralPlan, (v, field) {
                   final current = widget.funeralPlan ?? {};
                   widget.onFuneralPlanChanged({...current, field: v});
                 }),
              ]),
              const SizedBox(height: 16),
              _buildSwitchItem(l10n.funeralPlan24h, 'support_24h', widget.funeralPlan, (v) {
                final current = widget.funeralPlan ?? {};
                widget.onFuneralPlanChanged({...current, 'support_24h': v});
              }),
              const SizedBox(height: 16),
              ProfileDesignSystem.buildTextField(
                controller: _fpContactController,
                label: l10n.funeralPlanEmergencyContact,
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                onChanged: () {
                  final current = widget.funeralPlan ?? {};
                  widget.onFuneralPlanChanged({...current, 'emergency_contact': _fpContactController.text});
                },
              ),
            ],
          ),

          // SEÇÃO 4: Seguro de Vida
          _buildPlanSection(
            title: l10n.planTitleLife,
            icon: Icons.favorite,
            isActive: widget.lifeInsurance?['active'] == true,
            helpText: l10n.lifeInsuranceHelpText,
            onToggle: (v) {
              final current = widget.lifeInsurance ?? {};
              widget.onLifeInsuranceChanged({...current, 'active': v});
            },
            children: [
              ProfileDesignSystem.buildTextField(
                controller: _liInsurerController,
                label: l10n.lifeInsuranceInsurer,
                icon: Icons.security,
                onChanged: () {
                  final current = widget.lifeInsurance ?? {};
                  widget.onLifeInsuranceChanged({...current, 'insurer': _liInsurerController.text});
                },
              ),
              const SizedBox(height: 16),
              ProfileDesignSystem.buildTextField(
                controller: _liValueController,
                label: l10n.lifeInsuranceInsuredValue,
                icon: Icons.payments,
                keyboardType: TextInputType.number,
                onChanged: () {
                  final current = widget.lifeInsurance ?? {};
                  widget.onLifeInsuranceChanged({...current, 'insured_value': _liValueController.text});
                },
              ),
              const SizedBox(height: 16),
              _buildSubsectionTitle(l10n.lifeInsuranceCoverages),
              _buildCheckboxGrid([
                 _buildCheckboxItem(l10n.lifeInsuranceDeath, 'cov_death', widget.lifeInsurance, (v, field) {
                   final current = widget.lifeInsurance ?? {};
                   widget.onLifeInsuranceChanged({...current, field: v});
                 }),
                 _buildCheckboxItem(l10n.lifeInsuranceGraveIllness, 'cov_illness', widget.lifeInsurance, (v, field) {
                   final current = widget.lifeInsurance ?? {};
                   widget.onLifeInsuranceChanged({...current, field: v});
                 }),
                 _buildCheckboxItem(l10n.lifeInsuranceEuthanasia, 'cov_euthanasia', widget.lifeInsurance, (v, field) {
                   final current = widget.lifeInsurance ?? {};
                   widget.onLifeInsuranceChanged({...current, field: v});
                 }),
              ]),
              const SizedBox(height: 16),
              _buildSwitchItem(l10n.lifeInsuranceEconomicValue, 'has_economic_value', widget.lifeInsurance, (v) {
                final current = widget.lifeInsurance ?? {};
                widget.onLifeInsuranceChanged({...current, 'has_economic_value': v});
              }),
            ],
          ),

          const SizedBox(height: 8),
          CumulativeObservationsField(
            sectionName: l10n.plansTabTitle,
            initialValue: widget.observacoesController.text,
            controller: widget.observacoesController,
            label: l10n.planObservations,
            onChanged: (v) => _notifyInteraction(),
          ),
          const SizedBox(height: 80), // Padding para fab/footer
        ],
      ),
    );
  }

  Widget _buildPlanSection({
    required String title,
    required IconData icon,
    required bool isActive,
    required String helpText,
    required Function(bool) onToggle,
    required List<Widget> children,
  }) {
    return Card(
      color: Colors.white.withOpacity(0.05),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: ProfileDesignSystem.buildSectionTitle(title, icon: icon)),
                Switch(
                  value: isActive,
                  onChanged: (v) {
                    onToggle(v);
                    _notifyInteraction();
                  },
                  activeThumbColor: AppDesign.petPink,
                ),
              ],
            ),
            
            Text(
              helpText,
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontStyle: FontStyle.italic),
            ),
            
            if (isActive) ...[
              const Divider(color: Colors.white10, height: 24),
              ...children,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubsectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCheckboxGrid(List<Widget> children) {
    return Wrap(
      spacing: 8,
      runSpacing: 0,
      children: children,
    );
  }

  Widget _buildCheckboxItem(String label, String field, Map<String, dynamic>? data, [Function(bool, String)? customOnChanged]) {
    final bool isChecked = data?[field] == true;
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 80) / 2,
      child: CheckboxListTile(
        value: isChecked,
        title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        dense: true,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: AppDesign.petPink,
        onChanged: (v) {
           if (customOnChanged != null) {
             customOnChanged(v ?? false, field);
           } else {
             // Default notify/change (to be handled by parent logic if generic)
             final current = widget.healthPlan ?? {}; // Example for health set
             widget.onHealthPlanChanged({...current, field: v});
           }
           _notifyInteraction();
        },
      ),
    );
  }

  Widget _buildRadioItem(String label, String value, dynamic groupValue, Function(String?)? onChanged) {
    return Expanded(
      child: RadioListTile<String>(
        value: value,
        groupValue: groupValue?.toString(),
        title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        dense: true,
        contentPadding: EdgeInsets.zero,
        activeColor: AppDesign.petPink,
        onChanged: (v) {
          onChanged?.call(v);
          _notifyInteraction();
        },
      ),
    );
  }

  Widget _buildSwitchItem(String label, String field, Map<String, dynamic>? data, Function(bool) onChanged) {
    return SwitchListTile(
      value: data?[field] == true,
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
      contentPadding: EdgeInsets.zero,
      dense: true,
      activeThumbColor: AppDesign.petPink,
      onChanged: (v) {
        onChanged(v);
        _notifyInteraction();
      },
    );
  }
}
