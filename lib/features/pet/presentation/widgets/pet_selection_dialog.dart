import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_design.dart';

/// Dialog for selecting a pet from registered pets or creating a new analysis
class PetSelectionDialog extends StatelessWidget {
  final List<Map<String, String>> registeredPets; // List of {id: uuid, name: petName}

  const PetSelectionDialog({
    super.key,
    required this.registeredPets,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
          maxWidth: 400,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A), // Fundo escuro
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.pets,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.petSelectionTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Pet List
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // NOVO option at the top
                  _buildPetOption(
                    context: context,
                    petName: '<NOVO>',
                    displayName: l10n.petNew,
                    isNew: true,
                  ),
                  
                  if (registeredPets.isNotEmpty)
                    Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                  
                  // Registered pets
                  ...registeredPets.map((pet) => _buildPetOption(
                    context: context,
                    petName: pet['name'] ?? 'Pet',
                    petId: pet['id'] ?? '',
                    isNew: false,
                  )),
                ],
              ),
            ),
            
            // Cancel button
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: Text(
                  l10n.cancel,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetOption({
    required BuildContext context,
    required String petName,
    String? petId,
    String? displayName,
    required bool isNew,
  }) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(isNew ? '<NOVO>' : petId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withOpacity(0.1),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isNew 
                    ? AppDesign.petPink.withOpacity(0.2)
                    : Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isNew 
                      ? AppDesign.petPink
                      : Colors.blue.shade400,
                  width: 1.5,
                ),
              ),
              child: Icon(
                isNew ? Icons.add_circle_outline : Icons.pets,
                color: isNew 
                    ? AppDesign.petPink
                    : Colors.blue.shade300,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName ?? petName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: isNew ? FontWeight.w600 : FontWeight.w500,
                      color: Colors.white, // TEXTO BRANCO
                    ),
                  ),
                  if (isNew)
                    Text(
                      AppLocalizations.of(context)!.petQuickAnalysis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white60, // Subtítulo em branco translúcido
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.white30,
            ),
          ],
        ),
      ),
    );
  }
}
