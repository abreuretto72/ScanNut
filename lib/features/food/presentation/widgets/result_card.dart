import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/food_analysis_model.dart';
import '../../../../core/utils/color_helper.dart';
import '../../../../core/providers/settings_provider.dart';

class ResultCard extends ConsumerStatefulWidget {
  final FoodAnalysisModel analysis;
  final VoidCallback onSave;

    const ResultCard({Key? key, required this.analysis, required this.onSave}) : super(key: key);

  @override
  ConsumerState<ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends ConsumerState<ResultCard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        HapticFeedback.selectionClick();
      }
    });
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color get _themeColor => ColorHelper.getFoodThemeColor(
        calories: widget.analysis.estimatedCalories,
        risks: widget.analysis.risks,
        benefits: widget.analysis.benefits,
      );

  double get _vitalityScore {
    double score = 8.0;
    if (widget.analysis.risks.isNotEmpty) {
      score -= widget.analysis.risks.length * 0.5;
    }
    if (widget.analysis.benefits.isNotEmpty) {
      score += widget.analysis.benefits.length * 0.3;
    }
    return score.clamp(1.0, 10.0);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.grey.shade900.withValues(alpha: 0.95),
                    Colors.black.withValues(alpha: 0.98),
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Handle Bar
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white30,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () => _showRecipesDialog(context),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.analysis.itemName
                                            .replaceAll('aproximadamente', '+-')
                                            .replaceAll('Aproximadamente', '+-'),
                                        style: GoogleFonts.poppins(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          decoration: TextDecoration.underline,
                                          decorationColor: Colors.white30,
                                          decorationStyle: TextDecorationStyle.dotted,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(
                                      Icons.menu_book_rounded,
                                      color: Colors.white54,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                "Toque para ver receitas ✨",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: _themeColor,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showVitalityScoreDialog(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _themeColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _themeColor.withValues(alpha: 0.5)),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _vitalityScore.toStringAsFixed(1),
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _themeColor,
                                  ),
                                ),
                                Text(
                                  "Score",
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: _themeColor.withValues(alpha: 0.8),
                                  ),
                                ),
                                Icon(
                                  Icons.info_outline,
                                  size: 12,
                                  color: _themeColor.withValues(alpha: 0.6),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // TabBar
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: _themeColor,
                      indicatorWeight: 3,
                      labelColor: _themeColor,
                      unselectedLabelColor: Colors.white54,
                      labelStyle: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      tabs: const [
                        Tab(text: "Visão Geral"),
                        Tab(text: "Detalhes"),
                        Tab(text: "Dicas"),
                      ],
                    ),
                  ),

                  // TabBarView
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(scrollController),
                        _buildDetailsTab(scrollController),
                        _buildInsightsTab(scrollController),
                      ],
                    ),
                  ),

                  // Footer Button
                  _buildFooter(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverviewTab(ScrollController scrollController) {
    final settings = ref.watch(settingsProvider);
    final dailyGoal = settings.dailyCalorieGoal;
    
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(24),
      children: [
        // Calories Card with Circle
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _themeColor.withValues(alpha: 0.2),
                _themeColor.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _themeColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              CircularPercentIndicator(
                radius: 70.0,
                lineWidth: 10.0,
                animation: true,
                animationDuration: 1200,
                percent: (widget.analysis.estimatedCalories / dailyGoal).clamp(0.0, 1.0),
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${widget.analysis.estimatedCalories}",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "kcal",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
                circularStrokeCap: CircularStrokeCap.round,
                backgroundColor: Colors.white10,
                progressColor: _themeColor,
              ),
              const SizedBox(height: 16),
              Text(
                "Calorias Totais",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "${((widget.analysis.estimatedCalories / dailyGoal) * 100).toStringAsFixed(0)}% da meta diária ($dailyGoal kcal)",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // PIE CHART FOR MACROS
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white10),
          ),
          child: PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 40,
              sections: [
                PieChartSectionData(
                  value: _parseGrams(widget.analysis.macronutrients.protein),
                  color: Colors.blue,
                  title: 'Prot',
                  radius: 50,
                  titleStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                PieChartSectionData(
                  value: _parseGrams(widget.analysis.macronutrients.carbs),
                  color: Colors.orange,
                  title: 'Carb',
                  radius: 50,
                  titleStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                PieChartSectionData(
                  value: _parseGrams(widget.analysis.macronutrients.fats),
                  color: Colors.purple,
                  title: 'Gord',
                  radius: 50,
                  titleStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Macros Dashboard
        Text(
          "Distribuição de Macronutrientes",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),

        // Macros em Column (sem overflow)
        _buildMacroCard(
          "Proteína",
          widget.analysis.macronutrients.protein,
          Icons.fitness_center,
          Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildMacroCard(
          "Carboidratos",
          widget.analysis.macronutrients.carbs,
          Icons.grain,
          Colors.orange,
        ),
        const SizedBox(height: 12),
        _buildMacroCard(
          "Gorduras",
          widget.analysis.macronutrients.fats,
          Icons.opacity,
          Colors.purple,
        ),

        const SizedBox(height: 24),

        // Quick Stats
        Text(
          "Resumo Rápido",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _showBenefitsDialog(context),
                child: _buildStatCard(
                  "${widget.analysis.benefits.length}",
                  "Benefícios",
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => _showAlertsDialog(context),
                child: _buildStatCard(
                  "${widget.analysis.risks.length}",
                  "Alertas",
                  Icons.warning_amber_rounded,
                  Colors.orange,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Vitality Score Card (Tappable)
        GestureDetector(
          onTap: () => _showVitalityScoreDialog(context),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _themeColor.withValues(alpha: 0.3),
                  _themeColor.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _themeColor.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _themeColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.favorite,
                    color: _themeColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Score de Vitalidade",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            _vitalityScore.toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: _themeColor,
                            ),
                          ),
                          Text(
                            " / 10",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Progress bar
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularPercentIndicator(
                    radius: 30,
                    lineWidth: 6,
                    percent: _vitalityScore / 10,
                    center: Text(
                      "${(_vitalityScore * 10).toStringAsFixed(0)}%",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  progressColor: _themeColor,
                  backgroundColor: Colors.white10,
                  circularStrokeCap: CircularStrokeCap.round,
                ),
              ),
            ],
          ),
        ),
        ),
      ],
    );
  }

  Widget _buildMacroCard(String label, String value, IconData icon, Color color) {
    // Extract numeric value and clean up
    final numericValue = value
        .split('(').first
        .trim()
        .replaceAll('aproximadamente', '+-')
        .replaceAll('Aproximadamente', '+-');

    return GestureDetector(
      onTap: () => _showMacronutrientDialog(context, label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.2),
              color.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
            ),
            Text(
              numericValue,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.info_outline,
              size: 16,
              color: color.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab(ScrollController scrollController) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          "Informações Detalhadas",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),

        // Protein Details
        if (widget.analysis.macronutrients.protein.contains('('))
          _buildDetailCard(
            "Proteína",
            widget.analysis.macronutrients.protein,
            Icons.fitness_center,
          ),

        // Carbs Details
        if (widget.analysis.macronutrients.carbs.contains('('))
          _buildDetailCard(
            "Carboidratos",
            widget.analysis.macronutrients.carbs,
            Icons.grain,
          ),

        // Fats Details
        if (widget.analysis.macronutrients.fats.contains('('))
          _buildDetailCard(
            "Gorduras",
            widget.analysis.macronutrients.fats,
            Icons.opacity,
          ),

        const SizedBox(height: 16),
        const Text(
          'Nota: Esta é uma análise feita por IA e não substitui um diagnóstico de nutricionista.',
          style: TextStyle(color: Colors.white54, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInsightsTab(ScrollController scrollController) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(24),
      children: [
        // Benefits
        if (widget.analysis.benefits.isNotEmpty) ...[
          Text(
            "Benefícios",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          ...widget.analysis.benefits.map((b) => _buildInsightCard(b, true)),
          const SizedBox(height: 24),
        ],

        // Risks
        if (widget.analysis.risks.isNotEmpty) ...[
          Text(
            "Pontos de Atenção",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 16),
          ...widget.analysis.risks.map((r) => _buildInsightCard(r, false)),
          const SizedBox(height: 24),
        ],

        // Advice
        _buildAdviceCard(),
      ],
    );
  }

  Widget _buildMacroRow(String label, String value, IconData icon) {
    final numericValue = value.split('(').first.trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: _themeColor, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const Spacer(),
          Text(
            numericValue,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String label, String fullValue, IconData icon) {
    return GestureDetector(
      onTap: () => _showMacronutrientDialog(context, label),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: _themeColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _themeColor,
                    ),
                  ),
                ),
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: _themeColor.withValues(alpha: 0.6),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              fullValue,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(String text, bool isPositive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isPositive
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPositive
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: ListTile(
        leading: Icon(
          isPositive ? Icons.check_circle : Icons.warning_amber_rounded,
          color: isPositive ? Colors.greenAccent : Colors.orangeAccent,
        ),
        title: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ),
    );
  }

  Widget _buildAdviceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tips_and_updates, color: _themeColor, size: 20),
              const SizedBox(width: 8),
              Text(
                "Dica Nutricional",
                style: GoogleFonts.poppins(
                  color: _themeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.analysis.advice,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: InkWell(
          onTap: () {
            if (!_isSaved) {
              setState(() => _isSaved = true);
              HapticFeedback.heavyImpact();
              widget.onSave();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isSaved
                    ? [Colors.green, Colors.green.shade700]
                    : [_themeColor, _themeColor.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _themeColor.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isSaved ? Icons.check_circle : Icons.bookmark_add_outlined,
                  color: _isSaved ? Colors.white : Colors.black,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  _isSaved ? "Salvo!" : "Salvar no Diário",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _isSaved ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showVitalityScoreDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(20),
        title: Row(
          children: [
            Icon(Icons.favorite, color: _themeColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Score de Vitalidade',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Score
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _themeColor.withValues(alpha: 0.3),
                        _themeColor.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _themeColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _vitalityScore.toStringAsFixed(1),
                        style: GoogleFonts.poppins(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: _themeColor,
                        ),
                      ),
                      Text(
                        ' / 10',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Explanation
                Text(
                  'O que é?',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pontuação de 1 a 10 que indica o quão saudável é este alimento.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),

                // How it's calculated
                Text(
                  'Como é calculado?',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                _buildScoreItem('✅', 'Benefícios', '+0.3 pts', Colors.green),
                _buildScoreItem('⚠️', 'Alertas', '-0.5 pts', Colors.orange),
                const SizedBox(height: 12),

                // Scale
                Text(
                  'Escala',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                _buildScaleItem('9-10', 'Excelente', Colors.green),
                _buildScaleItem('7-9', 'Muito Bom', Colors.lightGreen),
                _buildScaleItem('5-7', 'Bom', Colors.yellow),
                _buildScaleItem('3-5', 'Regular', Colors.orange),
                _buildScaleItem('1-3', 'Atenção', Colors.red),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Entendi',
              style: GoogleFonts.poppins(
                color: _themeColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreItem(String emoji, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScaleItem(String range, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            range,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            '•',
            style: TextStyle(color: Colors.white30),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white54,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _showBenefitsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Benefícios',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.analysis.benefits.isEmpty)
                  Text(
                    'Nenhum benefício específico identificado.',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  )
                else
                  ...widget.analysis.benefits.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${entry.key + 1}',
                              style: GoogleFonts.poppins(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Fechar',
              style: GoogleFonts.poppins(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAlertsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Pontos de Atenção',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.analysis.risks.isEmpty)
                  Text(
                    'Nenhum ponto de atenção identificado.',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  )
                else
                  ...widget.analysis.risks.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${entry.key + 1}',
                              style: GoogleFonts.poppins(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Fechar',
              style: GoogleFonts.poppins(
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMacronutrientDialog(BuildContext context, String macroType) {
    final Map<String, Map<String, dynamic>> macroInfo = {
      'Proteína': {
        'icon': Icons.fitness_center,
        'color': Colors.blue,
        'title': 'Proteínas',
        'description': 'As proteínas são macronutrientes essenciais formados por aminoácidos, fundamentais para a construção e reparação de tecidos.',
        'functions': [
          'Construção e reparação muscular',
          'Produção de enzimas e hormônios',
          'Fortalecimento do sistema imunológico',
          'Transporte de nutrientes no sangue',
        ],
        'sources': [
          'Carnes (frango, peixe, carne vermelha)',
          'Ovos e laticínios',
          'Leguminosas (feijão, lentilha, grão-de-bico)',
          'Nozes e sementes',
        ],
        'recommendation': 'Recomendação: 0.8-1.2g por kg de peso corporal/dia',
      },
      'Carboidratos': {
        'icon': Icons.grain,
        'color': Colors.amber,
        'title': 'Carboidratos',
        'description': 'Os carboidratos são a principal fonte de energia do corpo, sendo convertidos em glicose para fornecer combustível às células.',
        'functions': [
          'Fonte primária de energia',
          'Combustível para o cérebro e sistema nervoso',
          'Preservação da massa muscular',
          'Regulação do metabolismo',
        ],
        'sources': [
          'Cereais integrais (arroz, aveia, quinoa)',
          'Pães e massas integrais',
          'Frutas e vegetais',
          'Batata, mandioca e tubérculos',
        ],
        'recommendation': 'Recomendação: 45-65% das calorias diárias',
      },
      'Gorduras': {
        'icon': Icons.opacity,
        'color': Colors.orange,
        'title': 'Gorduras',
        'description': 'As gorduras são macronutrientes essenciais que fornecem energia concentrada e são vitais para diversas funções corporais.',
        'functions': [
          'Absorção de vitaminas A, D, E e K',
          'Produção de hormônios',
          'Proteção de órgãos vitais',
          'Isolamento térmico do corpo',
        ],
        'sources': [
          'Abacate e azeite de oliva',
          'Peixes gordurosos (salmão, sardinha)',
          'Nozes, castanhas e sementes',
          'Óleo de coco e manteiga ghee',
        ],
        'recommendation': 'Recomendação: 20-35% das calorias diárias',
      },
    };

    final info = macroInfo[macroType]!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(20),
        title: Row(
          children: [
            Icon(info['icon'] as IconData, color: info['color'] as Color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                info['title'] as String,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                Text(
                  info['description'] as String,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),

                // Functions
                Text(
                  'Funções Principais',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                ...(info['functions'] as List<String>).map((function) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: info['color'] as Color,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            function,
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 16),

                // Sources
                Text(
                  'Principais Fontes',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                ...(info['sources'] as List<String>).map((source) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.restaurant,
                          size: 16,
                          color: info['color'] as Color,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            source,
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 16),

                // Recommendation
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (info['color'] as Color).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (info['color'] as Color).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: info['color'] as Color,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          info['recommendation'] as String,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Entendi',
              style: GoogleFonts.poppins(
                color: info['color'] as Color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRecipesDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(20),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.restaurant_menu_rounded, color: _themeColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Receitas Inteligentes',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Com ${widget.analysis.itemName}',
                          style: GoogleFonts.poppins(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white10),

            // Content
            Expanded(
              child: widget.analysis.recipes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.no_meals_rounded,
                            size: 64,
                            color: Colors.white24,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhuma receita encontrada.',
                            style: GoogleFonts.poppins(
                              color: Colors.white54,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tente analisar outro alimento.',
                            style: GoogleFonts.poppins(
                              color: Colors.white38,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: widget.analysis.recipes.length,
                      itemBuilder: (context, index) {
                        final recipe = widget.analysis.recipes[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              dividerColor: Colors.transparent,
                            ),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              childrenPadding: const EdgeInsets.all(16),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _themeColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.restaurant,
                                  color: _themeColor,
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                recipe.name,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Row(
                                  children: [
                                    _buildRecipeBadge(
                                      Icons.timer,
                                      recipe.prepTime,
                                      Colors.blue,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildRecipeBadge(
                                      Icons.speed,
                                      recipe.difficulty,
                                      recipe.difficulty == 'Fácil'
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                  ],
                                ),
                              ),
                              children: [
                                // Extra Ingredients
                                if (recipe.extraIngredients.isNotEmpty) ...[
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '🛒 Ingredientes Extras:',
                                      style: GoogleFonts.poppins(
                                        color: _themeColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: recipe.extraIngredients
                                        .map((ingredient) => Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white10,
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                ingredient,
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // Instructions
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '👨‍🍳 Modo de Preparo:',
                                    style: GoogleFonts.poppins(
                                      color: _themeColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...recipe.instructions.asMap().entries.map(
                                      (entry) => Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${entry.key + 1}.',
                                              style: GoogleFonts.poppins(
                                                color: _themeColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                entry.value,
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white70,
                                                  fontSize: 14,
                                                  height: 1.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  double _parseGrams(String value) {
    try {
      // Regex to find numbers, handles ±, g, and spaces
      final RegExp regExp = RegExp(r'(\d+)');
      final match = regExp.firstMatch(value);
      if (match != null) {
        return double.parse(match.group(1)!);
      }
      return 1.0; // Fallback
    } catch (e) {
      return 1.0;
    }
  }
}
