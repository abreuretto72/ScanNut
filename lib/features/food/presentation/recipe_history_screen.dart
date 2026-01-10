import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/theme/app_design.dart';
import '../models/recipe_history_item.dart';
import '../services/recipe_service.dart';
import 'widgets/recipe_export_configuration_modal.dart';
import '../../../core/services/export_service.dart';
import '../../../core/widgets/pdf_preview_screen.dart';
import 'package:scannut/l10n/app_localizations.dart';

class RecipeHistoryScreen extends StatefulWidget {
  const RecipeHistoryScreen({Key? key}) : super(key: key);

  @override
  State<RecipeHistoryScreen> createState() => _RecipeHistoryScreenState();
}

class _RecipeHistoryScreenState extends State<RecipeHistoryScreen> {
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _initService();
  }

  Future<void> _initService() async {
    await RecipeService().init();
    if (mounted) {
      setState(() {
        _isReady = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Livro de Receitas da IA', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
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
            tooltip: 'Exportar PDF',
          )
        ],
      ),
      body: !_isReady 
          ? const Center(child: CircularProgressIndicator(color: AppDesign.foodOrange))
          : ValueListenableBuilder<Box<RecipeHistoryItem>>(
              valueListenable: Hive.box<RecipeHistoryItem>(RecipeService.boxName).listenable(),
              builder: (context, box, _) {
                debugPrint('🔍 Recipe History Debug: Box Open? ${box.isOpen}, Key Count: ${box.keys.length}, Values Count: ${box.values.length}');
                final recipes = box.values.toList();
                recipes.sort((a, b) => b.timestamp.compareTo(a.timestamp));

                if (recipes.isEmpty) {
                   return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.restaurant_menu, size: 60, color: AppDesign.foodOrange.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          Text(
                            'Suas receitas sugeridas pela IA\naparecerão aqui.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 16),
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
        color: Colors.white.withOpacity(0.05),
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
              child: const Center(child: Icon(Icons.restaurant, color: AppDesign.foodOrange, size: 30)),
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
                          style: GoogleFonts.poppins(color: AppDesign.foodOrange, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppDesign.foodOrange.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                        child: Text(recipe.prepTime, style: GoogleFonts.poppins(color: AppDesign.foodOrange, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${recipe.foodName} • ${dateFormat.format(recipe.timestamp)}',
                    style: GoogleFonts.poppins(color: Colors.white38, fontSize: 10),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recipe.instructions,
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12, height: 1.3),
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
                        child: Text('Ver Detalhes >', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11)),
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
        title: Text(recipe.recipeName, style: GoogleFonts.poppins(color: AppDesign.foodOrange, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                  if (recipe.imagePath != null && File(recipe.imagePath!).existsSync())
                    ClipRRect(
                       borderRadius: BorderRadius.circular(12),
                       child: Image.file(File(recipe.imagePath!), width: double.infinity, height: 200, fit: BoxFit.cover),
                    ),
                  const SizedBox(height: 16),
                  Text('Ingrediente Principal: ${recipe.foodName}', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 16),
                  Text(recipe.instructions, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fechar', style: GoogleFonts.poppins(color: Colors.white)),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhuma receita para exportar!')));
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
              child: CircularProgressIndicator(color: AppDesign.foodOrange)
            ),
          );

          try {
            final doc = await ExportService().generateRecipeBookReport(
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
                  title: 'Livro de Receitas IA',
                  buildPdf: (format) async => doc.save(),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Erro ao gerar PDF. Tente novamente.'))
              );
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
        title: Text('Limpar Histórico?', style: GoogleFonts.poppins(color: Colors.white)),
        content: Text('Isso apagará todas as receitas salvas.', style: GoogleFonts.poppins(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Limpar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await RecipeService().clearHistory();
    }
  }
}
