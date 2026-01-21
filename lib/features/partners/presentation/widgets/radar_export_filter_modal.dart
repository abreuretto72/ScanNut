import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scannut/core/theme/app_design.dart';
import 'package:scannut/core/models/partner_model.dart';

class RadarExportFilterModal extends StatefulWidget {
  final List<PartnerModel> currentResults;
  final Function(List<PartnerModel>) onGenerate;

  const RadarExportFilterModal({
    super.key,
    required this.currentResults,
    required this.onGenerate,
  });

  @override
  State<RadarExportFilterModal> createState() => _RadarExportFilterModalState();
}

class _RadarExportFilterModalState extends State<RadarExportFilterModal> {
  String _filterMode = 'nearby';
  final Set<String> _selectedIds = {};

  List<PartnerModel> get _filteredPartners {
    final List<PartnerModel> source = widget.currentResults;
    if (_filterMode == 'active') {
      return source.where((PartnerModel p) {
        final isOpen = p.openingHours['raw'] == 'Aberto Agora' || p.openingHours['plantao24h'] == true;
        return isOpen;
      }).toList();
    }
    return source;
  }

  @override
  Widget build(BuildContext context) {
    final List<PartnerModel> filteredList = _filteredPartners;
    int count = 0;
    if (_filterMode == 'manual') {
      count = filteredList.where((PartnerModel p) => _selectedIds.contains(p.id)).length;
    } else {
      count = filteredList.length;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Exportar Resultados Radar',
                    style: GoogleFonts.poppins(color: AppDesign.petPink, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppDesign.petPink),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildFilterOption('Estabelecimentos Próximos', 'nearby', Icons.location_on_outlined),
            const SizedBox(height: 12),
            _buildFilterOption('Apenas Parceiros Ativos', 'active', Icons.check_circle_outline),
            const SizedBox(height: 12),
            _buildFilterOption('Seleção Manual', 'manual', Icons.checklist_rtl_outlined),
            if (_filterMode == 'manual') ...[
              const SizedBox(height: 20),
              Container(
                height: 180,
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                child: widget.currentResults.isEmpty
                    ? const Center(child: Text('Nenhum resultado.', style: TextStyle(color: Colors.white30)))
                    : ListView.builder(
                        itemCount: widget.currentResults.length,
                        itemBuilder: (context, index) {
                          final p = widget.currentResults[index];
                          final isSelected = _selectedIds.contains(p.id);
                          return CheckboxListTile(
                            title: Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 13)),
                            subtitle: Text(p.category, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                            value: isSelected,
                            activeColor: AppDesign.petPink,
                            checkColor: Colors.black,
                            dense: true,
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  _selectedIds.add(p.id);
                                } else {
                                  _selectedIds.remove(p.id);
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
            ],
            const SizedBox(height: 32),
            BtnPrimaryPink(
              text: 'GERAR RELATÓRIO PDF ($count)',
              onPressed: count > 0 ? _onGeneratePressed : null,
            ),
            const SizedBox(height: 12),
          ],
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
            _selectedIds.addAll(widget.currentResults.map((PartnerModel p) => p.id));
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppDesign.petPink.withOpacity(0.15) : Colors.white10,
          border: Border.all(
            color: isSelected ? AppDesign.petPink : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppDesign.petPink : Colors.white54, size: 24),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.poppins(color: isSelected ? AppDesign.petPink : Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }

  void _onGeneratePressed() {
    List<PartnerModel> finalPartners = _filteredPartners;
    if (_filterMode == 'manual') {
      finalPartners = finalPartners.where((PartnerModel p) => _selectedIds.contains(p.id)).toList();
    }
    Navigator.pop(context);
    widget.onGenerate(finalPartners);
  }
}

class BtnPrimaryPink extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  const BtnPrimaryPink({super.key, required this.text, this.onPressed});
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppDesign.petPink,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        disabledBackgroundColor: Colors.white10,
        elevation: 0,
      ),
      child: Text(text, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }
}
