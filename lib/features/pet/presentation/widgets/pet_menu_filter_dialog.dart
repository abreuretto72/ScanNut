import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_design.dart';

class PetMenuFilterDialog extends StatefulWidget {
  final Map<String, dynamic>? initialConfig;
  
  const PetMenuFilterDialog({
    Key? key, 
    this.initialConfig
  }) : super(key: key);

  @override
  State<PetMenuFilterDialog> createState() => _PetMenuFilterDialogState();
}

class _PetMenuFilterDialogState extends State<PetMenuFilterDialog> {
  String _selectedMode = 'weekly'; // weekly, monthly, custom
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  
  // Diet
  String? _selectedDietKey;
  final TextEditingController _otherNoteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.initialConfig != null) {
      _selectedMode = widget.initialConfig!['mode'] ?? 'weekly';
      if (widget.initialConfig!['startDate'] != null) {
        _startDate = DateTime.parse(widget.initialConfig!['startDate']);
      }
      if (widget.initialConfig!['endDate'] != null) {
        _endDate = DateTime.parse(widget.initialConfig!['endDate']);
      }
    }
    
    // Default EndDate Logic
    _updateEndDate();
  }
  
  @override
  void dispose() {
    _otherNoteController.dispose();
    super.dispose();
  }

  void _updateEndDate() {
    if (_selectedMode == 'weekly') {
      _endDate = _startDate.add(const Duration(days: 6));
    } else if (_selectedMode == 'monthly') {
      _endDate = _startDate.add(const Duration(days: 27)); // 28 days total
    } else {
       // Custom - keep existing or default to +1 week
       if (_endDate == null || _endDate!.isBefore(_startDate)) {
         _endDate = _startDate.add(const Duration(days: 6));
       }
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final firstDate = now.subtract(const Duration(days: 365));
    final lastDate = now.add(const Duration(days: 365));
    
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : (_endDate ?? _startDate),
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
             colorScheme: const ColorScheme.dark(
               primary: AppDesign.petPink,
               onPrimary: Colors.black,
               surface: AppDesign.surfaceDark,
               onSurface: Colors.white,
             ),
             dialogBackgroundColor: AppDesign.surfaceDark,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          _updateEndDate();
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _generate() {
    final l10n = AppLocalizations.of(context)!;
    
    if (!_formKey.currentState!.validate()) return;
    
    // Validate Diet
    if (_selectedDietKey == null) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.dietRequiredError), backgroundColor: AppDesign.error));
       return;
    }

    // Validate Custom Date
    if (_selectedMode == 'custom') {
       if (_endDate == null) return;
       final diff = _endDate!.difference(_startDate).inDays;
       if (diff < 0) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Data final inválida'), backgroundColor: AppDesign.error));
         return;
       }
       if (diff > 60) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.petMenuDateRangeError), backgroundColor: AppDesign.error));
         return;
       }
    }

    Navigator.pop(context, {
      'mode': _selectedMode,
      'startDate': _startDate,
      'endDate': _endDate,
      'dietType': _selectedDietKey,
      'otherNote': _otherNoteController.text.trim(),
    });
  }

  Map<String, String> _getDietOptions(AppLocalizations l10n) => {
    'renal': l10n.dietRenal,
    'hepatic': l10n.dietHepatic,
    'gastrointestinal': l10n.dietGastrointestinal,
    'hypoallergenic': l10n.dietHypoallergenic,
    'obesity': l10n.dietObesity,
    'diabetes': l10n.dietDiabetes,
    'cardiac': l10n.dietCardiac,
    'urinary': l10n.dietUrinary,
    'muscle_gain': l10n.dietMuscleGain,
    'pediatric': l10n.dietPediatric,
    'growth': l10n.dietGrowth,
    'other': l10n.dietOther,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dietOptions = _getDietOptions(l10n);

    return AlertDialog(
      backgroundColor: AppDesign.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        l10n.petMenuFilterTitle,
        style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // DIET SECTION
              Text(l10n.dietTypeLabel.toUpperCase(), style: GoogleFonts.poppins(color: AppDesign.petPink, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              DropdownButtonFormField<String>(
                value: _selectedDietKey,
                dropdownColor: AppDesign.surfaceDark,
                decoration: InputDecoration(
                   filled: true,
                   fillColor: Colors.white.withOpacity(0.05),
                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                   contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: GoogleFonts.poppins(color: Colors.white),
                hint: Text(l10n.dietRequiredError, style: const TextStyle(color: Colors.white54)),
                icon: const Icon(Icons.keyboard_arrow_down, color: AppDesign.petPink),
                items: dietOptions.entries.map((e) {
                  return DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedDietKey = val;
                    if (val != 'other') _otherNoteController.clear();
                  });
                },
                validator: (val) => val == null ? l10n.dietRequiredError : null,
              ),

              if (_selectedDietKey == 'other') ...[
                 const SizedBox(height: 12),
                 TextFormField(
                    controller: _otherNoteController,
                    maxLength: 60,
                    style: GoogleFonts.poppins(color: Colors.white),
                    decoration: InputDecoration(
                       hintText: l10n.dietOtherHint,
                       hintStyle: const TextStyle(color: Colors.white30),
                       filled: true,
                       fillColor: Colors.white.withOpacity(0.05),
                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    validator: (val) {
                       if (val == null || val.trim().isEmpty) return l10n.dietOtherRequiredError;
                       return null;
                    },
                 ),
              ],
              
              const SizedBox(height: 24),
              const Divider(color: Colors.white10),
              const SizedBox(height: 16),

              // MODE SECTION
              Text(l10n.petMenuModeWeekly.toUpperCase(), style: GoogleFonts.poppins(color: AppDesign.petPink, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildRadioOption(l10n.petMenuModeWeekly, 'weekly'),
              _buildRadioOption(l10n.petMenuModeMonthly, 'monthly'),
              _buildRadioOption(l10n.petMenuModeCustom, 'custom'),
              
              const SizedBox(height: 24),
              
              // Date Selection
              Text(l10n.petMenuStartDate, style: GoogleFonts.poppins(color: AppDesign.textSecondaryDark, fontSize: 12)),
              const SizedBox(height: 8),
              _buildDateTrigger(_startDate, true),
              
              const SizedBox(height: 16),
              
              Text(l10n.petMenuEndDate, style: GoogleFonts.poppins(color: AppDesign.textSecondaryDark, fontSize: 12)),
               const SizedBox(height: 8),
              _buildDateTrigger(_endDate!, false, enabled: _selectedMode == 'custom'),

              const SizedBox(height: 8),
              if (_endDate != null)
                 Text(
                   '${(_endDate!.difference(_startDate).inDays + 1)} dias selecionados',
                   style: GoogleFonts.poppins(color: AppDesign.petPink, fontSize: 12, fontWeight: FontWeight.bold),
                 ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel ?? 'Cancelar', style: const TextStyle(color: Colors.white60)),
        ),
        ElevatedButton(
          onPressed: _generate,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppDesign.petPink,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: Text(l10n.petMenuGenerateBtn),
        ),
      ],
    );
  }

  Widget _buildRadioOption(String label, String value) {
    return RadioListTile<String>(
      title: Text(label, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
      value: value,
      groupValue: _selectedMode,
      activeColor: AppDesign.petPink,
      contentPadding: EdgeInsets.zero,
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _selectedMode = val;
            _updateEndDate();
          });
        }
      },
    );
  }

  Widget _buildDateTrigger(DateTime date, bool isStart, {bool enabled = true}) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return InkWell(
      onTap: enabled ? () => _pickDate(isStart) : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: enabled ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: enabled ? Colors.white24 : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: enabled ? AppDesign.petPink : Colors.white24, size: 18),
            const SizedBox(width: 12),
            Text(
              dateFormat.format(date),
              style: GoogleFonts.poppins(
                color: enabled ? Colors.white : Colors.white24,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
