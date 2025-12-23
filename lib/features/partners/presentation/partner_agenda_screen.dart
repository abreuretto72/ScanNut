import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../core/models/partner_model.dart';
import '../models/agenda_event.dart';
import '../../pet/services/pet_event_service.dart';
import '../../pet/services/pet_event_service.dart';
import '../../pet/models/pet_event.dart';
import '../../../core/services/export_service.dart';
import '../../../core/widgets/pdf_preview_screen.dart';
import './widgets/add_event_modal.dart';

class PartnerAgendaScreen extends StatefulWidget {
  final PartnerModel partner;
  final List<Map<String, dynamic>> initialEvents;
  final Function(List<Map<String, dynamic>>) onSave;
  final String? petId; // Context for linking
  // In EditPetForm, we don't always have a saved pet ID if it's new, but usually we do. 
  // Requirement says: "automatically load id_pet and id_partner".

  const PartnerAgendaScreen({
    Key? key,
    required this.partner,
    required this.initialEvents,
    required this.onSave,
    this.petId,
  }) : super(key: key);

  @override
  State<PartnerAgendaScreen> createState() => _PartnerAgendaScreenState();
}

class _PartnerAgendaScreenState extends State<PartnerAgendaScreen> {
  late List<Map<String, dynamic>> _events;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  // Voice
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _events = List.from(widget.initialEvents);
    _selectedDay = _focusedDay;
    _speech = stt.SpeechToText();
    _loadEventsFromService();
  }

  Future<void> _loadEventsFromService() async {
    if (widget.petId == null) return;
    
    try {
        final service = PetEventService();
        await service.init();
        final serviceEvents = service.getEventsByPet(widget.petId!);
        
        if (serviceEvents.isEmpty) return;

        setState(() {
            // Create a map of existing event IDs to avoid duplicates
            final existingIds = _events.map((e) => e['id']).toSet();
            
            for (var pEvent in serviceEvents) {
                if (!existingIds.contains(pEvent.id)) {
                    // Map PetEvent to AgendaEvent JSON format
                    // Map EventType to EventCategory string
                    String category = 'extras';
                    final typeStr = pEvent.type.toString().split('.').last.toLowerCase();
                    
                    if (typeStr == 'vaccine') category = 'vacina';
                    else if (typeStr == 'medication') category = 'remedios';
                    else if (typeStr == 'veterinary') category = 'consulta';
                    else if (typeStr == 'grooming') category = 'estetica';
                    else if (typeStr == 'bath') category = 'banho';
                    else if (typeStr == 'other') category = 'extras';
                    
                    final newEventMap = {
                        'id': pEvent.id,
                        'partnerId': widget.partner.id, // Assuming same partner or we preserve it
                        'petId': pEvent.petName,
                        'category': category,
                        'title': pEvent.title,
                        'description': pEvent.notes,
                        'dateTime': pEvent.dateTime.toIso8601String(),
                        'attendant': pEvent.attendant,
                        'createdAt': pEvent.createdAt.toIso8601String(),
                        // Compatibility keys
                        'content': pEvent.notes,
                        'date': pEvent.dateTime.toIso8601String(),
                        'type': 'event',
                    };
                    
                    _events.add(newEventMap);
                    existingIds.add(pEvent.id);
                }
            }
            
            // Re-sort
            _events.sort((a, b) {
                final dateA = DateTime.parse(a['date']);
                final dateB = DateTime.parse(b['date']);
                return dateA.compareTo(dateB);
            });
        });
    } catch (e) {
        debugPrint('Error loading events from service: $e');
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events.where((event) {
      final eventDate = DateTime.parse(event['date']);
      return isSameDay(eventDate, day);
    }).toList()
    ..sort((a, b) { // Sort chronologically
         final dateA = DateTime.parse(a['date']);
         final dateB = DateTime.parse(b['date']);
         return dateA.compareTo(dateB);
    });
  }

  void _addEvent(Map<String, dynamic> newEvent) {
    setState(() {
      _events.add(newEvent);
    });
    // Immediate Save (callback)
    widget.onSave(_events); 

    // Also persist to Service immediately
    if (widget.petId != null) {
        _persistToService(newEvent);
    }
  }

  Future<void> _persistToService(Map<String, dynamic> eventMap) async {
      final service = PetEventService();
      await service.init();
      
      final agendaEvent = AgendaEvent.fromJson(eventMap);
      
      // Map back to PetEvent
      EventType pType = EventType.other;
      if (agendaEvent.category == EventCategory.vacina) pType = EventType.vaccine;
      else if (agendaEvent.category == EventCategory.banho) pType = EventType.bath;
      else if (agendaEvent.category == EventCategory.tosa) pType = EventType.grooming;
      else if (agendaEvent.category == EventCategory.remedios) pType = EventType.medication;
      else if (agendaEvent.category == EventCategory.consulta || 
         agendaEvent.category == EventCategory.emergencia ||
         agendaEvent.category == EventCategory.saude ||
         agendaEvent.category == EventCategory.exame ||
         agendaEvent.category == EventCategory.cirurgia) pType = EventType.veterinary;

      final pEvent = PetEvent(
          id: agendaEvent.id,
          petName: widget.petId!,
          title: agendaEvent.title,
          type: pType,
          dateTime: agendaEvent.dateTime,
          notes: agendaEvent.description,
          createdAt: agendaEvent.createdAt,
          attendant: widget.partner.name,
          completed: false,
      );
      
      await service.addEvent(pEvent);
  }

  void _showAddEventModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: AddEventModal(
            selectedDate: _selectedDay ?? DateTime.now(),
            scrollController: scrollController,
            partner: widget.partner,
            petId: widget.petId,
            onSave: (AgendaEvent event) {
              // Convert AgendaEvent to old format for compatibility
              final eventMap = event.toJson();
              _addEvent(eventMap);
              Navigator.pop(context);
            },
            speech: _speech,
          ),
        ),
      ),
    );
  }

  void _showEditEventModal(Map<String, dynamic> eventMap) {
    final event = AgendaEvent.fromJson(eventMap);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: AddEventModal(
            selectedDate: event.dateTime,
            scrollController: scrollController,
            partner: widget.partner,
            petId: widget.petId,
            existingEvent: event,
            onSave: (AgendaEvent updatedEvent) {
              setState(() {
                final index = _events.indexWhere((e) => e['id'] == event.id);
                if (index != -1) {
                  _events[index] = updatedEvent.toJson();
                } else {
                  _events.add(updatedEvent.toJson());
                }
              });
              widget.onSave(_events);
              Navigator.pop(context);
            },
            speech: _speech,
          ),
        ),
      ),
    );
  }

  void _showExportDialog() {
    String reportType = 'Detalhamento';
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Exportar Agenda', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tipo de Relatório:', style: TextStyle(color: Colors.white70)),
                RadioListTile<String>(
                  title: const Text('Resumo', style: TextStyle(color: Colors.white)),
                  value: 'Resumo',
                  groupValue: reportType,
                  onChanged: (val) => setDialogState(() => reportType = val!),
                  activeColor: const Color(0xFF00E676),
                ),
                RadioListTile<String>(
                  title: const Text('Detalhamento', style: TextStyle(color: Colors.white)),
                  value: 'Detalhamento',
                  groupValue: reportType,
                  onChanged: (val) => setDialogState(() => reportType = val!),
                  activeColor: const Color(0xFF00E676),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                
                // Convert Map events to PetEvent objects for the report
                final petEvents = _events.map((e) {
                   return PetEvent(
                      id: e['id'] ?? '',
                      petName: widget.petId ?? 'N/A',
                      title: e['title'] ?? '',
                      type: EventType.other,
                      dateTime: DateTime.parse(e['date']),
                      notes: e['content'],
                      completed: false, // Default
                      attendant: widget.partner.name,
                   );
                }).toList();
                
                // Sort by date desc
                petEvents.sort((a, b) => b.dateTime.compareTo(a.dateTime));

                final service = ExportService();
                final pdf = await service.generateAgendaReport(
                  events: petEvents,
                  start: DateTime(2000), // Coverage
                  end: DateTime(2100),
                  reportType: reportType
                );
                
                if (mounted) {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => PdfPreviewScreen(
                      title: 'Relatório de Agenda',
                      buildPdf: (format) async => pdf.save(),
                    ))
                  );
                }
              },
              child: const Text('Gerar PDF', style: TextStyle(color: Color(0xFF00E676))),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Current events for selected day
    final dailyEvents = _getEventsForDay(_selectedDay ?? DateTime.now());

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Agenda', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
            Text(widget.partner.name, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            tooltip: 'Exportar PDF',
            onPressed: _showExportDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Calendar
            Container(
              color: Colors.white.withOpacity(0.05),
              padding: const EdgeInsets.only(bottom: 8),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 10, 16),
                lastDay: DateTime.utc(2030, 3, 14),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  if (_calendarFormat != format) setState(() => _calendarFormat = format);
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                eventLoader: _getEventsForDay, // Shows dots
                
                // Styles
                headerStyle: HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                  titleTextStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  leftChevronIcon: const Icon(Icons.chevron_left, color: Color(0xFF00E676)),
                  rightChevronIcon: const Icon(Icons.chevron_right, color: Color(0xFF00E676)),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekendStyle: TextStyle(color: Colors.white30),
                  weekdayStyle: TextStyle(color: Colors.white70),
                ),
                calendarStyle: CalendarStyle(
                  defaultTextStyle: GoogleFonts.poppins(color: Colors.white),
                  weekendTextStyle: GoogleFonts.poppins(color: Colors.white54),
                  todayTextStyle: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold),
                  todayDecoration: const BoxDecoration(
                    color: Color(0xFF00E676),
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                  selectedDecoration: const BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: const BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
                  outsideDaysVisible: false,
                ),
              ),
            ),

            const SizedBox(height: 10),
            
            // Header for Timeline
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedDay != null 
                      ? DateFormat('d ' 'de' ' MMMM', 'pt_BR').format(_selectedDay!)
                      : 'Hoje',
                    style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  Text('${dailyEvents.length} eventos', style: const TextStyle(color: Colors.white24, fontSize: 12)),
                ],
              ),
            ),

            // 2. Event List (Timeline)
            dailyEvents.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: dailyEvents.length,
                    itemBuilder: (context, index) {
                      final event = dailyEvents[index];
                      return _buildTimelineItem(event, isLast: index == dailyEvents.length - 1);
                    },
            ),
            
            // Padding for FAB
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventModal,
        backgroundColor: const Color(0xFF00E676),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available, size: 60, color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: 16),
          Text('Sem eventos neste dia', style: GoogleFonts.poppins(color: Colors.white24)),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> event, {bool isLast = false}) {
    final date = DateTime.parse(event['date']);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Line & Dot
          Column(
            children: [
               Container(
                 width: 12, height: 12,
                 decoration: BoxDecoration(
                   color: Colors.black,
                   border: Border.all(color: const Color(0xFF00E676), width: 2),
                   shape: BoxShape.circle,
                 ),
               ),
               Expanded(
                 child: isLast ? const SizedBox() : Container(width: 2, color: Colors.white10),
               )
            ],
          ),
          const SizedBox(width: 16),
          
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: InkWell(
                  onTap: () => _showEditEventModal(event),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('HH:mm').format(date),
                              style: GoogleFonts.poppins(color: const Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event['title'],
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        if (event['content'] != null && event['content'].toString().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            event['content'],
                            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

