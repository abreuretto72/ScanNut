import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NutritionalPillarsScreen extends StatelessWidget {
  const NutritionalPillarsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Guia de Nutrição Animal ScanNut',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold
          ),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // INTRO TEXT
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Text(
                'Diferente dos humanos, os cães e gatos possuem um metabolismo acelerado e exigências nutricionais únicas. O ScanNut utiliza IA para equilibrar estes 5 pilares vitais para a longevidade do seu pet.',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            _buildPillarCard(
              context,
              title: 'Proteína Animal',
              subtitle: 'A Força do Pet',
              icon: Icons.fitness_center,
              color: Colors.redAccent,
              whatIs: 'Pets são carnívoros (estritos como gatos ou facultativos como cães). Eles precisam de aminoácidos específicos encontrados na carne que o corpo deles não produz.',
              scanNutAction: 'Priorizamos fontes como frango, carne bovina, peixes, ovos ou proteínas selecionadas em rações premium.',
            ),
            const SizedBox(height: 16),
            _buildPillarCard(
              context,
              title: 'Gorduras Específicas',
              subtitle: 'A Proteção',
              icon: Icons.bolt,
              color: Colors.amber,
              whatIs: 'Além da energia, a gordura correta previne dermatites e garante que o pet absorva as vitaminas A, D, E e K. O Ômega 3 é o maior aliado contra inflamações.',
              scanNutAction: 'Sugerimos o equilíbrio de Ômegas 3 e 6, provenientes de óleos de peixe ou gorduras boas.',
            ),
            const SizedBox(height: 16),
            _buildPillarCard(
              context,
              title: 'Fibras e Carboidratos Selecionados',
              subtitle: 'O Intestino',
              icon: Icons.grass,
              color: Colors.green,
              whatIs: 'O sistema digestivo do pet é mais curto. Usamos carboidratos de fácil digestão (como batata-doce ou arroz) e fibras que auxiliam na formação correta das fezes.',
              scanNutAction: 'Sugerimos vegetais como abóbora e cenoura, e grãos como arroz integral ou aveia.',
            ),
            const SizedBox(height: 16),
            _buildPillarCard(
              context,
              title: 'Minerais e Vitaminas',
              subtitle: 'Cuidado com a Dose',
              icon: Icons.science,
              color: Colors.purpleAccent,
              whatIs: 'Crucial: O excesso de cálcio pode prejudicar filhotes e a falta pode fragilizar idosos. O ScanNut foca no equilíbrio mineral exato para a estrutura óssea canina e felina.',
              scanNutAction: 'O app sinaliza a necessidade de suplementação, especialmente em dietas Naturais, para evitar carências.',
            ),
            const SizedBox(height: 16),
            _buildPillarCard(
              context,
              title: 'Hidratação Biológica',
              subtitle: 'O Ponto Fraco',
              icon: Icons.water_drop,
              color: Colors.blueAccent,
              whatIs: 'Muitos pets não sentem sede proporcional à necessidade. O app incentiva alimentos úmidos para evitar cálculos renais, uma das maiores causas de óbito em gatos e cães idosos.',
              scanNutAction: 'Sugerimos a inclusão de alimentos úmidos, caldos ou adição de água na ração para proteger os rins.',
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.4
                        ),
                        children: [
                          TextSpan(
                            text: 'ATENÇÃO: ',
                            style: GoogleFonts.poppins(
                              color: Colors.orangeAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const TextSpan(
                            text: 'Nunca ofereça alimentos proibidos para pets (como chocolate, uvas, cebola e xilitol). As sugestões do ScanNut respeitam estas restrições de segurança.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPillarCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String whatIs,
    required String scanNutAction,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.poppins(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 12),
                  _buildSectionTitle('O que é:', color),
                  const SizedBox(height: 4),
                  Text(
                    whatIs,
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle('No ScanNut:', const Color(0xFF00E676)),
                  const SizedBox(height: 4),
                  Text(
                    scanNutAction,
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text, Color color) {
    return Row(
      children: [
        Icon(Icons.arrow_right, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.poppins(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
