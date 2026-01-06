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
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_design.dart';

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

  AppLocalizations get l10n => AppLocalizations.of(context)!;

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
    final l10n = AppLocalizations.of(context)!;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppDesign.surfaceDark,
                  AppDesign.backgroundDark,
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
                        color: AppDesign.textSecondaryDark.withOpacity(0.3),
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
                                            .replaceAll('aproximadamente', '±')
                                            .replaceAll('Aproximadamente', '±'),
                                        style: GoogleFonts.poppins(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: AppDesign.textPrimaryDark,
                                          decoration: TextDecoration.underline,
                                          decorationColor: AppDesign.textSecondaryDark.withOpacity(0.3),
                                          decorationStyle: TextDecorationStyle.dotted,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(
                                      Icons.menu_book_rounded,
                                      color: AppDesign.textSecondaryDark,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                                Text(
                                  l10n.cardTapForRecipes,
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
                              color: _themeColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _themeColor.withOpacity(0.5)),
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
                                  l10n.cardScore,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: _themeColor.withOpacity(0.8),
                                  ),
                                ),
                                Icon(
                                  Icons.info_outline,
                                  size: 12,
                                  color: _themeColor.withOpacity(0.6),
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
                        bottom: BorderSide(color: AppDesign.textPrimaryDark.withOpacity(0.1)),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: _themeColor,
                      indicatorWeight: 3,
                      labelColor: _themeColor,
                      unselectedLabelColor: AppDesign.textSecondaryDark,
                      labelStyle: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                        tabs: [
                          Tab(text: l10n.cardTabOverview),
                          Tab(text: l10n.cardTabDetails),
                          Tab(text: l10n.cardTabTips),
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
          );
        },
      );
    }

  Widget _buildOverviewTab(ScrollController scrollController) {
    final l10n = AppLocalizations.of(context)!;
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
                _themeColor.withOpacity(0.2),
                _themeColor.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _themeColor.withOpacity(0.3)),
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
                backgroundColor: AppDesign.textPrimaryDark.withOpacity(0.1),
                progressColor: _themeColor,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.cardTotalCalories,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppDesign.textPrimaryDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "${((widget.analysis.estimatedCalories / dailyGoal) * 100).toStringAsFixed(0)}% ${l10n.cardDailyGoal} ($dailyGoal kcal)",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppDesign.textSecondaryDark,
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
            color: AppDesign.surfaceDark,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppDesign.textPrimaryDark.withOpacity(0.1)),
          ),
          child: PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 40,
              sections: [
                PieChartSectionData(
                  value: _parseGrams(widget.analysis.macronutrients.protein),
                  color: AppDesign.info,
                  title: l10n.foodProt,
                  radius: 50,
                  titleStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppDesign.textPrimaryDark),
                ),
                PieChartSectionData(
                  value: _parseGrams(widget.analysis.macronutrients.carbs),
                  color: AppDesign.warning,
                  title: l10n.foodCarb,
                  radius: 50,
                  titleStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppDesign.textPrimaryDark),
                ),
                PieChartSectionData(
                  value: _parseGrams(widget.analysis.macronutrients.fats),
                  color: AppDesign.primary,
                  title: l10n.foodFat,
                  radius: 50,
                  titleStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppDesign.textPrimaryDark),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Macros Dashboard
        Text(
          l10n.cardMacroDist,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppDesign.textPrimaryDark,
          ),
        ),
        const SizedBox(height: 16),

        // Macros em Column (sem overflow)
        _buildMacroCard(
          l10n.nutrientsProteins,
          widget.analysis.macronutrients.protein,
          Icons.fitness_center,
          AppDesign.info,
        ),
        const SizedBox(height: 12),
        _buildMacroCard(
          l10n.nutrientsCarbs,
          widget.analysis.macronutrients.carbs,
          Icons.grain,
          AppDesign.warning,
        ),
        const SizedBox(height: 12),
        _buildMacroCard(
          l10n.nutrientsFats,
          widget.analysis.macronutrients.fats,
          Icons.opacity,
          AppDesign.primary,
        ),

        const SizedBox(height: 24),

        // Quick Stats
        Text(
          l10n.cardQuickSummary,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppDesign.textPrimaryDark,
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
                  l10n.cardBenefits,
                  Icons.check_circle,
                  AppDesign.success,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => _showAlertsDialog(context),
                child: _buildStatCard(
                  "${widget.analysis.risks.length}",
                  l10n.cardAlerts,
                  Icons.warning_amber_rounded,
                  AppDesign.warning,
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
                  _themeColor.withOpacity(0.3),
                  _themeColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _themeColor.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _themeColor.withOpacity(0.2),
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
                        l10n.cardVitalityScore,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppDesign.textSecondaryDark,
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
                      color: AppDesign.textPrimaryDark,
                    ),
                  ),
                  progressColor: _themeColor,
                  backgroundColor: AppDesign.textPrimaryDark.withOpacity(0.1),
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
        .replaceAll('aproximadamente', '±')
        .replaceAll('Aproximadamente', '±');

    return GestureDetector(
      onTap: () => _showMacronutrientDialog(context, label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.2),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
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
                  color: AppDesign.textSecondaryDark,
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
              color: color.withOpacity(0.6),
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
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
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          l10n.cardDetailedInfo,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppDesign.textPrimaryDark,
          ),
        ),
        const SizedBox(height: 16),

        // Protein Details
        if (widget.analysis.macronutrients.protein.contains('('))
          _buildDetailCard(
            l10n.nutrientsProteins,
            widget.analysis.macronutrients.protein,
            Icons.fitness_center,
          ),

        // Carbs Details
        if (widget.analysis.macronutrients.carbs.contains('('))
          _buildDetailCard(
            l10n.nutrientsCarbs,
            widget.analysis.macronutrients.carbs,
            Icons.grain,
          ),

        // Fats Details
        if (widget.analysis.macronutrients.fats.contains('('))
          _buildDetailCard(
            l10n.nutrientsFats,
            widget.analysis.macronutrients.fats,
            Icons.opacity,
          ),

        const SizedBox(height: 16),
        Text(
          l10n.cardDisclaimer,
          style: const TextStyle(color: AppDesign.textSecondaryDark, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInsightsTab(ScrollController scrollController) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(24),
      children: [
        // Benefits
        if (widget.analysis.benefits.isNotEmpty) ...[
          Text(
            l10n.cardBenefits,
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
            l10n.foodCons,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppDesign.warning,
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
    final numericValue = value
        .replaceAll('aproximadamente', '±')
        .replaceAll('Aproximadamente', '±')
        .split('(').first.trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppDesign.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppDesign.textPrimaryDark.withOpacity(0.1)),
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
              color: AppDesign.textPrimaryDark,
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
          color: AppDesign.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppDesign.textPrimaryDark.withOpacity(0.1)),
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
                  color: _themeColor.withOpacity(0.6),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              fullValue.replaceAll('aproximadamente', '±').replaceAll('Aproximadamente', '±'),
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppDesign.textSecondaryDark,
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
            ? AppDesign.success.withOpacity(0.1)
            : AppDesign.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPositive
              ? AppDesign.success.withOpacity(0.3)
              : AppDesign.warning.withOpacity(0.3),
        ),
      ),
      child: ListTile(
        leading: Icon(
          isPositive ? Icons.check_circle : Icons.warning_amber_rounded,
          color: isPositive ? AppDesign.success : AppDesign.warning,
        ),
        title: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppDesign.textPrimaryDark.withOpacity(0.9),
          ),
        ),
      ),
    );
  }

  Widget _buildAdviceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppDesign.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppDesign.textPrimaryDark.withOpacity(0.1)),
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
              color: AppDesign.textSecondaryDark,
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
        color: AppDesign.backgroundDark,
        boxShadow: [
          BoxShadow(
            color: AppDesign.backgroundDark.withOpacity(0.5),
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
                    ? [AppDesign.accent, AppDesign.accent.withOpacity(0.8)]
                    : [_themeColor, _themeColor.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _themeColor.withOpacity(0.3),
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
                  color: _isSaved ? AppDesign.textPrimaryDark : AppDesign.backgroundDark,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  _isSaved ? "Salvo!" : "Salvar no Diário",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _isSaved ? AppDesign.textPrimaryDark : AppDesign.backgroundDark,
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
        backgroundColor: AppDesign.surfaceDark,
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
                  color: AppDesign.textPrimaryDark,
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
                        _themeColor.withOpacity(0.3),
                        _themeColor.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _themeColor.withOpacity(0.5)),
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
                          color: AppDesign.textSecondaryDark,
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
                    color: AppDesign.textPrimaryDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pontuação de 1 a 10 que indica o quão saudável é este alimento.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppDesign.textSecondaryDark,
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
                    color: AppDesign.textPrimaryDark,
                  ),
                ),
                const SizedBox(height: 6),
                _buildScoreItem('✅', 'Benefícios', '+0.3 pts', AppDesign.success),
                _buildScoreItem('⚠️', 'Alertas', '-0.5 pts', AppDesign.warning),
                const SizedBox(height: 12),

                // Scale
                Text(
                  'Escala',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppDesign.textPrimaryDark,
                  ),
                ),
                const SizedBox(height: 6),
                _buildScaleItem('9-10', 'Excelente', AppDesign.success),
                _buildScaleItem('7-9', 'Muito Bom', AppDesign.success.withOpacity(0.7)),
                _buildScaleItem('5-7', 'Bom', AppDesign.warning.withOpacity(0.7)),
                _buildScaleItem('3-5', 'Regular', AppDesign.warning),
                _buildScaleItem('1-3', 'Atenção', AppDesign.error),
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
                color: AppDesign.textSecondaryDark,
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
              color: AppDesign.textSecondaryDark,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '•',
            style: TextStyle(color: AppDesign.textSecondaryDark.withOpacity(0.3)),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: AppDesign.textSecondaryDark,
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
        backgroundColor: AppDesign.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppDesign.success, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Benefícios',
                style: GoogleFonts.poppins(
                  color: AppDesign.textPrimaryDark,
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
                      color: AppDesign.textSecondaryDark,
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
                              color: AppDesign.success.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${entry.key + 1}',
                              style: GoogleFonts.poppins(
                                color: AppDesign.success,
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
                                color: AppDesign.textPrimaryDark,
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
                color: AppDesign.success,
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
        backgroundColor: AppDesign.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppDesign.warning, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Pontos de Atenção',
                style: GoogleFonts.poppins(
                  color: AppDesign.textPrimaryDark,
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
                      color: AppDesign.textSecondaryDark,
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
                              color: AppDesign.warning.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${entry.key + 1}',
                              style: GoogleFonts.poppins(
                                color: AppDesign.warning,
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
                                color: AppDesign.textPrimaryDark,
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
                color: AppDesign.warning,
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
        'color': AppDesign.info,
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
        'color': AppDesign.warning,
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
        'color': AppDesign.warning,
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
        backgroundColor: AppDesign.surfaceDark,
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
                  color: AppDesign.textPrimaryDark,
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
                    color: AppDesign.textSecondaryDark,
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
                    color: AppDesign.textPrimaryDark,
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
                              color: AppDesign.textSecondaryDark,
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
                    color: AppDesign.textPrimaryDark,
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
                              color: AppDesign.textSecondaryDark,
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
                    color: (info['color'] as Color).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (info['color'] as Color).withOpacity(0.5),
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
                            color: AppDesign.textPrimaryDark,
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
          color: AppDesign.surfaceDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          boxShadow: [
            BoxShadow(
              color: AppDesign.backgroundDark.withOpacity(0.5),
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
                color: AppDesign.textPrimaryDark.withOpacity(0.24),
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
                            color: AppDesign.textPrimaryDark,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Com ${widget.analysis.itemName}',
                          style: GoogleFonts.poppins(
                            color: AppDesign.textSecondaryDark,
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
                        color: AppDesign.textPrimaryDark.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: AppDesign.textPrimaryDark, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: AppDesign.textPrimaryDark.withOpacity(0.1)),

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
                            color: AppDesign.textPrimaryDark.withOpacity(0.24),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhuma receita encontrada.',
                            style: GoogleFonts.poppins(
                              color: AppDesign.textSecondaryDark,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tente analisar outro alimento.',
                            style: GoogleFonts.poppins(
                              color: AppDesign.textSecondaryDark.withOpacity(0.5),
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
                            color: AppDesign.surfaceDark,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppDesign.textPrimaryDark.withOpacity(0.1)),
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
                                  color: _themeColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.restaurant,
                                  color: _themeColor,
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                recipe.nome,
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
                                      recipe.tempoPreparo,
                                      Colors.blue,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildRecipeBadge(
                                      Icons.speed,
                                      'Rápido',
                                      'Rápido' == 'Fácil'
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                  ],
                                ),
                              ),
                              children: [
                                // Instructions
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    recipe.instrucoes,
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
        color: color.withOpacity(0.2),
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
