import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/services/history_service.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/providers/partner_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameController = TextEditingController();
  final _calorieController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(settingsProvider);
      _nameController.text = settings.userName;
      _calorieController.text = settings.dailyCalorieGoal.toString();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _calorieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Configurações',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        children: [
          // Profile Section
          Text(
            'Perfil',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Name Field
          _buildTextField(
            controller: _nameController,
            label: 'Nome',
            hint: 'Como você gostaria de ser chamado?',
            icon: Icons.person_outline,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setUserName(value);
            },
          ),

          const SizedBox(height: 32),

          // Nutrition Section
          Text(
            'Metas Nutricionais Humanas',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Calorie Goal Field
          _buildTextField(
            controller: _calorieController,
            label: 'Meta Diária de Calorias',
            hint: '2000',
            icon: Icons.local_fire_department,
            keyboardType: TextInputType.number,
            suffix: 'kcal',
            onChanged: (value) {
              final calories = int.tryParse(value);
              if (calories != null && calories > 0 && calories <= 10000) {
                ref.read(settingsProvider.notifier).setDailyCalorieGoal(calories);
              }
            },
          ),

          const SizedBox(height: 16),

          // Calorie Presets
          Text(
            'Presets Comuns',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPresetChip('1500 kcal', 1500),
              _buildPresetChip('1800 kcal', 1800),
              _buildPresetChip('2000 kcal', 2000),
              _buildPresetChip('2200 kcal', 2200),
              _buildPresetChip('2500 kcal', 2500),
              _buildPresetChip('3000 kcal', 3000),
            ],
          ),


          const SizedBox(height: 32),

          // Button Visibility Section
          Text(
            'Visibilidade dos Botões',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          _buildSwitchTile(
            title: 'Botão Comida',
            subtitle: 'Exibir opção de análise de alimentos',
            value: settings.showFoodButton,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setShowFoodButton(value);
              HapticFeedback.selectionClick();
            },
          ),
          const SizedBox(height: 8),
          _buildSwitchTile(
            title: 'Botão Plantas',
            subtitle: 'Exibir opção de análise de plantas',
            value: settings.showPlantButton,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setShowPlantButton(value);
              HapticFeedback.selectionClick();
            },
          ),
          const SizedBox(height: 8),
          _buildSwitchTile(
            title: 'Botão Pets',
            subtitle: 'Exibir opção de análise de pets',
            value: settings.showPetButton,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setShowPetButton(value);
              HapticFeedback.selectionClick();
            },
          ),

          const SizedBox(height: 32),

          // Preferences Section
          Text(
            'Preferências',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Show Tips Toggle
          _buildSwitchTile(
            title: 'Mostrar Dicas',
            subtitle: 'Exibir dicas nutricionais nas análises',
            value: settings.showTips,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setShowTips(value);
              HapticFeedback.selectionClick();
            },
          ),

          const SizedBox(height: 32),

          // Partners Section
          Text(
            'Gestão de Parceiros',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildRadiusSlider(settings.partnerSearchRadius),

          const SizedBox(height: 32),

          // Danger Zone
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.dangerous, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Text(
                      'Zona de Perigo',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDangerButton(
                  'Excluir Histórico de Pets',
                  'Apagar todos os pets salvos permanentemente.',
                  () => _confirmDeleteAction('Pets', () => ref.read(historyServiceProvider).clearAllPets()),
                ),
                const SizedBox(height: 12),
                _buildDangerButton(
                  'Excluir Histórico de Plantas',
                  'Apagar todas as plantas salvas permanentemente.',
                  () => _confirmDeleteAction('Plantas', () => ref.read(historyServiceProvider).clearAllPlants()),
                ),
                const SizedBox(height: 12),
                _buildDangerButton(
                  'Excluir Histórico de Alimentos',
                  'Apagar todos os alimentos salvos permanentemente.',
                  () => _confirmDeleteAction('Alimentos', () => ref.read(historyServiceProvider).clearAllFood()),
                ),
                const SizedBox(height: 12),
                _buildDangerButton(
                  'Limpar Rede de Apoio',
                  'Remover todos os parceiros cadastrados permanentemente.',
                  () => _confirmDeleteAction('Parceiros', () async {
                    final service = ref.read(partnerServiceProvider);
                    await service.init();
                    await service.clearAllPartners();
                  }),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),

          // Reset Button
          OutlinedButton.icon(
            onPressed: () {
              _showResetDialog();
            },
            icon: const Icon(Icons.restore, color: Colors.red),
            label: Text(
              'Restaurar Padrões',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),

          const SizedBox(height: 16),

          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade300),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Suas configurações são salvas automaticamente',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.blue.shade300,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? suffix,
    TextInputType? keyboardType,
    required Function(String) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(color: Colors.white),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: GoogleFonts.poppins(color: Colors.white70),
          hintStyle: GoogleFonts.poppins(color: Colors.white30),
          prefixIcon: Icon(icon, color: Colors.white70),
          suffixText: suffix,
          suffixStyle: GoogleFonts.poppins(color: Colors.white54),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, int calories) {
    final settings = ref.watch(settingsProvider);
    final isSelected = settings.dailyCalorieGoal == calories;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _calorieController.text = calories.toString();
          ref.read(settingsProvider.notifier).setDailyCalorieGoal(calories);
          HapticFeedback.selectionClick();
        }
      },
      labelStyle: GoogleFonts.poppins(
        color: isSelected ? Colors.black : Colors.white70,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      selectedColor: Colors.green,
      checkmarkColor: Colors.black,
      side: BorderSide(
        color: isSelected ? Colors.green : Colors.white.withValues(alpha: 0.2),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.green,
      ),
    );
  }

  Widget _buildRadiusSlider(double currentRadius) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Raio de Busca Padrão',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
              ),
              Text(
                '${currentRadius.toInt()} km',
                style: GoogleFonts.poppins(color: const Color(0xFF00E676), fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Slider(
            value: currentRadius.clamp(1, 20),
            min: 1,
            max: 20,
            divisions: 19,
            activeColor: const Color(0xFF00E676),
            inactiveColor: Colors.white24,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setPartnerSearchRadius(value);
              HapticFeedback.selectionClick();
            },
          ),
          Text(
            'Sugere parceiros próximos ao seu pet baseando-se neste limite.',
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(
          'Restaurar Padrões',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Text(
          'Tem certeza que deseja restaurar todas as configurações para os valores padrão?',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).resetToDefaults();
              _nameController.text = '';
              _calorieController.text = '2000';
              Navigator.pop(context);
              SnackBarHelper.showSuccess(context, 'Configurações restauradas');
            },
            child: Text(
              'Restaurar',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerButton(String text, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.delete_forever, color: Colors.redAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: GoogleFonts.poppins(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.redAccent, size: 16),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAction(String itemType, Future<void> Function() onDelete) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(
          'Confirmar Exclusão',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Tem certeza que deseja apagar permanentemente todo o histórico de $itemType? Essa ação não pode ser desfeita.',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: GoogleFonts.poppins(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await onDelete();
               if (!mounted) return;
              SnackBarHelper.showSuccess(context, 'Histórico de $itemType apagado com sucesso.');
            },
            child: Text('Apagar', style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
