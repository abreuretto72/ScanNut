import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/pet_analysis_result.dart';
import '../../../../core/utils/color_helper.dart';

class PetResultCard extends StatefulWidget {
  final PetAnalysisResult analysis;
  final VoidCallback onSave;

  const PetResultCard({
    super.key,
    required this.analysis,
    required this.onSave,
  });

  @override
  State<PetResultCard> createState() => _PetResultCardState();
}

class _PetResultCardState extends State<PetResultCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    // Haptic feedback - stronger for emergency
    if (_isEmergency) {
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 200), () {
        HapticFeedback.heavyImpact();
      });
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _urgencyColor =>
      ColorHelper.getPetThemeColor(widget.analysis.urgenciaNivel);

  bool get _isEmergency =>
      widget.analysis.urgenciaNivel.toLowerCase() == 'vermelho';

  String get _urgencyText {
    switch (widget.analysis.urgenciaNivel.toLowerCase()) {
      case 'vermelho':
        return 'Emergência: Procure um Veterinário AGORA';
      case 'amarelo':
        return 'Atenção: Recomenda-se cuidado profissional';
      case 'verde':
      default:
        return 'Observação: Sintoma leve detectado';
    }
  }

  Future<void> _callVet() async {
    final Uri mapsUri = Uri.parse('geo:0,0?q=veterinario+24h');

    if (await canLaunchUrl(mapsUri)) {
      await launchUrl(mapsUri);
    } else {
      debugPrint('Could not launch maps');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: _isEmergency ? Colors.black : Colors.black.withOpacity(0.8),
              child: Stack(
                children: [
                  // Panic Mode Effect (Subtle red glow if emergency)
                  if (_isEmergency)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.topCenter,
                            radius: 1.5,
                            colors: [
                              Colors.red.withOpacity(0.2),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                  Column(
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

                      // Urgency Banner
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 24, bottom: 0),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          color: _urgencyColor,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isEmergency
                                    ? Icons.warning_amber_rounded
                                    : Icons.info_outline,
                                color: Colors.black,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _urgencyText,
                                  style: GoogleFonts.poppins(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(24),
                          children: [
                            // Identification
                            Text(
                              widget.analysis.especie,
                              style: GoogleFonts.comfortaa(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Triagem de Bem-estar",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white54,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Visual Analysis
                            _buildGlassCard(
                              title: "O que a IA viu:",
                              content: widget.analysis.descricaoVisual,
                              icon: Icons.visibility,
                              color: Colors.blueAccent,
                            ),
                            const SizedBox(height: 16),

                            // Possible Causes
                            _buildGlassCard(
                              title: "Possíveis Causas:",
                              content:
                                  widget.analysis.possiveisCausas.join('\n• '),
                              icon: Icons.list,
                              color: Colors.purpleAccent,
                              isList: true,
                            ),
                            const SizedBox(height: 16),

                            // Immediate Care / First Aid
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.medical_services,
                                          color: Colors.tealAccent, size: 20),
                                      const SizedBox(width: 10),
                                      Text(
                                        "O que você pode fazer agora",
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.tealAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    widget.analysis.orientacaoImediata,
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      color: Colors.white.withOpacity(0.9),
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Disclaimer
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.orange.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.gavel,
                                      color: Colors.orange, size: 16),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      "Esta triagem automática não substitui a consulta veterinária.",
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.orange,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 80),
                          ],
                        ),
                      ),

                      // Footer Actions
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          boxShadow: [
                            BoxShadow(
                              color: _isEmergency
                                  ? Colors.red.withOpacity(0.3)
                                  : Colors.black.withOpacity(0.5),
                              blurRadius: 20,
                              offset: const Offset(0, -10),
                            ),
                          ],
                        ),
                        child: SafeArea(
                          top: false,
                          child: Column(
                            children: [
                              if (_isEmergency)
                                ElevatedButton(
                                  onPressed: _callVet,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                    elevation: 8,
                                    shadowColor:
                                        Colors.redAccent.withOpacity(0.5),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.phone_in_talk),
                                      const SizedBox(width: 12),
                                      Text(
                                        "Emergência: Clínicas 24h",
                                        style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              if (_isEmergency) const SizedBox(height: 12),

                              ElevatedButton(
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
                                      : _isEmergency
                                          ? Colors.grey[900]
                                          : const Color(0xFF00E676),
                                  foregroundColor: _isSaved
                                      ? Colors.white
                                      : _isEmergency
                                          ? Colors.white
                                          : Colors.black,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(_isSaved
                                          ? Icons.check_circle
                                          : Icons.bookmark_add_outlined),
                                      const SizedBox(width: 12),
                                      Text(
                                        _isSaved
                                            ? "Salvo!"
                                            : "Salvar no Histórico",
                                        style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlassCard({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
    bool isList = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isList ? '• $content' : content,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }
}
