import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'dart:io';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_design.dart';
import 'package:scannut/l10n/app_localizations.dart';
import '../../models/pet_analysis_result.dart';
import '../../../../core/utils/color_helper.dart';
import '../../../../core/templates/race_nutrition_component.dart';
import '../../../../core/templates/weekly_meal_planner_component.dart';
import 'vaccine_card.dart';
import '../../../../core/services/file_upload_service.dart';
import '../../../../core/widgets/pdf_preview_screen.dart';
import '../../models/pet_profile_extended.dart';
import '../../../../core/widgets/app_pdf_icon.dart';
import '../../../../core/widgets/pdf_action_button.dart';

class PetResultCard extends StatefulWidget {
  final PetAnalysisResult analysis;
  final String imagePath;
  final VoidCallback onSave;
  final String? petName;
  final PetProfileExtended? petProfile; // 🛡️ Source of Truth

  const PetResultCard(
      {super.key,
      required this.analysis,
      required this.imagePath,
      required this.onSave,
      this.petName,
      this.petProfile});

  @override
  State<PetResultCard> createState() => _PetResultCardState();
}

class _PetResultCardState extends State<PetResultCard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSaved = false;
  final Color _themeColor = AppDesign.petPink;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    // Removed listener as we are switching to a unified scrollable list
    HapticFeedback.mediumImpact();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.analysis.analysisType == 'identification') {
        if (widget.analysis.higiene.manutencaoPelagem['alerta_subpelo'] !=
                null &&
            widget.analysis.higiene.manutencaoPelagem['alerta_subpelo']!
                .toString()
                .toLowerCase()
                .contains('importante')) {
          _showSpecialWarning("ALERTA DE PELAGEM",
              widget.analysis.higiene.manutencaoPelagem['alerta_subpelo']);
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
          backgroundColor: AppDesign.surfaceDark.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
              side: const BorderSide(color: AppDesign.info, width: 2)),
          title: Row(
            children: [
              const Icon(AppDesign.iconInfo, color: AppDesign.info, size: 32),
              const SizedBox(width: 12),
              Text(title,
                  style: GoogleFonts.poppins(
                      color: AppDesign.textPrimaryDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ],
          ),
          content: Text(
            message,
            style: GoogleFonts.poppins(
                color: AppDesign.textPrimaryDark, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.commonUnderstand,
                  style: GoogleFonts.poppins(
                      color: AppDesign.info, fontWeight: FontWeight.bold)),
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

  Color get _urgencyColor =>
      ColorHelper.getPetThemeColor(widget.analysis.urgenciaNivel);
  bool get _isEmergency {
    final level = widget.analysis.urgenciaNivel.toLowerCase();
    return level.contains('vermelho') ||
        level.contains('red') ||
        level.contains('rojo');
  }

  String get _localizedRaca {
    // 🛡️ Source of Truth: Use Profile if available
    final raca = widget.petProfile?.raca ?? widget.analysis.raca;

    if (raca.toLowerCase() == 'vira-lata' ||
        raca.toLowerCase() == 'srd' ||
        raca.toLowerCase().contains('sem raça') ||
        raca.toLowerCase() == 'unknown breed') {
      return AppLocalizations.of(context)!.petUnknownBreed;
    }
    return raca;
  }

  // Helper to translate raw DB values to current Locale
  String _bestEffortTranslate(String value) {
    // Estimation Marker Detection
    bool isEstimated = value.contains('[ESTIMATED]');
    String cleanValue = value.replaceAll('[ESTIMATED]', '').trim();

    if (cleanValue.toLowerCase() == 'n/a' ||
        cleanValue.toLowerCase() == 'não informado' ||
        cleanValue.toLowerCase() == 'sem dados') {
      return AppLocalizations.of(context)!.petNotOffice;
    }

    // Activity Level
    String result = cleanValue;
    if (cleanValue.toLowerCase().contains('moderad') ||
        cleanValue.toLowerCase().contains('medium')) {
      result = AppLocalizations.of(context)!.petActivityModerate;
    } else if (cleanValue.toLowerCase().contains('alt') ||
        cleanValue.toLowerCase().contains('high'))
      result = AppLocalizations.of(context)!.petActivityHigh;
    else if (cleanValue.toLowerCase().contains('baix') ||
        cleanValue.toLowerCase().contains('low'))
      result = AppLocalizations.of(context)!.petActivityLow;

    // Reproductive Status
    else if (cleanValue.toLowerCase().contains('castrado') ||
        cleanValue.toLowerCase().contains('neutered'))
      result = AppLocalizations.of(context)!.petNeutered;
    else if (cleanValue.toLowerCase().contains('intact') ||
        cleanValue.toLowerCase().contains('inteiro'))
      result = AppLocalizations.of(context)!.petIntact;

    // Bath Frequency
    else if (cleanValue.toLowerCase().contains('quinzenal') ||
        cleanValue.toLowerCase().contains('biweekly'))
      result = AppLocalizations.of(context)!.petBathBiweekly;
    else if (cleanValue.toLowerCase().contains('semanal') ||
        cleanValue.toLowerCase().contains('weekly'))
      result = AppLocalizations.of(context)!.petBathWeekly;
    else if (cleanValue.toLowerCase().contains('mensal') ||
        cleanValue.toLowerCase().contains('monthly'))
      result = AppLocalizations.of(context)!.petBathMonthly;

    // Filters for Partners
    else if (cleanValue.toLowerCase() == 'todos' ||
        cleanValue.toLowerCase() == 'all')
      result = AppLocalizations.of(context)!.partnersFilterAll;

    if (isEstimated) {
      return "$result ✨"; // Sparkle icon to indicate AI/Breed estimation
    }
    return result;
  }

  Future<void> _generatePDF() async {
    final pdf = pw.Document();

    // 1. Imagem Principal
    pw.MemoryImage? image;
    try {
      if (File(widget.imagePath).existsSync()) {
        final imageBytes = await File(widget.imagePath).readAsBytes();
        image = pw.MemoryImage(imageBytes);
      }
    } catch (e) {
      debugPrint("Erro carregar imagem PDF: $e");
    }

    // 2. Imagens do Histórico Unificado (Fix: Step 4513)
    // Carrega imagens de feridas/fezes para o relatório
    final Map<int, pw.MemoryImage> historicalImages = {};
    final history = widget.petProfile?.historicoAnaliseFeridas ?? [];

    for (int i = 0; i < history.length; i++) {
      final item = history[i];
      if (item.imagemRef.isNotEmpty) {
        final f = File(item.imagemRef);
        if (f.existsSync()) {
          try {
            final bytes = await f.readAsBytes();
            if (bytes.isNotEmpty) {
              historicalImages[i] = pw.MemoryImage(bytes);
            }
          } catch (e) {
            debugPrint('Erro carregar imagem histórico PDF $i: $e');
          }
        }
      }
    }

    final now = DateTime.now();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final dateStr = DateFormat.yMd(l10n.localeName).add_Hm().format(now);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context pdfContext) {
          final pet = widget.analysis;
          if (pet.analysisType == 'diagnosis') {
            return [
              pw.Header(
                  level: 0,
                  child: pw.Text("ScanNut ${l10n.pdfDiagnosisTriage}",
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 24,
                          color: PdfColors.red))),
              pw.SizedBox(height: 10),
              if (image != null) pw.Center(child: pw.Image(image, height: 200)),
              pw.SizedBox(height: 20),
              pw.Text(
                  "${l10n.pdfFieldBreedSpecies}: ${widget.petProfile?.especie ?? pet.especie} - ${widget.petProfile?.raca ?? pet.raca}"),
              pw.Row(
                children: [
                  pw.Text("${l10n.pdfFieldUrgency}: ",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(_translateStatus(pet.urgenciaNivel, l10n),
                      style: pw.TextStyle(
                        color: pet.urgenciaNivel
                                    .toLowerCase()
                                    .contains('vermelho') ||
                                pet.urgenciaNivel
                                    .toLowerCase()
                                    .contains('red') ||
                                pet.urgenciaNivel.toLowerCase().contains('rojo')
                            ? PdfColors.red
                            : PdfColors.black,
                        fontWeight: pw.FontWeight.bold,
                      )),
                ],
              ),
              pw.Text("${l10n.petVisualDescription}: ${pet.descricaoVisual}"),
              pw.SizedBox(height: 5),
              pw.Text("${l10n.pdfFieldProfessionalRecommendation}:",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(pet.orientacaoImediata
                  .replaceAll('veterinário', 'Vet')
                  .replaceAll('Veterinário', 'Vet')
                  .replaceAll('aproximadamente', '±')
                  .replaceAll('Aproximadamente', '±')),
              pw.Footer(
                  title: pw.Text(l10n.pdfGeneratedBy(dateStr, "ScanNut"),
                      style: const pw.TextStyle(
                          fontSize: 10, color: PdfColors.grey))),
            ];
          }
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("ScanNut",
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 24,
                          color: PdfColors.pink)),
                  pw.Text(l10n.pdfDossierTitle,
                      style: const pw.TextStyle(fontSize: 18)),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(l10n.pdfGeneratedBy(dateStr, "ScanNut"),
                style: const pw.TextStyle(color: PdfColors.grey)),
            pw.SizedBox(height: 10),
            // Pet Name - Always visible
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: pw.BoxDecoration(
                color: PdfColors.pink50,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text(
                l10n.vet360ReportTitle(widget.petName ?? l10n.petNotIdentified),
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 18,
                  color: PdfColors.pink900,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            if (image != null)
              pw.Center(
                  child: pw.Image(image, height: 200, fit: pw.BoxFit.contain)),
            pw.SizedBox(height: 20),

            // === SEÇÃO 1: IDENTIDADE E PERFIL ===
            pw.Text(l10n.pdfSectionIdentity,
                style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.pink900)),
            pw.Divider(color: PdfColors.pink900),
            pw.Text(
                "${l10n.pdfFieldPredominantBreed}: ${pet.identificacao.racaPredominante}"),
            pw.Text(
                "${l10n.petLineage}: ${pet.identificacao.linhagemSrdProvavel}"),
            pw.Text("${l10n.petSize}: ${pet.identificacao.porteEstimado}"),
            pw.Text(
                "${l10n.petLongevity}: ${pet.identificacao.expectativaVidaMedia}"),
            pw.SizedBox(height: 10),

            // Perfil Comportamental
            pw.Text("${l10n.pdfFieldBehavioralProfile}:",
                style:
                    pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Bullet(
                text:
                    "${l10n.pdfFieldEnergyLevel}: ${pet.perfilComportamental.nivelEnergia}/5"),
            pw.Bullet(
                text:
                    "${l10n.pdfFieldIntelligence}: ${pet.perfilComportamental.nivelInteligencia}/5"),
            pw.Bullet(
                text:
                    "${l10n.pdfFieldSociability}: ${pet.perfilComportamental.sociabilidadeGeral}/5"),
            pw.Bullet(
                text:
                    "${l10n.pdfFieldAncestralDrive}: ${pet.perfilComportamental.driveAncestral}"),
            pw.SizedBox(height: 15),

            // Growth Curve
            if (pet.identificacao.curvaCrescimento.isNotEmpty) ...[
              pw.Text("${l10n.pdfFieldEstimatedGrowthCurve}:",
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Bullet(
                  text:
                      "${l10n.petMonth3}: ${pet.identificacao.curvaCrescimento['peso_3_meses'] ?? 'N/A'}"),
              pw.Bullet(
                  text:
                      "${l10n.petMonth6}: ${pet.identificacao.curvaCrescimento['peso_6_meses'] ?? 'N/A'}"),
              pw.Bullet(
                  text:
                      "${l10n.petMonth12}: ${pet.identificacao.curvaCrescimento['peso_12_meses'] ?? 'N/A'}"),
              pw.Bullet(
                  text:
                      "${l10n.petAdult}: ${pet.identificacao.curvaCrescimento['peso_adulto'] ?? 'N/A'}"),
              pw.SizedBox(height: 15),
            ],

            // === SEÇÃO 2: NUTRIÇÃO E DIETA ===
            pw.Text(l10n.pdfSectionNutrition,
                style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.pink900)),
            pw.Divider(color: PdfColors.pink900),

            // Metas Calóricas
            pw.Text("${l10n.pdfFieldDailyCaloricGoals}:",
                style:
                    pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Bullet(
                text:
                    "${l10n.pdfFieldPuppy}: ${(pet.nutricao.metaCalorica['kcal_filhote'] ?? 'N/A').replaceAll('aproximadamente', '±')}"),
            pw.Bullet(
                text:
                    "${l10n.pdfFieldAdult}: ${(pet.nutricao.metaCalorica['kcal_adulto'] ?? 'N/A').replaceAll('aproximadamente', '±')}"),
            pw.Bullet(
                text:
                    "${l10n.pdfFieldSenior}: ${(pet.nutricao.metaCalorica['kcal_senior'] ?? 'N/A').replaceAll('aproximadamente', '±')}"),
            pw.SizedBox(height: 10),

            pw.Text(
                "${l10n.pdfFieldTargetNutrients}: ${pet.nutricao.nutrientesAlvo.join(', ')}"),
            pw.Text(
                "${l10n.pdfFieldSuggestedSupplementation}: ${pet.nutricao.suplementacaoSugerida.join(', ')}"),
            pw.SizedBox(height: 10),

            // Segurança Alimentar
            pw.Text("${l10n.pdfFieldFoodSafety}:",
                style:
                    pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            if (pet.nutricao.segurancaAlimentar['tendencia_obesidade'] == true)
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.red50,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(l10n.pdfAlertObesity,
                    style: const pw.TextStyle(color: PdfColors.red900)),
              ),
            pw.SizedBox(height: 15),

            // Tabelas de Alimentos
            if (pet.tabelaBenigna.isNotEmpty) ...[
              pw.Text("${l10n.pdfFieldSafeFoods}:",
                  style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.pink900)),
              pw.TableHelper.fromTextArray(
                headerStyle:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.pink100),
                data: [
                  [l10n.pdfFieldFoodName, l10n.pdfFieldBenefit],
                  ...pet.tabelaBenigna.map(
                      (row) => [row['alimento'] ?? '', row['beneficio'] ?? '']),
                ],
              ),
              pw.SizedBox(height: 10),
            ],

            if (pet.tabelaMaligna.isNotEmpty) ...[
              pw.Text("${l10n.pdfFieldToxicFoods}:",
                  style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.red900)),
              pw.TableHelper.fromTextArray(
                headerStyle:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.red100),
                data: [
                  [l10n.pdfFieldFoodName, l10n.pdfFieldRisk],
                  ...pet.tabelaMaligna.map(
                      (row) => [row['alimento'] ?? '', row['risco'] ?? '']),
                ],
              ),
              pw.SizedBox(height: 15),
            ],

            // Weekly Meal Plan
            if (pet.planoSemanal.isNotEmpty) ...[
              pw.Text("${l10n.pdfFieldWeeklyMenu}:",
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold)),
              if (pet.orientacoesGerais != null) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.pink50,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Text("💡 ${pet.orientacoesGerais}",
                      style: const pw.TextStyle(fontSize: 11)),
                ),
                pw.SizedBox(height: 10),
              ],
              ...pet.planoSemanal.asMap().entries.map((entry) {
                final index = entry.key;
                final day = entry.value;

                final now = DateTime.now();
                final mondayStart = DateTime(now.year, now.month, now.day)
                    .subtract(Duration(days: now.weekday - 1));
                final dateForDay = mondayStart.add(Duration(days: index));
                final dateStr = DateFormat(
                        'dd/MM', Localizations.localeOf(context).toString())
                    .format(dateForDay);
                final weekDayName = DateFormat(
                        'EEEE', Localizations.localeOf(context).toString())
                    .format(dateForDay);
                final weekDayCap =
                    weekDayName[0].toUpperCase() + weekDayName.substring(1);
                final String dia = "$weekDayCap - $dateStr";

                final String refeicao = (day['refeicao'] ?? '').toString();
                final String beneficio = (day['beneficio'] ?? '').toString();
                final String dailyKcal =
                    pet.nutricao.metaCalorica['kcal_adulto'] ??
                        pet.nutricao.metaCalorica['kcal_filhote'] ??
                        pet.nutricao.metaCalorica['kcal_senior'] ??
                        'N/A';

                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(dia,
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 12,
                                color: PdfColors.pink900)),
                        pw.RichText(
                            text: pw.TextSpan(children: [
                          const pw.TextSpan(
                              text: 'Meta: ',
                              style: pw.TextStyle(
                                  fontSize: 8, color: PdfColors.grey700)),
                          pw.TextSpan(
                              text: dailyKcal,
                              style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.pink900)),
                        ])),
                      ],
                    ),
                    pw.Bullet(
                        text: refeicao,
                        style: const pw.TextStyle(fontSize: 10)),
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 15),
                      child: pw.Text("↳ ${l10n.pdfFieldReason}: $beneficio",
                          style: pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey700,
                              fontStyle: pw.FontStyle.italic)),
                    ),
                    pw.SizedBox(height: 10),
                  ],
                );
              }),
              pw.SizedBox(height: 15),
            ],

            // === SEÇÃO 3: GROOMING E HIGIENE ===
            pw.Text(l10n.pdfSectionGrooming,
                style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.pink900)),
            pw.Divider(color: PdfColors.pink900),
            pw.Text(
                "${l10n.pdfFieldCoatType}: ${pet.higiene.manutencaoPelagem['tipo_pelo'] ?? 'N/A'}"),
            pw.Text(
                "${l10n.pdfFieldBrushingFrequency}: ${pet.higiene.manutencaoPelagem['frequencia_escovacao_semanal'] ?? 'N/A'}"),
            pw.Text(
                "${l10n.pdfFieldBathFrequency}: ${pet.higiene.banhoEHigiene['frequencia_ideal_banho'] ?? 'N/A'}"),
            pw.Text(
                "${l10n.pdfFieldRecommendedProducts}: ${pet.higiene.banhoEHigiene['produtos_recomendados'] ?? 'N/A'}"),
            if (pet.higiene.manutencaoPelagem['alerta_subpelo'] != null)
              pw.Container(
                margin: const pw.EdgeInsets.only(top: 8),
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey50,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                    "⚠️ ${pet.higiene.manutencaoPelagem['alerta_subpelo']}",
                    style: const pw.TextStyle(color: PdfColors.grey900)),
              ),
            pw.SizedBox(height: 15),

            // === SEÇÃO 4: SAÚDE PREVENTIVA ===
            pw.Text(l10n.pdfSectionHealth,
                style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red900)),
            pw.Divider(color: PdfColors.red900),

            pw.Text("${l10n.pdfFieldDiseasePredisposition}:",
                style:
                    pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            if (pet.saude.predisposicaoDoencas.isNotEmpty)
              ...pet.saude.predisposicaoDoencas.map((d) => pw.Bullet(text: d))
            else
              pw.Text("• ${l10n.petNotIdentifiedPlural}",
                  style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 10),

            pw.Text("${l10n.pdfFieldAnatomicalCriticalPoints}:",
                style:
                    pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            if (pet.saude.pontosCriticosAnatomicos.isNotEmpty)
              ...pet.saude.pontosCriticosAnatomicos
                  .map((p) => pw.Bullet(text: p))
            else
              pw.Text("• ${l10n.petNotIdentified}",
                  style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 10),

            pw.Text("${l10n.pdfFieldVeterinaryCheckup}:",
                style:
                    pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Bullet(
                text:
                    "${l10n.petFrequency}: ${pet.saude.checkupVeterinario['frequencia_ideal'] ?? 'Anual'}"),
            if (pet.saude.checkupVeterinario['exames_obrigatorios_anuais'] !=
                null)
              pw.Bullet(
                  text:
                      "${l10n.pdfFieldMandatoryExams}: ${(pet.saude.checkupVeterinario['exames_obrigatorios_anuais'] as List).join(', ')}"),
            pw.SizedBox(height: 10),

            pw.Text("${l10n.pdfFieldClimateSensitivity}:",
                style:
                    pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Bullet(
                text:
                    "${l10n.pdfFieldHeat}: ${pet.saude.sensibilidadeClimatica['tolerancia_calor'] ?? 'N/A'}"),
            pw.Bullet(
                text:
                    "${l10n.pdfFieldCold}: ${pet.saude.sensibilidadeClimatica['tolerancia_frio'] ?? 'N/A'}"),
            pw.SizedBox(height: 15),

            // Protocolo de Imunização
            if (pet.protocoloImunizacao != null) ...[
              pw.Text(l10n.pdfSectionImmunization,
                  style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.pink900)),
              pw.SizedBox(height: 8),

              // Vacinas Essenciais
              if (pet.protocoloImunizacao!['vacinas_essenciais'] != null) ...[
                pw.Text("${l10n.pdfFieldEssentialVaccines}:",
                    style: pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ...((pet.protocoloImunizacao!['vacinas_essenciais'] as List?) ??
                        [])
                    .map((v) {
                  final nome = v['nome'] ?? 'Vacina';
                  final objetivo = v['objetivo'] ?? '';
                  final primeiraIdade = v['idade_primeira_dose'] ?? '';
                  final reforco = v['reforco_adulto'] ?? '';

                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 6),
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.pink50,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("• $nome",
                            style: pw.TextStyle(
                                fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        if (objetivo.isNotEmpty)
                          pw.Text("  ${l10n.pdfFieldVaccineGoal}: $objetivo",
                              style: const pw.TextStyle(fontSize: 9)),
                        if (primeiraIdade.isNotEmpty)
                          pw.Text("  ${l10n.pdfFieldFirstDose}: $primeiraIdade",
                              style: const pw.TextStyle(fontSize: 9)),
                        if (reforco.isNotEmpty)
                          pw.Text("  ${l10n.pdfFieldBooster}: $reforco",
                              style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                  );
                }),
                pw.SizedBox(height: 10),
              ],

              // Calendário Preventivo
              if (pet.protocoloImunizacao!['calendario_preventivo'] !=
                  null) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.pink50,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.pink900),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Text("📅 ",
                              style: const pw.TextStyle(fontSize: 12)),
                          pw.Text(l10n.pdfFieldPreventiveCalendar,
                              style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.pink900)),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      if (pet.protocoloImunizacao!['calendario_preventivo']
                              ['cronograma_filhote'] !=
                          null)
                        pw.Bullet(
                            text:
                                "${l10n.pdfFieldPuppies}: ${pet.protocoloImunizacao!['calendario_preventivo']['cronograma_filhote']}",
                            style: const pw.TextStyle(fontSize: 10)),
                      if (pet.protocoloImunizacao!['calendario_preventivo']
                              ['reforco_anual'] !=
                          null)
                        pw.Bullet(
                            text:
                                "${l10n.pdfFieldAdults}: ${pet.protocoloImunizacao!['calendario_preventivo']['reforco_anual']}",
                            style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),
              ],

              // Prevenção Parasitária
              if (pet.protocoloImunizacao!['prevencao_parasitaria'] !=
                  null) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.pink50,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.pink900),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Text("🐛 ",
                              style: const pw.TextStyle(fontSize: 12)),
                          pw.Text(l10n.pdfFieldParasitePrevention,
                              style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.pink900)),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      if (pet.protocoloImunizacao!['prevencao_parasitaria']
                              ['vermifugacao'] !=
                          null)
                        pw.Builder(
                          builder: (context) {
                            final vermifugacao = pet.protocoloImunizacao![
                                    'prevencao_parasitaria']['vermifugacao']
                                as Map<String, dynamic>;
                            return pw.Bullet(
                                text:
                                    "${l10n.pdfFieldDewormer}: ${vermifugacao['frequencia'] ?? l10n.petConsultVetCare}",
                                style: const pw.TextStyle(fontSize: 10));
                          },
                        ),
                      if (pet.protocoloImunizacao!['prevencao_parasitaria']
                              ['controle_ectoparasitas'] !=
                          null)
                        pw.Builder(
                          builder: (context) {
                            final ecto = pet.protocoloImunizacao![
                                        'prevencao_parasitaria']
                                    ['controle_ectoparasitas']
                                as Map<String, dynamic>;
                            return pw.Bullet(
                                text:
                                    "${l10n.pdfFieldTickFlea}: ${ecto['pulgas_carrapatos'] ?? l10n.petConsultVetCare}",
                                style: const pw.TextStyle(fontSize: 10));
                          },
                        ),
                      if (pet.protocoloImunizacao!['prevencao_parasitaria']
                              ['alerta_regional'] !=
                          null)
                        pw.Container(
                          margin: const pw.EdgeInsets.only(top: 6),
                          padding: const pw.EdgeInsets.all(6),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.red50,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                              "⚠️ ${pet.protocoloImunizacao!['prevencao_parasitaria']['alerta_regional']}",
                              style: const pw.TextStyle(
                                  fontSize: 9, color: PdfColors.red900)),
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
                    color: PdfColors.pink50,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.pink900),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Text("🦴 ",
                              style: const pw.TextStyle(fontSize: 12)),
                          pw.Text(l10n.pdfFieldOralBoneHealth,
                              style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.pink900)),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      if (pet.protocoloImunizacao!['saude_bucal_ossea']
                              ['ossos_naturais_permitidos'] !=
                          null)
                        pw.Builder(
                          builder: (context) {
                            final ossos =
                                pet.protocoloImunizacao!['saude_bucal_ossea']
                                    ['ossos_naturais_permitidos'] as List;
                            return pw.Bullet(
                                text:
                                    "${l10n.pdfFieldPermittedBones}: ${ossos.join(', ')}",
                                style: const pw.TextStyle(fontSize: 10));
                          },
                        ),
                      if (pet.protocoloImunizacao!['saude_bucal_ossea']
                              ['frequencia_semanal'] !=
                          null)
                        pw.Bullet(
                            text:
                                "${l10n.pdfFieldFrequency}: ${pet.protocoloImunizacao!['saude_bucal_ossea']['frequencia_semanal']}",
                            style: const pw.TextStyle(fontSize: 10)),
                      if (pet.protocoloImunizacao!['saude_bucal_ossea']
                              ['alerta_seguranca'] !=
                          null)
                        pw.Container(
                          margin: const pw.EdgeInsets.only(top: 6),
                          padding: const pw.EdgeInsets.all(6),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.red50,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                              "⚠️ ${pet.protocoloImunizacao!['saude_bucal_ossea']['alerta_seguranca']}",
                              style: const pw.TextStyle(
                                  fontSize: 9, color: PdfColors.red900)),
                        ),
                    ],
                  ),
                ),
              ],

              pw.SizedBox(height: 15),
            ],

            // === SEÇÃO 5: LIFESTYLE E EDUCAÇÃO ===
            pw.Text(l10n.pdfSectionLifestyle,
                style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.pink900)),
            pw.Divider(color: PdfColors.pink900),

            pw.Text("${l10n.pdfFieldTraining}:",
                style:
                    pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Bullet(
                text:
                    "${l10n.pdfFieldTrainingDifficulty}: ${pet.lifestyle.treinamento['dificuldade_adestramento'] ?? 'N/A'}"),
            pw.Bullet(
                text:
                    "${l10n.pdfFieldRecommendedMethods}: ${pet.lifestyle.treinamento['metodos_recomendados'] ?? l10n.petPositiveReinforcement}"),
            pw.SizedBox(height: 10),

            pw.Text("${l10n.pdfFieldIdealEnvironment}:",
                style:
                    pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Bullet(
                text:
                    "${l10n.pdfFieldOpenSpace}: ${pet.lifestyle.ambienteIdeal['necessidade_de_espaco_aberto'] ?? 'N/A'}"),
            pw.Bullet(
                text:
                    "${l10n.pdfFieldApartmentAdaptation}: ${pet.lifestyle.ambienteIdeal['adaptacao_apartamento_score'] ?? 'N/A'}/5"),
            pw.SizedBox(height: 10),

            pw.Text("${l10n.pdfFieldMentalStimulus}:",
                style:
                    pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Bullet(
                text:
                    "${l10n.petFrequency}: ${pet.lifestyle.estimuloMental['necessidade_estimulo_mental'] ?? 'N/A'}"),
            pw.Bullet(
                text:
                    "${l10n.pdfFieldSuggestedActivities}: ${pet.lifestyle.estimuloMental['atividades_sugeridas'] ?? l10n.petInteractiveToys}"),
            pw.SizedBox(height: 15),

            // === INSIGHT DO ESPECIALISTA ===
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.pink50,
                borderRadius: pw.BorderRadius.circular(10),
                border: pw.Border.all(color: PdfColors.pink900),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("💡 ${l10n.pdfFieldExpertInsight}",
                      style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.pink900)),
                  pw.SizedBox(height: 6),
                  pw.Text(
                      pet.dica.insightExclusivo
                          .replaceAll('veterinário', 'Vet')
                          .replaceAll('Veterinário', 'Vet')
                          .replaceAll('aproximadamente', '±')
                          .replaceAll('Aproximadamente', '±'),
                      style: const pw.TextStyle(fontSize: 11)),
                ],
              ),
            ),

            // === SEÇÃO 6: HISTÓRICO CLÍNICO & FERIDAS (Unified) ===
            if (history.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              pw.Text(l10n.pdfClinicalHistorySection,
                  style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.red900)),
              pw.Divider(color: PdfColors.red900),
              ...history.asMap().entries.map((entry) {
                final index = entry.key;
                final h = entry.value;
                final img = historicalImages[index];
                final dateLabel = DateFormat.yMd(l10n.localeName)
                    .add_Hm()
                    .format(h.dataAnalise);

                return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 12),
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(8)),
                    child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // Imagem
                          if (img != null)
                            pw.Container(
                                width: 80,
                                height: 80,
                                margin: const pw.EdgeInsets.only(right: 12),
                                decoration: pw.BoxDecoration(
                                    border: pw.Border.all(
                                        color: PdfColors.grey200)),
                                child: pw.Image(img, fit: pw.BoxFit.cover)),

                          // Dados
                          pw.Expanded(
                              child: pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,
                                  children: [
                                pw.Row(
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.spaceBetween,
                                    children: [
                                      pw.Text(
                                          (h.categoria ?? l10n.commonGeneral)
                                              .toUpperCase(),
                                          style: pw.TextStyle(
                                              fontWeight: pw.FontWeight.bold,
                                              fontSize: 11,
                                              color: PdfColors.pink900)),
                                      pw.Text(dateLabel,
                                          style: const pw.TextStyle(
                                              fontSize: 9,
                                              color: PdfColors.grey700)),
                                    ]),
                                pw.SizedBox(height: 4),

                                if (h.diagnosticosProvaveis.isNotEmpty)
                                  pw.Padding(
                                    padding:
                                        const pw.EdgeInsets.only(bottom: 4),
                                    child: pw.Text(
                                        "${l10n.pdfDiagnoses}: ${h.diagnosticosProvaveis.join(', ')}",
                                        style: pw.TextStyle(
                                            fontSize: 10,
                                            fontWeight: pw.FontWeight.bold,
                                            color: PdfColors.black)),
                                  ),

                                // Detalhes (Achados)
                                ...h.achadosVisuais.entries
                                    .where((e) =>
                                        e.value != null &&
                                        e.value.toString().isNotEmpty &&
                                        e.value.toString().toLowerCase() !=
                                            'null')
                                    .take(6)
                                    .map((e) => pw.Text(
                                        "• ${e.key}: ${e.value}",
                                        style: const pw.TextStyle(
                                            fontSize: 9,
                                            color: PdfColors.grey800))),

                                if (h.recomendacao.isNotEmpty)
                                  pw.Padding(
                                      padding: const pw.EdgeInsets.only(top: 4),
                                      child: pw.Text(
                                          "${l10n.pdfRecommendation}: ${h.recomendacao}",
                                          maxLines: 3,
                                          style: pw.TextStyle(
                                              fontSize: 9,
                                              fontStyle: pw.FontStyle.italic,
                                              color: PdfColors.grey700))),
                              ]))
                        ]));
              }),
            ],

            pw.Footer(
              title: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(l10n.pdfFooterBranding,
                      style: const pw.TextStyle(
                          fontSize: 10, color: PdfColors.grey)),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    l10n.pdfDisclaimer,
                    style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                        fontStyle: pw.FontStyle.italic),
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
            title:
                "${l10n.pdfDossierTitle}: ${widget.petName ?? l10n.petNotIdentified}",
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
      case 0:
        return _buildIdentidadeTab(sc);
      case 1:
        return _buildNutricaoTab(sc);
      case 2:
        return _buildGroomingTab(sc);
      case 3:
        return _buildSaudeTab(sc);
      case 4:
        return _buildLifestyleTab(sc);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      minChildSize: 0.95,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: Container(
            color: AppDesign.backgroundDark,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _buildMainContent(scrollController),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainContent(ScrollController sc) {
    return ListView(
      controller: sc,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        _buildSummaryCard(),
        const SizedBox(height: 12),
        _buildSignsCard(),
        const SizedBox(height: 12),
        _buildRecommendationsCard(),
        const SizedBox(height: 12),
        _buildTechnicalExpansion(),
        const SizedBox(height: 32),
        _buildFooterActions(),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppDesign.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: AppDesign.petPink),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.petResult,
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
              PdfActionButton(onPressed: _generatePDF),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {
                  if (!_isSaved) {
                    setState(() => _isSaved = true);
                    widget.onSave();
                  }
                },
                icon: Icon(
                    _isSaved ? Icons.check_circle_rounded : Icons.save_rounded,
                    color: AppDesign.petPink),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final l10n = AppLocalizations.of(context)!;
    final isDiag = widget.analysis.analysisType == 'diagnosis';
    final title =
        widget.petName ?? (isDiag ? widget.analysis.raca : _localizedRaca);
    final subtitle = isDiag
        ? widget.analysis.especie
        : (widget.petProfile?.especie ?? widget.analysis.especie);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppDesign.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.tabSummary,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppDesign.petPink,
                    letterSpacing: 1.2),
              ),
              if (widget.analysis.reliability != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppDesign.petPink.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${l10n.petLabelConfidence}: ${widget.analysis.reliability}",
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppDesign.petPink),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildPetAvatarCard(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                          fontSize: 14, color: Colors.white60),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isDiag
                ? widget.analysis.descricaoVisual
                : widget.analysis.identificacao.linhagemSrdProvavel,
            style: GoogleFonts.poppins(
                fontSize: 14, color: Colors.white, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildPetAvatarCard() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppDesign.petPink.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        image: widget.imagePath.isNotEmpty
            ? DecorationImage(
                image: FileImage(File(widget.imagePath)),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: widget.imagePath.isEmpty
          ? const Icon(Icons.pets_rounded, color: AppDesign.petPink, size: 30)
          : null,
    );
  }

  Widget _buildSignsCard() {
    final l10n = AppLocalizations.of(context)!;
    final isDiag = widget.analysis.analysisType == 'diagnosis';

    // 🛡️ V144: UNIFIED DATA AGGREGATION
    // Combine all specialized finding maps into one display source to ensure nothing is hidden
    final Map<String, dynamic> effectiveSigns = {};

    // 1. Base Generic Signs
    if (widget.analysis.clinicalSignsDiag != null) {
      effectiveSigns.addAll(widget.analysis.clinicalSignsDiag!);
    }

    // 2. Specialized Maps (Merge if present)
    if (widget.analysis.stoolAnalysis != null) {
      effectiveSigns.addAll(widget.analysis.stoolAnalysis!);
    }
    if (widget.analysis.eyeDetails != null) {
      effectiveSigns.addAll(widget.analysis.eyeDetails!);
    }
    if (widget.analysis.dentalDetails != null) {
      effectiveSigns.addAll(widget.analysis.dentalDetails!);
    }
    if (widget.analysis.skinDetails != null) {
      effectiveSigns.addAll(widget.analysis.skinDetails!);
    }
    if (widget.analysis.woundDetails != null) {
      effectiveSigns.addAll(widget.analysis.woundDetails!);
    }

    final racaPredict = widget.analysis.identificacao.racaPredict;
    final morfologia = widget.analysis.identificacao.morfologiaBase;

    // 🛡️ V190: DEEP DIAGNOSIS MODE - SHOW ALL DATA
    if (isDiag) {
      return Column(
        children: [
          // 1. Clinical Signs (Detailed Map)
          if (effectiveSigns.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppDesign.surfaceDark,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
              ),
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: true,
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: const Icon(Icons.medical_services_outlined,
                      color: AppDesign.warning),
                  title: Text(
                    l10n.labelClinicalSigns.toUpperCase(),
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 14),
                  ),
                  subtitle: Text(
                    l10n.petClinicalSignsCount(effectiveSigns.length),
                    style: GoogleFonts.poppins(
                        color: Colors.white54, fontSize: 12),
                  ),
                  children: effectiveSigns.entries.where((e) {
                    final k = e.key.toLowerCase();
                    return ![
                      'identification',
                      'identificacao',
                      'pet_name',
                      'analysis_type',
                      'metadata',
                      'raw_response'
                    ].contains(k);
                  }).map((e) {
                    IconData icon = Icons.help_outline;
                    Color color = Colors.white70;
                    String label = _translateKey(e.key.toString(), l10n);
                    final k = e.key.toLowerCase();

                    // Icon Mapping
                    if (k.contains('eye') || k.contains('olho')) {
                      icon = Icons.visibility;
                    } else if (k.contains('skin') || k.contains('pele')) {
                      icon = Icons.spa;
                    } else if (k.contains('bone') ||
                        k.contains('ortho') ||
                        k.contains('ortop')) {
                      icon = Icons.accessibility_new;
                    } else if (k.contains('diges')) {
                      icon = Icons.local_dining;
                    } else if (k.contains('dent')) {
                      icon = Icons.cleaning_services;
                    }
                    // Stool Specifics
                    else if (k.contains('stool') ||
                        k.contains('fec') ||
                        k.contains('coco') ||
                        k.contains('bristol') ||
                        k.contains('parasit') ||
                        k.contains('worm')) {
                      icon = FontAwesomeIcons.poop;
                    }

                    // Value safe conversion
                    final valStr = e.value.toString();

                    // Highlight abnormal findings
                    final isNormal = valStr.toLowerCase().contains('normal') ||
                        valStr.toLowerCase().contains('saudável') ||
                        valStr.toLowerCase().contains('ausente') ||
                        valStr.toLowerCase() == 'false' ||
                        valStr.toLowerCase() == 'não' ||
                        valStr.toLowerCase() == 'no';

                    if (!isNormal) color = AppDesign.warning;

                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                              width: 20,
                              child: Icon(icon, color: color, size: 16)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(label,
                                    style: GoogleFonts.poppins(
                                        color: Colors.white54,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                                Text(valStr,
                                    style: GoogleFonts.poppins(
                                        color: isNormal
                                            ? Colors.white70
                                            : Colors.white,
                                        fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          // 2. Possible Causes (Explicit List)
          if (widget.analysis.possiveisCausas.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: AppDesign.surfaceDark,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
              ),
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: true,
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: const Icon(Icons.analytics_outlined,
                      color: AppDesign.petPink),
                  title: Text(
                    l10n.petLabelPossibleCauses,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 14),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        children: widget.analysis.possiveisCausas
                            .map((cause) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.arrow_right_rounded,
                                          color: AppDesign.petPink, size: 20),
                                      const SizedBox(width: 4),
                                      Expanded(
                                          child: Text(cause,
                                              style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontSize: 13))),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    )
                  ],
                ),
              ),
            ),
        ],
      );
    }

    // fallback for Identification Mode
    final signs = [
      if (racaPredict != 'Unknown' && racaPredict.isNotEmpty)
        "IA Breed: $racaPredict",
      if (morfologia.isNotEmpty) "Morfologia: $morfologia",
      _bestEffortTranslate(widget.analysis.identificacao.porteEstimado),
      _bestEffortTranslate(
          widget.analysis.higiene.manutencaoPelagem['tipo_pelo'] ??
              l10n.commonNormal),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppDesign.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fingerprint, color: AppDesign.petPink),
              const SizedBox(width: 8),
              Text(
                l10n.pdfIdentitySection.toUpperCase(),
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...signs.map((sign) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        color: AppDesign.petPink, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        sign,
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.9)),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    final l10n = AppLocalizations.of(context)!;
    final isDiag = widget.analysis.analysisType == 'diagnosis';

    final rawCare = widget.analysis.orientacaoImediata;
    final homeCare = isDiag
        ? (rawCare == 'Consulte um Vet.' ? l10n.petConsultVetCare : rawCare)
        : (widget.analysis.nutricao.nutrientesAlvo.isNotEmpty
            ? "${l10n.petSupplementation}: ${widget.analysis.nutricao.nutrientesAlvo.join(', ')}"
            : l10n.petCheckup);

    final vetCare = isDiag ? widget.analysis.urgenciaNivel : l10n.petCheckup;

    final isEmergency = isDiag &&
        (widget.analysis.urgenciaNivel.toLowerCase().contains('emergência') ||
            widget.analysis.urgenciaNivel.toLowerCase().contains('red') ||
            widget.analysis.urgenciaNivel.toLowerCase().contains('vermelho'));

    return Container(
      decoration: BoxDecoration(
        color: AppDesign.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isEmergency
                ? Colors.red.withValues(alpha: 0.3)
                : Colors.white10),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Icon(
            isEmergency ? Icons.warning_amber_rounded : Icons.healing,
            color: isEmergency ? Colors.redAccent : AppDesign.petPink,
          ),
          title: Text(
            l10n.petLabelRecommendations,
            style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // VETERINARY STATUS HEADER
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isEmergency
                          ? Colors.red.withValues(alpha: 0.2)
                          : Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isEmergency ? Colors.red : Colors.green,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.monitor_heart,
                            size: 16,
                            color: isEmergency ? Colors.red : Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          vetCare.toUpperCase(),
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isEmergency ? Colors.red : Colors.green),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // FULL RECOMMENDATION TEXT
                  Text(
                    l10n.petImmediateOrientation.toUpperCase(),
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    homeCare,
                    style: GoogleFonts.poppins(
                        fontSize: 14, color: Colors.white, height: 1.5),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // _buildCareSection is no longer needed but keeping it empty or deprecated would be cleaner.
  // For safety, I'll remove it or ignore it if not called.
  // Actually, I can just replace the whole block including _buildCareSection if it was consecutive.
  // Checking line numbers... 1081 is _buildCareSection. My edit ends at 1110.
  // So I can replace both functions in one go.

  Widget _buildTechnicalExpansion() {
    final l10n = AppLocalizations.of(context)!;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          l10n.petTechnicalDetails,
          style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: const Icon(Icons.analytics_rounded, color: AppDesign.petPink),
        backgroundColor: AppDesign.surfaceDark,
        collapsedBackgroundColor: AppDesign.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        collapsedShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        children: [
          _buildTechnicalGrid(),
        ],
      ),
    );
  }

  Widget _buildTechnicalGrid() {
    final nut = widget.analysis.nutricao;
    final id = widget.analysis.identificacao;

    return Column(
      children: [
        if (nut.metaCalorica.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildCaloricMetrics(nut.metaCalorica),
          const SizedBox(height: 16),
        ],
        _buildInfoRow(AppLocalizations.of(context)!.petSize,
            _bestEffortTranslate(id.porteEstimado)),
        _buildInfoRow(AppLocalizations.of(context)!.petLongevity,
            _bestEffortTranslate(id.expectativaVidaMedia)),
        _buildInfoRow(AppLocalizations.of(context)!.petLineage,
            _bestEffortTranslate(id.linhagemSrdProvavel)),
      ],
    );
  }

  Widget _buildCaloricMetrics(Map<String, String> meta) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildMetricRow(l10n.petAdult, meta['kcal_adulto'] ?? 'N/A'),
          const SizedBox(height: 8),
          _buildMetricRow(l10n.petPuppy, meta['kcal_filhote'] ?? 'N/A'),
          const SizedBox(height: 8),
          _buildMetricRow(l10n.petSenior, meta['kcal_senior'] ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    final cleanValue = value.replaceAll('[ESTIMATED]', '').trim();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
        Text(
          cleanValue,
          style: GoogleFonts.poppins(
              color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildFooterActions() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () {
              // Navigation to pet profile
              Navigator.pop(context);
            },
            icon: const Icon(Icons.pets_rounded),
            label: Text(l10n.petResult_viewProfile),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppDesign.petPink,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _generatePDF,
                icon: const Icon(Icons.picture_as_pdf_rounded,
                    color: Colors.white),
                label: Text(l10n.commonShare,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppDesign.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (!_isSaved)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _isSaved = true);
                    widget.onSave();
                  },
                  icon: const Icon(Icons.save_rounded),
                  label: Text(l10n.commonSave),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _showAttachmentOptions() async {
    final service = FileUploadService();

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppDesign.surfaceDark,
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
                color: AppDesign.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(AppDesign.iconScan, color: AppDesign.accent),
              title: Text('Tirar Foto de Receita/Exame',
                  style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark)),
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
                      const SnackBar(
                          content: Text('Documento salvo! Processando...')),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppDesign.info),
              title: Text('Escolher da Galeria',
                  style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark)),
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
                      const SnackBar(
                          content: Text('Documento salvo! Processando...')),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const AppPdfIcon(),
              title: Text('Selecionar PDF',
                  style: GoogleFonts.poppins(color: Colors.white)),
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
                      const SnackBar(
                          content: Text('Documento salvo! Processando...')),
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
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white10))),
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
          decoration: BoxDecoration(
              color: _urgencyColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _urgencyColor)),
          child: Row(
            children: [
              Icon(_isEmergency ? Icons.warning : Icons.info,
                  color: _urgencyColor),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(widget.analysis.urgenciaNivel,
                      style: GoogleFonts.poppins(
                          color: _urgencyColor, fontWeight: FontWeight.bold))),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionCard(
            title: AppLocalizations.of(context)!.petVisualDescription,
            icon: Icons.visibility,
            color: Colors.blueAccent,
            child: Text(
                widget.analysis.descricaoVisual
                    .replaceAll('veterinário', 'Vet')
                    .replaceAll('Veterinário', 'Vet')
                    .replaceAll('aproximadamente', '±')
                    .replaceAll('Aproximadamente', '±'),
                style: const TextStyle(color: Colors.white70))),
        const SizedBox(height: 16),
        _buildSectionCard(
            title: AppLocalizations.of(context)!.petPossibleCauses,
            icon: Icons.list,
            color: AppDesign.petPink,
            child: Text(widget.analysis.possiveisCausas.join('\n• '),
                style: const TextStyle(color: Colors.white70))),
        const SizedBox(height: 16),
        _buildSectionCard(
            title: AppLocalizations.of(context)!.petSpecialistOrientation,
            icon: Icons.medical_services,
            color: AppDesign.petPink,
            child: Text(
                widget.analysis.orientacaoImediata
                    .replaceAll('veterinário', 'Vet')
                    .replaceAll('Veterinário', 'Vet')
                    .replaceAll('aproximadamente', '±')
                    .replaceAll('Aproximadamente', '±'),
                style: const TextStyle(color: Colors.white))),
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
                  color: Colors.white.withValues(alpha: 0.05),
                  child: const Center(
                      child: Icon(Icons.pets, size: 50, color: Colors.white24)),
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
              _buildInfoRow("${AppLocalizations.of(context)!.petLineage}:",
                  _bestEffortTranslate(id.linhagemSrdProvavel)),
              _buildInfoRow("${AppLocalizations.of(context)!.petSize}:",
                  _bestEffortTranslate(id.porteEstimado)),
              _buildInfoRow("${AppLocalizations.of(context)!.petLongevity}:",
                  _bestEffortTranslate(id.expectativaVidaMedia)),
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
                _buildInfoRow(
                    "${AppLocalizations.of(context)!.petMonth3}:",
                    _bestEffortTranslate(
                        id.curvaCrescimento['peso_3_meses'] ?? 'N/A')),
                _buildInfoRow(
                    "${AppLocalizations.of(context)!.petMonth6}:",
                    _bestEffortTranslate(
                        id.curvaCrescimento['peso_6_meses'] ?? 'N/A')),
                _buildInfoRow(
                    "${AppLocalizations.of(context)!.petMonth12}:",
                    _bestEffortTranslate(
                        id.curvaCrescimento['peso_12_meses'] ?? 'N/A')),
                _buildInfoRow(
                    "${AppLocalizations.of(context)!.petAdult}:",
                    _bestEffortTranslate(
                        id.curvaCrescimento['peso_adulto'] ?? 'N/A')),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        _buildStatLine(AppLocalizations.of(context)!.petEnergy,
            pc.nivelEnergia / 5.0, AppDesign.petPink),
        _buildStatLine(AppLocalizations.of(context)!.petIntelligence,
            pc.nivelInteligencia / 5.0, AppDesign.petPink),
        _buildStatLine(AppLocalizations.of(context)!.petSociability,
            pc.sociabilidadeGeral / 5.0, AppDesign.petPink),
        _buildInfoLabel(
            "${AppLocalizations.of(context)!.petDrive}:", pc.driveAncestral),
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
        if (widget.analysis.tabelaBenigna.isNotEmpty ||
            widget.analysis.tabelaMaligna.isNotEmpty) ...[
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
              weeklyPlan: widget.analysis.planoSemanal
                  .map((e) => Map<String, String>.from(
                      e.map((key, value) => MapEntry(key, value.toString()))))
                  .toList(),
              generalGuidelines: widget.analysis.orientacoesGerais,
              startDate: DateTime.now().subtract(Duration(
                  days: DateTime.now().weekday -
                      1)), // Começamos na Segunda-feira desta semana
              dailyKcal: nut.metaCalorica['kcal_adulto'] ??
                  nut.metaCalorica['kcal_filhote'] ??
                  nut.metaCalorica['kcal_senior'],
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
              _buildCaloricRow("${AppLocalizations.of(context)!.petPuppy}:",
                  nut.metaCalorica['kcal_filhote'] ?? 'N/A', Colors.pinkAccent),
              const Divider(color: Colors.white10, height: 16),
              _buildCaloricRow("${AppLocalizations.of(context)!.petAdult}:",
                  nut.metaCalorica['kcal_adulto'] ?? 'N/A', Colors.orange),
              const Divider(color: Colors.white10, height: 16),
              _buildCaloricRow("${AppLocalizations.of(context)!.petSenior}:",
                  nut.metaCalorica['kcal_senior'] ?? 'N/A', Colors.blueGrey),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: AppLocalizations.of(context)!.petSecuritySupplements,
          icon: Icons.medication_liquid,
          color: AppDesign.petPink,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoLabel(
                  "${AppLocalizations.of(context)!.petTargetNutrients}:",
                  nut.nutrientesAlvo.join(', ')),
              _buildInfoLabel(
                  "${AppLocalizations.of(context)!.petSupplementation}:",
                  nut.suplementacaoSugerida.join(', ')),
              _buildToggleInfo(AppLocalizations.of(context)!.petObesityTendency,
                  nut.segurancaAlimentar['tendencia_obesidade'] == true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGroomingTab(ScrollController sc) {
    final groo = widget.analysis.higiene;
    return ListView(
        controller: sc,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        children: [
          _buildSectionCard(
              title: AppLocalizations.of(context)!.petCoatGrooming,
              icon: Icons.brush,
              color: Colors.amber,
              child: Column(children: [
                _buildInfoRow(
                    "${AppLocalizations.of(context)!.petType}:",
                    _bestEffortTranslate(
                        groo.manutencaoPelagem['tipo_pelo'] ?? 'N/A')),
                _buildInfoRow(
                    "${AppLocalizations.of(context)!.petFrequency}:",
                    _bestEffortTranslate(groo.manutencaoPelagem[
                            'frequencia_escovacao_semanal'] ??
                        'N/A')),
                if (groo.manutencaoPelagem['alerta_subpelo'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                      _bestEffortTranslate(
                          groo.manutencaoPelagem['alerta_subpelo']!),
                      style: const TextStyle(
                          color: Colors.cyanAccent, fontSize: 11)),
                ]
              ])),
        ]);
  }

  Widget _buildSaudeTab(ScrollController sc) {
    final sau = widget.analysis.saude;
    return ListView(
        controller: sc,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        children: [
          _buildSectionCard(
              title: AppLocalizations.of(context)!.petPreventiveHealth,
              icon: Icons.health_and_safety,
              color: Colors.redAccent,
              child: Column(children: [
                _buildInfoLabel(
                    "${AppLocalizations.of(context)!.petPredisposition}:",
                    sau.predisposicaoDoencas.join(', ')),
                _buildInfoLabel(
                    "${AppLocalizations.of(context)!.petCheckup}:",
                    (sau.checkupVeterinario['exames_obrigatorios_anuais']
                                as List? ??
                            [])
                        .join(', ')),
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
    return ListView(
        controller: sc,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        children: [
          _buildSectionCard(
              title: AppLocalizations.of(context)!.petTrainingEnvironment,
              icon: Icons.psychology,
              color: AppDesign.petPink,
              child: Column(children: [
                _buildInfoRow(
                    "${AppLocalizations.of(context)!.petTraining}:",
                    _bestEffortTranslate(
                        life.treinamento['dificuldade_adestramento'] ?? 'N/A')),
                _buildStatLine(
                    AppLocalizations.of(context)!.petApartmentRef,
                    (life.ambienteIdeal['adaptacao_apartamento_score'] ?? 3) /
                        5.0,
                    AppDesign.petPink),
              ])),
        ]);
  }

  // --- HELPERS ---

  Widget _buildSectionCard(
      {required String title,
      required IconData icon,
      required Color color,
      required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(title,
                  style: GoogleFonts.poppins(
                      color: color, fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis))
        ]),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }

  Widget _buildInfoRow(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(width: 8),
        Expanded(
            child: Text(
                value
                    .replaceAll('aproximadamente', '±')
                    .replaceAll('Aproximadamente', '±')
                    .replaceAll('veterinário', 'Vet')
                    .replaceAll('Veterinário', 'Vet'),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.right))
      ]));

  Widget _buildStatLine(String label, double percent, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style:
                      GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
              Text("${(percent * 100).toInt()}%",
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.white10,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppDesign.petPink),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoLabel(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
                text: "$label ",
                style: GoogleFonts.poppins(
                    color: Colors.white60,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
            TextSpan(
                text: value,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleInfo(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(value ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: value ? AppDesign.petPink : Colors.white24, size: 16),
          const SizedBox(width: 8),
          Text(label,
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildInsightCard(String insight) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppDesign.petPink.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppDesign.petPink.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: AppDesign.petPink),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              insight,
              style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaloricRow(String label, String value, Color color) {
    final isEstimated = value.contains('[ESTIMATED]');
    final cleanValue = value
        .replaceAll('[ESTIMATED]', '')
        .replaceAll('aproximadamente', '±')
        .replaceAll('Aproximadamente', '±')
        .replaceAll('Kcal/dia', '')
        .replaceAll('kcal/dia', '')
        .replaceAll('Kcal', '')
        .replaceAll('kcal', '')
        .trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(isEstimated ? Icons.auto_awesome : Icons.label_important,
              color: AppDesign.petPink.withValues(alpha: 0.5), size: 14),
          const SizedBox(width: 10),
          SizedBox(
            width: 85,
            child: Text(label,
                style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  cleanValue,
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
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
            child: Text(AppLocalizations.of(context)!.kcalPerDay,
                style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11),
                textAlign: TextAlign.left),
          ),
        ],
      ),
    );
  }

  String _translateKey(String key, AppLocalizations l10n) {
    final upper = key.toUpperCase().replaceAll(' ', '_');

    final Map<String, String> mapper = {
      'IDENTIFICATION': l10n.labelIdentification,
      'BREED_NAME': l10n.labelBreed,
      'ORIGIN_REGION': l10n.labelOriginRegion,
      'MORPHOLOGY_TYPE': l10n.labelMorphologyType,
      'LINEAGE': l10n.labelLineage,
      'SIZE': l10n.labelSize,
      'LIFESPAN': l10n.labelLifespan,
      'GROWTH_CURVE': l10n.labelGrowthCurve,
      'NUTRITION': l10n.labelNutrition,
      'KCAL_PUPPY': l10n.labelKcalPuppy,
      'KCAL_ADULT': l10n.labelKcalAdult,
      'KCAL_SENIOR': l10n.labelKcalSenior,
      'TARGET_NUTRIENTS': l10n.labelTargetNutrients,
      'WEIGHT': l10n.labelWeight,
      'HEIGHT': l10n.labelHeight,
      'COAT': l10n.labelCoat,
      'COLOR': l10n.labelColor,
      'TEMPERAMENT': l10n.labelTemperament,
      'ENERGY_LEVEL': l10n.labelEnergyLevel,
      'SOCIAL_BEHAVIOR': l10n.labelSocialBehavior,
      'CLINICAL_SIGNS': l10n.labelClinicalSigns,
      'GROOMING': l10n.labelGrooming,
      'COAT_TYPE': l10n.labelCoatType,
      'GROOMING_FREQUENCY': l10n.labelGroomingFrequency,
      'HEALTH': l10n.labelHealth,
      'PREDISPOSITIONS': l10n.labelPredispositions,
      'PREVENTIVE_CHECKUP': l10n.labelPreventiveCheckup,
      'LIFESTYLE': l10n.labelLifestyle,
      'TRAINING_INTELLIGENCE': l10n.labelTrainingIntelligence,
      'ENVIRONMENT_TYPE': l10n.labelEnvironmentType,
      'ACTIVITY_LEVEL': l10n.labelActivityLevel,
      'PERSONALITY': l10n.labelPersonality,
      'EYES': l10n.labelEyes,
      'SKIN': l10n.labelSkin,
      'DENTAL': l10n.labelDental,
      'ORAL': l10n.labelOral,
      'STOOL': l10n.labelStool,
      'WOUNDS': l10n.labelWounds,
      'EYE': l10n.labelEyes,
    };

    return mapper[upper] ?? key.replaceAll('_', ' ').toUpperCase();
  }

  String _translateStatus(String status, AppLocalizations l10n) {
    switch (status.toLowerCase().trim()) {
      case 'verde':
      case 'green':
      case 'bajo':
      case 'low':
        return l10n.commonGreen;
      case 'amarelo':
      case 'yellow':
      case 'medio':
      case 'medium':
        return l10n.commonYellow;
      case 'vermelho':
      case 'red':
      case 'rojo':
      case 'high':
      case 'alta':
        return l10n.commonRed;
      default:
        return status;
    }
  }
}
