import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../l10n/app_localizations.dart';
import '../../models/pet_analysis_result.dart';
import '../../models/pet_profile_extended.dart';
import '../../../../core/widgets/pdf_action_button.dart';

/// Modern Pet Dossier View - Premium UI with white cards and black text
/// Replaces the old dark-themed result card with a clean, professional design
class PetDossierView extends StatefulWidget {
  final PetAnalysisResult analysis;
  final String imagePath;
  final VoidCallback onSave;
  final VoidCallback onGeneratePDF;
  final VoidCallback? onViewProfile;
  final String? petName;
  final PetProfileExtended? petProfile;

  const PetDossierView({
    Key? key,
    required this.analysis,
    required this.imagePath,
    required this.onSave,
    required this.onGeneratePDF,
    this.onViewProfile,
    this.petName,
    this.petProfile,
  }) : super(key: key);

  @override
  State<PetDossierView> createState() => _PetDossierViewState();
}

class _PetDossierViewState extends State<PetDossierView> {
  bool _isSaved = false;
  final Set<int> _expandedSections = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light gray background
      appBar: _buildAppBar(l10n),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeroCard(l10n),
                  const SizedBox(height: 12),
                  _buildAIBanner(l10n),
                  const SizedBox(height: 16),
                  ..._buildSections(l10n),
                  const SizedBox(height: 80), // Space for fixed CTA
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildFixedCTA(l10n),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    return AppBar(
      backgroundColor: AppDesign.surfaceDark,
      elevation: 2,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Análise Veterinária 360°',
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      actions: [
        PdfActionButton(onPressed: widget.onGeneratePDF),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeroCard(AppLocalizations l10n) {
    final isDiag = widget.analysis.analysisType == 'diagnosis';
    final title = widget.petName ?? (isDiag ? widget.analysis.raca : widget.analysis.raca);
    final subtitle = widget.petProfile?.especie ?? widget.analysis.especie;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Pet Photo
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppDesign.petPink.withOpacity(0.1),
              border: Border.all(color: AppDesign.petPink, width: 2),
            ),
            child: const Icon(Icons.pets, size: 40, color: AppDesign.petPink),
          ),
          const SizedBox(width: 16),
          // Pet Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildChip(widget.analysis.identificacao.porteEstimado, Icons.straighten),
                    if (!isDiag)
                      _buildChip(widget.analysis.identificacao.expectativaVidaMedia, Icons.calendar_today),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppDesign.petPink.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppDesign.petPink.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppDesign.petPink),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIBanner(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.amber.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Conteúdo gerado por IA. Não substitui diagnóstico veterinário.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSections(AppLocalizations l10n) {
    final sections = [
      _SectionData(
        id: 0,
        icon: Icons.visibility_outlined,
        title: 'Sinais Observados',
        content: widget.analysis.descricaoVisual,
      ),
      _SectionData(
        id: 1,
        icon: Icons.restaurant_outlined,
        title: 'Nutrição & Dieta',
        content: _buildNutritionContent(),
      ),
      _SectionData(
        id: 2,
        icon: Icons.shower_outlined,
        title: 'Grooming & Higiene',
        content: _buildGroomingContent(),
      ),
      _SectionData(
        id: 3,
        icon: Icons.favorite_outline,
        title: 'Saúde Preventiva',
        content: _buildHealthContent(),
      ),
      _SectionData(
        id: 4,
        icon: Icons.home_outlined,
        title: 'Lifestyle & Educação',
        content: _buildLifestyleContent(),
      ),
    ];

    return sections.map((section) => _buildAccordionCard(section)).toList();
  }

  Widget _buildAccordionCard(_SectionData section) {
    final isExpanded = _expandedSections.contains(section.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedSections.remove(section.id);
              } else {
                _expandedSections.add(section.id);
              }
            });
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppDesign.petPink.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(section.icon, color: AppDesign.petPink, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        section.title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.black54,
                    ),
                  ],
                ),
                if (isExpanded) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Text(
                    section.content,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFixedCTA(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: widget.onViewProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppDesign.petPink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Ver Perfil do Pet',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: () {
                if (!_isSaved) {
                  setState(() => _isSaved = true);
                  widget.onSave();
                }
              },
              icon: Icon(
                _isSaved ? Icons.check_circle : Icons.bookmark_outline,
                color: AppDesign.petPink,
                size: 28,
              ),
              style: IconButton.styleFrom(
                backgroundColor: AppDesign.petPink.withOpacity(0.1),
                padding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildNutritionContent() {
    final nutri = widget.analysis.nutricao;
    return '''Meta Calórica: ${nutri.metaCalorica['kcal_adulto'] ?? 'N/A'}
Nutrientes Alvo: ${nutri.nutrientesAlvo.join(', ')}
Suplementação: ${nutri.suplementacaoSugerida.join(', ')}''';
  }

  String _buildGroomingContent() {
    final grooming = widget.analysis.higiene;
    return '''Tipo de Pelo: ${grooming.manutencaoPelagem['tipo_pelo'] ?? 'N/A'}
Escovação: ${grooming.manutencaoPelagem['frequencia_escovacao_semanal'] ?? 'N/A'}
Banho: ${grooming.banhoEHigiene['frequencia_ideal_banho'] ?? 'N/A'}''';
  }

  String _buildHealthContent() {
    final health = widget.analysis.saude;
    return '''Predisposições: ${health.predisposicaoDoencas.join(', ')}
Checkup: ${health.checkupVeterinario['frequencia_ideal'] ?? 'Anual'}''';
  }

  String _buildLifestyleContent() {
    final lifestyle = widget.analysis.lifestyle;
    return '''Treinamento: ${lifestyle.treinamento['dificuldade_adestramento'] ?? 'N/A'}
Espaço: ${lifestyle.ambienteIdeal['necessidade_de_espaco_aberto'] ?? 'N/A'}
Estímulo Mental: ${lifestyle.estimuloMental['necessidade_estimulo_mental'] ?? 'N/A'}''';
  }
}

class _SectionData {
  final int id;
  final IconData icon;
  final String title;
  final String content;

  _SectionData({
    required this.id,
    required this.icon,
    required this.title,
    required this.content,
  });
}
