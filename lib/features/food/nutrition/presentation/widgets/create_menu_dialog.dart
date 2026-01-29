import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../data/models/menu_creation_params.dart';
import '../../data/models/menu_creation_result.dart';
import 'package:scannut/core/theme/app_design.dart';
import 'package:scannut/l10n/app_localizations.dart';

class CreateMenuDialog extends StatefulWidget {
  final List<String> userRestrictions;
  final MenuCreationParams? initialParams;
  final String? initialSelectedPeriodId;

  const CreateMenuDialog({
    super.key,
    this.userRestrictions = const [],
    this.initialParams,
    this.initialSelectedPeriodId,
  });

  @override
  State<CreateMenuDialog> createState() => _CreateMenuDialogState();
}

class _CreateMenuDialogState extends State<CreateMenuDialog> {
  // UI State
  // Modes: 'weekly', 'biweekly', 'monthly', 'custom'
  late String _selectedMode;

  late DateTime _startDate;
  late DateTime _endDate; 

  late String _selectedObjective;
  late List<String> _selectedRestrictions;

  @override
  void initState() {
    super.initState();

    // 1. Initialize Start Date (Persisted or Today)
    _startDate = DateTime.now();
    if (widget.initialParams != null && widget.initialParams!.startDate != null) {
       _startDate = widget.initialParams!.startDate!;
    }
    _startDate = DateTime(_startDate.year, _startDate.month, _startDate.day);

    // 2. Resolve Mode from Input ID
    final inputId = widget.initialSelectedPeriodId;
    
    if (inputId == 'biweekly') {
       _selectedMode = 'biweekly';
    } else if (inputId == 'monthly' || inputId == 'month') {
       _selectedMode = 'monthly';
    } else if (inputId == 'custom') {
       _selectedMode = 'custom';
    } else {
       // 'weekly', 'this_week', 'next_week' -> Default to Weekly
       _selectedMode = 'weekly';
    }

    // 3. Normalize Mode
    if (!['weekly', 'biweekly', 'monthly', 'custom'].contains(_selectedMode)) {
      _selectedMode = 'weekly';
    }

    // 4. Initialize Duration/End Date
    if (_selectedMode == 'custom') {
      final days = widget.initialParams?.customDays ?? 7;
      _endDate = _startDate.add(Duration(days: days - 1));
    } else {
      _updateEndDateBasedOnMode();
    }

    // 5. Initialize Objective & Restrictions
    _selectedObjective = widget.initialParams?.objective ?? 'maintenance';
    _selectedRestrictions = List.from(widget.initialParams?.restrictions ?? widget.userRestrictions);
  }

  void _updateEndDateBasedOnMode() {
    int days = 7;
    if (_selectedMode == 'biweekly') days = 15;
    if (_selectedMode == 'monthly') days = 30;

    setState(() {
      _endDate = _startDate.add(Duration(days: days - 1));
    });
  }

