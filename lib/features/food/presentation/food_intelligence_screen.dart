import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:scannut/l10n/app_localizations.dart';
import 'package:scannut/features/food/l10n/app_localizations.dart';
import '../models/food_analysis_model.dart';
import '../services/food_export_service.dart';
import '../services/recipe_service.dart';
import '../services/nutrition_service.dart';
import '../services/food_config_service.dart';
import 'widgets/food_recipe_card.dart';
import '../../../../core/theme/app_design.dart';
import 'food_pdf_preview_screen.dart';

/// 🛡️ FOOD INTELLIGENCE SCREEN (Era Gemini 2.5)
/// Tela Unificada de Análise Alimentar e Biohacking
class FoodIntelligenceScreen extends ConsumerStatefulWidget {
  final FoodAnalysisModel analysis;
  final File? imageFile;
  final bool isReadOnly;

  const FoodIntelligenceScreen({
    super.key,
    required this.analysis,
    this.imageFile,
    this.isReadOnly = false,
  });

  @override
  ConsumerState<FoodIntelligenceScreen> createState() => _FoodIntelligenceScreenState();
}

class _FoodIntelligenceScreenState extends ConsumerState<FoodIntelligenceScreen> {
  bool _isGeneratingPdf = false;
  late FoodAnalysisModel _analysis;
  Color _activeThemeColor = AppDesign.foodOrange;

  @override
  void initState() {
    super.initState();
    _analysis = widget.analysis;
    _loadRemoteConfig();
  }

