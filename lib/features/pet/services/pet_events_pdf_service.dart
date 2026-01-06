import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/services/export_service.dart';
import '../models/pet_event_model.dart';
import '../models/pet_profile_extended.dart';
import '../services/pet_event_repository.dart';
import '../services/pet_profile_service.dart';

class PetEventsPdfService {
  static final PetEventsPdfService _instance = PetEventsPdfService._internal();
  factory PetEventsPdfService() => _instance;
  PetEventsPdfService._internal();

  final _exportService = ExportService();
  final _repo = PetEventRepository();
  final _profileService = PetProfileService();

  Future<File?> generateReport({
    required String petId,
    required DateTime start,
    required DateTime end,
    String? groupFilter,
    bool onlyIncludeInPdf = true,
    required AppLocalizations l10n,
  }) async {
    try {
      debugPrint('PET_EVENTS_PDF: Generating report for $petId ($start to $end)');
      
      final profileMap = await _profileService.getProfile(petId);
      final profile = profileMap != null ? PetProfileExtended.fromHiveEntry(profileMap) : null;
      
      var events = _repo.listEventsByPet(petId, from: start, to: end);
      
      if (groupFilter != null && groupFilter != 'all') {
        events = events.where((e) => e.group == groupFilter).toList();
      }
      
      if (onlyIncludeInPdf) {
        events = events.where((e) => e.includeInPdf).toList();
      }

      final pdf = pw.Document();
      final timestampStr = DateFormat.yMd(l10n.localeName).add_Hm().format(DateTime.now());
      final periodStr = '${DateFormat.yMd(l10n.localeName).format(start)} - ${DateFormat.yMd(l10n.localeName).format(end)}';

      // 1. Pre-load Pet Photo
      pw.ImageProvider? petPhoto;
      if (profile?.imagePath != null) {
        petPhoto = await _exportService.safeLoadImage(profile!.imagePath);
      }

      // 2. Pre-load Event Thumbnails (max 12 total)
      final thumbnails = <String, List<pw.ImageProvider>>{};
      int totalImagesLoaded = 0;
      const int maxImagesTotal = 12;

      for (var event in events) {
        final images = event.attachments.where((a) => a.kind == 'image').take(3).toList();
        for (var img in images) {
          if (totalImagesLoaded >= maxImagesTotal) break;
          final provider = await _exportService.safeLoadImage(img.path);
          if (provider != null) {
            thumbnails[event.id] ??= [];
            thumbnails[event.id]!.add(provider);
            totalImagesLoaded++;
          }
        }
      }

      // Group counts
      final counts = <String, int>{};
      for (var e in events) {
        counts[e.group] = (counts[e.group] ?? 0) + 1;
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(35),
          header: (context) => _exportService.buildHeader(l10n.petEvent_reportTitle, timestampStr),
          footer: (context) => _exportService.buildFooter(context, strings: l10n),
          build: (context) => [
            // Header Info Card
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                border: pw.Border.all(color: PdfColors.blue800, width: 0.5),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                   if (petPhoto != null) ...[
                     pw.Container(
                       width: 60,
                       height: 60,
                       decoration: pw.BoxDecoration(
                         shape: pw.BoxShape.circle,
                         image: pw.DecorationImage(image: petPhoto, fit: pw.BoxFit.cover),
                       ),
                     ),
                     pw.SizedBox(width: 15),
                   ],
                   pw.Expanded(
                     child: pw.Column(
                       crossAxisAlignment: pw.CrossAxisAlignment.start,
                       children: [
                         pw.Text(petId.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                         pw.SizedBox(height: 4),
                         pw.Text('${l10n.petEvent_reportPeriod}: $periodStr', style: const pw.TextStyle(fontSize: 10, color: PdfColors.blue700)),
                         if (profile?.raca != null)
                           pw.Text(profile!.raca!, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                       ],
                     ),
                   ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Summary Section
            pw.Text(l10n.petEvent_reportSummary.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
            pw.SizedBox(height: 10),
            pw.Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _exportService.buildIndicator(l10n.petEvent_reportTotal, events.length.toString(), PdfColors.black),
                ...counts.entries.map((c) => _exportService.buildIndicator(_getGroupLabel(c.key, l10n), c.value.toString(), PdfColors.blue700)),
              ],
            ),
            pw.SizedBox(height: 25),

            // Timeline Section
            ..._groupEventsByDate(events).entries.map((entry) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    color: PdfColors.grey200,
                    child: pw.Text(
                      DateFormat.yMMMMEEEEd(l10n.localeName).format(entry.key).toUpperCase(),
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  ...entry.value.map((event) {
                    final eventThumbnails = thumbnails[event.id] ?? [];
                    final otherAttachments = event.attachments.where((a) => a.kind != 'image').toList();
                    
                    return pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 15, left: 10),
                      padding: const pw.EdgeInsets.only(left: 10),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(left: pw.BorderSide(color: PdfColors.blue100, width: 2)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            children: [
                              pw.Text(DateFormat.Hm().format(event.timestamp), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.blue900)),
                              pw.SizedBox(width: 8),
                              pw.Text('[${_getGroupLabel(event.group, l10n)}]', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                              pw.SizedBox(width: 8),
                              pw.Expanded(child: pw.Text(event.title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                            ],
                          ),
                          if (event.notes.isNotEmpty) ...[
                             pw.SizedBox(height: 4),
                             pw.Text(event.notes, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                          ],
                          
                          // Dynamic Data
                          if (event.data.isNotEmpty) ...[
                             pw.SizedBox(height: 6),
                             pw.Wrap(
                               spacing: 8,
                               children: event.data.entries.map((d) {
                                  if (d.value == null || d.value.toString().isEmpty) return pw.SizedBox.shrink();
                                  return pw.Text('${d.key}: ${d.value}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700, fontStyle: pw.FontStyle.italic));
                               }).toList(),
                             ),
                          ],

                          // Images / Thumbnails
                          if (eventThumbnails.isNotEmpty) ...[
                             pw.SizedBox(height: 10),
                             pw.Wrap(
                               spacing: 8,
                               children: eventThumbnails.map((prov) => pw.Container(
                                 width: 80,
                                 height: 80,
                                 decoration: pw.BoxDecoration(
                                   border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                                   image: pw.DecorationImage(image: prov, fit: pw.BoxFit.cover),
                                 ),
                               )).toList(),
                             ),
                          ],

                          // List of Other Attachments
                          if (otherAttachments.isNotEmpty) ...[
                             pw.SizedBox(height: 8),
                             ...otherAttachments.map((a) => pw.Row(
                               children: [
                                  pw.Text('📎 ', style: const pw.TextStyle(fontSize: 8)),
                                  pw.Text('${_getKindLabel(a.kind)}: ${a.path.split('/').last} (${_formatSize(a.size)})', style: const pw.TextStyle(fontSize: 7, color: PdfColors.blue800)),
                               ],
                             )).toList(),
                          ],
                          pw.SizedBox(height: 10),
                        ],
                      ),
                    );
                  }).toList(),
                  pw.SizedBox(height: 15),
                ],
              );
            }).toList(),
          ],
        ),
      );

      final bytes = await pdf.save();
      final directory = await getTemporaryDirectory(); 
      String fileName = 'Relatorio_${petId}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);

      // Save to Downloads
      try {
        if (!kIsWeb) {
          Directory? downloadsDir;
          if (Platform.isAndroid) {
            downloadsDir = Directory('/storage/emulated/0/Download');
          } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
            downloadsDir = await getDownloadsDirectory();
          }
          
          if (downloadsDir != null && await downloadsDir.exists()) {
             final permanentFile = File('${downloadsDir.path}/$fileName');
             await permanentFile.writeAsBytes(bytes);
             debugPrint('PET_EVENTS_PDF: Saved to Downloads: ${permanentFile.path}');
          }
        }
      } catch (e) {
        debugPrint('PET_EVENTS_PDF: Could not save to Downloads: $e');
      }

