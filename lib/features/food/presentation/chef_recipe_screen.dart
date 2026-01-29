import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:scannut/features/food/l10n/app_localizations.dart';
import 'package:scannut/core/theme/app_design.dart';
import 'package:scannut/features/food/models/food_analysis_model.dart';
import 'package:scannut/features/food/models/food_recipe_suggestion.dart';
import 'package:scannut/features/food/services/food_export_service.dart';
import 'package:scannut/core/widgets/pdf_preview_screen.dart';

class ChefRecipeScreen extends StatelessWidget {
  final FoodAnalysisModel analysis;
  final File? imageFile;

  const ChefRecipeScreen({
    super.key,
    required this.analysis,
    this.imageFile,
  });

  @override
  Widget build(BuildContext context) {
    // 🛡️ Saneamento de Linter: Usando .withValues em vez de .withOpacity (User Req 5)
    final Color primaryColor = AppDesign.foodOrange;
    final Color accentColor = const Color(0xFFE65100); // Darker orange

    // Extract recipes
    final recipes = analysis.receitas;

    return Scaffold(
      backgroundColor: AppDesign.backgroundDark,
      appBar: AppBar(
        title: Text(
          "Chef Vision",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            tooltip: "Gerar PDF de Receitas",
            onPressed: () => _generatePDF(context),
          ),
        ],
      ),
      body: recipes.isEmpty
          ? Center(
              child: Text(
                "Nenhuma receita encontrada para os ingredientes.",
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            )
          : SafeArea(
              bottom: true,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // 80px bottom padding (Institutional Footer Protection)
                itemCount: recipes.length + 1, // +1 for Header info
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildHeader(context);
                  }
                  final recipe = recipes[index - 1];
                  return _buildRecipeCard(context, recipe, primaryColor, accentColor);
                },
              ),
            ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    // Show detected ingredients summary
    final ingredients = analysis.identidade.nome.replacingOccurrences(of: "Inventário: ", replacement: "");
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            const Icon(Icons.kitchen, color: AppDesign.foodOrange, size: 32),
            const SizedBox(height: 12),
            Text(
              "Inventário Detectado",
              style: GoogleFonts.poppins(
                color: AppDesign.foodOrange,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              ingredients,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, RecipeSuggestion recipe, Color primary, Color accent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title & Meta
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary.withValues(alpha: 0.2), Colors.transparent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        recipe.name,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildMetaBadge(Icons.timer, recipe.prepTime, primary),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildMetaBadge(Icons.local_fire_department, recipe.calories, AppDesign.error),
                    const SizedBox(width: 8),
                    _buildMetaBadge(Icons.signal_cellular_alt, recipe.difficulty, AppDesign.warning),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Colors.white10),

          // Body: Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // We use Markdown to render the "instructions" field which contains Ingredients & Prep Mode
                MarkdownBody(
                  data: recipe.instructions,
                  styleSheet: MarkdownStyleSheet(
                    p: GoogleFonts.poppins(color: Colors.white70, fontSize: 14, height: 1.6),
                    strong: GoogleFonts.poppins(color: primary, fontWeight: FontWeight.bold),
                    h1: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    h2: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    listBullet: TextStyle(color: primary),
                  ),
                ),
              ],
            ),
          ),

          // Justification Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: Colors.black.withValues(alpha: 0.2),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: Colors.yellow, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    recipe.justification,
                    style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(color: color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePDF(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfPreviewScreen(
          title: "Chef Vision Recipes",
          buildPdf: (format) async {
             final strings = FoodLocalizations.of(context)!;
             final pdf = await FoodExportService().generateChefVisionReport(
               analysis: analysis, 
               strings: strings,
               imageFile: imageFile
             );
             return pdf.save();
          },
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String replacingOccurrences({required String of, required String replacement}) {
    return replaceAll(of, replacement);
  }
}
