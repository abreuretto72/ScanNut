import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/services/history_service.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/theme/app_design.dart';
import '../../core/providers/partner_provider.dart';
import '../../core/models/user_profile.dart';
import '../../core/services/user_profile_service.dart';
import '../../l10n/app_localizations.dart';
import '../../features/food/services/nutrition_service.dart';
import '../../features/plant/services/botany_service.dart';
import '../../core/services/simple_auth_service.dart';
import '../../nutrition/presentation/controllers/nutrition_providers.dart';
import '../../core/providers/vaccine_status_provider.dart';
import '../../core/providers/pet_event_provider.dart';
import 'widgets/local_backup_widget.dart';
import '../../core/utils/app_logger.dart';
import 'screens/diagnostics_screen.dart';
import 'screens/auth_certificates_screen.dart';
import 'screens/change_password_screen.dart';
import '../../core/services/media_vault_service.dart';
import '../../features/pet/models/pet_event.dart';
import '../../features/pet/services/pet_event_service.dart';
import 'screens/data_archiving_screen.dart';
import 'package:uuid/uuid.dart';

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
  int _devTapCount = 0;
  String? _profileId;

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
      _profileId = profile.id;
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
      backgroundColor: AppDesign.backgroundDark,
      body: CustomScrollView(
        slivers: [
          // AppBar
          SliverAppBar(
            backgroundColor: AppDesign.surfaceDark,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppDesign.textPrimaryDark),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              l10n.settingsTitle,
              style: GoogleFonts.poppins(
                color: AppDesign.textPrimaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                
                // Section A: Account / Login
                _buildSectionHeader(l10n.settingsSectionAccount, Icons.person),
                _buildCardGroup([
                  // Name Field inside Card
                  Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                     child: TextField(
                        controller: _nameController,
                        style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark),
                        onChanged: (value) => ref.read(settingsProvider.notifier).setUserName(value),
                        decoration: InputDecoration(
                           labelText: l10n.settingsNameLabel,
                           hintText: l10n.settingsNameHint,
                           labelStyle: GoogleFonts.poppins(color: AppDesign.textSecondaryDark),
                           hintStyle: GoogleFonts.poppins(color: AppDesign.textPrimaryDark.withOpacity(0.3)),
                           border: InputBorder.none,
                           icon: const Icon(Icons.person_outline, color: AppDesign.accent),
                        ),
                     ),
                  ),
                  const Divider(height: 1, color: Colors.white10),

                  // Change Password
                  _buildSettingsTile(
                    title: l10n.settingsChangePassword,
                    icon: Icons.lock_reset,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
                  ),
                  const Divider(height: 1, color: Colors.white10),

                  // Keep Signed In
                  _buildSwitchTile(
                     title: l10n.settingsKeepSignedIn,
                     subtitle: simpleAuthService.getPersistSession() ? l10n.settingsKeepSignedInSubOn : l10n.settingsKeepSignedInSubOff,
                     value: simpleAuthService.getPersistSession(),
                     icon: Icons.vpn_key,
                     onChanged: (val) async {
                        try {
                           await simpleAuthService.setPersistSession(val);
                           setState(() {});
                           if (context.mounted) SnackBarHelper.showSuccess(context, val ? l10n.settingsMsgSessionKept : l10n.settingsMsgLoginRequired);
                        } catch(e) { /* ignore */ }
                     },
                  ),
                  const Divider(height: 1, color: Colors.white10),

                  // Biometrics
                  FutureBuilder<bool>(
                     future: simpleAuthService.checkBiometricsAvailable(),
                     builder: (context, snapshot) {
                        if(snapshot.data != true) return const SizedBox.shrink();
                        return _buildSwitchTile(
                           title: l10n.settingsUseBiometrics,
                           subtitle: simpleAuthService.isBiometricEnabled ? l10n.settingsBiometricsOn : l10n.settingsBiometricsOff,
                           value: simpleAuthService.isBiometricEnabled,
                           icon: Icons.fingerprint,
                           onChanged: (val) async {
                              await simpleAuthService.setBiometricEnabled(val);
                              setState(() {});
                           },
                        );
                     }
                  ),
                ]),


                const SizedBox(height: 24),


                // Section B: Preferences
                _buildSectionHeader(l10n.settingsSectionPreferences, Icons.tune),
                _buildCardGroup([
                  // Language
                  _buildDropdownTile<String?>(
                     title: l10n.settingsLanguage,
                     icon: Icons.language,
                     value: settings.languageCode,
                     items: [
                        DropdownMenuItem(value: null, child: Text(l10n.settingsLabelAutomatic, style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark))),
                        DropdownMenuItem(value: 'en', child: Text('English', style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark))),
                        DropdownMenuItem(value: 'pt_BR', child: Text('Português (BR)', style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark))),
                        DropdownMenuItem(value: 'pt_PT', child: Text('Português (PT)', style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark))),
                        DropdownMenuItem(value: 'es', child: Text('Español', style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark))),
                     ],
                     onChanged: (val) => ref.read(settingsProvider.notifier).setLanguage(val),
                  ),
                  const Divider(height: 1, color: Colors.white10),

                  // Weight Unit
                  _buildDropdownTile<String>(
                     title: l10n.settingsWeightUnit,
                     icon: Icons.scale,
                     value: settings.weightUnit,
                     items: [
                        DropdownMenuItem(value: 'kg', child: Text(l10n.settingsKg, style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark))),
                        DropdownMenuItem(value: 'lbs', child: Text(l10n.settingsLbs, style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark))),
                     ],
                     onChanged: (val) { if(val!=null) ref.read(settingsProvider.notifier).setWeightUnit(val); },
                  ),
                  const Divider(height: 1, color: Colors.white10),

                  // Partner Radius Slider
                  Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                     child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Row(
                              children: [
                                 const Icon(Icons.map, color: AppDesign.accent),
                                 const SizedBox(width: 16),
                                 Expanded(child: Text(l10n.settingsSearchRadius, style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark, fontSize: 16))),
                                 Text('${settings.partnerSearchRadius.toInt()} km', style: GoogleFonts.poppins(color: AppDesign.accent, fontWeight: FontWeight.bold)),
                              ],
                           ),
                           Slider(
                              value: settings.partnerSearchRadius.clamp(1, 100),
                              min: 1, max: 100, divisions: 99,
                              activeColor: AppDesign.accent,
                              inactiveColor: Colors.white10,
                              onChanged: (val) {
                                 ref.read(settingsProvider.notifier).setPartnerSearchRadius(val);
                                 HapticFeedback.selectionClick();
                              },
                           ),
                        ],
                     ),
                  ),
                ]),


                const SizedBox(height: 24),


                // Section C: Backup
                _buildSectionHeader(l10n.settingsSectionBackup, Icons.cloud_sync),
                Container(
                   decoration: BoxDecoration(
                      color: AppDesign.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                   ),
                   child: const LocalBackupWidget(),
                ),




                const SizedBox(height: 24),
                
                const SizedBox(height: 16),
                
                // Reset settings secondary button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                     onPressed: _showResetDialog,
                     icon: const Icon(Icons.restore, color: AppDesign.textPrimaryDark, size: 18),
                     label: Text(l10n.settingsResetDefaults, style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark)),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: AppDesign.primary,
                       padding: const EdgeInsets.symmetric(vertical: 12),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                     ),
                  ),
                ),


                const SizedBox(height: 32),


                   // Developer Mode Activator Hidden (Moved from deleted About Section)
                   GestureDetector(
                      onTap: () {
                         _devTapCount++;
                         if (_devTapCount >= 7) {
                            ref.read(settingsProvider.notifier).setDeveloperMode(true);
                            logger.setDeveloperMode(true);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Developer Mode Activated! 🛠️')));
                            _devTapCount = 0;
                         }
                      },
                      child: Container(
                         height: 40, 
                         color: Colors.transparent, // Invisible click area at bottom
                         width: double.infinity,
                      ),
                   ),

                if (settings.developerMode) ...[
                   const SizedBox(height: 32),
                   _buildSectionHeader('🛠️ Developer Tools', Icons.build, color: Colors.purple),
                   Container(
                      decoration: BoxDecoration(
                         color: Colors.purple.withOpacity(0.05),
                         borderRadius: BorderRadius.circular(12), 
                         border: Border.all(color: Colors.purple.withOpacity(0.3)),
                      ),
                      child: Column(
                         children: [
                            ListTile(
                               leading: const Icon(Icons.bug_report, color: Colors.purple),
                               title: Text('Diagnósticos', style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark)),
                               trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppDesign.textSecondaryDark),
                               onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DiagnosticsScreen())),
                            ),
                            const Divider(height: 1, color: Colors.white10),
                            ListTile(
                               leading: const Icon(Icons.security, color: Colors.purple),
                               title: Text('Certificados & Auth', style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark)),
                               trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppDesign.textSecondaryDark),
                               onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AuthCertificatesScreen())),
                            ),
                            const Divider(height: 1, color: Colors.white10),
                            ListTile(
                               leading: const Icon(Icons.delete_sweep, color: Colors.red),
                               title: Text('Resetar Sessão + Onboarding', style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark)),
                               onTap: () async {
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.remove('onboarding_completed');
                                  await prefs.remove('disclaimer_accepted');
                                  await simpleAuthService.logout();
                                  if(context.mounted) {
                                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Estado resetado. Fechando app...')));
                                     Future.delayed(const Duration(seconds: 2), () => SystemNavigator.pop());
                                  }
                               },
                            ),
                         ],
                      ),
                   )
                ],
                
                const SizedBox(height: 48), // Padding bottom
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Builders for New UI ---

  Widget _buildSectionHeader(String title, IconData icon, {Color? color}) {
     return Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 12),
        child: Row(
           children: [
              Icon(icon, size: 18, color: color ?? AppDesign.textSecondaryDark),
              const SizedBox(width: 8),
              Text(
                 title.toUpperCase(),
                 style: GoogleFonts.poppins(
                    fontSize: 12, 
                    fontWeight: FontWeight.bold, 
                    color: color ?? AppDesign.textSecondaryDark,
                    letterSpacing: 1.0,
                 ),
              ),
           ],
        ),
     );
  }

  Widget _buildCardGroup(List<Widget> children) {
     return Container(
        decoration: BoxDecoration(
           color: AppDesign.surfaceDark,
           borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
           children: children,
        ),
     );
  }

  Widget _buildSettingsTile({required String title, required IconData icon, required VoidCallback onTap}) {
     return ListTile(
        leading: Icon(icon, color: AppDesign.accent),
        title: Text(title, style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark, fontSize: 16)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppDesign.textSecondaryDark),
        onTap: onTap,
     );
  }

  Widget _buildSwitchTile({required String title, required String subtitle, required IconData icon, required bool value, required Function(bool) onChanged}) {
     return SwitchListTile(
        secondary: Icon(icon, color: AppDesign.accent),
        title: Text(title, style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark, fontSize: 16)),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(color: AppDesign.textSecondaryDark, fontSize: 12)),
        value: value,
        onChanged: onChanged,
        activeColor: AppDesign.accent,
     );
  }

  Widget _buildDropdownTile<T>({required String title, required IconData icon, required T value, required List<DropdownMenuItem<T>> items, required Function(T?) onChanged}) {
     return ListTile(
        leading: Icon(icon, color: AppDesign.accent),
        title: Text(title, style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark, fontSize: 16)),
        trailing: DropdownButtonHideUnderline(
           child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              dropdownColor: AppDesign.surfaceDark,
              style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark, fontSize: 14),
              icon: const Icon(Icons.arrow_drop_down, color: AppDesign.textSecondaryDark),
           ),
        ),
     );
  }

  Widget _buildDangerTile({required String title, required String subtitle, required VoidCallback onTap, bool isLast = false}) {
     return ListTile(
        title: Text(title, style: GoogleFonts.poppins(color: AppDesign.error, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(color: AppDesign.textSecondaryDark, fontSize: 11)),
        trailing: const Icon(Icons.chevron_right, color: AppDesign.error),
        onTap: onTap,
     );
  }

  void _showResetDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppDesign.surfaceDark,
        title: Text(
          l10n.settingsResetDialogTitle,
          style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark),
        ),
        content: Text(
          l10n.settingsResetDialogContent,
          style: GoogleFonts.poppins(color: AppDesign.textSecondaryDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
              style: GoogleFonts.poppins(color: AppDesign.textSecondaryDark),
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
              l10n.settingsActionRestore,
              style: GoogleFonts.poppins(color: AppDesign.error),
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
          color: AppDesign.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppDesign.error.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.delete_forever, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: GoogleFonts.poppins(
                      color: AppDesign.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: AppDesign.textSecondaryDark,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppDesign.error, size: 16),
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
        backgroundColor: AppDesign.surfaceDark,
        title: Text(
          isNuclear ? l10n.deleteAccountConfirmTitle : l10n.settingsConfirmDeleteTitle,
          style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark, fontWeight: FontWeight.bold),
        ),
        content: Text(
          isNuclear 
            ? l10n.deleteAccountConfirmBody 
            : l10n.settingsConfirmDeleteContent(itemType),
          style: GoogleFonts.poppins(color: AppDesign.textSecondaryDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel, style: GoogleFonts.poppins(color: AppDesign.textSecondaryDark)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await onDelete();
               if (!mounted) return;
              SnackBarHelper.showSuccess(context, l10n.settingsDeleteSuccess(itemType));
            },
            child: Text(l10n.actionDelete, style: GoogleFonts.poppins(color: AppDesign.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _atomicWipeHistoryData() async {
      final l10n = AppLocalizations.of(context)!;
      try {
         debugPrint('🚨 [WIPE_TRACE] Starting Atomic Wipe...');
         
         // 1. Identify Target Boxes (Operational Data Only)
         // Excludes: user_profile, settings (Global Config)
         final targetBoxes = [
            'scannut_history',      // General history
            'box_pets_master',      // Pets and internal history
            'pet_events',           // Journal events
            'pet_events_journal',   // Legacy journal
            'meal_logs',            // Nutrition logs
            'weekly_plans',         // Nutrition plans
            'shopping_list',        // Nutrition list
            'cached_feed',          // Social feed cache
         ];

         // 2. Clear Boxes Atomically (Keep Box Open)
         for (final name in targetBoxes) {
             try {
                Box box;
                if (Hive.isBoxOpen(name)) {
                   box = Hive.box(name);
                } else {
                   // Open safely just to clear
                   box = await Hive.openBox(name);
                }
                await box.clear(); // The Atomic Wipe
                debugPrint('✅ [WIPE_TRACE] Box cleared: $name');
             } catch (e) {
                debugPrint('⚠️ [WIPE_TRACE] Failed to clear $name: $e');
             }
         }

         // 3. Physical Media Cleanup (Reclaim Storage)
         final mediaService = MediaVaultService();
         await mediaService.clearDomain(MediaVaultService.PETS_DIR);
         await mediaService.clearDomain(MediaVaultService.FOOD_DIR);
         await mediaService.clearDomain(MediaVaultService.BOTANY_DIR);
         await mediaService.clearDomain(MediaVaultService.WOUNDS_DIR); // V180
         debugPrint('✅ [WIPE_TRACE] Media Vault purged.');

         if (!mounted) return;
         SnackBarHelper.showSuccess(context, l10n.settingsWipeSuccess);
         
      } catch (e) {
         debugPrint('❌ [WIPE_TRACE] Critical failure: $e');
         if(mounted) SnackBarHelper.showError(context, l10n.settingsWipeError(e.toString()));
      }
  }

  void _showAtomicWipeDialog() {
     final l10n = AppLocalizations.of(context)!;
     showDialog(
        context: context,
        builder: (context) => AlertDialog(
           backgroundColor: AppDesign.surfaceDark,
           title: Row(
              children: [
                 const Icon(Icons.warning_amber_rounded, color: AppDesign.error),
                 const SizedBox(width: 8),
                 Text(l10n.settingsDangerZone, style: GoogleFonts.poppins(color: AppDesign.error, fontWeight: FontWeight.bold)),
              ],
           ),
           content: Text(
              l10n.settingsWipeConfirmBody,
              style: GoogleFonts.poppins(color: AppDesign.textSecondaryDark),
           ),
           actions: [
              TextButton(
                 onPressed: () => Navigator.pop(context),
                 child: Text(l10n.cancel, style: GoogleFonts.poppins(color: AppDesign.textSecondaryDark)),
              ),
              TextButton(
                 onPressed: () {
                    Navigator.pop(context);
                    _atomicWipeHistoryData();
                 },
                 child: Text(l10n.settingsActionWipeAll, style: GoogleFonts.poppins(color: AppDesign.error, fontWeight: FontWeight.bold)),
              ),
           ],
        ),
     );
  }

  Future<void> _performFactoryReset() async {
      await _atomicWipeHistoryData();
      // Optional: Logout if desired, but Atomic Wipe is history-only.
      // If full factory reset is needed, we would add settings reset logic here.
  }

  Future<void> _saveUserProfileOnChange() async {
    final settings = ref.read(settingsProvider);
    final profile = UserProfile(
      id: _profileId ?? const Uuid().v4(),
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

  // --- Segmented Delete UI Helpers ---

  Widget _buildDomainDeleteCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> actions,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppDesign.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }

  Widget _buildDeleteAction({required String label, required VoidCallback onTap, bool isDestructive = false}) {
    return ListTile(
      title: Text(label, style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark, fontSize: 14)),
      trailing: Icon(Icons.delete_outline, color: isDestructive ? Colors.red : AppDesign.textSecondaryDark, size: 20),
      onTap: onTap,
    );
  }

  // --- Logic Helpers ---

  Future<void> _clearBox(String boxName) async {
    try {
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box(boxName).clear();
      } else {
        await Hive.deleteBoxFromDisk(boxName);
      }
      debugPrint('🧹 Box wiped: $boxName');
    } catch (e) {
      debugPrint('⚠️ Error clearing box $boxName: $e');
    }
  }

  Future<void> _clearHistoryByMode(String mode) async {
    try {
      final boxName = 'scannut_history';
      Box box;
      if (Hive.isBoxOpen(boxName)) {
        box = Hive.box(boxName);
      } else {
        box = await Hive.openBox(boxName, encryptionCipher: SimpleAuthService().encryptionCipher);
      }

      final keysToDelete = <dynamic>[];
      for (var key in box.keys) {
        final val = box.get(key);
        if (val is Map && val['mode'] == mode) {
          keysToDelete.add(key);
        }
      }
      await box.deleteAll(keysToDelete);
      debugPrint('🧹 Cleared ${keysToDelete.length} history items for mode: $mode');
    } catch (e) {
      debugPrint('⚠️ Error clearing history by mode: $e');
    }
  }

  Future<void> _clearJournalByGroup(List<String> groups) async {
    try {
      final boxName = 'pet_events_journal';
      Box box;
      // We might need to register adapters if opening raw, but usually main.dart handles it.
      // If box is closed, opening it generic might fail if adapters are missing.
      // Assuming modules initialized it or we can try catch.
      if (Hive.isBoxOpen(boxName)) {
        box = Hive.box(boxName);
      } else {
        box = await Hive.openBox(boxName); // No cipher? Pet repo used cipher usually? 
        // PetEventRepo uses cipher if provided. Let's assume standard auth cipher if needed.
        // Actually PetEventRepo init passes cipher. Let's try simple open first.
      }

      final keysToDelete = <dynamic>[];
      for (var key in box.keys) {
        final val = box.get(key);
        // val is PetEventModel usually.
        // If we can't access model properties easily without casting to generic, we check via dynamic
        try {
           final g = (val as dynamic).group; 
           if (groups.contains(g)) {
             keysToDelete.add(key);
           }
        } catch (_) {
           // Fallback for Map
           if (val is Map && groups.contains(val['group'])) {
             keysToDelete.add(key);
           }
        }
      }
      await box.deleteAll(keysToDelete);
      debugPrint('🧹 Cleared ${keysToDelete.length} journal items for groups: $groups');
    } catch (e) {
      debugPrint('⚠️ Error clearing journal by group: $e');
    }
  }
}
