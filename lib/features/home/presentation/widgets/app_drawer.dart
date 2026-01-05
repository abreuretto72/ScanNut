import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../settings/settings_screen.dart';
import '../../../pet/presentation/nutritional_pillars_screen.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/services/data_management_service.dart';
import '../../../food/presentation/nutrition_history_screen.dart';
import '../../../plant/presentation/botany_history_screen.dart';
import '../../../food/presentation/fitness_dashboard_screen.dart';
import '../../../pet/presentation/pet_history_screen.dart';
import '../../../../nutrition/presentation/screens/nutrition_home_screen.dart';
import '../../../../features/subscription/presentation/paywall_screen.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Drawer(
      backgroundColor: Colors.grey.shade900,
      child: SafeArea(
        child: Column(
          children: [
            // Header (mantido igual, não mostrado no replace)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.shade700,
                    Colors.green.shade900,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    settings.userName.isEmpty ? l10n.menuHello : l10n.menuHelloUser(settings.userName),
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    l10n.menuAiAssistant,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // PRO BUTTON
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PaywallScreen(),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFA000), Color(0xFFFFC107)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.star, color: Colors.black),
                        title: Text(
                          l10n.drawerProTitle,
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          l10n.drawerProSubtitle,
                          style: GoogleFonts.poppins(color: Colors.black87, fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.black54, size: 16),
                      ),
                    ),
                  ),

                  _buildMenuItem(
                    context,
                    icon: Icons.settings,
                    title: l10n.menuSettings,
                    subtitle: l10n.menuSettingsSubtitle(settings.dailyCalorieGoal.toString()),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.temple_buddhist,
                    title: l10n.menuNutritionalPillars,
                    subtitle: l10n.menuNutritionalPillarsSubtitle,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const NutritionalPillarsScreen()));
                    },
                  ),
                  const Divider(color: Colors.white24, height: 16),
                  _buildMenuItem(
                    context,
                    icon: Icons.dashboard_customize_outlined,
                    title: l10n.menuEnergyBalance,
                    subtitle: l10n.menuEnergyBalanceSubtitle,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const FitnessDashboardScreen()));
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.history,
                    title: l10n.menuNutritionHistory,
                    subtitle: l10n.menuNutritionHistorySubtitle,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const NutritionHistoryScreen()));
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.local_florist_outlined,
                    title: l10n.menuBotanyHistory,
                    subtitle: l10n.menuBotanyHistorySubtitle,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const BotanyHistoryScreen()));
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.pets_outlined,
                    title: l10n.menuPetHistory,
                    subtitle: l10n.menuPetHistorySubtitle,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => PetHistoryScreen()));
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.help_outline,
                    title: l10n.menuHelp,
                    subtitle: l10n.menuHelpSubtitle,
                    onTap: () {
                      Navigator.pop(context);
                      _showHelpDialog(context);
                    },
                  ),
                  FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      final version = snapshot.hasData 
                          ? 'Versão ${snapshot.data!.version}'
                          : 'Carregando...';
                      return _buildMenuItem(
                        context,
                        icon: Icons.info_outline,
                        title: l10n.menuAbout,
                        subtitle: version,
                        onTap: () {
                          Navigator.pop(context);
                          _showAboutDialog(context);
                        },
                      );
                    },
                  ),
                  const Divider(color: Colors.white24, height: 32),
                  _buildMenuItem(
                    context,
                    icon: Icons.privacy_tip_outlined,
                    title: l10n.privacyPolicy,
                    subtitle: 'Consultar termos e dados',
                    onTap: () async {
                      Navigator.pop(context);
                      final url = Uri.parse('https://abreuretto72.github.io/ScanNut/');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.linkError)),
                          );
                        }
                      }
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.delete_forever_outlined,
                    title: l10n.deleteAccount,
                    subtitle: l10n.menuDeleteAccountSubtitle,
                    onTap: () => _showDeleteAccountDialog(context),
                    isDestructive: true,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.exit_to_app,
                    title: l10n.menuExit,
                    subtitle: l10n.menuExitSubtitle,
                    onTap: () {
                      _showExitDialog(context);
                    },
                    isDestructive: true,
                  ),
                ],
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.footerMadeWith,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white54,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : Colors.green;
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color.shade300),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: isDestructive ? Colors.red.shade300 : Colors.white,
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
      onTap: onTap,
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.red, width: 1)),
        title: Text(
          l10n.deleteAccountConfirmTitle,
          style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: Text(
          l10n.deleteAccountConfirmBody,
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.petNamePromptCancel,
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () async {
              try {
                final dataService = DataManagementService();
                await dataService.deleteAllData();
                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Todos os dados foram removidos. Fechando...')),
                  );
                  Future.delayed(const Duration(seconds: 2), () {
                    SystemNavigator.pop();
                  });
                }
              } catch (e) {
                if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao excluir dados: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: Text(
              l10n.deleteAccountButton,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(
          l10n.exitDialogTitle,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Text(
          l10n.exitDialogContent,
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.petNamePromptCancel,
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close drawer
              // Close app
              SystemNavigator.pop();
            },
            child: Text(
              l10n.menuExit,
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) async {
    // Load version info from pubspec.yaml
    final packageInfo = await PackageInfo.fromPlatform();
    final version = packageInfo.version;
    final buildNumber = packageInfo.buildNumber;
    
    if (!context.mounted) return;
    
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(
          l10n.aboutTitle,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.aboutSubtitle,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Versão: $version (Build $buildNumber)',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.aboutDescription,
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.aboutPoweredBy,
              style: GoogleFonts.poppins(
                color: Colors.green.shade300,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Fechar', // You might want to localize this too or use 'Cancel'
              style: GoogleFonts.poppins(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF00E676).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.help_outline, color: Color(0xFF00E676), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.helpUserGuide,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Seções do Perfil
              Text(
                l10n.guideVitalsTitle,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF00E676),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              _buildSectionInfo(
                '🐾 ${l10n.guideIdentity}',
                l10n.guideIdentityDesc,
              ),
              
              _buildSectionInfo(
                '💉 ${l10n.guideHealth}',
                l10n.guideHealthDesc,
              ),
              
              _buildSectionInfo(
                '🍖 ${l10n.guideNutrition}',
                l10n.guideNutritionDesc,
              ),
              
              _buildSectionInfo(
                '📸 ${l10n.guideGallery}',
                l10n.guideGalleryDesc,
              ),
              
              _buildSectionInfo(
                '🤝 ${l10n.guidePrac}',
                l10n.guidePracDesc,
              ),
              
              const SizedBox(height: 20),
              const Divider(color: Colors.white24),
              const SizedBox(height: 16),
              
              // Campo de Observações
              Text(
                l10n.guideObservationsTitle,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF00E676),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              _buildFeatureItem(
                '✅ ${l10n.guideHistory}',
                l10n.guideHistoryDesc,
              ),
              
              _buildFeatureItem(
                '🕐 ${l10n.guideTimestamps}',
                l10n.guideTimestampsDesc,
              ),
              
              _buildFeatureItem(
                '📌 ${l10n.guideOrder}',
                l10n.guideOrderDesc,
              ),
              
              _buildFeatureItem(
                '🎤 ${l10n.guideVoice}',
                l10n.guideVoiceDesc,
              ),
              
              const SizedBox(height: 20),
              const Divider(color: Colors.white24),
              const SizedBox(height: 16),
              
              // Exportação PDF
              Text(
                '📄 ${l10n.guideExportTitle}',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF00E676),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.picture_as_pdf, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.guidePdfTitle,
                            style: GoogleFonts.poppins(
                              color: Colors.blue[200],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.guidePdfDesc,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              const Divider(color: Colors.white24),
              const SizedBox(height: 16),
              
              // Módulo de Plantas
              Text(
                '🌿 ${l10n.guideBotanyTitle}',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF00E676),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              _buildFeatureItem(
                '🍃 ${l10n.guideBotanyLeaf}',
                l10n.guideBotanyLeafDesc,
              ),
              
              _buildFeatureItem(
                '⚠️ ${l10n.guideBotanyAlert}',
                l10n.guideBotanyAlertDesc,
              ),
              
              _buildFeatureItem(
                '🚨 ${l10n.guideBotanyCritical}',
                l10n.guideBotanyCriticalDesc,
              ),
              
              _buildFeatureItem(
                '📊 ${l10n.guideBotanyTraffic}',
                l10n.guideBotanyTrafficDesc,
              ),
              
              const SizedBox(height: 20),
              
              // Dica Final
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF00E676).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb, color: Color(0xFF00E676), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.guideFinalTip,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF00E676),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.commonUnderstand,
              style: GoogleFonts.poppins(
                color: const Color(0xFF00E676),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionInfo(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF00E676),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    color: Colors.white60,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
