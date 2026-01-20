import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_design.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/models/partner_model.dart';
import '../../../../../core/widgets/cumulative_observations_field.dart';
import '../linked_partner_card.dart';

class PartnersFragment extends StatelessWidget {
  final List<PartnerModel> allPartners;
  final List<String> linkedPartnerIds;
  final String selectedPartnerFilter;
  final List<String> filterCategories;
  final String observacoesPrac;
  final String petId;
  final String petName;
  
  final Function(String) onFilterChanged;
  final Function(PartnerModel) onLinkStatusChanged;
  final Function(PartnerModel) onPartnerUpdated;
  final Function(PartnerModel) onOpenAgenda;
  final Function(String) onObservacoesChanged;
  final Widget actionButtons;
  final String Function(String) localizeValue;

  const PartnersFragment({
    Key? key,
    required this.allPartners,
    required this.linkedPartnerIds,
    required this.selectedPartnerFilter,
    required this.filterCategories,
    required this.observacoesPrac,
    required this.petId,
    required this.petName,
    required this.onFilterChanged,
    required this.onLinkStatusChanged,
    required this.onPartnerUpdated,
    required this.onOpenAgenda,
    required this.onObservacoesChanged,
    required this.actionButtons,
    required this.localizeValue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filterAll = l10n.partnersFilterAll;
    
    final filtered = selectedPartnerFilter == filterAll
        ? allPartners 
        : allPartners.where((p) => localizeValue(p.category) == selectedPartnerFilter).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
      children: [
        // 1. Category Filter Dropdown
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: _buildCategoryDropdown(context),
        ),
        
        const SizedBox(height: 10),

        // 2. Partners List
        if (allPartners.isEmpty)
          _buildEmptyState(l10n.petPartnersNoPartners)
        else if (filtered.isEmpty)
          _buildEmptyState(l10n.petPartnersNotFound, color: Colors.white30)
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final partner = filtered[index];
              final isLinked = linkedPartnerIds.contains(partner.id);
              
              if (isLinked) {
                return LinkedPartnerCard(
                  partner: partner,
                  petId: petId,
                  petName: petName,
                  onUnlink: () => onLinkStatusChanged(partner),
                  onUpdate: onPartnerUpdated,
                  onOpenAgenda: () => onOpenAgenda(partner),
                );
              }

              return Card(
                color: AppDesign.textPrimaryDark.withOpacity(0.05),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.grey.withOpacity(0.1),
                        child: const Icon(Icons.link_off, color: Colors.grey, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(partner.name, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                            Text(localizeValue(partner.category), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ),
                      Switch(
                        value: false,
                        activeColor: AppDesign.petPink,
                        onChanged: (val) {
                          if (val) onLinkStatusChanged(partner);
                        },
                      )
                    ],
                  ),
                ),
              );
            },
          ),

        // 3. Observations Field
        Padding(
          padding: const EdgeInsets.all(16),
          child: CumulativeObservationsField(
            sectionName: l10n.petPartnersObs,
            initialValue: observacoesPrac,
            onChanged: onObservacoesChanged,
            icon: Icons.handshake,
            accentColor: AppDesign.petPink,
          ),
        ),

        // 4. Action Buttons
        actionButtons,

        const SizedBox(height: 100),
      ],
      ),
    );
  }

  Widget _buildEmptyState(String message, {Color color = Colors.white54}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Center(
        child: Text(
          message,
          style: GoogleFonts.poppins(color: color, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    
    final groups = [
      {
        'title': strings.catHeaderHealth,
        'items': [
          strings.catVet,
          strings.catVetEmergency,
          strings.catVetSpecialist,
          strings.catPhysio,
          strings.catHomeo,
          strings.catNutri,
          strings.catAnest,
          strings.catOnco,
          strings.catDentist,
          strings.partnersFilterLab,
          strings.partnersFilterPharmacy,
        ]
      },
      {
        'title': strings.catHeaderDaily,
        'items': [
          strings.catSitter,
          strings.partnersFilterDogWalker,
          strings.catNanny,
          strings.partnersFilterHotel,
          strings.catDaycare,
        ]
      },
      {
        'title': strings.catHeaderGrooming,
        'items': [
          strings.partnersFilterGrooming,
          strings.catStylist,
          strings.catGroomerBreed,
        ]
      },
      {
        'title': strings.catHeaderTraining,
        'items': [
          strings.catTrainer,
          strings.catBehaviorist,
          strings.catCatSultant,
        ]
      },
      {
        'title': strings.catHeaderRetail,
        'items': [
          strings.catPetShop,
          strings.partnersFilterPetShop,
          strings.catSupplies,
          strings.catTransport,
        ]
      },
      {
        'title': strings.catHeaderOther,
        'items': [
          strings.catNgo,
          strings.catBreeder,
          strings.catInsurance,
          strings.catFuneralPlan,
          strings.catCemeterie,
          strings.catCremation,
          strings.catFuneral,
        ]
      }
    ];

    final List<DropdownMenuItem<String>> menuItems = [];
    
    // Add "All" option first
    menuItems.add(DropdownMenuItem<String>(
      value: strings.partnersFilterAll,
      child: Text(
        strings.partnersFilterAll,
        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    ));

    // Add grouped categories
    for (var g in groups) {
      final title = g['title'] as String;
      final items = g['items'] as List<String>;

      // Header (non-selectable)
      menuItems.add(DropdownMenuItem<String>(
        value: "HEADER_$title",
        enabled: false,
        child: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppDesign.petPink,
            fontSize: 13,
          ),
        ),
      ));

      // Category items
      for (var item in items) {
        menuItems.add(DropdownMenuItem<String>(
          value: item,
          child: Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Text(item, style: GoogleFonts.poppins(fontSize: 14)),
          ),
        ));
      }
    }

    return DropdownButtonFormField<String>(
      value: selectedPartnerFilter,
      dropdownColor: AppDesign.surfaceDark,
      isExpanded: true,
      style: const TextStyle(color: AppDesign.textPrimaryDark),
      decoration: InputDecoration(
        labelText: strings.partnersCategory,
        labelStyle: const TextStyle(color: AppDesign.textSecondaryDark),
        prefixIcon: const Icon(Icons.filter_list, color: AppDesign.petPink),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: menuItems,
      onChanged: (v) {
        if (v != null && !v.startsWith("HEADER_")) {
          onFilterChanged(v);
        }
      },
    );
  }
}
