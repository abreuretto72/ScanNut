import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as path;

import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_design.dart';
import '../../../l10n/app_localizations.dart';
import '../models/pet_event_model.dart';
import '../services/pet_event_repository.dart';
import '../services/pet_indexing_service.dart';
import 'widgets/pet_event_report_dialog.dart';
import 'widgets/attachment_analysis_dialog.dart';
import 'pet_result_screen.dart';
import '../models/pet_analysis_result.dart';
import 'dart:io';
import '../../../core/widgets/pdf_action_button.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../partners/presentation/partner_registration_screen.dart';
import '../../../core/services/partner_service.dart';
import '../../../core/models/partner_model.dart';


class PetEventHistoryScreen extends StatelessWidget {
  final String petId;
  final String petName;

  const PetEventHistoryScreen({
    Key? key,
    required this.petId,
    required this.petName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppDesign.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(petName, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            Text(
              l10n.petEvent_historyTitle,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        actions: [
          PdfActionButton(
            onPressed: () => showDialog(
              context: context,
              builder: (context) => PetEventReportDialog(petId: petId),
            ),
            tooltip: l10n.petEvent_generateReport,
            color: AppDesign.primary, // Usando Roxo ScanNut para melhor contraste com branco
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: ValueListenableBuilder(
        valueListenable: PetEventRepository().listenable,
        builder: (context, box, _) {
          final events = PetEventRepository().listEventsByPet(petId);

          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.history_toggle_off, size: 64, color: Colors.white12),
                   const SizedBox(height: 16),
                   Text(l10n.petEvent_emptyHistory, style: const TextStyle(color: Colors.white30)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return _buildEventTimelineItem(context, event, l10n);
            },
          );
        },
      ),
    );
  }

  Widget _buildEventTimelineItem(BuildContext context, PetEventModel event, AppLocalizations l10n) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final timeFormat = DateFormat('HH:mm');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline line
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppDesign.petPink,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: AppDesign.petPink.withOpacity(0.3), blurRadius: 8, spreadRadius: 1),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(width: 2, color: Colors.white10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Content Card
          Expanded(
            child: Column(
              children: [
                  InkWell(
                    onTap: () {
                      final deepLink = event.data['deep_link']?.toString();
                      if (deepLink != null) {
                        _handleDeepLink(context, deepLink, event);
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppDesign.surfaceDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: event.data.containsKey('deep_link') 
                            ? AppDesign.petPink.withOpacity(0.2) 
                            : Colors.white.withOpacity(0.05)
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.05),
                            Colors.white.withOpacity(0.02),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppDesign.petPink.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(_getGroupIcon(event.group), color: AppDesign.petPink, size: 14),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.title,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    Text(
                                      dateFormat.format(event.timestamp),
                                      style: const TextStyle(color: AppDesign.petPink, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      Text(petName, style: const TextStyle(color: AppDesign.accent, fontSize: 10, fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 8),
                                      // Intelligence Check Button
                                      GestureDetector(
                                        onTap: () async {
                                           final isCompleted = event.data['is_completed'] == true;
                                           if (isCompleted) return; // Prevent double indexing or unchecking for now as per prompt "Action: Click Check"
                                           
                                           // Update State
                                           final updatedData = Map<dynamic, dynamic>.from(event.data);
                                           updatedData['is_completed'] = true;
                                           
                                           final updatedEvent = event.copyWith(data: updatedData);
                                           await PetEventRepository().updateEvent(updatedEvent);
                                           // Rebuild happens automatically via ValueListenableBuilder
                                           
                                           // Indexing (Intelligence)
                                            try {
                                              PetIndexingService().indexTaskCompletion(
                                                petId: event.petId,
                                                petName: petName,
                                                taskTitle: event.title,
                                                taskId: event.id,
                                                localizedTitle: AppLocalizations.of(context)!.petIndexing_taskCompleted(event.title),
                                              );
                                              
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Tarefa concluída e registrada em Saúde!'),
                                                  backgroundColor: AppDesign.petPink,
                                                )
                                              );
                                            } catch (e) {
                                              debugPrint('Error indexing task completion: $e');
                                            }
                                        },
                                        child: Icon(
                                            event.data['is_completed'] == true ? Icons.check_circle : Icons.radio_button_unchecked, 
                                            color: event.data['is_completed'] == true ? AppDesign.petPink : Colors.white30, 
                                            size: 18
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () => _confirmDelete(context, event.id),
                                        child: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    timeFormat.format(event.timestamp),
                                    style: const TextStyle(color: Colors.white30, fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (event.notes.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              event.notes,
                              style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                            ),
                          ],
                          
                          if (event.data.containsKey('deep_link')) ...[
                             const SizedBox(height: 12),
                             Row(
                               children: [
                                 Icon(Icons.touch_app, color: AppDesign.petPink.withOpacity(0.5), size: 12),
                                 const SizedBox(width: 4),
                                 Text(
                                   AppLocalizations.of(context)!.petEvent_tapToViewDetails, 
                                   style: TextStyle(color: AppDesign.petPink.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.bold)
                                  ),
                               ],
                             ),
                          ],

                          // Info Grid from Data
                          if (event.data.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: event.data.entries.map((e) {
                                 if (e.key == 'deep_link' || e.key == 'indexing_origin' || e.value == null || e.value.toString().isEmpty) return const SizedBox.shrink();
                                 return Container(
                                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                   decoration: BoxDecoration(
                                     color: Colors.black26,
                                     borderRadius: BorderRadius.circular(8),
                                     border: Border.all(color: Colors.white.withOpacity(0.03)),
                                    ),
                                   child: Text(
                                     '${e.key.toUpperCase()}: ${e.value}', 
                                     style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w600),
                                   ),
                                 );
                              }).toList(),
                            ),
                          ],
                          // Attachments List
                          if (event.attachments.isNotEmpty) ...[
                             const SizedBox(height: 12),
                             const Divider(color: Colors.white10),
                             const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: event.attachments
                                    .where((a) => a.analysisResult != 'SIDEAR_FILE')
                                    .expand((a) {
                                  final sidecarPath = path.join(
                                    path.dirname(a.path), 
                                    "${path.basenameWithoutExtension(a.path)}_ResuAnalise.json"
                                  );
                                  
                                  return [
                                    // Original Attachment
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.05),
                                        border: Border.all(color: AppDesign.petPink.withOpacity(0.2)),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: GestureDetector(
                                        onTap: () => OpenFilex.open(a.path),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(a.kind == 'file' ? Icons.description : Icons.image, color: AppDesign.petPink, size: 16),
                                            const SizedBox(width: 8),
                                            ConstrainedBox(
                                              constraints: const BoxConstraints(maxWidth: 100),
                                              child: Text(
                                                _parseAttachmentName(a.path),
                                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    
                                    // SIDEAR RESULT FILE (If exists on disk)
                                    if (File(sidecarPath).existsSync())
                                      GestureDetector(
                                        onTap: () {
                                           try {
                                              final content = File(sidecarPath).readAsStringSync();
                                              AttachmentAnalysisDialog.show(context, content);
                                           } catch (e) {
                                              debugPrint("Error reading sidecar: $e");
                                           }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.greenAccent.withOpacity(0.12),
                                            border: Border.all(color: Colors.greenAccent.withOpacity(0.35)),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.assignment_turned_in_outlined, color: Colors.greenAccent, size: 14),
                                              const SizedBox(width: 6),
                                              Text(
                                                "LAUDO CLÍNICO IA",
                                                style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ];
                                }).toList(),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getGroupIcon(String groupId) {
    switch (groupId) {
      case 'food': return Icons.restaurant;
      case 'health': return Icons.medical_services;
      case 'elimination': return Icons.opacity;
      case 'grooming': return Icons.content_cut;
      case 'activity': return Icons.directions_walk;
      case 'behavior': return Icons.psychology;
      case 'schedule': return Icons.event;
      case 'media': return Icons.photo_camera;
      case 'metrics': return Icons.straighten;
      default: return Icons.event_note;
    }
  }

  Future<void> _confirmDelete(BuildContext context, String eventId) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppDesign.surfaceDark,
        title: const Text('Excluir Evento', style: TextStyle(color: Colors.white)),
        content: const Text('Deseja remover este registro do histórico?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.petEvent_cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Excluir', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await PetEventRepository().deleteEventSoft(eventId);
    }
  }

  void _handleDeepLink(BuildContext context, String deepLink, PetEventModel event) async {
    debugPrint('🔗 Handling deep link: $deepLink');
    final uri = Uri.parse(deepLink);
    
    // 1. VAULT OPEN
    if (deepLink.startsWith('scannut://vault/open')) {
        final filePath = uri.queryParameters['path'];
        if (filePath != null && File(filePath).existsSync()) {
            OpenFilex.open(filePath);
        } else {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Arquivo não encontrado no Vault.'))
            );
        }
        return;
    }

    // 2. PARTNER PROFILE
    if (deepLink.startsWith('scannut://partners/profile/')) {
        final partnerId = uri.pathSegments.last;
        final service = PartnerService();
        await service.init();
        final partners = service.getAllPartners();
        try {
            final partner = partners.firstWhere((p) => p.id == partnerId);
            if (context.mounted) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => PartnerRegistrationScreen(initialData: partner)));
            }
        } catch (e) {
            if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Parceiro não encontrado.'))
                );
            }
        }
        return;
    }

    // 3. AI ANALYSIS
    if (deepLink.startsWith('scannut://pet/analysis/')) {
        // Find result in data or attachments
        // For indexed events, we usually have a result_id in data
        // and often the original image as an attachment.
        if (event.attachments.isNotEmpty) {
            final firstImage = event.attachments.firstWhere((a) => a.kind == 'image', orElse: () => event.attachments.first);
            final sidecarPath = path.join(
                path.dirname(firstImage.path), 
                "${path.basenameWithoutExtension(firstImage.path)}_ResuAnalise.json"
            );
            
            if (File(sidecarPath).existsSync()) {
                final content = File(sidecarPath).readAsStringSync();
                _openAnalysisResult(context, content, firstImage.path);
            } else {
                 ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Resultado da análise não encontrado.'))
                );
            }
        }
        return;
    }

    // 4. EXTERNAL LINKS
    if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
    }
  }

  void _openAnalysisResult(BuildContext context, String jsonString, String imagePath) {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) throw Exception("Invalid format");
      
      // Try parsing full result
      final result = PetAnalysisResult.fromJson(decoded);
      
      Navigator.push(
        context, 
        MaterialPageRoute(
          builder: (_) => PetResultScreen(
            imageFile: File(imagePath),
            existingResult: result,
            isHistoryView: true,
          )
        )
      );
    } catch (e) {
      debugPrint("Error opening analysis: $e");
      ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Não foi possível carregar os detalhes desta análise.'), backgroundColor: AppDesign.warning)
      );
    }
  }

  String _parseAttachmentName(String filePath) {
    final filename = path.basenameWithoutExtension(filePath);
    // Remove pattern: yyyyMMdd_HHmmss_X_ (ScanNut Standard)
    return filename.replaceFirst(RegExp(r'^\d{8}_\d{6}_[A-Z]_'), '')
                   .replaceFirst(RegExp(r'^\d{8}_\d{6}_'), '');
  }
}
