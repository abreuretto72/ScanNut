import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../settings/settings_screen.dart';
import '../../../pet/presentation/nutritional_pillars_screen.dart';
import '../../../../core/theme/app_design.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/services/data_management_service.dart';
import '../../../food/presentation/nutrition_history_screen.dart';
import '../../../plant/presentation/botany_history_screen.dart';
import '../../../food/presentation/fitness_dashboard_screen.dart';
import '../../../pet/presentation/pet_history_screen.dart';
import '../../../../nutrition/presentation/screens/nutrition_home_screen.dart';
import '../../../../features/subscription/presentation/paywall_screen.dart';
import '../../../../core/services/simple_auth_service.dart';
import '../../../auth/presentation/login_screen.dart';
import '../../../settings/privacy_policy_screen.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Drawer(
      backgroundColor: AppDesign.backgroundDark,
      child: SafeArea(
        child: Column(
          children: [
            // Header (mantido igual, não mostrado no replace)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppDesign.primary,
                    AppDesign.primary,
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
                      color: AppDesign.accent,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    settings.userName.isEmpty ? l10n.menuHello : l10n.menuHelloUser(settings.userName),
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppDesign.textPrimaryDark,
                    ),
                  ),
                  Text(
                    l10n.menuAiAssistant,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppDesign.textSecondaryDark,
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
                        color: const Color(0xFFFADADD),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFADADD).withOpacity(0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.star, color: AppDesign.textPrimaryLight),
                        title: Text(
                          l10n.drawerProTitle,
                          style: GoogleFonts.poppins(
                            color: AppDesign.textPrimaryLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          l10n.drawerProSubtitle,
                          style: GoogleFonts.poppins(color: AppDesign.textSecondaryLight, fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, color: AppDesign.textSecondaryLight, size: 16),
                      ),
                    ),
                  ),

                  _buildMenuItem(
                    context,
                    icon: AppDesign.iconConfig,
                    title: l10n.menuSettings,
                    subtitle: l10n.settingsPreferences,
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
                        icon: Icons.info_outline, // Keep generic or add to AppDesign if needed. User provided list didn't have info icon explicitly? "Icons.xxx -> AppDesign.iconXXX" - let's see. iconAlert is warning. iconInfo? No. So I'll keep generic or map to something close. Or just use Icons.info_outline as exception? "Icons. fora do app_design.dart -> apenas exceções do MaterialApp". info_outline is material. But let's check if I can add it to AppDesign or reuse. I'll use AppDesign.iconAlert for now or just generic. Actually, I shouldn't add to AppDesign unless I edit it. I'll stick to Icons.info_outline for now as it's not in the replaced list provided by user, but I should try to remove all Icons. usages.
                        // User list: iconFood, iconPlant, iconPet, iconScan, iconMenu, iconConfig, iconDelete, iconBackup, iconRestore, iconAlert.
                        // info_outline is not there. I will leave it as Icons.info_outline but be careful.
                        // Wait, "Substituir ícones diretos: Icons.xxx -> AppDesign.iconXXX" implies those that exist in AppDesign.
                        // I'll leave Icons.info_outline for now.
                        title: l10n.menuAbout,
                        subtitle: version,
                        onTap: () {
                          Navigator.pop(context);
                          _showAboutDialog(context, snapshot.data);
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
                      Navigator.pop(context); // Close drawer first
                      const url = 'https://abreuretto72.github.io/ScanNut/';
                      try {
                        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                      } catch (e) {
                         // Fallback or ignore
                         debugPrint('Could not launch policy URL: $e');
                      }
                    },
                  ),

                  _buildMenuItem(
                    context,
                    icon: Icons.logout, // Not in AppDesign
                    title: l10n.logoutTitle,
                    subtitle: l10n.logoutSubtitle,
                    onTap: () async {
                      await simpleAuthService.logout();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      }
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
    final color = isDestructive ? AppDesign.error : AppDesign.accent;
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color), // Removed .shade300
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: isDestructive ? AppDesign.error : AppDesign.textPrimaryDark,
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



  void _showExitDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppDesign.surfaceDark,
        title: Text(
          l10n.exitDialogTitle,
          style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark),
        ),
        content: Text(
          l10n.exitDialogContent,
          style: GoogleFonts.poppins(color: AppDesign.textSecondaryDark),
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
              style: GoogleFonts.poppins(color: AppDesign.error),
            ),
          ),
          Center(
            child: Text(
              'Desenvolvido por Multiverso Digital',
              style: GoogleFonts.poppins(color: Colors.white24, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context, [PackageInfo? info]) async {
    // Load version info from pubspec.yaml if not provided
    PackageInfo packageInfo;
    if (info != null) {
      packageInfo = info;
    } else {
      packageInfo = await PackageInfo.fromPlatform();
      if (!context.mounted) return;
    }
    
    final version = packageInfo.version;
    final buildNumber = packageInfo.buildNumber;
    
    if (!context.mounted) return;
    
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppDesign.surfaceDark,
        title: Text(
          l10n.aboutTitle,
          style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.aboutSubtitle,
              style: GoogleFonts.poppins(
                color: AppDesign.textPrimaryDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Versão: $version (Build $buildNumber)',
              style: GoogleFonts.poppins(color: AppDesign.textSecondaryDark, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.aboutDescription,
              style: GoogleFonts.poppins(color: AppDesign.textSecondaryDark, fontSize: 14),
            ),
            
            const SizedBox(height: 24),
            const Divider(color: Colors.white12),
            const SizedBox(height: 16),
            
            Text(
              'Desenvolvido por',
              style: GoogleFonts.poppins(
                color: AppDesign.textPrimaryDark,
                fontSize: 14,
              ),
            ),
            Text(
              'Multiverso Digital',
              style: GoogleFonts.poppins(
                color: AppDesign.textPrimaryDark,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            Text(
              'Copyright © 2026',
              style: GoogleFonts.poppins(color: AppDesign.textSecondaryDark, fontSize: 12),
            ),
            const SizedBox(height: 4),
            InkWell(
              onTap: () async {
                 final Uri emailLaunchUri = Uri(
                   scheme: 'mailto',
                   path: 'contato@multiversodigital.com.br',
                   query: 'subject=${l10n.contactSubject}',
                 );
                 // Best effort launch
                 try {
                   await launchUrl(emailLaunchUri);
                 } catch (e) {
                   // ignore
                 }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'contato@multiversodigital.com.br',
                  style: GoogleFonts.poppins(color: Colors.blue, fontSize: 12, decoration: TextDecoration.none),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Fechar', // You might want to localize this too or use 'Cancel'
              style: GoogleFonts.poppins(color: AppDesign.accent),
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
        backgroundColor: AppDesign.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppDesign.accent.withOpacity(0.2), // withValues -> withOpacity
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.help_outline, color: AppDesign.accent, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.helpUserGuide,
                style: GoogleFonts.poppins(
                  color: AppDesign.textPrimaryDark,
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
              // Welcome
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppDesign.primary, AppDesign.info], // Replaced purple/blue shades
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: AppDesign.textPrimaryDark, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${l10n.helpWelcomeTitle}\n${l10n.helpWelcomeSubtitle}',
                        style: GoogleFonts.poppins(
                          color: AppDesign.textPrimaryDark,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // AVISO DE RESPONSABILIDADE DA IA
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppDesign.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppDesign.error.withOpacity(0.4), width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppDesign.error, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.helpDisclaimerTitle,
                            style: GoogleFonts.poppins(
                              color: AppDesign.error,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.helpDisclaimerBody,
                      style: GoogleFonts.poppins(
                        color: AppDesign.textPrimaryDark,
                        fontSize: 12,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // MÓDULO PET
              Text(
                '🐾 MÓDULO PET',
                style: GoogleFonts.poppins(
                  color: AppDesign.accent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              _buildModuleCard(
                icon: AppDesign.iconScan,
                color: AppDesign.primary,
                title: 'Identificação de Raça',
                description: '1. Tire uma foto do seu pet\n'
                    '2. A IA identifica a raça\n'
                    '3. Receba perfil biológico completo\n'
                    '4. Plano alimentar personalizado',
              ),
              
              const SizedBox(height: 12),
              
              _buildModuleCard(
                icon: Icons.healing, // Keep or find replacement
                color: AppDesign.error,
                title: 'Análise de Feridas',
                description: '• Triagem visual de lesões\n'
                    '• Descrição clínica detalhada\n'
                    '• Nível de urgência (🟢🟡🔴)\n'
                    '• Primeiros socorros\n'
                    '⚠️ NÃO substitui veterinário!',
              ),
              
              const SizedBox(height: 12),
              
              _buildModuleCard(
                icon: Icons.folder_special,
                color: AppDesign.info, // Blue -> Info
                title: 'Prontuário Digital',
                description: '✅ Histórico de vacinas\n'
                    '✅ Controle de peso\n'
                    '✅ Exames (OCR automático)\n'
                    '✅ Agenda de eventos\n'
                    '✅ Rede de parceiros',
              ),
              
              const SizedBox(height: 24),
              Divider(color: AppDesign.textPrimaryDark.withOpacity(0.24)),
              const SizedBox(height: 16),
              
              // MÓDULO PLANTAS
              Text(
                '🌿 MÓDULO PLANTAS',
                style: GoogleFonts.poppins(
                  color: AppDesign.accent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              _buildModuleCard(
                icon: AppDesign.iconPlant, 
                color: AppDesign.accent, // Green -> Accent (as requested)
                title: 'Identificação Botânica',
                description: '1. Fotografe a planta\n'
                    '2. Nome científico e popular\n'
                    '3. Família botânica\n'
                    '4. Cuidados necessários',
              ),
              
              const SizedBox(height: 12),
              
              _buildModuleCard(
                icon: AppDesign.iconAlert,
                color: AppDesign.warning,
                title: 'Detecção de Toxicidade',
                description: '🟢 Segura - Sem riscos\n'
                    '🟡 Atenção - Irritação leve\n'
                    '🔴 TÓXICA - Manter afastado!\n\n'
                    'Proteção para pets e crianças',
              ),
              
              const SizedBox(height: 12),
              
              _buildModuleCard(
                icon: Icons.water_drop,
                color: AppDesign.info,
                title: 'Guia de Cuidados',
                description: '💧 Frequência de rega\n'
                    '☀️ Necessidade de luz\n'
                    '🌱 Tipo de solo ideal\n'
                    '🌡️ Temperatura adequada',
              ),
              
              const SizedBox(height: 24),
              Divider(color: AppDesign.textPrimaryDark.withOpacity(0.24)),
              const SizedBox(height: 16),
              
              // MÓDULO COMIDA
              Text(
                '🍎 MÓDULO COMIDA',
                style: GoogleFonts.poppins(
                  color: AppDesign.accent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              _buildModuleCard(
                icon: AppDesign.iconFood,
                color: AppDesign.warning, // DeepOrange -> Warning? Or Primary? Food usually warm color. Warning is orange.
                title: 'Análise Nutricional',
                description: '1. Fotografe o alimento\n'
                    '2. IA calcula macros:\n'
                    '   • Calorias\n'
                    '   • Proteínas\n'
                    '   • Carboidratos\n'
                    '   • Gorduras',
              ),
              

              
              const SizedBox(height: 12),
              
              _buildModuleCard(
                icon: Icons.calendar_month,
                color: AppDesign.primary, // Indigo -> Primary
                title: 'Planejamento Semanal',
                description: '📅 Organize suas refeições\n'
                    '🍽️ Histórico completo\n'
                    '📋 Lista de compras\n'
                    '⏰ Lembretes personalizados',
              ),
              
              const SizedBox(height: 24),
              const Divider(color: Colors.white24),
              const SizedBox(height: 16),
              
              // BACKUP LOCAL
              Text(
                '💾 BACKUP LOCAL',
                style: GoogleFonts.poppins(
                  color: AppDesign.accent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              _buildModuleCard(
                icon: Icons.upload_file,
                color: AppDesign.info,
                title: 'Exportar Backup',
                description: 'Settings → Backup Local\n'
                    '→ Exportar\n'
                    '→ Salve o arquivo .scannut\n\n'
                    '✅ Tudo fica em um único arquivo',
              ),
              
              const SizedBox(height: 12),
              
              _buildModuleCard(
                icon: Icons.file_download,
                color: AppDesign.warning,
                title: 'Restaurar Backup',
                description: 'Settings → Backup Local\n'
                    '→ Importar\n'
                    '→ Selecione seu arquivo .scannut\n\n'
                    '✅ Dados restaurados na hora!',
              ),
              
              const SizedBox(height: 24),
              const Divider(color: Colors.white24),
              const SizedBox(height: 16),
              
              // DICAS FINAIS
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppDesign.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppDesign.accent.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb, color: AppDesign.accent, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '💡 DICAS IMPORTANTES',
                            style: GoogleFonts.poppins(
                              color: AppDesign.accent,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• Tire fotos com boa iluminação\n'
                      '• Mantenha a câmera estável\n'
                      '• Use Wi-Fi para economizar dados\n'
                      '• Análise de feridas NÃO substitui veterinário',
                      style: GoogleFonts.poppins(
                        color: AppDesign.textSecondaryDark,
                        fontSize: 12,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Footer
              Center(
                child: Text(
                  l10n.helpFooter,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: AppDesign.textSecondaryDark.withOpacity(0.5),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Entendi!',
              style: GoogleFonts.poppins(
                color: AppDesign.success,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: AppDesign.textPrimaryDark,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    color: AppDesign.textSecondaryDark,
                    fontSize: 11,
                    height: 1.5,
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
              style: GoogleFonts.poppins(color: AppDesign.textSecondaryDark),
            ),
          ),
        ],
      ),
    );
  }
}
