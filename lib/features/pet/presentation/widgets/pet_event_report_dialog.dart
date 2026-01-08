import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../../../core/theme/app_design.dart';
import '../../../../l10n/app_localizations.dart';
import '../../services/pet_events_pdf_service.dart';
import '../../../../core/widgets/pdf_preview_screen.dart';

class PetEventReportDialog extends StatefulWidget {
  final String petId;

  const PetEventReportDialog({Key? key, required this.petId}) : super(key: key);

  @override
  State<PetEventReportDialog> createState() => _PetEventReportDialogState();
}

class _PetEventReportDialogState extends State<PetEventReportDialog> {
  String _mode = 'weekly'; // weekly, monthly, custom
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  String _selectedGroup = 'all';
  bool _onlyPdf = true;
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      backgroundColor: AppDesign.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(l10n.petEvent_generateReport, style: const TextStyle(color: Colors.white, fontSize: 18)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mode Selection
            _buildSectionTitle(l10n.petEvent_reportPeriod),
            Wrap(
              spacing: 8,
              children: [
                _buildModeChip('weekly', l10n.petEvent_reportWeekly),
                _buildModeChip('monthly', l10n.petEvent_reportMonthly),
                _buildModeChip('custom', l10n.petEvent_reportCustom),
              ],
            ),
            const SizedBox(height: 20),

            // Date Pickers
            if (_mode == 'custom') ...[
              Row(
                children: [
                   Expanded(
                     child: _buildDatePicker(
                       label: l10n.petEvent_reportStartDate,
                       date: _startDate,
                       onTap: () => _pickDate(true),
                     ),
                   ),
                   const SizedBox(width: 12),
                   Expanded(
                     child: _buildDatePicker(
                       label: l10n.petEvent_reportEndDate,
                       date: _endDate,
                       onTap: () => _pickDate(false),
                     ),
                   ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Group Filter
            _buildSectionTitle(l10n.petEvent_reportFilterGroup),
            DropdownButtonFormField<String>(
              dropdownColor: AppDesign.surfaceDark,
              value: _selectedGroup,
              items: [
                DropdownMenuItem(value: 'all', child: Text(l10n.commonCategory ?? 'Todas', style: const TextStyle(color: Colors.white70))),
                DropdownMenuItem(value: 'food', child: Text(l10n.petEvent_group_food, style: const TextStyle(color: Colors.white70))),
                DropdownMenuItem(value: 'health', child: Text(l10n.petEvent_group_health, style: const TextStyle(color: Colors.white70))),
                DropdownMenuItem(value: 'elimination', child: Text(l10n.petEvent_group_elimination, style: const TextStyle(color: Colors.white70))),
                DropdownMenuItem(value: 'grooming', child: Text(l10n.petEvent_group_grooming, style: const TextStyle(color: Colors.white70))),
                DropdownMenuItem(value: 'activity', child: Text(l10n.petEvent_group_activity, style: const TextStyle(color: Colors.white70))),
                DropdownMenuItem(value: 'behavior', child: Text(l10n.petEvent_group_behavior, style: const TextStyle(color: Colors.white70))),
                DropdownMenuItem(value: 'schedule', child: Text(l10n.petEvent_group_schedule, style: const TextStyle(color: Colors.white70))),
                DropdownMenuItem(value: 'media', child: Text(l10n.petEvent_group_media, style: const TextStyle(color: Colors.white70))),
                DropdownMenuItem(value: 'metrics', child: Text(l10n.petEvent_group_metrics, style: const TextStyle(color: Colors.white70))),
              ],
              onChanged: (val) => setState(() => _selectedGroup = val!),
              decoration: _inputDecoration(),
            ),
            const SizedBox(height: 16),

            // Toggle
            SwitchListTile(
              title: Text(l10n.petEvent_reportIncludesOnlyPdf, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              value: _onlyPdf,
              activeColor: AppDesign.petPink,
              onChanged: (val) => setState(() => _onlyPdf = val),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isGenerating ? null : () => Navigator.pop(context),
          child: Text(l10n.petEvent_cancel, style: const TextStyle(color: Colors.white38)),
        ),
        ElevatedButton(
          onPressed: _isGenerating ? null : _handleGenerate,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppDesign.petPink,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isGenerating 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(l10n.petEvent_generateReport, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildModeChip(String mode, String label) {
    final isSelected = _mode == mode;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() {
            _mode = mode;
            if (mode == 'weekly') {
              _startDate = DateTime.now().subtract(const Duration(days: 7));
              _endDate = DateTime.now();
            } else if (mode == 'monthly') {
               _startDate = DateTime.now().subtract(const Duration(days: 30));
               _endDate = DateTime.now();
            }
          });
        }
      },
      selectedColor: AppDesign.petPink,
      labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white70),
      backgroundColor: Colors.white12,
    );
  }

  Widget _buildDatePicker({required String label, required DateTime date, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: Text(
              DateFormat('dd/MM/yy').format(date),
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(primary: AppDesign.petPink, onPrimary: Colors.black, surface: AppDesign.surfaceDark),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startDate = picked; else _endDate = picked;
      });
    }
  }

  Future<void> _handleGenerate() async {
    final l10n = AppLocalizations.of(context)!;
    
    // Custom limit check
    if (_mode == 'custom' && _endDate.difference(_startDate).inDays > 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Período máximo de 60 dias permitido.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      // 🚀 REDIRECIONAMENTO PARA PDFPREVIEW (PADRÃO SCAN NUT)
      Navigator.pop(context); // Close dialog

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfPreviewScreen(
            title: l10n.petEvent_reportTitle,
            buildPdf: (format) async {
              final bytes = await PetEventsPdfService().buildReportBytes(
                petId: widget.petId,
                start: _startDate,
                end: _endDate,
                groupFilter: _selectedGroup,
                onlyIncludeInPdf: _onlyPdf,
                l10n: l10n,
              );
              return bytes ?? Uint8List(0);
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ PDF_GEN: Error $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(l10n.petEvent_reportError), backgroundColor: AppDesign.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }
}
