import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../models/food_analysis_model.dart';
import '../models/food_nutrition_history_item.dart';
import '../models/food_recipe_history_item.dart';
import '../../../core/services/base_pdf_helper.dart';
import '../nutrition/data/models/plan_day.dart';
import '../nutrition/data/models/shopping_list_model.dart';
import '../models/food_pdf_labels.dart';
import 'dart:convert';

import 'package:flutter/widgets.dart' show WidgetsFlutterBinding; // 🛡️ Fix: Import for ensureInitialized

/// Refined Service for Food-specific PDF exports.
/// Part of the Micro-Apps strategy and Iron Law of isolation.
class FoodExportService {
  static final FoodExportService _instance = FoodExportService._internal();
  factory FoodExportService() => _instance;
  FoodExportService._internal();

  static const PdfColor themeColor = PdfColor.fromInt(0xFFFF9800); // Laranja Mestre V135
  static const String institutionalFooter = 'ScanNut | Chef Vision | © 2026 Multiverso Digital';

  /// 🧠 NEW INTELLIGENCE REPORT (Gemini 2.5)
  Future<File> generateIntelligencePDF(FoodAnalysisModel analysis, File? imageFile, FoodLocalizations strings) async {
    final pdfLabels = FoodPdfLabels(
       title: strings.foodPdfTitle,
       date: strings.foodDateLabel,
       nutrientsTable: strings.foodNutrientsTable,
       qty: strings.foodQuantity,
       dailyGoal: strings.foodGoalLabel, // Ensure this exists in ARB
       calories: strings.foodCalories,
       proteins: strings.foodNutrientsProteins,
       carbs: strings.foodNutrientsCarbs,
       fats: strings.foodNutrientsFats,
       healthRating: strings.foodTrafficLight,
       clinicalRec: strings.foodClinicalRec,
       disclaimer: strings.foodDisclaimer,
       recipesTitle: strings.foodRecipesTitle,
       justificationLabel: strings.foodJustificationLabel,
       difficultyLabel: strings.foodDifficultyLabel,
       instructionsLabel: strings.foodInstructionsLabel,
       strings: strings,
    );

    final pdf = await generateFullAnalysisPdf(analysis, pdfLabels, imageFile: imageFile);
    return BasePdfHelper.saveDocument(name: 'scannut_intelligence_${DateTime.now().millisecondsSinceEpoch}.pdf', pdf: pdf);
  }