  void _onModeChanged(String mode) {
    setState(() {
      _selectedMode = mode;
      _updateEndDateBasedOnMode();
    });
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppDesign.foodOrange,
              onPrimary: AppDesign.surfaceDark,
              surface: AppDesign.surfaceDark,
              onSurface: AppDesign.textPrimaryDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        final duration = _endDate.difference(_startDate).inDays;
        _startDate = picked;
        
        if (_selectedMode == 'custom') {
          _endDate = _startDate.add(Duration(days: duration));
        } else {
          _updateEndDateBasedOnMode();
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: _startDate.add(const Duration(days: 60)), 
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppDesign.foodOrange,
              onPrimary: AppDesign.surfaceDark,
              surface: AppDesign.surfaceDark,
              onSurface: AppDesign.textPrimaryDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final days = picked.difference(_startDate).inDays + 1;
      if (days > 60) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Período máximo: 60 dias')));
        return;
      }
      setState(() {
        _endDate = picked;
      });
    }
  }

  int get _currentDurationDays => _endDate.difference(_startDate).inDays + 1;

  bool get _isValid {
    if (_currentDurationDays <= 0) return false;
    if (_selectedMode == 'custom' && _currentDurationDays > 60) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context); // Safe to assume non-null in build

    // Manual Labels to ensure consistency with User Request
    final modeLabels = {
      'weekly': 'Semana',
      'biweekly': 'Quinzena',
      'monthly': 'Mês',
      'custom': 'Personalizado',
    };

    final objectiveLabels = {
      'maintenance': 'Manter peso',
      'emagrecimento': 'Emagrecimento',
      'ganho_massa': 'Alimentação equilibrada',
    };

    const colorBg = AppDesign.surfaceDark;
    const colorCard = Color(0xFF1E1E1E);
    const colorTextPrimary = Colors.white;
    const colorTextSecondary = Colors.grey;
    const colorAccent = AppDesign.foodOrange;

    return Dialog(
      backgroundColor: colorBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text('Gerar Cardápio', style: GoogleFonts.poppins(color: colorTextPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Escolha o período e data de início', textAlign: TextAlign.center, style: GoogleFonts.poppins(color: colorTextSecondary, fontSize: 13)),
              ],
            ),
          ),

          const Divider(height: 1, color: Colors.white10),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // MODE
                  _buildSectionTitle('Período'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: modeLabels.entries.map((e) {
                         final isSelected = _selectedMode == e.key;
                         // Adjust layout: custom might need scrolling if too wide? 
                         // With 4 items, flex might be tight. Let's try flexible.
                         return Expanded(
                           child: GestureDetector(
                             onTap: () => _onModeChanged(e.key),
                             child: AnimatedContainer(
                               duration: const Duration(milliseconds: 200),
                               padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                               decoration: BoxDecoration(
                                 color: isSelected ? colorAccent.withValues(alpha: 0.2) : Colors.transparent,
                                 borderRadius: BorderRadius.circular(8),
                                 border: isSelected ? Border.all(color: colorAccent.withValues(alpha: 0.5)) : null,
                               ),
                               child: Text(e.value, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.clip,
                                  style: GoogleFonts.poppins(
                                    color: isSelected ? colorAccent : colorTextSecondary,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    fontSize: 11, // Smaller font for 4 items
                                  )),
                             ),
                           ),
                         );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_selectedMode == 'weekly') _buildHelperText('Gera 7 dias (Semanal).'),
                  if (_selectedMode == 'biweekly') _buildHelperText('Gera 15 dias (Quinzena).'),
                  if (_selectedMode == 'monthly') _buildHelperText('Gera 30 dias (Mensal).'),
                  if (_selectedMode == 'custom') _buildHelperText('Escolha as datas livremente.'),

                  const SizedBox(height: 24),

                  // DATES
                  _buildSectionTitle('Data de Início'), // Renamed from 'Período' to prioritize Start Date concept
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateInput(
                          label: 'Iniciar em:',
                          date: _startDate,
                          onTap: _pickStartDate,
                        ),
                      ),
                      if (_selectedMode == 'custom') ...[
                        const SizedBox(width: 12),
                        Expanded(child: _buildDateInput(label: 'Terminar em:', date: _endDate, onTap: _pickEndDate)),
                      ],
                    ],
                  ),
                   if (_selectedMode != 'custom')
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                         child: Text(
                          'Termina em: ${DateFormat('dd/MM/yy').format(_endDate)} ($_currentDurationDays dias)',
                          style: GoogleFonts.poppins(color: Colors.white30, fontSize: 11),
                        ),
                      ),

                  const SizedBox(height: 24),

                  // OBJECTIVE
                  _buildSectionTitle('Objetivo Nutricional'),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: objectiveLabels.entries.map((e) {
                      final isSelected = _selectedObjective == e.key;
                      return ChoiceChip(
                        label: Text(e.value),
                        selected: isSelected,
                        onSelected: (val) => setState(() => _selectedObjective = e.key),
                        selectedColor: colorAccent.withValues(alpha: 0.2),
                        backgroundColor: colorCard,
                        labelStyle: GoogleFonts.poppins(color: isSelected ? colorAccent : colorTextSecondary, fontSize: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? colorAccent : Colors.white12)),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // RESTRICTIONS
                  _buildSectionTitle('Preferências (Opcional)'),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: ['Sem lactose', 'Sem glúten', 'Vegetariano'].map((pref) {
                      final isSelected = _selectedRestrictions.contains(pref);
                      return FilterChip(
                        label: Text(pref),
                        selected: isSelected,
                        onSelected: (val) {
                          setState(() { if (val) _selectedRestrictions.add(pref); else _selectedRestrictions.remove(pref); });
                        },
                        selectedColor: colorAccent.withValues(alpha: 0.2),
                        backgroundColor: colorCard,
                        labelStyle: GoogleFonts.poppins(color: isSelected ? colorAccent : colorTextSecondary, fontSize: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? colorAccent : Colors.white12)),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // SUMMARY
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: colorCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('RESUMO', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 10, letterSpacing: 1.0, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(modeLabels[_selectedMode]!, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text('$_currentDurationDays dias', style: GoogleFonts.poppins(color: colorAccent, fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 4),
                      Text('${DateFormat('dd/MM', 'pt_BR').format(_startDate)} até ${DateFormat('dd/MM', 'pt_BR').format(_endDate)}', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
                    ]),
                  ),
                ],
              ),
            ),
          ),

          // BUTTON
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _isValid ? _generate : null,
                style: ElevatedButton.styleFrom(backgroundColor: colorAccent, foregroundColor: Colors.black, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text('GERAR CARDÁPIO', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)));
  }

  Widget _buildHelperText(String text) {
    return Padding(padding: const EdgeInsets.only(top: 8), child: Text(text, style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic)));
  }

  Widget _buildDateInput({required String label, required DateTime date, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 2),
          Row(children: [
            const Icon(Icons.calendar_today, size: 14, color: AppDesign.foodOrange),
            const SizedBox(width: 8),
            Text(DateFormat('dd/MM/yy').format(date), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500)),
          ]),
        ]),
      ),
    );
  }

  void _generate() {
    final params = MenuCreationParams(
      periodType: 'custom', // Always custom logic internally now
      customDays: _currentDurationDays,
      startDate: _startDate,
      objective: _selectedObjective,
      restrictions: _selectedRestrictions,
      mealsPerDay: 4,
      style: widget.initialParams?.style ?? 'simples',
    );

    final result = MenuCreationResult(
      params: params,
      selectedPeriodId: _selectedMode, 
    );

    if (!mounted) return;
    Navigator.pop(context, result);
  }
}
