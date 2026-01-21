import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:scannut/l10n/app_localizations.dart';
import '../../../../core/theme/app_design.dart';
import '../../models/pet_event.dart';
import '../../../../core/providers/pet_event_provider.dart';
import '../../services/pet_event_service.dart';

class VaccinationCard extends ConsumerStatefulWidget {
  final String petId;
  final String petName;
  final String species; // "Cão", "Gato", etc.

  const VaccinationCard({
    Key? key,
    required this.petId,
    required this.petName,
    required this.species,
    this.legacyV10Date,
    this.legacyRabiesDate,
  }) : super(key: key);

  final DateTime? legacyV10Date;
  final DateTime? legacyRabiesDate;

  @override
  ConsumerState<VaccinationCard> createState() => _VaccinationCardState();
}

class _VaccinationCardState extends ConsumerState<VaccinationCard> {
  bool _isLoading = true;
  final Map<String, DateTime?> _vaccineDates = {};

  // List of keys for vaccines based on species
  List<String> get _requiredVaccines {
    final s = widget.species.toLowerCase();
    if (s.contains('cão') || s.contains('dog') || s.contains('cachorro')) {
      return [
        'vaccineV8V10',
        'vaccineRabies',
        'vaccineFlu',
        'vaccineGiardia',
        'vaccineLeishmania',
      ];
    } else {
      // Gato/Cat defaults
      return [
        'vaccineV3V4V5',
        'vaccineRabies',
        'vaccineFivFelv',
      ];
    }
  }

