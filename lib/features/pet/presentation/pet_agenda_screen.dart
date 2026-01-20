import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/pet_event.dart';
import '../services/pet_event_service.dart';
import '../../../core/providers/pet_event_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:scannut/l10n/app_localizations.dart';
import '../../../../core/theme/app_design.dart';

class PetAgendaScreen extends ConsumerStatefulWidget {
  final String petId;
  final String petName;

  const PetAgendaScreen({Key? key, required this.petId, required this.petName}) : super(key: key);

  @override
  ConsumerState<PetAgendaScreen> createState() => _PetAgendaScreenState();
}

class _PetAgendaScreenState extends ConsumerState<PetAgendaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  EventType? _filterType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddEventDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddEventDialog(petId: widget.petId, petName: widget.petName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventServiceAsync = ref.watch(petEventServiceProvider);

    return eventServiceAsync.when(
      data: (eventService) => _buildContent(context, eventService),
      loading: () => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Agenda',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppDesign.petPink),
        ),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Agenda',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
        body: Center(
          child: Text(
            '${AppLocalizations.of(context)!.commonError}: $error',
            style: GoogleFonts.poppins(color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, PetEventService eventService) {
    final allEvents = eventService.getEventsByPet(widget.petName);
    final upcomingEvents = eventService.getUpcomingEvents(widget.petName);
    final pastEvents = eventService.getPastEvents(widget.petName);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.agendaTitle,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            Text(
              widget.petName,
              style: GoogleFonts.poppins(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          // Filter button
          PopupMenuButton<EventType?>(
            icon: Icon(
              _filterType == null ? Icons.filter_list : Icons.filter_alt,
              color: _filterType == null ? Colors.white54 : Colors.blueAccent,
            ),
            onSelected: (type) {
              setState(() => _filterType = type);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: null,
                child: Text(AppLocalizations.of(context)!.agendaTabAll, style: GoogleFonts.poppins()),
              ),
              ...EventType.values.map((type) {
                final event = PetEvent(
                  id: '',
                  petId: '',
                  petName: '',
                  title: '',
                  type: type,
                  dateTime: DateTime.now(),
                );
                return PopupMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Text(event.typeEmoji),
                      const SizedBox(width: 8),
                      Text(event.typeLabel, style: GoogleFonts.poppins()),
                    ],
                  ),
                );
              }),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppDesign.petPink,
          labelColor: AppDesign.petPink,
          unselectedLabelColor: Colors.white54,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: '${AppLocalizations.of(context)!.agendaTabUpcoming} (${upcomingEvents.length})'),
            Tab(text: '${AppLocalizations.of(context)!.agendaTabPast} (${pastEvents.length})'),
            Tab(text: '${AppLocalizations.of(context)!.agendaTabAll} (${allEvents.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEventList(upcomingEvents, isEmpty: upcomingEvents.isEmpty, emptyMessage: AppLocalizations.of(context)!.agendaNoUpcoming),
          _buildEventList(pastEvents, isEmpty: pastEvents.isEmpty, emptyMessage: AppLocalizations.of(context)!.agendaNoPast),
          _buildEventList(allEvents, isEmpty: allEvents.isEmpty, emptyMessage: AppLocalizations.of(context)!.agendaNoEvents),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddEventDialog,
        backgroundColor: AppDesign.petPink,
        icon: const Icon(Icons.add, color: Colors.black),
        label: Text(
          AppLocalizations.of(context)!.agendaNewEvent,
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEventList(List<PetEvent> events, {required bool isEmpty, required String emptyMessage}) {
    if (isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: GoogleFonts.poppins(color: Colors.white54),
            ),
          ],
        ),
      );
    }

    // Apply filter if set
    final filteredEvents = _filterType == null
        ? events
        : events.where((e) => e.type == _filterType).toList();

    if (filteredEvents.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.agendaNoFiltered,
          style: GoogleFonts.poppins(color: Colors.white54),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredEvents.length,
      itemBuilder: (context, index) {
        final event = filteredEvents[index];
        return _EventCard(
          event: event,
          onTap: () => _showEventDetails(event),
          onDelete: () => _deleteEvent(event),
          onToggleComplete: () => _toggleComplete(event),
        );
      },
    );
  }

  void _showEventDetails(PetEvent event) {
    showDialog(
      context: context,
      builder: (context) => _EventDetailsDialog(event: event),
    );
  }

  void _deleteEvent(PetEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(AppLocalizations.of(context)!.agendaDeleteTitle, style: GoogleFonts.poppins(color: Colors.white)),
        content: Text(
          AppLocalizations.of(context)!.agendaDeleteContent(event.title),
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.btnCancel, style: GoogleFonts.poppins(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.btnDelete, style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final service = await ref.read(petEventServiceProvider.future);
      await service.deleteEvent(event.id);
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.agendaDeleted, style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleComplete(PetEvent event) async {
    final service = await ref.read(petEventServiceProvider.future);
    await service.markAsCompleted(event.id);
    setState(() {});
  }
}

// Event Card Widget
class _EventCard extends StatelessWidget {
  final PetEvent event;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onToggleComplete;

  const _EventCard({
    required this.event,
    required this.onTap,
    required this.onDelete,
    required this.onToggleComplete,
  });

  Color get _eventColor {
    switch (event.type) {
      case EventType.vaccine:
        return Colors.purple;
      case EventType.bath:
        return Colors.blue;
      case EventType.grooming:
        return Colors.pink;
      case EventType.veterinary:
        return Colors.red;
      case EventType.medication:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final isOverdue = event.isPast && !event.completed;

    return Card(
      color: Colors.white.withOpacity(0.05),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isOverdue ? Colors.red.withOpacity(0.5) : _eventColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Type icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _eventColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(event.typeEmoji, style: const TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  // Title and type
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            decoration: event.completed ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        Text(
                          event.typeLabel,
                          style: GoogleFonts.poppins(
                            color: _eventColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Complete checkbox
                  if (!event.isPast)
                    IconButton(
                      icon: Icon(
                        event.completed ? Icons.check_circle : Icons.circle_outlined,
                        color: event.completed ? AppDesign.petPink : Colors.white54,
                      ),
                      onPressed: onToggleComplete,
                    ),
                  // Delete button
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: onDelete,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Date and time
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: isOverdue ? Colors.red : Colors.white54),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(event.dateTime),
                    style: GoogleFonts.poppins(
                      color: isOverdue ? Colors.red : Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  if (isOverdue) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.agendaStatusOverdue,
                        style: GoogleFonts.poppins(
                          color: Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  if (event.isToday && !event.completed) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.agendaStatusToday,
                        style: GoogleFonts.poppins(
                          color: Colors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              // Recurrence
              if (event.recurrence != RecurrenceType.once) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.repeat, size: 16, color: Colors.white54),
                    const SizedBox(width: 4),
                    Text(
                      event.recurrenceLabel,
                      style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ],
              // Notes
              if (event.notes != null && event.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  event.notes!,
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Add Event Dialog (placeholder - will be implemented next)
class _AddEventDialog extends ConsumerStatefulWidget {
  final String petId;
  final String petName;
  final PetEvent? existingEvent;

  const _AddEventDialog({required this.petId, required this.petName, this.existingEvent});

  @override
  ConsumerState<_AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends ConsumerState<_AddEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  
  EventType _selectedType = EventType.other;
  RecurrenceType _selectedRecurrence = RecurrenceType.once;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _notificationMinutes = 1440; // 1 day
  
  // Available vaccines
  final List<String> _availableVaccines = [
    'V10 ou V8 (Polivalente)',
    'Antirrábica',
    'Gripe Canina (Tosse dos Canis)',
    'Giárdia',
    'Leishmaniose',
    'Influenza Canina (H3N8)',
    'Outra vacina',
  ];
  String? _selectedVaccine;

  @override
  void initState() {
    super.initState();
    if (widget.existingEvent != null) {
      _titleController.text = widget.existingEvent!.title;
      _notesController.text = widget.existingEvent!.notes ?? '';
      _selectedType = widget.existingEvent!.type;
      _selectedRecurrence = widget.existingEvent!.recurrence;
      _selectedDate = widget.existingEvent!.dateTime;
      _selectedTime = TimeOfDay.fromDateTime(widget.existingEvent!.dateTime);
      _notificationMinutes = widget.existingEvent!.notificationMinutes;
      
      // If it's a vaccine event, try to match with available vaccines
      if (_selectedType == EventType.vaccine) {
        final title = widget.existingEvent!.title;
        if (_availableVaccines.contains(title)) {
          _selectedVaccine = title;
        } else {
          _selectedVaccine = 'Outra vacina';
          _titleController.text = title;
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  void _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final service = await ref.read(petEventServiceProvider.future);
    
    // Get the correct title based on event type
    String eventTitle;
    if (_selectedType == EventType.vaccine) {
      if (_selectedVaccine == 'Outra vacina' || _selectedVaccine == null) {
        eventTitle = _titleController.text.trim();
      } else {
        eventTitle = _selectedVaccine!;
      }
    } else {
      eventTitle = _titleController.text.trim();
    }

    if (widget.existingEvent != null) {
      // Update existing event
      final updatedEvent = PetEvent(
        id: widget.existingEvent!.id,
        petId: widget.existingEvent!.petId,
        petName: widget.petName,
        title: eventTitle,
        type: _selectedType,
        dateTime: dateTime,
        recurrence: _selectedRecurrence,
        notificationMinutes: _notificationMinutes,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        completed: widget.existingEvent!.completed,
        createdAt: widget.existingEvent!.createdAt,
      );
      await service.updateEvent(updatedEvent);
    } else {
      // Create new event
      final event = PetEvent(
        id: const Uuid().v4(),
        petId: widget.petId,
        petName: widget.petName,
        title: eventTitle,
        type: _selectedType,
        dateTime: dateTime,
        recurrence: _selectedRecurrence,
        notificationMinutes: _notificationMinutes,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      await service.addEvent(event);
    }
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existingEvent != null ? AppLocalizations.of(context)!.agendaUpdated : AppLocalizations.of(context)!.agendaCreated,
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppDesign.petPink,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingEvent != null;
    return Dialog(
      backgroundColor: Colors.transparent, // Let Scaffold handle visual
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Scaffold(
          backgroundColor: Colors.grey[900],
          appBar: AppBar(
            backgroundColor: Colors.grey[900],
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              isEdit ? AppLocalizations.of(context)!.agendaEditEvent : AppLocalizations.of(context)!.agendaNewEvent,
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Title/Vaccine Selection
                          if (_selectedType == EventType.vaccine) ...[
                            DropdownButtonFormField<String>(
                              value: _selectedVaccine,
                              dropdownColor: Colors.grey[800],
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context)!.agendaFieldVaccineSelect,
                                labelStyle: const TextStyle(color: Colors.white54),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: AppDesign.petPink),
                                ),
                              ),
                              items: _availableVaccines.map((vaccine) {
                                return DropdownMenuItem(
                                  value: vaccine,
                                  child: Text(vaccine),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedVaccine = value;
                                  if (value != 'Outra vacina') {
                                    _titleController.text = value ?? '';
                                  } else {
                                    _titleController.clear();
                                  }
                                });
                              },
                              validator: (value) => value == null ? AppLocalizations.of(context)!.agendaFieldVaccineSelect : null,
                            ),
                            const SizedBox(height: 16),
                            if (_selectedVaccine == 'Outra vacina')
                              TextFormField(
                                controller: _titleController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: AppLocalizations.of(context)!.agendaFieldVaccineName,
                                  labelStyle: const TextStyle(color: Colors.white54),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(color: AppDesign.petPink),
                                  ),
                                ),
                                validator: (value) => value == null || value.trim().isEmpty ? AppLocalizations.of(context)!.agendaRequired : null,
                              ),
                          ] else
                            TextFormField(
                              controller: _titleController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context)!.agendaFieldTitle,
                                labelStyle: const TextStyle(color: Colors.white54),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: AppDesign.petPink),
                                ),
                              ),
                              validator: (value) => value == null || value.trim().isEmpty ? AppLocalizations.of(context)!.agendaRequired : null,
                            ),
                          const SizedBox(height: 16),
                          // Type
                          DropdownButtonFormField<EventType>(
                            value: _selectedType,
                            dropdownColor: Colors.grey[800],
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.agendaFieldType,
                              labelStyle: const TextStyle(color: Colors.white54),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: AppDesign.petPink),
                              ),
                            ),
                            items: EventType.values.map((type) {
                              final dummyEvent = PetEvent(
                                id: '',
                                petId: '',
                                petName: '',
                                title: '',
                                type: type,
                                dateTime: DateTime.now(),
                              );
                              return DropdownMenuItem(
                                value: type,
                                child: Row(
                                  children: [
                                    Text(dummyEvent.typeEmoji),
                                    const SizedBox(width: 8),
                                    Text(dummyEvent.typeLabel),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedType = value!;
                                if (value != EventType.vaccine) {
                                  _selectedVaccine = null;
                                  if (_titleController.text.isEmpty) {
                                    _titleController.clear();
                                  }
                                } else {
                                  _titleController.clear();
                                  _selectedVaccine = null;
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          // Date and Time
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _selectDate,
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.white.withOpacity(0.3)),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16)
                                  ),
                                  icon: const Icon(Icons.calendar_today, color: Colors.white, size: 20),
                                  label: Text(
                                    DateFormat('dd/MM/yyyy').format(_selectedDate),
                                    style: GoogleFonts.poppins(color: Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _selectTime,
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.white.withOpacity(0.3)),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16)
                                  ),
                                  icon: const Icon(Icons.access_time, color: Colors.white, size: 20),
                                  label: Text(
                                    _selectedTime.format(context),
                                    style: GoogleFonts.poppins(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Recurrence
                          DropdownButtonFormField<RecurrenceType>(
                            value: _selectedRecurrence,
                            dropdownColor: Colors.grey[800],
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Recorrência',
                              labelStyle: const TextStyle(color: Colors.white54),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: AppDesign.petPink),
                              ),
                            ),
                            items: RecurrenceType.values.map((type) {
                              final dummyEvent = PetEvent(
                                id: '',
                                petId: '',
                                petName: '',
                                title: '',
                                type: EventType.other,
                                dateTime: DateTime.now(),
                                recurrence: type,
                              );
                              return DropdownMenuItem(
                                value: type,
                                child: Text(dummyEvent.recurrenceLabel),
                              );
                            }).toList(),
                            onChanged: (value) => setState(() => _selectedRecurrence = value!),
                          ),
                          const SizedBox(height: 16),
                          // Notes
                          TextFormField(
                            controller: _notesController,
                            style: const TextStyle(color: Colors.white),
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Observações (opcional)',
                              labelStyle: const TextStyle(color: Colors.white54),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: AppDesign.petPink),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // 🦶 BUTTON AREA (FULL WIDTH + SAFE AREA)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _saveEvent,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppDesign.petPink,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          child: Text(
                            'SALVAR',
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1.2
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20), // Padding below button as requested
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Event Details Dialog (placeholder)
class _EventDetailsDialog extends StatelessWidget {
  final PetEvent event;

  const _EventDetailsDialog({required this.event});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: Row(
        children: [
          Text(event.typeEmoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              event.title,
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailRow(label: 'Tipo', value: event.typeLabel),
          _DetailRow(label: 'Data', value: DateFormat('dd/MM/yyyy HH:mm').format(event.dateTime)),
          _DetailRow(label: 'Recorrência', value: event.recurrenceLabel),
          if (event.notes != null) _DetailRow(label: 'Observações', value: event.notes!),
          _DetailRow(label: 'Status', value: event.completed ? 'Concluído' : event.isPast ? 'Atrasado' : 'Pendente'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context); // Close details dialog
            // Open edit dialog
            showDialog(
              context: context,
              builder: (context) => _AddEventDialog(
                petId: event.petId,
                petName: event.petName,
                existingEvent: event,
              ),
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.edit, size: 18, color: Colors.blueAccent),
              const SizedBox(width: 4),
              Text('Editar', style: GoogleFonts.poppins(color: Colors.blueAccent)),
            ],
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Fechar', style: GoogleFonts.poppins(color: Colors.white)),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
