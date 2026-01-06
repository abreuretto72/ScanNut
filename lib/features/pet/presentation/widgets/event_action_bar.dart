import 'package:flutter/material.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../l10n/app_localizations.dart';
import '../../models/pet_event_model.dart';
import '../../services/pet_event_repository.dart';
import 'pet_event_bottom_sheet.dart';
import 'package:hive_flutter/hive_flutter.dart';

class EventActionBar extends StatelessWidget {
  final String petId;

  const EventActionBar({
    Key? key,
    required this.petId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final groups = [
      {'id': 'food', 'icon': Icons.restaurant, 'label': l10n.petEvent_group_food},
      {'id': 'health', 'icon': Icons.medical_services, 'label': l10n.petEvent_group_health},
      {'id': 'elimination', 'icon': Icons.opacity, 'label': l10n.petEvent_group_elimination},
      {'id': 'grooming', 'icon': Icons.content_cut, 'label': l10n.petEvent_group_grooming},
      {'id': 'activity', 'icon': Icons.directions_walk, 'label': l10n.petEvent_group_activity},
      {'id': 'behavior', 'icon': Icons.psychology, 'label': l10n.petEvent_group_behavior},
      {'id': 'schedule', 'icon': Icons.event, 'label': l10n.petEvent_group_schedule},
      {'id': 'media', 'icon': Icons.photo_camera, 'label': l10n.petEvent_group_media},
      {'id': 'metrics', 'icon': Icons.straighten, 'label': l10n.petEvent_group_metrics},
    ];

    return ValueListenableBuilder<Box<PetEventModel>>(
      valueListenable: PetEventRepository().listenable,
      builder: (context, box, _) {
        final todayCounts = PetEventRepository().listTodayCountByGroup(petId);

        return SizedBox(
          height: 85,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: groups.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final group = groups[index];
              final count = todayCounts[group['id']] ?? 0;

              return InkWell(
                onTap: () => _openEventSheet(context, group['id'] as String, group['label'] as String),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 70,
                  decoration: BoxDecoration(
                    color: AppDesign.surfaceDark.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppDesign.petPink.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(group['icon'] as IconData, color: AppDesign.petPink, size: 22),
                          ),
                          if (count > 0)
                            Positioned(
                              right: -4,
                              top: -4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                child: Text(
                                  '$count',
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        group['label'] as String,
                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
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
