import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../models/plant_analysis_model.dart';
import '../../../../core/utils/color_helper.dart';

class PlantResultCard extends StatefulWidget {
  final PlantAnalysisModel analysis;
  final VoidCallback onSave;
  final VoidCallback onShop;

  const PlantResultCard({
    super.key,
    required this.analysis,
    required this.onSave,
    required this.onShop,
  });

  @override
  State<PlantResultCard> createState() => _PlantResultCardState();
}

class _PlantResultCardState extends State<PlantResultCard> {
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    // Haptic feedback on result display
    HapticFeedback.mediumImpact();
  }

  Color get _statusColor => ColorHelper.getPlantThemeColor(widget.analysis.urgency);
  IconData get _statusIcon => widget.analysis.isHealthy
      ? FontAwesomeIcons.leaf
      : FontAwesomeIcons.circleExclamation;

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
              color: Colors.black.withOpacity(0.8),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white30,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.analysis.plantName,
                                style: GoogleFonts.poppins(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.analysis.condition,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _statusColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: _statusColor.withOpacity(0.5)),
                          ),
                          child: Icon(_statusIcon, color: _statusColor, size: 24),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Diagnosis Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _statusColor.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(FontAwesomeIcons.stethoscope,
                                  color: _statusColor, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                "Diagnóstico Detectado",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _statusColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.analysis.diagnosis,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Treatment Timeline
                    Text(
                      "Plano de Recuperação",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTreatmentTimeline(),

                    const SizedBox(height: 24),

                    // Urgency Meter
                    if (!widget.analysis.isHealthy) ...[
                      Text(
                        "Nível de Risco",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearPercentIndicator(
                        lineHeight: 8.0,
                        animation: true,
                        animationDuration: 1000,
                        percent: widget.analysis.urgencyValue,
                        backgroundColor: Colors.white10,
                        progressColor: _statusColor,
                        barRadius: const Radius.circular(4),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Actions
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          if (!_isSaved) {
                            setState(() => _isSaved = true);
                            HapticFeedback.heavyImpact();
                            widget.onSave();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isSaved
                              ? Colors.green
                              : const Color(0xFF00E676),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isSaved ? Icons.check_circle : Icons.bookmark_add_outlined,
                              color: Colors.black,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _isSaved ? "Salvo!" : "Salvar no Jardim",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!widget.analysis.isHealthy) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: widget.onShop,
                          child: Text(
                            "Comprar remédio sugerido",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFF00E676),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTreatmentTimeline() {
    // Parse treatment steps (simple split by newline or numbered list)
    final steps = widget.analysis.organicTreatment.split('\n').where((s) => s.trim().isNotEmpty).toList();
    
    if (steps.isEmpty) {
      return _buildSingleTreatmentCard();
    }

    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isLast = index == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline indicator
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF00E676), width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF00E676),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: const Color(0xFF00E676).withOpacity(0.3),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Step content
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text(
                  step.trim(),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSingleTreatmentCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(FontAwesomeIcons.seedling,
                  color: Colors.greenAccent, size: 16),
              const SizedBox(width: 8),
              Text(
                "Tratamento Orgânico",
                style: GoogleFonts.poppins(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.analysis.organicTreatment,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
