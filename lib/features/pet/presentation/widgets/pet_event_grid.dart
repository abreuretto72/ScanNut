import 'package:flutter/material.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../l10n/app_localizations.dart';
import '../../models/pet_event_model.dart';
import '../../services/pet_event_repository.dart';
import 'pet_event_bottom_sheet.dart';
import 'package:hive_flutter/hive_flutter.dart';

class PetEventGrid extends StatelessWidget {
  final String petId;

  const PetEventGrid({
    super.key,
    required this.petId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final groups = [
      {'id': 'food', 'icon': Icons.restaurant, 'label': l10n.petEvent_group_food},
      {'id': 'health', 'icon': Icons.medical_services, 'label': l10n.petEvent_group_health},
      {'id': 'elimination', 'icon': Icons.opacity, 'label': l10n.petEvent_group_elimination},
      {'id': 'medication', 'icon': Icons.medication, 'label': l10n.petEvent_group_medication},
      {'id': 'grooming', 'icon': Icons.content_cut, 'label': l10n.petEvent_group_grooming},
      {'id': 'activity', 'icon': Icons.directions_walk, 'label': l10n.petEvent_group_activity},
      {'id': 'behavior', 'icon': Icons.psychology, 'label': l10n.petEvent_group_behavior},
      {'id': 'schedule', 'icon': Icons.event, 'label': l10n.petEvent_group_schedule},
      {'id': 'documents', 'icon': Icons.description, 'label': l10n.petEvent_group_documents},
      {'id': 'exams', 'icon': Icons.biotech, 'label': l10n.petEvent_group_exams},
      {'id': 'allergies', 'icon': Icons.warning_amber, 'label': l10n.petEvent_group_allergies},
      {'id': 'dentistry', 'icon': Icons.health_and_safety, 'label': l10n.petEvent_group_dentistry},
      {'id': 'metrics', 'icon': Icons.straighten, 'label': l10n.petEvent_group_metrics},
      {'id': 'media', 'icon': Icons.photo_library, 'label': l10n.petEvent_group_media},
      {'id': 'other', 'icon': Icons.bookmark_border, 'label': l10n.petEvent_group_other},
    ];

    // Sort alphabetically by label
    groups.sort((a, b) => (a['label'] as String).compareTo(b['label'] as String));

    return ValueListenableBuilder<Box<PetEventModel>>(
      valueListenable: PetEventRepository().listenable,
      builder: (context, box, _) {
        final totalCounts = PetEventRepository().listTotalCountByGroup(petId);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.1,
          ),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            final count = totalCounts[group['id']] ?? 0;

            return InkWell(
              onTap: () => _openEventSheet(context, group['id'] as String, group['label'] as String),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppDesign.surfaceDark.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppDesign.petPink.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(group['icon'] as IconData, color: AppDesign.petPink, size: 24),
                        ),
                        if (count > 0)
                          Positioned(
                            right: -5,
                            top: -5,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(color: AppDesign.petPink, shape: BoxShape.circle),
                              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                              child: Text(
                                '$count',
                                style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      group['label'] as String,
                      style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openEventSheet(BuildContext context, String groupId, String groupLabel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PetEventBottomSheet(
        petId: petId,
        groupId: groupId,
        groupLabel: groupLabel,
      ),
    );
  }
}
