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
        // 1. Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: filterCategories.map((cat) {
              final isSelected = selectedPartnerFilter == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (v) => onFilterChanged(cat),
                  backgroundColor: Colors.white.withOpacity(0.05),
                  selectedColor: AppDesign.petPink,
                  labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white),
                  checkmarkColor: Colors.black,
                ),
              );
            }).toList(),
          ),
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
}
