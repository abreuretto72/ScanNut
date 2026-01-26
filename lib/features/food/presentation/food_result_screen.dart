import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart'; // Pilar: Resolução de Dependência
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';
import '../models/food_analysis_model.dart';
import '../services/food_pdf_service.dart';

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

  @override
  void initState() {
    super.initState();
  }

  // --- CONSTRUTORES DE UI (PROTEÇÃO SM A256E) ---

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
                  IconButton(
                    icon: _isGeneratingPdf 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.share),
                    onPressed: _isGeneratingPdf ? null : () => _generatePdf(context),
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
                    labelColor: _themeColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: _themeColor,
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
          if (widget.analysis.identidade.alertaCritico.contains(':')) _buildAllergenWarning(),
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
    final micros = widget.analysis.micronutrientes;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNutritionalTable(l10n),
          const SizedBox(height: 16),
          Text("Micronutrientes (Estimativa IA)", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                    Text("${n.quantidade} (${n.percentualDv}%)", style: TextStyle(color: _themeColor, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                LinearPercentIndicator(
                  lineHeight: 8.0,
                  percent: (n.percentualDv / 100).clamp(0, 1),
                  progressColor: _themeColor,
                  backgroundColor: _themeColor.withValues(alpha: 0.1),
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
                 color: _themeColor.withValues(alpha: 0.05),
                 borderRadius: BorderRadius.circular(12),
                 border: Border.all(color: _themeColor.withValues(alpha: 0.2)),
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Row(children: [Icon(Icons.auto_awesome, size: 16, color: _themeColor), const SizedBox(width: 8), Text("Sinergia", style: TextStyle(fontWeight: FontWeight.bold, color: _themeColor))]),
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

  Widget _buildGastronomiaTab(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 150),
      child: Column(
        children: [
          _buildGastronomySection(l10n),
          if (widget.analysis.receitas.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Receitas Recomendadas", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...widget.analysis.receitas.map((r) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      title: Text(r.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Preparo: ${r.tempoPreparo}"),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(r.instrucoes, style: const TextStyle(fontSize: 12)),
                        )
                      ],
                    ),
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
              widget.analysis.identidade.alertaCritico,
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProsConsRow(AppLocalizations l10n) {
    final pros = widget.analysis.analise.pontosPositivos;
    final cons = widget.analysis.analise.pontosNegativos;
    
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
    final performance = widget.analysis.performance;
    if (performance.impactoFocoEnergia.isEmpty && performance.pontosPositivosCorpo.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color: Colors.blue.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bolt, color: Colors.blue),
                const SizedBox(width: 8),
                Text("Biohacking & Performance", 
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue)),
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
                    const Text("• ", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
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
    final gastro = widget.analysis.gastronomia;
    if (gastro.smartSwap.isEmpty && gastro.dicaEspecialista.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color: Colors.orange.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.restaurant, color: Colors.orange),
                const SizedBox(width: 8),
                Text("Inteligência Culinária", 
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.orange)),
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
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: Colors.blue),
            const SizedBox(width: 4),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue), overflow: TextOverflow.ellipsis)),
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
            color: _themeColor.withValues(alpha: 0.2),
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
            widget.analysis.identidade.nome,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: _themeColor,
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
    final status = widget.analysis.identidade.semaforoSaude.toLowerCase();
    
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
        Text("Semáforo: ${widget.analysis.identidade.semaforoSaude}", 
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
            _nutritionRow("Calorias", "${widget.analysis.macros.calorias100g} kcal/100g", Icons.fireplace),
            _nutritionRow("Proteínas", widget.analysis.macros.proteinas, Icons.fitness_center),
            _nutritionRow("Carboidratos", widget.analysis.macros.carboidratosLiquidos, Icons.grain),
            _nutritionRow("Gorduras", widget.analysis.macros.gordurasPerfil, Icons.water_drop),
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
          Icon(icon, color: _themeColor, size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
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
        color: _themeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _themeColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: _themeColor),
              const SizedBox(width: 8),
              Text("Recomendação", style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(widget.analysis.analise.vereditoIa),
        ],
      ),
    );
  }

  Future<void> _generatePdf(BuildContext context) async {
    setState(() => _isGeneratingPdf = true);
    try {
      final pdfService = FoodPdfService();
      final labels = FoodPdfLabels(
        title: "Análise Nutricional",
        date: DateFormat('dd/MM/yyyy').format(DateTime.now()),
        nutrientsTable: "Tabela Nutricional",
        qty: "Qtd",
        dailyGoal: "% Diário",
        calories: "Calorias",
        proteins: "Proteínas",
        carbs: "Carboidratos",
        fats: "Gorduras",
        healthRating: "Nível de Saúde",
        clinicalRec: "Parecer Clínico",
        disclaimer: "Aviso: Consulte um especialista.",
      );

      await pdfService.generateAndPreview(widget.analysis, labels);
    } catch (e) {
       debugPrint("PDF Error: $e");
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao gerar PDF: $e")));
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
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
