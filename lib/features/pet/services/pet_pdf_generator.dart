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

import '../models/lab_exam.dart';
import '../../../core/services/image_optimization_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../../core/services/partner_service.dart';
import '../services/meal_plan_service.dart'; // 🛡️ NEW: Para acessar recommendedBrands

class PetPdfGenerator {
  static final PetPdfGenerator _instance = PetPdfGenerator._internal();
  factory PetPdfGenerator() => _instance;
  PetPdfGenerator._internal();

  static final PdfColor colorPrimary = PdfColor.fromHex('#FFD1DC'); // Rosa Pastel
  static final PdfColor colorAccent = PdfColor.fromHex('#FF4081');
  static final PdfColor colorText = PdfColor.fromHex('#333333');

  Future<pw.Document> generateSingleAnalysisReport({
    required PetProfileExtended profile,
    required AppLocalizations strings,
    AnaliseFeridaModel? specificWound,
  }) async {
    final pdf = pw.Document();
    
    // 1. Load Images
    pw.ImageProvider? profileImage;
    if (profile.imagePath != null && profile.imagePath!.isNotEmpty) {
      profileImage = await _safeLoadImage(profile.imagePath!, profilePetName: profile.petName);
    }

    pw.ImageProvider? analysisImage;
    if (specificWound != null && specificWound.imagemRef.isNotEmpty) {
        analysisImage = await _safeLoadImage(specificWound.imagemRef, profilePetName: profile.petName);
    }

    // 2. Build PDF
    final font = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    pdf.addPage(
      pw.Page(
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
                   (specificWound.categoria == 'fezes' || specificWound.categoria == 'stool')
                       ? _buildStoolItem(specificWound, analysisImage, strings)
                       : _buildWoundItem(specificWound, analysisImage, strings),
               ],
            ]
          );
        },
      )
    );

    return pdf;
  }

  Future<pw.Document> generateReport({
    required PetProfileExtended profile,
    required AppLocalizations strings,
    PetAnalysisResult? currentAnalysis,
    List<File>? manualGallery,
    Map<String, DateTime>? vaccinationData, // 🛡️ NEW: Smart Vaccination Data
  }) async {
    final pdf = pw.Document();
    
    debugPrint('[PetPdfGenerator] Starting generation for ${profile.petName}');

    // --- 1. PRE-LOAD IMAGES ---
    pw.ImageProvider? profileImage;
    if (profile.imagePath != null && profile.imagePath!.isNotEmpty) {
      profileImage = await _safeLoadImage(profile.imagePath!, profilePetName: profile.petName);
    }

    // WOUNDS (Unified + Legacy)
    final List<Map<String, dynamic>> woundItems = [];
    List<AnaliseFeridaModel> fullWounds = [...profile.historicoAnaliseFeridas];
    
    if (profile.woundAnalysisHistory.isNotEmpty) {
         for (var w in profile.woundAnalysisHistory) {
             try {
               fullWounds.add(AnaliseFeridaModel(
                   dataAnalise: DateTime.tryParse(w['date']?.toString() ?? '') ?? DateTime.now(),
                   imagemRef: w['imagePath']?.toString() ?? '',
                   achadosVisuais: {},
                   nivelRisco: w['severity']?.toString() ?? strings.categoryGeneral,
                   recomendacao: (w['recommendations'] as List?)?.join(', ') ?? '',
                   diagnosticosProvaveis: w['diagnosis'] != null ? [w['diagnosis'].toString()] : [],
                   categoria: 'Legacy'
               ));
             } catch (_) {}
         }
    }
    fullWounds.sort((a,b) => b.dataAnalise.compareTo(a.dataAnalise));
    
    for (var item in fullWounds) {
       pw.ImageProvider? img;
       if (item.imagemRef.isNotEmpty) img = await _safeLoadImage(item.imagemRef, profilePetName: profile.petName);
       woundItems.add({ 'model': item, 'image': img });
    }

    // LAB EXAMS
    final List<Map<String, dynamic>> labItems = [];
    for (var examMap in profile.labExams) { 
        try {
            final e = LabExam.fromJson(examMap);
            pw.ImageProvider? img;
            if (e.filePath.isNotEmpty) img = await _safeLoadImage(e.filePath, profilePetName: profile.petName);
            labItems.add({ 'model': e, 'image': img });
        } catch (_) {}
    }
    
    // PARTNERS
    final List<Map<String, String>> partnerItems = [];
    if (profile.linkedPartnerIds.isNotEmpty) {
        try {
            final service = PartnerService();
            for (var id in profile.linkedPartnerIds) {
                final p = service.getPartner(id);
                if (p != null) {
                    partnerItems.add({
                        'name': p.name,
                        'category': p.category ?? strings.partnersFilterAll, // Fallback to 'All' or similar since generic 'Partner' key missing
                        'phone': p.phone.isNotEmpty ? p.phone : (p.whatsapp ?? p.metadata['formatted_phone_number']?.toString() ?? ''),
                        'email': p.email ?? '',
                        'email': p.email ?? '',
                        'address': p.address ?? '',
                        'notes': (profile.partnerNotes[id] as List?)?.map((n) => n['content']?.toString() ?? '').join('; ') ?? ''
                    });
                }
            }
        } catch (e) {
            debugPrint('⚠️ Error loading partners: $e');
        }
    }

    // GALERIA
    final List<Map<String, dynamic>> galleryItems = [];
    
    // 🛡️ NEW: Adiciona foto do perfil na galeria (primeiro item)
    if (profileImage != null) {
      galleryItems.add({
        'image': profileImage,
        'date': DateTime.now(), // Foto do perfil sempre aparece primeiro
        'label': strings.labelProfile
      });
    }
    
    if (manualGallery != null) {
        for (var f in manualGallery) {
            // 🛡️ V_FIX: Only include common image formats in gallery grid
            final ext = path.extension(f.path).toLowerCase();
            if (!['.jpg', '.jpeg', '.png', '.webp', '.heic'].contains(ext)) continue;

            try {
              final img = await _safeLoadImage(f.path, profilePetName: profile.petName);
              if (img != null) {
                   final stat = await f.stat();
                   galleryItems.add({
                      'image': img, 
                      'date': stat.modified, // 🛡️ Use actual file date
                      'label': strings.guideGallery
                   });
              }
            } catch (e) {
                debugPrint('⚠️ Error loading gallery image ${f.path}: $e');
            }
        }
    }
    // Sort gallery by date (newest first) - mas mantém foto do perfil sempre primeiro
    if (galleryItems.length > 1) {
        galleryItems.sort((a,b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
      }

    // GENERIC ANALYSIS HISTORY IMAGES
    final List<Map<String, dynamic>> analysisWithImages = [];
    for (var a in profile.analysisHistory) {
        pw.ImageProvider? img;
        final path = a['image_path'] ?? a['photo_path'];
        if (path != null && path.toString().isNotEmpty) {
            img = await _safeLoadImage(path.toString(), profilePetName: profile.petName);
        }
        analysisWithImages.add({'data': a, 'image': img});
    }

    // --- 2. BUILD PDF ---
    final font = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    // 🛡️ NEW: Busca recommendedBrands ANTES de construir o PDF
    List<dynamic> recommendedBrands = [];
    try {
      final mealService = MealPlanService();
      final plans = await mealService.getPlansForPet(profile.petName);
      if (plans.isNotEmpty) {
        final latestPlan = plans.first;
        recommendedBrands = latestPlan.safeRecommendedBrands;
      }
    } catch (e) {
      debugPrint('⚠️ [PDF] Erro ao buscar recommendedBrands: $e');
    }

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          // 🛡️ NEW: Await nutrition section to fetch recommendedBrands
          final nutritionWidget = _buildNutritionSection(profile, strings, recommendedBrands: recommendedBrands);
          
          return [
             _buildHeader(profile, profileImage, strings),
             pw.SizedBox(height: 20),
             
             _buildSectionTitle(strings.pdfIdentitySection, strings),
             _buildIdentityTable(profile, strings),
             pw.SizedBox(height: 10),
             
             _buildPreferences(profile, strings),
             pw.SizedBox(height: 20),
             
             _buildSectionTitle(strings.pdfParcSection, strings),
             pw.SizedBox(height: 10),
             partnerItems.isNotEmpty 
                ? _buildPartnersTable(partnerItems, strings)
                : pw.Text(strings.pdfNoInfo, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
             pw.SizedBox(height: 20),

             _buildSectionTitle(strings.pdfPlansInsurance, strings),
             pw.SizedBox(height: 10),
             _buildPlansSection(profile, strings),
             pw.SizedBox(height: 20),

             _buildSectionTitle(strings.pdfHealthSection, strings),
             _buildVaccineTable(profile, strings, vaccinationData),
             pw.SizedBox(height: 10),
             _buildWeightSection(profile, strings),
             pw.SizedBox(height: 10),
             
             _buildAllergies(profile, strings),
             pw.SizedBox(height: 20),
             
             _buildSectionTitle(strings.guideObservationsTitle, strings),
             _buildNotesSection(profile, strings),
             pw.SizedBox(height: 20),

             _buildSectionTitle(strings.pdfAnaliseFeridas.toUpperCase(), strings),
             pw.SizedBox(height: 10),
             if (woundItems.isNotEmpty)
                ...woundItems.map((e) {
                    final model = e['model'] as AnaliseFeridaModel;
                    return (model.categoria == 'fezes' || model.categoria == 'stool')
                        ? _buildStoolItem(model, e['image'], strings)
                        : _buildWoundItem(model, e['image'], strings);
                }).toList()
             else
                pw.Text(strings.fallbackNoInfo, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
             pw.SizedBox(height: 20),

             _buildSectionTitle(strings.pdfGeneralAnalysisHistory, strings),
             pw.SizedBox(height: 10),
             if (analysisWithImages.isNotEmpty)
                  ...analysisWithImages.map((e) => _buildGeneralAnalysisItem(e['data'], strings, image: e['image'])).toList()
             else
                  pw.Text(strings.pdfNoInfo, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
             pw.SizedBox(height: 20),

             _buildSectionTitle(strings.pdfLabExams, strings),
             pw.SizedBox(height: 10),
             if (labItems.isNotEmpty)
                 ...labItems.map((e) => _buildLabItem(e['model'], e['image'], strings)).toList()
             else
                 pw.Text(strings.fallbackNoInfo, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
             pw.SizedBox(height: 20),
             
             _buildSectionTitle(strings.pdfNutritionSection.toUpperCase(), strings),
             nutritionWidget, // 🛡️ NEW: Use awaited widget
             pw.SizedBox(height: 20),
             
             _buildSectionTitle(strings.pdfGallerySection.toUpperCase(), strings),
             pw.SizedBox(height: 15),
             if (galleryItems.isNotEmpty)
                 _buildGalleryGrid(galleryItems, strings)
             else 
                 pw.Text(strings.fallbackNoInfo, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ];
        },
        footer: (context) => _buildFooter(context, strings),
      )
    );

    return pdf;
  }

  // --- WIDGET BUILDERS ---

  pw.Widget _buildHeader(PetProfileExtended profile, pw.ImageProvider? image, AppLocalizations strings) {
    return pw.Row(children: [
        if (image != null)
          pw.Container(width: 80, height: 80, decoration: pw.BoxDecoration(shape: pw.BoxShape.circle, border: pw.Border.all(color: colorAccent, width: 2), image: pw.DecorationImage(image: image, fit: pw.BoxFit.cover)))
        else
          pw.Container(width: 80, height: 80, decoration: pw.BoxDecoration(color: colorPrimary, shape: pw.BoxShape.circle), child: pw.Center(child: pw.Text(profile.petName.isNotEmpty ? profile.petName[0].toUpperCase() : '?', style: pw.TextStyle(fontSize: 30, fontWeight: pw.FontWeight.bold, color: colorAccent)))),
        pw.SizedBox(width: 20),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(profile.petName, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.Text(strings.pdfReportTitle, style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
            pw.Text('${strings.pdfGeneratedOn}: ${DateFormat.yMd(strings.localeName).add_Hm().format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
        ])
    ]);
  }

  pw.Widget _buildSectionTitle(String title, AppLocalizations strings) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: pw.BoxDecoration(color: colorPrimary, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
      child: pw.Text(title, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: colorText)),
    );
  }

  pw.Widget _buildIdentityTable(PetProfileExtended profile, AppLocalizations strings) {
      final noInfo = strings.petNotOffice;
      return pw.Table(border: pw.TableBorder.all(color: PdfColors.grey300), children: [
           _buildTableRow(strings.pdfFieldBreedSpecies, '${profile.especie ?? noInfo} / ${profile.raca ?? noInfo}'),
           _buildTableRow(strings.pdfFieldAge, profile.idadeExata ?? noInfo),
           _buildTableRow(strings.pdfFieldCurrentWeight, '${profile.pesoAtual ?? noInfo} kg (${strings.pdfFieldIdealWeight}: ${profile.pesoIdeal ?? noInfo} kg)'),
           _buildTableRow('${strings.pdfFieldSex} / ${strings.pdfFieldReproductiveStatus}', '${_localizeSex(profile.sex, strings)} / ${_localizeReproStatus(profile.statusReprodutivo, strings)}'),
           if (profile.microchip != null && profile.microchip!.isNotEmpty)
                _buildTableRow(strings.pdfFieldMicrochip, profile.microchip!),
           _buildTableRow(strings.pdfFieldActivityLevel, _localizeActivityLevel(profile.nivelAtividade, strings)),
           _buildTableRow(strings.pdfFieldBathFrequency, _localizeBathFrequency(profile.frequenciaBanho, strings)),
      ]);
  }
  
  pw.TableRow _buildTableRow(String label, String value) {
     return pw.TableRow(children: [
         pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
         pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(value, style: const pw.TextStyle(fontSize: 10))),
     ]);
  }

  pw.Widget _buildPreferences(PetProfileExtended profile, AppLocalizations strings) {
      final noInfo = strings.petNotOffice;
      return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('${strings.settingsPreferences}: ${profile.preferencias.isNotEmpty ? profile.preferencias.join(", ") : noInfo}', style: const pw.TextStyle(fontSize: 10)),
          pw.Text('${strings.dietaryRestrictions}: ${profile.restricoes.isNotEmpty ? profile.restricoes.join(", ") : noInfo}', style: pw.TextStyle(fontSize: 10, color: profile.restricoes.isNotEmpty ? PdfColors.red900 : PdfColors.black)),
      ]);
  }
  
  pw.Widget _buildPartnersTable(List<Map<String, String>> partners, AppLocalizations strings) {
      return pw.Table(border: pw.TableBorder.all(color: PdfColors.grey300), children: [
           pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.grey200), children: [
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(strings.pdfPartnerName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(strings.pdfPartnerSpecialty, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(strings.pdfPartnerContact, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
           ]),
            ...partners.map((p) => pw.TableRow(children: [
               pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(p['name']!, style: const pw.TextStyle(fontSize: 9))),
               pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(p['category']!, style: const pw.TextStyle(fontSize: 9))),
               pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                   if (p['phone']!.isNotEmpty) pw.Text('${strings.labelPhone}: ${p['phone']}', style: pw.TextStyle(fontSize: 9)),
                   if (p['email']!.isNotEmpty) pw.Text('${strings.labelEmail}: ${p['email']}', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                   if (p['address']!.isNotEmpty) pw.Text(p['address']!, style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic)),
                   if (p['notes'] != null && p['notes']!.isNotEmpty) 
                       pw.Padding(
                           padding: const pw.EdgeInsets.only(top: 4),
                           child: pw.Text('${strings.labelNotes}: ${p['notes']}', style: pw.TextStyle(fontSize: 8, color: PdfColors.blueGrey800, fontStyle: pw.FontStyle.italic))
                       )
               ])),
            ]))
       ]);
  }
  
  pw.Widget _buildNotesSection(PetProfileExtended profile, AppLocalizations strings) {
      final notes = [
          if (profile.observacoesIdentidade.isNotEmpty) '${strings.tabIdentity}: ${profile.observacoesIdentidade}',
          if (profile.observacoesSaude.isNotEmpty) '${strings.tabHealth}: ${profile.observacoesSaude}',
          if (profile.observacoesNutricao.isNotEmpty) '${strings.tabNutrition}: ${profile.observacoesNutricao}',
          if (profile.observacoesGaleria.isNotEmpty) '${strings.tabGrooming}: ${profile.observacoesGaleria}',
          if (profile.observacoesPrac.isNotEmpty) '${strings.pdfParcSection}: ${profile.observacoesPrac}',
      ];
      
      if (notes.isEmpty) {
          return pw.Text(strings.petNotOffice, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700));
      }

      return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: notes.map((n) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 4), child: pw.Text('• $n', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)))).toList());
  }
  
  pw.Widget _buildVaccineTable(PetProfileExtended profile, AppLocalizations strings, Map<String, DateTime>? vaccinationData) {
      final rows = <pw.TableRow>[
          pw.TableRow(children: [pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(strings.pdfFieldEvent, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))), pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(strings.pdfDate, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)))]),
      ];

      // Use dynamic data if available, otherwise fallback to legacy
      if (vaccinationData != null && vaccinationData.isNotEmpty) {
          vaccinationData.forEach((key, date) {
              rows.add(_buildTableRow(key, DateFormat.yMd(strings.localeName).format(date)));
          });
      } else {
          // Legacy Fallback
          final v10Date = profile.dataUltimaV10 != null ? DateFormat.yMd(strings.localeName).format(profile.dataUltimaV10!) : strings.pdfPending;
          final rabDate = profile.dataUltimaAntirrabica != null ? DateFormat.yMd(strings.localeName).format(profile.dataUltimaAntirrabica!) : strings.pdfPending;
          rows.add(_buildTableRow(strings.petLastV10, v10Date));
          rows.add(_buildTableRow(strings.petLastRabies, rabDate));
      }

      return pw.Table(border: pw.TableBorder.all(color: PdfColors.grey300), children: rows);
  }

  pw.Widget _buildWeightSection(PetProfileExtended profile, AppLocalizations strings) {
      if (profile.weightHistory.isEmpty) return pw.Text('${strings.pdfWeightHistory}: ${strings.pdfNoInfo}', style: const pw.TextStyle(fontSize: 10));
      return pw.Row(children: [
         pw.Text('${strings.pdfWeightHistory} (${profile.weightHistory.length}): ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
         pw.Text(profile.weightHistory.take(10).map((e) => '${e['weight']}kg').join(' → '), style: const pw.TextStyle(fontSize: 10)),
      ]);
  }

  pw.Widget _buildAllergies(PetProfileExtended profile, AppLocalizations strings) {
      if (profile.alergiasConhecidas.isEmpty) {
          return pw.Text('${strings.pdfKnownAllergies}: ${strings.pdfNoInfo}', style: const pw.TextStyle(fontSize: 10));
      }
      return pw.Container(
         padding: const pw.EdgeInsets.all(8),
         decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.red), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
         child: pw.Text('${strings.pdfKnownAllergies}: ${profile.alergiasConhecidas.join(", ")}', style: pw.TextStyle(color: PdfColors.red, fontWeight: pw.FontWeight.bold, fontSize: 10))
      );
  }

  pw.Widget _buildWoundItem(AnaliseFeridaModel item, pw.ImageProvider? image, AppLocalizations strings) {
     final dateStr = DateFormat.yMd(strings.localeName).format(item.dataAnalise);
     PdfColor riskColor = PdfColors.green;
     if (item.nivelRisco.toLowerCase().contains('alto') || item.nivelRisco.toLowerCase().contains('vermelho')) riskColor = PdfColors.red;
     if (item.nivelRisco.toLowerCase().contains('médio') || item.nivelRisco.toLowerCase().contains('amarelo')) riskColor = PdfColors.orange;

     return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 12),
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            if (image != null) pw.Container(width: 70, height: 70, margin: const pw.EdgeInsets.only(right: 10), child: pw.Image(image, fit: pw.BoxFit.contain)),
            pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Row(children: [
                    pw.Text(dateStr, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.SizedBox(width: 10),
                    pw.Container(padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2), decoration: pw.BoxDecoration(color: riskColor, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2))), child: pw.Text(item.nivelRisco.toUpperCase(), style: const pw.TextStyle(color: PdfColors.white, fontSize: 8)))
                ]),
                pw.SizedBox(height: 4),
                pw.Text('${strings.termDiagnosis}: ${_localizeDiagnosisList(item.diagnosticosProvaveis, strings).join(", ")}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                if (item.descricaoVisual != null && item.descricaoVisual!.isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    pw.Text(item.descricaoVisual!, style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic), maxLines: 6),
                ],
                pw.SizedBox(height: 4),
                pw.Text(item.recomendacao, style: const pw.TextStyle(fontSize: 9), maxLines: 6),
            ]))
        ])
     );
  }

  pw.Widget _buildStoolItem(AnaliseFeridaModel item, pw.ImageProvider? image, AppLocalizations strings) {
      final dateStr = DateFormat.yMd(strings.localeName).format(item.dataAnalise);
      PdfColor riskColor = PdfColors.green;
      if (item.nivelRisco.toLowerCase().contains('alto') || item.nivelRisco.toLowerCase().contains('vermelho')) riskColor = PdfColors.red;
      if (item.nivelRisco.toLowerCase().contains('médio') || item.nivelRisco.toLowerCase().contains('amarelo')) riskColor = PdfColors.orange;

      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 12),
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            if (image != null) pw.Container(width: 70, height: 70, margin: const pw.EdgeInsets.only(right: 10), child: pw.Image(image, fit: pw.BoxFit.contain)),
            pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                 pw.Row(children: [
                    pw.Text('$dateStr - Bristol ${item.achadosVisuais['bristol_scale'] ?? "-"}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.SizedBox(width: 10),
                    pw.Container(padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2), decoration: pw.BoxDecoration(color: riskColor, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2))), child: pw.Text(item.nivelRisco.toUpperCase(), style: const pw.TextStyle(color: PdfColors.white, fontSize: 8)))
                ]),
                pw.SizedBox(height: 4),
                if (item.diagnosticosProvaveis.isNotEmpty)
                    pw.Text('${strings.pdfCauses}: ${_localizeDiagnosisList(item.diagnosticosProvaveis, strings).join(", ")}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                if (item.descricaoVisual != null && item.descricaoVisual!.isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    pw.Text(item.descricaoVisual!, style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic), maxLines: 6),
                ],
                pw.SizedBox(height: 4),
                pw.Text(item.recomendacao, style: const pw.TextStyle(fontSize: 9), maxLines: 6),
            ]))
        ])
      );
  }

  pw.Widget _buildLabItem(LabExam item, pw.ImageProvider? image, AppLocalizations strings) {
      final dateStr = DateFormat.yMd(strings.localeName).format(item.uploadDate);
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 12),
        child: pw.Row(children: [
            if (image != null) pw.Container(width: 70, height: 70, margin: const pw.EdgeInsets.only(right: 10), child: pw.Image(image, fit: pw.BoxFit.contain)),
            pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('$dateStr - ${_localizeLabCategory(item.category, strings).toUpperCase()}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                if (item.aiExplanation != null) 
                   pw.Container(
                     margin: const pw.EdgeInsets.only(top: 4),
                     padding: const pw.EdgeInsets.all(6),
                     decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
                     child: pw.Text(item.aiExplanation!.replaceAll('\n', ' '), style: const pw.TextStyle(fontSize: 8, color: PdfColors.black))
                   )
            ]))
        ])
      );
  }

  pw.Widget _buildNutritionSection(PetProfileExtended profile, AppLocalizations strings, {List<dynamic> recommendedBrands = const []}) {
    final diet = profile.rawAnalysis?['tipo_dieta'] ?? strings.fallbackNoInfo;
    final plan = profile.rawAnalysis?['plano_semanal'];

    final nutritionData = profile.rawAnalysis?['nutrition'];
    String? kcal;
    if (nutritionData != null && nutritionData is Map) {
        final kA = nutritionData['kcal_adult'] ?? nutritionData['kcal_adulto'];
        if (kA != null) kcal = '$kA ${strings.unitKcalPerDay}';
    }

    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Row(children: [
           pw.Text('${strings.pdfDietType}: $diet', style: const pw.TextStyle(fontSize: 10)),
           if (kcal != null) ...[
               pw.SizedBox(width: 20),
               pw.Text('${strings.pdfCaloricGoal}: $kcal', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
           ]
        ]),
        if (plan != null && plan is List && plan.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Text(strings.pdfWeeklyPlan, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),
            pw.Table(border: pw.TableBorder.all(color: PdfColors.grey300), children: [
                pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.grey200), children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(strings.pdfDay, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(strings.pdfMeal, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                ]),
                ...plan.map((e) {
                    final day = e['dia']?.toString() ?? '-';
                    final refeicoes = (e['refeicoes'] as List?)?.map((r) => r['descricao']?.toString() ?? '').join('\\n') ?? (e['descricao']?.toString() ?? '-');
                    return pw.TableRow(children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(day, style: const pw.TextStyle(fontSize: 8))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(refeicoes, style: const pw.TextStyle(fontSize: 8))),
                    ]);
                }).toList()
            ])
        ],
        
        // 🛡️ NEW: Seção de Sugestões de Marcas (Atualizado para BrandSuggestion)
        if (recommendedBrands.isNotEmpty) ...[
          pw.SizedBox(height: 15),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
               color: PdfColor.fromHex('#E8F5E9'), // Light green background
               border: pw.Border.all(color: PdfColor.fromHex('#4CAF50'), width: 1.0),
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
                        child: pw.Text('i', style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(strings.pdfBrandSuggestions, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColor.fromHex('#2E7D32'))),
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
                        pw.Text('• ', style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('#4CAF50'), fontWeight: pw.FontWeight.bold)),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                brandName, 
                                style: pw.TextStyle(
                                  fontSize: 10, 
                                  color: PdfColors.black, 
                                  fontWeight: pw.FontWeight.bold
                                )
                              ),
                              if (reason != null && reason.isNotEmpty)
                                pw.Text(
                                  reason,
                                  style: pw.TextStyle(
                                    fontSize: 9, 
                                    color: PdfColors.grey700, 
                                    fontStyle: pw.FontStyle.italic
                                  )
                                ),
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
                    color: PdfColor.fromHex('#FFF9C4'), // Light yellow for disclaimer
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Text(
                    strings.pdfLegalDisclaimer,
                    style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: PdfColors.black),
                  ),
                ),
              ],
            ),
          ),
        ],
    ]);
  }
  
  pw.Widget _buildGalleryGrid(List<Map<String, dynamic>> items, AppLocalizations strings) {
      return pw.Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items.map((e) {
              final image = e['image'] as pw.ImageProvider;
              final date = DateFormat.yMd(strings.localeName).format(e['date'] as DateTime);
              final label = e['label'] as String;
              return pw.Container(
                  width: 140,
                  height: 160,
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
                  child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                      pw.Expanded(child: pw.ClipRRect(horizontalRadius: 4, verticalRadius: 4, child: pw.Image(image, fit: pw.BoxFit.cover))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('$date\n$label', style: const pw.TextStyle(fontSize: 9)))
                  ])
              );
          }).toList()
      );
  }

  pw.Widget _buildFooter(pw.Context context, AppLocalizations strings) {
    return pw.Container(
        margin: const pw.EdgeInsets.only(top: 20), 
        child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
                pw.Text(strings.pdfFooterText, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                pw.Text('ScanNut - ${strings.pdfPage(context.pageNumber, context.pagesCount)}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500))
            ]
        )
    );
  }

  Future<pw.ImageProvider?> _safeLoadImage(String pathStr, {String? profilePetName}) async {
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
               final vaultPath = path.join(support.path, 'media_vault', 'pets', profilePetName ?? '', basename);
               final vFile = File(vaultPath);
               
               if (await vFile.exists()) {
                   file = vFile;
                   debugPrint('✨ [PDF] Recovered from Vault: ${file.path}');
               } else {
                    // Try Documents (Legacy)
                    final legacyPath = path.join(docs.path, 'medical_docs', profilePetName ?? '', basename);
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
           final opt = await ImageOptimizationService().loadOptimizedBytes(originalPath: file.path); 
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
      if (s == 'female' || s == 'fêmea' || s == 'femea') return strings.gender_female;
      return sex;
  }

  String _localizeReproStatus(String? status, AppLocalizations strings) {
      if (status == null) return '-';
      final s = status.toLowerCase();
      if (s.contains('castrado') || s.contains('neutered')) return strings.petNeutered;
      if (s.contains('inteiro') || s.contains('intacto') || s.contains('intact')) return strings.petIntact;
      return status;
  }

  String _localizeActivityLevel(String? level, AppLocalizations strings) {
      if (level == null) return '-';
      final l = level.toLowerCase();
      if (l.contains('baixo') || l.contains('low') || l.contains('sedentário')) return strings.petActivityLow;
      if (l.contains('moderado') || l.contains('moderate')) return strings.petActivityModerate;
      if (l.contains('ativo') || l.contains('alto') || l.contains('high')) return strings.petActivityHigh;
      if (l.contains('atleta') || l.contains('athlete')) return strings.petActivityAthlete;
      return level;
  }

  String _localizeBathFrequency(String? freq, AppLocalizations strings) {
      if (freq == null) return '-';
      final f = freq.toLowerCase();
      if (f.contains('semanal') || f.contains('weekly')) return strings.petBathWeekly;
      if (f.contains('quinzenal') || f.contains('biweekly')) return strings.labelFortnightly;
      if (f.contains('mensal') || f.contains('monthly')) return strings.petBathMonthly;
      return freq;
  }

  String _localizeLabCategory(String cat, AppLocalizations strings) {
      final c = cat.toLowerCase();
      if (c.contains('blood') || c.contains('sangue')) return strings.labCategoryBlood;
      if (c.contains('urine') || c.contains('urina')) return strings.labCategoryUrine;
      if (c.contains('fezes') || c.contains('stool')) return strings.labCategoryFeces;
      if (c.contains('ultras') || c.contains('raio') || c.contains('x-ray') || c.contains('image')) return strings.labCategoryImaging;
      return cat;
  }

  List<String> _localizeDiagnosisList(List<String> input, AppLocalizations strings) {
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
          for(var k in map.keys) {
              if (low == k || low.contains(k)) return map[k]!;
          }
          return e;
      }).toList();
   }

   pw.Widget _buildPlansSection(PetProfileExtended profile, AppLocalizations strings) {
       final activePlans = [];
       if (profile.healthPlan?['active'] == true) activePlans.add({'type': 'health', 'data': profile.healthPlan});
       if (profile.assistancePlan?['active'] == true) activePlans.add({'type': 'assistance', 'data': profile.assistancePlan});
       if (profile.funeralPlan?['active'] == true) activePlans.add({'type': 'funeral', 'data': profile.funeralPlan});
       if (profile.lifeInsurance?['active'] == true) activePlans.add({'type': 'life', 'data': profile.lifeInsurance});

       if (activePlans.isEmpty && profile.observacoesPlanos.isEmpty) {
           return pw.Text('Sem planos ativos ou observações.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700));
       }

       return pw.Column(
           crossAxisAlignment: pw.CrossAxisAlignment.start,
           children: [
               ...activePlans.map((p) {
                   final type = p['type'] as String;
                   final data = p['data'] as Map<String, dynamic>;
                   
                   String title = '';
                   List<String> details = [];

                   if (type == 'health') {
                       title = 'SAÚDE VETERINÁRIA';
                       final name = data['name'] ?? '-';
                       details.add('Operadora: $name');
                       if (data['monthly_value'] != null) details.add('Mensalidade: R\$ ${data['monthly_value']}');
                       
                       String planType = data['type'] == 'reimbursement' ? 'Reembolso' : 'Rede Credenciada';
                       details.add('Tipo: $planType');

                       List<String> coverage = [];
                       if (data['covers_consults'] == true) coverage.add('Consultas');
                       if (data['covers_exams'] == true) coverage.add('Exames');
                       if (data['covers_surgeries'] == true) coverage.add('Cirurgias');
                       if (data['covers_emergencies'] == true) coverage.add('Emergências');
                       if (data['covers_hospitalization'] == true) coverage.add('Internação');
                       if (data['covers_vaccines'] == true) coverage.add('Vacinas');
                       if (coverage.isNotEmpty) details.add('Cobertura: ${coverage.join(", ")}');
                   } 
                   else if (type == 'assistance') {
                       title = 'ASSISTÊNCIA / REEMBOLSO';
                       final name = data['name'] ?? '-';
                       details.add('Operadora: $name');
                       if (data['max_value'] != null) details.add('Limite Máximo: R\$ ${data['max_value']}');
                       
                       String rType = data['reimbursement_type'] == 'partial' ? 'Parcial' : 'Total';
                       details.add('Reembolso: $rType');
                       if (data['needs_invoice'] == true) details.add('Exige Nota Fiscal: Sim');
                   }
                   else if (type == 'funeral') {
                       title = 'PLANO FUNERÁRIO';
                       final name = data['name'] ?? '-';
                       details.add('Operadora: $name');
                       if (data['emergency_contact'] != null) details.add('Contato 24h: ${data['emergency_contact']}');
                       if (data['support_24h'] == true) details.add('Suporte 24h: Sim');

                       List<String> svcs = [];
                       if (data['incl_wake'] == true) svcs.add('Velório');
                       if (data['incl_crem_indiv'] == true) svcs.add('Cremação Indiv.');
                       if (data['incl_crem_coll'] == true) svcs.add('Cremação Coletiva');
                       if (data['incl_transport'] == true) svcs.add('Translado');
                       if (data['incl_memorial'] == true) svcs.add('Memorial');
                       if (svcs.isNotEmpty) details.add('Serviços: ${svcs.join(", ")}');
                   }
                   else if (type == 'life') {
                       title = 'SEGURO DE VIDA';
                       final name = data['insurer'] ?? '-';
                       details.add('Seguradora: $name');
                       if (data['insured_value'] != null) details.add('Capital Segurado: R\$ ${data['insured_value']}');
                       if (data['has_economic_value'] == true) details.add('Possui Valor Econômico: Sim');

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
                               pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: colorAccent)),
                               pw.SizedBox(height: 4),
                               ...details.map((d) => pw.Padding(
                                   padding: const pw.EdgeInsets.only(bottom: 2),
                                   child: pw.Text(d, style: const pw.TextStyle(fontSize: 9))
                               )).toList(),
                           ]
                       )
                   );
               }).toList(),
               if (profile.observacoesPlanos.isNotEmpty) ...[
                   pw.SizedBox(height: 10),
                   pw.Text('Observações de Planos:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                   pw.Text(profile.observacoesPlanos, style: const pw.TextStyle(fontSize: 10)),
               ]
           ]
       );
   }

   pw.Widget _buildGeneralAnalysisItem(Map<String, dynamic> data, AppLocalizations strings, {pw.ImageProvider? image}) {
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
        final type = typeMap[rawType] ?? (data['analysis_type']?.toString().toUpperCase() ?? 'ANÁLISE');

        String dateStr = '-';
        if (data['last_updated'] != null) {
           try {
              final dt = DateTime.parse(data['last_updated'].toString());
              dateStr = DateFormat.yMd(strings.localeName).add_Hm().format(dt);
           } catch (_) {}
        }
        
        final ignoredKeys = ['analysis_type', 'last_updated', 'pet_name', 'tabela_benigna', 'tabela_maligna', 'plano_semanal', 'weekly_plan', 'data_inicio_semana', 'data_fim_semana', 'orientacoes_gerais', 'general_guidelines', 'start_date', 'end_date', 'identificacao', 'identification', 'clinical_signs', 'sinais_clinicos', 'metadata', 'temperament', 'temperamento', 'image_path', 'photo_path'];
        
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
            if (e.value == null || e.value.toString() == 'null' || e.value.toString().trim().isEmpty) return false;
            return true;
        }).toList();

        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 12),
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (image != null) 
                 pw.Container(
                    width: 70, 
                    height: 70, 
                    margin: const pw.EdgeInsets.only(right: 12),
                    child: pw.Image(image, fit: pw.BoxFit.contain)
                 ),
              pw.Expanded(
                 child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start, 
                    children: [
                        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                             pw.Text(type, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: colorAccent)),
                             pw.Text(dateStr, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                        ]),
                        pw.Divider(color: PdfColors.grey200, thickness: 0.5),
                        ...entries.map((e) {
                             final label = keyLocalization[e.key] ?? e.key;
                             final val = e.value.toString().replaceAll('{', '').replaceAll('}', ''); 
                             return pw.Padding(padding: const pw.EdgeInsets.only(bottom: 2), child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                                 pw.Container(width: 80, child: pw.Text('$label: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.grey800))),
                                 pw.Expanded(child: pw.Text(val, style: const pw.TextStyle(fontSize: 9))),
                             ]));
                        }).toList()
                    ]
                 )
              )
            ]
          )
        );
   }
}