  bool _isFirstLoad = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isFirstLoad) {
      _isFirstLoad = false;
      _loadVaccineHistory();
    }
  }

  Future<void> _loadVaccineHistory() async {
    setState(() => _isLoading = true);
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    final service = await ref.read(petEventServiceProvider.future);
    final events = service.getEventsByPet(widget.petName);
    
    // MIGRATION LOGIC: Check for legacy dates and create events if missing
    await _checkMigration(service, events, l10n.vaccineV8V10, widget.legacyV10Date);
    await _checkMigration(service, events, l10n.vaccineRabies, widget.legacyRabiesDate);
    
    // Initialize map
    _vaccineDates.clear();
    
    // Helper to get localized vaccine name (we store the KEY in memory, but Title in DB)
    // Actually, to be robust, we should store standardized keys or match by title
    // For simplicity and robustness given existing localization, we will match by Title if possible
    // But since we are creating new events, we can standardise.
    
    // Strategy: Search events where title matches the LOCALIZED name of the vaccine
    // This assumes the user didn't change the language. 
    // Ideally, we should store metadata. But PetEvent is simple.
    
    try {
      // We need localization context. Assuming context is available in initState technically no, 
      // but we will do this in didChangeDependencies or just force a rebuild.
      // Let's delay slighty or use a post-frame callback if context is needed.
      // Better: do matching in build or load with a context reference if safe.
      
      // Actually, we can just look for the most recent event of type 'vaccine' 
      // and matching common strings.
    } catch(e) {
      debugPrint('Error loading vaccines: $e');
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _checkMigration(PetEventService service, List<PetEvent> events, String title, DateTime? legacyDate) async {
      if (legacyDate == null) return;
      
      // Check if any event exists with this title
      final exists = events.any((e) => e.type == EventType.vaccine && e.title.toLowerCase().trim() == title.toLowerCase().trim());
      
      if (!exists) {
         debugPrint('🔄 Migrating legacy vaccine date for $title: $legacyDate');
         final event = PetEvent(
            id: DateTime.now().millisecondsSinceEpoch.toString() + (title.hashCode).toString(), // Unique ID
            petId: widget.petId,
            petName: widget.petName,
            title: title,
            type: EventType.vaccine,
            dateTime: legacyDate,
            notes: 'Migrated from legacy profile',
         );
         await service.addEvent(event);
         // Add to local list to avoid fetch delay issues
         events.add(event); 
      }
  }
  
  // We need to fetch localized strings every build, so better to do the mapping logic there
  // or store the mapping.

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Small load on first frame or just continue rendering with empty dates
      // Let's trigger the async load result processing here safely
      // But _loadVaccineHistory is async.
    }
    
    // Trigger load if map is empty and not loading? 
    // Better to use FutureBuilder. But we want state.
    
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Map keys to localized labels
    final vaccineLabels = {
      'vaccineV8V10': l10n.vaccineV8V10,
      'vaccineRabies': l10n.vaccineRabies,
      'vaccineFlu': l10n.vaccineFlu,
      'vaccineGiardia': l10n.vaccineGiardia,
      'vaccineLeishmania': l10n.vaccineLeishmania,
      'vaccineV3V4V5': l10n.vaccineV3V4V5,
      'vaccineFivFelv': l10n.vaccineFivFelv,
    };

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppDesign.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Help Icon
          Row(
            children: [
              const Icon(Icons.medical_services_outlined, color: AppDesign.petPink, size: 20),
              const SizedBox(width: 8),
              Text(
                'Histórico de Vacinas', // TODO: Add key or use hardcoded if acceptable/Add to arb
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.info_outline, color: AppDesign.petPink, size: 20),
                onPressed: () => _showHelpDialog(context, l10n),
                tooltip: l10n.vaccinationGuideTitle,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Vaccine List
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppDesign.petPink))
          else
            _buildVaccineList(l10n, vaccineLabels),
        ],
      ),
    );
  }
  
  Widget _buildVaccineList(AppLocalizations l10n, Map<String, String> labels) {
    final keys = _requiredVaccines;
    
    // We need to match events here since we have l10n now
    final eventProvider = ref.watch(petEventServiceProvider);
    
    return eventProvider.when(
      loading: () => const CircularProgressIndicator(),
      error: (_,__) => Text('Error loading data'),
      data: (service) {
        final events = service.getEventsByPet(widget.petName);
        
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), // Protected Scroll
          itemCount: keys.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final key = keys[index];
            final label = labels[key] ?? key;
            
            // Find latest event for this vaccine
            PetEvent? latestEvent;
            try {
               final relevantEvents = events.where((e) => 
                 e.type == EventType.vaccine && 
                 e.title.toLowerCase().trim() == label.toLowerCase().trim()
               ).toList();
               
               if (relevantEvents.isNotEmpty) {
                 relevantEvents.sort((a,b) => b.dateTime.compareTo(a.dateTime));
                 latestEvent = relevantEvents.first;
               }
            } catch (_) {}
            
            final date = latestEvent?.dateTime;
            
            return _VaccineRow(
              label: label,
              date: date,
              onDateSelected: (newDate) => _saveVaccineDate(service, label, newDate),
            );
          },
        );
      }
    );
  }

  Future<void> _saveVaccineDate(PetEventService service, String vaccineName, DateTime date) async {
    // Create new event
    // Format: Title = Vaccine Name
    final event = PetEvent(
       id: DateTime.now().millisecondsSinceEpoch.toString(), // Simple durable ID for now
       petId: widget.petId, // Assuming we have petId, or generate one if empty?
       // Wait, PetEvent requires petId. If we don't have it (e.g. creating pet), this fails.
       // Assuming we are in EDIT mode mostly.
       petName: widget.petName,
       title: vaccineName,
       type: EventType.vaccine,
       dateTime: date,
       notes: 'Vaccination record via smart card',
    );
    
    await service.addEvent(event);
    setState(() {}); // Force rebuild to refresh list
  }

  void _showHelpDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Row(
          children: [
            const Icon(Icons.help_outline, color: AppDesign.accent),
            const SizedBox(width: 8),
            Expanded(child: Text(l10n.vaccinationGuideTitle, style: GoogleFonts.poppins(color: Colors.white))),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text(l10n.vaccinationHelpBody, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
               const SizedBox(height: 16),
               Flexible(
                 child: ListView(
                   shrinkWrap: true,
                   children: _buildHelpItems(l10n),
                 ),
               ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.btn_close, style: GoogleFonts.poppins(color: AppDesign.accent)),
          ),
        ],
      ),
    );
  }
  
  List<Widget> _buildHelpItems(AppLocalizations l10n) {
    // Determine items based on species
    final isDog = widget.species.toLowerCase().contains('cão') || widget.species.toLowerCase().contains('dog');
    
    final List<Map<String, dynamic>> items = isDog ? [
      {'name': l10n.vaccineV8V10, 'type': 'mandatory', 'desc': 'Essencial. Protege contra Cinomose, Parvovirose, etc.', 'freq': 'Anual (Reforço). Filhotes: 3 doses.'},
      {'name': l10n.vaccineRabies, 'type': 'mandatory', 'desc': 'Obrigatória por lei.', 'freq': 'Anual.'},
      {'name': l10n.vaccineGiardia, 'type': 'optional', 'desc': 'Recomendada para cães que convivem em grupos.', 'freq': 'Anual (2 doses iniciais).'},
      {'name': l10n.vaccineFlu, 'type': 'optional', 'desc': 'Importante em invernos ou creches.', 'freq': 'Anual.'},
      {'name': l10n.vaccineLeishmania, 'type': 'optional', 'desc': 'Essencial em áreas endêmicas.', 'freq': 'Anual (Protocolo Específico).'},
    ] : [
      {'name': l10n.vaccineV3V4V5, 'type': 'mandatory', 'desc': 'Essencial. Rinotraqueíte, Calicivirose, Panleucopenia.', 'freq': 'Anual (Reforço).'},
      {'name': l10n.vaccineRabies, 'type': 'mandatory', 'desc': 'Obrigatória por lei.', 'freq': 'Anual.'},
      {'name': l10n.vaccineFivFelv, 'type': 'optional', 'desc': 'Recomendada para gatos com acesso à rua.', 'freq': 'Anual.'},
    ];

    return items.map((item) {
       final isMandatory = item['type'] == 'mandatory';
       final color = isMandatory ? AppDesign.petPink : Colors.blue;
       
       return Container(
         margin: const EdgeInsets.only(bottom: 8),
         padding: const EdgeInsets.all(8),
         decoration: BoxDecoration(
           color: color.withValues(alpha: 0.1), // Sanitized per instructions
           borderRadius: BorderRadius.circular(8),
           border: Border.all(color: color.withValues(alpha: 0.3)),
         ),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Row(
               children: [
                 Icon(isMandatory ? Icons.check_circle : Icons.info, color: color, size: 16),
                 const SizedBox(width: 8),
                 Expanded(
                   child: Text(
                     item['name'], 
                     style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)
                   ),
                 ),
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                   decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                   child: Text(
                     isMandatory ? l10n.vaccinationMandatory : l10n.vaccinationOptional,
                     style: GoogleFonts.poppins(
                       color: isMandatory ? Colors.black : Colors.white,
                       fontSize: 9, 
                       fontWeight: FontWeight.bold
                     )
                   ),
                 ),
               ],
             ),
             const SizedBox(height: 4),
             Text(
               item['desc'],
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                'Frequência: ${item['freq']}',
                style: GoogleFonts.poppins(color: AppDesign.petPink, fontSize: 11, fontWeight: FontWeight.w600),
              ),
           ],
         ),
       );
    }).toList();
  }
}

