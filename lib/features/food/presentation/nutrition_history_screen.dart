import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/food_nutrition_history_item.dart';
import '../models/food_pdf_labels.dart';
import '../services/nutrition_service.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart'; // Keeping it used in list? Check line 166 usage. The analysis says unused?
// If analysis says unused, I remove it.
import '../models/food_analysis_model.dart';
import 'food_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../l10n/app_localizations.dart';
import '../l10n/app_localizations.dart';
import '../../../core/theme/app_design.dart';
import '../services/food_export_service.dart';
import 'food_pdf_preview_screen.dart';
import 'widgets/food_export_configuration_modal.dart';
import 'widgets/food_history_card.dart';
import 'food_chat_screen.dart';

class NutritionHistoryScreen extends StatefulWidget {
  const NutritionHistoryScreen({super.key});

  @override
  State<NutritionHistoryScreen> createState() => _NutritionHistoryScreenState();
}

class _NutritionHistoryScreenState extends State<NutritionHistoryScreen> {
  List<NutritionHistoryItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _performInitialSanitation();
    _loadHistory();
  }

  Future<void> _performInitialSanitation() async {
    // 🧹 SANEAMENTO RETROATIVO (Lei de Ferro)
    // Limpa receitas corrompidas e histórico de sugestões antes de exibir
    try {
      final removed = await NutritionService().sanitizeHistoryItems();
      if (removed > 0 && mounted) {
        final l10n = AppLocalizations.of(context);
        if (l10n != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n?.msgRecipeDiscarded ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(l10n?.msgRecipeDiscardedDesc ?? '', style: const TextStyle(fontSize: 12)),
                ],
              ),
              backgroundColor: AppDesign.foodOrange.withValues(alpha: 0.9),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('⚠️ Erro ao sanear histórico de nutrição: $e');
    }
  }

  Future<void> _loadHistory() async {
    final items = await NutritionService().getHistory();
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🖥️ [HistoryScreen] Building...');
    final l10n = AppLocalizations.of(context);
    final foodL10n = FoodLocalizations.of(context);
    if (l10n == null || foodL10n == null) return const SizedBox.shrink();



    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(foodL10n.foodHistoryTitle,
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.psychology, color: AppDesign.foodOrange),
            tooltip: "NutriChat IA",
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const FoodChatScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            onPressed: _generateHistoryPdf,
            tooltip: foodL10n.tooltipHistoryReport,
          ),
        ],
      ),
      body: FutureBuilder(
        future: NutritionService().init(), // Ensure init
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF00E676)));
          }

          final listenable = NutritionService().listenable;
          if (listenable == null) {
            debugPrint('⚠️ [HistoryScreen] Listenable is null');
            return _buildEmptyState();
          }

          return ValueListenableBuilder<Box<NutritionHistoryItem>>(
            valueListenable: listenable,
            builder: (context, box, _) {
              debugPrint('📡 [HistoryScreen] ValueListenable Builder Triggered. Box Name: ${box.name} | Length: ${box.length}');
              
              final List<NutritionHistoryItem> items = [];
              try {
                // 🛠️ Defesa contra corrupção de registro individual no Hive
                items.addAll(box.values
                    .whereType<NutritionHistoryItem>()
                    .toList()
                    .reversed);
                
                debugPrint('🔄 [HistoryScreen] Filtered items count: ${items.length}');
              } catch (e) {
                debugPrint('❌ [HistoryScreen] CRITICAL ERROR reading box values: $e');
                // Se o box estiver ilegível, retornamos estado vazio/erro em vez de crash
                return _buildEmptyState();
              }

              if (items.isNotEmpty) {
                debugPrint('   First item: ${items.first.foodName} | ID: ${items.first.id}');
              }

              if (items.isEmpty) {
                debugPrint('📭 [HistoryScreen] Displaying Empty State');
                return _buildEmptyState();
              }

              debugPrint('🎨 [HistoryScreen] Building AnimationLimiter with ${items.length} cards...');
              
              return RepaintBoundary(
                child: RefreshIndicator(
                  onRefresh: () async {
                    debugPrint('🔃 [HistoryScreen] Manual Refresh Triggered');
                    await NutritionService().init();
                    setState(() {});
                  },
                  color: const Color(0xFF00E676),
                  backgroundColor: Colors.black,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      debugPrint('🎴 [HistoryScreen] Building card index $index: ${item.foodName}');
                      try {
                        return FoodHistoryCard(
                          item: item,
                          onTap: () => _showDetailModal(item),
                          onDelete: () => _confirmDelete(item),
                        );
                      } catch (e) {
                        debugPrint('❌ [HistoryScreen] ERROR building card at index $index: $e');
                        return ListTile(
                          title: Text("Erro ao carregar item $index", 
                          style: const TextStyle(color: Colors.red))
                        );
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);
    final foodL10n = FoodLocalizations.of(context);
    if (l10n == null || foodL10n == null) return const SizedBox.shrink();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, size: 80, color: Colors.grey.shade800),
          const SizedBox(height: 16),
          Text(
            foodL10n.foodHistoryEmpty,
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 24),
          // 🛡️ RECOVERY TRIGGER: Botão de redundância caso a lista falhe silenciosamente
          ElevatedButton.icon(
            onPressed: () => setState(() {}),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade900),
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text("FORÇAR ATUALIZAÇÃO", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }



  Future<void> _confirmDelete(NutritionHistoryItem item) async {
    final l10n = AppLocalizations.of(context);
    final foodL10n = FoodLocalizations.of(context);
    if (l10n == null || foodL10n == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(foodL10n.foodDeleteConfirmTitle,
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(foodL10n.foodDeleteConfirmContent,
            style: GoogleFonts.poppins(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(foodL10n.foodCancel,
                style: GoogleFonts.poppins(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(foodL10n.foodDelete,
                style: GoogleFonts.poppins(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await NutritionService().deleteHistoryItem(item);
      _loadHistory(); // Refresh list
    }
  }

  Future<void> _showDetailModal(NutritionHistoryItem item) async {
    debugPrint('🔍 [History] Opening details for: ${item.foodName}');

    final metadata = item.rawMetadata;
    if (metadata != null) {
      debugPrint('📄 [History] keys: ${metadata.keys.toList()}');
      // debugPrint('📄Raw: ${item.rawMetadata}'); // Uncomment if needed, can be huge
    } else {
      debugPrint('⚠️ [History] rawMetadata is NULL');
    }

    if (metadata == null || metadata.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Detalhes antigos não suportados na visualização completa.')));
      return;
    }

    try {
      // Robust conversion from dynamic Hive maps to Map<String, dynamic>
      final jsonMap = _convertToMapStringDynamic(item.rawMetadata);
      final analysis = FoodAnalysisModel.fromJson(jsonMap);

      final isChefVision = item.foodName?.toLowerCase().contains('inventário') ?? false;

      // 🛡️ LEI DE FERRO: Validação de Dados Chef Vision
      if (isChefVision) {
         final hasValidRecipes = analysis.receitas.any((r) => r.instructions.length > 20);
         if (!hasValidRecipes) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.errorRecipeDataCorrupted),
                  backgroundColor: AppDesign.error,
                )
              );
            }
            return;
         }
      }

      // 🚀 NAVEGAÇÃO INTELIGENTE (FoodRouter Protocol)
      // Direciona para a tela correta baseada na origem dos dados
      await FoodRouter.navigateToResult(
        context: context,
        analysis: analysis,
        imageFile: item.imagePath != null ? File(item.imagePath!) : null,
        isChefVision: isChefVision,
      );
    } catch (e, stack) {
      final l10n = AppLocalizations.of(context);
      if (l10n == null) return;
      debugPrint('❌ [History] Error parsing history item: $e');
      debugPrint(stack.toString());
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.errorMetadataMissing)));
    }
  }

  // Helper to deep convert to Map<String, dynamic>
  Map<String, dynamic> _convertToMapStringDynamic(dynamic input) {
    final fixed = _deepFixMaps(input);
    if (fixed is Map) {
      return Map<String, dynamic>.from(fixed);
    }
    return {};
  }

  // Better implementation of the helper inside the class
  dynamic _deepFixMaps(dynamic value) {
    if (value is Map) {
      return value.map<String, dynamic>(
          (k, v) => MapEntry(k.toString(), _deepFixMaps(v)));
    }
    if (value is List) {
      return value.map((e) => _deepFixMaps(e)).toList();
    }
    return value;
  }

  Future<void> _generateHistoryPdf() async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.msgNoHistoryToExport)));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FoodExportConfigurationModal(
        allItems: _items,
        onGenerate: (selectedItems) {
          // Small delay to allow modal to close smoothly before pushing screen?
          // Not strictly necessary but good UX.
          // However, modal closes inside onGenerate (Navigator.pop).
          // So here we are back in HistoryScreen context.

          if (selectedItems.isEmpty) return;

              Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FoodPdfPreviewScreen(
                foodName: l10n.pdfTitleFoodHistory(DateFormat('dd/MM').format(DateTime.now())),
                buildPdf: (format) async {
                  final foodStrings = FoodLocalizations.of(context)!;
                  final doc = await FoodExportService().generateFoodHistoryReport(
                    items: selectedItems,
                    strings: foodStrings,
                  );
                  return doc.save();
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
