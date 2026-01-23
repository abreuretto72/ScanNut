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


class PetEventHistoryScreen extends StatefulWidget {
  final String petId;
  final String petName;

  const PetEventHistoryScreen({
    super.key,
    required this.petId,
    required this.petName,
  });

  @override
  State<PetEventHistoryScreen> createState() => _PetEventHistoryScreenState();
}

class _PetEventHistoryScreenState extends State<PetEventHistoryScreen> {
  DateTimeRange? _selectedDateRange;
  String? _selectedType;

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
            Text(widget.petName, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            Text(
              l10n.petEvent_historyTitle,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        actions: [
          // FILTER BUTTON
          IconButton(
            icon: Icon(Icons.filter_list, color: (_selectedDateRange != null || _selectedType != null) ? AppDesign.petPink : Colors.white),
            tooltip: 'Filtrar',
            onPressed: () => _showFilterDialog(context),
          ),
          PdfActionButton(
            onPressed: () => showDialog(
              context: context,
              builder: (context) => PetEventReportDialog(petId: widget.petId),
            ),
            tooltip: l10n.petEvent_generateReport,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: ValueListenableBuilder(
        valueListenable: PetEventRepository().listenable,
        builder: (context, box, _) {
          // 1. Fetch filtered by Date (Native Repo efficiency)
          var events = PetEventRepository().listEventsByPet(
             widget.petId, 
             petName: widget.petName,
             from: _selectedDateRange?.start,
             to: _selectedDateRange?.end != null ? _selectedDateRange!.end.add(const Duration(days: 1)) : null, // Inclusive
          );

          // 2. Filter by Type (In-memory)
          if (_selectedType != null) {
             events = events.where((e) => e.type == _selectedType).toList();
          }

          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.history_toggle_off, size: 64, color: Colors.white12),
                   const SizedBox(height: 16),
                   Text(
                      (_selectedDateRange != null || _selectedType != null) 
                        ? 'Nenhum resultado para este filtro.' 
                        : l10n.petEvent_emptyHistory, 
                      style: const TextStyle(color: Colors.white30)
                   ),
                   if (_selectedDateRange != null || _selectedType != null)
                      TextButton(
                         onPressed: () => setState(() {
                            _selectedDateRange = null;
                            _selectedType = null;
                         }),
                         child: const Text('Limpar Filtros', style: TextStyle(color: AppDesign.petPink)),
                      )
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
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

  void _showFilterDialog(BuildContext context) {
      // Collect unique types for dropdown
      final allEvents = PetEventRepository().listEventsByPet(widget.petId);
      final uniqueTypes = allEvents.map((e) => e.type).toSet().toList()..sort();
      // Add friendlier empty/default check
      if (uniqueTypes.isEmpty) uniqueTypes.add('occurrence');

      showModalBottomSheet(
         context: context,
         backgroundColor: AppDesign.surfaceDark,
         shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
         builder: (ctx) => StatefulBuilder(
           builder: (context, setModalState) {
             return Padding(
               padding: const EdgeInsets.all(24),
               child: Column(
                 mainAxisSize: MainAxisSize.min,
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   const Text('Filtrar Histórico', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 24),
                   
                   // TYPE SELECTOR
                   const Text('Tipo de Ocorrência', style: TextStyle(color: Colors.white54, fontSize: 12)),
                   const SizedBox(height: 8),
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 12),
                     decoration: BoxDecoration(
                       color: Colors.white.withValues(alpha: 0.05),
                       borderRadius: BorderRadius.circular(12),
                       border: Border.all(color: Colors.white12)
                     ),
                     child: DropdownButtonHideUnderline(
                       child: DropdownButton<String>(
                         value: _selectedType,
                         isExpanded: true,
                         dropdownColor: AppDesign.surfaceDark,
                         hint: const Text('Todos os Tipos', style: TextStyle(color: Colors.white38)),
                         icon: const Icon(Icons.arrow_drop_down, color: AppDesign.petPink),
                         items: [
                           const DropdownMenuItem<String>(value: null, child: Text('Todos', style: TextStyle(color: Colors.white))),
                           ...uniqueTypes.map((t) => DropdownMenuItem(
                              value: t, 
                              child: Text(t.toUpperCase(), style: const TextStyle(color: Colors.white))
                           ))
                         ], 
                         onChanged: (val) => setModalState(() => _selectedType = val),
                       ),
                     ),
                   ),
                   
                   const SizedBox(height: 24),
                   
                   // PERIOD SELECTOR
                   const Text('Período', style: TextStyle(color: Colors.white54, fontSize: 12)),
                   const SizedBox(height: 8),
                   Row(
                      children: [
                         Expanded(
                           child: InkWell(
                             onTap: () async {
                                final now = DateTime.now();
                                final picked = await showDateRangePicker(
                                   context: context, 
                                   firstDate: DateTime(2020), 
                                   lastDate: now.add(const Duration(days: 365)),
                                   initialDateRange: _selectedDateRange,
                                   builder: (context, child) => Theme(
                                      data: Theme.of(context).copyWith(
                                         colorScheme: const ColorScheme.dark(
                                            primary: AppDesign.petPink,
                                            onPrimary: Colors.white,
                                            surface: AppDesign.surfaceDark,
                                         ),
                                      ), 
                                      child: child!
                                   )
                                );
                                if (picked != null) {
                                   setModalState(() => _selectedDateRange = picked);
                                }
                             },
                             borderRadius: BorderRadius.circular(12),
                             child: Container(
                               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                               decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _selectedDateRange != null ? AppDesign.petPink : Colors.white12)
                               ),
                               child: Row(
                                  children: [
                                     Icon(Icons.calendar_today, size: 16, color: _selectedDateRange != null ? AppDesign.petPink : Colors.white54),
                                     const SizedBox(width: 12),
                                     Text(
                                        _selectedDateRange != null 
                                          ? '${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}'
                                          : 'Selecionar Datas...',
                                        style: TextStyle(color: _selectedDateRange != null ? Colors.white : Colors.white38),
                                     ),
                                  ],
                               ),
                             ),
                           ),
                         ),
                         if (_selectedDateRange != null)
                            IconButton(
                               icon: const Icon(Icons.close, color: Colors.white38),
                               onPressed: () => setModalState(() => _selectedDateRange = null),
                            )
                      ],
                   ),
                   
                   const SizedBox(height: 32),
                   
                   // ACTIONS
                   Row(
                      children: [
                         Expanded(
                            child:  TextButton(
                               onPressed: () {
                                  setState(() {
                                     _selectedType = null;
                                     _selectedDateRange = null;
                                  });
                                  if (!mounted) return;
                                  Navigator.pop(context);
                               }, 
                               child: const Text('Limpar Filtros'),
                            )
                         ),
                         const SizedBox(width: 16),
                         Expanded(
                            child: ElevatedButton(
                               style: ElevatedButton.styleFrom(
                                  backgroundColor: AppDesign.petPink,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                               ),
                               onPressed: () {
                                  setState(() {}); // Trigger rebuild with new state
                                  Navigator.pop(context);
                               }, 
                               child: const Text('Aplicar'),
                            )
                         ),
                      ],
                   ),
                   const SizedBox(height: 16),
                 ],
               ),
             );
           }
         )
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
                      BoxShadow(color: AppDesign.petPink.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 1),
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
                            ? AppDesign.petPink.withValues(alpha: 0.2) 
                            : Colors.white.withValues(alpha: 0.05)
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.05),
                            Colors.white.withValues(alpha: 0.02),
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
                                  color: AppDesign.petPink.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(_getGroupIcon(event.group), color: AppDesign.petPink, size: 14),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (event.type.isNotEmpty && event.type != 'occurrence')
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          (event.type == 'ai_analysis' || event.type == 'vault_upload' 
                                           ? 'Foto do pet analisada' 
                                           : event.type).toUpperCase(),
                                          style: TextStyle(color: AppDesign.petPink.withValues(alpha: 0.8), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                        ),
                                      ),
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
                                      Text(widget.petName, style: const TextStyle(color: AppDesign.accent, fontSize: 10, fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 8),
                                      // Intelligence Check Button
                                      // Intelligence Check Button (Only for Schedule or Tasks)
                                      if (event.group == 'schedule' || event.data['is_task'] == true) 
                                        GestureDetector(
                                          onTap: () async {
                                             final isCompleted = event.data['is_completed'] == true;
                                             if (isCompleted) return; // Prevent double indexing
                                             
                                             // Update State
                                             final updatedData = Map<dynamic, dynamic>.from(event.data);
                                             updatedData['is_completed'] = true;
                                             
                                             final updatedEvent = event.copyWith(data: updatedData);
                                             await PetEventRepository().updateEvent(updatedEvent);
                                             
                                             // Indexing (Intelligence)
                                              try {
                                                PetIndexingService().indexTaskCompletion(
                                                  petId: event.petId,
                                                  petName: widget.petName,
                                                  taskTitle: event.title,
                                                  taskId: event.id,
                                                  localizedTitle: AppLocalizations.of(context)!.petIndexing_taskCompleted(event.title),
                                                );
                                                
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Tarefa marcada como concluída!'),
                                                    backgroundColor: AppDesign.petPink,
                                                  )
                                                );
                                              } catch (e) {
                                                debugPrint('Error indexing task completion: $e');
                                              }
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.only(right: 8),
                                            child: Icon(
                                                event.data['is_completed'] == true ? Icons.check_circle : Icons.radio_button_unchecked, 
                                                color: event.data['is_completed'] == true ? AppDesign.petPink : Colors.white30, 
                                                size: 18
                                            ),
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
                          if (event.notes.isNotEmpty || event.data['source'] == 'vocal_analysis') ...[
                            const SizedBox(height: 10),
                            Builder(
                              builder: (context) {
                                if (event.data['source'] == 'vocal_analysis') {
                                   final fname = event.data['file_name']?.toString() ?? 'Audio';
                                   final displayFname = fname.startsWith('sound_rec_') ? (l10n.soundRecording.replaceAll('...', '')) : fname;
                                   
                                    
                                    final reason = event.data['reason_simple'] ?? event.data['reason'];
                                    final action = event.data['action_tip'] ?? event.data['action'];
                                    
                                    // 🛡️ Construct Summary
                                    String summary = '';
                                    if (reason != null && reason.toString().isNotEmpty) summary += 'Motivo: $reason\n';
                                    if (action != null && action.toString().isNotEmpty) summary += 'Dica: $action';
                                    
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${l10n.soundUploadBtn.split(' ').last}: $displayFname', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                        if (summary.isNotEmpty) ...[
                                           const SizedBox(height: 4),
                                           Text(
                                               summary.trim(),
                                               style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, height: 1.3),
                                               maxLines: 5,
                                               overflow: TextOverflow.ellipsis,
                                           )
                                        ]
                                      ],
                                    );
                                  } else if (event.data['source'] == 'body_analysis') {
                                      // 🛡️ Limitação de linhas para Análise Corporal
                                      return Text(
                                        event.notes,
                                        style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                                        maxLines: 5,
                                        overflow: TextOverflow.ellipsis,
                                      );
                                  }
                                  return Text(
                                    event.notes,
                                    style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                                  );
                              }
                            ),
                          ],
                          
                          if (event.data.containsKey('deep_link')) ...[
                             const SizedBox(height: 12),
                             Row(
                               children: [
                                 Icon(Icons.touch_app, color: AppDesign.petPink.withValues(alpha: 0.5), size: 12),
                                 const SizedBox(width: 4),
                                 Text(
                                   AppLocalizations.of(context)!.petEvent_tapToViewDetails, 
                                   style: TextStyle(color: AppDesign.petPink.withValues(alpha: 0.5), fontSize: 9, fontWeight: FontWeight.bold)
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
                                 final key = e.key.toLowerCase();
                                 const ignoredKeys = {
                                    'deep_link', 'indexing_origin', 'pet_name', 'file_name', 
                                    'vault_path', 'is_automatic', 'file_type', 'analysis_type', 
                                    'result_id', 'raw_content', 'timestamp', 'event_type', 'is_completed',
                                    'partner_name', 'partner_id', 'interaction_type',
                                    'diet_type', 'weeks_count', 'source',
                                    'emotion', 'reason', 'action',
                                    'score', 'signals', 'advice', 'image_path',
                                    'quality', 'brand', 'raw_result'
                                 };
                                 
                                 if (ignoredKeys.contains(key) || e.value == null || e.value.toString().isEmpty) return const SizedBox.shrink();
                                 return Container(
                                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                   decoration: BoxDecoration(
                                     color: Colors.black26,
                                     borderRadius: BorderRadius.circular(8),
                                     border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
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
                                        color: Colors.white.withValues(alpha: 0.05),
                                        border: Border.all(color: AppDesign.petPink.withValues(alpha: 0.2)),
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
                                              if (!mounted) return;
                                              AttachmentAnalysisDialog.show(context, content);
                                           } catch (e) {
                                              debugPrint("Error reading sidecar: $e");
                                           }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.greenAccent.withValues(alpha: 0.12),
                                            border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.35)),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.assignment_turned_in_outlined, color: Colors.greenAccent, size: 14),
                                              SizedBox(width: 6),
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
        // 🛡️ V231: Check for Embedded Result First (Indexing v2)
        final embeddedResult = event.data['raw_result']?.toString();
        final embeddedImage = event.data['image_path']?.toString();
        
        if (embeddedResult != null && embeddedResult.isNotEmpty) {
             _openAnalysisResult(context, embeddedResult, embeddedImage ?? '');
             return;
        }

        // 🛡️ Fallback: Legend Disk Search (Index v1 / Attachments)
        if (event.attachments.isNotEmpty) {
            final firstImage = event.attachments.firstWhere((a) => a.kind == 'image', orElse: () => event.attachments.first);
            final sidecarPath = path.join(
                path.dirname(firstImage.path), 
                "${path.basenameWithoutExtension(firstImage.path)}_ResuAnalise.json"
            );
            
            if (File(sidecarPath).existsSync()) {
                final content = File(sidecarPath).readAsStringSync();
                if (!mounted) return;
                _openAnalysisResult(context, content, firstImage.path);
            } else {
                 ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Resultado da análise não encontrado.'))
                );
            }
        } else {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Detalhes desta análise não disponíveis offline.'))
            );
        }
        return;
    }



    // 4. SOUND ANALYSIS
    if (deepLink.startsWith('scannut://sound/analysis/')) {
       final l10n = AppLocalizations.of(context)!;
       final emotion = event.data['emotion']?.toString() ?? 'Unknown';
       final reason = event.data['reason']?.toString() ?? '';
       final action = event.data['action']?.toString() ?? '';
       
       showDialog(
         context: context,
         builder: (ctx) => AlertDialog(
           backgroundColor: AppDesign.surfaceDark,
           title: Row(
             children: [
               const Icon(Icons.graphic_eq, color: AppDesign.petPink),
               const SizedBox(width: 8),
               Expanded(child: Text('${l10n.soundAnalysisTitle}: $emotion', style: const TextStyle(color: Colors.white, fontSize: 16))),
             ],
           ),
           content: Column(
             mainAxisSize: MainAxisSize.min,
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text(l10n.soundReasonSimple, style: const TextStyle(color: Colors.white54, fontSize: 12)),
               const SizedBox(height: 4),
               Text(reason, style: const TextStyle(color: Colors.white70)),
               const SizedBox(height: 16),
               Text(l10n.soundActionTip, style: const TextStyle(color: Colors.white54, fontSize: 12)),
               const SizedBox(height: 4),
               Text(action, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
             ],
           ),
           actions: [
             TextButton(
               onPressed: () => Navigator.pop(ctx),
               child: Text(l10n.commonClose, style: const TextStyle(color: AppDesign.petPink)),
             )
           ],
         )
       );
       return;
    }

    // 5. EXTERNAL LINKS
    if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
    } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Não foi possível abrir o link: $deepLink'))
        );
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