  Future<void> _loadRemoteConfig() async {
    try {
      final config = await FoodConfigService().getFoodConfig();
      if (mounted) {
        setState(() {
          _activeThemeColor = config.enforceOrangeTheme ? AppDesign.foodOrange : AppDesign.foodOrange;
        });
        
        // Snackbar removed per Iron Law of Cleanliness
      }
    } catch (e) {
      debugPrint("Remote Config Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = FoodLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppDesign.backgroundDark, // 🛡️ Solid Background (Iron Law)
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              _buildSliverAppBar(l10n),
            ];
          },
          body: Container(
             color: AppDesign.backgroundDark, // Ensure body also has background
             child: TabBarView(
              children: [
                // 1. NUTRIÇÃO
                CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildMainHeader(l10n),
                            const SizedBox(height: 24),
                            // 1. Energy Balance & Macros (Priority)
                            _buildNutritionalDetails(l10n),
                            const SizedBox(height: 16),
                            // 2. Smart Swaps
                            _SmartSwapSection(analysis: _analysis, l10n: l10n, themeColor: _activeThemeColor),
                            const SizedBox(height: 16),
                            // 3. Processing X-Ray
                            _buildProcessingXRay(l10n),
                          ],
                        ),
                      ),
                    ),
                    const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
                  ],
                ),

                // 2. BIOHACKING (Deep Dive)
                CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                       child: Padding(
                         padding: const EdgeInsets.all(16),
                         child: Column(
                           children: [
                              _buildBiohackingCard(l10n),
                              const SizedBox(height: 16),
                              _buildAdvancedInsights(l10n),
                           ],
                         ),
                       ),
                    ),
                    const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
                  ],
                ),

                // 3. RECEITAS
                CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverToBoxAdapter(
                        child: _buildRecipesSection(l10n),
                      ),
                    ),
                     const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(FoodLocalizations l10n) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: _activeThemeColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
             widget.imageFile != null
                ? Image.file(widget.imageFile!, fit: BoxFit.cover)
                : Container(color: Colors.grey[800], child: const Icon(Icons.fastfood, size: 80, color: Colors.white24)),
             // Overlay for readability
             Container(
               decoration: BoxDecoration(
                 gradient: LinearGradient(
                   begin: Alignment.topCenter,
                   end: Alignment.bottomCenter,
                   colors: [
                     Colors.transparent,
                     Colors.black.withValues(alpha: 0.7),
                   ]
                 )
               ),
             )
          ]
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          color: AppDesign.backgroundDark, // Background for the TabBar to sit on
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: TabBar(
            indicatorColor: _activeThemeColor,
            indicatorWeight: 4,
            labelColor: _activeThemeColor,
            unselectedLabelColor: Colors.white54,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: "Nutrição"),
              Tab(text: "Biohacking"),
              Tab(text: "Receitas"),
            ],
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: _isGeneratingPdf ? null : () => _generateIntelligencePdf(context),
                 icon: _isGeneratingPdf 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 24),
                tooltip: l10n.foodExportPdfTooltip,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainHeader(FoodLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _analysis.identidade.nome,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _activeThemeColor,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
             Container(
               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
               decoration: BoxDecoration(
                 color: _getTrafficLightColor(_analysis.identidade.semaforoSaude).withValues(alpha: 0.1),
                 borderRadius: BorderRadius.circular(8),
                 border: Border.all(color: _getTrafficLightColor(_analysis.identidade.semaforoSaude).withValues(alpha: 0.3)),
               ),
               child: Text(
                 _analysis.identidade.semaforoSaude.toUpperCase(),
                 style: TextStyle(
                   color: _getTrafficLightColor(_analysis.identidade.semaforoSaude),
                   fontWeight: FontWeight.bold,
                   fontSize: 12
                 ),
               ),
             ),
             const SizedBox(width: 12),
             Expanded(
               child: Wrap(
                 crossAxisAlignment: WrapCrossAlignment.center,
                 spacing: 8,
                 runSpacing: 4,
                 children: [
                   Text(
                     "${_analysis.macros.calorias100g} kcal/100g",
                     style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white70),
                   ),
                   if (widget.imageFile != null)
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                       decoration: BoxDecoration(
                         color: AppDesign.chefVisionPurple.withValues(alpha: 0.15),
                         borderRadius: BorderRadius.circular(6),
                         border: Border.all(color: AppDesign.chefVisionPurple.withValues(alpha: 0.5)),
                       ),
                       child: Text(
                         l10n.chefVisionLabel,
                         style: GoogleFonts.poppins(
                           fontSize: 10,
                           fontWeight: FontWeight.bold,
                           color: AppDesign.chefVisionPurple,
                         ),
                       ),
                     ),
                 ],
               ),
             ),
          ],
        ),
         const SizedBox(height: 16),
         LinearPercentIndicator(
            lineHeight: 8.0,
            percent: (_analysis.performance.indiceSaciedade / 10).clamp(0.0, 1.0),
            backgroundColor: Colors.grey.withValues(alpha: 0.2),
            progressColor: _activeThemeColor,
            barRadius: const Radius.circular(4),
            leading: Text(l10n.foodSatietyIndex, style: const TextStyle(fontSize: 10, color: Colors.white70)), 
            trailing: Text("${_analysis.performance.indiceSaciedade}/10", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
         ),
      ],
    );
  }

  Widget _buildBiohackingCard(FoodLocalizations l10n) {
    if (_analysis.performance.impactoFocoEnergia.isEmpty && _analysis.micronutrientes.sinergiaNutricional.isEmpty) {
      return const Center(child: Text("Sem dados de biohacking", style: TextStyle(color: Colors.white54)));
    }

    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bolt, color: Colors.blueAccent, size: 24),
                const SizedBox(width: 10),
                Text(
                  l10n.foodBiohacking, 
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_analysis.performance.impactoFocoEnergia.isNotEmpty)
              _buildBioItem(
                Icons.psychology, 
                l10n.foodFocusEnergy, 
                _analysis.performance.impactoFocoEnergia,
                Colors.purpleAccent
              ),

            if (_analysis.micronutrientes.sinergiaNutricional.isNotEmpty) ...[
              const SizedBox(height: 12),
               _buildBioItem(
                Icons.hub, 
                l10n.foodSynergy, 
                _analysis.micronutrientes.sinergiaNutricional,
                Colors.tealAccent
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildBioItem(IconData icon, String title, String content, Color accent) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(content, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingXRay(FoodLocalizations l10n) {
     if (_analysis.identidade.nivelProcessamento == null && _analysis.identidade.metodoCoccao == null) {
       return const SizedBox.shrink();
     }

     return Card(
       color: const Color(0xFF1E1E1E),
       elevation: 2,
       shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.circular(16),
         side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
       ),
       child: Padding(
         padding: const EdgeInsets.all(16.0),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Text("Raio-X (Processing X-Ray)", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
             const SizedBox(height: 12),
             Row(
               children: [
                 if (_analysis.identidade.nivelProcessamento != null)
                   Expanded(
                     child: _buildXRayBadge(
                       l10n.foodProcessing, 
                       _analysis.identidade.nivelProcessamento!,
                       Icons.factory
                     )
                   ),
                  if (_analysis.identidade.nivelProcessamento != null && _analysis.identidade.metodoCoccao != null)
                    const SizedBox(width: 8),
                  if (_analysis.identidade.metodoCoccao != null)
                   Expanded(
                     child: _buildXRayBadge(
                       "Método", 
                       _analysis.identidade.metodoCoccao!,
                       Icons.microwave
                     )
                   ),
               ],
             )
           ],
         ),
       ),
     );
  }

  Widget _buildXRayBadge(String label, String value, IconData icon) {
    Color color = Colors.green;
    if (value.toLowerCase().contains("ultra") || value.toLowerCase().contains("frit")) color = Colors.redAccent;
    else if (value.toLowerCase().contains("processado")) color = Colors.orangeAccent;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8))),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildNutritionalDetails(FoodLocalizations l10n) {
    return Card(
      color: const Color(0xFF1E1E1E), // Dark Card
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Row(
               children: [
                 Icon(Icons.monitor_heart_outlined, color: _activeThemeColor),
                 const SizedBox(width: 8),
                 Text("Balanço Energético & Macros", 
                   style: GoogleFonts.poppins(
                     fontSize: 16, 
                     fontWeight: FontWeight.bold, 
                     color: Colors.white
                   )
                 ),
               ],
             ),
             Divider(height: 24, color: Colors.white.withValues(alpha: 0.1)),
             _nutritionRow(l10n.foodNutrientsProteins, _analysis.macros.proteinas, Icons.fitness_center, Colors.blue),
             _nutritionRow(l10n.foodNutrientsCarbs, _analysis.macros.carboidratosLiquidos, Icons.grain, Colors.orange),
             _nutritionRow(l10n.foodNutrientsFats, _analysis.macros.gordurasPerfil, Icons.opacity, Colors.red),
           ],
        ),
      ),
    );
  }

  Widget _nutritionRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
             padding: const EdgeInsets.all(8),
             decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
             child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white70))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildAdvancedInsights(FoodLocalizations l10n) {
    if (_analysis.performance.insightsAvancados.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text("Insights Avançados (IA)", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: _activeThemeColor)),
        ),
        const SizedBox(height: 12),
        ..._analysis.performance.insightsAvancados.map((insight) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppDesign.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: Colors.orange, width: 4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lightbulb, color: Colors.orange, size: 18),
              const SizedBox(width: 12),
              Expanded(child: Text(insight, style: const TextStyle(fontSize: 13, height: 1.4))),
            ],
          ),
        )),
      ],
    );
  }
  
  // Replaced by _SmartSwapSection widget below
  // Widget _buildGastronomySection(FoodLocalizations l10n) { ... }

  Widget _buildRecipesSection(FoodLocalizations l10n) {
    if (_analysis.receitas.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.green.shade900.withValues(alpha: 0.2), // Fundo verde suave
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.greenAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Receitas indisponíveis para este item',
                style: GoogleFonts.poppins(color: Colors.greenAccent),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title handled by Tab or kept here? Tab implies header but maybe nice to keep.
        // Actually tabs usually don't repeat the header inside.
        // Removing "Receitas" title to avoid double labeling.
        
        ..._analysis.receitas.map((r) => FoodRecipeCard(
              recipe: r,
              originFoodName: _analysis.identidade.nome,
              themeColor: _activeThemeColor,
              onDelete: () {}, // Read only here
              isExpansionTile: true,
              initiallyExpanded: true,
           ),
        )
      ],
    );
  }

  Color _getTrafficLightColor(String status) {
    if (status.toLowerCase().contains('verde')) return Colors.green;
    if (status.toLowerCase().contains('vermelho')) return Colors.red;
    return Colors.orange;
  }

  // PDF Generator using the new Service
  Future<void> _generateIntelligencePdf(BuildContext context) async {
    setState(() => _isGeneratingPdf = true);
    try {
      final l10n = FoodLocalizations.of(context)!;
      final pdfFile = await FoodExportService().generateIntelligencePDF(_analysis, widget.imageFile, l10n);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FoodPdfPreviewScreen(pdfPath: pdfFile.path, foodName: _analysis.identidade.nome),
          ),
        );
      }
    } catch (e) {
      if(mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro PDF: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if(mounted) setState(() => _isGeneratingPdf = false);
    }
  }
}

