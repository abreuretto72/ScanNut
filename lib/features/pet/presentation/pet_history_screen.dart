import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/services/history_service.dart';
import '../../pet/models/pet_analysis_result.dart';
import '../../pet/models/pet_profile_extended.dart';
import '../../pet/services/pet_profile_service.dart';
import 'widgets/pet_result_card.dart';
import 'widgets/edit_pet_form.dart';
import 'pet_agenda_screen.dart';
import 'widgets/weekly_menu_screen.dart';
import '../../../core/services/file_upload_service.dart';

class PetHistoryScreen extends ConsumerStatefulWidget {
  const PetHistoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PetHistoryScreen> createState() => _PetHistoryScreenState();
}

class _PetHistoryScreenState extends ConsumerState<PetHistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final history = await HistoryService.getHistory();
    // Filter only pet related items
    final petHistory = history.where((item) => 
      item['mode'] == 'Pet'
    ).toList();
    
    // Sort by date desc
    petHistory.sort((a, b) {
      final dateA = DateTime.parse(a['timestamp']);
      final dateB = DateTime.parse(b['timestamp']);
      return dateB.compareTo(dateA);
    });

    if (mounted) {
      setState(() {
        _history = petHistory;
        _isLoading = false;
      });
    }
  }

  void _openResult(Map<String, dynamic> item) {
    try {
      final data = item['data'];
      final analysis = PetAnalysisResult.fromJson(data);
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PetResultCard(
            analysis: analysis,
            imagePath: item['image_path'] ?? '',
            petName: item['pet_name'],
            onSave: () {}, // Already saved
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao abrir: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Meus Pets Salvos',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        // Ícone + removido conforme solicitado
      ),
      body: _history.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.pets, size: 64, color: Colors.white24),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum pet salvo ainda.',
                    style: GoogleFonts.poppins(color: Colors.white54),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final rawItem = _history[index];
                // Cast to proper type
                final item = Map<String, dynamic>.from(rawItem as Map);
                final data = item['data'];
                final date = DateTime.parse(item['timestamp']);
                final petName = item['pet_name'] ?? 'Pet Desconhecido';
                
                // Extract breed/species for subtitle
                String subtitle = 'Carregando...';
                try {
                  if (data['analysis_type'] == 'diagnosis') {
                    subtitle = "${data['breed'] ?? 'N/A'} • Saúde";
                  } else {
                    subtitle = "${data['identificacao']?['raca_predominante'] ?? 'N/A'} • ID";
                  }
                } catch (e) {
                   subtitle = 'Info indisponível';
                }

                return Card(
                  color: Colors.white.withValues(alpha: 0.05),
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: ListTile(
                    onTap: () => _openResult(item),
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.pets, color: Colors.orangeAccent),
                    ),
                    title: Text(
                      petName,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(date),
                          style: GoogleFonts.poppins(color: Colors.white30, fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        // Action buttons row (Agenda & Menu)
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PetAgendaScreen(petName: petName),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.calendar_today, color: Colors.blueAccent, size: 16),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                if (data['plano_semanal'] != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => WeeklyMenuScreen(
                                          currentWeekPlan: (data['plano_semanal'] as List).map((e) => (e as Map).map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''))).toList(),
                                          generalGuidelines: data['orientacoes_gerais'],
                                          petName: petName,
                                          raceName: data['breed'] ?? data['identificacao']?['raca'] ?? 'Raça não informada',
                                        ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Sem cardápio disponível')),
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.restaurant_menu, color: Colors.greenAccent, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Edit Button
                        IconButton(
                          icon: const Icon(Icons.edit, color: Color(0xFF00E676)),
                          tooltip: 'Editar Perfil',
                          onPressed: () {
                             Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditPetForm(
                                  existingProfile: PetProfileExtended(
                                    petName: petName,
                                    raca: data['breed'] ?? data['identificacao']?['raca_predominante'],
                                    nivelAtividade: (data['perfil_comportamental']?['nivel_energia'] is int) 
                                        ? ((data['perfil_comportamental']!['nivel_energia'] as int) > 3 ? 'Ativo' : ((data['perfil_comportamental']!['nivel_energia'] as int) < 3 ? 'Sedentário' : 'Moderado'))
                                        : 'Moderado',
                                    frequenciaBanho: data['higiene']?['banho_e_higiene']?['frequencia']?.toString() ?? 'Quinzenal',
                                    imagePath: data['image_path'],
                                    lastUpdated: DateTime.parse(data['timestamp'] ?? DateTime.now().toIso8601String()),
                                    rawAnalysis: data != null ? Map<String, dynamic>.from(data as Map) : null,
                                  ),
                                  onSave: (profile) async {
                                    final service = PetProfileService();
                                    await service.init();
                                    await service.saveOrUpdateProfile(
                                      profile.petName,
                                      profile.toJson(),
                                    );
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Perfil atualizado!')),
                                    );
                                    _loadHistory();
                                  },
                                  onDelete: () async {
                                    await HistoryService.deletePet(petName);
                                    if (context.mounted) Navigator.pop(context);
                                    _loadHistory();
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

}
