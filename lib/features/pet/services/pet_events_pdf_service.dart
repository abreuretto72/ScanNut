import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../services/pet_export_service.dart';
import '../models/pet_event_model.dart';
import '../models/pet_profile_extended.dart';
import '../services/pet_event_repository.dart';
import '../../../core/services/base_pdf_helper.dart';
import 'pet_profile_service.dart';

class PetEventsPdfService {
  static final PetEventsPdfService _instance = PetEventsPdfService._internal();
  factory PetEventsPdfService() => _instance;
  PetEventsPdfService._internal();

  // final _exportService = PetExportService(); // Removed
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
    final bytes = await buildReportBytes(
      petId: petId,
      start: start,
      end: end,
      groupFilter: groupFilter,
      onlyIncludeInPdf: onlyIncludeInPdf,
      l10n: l10n,
    );

    if (bytes == null) return null;

    final directory = await getTemporaryDirectory();
    String fileName =
        'Relatorio_${petId}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
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
          debugPrint(
              'PET_EVENTS_PDF: Saved to Downloads: ${permanentFile.path}');
        }
      }
    } catch (e) {
      debugPrint('PET_EVENTS_PDF: Could not save to Downloads: $e');
    }

    return file;
  }

  /// 📄 CORE BUILDER: Returns the PDF bytes for usage in PdfPreview
  Future<Uint8List?> buildReportBytes({
    required String petId,
    required DateTime start,
    required DateTime end,
    String? groupFilter,
    bool onlyIncludeInPdf = true,
    required AppLocalizations l10n,
  }) async {
    try {
      debugPrint(
          'PET_EVENTS_PDF: Building report bytes for $petId ($start to $end)');

      final profileMap = await _profileService.getProfile(petId);
      final profile = profileMap != null
          ? PetProfileExtended.fromHiveEntry(profileMap)
          : null;

      var events = _repo.listEventsByPet(petId, from: start, to: end);

      if (groupFilter != null && groupFilter != 'all') {
        events = events.where((e) => e.group == groupFilter).toList();
      }

      if (onlyIncludeInPdf) {
        events = events.where((e) => e.includeInPdf).toList();
      }

      final pdf = pw.Document();
      final timestampStr =
          DateFormat.yMd(l10n.localeName).add_Hm().format(DateTime.now());
      final periodStr =
          '${DateFormat.yMd(l10n.localeName).format(start)} - ${DateFormat.yMd(l10n.localeName).format(end)}';

      // 1. Pre-load Pet Photo
      pw.ImageProvider? petPhoto;
      if (profile?.imagePath != null) {
        petPhoto = await BasePdfHelper.safeLoadImage(profile!.imagePath!);
      }

      // 2. Pre-load Event Thumbnails
      final thumbnails = <String, List<pw.ImageProvider>>{};
      int totalImagesLoaded = 0;
      const int maxImagesTotal = 30; // High limit for report

      for (var event in events) {
        final images =
            event.attachments.where((a) => a.kind == 'image').take(3).toList();
        for (var img in images) {
          if (totalImagesLoaded >= maxImagesTotal) break;
          // Load from Vault! (safeLoadImage handles vault detection)
          final provider = await BasePdfHelper.safeLoadImage(img.path);
          if (provider != null) {
            thumbnails[event.id] ??= [];
            thumbnails[event.id]!.add(provider);
            totalImagesLoaded++;
          }
        }
      }

      // 3. Pre-load Sidecar JSON contents
      final sidecarContents = <String, String>{};
      for (var event in events) {
        for (var a in event.attachments) {
          if (a.analysisResult == 'SIDEAR_FILE') {
            try {
              final file = File(a.path);
              if (await file.exists()) {
                sidecarContents[a.id] = await file.readAsString();
              }
            } catch (e) {
              debugPrint('Error loading sidecar ${a.id}: $e');
            }
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
          header: (context) => BasePdfHelper.buildHeader(
              l10n.petEvent_reportTitle, timestampStr,
              color: PetExportService.themeColor,
              appName: 'ScanNut'),
          footer: (context) =>
              BasePdfHelper.buildFooter(context, strings: l10n),
          build: (context) => [
            // Header Info Card
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (petPhoto != null) ...[
                    pw.Container(
                      width: 60,
                      height: 60,
                      decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        image: pw.DecorationImage(
                            image: petPhoto, fit: pw.BoxFit.cover),
                      ),
                    ),
                    pw.SizedBox(width: 15),
                  ],
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(profile?.petName ?? petId,
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 14)),
                        pw.SizedBox(height: 4),
                        pw.Text('${l10n.petEvent_reportPeriod}: $periodStr',
                            style: const pw.TextStyle(
                                fontSize: 10, color: PdfColors.grey700)),
                        if (profile?.raca != null)
                          pw.Text(profile!.raca!,
                              style: const pw.TextStyle(
                                  fontSize: 9, color: PdfColors.grey600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            pw.SizedBox(height: 10),

            // Timeline Section
            ..._groupEventsByDate(events).entries.map((entry) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 4, horizontal: 8),
                    color: PetExportService.themeColor, // 🎨 Domain Color Pink
                    child: pw.Text(
                      DateFormat.yMMMMEEEEd(l10n.localeName)
                          .format(entry.key)
                          .toUpperCase(),
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 9),
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  ...entry.value.map((event) {
                    final eventThumbnails = thumbnails[event.id] ?? [];
                    final otherAttachments = event.attachments
                        .where((a) =>
                            a.kind != 'image' &&
                            a.analysisResult != 'SIDEAR_FILE')
                        .toList();
                    final sidecarIds = event.attachments
                        .where((a) => a.analysisResult == 'SIDEAR_FILE')
                        .map((a) => a.id)
                        .toList();

                    // 🛡️ Logic similar to pet_event_history_screen.dart
                    final displayType = (event.type == 'ai_analysis' ||
                                event.type == 'vault_upload'
                            ? 'Foto do pet analisada'
                            : event.type)
                        .toUpperCase();

                    String notesSummary = event.notes;
                    if (event.data['source'] == 'vocal_analysis') {
                      final reason =
                          event.data['reason_simple'] ?? event.data['reason'];
                      final action =
                          event.data['action_tip'] ?? event.data['action'];
                      String summary = '';
                      if (reason != null && reason.toString().isNotEmpty) {
                        summary += 'Motivo: $reason\n';
                      }
                      if (action != null && action.toString().isNotEmpty) {
                        summary += 'Dica: $action';
                      }
                      notesSummary = summary.trim();
                    }

                    return pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 15, left: 10),
                      padding: const pw.EdgeInsets.only(left: 10),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                            left: pw.BorderSide(
                                color: PdfColors.grey300, width: 2)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            children: [
                              pw.Text(DateFormat.Hm().format(event.timestamp),
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 9)),
                              pw.SizedBox(width: 8),
                              pw.Text('[$displayType]',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 8,
                                      color: PetExportService.themeColor)),
                              pw.SizedBox(width: 8),
                              pw.Expanded(
                                  child: pw.Text(event.title,
                                      style: pw.TextStyle(
                                          fontWeight: pw.FontWeight.bold,
                                          fontSize: 10))),
                              if (event.data['is_completed'] == true) ...[
                                pw.SizedBox(width: 10),
                                pw.Text('[CONCLUÍDO]',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 8,
                                        color: PdfColors.green700)),
                              ]
                            ],
                          ),
                          if (notesSummary.isNotEmpty) ...[
                            pw.SizedBox(height: 4),
                            pw.Text(notesSummary,
                                style: const pw.TextStyle(
                                    fontSize: 9, color: PdfColors.grey800)),
                          ],

                          // Dynamic Data
                          if (event.data.isNotEmpty) ...[
                            pw.SizedBox(height: 6),
                            pw.Wrap(
                              spacing: 8,
                              children: event.data.entries.map((d) {
                                final key = d.key.toLowerCase();
                                const ignoredKeys = {
                                  'deep_link',
                                  'indexing_origin',
                                  'pet_name',
                                  'file_name',
                                  'vault_path',
                                  'is_automatic',
                                  'file_type',
                                  'analysis_type',
                                  'result_id',
                                  'raw_content',
                                  'timestamp',
                                  'event_type',
                                  'is_completed',
                                  'partner_name',
                                  'partner_id',
                                  'interaction_type',
                                  'diet_type',
                                  'weeks_count',
                                  'source',
                                  'emotion',
                                  'reason',
                                  'action',
                                  'reason_simple',
                                  'action_tip',
                                  'score',
                                  'signals',
                                  'advice',
                                  'image_path',
                                  'quality',
                                  'brand',
                                  'raw_result'
                                };

                                if (ignoredKeys.contains(key) ||
                                    d.value == null ||
                                    d.value.toString().isEmpty) {
                                  return pw.SizedBox.shrink();
                                }
                                return pw.Text(
                                    '${d.key.toUpperCase()}: ${d.value}',
                                    style: pw.TextStyle(
                                        fontSize: 8,
                                        color: PdfColors.grey700,
                                        fontStyle: pw.FontStyle.italic));
                              }).toList(),
                            ),
                          ],

                          // IA Clinical Report Content (Sidecar)
                          if (sidecarIds.isNotEmpty) ...[
                            pw.SizedBox(height: 8),
                            ...sidecarIds.map((sid) {
                              final jsonStr = sidecarContents[sid];
                              if (jsonStr == null) return pw.SizedBox.shrink();
                              try {
                                final data = jsonDecode(jsonStr);
                                return pw.Container(
                                    width: double.infinity,
                                    padding: const pw.EdgeInsets.all(6),
                                    decoration: pw.BoxDecoration(
                                        color: PdfColors.green50,
                                        border: pw.Border.all(
                                            color: PdfColors.green200),
                                        borderRadius: const pw.BorderRadius.all(
                                            pw.Radius.circular(4))),
                                    child: pw.Column(
                                        crossAxisAlignment:
                                            pw.CrossAxisAlignment.start,
                                        children: [
                                          pw.Text("LAUDO CLÍNICO IA",
                                              style: pw.TextStyle(
                                                  fontWeight:
                                                      pw.FontWeight.bold,
                                                  fontSize: 8,
                                                  color: PdfColors.green900)),
                                          if (data['summary'] != null) ...[
                                            pw.SizedBox(height: 4),
                                            pw.Text(
                                                "RESUMO: ${data['summary']}",
                                                style: const pw.TextStyle(
                                                    fontSize: 8,
                                                    color: PdfColors.grey900)),
                                          ],
                                          if (data['alerts'] != null &&
                                              data['alerts'] is List &&
                                              (data['alerts'] as List)
                                                  .isNotEmpty) ...[
                                            pw.SizedBox(height: 4),
                                            pw.Text(
                                                "ALERTAS: ${(data['alerts'] as List).join(' • ')}",
                                                style: pw.TextStyle(
                                                    fontSize: 8,
                                                    color: PdfColors.red900,
                                                    fontWeight:
                                                        pw.FontWeight.bold)),
                                          ],
                                        ]));
                              } catch (_) {
                                return pw.SizedBox.shrink();
                              }
                            }),
                          ],

                          // Images / Thumbnails
                          if (eventThumbnails.isNotEmpty) ...[
                            pw.SizedBox(height: 10),
                            pw.Wrap(
                              spacing: 8,
                              children: eventThumbnails
                                  .map((prov) => pw.Container(
                                        width: 140, // Increased for vision
                                        height: 140,
                                        decoration: pw.BoxDecoration(
                                          border: pw.Border.all(
                                              color: PdfColors.grey300,
                                              width: 0.5),
                                          image: pw.DecorationImage(
                                              image: prov,
                                              fit: pw.BoxFit.cover),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ],

                          // List of Other Attachments
                          if (otherAttachments.isNotEmpty) ...[
                            pw.SizedBox(height: 8),
                            ...otherAttachments.map((a) => pw.Row(
                                  children: [
                                    pw.Text('📎 ',
                                        style: const pw.TextStyle(fontSize: 8)),
                                    pw.Text(
                                        '${_getKindLabel(a.kind)}: ${a.path.split('/').last} (${_formatSize(a.size)})',
                                        style: const pw.TextStyle(
                                            fontSize: 7,
                                            color: PdfColors.blue800)),
                                  ],
                                )),
                          ],
                          pw.SizedBox(height: 10),
                        ],
                      ),
                    );
                  }),
                  pw.SizedBox(height: 15),
                ],
              );
            }),
          ],
        ),
      );

      return await pdf.save();
    } catch (e, stack) {
      debugPrint('❌ PET_EVENTS_PDF: Error building PDF bytes: $e\n$stack');
      return null;
    }
  }

  Map<DateTime, List<PetEventModel>> _groupEventsByDate(
      List<PetEventModel> events) {
    final groups = <DateTime, List<PetEventModel>>{};
    for (var e in events) {
      final date =
          DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day);
      groups[date] ??= [];
      groups[date]!.add(e);
    }
    // Sort dates
    final sortedKeys = groups.keys.toList()..sort((a, b) => b.compareTo(a));
    return Map.fromEntries(sortedKeys.map((k) => MapEntry(k, groups[k]!)));
  }

  String _getGroupLabel(String group, AppLocalizations l10n) {
    switch (group) {
      case 'food':
        return l10n.petEvent_group_food;
      case 'health':
        return l10n.petEvent_group_health;
      case 'elimination':
        return l10n.petEvent_group_elimination;
      case 'grooming':
        return l10n.petEvent_group_grooming;
      case 'activity':
        return l10n.petEvent_group_activity;
      case 'behavior':
        return l10n.petEvent_group_behavior;
      case 'schedule':
        return l10n.petEvent_group_schedule;
      case 'media':
        return l10n.petEvent_group_media;
      case 'metrics':
        return l10n.petEvent_group_metrics;
      case 'medication':
        return l10n.petEvent_group_medication;
      case 'documents':
        return l10n.petEvent_group_documents;
      case 'exams':
        return l10n.petEvent_group_exams;
      case 'allergies':
        return l10n.petEvent_group_allergies;
      case 'dentistry':
        return l10n.petEvent_group_dentistry;
      case 'other':
        return l10n.petEvent_group_other;
      default:
        return group[0].toUpperCase() + group.substring(1);
    }
  }

  String _getKindLabel(String kind) {
    switch (kind) {
      case 'image':
        return 'Imagem';
      case 'video':
        return 'Vídeo';
      case 'file':
        return 'Arquivo';
      default:
        return kind;
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