/// 🔄 SMART SWAP SECTION
class _SmartSwapSection extends StatelessWidget {
  final FoodAnalysisModel analysis;
  final FoodLocalizations l10n;
  final Color themeColor;

  const _SmartSwapSection({
    required this.analysis,
    required this.l10n,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    if (analysis.gastronomia.smartSwap.isEmpty) return const SizedBox.shrink();

    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Container(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
             decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
             ),
             child: Row(
               children: [
                 const Icon(Icons.swap_horiz_rounded, color: Colors.blueAccent),
                 const SizedBox(width: 8),
                 Text(l10n.foodSmartSwap, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
               ],
             ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Text(
                   analysis.gastronomia.smartSwap,
                   style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.white),
                 ),
                 
                 const SizedBox(height: 12),
                 if (analysis.gastronomia.preservacaoNutrientes.isNotEmpty) ...[
                    Divider(color: Colors.white.withValues(alpha: 0.1)),
                    const SizedBox(height: 12),
                    Row(
                       children: [
                          const Icon(Icons.science, color: Colors.tealAccent, size: 16),
                          const SizedBox(width: 8),
                          const Text("Dica de Preservação", style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                       ],
                    ),
                    const SizedBox(height: 4),
                    Text(analysis.gastronomia.preservacaoNutrientes, style: const TextStyle(fontSize: 13, color: Colors.white70)),
                 ]
              ],
            ),
          )
        ],
      ),
    );
  }
}
