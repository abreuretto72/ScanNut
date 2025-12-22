import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/models/partner_model.dart';
import '../../models/agenda_event.dart';
import '../../../pet/services/pet_event_service.dart';
import '../../../pet/models/pet_event.dart';

class AddEventModal extends StatefulWidget {
  final DateTime selectedDate;
  final ScrollController scrollController;
  final PartnerModel partner;
  final String? petId;
  final AgendaEvent? existingEvent;
  final Function(AgendaEvent event) onSave;
  final stt.SpeechToText speech;

  final bool isReadOnly;

  const AddEventModal({
    Key? key,
    required this.selectedDate,
    required this.scrollController,
    required this.partner,
    this.petId,
    this.existingEvent,
    required this.onSave,
    required this.speech,
    this.isReadOnly = false,
  }) : super(key: key);

  @override
  State<AddEventModal> createState() => _AddEventModalState();
}

class _AddEventModalState extends State<AddEventModal> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  late TimeOfDay _time;
  bool _isListening = false;
  
  EventCategory _selectedCategory = EventCategory.consulta;
  String? _selectedAttendant;
  List<String> _attachments = [];
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.existingEvent != null) {
      _titleController.text = widget.existingEvent!.title;
      _contentController.text = widget.existingEvent!.description;
      _time = TimeOfDay.fromDateTime(widget.existingEvent!.dateTime);
      _selectedCategory = widget.existingEvent!.category;
      _selectedAttendant = widget.existingEvent!.attendant;
      _attachments = List.from(widget.existingEvent!.attachments);
    } else {
      _time = TimeOfDay.now();
    }
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  EventType _mapCategoryToType(EventCategory cat) {
    if (cat == EventCategory.vacina) return EventType.vaccine;
    if (cat == EventCategory.banho) return EventType.bath;
    if (cat == EventCategory.tosa) return EventType.grooming;
    if (cat == EventCategory.consulta || cat == EventCategory.saude || cat == EventCategory.emergencia || cat == EventCategory.exame || cat == EventCategory.cirurgia) return EventType.veterinary;
    if (cat == EventCategory.remedios) return EventType.medication;
    return EventType.other;
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
      child: AbsorbPointer(
        absorbing: widget.isReadOnly,
        child: SingleChildScrollView(
          controller: widget.scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  widget.isReadOnly 
                    ? 'Detalhes do Evento' 
                    : (widget.existingEvent != null ? 'Editar Evento' : 'Novo Evento'),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Campo: Parceiro/Local (Visualização apenas)
              _buildInfoField('Parceiro/Local', widget.partner.name, Icons.location_on),
              const SizedBox(height: 16),

              // Campo: Pet (Visualização apenas se houver petId)
              if (widget.petId != null) ...[
                _buildInfoField('Pet', widget.petId!, Icons.pets),
                const SizedBox(height: 16),
              ],

              // Campo: Data
              _buildInfoField('Data', DateFormat('dd/MM/yyyy').format(widget.selectedDate), Icons.calendar_today),
              const SizedBox(height: 16),

              // Campo: Hora
              const Text('Hora', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
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
                      if (!widget.isReadOnly) 
                        const Text('Alterar', style: TextStyle(color: Colors.white24, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text('Categoria', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
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
                            Expanded(child: Text(category.label, style: TextStyle(color: Colors.white))),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) { if (val != null) setState(() => _selectedCategory = val); },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (widget.partner.teamMembers.isNotEmpty) ...[
                const Text('Atendente / Especialista', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
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
                          Text('Selecione o atendente', style: GoogleFonts.poppins(color: Colors.white30, fontSize: 14)),
                        ],
                      ),
                      items: widget.partner.teamMembers.map((name) => DropdownMenuItem(value: name, child: Text(name, style: const TextStyle(color: Colors.white)))).toList(),
                      onChanged: (val) => setState(() => _selectedAttendant = val),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              TextField(
                controller: _titleController,
                readOnly: widget.isReadOnly,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Título do Evento',
                  labelStyle: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold),
                  hintText: 'ex: Vacina Polivalente V10',
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00E676))),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 20),

              Stack(
                children: [
                  TextField(
                    controller: _contentController,
                    readOnly: widget.isReadOnly,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Observações',
                      labelStyle: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold),
                      hintText: 'Digite ou use o microfone...',
                      hintStyle: const TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00E676))),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  if (!widget.isReadOnly)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: FloatingActionButton.small(
                        onPressed: _listen,
                        backgroundColor: _isListening ? Colors.redAccent : const Color(0xFF00E676),
                        child: Icon(_isListening ? Icons.stop : Icons.mic, color: Colors.black),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              
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
                            Icon(Icons.attach_file, color: const Color(0xFF00E676), size: 18),
                            const SizedBox(width: 8),
                            Text('Anexos (PDF ou Fotos)', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        if (!widget.isReadOnly)
                          IconButton(icon: const Icon(Icons.add_photo_alternate, color: Color(0xFF00E676), size: 20), onPressed: _pickAttachment, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                      ],
                    ),
                    if (_attachments.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _attachments.asMap().entries.map((entry) {
                          final index = entry.key;
                          final path = entry.value;
                          final fileName = path.split('/').last;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: const Color(0xFF00E676).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.attach_file, size: 14, color: Color(0xFF00E676)),
                                const SizedBox(width: 6),
                                ConstrainedBox(constraints: const BoxConstraints(maxWidth: 120), child: Text(fileName, style: const TextStyle(color: Colors.white, fontSize: 11), overflow: TextOverflow.ellipsis)),
                                const SizedBox(width: 4),
                                if (!widget.isReadOnly)
                                  GestureDetector(onTap: () => setState(() => _attachments.removeAt(index)), child: const Icon(Icons.close, size: 14, color: Colors.white70)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              if (!widget.isReadOnly) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_titleController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, insira um título'), backgroundColor: Colors.orange));
                        return;
                      }
                      final event = widget.existingEvent?.copyWith(
                        category: _selectedCategory,
                        title: _titleController.text.trim(),
                        description: _contentController.text.trim(),
                        dateTime: DateTime(widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day, _time.hour, _time.minute),
                        attendant: _selectedAttendant,
                        attachments: _attachments,
                      ) ?? AgendaEvent(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        partnerId: widget.partner.id,
                        petId: widget.petId,
                        category: _selectedCategory,
                        title: _titleController.text.trim(),
                        description: _contentController.text.trim(),
                        dateTime: DateTime(widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day, _time.hour, _time.minute),
                        attendant: _selectedAttendant,
                        attachments: _attachments,
                        createdAt: DateTime.now(),
                      );
                      
                      if (widget.petId != null) {
                        final pType = _mapCategoryToType(event.category);
                        final attendantInfo = event.attendant != null && event.attendant!.isNotEmpty ? 'Atendente: ${event.attendant}\n\n' : '';
                        final pEvent = PetEvent(
                          id: event.id,
                          petName: widget.petId!,
                          title: event.title,
                          type: pType,
                          dateTime: event.dateTime,
                          notes: '$attendantInfo${event.description}',
                        );
                        PetEventService().addEvent(pEvent);
                      }
                      widget.onSave(event);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676), 
                      foregroundColor: Colors.black, 
                      padding: const EdgeInsets.symmetric(vertical: 16), 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                    ),
                    child: Text(
                      widget.existingEvent != null ? 'SALVAR ALTERAÇÕES' : 'CONFIRMAR EVENTO', 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom), 
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoField(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white24, size: 18),
              const SizedBox(width: 12),
              Text(value, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}