      return file;
    } catch (e, stack) {
      debugPrint('❌ PET_EVENTS_PDF: Error generating PDF: $e\n$stack');
      return null;
    }
  }

  Map<DateTime, List<PetEventModel>> _groupEventsByDate(List<PetEventModel> events) {
    final groups = <DateTime, List<PetEventModel>>{};
    for (var e in events) {
      final date = DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day);
      groups[date] ??= [];
      groups[date]!.add(e);
    }
    // Sort dates
    final sortedKeys = groups.keys.toList()..sort((a, b) => b.compareTo(a));
    return Map.fromEntries(sortedKeys.map((k) => MapEntry(k, groups[k]!)));
  }

  String _getGroupLabel(String group, AppLocalizations l10n) {
    switch (group) {
      case 'food': return l10n.petEvent_group_food;
      case 'health': return l10n.petEvent_group_health;
      case 'elimination': return l10n.petEvent_group_elimination;
      case 'grooming': return l10n.petEvent_group_grooming;
      case 'activity': return l10n.petEvent_group_activity;
      case 'behavior': return l10n.petEvent_group_behavior;
      case 'schedule': return l10n.petEvent_group_schedule;
      case 'media': return l10n.petEvent_group_media;
      case 'metrics': return l10n.petEvent_group_metrics;
      default: return group;
    }
  }

  String _getKindLabel(String kind) {
    switch (kind) {
      case 'image': return 'Imagem';
      case 'video': return 'Vídeo';
      case 'file': return 'Arquivo';
      default: return kind;
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
