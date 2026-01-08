import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/widgets/pro_access_wrapper.dart';
import '../../../l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:printing/printing.dart';
import '../services/nutrition_service.dart';
import '../models/food_analysis_model.dart';
import 'widgets/result_card.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/widgets/pdf_action_button.dart';
import '../../../core/services/export_service.dart';
import '../../../core/widgets/pdf_preview_screen.dart';
import '../../../nutrition/domain/usecases/scan_to_nutrition_mapper.dart';
import '../../../nutrition/presentation/controllers/nutrition_providers.dart';
import '../../../nutrition/data/models/meal_log.dart';
import '../../../nutrition/data/models/plan_day.dart';
import '../../../core/theme/app_design.dart';

class FoodResultScreen extends ConsumerStatefulWidget {
  final FoodAnalysisModel analysis;
  final File? imageFile;
  final VoidCallback onSave;
  final bool isReadOnly;

  const FoodResultScreen({
    Key? key, 
    required this.analysis, 
    this.imageFile, 
    required this.onSave,
    this.isReadOnly = false,
  }) : super(key: key);

  @override
  ConsumerState<FoodResultScreen> createState() => _FoodResultScreenState();
}

class _FoodResultScreenState extends ConsumerState<FoodResultScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  final Color _themeColor = AppDesign.foodOrange; // Orange Food Theme

  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scrollController = ScrollController();
    if (widget.isReadOnly) {
      _isSaved = true;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _generatePDF() async {
    try {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PdfPreviewScreen(
              title: 'Análise Nutricional: ${widget.analysis.identidade.nome}',
              buildPdf: (format) async {
                final pdf = await ExportService().generateFoodAnalysisReport(
                  analysis: widget.analysis,
                  imageFile: widget.imageFile,
                  strings: AppLocalizations.of(context)!,
                );
                return pdf.save();
              },
            ),
          ),
        );
    } catch (e) {
      debugPrint("Erro ao gerar PDF: $e");
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ao gerar PDF: $e'), backgroundColor: Colors.red),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dailyGoal = ref.read(settingsProvider).dailyCalorieGoal;

    return Scaffold(
      backgroundColor: Colors.black,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 350.0,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                PdfActionButton(
                  onPressed: _generatePDF,
                  color: Colors.white,
                ),
                IconButton(
                  icon: const Icon(Icons.check_circle, color: AppDesign.foodOrange), // Synced with Food Domain
                  onPressed: null, // No action needed
                  tooltip: 'Salvo Automaticamente',
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (widget.imageFile != null)
                      Hero(
                        tag: 'captured_food_image',
                        child: Image.file(
                          widget.imageFile!,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(color: Colors.grey.shade900),
                    
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.2),
                            Colors.black.withOpacity(0.8),
                            Colors.black,
                          ],
                          stops: const [0.5, 0.7, 0.9, 1.0],
                        ),
                      ),
                    ),

                    Positioned(
                      left: 20,
                      bottom: 80,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCalorieBadge(dailyGoal),
                          const SizedBox(height: 8),
                          Text(
                            (widget.analysis.identidade.nome == 'UNKNOWN_FOOD')
                                ? AppLocalizations.of(context)!.unknownFood
                                : widget.analysis.identidade.nome
                                    .replaceAll('aproximadamente', '±')
                                    .replaceAll('Aproximadamente', '±'),
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: const [
                                Shadow(blurRadius: 10, color: Colors.black54, offset: Offset(0, 2)),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: _themeColor,
                    indicatorWeight: 3,
                    labelColor: _themeColor,
                    unselectedLabelColor: Colors.white54,
                    isScrollable: true,
                    labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                    tabs: [
                      Tab(text: AppLocalizations.of(context)!.tabSummary),
                      Tab(text: AppLocalizations.of(context)!.tabHealth),
                      Tab(text: AppLocalizations.of(context)!.tabNutrients),
                      Tab(text: AppLocalizations.of(context)!.tabGastronomy),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildResumoTab(),
            _buildSaudeTab(),
            _buildNutrientesTab(),
            _buildGastronomiaTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieBadge(int dailyGoal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department_rounded, color: _themeColor, size: 16),
          const SizedBox(width: 6),
          Text(
            "${widget.analysis.macros.calorias100g} kcal / 100g",
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // --- TAB 1: RESUMO ---
  Widget _buildResumoTab() {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // _buildVitalityHeader removed as per user request (exclusivo para plantas)
          Text(l10n.foodVerdict, style: _sectionTitleStyle),
          const SizedBox(height: 8),
          Text(widget.analysis.analise.vereditoIa.replaceAll('aproximadamente', '±').replaceAll('Aproximadamente', '±'), style: GoogleFonts.poppins(color: Colors.white70, fontSize: 15, fontStyle: FontStyle.italic)),
          const SizedBox(height: 24),
          Text(l10n.foodPros, style: _sectionTitleStyle),
          const SizedBox(height: 12),
          ...widget.analysis.analise.pontosPositivos.map((p) => _buildPointRow(p.replaceAll('aproximadamente', '±').replaceAll('Aproximadamente', '±'), Icons.check_circle, AppDesign.foodOrange)),
          const SizedBox(height: 16),
          Text(l10n.foodCons, style: _sectionTitleStyle),
          const SizedBox(height: 12),
          ...widget.analysis.analise.pontosNegativos.map((p) => _buildPointRow(p.replaceAll('aproximadamente', '±').replaceAll('Aproximadamente', '±'), Icons.warning_rounded, Colors.orangeAccent)),
          const SizedBox(height: 20),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(l10n.foodDisclaimer, textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.white30, fontSize: 10)),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // --- TAB 2: SAÚDE ---
  Widget _buildSaudeTab() {
    final l10n = AppLocalizations.of(context)!;
    final performance = widget.analysis.performance;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGlassCard(
            title: l10n.foodBiohacking,
            icon: Icons.bolt,
            color: Colors.purpleAccent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProgressRow(l10n.foodSatietyIndex, performance.indiceSaciedade / 5.0, Colors.tealAccent),
                const SizedBox(height: 20),
                Text("${l10n.foodBodyBenefits}:", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...performance.pontosPositivosCorpo.map((p) => _buildPointRow(p, Icons.trending_up, Colors.tealAccent)),
                const SizedBox(height: 12),
                Text("${l10n.foodAttention}:", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...performance.pontosAtencaoCorpo.map((p) => _buildPointRow(p, Icons.priority_high, Colors.orangeAccent)),
                const Divider(color: Colors.white10, height: 24),
                _buildInfoRow("${l10n.foodFocusEnergy}:", performance.impactoFocoEnergia),
                _buildInfoRow("${l10n.foodIdealMoment}:", performance.momentoIdealConsumo),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildGlassCard(
            title: l10n.foodSafetyBio,
            icon: Icons.security,
            color: Colors.blueAccent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow("${l10n.foodCriticalAlerts}:", widget.analysis.identidade.alertaCritico),
                const SizedBox(height: 10),
                _buildInfoRow("${l10n.foodBioChem}:", widget.analysis.identidade.bioquimicaAlert),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(l10n.foodDisclaimer, textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.white30, fontSize: 10)),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // --- TAB 3: NUTRIENTES ---
  Widget _buildNutrientesTab() {
    final l10n = AppLocalizations.of(context)!;
    final macros = widget.analysis.macros;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.nutrientsAdvancedMacros, style: _sectionTitleStyle),
          const SizedBox(height: 16),
          _buildMacroDetailRow(l10n.nutrientsProteins, macros.proteinas, l10n.labelAminoProfile, Colors.blue),
          _buildMacroDetailRow(l10n.nutrientsCarbs, macros.carboidratosLiquidos, "${l10n.labelGlycemicImpact}: ${macros.indiceGlicemico}", Colors.amber),
          _buildMacroDetailRow(l10n.nutrientsFats, macros.gordurasPerfil, l10n.labelFattyAcids, Colors.red),
          const SizedBox(height: 24),
          
          ProAccessWrapper(
            featureName: l10n.featureMicrosTitle,
            featureDescription: l10n.featureMicrosDesc,
            featureIcon: FontAwesomeIcons.dna,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.nutrientsMinerals, style: _sectionTitleStyle),
                const SizedBox(height: 16),
                ...widget.analysis.micronutrientes.lista.map((n) => _buildNutrientLinear(n)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.cyanAccent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${l10n.nutrientsSynergy}: ${widget.analysis.micronutrientes.sinergiaNutricional}",
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.cyanAccent),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Disclaimer
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                l10n.foodDisclaimer,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.white30, fontSize: 10),
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // --- TAB 4: GASTRONOMIA ---
  Widget _buildGastronomiaTab() {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.recipesQuick, style: _sectionTitleStyle),
          const SizedBox(height: 16),
          ...widget.analysis.receitas.map((r) => _buildRecipeCard(r)),
          const SizedBox(height: 24),
          _buildGlassCard(
            title: l10n.recipesCulinaryIntel,
            icon: Icons.restaurant_menu,
            color: Colors.orangeAccent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow("${l10n.foodPreservation}:", widget.analysis.gastronomia.preservacaoNutrientes),
                const SizedBox(height: 16),
                _buildInfoRow("${l10n.foodSmartSwap}:", widget.analysis.gastronomia.smartSwap),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildGlassCard(
            title: l10n.recipesExpertTip,
            icon: Icons.lightbulb,
            color: Colors.amberAccent,
            child: Text(widget.analysis.gastronomia.dicaEspecialista.replaceAll('aproximadamente', '±').replaceAll('Aproximadamente', '±'), style: GoogleFonts.poppins(color: Colors.white, height: 1.5)),
          ),
          const SizedBox(height: 20),
          // Disclaimer
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                l10n.foodDisclaimer,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.white30, fontSize: 10),
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // --- HELPERS ---

  // --- HELPERS ---

  Color _getSemaforoColor(String status) {
    switch (status.toLowerCase()) {
      case 'verde': return AppDesign.foodOrange;
      case 'amarelo': return Colors.amberAccent;
      case 'vermelho': return Colors.redAccent;
      default: return AppDesign.foodOrange;
    }
  }

  Widget _buildVitalityHeader(Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white10,
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 35,
            lineWidth: 6,
            percent: widget.analysis.identidade.semaforoSaude.toLowerCase() == 'verde' ? 0.95 : (widget.analysis.identidade.semaforoSaude.toLowerCase() == 'amarelo' ? 0.6 : 0.3),
            progressColor: statusColor,
            center: Icon(Icons.shield_rounded, color: statusColor, size: 30),
            animation: true,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.analysis.identidade.statusProcessamento.toUpperCase(), 
                  style: GoogleFonts.poppins(color: statusColor, fontSize: 13, fontWeight: FontWeight.bold)
                ),
                Text("${AppLocalizations.of(context)!.labelTrafficLight}: ${widget.analysis.identidade.semaforoSaude}", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(ReceitaRapida recipe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(recipe.nome, style: GoogleFonts.poppins(color: _themeColor, fontWeight: FontWeight.bold, fontSize: 15))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: _themeColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: Text(recipe.tempoPreparo, style: GoogleFonts.poppins(color: _themeColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(recipe.instrucoes.replaceAll('aproximadamente', '±').replaceAll('Aproximadamente', '±'), style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required String title, required IconData icon, required Color color, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
          Text(value.replaceAll('aproximadamente', '±').replaceAll('Aproximadamente', '±'), style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildPointRow(String text, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(text.replaceAll('aproximadamente', '±').replaceAll('Aproximadamente', '±'), style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.8), fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, double percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 8),
        LinearPercentIndicator(
          lineHeight: 6,
          percent: percent.clamp(0.0, 1.0),
          progressColor: color,
          backgroundColor: Colors.white10,
          barRadius: const Radius.circular(3),
          padding: EdgeInsets.zero,
          animation: true,
        ),
      ],
    );
  }

  Widget _buildMacroDetailRow(String label, String value, String detail, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(width: 4, height: 40, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.poppins(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Flexible(
                      flex: 2,
                      child: Text(
                        value.replaceAll('aproximadamente', '±').replaceAll('Aproximadamente', '±'),
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: Text(
                        detail,
                        style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientLinear(NutrienteItem n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  n.nome,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 1,
                child: Text(
                  "${n.quantidade.replaceAll('aproximadamente', '±').replaceAll('Aproximadamente', '±')} (${n.percentualDv}%)",
                  style: GoogleFonts.poppins(color: _themeColor, fontSize: 11, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearPercentIndicator(
            lineHeight: 4,
            percent: (n.percentualDv / 100.0).clamp(0.0, 1.0),
            progressColor: _themeColor,
            backgroundColor: Colors.white10,
            barRadius: const Radius.circular(2),
            padding: EdgeInsets.zero,
            animation: true,
          ),
        ],
      ),
    );
  }

  /// Salva no histórico de alimentos
  Future<void> _saveToHistory() async {
    try {
      await NutritionService().saveFoodAnalysis(
        widget.analysis, 
        widget.imageFile
      );

      if (mounted) {
        setState(() {
          _isSaved = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Análise salva no histórico!'),
            backgroundColor: AppDesign.foodOrange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error saving to history: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Adiciona ao plano de hoje
  Future<void> _addToTodayPlan() async {
    try {
      final tipo = await _showMealTypeDialog();
      if (tipo == null) return;

      final currentPlan = ref.read(currentWeekPlanProvider);
      
      if (currentPlan == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Crie um plano semanal primeiro'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final todayPlan = currentPlan.getDayByDate(DateTime.now());
      if (todayPlan == null) return;

      final meal = ScanToNutritionMapper.createMealFromScan(
        analysis: widget.analysis,
        tipo: tipo,
      );

      todayPlan.meals.add(meal);
      await todayPlan.save();
      ref.read(currentWeekPlanProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Adicionado ao plano ($tipo)'),
            backgroundColor: AppDesign.foodOrange,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<String?> _showMealTypeDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text('Tipo de Refeição', style: GoogleFonts.poppins(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.free_breakfast, color: AppDesign.foodOrange),
              title: Text('Café da Manhã', style: GoogleFonts.poppins(color: Colors.white)),
              onTap: () => Navigator.pop(context, 'cafe'),
            ),
            ListTile(
              leading: Icon(Icons.lunch_dining, color: AppDesign.foodOrange),
              title: Text('Almoço', style: GoogleFonts.poppins(color: Colors.white)),
              onTap: () => Navigator.pop(context, 'almoco'),
            ),
            ListTile(
              leading: Icon(Icons.cookie, color: AppDesign.foodOrange),
              title: Text('Lanche', style: GoogleFonts.poppins(color: Colors.white)),
              onTap: () => Navigator.pop(context, 'lanche'),
            ),
            ListTile(
              leading: Icon(Icons.dinner_dining, color: AppDesign.foodOrange),
              title: Text('Jantar', style: GoogleFonts.poppins(color: Colors.white)),
              onTap: () => Navigator.pop(context, 'jantar'),
            ),
          ],
        ),
      ),
    );
  }



  TextStyle get _sectionTitleStyle => GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white);
}
