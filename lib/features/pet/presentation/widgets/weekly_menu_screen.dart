import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../../core/widgets/pdf_action_button.dart';

class WeeklyMenuScreen extends StatefulWidget {
  final List<Map<String, String>> currentWeekPlan;
  final String? generalGuidelines;
  final String petName;
  final String raceName;

    const WeeklyMenuScreen({Key? key, required this.currentWeekPlan, this.generalGuidelines, required this.petName, required this.raceName}) : super(key: key);

  @override
  State<WeeklyMenuScreen> createState() => _WeeklyMenuScreenState();
}

class _WeeklyMenuScreenState extends State<WeeklyMenuScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, String>> _nextWeekPlan = [];
  String? _nextWeekGuidelines;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cardápio de ${widget.petName}',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.raceName,
              style: GoogleFonts.poppins(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          PdfActionButton(
            onPressed: _generateMenuPDF,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00E676),
          labelColor: const Color(0xFF00E676),
          unselectedLabelColor: Colors.white54,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Semana Anterior'),
            Tab(text: 'Semana Atual'),
            Tab(text: 'Próxima Semana'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWeekView('previous'),
          _buildWeekView('current'),
          _buildWeekView('next'),
        ],
      ),
    );
  }

  Future<void> _generateMenuPDF() async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(now);

    // Calculate dates for each day of the week (starting from next Monday)
    final today = DateTime.now();
    final daysUntilMonday = (DateTime.monday - today.weekday + 7) % 7;
    final nextMonday = today.add(Duration(days: daysUntilMonday == 0 ? 7 : daysUntilMonday));

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
                  pw.Text(
                    'ScanNut',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 24,
                      color: PdfColors.green,
                    ),
                  ),
                  pw.Text(
                    'Cardápio Semanal',
                    style: pw.TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text('Gerado em: $dateStr', style: const pw.TextStyle(color: PdfColors.grey)),
            pw.SizedBox(height: 10),
            pw.Text(
              'Pet: ${widget.petName}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
            ),
            pw.Text(
              'Raça: ${widget.raceName}',
              style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 20),

            if (widget.generalGuidelines != null) ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.orange50,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('💡 ', style: const pw.TextStyle(fontSize: 14)),
                    pw.Expanded(
                      child: pw.Text(
                        widget.generalGuidelines!,
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
            ],

            pw.Text(
              'Plano Alimentar da Semana',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Divider(),
            pw.SizedBox(height: 10),

            ...widget.currentWeekPlan.asMap().entries.map((entry) {
              final index = entry.key;
              final day = entry.value;
              final dia = day['dia'] ?? 'Dia ${index + 1}';
              final refeicao = day['refeicao'] ?? '';
              final beneficio = day['beneficio'] ?? '';

              // Calculate the actual date for this day
              final dayDate = nextMonday.add(Duration(days: index));
              final formattedDate = DateFormat('EEEE, dd/MM/yyyy', 'pt_BR').format(dayDate);

              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 15),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          dia,
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        pw.Text(
                          formattedDate,
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    pw.Bullet(text: refeicao, style: const pw.TextStyle(fontSize: 12)),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      '   → $beneficio',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.Text(
              '⚠️ Lembre-se: Sempre cozinhar sem sal. Consulte um veterinário antes de mudanças alimentares.',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
            ),

            pw.Footer(
              title: pw.Text(
                'ScanNut App - Alimentação Natural para Pets',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ),
          ];
        },
      ),
    );

    try {
      final pdfBytes = await pdf.save();
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/cardapio_${widget.petName}_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(pdfBytes);

      if (mounted) {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.grey[900],
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.print, color: Colors.blueAccent),
                  title: const Text('Imprimir Cardápio', style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    Navigator.pop(context);
                    await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share, color: Colors.greenAccent),
                  title: const Text('Compartilhar PDF', style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    Navigator.pop(context);
                    await Share.shareXFiles(
                      [XFile(file.path)],
                      text: 'Cardápio Semanal - ${widget.petName}',
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.open_in_new, color: Colors.amberAccent),
                  title: const Text('Abrir no Visualizador', style: TextStyle(color: Colors.white)),
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
      debugPrint('Erro ao gerar PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildWeekView(String weekType) {
    if (weekType == 'current' && widget.currentWeekPlan.isEmpty) {
      return _buildEmptyState('Nenhum cardápio gerado ainda.');
    }

    if (weekType == 'previous') {
      return _buildEmptyState('Histórico da semana anterior não disponível.');
    }

    if (weekType == 'next') {
      // Show generated next week plan if available
      if (_nextWeekPlan.isNotEmpty) {
        return _buildWeekPlanView(_nextWeekPlan, _nextWeekGuidelines);
      }
      return _buildGenerateNextWeek();
    }

    return _buildWeekPlanView(widget.currentWeekPlan, widget.generalGuidelines);
  }

  Widget _buildWeekPlanView(List<Map<String, String>> weekPlan, String? guidelines) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (guidelines != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.tips_and_updates, color: Colors.orangeAccent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    guidelines,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        ...weekPlan.map((day) {
          final dia = day['dia'] ?? 'Dia';
          final refeicao = day['refeicao'] ?? '';
          final beneficio = day['beneficio'] ?? '';
          final initial = dia.isNotEmpty ? dia[0].toUpperCase() : '?';

          return Card(
            color: Colors.white.withValues(alpha: 0.05),
            elevation: 0,
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF00E676).withValues(alpha: 0.2),
                child: Text(
                  initial,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF00E676),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                dia,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    refeicao,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.star, color: Colors.amberAccent, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "Por que: $beneficio",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 80,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(
              color: Colors.white54,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateNextWeek() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 80,
            color: const Color(0xFF00E676).withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'Gerar Cardápio da Próxima Semana',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'O sistema irá criar um novo cardápio evitando os ingredientes da semana atual para garantir rotação nutricional.',
              style: GoogleFonts.poppins(
                color: Colors.white54,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              // Show loading dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E676)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Gerando novo cardápio...',
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              );

              try {
                // Get excluded ingredients from current week
                final currentIngredients = <String>{};
                for (var day in widget.currentWeekPlan) {
                  final meal = day['refeicao'] ?? '';
                  final parts = meal.split(RegExp(r'[,;e]'));
                  for (var part in parts) {
                    final cleaned = part.trim().toLowerCase();
                    if (cleaned.isNotEmpty) {
                      final firstWord = cleaned.split(' ').first;
                      if (firstWord.length > 3) currentIngredients.add(firstWord);
                    }
                  }
                }

                // Build prompt for new meal plan
                final exclusionText = currentIngredients.isEmpty
                    ? 'Nenhuma restrição.'
                    : 'EVITE os seguintes ingredientes usados recentemente: ${currentIngredients.join(", ")}.';

                final prompt = '''
Atue como Nutrólogo Pet especializado em Alimentação Natural (AN).
Gere um novo plano semanal de 7 dias para a raça: ${widget.raceName}.

$exclusionText

⚠️ REGRAS CRÍTICAS:
- É TERMINANTEMENTE PROIBIDO sugerir ração ou alimentos processados
- Use APENAS: Proteínas (carnes, ovos), Vísceras, Vegetais, Carboidratos saudáveis
- Varie os ingredientes para garantir rotação nutricional
- Cada refeição deve conter: Proteína + Víscera + Vegetal + Carboidrato

Responda APENAS em JSON (sem markdown):
{
  "plano_semanal": [
    {"dia": "Segunda-feira", "refeicao": "string", "beneficio": "string"},
    {"dia": "Terça-feira", "refeicao": "string", "beneficio": "string"},
    {"dia": "Quarta-feira", "refeicao": "string", "beneficio": "string"},
    {"dia": "Quinta-feira", "refeicao": "string", "beneficio": "string"},
    {"dia": "Sexta-feira", "refeicao": "string", "beneficio": "string"},
    {"dia": "Sábado", "refeicao": "string", "beneficio": "string"},
    {"dia": "Domingo", "refeicao": "string", "beneficio": "string"}
  ],
  "orientacoes_gerais": "string"
}
''';

                // Call Gemini
                final geminiService = GeminiService();
                final response = await geminiService.generateTextContent(prompt);

                // Close loading dialog
                if (mounted) Navigator.pop(context);

                // Validate response
                if (response['plano_semanal'] == null) {
                  throw Exception('Resposta inválida da IA');
                }

                // Show success and navigate back with new plan
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Novo cardápio gerado com sucesso! 🎉',
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: const Color(0xFF00E676),
                      duration: const Duration(seconds: 2),
                    ),
                  );

                  // Update state with new plan
                  final newPlan = response['plano_semanal'] as List;
                  final newGuidelines = response['orientacoes_gerais'] as String?;
                  
                  setState(() {
                    _nextWeekPlan = newPlan.map((day) => Map<String, String>.from(day as Map)).toList();
                    _nextWeekGuidelines = newGuidelines;
                  });

                  // Wait a bit for snackbar to show, then switch tab
                  await Future.delayed(const Duration(milliseconds: 500));
                  
                  // Stay on "Próxima Semana" tab to show the generated plan
                  // User can see it immediately
                }
              } catch (e) {
                // Close loading dialog
                if (mounted) Navigator.pop(context);
                
                // Show error
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Erro ao gerar cardápio: ${e.toString()}',
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.refresh, color: Colors.black),
            label: Text(
              'Gerar Novo Cardápio',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
