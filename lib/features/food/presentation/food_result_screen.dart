import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart'; // Pilar: Resolução de Dependência
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';
import '../models/food_analysis_model.dart';
import '../models/recipe_suggestion.dart';
import '../services/food_export_service.dart';
import '../services/recipe_service.dart';
import '../services/nutrition_service.dart';
import '../services/food_remote_config_repository.dart';
import 'food_pdf_preview_screen.dart';
import 'widgets/food_recipe_card.dart';
import '../../../../core/theme/app_design.dart';

class FoodResultScreen extends ConsumerStatefulWidget {
  final FoodAnalysisModel analysis;
  final File? imageFile;
  final bool isReadOnly;

  const FoodResultScreen({
    super.key,
    required this.analysis,
    this.imageFile,
    this.isReadOnly = false,
  });

  @override
  ConsumerState<FoodResultScreen> createState() => _FoodResultScreenState();
}

class _FoodResultScreenState extends ConsumerState<FoodResultScreen> {
  bool _isGeneratingPdf = false;
  final Color _themeColor = const Color(0xFF4CAF50); // Cor de domínio Comida (Verde)
  Color _activeThemeColor = const Color(0xFF4CAF50);
  late FoodAnalysisModel _analysis;

  @override
  void initState() {
    super.initState();
    _analysis = widget.analysis;
    _loadRemoteConfig();
  }

  Future<void> _loadRemoteConfig() async {
    try {
      final config = await FoodRemoteConfigRepository().fetchRemoteConfig();
      if (mounted) {
        setState(() {
          _activeThemeColor = config.enforceOrangeTheme ? AppDesign.foodOrange : _themeColor;
        });
        
        // Success Notification (Multiverso Digital Sync)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text("Configuração sincronizada com Multiverso Digital", style: TextStyle(color: Colors.white, fontSize: 12)),
          backgroundColor: Colors.green.withValues(alpha: 0.7),
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      debugPrint("Remote Config Error: $e");
    }
  }

  // --- CONSTRUTORES DE UI (PROTEÇÃO SM A256E) ---

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildImageHeader(),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: _activeThemeColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _showRecipesDialog(context),
                          icon: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 24),
                          tooltip: l10n.foodRecipesTooltip,
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        IconButton(
                          onPressed: _isGeneratingPdf ? null : () => _generatePdf(context),
                          icon: _isGeneratingPdf 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 24),
                          tooltip: l10n.exportPdfTooltip,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: _buildMainInfo(l10n),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    labelColor: _activeThemeColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: _activeThemeColor,
                    isScrollable: true,
                    tabs: const [
                      Tab(text: "RESUMO"),
                      Tab(text: "SAÚDE"),
                      Tab(text: "NUTRIENTES"),
                      Tab(text: "GASTRONOMIA"),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              _buildResumoTab(l10n),
              _buildSaudeTab(l10n),
              _buildNutrientesTab(l10n),
              _buildGastronomiaTab(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResumoTab(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 150),
      child: Column(
        children: [
          _buildNutritionalTable(l10n),
          _buildRecommendationCard(l10n),
          if (_analysis.identidade.alertaCritico.contains(':')) _buildAllergenWarning(),
          _buildProsConsRow(l10n),
          _buildFooter(l10n),
        ],
      ),
    );
  }

