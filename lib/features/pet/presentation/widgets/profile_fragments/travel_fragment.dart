import 'package:flutter/material.dart';
import '../../../../../core/theme/app_design.dart';
import '../../../../../l10n/app_localizations.dart';

class TravelFragment extends StatelessWidget {
  final Map<String, dynamic> travelPreferences;
  final Function(String, dynamic) onPreferenceChanged;
  final DateTime? rabiesDate;
  final String? microchip;

  const TravelFragment({
    super.key,
    required this.travelPreferences,
    required this.onPreferenceChanged,
    this.rabiesDate,
    this.microchip,
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
            isRabiesVaxValid ? l10n.petTravelVaccineStatusOk : l10n.petTravelVaccineStatusPending,
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
          
          const SizedBox(height: 24),
          
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
}
