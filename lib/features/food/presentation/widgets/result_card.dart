import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/food_analysis_model.dart';
import '../../../../core/utils/color_helper.dart';

class ResultCard extends StatefulWidget {
  final FoodAnalysisModel analysis;
  final VoidCallback onSave;

  const ResultCard({
    super.key,
    required this.analysis,
    required this.onSave,
  });

  @override
  State<ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<ResultCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _controller.forward();
    
    // Haptic feedback on result display
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _controller.dispose();
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
                    Colors.grey.shade900.withOpacity(0.95),
                    Colors.black.withOpacity(0.98),
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
                  Expanded(
                    child: AnimationLimiter(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(24),
                        children: AnimationConfiguration.toStaggeredList(
                          duration: const Duration(milliseconds: 600),
                          childAnimationBuilder: (widget) => SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(child: widget),
                          ),
                          children: [
                            // Header
                            _buildHeader(),
                            const SizedBox(height: 32),

                            // Main Stats (Calories & Macros)
                            _buildMainStats(),
                            const SizedBox(height: 32),

                            // Insights
                            Text(
                              "Insights Nutricionais",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...widget.analysis.benefits
                                .map((b) => _buildInsightCard(b, true)),
                            ...widget.analysis.risks
                                .map((r) => _buildInsightCard(r, false)),

                            const SizedBox(height: 24),

                            // Advice
                            _buildAdviceCard(),

                            const SizedBox(height: 16),

                            // Disclaimer
                            const Text(
                              'Nota: Esta é uma análise feita por IA e não substitui um diagnóstico de nutricionista.',
                              style: TextStyle(color: Colors.white54, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
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

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.analysis.itemName,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                "Análise Nutricional",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ),
        Container(
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
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _themeColor,
                ),
              ),
              Text(
                "Vitalidade",
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: _themeColor.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainStats() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          CircularPercentIndicator(
            radius: 80.0,
            lineWidth: 12.0,
            animation: true,
            animationDuration: 1200,
            percent: (widget.analysis.estimatedCalories / 2000).clamp(0.0, 1.0),
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${widget.analysis.estimatedCalories}",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "kcal",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
            circularStrokeCap: CircularStrokeCap.round,
            backgroundColor: Colors.white10,
            progressColor: _themeColor,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMacroItem(
                  "Proteína", widget.analysis.macronutrients.protein, Icons.fitness_center),
              _buildMacroItem(
                  "Carbs", widget.analysis.macronutrients.carbs, Icons.grain),
              _buildMacroItem(
                  "Gorduras", widget.analysis.macronutrients.fats, Icons.opacity),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white10,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white70, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard(String text, bool isPositive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isPositive
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPositive
              ? Colors.green.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
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
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ),
    );
  }

  Widget _buildAdviceCard() {
    return Container(
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
            color: Colors.black.withOpacity(0.5),
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
}
