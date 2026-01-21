import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../data/models/menu_creation_params.dart';
import '../../data/models/menu_creation_result.dart';
import '../../../core/theme/app_design.dart';
import '../../../l10n/app_localizations.dart';

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
  // Modes: 'weekly', 'monthly', 'custom'
  late String _selectedMode;
  
  late DateTime _startDate;
  late DateTime _endDate; // Only relevant for visual calculation in Weekly/Monthly, editable in Custom
  
  late String _selectedObjective;
  late List<String> _selectedRestrictions;

  @override
  void initState() {
    super.initState();
    
    // Initialize from persisted params or defaults
    _selectedMode = widget.initialSelectedPeriodId ?? 'weekly';
    
    // Validate loaded mode
    if (!['weekly', 'monthly', 'custom'].contains(_selectedMode)) {
      _selectedMode = 'weekly';
    }

    // Initialize Dates
    // If we have a startDate in params, use it. Otherwise Today.
    _startDate = widget.initialParams?.startDate ?? DateTime.now();
    
    // Normalize time to midnight
    _startDate = DateTime(_startDate.year, _startDate.month, _startDate.day);

    // Initialize Duration/End Date based on Mode & Params
    if (_selectedMode == 'custom') {
      final days = widget.initialParams?.customDays ?? 7;
      _endDate = _startDate.add(Duration(days: days - 1));
    } else {
      _updateEndDateBasedOnMode();
    }

    // Initialize Objective
    _selectedObjective = widget.initialParams?.objective ?? 'maintenance';

    // Initialize Restrictions
    _selectedRestrictions = List.from(widget.initialParams?.restrictions ?? widget.userRestrictions);
  }

  void _updateEndDateBasedOnMode() {
    int days = 7;
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
        // Maintain duration if not custom? Or reset?
        // Prompt implies "Start Date" is mandatory.
        // If Custom, and I change Start, End should probably allow user to re-pick, 
        // or shift End to maintain duration. Let's shift to maintain duration for UX niceness.
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
      lastDate: _startDate.add(const Duration(days: 60)), // Max 60 days constraint in picker
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
      // Validate Check max 60 days
      final days = picked.difference(_startDate).inDays + 1;
      if (days > 60) {
        // Show error
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
    // Map objectives to localized strings manually or via l10n if available for these specific keys
    // Assuming simple mapping for now based on prompt.
    // L10n access
    final l10n = AppLocalizations.of(context); // You might need non-null assertion or handling
    
    // Labels
    final modeLabels = {
      'weekly': 'Semanal',
      'monthly': 'Mensal',
      'custom': 'Personalizado',
    };

    final objectiveLabels = {
      'maintenance': 'Manter peso',
      'emagrecimento': 'Emagrecimento',
      'ganho_massa': 'Alimentação equilibrada', // Mapping to 'Equilibrada' per prompt
    };

    // Color Palette
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
          // CABECALHO
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Gerar Cardápio',
                  style: GoogleFonts.poppins(
                    color: colorTextPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Escolha como deseja montar seu cardápio',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: colorTextSecondary,
                    fontSize: 13,
                  ),
                ),
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
                  // BLOCO 1 - MODO
                  _buildSectionTitle('Modo de Geração'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: modeLabels.entries.map((e) {
                        final isSelected = _selectedMode == e.key;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => _onModeChanged(e.key),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? colorAccent.withOpacity(0.2) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: isSelected ? Border.all(color: colorAccent.withOpacity(0.5)) : null,
                              ),
                              child: Text(
                                e.value,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: isSelected ? colorAccent : colorTextSecondary,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  if (_selectedMode == 'weekly')
                    _buildHelperText('Gera 7 dias a partir da data de início.'),
                  if (_selectedMode == 'monthly')
                    _buildHelperText('Gera 30 dias a partir da data de início.'),
                  if (_selectedMode == 'custom')
                    _buildHelperText('Escolha as datas. Máximo de 60 dias.'),
                  
                  const SizedBox(height: 24),

                  // BLOCO 2 - DATAS
                  _buildSectionTitle('Período'),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateInput(
                          label: 'Início',
                          date: _startDate,
                          onTap: _pickStartDate,
                        ),
                      ),
                      if (_selectedMode == 'custom') ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDateInput(
                            label: 'Fim',
                            date: _endDate,
                            onTap: _pickEndDate,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (_selectedMode == 'custom' && _currentDurationDays > 60)
                     Padding(
                       padding: const EdgeInsets.only(top: 8),
                       child: Text(
                         'Período excede 60 dias!',
                         style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 12),
                       ),
                     ),

                  const SizedBox(height: 24),

                  // BLOCO 3 - OBJETIVO
                  _buildSectionTitle('Objetivo Nutricional'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: objectiveLabels.entries.map((e) {
                       final isSelected = _selectedObjective == e.key;
                       return ChoiceChip(
                         label: Text(e.value),
                         selected: isSelected,
                         onSelected: (val) => setState(() => _selectedObjective = e.key),
                         selectedColor: colorAccent.withOpacity(0.2),
                         backgroundColor: colorCard,
                         labelStyle: GoogleFonts.poppins(
                           color: isSelected ? colorAccent : colorTextSecondary,
                           fontSize: 13,
                         ),
                         shape: RoundedRectangleBorder(
                           borderRadius: BorderRadius.circular(20),
                           side: BorderSide(
                             color: isSelected ? colorAccent : Colors.white12,
                           ),
                         ),
                       );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // BLOCO 4 - PREFERENCIAS
                  _buildSectionTitle('Preferências (Opcional)'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Sem lactose', 'Sem glúten', 'Vegetariano'].map((pref) {
                      final isSelected = _selectedRestrictions.contains(pref);
                      return FilterChip(
                        label: Text(pref),
                        selected: isSelected,
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _selectedRestrictions.add(pref);
                            } else {
                              _selectedRestrictions.remove(pref);
                            }
                          });
                        },
                         selectedColor: colorAccent.withOpacity(0.2),
                         backgroundColor: colorCard,
                         labelStyle: GoogleFonts.poppins(
                           color: isSelected ? colorAccent : colorTextSecondary,
                           fontSize: 13,
                         ),
                         shape: RoundedRectangleBorder(
                           borderRadius: BorderRadius.circular(20),
                           side: BorderSide(
                             color: isSelected ? colorAccent : Colors.white12,
                           ),
                         ),
                      );
                    }).toList(),
                  ),
                  _buildHelperText('Se não marcar nada, o cardápio será padrão.'),

                  const SizedBox(height: 24),

                  // BLOCO 5 - RESUMO
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('RESUMO DO PEDIDO', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 10, letterSpacing: 1.0, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(modeLabels[_selectedMode]!, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text('$_currentDurationDays dias', style: GoogleFonts.poppins(color: colorAccent, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${DateFormat('dd/MM', 'pt_BR').format(_startDate)} até ${DateFormat('dd/MM', 'pt_BR').format(_endDate)}',
                          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                         Text(
                          objectiveLabels[_selectedObjective] ?? _selectedObjective,
                          style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                ],
              ),
            ),
          ),

          // ACTION BUTTON
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isValid ? _generate : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorAccent,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.white10,
                  disabledForegroundColor: Colors.white38,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'GERAR CARDÁPIO',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildHelperText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: Colors.white38,
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildDateInput({required String label, required DateTime date, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11)),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: AppDesign.foodOrange),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd/MM/yy').format(date),
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _generate() {
    // Determine Period Type
    // We are using 'custom' + customDays for maximum flexibility as decided
    // But we might want to preserve the semantical 'weekly' / 'monthly' in data if needed
    // The Generator now supports customDays.
    
    // Actually, if we use 'weekly' in periodType, the generator overrides numDays to 7. 
    /// This is fine if duration is 7.
    // However, we want to respect Start Date strictly.
    // The Generator modification I made uses anchorDate = (periodType == 'custom') ? now : _getMonday(now)
    // So if I want to respect strict StartDate (e.g. Wednesday), I MUST use 'custom'.
    
    final params = MenuCreationParams(
      periodType: 'custom', 
      customDays: _currentDurationDays,
      startDate: _startDate,
      objective: _selectedObjective,
      restrictions: _selectedRestrictions,
      mealsPerDay: 4, // Default
      style: widget.initialParams?.style ?? 'simples',
    );

    final result = MenuCreationResult(
      params: params,
      selectedPeriodId: _selectedMode, // Persist 'weekly', 'monthly' or 'custom'
    );

    Navigator.pop(context, result);
  }
}
