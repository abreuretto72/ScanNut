import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../settings/settings_screen.dart';
import '../../../pet/presentation/nutritional_pillars_screen.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Drawer(
      backgroundColor: Colors.grey.shade900,
      child: SafeArea(
        child: Column(
          children: [
            // Header
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
                    settings.userName.isEmpty ? 'Olá!' : 'Olá, ${settings.userName}!',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Scannut AI Assistant',
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
                  _buildMenuItem(
                    context,
                    icon: Icons.settings,
                    title: 'Configuração',
                    subtitle: 'Meta diária: ${settings.dailyCalorieGoal} kcal',
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
                    icon: Icons.temple_buddhist, // Or local_library or spa
                    title: 'Pilares da Nutrição',
                    subtitle: 'Conceitos do ScanNut',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NutritionalPillarsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.help_outline,
                    title: 'Ajuda',
                    subtitle: 'Como usar o app',
                    onTap: () {
                      Navigator.pop(context);
                      _showHelpDialog(context);
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.info_outline,
                    title: 'Sobre',
                    subtitle: 'Versão 1.0.0',
                    onTap: () {
                      Navigator.pop(context);
                      _showAboutDialog(context);
                    },
                  ),
                  const Divider(color: Colors.white24, height: 32),
                  _buildMenuItem(
                    context,
                    icon: Icons.exit_to_app,
                    title: 'Sair',
                    subtitle: 'Fechar o aplicativo',
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
                'Feito com ❤️ usando Gemini AI',
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

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(
          'Sair do App',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Text(
          'Deseja realmente sair do Scannut?',
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
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close drawer
              // Close app
              SystemNavigator.pop();
            },
            child: Text(
              'Sair',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(
          'Sobre o Scannut',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scannut AI Visual Assistant',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Versão: 1.0.0',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Text(
              'Análise inteligente de:\n• Alimentos 🍎\n• Plantas 🌿\n• Pets 🐾',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Text(
              'Powered by Google Gemini 2.5 Flash',
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
              'Fechar',
              style: GoogleFonts.poppins(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
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
                'Guia Completo',
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
                '📋 SEÇÕES DO PERFIL DO PET',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF00E676),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              _buildSectionInfo(
                '🐾 Identidade',
                'Gerencie os dados vitais do pet: peso, raça, idade e análise comportamental genética completa.',
              ),
              
              _buildSectionInfo(
                '💉 Saúde',
                'Histórico médico completo com controle de vacinas, vermífugos, exames laboratoriais e lembretes de consultas.',
              ),
              
              _buildSectionInfo(
                '🍖 Nutrição',
                'Planejamento alimentar semanal detalhado com cálculos de Kcal, datas (DD/MM) e os 5 pilares nutricionais.',
              ),
              
              _buildSectionInfo(
                '📸 Galeria',
                'Documente visualmente a evolução e momentos especiais do seu pet com fotos e vídeos.',
              ),
              
              _buildSectionInfo(
                '🤝 Prac',
                'Prontuário de Acompanhamento Comportamental para registrar rotinas, mudanças de hábito e rede de apoio.',
              ),
              
              const SizedBox(height: 20),
              const Divider(color: Colors.white24),
              const SizedBox(height: 16),
              
              // Campo de Observações
              Text(
                '📝 OBSERVAÇÕES E HISTÓRICO',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF00E676),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              _buildFeatureItem(
                '✅ Histórico Cumulativo',
                'Cada seção possui um campo de observações. Novas anotações NÃO apagam as antigas - tudo fica registrado!',
              ),
              
              _buildFeatureItem(
                '🕐 Timestamps Automáticos',
                'O sistema insere automaticamente Data e Hora em cada entrada, criando um histórico cronológico completo.',
              ),
              
              _buildFeatureItem(
                '📌 Ordem Inteligente',
                'A entrada mais recente sempre aparece no topo, facilitando a leitura e acompanhamento.',
              ),
              
              _buildFeatureItem(
                '🎤 Ditado por Voz',
                'Use o ícone de microfone para ditar observações em vez de digitar. Mais rápido e prático!',
              ),
              
              const SizedBox(height: 20),
              const Divider(color: Colors.white24),
              const SizedBox(height: 16),
              
              // Exportação PDF
              Text(
                '📄 EXPORTAÇÃO EM PDF',
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
                            'Prontuário Veterinário Completo',
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
                      'Todas as informações e observações acumuladas podem ser exportadas de forma seletiva no PDF do Perfil.',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '✓ Serve como prontuário oficial para veterinários\n✓ Escolha quais seções incluir\n✓ Formato profissional com capa e timestamps',
                      style: GoogleFonts.poppins(
                        color: Colors.white60,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
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
                        'O ScanNut é uma ferramenta de longo prazo para acompanhar toda a vida do seu pet!',
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
              'Entendi',
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
