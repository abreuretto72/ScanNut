import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../l10n/app_localizations.dart';
import '../../models/pet_analysis_result.dart';
import '../../models/pet_profile_extended.dart';
import '../../../../core/widgets/pdf_action_button.dart';

import '../pet_chat_screen.dart';

/// Premium Dark UI for Pet Analysis Result (360° Dossier)
/// Replaces the previous light/white design with a dark theme consistent with the App.
class PetDossierView extends ConsumerStatefulWidget {
  final PetAnalysisResult analysis;
  final String imagePath;
  final VoidCallback
      onSave; // Auto-save trigger if needed, though parent usually handles it
  final VoidCallback onGeneratePDF;
  final VoidCallback? onViewProfile;
  final String? petName;
  final PetProfileExtended? petProfile;

  const PetDossierView({
    super.key,
    required this.analysis,
    required this.imagePath,
    required this.onSave,
    required this.onGeneratePDF,
    this.onViewProfile,
    this.petName,
    this.petProfile,
  });

  @override
  ConsumerState<PetDossierView> createState() => _PetDossierViewState();
}

class _PetDossierViewState extends ConsumerState<PetDossierView> {
  // State to track expanded sections
  final Set<String> _expandedSections = {'sinais', 'risco'}; // Default expanded

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDiagnosis = widget.analysis.analysisType == 'diagnosis';
    final petId = widget.petProfile?.id ?? widget.analysis.petId; // Using petId primarily

