import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/menu_creation_params.dart';
import '../../../l10n/app_localizations.dart';

/// Modal para configurar criação do cardápio
class CreateMenuDialog extends StatefulWidget {
  final List<String> userRestrictions;

  const CreateMenuDialog({
    Key? key,
    this.userRestrictions = const [],
  }) : super(key: key);

  @override
  State<CreateMenuDialog> createState() => _CreateMenuDialogState();
}

class _CreateMenuDialogState extends State<CreateMenuDialog> {
  int _mealsPerDay = 4;
  String _style = 'simples';
  late List<String> _restrictions;
  bool _allowRepetition = true;

  final List<String> _availableRestrictions = [
    'vegetariano',
    'vegano',
    'sem_lactose',
    'sem_gluten',
    'diabetes',
    'hipertensao',
  ];

  @override
  void initState() {
    super.initState();
    _restrictions = List.from(widget.userRestrictions);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      backgroundColor: Colors.grey.shade900,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Text(
                l10n.menuCreationTitle,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.menuCreationSubtitle,
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 24),

              // Número de refeições
              _buildSection(
                l10n.mealsPerDay,
                Row(
                  children: [
                    _buildMealOption(3, l10n),
                    const SizedBox(width: 12),
                    _buildMealOption(4, l10n),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Estilo
              _buildSection(
                l10n.menuStyleTitle,
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildStyleChip('simples', l10n.styleSimple, Icons.restaurant),
                    _buildStyleChip('economico', l10n.styleBudget, Icons.attach_money),
                    _buildStyleChip('rapido', l10n.styleQuick, Icons.speed),
                    _buildStyleChip('saudavel', l10n.styleHealthy, Icons.favorite),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Restrições
              _buildSection(
                l10n.dietaryRestrictions,
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableRestrictions.map((r) {
                    final isSelected = _restrictions.contains(r);
                    return FilterChip(
                      label: Text(_getRestrictionLabel(r, l10n)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _restrictions.add(r);
                          } else {
                            _restrictions.remove(r);
                          }
                        });
                      },
                      selectedColor: const Color(0xFF00E676).withValues(alpha: 0.3),
                      checkmarkColor: const Color(0xFF00E676),
                      labelStyle: GoogleFonts.poppins(
                        color: isSelected ? const Color(0xFF00E676) : Colors.white70,
                        fontSize: 12,
                      ),
                      backgroundColor: Colors.grey.shade800,
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // Repetição
              CheckboxListTile(
                value: _allowRepetition,
                onChanged: (value) => setState(() => _allowRepetition = value ?? true),
                title: Text(
                  l10n.allowRepetition,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                ),
                subtitle: Text(
                  l10n.allowRepetitionSubtitle,
                  style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
                ),
                activeColor: const Color(0xFF00E676),
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 24),

              // Botões
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(l10n.cancel, style: GoogleFonts.poppins()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _createMenu,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E676),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        l10n.createPlanButton,
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildMealOption(int count, AppLocalizations l10n) {
    final isSelected = _mealsPerDay == count;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _mealsPerDay = count),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF00E676).withValues(alpha: 0.2)
                : Colors.grey.shade800,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF00E676) : Colors.white12,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Text(
                '$count',
                style: GoogleFonts.poppins(
                  color: isSelected ? const Color(0xFF00E676) : Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                l10n.mealsUnit,
                style: GoogleFonts.poppins(
                  color: isSelected ? const Color(0xFF00E676) : Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStyleChip(String value, String label, IconData icon) {
    final isSelected = _style == value;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.black : Colors.white70),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _style = value);
      },
      selectedColor: const Color(0xFF00E676),
      backgroundColor: Colors.grey.shade800,
      labelStyle: GoogleFonts.poppins(
        color: isSelected ? Colors.black : Colors.white70,
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  String _getRestrictionLabel(String restriction, AppLocalizations l10n) {
    switch (restriction) {
      case 'vegetariano':
        return l10n.restVegetarian;
      case 'vegano':
        return l10n.restVegan;
      case 'sem_lactose':
        return l10n.restLactoseFree;
      case 'sem_gluten':
        return l10n.restGlutenFree;
      case 'diabetes':
        return l10n.restDiabetes;
      case 'hipertensao':
        return l10n.restHypertension;
      default:
        return restriction;
    }
  }

  void _createMenu() {
    final params = MenuCreationParams(
      mealsPerDay: _mealsPerDay,
      style: _style,
      restrictions: _restrictions,
      allowRepetition: _allowRepetition,
    );
    Navigator.pop(context, params);
  }
}
