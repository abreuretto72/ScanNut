import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/food_analysis_model.dart';
import '../models/recipe_suggestion.dart';
import '../models/nutrition_history_item.dart';
import '../models/recipe_history_item.dart';
import '../data/emergency_recipes.dart';
import '../../../core/services/image_optimization_service.dart';
import '../../../core/theme/app_design.dart';

// 🛡️ DTO para Strings Localizadas (Sanitização)
class FoodPdfLabels {
  final String title;
  final String date;
  final String nutrientsTable;
  final String qty;
  final String dailyGoal;
  final String calories;
  final String proteins;
  final String carbs;
  final String fats;
  final String healthRating;
  final String clinicalRec;
  final String disclaimer;
  final String recipesTitle;
  final String justificationLabel;
  final String difficultyLabel;
  final String instructionsLabel;
  
  // Novas labels para abas
  final String healthSectionTitle;
  final String benefitsLabel;
  final String risksLabel;
  final String performanceTitle;
  final String gastronomyTitle;
  final String micronutrientsTitle;
  final String micronutrientName;
  final String micronutrientAmount;
  final String micronutrientDv;

  FoodPdfLabels({
    required this.title,
    required this.date,
    required this.nutrientsTable,
    required this.qty,
    required this.dailyGoal,
    required this.calories,
    required this.proteins,
    required this.carbs,
    required this.fats,
    required this.healthRating,
    required this.clinicalRec,
    required this.disclaimer,
    required this.recipesTitle,
    required this.justificationLabel,
    required this.difficultyLabel,
    required this.instructionsLabel,
    this.healthSectionTitle = "Saúde & Biohacking",
    this.benefitsLabel = "Pontos Positivos",
    this.risksLabel = "Pontos Negativos",
    this.performanceTitle = "Impacto Orgânico",
    this.gastronomyTitle = "Inteligência Culinária",
    this.micronutrientsTitle = "Micronutrientes (Vitaminas e Minerais)",
    this.micronutrientName = "Nutriente",
    this.micronutrientAmount = "Quantidade",
    this.micronutrientDv = "% VD",
  });
}

class FoodExportService {
  static final FoodExportService _instance = FoodExportService._internal();
  factory FoodExportService() => _instance;
  FoodExportService._internal();

  /// 📜 RELATÓRIO A: Análise Nutricional Completa (4 Abas)
  Future<Uint8List> generateFullAnalysisPdf(FoodAnalysisModel data, FoodPdfLabels labels) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (context) => _buildFooter(context),
        header: (context) => _buildHeader(labels),
        build: (context) => [
          // ABA 1: RESUMO
          pw.SizedBox(height: 10),
          _buildTitle(data.identidade.nome),
          pw.Divider(thickness: 0.5, color: PdfColor.fromHex('#E65100')),
          pw.SizedBox(height: 10),
          _buildSectionTitle(labels.clinicalRec),
          pw.Paragraph(
            text: data.analise.vereditoIa.isEmpty ? "Sem vaticínio clínico disponível." : data.analise.vereditoIa,
            style: const pw.TextStyle(fontSize: 11),
          ),
          if (data.identidade.alertaCritico.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Text(
              "ALERTA CRÍTICO: ${data.identidade.alertaCritico}", 
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)
            ),
          ],

          // ABA 2: SAÚDE & RISCOS
          pw.SizedBox(height: 25),
          _buildSectionTitle(labels.healthSectionTitle),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _buildListSection(labels.benefitsLabel, data.analise.pontosPositivos, PdfColors.green800),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: _buildListSection(labels.risksLabel, data.analise.pontosNegativos, PdfColors.red800),
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          _buildSectionTitle(labels.performanceTitle),
          _buildPerformanceRow(data, labels),

          // ABA 3: NUTRIENTES
          pw.SizedBox(height: 25),
          _buildSectionTitle(labels.nutrientsTable),
          _buildNutritionalTable(data, labels),
          if (data.micronutrientes.lista.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            _buildSectionTitle(labels.micronutrientsTitle),
            _buildMicrosTable(data, labels),
          ],