    return Scaffold(
      backgroundColor: AppDesign.backgroundDark,
      appBar: _buildAppBar(context, l10n),
      floatingActionButton: petId != null ? FloatingActionButton(
        backgroundColor: AppDesign.petPink,
        child: const Icon(Icons.psychology, color: Colors.white),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => PetChatScreen(
            petId: petId,
            petName: widget.petName ?? widget.analysis.petName ?? 'Pet',
            profile: widget.petProfile,
          )));
        },
      ) : null,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100), // Space for footer
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildIdentityHeader(l10n),
                    const SizedBox(height: 16),
                    _buildDisclaimerBanner(l10n),
                    const SizedBox(height: 24),
                    _buildQuickSummaryGrid(l10n, isDiagnosis),
                    const SizedBox(height: 24),
                    _buildAnalyzedImageCard(l10n),
                    const SizedBox(height: 24),
                    _buildSectionsList(l10n),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildFixedFooter(l10n),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, AppLocalizations l10n) {
    return AppBar(
      backgroundColor: AppDesign.surfaceDark,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        l10n.petDossierTitle,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
      centerTitle: true,
      actions: [
        PdfActionButton(
          onPressed: widget.onGeneratePDF,
          color: AppDesign.petPink, // HIGHLIGHTED
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  /// 2) Header “Pet Identity Card” (premium)
  Widget _buildIdentityHeader(AppLocalizations l10n) {
    // Priority: Pet Name from Profile > Pet Name from Analysis > "Pet Desconhecido"
    final displayPetName =
        widget.petName ?? widget.analysis.petName ?? l10n.petUnknown;

    // Breed & Species logic
    final species = widget.petProfile?.especie ?? widget.analysis.especie;
    final breed = widget.petProfile?.raca ?? widget.analysis.raca;
    final age =
        widget.petProfile?.idadeExata; // Logic simplified in previous step

    // Image Source: Profile Image (if exists) > Analysis Image (as fallback avatar)
    String? avatarPath = widget.petProfile?.imagePath;
    if (avatarPath == null || avatarPath.isEmpty) {
      // Fallback to the analysis image if it's an identification task
      avatarPath = widget.imagePath;
    }

    // V480: IDENTITY ENGINE TRACE & FALLBACKS
    final strings = AppLocalizations.of(context)!;

    // 1. Data Capture with Fallbacks
    final lineageInv = widget.analysis.identificacao.linhagemSrdProvavel;
    final lineage =
        (lineageInv.trim().isNotEmpty && !lineageInv.contains('N/A'))
            ? lineageInv
            : 'Linhagem N/A'; // Fallback visual

    final originInv = widget.analysis.identificacao.origemGeografica;
    final origin = (originInv.trim().isNotEmpty && !originInv.contains('N/A'))
        ? originInv
        : strings.unknownRegion;

    final morphoInv = widget.analysis.identificacao.morfologiaBase;
    final morpho = (morphoInv.trim().isNotEmpty && !morphoInv.contains('N/A'))
        ? morphoInv
        : strings.unknownMorphology;

    final reliabilityRaw = widget.analysis.reliability ?? '0%';
    final isReliable = reliabilityRaw.contains('9') ||
        reliabilityRaw.toLowerCase() == 'high' ||
        reliabilityRaw.toLowerCase() == 'alta';

    // 2. Trace Log
    debugPrint(
        '✅ [ID_TRACE] Mapping: Linhagem: $lineage | Conf: $reliabilityRaw | Regiao: $origin | Morpho: $morpho');

    return Container(
      color: AppDesign.surfaceDark,
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
      child: Column(
        children: [
          // Avatar
          Hero(
            tag: 'pet_avatar_hero',
            child: Container(
              width: 100,
              height: 100,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppDesign.petPink, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppDesign.petPink.withValues(alpha: 0.2),
                    blurRadius: 12,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: ClipOval(
                child: _buildRobustImage(avatarPath),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Name
          Text(displayPetName,
              style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          // Subtitle
          Text('$species • $breed',
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white70,
                  fontWeight: FontWeight.w400),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),

          // V480: Unified Identity Grid
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              // 1. Reliability (Green/High Priority)
              _buildHeaderChip(
                  reliabilityRaw.isEmpty ? 'N/A' : 'Conf: $reliabilityRaw',
                  Icons.verified_user,
                  backgroundColor:
                      isReliable ? Colors.green.withValues(alpha: 0.2) : null,
                  borderColor: isReliable ? Colors.green : Colors.grey,
                  textColor: isReliable ? Colors.greenAccent : Colors.white70),
              // 2. Origin
              _buildHeaderChip(origin, Icons.public,
                  borderColor: Colors.orangeAccent),
              // 3. Morphology
              _buildHeaderChip(morpho, Icons.pets,
                  borderColor: AppDesign.petPink),
              // 4. Lineage
              _buildHeaderChip(lineage, Icons.account_tree_outlined,
                  borderColor: Colors.blueAccent),
              // 5. Basic Info
              if (age != null && age.isNotEmpty)
                _buildHeaderChip(age, Icons.cake_outlined),
              _buildHeaderChip(widget.analysis.identificacao.porteEstimado,
                  Icons.straighten),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderChip(String label, IconData icon,
      {Color? borderColor, Color? backgroundColor, Color? textColor}) {
    if (label.isEmpty || label == 'N/A') return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppDesign.backgroundDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor ?? AppDesign.petPink),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: textColor ?? Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }

  /// 3) Banner de aviso (sem amarelo agressivo)
  Widget _buildDisclaimerBanner(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A), // Dark Gray
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppDesign.petPink.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppDesign.petPink, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.petDossierDisclaimer,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 4) “Resumo Rápido” (topo, antes das seções)
  Widget _buildQuickSummaryGrid(AppLocalizations l10n, bool isDiagnosis) {
    // Extract key metrics
    String signalCount = '---';
    String riskLabel = isDiagnosis
        ? widget.analysis.urgenciaNivel
        : (widget.analysis.reliability ?? 'Alta');
    String actionLabel = isDiagnosis
        ? widget.analysis.orientacaoImediata
        : (widget.analysis.identificacao.racaPredominante.isNotEmpty
            ? 'Raça Identificada'
            : 'Análise Concluída');

    // Count list items for "Sinais"
    if (isDiagnosis) {
      signalCount = '${widget.analysis.possiveisCausas.length} causas';
    } else {
      // For identification, maybe visual characteristics count
      signalCount = 'Bio-Visual';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
              child: _buildSummaryCard(l10n.petDossierSignals, signalCount,
                  Icons.visibility_outlined)),
          const SizedBox(width: 10),
          Expanded(
              child: _buildSummaryCard(
                  isDiagnosis ? l10n.petDossierRisk : l10n.petDossierPrecision,
                  riskLabel,
                  Icons.analytics_outlined)),
          const SizedBox(width: 10),
          Expanded(
              child: _buildSummaryCard(l10n.petDossierStatus, actionLabel,
                  Icons.check_circle_outline,
                  isHighlighted: true)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon,
      {bool isHighlighted = false}) {
    // Truncate value if too long
    String safeValue =
        value.length > 25 ? '${value.substring(0, 22)}...' : value;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppDesign.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        // border: isHighlighted ? Border.all(color: AppDesign.petPink.withValues(alpha: 0.5)) : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon,
              color: isHighlighted ? AppDesign.petPink : Colors.white38,
              size: 20),
          const SizedBox(height: 8),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
                fontSize: 9,
                color: Colors.white38,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            safeValue,
            style: TextStyle(
                fontSize: 11,
                color: isHighlighted ? AppDesign.petPink : Colors.white,
                fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// B) IMAGEM ANALISADA (foto da análise)
  Widget _buildAnalyzedImageCard(AppLocalizations l10n) {
    final path = widget.imagePath;
    if (path.isEmpty || !File(path).existsSync()) {
      return const SizedBox.shrink(); // Hide if invalid
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppDesign.surfaceDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.image_search,
                    color: AppDesign.petPink, size: 18),
                const SizedBox(width: 8),
                Text(l10n.petDossierAnalyzedImage,
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.file(
                      File(path),
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                          color: Colors.grey[900],
                          child: const Icon(Icons.broken_image,
                              color: Colors.white54)),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: InkWell(
                      onTap: () {
                        // Fullscreen view
                        showDialog(
                          context: context,
                          builder: (_) => Dialog(
                            backgroundColor: Colors.black,
                            insetPadding: EdgeInsets.zero,
                            child: Stack(
                              children: [
                                Center(child: Image.file(File(path))),
                                Positioned(
                                    top: 40,
                                    right: 20,
                                    child: IconButton(
                                        icon: const Icon(Icons.close,
                                            color: Colors.white, size: 30),
                                        onPressed: () =>
                                            Navigator.pop(context)))
                              ],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.fullscreen,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(l10n.petDossierViewFull,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 5) Seções em “Accordion Cards”
  Widget _buildSectionsList(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildTriageCards(l10n), // 🛡️ V460: Specialized Triage Cards
          _buildClinicalSection(l10n), // 🛡️ V210: INJECTED CLINICAL SECTION
          _buildStoolSection(l10n), // 💩 V231: INJECTED STOOL SECTION
          _buildAccordion(
              'identificacao', l10n.petSectionIdentity, Icons.pets, {
            'Raça Predominante': widget.analysis.identificacao.racaPredominante,
            'Linhagem': widget.analysis.identificacao.linhagemSrdProvavel,
            'Porte': widget.analysis.identificacao.porteEstimado,
            'Expectativa de Vida':
                widget.analysis.identificacao.expectativaVidaMedia,
          }),
          _buildAccordion(
              'nutricao', l10n.petSectionNutrition, Icons.restaurant, {
            'Meta Calórica (Adulto)':
                widget.analysis.nutricao.metaCalorica['kcal_adulto'] ?? 'N/A',
            'Meta Calórica (Filhote)':
                widget.analysis.nutricao.metaCalorica['kcal_filhote'] ?? 'N/A',
            'Nutrientes Alvo':
                widget.analysis.nutricao.nutrientesAlvo.join(', '),
          }),
          _buildAccordion('higiene', l10n.petSectionGrooming, Icons.shower, {
            'Tipo de Pelo':
                widget.analysis.higiene.manutencaoPelagem['tipo_pelo'] ?? 'N/A',
            'Escovação': widget.analysis.higiene
                    .manutencaoPelagem['frequencia_escovacao_semanal'] ??
                'N/A',
            'Alerta':
                widget.analysis.higiene.manutencaoPelagem['alerta_subpelo'] ??
                    'N/A',
          }),
          _buildAccordion('saude', l10n.petSectionPreventive, Icons.favorite, {
            'Predisposições':
                widget.analysis.saude.predisposicaoDoencas.join('\n'),
            'Pontos Anatômicos':
                widget.analysis.saude.pontosCriticosAnatomicos.join(', '),
            'Checkup': widget.analysis.saude
                    .checkupVeterinario['exames_obrigatorios_anuais']
                    ?.toString() ??
                'N/A',
          }),
          _buildAccordion('lifestyle', l10n.petSectionLifestyle, Icons.park, {
            'Ambiente Ideal': widget.analysis.lifestyle
                    .ambienteIdeal['necessidade_de_espaco_aberto'] ??
                'N/A',
            'Estímulo Mental': widget.analysis.lifestyle
                    .estimuloMental['necessidade_estimulo_mental'] ??
                'N/A',
            'Adestramento': widget.analysis.lifestyle
                    .treinamento['dificuldade_adestramento'] ??
                'N/A',
          }),
          _buildAccordion(
              'behavior', 'Perfil Comportamental', Icons.psychology, {
            'Personalidade':
                widget.analysis.perfilComportamental.personalidade ?? 'N/A',
            'Comportamento Social':
                widget.analysis.perfilComportamental.comportamentoSocial ??
                    'N/A',
            'Energia':
                widget.analysis.perfilComportamental.descricaoEnergia ?? 'N/A',
            'Drive Ancestral':
                widget.analysis.perfilComportamental.driveAncestral,
          }),
          if (widget.analysis.identificacao.curvaCrescimento.isNotEmpty)
            _buildAccordion(
                'crescimento', l10n.petSectionGrowth, Icons.trending_up, {
              'Peso 3 Meses': widget.analysis.identificacao
                      .curvaCrescimento['peso_3_meses'] ??
                  'N/A',
              'Peso 6 Meses': widget.analysis.identificacao
                      .curvaCrescimento['peso_6_meses'] ??
                  'N/A',
              'Peso Adulto': widget
                      .analysis.identificacao.curvaCrescimento['peso_adulto'] ??
                  'N/A',
            }),
        ],
      ),
    );
  }

  Widget _buildTriageCards(AppLocalizations l10n) {
    if (widget.analysis.category == null) return const SizedBox.shrink();

    final category = widget.analysis.category!.toLowerCase();

    if (category == 'olhos' && widget.analysis.eyeDetails != null) {
      return _buildAccordion('triage_ocular', 'Análise Ocular Especializada',
          Icons.remove_red_eye, {
        'Hiperemia': widget.analysis.eyeDetails!['hiperemia'] ?? 'N/A',
        'Opacidade': widget.analysis.eyeDetails!['opacidade'] ?? 'N/A',
        'Secreção': widget.analysis.eyeDetails!['secrecao'] ?? 'N/A',
      });
    }

    if (category == 'dentes' && widget.analysis.dentalDetails != null) {
      return _buildAccordion('triage_dental',
          'Análise Odontológica Especializada', Icons.health_and_safety, {
        'Índice de Tártaro':
            widget.analysis.dentalDetails!['tartaro_index'] ?? 'N/A',
        'Gengivite': widget.analysis.dentalDetails!['gengivite'] ?? 'N/A',
        'Halitose': widget.analysis.dentalDetails!['halitose'] ?? 'N/A',
      });
    }

    if (category == 'pele' && widget.analysis.skinDetails != null) {
      return _buildAccordion(
          'triage_skin', 'Análise Dermatológica Especializada', Icons.spa, {
        'Alopecias': widget.analysis.skinDetails!['alopecias'] ?? 'N/A',
        'Ectoparasitas': widget.analysis.skinDetails!['ectoparasitas'] ?? 'N/A',
        'Descamação': widget.analysis.skinDetails!['descamacao'] ?? 'N/A',
      });
    }

    if (category == 'ferida' && widget.analysis.woundDetails != null) {
      return _buildAccordion(
          'triage_wound', 'Análise de Lesão Especializada', Icons.healing, {
        'Profundidade': widget.analysis.woundDetails!['profundidade'] ?? 'N/A',
        'Secreção': widget.analysis.woundDetails!['secrecao'] ?? 'N/A',
        'Bordas': widget.analysis.woundDetails!['bordas'] ?? 'N/A',
      });
    }

    return const SizedBox.shrink();
  }

  Widget _buildStoolSection(AppLocalizations l10n) {
    if (widget.analysis.analysisType != 'stool_analysis') {
      return const SizedBox.shrink();
    }

    final details = widget.analysis.stoolAnalysis ?? {};
    final colorHex = details['color_hex']?.toString() ?? '#8B4513';

    // Bristol description helper
    String bristolDesc = 'N/A';
    final bristol = details['consistency_bristol_scale'];
    if (bristol != null) {
      final bInt = int.tryParse(bristol.toString()) ?? 0;
      if (bInt == 1) {
        bristolDesc = 'Caroços duros (Constipação)';
      } else if (bInt == 4)
        bristolDesc = 'Ideal (Salsicha lisa)';
      else if (bInt == 7)
        bristolDesc = 'Aquosa (Diarreia)';
      else
        bristolDesc = 'Escala $bInt';
    }

    return Column(
      children: [
        _buildAccordion(
            'stool_main', 'Biometria de Consistência & Cor', Icons.biotech, {
          'Escala de Bristol': bristolDesc,
          'Firmeza': details['firmness'] ?? 'N/A',
          'Hidratação/Muco': details['hydration_mucus'] ?? 'N/A',
          'Coloração': '${details['color_name'] ?? "N/A"} ($colorHex)',
          'Significado Clínico': details['clinical_color_meaning'] ?? 'N/A',
        }),
        _buildAccordion(
            'stool_inclusions', 'Inclusões & Corpos Estranhos', Icons.search, {
          'Corpos Estranhos':
              (details['foreign_bodies'] as List?)?.join(', ') ??
                  'Nenhum detectado',
          'Parasitas Visíveis': (details['parasites_detected'] == true)
              ? 'DETECTADO'
              : 'Nenhum detectado',
          'Avaliação de Volume': details['volume_assessment'] ?? 'N/A',
        }),
        // Visual Color Indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              const Text('Cor Predominante: ',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Color(int.parse(colorHex.replaceFirst('#', '0xFF'))),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClinicalSection(AppLocalizations l10n) {
    // 🛡️ FALLBACK LOGIC
    Map<String, dynamic>? signs = widget.analysis.clinicalSignsDiag != null
        ? Map<String, dynamic>.from(widget.analysis.clinicalSignsDiag!)
        : null;

    List<String>? causes = widget.analysis.possiveisCausas;

    // Check if current analysis is empty, if so, look at history
    bool useHistory = false;
    if ((signs == null || signs.isEmpty) && (causes.isEmpty)) {
      final history = widget.petProfile?.historicoAnaliseFeridas;
      if (history != null && history.isNotEmpty) {
        final last = history.last;
        // Fix Casting for History Data
        signs = last.achadosVisuais;
        causes = last.diagnosticosProvaveis;
        useHistory = true;
      }
    }

    if ((signs == null || signs.isEmpty) && (causes.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (signs != null && signs.isNotEmpty)
          _buildAccordion('clinical_signs', 'Sinais Clínicos Identificados',
              Icons.medical_services, Map<String, dynamic>.from(signs)),
        if (causes.isNotEmpty)
          _buildAccordion(
              'possible_causes',
              'Diagnósticos Prováveis',
              Icons.analytics,
              {for (var e in causes) 'Possibilidade': e.toString()}),
        if (useHistory)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text("(Exibindo dados do histórico recente)",
                style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 10,
                    fontStyle: FontStyle.italic)),
          )
      ],
    );
  }

  Widget _buildAccordion(
      String id, String title, IconData icon, Map<String, dynamic> items) {
    // Filter out empty items
    final validItems = Map<String, dynamic>.from(items)
      ..removeWhere(
          (k, v) => v == null || v.toString().isEmpty || v.toString() == 'N/A');
    if (validItems.isEmpty) return const SizedBox.shrink();

    final isExpanded = _expandedSections.contains(id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppDesign.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey(id),
          initiallyExpanded: isExpanded,
          onExpansionChanged: (val) {
            setState(() {
              if (val) {
                _expandedSections.add(id);
              } else {
                _expandedSections.remove(id);
              }
            });
          },
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: AppDesign.petPink.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: AppDesign.petPink, size: 20),
          ),
          title: Text(title,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 14)),
          iconColor: Colors.white54,
          collapsedIconColor: Colors.white54,
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: validItems.entries
              .map((e) => Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${e.key}: ',
                            style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                        Expanded(
                            child: Text(e.value.toString(),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13))),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  /// 6) Rodapé com CTAs
  Widget _buildFixedFooter(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppDesign.surfaceDark,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              offset: const Offset(0, -4),
              blurRadius: 12)
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: widget.onViewProfile ??
                    () {
                      debugPrint('❌ onViewProfile callback is NULL');
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text(
                              'Erro de navegação: callback não definido.')));
                    },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppDesign.petPink,
                  foregroundColor: Colors.black, // FIXED: High Contrast
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                child: Text(
                  l10n.petActionViewProfile,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
            // REMOVED Redundant PDF Button
          ],
        ),
      ),
    );
  }

  /// Helper: Robust Image Builder
  Widget _buildRobustImage(String? path) {
    if (path == null || path.isEmpty) {
      return Container(
        color: Colors.grey[800],
        child: const Icon(Icons.pets, color: Colors.white24, size: 40),
      );
    }

    final file = File(path);
    if (!file.existsSync()) {
      debugPrint('⚠️ Image not found: $path');
      return Container(
        color: Colors.grey[800],
        child: const Icon(Icons.broken_image, color: Colors.white24, size: 40),
      );
    }

    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('⚠️ Image load error: $error');
        return Container(
          color: Colors.grey[800],
          child: const Icon(Icons.error_outline, color: Colors.white24),
        );
      },
    );
  }
}
