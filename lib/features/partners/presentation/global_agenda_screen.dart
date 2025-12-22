import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/models/partner_model.dart';
import '../../../core/services/partner_service.dart';
import '../../pet/services/pet_profile_service.dart';
import '../models/agenda_event.dart';
import 'partner_agenda_screen.dart';

/// Agenda Global - Visão consolidada de todos os pets e parceiros
class GlobalAgendaScreen extends StatefulWidget {
  const GlobalAgendaScreen({Key? key}) : super(key: key);

  @override
  State<GlobalAgendaScreen> createState() => _GlobalAgendaScreenState();
}

class _GlobalAgendaScreenState extends State<GlobalAgendaScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  List<AgendaEvent> _allEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllEvents();
  }

  Future<void> _loadAllEvents() async {
    setState(() => _isLoading = true);
    
    try {
      final petService = PetProfileService();
      await petService.init();
      
      final petNames = await petService.getAllPetNames();
      final List<AgendaEvent> events = [];
      
      // Carregar eventos de todos os pets
      for (final petName in petNames) {
        final profileData = await petService.getProfile(petName);
        if (profileData != null) {
          final agendaEvents = profileData['data']?['agendaEvents'] as List? ?? [];
          for (final eventData in agendaEvents) {
            try {
              final event = AgendaEvent.fromJson(Map<String, dynamic>.from(eventData as Map));
              events.add(event);
            } catch (e) {
              debugPrint('Error parsing event: $e');
            }
          }
        }
      }
      
      setState(() {
        _allEvents = events;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading events: $e');
      setState(() => _isLoading = false);
    }
  }

  List<AgendaEvent> _getEventsForDay(DateTime day) {
    return _allEvents.where((event) {
      return event.dateTime.year == day.year &&
          event.dateTime.month == day.month &&
          event.dateTime.day == day.day;
    }).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  @override
  Widget build(BuildContext context) {
    final eventsForSelectedDay = _getEventsForDay(_selectedDay);
    
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Agenda Geral',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadAllEvents,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)))
          : Column(
              children: [
                // Calendário
                TableCalendar(
                  firstDay: DateTime.now().subtract(const Duration(days: 365)),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: const Color(0xFF00E676).withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Color(0xFF00E676),
                      shape: BoxShape.circle,
                    ),
                    defaultTextStyle: const TextStyle(color: Colors.white),
                    weekendTextStyle: const TextStyle(color: Colors.white70),
                  ),
                  headerStyle: HeaderStyle(
                    titleTextStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
                    formatButtonVisible: false,
                    leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white),
                    rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white),
                  ),
                  daysOfWeekStyle: const DaysOfWeekStyle(
                    weekdayStyle: TextStyle(color: Colors.white70),
                    weekendStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                
                const Divider(color: Colors.white10),
                
                // Timeline de eventos
                Expanded(
                  child: eventsForSelectedDay.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_busy, size: 64, color: Colors.white30),
                              const SizedBox(height: 16),
                              Text(
                                'Nenhum evento para este dia',
                                style: GoogleFonts.poppins(color: Colors.white30, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Acesse o perfil de um pet para adicionar',
                                style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.2), fontSize: 12),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: eventsForSelectedDay.length,
                          itemBuilder: (context, index) {
                            final event = eventsForSelectedDay[index];
                            return _buildEventCard(event);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildEventCard(AgendaEvent event) {
    return Card(
      color: Colors.white.withOpacity(0.08),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: event.category.color.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(event.category.icon, color: event.category.color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.title,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    event.petId ?? 'Pet',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF00E676),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.white54, size: 14),
                const SizedBox(width: 4),
                Text(
                  DateFormat('HH:mm').format(event.dateTime),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                if (event.attendant != null) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.person, color: Colors.white54, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    event.attendant!,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ],
            ),
            if (event.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                event.description,
                style: const TextStyle(color: Colors.white60, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (event.attachments.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.attach_file, color: Colors.white30, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${event.attachments.length} anexo(s)',
                    style: const TextStyle(color: Colors.white30, fontSize: 11),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
