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
import '../../partners/presentation/partner_agenda_screen.dart';
import 'widgets/weekly_menu_screen.dart';
import '../../../core/services/meal_history_service.dart';
import '../../../core/services/file_upload_service.dart';
import '../../../core/services/partner_service.dart';
import '../../../core/models/partner_model.dart';
import 'package:url_launcher/url_launcher.dart';

class PetHistoryScreen extends ConsumerStatefulWidget {
  const PetHistoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PetHistoryScreen> createState() => _PetHistoryScreenState();
}

class _PetHistoryScreenState extends ConsumerState<PetHistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  Map<String, PartnerModel?> _petVets = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    // Init services for Vet lookup
    final partnerService = PartnerService();
    await partnerService.init();
    final profileService = PetProfileService();
    await profileService.init();

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

    // Load Linked Vets
    final vetMap = <String, PartnerModel?>{};
    for (var item in petHistory) {
         final petName = item['pet_name'] as String? ?? '';
         if (petName.isNotEmpty) {
             final profileData = await profileService.getProfile(petName);
             if (profileData != null && profileData['linkedPartnerIds'] != null) {
                 final ids = profileData['linkedPartnerIds'] as List;
                 if (ids.isNotEmpty) {
                     final partnerId = ids.first; // Primary Vet
                     final partner = partnerService.getPartner(partnerId);
                     vetMap[petName] = partner;
                 }
             }
         }
    }

    if (mounted) {
      setState(() {
        _history = petHistory;
        _petVets = vetMap;
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
                        
                        // Vet do Pet Display
                        if (_petVets[petName] != null) ...[
                            const SizedBox(height: 8),
                            InkWell(
                                onTap: () async {
                                    final p = _petVets[petName]!;
                                    final uri = Uri(scheme: 'tel', path: p.phone);
                                    if (await canLaunchUrl(uri)) launchUrl(uri);
                                },
                                child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: const Color(0xFF00E676).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFF00E676).withOpacity(0.3))
                                    ),
                                    child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                            const Icon(Icons.medical_services, color: Color(0xFF00E676), size: 12),
                                            const SizedBox(width: 6),
                                            Text(
                                                'Vet: ${_petVets[petName]!.name}',
                                                style: const TextStyle(color: Color(0xFF00E676), fontSize: 11, fontWeight: FontWeight.bold)
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(Icons.call, color: Color(0xFF00E676), size: 10)
                                        ],
                                    ),
                                ),
                            )
                        ],

                        const SizedBox(height: 12),
                        // Action buttons row (Agenda & Menu)
                        Row(
                          children: [
                            InkWell(
                              onTap: () async {
                                // AGENDA ÚNICA - Filtrada por Pet
                                final partner = _petVets[petName];
                                
                                if (partner != null) {
                                  // Navegar para Agenda Única com filtro de pet
                                  final service = PetProfileService();
                                  await service.init();
                                  final profileData = await service.getProfile(petName);
                                  
                                  // Extrair eventos da agenda (se existirem)
                                  final agendaEvents = profileData?['data']?['agendaEvents'] as List? ?? [];
                                  final eventsList = agendaEvents.map((e) => Map<String, dynamic>.from(e as Map)).toList();
                                  
                                  if (context.mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PartnerAgendaScreen(
                                          partner: partner,
                                          initialEvents: eventsList,
                                          onSave: (events) async {
                                            // Salvar eventos na agenda do pet
                                            if (profileData != null) {
                                              final data = Map<String, dynamic>.from(profileData['data'] as Map);
                                              data['agendaEvents'] = events;
                                              await service.saveOrUpdateProfile(petName, data);
                                            }
                                          },
                                          petId: petName, // Filtro automático por pet
                                        ),
                                      ),
                                    );
                                  }
                                } else {
                                  // Sem parceiro vinculado
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Vincule um parceiro na aba "Parc." para acessar a agenda'),
                                        backgroundColor: Colors.orange,
                                        duration: const Duration(seconds: 4),
                                        action: SnackBarAction(
                                          label: 'OK',
                                          textColor: Colors.white,
                                          onPressed: () {},
                                        ),
                                      ),
                                    );
                                  }
                                }
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
                          onPressed: () async {
                             PetProfileExtended? loaded;
                             try {
                               final profileService = PetProfileService();
                               await profileService.init();
                               final existingMap = await profileService.getProfile(petName.trim());
                               if (existingMap != null && existingMap['data'] != null) {
                                  loaded = PetProfileExtended.fromJson(Map<String,dynamic>.from(existingMap['data']));
                               }
                             } catch (e) {
                               debugPrint('Error loading full profile: $e');
                             }

                             if (!context.mounted) return;

                             final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditPetForm(
                                  existingProfile: loaded ?? PetProfileExtended(
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
                                    
                                    final oldName = petName;
                                    final newName = profile.petName;
                                    
                                    // 1. Save Profile (Canonical Data)
                                    await service.saveOrUpdateProfile(
                                      newName,
                                      profile.toJson(),
                                    );
                                    
                                    // 2. Sync with History (Display Data)
                                    // Update raw analysis with edited fields for consistency
                                    final analysisData = profile.rawAnalysis ?? {};
                                    if (profile.raca != null) {
                                      if (analysisData['identificacao'] == null) analysisData['identificacao'] = {};
                                      analysisData['identificacao']['raca_predominante'] = profile.raca;
                                      analysisData['breed'] = profile.raca;
                                    }
                                    
                                    // If name changed, delete old entries
                                    if (oldName != newName) {
                                        await HistoryService.deletePet(oldName);
                                        await service.deleteProfile(oldName);
                                    }
                                    
                                    // Re-save to History to update list view
                                    await HistoryService().savePetAnalysis(
                                      newName,
                                      analysisData,
                                      imagePath: profile.imagePath
                                    );

                                    // DO NOT POP HERE - Handled by WillPop in EditPetForm
                                    // Just update history locally
                                  },
                                  onDelete: () async {
                                    await HistoryService.deletePet(petName);
                                    final service = PetProfileService(); 
                                    await service.init();
                                    await service.deleteProfile(petName);
                                    
                                    if (context.mounted) Navigator.pop(context);
                                    _loadHistory();
                                  },
                                ),
                              ),
                            );

                            // Handle Undo Result
                            if (result != null && result is Map && result['action'] == 'save') {
                                _loadHistory(); // Refresh with new data
                                if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: const Text('Alterações no perfil salvas.'),
                                            duration: const Duration(seconds: 8), // Máximo 10s conforme solicitado
                                            backgroundColor: const Color(0xFF00E676),
                                            behavior: SnackBarBehavior.floating, // Permite dismiss por swipe
                                            margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16), // Acima do rodapé
                                            action: SnackBarAction(
                                                label: 'DESFAZER',
                                                textColor: Colors.black,
                                                onPressed: () async {
                                                    final backup = result['backup'] as PetProfileExtended?;
                                                    if (backup != null) {
                                                        final service = PetProfileService();
                                                        await service.init();
                                                        // Restore Backup
                                                        await service.saveOrUpdateProfile(backup.petName, backup.toJson());
                                                        
                                                        // Restore History (simplified)
                                                        // Note: We are restoring based on the backup content.
                                                        // If name changed, this might be tricky, but backup has original name.
                                                        final originalName = backup.petName;
                                                        // If name was changed during edit, we need to delete the NEW name
                                                        // But result['petName'] has the new name
                                                        final newName = result['petName'];
                                                        if (newName != null && newName != originalName) {
                                                            await service.deleteProfile(newName);
                                                            await HistoryService.deletePet(newName);
                                                        }

                                                        // Restore History entry
                                                        await HistoryService().savePetAnalysis(
                                                            originalName,
                                                            backup.rawAnalysis ?? {},
                                                            imagePath: backup.imagePath
                                                        );

                                                        if (context.mounted) {
                                                            _loadHistory();
                                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alterações revertidas com sucesso.')));
                                                        }
                                                    }
                                                }
                                            ),
                                        )
                                    );
                                }
                            } else {
                                _loadHistory();
                            }

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
