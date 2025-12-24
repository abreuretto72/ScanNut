import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import '../../models/plant_analysis_model.dart';
import '../../../../core/utils/color_helper.dart';

class PlantResultCard extends StatefulWidget {
  final PlantAnalysisModel analysis;
  final String? imagePath;
  final VoidCallback onSave;
  final VoidCallback onShop;

    const PlantResultCard({Key? key, required this.analysis, this.imagePath, required this.onSave, required this.onShop}) : super(key: key);

  @override
  State<PlantResultCard> createState() => _PlantResultCardState();
}

class _PlantResultCardState extends State<PlantResultCard> with SingleTickerProviderStateMixin {
  bool _isSaved = false;
  late TabController _tabController;
  final Color _themeColor = const Color(0xFF00E676);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_handleTabSelection);
    HapticFeedback.mediumImpact();
    
    // Check for toxicity and show warning jump-scare
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.analysis.segurancaBiofilia.segurancaDomestica['toxica_para_pets'] == true ||
          widget.analysis.segurancaBiofilia.segurancaDomestica['toxica_para_criancas'] == true) {
        _showToxicityWarning();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showToxicityWarning() {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: Colors.red.shade900.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25), side: const BorderSide(color: Colors.redAccent, width: 2)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Text("ALERTA CRÍTICO", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Esta planta possui componentes TÓXICOS!",
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (widget.analysis.segurancaBiofilia.segurancaDomestica['toxica_para_pets'] == true)
                _buildToxicityBadge("TÓXICA PARA PETS 🐾"),
              if (widget.analysis.segurancaBiofilia.segurancaDomestica['toxica_para_criancas'] == true)
                _buildToxicityBadge("TÓXICA PARA CRIANÇAS 👶"),
              const SizedBox(height: 16),
              Text(
                widget.analysis.segurancaBiofilia.segurancaDomestica['sintomas_ingestao'] ?? "Cuidado com a ingestão acidental.",
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("ENTENDI O RISCO", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToxicityBadge(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white30)),
      child: Text(text, style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Color get _statusColor => ColorHelper.getPlantThemeColor(widget.analysis.urgency);
  IconData get _statusIcon => widget.analysis.isHealthy
      ? FontAwesomeIcons.leaf
      : FontAwesomeIcons.circleExclamation;

  Future<void> _generatePDF() async {
    final pdf = pw.Document();

    pw.MemoryImage? image;
    if (widget.imagePath != null) {
      final imageBytes = await File(widget.imagePath!).readAsBytes();
      image = pw.MemoryImage(imageBytes);
    }

    final now = DateTime.now();
    final dateStr = "${now.day}/${now.month}/${now.year} - ${now.hour}:${now.minute}";

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          final plant = widget.analysis;
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                   pw.Text("ScanNut", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 24, color: PdfColors.green)),
                   pw.Text("Dossiê Botânico Definitivo", style: pw.TextStyle(fontSize: 18)),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text("Gerado em: $dateStr", style: const pw.TextStyle(color: PdfColors.grey)),
            pw.SizedBox(height: 20),
            
            if (image != null) 
              pw.Center(child: pw.Image(image, height: 200, fit: pw.BoxFit.contain)),
            
            pw.SizedBox(height: 20),
            pw.Text("Identificação:", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Text("Nome Popular: ${plant.identificacao.nomesPopulares.join(', ')}"),
            pw.Text("Nome Científico: ${plant.identificacao.nomeCientifico}"),
            pw.Text("Família: ${plant.identificacao.familia}"),
            pw.Text("Origem: ${plant.identificacao.origemGeografica}"),
            pw.SizedBox(height: 20),

            pw.Text("Status de Saúde", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
            pw.Divider(),
            pw.Text("Condição: ${plant.saude.condicao}"),
            pw.SizedBox(height: 20),

            pw.Text("Guia de Sobrevivência (Hardware)", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Text("Luz: ${plant.sobrevivencia.luminosidade['tipo']} - ${plant.sobrevivencia.luminosidade['explicacao'].toString().replaceAll('veterinário', 'Vet').replaceAll('Veterinário', 'Vet').replaceAll('aproximadamente', '+-').replaceAll('Aproximadamente', '+-')}"),
            pw.Text("Rega: ${plant.sobrevivencia.regimeHidrico['frequencia_ideal'].toString().replaceAll('veterinário', 'Vet').replaceAll('Veterinário', 'Vet').replaceAll('aproximadamente', '+-').replaceAll('Aproximadamente', '+-')} | ${plant.sobrevivencia.regimeHidrico['sinais_sede']}"),
            pw.SizedBox(height: 20),

            pw.Text("Segurança e Biofília", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Text("Tóxica Pets: ${plant.segurancaBiofilia.segurancaDomestica['toxica_para_pets'] == true ? 'SIM' : 'NÃO'}"),
            pw.Text("Tóxica Crianças: ${plant.segurancaBiofilia.segurancaDomestica['toxica_para_criancas'] == true ? 'SIM' : 'NÃO'}"),
            pw.Text("Purificação Ar Score: ${plant.segurancaBiofilia.poderesBiofilicos['purificacao_ar_score']}/10"),
            pw.SizedBox(height: 20),

            pw.Text("Simbolismo e Lifestyle", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Text("Onde colocar: ${plant.lifestyle.posicionamentoIdeal.replaceAll('veterinário', 'Vet').replaceAll('Veterinário', 'Vet').replaceAll('aproximadamente', '+-').replaceAll('Aproximadamente', '+-')}"),
            pw.Text("Simbolismo: ${plant.lifestyle.simbolismo.replaceAll('veterinário', 'Vet').replaceAll('Veterinário', 'Vet').replaceAll('aproximadamente', '+-').replaceAll('Aproximadamente', '+-')}"),

            pw.Footer(title: pw.Text("ScanNut App - Inteligência Botânica", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey))),
          ];
        },
      ),
    );

    try {
      final pdfBytes = await pdf.save();
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/plant_dossier_${DateTime.now().millisecondsSinceEpoch}.pdf");
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
                    await Share.shareXFiles([XFile(file.path)], text: 'Dossiê Botânico ScanNut - ${widget.analysis.plantName}');
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

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    } else {
      setState(() {});
    }
  }

  Widget _buildTabContent(ScrollController sc) {
    switch (_tabController.index) {
      case 0: return _buildHardwareTab(sc);
      case 1: return _buildSaudeTab(sc);
      case 2: return _buildBiosTab(sc);
      case 3: return _buildPropagacaoTab(sc);
      case 4: return _buildLifestyleTab(sc);
      default: return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      minChildSize: 0.95,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: Colors.black.withValues(alpha: 0.9),
              child: Column(
                children: [
                   // Handle Bar
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white30,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // TOP ACTIONS ROW
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildActionButton(Icons.picture_as_pdf_rounded, "DOSSIÊ", Colors.redAccent, _generatePDF),
                          const SizedBox(width: 8),
                          _buildActionButton(
                            _isSaved ? Icons.check : Icons.save, 
                            _isSaved ? "Jardim" : "Salvar", 
                            _themeColor, 
                            () {
                              if (!_isSaved) {
                                setState(() => _isSaved = true);
                                widget.onSave();
                              }
                            }
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.analysis.plantName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                Text(
                                  widget.analysis.identificacao.nomeCientifico,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.white54,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _statusColor.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(color: _statusColor.withValues(alpha: 0.5)),
                            ),
                            child: Icon(_statusIcon, color: _statusColor, size: 24),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // TabBar
                    Container(
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: _themeColor,
                        labelColor: _themeColor,
                        unselectedLabelColor: Colors.white54,
                        isScrollable: true,
                        tabs: const [
                          Tab(text: "HARDWARE"),
                          Tab(text: "SAÚDE"),
                          Tab(text: "BIOS"),
                          Tab(text: "PROPAGAÇÃO"),
                          Tab(text: "LIFESTYLE"),
                        ],
                      ),
                    ),

                    // TabBarView
                    Expanded(
                      child: _buildTabContent(scrollController),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- TAB 1: HARDWARE (Survivor Guide) ---
  Widget _buildHardwareTab(ScrollController sc) {
    final surv = widget.analysis.sobrevivencia;
    final alertS = widget.analysis.alertasSazonais;
    return ListView(
      controller: sc,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      children: [
        Text("Semáforo de Sobrevivência 🚦", style: _tabTitleStyle),
        const SizedBox(height: 16),
        _buildSurvivorRow("☀️ LUZ", surv.luminosidade['tipo'], surv.luminosidade['explicacao'], Colors.amber),
        _buildSurvivorRow("💧 ÁGUA", surv.regimeHidrico['frequencia_ideal'], surv.regimeHidrico['método_rega'] ?? "Rega direta no solo", Colors.blue),
        _buildSurvivorRow("🪴 SOLO", surv.soloENutricao['adubo_recomendado'], surv.soloENutricao['frequencia_adubacao'], Colors.brown),
        const SizedBox(height: 24),
        _buildSectionCard(
          title: "Ajustes de Estação",
          icon: Icons.calendar_month,
          color: Colors.cyanAccent,
          child: Column(
            children: [
              _buildSeasonRow("Inverno (Dormência)", alertS.inverno),
              _buildSeasonRow("Verão (Crescimento)", alertS.verao),
            ],
          ),
        ),
      ],
    );
  }

  // --- TAB 2: SAÚDE ---
  Widget _buildSaudeTab(ScrollController sc) {
    final saude = widget.analysis.saude;
    return ListView(
      controller: sc,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      children: [
        _buildSectionCard(
          title: "Diagnóstico Clínico",
          icon: FontAwesomeIcons.stethoscope,
          color: _statusColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(saude.condicao, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              Text(saude.detalhes, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
              if (!widget.analysis.isHealthy) ...[
                const SizedBox(height: 16),
                _buildInfoLabel("Urgência:", widget.analysis.urgency),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildSectionCard(
          title: "Plano de Recuperação",
          icon: FontAwesomeIcons.kitMedical,
          color: Colors.redAccent,
          child: Text(saude.planoRecuperacao, style: GoogleFonts.poppins(color: Colors.white, height: 1.5)),
        ),
        if (!widget.analysis.isHealthy) ...[
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: widget.onShop,
            icon: const Icon(Icons.shopping_cart, color: Colors.black),
            label: const Text("COMPRAR TRATAMENTO SUGERIDO", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            style: ElevatedButton.styleFrom(backgroundColor: _themeColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ],
      ],
    );
  }

  // --- TAB 3: BIOS (Security & Well-being) ---
  Widget _buildBiosTab(ScrollController sc) {
    final bios = widget.analysis.segurancaBiofilia;
    return ListView(
      controller: sc,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      children: [
        _buildSectionCard(
          title: "Segurança Doméstica",
          icon: Icons.security,
          color: Colors.redAccent,
          child: Column(
            children: [
              _buildToggleInfo("Perigo para Pets 🐾", bios.segurancaDomestica['toxica_para_pets'] == true),
              _buildToggleInfo("Perigo para Crianças 👶", bios.segurancaDomestica['toxica_para_criancas'] == true),
              const SizedBox(height: 12),
              Text(bios.segurancaDomestica['sintomas_ingestao'] ?? "Sem alertas críticos.", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildSectionCard(
          title: "Poderes Biofílicos",
          icon: Icons.auto_awesome,
          color: Colors.pinkAccent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProgressBar("Escore de Purificação de Ar", (bios.poderesBiofilicos['purificacao_ar_score'] ?? 5) / 10.0, Colors.greenAccent),
              const SizedBox(height: 16),
              _buildInfoLabel("Umidificação:", bios.poderesBiofilicos['umidificacao_natural']),
              _buildInfoLabel("Bem-estar:", bios.poderesBiofilicos['impacto_bem_estar']),
            ],
          ),
        ),
      ],
    );
  }

  // --- TAB 4: PROPAGAÇÃO ---
  Widget _buildPropagacaoTab(ScrollController sc) {
    final prop = widget.analysis.propagacao;
    final eco = widget.analysis.ecossistema;
    return ListView(
      controller: sc,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      children: [
         _buildSectionCard(
           title: "Engenharia de Propagação",
           icon: Icons.copy,
           color: Colors.purpleAccent,
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               _buildInfoLabel("Método:", prop.metodo),
               _buildInfoLabel("Dificuldade:", prop.dificuldade),
               const Divider(color: Colors.white10),
               Text("Passo a Passo:", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.purpleAccent, fontSize: 12)),
               const SizedBox(height: 8),
               Text(prop.passoAPasso, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, height: 1.5)),
             ],
           ),
         ),
         const SizedBox(height: 20),
         _buildSectionCard(
           title: "Inteligência de Ecossistema",
           icon: Icons.group,
           color: Colors.tealAccent,
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               _buildInfoLabel("Companhias Ideais:", (eco.plantasParceiras as List? ?? []).join(', ')),
               _buildInfoLabel("Evitar Perto de:", (eco.plantasConflitantes as List? ?? []).join(', ')),
               _buildInfoLabel("Repelente Natural:", eco.repelenteNatural),
             ],
           ),
         ),
      ],
    );
  }

  // --- TAB 5: LIFESTYLE ---
  Widget _buildLifestyleTab(ScrollController sc) {
    final lifestyle = widget.analysis.lifestyle;
    final estetica = widget.analysis.estetica;
    return ListView(
      controller: sc,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      children: [
        _buildSectionCard(
          title: "Feng Shui Botânico",
          icon: Icons.home,
          color: Colors.amberAccent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoLabel("Onde Colocar:", lifestyle.posicionamentoIdeal),
              const SizedBox(height: 8),
              _buildInfoLabel("Simbolismo:", lifestyle.simbolismo),
            ],
          ),
        ),
        const SizedBox(height: 20),
         _buildSectionCard(
          title: "Estética Viva",
          icon: Icons.palette,
          color: Colors.orangeAccent,
          child: Column(
            children: [
              _buildInfoLabel("Floração:", estetica.epocaFloracao),
              _buildInfoLabel("Cor das Flores:", estetica.corDasFlores),
              _buildInfoLabel("Crescimento:", estetica.velocidadeCrescimento),
              _buildInfoLabel("Tamanho Máximo:", estetica.tamanhoMaximo),
            ],
          ),
        ),
      ],
    );
  }

  // --- HELPERS ---

  Widget _buildSurvivorRow(String title, String type, String desc, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
              const Spacer(),
              _buildHardwareBadge(type, color),
            ],
          ),
          const SizedBox(height: 8),
          Text(desc, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12), overflow: TextOverflow.visible),
        ],
      ),
    );
  }

  Widget _buildHardwareBadge(String label, Color color) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 100),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10), overflow: TextOverflow.ellipsis),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Color color, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildToggleInfo(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13), overflow: TextOverflow.ellipsis)),
          Icon(value ? Icons.dangerous : Icons.check_circle, color: value ? Colors.redAccent : Colors.greenAccent, size: 18),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, double percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
            Text("${(percent * 100).toInt()}%", style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        LinearPercentIndicator(lineHeight: 8, percent: percent.clamp(0.0, 1.0), progressColor: color, backgroundColor: Colors.white10, barRadius: const Radius.circular(4), padding: EdgeInsets.zero, animation: true),
      ],
    );
  }

  Widget _buildInfoLabel(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white54, fontSize: 12)),
          const SizedBox(width: 6),
          Expanded(child: Text(value.replaceAll('veterinário', 'Vet').replaceAll('Veterinário', 'Vet').replaceAll('aproximadamente', '+-').replaceAll('Aproximadamente', '+-'), style: const TextStyle(color: Colors.white, fontSize: 12), overflow: TextOverflow.visible)),
        ],
      ),
    );
  }

  Widget _buildSeasonRow(String season, String alert) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(season, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
          Text(alert, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  TextStyle get _tabTitleStyle => GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white);
}
