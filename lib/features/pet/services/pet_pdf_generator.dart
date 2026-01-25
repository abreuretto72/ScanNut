import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:scannut/l10n/app_localizations.dart';
import '../models/pet_profile_extended.dart';
import '../models/pet_analysis_result.dart';
import '../models/analise_ferida_model.dart';
import '../models/brand_suggestion.dart'; // 🛡️ NEW
import '../models/weekly_meal_plan.dart'; // 🛡️ NEW

import '../models/lab_exam.dart';
import '../../../core/services/image_optimization_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
// 🛡️ NEW: Para acessar recommendedBrands

class PetPdfGenerator {
  static final PetPdfGenerator _instance = PetPdfGenerator._internal();
  factory PetPdfGenerator() => _instance;
  PetPdfGenerator._internal();

  static final PdfColor colorPrimary =
      PdfColor.fromHex('#E3F2FD'); // Light blue as base
  static final PdfColor colorAccent = PdfColor.fromHex('#1976D2');
  static final PdfColor colorText = PdfColor.fromHex('#333333');

  // NEW DESIGN SYSTEM (V300) - Soft & Professional Palette
  static final PdfColor softBlue = PdfColor.fromHex('#E3F2FD');
  static final PdfColor accentBlue = PdfColor.fromHex('#1976D2');
  static final PdfColor softGreen = PdfColor.fromHex('#E8F5E9');
  static final PdfColor accentGreen = PdfColor.fromHex('#388E3C');
  static final PdfColor softLilac = PdfColor.fromHex('#F3E5F5');
  static final PdfColor accentLilac = PdfColor.fromHex('#7B1FA2');
  static final PdfColor softOrange = PdfColor.fromHex('#FFF3E0');
  static final PdfColor accentOrange = PdfColor.fromHex('#EF6C00');
  static final PdfColor softRed = PdfColor.fromHex('#FFEBEE');
  static final PdfColor accentRed = PdfColor.fromHex('#D32F2F');
  static final PdfColor neutralGrey = PdfColor.fromHex('#F5F5F5');

  PdfColor _withAlpha(PdfColor color, double alpha) =>
      PdfColor(color.red, color.green, color.blue, alpha);