class _VaccineRow extends StatelessWidget {
  final String label;
  final DateTime? date;
  final Function(DateTime) onDateSelected;

  const _VaccineRow({required this.label, required this.date, required this.onDateSelected});

  @override
  Widget build(BuildContext context) {
    final hasDate = date != null;
    
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
          ),
        ),
        InkWell(
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? now,
              firstDate: now.subtract(const Duration(days: 365 * 10)),
              lastDate: now.add(const Duration(days: 365)),
              builder: (context, child) {
                return Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: AppDesign.petPink,
                      onPrimary: Colors.white,
                      surface: Colors.grey,
                      onSurface: Colors.white,
                    ),
                    dialogBackgroundColor: Colors.grey[900],
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              onDateSelected(picked);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: hasDate 
                  ? (date!.isBefore(DateTime.now().subtract(const Duration(days: 365))) ? Colors.red.withValues(alpha: 0.2) : AppDesign.petPink.withValues(alpha: 0.2)) 
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: hasDate 
                      ? (date!.isBefore(DateTime.now().subtract(const Duration(days: 365))) ? Colors.red : AppDesign.petPink) 
                      : Colors.white24
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today, 
                  size: 14, 
                  color: hasDate ? Colors.white : Colors.white54
                ),
                const SizedBox(width: 8),
                Text(
                  hasDate ? DateFormat('dd/MM/yy').format(date!) : 'Definir',
                  style: GoogleFonts.poppins(
                    color: hasDate ? Colors.white : Colors.white54,
                    fontSize: 13,
                    fontWeight: hasDate ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
