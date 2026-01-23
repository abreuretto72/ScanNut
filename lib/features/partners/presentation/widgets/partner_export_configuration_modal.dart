import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scannut/core/theme/app_design.dart';
import 'package:scannut/core/models/partner_model.dart';

class PartnerExportConfigurationModal extends StatefulWidget {
  final List<PartnerModel> allPartners;
  final Function(List<PartnerModel>) onGenerate;

  const PartnerExportConfigurationModal({
    super.key,
    required this.allPartners,
    required this.onGenerate,
  });

  @override
  State<PartnerExportConfigurationModal> createState() => _PartnerExportConfigurationModalState();
}

class _PartnerExportConfigurationModalState extends State<PartnerExportConfigurationModal> {
  String _filterMode = 'all'; // 'all', 'veterinario', 'petshop', 'banho', 'farmacia', 'manual'
  final Set<String> _selectedIds = {};

  List<PartnerModel> get _filteredPartners {
    switch (_filterMode) {
      case 'veterinario':
        return widget.allPartners.where((p) => p.category == 'Veterinário').toList();
      case 'petshop':
        return widget.allPartners.where((p) => p.category == 'Pet Shop').toList();
      case 'banho':
        return widget.allPartners.where((p) => p.category == 'Banho e Tosa').toList();
      case 'farmacia':
        return widget.allPartners.where((p) => p.category == 'Farmácias').toList();
      case 'manual':
        return widget.allPartners;
      case 'all':
      default:
        return widget.allPartners;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredPartners;
    final int count = _filterMode == 'manual'
        ? filteredList.where((p) => _selectedIds.contains(p.id)).length
        : filteredList.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Exportar Guia de Parceiros',
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // FILTER OPTIONS
              Text('Filtrar por categoria:', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 10),

              _buildFilterOption('Todos os Parceiros', 'all', Icons.business),
              const SizedBox(height: 8),
              _buildFilterOption('Veterinários', 'veterinario', Icons.local_hospital),
              const SizedBox(height: 8),
              _buildFilterOption('Pet Shops', 'petshop', Icons.shopping_basket),
              const SizedBox(height: 8),
              _buildFilterOption('Banho e Tosa', 'banho', Icons.content_cut),
              const SizedBox(height: 8),
              _buildFilterOption('Farmácias', 'farmacia', Icons.medication),
              const SizedBox(height: 8),
              _buildFilterOption('Seleção Manual', 'manual', Icons.checklist),

              const SizedBox(height: 20),

              // MANUAL SELECTION LIST
              if (_filterMode == 'manual') ...[
                Text('Selecione os parceiros:', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 8),
                Container(
                  height: 200,
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                  child: filteredList.isEmpty
                      ? const Center(child: Text('Nenhum parceiro encontrado.', style: TextStyle(color: Colors.white30)))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const ClampingScrollPhysics(),
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final partner = filteredList[index];
                            final isSelected = _selectedIds.contains(partner.id);
                            return CheckboxListTile(
                              title: Text(partner.name, style: const TextStyle(color: Colors.white, fontSize: 13)),
                              subtitle: Text(partner.category, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                              value: isSelected,
                              activeColor: AppDesign.petPink,
                              checkColor: Colors.black,
                              dense: true,
                              onChanged: (v) {
                                setState(() {
                                  if (v == true) {
                                    _selectedIds.add(partner.id);
                                  } else {
                                    _selectedIds.remove(partner.id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                ),
                const SizedBox(height: 20),
              ],

              ElevatedButton(
                onPressed: count > 0 ? _onGeneratePressed : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppDesign.petPink,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor: Colors.white10,
                ),
                child: Text(
                  'Gerar PDF ($count parceiros)',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: count > 0 ? Colors.black : Colors.white30,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterOption(String label, String value, IconData icon) {
    final isSelected = _filterMode == value;
    return InkWell(
      onTap: () {
        setState(() {
          _filterMode = value;
          if (value == 'manual' && _selectedIds.isEmpty) {
            _selectedIds.addAll(_filteredPartners.map((p) => p.id));
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppDesign.petPink.withValues(alpha: 0.2) : Colors.white10,
          border: Border.all(
            color: isSelected ? AppDesign.petPink : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppDesign.petPink : Colors.white54, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isSelected ? AppDesign.petPink : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onGeneratePressed() {
    List<PartnerModel> finalPartners = _filteredPartners;

    if (_filterMode == 'manual') {
      finalPartners = finalPartners.where((p) => _selectedIds.contains(p.id)).toList();
    }

    Navigator.pop(context);
    widget.onGenerate(finalPartners);
  }
}
