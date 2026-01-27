import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/theme/app_design.dart';
import '../models/recipe_history_item.dart';
import '../services/recipe_service.dart';
import 'widgets/recipe_export_configuration_modal.dart';
import '../services/food_export_service.dart';
import 'food_pdf_preview_screen.dart';
import 'package:scannut/l10n/app_localizations.dart';

class RecipeHistoryScreen extends StatefulWidget {
  const RecipeHistoryScreen({super.key});

  @override
  State<RecipeHistoryScreen> createState() => _RecipeHistoryScreenState();
}

class _RecipeHistoryScreenState extends State<RecipeHistoryScreen> {
  bool _isReady = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initService();
  }

  Future<void> _initService() async {
    debugPrint('🔍 [RecipeHistoryScreen] Starting initialization...');
    try {
      await RecipeService().init();
      // 🧹 SANEAMENTO RETROATIVO (Lei de Ferro)
      final removed = await RecipeService().sanitizeRecipeBox();
      
      if (removed > 0 && mounted) {
        final l10n = AppLocalizations.of(context);
        if (l10n != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.msgRecipeDiscarded, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(l10n.msgRecipeDiscardedDesc, style: const TextStyle(fontSize: 12)),
                ],
              ),
              backgroundColor: AppDesign.foodOrange.withValues(alpha: 0.9),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
      
      debugPrint('✅ [RecipeHistoryScreen] Service initialized successfully.');
      if (mounted) {
        setState(() {
          _isReady = true;
          _hasError = false;
        });
      }
    } catch (e, s) {
      debugPrint('❌ [RecipeHistoryScreen] Init Failed: $e');
      debugPrint('📜 [RecipeHistoryScreen] Stack Trace: $s');
      if (mounted) {
        setState(() {
          _isReady = true;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(l10n.historyTitleRecipes,
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            onPressed: () => _showExportModal(context),
            tooltip: l10n.tooltipExportPdf,
          )
        ],
      ),
      body: !_isReady
          ? const Center(
              child: CircularProgressIndicator(color: AppDesign.foodOrange))
          : _hasError
              ? Center(
                  child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                      l10n.historyErrorLoading(_errorMessage),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: Colors.redAccent)),
                ))
              : ValueListenableBuilder<Box<RecipeHistoryItem>>(
                  valueListenable:
                      Hive.box<RecipeHistoryItem>(RecipeService.boxName)
                          .listenable(),
                  builder: (context, box, _) {
                    debugPrint(
                        '🔍 Recipe History Debug: Box Open? ${box.isOpen}, Key Count: ${box.keys.length}, Values Count: ${box.values.length}');
                    final recipes = box.values.toList();
                    recipes.sort((a, b) => b.timestamp.compareTo(a.timestamp));

                    if (recipes.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.restaurant_menu,
                                size: 60,
                                color: AppDesign.foodOrange
                                    .withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            Text(
                              l10n.historyEmptyRecipes,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                  color: Colors.white54, fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: recipes.length,
                      itemBuilder: (context, index) {
                        return _buildRecipeCard(recipes[index]);
                      },
                    );
                  },
                ),
    );
  }

  Widget _buildRecipeCard(RecipeHistoryItem recipe) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Thumbnail
            Container(
              width: 50,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                  child: Icon(Icons.restaurant,
                      color: AppDesign.foodOrange, size: 30)),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          recipe.recipeName,
                          style: GoogleFonts.poppins(
                              color: AppDesign.foodOrange,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: AppDesign.foodOrange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(recipe.prepTime,
                            style: GoogleFonts.poppins(
                                color: AppDesign.foodOrange,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${recipe.foodName} • ${dateFormat.format(recipe.timestamp)}',
                    style: GoogleFonts.poppins(
                        color: Colors.white38, fontSize: 10),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recipe.instructions,
                    style: GoogleFonts.poppins(
                        color: Colors.white70, fontSize: 12, height: 1.3),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: () => _showFullRecipe(recipe),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Text(
                            AppLocalizations.of(context)?.btnViewDetails ?? '',
                            style: GoogleFonts.poppins(
                                color: Colors.white54, fontSize: 11)),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullRecipe(RecipeHistoryItem recipe) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(recipe.recipeName,
            style: GoogleFonts.poppins(
                color: AppDesign.foodOrange, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (recipe.imagePath != null &&
                  File(recipe.imagePath!).existsSync())
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(recipe.imagePath!),
                      width: double.infinity, height: 200, fit: BoxFit.cover),
                ),
              const SizedBox(height: 16),
              Text(
                  l10n.labelMainIngredient(recipe.foodName),
                  style:
                      GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 16),
              Text(recipe.instructions,
                  style:
                      GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonClose,
                style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showExportModal(BuildContext context) {
    if (!Hive.isBoxOpen(RecipeService.boxName)) return;

    final box = Hive.box<RecipeHistoryItem>(RecipeService.boxName);
    final allItems = box.values.toList();
    allItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (allItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.msgNoHistoryToExport)));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => RecipeExportConfigurationModal(
        allItems: allItems,
        onGenerate: (selectedItems) async {
          // Close the modal first
          Navigator.pop(modalContext);

          // Show loading dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => const Center(
                child: CircularProgressIndicator(color: AppDesign.foodOrange)),
          );

          try {
            // Close loading dialog before pushing
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }

            if (!mounted) return;

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FoodPdfPreviewScreen(
                  labels: FoodPdfLabels(
                    title: l10n.pdfTitleRecipeBook,
                    date: DateFormat('dd/MM/yyyy').format(DateTime.now()),
                    nutrientsTable: l10n.pdfDetailedNutrition,
                    qty: l10n.pdfQuantity,
                    dailyGoal: l10n.pdfGoalLabel,
                    calories: l10n.pdfCalories,
                    proteins: l10n.foodProt,
                    carbs: l10n.foodCarb,
                    fats: l10n.foodFat,
                    healthRating: l10n.labelTrafficLight,
                    clinicalRec: l10n.pdfAiVerdict,
                    disclaimer: "Aviso: Consulte um especialista.",
                    recipesTitle: l10n.foodRecipesTitle,
                    justificationLabel: l10n.foodJustification,
                    difficultyLabel: l10n.foodDifficulty,
                    instructionsLabel: l10n.foodInstructions,
                  ),
                  buildPdf: (format) async {
                    return await FoodExportService().generateRecipeHistoryReportFromList(
                      selectedItems,
                      FoodPdfLabels(
                        title: l10n.pdfTitleRecipeBook,
                        date: DateFormat('dd/MM/yyyy').format(DateTime.now()),
                        nutrientsTable: l10n.pdfDetailedNutrition,
                        qty: l10n.pdfQuantity,
                        dailyGoal: l10n.pdfGoalLabel,
                        calories: l10n.pdfCalories,
                        proteins: l10n.foodProt,
                        carbs: l10n.foodCarb,
                        fats: l10n.foodFat,
                        healthRating: l10n.labelTrafficLight,
                        clinicalRec: l10n.pdfAiVerdict,
                        disclaimer: "Aviso: Consulte um especialista.",
                        recipesTitle: l10n.foodRecipesTitle,
                        justificationLabel: l10n.foodJustification,
                        difficultyLabel: l10n.foodDifficulty,
                        instructionsLabel: l10n.foodInstructions,
                      ),
                    );
                  },
                ),
              ),
            );
          } catch (e) {
            // Close loading dialog on error
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }

            debugPrint('❌ Error generating PDF: $e');

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(l10n.pdfErrorGeneration(e.toString()))));
            }
          }
        },
      ),
    );
  }

  Future<void> _confirmClear() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(l10n.dialogClearHistoryTitle,
            style: GoogleFonts.poppins(color: Colors.white)),
        content: Text(l10n.dialogClearHistoryBody,
            style: GoogleFonts.poppins(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.commonCancel)),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.commonDelete,
                  style: const TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await RecipeService().clearHistory();
    }
  }
}
