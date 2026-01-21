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
import 'widgets/plant_level_icon.dart';

class BotanyHistoryScreen extends StatefulWidget {
  const BotanyHistoryScreen({super.key});

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
            tooltip: AppLocalizations.of(context)!.tooltipExportPdf,
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
          const Icon(Icons.local_florist, size: 80, color: AppDesign.surfaceDark),
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
    final toxicityText = isToxic ? (l10n.botanyToxicHuman) : l10n.labelSafe;

    return GestureDetector(
      onTap: () => _showFullResult(item),
      child: Container(
        constraints: const BoxConstraints(minHeight: 130), // 📏 FLEXIBLE MIN-HEIGHT
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
                              child: Icon(Icons.delete_outline, size: 18, color: Colors.white54),
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
                    
                    const SizedBox(height: 8),

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
                             child: Builder(
                               builder: (context) {
                                 final meta = item.rawMetadata;
                                 
                                 // Default Safe
                                 String text = l10n.labelSafe;
                                 Color color = const Color(0xFF00E676);
                                 Color bg = const Color(0xFF00E676).withOpacity(0.15);
                                 
                                 if (meta != null && meta['seguranca_biofilia'] != null) {
                                    final sec = meta['seguranca_biofilia']['seguranca_domestica'];
                                    if (sec != null) {
                                       final bool toxicPets = sec['toxica_para_pets'] == true || sec['is_toxic_to_pets'] == true;
                                       final bool toxicKids = sec['toxica_para_criancas'] == true;
                                       
                                       if (toxicPets) {
                                          color = Colors.redAccent;
                                          bg = Colors.redAccent.withOpacity(0.2);
                                          
                                          // Try to find specific animal mention in details
                                          final String details = (sec['sintomas_ingestao'] ?? sec['toxicity_details'] ?? '').toString().toLowerCase();
                                          if (details.contains('gato') && details.contains('cão')) {
                                             text = l10n.labelToxicDogsCats;
                                          } else if (details.contains('gato') || details.contains('felino')) {
                                             text = l10n.labelToxicCats;
                                          } else if (details.contains('cão') || details.contains('cachorro') || details.contains('canino')) {
                                             text = l10n.labelToxicDogs;
                                          } else {
                                             text = l10n.botanyDangerousPet.toUpperCase();
                                          }
                                       } else if (toxicKids) {
                                           color = Colors.orangeAccent;
                                           bg = Colors.orangeAccent.withOpacity(0.2);
                                           text = l10n.botanyToxicHuman.toUpperCase();
                                       }
                                    }
                                 } else {
                                    // Fallback legacy
                                    if (item.toxicityStatus != 'safe') {
                                       color = Colors.redAccent;
                                       bg = Colors.redAccent.withOpacity(0.2);
                                       text = l10n.botanyDangerousPet.toUpperCase();
                                    }
                                 }

                                 return Container(
                                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                   decoration: BoxDecoration(
                                      color: bg,
                                      borderRadius: BorderRadius.circular(6),
                                   ),
                                   child: Text(
                                      text.toUpperCase(),
                                      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                   ),
                                 );
                               }
                             ),
                           ),
                       ],
                     ),
                     
                     // 3) New Care Requirements Row
                     _buildCareRequirements(item),
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
    final l10n = AppLocalizations.of(context)!;
    if (item.rawMetadata == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorMetadataMissing)),
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
        SnackBar(content: Text(l10n.errorLoadDetails(e.toString()))),
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
                side: const BorderSide(color: AppDesign.success, width: 0.5),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _buildCircularIconAction(
          icon: Icons.wb_sunny_rounded,
          color: AppDesign.warning,
          tooltip: l10n.tooltipFengShui,
          onPressed: () => _showFengShui(item),
        ),
        const SizedBox(width: 10),
        _buildCircularIconAction(
          icon: Icons.picture_as_pdf_rounded,
          color: Colors.white,
          backgroundColor: AppDesign.primary,
          tooltip: l10n.tooltipGeneratePdf,
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
        SnackBar(content: Text(l10n.errorMetadataMissing)),
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
          SnackBar(content: Text(l10n.errorGeneratePdf(e.toString())), backgroundColor: AppDesign.error),
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
    final l10n = AppLocalizations.of(context)!;
    final s = status.toLowerCase();
    // Assuming Portuguese is the base storage language for these keys 'verde', 'amarelo', 'vermelho'
    // We map them to English equivalents if we are in English mode, or return as is (uppercased)
    // Actually, checking if we have specific keys. We don't have "Green" in arb, but we can infer logical mapping.
    
    // Check if current locale is English (or use localization for all)
    // We now have keys for these
    if (s.contains('verde') || s.contains('green')) return l10n.statusHealthy;
    if (s.contains('amarelo') || s.contains('yellow')) return l10n.statusWarning;
    if (s.contains('vermelho') || s.contains('red')) return l10n.statusCritical;
    
    // Default fallback
    return status.toUpperCase();
  }

  void _showExportModal(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final allItems = BotanyService().listenable?.value.values.whereType<BotanyHistoryItem>().toList() ?? [];
    
    if (allItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorNoPlantsToExport))
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
          // 1. Fecha o Modal de Configuração de forma blindada
          Navigator.of(modalContext).pop();
          
          // 2. Aguarda um frame para garantir que o modal fechou
          await Future.delayed(Duration.zero);
          if (!mounted) return;

          // 3. Mostra Dialog de Carregamento usando Root Navigator para sobrepor tudo
          showDialog(
            context: context,
            barrierDismissible: false,
            useRootNavigator: true, 
            builder: (loadingContext) => const Center(
              child: CircularProgressIndicator(color: AppDesign.plantGreen)
            ),
          );

          try {
            final doc = await ExportService().generatePlantHistoryReport(
              items: selectedItems,
              strings: AppLocalizations.of(context)!
            );

            // 4. Fecha o Loading Dialog (via Root Navigator)
            if (mounted) {
               Navigator.of(context, rootNavigator: true).pop(); 
            }

            if (!mounted) return;
            
            // 5. Navega para PDF preview
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PdfPreviewScreen(
                  title: l10n.titleBotanyIntelligence,
                  buildPdf: (format) async => doc.save(),
                ),
              ),
            );
          } catch (e) {
            // Fecha Loading Dialog em caso de erro (via Root Navigator)
            if (mounted) {
               Navigator.of(context, rootNavigator: true).pop();
            }
            
            debugPrint('❌ Error generating plant PDF: $e');
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.errorPdfGeneration))
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildCareRequirements(BotanyHistoryItem item) {
    // Extract values
    final sun = item.lightWaterSoilNeeds['luz'];
    final water = item.lightWaterSoilNeeds['agua'];
    final soil = item.lightWaterSoilNeeds['solo']; // often implicitly mapped

    // Levels 1-3
    final sunLevel = _parseLevel(sun, 'sun');
    final waterLevel = _parseLevel(water, 'water');
    final soilLevel = _parseLevel(soil, 'soil');

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
    child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildCareItemWithLabel(sunLevel, PlantRequirementType.sun, AppLocalizations.of(context)!.labelSun, sun ?? AppLocalizations.of(context)!.labelSun),
            const SizedBox(width: 16),
            _buildCareItemWithLabel(waterLevel, PlantRequirementType.water, AppLocalizations.of(context)!.labelWater, water ?? AppLocalizations.of(context)!.labelWater),
            const SizedBox(width: 16),
            _buildCareItemWithLabel(soilLevel, PlantRequirementType.soil, AppLocalizations.of(context)!.labelSoil, soil ?? AppLocalizations.of(context)!.labelSoil),
          ],
        ),
      ),
    );
  }

  Widget _buildCareItemWithLabel(int level, PlantRequirementType type, String label, String tooltip) {
    Color color;
    switch (type) {
      case PlantRequirementType.sun: color = Colors.orange; break;
      case PlantRequirementType.water: color = Colors.blue; break;
      case PlantRequirementType.soil: color = Colors.brown; break;
    }

    return Tooltip(
      message: tooltip,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PlantLevelIcon(level: level, type: type, size: 20),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  int _parseLevel(String? value, String type) {
    if (value == null) return 1; // Fallback
    final s = value.toLowerCase();

    if (type == 'sun') {
      if (s.contains('pleno') || s.contains('full') || s.contains('direta')) return 3;
      if (s.contains('meia') || s.contains('partial') || s.contains('indireta')) return 2;
      return 1; // Sombra
    }

    if (type == 'water') {
      // Robust detection for "Abundantemente", "Frequente", etc.
      if (s.contains('abundante') || s.contains('high') || s.contains('frequente') || s.contains('muito')) return 3;
      if (s.contains('moderada') || s.contains('average') || s.contains('regular') || s.contains('semanal')) return 2;
      return 1; // Pouca
    }

    if (type == 'soil') {
      if (s.contains('rico') || s.contains('rich') || s.contains('fértil') || s.contains('humus')) return 3;
      if (s.contains('drenado') || s.contains('drain') || s.contains('arenoso')) return 1;
      return 2;
    }

    return 1;
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
