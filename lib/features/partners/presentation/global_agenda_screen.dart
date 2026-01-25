import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:scannut/l10n/app_localizations.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../pet/services/pet_event_service.dart';
import '../../pet/models/pet_event.dart';
import '../models/agenda_event.dart';
import '../../pet/services/pet_profile_service.dart';
import '../../pet/presentation/widgets/edit_pet_form.dart';
import 'partner_event_detail_screen.dart';
import '../../../core/widgets/pdf_action_button.dart';
import '../../../core/services/export_service.dart';
import '../../../core/widgets/pdf_preview_screen.dart';

import '../../../core/theme/app_design.dart';

/// Agenda Global - Visão consolidada REATIVA de todos os eventos (PetEventService)
class GlobalAgendaScreen extends StatefulWidget {
  const GlobalAgendaScreen({super.key});

  @override
  State<GlobalAgendaScreen> createState() => _GlobalAgendaScreenState();
}

class _GlobalAgendaScreenState extends State<GlobalAgendaScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  bool _isServiceReady = false;
  bool _showAllEvents =
      false; // Toggle para ver lista completa vs dia selecionado
  String? _selectedPetName; // Novo filtro de Pet

  @override
  void initState() {
    super.initState();
    _initService();
  }

  Future<void> _initService() async {
    debugPrint('🔍 [V104-TRACE] Agenda UI Handshake: Waiting for Service...');

    // 🛡️ [V104] ATOMIC HANDSHAKE
    // We wait for the service to be fully ready (and reconstructed if needed)
    // before allowing the UI to touch the box.
    try {
      await PetEventService.ensureReady();
      await _syncLegacyEvents(); // AUTO-MIGRATE LEGACY DATA

      if (mounted) {
        setState(() => _isServiceReady = true);
        debugPrint(
            '✅ [V104-TRACE] Service Ready. Building GlobalAgendaScreen.');
      }
    } catch (e) {
      debugPrint('❌ [V104-TRACE] Handshake Failed: $e');
      // Retry automatically once after 2 seconds
      Future.delayed(const Duration(seconds: 2), _initService);
    }
  }

  Future<void> _syncLegacyEvents() async {
    try {
      final profileService = PetProfileService();
      await profileService.init();
      final petNames = await profileService.getAllPetNames();
      final eventService = PetEventService();

      int count = 0;
      for (var petName in petNames) {
        final profile = await profileService.getProfile(petName);
        final agendaEvents = profile?['data']?['agendaEvents'] as List? ?? [];

        for (var evMap in agendaEvents) {
          final id = evMap['id'].toString();
          if (!eventService.box.containsKey(id)) {
            final agEvent =
                AgendaEvent.fromJson(Map<String, dynamic>.from(evMap));

            EventType pType = EventType.other;
            if (agEvent.category == EventCategory.vacina) {
              pType = EventType.vaccine;
            } else if (agEvent.category == EventCategory.banho)
              pType = EventType.bath;
            else if (agEvent.category == EventCategory.tosa)
              pType = EventType.grooming;
            else if (agEvent.category == EventCategory.consulta ||
                agEvent.category == EventCategory.saude ||
                agEvent.category == EventCategory.emergencia)
              pType = EventType.veterinary;
            else if (agEvent.category == EventCategory.remedios)
              pType = EventType.medication;

            final pEvent = PetEvent(
              id: agEvent.id,
              petId: petName,
              petName: petName,
              title: agEvent.title,
              type: pType,
              dateTime: agEvent.dateTime,
              notes: agEvent.description,
              createdAt: agEvent.createdAt,
              attendant: agEvent.attendant,
              partnerId: agEvent.partnerId,
            );

            await eventService.addEvent(pEvent);
            count++;
          }
        }
      }
      if (count > 0) {
        debugPrint(
            '✅ MIGRATION: $count eventos legados importados para PetEventService (Hive).');
      }
    } catch (e) {
      debugPrint('⚠️ Migration Warning: $e');
    }
  }

  Color _getCategoryColor(EventType type) {
    switch (type) {
      case EventType.vaccine:
        return AppDesign.info;
      case EventType.bath:
        return AppDesign.success;
      case EventType.grooming:
        return AppDesign.primary;
      case EventType.veterinary:
        return AppDesign.error;
      case EventType.medication:
        return AppDesign.warning;
      case EventType.food:
        return AppDesign.petPink;
      case EventType.elimination:
        return Colors.brown;
      case EventType.activity:
        return Colors.orange;
      case EventType.behavior:
        return Colors.purple;
      case EventType.media:
        return Colors.blueAccent;
      case EventType.metrics:
        return Colors.teal;
      case EventType.documents:
        return Colors.grey;
      case EventType.exams:
        return Colors.indigo;
      case EventType.dentistry:
        return Colors.white70;
      case EventType.parasite:
        return Colors.lightGreen;
      case EventType.surgery:
        return Colors.red;
      case EventType.other:
        return AppDesign.textSecondaryDark;
    }
  }

  List<PetEvent> _getEventsForDay(List<PetEvent> allEvents, DateTime day) {
    return allEvents.where((event) {
      return event.dateTime.year == day.year &&
          event.dateTime.month == day.month &&
          event.dateTime.day == day.day;
    }).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesign.surfaceDark,
      appBar: AppBar(
        backgroundColor: AppDesign.backgroundDark,
        title: Text(
          'Agenda Global',
          style: GoogleFonts.poppins(
              color: AppDesign.textPrimaryDark, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(_showAllEvents ? Icons.calendar_today : Icons.list,
                color: AppDesign.petPink),
            onPressed: () {
              setState(() {
                _showAllEvents = !_showAllEvents;
                if (!_showAllEvents) {
                  _selectedDay = DateTime
                      .now(); // Reset to today when going back to calendar
                }
              });
            },
            tooltip: _showAllEvents ? 'Ver Calendário' : 'Ver Lista Completa',
          ),
          PdfActionButton(onPressed: _showExportOptions),
        ],
      ),
      body: (!_isServiceReady || !PetEventService.isInitialized)
          ? Center(
              child: !_isServiceReady
                  ? const CircularProgressIndicator(color: AppDesign.petPink)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: AppDesign.error),
                        const SizedBox(height: 16),
                        const Text('Erro ao carregar agenda',
                            style:
                                TextStyle(color: AppDesign.textSecondaryDark)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _initService,
                          child: const Text('Tentar Novamente'),
                        )
                      ],
                    ),
            )
          : ValueListenableBuilder<Box<PetEvent>>(
              valueListenable: PetEventService().box.listenable(),
              builder: (context, box, _) {
                final allEvents = box.values.toList();
                allEvents.sort((a, b) => a.dateTime.compareTo(b.dateTime));

                final dayEvents = _showAllEvents
                    ? allEvents
                    : _getEventsForDay(allEvents, _selectedDay);

                final visibleEvents = _selectedPetName == null
                    ? dayEvents
                    : dayEvents
                        .where((e) => e.petName == _selectedPetName)
                        .toList();

                return Column(
                  children: [
                    if (!_showAllEvents)
                      TableCalendar(
                        firstDay:
                            DateTime.now().subtract(const Duration(days: 365)),
                        lastDay: DateTime.now().add(const Duration(days: 365)),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) =>
                            isSameDay(_selectedDay, day),
                        calendarFormat: CalendarFormat.week,
                        availableCalendarFormats: const {
                          CalendarFormat.week: 'Semana',
                          CalendarFormat.month: 'Mês'
                        },
                        eventLoader: (day) => _getEventsForDay(allEvents, day),
                        startingDayOfWeek: StartingDayOfWeek.monday,
                        calendarStyle: const CalendarStyle(
                          outsideDaysVisible: false,
                          defaultTextStyle:
                              TextStyle(color: AppDesign.textPrimaryDark),
                          weekendTextStyle:
                              TextStyle(color: AppDesign.textSecondaryDark),
                          selectedTextStyle: TextStyle(color: Colors.black),
                          selectedDecoration: BoxDecoration(
                            color: AppDesign.petPink,
                            shape: BoxShape.circle,
                          ),
                          todayDecoration: BoxDecoration(
                            color: Colors.white24,
                            shape: BoxShape.circle,
                          ),
                          markerDecoration: BoxDecoration(
                            color: AppDesign.warning,
                            shape: BoxShape.circle,
                          ),
                        ),
                        headerStyle: HeaderStyle(
                          titleTextStyle: GoogleFonts.poppins(
                              color: AppDesign.textPrimaryDark, fontSize: 16),
                          formatButtonTextStyle:
                              const TextStyle(color: AppDesign.petPink),
                          formatButtonDecoration: BoxDecoration(
                            border: Border.all(color: AppDesign.petPink),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          leftChevronIcon: const Icon(Icons.chevron_left,
                              color: AppDesign.textPrimaryDark),
                          rightChevronIcon: const Icon(Icons.chevron_right,
                              color: AppDesign.textPrimaryDark),
                        ),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        calendarBuilders: CalendarBuilders(
                          markerBuilder: (context, day, events) {
                            if (events.isEmpty) return const SizedBox();

                            final count = events.length;
                            final showCount = count > 3 ? 3 : count;

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(showCount, (index) {
                                final isOverflow = index == 2 && count > 3;
                                return Container(
                                  width: 6,
                                  height: 6,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 1.0),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isOverflow
                                        ? Colors.red
                                        : AppDesign.petPink,
                                  ),
                                );
                              }),
                            );
                          },
                        ),
                      ),
                    _buildPetFilter(),
                    const Divider(color: Colors.white12),
                    Expanded(
                      child: visibleEvents.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.event_busy,
                                      size: 64,
                                      color: AppDesign.textSecondaryDark),
                                  const SizedBox(height: 16),
                                  Text(
                                    _showAllEvents
                                        ? 'Nenhum evento registado'
                                        : 'Nenhum evento para este dia',
                                    style: const TextStyle(
                                        color: AppDesign.textSecondaryDark),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: visibleEvents.length,
                              itemBuilder: (context, index) {
                                return _buildEventCard(visibleEvents[index]);
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildPetFilter() {
    return FutureBuilder<List<String>>(
      future: PetProfileService().getAllPetNames(),
      builder: (context, snapshot) {
        final pets = snapshot.data ?? [];
        if (pets.isEmpty) return const SizedBox.shrink();

        return Container(
          height: 40,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: pets.length + 1,
            itemBuilder: (context, index) {
              final isAll = index == 0;
              final petName = isAll ? null : pets[index - 1];
              final isSelected = _selectedPetName == petName;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(isAll ? 'Todos os Animais' : petName!,
                      style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? AppDesign.backgroundDark
                              : AppDesign.textSecondaryDark)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedPetName = selected ? petName : null;
                    });
                  },
                  selectedColor: AppDesign.petPink,
                  backgroundColor: Colors.white10,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  showCheckmark: false,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEventCard(PetEvent event) {
    final color = _getCategoryColor(event.type);

    return Card(
      clipBehavior: Clip.antiAlias,
      color: const Color(0x14FFFFFF),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: color.withValues(alpha: 0.5),
            width: 1), // Dynamic color border
      ),
      child: InkWell(
        onTap: () => _handleCardTap(event),
        splashColor: color.withValues(alpha: 0.2),
        highlightColor: color.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    event.typeEmoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: AppDesign.textPrimaryDark,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat('dd/MM HH:mm').format(event.dateTime),
                          style: TextStyle(
                              color: color,
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    flex: 1,
                    child: GestureDetector(
                      onTap: () => _handlePetNameTap(event),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: color.withValues(alpha: 0.6)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.pets, size: 12, color: color),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                event.petName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (event.notes != null && event.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    event.notes!,
                    style: const TextStyle(
                        color: AppDesign.textSecondaryDark,
                        fontSize: 13,
                        fontStyle: FontStyle.italic),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handlePetNameTap(PetEvent event) async {
    final petService = PetProfileService();
    await petService.init();
    final profileData = await petService.getProfile(event.petName);

    if (profileData != null && mounted) {
      debugPrint(
          'Navegando para o Pet: ${event.petName} | Foto: ${profileData['photo_path']} | Vínculos: ${profileData['data']?['linked_partner_ids']}');

      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => EditPetForm(
                    petData: profileData,
                    onSave: (updated) async {
                      await petService.saveOrUpdateProfile(
                          event.petName, updated.toJson());
                      if (!mounted) return;
                      if (mounted) Navigator.pop(context);
                    },
                    onCancel: () => Navigator.pop(context),
                  )));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Perfil não encontrado: ${event.petName}'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppDesign.error,
        ),
      );
    }
  }

  Future<void> _handleCardTap(PetEvent event) async {
    final profileService = PetProfileService();
    final profile = await profileService.getProfile(event.petName);

    String? partnerId;

    if (profile != null) {
      final data = Map<String, dynamic>.from(profile['data'] as Map);
      final linkedPartners = data['linked_partner_ids'] as List?;

      if (linkedPartners != null && linkedPartners.isNotEmpty) {
        partnerId = linkedPartners.first.toString();
      }
    }

    if (partnerId != null) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PartnerEventDetailScreen(
                  partnerId: partnerId!, event: event)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Nenhum parceiro vinculado.',
            style: TextStyle(
                color: Color(0xFF880E4F), fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFFFFD1DC),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _showExportOptions() async {
    DateTime start = DateTime(DateTime.now().year, DateTime.now().month, 1);
    DateTime end = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
    String? petFilter;
    EventType? categoryFilter;
    String reportType = 'Detalhamento';

    final petNames = await PetProfileService().getAllPetNames();

    if (!mounted) return;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: AppDesign.surfaceDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                  left: 24,
                  right: 24,
                  top: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Exportar Relatório PDF',
                          style: TextStyle(
                              color: AppDesign.textPrimaryDark,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close,
                              color: AppDesign.textSecondaryDark, size: 20)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Date Range - Selection via Pencil icon only
                  const Text('Período do Relatório',
                      style: TextStyle(
                          color: AppDesign.textSecondaryDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${DateFormat('dd/MM/yyyy').format(start)} - ${DateFormat('dd/MM/yyyy').format(end)}',
                          style: const TextStyle(
                              color: AppDesign.petPink,
                              fontWeight: FontWeight.w500),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.edit,
                              color: AppDesign.petPink, size: 18),
                          onPressed: () async {
                            final range = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                              initialDateRange:
                                  DateTimeRange(start: start, end: end),
                              builder: (context, child) => Theme(
                                data: ThemeData.dark().copyWith(
                                  colorScheme: const ColorScheme.dark(
                                    primary: AppDesign.petPink,
                                    onPrimary: Colors.black,
                                    surface: AppDesign.surfaceDark,
                                    onSurface: AppDesign.textPrimaryDark,
                                  ),
                                ),
                                child: child!,
                              ),
                            );
                            if (range != null) {
                              setSheetState(() {
                                start = range.start;
                                end = range.end;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Pet Filter
                  const Text('Filtrar por Pet',
                      style: TextStyle(
                          color: AppDesign.textSecondaryDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        dropdownColor: AppDesign.surfaceDark,
                        value: petFilter,
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(
                              value: null,
                              child: Text('Todos os Animais',
                                  style: TextStyle(
                                      color: AppDesign.textPrimaryDark))),
                          ...petNames.map((name) => DropdownMenuItem(
                              value: name,
                              child: Text(name,
                                  style: const TextStyle(
                                      color: AppDesign.textPrimaryDark)))),
                        ],
                        onChanged: (val) =>
                            setSheetState(() => petFilter = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Category Filter
                  const Text('Filtrar por Categoria',
                      style: TextStyle(
                          color: AppDesign.textSecondaryDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<EventType?>(
                        dropdownColor: AppDesign.surfaceDark,
                        value: categoryFilter,
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(
                              value: null,
                              child: Text('Todas as Categorias',
                                  style: TextStyle(
                                      color: AppDesign.textPrimaryDark))),
                          ...EventType.values.map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(
                                  PetEvent(
                                          id: '',
                                          petId: '',
                                          petName: '',
                                          title: '',
                                          type: type,
                                          dateTime: DateTime.now())
                                      .typeLabel,
                                  style: const TextStyle(
                                      color: AppDesign.textPrimaryDark)))),
                        ],
                        onChanged: (val) =>
                            setSheetState(() => categoryFilter = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Report Type
                  const Text('Nível de Detalhe',
                      style: TextStyle(
                          color: AppDesign.textSecondaryDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppDesign.textPrimaryDark.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: AppDesign.surfaceDark,
                        value: reportType,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                              value: 'Detalhamento',
                              child: Text('Tabela Detalhada',
                                  style: TextStyle(
                                      color: AppDesign.textPrimaryDark))),
                          DropdownMenuItem(
                              value: 'Somente Agendamentos',
                              child: Text('Somente Agendamentos',
                                  style: TextStyle(
                                      color: AppDesign.textPrimaryDark))),
                          DropdownMenuItem(
                              value: 'Resumo',
                              child: Text('Apenas Resumo',
                                  style: TextStyle(
                                      color: AppDesign.textPrimaryDark))),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setSheetState(() => reportType = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppDesign.petPink,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Gerar PDF',
                        style: TextStyle(
                            color: AppDesign.backgroundDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            letterSpacing: 1)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (result == true) {
      final events = PetEventService().box.values.where((e) {
        final inRange =
            (e.dateTime.isAfter(start) || isSameDay(e.dateTime, start)) &&
                (e.dateTime.isBefore(end) || isSameDay(e.dateTime, end));
        final matchesPet = petFilter == null || e.petName == petFilter;
        final matchesCategory =
            categoryFilter == null || e.type == categoryFilter;

        // 🛡️ Filter Logic for "Only Appointments"
        final matchesReportType = (reportType == 'Somente Agendamentos')
            ? !e.id.startsWith('idx_')
            : true;

        return inRange && matchesPet && matchesCategory && matchesReportType;
      }).toList();

      events.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfPreviewScreen(
            title: 'Relatório de Agenda',
            buildPdf: (format) async {
              final pdf = await ExportService().generateAgendaReport(
                  events: events,
                  start: start,
                  end: end,
                  petFilter: petFilter,
                  categoryFilter: categoryFilter?.name,
                  reportType: reportType,
                  strings: AppLocalizations.of(context)!);
              return pdf.save();
            },
          ),
        ),
      );
    }
  }
}
