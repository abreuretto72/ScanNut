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
          child: _AddEventModal(
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
      ),
      body: Column(
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
          Expanded(
            child: dailyEvents.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: dailyEvents.length,
                    itemBuilder: (context, index) {
                      final event = dailyEvents[index];
                      return _buildTimelineItem(event, isLast: index == dailyEvents.length - 1);
                    },
            ),
          ),
        ],
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
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
                        // Badge if needed
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
                    ]
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------
// MODAL DE ENTRADA MULTIMODAL
// --------------------------------------------------------
class _AddEventModal extends StatefulWidget {
  final DateTime selectedDate;
  final ScrollController scrollController;
  final PartnerModel partner;
  final String? petId;
  final Function(AgendaEvent event) onSave;
  final stt.SpeechToText speech;

  const _AddEventModal({
    required this.selectedDate,
    required this.scrollController,
    required this.partner,
    this.petId,
    required this.onSave,
    required this.speech,
  });

  @override
  State<_AddEventModal> createState() => _AddEventModalState();
}

class _AddEventModalState extends State<_AddEventModal> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  late TimeOfDay _time;
  bool _isListening = false;
  
  // Novos campos multimodais
  EventCategory _selectedCategory = EventCategory.consulta;
  String? _selectedAttendant;
  List<String> _attachments = [];
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _time = TimeOfDay.now();
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
  
  Future<void> _pickAttachment() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF00E676)),
              title: const Text('Câmera', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final photo = await _imagePicker.pickImage(source: ImageSource.camera);
                if (photo != null) {
                  setState(() => _attachments.add(photo.path));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF00E676)),
              title: const Text('Galeria', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final photo = await _imagePicker.pickImage(source: ImageSource.gallery);
                if (photo != null) {
                  setState(() => _attachments.add(photo.path));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file, color: Color(0xFF00E676)),
              title: const Text('Arquivo PDF', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['pdf'],
                );
                if (result != null && result.files.single.path != null) {
                  setState(() => _attachments.add(result.files.single.path!));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await widget.speech.initialize(
        onStatus: (status) => debugPrint('onStatus: $status'),
        onError: (errorNotification) => debugPrint('onError: $errorNotification'),
      );
      if (available) {
        setState(() => _isListening = true);
        widget.speech.listen(
          onResult: (val) {
            setState(() {
              _contentController.text = val.recognizedWords;
            });
          },
          localeId: 'pt_BR', 
        );
      } else {
        debugPrint("Speech not available");
        // Fallback or permission request
        await Permission.microphone.request();
      }
    } else {
      setState(() => _isListening = false);
      widget.speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: ListView(
        controller: widget.scrollController,
        children: [
          Text(
            'Novo Evento • ${DateFormat('d/MM').format(widget.selectedDate)}',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Hora
          InkWell(
            onTap: () async {
              final t = await showTimePicker(
                context: context,
                initialTime: _time,
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    timePickerTheme: const TimePickerThemeData(
                      backgroundColor: Color(0xFF1E1E1E),
                      hourMinuteTextColor: Colors.white,
                      dialBackgroundColor: Colors.black,
                      dialHandColor: Color(0xFF00E676),
                    ),
                    colorScheme: const ColorScheme.dark(
                      primary: Color(0xFF00E676),
                      onSurface: Colors.white,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (t != null) setState(() => _time = t);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: Color(0xFF00E676)),
                  const SizedBox(width: 12),
                  Text(
                    _time.format(context),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Alterar',
                    style: TextStyle(color: Colors.white24, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Categoria
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<EventCategory>(
                value: _selectedCategory,
                isExpanded: true,
                dropdownColor: Colors.grey[850],
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF00E676)),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                items: EventCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Icon(category.icon, color: category.color, size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            category.label,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: category == EventCategory.ocorrencias 
                                  ? FontWeight.bold 
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (EventCategory? newValue) {
                  if (newValue != null) {
                    setState(() => _selectedCategory = newValue);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Atendente (se houver equipe cadastrada)
          if (widget.partner.teamMembers.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedAttendant,
                  isExpanded: true,
                  dropdownColor: Colors.grey[850],
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF00E676)),
                  hint: Row(
                    children: [
                      const Icon(Icons.person, color: Colors.white54, size: 18),
                      const SizedBox(width: 12),
                      Text(
                        'Selecione o atendente',
                        style: GoogleFonts.poppins(color: Colors.white30, fontSize: 14),
                      ),
                    ],
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  items: widget.partner.teamMembers.map((name) {
                    return DropdownMenuItem(
                      value: name,
                      child: Row(
                        children: [
                          const Icon(Icons.person, color: Color(0xFF00E676), size: 18),
                          const SizedBox(width: 12),
                          Text(name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() => _selectedAttendant = newValue);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Titulo
          TextField(
            controller: _titleController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Título (ex: Vacina, Banho)',
              hintStyle: const TextStyle(color: Colors.white30),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 16),

          // Voice & Text Area
          Stack(
            children: [
              TextField(
                controller: _contentController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Descrição ou notas...',
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: FloatingActionButton.small(
                  onPressed: _listen,
                  backgroundColor: _isListening
                      ? Colors.redAccent
                      : const Color(0xFF00E676),
                  child: Icon(
                    _isListening ? Icons.stop : Icons.mic,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          
          // Anexos
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.attach_file,
                          color: _selectedCategory == EventCategory.ocorrencias
                              ? const Color(0xFFFF6B6B)
                              : const Color(0xFF00E676),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selectedCategory == EventCategory.ocorrencias
                              ? 'Anexos (Fotos/Vídeos)'
                              : 'Anexos (Opcional)',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_photo_alternate, color: Color(0xFF00E676), size: 20),
                      onPressed: _pickAttachment,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                if (_attachments.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _attachments.asMap().entries.map((entry) {
                      final index = entry.key;
                      final path = entry.value;
                      final fileName = path.split('/').last;
                      final isImage = fileName.toLowerCase().endsWith('.jpg') ||
                          fileName.toLowerCase().endsWith('.jpeg') ||
                          fileName.toLowerCase().endsWith('.png');
                      final isPdf = fileName.toLowerCase().endsWith('.pdf');
                      
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E676).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF00E676).withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isImage ? Icons.image : (isPdf ? Icons.picture_as_pdf : Icons.videocam),
                              size: 16,
                              color: isImage ? Colors.blue : (isPdf ? Colors.red : Colors.purple),
                            ),
                            const SizedBox(width: 6),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 120),
                              child: Text(
                                fileName,
                                style: const TextStyle(color: Colors.white, fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                setState(() => _attachments.removeAt(index));
                              },
                              child: const Icon(Icons.close, size: 14, color: Colors.white70),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Nenhum anexo',
                      style: GoogleFonts.poppins(
                        color: Colors.white30,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Confirm Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor, insira um título'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                
                // Create AgendaEvent
                final event = AgendaEvent(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  partnerId: widget.partner.id,
                  petId: widget.petId,
                  category: _selectedCategory,
                  title: _titleController.text.trim(),
                  description: _contentController.text.trim(),
                  dateTime: DateTime(
                    widget.selectedDate.year,
                    widget.selectedDate.month,
                    widget.selectedDate.day,
                    _time.hour,
                    _time.minute,
                  ),
                  attendant: _selectedAttendant,
                  attachments: _attachments,
                  createdAt: DateTime.now(),
                );
                
                widget.onSave(event);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: const Text(
                'Confirmar',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          
          // Extra space at bottom for keyboard
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 20),
        ],
      ),
    );
  }
}
