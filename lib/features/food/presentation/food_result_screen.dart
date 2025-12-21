import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import '../models/food_analysis_model.dart';
import '../../../core/providers/settings_provider.dart';

class FoodResultScreen extends ConsumerStatefulWidget {
  final FoodAnalysisModel analysis;
  final File? imageFile;
  final VoidCallback onSave;

    const FoodResultScreen({Key? key, required this.analysis, this.imageFile, required this.onSave}) : super(key: key);

  @override
  ConsumerState<FoodResultScreen> createState() => _FoodResultScreenState();
}

class _FoodResultScreenState extends ConsumerState<FoodResultScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  final Color _themeColor = const Color(0xFF00E676); // Green Accent

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _generatePDF() async {
    final pdf = pw.Document();

    pw.MemoryImage? image;
    if (widget.imageFile != null) {
      final imageBytes = await widget.imageFile!.readAsBytes();
      image = pw.MemoryImage(imageBytes);
    }

    final now = DateTime.now();
    final dateStr = "${now.day}/${now.month}/${now.year} - ${now.hour}:${now.minute}";

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                   pw.Text("ScanNut", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 24, color: PdfColors.green)),
                   pw.Text("Dossiê Nutricional Profundo", style: pw.TextStyle(fontSize: 18)),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text("Gerado em: $dateStr", style: const pw.TextStyle(color: PdfColors.grey)),
            pw.SizedBox(height: 20),
            
            if (image != null) 
              pw.Center(child: pw.Image(image, height: 200, fit: pw.BoxFit.contain)),
            
            pw.SizedBox(height: 20),
            pw.Text("Alimento: ${widget.analysis.identidade.nome.replaceAll('aproximadamente', '+-').replaceAll('Aproximadamente', '+-')}", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
            pw.Text("Categoria (NOVA): ${widget.analysis.identidade.categoria}"),
            pw.SizedBox(height: 10),
            pw.Text("Veredito: ${widget.analysis.analise.vereditoIa}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),

            pw.Text("Composição Nutricional", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Text("Calorias: ${widget.analysis.macros.calorias} kcal"),
            pw.Text("Proteínas: ${widget.analysis.macros.proteinas['valor']} (${widget.analysis.macros.proteinas['aminoacidos']})"),
            pw.Text("Carboidratos Líquidos: ${widget.analysis.macros.carboidratos['liquidos']}"),
            pw.Text("Fibras: ${widget.analysis.macros.fibras['total']}"),
            pw.Text("Gorduras: ${widget.analysis.macros.gorduras['total']} (${widget.analysis.macros.gorduras['perfil']})"),
            pw.SizedBox(height: 20),

            pw.Text("Micronutrientes (Vitamins & Minerais)", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            ...widget.analysis.micronutrientes.lista.map((n) => pw.Bullet(text: "${n.nome}: ${n.quantidade.replaceAll('aproximadamente', '+-').replaceAll('Aproximadamente', '+-')} (${n.percentualDv}% DV) - ${n.funcao.replaceAll('veterinário', 'Vet').replaceAll('Veterinário', 'Vet').replaceAll('aproximadamente', '+-').replaceAll('Aproximadamente', '+-')}")),
            pw.SizedBox(height: 10),
            pw.Text("Sinergia: ${widget.analysis.micronutrientes.sinergiaNutricional.replaceAll('veterinário', 'Vet').replaceAll('Veterinário', 'Vet').replaceAll('aproximadamente', '+-').replaceAll('Aproximadamente', '+-')}", style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
            pw.SizedBox(height: 20),

            pw.Text("Biohacking e Performance", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Text("Indice de Saciedade: ${widget.analysis.performance.indiceSaciedade}/5"),
            pw.Text("Impacto no Foco: ${widget.analysis.performance.impactoNoFoco.replaceAll('veterinário', 'Vet').replaceAll('Veterinário', 'Vet').replaceAll('aproximadamente', '+-').replaceAll('Aproximadamente', '+-')}"),
            pw.Text("Momento Ideal: ${widget.analysis.performance.momentoIdeal}"),
            pw.SizedBox(height: 20),

            pw.Text("Inteligência Culinária", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Text("Melhor Preparo: ${widget.analysis.gastronomia.preservacaoNutrientes}"),
            pw.Text("Sugestão de Troca (Smart Swap): ${widget.analysis.gastronomia.smartSwap}"),
            
            pw.SizedBox(height: 30),
            pw.Text("Dica do Especialista:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.amber)),
            pw.Text(widget.analysis.dicaEspecialista.replaceAll('veterinário', 'Vet').replaceAll('Veterinário', 'Vet').replaceAll('aproximadamente', '+-').replaceAll('Aproximadamente', '+-')),

            pw.Footer(title: pw.Text("ScanNut App - Nutrição de Elite", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey))),
          ];
        },
      ),
    );

    try {
      final pdfBytes = await pdf.save();
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/food_dossier_${DateTime.now().millisecondsSinceEpoch}.pdf");
      await file.writeAsBytes(pdfBytes);
      
      if (mounted) {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.grey[900],
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.print, color: Colors.blueAccent),
                  title: const Text("Imprimir Relatório", style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    Navigator.pop(context);
                    await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share, color: Colors.greenAccent),
                  title: const Text("Compartilhar PDF", style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    Navigator.pop(context);
                    await Share.shareXFiles([XFile(file.path)], text: 'Dossiê Nutricional ScanNut - ${widget.analysis.identidade.nome.replaceAll('aproximadamente', '+-').replaceAll('Aproximadamente', '+-')}');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.open_in_new, color: Colors.amberAccent),
                  title: const Text("Abrir no Visualizador", style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    Navigator.pop(context);
                    await OpenFilex.open(file.path);
                  },
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Erro ao gerar PDF: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final dailyGoal = ref.read(settingsProvider).dailyCalorieGoal;

    return Scaffold(
      backgroundColor: Colors.black,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 350.0,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                  onPressed: _generatePDF,
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (widget.imageFile != null)
                      Hero(
                        tag: 'captured_food_image',
                        child: Image.file(
                          widget.imageFile!,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(color: Colors.grey.shade900),
                    
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.2),
                            Colors.black.withValues(alpha: 0.8),
                            Colors.black,
                          ],
                          stops: const [0.5, 0.7, 0.9, 1.0],
                        ),
                      ),
                    ),

                    Positioned(
                      left: 20,
                      bottom: 80,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCalorieBadge(dailyGoal),
                          const SizedBox(height: 8),
                          Text(
                            widget.analysis.identidade.nome
                                .replaceAll('aproximadamente', '+-')
                                .replaceAll('Aproximadamente', '+-'),
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: const [
                                Shadow(blurRadius: 10, color: Colors.black54, offset: Offset(0, 2)),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: _themeColor,
                    indicatorWeight: 3,
                    labelColor: _themeColor,
                    unselectedLabelColor: Colors.white54,
                    isScrollable: true,
                    labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                    tabs: const [
                      Tab(text: "RESUMO"),
                      Tab(text: "SAÚDE"),
                      Tab(text: "NUTRIENTES"),
                      Tab(text: "GASTRONOMIA"),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildResumoTab(),
            _buildSaudeTab(),
            _buildNutrientesTab(),
            _buildGastronomiaTab(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: widget.onSave,
        backgroundColor: _themeColor,
        icon: const Icon(Icons.save, color: Colors.black),
        label: Text(
          "Salvar Diário",
          style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildCalorieBadge(int dailyGoal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department_rounded, color: _themeColor, size: 16),
          const SizedBox(width: 6),
          Text(
            "${widget.analysis.macros.calorias} kcal",
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // --- TAB 1: RESUMO ---
  Widget _buildResumoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVitalityHeader(),
          const SizedBox(height: 24),
          Text("Veredito da IA", style: _sectionTitleStyle),
          const SizedBox(height: 8),
          Text(widget.analysis.analise.vereditoIa, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 15)),
          const SizedBox(height: 24),
          Text("Pontos Positivos", style: _sectionTitleStyle),
          const SizedBox(height: 12),
          ...widget.analysis.analise.pontosPositivos.map((p) => _buildPointRow(p, Icons.check_circle, Colors.green)),
          const SizedBox(height: 16),
          Text("Pontos de Atenção", style: _sectionTitleStyle),
          const SizedBox(height: 12),
          ...widget.analysis.analise.pontosNegativos.map((p) => _buildPointRow(p, Icons.warning_rounded, Colors.orangeAccent)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // --- TAB 2: SAÚDE ---
  Widget _buildSaudeTab() {
    final performance = widget.analysis.performance;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGlassCard(
            title: "Segurança Alimentar",
            icon: Icons.security,
            color: Colors.blueAccent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow("Alertas:", widget.analysis.identidade.alertaCritico),
                const Divider(color: Colors.white10),
                _buildInfoRow("Bioquímica:", widget.analysis.identidade.bioquimicaAlert),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildGlassCard(
            title: "Biohacking & Performance",
            icon: Icons.bolt,
            color: Colors.purpleAccent,
            child: Column(
              children: [
                _buildProgressRow("Índice de Saciedade", performance.indiceSaciedade / 5.0, Colors.tealAccent),
                const SizedBox(height: 16),
                _buildInfoRow("Impacto no Foco:", performance.impactoNoFoco),
                const SizedBox(height: 12),
                _buildInfoRow("Momento Ideal:", performance.momentoIdeal),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // --- TAB 3: NUTRIENTES ---
  Widget _buildNutrientesTab() {
    final macros = widget.analysis.macros;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Macronutrientes Avançados", style: _sectionTitleStyle),
          const SizedBox(height: 16),
          _buildMacroDetailRow("Proteínas", macros.proteinas['valor']!, macros.proteinas['aminoacidos']!, Colors.blue),
          _buildMacroDetailRow("Carboidratos", macros.carboidratos['total']!, "Líquidos: ${macros.carboidratos['liquidos']}", Colors.amber),
          _buildMacroDetailRow("Fibras", macros.fibras['total']!, macros.fibras['tipo']!, Colors.green),
          _buildMacroDetailRow("Gorduras", macros.gorduras['total']!, macros.gorduras['perfil']!, Colors.red),
          const SizedBox(height: 24),
          
          Text("Minerais e Vitaminas", style: _sectionTitleStyle),
          const SizedBox(height: 16),
          ...widget.analysis.micronutrientes.lista.map((n) => _buildNutrientLinear(n)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.cyanAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text("Sinergia: ${widget.analysis.micronutrientes.sinergiaNutricional}", style: GoogleFonts.poppins(fontSize: 12, color: Colors.cyanAccent))),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // --- TAB 4: GASTRONOMIA ---
  Widget _buildGastronomiaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGlassCard(
            title: "Inteligência Culinária",
            icon: Icons.restaurant_menu,
            color: Colors.orangeAccent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow("Preservação:", widget.analysis.gastronomia.preservacaoNutrientes),
                const SizedBox(height: 16),
                _buildInfoRow("Smart Swap (Troca):", widget.analysis.gastronomia.smartSwap),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildGlassCard(
            title: "Dica do Especialista",
            icon: Icons.lightbulb,
            color: Colors.amberAccent,
            child: Text(widget.analysis.dicaEspecialista, style: GoogleFonts.poppins(color: Colors.white, height: 1.5)),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // --- HELPERS ---

  Widget _buildVitalityHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white10,
        border: Border.all(color: _themeColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 35,
            lineWidth: 6,
            percent: 0.85, // Mock score
            progressColor: _themeColor,
            center: Text("A+", style: TextStyle(color: _themeColor, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.analysis.identidade.categoria, style: GoogleFonts.poppins(color: _themeColor, fontSize: 12, fontWeight: FontWeight.bold)),
                Text("Análise de Processamento", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required String title, required IconData icon, required Color color, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
          Text(value, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildPointRow(String text, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.8), fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, double percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 8),
        LinearPercentIndicator(
          lineHeight: 6,
          percent: percent.clamp(0.0, 1.0),
          progressColor: color,
          backgroundColor: Colors.white10,
          barRadius: const Radius.circular(3),
          padding: EdgeInsets.zero,
          animation: true,
        ),
      ],
    );
  }

  Widget _buildMacroDetailRow(String label, String value, String detail, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(width: 4, height: 40, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.poppins(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Text(value, style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(detail, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12), overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientLinear(NutrienteItem n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(n.nome, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13), overflow: TextOverflow.ellipsis)),
              Text("${n.quantidade.replaceAll('aproximadamente', '+-').replaceAll('Aproximadamente', '+-')} (${n.percentualDv}%)", style: GoogleFonts.poppins(color: _themeColor, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          LinearPercentIndicator(
            lineHeight: 4,
            percent: (n.percentualDv / 100.0).clamp(0.0, 1.0),
            progressColor: _themeColor,
            backgroundColor: Colors.white10,
            barRadius: const Radius.circular(2),
            padding: EdgeInsets.zero,
            animation: true,
          ),
        ],
      ),
    );
  }

  TextStyle get _sectionTitleStyle => GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white);
}
