import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/services/history_service.dart';
import '../models/pet_profile_extended.dart';
import '../../../core/utils/json_cast.dart';

import '../services/pet_profile_service.dart';
import 'widgets/edit_pet_form.dart';
import '../../partners/presentation/partner_agenda_screen.dart';
import 'widgets/weekly_menu_screen.dart';
import '../../../core/services/meal_history_service.dart';
import '../../../core/services/file_upload_service.dart';
import '../../../core/services/partner_service.dart';
import '../../../core/models/partner_model.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/pet_event_service.dart';
import '../models/pet_event.dart';
import '../../partners/models/agenda_event.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_design.dart';
import 'widgets/pet_menu_filter_dialog.dart';
import '../services/pet_menu_generator_service.dart';
import 'widgets/pet_event_grid.dart';

import '../models/meal_plan_request.dart';


import 'widgets/pet_event_report_dialog.dart';
import 'pet_event_history_screen.dart';
import 'package:share_plus/share_plus.dart';



class PetHistoryScreen extends ConsumerStatefulWidget {
  const PetHistoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PetHistoryScreen> createState() => _PetHistoryScreenState();
}

class _PetHistoryScreenState extends ConsumerState<PetHistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  Map<String, PartnerModel?> _petVets = {};
  Map<String, String?> _currentProfileImages = {};
  Map<String, PetProfileExtended?> _petProfiles = {}; // 🛡️ Source of Truth Map
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
      _initDocsDir();
      _loadHistory();
    });
  }
  
  Future<void> _initDocsDir() async {
      _appDocsDir = await getApplicationDocumentsDirectory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    final historyService = HistoryService();
    await historyService.init();
    final petHistory = await HistoryService.getHistory(); // Use static method
    
    // Sort by date descending
    petHistory.sort((a, b) {
        final dateA = DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime(2000);
        final dateB = DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime(2000);
        return dateB.compareTo(dateA);
    });

    // Load Vets and Images for each pet in history
    final partnerService = PartnerService();
    await partnerService.init();
    
    final profileService = PetProfileService();
    await profileService.init();

    Map<String, PartnerModel?> vetMap = {};
    Map<String, String?> imageMap = {};
    Map<String, PetProfileExtended?> profileMap = {};
    
    for (var item in petHistory) {
         final petName = item['pet_name'];
         if (petName != null && !profileMap.containsKey(petName)) {
             final profileData = await profileService.getProfile(petName);
             if (profileData != null && profileData['data'] != null) {
                 final profile = PetProfileExtended.fromHiveEntry(Map<String, dynamic>.from(profileData['data']));
                 profileMap[petName] = profile;
                 
                 // Cache image path
                 imageMap[petName] = profile.imagePath;
             }
         }

         // Load Vet for specific entries if needed
         if (item['type'] == 'pet_profile_created' || item['type'] == 'pet_profile_updated') {
             final petName = item['pet_name'];
             if (petName != null) {
                 final linkedIds = item['data']?['linked_partner_ids'] ?? [];
                 if (linkedIds is List && linkedIds.isNotEmpty) {
                     final partnerId = linkedIds.first; 
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
        _currentProfileImages = imageMap;
        _petProfiles = profileMap;
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
      body: !Hive.isBoxOpen(HistoryService.boxName) 
        ? const Center(child: CircularProgressIndicator(color: AppDesign.accent))
        : ValueListenableBuilder<Box>(
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
                  const Icon(Icons.pets, size: 64, color: AppDesign.petPink),
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
                final timestamp = DateFormat('dd/MM/yyyy HH:mm', Localizations.localeOf(context).toString()).format(date);
                
                // Extract breed/species for subtitle
                // 🛡️ SAFE SUBTITLE with Zero N/A Policy
                String subtitle;
                try {
                  // 🛡️ SHIELDING: Use Profile as Source of Truth if available
                  final profile = _petProfiles[petName];
                  String rawBreed = profile?.raca ?? '';
                  
                  if (rawBreed.isEmpty) {
                    if (data['analysis_type'] == 'diagnosis') {
                      rawBreed = data['breed']?.toString() ?? '';
                    } else {
                      // Robust Deep Search for Breed (Historical Fallback)
                      rawBreed = data['identificacao']?['raca_predominante']?.toString() ?? 
                                 data['identificacao']?['raca']?.toString() ?? 
                                 data['identificacao']?['breed']?.toString() ?? 
                                 data['identification']?['breed']?.toString() ?? 
                                 data['breed']?.toString() ?? 
                                 '';
                    }
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

                return Container(
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppDesign.surfaceDark,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // BLOCO 1 — CABEÇALHO (IDENTIDADE)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPetAvatar(item, radius: 44),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                petName,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_petProfiles[petName]?.especie ?? ''} • ${_petProfiles[petName]?.raca ?? data['breed'] ?? data['identificacao']?['raca_predominante'] ?? 'SRD'} • ${_petProfiles[petName]?.idadeExata ?? data['age'] ?? '---'}',
                                style: const TextStyle(color: Colors.white60, fontSize: 13),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${l10n.lastUpdated}: $timestamp',
                                style: const TextStyle(color: Colors.white38, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    

                  ],
                ),
              ),
            );
         },
      ),
      );
    },
  ),
);
}

  void _showEventSelector(BuildContext context, String petName) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppDesign.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: AppDesign.surfaceDark, 
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.petActionAgenda, // "Agenda" ou "Novo Evento"
                          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          'Selecione o tipo de registro',
                          style: TextStyle(color: Colors.white60, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PetEventHistoryScreen(petId: petName, petName: petName),
                          ),
                      );
                    },
                    icon: const Icon(Icons.history, size: 16, color: Colors.white),
                    label: Text(l10n.showEvents, style: const TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              PetEventGrid(petId: petName),
            ],
          ),
        ),
      ),
    );
  }

  
  /// 🛡️ Builds pet avatar with photo or fallback (PADRÃO OBRIGATÓRIO)
  Widget _buildPetAvatar(Map<String, dynamic> item, {double radius = 28}) {
    final l10n = AppLocalizations.of(context)!;
    final petName = item['pet_name'] as String? ?? l10n.petUnknown;

    // 1. Try to get FRESH image from Profile Service cache
    String? imagePath = _currentProfileImages[petName];
    
    // 2. Fallback to history item data if cache is empty
    if (imagePath == null) {
        imagePath = item['image_path'] as String?;
        if (imagePath == null && item['data'] != null && item['data'] is Map) {
            imagePath = item['data']['image_path']?.toString();
        }
    }
    
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
      debugPrint('   ✅ Valid image found for $petName: $imagePath');
    } else {
      debugPrint('   ℹ️ No valid image for $petName - using fallback');
    }
    
    // 🎨 Obter iniciais do nome para placeholder
    String getInitials(String name) {
      final words = name.trim().split(' ');
      if (words.isEmpty) return '?';
      if (words.length == 1) return words[0][0].toUpperCase();
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    
    // ✅ ROBUST IMPLEMENTATION: Container + ClipOval + Error Handling
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: AppDesign.petPink.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: AppDesign.petPink.withOpacity(0.3), width: 1),
      ),
      child: ClipOval(
        child: hasValidImage
            ? Image.file(
                File(imagePath!),
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('   ❌ Image load failed in UI: $error');
                  return _buildFallbackIcon(radius);
                },
              )
            : _buildFallbackIcon(radius),
      ),
    );
  }

  Widget _buildFallbackIcon(double radius) {
    return Center(
      child: Icon(
        Icons.pets,
        color: AppDesign.petPink,
        size: radius * 1.0, 
      ),
    );
  }


  Widget _buildQuickAction({required IconData icon, required String tooltip, required VoidCallback onTap, Color? color}) {
    return InkWell(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (color ?? Colors.white).withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: (color ?? Colors.white).withOpacity(0.1)),
          ),
          child: Icon(icon, color: color ?? Colors.white70, size: 18),
        ),
      ),
    );
  }

  Widget _buildCTA({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.2)),
        ),
        elevation: 0,
      ),
    );
  }

  Future<void> _handleEditTap(Map<String, dynamic> item, String petName, dynamic data) async {
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
    }

    if (!mounted) return;

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
            
            await HistoryService().savePetAnalysis(newName, analysisData, imagePath: profile.imagePath);
          },
          onDelete: () => _confirmDelete(context, petName),
        ),
      ),
    );
    if (mounted) _loadHistory();
  }

  Future<void> _handleMenuTap(BuildContext context, String petName) async {
    // Get pet profile to extract race name
    final profileService = PetProfileService();
    await profileService.init();
    final profileData = await profileService.getProfile(petName);
    
    String raceName = 'SRD';
    if (profileData != null && profileData['data'] != null) {
      raceName = profileData['data']['raca']?.toString() ?? 
                 profileData['data']['breed']?.toString() ?? 
                 'SRD';
    }
    
    // Navigate to weekly menu screen
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WeeklyMenuScreen(
          petName: petName,
          raceName: raceName,
        ),
      ),
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

