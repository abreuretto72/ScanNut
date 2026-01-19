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

import '../models/lab_exam.dart';
import '../../../core/services/image_optimization_service.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/services/partner_service.dart';

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
      profileImage = await _safeLoadImage(profile.imagePath!);
    }

    pw.ImageProvider? analysisImage;
    if (specificWound != null && specificWound.imagemRef.isNotEmpty) {
        analysisImage = await _safeLoadImage(specificWound.imagemRef);
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
                   _buildSectionTitle('DETALHES DA ANÁLISE CLÍNICA', strings),
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
    List<File>? manualGallery, // 🛡️ Added
  }) async {
    final pdf = pw.Document();
    
    debugPrint('[PetPdfGenerator] Starting generation for ${profile.petName}');

    // --- 1. PRE-LOAD IMAGES ---
    pw.ImageProvider? profileImage;
    if (profile.imagePath != null && profile.imagePath!.isNotEmpty) {
      profileImage = await _safeLoadImage(profile.imagePath!);
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
                   nivelRisco: w['severity']?.toString() ?? 'Geral',
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
       if (item.imagemRef.isNotEmpty) img = await _safeLoadImage(item.imagemRef);
       woundItems.add({ 'model': item, 'image': img });
    }

    // LAB EXAMS
    final List<Map<String, dynamic>> labItems = [];
    for (var examMap in profile.labExams) { 
        try {
            final e = LabExam.fromJson(examMap);
            pw.ImageProvider? img;
            if (e.filePath.isNotEmpty) img = await _safeLoadImage(e.filePath);
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
                        'category': p.category ?? 'Parceiro',
                        'phone': p.phone.isNotEmpty ? p.phone : (p.whatsapp ?? p.metadata['formatted_phone_number']?.toString() ?? ''),
                        'email': p.email ?? '',
                        'address': p.address ?? ''
                    });
                }
            }
        } catch (e) {
            debugPrint('⚠️ Error loading partners: $e');
        }
    }

    // GALERIA
    final List<Map<String, dynamic>> galleryItems = [];
    if (manualGallery != null) {
        for (var f in manualGallery) {
            final img = await _safeLoadImage(f.path);
            if (img != null) {
                 galleryItems.add({
                    'image': img, 
                    'date': DateTime.now(), // Fallback
                    'label': 'Galeria'
                 });
            }
        }
    }

    // --- 2. BUILD PDF ---
    final font = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
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
                ? _buildPartnersTable(partnerItems)
                : pw.Text('Sem informação', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
             pw.SizedBox(height: 20),

             _buildSectionTitle(strings.pdfHealthSection, strings),
             _buildVaccineTable(profile, strings),
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
                pw.Text('Sem informação', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
             pw.SizedBox(height: 20),

             _buildSectionTitle('EXAMES LABORATORIAIS', strings),
             pw.SizedBox(height: 10),
             if (labItems.isNotEmpty)
                 ...labItems.map((e) => _buildLabItem(e['model'], e['image'], strings)).toList()
             else
                 pw.Text('Sem informação', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
             pw.SizedBox(height: 20),
             
             _buildSectionTitle(strings.pdfNutritionSection.toUpperCase(), strings),
             _buildNutritionSection(profile, strings),
             pw.SizedBox(height: 20),
             
             pw.NewPage(), 
             _buildSectionTitle(strings.pdfGallerySection.toUpperCase(), strings),
             pw.SizedBox(height: 15),
             if (galleryItems.isNotEmpty)
                 _buildGalleryGrid(galleryItems, strings)
             else 
                 pw.Text('Sem informação', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ];
        },
        footer: (context) => _buildFooter(context),
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
      final noInfo = 'Sem informação';
      return pw.Table(border: pw.TableBorder.all(color: PdfColors.grey300), children: [
           _buildTableRow('Espécie / Raça', '${profile.especie ?? noInfo} / ${profile.raca ?? noInfo}'),
           _buildTableRow('Porte', profile.porte ?? noInfo),
           _buildTableRow('Idade', profile.idadeExata ?? noInfo),
           _buildTableRow('Peso', '${profile.pesoAtual ?? noInfo} kg (Ideal: ${profile.pesoIdeal ?? noInfo} kg)'),
           _buildTableRow('Sexo / Castrado', '${_localizeSex(profile.sex, strings)} / ${profile.statusReprodutivo ?? noInfo}'),
           _buildTableRow('Nível de Atividade', profile.nivelAtividade ?? noInfo),
           _buildTableRow('Frequência de Banho', profile.frequenciaBanho ?? noInfo),
      ]);
  }
  
  pw.TableRow _buildTableRow(String label, String value) {
     return pw.TableRow(children: [
         pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
         pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(value, style: const pw.TextStyle(fontSize: 10))),
     ]);
  }

  pw.Widget _buildPreferences(PetProfileExtended profile, AppLocalizations strings) {
      final noInfo = 'Sem informação';
      return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('Preferências: ${profile.preferencias.isNotEmpty ? profile.preferencias.join(", ") : noInfo}', style: const pw.TextStyle(fontSize: 10)),
          pw.Text('Restrições: ${profile.restricoes.isNotEmpty ? profile.restricoes.join(", ") : noInfo}', style: pw.TextStyle(fontSize: 10, color: profile.restricoes.isNotEmpty ? PdfColors.red900 : PdfColors.black)),
      ]);
  }
  
  pw.Widget _buildPartnersTable(List<Map<String, String>> partners) {
      return pw.Table(border: pw.TableBorder.all(color: PdfColors.grey300), children: [
          pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.grey200), children: [
             pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Nome', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
             pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Especialidade', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
             pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Contato', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
          ]),
           ...partners.map((p) => pw.TableRow(children: [
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(p['name']!, style: const pw.TextStyle(fontSize: 9))),
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(p['category']!, style: const pw.TextStyle(fontSize: 9))),
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  if (p['phone']!.isNotEmpty) pw.Text('Tel: ${p['phone']}', style: pw.TextStyle(fontSize: 9)),
                  if (p['email']!.isNotEmpty) pw.Text('Email: ${p['email']}', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                  if (p['address']!.isNotEmpty) pw.Text(p['address']!, style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic)),
              ])),
           ]))
      ]);
  }
  
  pw.Widget _buildNotesSection(PetProfileExtended profile, AppLocalizations strings) {
      final notes = [
          if (profile.observacoesIdentidade.isNotEmpty) 'Ident/Comp: ${profile.observacoesIdentidade}',
          if (profile.observacoesSaude.isNotEmpty) 'Saúde: ${profile.observacoesSaude}',
          if (profile.observacoesNutricao.isNotEmpty) 'Nutrição: ${profile.observacoesNutricao}',
          if (profile.observacoesGaleria.isNotEmpty) 'Galeria: ${profile.observacoesGaleria}',
          if (profile.observacoesPrac.isNotEmpty) 'Outros: ${profile.observacoesPrac}',
      ];
      
      if (notes.isEmpty) {
          return pw.Text('Sem informação', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700));
      }

      return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: notes.map((n) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 4), child: pw.Text('• $n', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)))).toList());
  }
  
  pw.Widget _buildVaccineTable(PetProfileExtended profile, AppLocalizations strings) {
      final v10Date = profile.dataUltimaV10 != null ? DateFormat.yMd(strings.localeName).format(profile.dataUltimaV10!) : 'Pendente';
      final rabDate = profile.dataUltimaAntirrabica != null ? DateFormat.yMd(strings.localeName).format(profile.dataUltimaAntirrabica!) : 'Pendente';
      return pw.Table(border: pw.TableBorder.all(color: PdfColors.grey300), children: [
          pw.TableRow(children: [pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Vacina', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))), pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Última Dose', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)))]),
          _buildTableRow('Múltipla (V8/V10)', v10Date),
          _buildTableRow('Antirrábica', rabDate),
      ]);
  }

  pw.Widget _buildWeightSection(PetProfileExtended profile, AppLocalizations strings) {
      if (profile.weightHistory.isEmpty) return pw.Text('Histórico de Peso: Sem informação', style: const pw.TextStyle(fontSize: 10));
      return pw.Row(children: [
         pw.Text('Histórico de Peso (${profile.weightHistory.length} registros): ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
         pw.Text(profile.weightHistory.take(3).map((e) => '${e['weight']}kg').join(' → '), style: const pw.TextStyle(fontSize: 10)),
      ]);
  }

  pw.Widget _buildAllergies(PetProfileExtended profile, AppLocalizations strings) {
      if (profile.alergiasConhecidas.isEmpty) {
          return pw.Text('ALERGIAS CONHECIDAS: Sem informação', style: const pw.TextStyle(fontSize: 10));
      }
      return pw.Container(
         padding: const pw.EdgeInsets.all(8),
         decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.red), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
         child: pw.Text('ALERGIAS CONHECIDAS: ${profile.alergiasConhecidas.join(", ")}', style: pw.TextStyle(color: PdfColors.red, fontWeight: pw.FontWeight.bold, fontSize: 10))
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
                pw.Text('Diagnósticos: ${_localizeDiagnosisList(item.diagnosticosProvaveis, strings).join(", ")}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
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
                    pw.Text('Causas: ${_localizeDiagnosisList(item.diagnosticosProvaveis, strings).join(", ")}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
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

  pw.Widget _buildNutritionSection(PetProfileExtended profile, AppLocalizations strings) {
      final diet = profile.rawAnalysis?['tipo_dieta'] ?? 'Não especificada';
      final plan = profile.rawAnalysis?['plano_semanal'];

      return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('Tipo de Dieta: $diet', style: const pw.TextStyle(fontSize: 10)),
          if (plan != null && plan is List && plan.isNotEmpty) ...[
              pw.SizedBox(height: 10),
              pw.Text('PLANO SEMANAL', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              pw.Table(border: pw.TableBorder.all(color: PdfColors.grey300), children: [
                  pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.grey200), children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Dia', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Refeição', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                  ]),
                  ...plan.map((e) {
                      final day = e['dia']?.toString() ?? '-';
                      final refeicoes = (e['refeicoes'] as List?)?.map((r) => r['descricao']?.toString() ?? '').join('\n') ?? (e['descricao']?.toString() ?? '-');
                      return pw.TableRow(children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(day, style: const pw.TextStyle(fontSize: 8))),
                          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(refeicoes, style: const pw.TextStyle(fontSize: 8))),
                      ]);
                  }).toList()
              ])
          ]
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

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(alignment: pw.Alignment.centerRight, margin: const pw.EdgeInsets.only(top: 20), child: pw.Text('ScanNut - Página ${context.pageNumber} de ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)));
  }

  Future<pw.ImageProvider?> _safeLoadImage(String pathStr) async {
       if (pathStr.isEmpty) return null;
       String cleanPath = pathStr;
       if (cleanPath.startsWith('file://')) cleanPath = cleanPath.substring(7);
       
       debugPrint('🖼️ [PDF] Attempting to load: $cleanPath');
       File file = File(cleanPath);
       
       if (!await file.exists()) {
           try {
               final docs = await getApplicationDocumentsDirectory();
               final altPath1 = '${docs.path}/$cleanPath';
               if (await File(altPath1).exists()) {
                   file = File(altPath1);
               } else {
                    final basename = cleanPath.split('/').last;
                    final altPath2 = '${docs.path}/$basename';
                    if (await File(altPath2).exists()) {
                        file = File(altPath2);
                    } else {
                        return null;
                    }
               }
           } catch (e) {
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
      if (s == 'male' || s == 'macho') return 'Macho';
      if (s == 'female' || s == 'fêmea' || s == 'femea') return 'Fêmea';
      return sex;
  }

  String _localizeLabCategory(String cat, AppLocalizations strings) {
      final c = cat.toLowerCase();
      if (c.contains('blood') || c.contains('sangue')) return 'Exame de Sangue';
      if (c.contains('urine') || c.contains('urina')) return 'Urina';
      if (c.contains('fezes') || c.contains('stool')) return 'Fezes';
      if (c.contains('ultras') || c.contains('raio') || c.contains('x-ray') || c.contains('image')) return 'Imagem';
      return cat;
  }

  List<String> _localizeDiagnosisList(List<String> input, AppLocalizations strings) {
      const map = {
         'obesity': 'Obesidade',
         'overweight': 'Sobrepeso',
         'underweight': 'Abaixo do peso',
         'dermatitis': 'Dermatite',
         'disbiosis': 'Disbiose',
         'parasites': 'Parasitas',
         'infection': 'Infecção',
         'inflammation': 'Inflamação',
         'tartar': 'Tártaro',
         'gingivitis': 'Gengivite',
         'plaque': 'Placa bacteriana',
         'mass': 'Nódulo/Massa',
         'tumor': 'Tumor',
         'allergy': 'Alergia',
         'anemia': 'Anemia',
         'fracture': 'Fratura',
         'pain': 'Dor',
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
}
