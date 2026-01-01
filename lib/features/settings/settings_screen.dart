import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/services/history_service.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/providers/partner_provider.dart';
import 'widgets/backup_optimize_dialog.dart';
import '../../core/models/user_profile.dart';
import '../../core/services/user_profile_service.dart';
import '../../l10n/app_localizations.dart';
import '../../features/food/services/nutrition_service.dart';
import '../../nutrition/presentation/controllers/nutrition_providers.dart';
import '../../core/providers/vaccine_status_provider.dart';
import '../../core/providers/pet_event_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameController = TextEditingController();
  final _calorieController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final settings = ref.read(settingsProvider);
    _nameController.text = settings.userName;
    _calorieController.text = settings.dailyCalorieGoal.toString();
    
    final profile = await UserProfileService().getProfile();
    if (profile != null) {
      _weightController.text = profile.weight.toString();
      _heightController.text = profile.height.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _calorieController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;

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
          l10n.settingsTitle,
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
            l10n.settingsProfile,
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
            label: l10n.settingsNameLabel,
            hint: l10n.settingsNameHint,
            icon: Icons.person_outline,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setUserName(value);
            },
          ),

          const SizedBox(height: 32),

          // Language Section
          Text(
            l10n.settingsLanguage,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          Container(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
             decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
             ),
             child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                   value: settings.languageCode, // Now protected by provider update
                   dropdownColor: Colors.grey[900],
                   style: GoogleFonts.poppins(color: Colors.white),
                   isExpanded: true,
                   icon: const Icon(Icons.language, color: Color(0xFF00E676)),
                   items: [
                      DropdownMenuItem(value: null, child: Text('Automático (Padrão do Sistema)')),
                      DropdownMenuItem(value: 'en', child: Text('🇺🇸 English')),
                      DropdownMenuItem(value: 'pt_BR', child: Text('🇧🇷 Português (Brasil)')),
                      DropdownMenuItem(value: 'pt_PT', child: Text('🇵🇹 Português (Portugal)')),
                      DropdownMenuItem(value: 'es', child: Text('🇪🇸 Español')),
                   ],
                   onChanged: (val) {
                      ref.read(settingsProvider.notifier).setLanguage(val);
                      // Force App Refresh logic handles automatically via Riverpod and Main.dart
                   },
                ),
             ),
          ),
          
          const SizedBox(height: 32),

          // Weight Unit Section
          Text(
            l10n.settingsWeightUnit,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          Container(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
             decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
             ),
             child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                   value: settings.weightUnit,
                   dropdownColor: Colors.grey[900],
                   style: GoogleFonts.poppins(color: Colors.white),
                   isExpanded: true,
                   icon: const Icon(Icons.scale, color: Color(0xFF00E676)),
                   items: [
                      DropdownMenuItem(value: 'kg', child: Text(l10n.settingsKg)),
                      DropdownMenuItem(value: 'lbs', child: Text(l10n.settingsLbs)),
                   ],
                   onChanged: (val) {
                      if (val != null) {
                        ref.read(settingsProvider.notifier).setWeightUnit(val);
                      }
                   },
                ),
             ),
          ),

          const SizedBox(height: 32),

          // Preferences Section
          Text(
            l10n.settingsPreferences,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Show Tips Toggle
          _buildSwitchTile(
            title: l10n.settingsShowTips,
            subtitle: l10n.settingsShowTipsSubtitle,
            value: settings.showTips,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setShowTips(value);
              HapticFeedback.selectionClick();
            },
          ),

          const SizedBox(height: 32),

          // Partners Section
          Text(
            l10n.settingsPartnerManagement,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildRadiusSlider(settings.partnerSearchRadius),

          const SizedBox(height: 32),

          // Backup & Optimization
          Text(
            l10n.settingsSystemMaintenance,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          ListTile(
            onTap: () {
               showDialog(context: context, builder: (_) => const BackupOptimizeDialog());
            },
            tileColor: Colors.white.withOpacity(0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.security, color: Colors.amber),
            ),
            title: Text(l10n.settingsBackupOptimize, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
            subtitle: Text(l10n.settingsBackupOptimizeSubtitle, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
          ),

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
                      l10n.settingsDangerZone,
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
                  l10n.settingsDeletePets,
                  l10n.settingsDeletePetsSubtitle,
                  () => _confirmDeleteAction('Pets', () async {
                      final petBoxes = ['box_pets_master', 'pet_health_records', 'weekly_meal_plans', 'pet_events', 'vaccine_status'];
                      for(var b in petBoxes) {
                        if (Hive.isBoxOpen(b)) await Hive.box(b).close();
                        await Hive.deleteBoxFromDisk(b);
                      }
                  }),
                ),
                const SizedBox(height: 12),
                _buildDangerButton(
                  l10n.settingsDeletePlants,
                  l10n.settingsDeletePlantsSubtitle,
                  () => _confirmDeleteAction('Plantas', () async {
                      final plantBoxes = ['box_botany_intel', 'box_plants_history'];
                      for(var b in plantBoxes) {
                        if (Hive.isBoxOpen(b)) await Hive.box(b).close();
                        await Hive.deleteBoxFromDisk(b);
                      }
                  }),
                ),
                const SizedBox(height: 12),
                _buildDangerButton(
                  l10n.settingsDeleteFood,
                  l10n.settingsDeleteFoodSubtitle,
                  () => _confirmDeleteAction('Alimentos', () async {
                      // Power delete food related boxes
                      final foodBoxes = ['box_nutrition_human', 'nutrition_weekly_plans', 'meal_log', 'nutrition_shopping_list'];
                      for(var b in foodBoxes) {
                        if (Hive.isBoxOpen(b)) await Hive.box(b).close();
                        await Hive.deleteBoxFromDisk(b);
                      }
                      // Re-init current box if needed for UI, but navigating away is safer.
                      // For simplicity, we just clear and the user will see empty on next visit.
                  }),
                ),
                const SizedBox(height: 12),
                _buildDangerButton(
                  l10n.settingsClearPartners,
                  l10n.settingsClearPartnersSubtitle,
                  () => _confirmDeleteAction('Parceiros', () async {
                    final service = ref.read(partnerServiceProvider);
                    await service.init();
                    await service.clearAllPartners();
                  }),
                ),
                const SizedBox(height: 12),
                _buildDangerButton(
                  l10n.deleteAccount,
                  l10n.menuDeleteAccountSubtitle,
                  () => _confirmDeleteAction('CONTA COMPLETA', () => _performFactoryReset()),
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
              l10n.settingsResetDefaults,
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
                    l10n.settingsAutoSaveInfo,
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
                AppLocalizations.of(context)!.settingsSearchRadius,
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
            value: currentRadius.clamp(1, 100),
            min: 1,
            max: 100,
            divisions: 99,
            activeColor: const Color(0xFF00E676),
            inactiveColor: Colors.white24,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setPartnerSearchRadius(value);
              HapticFeedback.selectionClick();
            },
          ),
          Text(
            AppLocalizations.of(context)!.settingsSearchRadiusSubtitle,
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(
          l10n.settingsResetDialogTitle,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Text(
          l10n.settingsResetDialogContent,
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).resetToDefaults();
              _nameController.text = '';
              _calorieController.text = '2000';
              Navigator.pop(context);
              SnackBarHelper.showSuccess(context, l10n.settingsResetSuccess);
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
    final l10n = AppLocalizations.of(context)!;
    final isNuclear = itemType == 'CONTA COMPLETA';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(
          isNuclear ? l10n.deleteAccountConfirmTitle : l10n.settingsConfirmDeleteTitle,
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          isNuclear 
            ? l10n.deleteAccountConfirmBody 
            : l10n.settingsConfirmDeleteContent(itemType),
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel, style: GoogleFonts.poppins(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await onDelete();
               if (!mounted) return;
              SnackBarHelper.showSuccess(context, l10n.settingsDeleteSuccess(itemType));
            },
            child: Text(l10n.actionDelete, style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _performFactoryReset() async {
    try {
      // 1. Reset SharedPreferences (Settings)
      await ref.read(settingsProvider.notifier).resetToDefaults();
      
      // 2. Hard reset all Hive databases
      await ref.read(historyServiceProvider).hardResetAllDatabases();
      
      // 3. Invalidate Providers to clear RAM cache (Exhaustive)
      final providersToInvalidate = [
        nutritionProfileProvider,
        weeklyPlanHistoryProvider,
        currentWeekPlanProvider,
        mealLogsProvider,
        shoppingListProvider,
        historyServiceProvider,
        settingsProvider,
        vaccineStatusServiceProvider,
        petEventServiceProvider,
        partnerServiceProvider,
      ];

      for (final provider in providersToInvalidate) {
        ref.invalidate(provider as dynamic);
      }
      
      if (!mounted) return;
      
      // 4. Shimmer/Wait for UI
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All data has been successfully deleted.'),
          backgroundColor: Colors.green,
        ),
      );

      // 5. Force navigate to Root (Splash) - This will re-trigger init sequence
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      debugPrint('Error factory reset: $e');
      if (mounted) {
        SnackBarHelper.showError(context, 'Erro ao resetar: $e');
      }
    }
  }

  Future<void> _saveUserProfileOnChange() async {
    final settings = ref.read(settingsProvider);
    final profile = UserProfile(
      userName: settings.userName,
      dailyCalorieGoal: settings.dailyCalorieGoal,
      weight: double.tryParse(_weightController.text) ?? 0.0,
      height: double.tryParse(_heightController.text) ?? 0.0,
      preferences: {
        'showTips': settings.showTips,
        'weightUnit': settings.weightUnit,
      },
    );
    await UserProfileService().saveProfile(profile);
  }
}
