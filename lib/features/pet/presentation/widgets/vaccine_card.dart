import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/vaccine_status_provider.dart';
import '../../../../core/theme/app_design.dart';

class VaccineCard extends StatelessWidget {
  final Map<String, dynamic> vaccinationProtocol;
  final String petName;
  final VoidCallback? onScheduleVaccine;

  const VaccineCard({super.key, required this.vaccinationProtocol, required this.petName, this.onScheduleVaccine});

  @override
  Widget build(BuildContext context) {
    final vaccines = vaccinationProtocol['vacinas_essenciais'] as List? ?? [];
    final preventiveCalendar = vaccinationProtocol['calendario_preventivo'] as Map<String, dynamic>? ?? {};
    final parasitePrevention = vaccinationProtocol['prevencao_parasitaria'] as Map<String, dynamic>? ?? {};
    final dentalHealth = vaccinationProtocol['saude_bucal_ossea'] as Map<String, dynamic>? ?? {};

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withValues(alpha: 0.1),
            Colors.purple.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.vaccines, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '💉 Protocolo de Imunização',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Caderneta de Vacinação de $petName',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Vaccines List
          if (vaccines.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vacinas Essenciais',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...vaccines.map((vaccine) => _VaccineItem(
                    vaccine: vaccine as Map<String, dynamic>,
                    petName: petName,
                    onSchedule: onScheduleVaccine,
                  )),
                ],
              ),
            ),
          ],

          // Preventive Calendar
          if (preventiveCalendar.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppDesign.petPink.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppDesign.petPink.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, color: AppDesign.petPink, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Calendário Preventivo',
                        style: GoogleFonts.poppins(
                          color: AppDesign.petPink,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (preventiveCalendar['cronograma_filhote'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '🐶 Filhotes: ${preventiveCalendar['cronograma_filhote']}',
                      style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                  if (preventiveCalendar['reforco_anual'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '🔄 Adultos: ${preventiveCalendar['reforco_anual']}',
                      style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Parasite Prevention
          if (parasitePrevention.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bug_report, color: Colors.orangeAccent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Prevenção Parasitária',
                        style: GoogleFonts.poppins(
                          color: Colors.orangeAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (parasitePrevention['vermifugacao'] != null) ...[
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        final vermifugacao = parasitePrevention['vermifugacao'] as Map<String, dynamic>;
                        return Text(
                          '💊 Vermífugo: ${vermifugacao['frequencia'] ?? 'Consulte veterinário'}',
                          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                        );
                      },
                    ),
                  ],
                  if (parasitePrevention['controle_ectoparasitas'] != null) ...[
                    const SizedBox(height: 4),
                    Builder(
                      builder: (context) {
                        final ectoparasitas = parasitePrevention['controle_ectoparasitas'] as Map<String, dynamic>;
                        return Text(
                          '🦟 Pulgas/Carrapatos: ${ectoparasitas['pulgas_carrapatos'] ?? 'Consulte veterinário'}',
                          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                        );
                      },
                    ),
                  ],
                  if (parasitePrevention['alerta_regional'] != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.redAccent, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              parasitePrevention['alerta_regional'],
                              style: GoogleFonts.poppins(
                                color: Colors.redAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Dental Health
          if (dentalHealth.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppDesign.petPink.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppDesign.petPink.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.pets, color: AppDesign.petPink, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Saúde Bucal e Óssea',
                        style: GoogleFonts.poppins(
                          color: AppDesign.petPink,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (dentalHealth['ossos_naturais_permitidos'] != null) ...[
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        final bones = dentalHealth['ossos_naturais_permitidos'] as List;
                        return Text(
                          '🦴 Ossos Permitidos: ${bones.join(", ")}',
                          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                        );
                      },
                    ),
                  ],
                  if (dentalHealth['frequencia_semanal'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '📅 Frequência: ${dentalHealth['frequencia_semanal']}',
                      style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                  if (dentalHealth['alerta_seguranca'] != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.redAccent, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              dentalHealth['alerta_seguranca'],
                              style: GoogleFonts.poppins(
                                color: Colors.redAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}

class _VaccineItem extends ConsumerStatefulWidget {
  final Map<String, dynamic> vaccine;
  final String petName;
  final VoidCallback? onSchedule;

  const _VaccineItem({
    required this.vaccine,
    required this.petName,
    this.onSchedule,
  });

  @override
  ConsumerState<_VaccineItem> createState() => _VaccineItemState();
}

class _VaccineItemState extends ConsumerState<_VaccineItem> {
  bool _isChecked = false;

  @override
  void initState() {
    super.initState();
    // Load status after build to ensure provider is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVaccineStatus();
    });
  }

  Future<void> _loadVaccineStatus() async {
    try {
      if (!mounted) return;
      final name = widget.vaccine['nome'] ?? 'Vacina';
      debugPrint('💉 Loading vaccine status for: $name (Pet: ${widget.petName})');
      final service = ref.read(vaccineStatusServiceProvider);
      debugPrint('✅ Service obtained: $service');
      final isCompleted = service.isCompleted(widget.petName, name);
      debugPrint('📋 Vaccine $name is completed: $isCompleted');
      if (mounted) {
        setState(() {
          _isChecked = isCompleted;
        });
        debugPrint('✅ State updated: _isChecked = $_isChecked');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading vaccine status: $e');
      debugPrint('Stack: $stackTrace');
    }
  }

  Future<void> _toggleVaccine() async {
    try {
      final name = widget.vaccine['nome'] ?? 'Vacina';
      debugPrint('🔄 TOGGLE VACCINE CLICKED: $name (Pet: ${widget.petName})');
      debugPrint('Current state before toggle: $_isChecked');
      
      final service = ref.read(vaccineStatusServiceProvider);
      debugPrint('✅ Service obtained for toggle');
      
      await service.toggleStatus(widget.petName, name);
      debugPrint('✅ Toggle status completed');
      
      if (mounted) {
        setState(() {
          _isChecked = !_isChecked;
        });
        debugPrint('✅ State updated after toggle: $_isChecked');
      }
    } catch (e, stackTrace) {
      debugPrint('❌❌❌ ERROR TOGGLING VACCINE: $e');
      debugPrint('Stack: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.vaccine['nome'] ?? 'Vacina';
    final objective = widget.vaccine['objetivo'] ?? '';
    final puppySchedule = widget.vaccine['periodicidade_filhote'] ?? '';
    final adultBooster = widget.vaccine['reforco_adulto'] ?? '';
    final firstDoseAge = widget.vaccine['idade_primeira_dose'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _isChecked 
            ? AppDesign.petPink.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isChecked 
              ? AppDesign.petPink.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: InkWell(
        onTap: () async {
          debugPrint('👆 InkWell TAPPED!');
          await _toggleVaccine();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox
              Container(
                margin: const EdgeInsets.only(top: 2),
                child: Icon(
                  _isChecked ? Icons.check_circle : Icons.circle_outlined,
                  color: _isChecked ? AppDesign.petPink : Colors.white54,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        decoration: _isChecked ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (objective.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        objective,
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Badges in column to prevent overflow
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (firstDoseAge.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '1ª dose: $firstDoseAge',
                              style: GoogleFonts.poppins(
                                color: Colors.blueAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        if (firstDoseAge.isNotEmpty && adultBooster.isNotEmpty)
                          const SizedBox(height: 4),
                        if (adultBooster.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Reforço: $adultBooster',
                              style: GoogleFonts.poppins(
                                color: Colors.purpleAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (puppySchedule.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '📋 Filhote: $puppySchedule',
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Schedule button
              if (widget.onSchedule != null)
                IconButton(
                  icon: const Icon(Icons.calendar_today, color: Colors.blueAccent, size: 20),
                  onPressed: widget.onSchedule,
                  tooltip: 'Agendar na Agenda',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
