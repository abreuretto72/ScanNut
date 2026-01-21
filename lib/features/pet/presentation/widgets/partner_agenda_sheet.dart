import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:scannut/l10n/app_localizations.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../core/models/partner_model.dart';

class PartnerAgendaSheet extends StatefulWidget {
  final PartnerModel partner;
  final List<Map<String, dynamic>> initialEvents;
  final Function(List<Map<String, dynamic>>) onSave;

  const PartnerAgendaSheet({
    super.key,
    required this.partner,
    required this.initialEvents,
    required this.onSave,
  });

  @override
  State<PartnerAgendaSheet> createState() => _PartnerAgendaSheetState();
}

class _PartnerAgendaSheetState extends State<PartnerAgendaSheet> {
  late List<Map<String, dynamic>> _events;
  
  // Controllers for new event
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _events = List.from(widget.initialEvents);
    // Sort by date/time (newest first)
    _sortEvents();
  }

  void _sortEvents() {
    _events.sort((a, b) {
        final dA = DateTime.parse(a['date']);
        final dB = DateTime.parse(b['date']);
        return dB.compareTo(dA);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _saveEvent() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    // Construct DateTime from selected Date + Time
    final fullDateTime = DateTime(
      _selectedDate.year, 
      _selectedDate.month, 
      _selectedDate.day,
      _selectedTime.hour, 
      _selectedTime.minute
    );

    setState(() {
      _events.insert(0, {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'content': _descController.text.trim(),
        'date': fullDateTime.toIso8601String(), // This is the Event Date
        'createdAt': DateTime.now().toIso8601String(),
        'type': 'event'
      });
      _sortEvents();
      _isAdding = false;
      _titleController.clear();
      _descController.clear();
    });
    
    widget.onSave(_events);
  }

  void _deleteEvent(Map<String, dynamic> event) {
      setState(() {
          _events.removeWhere((e) => e['id'] == event['id']);
      });
      widget.onSave(_events);
  }

  Map<String, List<Map<String, dynamic>>> _groupEventsByDate() {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final event in _events) {
      final date = DateTime.parse(event['date']);
      final key = DateFormat('yyyy-MM-dd').format(date);
      if (!grouped.containsKey(key)) grouped[key] = [];
      grouped[key]!.add(event);
    }
    return grouped;
  }
  
  // Helpers
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      isDense: true,
      border: const OutlineInputBorder(),
      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppDesign.petPink)),
    );
  }

  Widget _buildDateHeader(String dateKey) {
    final date = DateTime.parse(dateKey);
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    final isYesterday = DateUtils.isSameDay(date, DateTime.now().subtract(const Duration(days: 1)));
    
    String label;
    if (isToday) {
      label = AppLocalizations.of(context)!.todayLabel;
    } else if (isYesterday) label = AppLocalizations.of(context)!.agendaYesterday; // Will add to ARB
    else label = DateFormat('dd MMMM', Localizations.localeOf(context).toString()).format(date);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Row(
        children: [
          Container(
            width: 8, height: 8, 
            decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle)
          ),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.poppins(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 1, color: Colors.white10)),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> event) {
      final date = DateTime.parse(event['date']);
      
      return Dismissible(
        key: Key(event['id']),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => _deleteEvent(event),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: Colors.red.withOpacity(0.2),
          child: const Icon(Icons.delete, color: Colors.red),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            border: Border(left: BorderSide(color: AppDesign.petPink.withOpacity(0.5), width: 2)),
            borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8))
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Text(event['title'], style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                   Text(
                     DateFormat('HH:mm').format(date), 
                     style: const TextStyle(color: Colors.white38, fontSize: 12)
                   ),
                 ],
               ),
               if (event['content'] != null && event['content'].isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(event['content'], style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  )
            ],
          ),
        ),
      );
  }

  Widget _buildEmptyState() {
      return Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                  Icon(Icons.event_busy, size: 48, color: Colors.white.withOpacity(0.1)),
                  const SizedBox(height: 16),
                  Text(
                      AppLocalizations.of(context)!.agendaNoEvents, 
                      style: const TextStyle(color: Colors.white30)
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                      onPressed: () => setState(() => _isAdding = true),
                      icon: const Icon(Icons.add),
                      label: Text(AppLocalizations.of(context)!.agendaNewEvent),
                      style: OutlinedButton.styleFrom(foregroundColor: AppDesign.petPink)
                  )
              ],
          ),
      );
  }

  Widget _buildAddEventForm() {
      return Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: AppDesign.petPink.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppDesign.petPink.withOpacity(0.2))
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Text(AppLocalizations.of(context)!.agendaNewEvent, style: const TextStyle(color: AppDesign.petPink, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextFormField(
                      controller: _titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(AppLocalizations.of(context)!.agendaEventTitle),
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                      children: [
                          Expanded(
                              child: InkWell(
                                  onTap: () async {
                                      final d = await showDatePicker(
                                          context: context, 
                                          initialDate: _selectedDate, 
                                          firstDate: DateTime(2020), 
                                          lastDate: DateTime(2030)
                                      );
                                      if (d != null) setState(() => _selectedDate = d);
                                  },
                                  child: InputDecorator(
                                      decoration: _inputDecoration(AppLocalizations.of(context)!.agendaDate),
                                      child: Text(DateFormat('dd/MM/yyyy').format(_selectedDate), style: const TextStyle(color: Colors.white)),
                                  ),
                              ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                              child: InkWell(
                                  onTap: () async {
                                      final t = await showTimePicker(context: context, initialTime: _selectedTime);
                                      if (t != null) setState(() => _selectedTime = t);
                                  },
                                  child: InputDecorator(
                                      decoration: _inputDecoration(AppLocalizations.of(context)!.agendaTime),
                                      child: Text(_selectedTime.format(context), style: const TextStyle(color: Colors.white)),
                                  ),
                              ),
                          ),
                      ],
                  ),
                  
                  const SizedBox(height: 12),
                  TextFormField(
                      controller: _descController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(AppLocalizations.of(context)!.petEvent_details),
                      maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                          TextButton(
                              onPressed: () => setState(() => _isAdding = false), 
                              child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(color: Colors.white54))
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                              onPressed: _saveEvent,
                              style: ElevatedButton.styleFrom(backgroundColor: AppDesign.petPink, foregroundColor: Colors.black),
                              child: Text(AppLocalizations.of(context)!.petEvent_save),
                          )
                      ],
                  )
              ],
          ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).viewPadding.bottom + 20,
        left: 20,
        right: 20,
        top: 20
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.event_note, color: Colors.amberAccent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${AppLocalizations.of(context)!.petPartnersSchedule}: ${widget.partner.name}', 
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!_isAdding)
                IconButton(
                    icon: const Icon(Icons.add_circle, color: AppDesign.petPink), 
                    onPressed: () => setState(() => _isAdding = true)
                ),
              IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context))
            ],
          ),
          const SizedBox(height: 20),
          
          if (_isAdding) _buildAddEventForm(),
          
          Expanded(
            child: _events.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: _groupEventsByDate().length,
                  itemBuilder: (context, index) {
                      final grouped = _groupEventsByDate();
                      final keys = grouped.keys.toList()..sort((a,b)=>b.compareTo(a));
                      final key = keys[index];
                      final events = grouped[key]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDateHeader(key),
                          ...events.map((e) => _buildTimelineItem(e)),
                          const SizedBox(height: 16),
                        ],
                      );
                  } 
              ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
