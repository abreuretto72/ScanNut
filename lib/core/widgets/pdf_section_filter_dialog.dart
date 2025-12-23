import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Dialog for selecting which sections to include in the PDF export
class PdfSectionFilterDialog extends StatefulWidget {
  const PdfSectionFilterDialog({Key? key}) : super(key: key);

  @override
  State<PdfSectionFilterDialog> createState() => _PdfSectionFilterDialogState();
}

class _PdfSectionFilterDialogState extends State<PdfSectionFilterDialog> {
  final Map<String, bool> _selectedSections = {
    'identity': true,
    'health': true,
    'nutrition': true,
    'gallery': false,
    'parc': false,
  };

  final Map<String, String> _sectionLabels = {
    'identity': '🐾 Identidade',
    'health': '💉 Saúde',
    'nutrition': '🍖 Nutrição',
    'gallery': '📸 Galeria',
    'parc': '🤝 Parceiros',
  };

  final Map<String, String> _sectionDescriptions = {
    'identity': 'Informações básicas e perfil biológico',
    'health': 'Histórico de vacinas, peso e exames',
    'nutrition': 'Plano alimentar semanal e preferências',
    'gallery': 'Fotos e documentos anexados',
    'parc': 'Rede de apoio e parceiros vinculados',
  };

  bool get _hasSelection => _selectedSections.values.any((selected) => selected);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00E676).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.picture_as_pdf,
              color: Color(0xFF00E676),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Filtrar Seções do PDF',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selecione as seções que deseja incluir no relatório:',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            ..._selectedSections.keys.map((section) {
              return _buildSectionCheckbox(
                section: section,
                label: _sectionLabels[section]!,
                description: _sectionDescriptions[section]!,
                value: _selectedSections[section]!,
                onChanged: (value) {
                  setState(() {
                    _selectedSections[section] = value ?? false;
                  });
                },
              );
            }).toList(),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'O relatório incluirá apenas as seções selecionadas',
                      style: GoogleFonts.poppins(
                        color: Colors.blue[200],
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancelar',
            style: GoogleFonts.poppins(color: Colors.white54),
          ),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _selectedSections.updateAll((key, value) => true);
            });
          },
          child: Text(
            'Selecionar Tudo',
            style: GoogleFonts.poppins(color: const Color(0xFF00E676)),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00E676),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: _hasSelection
              ? () => Navigator.pop(context, _selectedSections)
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check, size: 18),
              const SizedBox(width: 4),
              Text(
                'Gerar PDF',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCheckbox({
    required String section,
    required String label,
    required String description,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: value
            ? const Color(0xFF00E676).withOpacity(0.1)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? const Color(0xFF00E676).withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF00E676),
        checkColor: Colors.black,
        title: Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            fontWeight: value ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          description,
          style: GoogleFonts.poppins(
            color: Colors.white60,
            fontSize: 11,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
}
