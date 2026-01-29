import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_design.dart';
import '../../models/plant_analysis_model.dart';
import '../../../../core/utils/color_helper.dart';
import '../../services/plant_export_service.dart';
import '../../../../core/widgets/pdf_preview_screen.dart';
import '../../services/botany_service.dart';
import '../../models/botany_history_item.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../botany_history_screen.dart';
import 'plant_level_icon.dart';

class PlantResultCard extends StatefulWidget {
  final PlantAnalysisModel analysis;
  final String? imagePath;
  final VoidCallback onSave;
  final VoidCallback onShop;
  final bool isReadOnly;

  const PlantResultCard({
    super.key,
    required this.analysis,
    this.imagePath,
    required this.onSave,
    required this.onShop,
    this.isReadOnly = false,
  });

  @override
  State<PlantResultCard> createState() => _PlantResultCardState();
}

class _PlantResultCardState extends State<PlantResultCard>
    with SingleTickerProviderStateMixin {
  bool _isSaved = false;
  late TabController _tabController;
  final Color _themeColor = AppDesign.success;

  bool _isToxic = false;

  @override
  void initState() {
    super.initState();
    _isSaved = widget.isReadOnly; // If viewing from history, already saved
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_handleTabSelection);
    if (!widget.isReadOnly) {
      HapticFeedback.mediumImpact();
    }

    // Check for toxicity status to enable the alert button
    if (widget.analysis.segurancaBiofilia
                .segurancaDomestica['toxica_para_pets'] ==
            true ||
        widget.analysis.segurancaBiofilia
                .segurancaDomestica['toxica_para_criancas'] ==
            true ||
        widget.analysis.segurancaBiofilia
                .segurancaDomestica['is_toxic_to_pets'] ==
            true) {
      _isToxic = true;
    }

    // Auto-save logic removed: Handled by HomeView for consistency across non-pet domains.
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showToxicityWarning(BuildContext context, dynamic safety) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.safetyAlert),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: SingleChildScrollView(
            child: Text(
              safety['toxicity_details'] ??
                  AppLocalizations.of(context)!.noInformation,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.close),
          ),
        ],
      ),
    );
  }

  Widget _buildToxicityBadge(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white30)),
      child: Text(text,
          style: GoogleFonts.poppins(
              color: AppDesign.textPrimaryDark,
              fontSize: 12,
              fontWeight: FontWeight.bold)),
    );
  }

  Color get _statusColor =>
      ColorHelper.getPlantThemeColor(widget.analysis.urgency);
  IconData get _statusIcon => widget.analysis.isHealthy
      ? FontAwesomeIcons.leaf
      : FontAwesomeIcons.circleExclamation;

  /// Translates luminosity values from English to Portuguese
  String _translateLuminosity(String value) {
    final normalized = value.trim().toLowerCase();
    final l10n = AppLocalizations.of(context)!;

    if (normalized.contains('full sun') || normalized.contains('sol pleno')) {
      return l10n.plantSunFull;
    } else if (normalized.contains('partial shade') ||
        normalized.contains('meia sombra')) {
      return l10n.plantSunPartial;
    } else if (normalized.contains('full shade') ||
        normalized.contains('sombra total')) {
      return l10n.plantSunShade;
    } else if (normalized.contains('indirect light') ||
        normalized.contains('luz indireta')) {
      return l10n.plantSunIndirect;
    }

    // Return original if no match
    return value;
  }

  Future<void> _generatePDF() async {
    debugPrint("📄 [PLANT_PDF] Botão PDF clicado. Iniciando fluxo...");
    try {
      debugPrint("📄 [PLANT_PDF] Navegando para PdfPreviewScreen...");
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfPreviewScreen(
            title:
                '${AppLocalizations.of(context)!.pdfPlantDossierTitle}: ${widget.analysis.plantName}',
            buildPdf: (format) async {
              debugPrint("📄 [PLANT_PDF] Callback buildPdf acionado.");
              try {
                final pdf = await PlantExportService().generatePlantAnalysisReport(
                  analysis: widget.analysis,
                  strings: AppLocalizations.of(context)!,
                  imageFile:
                      widget.imagePath != null ? File(widget.imagePath!) : null,
                );
                debugPrint(
                    "📄 [PLANT_PDF] Documento PDF gerado com sucesso. Salvando bytes...");
                return pdf.save();
              } catch (e, stack) {
                debugPrint(
                    "❌ [PLANT_PDF] Erro fatal durante a geração interna do PDF: $e");
                debugPrint("Stack: $stack");
                rethrow;
              }
            },
          ),
        ),
      );
      debugPrint("📄 [PLANT_PDF] Fluxo de PDF concluído (retorno da tela).");
    } catch (e, stack) {
      debugPrint("❌ [PLANT_PDF] Erro ao tentar abrir tela de PDF: $e");
      debugPrint("Stack: $stack");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${AppLocalizations.of(context)!.errorGeneratingPdf}: $e'),
              backgroundColor: AppDesign.error),
        );
      }
    }
  }

  Widget _buildActionButton(
      IconData icon, String? label, Color color, VoidCallback onTap,
      {Color? backgroundColor}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor ??
              AppDesign.textPrimaryDark.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: backgroundColor ??
                  AppDesign.textPrimaryDark.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            if (label != null) ...[
              const SizedBox(width: 6),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    } else {
      setState(() {});
    }
  }

  Widget _buildTabContent(ScrollController? sc) {
    switch (_tabController.index) {
      case 0:
        return _buildHardwareTab(sc);
      case 1:
        // TEMPORARY DEBUG: Bypass Pro Lock
        return _buildSaudeTab(sc);
      case 2:
        // TEMPORARY DEBUG: Bypass Pro Lock
        return _buildBiosTab(sc);
      case 3:
        return _buildPropagacaoTab(sc);
      case 4:
        return _buildLifestyleTab(sc);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    // We removed DraggableScrollableSheet here because it's already used in the parent/HomeView logic
    final listenable = BotanyService().listenable;

    if (listenable != null) {
      return ValueListenableBuilder<Box<BotanyHistoryItem>>(
        valueListenable: listenable,
        builder: (context, box, _) {
          return _buildContent(context);
        },
      );
    }

    // Fallback if service is not ready
    return _buildContent(context);
  }

  Widget _buildContent(BuildContext context) {
    return Material(
      color: AppDesign.backgroundDark,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Handle Bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppDesign.textPrimaryDark.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // TOP ACTIONS ROW
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_isToxic) ...[
                  _buildActionButton(
                      Icons.warning_amber_rounded,
                      AppLocalizations.of(context)!.commonAlert,
                      AppDesign.error,
                      () => _showToxicityWarning(
                          context,
                          widget
                              .analysis.segurancaBiofilia.segurancaDomestica)),
                  const SizedBox(width: 12),
                ],
                _buildActionButton(Icons.picture_as_pdf_rounded, null,
                    Colors.white, _generatePDF,
                    backgroundColor: Colors.transparent),
                const SizedBox(width: 12),

                // AUTO-SAVE INDICATOR (ReadOnly)
                Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: _themeColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle),
                    child: Icon(Icons.check_circle_rounded,
                        color: _themeColor, size: 20)),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoSizeText(
                        widget.analysis.plantName,
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppDesign.textPrimaryDark,
                        ),
                        maxLines: 1,
                        minFontSize: 16,
                        overflow: TextOverflow.ellipsis,
                      ),
                      AutoSizeText(
                        widget.analysis.identificacao.nomeCientifico,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppDesign.textSecondaryDark,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        minFontSize: 10,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: _buildCareRequirements(widget.analysis),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: _statusColor.withValues(alpha: 0.5)),
                  ),
                  child: Icon(_statusIcon, color: _statusColor, size: 24),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // TabBar
          Container(
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(
                      color: AppDesign.textPrimaryDark.withValues(alpha: 0.1))),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: _themeColor,
              labelColor: _themeColor,
              unselectedLabelColor: AppDesign.textSecondaryDark,
              isScrollable: true,
              tabs: [
                Tab(
                    text: AppLocalizations.of(context)!
                        .tabHardware
                        .toUpperCase()),
                Tab(
                    text:
                        AppLocalizations.of(context)!.tabHealth.toUpperCase()),
                Tab(text: AppLocalizations.of(context)!.tabBios.toUpperCase()),
                Tab(
                    text: AppLocalizations.of(context)!
                        .tabPropagation
                        .toUpperCase()),
                Tab(
                    text: AppLocalizations.of(context)!
                        .tabLifestyle
                        .toUpperCase()),
              ],
            ),
          ),

          // TabBarView
          Expanded(
            child: _buildTabContent(
                null), // ScrollController is managed by ListView itself now
          ),

          // Navigation to History
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppDesign.backgroundDark,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.05),
                  offset: const Offset(0, -4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const BotanyHistoryScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _themeColor, // AppDesign.success / Plant Color
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.plantAnalysisList,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 1: HARDWARE (Survivor Guide) ---
  Widget _buildHardwareTab(ScrollController? sc) {
    final surv = widget.analysis.sobrevivencia;
    final alertS = widget.analysis.alertasSazonais;
    return ListView(
      controller: sc,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      children: [
        // Localized Strings
        Text(AppLocalizations.of(context)!.labelTrafficLight,
            style: _tabTitleStyle),
        const SizedBox(height: 16),
        _buildSurvivorRow(
            "☀️ ${AppLocalizations.of(context)!.plantNeedSun.toUpperCase()}",
            _translateLuminosity(surv.luminosidade['type']?.toString() ??
                surv.luminosidade['tipo']?.toString() ??
                AppLocalizations.of(context)!.noInformation),
            surv.luminosidade['explanation']?.toString() ??
                surv.luminosidade['explicacao']?.toString() ??
                AppLocalizations.of(context)!.noInformation,
            Colors.amber),
        _buildSurvivorRow(
            "💧 ${AppLocalizations.of(context)!.plantNeedWater.toUpperCase()}",
            surv.regimeHidrico['frequency']?.toString() ??
                surv.regimeHidrico['frequencia_ideal']?.toString() ??
                AppLocalizations.of(context)!.noInformation,
            surv.regimeHidrico['watering_method']?.toString() ??
                surv.regimeHidrico['method']?.toString() ??
                surv.regimeHidrico['método_rega']?.toString() ??
                AppLocalizations.of(context)!.directSoilWatering,
            Colors.blue),
        _buildSurvivorRow(
            "🪴 ${AppLocalizations.of(context)!.plantNeedSoil.toUpperCase()}",
            surv.soloENutricao['soil_type']?.toString() ??
                surv.soloENutricao['tipo_solo']?.toString() ??
                surv.soloENutricao['composition']?.toString() ??
                AppLocalizations.of(context)!.noInformation,
            surv.soloENutricao['fertilizer']?.toString() ??
                surv.soloENutricao['adubo_recomendado']?.toString() ??
                AppLocalizations.of(context)!.asNeeded,
            Colors.brown),
        const SizedBox(height: 24),
        _buildSectionCard(
          title: AppLocalizations.of(context)!.plantSeasonAdjust,
          icon: Icons.calendar_month,
          color: AppDesign.info,
          child: Column(
            children: [
              _buildSeasonRow(
                  AppLocalizations.of(context)!.seasonWinter, alertS.inverno),
              _buildSeasonRow(
                  AppLocalizations.of(context)!.seasonSummer, alertS.verao),
            ],
          ),
        ),
      ],
    );
  }

  // --- TAB 2: SAÚDE ---
  Widget _buildSaudeTab(ScrollController? sc) {
    final saude = widget.analysis.saude;
    return ListView(
      controller: sc,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      children: [
        _buildSectionCard(
          title: AppLocalizations.of(context)!.plantClinicalDiagnosis,
          icon: FontAwesomeIcons.stethoscope,
          color: _statusColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(saude.condicao,
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppDesign.textPrimaryDark)),
              const SizedBox(height: 8),
              Text(
                  saude.detalhes.toLowerCase().contains('sem diagnóstico')
                      ? AppLocalizations.of(context)!.plantNoSpecificDiagnosis
                      : saude.detalhes,
                  style: GoogleFonts.poppins(
                      color: AppDesign.textSecondaryDark, fontSize: 13)),
              if (!widget.analysis.isHealthy) ...[
                const SizedBox(height: 16),
                _buildInfoLabel(
                    "${AppLocalizations.of(context)!.plantUrgency}:",
                    widget.analysis.urgency),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildSectionCard(
          title: AppLocalizations.of(context)!.plantRecoveryPlan,
          icon: FontAwesomeIcons.kitMedical,
          color: AppDesign.error,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: SingleChildScrollView(
              child: Text(saude.planoRecuperacao,
                  style: GoogleFonts.poppins(
                      color: AppDesign.textPrimaryDark, height: 1.5)),
            ),
          ),
        ),
      ],
    );
  }

  // --- TAB 3: BIOS (Security & Well-being) ---
  Widget _buildBiosTab(ScrollController? sc) {
    final bios = widget.analysis.segurancaBiofilia;
    return ListView(
      controller: sc,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      children: [
        _buildSectionCard(
          title: AppLocalizations.of(context)!
              .plantHomeSafety, // "Segurança Doméstica"
          icon: Icons.security,
          color: AppDesign.error,
          child: Column(
            children: [
              _buildToggleInfo(
                  "${AppLocalizations.of(context)!.plantDangerPets} 🐾",
                  (bios.segurancaDomestica['toxica_para_pets'] == true ||
                      bios.segurancaDomestica['is_toxic_to_pets'] == true)),
              _buildToggleInfo(
                  "${AppLocalizations.of(context)!.plantDangerKids} 👶",
                  (bios.segurancaDomestica['toxica_para_criancas'] == true ||
                      bios.segurancaDomestica['is_toxic_to_children'] == true)),
              const SizedBox(height: 12),
              Text(
                  bios.segurancaDomestica['sintomas_ingestao']?.toString() ??
                      bios.segurancaDomestica['toxicity_details']?.toString() ??
                      AppLocalizations.of(context)!.plantNoAlerts,
                  style: GoogleFonts.poppins(
                      color: AppDesign.textSecondaryDark, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildSectionCard(
          title: AppLocalizations.of(context)!
              .plantBioPower, // "Poderes Biofílicos"
          icon: Icons.auto_awesome,
          color: AppDesign.primary.withValues(alpha: 0.7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProgressBar(
                  AppLocalizations.of(context)!.plantAirScore,
                  ((bios.poderesBiofilicos['purificacao_ar_score'] ??
                              bios.poderesBiofilicos[
                                  'air_purification_score'] ??
                              5) as num)
                          .toDouble() /
                      10.0,
                  AppDesign.success),
              const SizedBox(height: 16),
              _buildInfoLabel(
                  "${AppLocalizations.of(context)!.plantHumidification}:",
                  bios.poderesBiofilicos['umidificacao_natural']?.toString() ??
                      AppLocalizations.of(context)!.noInformation),
              _buildInfoLabel(
                  "${AppLocalizations.of(context)!.plantWellness}:",
                  bios.poderesBiofilicos['impacto_bem_estar']?.toString() ??
                      bios.poderesBiofilicos['wellness_impact']?.toString() ??
                      AppLocalizations.of(context)!.noInformation),
            ],
          ),
        ),
      ],
    );
  }

  // --- TAB 4: PROPAGAÇÃO ---
  Widget _buildPropagacaoTab(ScrollController? sc) {
    final prop = widget.analysis.propagacao;
    final eco = widget.analysis.ecossistema;
    return ListView(
      controller: sc,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      children: [
        _buildSectionCard(
          title: AppLocalizations.of(context)!.plantPropagationEngine,
          icon: Icons.copy,
          color: AppDesign.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoLabel(
                  "${AppLocalizations.of(context)!.plantMethod}:", prop.metodo),
              _buildInfoLabel(
                  "${AppLocalizations.of(context)!.plantDifficulty}:",
                  prop.dificuldade),
              const Divider(color: Colors.white12),
              Text("${AppLocalizations.of(context)!.plantStepByStep}:",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 12)),
              const SizedBox(height: 8),
              Text(prop.passoAPasso,
                  style: GoogleFonts.poppins(
                      color: AppDesign.textPrimaryDark,
                      fontSize: 13,
                      height: 1.5)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildSectionCard(
          title: AppLocalizations.of(context)!.plantEcoIntel,
          icon: Icons.group,
          color: AppDesign.info,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoLabel(
                  "${AppLocalizations.of(context)!.plantCompanions}:",
                  (eco.plantasParceiras as List? ?? []).join(', ')),
              _buildInfoLabel("${AppLocalizations.of(context)!.plantAvoid}:",
                  (eco.plantasConflitantes as List? ?? []).join(', ')),
              _buildInfoLabel(
                  "${AppLocalizations.of(context)!.plantRepellent}:",
                  eco.repelenteNatural),
            ],
          ),
        ),
      ],
    );
  }

  // --- TAB 5: LIFESTYLE ---
  Widget _buildLifestyleTab(ScrollController? sc) {
    final lifestyle = widget.analysis.lifestyle;
    final estetica = widget.analysis.estetica;
    return ListView(
      controller: sc,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      children: [
        _buildSectionCard(
          title: AppLocalizations.of(context)!.plantFengShui,
          icon: Icons.home,
          color: AppDesign.warning,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoLabel(
                  "${AppLocalizations.of(context)!.plantPlacement}:",
                  lifestyle.posicionamentoIdeal),
              const SizedBox(height: 8),
              _buildInfoLabel(
                  "${AppLocalizations.of(context)!.plantSymbolism}:",
                  lifestyle.simbolismo),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildSectionCard(
          title: AppLocalizations.of(context)!.plantLivingAesthetic,
          icon: Icons.palette,
          color: AppDesign.warning,
          child: Column(
            children: [
              _buildInfoLabel(
                  "${AppLocalizations.of(context)!.plantFlowering}:",
                  estetica.epocaFloracao),
              _buildInfoLabel(
                  "${AppLocalizations.of(context)!.plantFlowerColor}:",
                  estetica.corDasFlores),
              _buildInfoLabel("${AppLocalizations.of(context)!.plantGrowth}:",
                  estetica.velocidadeCrescimento),
              _buildInfoLabel("${AppLocalizations.of(context)!.plantMaxSize}:",
                  estetica.tamanhoMaximo),
            ],
          ),
        ),
      ],
    );
  }

  // --- HELPERS ---

  Widget _buildSurvivorRow(
      String title, String type, String desc, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title,
                  style: GoogleFonts.poppins(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              const Spacer(),
              _buildHardwareBadge(type, color),
            ],
          ),
          const SizedBox(height: 8),
          Text(desc,
              style: GoogleFonts.poppins(
                  color: AppDesign.textSecondaryDark, fontSize: 12),
              overflow: TextOverflow.visible),
        ],
      ),
    );
  }

  Widget _buildHardwareBadge(String label, Color color) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 100),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Text(label,
          style: const TextStyle(
              color: AppDesign.backgroundDark,
              fontWeight: FontWeight.bold,
              fontSize: 10),
          overflow: TextOverflow.ellipsis),
    );
  }

  Widget _buildSectionCard(
      {required String title,
      required IconData icon,
      required Color color,
      required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppDesign.textPrimaryDark.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppDesign.textPrimaryDark.withValues(alpha: 0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(title,
                      style: GoogleFonts.poppins(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                      overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildToggleInfo(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: AppDesign.textSecondaryDark, fontSize: 13),
                  overflow: TextOverflow.ellipsis)),
          Icon(value ? Icons.dangerous : Icons.check_circle,
              color: value ? AppDesign.error : AppDesign.success, size: 18),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, double percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppDesign.textSecondaryDark, fontSize: 12)),
            Text("${(percent * 100).toInt()}%",
                style: TextStyle(
                    color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        LinearPercentIndicator(
            lineHeight: 8,
            percent: percent.clamp(0.0, 1.0),
            progressColor: color,
            backgroundColor: AppDesign.textPrimaryDark.withValues(alpha: 0.1),
            barRadius: const Radius.circular(4),
            padding: EdgeInsets.zero,
            animation: true),
      ],
    );
  }

  Widget _buildInfoLabel(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppDesign.textSecondaryDark,
                  fontSize: 12)),
          const SizedBox(width: 6),
          Expanded(
              child: Text(
                  value
                      .replaceAll('veterinário', 'Vet')
                      .replaceAll('Veterinário', 'Vet')
                      .replaceAll('aproximadamente', '±')
                      .replaceAll('Aproximadamente', '±'),
                  style: const TextStyle(
                      color: AppDesign.textPrimaryDark, fontSize: 12),
                  overflow: TextOverflow.visible)),
        ],
      ),
    );
  }

  Widget _buildSeasonRow(String season, String alert) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(season,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppDesign.textPrimaryDark,
                  fontSize: 13)),
          Text(alert,
              style: const TextStyle(
                  color: AppDesign.textSecondaryDark, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCareRequirements(PlantAnalysisModel analysis) {
    final surv = analysis.sobrevivencia;

    // Extract values
    final sun = surv.luminosidade['type']?.toString() ??
        surv.luminosidade['tipo']?.toString();
    final water = surv.regimeHidrico['frequency']?.toString() ??
        surv.regimeHidrico['frequencia_ideal']?.toString();
    final soil = surv.soloENutricao['type']?.toString() ??
        surv.soloENutricao['tipo']?.toString();

    // Levels 1-3
    final sunLevel = _parseLevel(sun, 'sun');
    final waterLevel = _parseLevel(water, 'water');
    final soilLevel = _parseLevel(soil, 'soil');

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _buildCareIconWithLabel(sunLevel, PlantRequirementType.sun,
            AppLocalizations.of(context)!.labelSun),
        const SizedBox(width: 20),
        _buildCareIconWithLabel(waterLevel, PlantRequirementType.water,
            AppLocalizations.of(context)!.labelWater),
        const SizedBox(width: 20),
        _buildCareIconWithLabel(soilLevel, PlantRequirementType.soil,
            AppLocalizations.of(context)!.labelSoil),
      ],
    );
  }

  Widget _buildCareIconWithLabel(
      int level, PlantRequirementType type, String label) {
    Color color;
    switch (type) {
      case PlantRequirementType.sun:
        color = Colors.orange;
        break;
      case PlantRequirementType.water:
        color = Colors.blue;
        break;
      case PlantRequirementType.soil:
        color = Colors.brown;
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PlantLevelIcon(level: level, type: type, size: 24),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: color.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  int _parseLevel(String? value, String type) {
    if (value == null) return 1;
    final s = value.toLowerCase();

    if (type == 'sun') {
      if (s.contains('pleno') || s.contains('full') || s.contains('direta')) {
        return 3;
      }
      if (s.contains('meia') || s.contains('partial') || s.contains('indireta')) {
        return 2;
      }
      return 1;
    }
    if (type == 'water') {
      // Expanded keywords for water detection
      if (s.contains('abundante') ||
          s.contains('high') ||
          s.contains('frequente') ||
          s.contains('muito')) {
        return 3;
      }
      if (s.contains('moderada') ||
          s.contains('average') ||
          s.contains('regular') ||
          s.contains('semanal')) {
        return 2;
      }
      return 1;
    }
    if (type == 'soil') {
      if (s.contains('rico') || s.contains('rich') || s.contains('fértil')) {
        return 3;
      }
      if (s.contains('drenado') || s.contains('drain') || s.contains('arenoso')) {
        return 1;
      }
      return 2;
    }
    return 1;
  }

  TextStyle get _tabTitleStyle => GoogleFonts.poppins(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: AppDesign.textPrimaryDark);
}
