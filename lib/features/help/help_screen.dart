import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_design.dart';

/// Help screen with comprehensive app documentation
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          l10n.helpAppBarTitle,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Introductory Message from Creator
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: AppDesign.surfaceDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                const Icon(Icons.format_quote_rounded, color: AppDesign.accent, size: 32),
                const SizedBox(height: 12),
                Text(
                  "O nome deste app é uma homenagem ao meu pet, o Nut. Minha ideia era criar uma ferramenta que fizesse a gestão completa da vida dele, desde a organização da rotina até a elaboração de cardápios saudáveis.\n\n"
                  "No dia a dia, o ScanNut me ajuda a registrar cada ocorrência. Para os exames de fezes, urina e sangue, utilizo a IA para obter as primeiras impressões através da análise de imagens — um suporte tecnológico que sempre compartilho com o veterinário. Além disso, incluí um guia de plantas para identificar espécies tóxicas e garantir a segurança dele.\n\n"
                  "Pensando na minha própria saúde, adicionei o Scan de Comidas para monitorar calorias, vitaminas e gerar cardápios com listas de compras. Sinto que, agora, o app ficou completo para nós dois.",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.white70,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text("- Abreu", style: TextStyle(color: AppDesign.accent, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
          
          _buildWelcomeCard(l10n),
          const SizedBox(height: 24),
          
          _buildSectionTitle(l10n.helpPetModule),
          _buildHelpCard(
            title: l10n.helpPetBreedTitle,
            description: l10n.helpPetBreedDesc,
            icon: Icons.pets,
            color: Colors.purple,
          ),
          const SizedBox(height: 12),
          _buildHelpCard(
            title: l10n.helpPetWoundTitle,
            description: l10n.helpPetWoundDesc,
            icon: Icons.healing,
            color: Colors.red,
          ),
          const SizedBox(height: 12),
          _buildHelpCard(
            title: l10n.helpPetDossierTitle,
            description: l10n.helpPetDossierDesc,
            icon: Icons.folder_special,
            color: Colors.blue,
          ),
          
          const SizedBox(height: 24),
          _buildSectionTitle(l10n.helpPlantModule),
          _buildHelpCard(
            title: l10n.helpPlantIdTitle,
            description: l10n.helpPlantIdDesc,
            icon: Icons.eco,
            color: Colors.green,
          ),
          
          const SizedBox(height: 24),
          _buildSectionTitle(l10n.helpFoodModule),
          _buildHelpCard(
            title: l10n.helpFoodAnalysisTitle,
            description: l10n.helpFoodAnalysisDesc,
            icon: Icons.restaurant,
            color: Colors.orange,
          ),
          
          const SizedBox(height: 24),
          _buildSectionTitle(l10n.helpMenuTitle),
          _buildHelpCard(
            title: l10n.helpMenuGenTitle,
            description: l10n.helpMenuGenDesc,
            icon: Icons.calendar_month,
            color: Colors.cyan,
          ),
          const SizedBox(height: 12),
          _buildHelpCard(
            title: l10n.helpMenuHistTitle,
            description: l10n.helpMenuHistDesc,
            icon: Icons.history,
            color: Colors.blueGrey,
          ),
          const SizedBox(height: 12),
          _buildHelpCard(
            title: l10n.helpMenuObjTitle,
            description: l10n.helpMenuObjDesc,
            icon: Icons.track_changes,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 12),
          _buildHelpCard(
            title: l10n.helpMenuPrefTitle,
            description: l10n.helpMenuPrefDesc,
            icon: Icons.dining,
            color: Colors.greenAccent,
          ),
          const SizedBox(height: 12),
          _buildHelpCard(
            title: l10n.helpMenuEditTitle,
            description: l10n.helpMenuEditDesc,
            icon: Icons.edit_note,
            color: Colors.amber,
          ),
          const SizedBox(height: 12),
          _buildHelpCard(
            title: l10n.helpMenuShopTitle,
            description: l10n.helpMenuShopDesc,
            icon: Icons.shopping_cart,
            color: Colors.teal,
          ),
          const SizedBox(height: 12),
          _buildHelpCard(
            title: l10n.helpMenuPdfTitle,
            description: l10n.helpMenuPdfDesc,
            icon: Icons.picture_as_pdf,
            color: AppDesign.primary,
          ),
          const SizedBox(height: 12),
          _buildHelpCard(
            title: l10n.helpMenuTipTitle,
            description: l10n.helpMenuTipDesc,
            icon: Icons.lightbulb,
            color: Colors.yellowAccent,
          ),
          const SizedBox(height: 12),
          _buildHelpCard(
            title: 'Geração Segura de Cardápios Pet',
            description: 'Os cardápios de pets só podem ser gerados através do Perfil do Pet, garantindo segurança e controle. '
                'Acesse o perfil do seu pet, vá até a seção "Nutrição" e clique em "Gerar cardápio". '
                'O status da última atualização é exibido em tempo real.',
            icon: Icons.shield_outlined,
            color: Colors.deepPurple,
          ),
          const SizedBox(height: 12),
          _buildHelpCard(
            title: 'PDFs Econômicos',
            description: 'Todos os relatórios em PDF foram otimizados para impressão econômica. '
                'Usamos apenas preto e branco, sem fundos coloridos, reduzindo o uso de tinta em até 90%. '
                'Perfeito para imprimir prontuários, relatórios de parceiros e históricos sem gastar muito.',
            icon: Icons.print,
            color: Colors.grey,
          ),
          
          const SizedBox(height: 24),
          _buildSectionTitle(l10n.backupSectionTitle),
          _buildHelpCard(
            title: l10n.helpBackupExportTitle,
            description: l10n.helpBackupExportDesc,
            icon: Icons.upload_file,
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildHelpCard(
            title: l10n.helpBackupImportTitle,
            description: '${l10n.helpBackupImportDesc}\n\n'
                '${l10n.helpBackupRestoreSecurity}',
            icon: Icons.file_download,
            color: Colors.amber,
          ),
          const SizedBox(height: 12),
          _buildHelpCard(
            title: l10n.helpSecurityTitle,
            description: '${l10n.helpSecuritySubtitle}\n\n'
                '${l10n.helpSecurityAesItem}\n'
                '${l10n.helpSecurityKeyItem}\n'
                '${l10n.helpSecurityWarningItem}',
            icon: Icons.security,
            color: Colors.cyanAccent,
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(l10n.helpProSection),
          _buildHelpCard(
            title: l10n.helpProBenefitsTitle,
            description: l10n.helpProBenefitsList,
            icon: Icons.workspace_premium,
            color: Colors.amber,
          ),
          
          const SizedBox(height: 24),
          _buildSectionTitle(l10n.helpPrivacySection),
          _buildHelpCard(
            title: l10n.helpSecurityEndToEnd,
            description: '${l10n.helpSecurityAes}\n'
                '${l10n.helpSecurityKey}\n'
                '${l10n.helpSecurityAccess}\n'
                '${l10n.helpSecurityBackupProtection}',
            icon: Icons.security,
            color: Colors.indigo,
          ),
          
          const SizedBox(height: 24),
          _buildSectionTitle(l10n.helpFaqSection),
          _buildFAQ(
            question: l10n.faqOfflineQ,
            answer: l10n.faqOfflineA,
          ),
          _buildFAQ(
            question: l10n.faqPhotosQ,
            answer: l10n.faqPhotosA,
          ),
          _buildFAQ(
            question: l10n.faqDevicesQ,
            answer: l10n.faqDevicesA,
          ),
          _buildFAQ(
            question: l10n.faqWoundQ,
            answer: l10n.faqWoundA,
          ),
          
          const SizedBox(height: 24),
          _buildSectionTitle(l10n.helpSupportSection),
          _buildHelpCard(
            title: l10n.helpNeedSupportTitle,
            description: l10n.helpSupportDesc,
            icon: Icons.support_agent,
            color: Colors.pink,
          ),
          
          const SizedBox(height: 40),
          Center(
            child: Text(
              l10n.helpFooter,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white38,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade700, Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.help_outline, size: 48, color: Colors.white),
          const SizedBox(height: 12),
          Text(
            l10n.helpWelcomeTitle,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.helpWelcomeSubtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white70,
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
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildHelpCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (icon == Icons.picture_as_pdf || icon == Icons.picture_as_pdf_rounded) ? Colors.transparent : color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon, 
              color: (icon == Icons.picture_as_pdf || icon == Icons.picture_as_pdf_rounded) ? Colors.white : color, 
              size: 24
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white70,
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

  Widget _buildFAQ({
    required String question,
    required String answer,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.help, color: Color(0xFF00E676), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
