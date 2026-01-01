import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/services/history_service.dart';
import '../../pet/models/pet_profile_extended.dart';
import '../../pet/services/pet_profile_service.dart';
import 'widgets/edit_pet_form.dart';
import '../../partners/presentation/partner_agenda_screen.dart';
import 'widgets/weekly_menu_screen.dart';
import '../../../core/services/meal_history_service.dart';
import '../../../core/services/file_upload_service.dart';
import '../../../core/services/partner_service.dart';
import '../../../core/models/partner_model.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../pet/services/pet_event_service.dart';
import '../../pet/models/pet_event.dart';
import '../../partners/models/agenda_event.dart';
import '../../../l10n/app_localizations.dart';

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
             if (profileData != null && profileData['data'] != null) {
                 final linkedIds = (profileData['data']['linked_partner_ids'] ?? []) as List;
                 if (linkedIds.isNotEmpty) {
                     final partnerId = linkedIds.first; // Primary Vet
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


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.petHistoryTitle,
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: _history.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.pets, size: 64, color: Colors.white24),
                  const SizedBox(height: 16),
                  Text(
                    l10n.petHistoryEmpty,
                    style: GoogleFonts.poppins(color: Colors.white54),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadHistory,
              color: const Color(0xFF00E676),
              backgroundColor: Colors.grey[900],
              child: ListView.builder(
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
                    subtitle = "${data['breed'] ?? l10n.petBreed} • Saúde";
                  } else {
                    subtitle = "${data['identificacao']?['raca_predominante'] ?? l10n.petBreed} • ID";
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
                    // onTap removed - card is now static, only icons are interactive
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm', Localizations.localeOf(context).toString()).format(date),
                          style: GoogleFonts.poppins(color: Colors.white30, fontSize: 12),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Action buttons row (Agenda & Menu & Edit)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // 1. AGENDA
                              InkWell(
                                onTap: () async {
                                  final partner = _petVets[petName];
                                  if (partner != null) {
                                    final service = PetProfileService();
                                    await service.init();
                                    final profileData = await service.getProfile(petName);
                                    
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
                                              if (profileData != null) {
                                                final data = Map<String, dynamic>.from(profileData['data'] as Map);
                                                data['agendaEvents'] = events;
                                                await service.saveOrUpdateProfile(petName, data);
                                                
                                                try {
                                                    final eventService = PetEventService();
                                                    await eventService.init();
                                                    for (var eMap in events) {
                                                        final agEvent = AgendaEvent.fromJson(eMap);
                                                        EventType pType = EventType.other;
                                                        if (agEvent.category == EventCategory.vacina) pType = EventType.vaccine;
                                                        else if (agEvent.category == EventCategory.banho) pType = EventType.bath;
                                                        else if (agEvent.category == EventCategory.tosa) pType = EventType.grooming;
                                                        else if (agEvent.category == EventCategory.consulta || 
                                                                 agEvent.category == EventCategory.emergencia || 
                                                                 agEvent.category == EventCategory.saude || 
                                                                 agEvent.category == EventCategory.exame || 
                                                                 agEvent.category == EventCategory.cirurgia) pType = EventType.veterinary;
                                                        else if (agEvent.category == EventCategory.remedios) pType = EventType.medication;
                                                        
                                                        final pEvent = PetEvent(
                                                            id: agEvent.id,
                                                            petName: petName,
                                                            title: agEvent.title,
                                                            type: pType,
                                                            dateTime: agEvent.dateTime,
                                                            notes: agEvent.description,
                                                            createdAt: agEvent.createdAt,
                                                            completed: false
                                                        );
                                                        await eventService.addEvent(pEvent);
                                                    }
                                                } catch (e) {
                                                    debugPrint('Erros bridging events: $e');
                                                }
                                              }
                                            },
                                            petId: petName,
                                          ),
                                        ),
                                      );
                                    }
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(l10n.petLinkPartnerError),
                                          backgroundColor: Colors.orange,
                                          duration: const Duration(seconds: 3),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                                  ),
                                  child: const Icon(Icons.calendar_today, color: Colors.blueAccent, size: 18),
                                ),
                              ),
                              
                              const SizedBox(width: 24),

                              // 2. MENU
                              InkWell(
                                onTap: () async {
                                  final service = PetProfileService();
                                  await service.init();
                                  final profile = await service.getProfile(petName.trim());
                                  
                                  List<dynamic> rawPlan = [];
                                  String? guidelines;
                                  
                                  if (profile != null && profile['data'] != null) {
                                      final pData = profile['data'];
                                      if (pData['plano_semanal'] != null) {
                                          rawPlan = pData['plano_semanal'];
                                          guidelines = pData['orientacoes_gerais'];
                                      }
                                  }
                                  
                                  if (rawPlan.isEmpty && data['plano_semanal'] != null) {
                                      rawPlan = data['plano_semanal'];
                                      guidelines = data['orientacoes_gerais'] ?? guidelines;
                                  }

                                    if (rawPlan.isNotEmpty) {
                                      final List<Map<String, dynamic>> formattedPlan = rawPlan.map((e) {
                                          return Map<String, dynamic>.from(e as Map);
                                      }).toList();

                                    if (context.mounted) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => WeeklyMenuScreen(
                                                currentWeekPlan: formattedPlan,
                                                generalGuidelines: guidelines,
                                                petName: petName,
                                                raceName: data['breed'] ?? data['identificacao']?['raca'] ?? 'Raça não informada',
                                              ),
                                          ),
                                        );
                                    }
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(l10n.petNoRecentMenu)),
                                      );
                                    }
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                                  ),
                                  child: const Icon(Icons.restaurant_menu, color: Colors.greenAccent, size: 18),
                                ),
                              ),

                              const SizedBox(width: 24),

                              // 3. EDIT
                              InkWell(
                                onTap: () async {
                                   PetProfileExtended? loaded;
                                   try {
                                     final profileService = PetProfileService();
                                     await profileService.init();
                                     final existingMap = await profileService.getProfile(petName.trim());
                                     if (existingMap != null && existingMap['data'] != null) {
                                        // Deep convert to ensure all nested maps are Map<String, dynamic>
                                        final dataMap = _deepConvertMap(existingMap['data']);
                                        loaded = PetProfileExtended.fromJson(dataMap);
                                     }
                                   } catch (e) {
                                     debugPrint('Error loading full profile: $e');
                                     if (context.mounted) {
                                       ScaffoldMessenger.of(context).showSnackBar(
                                         SnackBar(
                                           content: Text('Erro ao abrir: $e'),
                                           backgroundColor: Colors.red,
                                         ),
                                       );
                                     }
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
                                          
                                          await service.saveOrUpdateProfile(newName, profile.toJson());
                                          
                                          final analysisData = profile.rawAnalysis ?? {};
                                          if (profile.raca != null) {
                                            if (analysisData['identificacao'] == null) analysisData['identificacao'] = {};
                                            analysisData['identificacao']['raca_predominante'] = profile.raca;
                                            analysisData['breed'] = profile.raca;
                                          }
                                          
                                          if (oldName != newName) {
                                              await HistoryService.deletePet(oldName);
                                              await service.deleteProfile(oldName);
                                          }
                                          
                                          await HistoryService().savePetAnalysis(
                                            newName,
                                            analysisData,
                                            imagePath: profile.imagePath
                                          );
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

                                  if (result != null && result is Map && result['action'] == 'save') {
                                      _loadHistory();
                                      if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.petEditSaved)));
                                      }
                                  } else {
                                      _loadHistory();
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                  ),
                                  child: const Icon(Icons.edit, color: Colors.white, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ), 
    );
  }

  /// Helper function to deep convert all nested maps to Map<String, dynamic>
  static Map<String, dynamic> _deepConvertMap(dynamic data) {
    if (data is Map) {
      return data.map((key, value) {
        if (value is Map) {
          return MapEntry(key.toString(), _deepConvertMap(value));
        } else if (value is List) {
          return MapEntry(key.toString(), value.map((item) {
            if (item is Map) {
              return _deepConvertMap(item);
            }
            return item;
          }).toList());
        }
        return MapEntry(key.toString(), value);
      });
    }
    return {};
  }
}
