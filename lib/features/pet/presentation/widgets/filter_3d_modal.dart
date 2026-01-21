import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../l10n/app_localizations.dart';
import '../../services/pet_profile_service.dart';

/// ANTI-GRAVITY — REPARAÇÃO ESTÉTICA: FILTRO PDF PET (V63)
/// Modal de Filtro 360° com estética Rosa Pastel e Preto.
class Filter3DModal extends StatefulWidget {
  final String? initialPetName;

  const Filter3DModal({super.key, this.initialPetName});

  @override
  State<Filter3DModal> createState() => _Filter3DModalState();
}

class _Filter3DModalState extends State<Filter3DModal> {
  String? _selectedPet;
  List<String> _petNames = [];
  bool _isLoadingPets = true;

  // Paleta de Cores V63
  static const Color colorPastelPink = Color(0xFFFFD1DC);
  static const Color colorIntensePink = Color(0xFFFF4081);
  static const Color colorDeepPink = Color(0xFFF06292);

  final Map<String, bool> _selectedSections = {
    'identity': true,
    'health': true,
    'nutrition': true,
    'gallery': false,
    'parc': false,
  };

  @override
  void initState() {
    super.initState();
    _selectedPet = widget.initialPetName;
    _loadPets();
  }

  Future<void> _loadPets() async {
    try {
      final service = PetProfileService();
      await service.init();
      final names = await service.getAllPetNames();
      if (mounted) {
        setState(() {
          _petNames = names;
          _isLoadingPets = false;
          // Se o pet inicial não estiver na lista ou for nulo, tenta selecionar o primeiro
          if (_selectedPet == null || !names.contains(_selectedPet)) {
            if (names.isNotEmpty) _selectedPet = names.first;
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPets = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: const BoxDecoration(
        color: colorPastelPink,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.black, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Relatório 360°",
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            Text(
              "Selecione o pet e as seções desejadas para o dossiê completo.",
              style: GoogleFonts.poppins(color: Colors.black87, fontSize: 13),
            ),

            const SizedBox(height: 24),

            // Conteúdo com Scroll para evitar overflow
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // DROPDOWN DE PET (V46 Style)
                    Text(
                      "Pet Selecionado",
                      style: GoogleFonts.poppins(
                        color: Colors.black87,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildPetDropdown(),

                    const SizedBox(height: 24),

                    // SECTIONS
                    Text(
                      "Seções do Documento",
                      style: GoogleFonts.poppins(
                        color: Colors.black87,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    _buildSectionTile(
                      key: 'identity',
                      icon: Icons.pets,
                      label: l10n.sectionIdentity,
                      description: l10n.sectionDescIdentity,
                    ),
                    _buildSectionTile(
                      key: 'health',
                      icon: Icons.medical_services,
                      label: l10n.sectionHealth,
                      description: l10n.sectionDescHealth,
                    ),
                    _buildSectionTile(
                      key: 'nutrition',
                      icon: Icons.restaurant,
                      label: l10n.sectionNutrition,
                      description: l10n.sectionDescNutrition,
                    ),
                    _buildSectionTile(
                      key: 'gallery',
                      icon: Icons.photo_library, // Icon standard
                      label: l10n.sectionGallery,
                      description: l10n.sectionDescGallery,
                    ),
                    _buildSectionTile(
                      key: 'parc',
                      icon: Icons.shutter_speed, // Icon switch
                      label: l10n.sectionPartners,
                      description: l10n.sectionDescPartners,
                    ),
                    
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // BOTÃO DE GERAÇÃO
            ElevatedButton(
              onPressed: _selectedPet == null ? null : _onGenerate,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorDeepPink,
                foregroundColor: Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.picture_as_pdf, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    "GERAR DOSSIÊ 360°",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildPetDropdown() {
    if (_isLoadingPets) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
          ),
        ),
      );
    }

    if (_petNames.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.black54, size: 20),
            const SizedBox(width: 12),
            Text("Nenhum pet cadastrado", style: GoogleFonts.poppins(color: Colors.black54)),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPet,
          isExpanded: true,
          dropdownColor: colorPastelPink,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
          items: _petNames.map((name) {
            return DropdownMenuItem<String>(
              value: name,
              child: Text(
                name,
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            setState(() => _selectedPet = val);
          },
        ),
      ),
    );
  }

  Widget _buildSectionTile({
    required String key,
    required IconData icon,
    required String label,
    required String description,
  }) {
    final bool isSelected = _selectedSections[key] ?? false;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSections[key] = !isSelected;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorIntensePink.withOpacity(0.5) : Colors.black.withOpacity(0.05),
            width: 1.5,
          ),
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? colorIntensePink.withOpacity(0.2) : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: isSelected ? colorIntensePink : Colors.black54, size: 20),
          ),
          title: Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            description,
            style: GoogleFonts.poppins(color: Colors.black54, fontSize: 11),
          ),
          trailing: Checkbox(
            value: isSelected,
            onChanged: (val) {
              setState(() {
                _selectedSections[key] = val ?? false;
              });
            },
            activeColor: colorIntensePink,
            checkColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
      ),
    );
  }

  void _onGenerate() {
    if (_selectedPet == null) return;
    
    final result = {
      'petName': _selectedPet,
      'sections': _selectedSections,
    };
    
    Navigator.pop(context, result);
  }
}
