import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scannut/l10n/app_localizations.dart';

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

  bool get _hasSelection => _selectedSections.values.any((selected) => selected);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    final Map<String, String> sectionLabels = {
      'identity': '🐾 ${l10n.sectionIdentity}',
      'health': '💉 ${l10n.sectionHealth}',
      'nutrition': '🍖 ${l10n.sectionNutrition}',
      'gallery': '📸 ${l10n.sectionGallery}',
      'parc': '🤝 ${l10n.sectionPartners}',
    };

    final Map<String, String> sectionDescriptions = {
      'identity': l10n.sectionDescIdentity,
      'health': l10n.sectionDescHealth,
      'nutrition': l10n.sectionDescNutrition,
      'gallery': l10n.sectionDescGallery,
      'parc': l10n.sectionDescPartners,
    };

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
              l10n.pdfFilterTitle,
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
              l10n.pdfFilterSubtitle,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            ..._selectedSections.keys.map((section) {
              return _buildSectionCheckbox(
                section: section,
                label: sectionLabels[section]!,
                description: sectionDescriptions[section]!,
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
                      l10n.pdfFilterDisclaimer,
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
            l10n.btnCancel,
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
            l10n.pdfSelectAll,
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
                l10n.pdfGenerate,
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
