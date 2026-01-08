import 'package:flutter/material.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../l10n/app_localizations.dart';

/// Simplified action bar with only 3 essential icons
/// Replaces the cluttered event grid for a cleaner UX
class PetActionBar extends StatelessWidget {
  final String petId;
  final String petName;
  final VoidCallback onAgendaTap;
  final VoidCallback onMenuTap;
  final VoidCallback onEditTap;

  const PetActionBar({
    Key? key,
    required this.petId,
    required this.petName,
    required this.onAgendaTap,
    required this.onMenuTap,
    required this.onEditTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: _buildActionButton(
              context: context,
              icon: Icons.calendar_today,
              label: l10n.petActionAgenda,
              color: Colors.white, // Antes: AppDesign.petPink
              onTap: onAgendaTap,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildActionButton(
              context: context,
              icon: Icons.restaurant_menu,
              label: l10n.petActionMenu,
              color: Colors.white,
              onTap: onMenuTap,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildActionButton(
              context: context,
              icon: Icons.edit,
              label: l10n.petEdit,
              color: Colors.white, // Antes: Colors.grey
              onTap: onEditTap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool hasBackground = false, // Alterado padrão para false
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: hasBackground ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
