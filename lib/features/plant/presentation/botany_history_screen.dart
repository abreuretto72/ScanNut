import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../models/botany_history_item.dart';
import '../models/plant_analysis_model.dart';
import '../services/botany_service.dart';
import 'widgets/plant_result_card.dart';
import '../../../core/services/export_service.dart';
import '../../../core/widgets/pdf_preview_screen.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../l10n/app_localizations.dart';

class BotanyHistoryScreen extends StatefulWidget {
  const BotanyHistoryScreen({Key? key}) : super(key: key);

  @override
  State<BotanyHistoryScreen> createState() => _BotanyHistoryScreenState();
}

class _BotanyHistoryScreenState extends State<BotanyHistoryScreen> {
  List<BotanyHistoryItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final items = await BotanyService().getHistory();
    debugPrint("📜 HistoryScreen loaded ${items.length} items from service.");
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(l10n.botanyTitle,
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: ValueListenableBuilder<Box<BotanyHistoryItem>>(
        valueListenable: BotanyService().listenable!,
        builder: (context, box, _) {
          final items = box.values.whereType<BotanyHistoryItem>().toList().reversed.toList();
          
          if (items.isEmpty) {
            return _buildEmptyState();
          }
          
          return AnimationLimiter(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: _buildPlantCard(item),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_florist, size: 80, color: Colors.grey.shade800),
          const SizedBox(height: 16),
          Text(
            l10n.botanyEmpty,
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantCard(BotanyHistoryItem item) {
    final l10n = AppLocalizations.of(context)!;
    Color semaphoreColor;
    switch (item.survivalSemaphore.toLowerCase()) {
      case 'verde': semaphoreColor = Colors.greenAccent; break;
      case 'amarelo': semaphoreColor = Colors.yellowAccent; break;
      case 'vermelho': semaphoreColor = Colors.redAccent; break;
      default: semaphoreColor = Colors.greenAccent;
    }

    return GestureDetector(
      onTap: () => _showFullResult(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.grey.shade900.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: semaphoreColor.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Image and Semaphore
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: item.imagePath != null
                      ? Image.file(
                          File(item.imagePath!),
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 160,
                          width: double.infinity,
                          color: Colors.grey.shade800,
                          child: const Icon(Icons.park, color: Colors.white10, size: 50),
                        ),
                ),
                // Semaphore Indicator
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: semaphoreColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: semaphoreColor,
                            boxShadow: [BoxShadow(color: semaphoreColor, blurRadius: 4)],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${l10n.botanyStatus}: ${_getLocalizedStatus(item.survivalSemaphore)}',
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                // Date & Locale
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          DateFormat('dd MMM yyyy', Localizations.localeOf(context).toString()).format(item.timestamp),
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 10),
                        ),
                      ),
                      if (item.locale != null && item.locale != Localizations.localeOf(context).toString()) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber, width: 0.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.language, color: Colors.white, size: 10),
                              const SizedBox(width: 4),
                              Text(
                                item.locale!.toUpperCase().replaceAll('_', '-'),
                                style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Delete Button
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
                      onPressed: () => _confirmDeletePlant(item),
                    ),
                  ),
                ),
              ],
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AutoSizeText(
                    item.plantName,
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    maxLines: 1,
                    minFontSize: 14,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.healthStatus,
                    style: GoogleFonts.poppins(color: semaphoreColor, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  
                  // Needs Icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNeedIcon(Icons.light_mode, item.lightWaterSoilNeeds['luz'] ?? 'N/A', Colors.yellow.shade700),
                      _buildNeedIcon(Icons.water_drop, item.lightWaterSoilNeeds['agua'] ?? 'N/A', Colors.blueAccent),
                      _buildNeedIcon(Icons.grass, item.lightWaterSoilNeeds['solo'] ?? 'N/A', Colors.brown.shade300),
                    ],
                  ),
  
                  const SizedBox(height: 16),
                  // toxicity warning if any
                  if (item.toxicityStatus != 'safe')
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AutoSizeText(
                              item.toxicityStatus == 'toxic' ? l10n.botanyToxicHuman : l10n.botanyDangerousPet,
                              style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              minFontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
  
                  const SizedBox(height: 16),
                  _buildActionButtons(item),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullResult(BotanyHistoryItem item) {
    if (item.rawMetadata == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: Metadados da planta não encontrados.')),
      );
      return;
    }

    try {
      final analysis = PlantAnalysisModel.fromJson(item.rawMetadata!);
      
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => PlantResultCard(
          analysis: analysis,
          imagePath: item.imagePath,
          onSave: () {}, // Already saved
          onShop: () {}, // Handled in card
          isReadOnly: true, // Mark as read-only from history
        ),
      );
    } catch (e) {
      debugPrint('Error parsing plant metadata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar detalhes: $e')),
      );
    }
  }

  Widget _buildNeedIcon(IconData icon, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        SizedBox(
          width: 80,
            child: AutoSizeText(
              value,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 10),
              maxLines: 1,
              minFontSize: 6,
              overflow: TextOverflow.ellipsis,
            ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BotanyHistoryItem item) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showRecoveryPlan(item),
            icon: const Icon(Icons.health_and_safety_rounded, size: 18),
            label: Text(l10n.botanyRecovery, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 11)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E676).withValues(alpha: 0.1),
              foregroundColor: const Color(0xFF00E676),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFF00E676), width: 0.5),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _buildCircularIconAction(
          icon: Icons.wb_sunny_rounded,
          color: Colors.orangeAccent,
          tooltip: 'Feng Shui Tips',
          onPressed: () => _showFengShui(item),
        ),
        const SizedBox(width: 10),
        _buildCircularIconAction(
          icon: Icons.picture_as_pdf_rounded,
          color: Colors.redAccent,
          tooltip: 'Gerar Dossiê PDF',
          onPressed: () => _generateHistoryPDF(item),
        ),
      ],
    );
  }

  Widget _buildCircularIconAction({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onPressed,
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Future<void> _generateHistoryPDF(BotanyHistoryItem item) async {
    final l10n = AppLocalizations.of(context)!;
    if (item.rawMetadata == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: Dados completos não encontrados para este item.')),
      );
      return;
    }

    try {
      final analysis = PlantAnalysisModel.fromJson(item.rawMetadata!);
      
      if (!mounted) return;
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfPreviewScreen(
            title: l10n.botanyDossierTitle(item.plantName),
            buildPdf: (format) async {
              final pdf = await ExportService().generatePlantAnalysisReport(
                analysis: analysis,
                strings: AppLocalizations.of(context)!,
                imageFile: item.imagePath != null ? File(item.imagePath!) : null,
              );
              return pdf.save();
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint("Erro ao gerar PDF do histórico: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao gerar PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showRecoveryPlan(BotanyHistoryItem item) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(l10n.botanyRecoveryPlan, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(item.recoveryPlan, style: GoogleFonts.poppins(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.commonUnderstand)),
        ],
      ),
    );
  }

  void _showFengShui(BotanyHistoryItem item) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(l10n.botanyFengShui, style: GoogleFonts.poppins(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
        content: Text(item.fengShuiTips, style: GoogleFonts.poppins(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.commonClose)),
        ],
      ),
    );
  }

  String _getLocalizedStatus(String status) {
    final s = status.toLowerCase();
    // Assuming Portuguese is the base storage language for these keys 'verde', 'amarelo', 'vermelho'
    // We map them to English equivalents if we are in English mode, or return as is (uppercased)
    // Actually, checking if we have specific keys. We don't have "Green" in arb, but we can infer logical mapping.
    
    // Check if current locale is English
    bool isEnglish = Localizations.localeOf(context).languageCode == 'en';
    
    if (isEnglish) {
       if (s.contains('verde') || s.contains('green')) return 'GREEN / HEALTHY';
       if (s.contains('amarelo') || s.contains('yellow')) return 'YELLOW / WARNING';
       if (s.contains('vermelho') || s.contains('red')) return 'RED / CRITICAL';
    }
    
    // Default fallback (Portuguese or others)
    return status.toUpperCase();
  }

  Future<void> _confirmDeletePlant(BotanyHistoryItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deletePlantTitle),
        content: Text(l10n.deletePlantConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
       // Delete Image
       if (item.imagePath != null) {
          final file = File(item.imagePath!);
          if (await file.exists()) {
             await file.delete();
          }
       }
       // Delete from Hive
       await item.delete();
    }
  }
}
