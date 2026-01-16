import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_design.dart';
import '../../models/meal_plan_request.dart';

/// ANTI-GRAVITY — REPARAÇÃO ESTÉTICA: FILTRO MENU PET (V63)
/// Modal de Filtro de Cardápio com estética Rosa Pastel e Preto.
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
  PetDietType? _selectedDietType;
  PetFoodType _selectedFoodType = PetFoodType.mixed; // Default
  final TextEditingController _otherNoteController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  // Paleta de Cores V63
  static const Color colorPastelPink = Color(0xFFFFD1DC);
  static const Color colorIntensePink = Color(0xFFFF4081);
  static const Color colorDeepPink = Color(0xFFF06292);

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
          data: ThemeData.light().copyWith(
             colorScheme: const ColorScheme.light(
               primary: colorDeepPink,
               onPrimary: Colors.black,
               surface: colorPastelPink,
               onSurface: Colors.black,
             ),
             dialogBackgroundColor: colorPastelPink,
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
    
    if (_selectedDietType == null) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.dietRequiredError), backgroundColor: AppDesign.error));
       return;
    }

    if (_selectedMode == 'custom') {
       if (_endDate == null) return;
       final diff = _endDate!.difference(_startDate).inDays;
       if (diff < 0) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.petMenuDateRangeError), backgroundColor: AppDesign.error));
         return;
       }
    }

    Navigator.pop(context, {
      'mode': _selectedMode,
      'startDate': _startDate,
      'endDate': _endDate,
      'endDate': _endDate,
      'dietType': _selectedDietType,
      'foodType': _selectedFoodType,
      'otherNote': _otherNoteController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // 🛡️ V71: MATERIAL ANCESTOR FIX
    // Wrap content in Material to prevent "No Material widget found" error
    return Material(
      type: MaterialType.transparency,
      child: Container(
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
                  const Icon(Icons.restaurant_menu, color: Colors.black, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.petMenuFilterTitle,
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
              const SizedBox(height: 24),

              Flexible(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      // DIET SECTION
                      _buildSectionTitle(l10n.dietTypeLabel.toUpperCase()),
                      const SizedBox(height: 12),
                      _buildDietDropdown(l10n),
                      
                      const SizedBox(height: 12),
                      _buildSectionTitle('TIPO DE ALIMENTO'), // TODO: Localize
                       const SizedBox(height: 8),
                      _buildFoodTypeDropdown(l10n),

                      if (_selectedDietType == PetDietType.other) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _otherNoteController,
                          maxLength: 60,
                          style: GoogleFonts.poppins(color: Colors.black),
                          decoration: InputDecoration(
                            hintText: l10n.dietOtherHint,
                            hintStyle: const TextStyle(color: Colors.black38),
                            filled: true,
                            fillColor: Colors.black.withOpacity(0.05),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          validator: (val) => (val == null || val.trim().isEmpty) ? l10n.dietOtherRequiredError : null,
                        ),
                      ],

                      const SizedBox(height: 24),
                      const Divider(color: Colors.black12),
                      const SizedBox(height: 16),

                      // MODE SECTION
                      _buildSectionTitle(l10n.petMenuModeWeekly.toUpperCase()),
                      const SizedBox(height: 8),
                      _buildRadioOption(l10n.petMenuModeWeekly, 'weekly'),
                      _buildRadioOption(l10n.petMenuModeMonthly, 'monthly'),
                      _buildRadioOption(l10n.petMenuModeCustom, 'custom'),

                      const SizedBox(height: 24),

                      // Date Selection
                      _buildSectionTitle(l10n.petMenuStartDate),
                      const SizedBox(height: 8),
                      _buildDateTrigger(_startDate, true),

                      const SizedBox(height: 16),

                      _buildSectionTitle(l10n.petMenuEndDate),
                      const SizedBox(height: 8),
                      _buildDateTrigger(_endDate!, false, enabled: _selectedMode == 'custom'),

                      const SizedBox(height: 16),
                      if (_endDate != null)
                        Text(
                          '${(_endDate!.difference(_startDate).inDays + 1)} dias selecionados',
                          style: GoogleFonts.poppins(color: colorDeepPink, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ACTION BUTTONS
            ElevatedButton(
              onPressed: _generate,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorDeepPink,
                foregroundColor: Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l10n.petMenuGenerateBtn.toUpperCase(),
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
    ); // V71: Close Material widget
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: Colors.black87,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDietDropdown(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<PetDietType>(
          value: _selectedDietType,
          dropdownColor: colorPastelPink,
          isExpanded: true,
          decoration: const InputDecoration(border: InputBorder.none),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
          items: PetDietType.values.map((diet) {
            return DropdownMenuItem(
              value: diet,
              child: Text(
                diet.localizedLabel(l10n),
                style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600),
              ),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedDietType = val;
              if (val != PetDietType.other) _otherNoteController.clear();
            });
          },
          validator: (val) => val == null ? l10n.dietRequiredError : null,
        ),
      ),
    );
  }

  Widget _buildFoodTypeDropdown(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<PetFoodType>(
          value: _selectedFoodType,
          dropdownColor: colorPastelPink,
          isExpanded: true,
          decoration: const InputDecoration(border: InputBorder.none),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
          items: PetFoodType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(
                type.localizedLabel(l10n),
                style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600),
              ),
            );
          }).toList(),
          onChanged: (val) {
             if (val != null) setState(() => _selectedFoodType = val);
          },
        ),
      ),
    );
  }

  Widget _buildRadioOption(String label, String value) {
    return RadioListTile<String>(
      title: Text(label, style: GoogleFonts.poppins(color: Colors.black, fontSize: 14, fontWeight: _selectedMode == value ? FontWeight.bold : FontWeight.normal)),
      value: value,
      groupValue: _selectedMode,
      activeColor: colorIntensePink,
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: enabled ? Colors.black.withOpacity(0.05) : Colors.black.withOpacity(0.02),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: enabled ? Colors.black.withOpacity(0.1) : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: enabled ? colorDeepPink : Colors.black26, size: 20),
            const SizedBox(width: 12),
            Text(
              dateFormat.format(date),
              style: GoogleFonts.poppins(
                color: enabled ? Colors.black : Colors.black26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