  /// 📜 8. FOOD HISTORY REPORT
  Future<pw.Document> generateFoodHistoryReport({
    required List<NutritionHistoryItem> items,
    required FoodLocalizations strings,
  }) async {
    WidgetsFlutterBinding.ensureInitialized(); // 🛡️ Fix: Ensure AssetManifest for fonts
    final pdf = pw.Document();
    final String timestampStr = DateFormat('dd/MM/yyyy HH:mm', strings.localeName).format(DateTime.now());

    final List<pw.ImageProvider?> loadedImages = [];
    debugPrint('🔍 [PDF Debug] Iniciando carga de imagens. Total itens: ${items.length}');
    
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      debugPrint('🔍 [PDF Debug] Item $i: ${item.foodName} | Path: ${item.imagePath}');

      if (item.imagePath != null && item.imagePath!.isNotEmpty) {
        try {
          final file = File(item.imagePath!);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            debugPrint('✅ [PDF Debug] Imagem carregada: ${bytes.lengthInBytes} bytes');
            loadedImages.add(pw.MemoryImage(bytes));
          } else {
            debugPrint('❌ [PDF Debug] Arquivo não existe no caminho: ${item.imagePath}');
            loadedImages.add(null);
          }
        } catch (e) {
          debugPrint('⚠️ [PDF Debug] Exceção ao ler arquivo: $e');
          loadedImages.add(null);
        }
      } else {
        debugPrint('ℹ️ [PDF Debug] ImagePath nulo ou vazio para este item.');
        loadedImages.add(null);
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (context) => BasePdfHelper.buildHeader(
            strings.foodHistoryTitle, timestampStr,
            color: themeColor, appName: 'ScanNut'),
        footer: (context) => _buildFooter(context, strings: strings),
        build: (context) {
           return items.asMap().entries.map((e) {
             final index = e.key;
             final item = e.value;
             final image = loadedImages[index];

             return pw.Container(
               margin: const pw.EdgeInsets.only(bottom: 10),
               padding: const pw.EdgeInsets.all(10),
               decoration: const pw.BoxDecoration(
                 border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
               ),
               child: pw.Row(
                 crossAxisAlignment: pw.CrossAxisAlignment.start,
                 children: [
                    // Imagem (Restored)
                    pw.Container(
                      width: 50, height: 50,
                      margin: const pw.EdgeInsets.only(right: 12),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey200,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                        image: image != null ? pw.DecorationImage(image: image, fit: pw.BoxFit.cover) : null,
                      ),
                    ),
                    
                    // Info
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(item.foodName ?? strings.foodNotAvailable, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                          pw.SizedBox(height: 4),
                          pw.Text(DateFormat('dd/MM/yyyy HH:mm').format(item.timestamp), style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                        ]
                      )
                    ),

                    // Calories
                    pw.Text('${item.calories} kcal', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: themeColor)),
                 ]
               )
             );
           }).toList();
        }
      ),
    );
    return pdf;
  }

  /// 📜 9. RECIPE HISTORY REPORT
  Future<pw.Document> generateRecipeHistoryReport(
    List<RecipeHistoryItem> items,
    FoodLocalizations strings,
  ) async {
    final pdf = pw.Document();
    final String timestampStr = DateFormat('dd/MM/yyyy HH:mm', strings.localeName).format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (context) => BasePdfHelper.buildHeader(
            strings.foodRecipeBookTitle, timestampStr,
            color: themeColor, appName: 'ScanNut'),
        footer: (context) => _buildFooter(context, strings: strings),
        build: (context) {
           return items.map((item) {
             return pw.Container(
               margin: const pw.EdgeInsets.only(bottom: 15),
               padding: const pw.EdgeInsets.all(12),
               decoration: pw.BoxDecoration(
                 border: pw.Border.all(color: themeColor),
                 borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
               ),
               child: pw.Column(
                 crossAxisAlignment: pw.CrossAxisAlignment.start,
                 children: [
                    pw.Text(item.recipeName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                    pw.SizedBox(height: 4),
                    pw.Text("${item.foodName} | ${item.prepTime}", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    pw.SizedBox(height: 8),
                    pw.Text(item.instructions, maxLines: 5, style: const pw.TextStyle(fontSize: 10)),
                 ]
               )
             );
           }).toList();
        }
      ),
    );
    return pdf;
  }

  /// 📊 6. FULL ANALYSIS REPORT (SCANNUT STANDARD V136)
  Future<pw.Document> generateFullAnalysisPdf(
      FoodAnalysisModel analysis, FoodPdfLabels labels, {File? imageFile}) async {
    final pdf = pw.Document();
    WidgetsFlutterBinding.ensureInitialized(); // 🛡️ Samsung Fix: Ensure AssetManifest
    
    // 🛡️ IRON LAW: Load font to prevent missing character errors
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final fontItalic = await PdfGoogleFonts.robotoItalic();
    
    final theme = pw.ThemeData.withFont(
      base: font,
      bold: fontBold,
      italic: fontItalic,
    );
    
    final String timestampStr = DateFormat('dd/MM/yyyy HH:mm', labels.locale).format(DateTime.now());

    // 🛡️ DATA EXTRACTION
    final String dishName = analysis.identidade.nome;
    final String processing = analysis.identidade.statusProcessamento;
    final String trafficLight = analysis.identidade.semaforoSaude;
    final String? weight = analysis.identidade.estimativaPeso;
    final String? method = analysis.identidade.metodoPreparo;

    final int kcal = analysis.macros.calorias100g;
    final String carbs = analysis.macros.carboidratosLiquidos;
    final String protein = analysis.macros.proteinas;
    final String fats = analysis.macros.gordurasPerfil;

    pw.MemoryImage? foodImage;
    if (imageFile != null) {
      try {
        if (await imageFile.exists()) {
           final imageBytes = await imageFile.readAsBytes();
           foodImage = pw.MemoryImage(imageBytes);
        }
      } catch (e) {
        debugPrint('⚠️ [PDF Blindagem] Erro ao ler imagem principal: $e');
        foodImage = null;
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        theme: theme,
        header: (context) => BasePdfHelper.buildHeader(
            '${labels.title} - 360º', timestampStr,
            color: themeColor, appName: 'ScanNut'),
        footer: (context) => _buildFooter(context, strings: labels.strings),
        build: (context) => [
          // 0. FOOD IMAGE (If available)
          if (foodImage != null)
             pw.Container(
               height: 200,
               width: double.infinity,
               margin: const pw.EdgeInsets.only(bottom: 20),
               decoration: pw.BoxDecoration(
                 borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                 image: pw.DecorationImage(image: foodImage, fit: pw.BoxFit.cover),
               )
             ),

          // 1. HEADER INFO
          pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Expanded(
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(dishName.toUpperCase(),
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, color: PdfColors.black)),
              pw.SizedBox(height: 5),
              pw.Text('$processing • $trafficLight',
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
              if (weight != null)
                pw.Text('${labels.qty}: $weight',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              if (method != null)
                pw.Text('${labels.strings!.foodPrepShort}: $method',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            ]))
          ]),

          pw.SizedBox(height: 20),

          // 2. MACROS GRID
          BasePdfHelper.buildSectionHeader(labels.nutrientsTable, color: themeColor),
          pw.SizedBox(height: 5),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            BasePdfHelper.buildIndicator(labels.calories, '$kcal kcal', themeColor),
            BasePdfHelper.buildIndicator(labels.carbs, carbs, PdfColors.orange),
            BasePdfHelper.buildIndicator(labels.proteins, protein, PdfColors.red),
            BasePdfHelper.buildIndicator(labels.fats, fats, PdfColors.yellow),
          ]),

          pw.SizedBox(height: 20),

          // 3. IA VERDICT
          BasePdfHelper.buildSectionHeader(labels.clinicalRec, color: themeColor),
          pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text(labels.strings!.foodVerdict.toUpperCase(),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.Text(analysis.analise.vereditoIa, style: const pw.TextStyle(fontSize: 10)),
                if (analysis.analise.pontosPositivos.isNotEmpty) ...[
                  pw.SizedBox(height: 8),
                  pw.Text(labels.strings!.foodPros.toUpperCase(),
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.green700)),
                  ...analysis.analise.pontosPositivos.map((e) => _buildSafeBullet(e, color: PdfColors.green700)),
                ],
                if (analysis.analise.pontosNegativos.isNotEmpty) ...[
                  pw.SizedBox(height: 8),
                  pw.Text('PONTOS DE ATENÇÃO:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.red700)),
                  ...analysis.analise.pontosNegativos.map((e) => _buildSafeBullet(e, color: PdfColors.red700)),
                ]
              ])),

          pw.SizedBox(height: 20),

          // 4. PERFORMANCE & BIOHACKING
          BasePdfHelper.buildSectionHeader(labels.strings!.foodBiohackingTitle, color: themeColor),
          pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Expanded(
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(labels.strings!.foodBodyBenefitsTitle,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              ...analysis.performance.pontosPositivosCorpo.map((e) => _buildSafeBullet(e, color: themeColor)),
              pw.SizedBox(height: 10),
              pw.Text(labels.strings!.foodBodyAttentionTitle,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              if (analysis.performance.pontosAtencaoCorpo.isEmpty)
                pw.Text(labels.strings!.foodNoCriticalPoints,
                    style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic))
              else
                ...analysis.performance.pontosAtencaoCorpo
                    .map((e) => _buildSafeBullet(e, color: PdfColors.orange)),
            ])),
            pw.SizedBox(width: 15),
            pw.Expanded(
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              BasePdfHelper.buildIndicator(labels.strings!.foodSatietyLabel, '${analysis.performance.indiceSaciedade}/10', PdfColors.teal),
              pw.SizedBox(height: 10),
              pw.Text(labels.strings!.foodFocusEnergyTitle,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.Text(analysis.performance.impactoFocoEnergia, style: const pw.TextStyle(fontSize: 9)),
              pw.SizedBox(height: 10),
              pw.Text(labels.strings!.foodIdealMomentTitle,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.Text(analysis.performance.momentoIdealConsumo, style: const pw.TextStyle(fontSize: 9)),
            ])),
          ]),
        ],
      ),
    );

    // 5. ACTION PLAN PAGE (Smart Swap & Recipes)
    if (analysis.receitas.isNotEmpty || analysis.gastronomia.smartSwap.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(35),
          theme: theme, // Ensure fonts here too
          header: (context) => BasePdfHelper.buildHeader(labels.strings!.foodActionPlanTitle, timestampStr, color: themeColor, appName: 'ScanNut'),
          footer: (context) => _buildFooter(context, strings: labels.strings),
          build: (context) {
             final List<pw.Widget> content = [];
             
             // Smart Swap
             if (analysis.gastronomia.smartSwap.isNotEmpty) {
                content.add(BasePdfHelper.buildSectionHeader(labels.strings!.foodSmartSwapTitle, color: PdfColors.blueAccent));
                content.add(
                  pw.Container(
                    width: double.infinity,
                    margin: const pw.EdgeInsets.only(bottom: 20),
                    padding: const pw.EdgeInsets.all(15),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue50,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      border: pw.Border.all(color: PdfColors.blue200)
                    ),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Symbolic Icon
                        pw.Container(
                          width: 20, height: 20,
                          decoration: const pw.BoxDecoration(color: PdfColors.blueAccent, shape: pw.BoxShape.circle),
                        ),
                        pw.SizedBox(width: 10),
                        pw.Expanded(
                          child: pw.Text(analysis.gastronomia.smartSwap, style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.5))
                        )
                      ]
                    )
                  )
                );
             }

             // Recipes
             if (analysis.receitas.isNotEmpty) {
               content.add(BasePdfHelper.buildSectionHeader(labels.recipesTitle.toUpperCase(), color: themeColor));
               for(final r in analysis.receitas) {
                 content.add(
                   pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 12),
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey300),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
                      child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(r.name,
                                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                                  pw.Text(r.prepTime,
                                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                                ]),
                             pw.SizedBox(height: 4),
                            pw.Text(r.instructions,
                                style: const pw.TextStyle(fontSize: 8),
                                maxLines: 50), // Increase maxLines to show full recipe
                          ]))
                 );
               }
             }
             
             return content;
          }
        )
      );
    }

    return pdf;
  }

  /// 📖 7. RECIPE BOOK PDF
  Future<pw.Document> generateRecipeBookPdf(
      FoodAnalysisModel analysis, FoodPdfLabels labels) async {
    final pdf = pw.Document();
    final String timestampStr = DateFormat('dd/MM/yyyy HH:mm', labels.locale).format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (context) => BasePdfHelper.buildHeader(
            labels.recipesTitle, timestampStr,
            color: themeColor, appName: 'ScanNut'),
        footer: (context) => _buildFooter(context, strings: labels.strings),
        build: (context) {
          final List<pw.Widget> content = [];
          
          content.add(pw.Center(
            child: pw.Text('${labels.title} - ${analysis.identidade.nome}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16))
          ));
          content.add(pw.SizedBox(height: 20));

          for (final recipe in analysis.receitas) {
            content.add(
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 25),
                decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: const pw.BoxDecoration(
                        color: themeColor,
                        borderRadius: pw.BorderRadius.only(
                            topLeft: pw.Radius.circular(8),
                            topRight: pw.Radius.circular(8)),
                      ),
                      child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Expanded(
                                child: pw.Text(recipe.name,
                                    style: pw.TextStyle(
                                        color: PdfColors.white,
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 14))),
                            pw.Text(
                                "${recipe.prepTime} | ${recipe.calories}",
                                style: pw.TextStyle(
                                    color: PdfColors.white, fontSize: 10)),
                          ]),
                    ),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(12),
                        child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(labels.instructionsLabel.toUpperCase(),
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 10,
                                      color: themeColor)),
                              pw.SizedBox(height: 5),
                              pw.Text(
                                  recipe.instructions
                                      .replaceAll("**", "")
                                      .replaceAll("Ingredientes Usados:",
                                          "\nIngredientes Usados:")
                                      .replaceAll("Modo de Preparo:",
                                          "\nModo de Preparo:"),
                                  style: const pw.TextStyle(
                                      fontSize: 10, lineSpacing: 1.5)),
                              pw.Divider(color: PdfColors.grey300),
                              pw.Row(children:[
                                pw.Text("${labels.difficultyLabel}: ${recipe.difficulty ?? labels.strings!.foodNotAvailable} ", 
                                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                                pw.Spacer(),
                                pw.Text(recipe.justification,
                                  style: pw.TextStyle(
                                      fontStyle: pw.FontStyle.italic,
                                      fontSize: 9,
                                      color: PdfColors.grey600))
                              ])
                            ]))
                  ],
                ),
              ),
            );
          }
          return content;
        },
      ),
    );
    return pdf;
  }


  /// 🧑‍🍳 1. CHEF VISION REPORT
  Future<pw.Document> generateChefVisionReport({
    required FoodAnalysisModel analysis,
    required FoodLocalizations strings,
    File? imageFile,
  }) async {
    final pdf = pw.Document();
    final String timestampStr = DateFormat.yMd(strings.localeName).add_Hm().format(DateTime.now());
    
    pw.ImageProvider? mainImage;
    if (imageFile != null) {
      mainImage = await BasePdfHelper.safeLoadImage(imageFile.path);
    }
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        header: (context) => BasePdfHelper.buildHeader(
          strings.foodChefVisionReportTitle, 
          timestampStr, 
          color: themeColor, 
          dateLabel: strings.foodDateLabel,
          appName: 'ScanNut',
        ),
        footer: (context) => _buildFooter(context, strings: strings),
        build: (context) {
          final List<pw.Widget> content = [];
          
          if (mainImage != null) {
             content.add(
               pw.Container(
                 height: 150,
                 width: double.infinity,
                 margin: const pw.EdgeInsets.only(bottom: 20),
                 child: pw.Center(
                    child: pw.ClipRRect(
                      horizontalRadius: 8,
                      verticalRadius: 8,
                      child: pw.Image(mainImage, fit: pw.BoxFit.cover)
                    )
                 )
               )
             );
          }
          
          final inventory = analysis.identidade.nome.replaceAll("Inventário: ", "");
          content.add(
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              margin: const pw.EdgeInsets.only(bottom: 20),
              decoration: pw.BoxDecoration(
                 color: PdfColor.fromInt(0xFFFFF3E0), // Very Light Orange
                 borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                 border: pw.Border.all(color: themeColor)
              ),
              child: pw.Column(
                 crossAxisAlignment: pw.CrossAxisAlignment.start,
                 children: [
                    pw.Text(strings.foodInventoryDetectedTitle, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.black)),
                    pw.SizedBox(height: 5),
                    pw.Text(inventory, style: const pw.TextStyle(fontSize: 12, color: PdfColors.black))
                 ]
              )
            )
          );
          
          for (final recipe in analysis.receitas) {
             content.add(
               pw.Container(
                 margin: const pw.EdgeInsets.only(bottom: 25),
                 decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))
                 ),
                 child: pw.Column(
                   crossAxisAlignment: pw.CrossAxisAlignment.start,
                   children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: const pw.BoxDecoration(
                           color: themeColor,
                           borderRadius: pw.BorderRadius.only(topLeft: pw.Radius.circular(8), topRight: pw.Radius.circular(8)),
                        ),
                        child: pw.Row(
                           mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                           children: [
                              pw.Expanded(child: pw.Text(recipe.name, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 14))),
                              pw.Text("${recipe.prepTime} | ${recipe.calories}", style: pw.TextStyle(color: PdfColors.white, fontSize: 10))
                           ]
                        )
                      ),
                      
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(12),
                        child: pw.Column(
                           crossAxisAlignment: pw.CrossAxisAlignment.start,
                           children: [
                              pw.Text("MODO DE PREPARO & INGREDIENTES", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: themeColor)),
                              pw.SizedBox(height: 5),
                              pw.Text(
                                  recipe.instructions.replaceAll("**", "").replaceAll("Ingredientes Usados:", "\nIngredientes Usados:").replaceAll("Modo de Preparo:", "\nModo de Preparo:"),
                                  style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.5)
                              ),
                              pw.Divider(color: PdfColors.grey300),
                              pw.Text(recipe.justification, style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 9, color: PdfColors.grey600))
                           ]
                        )
                      )
                   ]
                 )
               )
             );
          }
          
          return content;
        }
      )
    );
    
    return pdf;
  }

  /// 📋 2. HUMAN NUTRITION PLAN REPORT
  Future<pw.Document> generateHumanNutritionPlanReport({
    required String goal,
    required List<PlanDay> days,
    required FoodLocalizations strings,
    String? batchCookingTips,
    String? shoppingListJson,
  }) async {
    final pdf = pw.Document();
    final String timestampStr = DateFormat('dd/MM/yyyy HH:mm', strings.localeName).format(DateTime.now());

    final List<WeeklyShoppingList> weeklyShoppingLists = [];
    if (shoppingListJson != null && shoppingListJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(shoppingListJson);
        if (decoded is List) {
          for (var item in decoded) {
            if (item is Map) {
              weeklyShoppingLists.add(WeeklyShoppingList.fromJson(Map<String, dynamic>.from(item)));
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error decoding shopping list JSON: $e');
      }
    }

    int numWeeks = (days.length / 7).ceil();

    for (int w = 0; w < numWeeks; w++) {
      final startIdx = w * 7;
      final endIdx = (startIdx + 7) > days.length ? days.length : (startIdx + 7);
      final weekDays = days.sublist(startIdx, endIdx);
      final weekLabel = numWeeks > 1 ? ' - SEMANA ${w + 1}' : '';

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(35),
          header: (context) => BasePdfHelper.buildHeader(
              '${strings.foodMenuPlanTitle}${weekLabel.toUpperCase()}',
              timestampStr,
              color: themeColor,
              appName: 'ScanNut'),
          footer: (context) => _buildFooter(context, strings: strings),
          build: (context) => [
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: themeColor, width: 0.5),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(strings.foodPersonalizedPlanTitle,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                      pw.Text('${strings.foodGoalLabel}: $goal',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: themeColor)),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(strings.foodGeneratedByLine,
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            ...weekDays.map((day) {
              final String diaStr = DateFormat.MMMEd(strings.localeName).format(day.date).toUpperCase();
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 20),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: themeColor, width: 1.0)),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      color: themeColor,
                      child: pw.Text(diaStr, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 11)),
                    ),
                    ...day.meals.map((meal) {
                      return pw.Container(
                        decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: themeColor, width: 0.5))),
                        padding: const pw.EdgeInsets.all(12),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(_getMealLabel(meal.tipo, strings).toUpperCase(),
                                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: themeColor)),
                                if (meal.nomePrato != null)
                                  pw.Text(meal.nomePrato!, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                              ],
                            ),
                            if (meal.observacoes.isNotEmpty) ...[
                              pw.SizedBox(height: 8),
                              pw.Text(meal.observacoes, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                            ],
                            pw.SizedBox(height: 10),
                            pw.Text(strings.foodIngredientsTitle, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                            pw.SizedBox(height: 4),
                            ...meal.itens.map((item) => pw.Padding(
                                  padding: const pw.EdgeInsets.only(left: 10, bottom: 2),
                                  child: pw.Row(
                                    children: [
                                      pw.Container(width: 3, height: 3, decoration: const pw.BoxDecoration(color: themeColor, shape: pw.BoxShape.circle)),
                                      pw.SizedBox(width: 6),
                                      pw.Expanded(child: pw.Text(item.nome, style: const pw.TextStyle(fontSize: 9))),
                                      pw.Text(item.quantidadeTexto, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),

            if (w == 0 && batchCookingTips != null && batchCookingTips.isNotEmpty) ...[
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: themeColor, width: 0.5), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(strings.foodBatchCookingTips, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: themeColor)),
                    pw.SizedBox(height: 8),
                    pw.Text(batchCookingTips, style: const pw.TextStyle(fontSize: 10, height: 1.3)),
                  ],
                ),
              ),
            ],
          ],
        ),
      );

      if (w < weeklyShoppingLists.length) {
        final weekShopping = weeklyShoppingLists[w];
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(35),
            header: (context) => BasePdfHelper.buildHeader('${strings.foodShoppingListTitle}${weekLabel.toUpperCase()}', timestampStr, color: themeColor, appName: 'ScanNut'),
            footer: (context) => _buildFooter(context, strings: strings),
            build: (context) => [
              pw.Text(strings.foodShoppingListDescription(weekShopping.weekLabel), style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              pw.SizedBox(height: 15),
              ...weekShopping.categories.map((cat) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    BasePdfHelper.buildSectionHeader(cat.title, color: PdfColors.grey200, textColor: PdfColors.black),
                    pw.Wrap(
                      spacing: 20, runSpacing: 10,
                      children: cat.items.map((item) {
                        return pw.Container(
                            width: 230,
                            child: pw.Row(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Container(width: 12, height: 12, margin: const pw.EdgeInsets.only(top: 1), decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 1), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)))),
                                  pw.SizedBox(width: 8),
                                  pw.Expanded(child: pw.RichText(text: pw.TextSpan(children: [
                                    pw.TextSpan(text: '${item.quantityDisplay} · ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.black)),
                                    pw.TextSpan(text: item.name, style: const pw.TextStyle(fontSize: 10, color: PdfColors.black)),
                                    if (item.kcalTotal > 0) pw.TextSpan(text: ' — ${item.kcalTotal} kcal', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                                  ])))
                                ]));
                      }).toList(),
                    ),
                    pw.SizedBox(height: 5),
                  ],
                );
              }),
            ],
          ),
        );
      }
    }
    return pdf;
  }




  // --- PRIVATE HELPERS ---


  String _getMealLabel(String? tipo, FoodLocalizations strings) {
    if (tipo == null) return '';
    switch (tipo.toLowerCase()) {
      case 'cafe': return strings.foodMealBreakfast;
      case 'almoco': return strings.foodMealLunch;
      case 'lanche': return strings.foodMealSnack;
      case 'jantar': return strings.foodMealDinner;
      default: return tipo;
    }
  }

  PdfColor _getTrafficLightColor(String semaforo) {
    final s = semaforo.toLowerCase();
    if (s.contains('verde') || s.contains('green')) return PdfColors.green;
    if (s.contains('amarelo') || s.contains('yellow')) return PdfColors.orange;
    return PdfColors.red;
  }

  pw.Widget _buildSafeBullet(String text, {double fontSize = 9, PdfColor? color}) {
    return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Container(
              width: 4,
              height: 4,
              margin: const pw.EdgeInsets.only(top: 3, right: 6),
              decoration: pw.BoxDecoration(
                  color: color ?? PdfColors.black, shape: pw.BoxShape.circle)),
          pw.Expanded(
              child: pw.Text(text,
                  style: pw.TextStyle(fontSize: fontSize, color: PdfColors.black)))
        ]));
  }


  dynamic _deepFixMaps(dynamic value) {
    if (value is Map) return value.map<String, dynamic>((k, v) => MapEntry(k.toString(), _deepFixMaps(v)));
    if (value is List) return value.map((e) => _deepFixMaps(e)).toList();
    return value;
  }
  static pw.Widget _buildFooter(
    pw.Context context, {
    FoodLocalizations? strings,
  }) {
    final pageText = strings?.foodPage(context.pageNumber, context.pagesCount) ??
        'Página ${context.pageNumber} de ${context.pagesCount}';

    final footerLabel = strings?.foodPdfFooter ?? institutionalFooter;

    return pw.Column(
      children: [
        pw.Divider(thickness: 0.5, color: PdfColors.grey300),
        pw.SizedBox(height: 5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(footerLabel,
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
            pw.Text(pageText,
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          ],
        ),
      ],
    );
  }
}