  Future<pw.Document> generateSingleAnalysisReport({
    required PetProfileExtended profile,
    required AppLocalizations strings,
    AnaliseFeridaModel? specificWound,
  }) async {
    final pdf = pw.Document();

    // 1. Load Images
    pw.ImageProvider? profileImage;
    if (profile.imagePath != null && profile.imagePath!.isNotEmpty) {
      profileImage = await _safeLoadImage(profile.imagePath!,
          profilePetName: profile.petName);
    }

    pw.ImageProvider? analysisImage;
    if (specificWound != null && specificWound.imagemRef.isNotEmpty) {
      analysisImage = await _safeLoadImage(specificWound.imagemRef,
          profilePetName: profile.petName);
    }

    // 2. Build PDF
    final font = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    pdf.addPage(pw.Page(
      theme: pw.ThemeData.withFont(base: font, bold: fontBold),
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (context) {
        return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(profile, profileImage, strings),
              pw.SizedBox(height: 20),
              _buildSectionTitle(strings.pdfIdentitySection, strings),
              _buildIdentityTable(profile, strings),
              pw.SizedBox(height: 30),
              if (specificWound != null) ...[
                _buildSectionTitle(strings.pdfClinicalNotes, strings),
                pw.SizedBox(height: 10),
                (specificWound.categoria == 'fezes' ||
                        specificWound.categoria == 'stool')
                    ? _buildStoolItem(specificWound, analysisImage, strings)
                    : _buildWoundItem(specificWound, analysisImage, strings),
              ],
            ]);
      },
    ));

    return pdf;
  }

  /// 🛡️ NEW: Generate Dossier Report (Dossiê Veterinário 360°)
  /// Shows all data from the current analysis (not the full medical record)
  Future<pw.Document> generateDossierReport({
    required PetAnalysisResult analysis,
    required String imagePath,
    required AppLocalizations strings,
  }) async {
    final pdf = pw.Document();

    // 1. Load Images
    pw.ImageProvider? analysisImage = await _safeLoadImage(imagePath);

    // 2. Build PDF
    final font = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    final isDiagnosis = analysis.analysisType == 'diagnosis' ||
        analysis.analysisType == 'stool_analysis';

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            // Header
            _buildDossierHeader(analysis, analysisImage, strings),
            pw.SizedBox(height: 20),

            // Disclaimer
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: colorAccent),
              ),
              child: pw.Row(
                children: [
                  pw.Icon(const pw.IconData(0xe88e),
                      color: colorAccent, size: 16), // info icon
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: pw.Text(
                      strings.petDossierDisclaimer,
                      style: const pw.TextStyle(
                          fontSize: 10, color: PdfColors.grey800),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Identification Section (for ID analyses)
            if (!isDiagnosis) ...[
              _buildSectionTitle(
                  strings.petSectionIdentity.toUpperCase(), strings),
              pw.SizedBox(height: 10),
              _buildDossierIdentification(analysis, strings),
              pw.SizedBox(height: 20),

              // Nutrition
              _buildSectionTitle(
                  strings.petSectionNutrition.toUpperCase(), strings),
              pw.SizedBox(height: 10),
              _buildDossierNutrition(analysis, strings),
              pw.SizedBox(height: 20),

              // Grooming
              _buildSectionTitle(
                  strings.petSectionGrooming.toUpperCase(), strings),
              pw.SizedBox(height: 10),
              _buildDossierGrooming(analysis, strings),
              pw.SizedBox(height: 20),

              // Preventive Health
              _buildSectionTitle(
                  strings.petSectionPreventive.toUpperCase(), strings),
              pw.SizedBox(height: 10),
              _buildDossierHealth(analysis, strings),
              pw.SizedBox(height: 20),

              // Lifestyle
              _buildSectionTitle(
                  strings.petSectionLifestyle.toUpperCase(), strings),
              pw.SizedBox(height: 10),
              _buildDossierLifestyle(analysis, strings),
              pw.SizedBox(height: 20),

              // Behavior
              _buildSectionTitle('PERFIL COMPORTAMENTAL', strings),
              pw.SizedBox(height: 10),
              _buildDossierBehavior(analysis, strings),
              pw.SizedBox(height: 20),

              // Growth (if available)
              if (analysis.identificacao.curvaCrescimento.isNotEmpty) ...[
                _buildSectionTitle(
                    strings.petSectionGrowth.toUpperCase(), strings),
                pw.SizedBox(height: 10),
                _buildDossierGrowth(analysis, strings),
                pw.SizedBox(height: 20),
              ],
            ],

            // Clinical Section (for diagnosis)
            if (isDiagnosis) ...[
              _buildSectionTitle('SINAIS CLÍNICOS', strings),
              pw.SizedBox(height: 10),
              _buildDossierClinical(analysis, strings),
              pw.SizedBox(height: 20),
              _buildSectionTitle('DIAGNÓSTICOS PROVÁVEIS', strings),
              pw.SizedBox(height: 10),
              _buildDossierDiagnosis(analysis, strings),
              pw.SizedBox(height: 20),
              _buildSectionTitle('ORIENTAÇÕES', strings),
              pw.SizedBox(height: 10),
              pw.Text(analysis.orientacaoImediata,
                  style: const pw.TextStyle(fontSize: 11)),
            ],
          ];
        },
        footer: (context) => _buildFooter(context, strings),
      ),
    );

    return pdf;
  }

  // Helper methods for Dossier Report
  pw.Widget _buildDossierHeader(PetAnalysisResult analysis,
      pw.ImageProvider? image, AppLocalizations strings) {
    return pw.Row(
      children: [
        if (image != null)
          pw.Container(
            width: 80,
            height: 80,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              border: pw.Border.all(color: colorAccent, width: 2),
              image: pw.DecorationImage(image: image, fit: pw.BoxFit.cover),
            ),
          )
        else
          pw.Container(
            width: 80,
            height: 80,
            decoration: pw.BoxDecoration(
                color: colorPrimary, shape: pw.BoxShape.circle),
            child: pw.Center(
              child: pw.Text(
                analysis.petName?.isNotEmpty == true
                    ? analysis.petName![0].toUpperCase()
                    : '?',
                style: pw.TextStyle(
                    fontSize: 30,
                    fontWeight: pw.FontWeight.bold,
                    color: colorAccent),
              ),
            ),
          ),
        pw.SizedBox(width: 20),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              analysis.petName ?? 'Pet',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              strings.petDossierTitle,
              style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
            ),
            pw.Text(
              '${strings.pdfGeneratedOn}: ${DateFormat.yMd(strings.localeName).add_Hm().format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildDossierIdentification(
      PetAnalysisResult analysis, AppLocalizations strings) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        _buildTableRow(
            'Raça Predominante', analysis.identificacao.racaPredominante),
        _buildTableRow(
            'Linhagem SRD', analysis.identificacao.linhagemSrdProvavel),
        _buildTableRow(
            'Origem Geográfica', analysis.identificacao.origemGeografica),
        _buildTableRow(
            'Morfologia Base', analysis.identificacao.morfologiaBase),
        _buildTableRow('Porte Estimado', analysis.identificacao.porteEstimado),
        _buildTableRow(
            'Expectativa de Vida', analysis.identificacao.expectativaVidaMedia),
        _buildTableRow('Confiabilidade', analysis.reliability ?? 'N/A'),
      ],
    );
  }

  pw.Widget _buildDossierNutrition(
      PetAnalysisResult analysis, AppLocalizations strings) {
    final meta = analysis.nutricao.metaCalorica;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Meta Calórica (Adulto): ${meta['kcal_adulto'] ?? 'N/A'}',
            style: const pw.TextStyle(fontSize: 10)),
        pw.Text('Meta Calórica (Filhote): ${meta['kcal_filhote'] ?? 'N/A'}',
            style: const pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 5),
        pw.Text('Nutrientes Alvo:',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        pw.Text(analysis.nutricao.nutrientesAlvo.join(', '),
            style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  pw.Widget _buildDossierGrooming(
      PetAnalysisResult analysis, AppLocalizations strings) {
    final pelagem = analysis.higiene.manutencaoPelagem;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Tipo de Pelo: ${pelagem['tipo_pelo'] ?? 'N/A'}',
            style: const pw.TextStyle(fontSize: 10)),
        pw.Text(
            'Escovação Semanal: ${pelagem['frequencia_escovacao_semanal'] ?? 'N/A'}',
            style: const pw.TextStyle(fontSize: 10)),
        pw.Text('Alerta: ${pelagem['alerta_subpelo'] ?? 'N/A'}',
            style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  pw.Widget _buildDossierHealth(
      PetAnalysisResult analysis, AppLocalizations strings) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Predisposições:',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ...analysis.saude.predisposicaoDoencas.map(
            (d) => pw.Text('• $d', style: const pw.TextStyle(fontSize: 10))),
        pw.SizedBox(height: 5),
        pw.Text('Pontos Críticos Anatômicos:',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        pw.Text(analysis.saude.pontosCriticosAnatomicos.join(', '),
            style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  pw.Widget _buildDossierLifestyle(
      PetAnalysisResult analysis, AppLocalizations strings) {
    final ambiente = analysis.lifestyle.ambienteIdeal;
    final estimulo = analysis.lifestyle.estimuloMental;
    final treino = analysis.lifestyle.treinamento;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
            'Ambiente Ideal: ${ambiente['necessidade_de_espaco_aberto'] ?? 'N/A'}',
            style: const pw.TextStyle(fontSize: 10)),
        pw.Text(
            'Estímulo Mental: ${estimulo['necessidade_estimulo_mental'] ?? 'N/A'}',
            style: const pw.TextStyle(fontSize: 10)),
        pw.Text('Adestramento: ${treino['dificuldade_adestramento'] ?? 'N/A'}',
            style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  pw.Widget _buildDossierBehavior(
      PetAnalysisResult analysis, AppLocalizations strings) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
            'Personalidade: ${analysis.perfilComportamental.personalidade ?? 'N/A'}',
            style: const pw.TextStyle(fontSize: 10)),
        pw.Text(
            'Comportamento Social: ${analysis.perfilComportamental.comportamentoSocial ?? 'N/A'}',
            style: const pw.TextStyle(fontSize: 10)),
        pw.Text(
            'Energia: ${analysis.perfilComportamental.descricaoEnergia ?? 'N/A'}',
            style: const pw.TextStyle(fontSize: 10)),
        pw.Text(
            'Drive Ancestral: ${analysis.perfilComportamental.driveAncestral}',
            style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  pw.Widget _buildDossierGrowth(
      PetAnalysisResult analysis, AppLocalizations strings) {
    final curva = analysis.identificacao.curvaCrescimento;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Peso 3 Meses: ${curva['peso_3_meses'] ?? 'N/A'}',
            style: const pw.TextStyle(fontSize: 10)),
        pw.Text('Peso 6 Meses: ${curva['peso_6_meses'] ?? 'N/A'}',
            style: const pw.TextStyle(fontSize: 10)),
        pw.Text('Peso Adulto: ${curva['peso_adulto'] ?? 'N/A'}',
            style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  pw.Widget _buildDossierClinical(
      PetAnalysisResult analysis, AppLocalizations strings) {
    final signs = analysis.clinicalSignsDiag ?? {};
    if (signs.isEmpty) {
      return pw.Text('Nenhum sinal clínico detectado',
          style: const pw.TextStyle(fontSize: 10));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: signs.entries
          .map((e) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text('• ${e.key}: ${e.value}',
                    style: const pw.TextStyle(fontSize: 10)),
              ))
          .toList(),
    );
  }

  pw.Widget _buildDossierDiagnosis(
      PetAnalysisResult analysis, AppLocalizations strings) {
    if (analysis.possiveisCausas.isEmpty) {
      return pw.Text('Nenhum diagnóstico provável',
          style: const pw.TextStyle(fontSize: 10));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: analysis.possiveisCausas
          .map((d) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text('• $d', style: const pw.TextStyle(fontSize: 10)),
              ))
          .toList(),
    );
  }

  Future<pw.Document> generateReport({
    required PetProfileExtended profile,
    required AppLocalizations strings,
    PetAnalysisResult? currentAnalysis,
    List<File>? manualGallery,
    Map<String, DateTime>? vaccinationData,
  }) async {
    final pdf = pw.Document();
    debugPrint(
        '[PetPdfGeneratorV3] Starting modern redesign for ${profile.petName}');

    // 1. DATA PREPARATION & IMAGE LOADING
    pw.ImageProvider? profileImage;
    if (profile.imagePath != null && (profile.imagePath!.isNotEmpty)) {
      profileImage = await _safeLoadImage(profile.imagePath!);
    }

    final font = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();
    final materialIcons = await PdfGoogleFonts.materialIcons();

    // Health Status & Alerts Analysis
    final healthSummary = _analyzeHealthStatus(profile, strings);

    // 2. CAPA (COVER PAGE)
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Spacer(flex: 2),
              if (profileImage != null)
                pw.Center(
                  child: pw.Container(
                    width: 220,
                    height: 220,
                    decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        image: pw.DecorationImage(
                            image: profileImage, fit: pw.BoxFit.cover),
                        border: pw.Border.all(color: softBlue, width: 6),
                        boxShadow: const [
                          pw.BoxShadow(
                              color: PdfColors.grey300,
                              blurRadius: 10,
                              offset: PdfPoint(0, 5))
                        ]),
                  ),
                )
              else
                pw.Container(
                  width: 220,
                  height: 220,
                  decoration: pw.BoxDecoration(
                      color: softBlue, shape: pw.BoxShape.circle),
                  child: pw.Center(
                      child: pw.Text(
                          profile.petName.isNotEmpty
                              ? profile.petName[0].toUpperCase()
                              : '?',
                          style: pw.TextStyle(
                              fontSize: 80,
                              color: accentBlue,
                              fontWeight: pw.FontWeight.bold))),
                ),
              pw.SizedBox(height: 48),
              pw.Text(profile.petName,
                  style: pw.TextStyle(
                      fontSize: 42,
                      fontWeight: pw.FontWeight.bold,
                      color: accentBlue)),
              pw.SizedBox(height: 12),
              pw.Text("PRONTUÁRIO DO PET",
                  style: const pw.TextStyle(
                      fontSize: 22,
                      letterSpacing: 2,
                      color: PdfColors.grey600)),
              pw.SizedBox(height: 24),
              pw.Container(width: 80, height: 3, color: accentBlue),
              pw.SizedBox(height: 48),
              pw.Text("RELATÓRIO DE SAÚDE E BEM-ESTAR",
                  style: const pw.TextStyle(
                      fontSize: 14, color: PdfColors.grey500)),
              pw.Text(
                  "${strings.pdfGeneratedOn}: ${DateFormat.yMd('pt_BR').format(DateTime.now())}",
                  style: const pw.TextStyle(
                      fontSize: 12, color: PdfColors.grey400)),
              pw.Spacer(flex: 3),
              pw.Text("Gerado por ScanNut AI Intelligence",
                  style: pw.TextStyle(
                      fontSize: 10,
                      fontStyle: pw.FontStyle.italic,
                      color: PdfColors.grey400)),
            ],
          );
        },
      ),
    );

    // 3. MAIN CONTENT
    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(
            base: font, bold: fontBold, icons: materialIcons),
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        footer: (context) => _buildFooter(context, strings),
        build: (context) {
          return [
            // Row 1: Identity & Quick Health Summary
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                    flex: 3, child: _buildIdentificationCard(profile, strings)),
                pw.SizedBox(width: 20),
                pw.Expanded(
                    flex: 2,
                    child: _buildHealthSummaryCard(healthSummary, strings)),
              ],
            ),

            // Urgent Alerts (Conditional)
            if (healthSummary['alerts']!.isNotEmpty) ...[
              pw.SizedBox(height: 10),
              _buildAlertsCard(healthSummary['alerts']!, strings),
            ],

            pw.SizedBox(height: 20),

            // Section: Vaccines
            _buildSectionTitleInMini("VACINAÇÃO E PREVENÇÃO", accentLilac),
            _buildVaccinesCard(profile, strings, vaccinationData),

            pw.SizedBox(height: 20),

            // Section: Exams
            _buildSectionTitleInMini("HISTÓRICO DE EXAMES", accentGreen),
            _buildExamsOverviewCards(profile, strings),

            pw.SizedBox(height: 20),

            // Row 2: Nutrition & Behavior
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(child: _buildNutritionCard(profile, strings)),
                pw.SizedBox(width: 20),
                pw.Expanded(child: _buildBehaviorCard(profile, strings)),
              ],
            ),

            if (profile.observacoesSaude.isNotEmpty ||
                profile.observacoesPrac.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              _buildObservationsCard(profile, strings),
            ],
          ];
        },
      ),
    );

    return pdf;
  }

  // --- NEW CARD BUILDER UI HELPERS ---

  pw.Widget _buildCard(
      {required List<pw.Widget> children,
      PdfColor? color,
      PdfColor? borderColor}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: color ?? PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(16)),
        border:
            pw.Border.all(color: borderColor ?? PdfColors.grey200, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  pw.Widget _buildSectionTitleInMini(String title, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8, left: 4),
      child: pw.Text(title,
          style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: color,
              letterSpacing: 1.2)),
    );
  }

  pw.Widget _buildIdentificationCard(
      PetProfileExtended profile, AppLocalizations strings) {
    return _buildCard(
      color: softBlue,
      borderColor: _withAlpha(accentBlue, 0.2),
      children: [
        pw.Text("IDENTIFICAÇÃO",
            style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 13,
                color: accentBlue)),
        pw.SizedBox(height: 12),
        _buildDetailRow("Nome", profile.petName),
        _buildDetailRow("Espécie / Raça",
            "${profile.especie ?? 'Pet'} / ${profile.raca ?? 'SRD'}"),
        _buildDetailRow("Idade", profile.idadeExata ?? "Não informada"),
        _buildDetailRow("Peso Atual", "${profile.pesoAtual ?? '---'} kg"),
        _buildDetailRow("Sexo", _localizeSex(profile.sex, strings)),
        _buildDetailRow(
            "Microchip",
            profile.microchip?.isNotEmpty == true
                ? profile.microchip!
                : "Não possui"),
      ],
    );
  }

  pw.Widget _buildHealthSummaryCard(
      Map<String, List<String>> summary, AppLocalizations strings) {
    final status = summary['status']?.first ?? "---";
    final findings = summary['findings'] ?? [];
    final isOk = !status.toLowerCase().contains("pendente");

    return _buildCard(
      color: isOk ? softGreen : softOrange,
      borderColor:
          isOk ? _withAlpha(accentGreen, 0.2) : _withAlpha(accentOrange, 0.2),
      children: [
        pw.Text("RESUMO DE SAÚDE",
            style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 13,
                color: isOk ? accentGreen : accentOrange)),
        pw.SizedBox(height: 12),
        pw.Row(children: [
          pw.Text(status,
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                  color: isOk ? accentGreen : accentOrange)),
        ]),
        pw.SizedBox(height: 8),
        pw.Text("Principais Achados:",
            style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700)),
        if (findings.isEmpty)
          pw.Text("• Nenhum achado crítico",
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600))
        else
          ...findings.map((f) => pw.Text("• $f",
              style:
                  const pw.TextStyle(fontSize: 9, color: PdfColors.grey800))),
      ],
    );
  }

  pw.Widget _buildAlertsCard(List<String> alerts, AppLocalizations strings) {
    return _buildCard(
      color: softRed,
      borderColor: _withAlpha(accentRed, 0.3),
      children: [
        pw.Row(children: [
          pw.Text("ALERTAS IMPORTANTES",
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                  color: accentRed)),
        ]),
        pw.SizedBox(height: 8),
        ...alerts.map((a) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("⚠️ ", style: const pw.TextStyle(fontSize: 10)),
                  pw.Expanded(
                      child: pw.Text(a,
                          style: pw.TextStyle(
                              fontSize: 10,
                              color: accentRed,
                              fontWeight: pw.FontWeight.bold))),
                ],
              ),
            )),
      ],
    );
  }

  pw.Widget _buildVaccinesCard(PetProfileExtended profile,
      AppLocalizations strings, Map<String, DateTime>? vaccinationData) {
    // Process vaccines to get list
    final vaccines = _processVaccinationList(profile, strings, vaccinationData);

    return _buildCard(
      color: softLilac,
      borderColor: _withAlpha(accentLilac, 0.1),
      children: [
        pw.Text("CRONOGRAMA DE VACINAS",
            style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 12,
                color: accentLilac)),
        pw.SizedBox(height: 12),
        pw.Table(
          children: vaccines
              .map((v) => pw.TableRow(
                    children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 4),
                          child: pw.Text(v['name']!,
                              style: const pw.TextStyle(
                                  fontSize: 10, color: PdfColors.grey800))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 4),
                          child: pw.Text(v['date']!,
                              style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  color: v['isOverdue'] == 'true'
                                      ? accentRed
                                      : accentLilac))),
                    ],
                  ))
              .toList(),
        ),
      ],
    );
  }

  pw.Widget _buildExamsOverviewCards(
      PetProfileExtended profile, AppLocalizations strings) {
    // Categorize and analyze exams
    final exams = _analyzeExams(profile, strings);

    return pw.Row(
      children: [
        pw.Expanded(
            child: _buildSingleExamStatusCard(
                "Fezes", exams['stool']!, accentGreen)),
        pw.SizedBox(width: 12),
        pw.Expanded(
            child: _buildSingleExamStatusCard(
                "Urina", exams['urine']!, accentBlue)),
        pw.SizedBox(width: 12),
        pw.Expanded(
            child: _buildSingleExamStatusCard(
                "Sangue", exams['blood']!, accentLilac)),
      ],
    );
  }

  pw.Widget _buildSingleExamStatusCard(
      String title, Map<String, dynamic> data, PdfColor accentColor) {
    final status = data['status'] as String; // Normal, Atenção, Risco
    final desc = data['desc'] as String;

    PdfColor bgColor = PdfColors.grey50;
    PdfColor statusColor = PdfColors.grey800;
    String icon = "✔️";

    if (status == "Normal") {
      bgColor = softGreen;
      statusColor = accentGreen;
      icon = "✔️";
    } else if (status == "Atenção") {
      bgColor = softOrange;
      statusColor = accentOrange;
      icon = "⚠️";
    } else if (status == "Risco") {
      bgColor = softRed;
      statusColor = accentRed;
      icon = "❌";
    }

    return _buildCard(
      color: bgColor,
      borderColor: _withAlpha(statusColor, 0.2),
      children: [
        pw.Text(title.toUpperCase(),
            style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey600)),
        pw.SizedBox(height: 4),
        pw.Text("$icon $status",
            style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: statusColor)),
        pw.SizedBox(height: 6),
        pw.Text(desc,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            maxLines: 2),
      ],
    );
  }

  pw.Widget _buildNutritionCard(
      PetProfileExtended profile, AppLocalizations strings) {
    final allergens = profile.alergiasConhecidas;
    final restrictions = profile.restricoes;
    final preferences = profile.preferencias;

    return _buildCard(
      color: neutralGrey,
      children: [
        pw.Text("ALIMENTAÇÃO",
            style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 12,
                color: PdfColors.grey800)),
        pw.SizedBox(height: 12),
        _buildMiniSection(
            "Pode Comer:",
            preferences.isNotEmpty ? preferences.join(", ") : "Diversificado",
            accentGreen),
        pw.SizedBox(height: 8),
        _buildMiniSection(
            "NÃO Pode Comer:",
            (allergens + restrictions).isNotEmpty
                ? (allergens + restrictions).join(", ")
                : "Nenhuma restrição informada",
            accentRed),
      ],
    );
  }

  pw.Widget _buildBehaviorCard(
      PetProfileExtended profile, AppLocalizations strings) {
    final behavior = profile.rawAnalysis?['behavior'] ??
        profile.rawAnalysis?['temperamento'] ??
        {};
    final personality = behavior['personality'] ??
        behavior['personalidade'] ??
        "Dócil e Companheiro";

    return _buildCard(
      color: softBlue,
      children: [
        pw.Text("COMPORTAMENTO",
            style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 12,
                color: accentBlue)),
        pw.SizedBox(height: 12),
        _buildMiniSection("Emoção Detectada:", personality, accentBlue),
        pw.SizedBox(height: 8),
        _buildMiniSection(
            "Orientação:",
            "Mantenha rotina de exercícios e estímulos mentais.",
            PdfColors.grey700),
      ],
    );
  }

  pw.Widget _buildObservationsCard(
      PetProfileExtended profile, AppLocalizations strings) {
    return _buildCard(
      color: PdfColors.white,
      children: [
        pw.Text("CADERNO DE ANOTAÇÕES",
            style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 12,
                color: PdfColors.grey700)),
        pw.SizedBox(height: 8),
        pw.Text(
          "${profile.observacoesSaude}\n${profile.observacoesPrac}",
          style: pw.TextStyle(
              fontSize: 9,
              color: PdfColors.blueGrey800,
              fontStyle: pw.FontStyle.italic),
        ),
      ],
    );
  }

  pw.Widget _buildDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style:
                  const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black)),
        ],
      ),
    );
  }

  pw.Widget _buildMiniSection(String title, String content, PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title,
            style: pw.TextStyle(
                fontSize: 8, fontWeight: pw.FontWeight.bold, color: color)),
        pw.Text(content,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
      ],
    );
  }

  // --- DATA ANALYSIS BUSINESS LOGIC ---

  Map<String, List<String>> _analyzeHealthStatus(
      PetProfileExtended profile, AppLocalizations strings) {
    List<String> findings = [];
    List<String> alerts = [];
    bool vaccinesOk = true;

    if (profile.isVaccineOverdue(profile.dataUltimaV10) ||
        profile.isVaccineOverdue(profile.dataUltimaAntirrabica)) {
      vaccinesOk = false;
    }

    // Keyword Scanning
    bool hasGiardia = false;
    bool hasInfection = false;

    final allHistory = [
      ...profile.analysisHistory,
      ...profile.historicoAnaliseFeridas.map((e) => e.toJson())
    ];

    for (var item in allHistory) {
      final text = item.toString().toLowerCase();
      if (text.contains('giárdia') || text.contains('giardia')) {
        hasGiardia = true;
      }
      if (text.contains('urinária') ||
          text.contains('infecção') ||
          text.contains('hematúria')) {
        hasInfection = true;
      }
    }

    if (hasGiardia) {
      findings.add("Giárdia identificada no histórico");
      alerts.add("Tratar Giárdia conforme prescrição veterinária");
    }
    if (hasInfection) {
      findings.add("Sinais de infecção ou alteração urinária");
      alerts.add("Investigar possível infecção urinária");
    }
    if (!vaccinesOk) {
      alerts.add("Levar ao veterinário para atualização de vacinas");
    }

    for (var wound in profile.historicoAnaliseFeridas) {
      if (wound.nivelRisco.toLowerCase().contains('alto') ||
          wound.nivelRisco.toLowerCase().contains('vermelho')) {
        alerts.add("Atenção: Lesão de alto risco detectada");
        alerts.add("Urgência: Avaliação veterinária presencial necessária");
        break;
      }
    }

    return {
      'findings': findings,
      'alerts': alerts,
      'status': [vaccinesOk ? "Vacinas em dia" : "Vacinas em atraso"],
    };
  }

  List<Map<String, String>> _processVaccinationList(PetProfileExtended profile,
      AppLocalizations strings, Map<String, DateTime>? vaccinationData) {
    List<Map<String, String>> list = [];
    final species = profile.especie?.toLowerCase() ?? '';
    final isDog = species.contains('cão') ||
        species.contains('dog') ||
        species.contains('cachorro');

    final keys = isDog
        ? ['V8/V10 Canina', 'Raiva (Antirrábica)']
        : ['V3/V4/V5 Felina', 'Raiva (Antirrábica)'];

    for (var k in keys) {
      DateTime? date;
      if (k.contains('V')) {
        date = profile.dataUltimaV10;
      } else {
        date = profile.dataUltimaAntirrabica;
      }

      list.add({
        'name': k,
        'date': date != null ? DateFormat.yMd('pt_BR').format(date) : "PEDENTE",
        'isOverdue': profile.isVaccineOverdue(date).toString(),
      });
    }

    if (vaccinationData != null) {
      vaccinationData.forEach((key, value) {
        if (!keys.any((k) => key.contains(k.substring(0, 2)))) {
          list.add({
            'name': key,
            'date': DateFormat.yMd('pt_BR').format(value),
            'isOverdue': 'false'
          });
        }
      });
    }

    return list;
  }

  Map<String, Map<String, dynamic>> _analyzeExams(
      PetProfileExtended profile, AppLocalizations strings) {
    Map<String, Map<String, dynamic>> result = {
      'stool': {
        'status': 'Normal',
        'desc': 'Nenhuma alteração detectada nos registros.'
      },
      'urine': {'status': 'Normal', 'desc': 'Aparentemente normal.'},
      'blood': {'status': 'Normal', 'desc': 'Sem registros de alterações.'},
    };

    for (var exam in profile.labExams) {
      final cat = exam['category']?.toString().toLowerCase() ?? '';
      final explanation = exam['ai_explanation']?.toString() ?? '';
      final isRisk = explanation.toLowerCase().contains('risco') ||
          explanation.toLowerCase().contains('anormal');

      if (cat.contains('sangue') || cat.contains('blood')) {
        result['blood'] = {
          'status': isRisk ? 'Risco' : 'Atenção',
          'desc': explanation.length > 50
              ? '${explanation.substring(0, 50)}...'
              : explanation
        };
      } else if (cat.contains('urina') || cat.contains('urine')) {
        result['urine'] = {
          'status': isRisk ? 'Risco' : 'Atenção',
          'desc': explanation.length > 50
              ? '${explanation.substring(0, 50)}...'
              : explanation
        };
      }
    }

    for (var wound in profile.historicoAnaliseFeridas) {
      if (wound.categoria == 'fezes' || wound.categoria == 'stool') {
        final isRisk = wound.nivelRisco.toLowerCase().contains('alto') ||
            wound.nivelRisco.toLowerCase().contains('vermelho');
        result['stool'] = {
          'status': isRisk ? 'Risco' : 'Atenção',
          'desc': wound.recomendacao.length > 50
              ? '${wound.recomendacao.substring(0, 50)}...'
              : wound.recomendacao
        };
      }
    }

    return result;
  }

  // --- WIDGET BUILDERS ---

  pw.Widget _buildHeader(PetProfileExtended profile, pw.ImageProvider? image,
      AppLocalizations strings) {
    return pw.Row(children: [
      if (image != null)
        pw.Container(
            width: 80,
            height: 80,
            decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                border: pw.Border.all(color: colorAccent, width: 2),
                image: pw.DecorationImage(image: image, fit: pw.BoxFit.cover)))
      else
        pw.Container(
            width: 80,
            height: 80,
            decoration: pw.BoxDecoration(
                color: colorPrimary, shape: pw.BoxShape.circle),
            child: pw.Center(
                child: pw.Text(
                    profile.petName.isNotEmpty
                        ? profile.petName[0].toUpperCase()
                        : '?',
                    style: pw.TextStyle(
                        fontSize: 30,
                        fontWeight: pw.FontWeight.bold,
                        color: colorAccent)))),
      pw.SizedBox(width: 20),
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(profile.petName,
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
        pw.Text(strings.pdfReportTitle,
            style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
        pw.Text(
            '${strings.pdfGeneratedOn}: ${DateFormat.yMd(strings.localeName).add_Hm().format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
      ])
    ]);
  }

  pw.Widget _buildSectionTitle(String title, AppLocalizations strings) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: pw.BoxDecoration(
          color: colorPrimary,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
      child: pw.Text(title,
          style: pw.TextStyle(
              fontSize: 12, fontWeight: pw.FontWeight.bold, color: colorText)),
    );
  }

  pw.Widget _buildIdentityTable(
      PetProfileExtended profile, AppLocalizations strings) {
    final noInfo = strings.petNotOffice;
    return pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300),
        children: [
          _buildTableRow(strings.pdfFieldBreedSpecies,
              '${profile.especie ?? noInfo} / ${profile.raca ?? noInfo}'),
          _buildTableRow(strings.pdfFieldAge, profile.idadeExata ?? noInfo),
          _buildTableRow(strings.pdfFieldCurrentWeight,
              '${profile.pesoAtual ?? noInfo} kg (${strings.pdfFieldIdealWeight}: ${profile.pesoIdeal ?? noInfo} kg)'),
          _buildTableRow(
              '${strings.pdfFieldSex} / ${strings.pdfFieldReproductiveStatus}',
              '${_localizeSex(profile.sex, strings)} / ${_localizeReproStatus(profile.statusReprodutivo, strings)}'),
          if (profile.microchip != null && profile.microchip!.isNotEmpty)
            _buildTableRow(strings.pdfFieldMicrochip, profile.microchip!),
          _buildTableRow(strings.pdfFieldActivityLevel,
              _localizeActivityLevel(profile.nivelAtividade, strings)),
          _buildTableRow(strings.pdfFieldBathFrequency,
              _localizeBathFrequency(profile.frequenciaBanho, strings)),
        ]);
  }

  pw.TableRow _buildTableRow(String label, String value) {
    return pw.TableRow(children: [
      pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(label,
              style:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
      pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(value, style: const pw.TextStyle(fontSize: 10))),
    ]);
  }

  pw.Widget _buildPreferences(
      PetProfileExtended profile, AppLocalizations strings) {
    final noInfo = strings.petNotOffice;
    return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
              '${strings.settingsPreferences}: ${profile.preferencias.isNotEmpty ? profile.preferencias.join(", ") : noInfo}',
              style: const pw.TextStyle(fontSize: 10)),
          pw.Text(
              '${strings.dietaryRestrictions}: ${profile.restricoes.isNotEmpty ? profile.restricoes.join(", ") : noInfo}',
              style: pw.TextStyle(
                  fontSize: 10,
                  color: profile.restricoes.isNotEmpty
                      ? PdfColors.red900
                      : PdfColors.black)),
        ]);
  }

  pw.Widget _buildPartnersTable(
      List<Map<String, String>> partners, AppLocalizations strings) {
    return pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300),
        children: [
          pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(strings.pdfPartnerName,
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 9))),
                pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(strings.pdfPartnerSpecialty,
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 9))),
                pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(strings.pdfPartnerContact,
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 9))),
              ]),
          ...partners.map((p) => pw.TableRow(children: [
                pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(p['name']!,
                        style: const pw.TextStyle(fontSize: 9))),
                pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(p['category']!,
                        style: const pw.TextStyle(fontSize: 9))),
                pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (p['phone']!.isNotEmpty)
                            pw.Text('${strings.labelPhone}: ${p['phone']}',
                                style: const pw.TextStyle(fontSize: 9)),
                          if (p['email']!.isNotEmpty)
                            pw.Text('${strings.labelEmail}: ${p['email']}',
                                style: const pw.TextStyle(
                                    fontSize: 9, color: PdfColors.grey700)),
                          if (p['address']!.isNotEmpty)
                            pw.Text(p['address']!,
                                style: pw.TextStyle(
                                    fontSize: 8,
                                    fontStyle: pw.FontStyle.italic)),
                          if (p['notes'] != null && p['notes']!.isNotEmpty)
                            pw.Padding(
                                padding: const pw.EdgeInsets.only(top: 4),
                                child: pw.Text(
                                    '${strings.labelNotes}: ${p['notes']}',
                                    style: pw.TextStyle(
                                        fontSize: 8,
                                        color: PdfColors.blueGrey800,
                                        fontStyle: pw.FontStyle.italic)))
                        ])),
              ]))
        ]);
  }

  pw.Widget _buildNotesSection(
      PetProfileExtended profile, AppLocalizations strings) {
    final notes = [
      if (profile.observacoesIdentidade.isNotEmpty)
        '${strings.tabIdentity}: ${profile.observacoesIdentidade}',
      if (profile.observacoesSaude.isNotEmpty)
        '${strings.tabHealth}: ${profile.observacoesSaude}',
      if (profile.observacoesNutricao.isNotEmpty)
        '${strings.tabNutrition}: ${profile.observacoesNutricao}',
      if (profile.observacoesGaleria.isNotEmpty)
        '${strings.tabGrooming}: ${profile.observacoesGaleria}',
      if (profile.observacoesPrac.isNotEmpty)
        '${strings.pdfParcSection}: ${profile.observacoesPrac}',
    ];

    if (notes.isEmpty) {
      return pw.Text(strings.petNotOffice,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700));
    }

    return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: notes
            .map((n) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text('• $n',
                    style: const pw.TextStyle(
                        fontSize: 9, color: PdfColors.grey800))))
            .toList());
  }

  pw.Widget _buildVaccineTable(PetProfileExtended profile,
      AppLocalizations strings, Map<String, DateTime>? vaccinationData) {
    final rows = <pw.TableRow>[
      pw.TableRow(decoration: pw.BoxDecoration(color: colorPrimary), children: [
        pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Text(strings.pdfFieldEvent,
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                    color: colorText))),
        pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Text(strings.pdfDate,
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                    color: colorText)))
      ]),
    ];

    // 1. Determine Species & Expected Vaccines
    final species = profile.especie?.toLowerCase() ?? '';
    final isDog = species.contains('cão') ||
        species.contains('dog') ||
        species.contains('cachorro');

    final dogKeys = [
      'vaccineV8V10',
      'vaccineRabies',
      'vaccineFlu',
      'vaccineGiardia',
      'vaccineLeishmania'
    ];
    final catKeys = ['vaccineV3V4V5', 'vaccineRabies', 'vaccineFivFelv'];

    final expectedKeys = isDog ? dogKeys : catKeys;

    // Map keys to Localized Titles
    final keyToLabel = {
      'vaccineV8V10': strings.vaccineV8V10,
      'vaccineRabies': strings.vaccineRabies,
      'vaccineFlu': strings.vaccineFlu,
      'vaccineGiardia': strings.vaccineGiardia,
      'vaccineLeishmania': strings.vaccineLeishmania,
      'vaccineV3V4V5': strings.vaccineV3V4V5,
      'vaccineFivFelv': strings.vaccineFivFelv,
    };

    // 2. Build rows for Expected Vaccines
    final processedTitles = <String>{};

    for (var key in expectedKeys) {
      final label = keyToLabel[key] ?? key;
      processedTitles.add(label);

      DateTime? date;
      // Strategy: event titles are generally localized. We match exact string.
      // If null, check case-insensitive match from vaccinationData keys
      if (vaccinationData != null) {
        if (vaccinationData.containsKey(label)) {
          date = vaccinationData[label];
        } else {
          // Try fuzzy match
          final match = vaccinationData.keys.firstWhere(
              (k) => k.toLowerCase().trim() == label.toLowerCase().trim(),
              orElse: () => '');
          if (match.isNotEmpty) date = vaccinationData[match];
        }
      }

      // Fallback legacy for specific keys if data missing
      if (date == null) {
        if (key == 'vaccineV8V10' || key == 'vaccineV3V4V5') {
          date = profile.dataUltimaV10;
        }
        if (key == 'vaccineRabies') date = profile.dataUltimaAntirrabica;
      }

      rows.add(_buildTableRow(
          label,
          date != null
              ? DateFormat.yMd(strings.localeName).format(date)
              : strings.pdfPending));
    }

    // 3. Add any EXTRA vaccines found in vaccinationData but not in expected list
    if (vaccinationData != null) {
      vaccinationData.forEach((key, date) {
        // Check if already key-matched or title-matched
        final normalizedKey = key.toLowerCase().trim();
        bool alreadyShown =
            processedTitles.any((t) => t.toLowerCase().trim() == normalizedKey);

        if (!alreadyShown) {
          rows.add(_buildTableRow(
              key, DateFormat.yMd(strings.localeName).format(date)));
        }
      });
    }

    return pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300), children: rows);
  }

  pw.Widget _buildWeightSection(
      PetProfileExtended profile, AppLocalizations strings) {
    if (profile.weightHistory.isEmpty) {
      return pw.Text('${strings.pdfWeightHistory}: ${strings.pdfNoInfo}',
          style: const pw.TextStyle(fontSize: 10));
    }
    return pw.Row(children: [
      pw.Text('${strings.pdfWeightHistory} (${profile.weightHistory.length}): ',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
      pw.Text(
          profile.weightHistory
              .take(10)
              .map((e) => '${e['weight']}kg')
              .join(' → '),
          style: const pw.TextStyle(fontSize: 10)),
    ]);
  }

  pw.Widget _buildAllergies(
      PetProfileExtended profile, AppLocalizations strings) {
    if (profile.alergiasConhecidas.isEmpty) {
      return pw.Text('${strings.pdfKnownAllergies}: ${strings.pdfNoInfo}',
          style: const pw.TextStyle(fontSize: 10));
    }
    return pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.red),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
        child: pw.Text(
            '${strings.pdfKnownAllergies}: ${profile.alergiasConhecidas.join(", ")}',
            style: pw.TextStyle(
                color: PdfColors.red,
                fontWeight: pw.FontWeight.bold,
                fontSize: 10)));
  }

  pw.Widget _buildWoundItem(AnaliseFeridaModel item, pw.ImageProvider? image,
      AppLocalizations strings) {
    final dateStr = DateFormat.yMd(strings.localeName).format(item.dataAnalise);
    PdfColor riskColor = PdfColors.green;
    if (item.nivelRisco.toLowerCase().contains('alto') ||
        item.nivelRisco.toLowerCase().contains('vermelho')) {
      riskColor = PdfColors.red;
    }
    if (item.nivelRisco.toLowerCase().contains('médio') ||
        item.nivelRisco.toLowerCase().contains('amarelo')) {
      riskColor = PdfColors.orange;
    }

    return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 12),
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
        child:
            pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          if (image != null)
            pw.Container(
                width: 70,
                height: 70,
                margin: const pw.EdgeInsets.only(right: 10),
                child: pw.Image(image, fit: pw.BoxFit.contain)),
          pw.Expanded(
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                pw.Row(children: [
                  pw.Text(dateStr,
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.SizedBox(width: 10),
                  pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: pw.BoxDecoration(
                          color: riskColor,
                          borderRadius:
                              const pw.BorderRadius.all(pw.Radius.circular(2))),
                      child: pw.Text(item.nivelRisco.toUpperCase(),
                          style: const pw.TextStyle(
                              color: PdfColors.white, fontSize: 8)))
                ]),
                pw.SizedBox(height: 4),
                pw.Text(
                    '${strings.termDiagnosis}: ${_localizeDiagnosisList(item.diagnosticosProvaveis, strings).join(", ")}',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 9)),
                if (item.descricaoVisual != null &&
                    item.descricaoVisual!.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(item.descricaoVisual!,
                      style: pw.TextStyle(
                          fontSize: 8, fontStyle: pw.FontStyle.italic),
                      maxLines: 6),
                ],
                pw.SizedBox(height: 4),
                pw.Text(item.recomendacao,
                    style: const pw.TextStyle(fontSize: 9), maxLines: 6),
              ]))
        ]));
  }

  pw.Widget _buildStoolItem(AnaliseFeridaModel item, pw.ImageProvider? image,
      AppLocalizations strings) {
    final dateStr = DateFormat.yMd(strings.localeName).format(item.dataAnalise);
    PdfColor riskColor = PdfColors.green;
    if (item.nivelRisco.toLowerCase().contains('alto') ||
        item.nivelRisco.toLowerCase().contains('vermelho')) {
      riskColor = PdfColors.red;
    }
    if (item.nivelRisco.toLowerCase().contains('médio') ||
        item.nivelRisco.toLowerCase().contains('amarelo')) {
      riskColor = PdfColors.orange;
    }

    return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 12),
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
        child:
            pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          if (image != null)
            pw.Container(
                width: 70,
                height: 70,
                margin: const pw.EdgeInsets.only(right: 10),
                child: pw.Image(image, fit: pw.BoxFit.contain)),
          pw.Expanded(
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                pw.Row(children: [
                  pw.Text(
                      '$dateStr - Bristol ${item.achadosVisuais['bristol_scale'] ?? "-"}',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.SizedBox(width: 10),
                  pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: pw.BoxDecoration(
                          color: riskColor,
                          borderRadius:
                              const pw.BorderRadius.all(pw.Radius.circular(2))),
                      child: pw.Text(item.nivelRisco.toUpperCase(),
                          style: const pw.TextStyle(
                              color: PdfColors.white, fontSize: 8)))
                ]),
                pw.SizedBox(height: 4),
                if (item.diagnosticosProvaveis.isNotEmpty)
                  pw.Text(
                      '${strings.pdfCauses}: ${_localizeDiagnosisList(item.diagnosticosProvaveis, strings).join(", ")}',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 9)),
                if (item.descricaoVisual != null &&
                    item.descricaoVisual!.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(item.descricaoVisual!,
                      style: pw.TextStyle(
                          fontSize: 8, fontStyle: pw.FontStyle.italic),
                      maxLines: 6),
                ],
                pw.SizedBox(height: 4),
                pw.Text(item.recomendacao,
                    style: const pw.TextStyle(fontSize: 9), maxLines: 6),
              ]))
        ]));
  }

  pw.Widget _buildLabItem(
      LabExam item, pw.ImageProvider? image, AppLocalizations strings) {
    final dateStr = DateFormat.yMd(strings.localeName).format(item.uploadDate);
    return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 12),
        child: pw.Row(children: [
          if (image != null)
            pw.Container(
                width: 70,
                height: 70,
                margin: const pw.EdgeInsets.only(right: 10),
                child: pw.Image(image, fit: pw.BoxFit.contain)),
          pw.Expanded(
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                pw.Text(
                    '$dateStr - ${_localizeLabCategory(item.category, strings).toUpperCase()}',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 10)),
                if (item.aiExplanation != null)
                  pw.Container(
                      margin: const pw.EdgeInsets.only(top: 4),
                      padding: const pw.EdgeInsets.all(6),
                      decoration: const pw.BoxDecoration(
                          color: PdfColors.grey100,
                          borderRadius:
                              pw.BorderRadius.all(pw.Radius.circular(4))),
                      child: pw.Text(item.aiExplanation!.replaceAll('\n', ' '),
                          style: const pw.TextStyle(
                              fontSize: 8, color: PdfColors.black)))
              ]))
        ]));
  }

  pw.Widget _buildNutritionSection(
      PetProfileExtended profile, AppLocalizations strings,
      {List<dynamic> recommendedBrands = const [], WeeklyMealPlan? fullPlan}) {
    final diet = fullPlan?.dietType ??
        profile.rawAnalysis?['tipo_dieta'] ??
        strings.fallbackNoInfo;
    final plan = fullPlan?.meals ?? profile.rawAnalysis?['plano_semanal'];

    final nutritionData = profile.rawAnalysis?['nutrition'];
    String? kcal;
    if (nutritionData != null && nutritionData is Map) {
      final kA = nutritionData['kcal_adult'] ?? nutritionData['kcal_adulto'];
      if (kA != null) kcal = '$kA ${strings.unitKcalPerDay}';
    }

    return pw
        .Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Row(children: [
        pw.Text('${strings.pdfDietType}: $diet',
            style: const pw.TextStyle(fontSize: 10)),
        if (kcal != null) ...[
          pw.SizedBox(width: 20),
          pw.Text('${strings.pdfCaloricGoal}: $kcal',
              style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green700)),
        ]
      ]),
      if (plan != null && plan is List && plan.isNotEmpty) ...[
        pw.SizedBox(height: 10),
        pw.Text(strings.pdfWeeklyPlan,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 5),
        pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(strings.pdfDay,
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 8))),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(strings.pdfMeal,
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 8))),
                  ]),
              if (fullPlan != null)
                ...fullPlan.meals.map((m) {
                  final dayNames = [
                    'Seg',
                    'Ter',
                    'Qua',
                    'Qui',
                    'Sex',
                    'Sab',
                    'Dom'
                  ];
                  final day = dayNames[m.dayOfWeek - 1];
                  return pw.TableRow(children: [
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(day,
                            style: const pw.TextStyle(fontSize: 8))),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                            '${m.title}: ${m.description} (${m.quantity})',
                            style: const pw.TextStyle(fontSize: 8))),
                  ]);
                })
              else
                ...plan.map((e) {
                  final day = e['dia']?.toString() ?? '-';
                  final refeicoes = (e['refeicoes'] as List?)
                          ?.map((r) => r['descricao']?.toString() ?? '')
                          .join('\n') ??
                      (e['descricao']?.toString() ?? '-');
                  return pw.TableRow(children: [
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(day,
                            style: const pw.TextStyle(fontSize: 8))),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(refeicoes,
                            style: const pw.TextStyle(fontSize: 8))),
                  ]);
                })
            ])
      ],

      // 🛡️ NEW: Seção de Sugestões de Marcas (Atualizado para BrandSuggestion)
      if (recommendedBrands.isNotEmpty) ...[
        pw.SizedBox(height: 15),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#E8F5E9'), // Light green background
            border:
                pw.Border.all(color: PdfColor.fromHex('#4CAF50'), width: 1.0),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  pw.Container(
                    width: 16,
                    height: 16,
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#4CAF50'),
                      shape: pw.BoxShape.circle,
                    ),
                    child: pw.Center(
                      child: pw.Text('i',
                          style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold)),
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Text(strings.pdfBrandSuggestions,
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                          color: PdfColor.fromHex('#2E7D32'))),
                ],
              ),
              pw.SizedBox(height: 10),
              ...recommendedBrands.map((item) {
                // 🛡️ Logica de extração híbrida (String vs BrandSuggestion)
                String brandName;
                String? reason;
                if (item is String) {
                  brandName = item;
                } else if (item is BrandSuggestion) {
                  brandName = item.brand;
                  reason = item.reason;
                } else {
                  brandName = item.toString();
                }

                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8, left: 24),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('• ',
                          style: pw.TextStyle(
                              fontSize: 10,
                              color: PdfColor.fromHex('#4CAF50'),
                              fontWeight: pw.FontWeight.bold)),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(brandName,
                                style: pw.TextStyle(
                                    fontSize: 10,
                                    color: PdfColors.black,
                                    fontWeight: pw.FontWeight.bold)),
                            if (reason != null && reason.isNotEmpty)
                              pw.Text(reason,
                                  style: pw.TextStyle(
                                      fontSize: 9,
                                      color: PdfColors.grey700,
                                      fontStyle: pw.FontStyle.italic)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex(
                      '#FFF9C4'), // Light yellow for disclaimer
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  strings.pdfLegalDisclaimer,
                  style: pw.TextStyle(
                      fontSize: 8,
                      fontStyle: pw.FontStyle.italic,
                      color: PdfColors.black),
                ),
              ),
            ],
          ),
        ),
      ],
    ]);
  }

  pw.Widget _buildGalleryGrid(
      List<Map<String, dynamic>> items, AppLocalizations strings) {
    return pw.Wrap(
        spacing: 10,
        runSpacing: 10,
        children: items.map((e) {
          final image = e['image'] as pw.ImageProvider;
          final date =
              DateFormat.yMd(strings.localeName).format(e['date'] as DateTime);
          final label = e['label'] as String;
          return pw.Container(
              width: 140,
              height: 160,
              decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(4))),
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                        child: pw.ClipRRect(
                            horizontalRadius: 4,
                            verticalRadius: 4,
                            child: pw.Image(image, fit: pw.BoxFit.cover))),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('$date\n$label',
                            style: const pw.TextStyle(fontSize: 9)))
                  ]));
        }).toList());
  }

  pw.Widget _buildFooter(pw.Context context, AppLocalizations strings) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300, thickness: 0.5),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              '“Este relatório é informativo e não substitui avaliação veterinária.”',
              style: pw.TextStyle(
                  fontSize: 8,
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.grey600),
            ),
            pw.Text(
              'Página ${context.pageNumber} de ${context.pagesCount} | ScanNut AI Engine',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
            ),
          ],
        ),
      ],
    );
  }

  Future<pw.ImageProvider?> _safeLoadImage(String pathStr,
      {String? profilePetName}) async {
    if (pathStr.isEmpty) return null;
    String cleanPath = pathStr;
    if (cleanPath.startsWith('file://')) cleanPath = cleanPath.substring(7);

    debugPrint('🖼️ [PDF] Attempting to load: $cleanPath');
    File file = File(cleanPath);

    if (!await file.exists()) {
      try {
        // 🛡️ V_FIX: Check both Support and Documents directories (Vault vs Legacy)
        final docs = await getApplicationDocumentsDirectory();
        final support = await getApplicationSupportDirectory();
        final basename = path.basename(cleanPath);

        // Try Support (Vault) first
        final vaultPath = path.join(support.path, 'media_vault', 'pets',
            profilePetName ?? '', basename);
        final vFile = File(vaultPath);

        if (await vFile.exists()) {
          file = vFile;
          debugPrint('✨ [PDF] Recovered from Vault: ${file.path}');
        } else {
          // Try Documents (Legacy)
          final legacyPath = path.join(
              docs.path, 'medical_docs', profilePetName ?? '', basename);
          final lFile = File(legacyPath);
          if (await lFile.exists()) {
            file = lFile;
            debugPrint('✨ [PDF] Recovered from Legacy: ${file.path}');
          } else {
            debugPrint('❌ [PDF] File not found in Vault or Legacy: $basename');
            return null;
          }
        }
      } catch (e) {
        debugPrint('⚠️ [PDF] Path recovery error: $e');
        return null;
      }
    }

    try {
      final opt = await ImageOptimizationService()
          .loadOptimizedBytes(originalPath: file.path);
      if (opt != null) return pw.MemoryImage(opt);
      return pw.MemoryImage(await file.readAsBytes());
    } catch (e) {
      debugPrint('❌ [PDF] Error reading bytes: $e');
    }
    return null;
  }

  String _localizeSex(String? sex, AppLocalizations strings) {
    if (sex == null) return '-';
    final s = sex.toLowerCase();
    if (s == 'male' || s == 'macho') return strings.gender_male;
    if (s == 'female' || s == 'fêmea' || s == 'femea') {
      return strings.gender_female;
    }
    return sex;
  }

  String _localizeReproStatus(String? status, AppLocalizations strings) {
    if (status == null) return '-';
    final s = status.toLowerCase();
    if (s.contains('castrado') || s.contains('neutered')) {
      return strings.petNeutered;
    }
    if (s.contains('inteiro') || s.contains('intacto') || s.contains('intact')) {
      return strings.petIntact;
    }
    return status;
  }

  String _localizeActivityLevel(String? level, AppLocalizations strings) {
    if (level == null) return '-';
    final l = level.toLowerCase();
    if (l.contains('baixo') || l.contains('low') || l.contains('sedentário')) {
      return strings.petActivityLow;
    }
    if (l.contains('moderado') || l.contains('moderate')) {
      return strings.petActivityModerate;
    }
    if (l.contains('ativo') || l.contains('alto') || l.contains('high')) {
      return strings.petActivityHigh;
    }
    if (l.contains('atleta') || l.contains('athlete')) {
      return strings.petActivityAthlete;
    }
    return level;
  }

  String _localizeBathFrequency(String? freq, AppLocalizations strings) {
    if (freq == null) return '-';
    final f = freq.toLowerCase();
    if (f.contains('semanal') || f.contains('weekly')) {
      return strings.petBathWeekly;
    }
    if (f.contains('quinzenal') || f.contains('biweekly')) {
      return strings.labelFortnightly;
    }
    if (f.contains('mensal') || f.contains('monthly')) {
      return strings.petBathMonthly;
    }
    return freq;
  }

  String _localizeLabCategory(String cat, AppLocalizations strings) {
    final c = cat.toLowerCase();
    if (c.contains('blood') || c.contains('sangue')) {
      return strings.labCategoryBlood;
    }
    if (c.contains('urine') || c.contains('urina')) {
      return strings.labCategoryUrine;
    }
    if (c.contains('fezes') || c.contains('stool')) {
      return strings.labCategoryFeces;
    }
    if (c.contains('ultras') ||
        c.contains('raio') ||
        c.contains('x-ray') ||
        c.contains('image')) {
      return strings.labCategoryImaging;
    }
    return cat;
  }

  List<String> _localizeDiagnosisList(
      List<String> input, AppLocalizations strings) {
    final map = {
      'obesity': strings.diagnosisObesity,
      'overweight': strings.diagnosisOverweight,
      'underweight': strings.diagnosisUnderweight,
      'dermatitis': strings.diagnosisDermatitis,
      'disbiosis': strings.diagnosisDysbiosis,
      'parasites': strings.diagnosisParasites,
      'infection': strings.diagnosisInfection,
      'inflammation': strings.diagnosisInflammation,
      'tartar': strings.diagnosisTartar,
      'gingivitis': strings.diagnosisGingivitis,
      'plaque': strings.diagnosisPlaque,
      'mass': strings.diagnosisMass,
      'tumor': strings.diagnosisTumor,
      'allergy': strings.diagnosisAllergy,
      'anemia': strings.diagnosisAnemia,
      'fracture': strings.diagnosisFracture,
      'pain': strings.diagnosisPain,
      'fever': 'Febre',
      'vomiting': 'Vômito',
      'diarrhea': 'Diarreia',
    };
    return input.map((e) {
      final low = e.toLowerCase().trim();
      for (var k in map.keys) {
        if (low == k || low.contains(k)) return map[k]!;
      }
      return e;
    }).toList();
  }

  pw.Widget _buildPlansSection(
      PetProfileExtended profile, AppLocalizations strings) {
    final activePlans = [];
    if (profile.healthPlan?['active'] == true) {
      activePlans.add({'type': 'health', 'data': profile.healthPlan});
    }
    if (profile.assistancePlan?['active'] == true) {
      activePlans.add({'type': 'assistance', 'data': profile.assistancePlan});
    }
    if (profile.funeralPlan?['active'] == true) {
      activePlans.add({'type': 'funeral', 'data': profile.funeralPlan});
    }
    if (profile.lifeInsurance?['active'] == true) {
      activePlans.add({'type': 'life', 'data': profile.lifeInsurance});
    }

    if (activePlans.isEmpty && profile.observacoesPlanos.isEmpty) {
      return pw.Text('Sem planos ativos ou observações.',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700));
    }

    return pw
        .Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      ...activePlans.map((p) {
        final type = p['type'] as String;
        final data = p['data'] as Map<String, dynamic>;

        String title = '';
        List<String> details = [];

        if (type == 'health') {
          title = 'SAÚDE VETERINÁRIA';
          final name = data['name'] ?? '-';
          details.add('Operadora: $name');
          if (data['monthly_value'] != null) {
            details.add('Mensalidade: R\$ ${data['monthly_value']}');
          }

          String planType = data['type'] == 'reimbursement'
              ? 'Reembolso'
              : 'Rede Credenciada';
          details.add('Tipo: $planType');

          List<String> coverage = [];
          if (data['covers_consults'] == true) coverage.add('Consultas');
          if (data['covers_exams'] == true) coverage.add('Exames');
          if (data['covers_surgeries'] == true) coverage.add('Cirurgias');
          if (data['covers_emergencies'] == true) coverage.add('Emergências');
          if (data['covers_hospitalization'] == true) {
            coverage.add('Internação');
          }
          if (data['covers_vaccines'] == true) coverage.add('Vacinas');
          if (coverage.isNotEmpty) {
            details.add('Cobertura: ${coverage.join(", ")}');
          }
        } else if (type == 'assistance') {
          title = 'ASSISTÊNCIA / REEMBOLSO';
          final name = data['name'] ?? '-';
          details.add('Operadora: $name');
          if (data['max_value'] != null) {
            details.add('Limite Máximo: R\$ ${data['max_value']}');
          }

          String rType =
              data['reimbursement_type'] == 'partial' ? 'Parcial' : 'Total';
          details.add('Reembolso: $rType');
          if (data['needs_invoice'] == true) {
            details.add('Exige Nota Fiscal: Sim');
          }
        } else if (type == 'funeral') {
          title = 'PLANO FUNERÁRIO';
          final name = data['name'] ?? '-';
          details.add('Operadora: $name');
          if (data['emergency_contact'] != null) {
            details.add('Contato 24h: ${data['emergency_contact']}');
          }
          if (data['support_24h'] == true) details.add('Suporte 24h: Sim');

          List<String> svcs = [];
          if (data['incl_wake'] == true) svcs.add('Velório');
          if (data['incl_crem_indiv'] == true) svcs.add('Cremação Indiv.');
          if (data['incl_crem_coll'] == true) svcs.add('Cremação Coletiva');
          if (data['incl_transport'] == true) svcs.add('Translado');
          if (data['incl_memorial'] == true) svcs.add('Memorial');
          if (svcs.isNotEmpty) details.add('Serviços: ${svcs.join(", ")}');
        } else if (type == 'life') {
          title = 'SEGURO DE VIDA';
          final name = data['insurer'] ?? '-';
          details.add('Seguradora: $name');
          if (data['insured_value'] != null) {
            details.add('Capital Segurado: R\$ ${data['insured_value']}');
          }
          if (data['has_economic_value'] == true) {
            details.add('Possui Valor Econômico: Sim');
          }

          List<String> covs = [];
          if (data['cov_death'] == true) covs.add('Morte Acidental/Natural');
          if (data['cov_illness'] == true) covs.add('Doenças Graves');
          if (data['cov_euthanasia'] == true) covs.add('Eutanásia');
          if (covs.isNotEmpty) details.add('Coberturas: ${covs.join(", ")}');
        }

        return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 12),
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(title,
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                          color: colorAccent)),
                  pw.SizedBox(height: 4),
                  ...details.map((d) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 2),
                      child:
                          pw.Text(d, style: const pw.TextStyle(fontSize: 9)))),
                ]));
      }),
      if (profile.observacoesPlanos.isNotEmpty) ...[
        pw.SizedBox(height: 10),
        pw.Text('Observações de Planos:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        pw.Text(profile.observacoesPlanos,
            style: const pw.TextStyle(fontSize: 10)),
      ]
    ]);
  }

  pw.Widget _buildTravelSection(
      PetProfileExtended profile, AppLocalizations strings,
      {Map<String, DateTime>? vaccinationData}) {
    final prefs = profile.travelPreferences;
    final hasMicrochip = profile.microchip?.isNotEmpty == true;

    // 🛡️ Resolve Rabies Date (Event Priority)
    DateTime? rabiesDate = profile.dataUltimaAntirrabica;
    if (vaccinationData != null) {
      // Check for localized rabies key in vaccination events
      final label = strings.vaccineRabies;
      if (vaccinationData.containsKey(label)) {
        rabiesDate = vaccinationData[label];
      } else {
        // Secondary fallback search
        final match = vaccinationData.keys.firstWhere(
            (k) =>
                k.toLowerCase().contains('rabies') ||
                k.toLowerCase().contains('raiva') ||
                k.toLowerCase().contains('antirrábica'),
            orElse: () => '');
        if (match.isNotEmpty) rabiesDate = vaccinationData[match];
      }
    }

    bool isRabiesVaxValid = false;
    if (rabiesDate != null) {
      final diff = DateTime.now().difference(rabiesDate);
      isRabiesVaxValid = diff.inDays >= 30 && diff.inDays <= 365;
    }

    // Section is only "empty" if absolutely no travel info exists
    if (prefs.isEmpty && !hasMicrochip && rabiesDate == null) {
      return pw.Text(strings.fallbackNoInfo,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700));
    }

    final mode = _localizeTravelValue(prefs['mode']?.toString(), strings);
    final scope = _localizeTravelValue(prefs['scope']?.toString(), strings);

    // Checklist items
    final List<String> basicItems = [];
    if (prefs['has_safety_belt'] == true) {
      basicItems.add(strings.petTravelSafetyBelt);
    }
    if (prefs['has_health_cert'] == true || isRabiesVaxValid) {
      basicItems.add(strings.petTravelHealthCert);
    }
    if (prefs['has_czi'] == true) basicItems.add(strings.petTravelCZI);
    if (hasMicrochip || prefs['has_microchip'] == true) {
      basicItems.add(strings.petTravelMicrochip);
    }

    // --- INTELLIGENT CHECKLIST MOTOR ---
    final List<_TravelImpactItem> intelligentItems = [];

    if (profile.analysisHistory.isEmpty &&
        profile.labExams.isEmpty &&
        profile.historicoAnaliseFeridas.isEmpty) {
      intelligentItems.add(
          _TravelImpactItem(strings.petTravelHealthCheckup, isWarning: true));
    } else {
      // 1. Parasites
      bool hasParasites = false;
      for (var a in profile.analysisHistory) {
        final diag = a['diagnostico_provavel']?.toString().toLowerCase() ?? '';
        if (diag.contains('parasita') ||
            diag.contains('giárdia') ||
            diag.contains('pulga') ||
            diag.contains('verme')) {
          hasParasites = true;
          break;
        }
      }
      for (var w in profile.historicoAnaliseFeridas) {
        final cat = w.categoria?.toLowerCase() ?? '';
        if (cat == 'fezes' || cat == 'stool') {
          final desc = w.diagnosticosProvaveis.join(' ').toLowerCase();
          if (desc.contains('parasita') ||
              desc.contains('giárdia') ||
              desc.contains('verme')) {
            hasParasites = true;
            break;
          }
        }
      }
      if (hasParasites) {
        intelligentItems.add(_TravelImpactItem(strings.petTravelHygieneKit,
            isWarning: true, subtitle: 'Identificado no historial recente'));
      }

      // 2. Infection/Inflammation
      bool hasInfection = false;
      for (var lab in profile.labExams) {
        final findings = lab['achados']?.toString().toLowerCase() ?? '';
        if (findings.contains('leucocitose') ||
            findings.contains('hematúria') ||
            findings.contains('infecção') ||
            findings.contains('inflamação')) {
          hasInfection = true;
          break;
        }
      }
      if (hasInfection) {
        intelligentItems.add(_TravelImpactItem(
            strings.petTravelHydrationMonitoring,
            isWarning: true,
            subtitle: 'Baseado em exames laboratoriais'));
      }

      // 3. Health Score / Dehydration
      bool needsRest = false;
      for (var a in profile.analysisHistory) {
        final recommendations =
            a['orientacao_imediata']?.toString().toLowerCase() ?? '';
        if (recommendations.contains('desidratação') ||
            recommendations.contains('repouso')) {
          needsRest = true;
          break;
        }
      }
      if (needsRest) {
        intelligentItems.add(
            _TravelImpactItem(strings.petTravelRestSupport, isWarning: true));
      }

      // 4. Diet
      bool needsPremiumFood = false;
      for (var a in profile.analysisHistory) {
        final diet =
            a['nutricao']?['regime_alimentar']?.toString().toLowerCase() ?? '';
        if (diet.contains('standard') || diet.contains('desbalanceada')) {
          needsPremiumFood = true;
          break;
        }
      }
      if (needsPremiumFood) {
        intelligentItems
            .add(_TravelImpactItem(strings.petTravelPremiumFoodKit));
      }
    }

    // 5. Standard Educational Items
    intelligentItems.add(_TravelImpactItem(strings.petTravelMedicationActive,
        subtitle: strings.petTravelMedicationActiveDesc));
    intelligentItems.add(_TravelImpactItem(strings.petTravelWaterMineral,
        subtitle: strings.petTravelWaterMineralDesc));
    intelligentItems.add(_TravelImpactItem(strings.petTravelTacticalStops,
        subtitle: strings.petTravelTacticalStopsDesc));

    // --- VACCINATION GUIDE ---
    final List<_EducationalGuideItem> vaccineGuide = [];
    final String speciesLower = profile.especie?.toLowerCase() ?? '';
    final bool isDog = speciesLower.contains('cão') ||
        speciesLower.contains('cao') ||
        speciesLower.contains('dog');
    final bool isCat =
        speciesLower.contains('gato') || speciesLower.contains('cat');

    if (isDog) {
      vaccineGuide.add(
          _EducationalGuideItem('V8/V10 (Cães)', strings.petTravelV8V10Desc));
      vaccineGuide.add(_EducationalGuideItem(
          'Gripe/Bordetella', strings.petTravelGripeDesc));
      vaccineGuide.add(
          _EducationalGuideItem('Leishmaniose', strings.petTravelLeishDesc));
    } else if (isCat) {
      vaccineGuide.add(_EducationalGuideItem(
          'V3/V4/V5 (Gatos)', strings.petTravelV3V4V5Desc));
    }
    vaccineGuide.add(_EducationalGuideItem(
        'Antirrábica', strings.petTravelRabiesDesc,
        isMandatory: true));

    return pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          border: pw.Border.all(color: PdfColors.grey300),
        ),
        child: pw
            .Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          // Status Badges
          pw.Row(children: [
            _buildTravelBadge(
                strings.petTravelVaccines, isRabiesVaxValid, strings),
            pw.SizedBox(width: 10),
            _buildTravelBadge(
                strings.petTravelMicrochip, hasMicrochip, strings),
          ]),
          pw.SizedBox(height: 10),

          pw.Row(children: [
            pw.Expanded(
                child: pw.Text('${strings.petTravelMode}: $mode',
                    style: const pw.TextStyle(fontSize: 10))),
            pw.Expanded(
                child: pw.Text('${strings.petTravelScope}: $scope',
                    style: const pw.TextStyle(fontSize: 10))),
          ]),

          if (hasMicrochip) ...[
            pw.SizedBox(height: 4),
            pw.Text('${strings.pdfFieldMicrochip}: ${profile.microchip}',
                style:
                    const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          ],

          pw.SizedBox(height: 8),
          pw.Text('DICAS INTELIGENTES DE VIAGEM',
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                  color: colorAccent)),
          pw.SizedBox(height: 4),
          pw.Text(
              _getTravelTips(prefs['mode']?.toString(),
                  prefs['scope']?.toString(), strings),
              style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic)),

          if (!isRabiesVaxValid && rabiesDate != null) ...[
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(6),
              decoration: const pw.BoxDecoration(
                color: PdfColors.yellow50,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text(
                  'REGRA DOS 30 DIAS: Para fins de transporte (especialmente aéreo ou internacional), a vacina antirrábica só é considerada válida após 30 dias da aplicação (Quarentena Obrigatória).',
                  style: pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.amber900,
                      fontStyle: pw.FontStyle.italic)),
            ),
          ],

          // --- NEW: INTELLIGENT CHECKLIST ---
          pw.SizedBox(height: 12),
          pw.Text('CHECKLIST INTELIGENTE (BASEADO NA SAÚDE)',
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                  color: colorAccent)),
          pw.SizedBox(height: 6),
          ...intelligentItems.map((item) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 4),
              padding: const pw.EdgeInsets.all(5),
              decoration: pw.BoxDecoration(
                color: item.isWarning ? PdfColors.red50 : PdfColors.white,
                border: pw.Border.all(
                    color:
                        item.isWarning ? PdfColors.red200 : PdfColors.grey200),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
              ),
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(children: [
                      pw.Container(
                          width: 5,
                          height: 5,
                          decoration: pw.BoxDecoration(
                              color: item.isWarning
                                  ? PdfColors.red
                                  : PdfColors.blue,
                              shape: pw.BoxShape.circle)),
                      pw.SizedBox(width: 5),
                      pw.Expanded(
                          child: pw.Text(item.label,
                              style: pw.TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: pw.FontWeight.bold,
                                  color: item.isWarning
                                      ? PdfColors.red900
                                      : PdfColors.grey900))),
                    ]),
                    if (item.subtitle != null) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(item.subtitle!,
                          style: pw.TextStyle(
                              fontSize: 7.5,
                              color: PdfColors.grey600,
                              fontStyle: pw.FontStyle.italic)),
                    ]
                  ]))),

          // --- NEW: VACCINATION GUIDE ---
          pw.SizedBox(height: 12),
          pw.Text(strings.petTravelVaccineGuide.toUpperCase(),
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                  color: colorAccent)),
          pw.SizedBox(height: 6),
          ...vaccineGuide.map((v) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 4),
              padding: const pw.EdgeInsets.all(5),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                    color: v.isMandatory ? colorAccent : PdfColors.grey200),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
              ),
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(children: [
                      pw.Text(v.title,
                          style: pw.TextStyle(
                              fontSize: 8.5,
                              fontWeight: pw.FontWeight.bold,
                              color: v.isMandatory
                                  ? colorAccent
                                  : PdfColors.grey900)),
                      if (v.isMandatory) ...[
                        pw.SizedBox(width: 4),
                        pw.Text('(OBRIGATÓRIO)',
                            style: pw.TextStyle(
                                fontSize: 7,
                                fontWeight: pw.FontWeight.bold,
                                color: colorAccent)),
                      ]
                    ]),
                    pw.SizedBox(height: 2),
                    pw.Text(v.description,
                        style: const pw.TextStyle(
                            fontSize: 7.5, color: PdfColors.grey700)),
                  ]))),

          if (basicItems.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text(strings.petTravelChecklist.toUpperCase(),
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 9,
                    color: colorAccent)),
            pw.SizedBox(height: 4),
            pw.Wrap(
              spacing: 12,
              runSpacing: 4,
              children: basicItems
                  .map((i) =>
                      pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
                        pw.Container(
                            width: 6,
                            height: 6,
                            decoration: const pw.BoxDecoration(
                                color: PdfColors.grey400,
                                shape: pw.BoxShape.circle)),
                        pw.SizedBox(width: 4),
                        pw.Text(i, style: const pw.TextStyle(fontSize: 8.5)),
                      ]))
                  .toList(),
            ),
          ],
        ]));
  }

  pw.Widget _buildTravelBadge(
      String label, bool isValid, AppLocalizations strings) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: pw.BoxDecoration(
        color: isValid ? PdfColors.green50 : PdfColors.red50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(
            color: isValid ? PdfColors.green200 : PdfColors.red200),
      ),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Container(
            width: 6,
            height: 6,
            decoration: pw.BoxDecoration(
              color: isValid ? PdfColors.green : PdfColors.red,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.SizedBox(width: 4),
          pw.Text(label,
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: isValid ? PdfColors.green900 : PdfColors.red900,
              )),
        ],
      ),
    );
  }

  String _localizeTravelValue(String? val, AppLocalizations strings) {
    if (val == null) return '-';
    final low = val.toLowerCase();
    if (low == 'carro' || low == 'car') return strings.petTravelCar;
    if (low == 'avião' || low == 'plane') return strings.petTravelPlane;
    if (low == 'navio' || low == 'ship') return strings.petTravelShip;
    if (low == 'nacional' || low == 'national') {
      return strings.petTravelNational;
    }
    if (low == 'internacional' || low == 'international') {
      return strings.petTravelInternational;
    }
    return val;
  }

  String _getTravelTips(String? mode, String? scope, AppLocalizations strings) {
    final lowMode = mode?.toLowerCase();
    final lowScope = scope?.toLowerCase();

    String tips = '';
    if (lowMode == 'carro' || lowMode == 'car') tips = strings.travel_car_tips;
    if (lowMode == 'avião' || lowMode == 'plane') {
      tips = strings.travel_plane_checklist;
    }
    if (lowMode == 'navio' || lowMode == 'ship') {
      tips = strings.travel_ship_tips;
    }

    if (lowScope == 'internacional' || lowScope == 'international') {
      tips += '\n• ${strings.intl_travel_tips}';
    }

    return tips.isNotEmpty
        ? tips
        : 'Certifique-se de levar os documentos e acessórios de segurança necessários.';
  }

  pw.Widget _buildGeneralAnalysisItem(
      Map<String, dynamic> data, AppLocalizations strings,
      {pw.ImageProvider? image}) {
    final rawType = data['analysis_type']?.toString().toLowerCase() ?? '';

    final typeMap = {
      'food_label': 'ANÁLISE DE RAÇÃO',
      'vocal_analysis': 'ANÁLISE VOCAL',
      'behavior': 'COMPORTAMENTO',
      'nutrition': 'NUTRIÇÃO',
      'body_analysis': 'ANÁLISE CORPORAL',
      // 🛡️ NEW: Traduções adicionais
      'identification': 'IDENTIFICAÇÃO',
      'grooming': 'HIGIENE',
      'health': 'SAÚDE',
      'lifestyle': 'ESTILO DE VIDA',
      'temperament': 'TEMPERAMENTO',
    };
    final type = typeMap[rawType] ??
        (data.containsKey('identification')
            ? 'ANÁLISE DE FOTO DO PET'
            : (data['analysis_type']?.toString().toUpperCase() ?? 'ANÁLISE'));

    String dateStr = '-';
    if (data['last_updated'] != null) {
      try {
        final dt = DateTime.parse(data['last_updated'].toString());
        dateStr = DateFormat.yMd(strings.localeName).add_Hm().format(dt);
      } catch (_) {}
    }

    final ignoredKeys = [
      'analysis_type',
      'last_updated',
      'pet_name',
      'tabela_benigna',
      'tabela_maligna',
      'plano_semanal',
      'weekly_plan',
      'data_inicio_semana',
      'data_fim_semana',
      'orientacoes_gerais',
      'general_guidelines',
      'start_date',
      'end_date',
      'identificacao',
      'identification',
      'clinical_signs',
      'sinais_clinicos',
      'metadata',
      'temperament',
      'temperamento',
      'image_path',
      'photo_path',
      'raw_result',
      'raw_analysis',
      'raw_data'
    ];

    final keyLocalization = {
      'veredict': 'Veredito',
      'simple_reason': 'Motivo',
      'daily_tip': 'Dica',
      'emotion_simple': 'Emoção',
      'reason_simple': 'Causa Provável',
      'action_tip': 'O que fazer',
      'original_filename': 'Arquivo',
      'health_score': 'Score de Saúde',
      'body_signals': 'Sinais Corporais',
      'simple_advice': 'Orientação',
      // 🛡️ NEW: Traduções adicionais para campos em inglês
      'grooming': 'Higiene',
      'health': 'Saúde',
      'lifestyle': 'Estilo de Vida',
      'nutrition': 'Nutrição',
      'behavior': 'Comportamento',
      'temperament': 'Temperamento',
      'exercise': 'Exercício',
      'training': 'Treinamento',
      'socialization': 'Socialização',
    };

    final entries = data.entries.where((e) {
      if (ignoredKeys.contains(e.key.toLowerCase())) return false;
      if (e.value == null ||
          e.value.toString() == 'null' ||
          e.value.toString().trim().isEmpty) {
        return false;
      }
      return true;
    }).toList();

    return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 12),
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
        child:
            pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          if (image != null)
            pw.Container(
                width: 70,
                height: 70,
                margin: const pw.EdgeInsets.only(right: 12),
                child: pw.Image(image, fit: pw.BoxFit.contain)),
          pw.Expanded(
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(type,
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                              color: colorAccent)),
                      pw.Text(dateStr,
                          style: const pw.TextStyle(
                              fontSize: 8, color: PdfColors.grey700)),
                    ]),
                pw.Divider(color: PdfColors.grey200, thickness: 0.5),
                ...entries.map((e) {
                  final label = keyLocalization[e.key] ?? e.key;
                  final val = e.value
                      .toString()
                      .replaceAll('{', '')
                      .replaceAll('}', '');
                  return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 2),
                      child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Container(
                                width: 80,
                                child: pw.Text('$label: ',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 9,
                                        color: PdfColors.grey800))),
                            pw.Expanded(
                                child: pw.Text(val,
                                    style: const pw.TextStyle(fontSize: 9))),
                          ]));
                })
              ]))
        ]));
  }
}

class _TravelImpactItem {
  final String label;
  final String? subtitle;
  final bool isWarning;
  _TravelImpactItem(this.label, {this.subtitle, this.isWarning = false});
}

class _EducationalGuideItem {
  final String title;
  final String description;
  final bool isMandatory;
  _EducationalGuideItem(this.title, this.description,
      {this.isMandatory = false});
}
