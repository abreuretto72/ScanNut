import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_design.dart';
import '../../../l10n/app_localizations.dart';
import '../models/pet_event_model.dart';
import '../services/pet_event_repository.dart';

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
        title: Text(
          l10n.petEvent_historyTitle,
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppDesign.surfaceDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
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
                              Text(
                                event.title,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                          Text(
                            timeFormat.format(event.timestamp),
                            style: const TextStyle(color: Colors.white30, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dateFormat.format(event.timestamp),
                        style: const TextStyle(color: AppDesign.petPink, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      if (event.notes.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          event.notes,
                          style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                        ),
                      ],
                      // Info Grid from Data
                      if (event.data.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: event.data.entries.map((e) {
                             if (e.value == null || e.value.toString().isEmpty) return const SizedBox.shrink();
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
                         const SizedBox(height: 16),
                         const Divider(color: Colors.white10),
                         const SizedBox(height: 8),
                         Wrap(
                           spacing: 8,
                           children: event.attachments.map((a) {
                              return Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppDesign.petPink.withOpacity(0.2)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(a.kind == 'file' ? Icons.description : Icons.image, color: AppDesign.petPink, size: 16),
                              );
                           }).toList(),
                         ),
                      ],
                      
                      // Delete Option
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.white24, size: 18),
                          onPressed: () => _confirmDelete(context, event.id),
                        ),
                      ),
                    ],
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
}