  Widget _buildSaudeTab(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 150),
      child: Column(
        children: [
          _buildBiohackingSection(l10n),
          _buildFooter(l10n),
        ],
      ),
    );
  }

  Widget _buildNutrientesTab(AppLocalizations l10n) {
    final micros = _analysis.micronutrientes;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNutritionalTable(l10n),
          const SizedBox(height: 16),
          Text("Micronutrientes (Estimativa IA)", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: _activeThemeColor)),
          const SizedBox(height: 12),
          if (micros.lista.isEmpty) 
             Center(child: Padding(padding: const EdgeInsets.all(20), child: Text("Carregando inteligência...", style: TextStyle(color: Colors.grey)))),
          ...micros.lista.map((n) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(n.nome, style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text("${n.quantidade} (${n.percentualDv}%)", style: TextStyle(color: _activeThemeColor, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                LinearPercentIndicator(
                  lineHeight: 8.0,
                  percent: (n.percentualDv / 100).clamp(0, 1),
                  progressColor: _activeThemeColor,
                  backgroundColor: _activeThemeColor.withValues(alpha: 0.1),
                  barRadius: const Radius.circular(10),
                  animation: true,
                ),
              ],
            ),
          )),
          if (micros.sinergiaNutricional.isNotEmpty) ...[
             const SizedBox(height: 20),
             Container(
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(
                 color: _activeThemeColor.withValues(alpha: 0.05),
                 borderRadius: BorderRadius.circular(12),
                 border: Border.all(color: _activeThemeColor.withValues(alpha: 0.2)),
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Row(children: [Icon(Icons.auto_awesome, size: 16, color: _activeThemeColor), const SizedBox(width: 8), Text("Sinergia", style: TextStyle(fontWeight: FontWeight.bold, color: _activeThemeColor))]),
                   const SizedBox(height: 8),
                   Text(micros.sinergiaNutricional, style: const TextStyle(fontSize: 12)),
                 ],
               ),
             ),
          ],
          const SizedBox(height: 150),
          _buildFooter(l10n),
        ],
      ),
    );
  }

  Future<void> _handleGenerateMoreRecipes() async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    
    // Rich Loading Feedback
    final loadingOverlay = OverlayEntry(
      builder: (context) => Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer, color: AppDesign.foodOrange, size: 40),
                const SizedBox(height: 16),
                Text(l10n.food_generating_recipes, style: const TextStyle(color: AppDesign.foodOrange, fontWeight: FontWeight.bold, decoration: TextDecoration.none, fontSize: 16)),
                const SizedBox(height: 12),
                const CircularProgressIndicator(color: AppDesign.foodOrange, strokeWidth: 3),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(loadingOverlay);

    try {
      final newRecipes = await RecipeService().generateRecipeSuggestions(_analysis.identidade.nome);
      loadingOverlay.remove();

      if (newRecipes.isEmpty) throw Exception("Falha na geração");

      await NutritionService().appendRecipes(_analysis.identidade.nome, newRecipes);

      setState(() {
         final updatedList = List<RecipeSuggestion>.from(_analysis.receitas)..addAll(newRecipes);
         _analysis = FoodAnalysisModel(
            identidade: _analysis.identidade,
            macros: _analysis.macros,
            micronutrientes: _analysis.micronutrientes,
            analise: _analysis.analise,
            performance: _analysis.performance,
            gastronomia: _analysis.gastronomia,
            receitas: updatedList,
            dicaEspecialista: _analysis.dicaEspecialista
         );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text("Receitas adicionadas com sucesso!", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green.withValues(alpha: 0.9)));
      }
    } on RecipeFallbackException catch (e) {
      if (loadingOverlay.mounted) loadingOverlay.remove();
      // 🛡️ FALLBACK HANDLING
      await NutritionService().appendRecipes(_analysis.identidade.nome, e.fallbackRecipes);
      
      setState(() {
         final updatedList = List<RecipeSuggestion>.from(_analysis.receitas)..addAll(e.fallbackRecipes);
         _analysis = FoodAnalysisModel(
            identidade: _analysis.identidade,
            macros: _analysis.macros,
            micronutrientes: _analysis.micronutrientes,
            analise: _analysis.analise,
            performance: _analysis.performance,
            gastronomia: _analysis.gastronomia,
            receitas: updatedList,
            dicaEspecialista: _analysis.dicaEspecialista
         );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.foodFallbackMessage, style: const TextStyle(color: Colors.white)),
          backgroundColor: AppDesign.foodOrange.withValues(alpha: 0.9)));
      }

    } catch (e) {
      if (loadingOverlay.mounted) loadingOverlay.remove();
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(
            children: [
              const Icon(Icons.timer_off_outlined, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(l10n.food_error_maintenance, style: const TextStyle(color: Colors.white))),
            ],
          ),
          backgroundColor: Colors.red.withValues(alpha: 0.9)));
      }
    }
  }

  Future<void> _confirmDeleteRecipe(RecipeSuggestion recipe) async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red[900],
        title: Text(l10n.food_delete_confirm_title, style: const TextStyle(color: Colors.white)),
        content: Text(l10n.food_delete_confirm_body, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.food_cancel, style: const TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.food_delete_confirm_action),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await NutritionService().removeRecipe(_analysis.identidade.nome, recipe.name);
      setState(() {
        _analysis.receitas.removeWhere((r) => r.name == recipe.name);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Receita '${recipe.name}' removida."),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Widget _buildGastronomiaTab(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 150),
      child: Column(
        children: [
          _buildGastronomySection(l10n),
          
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, color: AppDesign.foodOrange, size: 32),
              onPressed: () => _handleGenerateMoreRecipes(),
              tooltip: l10n.foodGenerateMoreRecipes,
            ),
          ),

          if (_analysis.receitas.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Receitas Recomendadas", 
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold, 
                          color: _activeThemeColor
                        )
                      ),
                      IconButton(
                        onPressed: () => _generateRecipesPdf(context),
                        icon: const Icon(Icons.picture_as_pdf_rounded, color: AppDesign.foodOrange, size: 20),
                        tooltip: l10n.exportPdfTooltip,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._analysis.receitas.map((r) => FoodRecipeCard(
                    recipe: r,
                    originFoodName: _analysis.identidade.nome,
                    themeColor: _activeThemeColor,
                    onDelete: () => _confirmDeleteRecipe(r),
                    isExpansionTile: true,
                  )),
                ],
              ),
            )
          ],
          _buildFooter(l10n),
        ],
      ),
    );
  }

  Widget _buildAllergenWarning() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _analysis.identidade.alertaCritico,
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProsConsRow(AppLocalizations l10n) {
    final pros = _analysis.analise.pontosPositivos;
    final cons = _analysis.analise.pontosNegativos;
    
    if (pros.isEmpty && cons.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pros.isNotEmpty) Expanded(child: _buildProsConsCard("Prós", pros, Colors.green)),
          if (pros.isNotEmpty && cons.isNotEmpty) const SizedBox(width: 12),
          if (cons.isNotEmpty) Expanded(child: _buildProsConsCard("Contras", cons, Colors.red)),
        ],
      ),
    );
  }

  Widget _buildProsConsCard(String title, List<String> items, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
          const SizedBox(height: 8),
          ...items.take(3).map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text("• $item", style: const TextStyle(fontSize: 11)),
          )),
        ],
      ),
    );
  }

  Widget _buildBiohackingSection(AppLocalizations l10n) {
    final performance = _analysis.performance;
    if (performance.impactoFocoEnergia.isEmpty && performance.pontosPositivosCorpo.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color: _activeThemeColor.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _activeThemeColor.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bolt, color: _activeThemeColor),
                const SizedBox(width: 8),
                Text("Biohacking & Performance", 
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: _activeThemeColor)),
              ],
            ),
            if (performance.impactoFocoEnergia.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text("Impacto Foco/Energia:", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(performance.impactoFocoEnergia, style: const TextStyle(fontSize: 13)),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _buildBioBadge(Icons.timer, performance.momentoIdealConsumo),
                const SizedBox(width: 8),
                _buildBioBadge(Icons.restaurant_menu, "Saciedade: ${performance.indiceSaciedade}/10"),
              ],
            ),
            if (performance.pontosPositivosCorpo.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...performance.pontosPositivosCorpo.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("• ", style: TextStyle(color: _activeThemeColor, fontWeight: FontWeight.bold)),
                    Expanded(child: Text(tip, style: const TextStyle(fontSize: 12))),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGastronomySection(AppLocalizations l10n) {
    final gastro = _analysis.gastronomia;
    if (gastro.smartSwap.isEmpty && gastro.dicaEspecialista.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color: _activeThemeColor.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _activeThemeColor.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.restaurant, color: _activeThemeColor),
                const SizedBox(width: 8),
                Text("Inteligência Culinária", 
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: _activeThemeColor)),
              ],
            ),
            if (gastro.smartSwap.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text("Smart Swap (Troca Inteligente):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(gastro.smartSwap, style: const TextStyle(fontSize: 13)),
            ],
            if (gastro.preservacaoNutrientes.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text("Técnica de Preparo:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(gastro.preservacaoNutrientes, style: const TextStyle(fontSize: 13)),
            ],
            if (gastro.dicaEspecialista.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text("Dica do Expert:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(gastro.dicaEspecialista, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBioBadge(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: _activeThemeColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: _activeThemeColor),
            const SizedBox(width: 4),
            Expanded(child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _activeThemeColor), overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(AppLocalizations l10n) {
    return Column(
      children: [
        Divider(color: Colors.white.withValues(alpha: 0.1), indent: 40, endIndent: 40),
        const SizedBox(height: 16),
        Text(
          "ScanNut © 2026",
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 12,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Nutrição Inteligente & Biohacking",
          style: TextStyle(
            color: _activeThemeColor.withValues(alpha: 0.2),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildImageHeader() {
    if (widget.imageFile == null) {
      return Container(
        height: 150,
        width: double.infinity,
        color: Colors.grey.shade900,
        child: const Icon(Icons.fastfood, size: 60, color: Colors.white24),
      );
    }
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: FileImage(widget.imageFile!),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildMainInfo(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _analysis.identidade.nome,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: _activeThemeColor,
            ),
          ),
          const SizedBox(height: 8),
          _buildHealthIndicator(l10n),
        ],
      ),
    );
  }

  Widget _buildHealthIndicator(AppLocalizations l10n) {
    double score = 0.5;
    Color color = Colors.orange;
    final status = _analysis.identidade.semaforoSaude.toLowerCase();
    
    if (status.contains('verde') || status.contains('green')) {
      score = 0.9;
      color = Colors.green;
    } else if (status.contains('vermelho') || status.contains('red')) {
      score = 0.2;
      color = Colors.red;
    } else {
      score = 0.5;
      color = Colors.orange;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Semáforo: ${_analysis.identidade.semaforoSaude}", 
          style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        LinearPercentIndicator( 
          lineHeight: 12.0,
          percent: score,
          progressColor: color,
          backgroundColor: Colors.white.withValues(alpha: 0.1), 
          barRadius: const Radius.circular(10),
          animation: true,
        ),
      ],
    );
  }

  Widget _buildNutritionalTable(AppLocalizations l10n) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _nutritionRow("Calorias", "\u00B1 ${_analysis.macros.calorias100g} kcal/100g", Icons.fireplace),
            _nutritionRow("Proteínas", "\u00B1 ${_analysis.macros.proteinas}", Icons.fitness_center),
            _nutritionRow("Carboidratos", "\u00B1 ${_analysis.macros.carboidratosLiquidos}", Icons.grain),
            _nutritionRow("Gorduras", "\u00B1 ${_analysis.macros.gordurasPerfil}", Icons.water_drop),
          ],
        ),
      ),
    );
  }

  Widget _nutritionRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: _activeThemeColor, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _activeThemeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _activeThemeColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: _activeThemeColor),
              const SizedBox(width: 8),
              Text("Recomendação", style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(_analysis.analise.vereditoIa),
        ],
      ),
    );
  }

  Future<void> _generatePdf(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    final labels = FoodPdfLabels(
      title: l10n.pdfFoodTitle,
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
      disclaimer: "Aviso: Consulte um especialista.", // Pode ser traduzido se houver chave
      recipesTitle: l10n.foodRecipesTitle,
      justificationLabel: l10n.foodJustification,
      difficultyLabel: l10n.foodDifficulty,
      instructionsLabel: l10n.foodInstructions,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FoodPdfPreviewScreen(
          analysis: _analysis,
          labels: labels,
        ),
      ),
    );
  }

  Future<void> _generateRecipesPdf(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    
    final labels = FoodPdfLabels(
      title: l10n.pdfFoodTitle,
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
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FoodPdfPreviewScreen(
          analysis: _analysis,
          labels: labels,
          isRecipesOnly: true,
        ),
      ),
    );
  }

  void _showRecipesDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.menu_book_rounded, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text("Receitas Recomendadas", 
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: _activeThemeColor, 
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _generateRecipesPdf(context),
                        icon: const Icon(Icons.picture_as_pdf_outlined, color: AppDesign.foodOrange),
                        tooltip: l10n.exportPdfTooltip,
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _analysis.receitas.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final r = _analysis.receitas[index];
                      return FoodRecipeCard(
                        recipe: r,
                        originFoodName: _analysis.identidade.nome,
                        themeColor: _activeThemeColor,
                        onDelete: () => _confirmDeleteRecipe(r),
                        isExpansionTile: false,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
