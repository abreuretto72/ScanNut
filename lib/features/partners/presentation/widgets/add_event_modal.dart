import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:scannut/l10n/app_localizations.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/models/partner_model.dart';
import '../../models/agenda_event.dart';
import '../../../pet/services/pet_event_service.dart';
import '../../../pet/services/pet_indexing_service.dart';
import '../../../../core/theme/app_design.dart';
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
    super.key,
    required this.selectedDate,
    required this.scrollController,
    required this.partner,
    this.petId,
    this.existingEvent,
    required this.onSave,
    required this.speech,
    this.isReadOnly = false,
  });

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
    if (cat == EventCategory.consulta ||
        cat == EventCategory.saude ||
        cat == EventCategory.emergencia ||
        cat == EventCategory.exame ||
        cat == EventCategory.cirurgia) {
      return EventType.veterinary;
    }
    if (cat == EventCategory.remedios) return EventType.medication;
    return EventType.other;
  }

  Future<void> _pickAttachment() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppDesign.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppDesign.petPink),
              title: Text(AppLocalizations.of(context)!.commonCamera,
                  style: const TextStyle(color: AppDesign.textPrimaryDark)),
              onTap: () async {
                Navigator.pop(context);
                final photo =
                    await _imagePicker.pickImage(source: ImageSource.camera);
                if (photo != null) {
                  setState(() => _attachments.add(photo.path));
                }
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: AppDesign.petPink),
              title: Text(AppLocalizations.of(context)!.commonGallery,
                  style: const TextStyle(color: AppDesign.textPrimaryDark)),
              onTap: () async {
                Navigator.pop(context);
                final photo =
                    await _imagePicker.pickImage(source: ImageSource.gallery);
                if (photo != null) {
                  setState(() => _attachments.add(photo.path));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file, color: AppDesign.petPink),
              title: Text(AppLocalizations.of(context)!.commonPDFFile,
                  style: const TextStyle(color: AppDesign.textPrimaryDark)),
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
        onError: (errorNotification) =>
            debugPrint('onError: $errorNotification'),
      );
      if (available) {
        setState(() => _isListening = true);
        widget.speech.listen(
          onResult: (val) {
            setState(() {
              _contentController.text = val.recognizedWords;
            });
          },
          localeId: Localizations.localeOf(context).toString(),
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
                      ? AppLocalizations.of(context)!.agendaAppointmentDetails
                      : (widget.existingEvent != null
                          ? AppLocalizations.of(context)!.agendaEditEvent
                          : AppLocalizations.of(context)!.agendaNewEvent),
                  style: GoogleFonts.poppins(
                    color: AppDesign.textPrimaryDark,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Campo: Parceiro/Local (Visualização apenas)
              _buildInfoField(
                  AppLocalizations.of(context)!.agendaResponsiblePartner,
                  widget.partner.name,
                  Icons.location_on),
              const SizedBox(height: 16),

              // Campo: Pet (Visualização apenas se houver petId)
              if (widget.petId != null) ...[
                _buildInfoField(AppLocalizations.of(context)!.pdfFieldPet,
                    widget.petId!, Icons.pets),
                const SizedBox(height: 16),
              ],

              // Campo: Data
              _buildInfoField(
                  AppLocalizations.of(context)!.pdfDate,
                  DateFormat('dd/MM/yyyy').format(widget.selectedDate),
                  Icons.calendar_today),
              const SizedBox(height: 16),

              // Campo: Hora
              Text(AppLocalizations.of(context)!.pdfFieldTime,
                  style: const TextStyle(
                      color: AppDesign.textSecondaryDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              InkWell(
                onTap: () async {
                  final t = await showTimePicker(
                    context: context,
                    initialTime: _time,
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                        timePickerTheme: const TimePickerThemeData(
                          backgroundColor: AppDesign.surfaceDark,
                          hourMinuteTextColor: AppDesign.textPrimaryDark,
                          dialBackgroundColor: AppDesign.backgroundDark,
                          dialHandColor: AppDesign.petPink,
                        ),
                        colorScheme: const ColorScheme.dark(
                          primary: AppDesign.petPink,
                          onSurface: AppDesign.textPrimaryDark,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (t != null) setState(() => _time = t);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: AppDesign.petPink),
                      const SizedBox(width: 12),
                      Text(
                        _time.format(context),
                        style: const TextStyle(
                          color: AppDesign.textPrimaryDark,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (!widget.isReadOnly)
                        Text(AppLocalizations.of(context)!.agendaChange,
                            style: const TextStyle(
                                color: AppDesign.textSecondaryDark,
                                fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(AppLocalizations.of(context)!.pdfFieldCategory,
                  style: const TextStyle(
                      color: AppDesign.textSecondaryDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppDesign.textPrimaryDark.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppDesign.textPrimaryDark.withValues(alpha: 0.1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<EventCategory>(
                    value: _selectedCategory,
                    isExpanded: true,
                    dropdownColor: AppDesign.surfaceDark,
                    icon: const Icon(Icons.arrow_drop_down,
                        color: AppDesign.petPink),
                    style: const TextStyle(
                        color: AppDesign.textPrimaryDark, fontSize: 14),
                    items: EventCategory.values.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Row(
                          children: [
                            Icon(category.icon,
                                color: category.color, size: 18),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Text(category.label,
                                    style: const TextStyle(
                                        color: AppDesign.textPrimaryDark))),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ATENDENTE / ESPECIALISTA (BLINDADO)
              Builder(builder: (context) {
                // 1. Garantir lista segura
                final validMembers = widget.partner.teamMembers
                    .where((m) => m.trim().isNotEmpty)
                    .toList();
                final hasMembers = validMembers.isNotEmpty;

                // 2. Se não houver membros, usar lista fallback para evitar erro items.isNotEmpty
                final safeItems = hasMembers
                    ? validMembers
                    : [AppLocalizations.of(context)!.agendaNoAttendants];

                // 3. Garantir value seguro
                String? safeValue = _selectedAttendant;
                if (hasMembers) {
                  if (safeValue != null && !validMembers.contains(safeValue)) {
                    safeValue = null; // Reset se não estiver na lista
                  }
                } else {
                  safeValue = safeItems.first; // Selecionar o fallback
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        AppLocalizations.of(context)!.agendaAttendantSpecialist,
                        style: const TextStyle(
                            color: AppDesign.textSecondaryDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: safeValue,
                          isExpanded: true,
                          dropdownColor: AppDesign.surfaceDark,
                          icon: const Icon(Icons.arrow_drop_down,
                              color: AppDesign.petPink),
                          hint: Row(
                            children: [
                              const Icon(Icons.person,
                                  color: AppDesign.textSecondaryDark, size: 18),
                              const SizedBox(width: 12),
                              Text(
                                  AppLocalizations.of(context)!
                                      .agendaSelectAttendant,
                                  style: GoogleFonts.poppins(
                                      color: AppDesign.textPrimaryDark
                                          .withValues(alpha: 0.3),
                                      fontSize: 14)),
                            ],
                          ),
                          // 🛡️ PROTEÇÃO: Se não há membros, desabilitar ou mostrar mensagem informativa
                          items: safeItems
                              .map((name) => DropdownMenuItem(
                                  value: name,
                                  enabled:
                                      hasMembers, // Desabilitar se for mensagem de erro
                                  child: Text(name,
                                      style: TextStyle(
                                          color: hasMembers
                                              ? AppDesign.textPrimaryDark
                                              : AppDesign.textSecondaryDark))))
                              .toList(),
                          onChanged: hasMembers
                              ? (val) =>
                                  setState(() => _selectedAttendant = val)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }),

              TextField(
                controller: _titleController,
                readOnly: widget.isReadOnly,
                style: const TextStyle(color: AppDesign.textPrimaryDark),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.agendaEventTitle,
                  labelStyle: const TextStyle(
                      color: AppDesign.petPink, fontWeight: FontWeight.bold),
                  hintText: AppLocalizations.of(context)!.agendaTitleExample,
                  hintStyle:
                      const TextStyle(color: AppDesign.textSecondaryDark),
                  filled: true,
                  fillColor: Colors.white10,
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white10)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppDesign.petPink)),
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
                    style: const TextStyle(color: AppDesign.textPrimaryDark),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.pdfObservations,
                      labelStyle: const TextStyle(
                          color: AppDesign.petPink,
                          fontWeight: FontWeight.bold),
                      hintText:
                          AppLocalizations.of(context)!.agendaObservationsHint,
                      hintStyle:
                          const TextStyle(color: AppDesign.textSecondaryDark),
                      filled: true,
                      fillColor: Colors.white10,
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white10)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppDesign.petPink)),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  if (!widget.isReadOnly)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: FloatingActionButton.small(
                        onPressed: _listen,
                        backgroundColor:
                            _isListening ? AppDesign.error : AppDesign.petPink,
                        child: Icon(_isListening ? Icons.stop : Icons.mic,
                            color: Colors.black),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white10,
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
                            const Icon(Icons.attach_file,
                                color: AppDesign.petPink, size: 18),
                            const SizedBox(width: 8),
                            Text(
                                AppLocalizations.of(context)!
                                    .agendaAttachmentsFull,
                                style: GoogleFonts.poppins(
                                    color: AppDesign.textSecondaryDark,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                        if (!widget.isReadOnly)
                          IconButton(
                              icon: const Icon(Icons.add_photo_alternate,
                                  color: AppDesign.petPink, size: 20),
                              onPressed: _pickAttachment,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints()),
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
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                                color:
                                    AppDesign.petPink.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.attach_file,
                                    size: 14, color: AppDesign.petPink),
                                const SizedBox(width: 6),
                                ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 120),
                                    child: Text(fileName,
                                        style: const TextStyle(
                                            color: AppDesign.textPrimaryDark,
                                            fontSize: 11),
                                        overflow: TextOverflow.ellipsis)),
                                const SizedBox(width: 4),
                                if (!widget.isReadOnly)
                                  GestureDetector(
                                      onTap: () => setState(
                                          () => _attachments.removeAt(index)),
                                      child: const Icon(Icons.close,
                                          size: 14,
                                          color: AppDesign.textSecondaryDark)),
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
                    onPressed: () async {
                      if (_titleController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                AppLocalizations.of(context)!.agendaEnterTitle),
                            backgroundColor: AppDesign.warning));
                        return;
                      }
                      // ... (existing code for creating event object)
                      final event = widget.existingEvent?.copyWith(
                            category: _selectedCategory,
                            title: _titleController.text.trim(),
                            description: _contentController.text.trim(),
                            dateTime: DateTime(
                                widget.selectedDate.year,
                                widget.selectedDate.month,
                                widget.selectedDate.day,
                                _time.hour,
                                _time.minute),
                            attendant: _selectedAttendant,
                            attachments: _attachments,
                          ) ??
                          AgendaEvent(
                            id: DateTime.now()
                                .millisecondsSinceEpoch
                                .toString(),
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
                                _time.minute),
                            attendant: _selectedAttendant,
                            attachments: _attachments,
                            createdAt: DateTime.now(),
                          );

                      if (widget.petId != null) {
                        final pType = _mapCategoryToType(event.category);
                        final attendantInfo = event.attendant != null &&
                                event.attendant!.isNotEmpty
                            ? 'Atendente: ${event.attendant}\n\n'
                            : '';
                        final pEvent = PetEvent(
                          id: event.id,
                          petId: widget.petId!,
                          petName: widget.petId!,
                          title: event.title,
                          type: pType,
                          dateTime: event.dateTime,
                          notes: '$attendantInfo${event.description}',
                        );
                        await PetEventService().addEvent(pEvent);

                        // 🧠 AUTOMATIC INDEXING (MARE Logic)
                        try {
                          if (false) {
                            // Prevent duplicate events
                            final indexer = PetIndexingService();
                            indexer.indexAgendaEvent(
                              petId: widget.petId!,
                              petName: widget
                                  .petId!, // Using ID as name if name not available here
                              attendantName:
                                  event.attendant ?? widget.partner.name,
                              eventTitle: event.title,
                              dateTime: event.dateTime,
                              partnerId: widget.partner.id,
                              partnerName: widget.partner.name,
                              localizedTitle: AppLocalizations.of(context)!
                                  .petIndexing_agendaTitle(
                                event.attendant ?? widget.partner.name,
                                widget.petId!,
                              ),
                            );
                          }
                        } catch (e) {
                          debugPrint('⚠️ Indexing failed in AddEventModal: $e');
                        }
                      }
                      widget.onSave(event);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppDesign.petPink,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                    ),
                    child: Text(
                      widget.existingEvent != null
                          ? AppLocalizations.of(context)!.agendaSaveChanges
                          : AppLocalizations.of(context)!.agendaConfirmEvent,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1.1),
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
        Text(label,
            style: const TextStyle(
                color: AppDesign.textSecondaryDark,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: AppDesign.textPrimaryDark.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppDesign.textPrimaryDark.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Icon(icon,
                  color: AppDesign.textPrimaryDark.withValues(alpha: 0.24),
                  size: 18),
              const SizedBox(width: 12),
              Text(value,
                  style: const TextStyle(
                      color: AppDesign.textSecondaryDark, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}
