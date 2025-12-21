import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:printing/printing.dart';

import 'dart:io';
import '../../models/pet_analysis_result.dart';
import '../../../../core/utils/color_helper.dart';
import '../../../../core/utils/color_helper.dart';
import 'package:open_filex/open_filex.dart';
import '../../../../core/templates/race_nutrition_component.dart';
import '../../../../core/templates/weekly_meal_planner_component.dart';
import 'weekly_menu_screen.dart';
import 'vaccine_card.dart';
import '../../../../core/services/file_upload_service.dart';
import 'edit_pet_form.dart';
import '../../models/pet_profile_extended.dart';
import '../../services/pet_profile_service.dart';

class PetResultCard extends StatefulWidget {
  final PetAnalysisResult analysis;
  final String imagePath;
  final VoidCallback onSave;
  final String? petName;

  const PetResultCard({Key? key, required this.analysis, required this.imagePath, required this.onSave, this.petName}) : super(key: key);

  @override
  State<PetResultCard> createState() => _PetResultCardState();
}

class _PetResultCardState extends State<PetResultCard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSaved = false;
  final Color _themeColor = const Color(0xFF00E676);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_handleTabSelection);
    HapticFeedback.mediumImpact();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.analysis.analysisType == 'identification') {
        if (widget.analysis.higiene.manutencaoPelagem['alerta_subpelo'] != null && 
            widget.analysis.higiene.manutencaoPelagem['alerta_subpelo']!.toString().toLowerCase().contains('importante')) {
           _showSpecialWarning("ALERTA DE PELAGEM", widget.analysis.higiene.manutencaoPelagem['alerta_subpelo']);
        }
      }
    });
  }

  void _showSpecialWarning(String title, String message) {
     showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: Colors.blueGrey.shade900.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25), side: const BorderSide(color: Colors.cyanAccent, width: 2)),
          title: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.cyanAccent, size: 32),
              const SizedBox(width: 12),
              Text(title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Text(
            message,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("ENTENDI", style: GoogleFonts.poppins(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color get _urgencyColor => ColorHelper.getPetThemeColor(widget.analysis.urgenciaNivel);
  bool get _isEmergency => widget.analysis.urgenciaNivel.toLowerCase() == 'vermelho';

  Future<void> _generatePDF() async {
    final pdf = pw.Document();
    
    pw.MemoryImage? image;
    try {
      final imageBytes = await File(widget.imagePath).readAsBytes();
      image = pw.MemoryImage(imageBytes);
    } catch (e) {
      debugPrint("Erro carregar imagem PDF: $e");
    }

    final now = DateTime.now();
    final dateStr = "${now.day}/${now.month}/${now.year} - ${now.hour}:${now.minute}";

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          final pet = widget.analysis;
          if (pet.analysisType == 'diagnosis') {
             return [
               pw.Header(level: 0, child: pw.Text("ScanNut - Triage Veterinária", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 24, color: PdfColors.red))),
               pw.SizedBox(height: 10),
               if (image != null) pw.Center(child: pw.Image(image, height: 200)),
               pw.SizedBox(height: 20),
               pw.Text("Raça/Espécie: ${pet.especie} - ${pet.raca}"),
               pw.Text("Urgência: ${pet.urgenciaNivel}"),
               pw.Text("Descrição: ${pet.descricaoVisual}"),
               pw.Text("Recomendação: ${pet.orientacaoImediata.replaceAll('veterinário', 'Vet').replaceAll('Veterinário', 'Vet').replaceAll('aproximadamente', '+-').replaceAll('Aproximadamente', '+-')}"),
               pw.Footer(title: pw.Text("Gerado em $dateStr por ScanNut", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey))),
             ];
          }
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("ScanNut", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 24, color: PdfColors.green)),
                  pw.Text("Dossiê 360º de Pet", style: pw.TextStyle(fontSize: 18)),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text("Gerado em: $dateStr", style: const pw.TextStyle(color: PdfColors.grey)),
            pw.SizedBox(height: 10),
            // Pet Name - Always visible
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text(
                "🐾 ${widget.petName ?? 'Pet sem nome'}",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 18,
                  color: PdfColors.green900,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            if (image != null) pw.Center(child: pw.Image(image, height: 200, fit: pw.BoxFit.contain)),
            pw.SizedBox(height: 20),
            
            pw.Text("Identidade e Perfil", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Text("Raça Predominante: ${pet.identificacao.racaPredominante}"),
            pw.Text("Porte: ${pet.identificacao.porteEstimado}"),
            pw.Text("Expectativa de Vida: ${pet.identificacao.expectativaVidaMedia}"),
            pw.SizedBox(height: 15),


            pw.Text("Dica Especialista", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Text(pet.dica.insightExclusivo.replaceAll('veterinário', 'Vet').replaceAll('Veterinário', 'Vet').replaceAll('aproximadamente', '+-').replaceAll('Aproximadamente', '+-')),
            
            pw.SizedBox(height: 15),

            // Growth Curve
            if (pet.identificacao.curvaCrescimento.isNotEmpty) ...[
              pw.Text("Curva de Crescimento Estimada", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Bullet(text: "3 Meses: ${pet.identificacao.curvaCrescimento['peso_3_meses'] ?? 'N/A'}"),
              pw.Bullet(text: "6 Meses: ${pet.identificacao.curvaCrescimento['peso_6_meses'] ?? 'N/A'}"),
              pw.Bullet(text: "12 Meses: ${pet.identificacao.curvaCrescimento['peso_12_meses'] ?? 'N/A'}"),
              pw.Bullet(text: "Adulto: ${pet.identificacao.curvaCrescimento['peso_adulto'] ?? 'N/A'}"),
              pw.SizedBox(height: 15),
            ],

            pw.Text("Nutrição Detalhada", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Bullet(text: "Meta Filhote: ${(pet.nutricao.metaCalorica['kcal_filhote'] ?? 'N/A').replaceAll('aproximadamente', '+-')}"),
            pw.Bullet(text: "Meta Adulto: ${(pet.nutricao.metaCalorica['kcal_adulto'] ?? 'N/A').replaceAll('aproximadamente', '+-')}"),
            pw.Bullet(text: "Meta Sênior: ${(pet.nutricao.metaCalorica['kcal_senior'] ?? 'N/A').replaceAll('aproximadamente', '+-')}"),
            pw.SizedBox(height: 5),
            pw.Text("Nutrientes Alvo: ${pet.nutricao.nutrientesAlvo.join(', ')}"),
            pw.Text("Suplementação: ${pet.nutricao.suplementacaoSugerida.join(', ')}"),
            pw.SizedBox(height: 15),

            pw.Text("Grooming & Higiene", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Text("Tipo de Pelo: ${pet.higiene.manutencaoPelagem['tipo_pelo'] ?? 'N/A'}"),
            pw.Text("Escovação: ${pet.higiene.manutencaoPelagem['frequencia_escovacao_semanal'] ?? 'N/A'}"),
            pw.Text("Banho: ${pet.higiene.banhoEHigiene['frequencia_ideal_banho'] ?? 'N/A'}"),
            if (pet.higiene.manutencaoPelagem['alerta_subpelo'] != null)
              pw.Text("ALERTA: ${pet.higiene.manutencaoPelagem['alerta_subpelo']}", style: const pw.TextStyle(color: PdfColors.red)),
            pw.SizedBox(height: 15),

            // Weekly Meal Plan
            if (pet.planoSemanal.isNotEmpty) ...[
              pw.Text("Cardápio Semanal (Dieta Natural)", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              if (pet.orientacoesGerais != null) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.orange50,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Text("💡 ${pet.orientacoesGerais}", style: const pw.TextStyle(fontSize: 11)),
                ),
                pw.SizedBox(height: 10),
              ],
              ...pet.planoSemanal.map((day) {
                final dia = day['dia'] ?? '';
                final refeicao = day['refeicao'] ?? '';
                final beneficio = day['beneficio'] ?? '';
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(dia, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                    pw.Bullet(text: refeicao),
                    pw.Text("   → $beneficio", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    pw.SizedBox(height: 8),
                  ],
                );
              }).toList(),
              pw.SizedBox(height: 15),
            ],

            pw.Text("Lifestyle & Educação", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Text("Nível de Energia: ${pet.perfilComportamental.nivelEnergia}/5"),
            pw.Text("Adestramento: ${pet.lifestyle.treinamento['dificuldade_adestramento'] ?? 'N/A'}"),
            pw.Text("Ambiente Ideal: ${pet.lifestyle.ambienteIdeal['necessidade_de_espaco_aberto'] ?? 'N/A'}"),
            
            pw.Footer(title: pw.Text("ScanNut App - Inteligência Animal", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey))),
          ];
        },
      ),
    );

    try {
      final pdfBytes = await pdf.save();
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/pet_dossier_${DateTime.now().millisecondsSinceEpoch}.pdf");
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
                    await Share.shareXFiles([XFile(file.path)], text: 'Dossiê Pet ScanNut - ${widget.analysis.raca}');
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
      debugPrint("Erro PDF: $e");
    }
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    } else {
      // Also update when animation finishes to ensure sync
      setState(() {}); 
    }
  }

  Widget _buildTabContent(ScrollController sc) {
    switch (_tabController.index) {
      case 0: return _buildIdentidadeTab(sc);
      case 1: return _buildNutricaoTab(sc);
      case 2: return _buildGroomingTab(sc);
      case 3: return _buildSaudeTab(sc);
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
                   _buildHeader(),
                   if (widget.analysis.analysisType == 'diagnosis') 
                     Expanded(child: _buildDiagnosisContent(scrollController))
                   else ...[
                     _buildTabBar(),
                     Expanded(
                       child: _buildTabContent(scrollController),
                     ),
                   ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.petName ?? widget.analysis.raca,
                      style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.petName != null ? widget.analysis.raca : widget.analysis.especie,
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.white54),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isEmergency) 
                    IconButton(onPressed: () => launchUrl(Uri.parse('geo:0,0?q=veterinario+24h')), icon: const Icon(Icons.phone, color: Colors.redAccent)),
                  IconButton(onPressed: _generatePDF, icon: const Icon(Icons.picture_as_pdf, color: Colors.orangeAccent)),
                  IconButton(
                    onPressed: () {
                      if (!_isSaved) {
                        setState(() => _isSaved = true);
                        widget.onSave();
                      }
                    }, 
                    icon: Icon(_isSaved ? Icons.check : Icons.save, color: _themeColor)
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Future<void> _showAttachmentOptions() async {
    final service = FileUploadService();
    
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anexar Documento Médico',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF00E676)),
              title: Text('Tirar Foto de Receita/Exame', style: GoogleFonts.poppins(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final file = await service.pickFromCamera();
                if (file != null && widget.petName != null) {
                  await service.saveMedicalDocument(
                    file: file,
                    petName: widget.petName!,
                    attachmentType: 'foto',
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Documento salvo! Processando...')),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blueAccent),
              title: Text('Escolher da Galeria', style: GoogleFonts.poppins(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final file = await service.pickFromGallery();
                if (file != null && widget.petName != null) {
                  await service.saveMedicalDocument(
                    file: file,
                    petName: widget.petName!,
                    attachmentType: 'galeria',
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Documento salvo! Processando...')),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
              title: Text('Selecionar PDF', style: GoogleFonts.poppins(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final file = await service.pickPdfFile();
                if (file != null && widget.petName != null) {
                  await service.saveMedicalDocument(
                    file: file,
                    petName: widget.petName!,
                    attachmentType: 'pdf',
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Documento salvo! Processando...')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10))),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: _themeColor,
        labelColor: _themeColor,
        unselectedLabelColor: Colors.white54,
        tabs: const [
          Tab(text: "IDENTIDADE"),
          Tab(text: "NUTRIÇÃO"),
          Tab(text: "GROOMING"),
          Tab(text: "SAÚDE"),
          Tab(text: "LIFESTYLE"),
        ],
      ),
    );
  }

  Widget _buildDiagnosisContent(ScrollController sc) {
    return ListView(
      controller: sc,
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: _urgencyColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16), border: Border.all(color: _urgencyColor)),
          child: Row(
            children: [
              Icon(_isEmergency ? Icons.warning : Icons.info, color: _urgencyColor),
              const SizedBox(width: 12),
              Expanded(child: Text(widget.analysis.urgenciaNivel, style: GoogleFonts.poppins(color: _urgencyColor, fontWeight: FontWeight.bold))),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionCard(title: "Descrição Visual", icon: Icons.visibility, color: Colors.blueAccent, child: Text(widget.analysis.descricaoVisual.replaceAll('veterinário', 'Vet').replaceAll('Veterinário', 'Vet').replaceAll('aproximadamente', '+-').replaceAll('Aproximadamente', '+-'), style: const TextStyle(color: Colors.white70))),
        const SizedBox(height: 16),
        _buildSectionCard(title: "Causas Prováveis", icon: Icons.list, color: Colors.purpleAccent, child: Text(widget.analysis.possiveisCausas.join('\n• '), style: const TextStyle(color: Colors.white70))),
        const SizedBox(height: 16),
        _buildSectionCard(title: "Orientação do Especialista", icon: Icons.medical_services, color: Colors.tealAccent, child: Text(widget.analysis.orientacaoImediata.replaceAll('veterinário', 'Vet').replaceAll('Veterinário', 'Vet').replaceAll('aproximadamente', '+-').replaceAll('Aproximadamente', '+-'), style: const TextStyle(color: Colors.white))),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildIdentidadeTab(ScrollController sc) {
    final id = widget.analysis.identificacao;
    final pc = widget.analysis.perfilComportamental;
    return ListView(
      controller: sc,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      children: [
        if (widget.imagePath.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(
                File(widget.imagePath),
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 250,
                  width: double.infinity,
                  color: Colors.grey[900],
                  child: const Center(child: Icon(Icons.pets, size: 50, color: Colors.white24)),
                ),
              ),
            ),
          ),
        _buildSectionCard(
          title: "Análise Biométrica",
          icon: Icons.fingerprint,
          color: Colors.blueAccent,
          child: Column(
            children: [
              _buildInfoRow("Linhagem:", id.linhagemSrdProvavel),
              _buildInfoRow("Porte:", id.porteEstimado),
              _buildInfoRow("Longevidade:", id.expectativaVidaMedia),
            ],
          ),
        ),
        if (id.curvaCrescimento.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildSectionCard(
            title: "Curva de Crescimento Estimada",
            icon: Icons.show_chart,
            color: Colors.cyanAccent,
            child: Column(
              children: [
                _buildInfoRow("3 Meses:", id.curvaCrescimento['peso_3_meses'] ?? 'N/A'),
                _buildInfoRow("6 Meses:", id.curvaCrescimento['peso_6_meses'] ?? 'N/A'),
                _buildInfoRow("12 Meses:", id.curvaCrescimento['peso_12_meses'] ?? 'N/A'),
                _buildInfoRow("Adulto:", id.curvaCrescimento['peso_adulto'] ?? 'N/A'),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        _buildStatLine("Energia", pc.nivelEnergia / 5.0, Colors.orange),
        _buildStatLine("Inteligência", pc.nivelInteligencia / 5.0, Colors.purpleAccent),
        _buildStatLine("Sociabilidade", pc.sociabilidadeGeral / 5.0, Colors.greenAccent),
        _buildInfoLabel("Drive Ancestral:", pc.driveAncestral),
        const SizedBox(height: 24),
        _buildInsightCard(widget.analysis.dica.insightExclusivo),
      ],
    );
  }

  Widget _buildNutricaoTab(ScrollController sc) {
    final nut = widget.analysis.nutricao;
    return ListView(
      controller: sc,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      children: [
        if (widget.analysis.tabelaBenigna.isNotEmpty || widget.analysis.tabelaMaligna.isNotEmpty) ...[
          RaceNutritionTables(
            benigna: widget.analysis.tabelaBenigna,
            maligna: widget.analysis.tabelaMaligna,
            raceName: widget.analysis.raca,
          ),
          const SizedBox(height: 16),
        ],
        _buildSectionCard(
          title: "Meta Calórica: Filhote",
          icon: Icons.child_care,
          color: Colors.pinkAccent,
          child: _buildInfoRow("Kcal/Dia:", nut.metaCalorica['kcal_filhote'] ?? 'N/A'),
        ),
        const SizedBox(height: 12),
        _buildSectionCard(
          title: "Meta Calórica: Adulto",
          icon: Icons.pets,
          color: Colors.orange,
          child: _buildInfoRow("Kcal/Dia:", nut.metaCalorica['kcal_adulto'] ?? 'N/A'),
        ),
        const SizedBox(height: 12),
        _buildSectionCard(
          title: "Meta Calórica: Sênior",
          icon: Icons.access_time_filled,
          color: Colors.blueGrey,
          child: _buildInfoRow("Kcal/Dia:", nut.metaCalorica['kcal_senior'] ?? 'N/A'),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: "Segurança & Suplementos",
          icon: Icons.medication_liquid,
          color: Colors.greenAccent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoLabel("Nutrientes Alvo:", nut.nutrientesAlvo.join(', ')),
              _buildInfoLabel("Suplementação:", nut.suplementacaoSugerida.join(', ')),
              _buildToggleInfo("Tendência Obesidade", nut.segurancaAlimentar['tendencia_obesidade'] == true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGroomingTab(ScrollController sc) {
    final groo = widget.analysis.higiene;
    return ListView(controller: sc, padding: const EdgeInsets.fromLTRB(24, 24, 24, 100), children: [
        _buildSectionCard(title: "Pelagem & Tosa", icon: Icons.brush, color: Colors.amber, child: Column(children: [
              _buildInfoRow("Tipo:", groo.manutencaoPelagem['tipo_pelo'] ?? 'N/A'),
              _buildInfoRow("Frequência:", groo.manutencaoPelagem['frequencia_escovacao_semanal'] ?? 'N/A'),
              if (groo.manutencaoPelagem['alerta_subpelo'] != null) ...[
                const SizedBox(height: 8),
                Text(groo.manutencaoPelagem['alerta_subpelo'], style: const TextStyle(color: Colors.cyanAccent, fontSize: 11)),
              ]
        ])),
    ]);
  }

  Widget _buildSaudeTab(ScrollController sc) {
    final sau = widget.analysis.saude;
    return ListView(controller: sc, padding: const EdgeInsets.fromLTRB(24, 24, 24, 100), children: [
        _buildSectionCard(title: "Saúde Preventiva", icon: Icons.health_and_safety, color: Colors.redAccent, child: Column(children: [
              _buildInfoLabel("Predisposição:", sau.predisposicaoDoencas.join(', ')),
              _buildInfoLabel("Checkup:", (sau.checkupVeterinario['exames_obrigatorios_anuais'] as List? ?? []).join(', ')),
        ])),
        
        // Vaccination Protocol Card
        if (widget.analysis.protocoloImunizacao != null)
          VaccineCard(
            vaccinationProtocol: widget.analysis.protocoloImunizacao!,
            petName: widget.petName ?? 'Pet',
          ),
    ]);
  }

  Widget _buildLifestyleTab(ScrollController sc) {
    final life = widget.analysis.lifestyle;
    return ListView(controller: sc, padding: const EdgeInsets.fromLTRB(24, 24, 24, 100), children: [
        _buildSectionCard(title: "Treino & Ambiente", icon: Icons.psychology, color: Colors.purpleAccent, child: Column(children: [
              _buildInfoRow("Treino:", life.treinamento['dificuldade_adestramento'] ?? 'N/A'),
              _buildStatLine("Apartamento", (life.ambienteIdeal['adaptacao_apartamento_score'] ?? 3) / 5.0, Colors.cyan),
        ])),
    ]);
  }

  // --- HELPERS ---

  Widget _buildSectionCard({required String title, required IconData icon, required Color color, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, color: color, size: 18), const SizedBox(width: 10), Expanded(child: Text(title, style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis))]),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }

  Widget _buildInfoRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 4), 
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)), 
        const SizedBox(width: 8),
        Expanded(child: Text(value.replaceAll('aproximadamente', '+-').replaceAll('Aproximadamente', '+-').replaceAll('veterinário', 'Vet').replaceAll('Veterinário', 'Vet'), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.right))
      ]
    )
  );

  Widget _buildStatLine(String label, double percent, Color color) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)), const SizedBox(height: 4), LinearPercentIndicator(lineHeight: 6, percent: percent.clamp(0.0, 1.0), progressColor: color, backgroundColor: Colors.white10, barRadius: const Radius.circular(3), padding: EdgeInsets.zero, animation: true), const SizedBox(height: 12)]);


  Widget _buildInfoLabel(String label, String value) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white54, fontSize: 11)), Text(value.replaceAll('aproximadamente', '+-').replaceAll('Aproximadamente', '+-').replaceAll('veterinário', 'Vet').replaceAll('Veterinário', 'Vet'), style: const TextStyle(color: Colors.white, fontSize: 13))]));

  Widget _buildToggleInfo(String label, bool value) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis)), Icon(value ? Icons.report_problem : Icons.check_circle, color: value ? Colors.redAccent : Colors.greenAccent, size: 16)]);

  Widget _buildInsightCard(String insight) => Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.purple.withOpacity(0.2), Colors.blue.withOpacity(0.2)]), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("💡 INSIGHT EXCLUSIVO", style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 12)), const SizedBox(height: 8), Text(insight, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontStyle: FontStyle.italic))]));
}
