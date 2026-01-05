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
import 'package:intl/intl.dart';
import 'package:scannut/l10n/app_localizations.dart';
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
import '../../../../core/widgets/pdf_preview_screen.dart';
import '../../models/pet_profile_extended.dart';
import '../../services/pet_profile_service.dart';
import '../../../../core/widgets/app_pdf_icon.dart';
import '../../../../core/widgets/pdf_action_button.dart';

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
          backgroundColor: Colors.blueGrey.shade900.withOpacity(0.9),
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
  
  String get _localizedRaca {
    final raca = widget.analysis.raca;
    if (raca.toLowerCase() == 'vira-lata' || raca.toLowerCase() == 'srd' || raca.toLowerCase().contains('sem raça')) {
       return AppLocalizations.of(context)!.breedMixed;
    }
    return raca;
  }

  // Helper to translate raw DB values to current Locale
  String _bestEffortTranslate(String value) {
    // Estimation Marker Detection
    bool isEstimated = value.contains('[ESTIMATED]');
    String cleanValue = value.replaceAll('[ESTIMATED]', '').trim();

    if (cleanValue.toLowerCase() == 'n/a' || cleanValue.toLowerCase() == 'não informado' || cleanValue.toLowerCase() == 'sem dados') {
      return AppLocalizations.of(context)!.petNotOffice; 
    }
    
    // Activity Level
    String result = cleanValue;
    if (cleanValue.toLowerCase().contains('moderad') || cleanValue.toLowerCase().contains('medium')) result = AppLocalizations.of(context)!.petActivityModerate;
    else if (cleanValue.toLowerCase().contains('alt') || cleanValue.toLowerCase().contains('high')) result = AppLocalizations.of(context)!.petActivityHigh;
    else if (cleanValue.toLowerCase().contains('baix') || cleanValue.toLowerCase().contains('low')) result = AppLocalizations.of(context)!.petActivityLow;
    
    // Reproductive Status
    else if (cleanValue.toLowerCase().contains('castrado') || cleanValue.toLowerCase().contains('neutered')) result = AppLocalizations.of(context)!.petNeutered;
    else if (cleanValue.toLowerCase().contains('intact') || cleanValue.toLowerCase().contains('inteiro')) result = AppLocalizations.of(context)!.petIntact;
    
    // Bath Frequency
    else if (cleanValue.toLowerCase().contains('quinzenal') || cleanValue.toLowerCase().contains('biweekly')) result = AppLocalizations.of(context)!.petBathBiweekly;
    else if (cleanValue.toLowerCase().contains('semanal') || cleanValue.toLowerCase().contains('weekly')) result = AppLocalizations.of(context)!.petBathWeekly;
    else if (cleanValue.toLowerCase().contains('mensal') || cleanValue.toLowerCase().contains('monthly')) result = AppLocalizations.of(context)!.petBathMonthly;

    // Filters for Partners
    else if (cleanValue.toLowerCase() == 'todos' || cleanValue.toLowerCase() == 'all') result = AppLocalizations.of(context)!.partnersFilterAll;

    if (isEstimated) {
      return "$result ✨"; // Sparkle icon to indicate AI/Breed estimation
    }
    return result;
  }

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
    final l10n = AppLocalizations.of(context)!;
    final dateStr = DateFormat.yMd(l10n.localeName).add_Hm().format(now);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context pdfContext) {
          final pet = widget.analysis;
          if (pet.analysisType == 'diagnosis') {
             return [
               pw.Header(level: 0, child: pw.Text("ScanNut - ${l10n.pdfDiagnosisTriage}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 24, color: PdfColors.red))),
               pw.SizedBox(height: 10),
               if (image != null) pw.Center(child: pw.Image(image, height: 200)),
               pw.SizedBox(height: 20),
               pw.Text("${l10n.pdfFieldBreedSpecies}: ${pet.especie} - ${pet.raca}"),
               pw.Row(
                 children: [
                   pw.Text("${l10n.pdfFieldUrgency}: ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                   pw.Text(pet.urgenciaNivel, style: pw.TextStyle(
                     color: pet.urgenciaNivel.toLowerCase().contains('vermelho') || 
                            pet.urgenciaNivel.toLowerCase().contains('red') || 
                            pet.urgenciaNivel.toLowerCase().contains('rojo') ? PdfColors.red : PdfColors.black,
                     fontWeight: pw.FontWeight.bold,
                   )),
                 ],
               ),
               pw.Text("${l10n.petVisualDescription}: ${pet.descricaoVisual}"),
               pw.SizedBox(height: 5),
               pw.Text("${l10n.pdfFieldProfessionalRecommendation}:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
               pw.Text(pet.orientacaoImediata.replaceAll('veterinário', 'Vet').replaceAll('Veterinário', 'Vet').replaceAll('aproximadamente', '+-').replaceAll('Aproximadamente', '+-')),
               pw.Footer(title: pw.Text(l10n.pdfGeneratedBy(dateStr, "ScanNut"), style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey))),
             ];
          }
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("ScanNut", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 24, color: PdfColors.green)),
                  pw.Text(l10n.pdfDossierTitle, style: pw.TextStyle(fontSize: 18)),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(l10n.pdfGeneratedBy(dateStr, "ScanNut"), style: const pw.TextStyle(color: PdfColors.grey)),
            pw.SizedBox(height: 10),
            // Pet Name - Always visible
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text(
                "🐾 ${widget.petName ?? l10n.petNotIdentified}",
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
            
            // === SEÇÃO 1: IDENTIDADE E PERFIL ===
            pw.Text(l10n.pdfSectionIdentity, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            pw.Divider(color: PdfColors.blue900),
            pw.Text("${l10n.pdfFieldPredominantBreed}: ${pet.identificacao.racaPredominante}"),
            pw.Text("${l10n.petLineage}: ${pet.identificacao.linhagemSrdProvavel}"),
            pw.Text("${l10n.petSize}: ${pet.identificacao.porteEstimado}"),
            pw.Text("${l10n.petLongevity}: ${pet.identificacao.expectativaVidaMedia}"),
            pw.SizedBox(height: 10),

            // Perfil Comportamental
            pw.Text("${l10n.pdfFieldBehavioralProfile}:", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Bullet(text: "${l10n.pdfFieldEnergyLevel}: ${pet.perfilComportamental.nivelEnergia}/5"),
            pw.Bullet(text: "${l10n.pdfFieldIntelligence}: ${pet.perfilComportamental.nivelInteligencia}/5"),
            pw.Bullet(text: "${l10n.pdfFieldSociability}: ${pet.perfilComportamental.sociabilidadeGeral}/5"),
            pw.Bullet(text: "${l10n.pdfFieldAncestralDrive}: ${pet.perfilComportamental.driveAncestral}"),
            pw.SizedBox(height: 15),

            // Growth Curve
            if (pet.identificacao.curvaCrescimento.isNotEmpty) ...[
              pw.Text("${l10n.pdfFieldEstimatedGrowthCurve}:", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Bullet(text: "${l10n.petMonth3}: ${pet.identificacao.curvaCrescimento['peso_3_meses'] ?? 'N/A'}"),
              pw.Bullet(text: "${l10n.petMonth6}: ${pet.identificacao.curvaCrescimento['peso_6_meses'] ?? 'N/A'}"),
              pw.Bullet(text: "${l10n.petMonth12}: ${pet.identificacao.curvaCrescimento['peso_12_meses'] ?? 'N/A'}"),
              pw.Bullet(text: "${l10n.petAdult}: ${pet.identificacao.curvaCrescimento['peso_adulto'] ?? 'N/A'}"),
              pw.SizedBox(height: 15),
            ],

            // === SEÇÃO 2: NUTRIÇÃO E DIETA ===
            pw.Text(l10n.pdfSectionNutrition, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900)),
            pw.Divider(color: PdfColors.orange900),
            
            // Metas Calóricas
            pw.Text("${l10n.pdfFieldDailyCaloricGoals}:", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Bullet(text: "${l10n.pdfFieldPuppy}: ${(pet.nutricao.metaCalorica['kcal_filhote'] ?? 'N/A').replaceAll('aproximadamente', '+-')}"),
            pw.Bullet(text: "${l10n.pdfFieldAdult}: ${(pet.nutricao.metaCalorica['kcal_adulto'] ?? 'N/A').replaceAll('aproximadamente', '+-')}"),
            pw.Bullet(text: "${l10n.pdfFieldSenior}: ${(pet.nutricao.metaCalorica['kcal_senior'] ?? 'N/A').replaceAll('aproximadamente', '+-')}"),
            pw.SizedBox(height: 10),
            
            pw.Text("${l10n.pdfFieldTargetNutrients}: ${pet.nutricao.nutrientesAlvo.join(', ')}"),
            pw.Text("${l10n.pdfFieldSuggestedSupplementation}: ${pet.nutricao.suplementacaoSugerida.join(', ')}"),
            pw.SizedBox(height: 10),

            // Segurança Alimentar
            pw.Text("${l10n.pdfFieldFoodSafety}:", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            if (pet.nutricao.segurancaAlimentar['tendencia_obesidade'] == true)
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.red50,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(l10n.pdfAlertObesity, style: const pw.TextStyle(color: PdfColors.red900)),
              ),
            pw.SizedBox(height: 15),

            // Tabelas de Alimentos
            if (pet.tabelaBenigna.isNotEmpty) ...[
              pw.Text("${l10n.pdfFieldSafeFoods}:", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
              pw.Table.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.green100),
                data: [
                  [l10n.pdfFieldFoodName, l10n.pdfFieldBenefit],
                  ...pet.tabelaBenigna.map((row) => [row['alimento'] ?? '', row['beneficio'] ?? '']),
                ],
              ),
              pw.SizedBox(height: 10),
            ],

            if (pet.tabelaMaligna.isNotEmpty) ...[
              pw.Text("${l10n.pdfFieldToxicFoods}:", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
              pw.Table.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.red100),
                data: [
                  [l10n.pdfFieldFoodName, l10n.pdfFieldRisk],
                  ...pet.tabelaMaligna.map((row) => [row['alimento'] ?? '', row['risco'] ?? '']),
                ],
              ),
              pw.SizedBox(height: 15),
            ],

            // Weekly Meal Plan
            if (pet.planoSemanal.isNotEmpty) ...[
              pw.Text("${l10n.pdfFieldWeeklyMenu}:", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
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
              ...pet.planoSemanal.asMap().entries.map((entry) {
                final index = entry.key;
                final day = entry.value;
                
                final now = DateTime.now();
                final mondayStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
                final dateForDay = mondayStart.add(Duration(days: index));
                final dateStr = DateFormat('dd/MM', Localizations.localeOf(context).toString()).format(dateForDay);
                final weekDayName = DateFormat('EEEE', Localizations.localeOf(context).toString()).format(dateForDay); 
                final weekDayCap = weekDayName[0].toUpperCase() + weekDayName.substring(1);
                final String dia = "$weekDayCap - $dateStr";

                final String refeicao = (day['refeicao'] ?? '').toString();
                final String beneficio = (day['beneficio'] ?? '').toString();
                final String dailyKcal = pet.nutricao.metaCalorica['kcal_adulto'] ?? pet.nutricao.metaCalorica['kcal_filhote'] ?? pet.nutricao.metaCalorica['kcal_senior'] ?? 'N/A';
                
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(dia, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.blue800)),
                        pw.RichText(text: pw.TextSpan(children: [
                             pw.TextSpan(text: 'Meta: ', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                             pw.TextSpan(text: dailyKcal, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
                        ])),
                      ],
                    ),
                    pw.Bullet(text: refeicao, style: const pw.TextStyle(fontSize: 10)),
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 15),
                      child: pw.Text("↳ ${l10n.pdfFieldReason}: $beneficio", style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700, fontStyle: pw.FontStyle.italic)),
                    ),
                    pw.SizedBox(height: 10),
                  ],
                );
              }).toList(),
              pw.SizedBox(height: 15),
            ],

            // === SEÇÃO 3: GROOMING E HIGIENE ===
            pw.Text(l10n.pdfSectionGrooming, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.amber900)),
            pw.Divider(color: PdfColors.amber900),
            pw.Text("${l10n.pdfFieldCoatType}: ${pet.higiene.manutencaoPelagem['tipo_pelo'] ?? 'N/A'}"),
            pw.Text("${l10n.pdfFieldBrushingFrequency}: ${pet.higiene.manutencaoPelagem['frequencia_escovacao_semanal'] ?? 'N/A'}"),
            pw.Text("${l10n.pdfFieldBathFrequency}: ${pet.higiene.banhoEHigiene['frequencia_ideal_banho'] ?? 'N/A'}"),
            pw.Text("${l10n.pdfFieldRecommendedProducts}: ${pet.higiene.banhoEHigiene['produtos_recomendados'] ?? 'N/A'}"),
            if (pet.higiene.manutencaoPelagem['alerta_subpelo'] != null)
              pw.Container(
                margin: const pw.EdgeInsets.only(top: 8),
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.cyan50,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text("⚠️ ${pet.higiene.manutencaoPelagem['alerta_subpelo']}", style: const pw.TextStyle(color: PdfColors.cyan900)),
              ),
            pw.SizedBox(height: 15),

            // === SEÇÃO 4: SAÚDE PREVENTIVA ===
            pw.Text(l10n.pdfSectionHealth, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
            pw.Divider(color: PdfColors.red900),
            
            pw.Text("${l10n.pdfFieldDiseasePredisposition}:", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            if (pet.saude.predisposicaoDoencas.isNotEmpty)
              ...pet.saude.predisposicaoDoencas.map((d) => pw.Bullet(text: d))
            else
              pw.Text("• ${l10n.petNotIdentifiedPlural}", style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 10),

            pw.Text("${l10n.pdfFieldAnatomicalCriticalPoints}:", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            if (pet.saude.pontosCriticosAnatomicos.isNotEmpty)
              ...pet.saude.pontosCriticosAnatomicos.map((p) => pw.Bullet(text: p))
            else
              pw.Text("• ${l10n.petNotIdentified}", style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 10),

            pw.Text("${l10n.pdfFieldVeterinaryCheckup}:", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Bullet(text: "${l10n.petFrequency}: ${pet.saude.checkupVeterinario['frequencia_ideal'] ?? 'Anual'}"),
            if (pet.saude.checkupVeterinario['exames_obrigatorios_anuais'] != null)
              pw.Bullet(text: "${l10n.pdfFieldMandatoryExams}: ${(pet.saude.checkupVeterinario['exames_obrigatorios_anuais'] as List).join(', ')}"),
            pw.SizedBox(height: 10),

            pw.Text("${l10n.pdfFieldClimateSensitivity}:", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Bullet(text: "${l10n.pdfFieldHeat}: ${pet.saude.sensibilidadeClimatica['tolerancia_calor'] ?? 'N/A'}"),
            pw.Bullet(text: "${l10n.pdfFieldCold}: ${pet.saude.sensibilidadeClimatica['tolerancia_frio'] ?? 'N/A'}"),
            pw.SizedBox(height: 15),

            // Protocolo de Imunização
            if (pet.protocoloImunizacao != null) ...[
              pw.Text(l10n.pdfSectionImmunization, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
              pw.SizedBox(height: 8),
              
              // Vacinas Essenciais
              if (pet.protocoloImunizacao!['vacinas_essenciais'] != null) ...[
                pw.Text("${l10n.pdfFieldEssentialVaccines}:", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ...((pet.protocoloImunizacao!['vacinas_essenciais'] as List?) ?? []).map((v) {
                  final nome = v['nome'] ?? 'Vacina';
                  final objetivo = v['objetivo'] ?? '';
                  final primeiraIdade = v['idade_primeira_dose'] ?? '';
                  final reforco = v['reforco_adulto'] ?? '';
                  
                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 6),
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue50,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("• $nome", style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        if (objetivo.isNotEmpty)
                          pw.Text("  ${l10n.pdfFieldVaccineGoal}: $objetivo", style: const pw.TextStyle(fontSize: 9)),
                        if (primeiraIdade.isNotEmpty)
                          pw.Text("  ${l10n.pdfFieldFirstDose}: $primeiraIdade", style: const pw.TextStyle(fontSize: 9)),
                        if (reforco.isNotEmpty)
                          pw.Text("  ${l10n.pdfFieldBooster}: $reforco", style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                  );
                }),
                pw.SizedBox(height: 10),
              ],

              // Calendário Preventivo
              if (pet.protocoloImunizacao!['calendario_preventivo'] != null) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green50,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.green900),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Text("📅 ", style: const pw.TextStyle(fontSize: 12)),
                          pw.Text(l10n.pdfFieldPreventiveCalendar, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      if (pet.protocoloImunizacao!['calendario_preventivo']['cronograma_filhote'] != null)
                        pw.Bullet(text: "${l10n.pdfFieldPuppies}: ${pet.protocoloImunizacao!['calendario_preventivo']['cronograma_filhote']}", style: const pw.TextStyle(fontSize: 10)),
                      if (pet.protocoloImunizacao!['calendario_preventivo']['reforco_anual'] != null)
                        pw.Bullet(text: "${l10n.pdfFieldAdults}: ${pet.protocoloImunizacao!['calendario_preventivo']['reforco_anual']}", style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),
              ],

              // Prevenção Parasitária
              if (pet.protocoloImunizacao!['prevencao_parasitaria'] != null) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.orange50,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.orange900),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Text("🐛 ", style: const pw.TextStyle(fontSize: 12)),
                          pw.Text(l10n.pdfFieldParasitePrevention, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900)),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      if (pet.protocoloImunizacao!['prevencao_parasitaria']['vermifugacao'] != null)
                        pw.Builder(
                          builder: (context) {
                            final vermifugacao = pet.protocoloImunizacao!['prevencao_parasitaria']['vermifugacao'] as Map<String, dynamic>;
                            return pw.Bullet(text: "${l10n.pdfFieldDewormer}: ${vermifugacao['frequencia'] ?? l10n.petConsultVetCare}", style: const pw.TextStyle(fontSize: 10));
                          },
                        ),
                      if (pet.protocoloImunizacao!['prevencao_parasitaria']['controle_ectoparasitas'] != null)
                        pw.Builder(
                          builder: (context) {
                            final ecto = pet.protocoloImunizacao!['prevencao_parasitaria']['controle_ectoparasitas'] as Map<String, dynamic>;
                            return pw.Bullet(text: "${l10n.pdfFieldTickFlea}: ${ecto['pulgas_carrapatos'] ?? l10n.petConsultVetCare}", style: const pw.TextStyle(fontSize: 10));
                          },
                        ),
                      if (pet.protocoloImunizacao!['prevencao_parasitaria']['alerta_regional'] != null)
                        pw.Container(
                          margin: const pw.EdgeInsets.only(top: 6),
                          padding: const pw.EdgeInsets.all(6),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.red50,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text("⚠️ ${pet.protocoloImunizacao!['prevencao_parasitaria']['alerta_regional']}", style: const pw.TextStyle(fontSize: 9, color: PdfColors.red900)),
                        ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),
              ],

              // Saúde Bucal e Óssea
              if (pet.protocoloImunizacao!['saude_bucal_ossea'] != null) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.teal50,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.teal900),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Text("🦴 ", style: const pw.TextStyle(fontSize: 12)),
                          pw.Text(l10n.pdfFieldOralBoneHealth, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      if (pet.protocoloImunizacao!['saude_bucal_ossea']['ossos_naturais_permitidos'] != null)
                        pw.Builder(
                          builder: (context) {
                            final ossos = pet.protocoloImunizacao!['saude_bucal_ossea']['ossos_naturais_permitidos'] as List;
                            return pw.Bullet(text: "${l10n.pdfFieldPermittedBones}: ${ossos.join(', ')}", style: const pw.TextStyle(fontSize: 10));
                          },
                        ),
                      if (pet.protocoloImunizacao!['saude_bucal_ossea']['frequencia_semanal'] != null)
                        pw.Bullet(text: "${l10n.pdfFieldFrequency}: ${pet.protocoloImunizacao!['saude_bucal_ossea']['frequencia_semanal']}", style: const pw.TextStyle(fontSize: 10)),
                      if (pet.protocoloImunizacao!['saude_bucal_ossea']['alerta_seguranca'] != null)
                        pw.Container(
                          margin: const pw.EdgeInsets.only(top: 6),
                          padding: const pw.EdgeInsets.all(6),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.red50,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text("⚠️ ${pet.protocoloImunizacao!['saude_bucal_ossea']['alerta_seguranca']}", style: const pw.TextStyle(fontSize: 9, color: PdfColors.red900)),
                        ),
                    ],
                  ),
                ),
              ],
              
              pw.SizedBox(height: 15),
            ],

            // === SEÇÃO 5: LIFESTYLE E EDUCAÇÃO ===
            pw.Text(l10n.pdfSectionLifestyle, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.purple900)),
            pw.Divider(color: PdfColors.purple900),
            
            pw.Text("${l10n.pdfFieldTraining}:", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Bullet(text: "${l10n.pdfFieldTrainingDifficulty}: ${pet.lifestyle.treinamento['dificuldade_adestramento'] ?? 'N/A'}"),
            pw.Bullet(text: "${l10n.pdfFieldRecommendedMethods}: ${pet.lifestyle.treinamento['metodos_recomendados'] ?? l10n.petPositiveReinforcement}"),
            pw.SizedBox(height: 10),

            pw.Text("${l10n.pdfFieldIdealEnvironment}:", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Bullet(text: "${l10n.pdfFieldOpenSpace}: ${pet.lifestyle.ambienteIdeal['necessidade_de_espaco_aberto'] ?? 'N/A'}"),
            pw.Bullet(text: "${l10n.pdfFieldApartmentAdaptation}: ${pet.lifestyle.ambienteIdeal['adaptacao_apartamento_score'] ?? 'N/A'}/5"),
            pw.SizedBox(height: 10),

            pw.Text("${l10n.pdfFieldMentalStimulus}:", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Bullet(text: "${l10n.petFrequency}: ${pet.lifestyle.estimuloMental['necessidade_estimulo_mental'] ?? 'N/A'}"),
            pw.Bullet(text: "${l10n.pdfFieldSuggestedActivities}: ${pet.lifestyle.estimuloMental['atividades_sugeridas'] ?? l10n.petInteractiveToys}"),
            pw.SizedBox(height: 15),

            // === INSIGHT DO ESPECIALISTA ===
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.purple50,
                borderRadius: pw.BorderRadius.circular(10),
                border: pw.Border.all(color: PdfColors.purple900),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                   pw.Text("💡 ${l10n.pdfFieldExpertInsight}", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.purple900)),
                  pw.SizedBox(height: 6),
                  pw.Text(pet.dica.insightExclusivo.replaceAll('veterinário', 'Vet').replaceAll('Veterinário', 'Vet').replaceAll('aproximadamente', '+-').replaceAll('Aproximadamente', '+-'), style: const pw.TextStyle(fontSize: 11)),
                ],
              ),
            ),
            
            pw.Footer(
              title: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                   pw.Text("ScanNut App - Inteligência Animal", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                   pw.SizedBox(height: 4),
                   pw.Text(
                     l10n.pdfDisclaimer,
                     style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700, fontStyle: pw.FontStyle.italic),
                   ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    // OPEN PREVIEW SCREEN
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfPreviewScreen(
            title: "${l10n.pdfDossierTitle}: ${widget.petName ?? l10n.petNotIdentified}",
            buildPdf: (format) async => pdf.save(),
          ),
        ),
      );
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
          child: Container(
            color: const Color(0xFF121212),
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
                   // Disclaimer removed by user request

                ],
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
                      widget.petName ?? _localizedRaca,
                      style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.petName != null ? _localizedRaca : widget.analysis.especie,
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.white54),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PdfActionButton(onPressed: _generatePDF),
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
              leading: const AppPdfIcon(),
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
        tabs: [
          Tab(text: AppLocalizations.of(context)!.tabIdentity),
          Tab(text: AppLocalizations.of(context)!.tabNutrition),
          Tab(text: AppLocalizations.of(context)!.tabGrooming),
          Tab(text: AppLocalizations.of(context)!.tabHealth),
          Tab(text: AppLocalizations.of(context)!.tabLifestyle),
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
          decoration: BoxDecoration(color: _urgencyColor.withOpacity(0.2), borderRadius: BorderRadius.circular(16), border: Border.all(color: _urgencyColor)),
          child: Row(
            children: [
              Icon(_isEmergency ? Icons.warning : Icons.info, color: _urgencyColor),
              const SizedBox(width: 12),
              Expanded(child: Text(widget.analysis.urgenciaNivel, style: GoogleFonts.poppins(color: _urgencyColor, fontWeight: FontWeight.bold))),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionCard(title: AppLocalizations.of(context)!.petVisualDescription, icon: Icons.visibility, color: Colors.blueAccent, child: Text(widget.analysis.descricaoVisual.replaceAll('veterinário', 'Vet').replaceAll('Veterinário', 'Vet').replaceAll('aproximadamente', '+-').replaceAll('Aproximadamente', '+-'), style: const TextStyle(color: Colors.white70))),
        const SizedBox(height: 16),
        _buildSectionCard(title: AppLocalizations.of(context)!.petPossibleCauses, icon: Icons.list, color: Colors.purpleAccent, child: Text(widget.analysis.possiveisCausas.join('\n• '), style: const TextStyle(color: Colors.white70))),
        const SizedBox(height: 16),
        _buildSectionCard(title: AppLocalizations.of(context)!.petSpecialistOrientation, icon: Icons.medical_services, color: Colors.tealAccent, child: Text(widget.analysis.orientacaoImediata.replaceAll('veterinário', 'Vet').replaceAll('Veterinário', 'Vet').replaceAll('aproximadamente', '+-').replaceAll('Aproximadamente', '+-'), style: const TextStyle(color: Colors.white))),
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
          title: AppLocalizations.of(context)!.petBiometricAnalysis,
          icon: Icons.fingerprint,
          color: Colors.blueAccent,
          child: Column(
            children: [
              _buildInfoRow("${AppLocalizations.of(context)!.petLineage}:", _bestEffortTranslate(id.linhagemSrdProvavel)),
              _buildInfoRow("${AppLocalizations.of(context)!.petSize}:", _bestEffortTranslate(id.porteEstimado)),
              _buildInfoRow("${AppLocalizations.of(context)!.petLongevity}:", _bestEffortTranslate(id.expectativaVidaMedia)),
            ],
          ),
        ),
        if (id.curvaCrescimento.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildSectionCard(
            title: AppLocalizations.of(context)!.petGrowthCurve,
            icon: Icons.show_chart,
            color: Colors.cyanAccent,
            child: Column(
              children: [
                _buildInfoRow("${AppLocalizations.of(context)!.petMonth3}:", _bestEffortTranslate(id.curvaCrescimento['peso_3_meses'] ?? 'N/A')),
                _buildInfoRow("${AppLocalizations.of(context)!.petMonth6}:", _bestEffortTranslate(id.curvaCrescimento['peso_6_meses'] ?? 'N/A')),
                _buildInfoRow("${AppLocalizations.of(context)!.petMonth12}:", _bestEffortTranslate(id.curvaCrescimento['peso_12_meses'] ?? 'N/A')),
                _buildInfoRow("${AppLocalizations.of(context)!.petAdult}:", _bestEffortTranslate(id.curvaCrescimento['peso_adulto'] ?? 'N/A')),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        _buildStatLine(AppLocalizations.of(context)!.petEnergy, pc.nivelEnergia / 5.0, Colors.orange),
        _buildStatLine(AppLocalizations.of(context)!.petIntelligence, pc.nivelInteligencia / 5.0, Colors.purpleAccent),
        _buildStatLine(AppLocalizations.of(context)!.petSociability, pc.sociabilidadeGeral / 5.0, Colors.greenAccent),
        _buildInfoLabel("${AppLocalizations.of(context)!.petDrive}:", pc.driveAncestral),
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
        
        // NOVO: Cardápio Semanal Sugerido pela IA
        if (widget.analysis.planoSemanal.isNotEmpty) ...[
          _buildSectionCard(
            title: AppLocalizations.of(context)!.petSuggestedPlan,
            icon: Icons.calendar_today,
            color: Colors.lightBlueAccent,
            child: WeeklyMealPlanner(
              weeklyPlan: widget.analysis.planoSemanal.map((e) => Map<String, String>.from(
                e.map((key, value) => MapEntry(key, value.toString()))
              )).toList(),
              generalGuidelines: widget.analysis.orientacoesGerais,
              startDate: DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)), // Começamos na Segunda-feira desta semana
              dailyKcal: nut.metaCalorica['kcal_adulto'] ?? nut.metaCalorica['kcal_filhote'] ?? nut.metaCalorica['kcal_senior'],
            ),
          ),
          const SizedBox(height: 16),
        ],

        _buildSectionCard(
          title: AppLocalizations.of(context)!.petDailyCaloricGoals,
          icon: Icons.bolt,
          color: Colors.orangeAccent,
          child: Column(
            children: [
              _buildCaloricRow("${AppLocalizations.of(context)!.petPuppy}:", nut.metaCalorica['kcal_filhote'] ?? 'N/A', Colors.pinkAccent),
              const Divider(color: Colors.white10, height: 16),
              _buildCaloricRow("${AppLocalizations.of(context)!.petAdult}:", nut.metaCalorica['kcal_adulto'] ?? 'N/A', Colors.orange),
              const Divider(color: Colors.white10, height: 16),
              _buildCaloricRow("${AppLocalizations.of(context)!.petSenior}:", nut.metaCalorica['kcal_senior'] ?? 'N/A', Colors.blueGrey),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: AppLocalizations.of(context)!.petSecuritySupplements,
          icon: Icons.medication_liquid,
          color: Colors.greenAccent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoLabel("${AppLocalizations.of(context)!.petTargetNutrients}:", nut.nutrientesAlvo.join(', ')),
              _buildInfoLabel("${AppLocalizations.of(context)!.petSupplementation}:", nut.suplementacaoSugerida.join(', ')),
              _buildToggleInfo(AppLocalizations.of(context)!.petObesityTendency, nut.segurancaAlimentar['tendencia_obesidade'] == true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGroomingTab(ScrollController sc) {
    final groo = widget.analysis.higiene;
    return ListView(controller: sc, padding: const EdgeInsets.fromLTRB(24, 24, 24, 100), children: [
        _buildSectionCard(title: AppLocalizations.of(context)!.petCoatGrooming, icon: Icons.brush, color: Colors.amber, child: Column(children: [
              _buildInfoRow("${AppLocalizations.of(context)!.petType}:", _bestEffortTranslate(groo.manutencaoPelagem['tipo_pelo'] ?? 'N/A')),
              _buildInfoRow("${AppLocalizations.of(context)!.petFrequency}:", _bestEffortTranslate(groo.manutencaoPelagem['frequencia_escovacao_semanal'] ?? 'N/A')),
              if (groo.manutencaoPelagem['alerta_subpelo'] != null) ...[
                const SizedBox(height: 8),
                Text(_bestEffortTranslate(groo.manutencaoPelagem['alerta_subpelo']!), style: const TextStyle(color: Colors.cyanAccent, fontSize: 11)),
              ]
        ])),
    ]);
  }

  Widget _buildSaudeTab(ScrollController sc) {
    final sau = widget.analysis.saude;
    return ListView(controller: sc, padding: const EdgeInsets.fromLTRB(24, 24, 24, 100), children: [
        _buildSectionCard(title: AppLocalizations.of(context)!.petPreventiveHealth, icon: Icons.health_and_safety, color: Colors.redAccent, child: Column(children: [
              _buildInfoLabel("${AppLocalizations.of(context)!.petPredisposition}:", sau.predisposicaoDoencas.join(', ')),
              _buildInfoLabel("${AppLocalizations.of(context)!.petCheckup}:", (sau.checkupVeterinario['exames_obrigatorios_anuais'] as List? ?? []).join(', ')),
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
        _buildSectionCard(title: AppLocalizations.of(context)!.petTrainingEnvironment, icon: Icons.psychology, color: Colors.purpleAccent, child: Column(children: [
              _buildInfoRow("${AppLocalizations.of(context)!.petTraining}:", _bestEffortTranslate(life.treinamento['dificuldade_adestramento'] ?? 'N/A')),
              _buildStatLine(AppLocalizations.of(context)!.petApartmentRef, (life.ambienteIdeal['adaptacao_apartamento_score'] ?? 3) / 5.0, Colors.cyan),
        ])),
    ]);
  }

  // --- HELPERS ---

  Widget _buildSectionCard({required String title, required IconData icon, required Color color, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
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

  Widget _buildInsightCard(String insight) => Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.purple.withOpacity(0.2), Colors.blue.withOpacity(0.2)]), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("💡 ${AppLocalizations.of(context)!.petExclusiveInsight}", style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 12)), const SizedBox(height: 8), Text(insight, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontStyle: FontStyle.italic))]));
  Widget _buildCaloricRow(String label, String value, Color color) {
    final isEstimated = value.contains('[ESTIMATED]');
    final cleanValue = value
        .replaceAll('[ESTIMATED]', '')
        .replaceAll('aproximadamente', '+-')
        .replaceAll('Aproximadamente', '+-')
        .replaceAll('Kcal/dia', '')
        .replaceAll('kcal/dia', '')
        .replaceAll('Kcal', '')
        .replaceAll('kcal', '')
        .trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(isEstimated ? Icons.auto_awesome : Icons.label_important, color: color.withOpacity(0.5), size: 14),
          const SizedBox(width: 10),
          SizedBox(
            width: 85,
            child: Text(label, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  cleanValue, 
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right,
                ),
                if (isEstimated)
                  Text(
                    AppLocalizations.of(context)!.petEstimatedByBreed,
                    style: const TextStyle(color: Colors.white24, fontSize: 8),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 55,
            child: Text("Kcal/dia", style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11), textAlign: TextAlign.left),
          ),
        ],
      ),
    );
  }
}
