import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Parâmetros para criação do cardápio semanal
class MenuCreationParams {
  final int mealsPerDay;
  final String style; // simples, economico, rapido, saudavel
  final List<String> restrictions;
  final bool allowRepetition;

  MenuCreationParams({
    this.mealsPerDay = 4,
    this.style = 'simples',
    this.restrictions = const [],
    this.allowRepetition = true,
  });

  MenuCreationParams copyWith({
    int? mealsPerDay,
    String? style,
    List<String>? restrictions,
    bool? allowRepetition,
  }) {
    return MenuCreationParams(
      mealsPerDay: mealsPerDay ?? this.mealsPerDay,
      style: style ?? this.style,
      restrictions: restrictions ?? this.restrictions,
      allowRepetition: allowRepetition ?? this.allowRepetition,
    );
  }
}

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
                'Criar Cardápio da Semana',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Configure como você quer seu cardápio',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 24),

              // Número de refeições
              _buildSection(
                'Refeições por dia',
                Row(
                  children: [
                    _buildMealOption(3),
                    const SizedBox(width: 12),
                    _buildMealOption(4),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Estilo
              _buildSection(
                'Estilo do cardápio',
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildStyleChip('simples', 'Simples', Icons.restaurant),
                    _buildStyleChip('economico', 'Econômico', Icons.attach_money),
                    _buildStyleChip('rapido', 'Rápido', Icons.speed),
                    _buildStyleChip('saudavel', 'Saudável', Icons.favorite),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Restrições
              _buildSection(
                'Restrições alimentares',
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableRestrictions.map((r) {
                    final isSelected = _restrictions.contains(r);
                    return FilterChip(
                      label: Text(_getRestrictionLabel(r)),
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
                  'Pode repetir receitas na semana',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                ),
                subtitle: Text(
                  'Se desligado, cada receita aparece apenas 1 vez',
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
                      child: Text('Cancelar', style: GoogleFonts.poppins()),
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
                        'Criar Cardápio',
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

  Widget _buildMealOption(int count) {
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
                'refeições',
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

  String _getRestrictionLabel(String restriction) {
    switch (restriction) {
      case 'vegetariano':
        return 'Vegetariano';
      case 'vegano':
        return 'Vegano';
      case 'sem_lactose':
        return 'Sem Lactose';
      case 'sem_gluten':
        return 'Sem Glúten';
      case 'diabetes':
        return 'Diabetes';
      case 'hipertensao':
        return 'Hipertensão';
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
