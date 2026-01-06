import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/services/history_service.dart';
import '../../pet/models/pet_profile_extended.dart';
import '../../../core/utils/json_cast.dart';

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
import '../../../core/theme/app_design.dart';
import 'widgets/pet_menu_filter_dialog.dart';
import '../../pet/services/pet_menu_generator_service.dart';
import 'widgets/event_action_bar.dart';
import 'pet_event_history_screen.dart';


class PetHistoryScreen extends ConsumerStatefulWidget {
  const PetHistoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PetHistoryScreen> createState() => _PetHistoryScreenState();
}

class _PetHistoryScreenState extends ConsumerState<PetHistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  Map<String, PartnerModel?> _petVets = {};
  bool _isLoading = true;
  Directory? _appDocsDir;

  @override
  void initState() {
    super.initState();
    // Pre-load docs dir for image recovery
    getApplicationDocumentsDirectory().then((dir) {
        if (mounted) setState(() => _appDocsDir = dir);
    });

    // 🛡️ Delay mínimo para garantir que o contexto esteja pronto
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _loadHistory();
      }
    });
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
    // Show loading indicator protecting Hive access
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppDesign.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppDesign.backgroundDark,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppDesign.textPrimaryDark),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator(color: AppDesign.accent)),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: AppDesign.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppDesign.backgroundDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppDesign.textPrimaryDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.petHistoryTitle,
          style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark, fontWeight: FontWeight.w600),
        ),
      ),
      body: ValueListenableBuilder<Box>(
        valueListenable: Hive.box(HistoryService.boxName).listenable(),
        builder: (context, box, _) {
          // Real-time filtering and sorting
          final allItems = box.values.toList();
          final petHistory = allItems.where((item) {
             if (item is! Map) return false;
             return item['mode'] == 'Pet';
          }).map((e) => deepCastMap(e)).toList();


          petHistory.sort((a, b) {
            final dateA = DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime(2000);
            final dateB = DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime(2000);
            return dateB.compareTo(dateA);
          });
          
          if (petHistory.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.pets, size: 64, color: AppDesign.textSecondaryDark),
                  const SizedBox(height: 16),
                  Text(
                    l10n.petHistoryEmpty,
                    style: GoogleFonts.poppins(color: AppDesign.textSecondaryDark),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
              onRefresh: _loadHistory,
              color: AppDesign.accent,
              backgroundColor: AppDesign.surfaceDark,
              child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: petHistory.length,
              itemBuilder: (context, index) {
                final item = petHistory[index];
                final data = item['data'] ?? {};
                final date = DateTime.tryParse(item['timestamp'] ?? '') ?? DateTime.now();
                final petName = item['pet_name'] ?? l10n.petUnknown;
                
                // Extract breed/species for subtitle
                // 🛡️ SAFE SUBTITLE with Zero N/A Policy
                String subtitle;
                try {
                  String rawBreed = '';
                  if (data['analysis_type'] == 'diagnosis') {
                    rawBreed = data['breed']?.toString() ?? '';
                  } else {
                    // Robust Deep Search for Breed
                    rawBreed = data['identificacao']?['raca_predominante']?.toString() ?? 
                               data['identificacao']?['raca']?.toString() ?? 
                               data['identificacao']?['breed']?.toString() ?? // Fix: English Object Key
                               data['identification']?['breed']?.toString() ?? // Fix: English Root Key
                               data['breed']?.toString() ?? // Fix: Root Key
                               '';
                  }

                  // 1. Limpeza e Validação
                  String displayBreed = rawBreed.trim();
                  if (displayBreed.isEmpty || 
                      displayBreed.toUpperCase() == 'N/A' || 
                      displayBreed.toUpperCase() == 'NULL' ||
                      displayBreed == 'Raça não identificada' ||
                      displayBreed.contains('unknown') ||
                      displayBreed == 'Unknown Breed') {
                      displayBreed = l10n.petBreedUnknown;  
                  }

                  // 2. Tradução de SRD (Adapter para I18N de dados)
                  if (displayBreed.toUpperCase() == 'SRD' || 
                      displayBreed.toUpperCase() == 'MISTIÇO' ||
                      displayBreed == 'Sem Raça Definida (SRD)') {
                      displayBreed = l10n.petSRD;
                  }

                  // 3. Sufixo de Tipo
                  String typeSuffix = (data['analysis_type'] == 'diagnosis') ? 'Saúde' : 'ID';
                  
                  subtitle = "$displayBreed • $typeSuffix";
                } catch (e) {
                   subtitle = l10n.petBreedUnknown;
                }

                return Card(
                  color: AppDesign.textPrimaryDark.withValues(alpha: 0.05),
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: AppDesign.textPrimaryDark.withValues(alpha: 0.1)),
                  ),
                  child: Stack(
                    children: [
                      ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: _buildPetAvatar(item),
                    title: Text(
                      petName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: AppDesign.textPrimaryDark,
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
                          style: GoogleFonts.poppins(color: AppDesign.textSecondaryDark, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm', Localizations.localeOf(context).toString()).format(date),
                          style: GoogleFonts.poppins(color: AppDesign.textSecondaryDark.withOpacity(0.5), fontSize: 12),
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
                                  // 🛡️ FRESH DATA FETCH: Garantir dados atualizados do Hive
                                  final profileService = PetProfileService();
                                  await profileService.init();
                                  final freshProfile = await profileService.getProfile(petName);

                                  PartnerModel? freshPartner;
                                  if (freshProfile != null && freshProfile['data'] != null) {
                                      final linked = freshProfile['data']['linked_partner_ids'] as List?;
                                      if (linked != null && linked.isNotEmpty) {
                                          final pService = PartnerService();
                                          await pService.init();
                                          freshPartner = pService.getPartner(linked.first);
                                      }
                                  }

                                  if (freshPartner != null) {
                                    final agendaEvents = freshProfile?['data']?['agendaEvents'] as List? ?? [];
                                    final eventsList = deepCastMapList(agendaEvents);

                                    
                                    if (context.mounted) {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PartnerAgendaScreen(
                                            partner: freshPartner!,
                                            initialEvents: eventsList,
                                            onSave: (events) async {
                                              if (freshProfile != null) {
                                                final data = Map<String, dynamic>.from(freshProfile['data'] as Map);
                                                data['agendaEvents'] = events;
                                                await profileService.saveOrUpdateProfile(petName, data);
                                                
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
                                      if (mounted) _loadHistory(); // Refresh on return
                                    }
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(l10n.petLinkPartnerError),
                                          backgroundColor: AppDesign.warning,
                                          duration: const Duration(seconds: 3),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppDesign.info.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppDesign.info.withValues(alpha: 0.3)),
                                  ),
                                  child: const Icon(Icons.calendar_today, color: AppDesign.info, size: 18),
                                ),
                              ),
                              
                              const SizedBox(width: 24),

                              // 2. MENU
                              InkWell(
                                onTap: () async {
                                  // 1. Show Filter Dialog
                                  final config = await showDialog<Map<String, dynamic>>(
                                    context: context,
                                    builder: (context) => const PetMenuFilterDialog(),
                                  );

                                  if (config == null || !mounted) return;

                                  // 2. Show Progress
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppDesign.petPink)),
                                  );

                                  try {
                                      final service = PetProfileService();
                                      await service.init();
                                      final profile = await service.getProfile(petName.trim());
                                      
                                      // 3. Generate
                                      await ref.read(petMenuGeneratorProvider).generateAndSave(
                                          petId: petName.trim(),
                                          profileData: profile?['data'] ?? {},
                                          mode: config['mode'],
                                          startDate: config['startDate'],
                                          endDate: config['endDate'],
                                          locale: Localizations.localeOf(context).toString(),
                                          dietType: config['dietType'] as String,
                                          otherNote: config['otherNote'] as String?,
                                      );


                                      if (mounted) {
                                          Navigator.pop(context); // Close loading
                                          ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text(l10n.petMenuSuccess), backgroundColor: AppDesign.success)
                                          );
                                          // Force reload history to potentially show updates if we tracked menu gen there
                                          _loadHistory();
                                      }
                                  } catch (e) {
                                      if (mounted) {
                                          Navigator.pop(context); // Close loading
                                          ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Erro: $e'), backgroundColor: AppDesign.error)
                                          );
                                      }
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppDesign.success.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppDesign.success.withValues(alpha: 0.3)),
                                  ),
                                  child: const Icon(Icons.restaurant_menu, color: AppDesign.success, size: 18),
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
                                        final dataMap = deepCastMap(existingMap['data']);
                                        loaded = PetProfileExtended.fromJson(dataMap);
                                     }

                                   } catch (e) {
                                     debugPrint('Error loading full profile: $e');
                                     if (context.mounted) {
                                       ScaffoldMessenger.of(context).showSnackBar(
                                         SnackBar(
                                           content: Text('Erro ao abrir: $e'),
                                           backgroundColor: AppDesign.error,
                                         ),
                                       );
                                     }
                                   }

                                   if (!context.mounted) return;

                                   await Navigator.push(
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
                                          rawAnalysis: data != null ? deepCastMap(data) : null,

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
                                          await _confirmDelete(context, petName);
                                        },
                                      ),
                                    ),
                                  );
                                  if (mounted) _loadHistory(); // Refresh
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppDesign.textPrimaryDark.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppDesign.textPrimaryDark.withValues(alpha: 0.2)),
                                  ),
                                  child: const Icon(Icons.edit, color: AppDesign.textPrimaryDark, size: 18),
                                ),
                              ),

                              const SizedBox(width: 24),

                              // 4. TIMELINE
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PetEventHistoryScreen(
                                        petId: petName,
                                        petName: petName,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppDesign.petPink.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppDesign.petPink.withOpacity(0.3)),
                                  ),
                                  child: const Icon(Icons.history_edu, color: AppDesign.petPink, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // --- PET EVENTS ACTION BAR ---
                        EventActionBar(petId: petName),
                        
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppDesign.textPrimaryDark),
                      onPressed: () => _confirmDelete(context, petName),
                    ),
                  ),
                ],
              ),
            );
         },
      ),
      );
    },
  ),
);
}

  
  /// 🛡️ Builds pet avatar with photo or fallback (PADRÃO OBRIGATÓRIO)
  Widget _buildPetAvatar(Map<String, dynamic> item) {
    String? imagePath = item['image_path'] as String?;
    
    // Fallback: Check inside data payload
    if (imagePath == null && item['data'] != null && item['data'] is Map) {
        imagePath = item['data']['image_path']?.toString();
    }

    final l10n = AppLocalizations.of(context)!;
    final petName = item['pet_name'] as String? ?? l10n.petUnknown;
    
    // 🛡️ Verificar se imagem existe e é válida
    bool hasValidImage = imagePath != null &&
                          imagePath.isNotEmpty &&
                          File(imagePath).existsSync();
    
    // 🚑 RECOVERY STRATEGY: Global Search for file in Documents
    if (!hasValidImage && imagePath != null && _appDocsDir != null) {
        try {
            final filename = path.basename(imagePath);
            
            // 🔍 SEARCH 1: Root of Documents (Common for Analysis photos)
            var rPath = path.join(_appDocsDir!.path, filename);
            var rFile = File(rPath);
            
            // 🔍 SEARCH 2: medical_docs/$petName/ (Common for Profile photos)
            if (!rFile.existsSync()) {
                rPath = path.join(_appDocsDir!.path, 'medical_docs', petName, filename);
                rFile = File(rPath);
            }

            if (rFile.existsSync()) {
                debugPrint('🚑 Rescued image for $petName at: $rPath');
                imagePath = rPath;
                hasValidImage = true;
            }
        } catch (e) {
            debugPrint('Error recovering history image: $e');
        }
    }
    
    if (hasValidImage) {
      debugPrint('   ✅ Valid image found');
    } else {
      debugPrint('   ℹ️ No valid image - using fallback');
    }
    
    // 🎨 Obter iniciais do nome para placeholder
    String getInitials(String name) {
      final words = name.trim().split(' ');
      if (words.isEmpty) return '?';
      if (words.length == 1) return words[0][0].toUpperCase();
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    
    // ✅ PADRÃO OBRIGATÓRIO: CircleAvatar com proteções
    return CircleAvatar(
      radius: 28,
      backgroundColor: AppDesign.warning.withValues(alpha: 0.2),
      // 🛡️ backgroundImage APENAS se imagem válida
      backgroundImage: hasValidImage
          ? FileImage(File(imagePath!))
          : null,
      // 🛡️ onBackgroundImageError para proteção extra
      onBackgroundImageError: hasValidImage
          ? (exception, stackTrace) {
              debugPrint('   ❌ Error loading image: $exception');
            }
          : null,
      // 🎨 child APENAS se não houver imagem (fallback)
      child: !hasValidImage
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pets, color: AppDesign.warning, size: 24),
                const SizedBox(height: 2),
                Text(
                  getInitials(petName),
                  style: const TextStyle(
                    color: AppDesign.warning,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          : null,
    );
  }

  Future<void> _confirmDelete(BuildContext context, String petName) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deletePetTitle),
        content: Text(l10n.deletePetConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete, style: const TextStyle(color: AppDesign.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
       await HistoryService.deletePet(petName);
       final service = PetProfileService();
       await service.init();
       await service.deleteProfile(petName);
       if (mounted) _loadHistory();
    }
  }
}