          // ABA 4: GASTRONOMIA
          pw.SizedBox(height: 25),
          _buildSectionTitle(labels.gastronomyTitle),
          _buildGastronomyInfo(data, labels),
          pw.SizedBox(height: 15),
          _buildRecipes(data, labels),

          pw.SizedBox(height: 30),
          _buildDisclaimer(labels),
        ],
      ),
    );

    return pdf.save();
  }

  /// 📜 RELATÓRIO B: Livro de Receitas Recomendadas (Exclusivo)
  Future<Uint8List> generateRecipeBookPdf(FoodAnalysisModel data, FoodPdfLabels labels) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (context) => _buildFooter(context),
        header: (context) => _buildHeader(labels),
        build: (context) => [
          pw.SizedBox(height: 10),
          _buildTitle("${labels.recipesTitle}: ${data.identidade.nome}"),
          pw.Divider(thickness: 0.5, color: PdfColor.fromHex('#E65100')),
          pw.SizedBox(height: 20),
          _buildRecipes(data, labels),
          pw.SizedBox(height: 30),
          _buildDisclaimer(labels),
        ],
      ),
    );

    return pdf.save();
  }

  /// 📜 RELATÓRIO C: Histórico Nutricional (Múltiplos Itens)
  /// Atende ao pedido: "Deve ser 100% Laranja e conter as 4 abas"
  Future<Uint8List> generateFoodHistoryReport(List<NutritionHistoryItem> items, FoodPdfLabels labels) async {
    final pdf = pw.Document();

    for (var item in items) {
      FoodAnalysisModel? analysis;
      if (item.rawMetadata != null) {
        try {
          final fixedMap = _deepFixMaps(item.rawMetadata);
          if (fixedMap is Map<String, dynamic>) {
            analysis = FoodAnalysisModel.fromJson(fixedMap);
          }
        } catch (e) {
          debugPrint('⚠️ [FoodExport] Erro ao processar item do histórico: ${item.foodName}');
        }
      }

      if (analysis == null) continue;
      final analysisData = analysis;

      pw.ImageProvider? foodImage = await _safeLoadImage(item.imagePath);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          footer: (context) => _buildFooter(context),
          header: (context) => _buildHeader(labels),
          build: (context) => [
            pw.SizedBox(height: 10),
            // HEADER COM IMAGEM (Se disponível)
            pw.Row(
              children: [
                if (foodImage != null) ...[
                  pw.Container(
                    width: 70, height: 70,
                    margin: const pw.EdgeInsets.only(right: 15),
                    decoration: pw.BoxDecoration(
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: PdfColor.fromHex('#E65100'), width: 1),
                    ),
                    child: pw.ClipRRect(
                      horizontalRadius: 7, verticalRadius: 7,
                      child: pw.Image(foodImage, fit: pw.BoxFit.cover),
                    ),
                  ),
                ],
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildTitle(analysisData.identidade.nome),
                      pw.Text(DateFormat('dd/MM/yyyy HH:mm').format(item.timestamp), 
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    ],
                  ),
                ),
              ],
            ),
            pw.Divider(thickness: 0.5, color: PdfColor.fromHex('#E65100')),
            
            // ABA 1 & 2: RESUMO E SAÚDE
            pw.SizedBox(height: 10),
            _buildSectionTitle(labels.clinicalRec),
            pw.Paragraph(
              text: analysisData.analise.vereditoIa.isEmpty ? "Sem vaticínio clínico." : analysisData.analise.vereditoIa,
              style: const pw.TextStyle(fontSize: 10),
            ),
            
            pw.SizedBox(height: 15),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: _buildListSection(labels.benefitsLabel, analysisData.analise.pontosPositivos, PdfColors.green800),
                ),
                pw.SizedBox(width: 20),
                pw.Expanded(
                  child: _buildListSection(labels.risksLabel, analysisData.analise.pontosNegativos, PdfColors.red800),
                ),
              ],
            ),

            // ABA 3: NUTRIENTES
            pw.SizedBox(height: 20),
            _buildSectionTitle(labels.nutrientsTable),
            _buildNutritionalTable(analysisData, labels),

            // ABA 4: GASTRONOMIA
            pw.SizedBox(height: 20),
            _buildSectionTitle(labels.gastronomyTitle),
            _buildGastronomyInfo(analysisData, labels),
          ],
        ),
      );
    }

    return pdf.save();
  }

  /// 📜 RELATÓRIO D: Livro de Receitas Histórico
  Future<Uint8List> generateRecipeHistoryReportFromList(List<RecipeHistoryItem> items, FoodPdfLabels labels) async {
    final pdf = pw.Document();

    for (var item in items) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          footer: (context) => _buildFooter(context),
          header: (context) => _buildHeader(labels),
          build: (context) => [
            pw.SizedBox(height: 10),
            _buildTitle("${item.recipeName} (${item.foodName})"),
            pw.Divider(thickness: 0.5, color: PdfColor.fromHex('#E65100')),
            pw.SizedBox(height: 15),
            
            _buildSectionTitle("MODO DE PREPARO"),
            pw.Paragraph(
              text: item.instructions.isEmpty ? "Sem instruções disponíveis." : item.instructions,
              style: const pw.TextStyle(fontSize: 11),
            ),
            
            if (item.prepTime.isNotEmpty) ...[
              pw.SizedBox(height: 10),
              pw.Text("Tempo Estimado: ${item.prepTime}", 
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColor.fromHex('#E65100'))),
            ],
            
            pw.SizedBox(height: 30),
            _buildDisclaimer(labels),
          ],
        ),
      );
    }

    return pdf.save();
  }

  // --- HELPERS INTERNOS ---

  Future<pw.ImageProvider?> _safeLoadImage(String? path) async {
    if (path == null || path.isEmpty) return null;
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      final optimizedBytes = await ImageOptimizationService().loadOptimizedBytes(originalPath: path);
      if (optimizedBytes != null) return pw.MemoryImage(optimizedBytes);
      return pw.MemoryImage(await file.readAsBytes());
    } catch (e) {
      return null;
    }
  }

  dynamic _deepFixMaps(dynamic value) {
    if (value is Map) {
      return value.map<String, dynamic>(
          (k, v) => MapEntry(k.toString(), _deepFixMaps(v)));
    }
    if (value is List) {
      return value.map((e) => _deepFixMaps(e)).toList();
    }
    return value;
  }

  pw.Widget _buildHeader(FoodPdfLabels labels) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColor.fromHex('#E65100'), width: 1.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(labels.title.toUpperCase(), style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#E65100'))),
          pw.Text(labels.date, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(top: 20),
      padding: const pw.EdgeInsets.symmetric(vertical: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Text(
        'ScanNut | Página ${context.pageNumber} de ${context.pagesCount} | © 2026 Multiverso Digital | contato@multiversodigital.com.br',
        style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
      ),
    );
  }

  pw.Widget _buildTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 10),
      child: pw.Text(
        title.toUpperCase(),
        style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
      ),
    );
  }

  pw.Widget _buildSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#E65100')),
      ),
    );
  }

  pw.Widget _buildTrafficLight(String status, FoodPdfLabels labels) {
    PdfColor color;
    if (status.contains('Verde')) color = PdfColors.green800;
    else if (status.contains('Amarelo')) color = PdfColors.amber800;
    else color = PdfColors.red800;

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
        color: PdfColor(color.red, color.green, color.blue, 0.05),
        border: pw.Border.all(color: color, width: 1),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 10, height: 10,
            decoration: pw.BoxDecoration(shape: pw.BoxShape.circle, color: color),
          ),
          pw.SizedBox(width: 10),
          pw.Text('${labels.healthRating}: $status', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: color, fontSize: 11)),
        ],
      ),
    );
  }

  pw.Widget _buildListSection(String title, List<String> items, PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: color)),
        pw.SizedBox(height: 4),
        if (items.isEmpty)
          pw.Text("- Nenhum dado registrado", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500))
        else
          ...items.map((i) => pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("• ", style: pw.TextStyle(color: color, fontWeight: pw.FontWeight.bold)),
              pw.Expanded(child: pw.Text(i, style: const pw.TextStyle(fontSize: 10))),
            ],
          )),
      ],
    );
  }

  pw.Widget _buildPerformanceRow(FoodAnalysisModel data, FoodPdfLabels labels) {
    final perf = data.performance;
    return pw.Table.fromTextArray(
      data: [
        ["Critério", "Valor"],
        ["Saciedade", "${perf.indiceSaciedade}/10"],
        ["Momento Ideal", perf.momentoIdealConsumo],
      ],
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#E65100'), fontSize: 9),
      cellStyle: const pw.TextStyle(fontSize: 9),
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      cellAlignment: pw.Alignment.centerLeft,
    );
  }

  pw.Widget _buildMiniCard(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#FFF3E0'), // Laranja clarinho estruturado
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColor(color.red, color.green, color.blue, 0.3), width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          pw.SizedBox(height: 2),
          pw.Text(value.isEmpty ? "N/A" : value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  pw.Widget _buildNutritionalTable(FoodAnalysisModel data, FoodPdfLabels labels) {
    final m = data.macros;
    final calStr = "\u00B1 ${m.calorias100g} kcal";
    
    return pw.Table.fromTextArray(
      headers: [labels.nutrientsTable, labels.qty, labels.dailyGoal],
      data: [
        [labels.calories, calStr, "${((m.calorias100g / 2000) * 100).toStringAsFixed(1)}%"],
        [labels.proteins, "\u00B1 ${m.proteinas}", "-"],
        [labels.carbs, "\u00B1 ${m.carboidratosLiquidos}", "-"],
        [labels.fats, "\u00B1 ${m.gordurasPerfil}", "-"],
      ],
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#E65100'), fontSize: 10),
      headerDecoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColor.fromHex('#E65100'), width: 1.0))
      ),
      cellStyle: const pw.TextStyle(fontSize: 10),
      rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))),
      cellAlignment: pw.Alignment.centerLeft,
    );
  }

  pw.Widget _buildMicrosTable(FoodAnalysisModel data, FoodPdfLabels labels) {
    return pw.Table.fromTextArray(
      headers: [labels.micronutrientName, labels.micronutrientAmount, labels.micronutrientDv],
      data: data.micronutrientes.lista.map((n) => [
        n.nome,
        n.quantidade,
        "${n.percentualDv}%"
      ]).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#E65100'), fontSize: 9),
      headerDecoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColor.fromHex('#E65100'), width: 0.8))
      ),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellAlignment: pw.Alignment.centerLeft,
    );
  }

  pw.Widget _buildGastronomyInfo(FoodAnalysisModel data, FoodPdfLabels labels) {
    final g = data.gastronomia;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (g.preservacaoNutrientes.isNotEmpty)
          _buildInfoRow("Técnica:", g.preservacaoNutrientes),
        if (g.smartSwap.isNotEmpty)
          _buildInfoRow("Smart Swap:", g.smartSwap),
        _buildInfoRow("Dica Expert:", data.analise.vereditoIa),
      ],
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(text: "$label ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            pw.TextSpan(text: value, style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildRecipes(FoodAnalysisModel data, FoodPdfLabels labels) {
    var recipes = data.receitas.where((r) => r.isValid).toList();
    
    // 🛡️ Lei de Ferro: Fallback se vazio
    if (recipes.isEmpty) {
      recipes = EmergencyRecipes.getFallback(data.identidade.nome);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(labels.recipesTitle, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.orange800)),
        pw.SizedBox(height: 8),
        ...recipes.map((r) {
          String cal = r.calories;
          if (!cal.contains('\u00B1')) cal = '\u00B1 $cal';
          if (!cal.toLowerCase().contains('kcal')) cal = '$cal kcal';

          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 12),
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.orange50,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.orange200, width: 0.5),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(r.name.contains(':') ? r.name : "${data.identidade.nome}: ${r.name}", 
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.orange900)),
                    pw.Text(cal, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Text("${labels.difficultyLabel}: ${r.difficulty} | Tempo: ${r.prepTime}", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                pw.SizedBox(height: 6),
                pw.Text("${labels.instructionsLabel}:", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                pw.Text(r.instructions, style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  pw.Widget _buildDisclaimer(FoodPdfLabels labels) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.Text(
          labels.disclaimer,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }
}
