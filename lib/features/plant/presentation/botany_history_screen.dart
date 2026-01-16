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
import '../../../core/theme/app_design.dart';
import 'widgets/plant_export_configuration_modal.dart';

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
      backgroundColor: AppDesign.backgroundDark,
      appBar: AppBar(
        title: Text(l10n.botanyTitle,
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: AppDesign.backgroundDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            onPressed: () => _showExportModal(context),
            tooltip: 'Exportar PDF',
          ),
        ],
      ),
      body: BotanyService().listenable == null 
          ? const Center(child: CircularProgressIndicator(color: AppDesign.plantGreen))
          : ValueListenableBuilder<Box<BotanyHistoryItem>>(
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
          Icon(Icons.local_florist, size: 80, color: AppDesign.surfaceDark),
          const SizedBox(height: 16),
          Text(
            l10n.botanyEmpty,
            style: GoogleFonts.poppins(color: AppDesign.textSecondaryDark, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantCard(BotanyHistoryItem item) {
    final l10n = AppLocalizations.of(context)!;
    Color semaphoreColor;
    
    // Determine Color based on Health Status
    switch (item.survivalSemaphore.toLowerCase()) {
      case 'verde': semaphoreColor = AppDesign.success; break;
      case 'amarelo': semaphoreColor = AppDesign.warning; break;
      case 'vermelho': semaphoreColor = AppDesign.error; break;
      default: semaphoreColor = AppDesign.success;
    }

    final isToxic = item.toxicityStatus != 'safe';
    final toxicityColor = isToxic ? Colors.redAccent : const Color(0xFF00E676);
    final toxicityBg = isToxic ? Colors.redAccent.withOpacity(0.2) : const Color(0xFF00E676).withOpacity(0.15);
    final toxicityText = isToxic ? (l10n.botanyToxicHuman) : "Segura / Safe";

    return GestureDetector(
      onTap: () => _showFullResult(item),
      child: Container(
        height: 120, // 📏 COMPACT FIXED HEIGHT
        margin: const EdgeInsets.only(bottom: 12), // Tighter spacing
        decoration: BoxDecoration(
          color: AppDesign.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          // Subtle border for high-end look
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
             BoxShadow(
               color: Colors.black.withOpacity(0.3),
               blurRadius: 8,
               offset: const Offset(0, 4),
             )
          ],
        ),
        child: Row(
          children: [
            // 📸 LEFT: SQUARE PHOTO (COMPACT)
            Padding(
              padding: const EdgeInsets.all(10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                   width: 100,
                   height: 100,
                   child: item.imagePath != null
                      ? Image.file(
                          File(item.imagePath!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                             // 🛡️ MEDIA VAULT ERROR HANDLER
                             return Container(
                                color: Colors.grey[800],
                                child: const Center(child: Icon(Icons.park, color: Colors.white24, size: 30)),
                             );
                          },
                        )
                      : Container(
                          color: Colors.grey[800],
                          child: const Center(child: Icon(Icons.park, color: Colors.white24, size: 30)),
                        ),
                ),
              ),
            ),
            
            // 📝 RIGHT: METADATA COLUMN
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // TOP ROW: Name + Delete
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         Expanded(
                           child: Text(
                             item.plantName,
                             style: GoogleFonts.poppins(
                               fontWeight: FontWeight.bold,
                               fontSize: 15,
                               color: Colors.white, // Preto Puro equivalent in Dark Mode
                             ),
                             maxLines: 1,
                             overflow: TextOverflow.ellipsis,
                           ),
                         ),
                         // Mini Delete Action
                         GestureDetector(
                            onTap: () => _confirmDeletePlant(item),
                            child: const Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Icon(Icons.close_rounded, size: 16, color: Colors.white24),
                            ),
                         ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // DATE
                    Text(
                         DateFormat('dd MMM yyyy', Localizations.localeOf(context).toString()).format(item.timestamp),
                         style: GoogleFonts.poppins(color: Colors.grey, fontSize: 11),
                    ),
                    
                    const Spacer(),

                    // BOTTOM ROW: BADGES (Toxicity + Status)
                    Row(
                      children: [
                         // 1) Health Status Badge
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                           decoration: BoxDecoration(
                              color: semaphoreColor.withOpacity(0.2), 
                              borderRadius: BorderRadius.circular(6),
                           ),
                           child: Text(
                              // Using localized abbreviated status logic
                              _getLocalizedStatus(item.survivalSemaphore).split('/')[0].trim(),
                              style: TextStyle(color: semaphoreColor, fontSize: 10, fontWeight: FontWeight.bold),
                           ),
                         ),
                         const SizedBox(width: 8),

                         // 2) Toxicity Badge (Compact)
                         Expanded(
                           child: Container(
                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                             decoration: BoxDecoration(
                                color: toxicityBg,
                                borderRadius: BorderRadius.circular(6),
                             ),
                             child: Text(
                                toxicityText.toUpperCase(),
                                style: TextStyle(color: toxicityColor, fontSize: 10, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                             ),
                           ),
                         ),
                      ],
                    )
                  ],
                ),
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
              style: GoogleFonts.poppins(color: AppDesign.textSecondaryDark, fontSize: 10),
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
              backgroundColor: AppDesign.success.withOpacity(0.1),
              foregroundColor: AppDesign.success,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppDesign.success, width: 0.5),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _buildCircularIconAction(
          icon: Icons.wb_sunny_rounded,
          color: AppDesign.warning,
          tooltip: 'Feng Shui Tips',
          onPressed: () => _showFengShui(item),
        ),
        const SizedBox(width: 10),
        _buildCircularIconAction(
          icon: Icons.picture_as_pdf_rounded,
          color: Colors.white,
          backgroundColor: AppDesign.primary,
          tooltip: 'Gerar Dossiê PDF',
          onPressed: () => _generateHistoryPDF(item),
        ),
      ],
    );
  }

  Widget _buildCircularIconAction({
    required IconData icon,
    required Color color,
    Color? backgroundColor,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: backgroundColor ?? color.withOpacity(0.3)),
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
          SnackBar(content: Text('Erro ao gerar PDF: $e'), backgroundColor: AppDesign.error),
        );
      }
    }
  }

  void _showRecoveryPlan(BotanyHistoryItem item) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppDesign.surfaceDark,
        title: Text(l10n.botanyRecoveryPlan, style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark, fontWeight: FontWeight.bold)),
        content: Text(item.recoveryPlan, style: GoogleFonts.poppins(color: AppDesign.textSecondaryDark)),
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
        backgroundColor: AppDesign.surfaceDark,
        title: Text(l10n.botanyFengShui, style: GoogleFonts.poppins(color: AppDesign.warning, fontWeight: FontWeight.bold)),
        content: Text(item.fengShuiTips, style: GoogleFonts.poppins(color: AppDesign.textSecondaryDark)),
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

  void _showExportModal(BuildContext context) {
    final allItems = BotanyService().listenable?.value.values.whereType<BotanyHistoryItem>().toList() ?? [];
    
    if (allItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma planta para exportar!'))
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => PlantExportConfigurationModal(
        allItems: allItems,
        onGenerate: (selectedItems) async {
          // Close the modal first
          Navigator.pop(modalContext);
          
          // Show loading dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => const Center(
              child: CircularProgressIndicator(color: AppDesign.plantGreen)
            ),
          );

          try {
            final doc = await ExportService().generatePlantHistoryReport(
              items: selectedItems,
              strings: AppLocalizations.of(context)!
            );

            // Close loading dialog
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }

            if (!mounted) return;
            
            // Navigate to PDF preview
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PdfPreviewScreen(
                  title: 'Inteligência Botânica',
                  buildPdf: (format) async => doc.save(),
                ),
              ),
            );
          } catch (e) {
            // Close loading dialog on error
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
            
            debugPrint('❌ Error generating plant PDF: $e');
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Erro ao gerar PDF. Tente novamente.'))
              );
            }
          }
        },
      ),
    );
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
            child: Text(l10n.delete, style: const TextStyle(color: AppDesign.error)),
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
