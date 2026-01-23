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
import 'package:uuid/uuid.dart';

import '../services/pet_profile_service.dart';
import 'widgets/edit_pet_form.dart';
import 'widgets/weekly_menu_screen.dart';
import '../../../core/services/partner_service.dart';
import '../../../core/models/partner_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_design.dart';
import 'widgets/pet_event_grid.dart';
import 'widgets/pet_action_bar.dart';


import 'pet_event_history_screen.dart';
import 'deep_analysis_pet_screen.dart';
import '../../../core/services/simple_auth_service.dart';
import '../models/pet_analysis_result.dart'; // Ensure this is imported


class PetHistoryScreen extends ConsumerStatefulWidget {
  const PetHistoryScreen({super.key});

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
         // 🛡️ ROBUST IDENTITY RESOLUTION (UUID Priority)
         final data = item['data'] is Map ? item['data'] : {};
         final rawName = item['pet_name'] ?? data['pet_name'] ?? data['name'];
         final rawId = item['pet_id'] ?? item['id'] ?? data['pet_id'] ?? data['id'];
         
         if (rawId != null || rawName != null) {
             final identifier = rawId?.toString() ?? rawName?.toString().trim();
             if (identifier == null || identifier.isEmpty) continue;
             
             if (!profileMap.containsKey(identifier)) {
                 final profileData = await profileService.getProfile(identifier);
                 if (profileData != null && profileData['data'] != null) {
                     try {
                        final dataMap = deepCastMap(profileData['data']);
                        final profile = PetProfileExtended.fromJson(dataMap);
                        profileMap[identifier] = profile;
                        
                        // Cache image path using UI-safe identifier
                        if (profile.imagePath != null && profile.imagePath!.isNotEmpty) {
                            imageMap[identifier] = profile.imagePath;
                        }
                     } catch (e) {
                        debugPrint('❌ [PetHistory] Error parsing profile for $identifier: $e');
                     }
                 }
             }
             
             // Load Vet for specific entries if needed
             if (item['type'] == 'pet_profile_created' || item['type'] == 'pet_profile_updated') {
                  final linkedIds = data['linked_partner_ids'] ?? [];
                  if (linkedIds is List && linkedIds.isNotEmpty) {
                      final partnerId = linkedIds.first; 
                      final partner = partnerService.getPartner(partnerId);
                      vetMap[identifier] = partner;
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
          debugPrint('📜 [AUDIT] Total de itens brutos na history box: ${allItems.length}');
          
          final rawHistory = allItems.where((item) {
             if (item is! Map) {
               debugPrint('   ⚠️ [AUDIT] Item ignorado: não é um Map (${item.runtimeType})');
               return false;
             }
             
             final mode = item['mode']?.toString().toLowerCase();
             final hasPetId = item['pet_id'] != null || (item['data'] is Map && item['data']['pet_id'] != null);
             final hasPetName = item['pet_name'] != null || (item['data'] is Map && item['data']['pet_name'] != null);
             
             // 🛡️ Permissive Filter: Accept explicit 'pet' mode OR any item with pet identifiers
             final isPet = mode == 'pet' || (mode == null && (hasPetId || hasPetName));
             
             if (!isPet) {
               debugPrint('   ℹ️ [AUDIT] Item filtrado (não identificado como Pet): mode=$mode');
             }
             return isPet;
          }).map((e) => deepCastMap(e)).toList();

          debugPrint('📜 [AUDIT] Itens após filtro de mode=Pet: ${rawHistory.length}');

          // 🛡️ DEDUPLICATION STRATEGY (V190)
          final Map<String, Map<String, dynamic>> uniqueMap = {};
          
          for (var item in rawHistory) {
              final data = (item['data'] is Map) ? item['data'] as Map : {};
              
              final rawId = item['pet_id'] ?? item['id'] ?? data['pet_id'] ?? data['id'];
              final rawName = item['pet_name'] ?? data['pet_name'] ?? data['name'];
              
              final key = rawId?.toString() ?? 
                           (rawName?.toString().trim().isNotEmpty == true ? rawName.toString().trim() : 'Unknown_${item['timestamp']}');
              
              debugPrint('   🔍 [AUDIT] Processando Pet: Name=$rawName, ID=$rawId -> Final Key=$key');
              
              if (key.isNotEmpty) {
                  if (!uniqueMap.containsKey(key)) {
                      uniqueMap[key] = item;
                  } else {
                      final currentTs = DateTime.tryParse(uniqueMap[key]?['timestamp'] ?? '') ?? DateTime(2000);
                      final newTs = DateTime.tryParse(item['timestamp'] ?? '') ?? DateTime(2000);
                      if (newTs.isAfter(currentTs)) {
                          uniqueMap[key] = item;
                      }
                  }
              }
          }
          
          // Override the list with uniqued values
          final petHistory = uniqueMap.values.toList();
          
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
                
                // 🛡️ ROBUST NAME RESOLUTION
                // Prioritize top-level pet_name, then data-level pet_name, then 'Pet'
                final rawName = item['pet_name'] ?? data['pet_name'] ?? data['name'];
                final petName = (rawName != null && rawName.toString().trim().isNotEmpty) 
                    ? rawName.toString().trim() 
                    : l10n.petUnknown;

                final timestamp = DateFormat('dd/MM/yyyy HH:mm', Localizations.localeOf(context).toString()).format(date);
                
                final rawId = item['pet_id'] ?? item['id'] ?? data['pet_id'] ?? data['id'];
                final identifier = rawId?.toString() ?? petName;
                
                // Extract breed/species for subtitle
                // 🛡️ SAFE SUBTITLE with Zero N/A Policy
                String subtitle;
                try {
                  // 🛡️ SUBTITLE LOGIC: Prioritize Profile as Source of Truth
                final profile = _petProfiles[identifier];
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
                  String typeSuffix = (data['analysis_type'] == 'diagnosis') ? l10n.petTypeHealth : l10n.petTypeID;
                  
                  subtitle = "$displayBreed • $typeSuffix";
                } catch (e) {
                   subtitle = l10n.petBreedUnknown;
                }

                return GestureDetector(
                  onTap: () async {
                      // 🛡️ V180: Secure Access to Deep Analysis
                      final authResult = await SimpleAuthService.authenticate();
                      if (authResult != AuthResult.success) return;
                      
                      try {
                          final analysisData = deepCastMap(data);
                          final result = PetAnalysisResult.fromJson(analysisData);
                          final profile = _petProfiles[petName];
                          
                          // Resolve Best Image Path
                          final rawId = item['pet_id'] ?? item['id'] ?? data['pet_id'] ?? data['id'];
                          final identifier = rawId?.toString() ?? petName;
                          
                          String? imgPath = _currentProfileImages[identifier];
                          if (imgPath == null || !File(imgPath).existsSync()) {
                             imgPath = item['image_path'] ?? data['image_path'];
                          }
                          
                          if (mounted) {
                             Navigator.push(
                               context, 
                               MaterialPageRoute(
                                 builder: (_) => DeepAnalysisPetScreen(
                                   analysis: result,
                                   imagePath: imgPath ?? '',
                                   petProfile: profile,
                                 )
                               )
                             );
                          }
                      } catch (e) {
                          debugPrint('❌ Error opening deep analysis: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text('${l10n.errorOpenAnalysis}: $e'))
                          );
                      }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: AppDesign.surfaceDark,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2), // Linter Fix
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
                                      '${_petProfiles[identifier]?.especie ?? ''} • ${_petProfiles[identifier]?.raca ?? data['breed'] ?? data['identificacao']?['raca_predominante'] ?? 'SRD'} • ${_petProfiles[identifier]?.idadeExata ?? data['age'] ?? '---'}',
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
                          
                          const SizedBox(height: 12),
                          
                          // BLOCO 2 — AÇÕES (3 BOTÕES)
                          PetActionBar(
                            petId: identifier,
                            petName: petName,
                            onAgendaTap: () => _showEventSelector(context, identifier, petName),
                            onMenuTap: () => _handleMenuTap(context, identifier, petName),
                            onEditTap: () => _handleEditTap(item, identifier, petName, data),
                          ),
                        ],
                      ),
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

  void _showEventSelector(BuildContext context, String identifier, String petName) {
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
                    (petName.isEmpty || petName == 'Pet') ? l10n.petNoName : petName,
                    style: GoogleFonts.poppins(fontSize: 20,
                      fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          l10n.petSelectRecordType,
                          style: const TextStyle(color: Colors.white60, fontSize: 13),
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
                             builder: (context) => PetEventHistoryScreen(petId: identifier, petName: petName),
                          ),
                      );
                    },
                    icon: const Icon(Icons.history, size: 16, color: Colors.black),
                    label: Text(l10n.petShowAll, style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppDesign.petPink,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
               PetEventGrid(petId: identifier),
            ],
          ),
        ),
      ),
    );
  }

  
    // 🛡️ Builds pet avatar with photo or fallback (PADRÃO OBRIGATÓRIO)
  Widget _buildPetAvatar(Map<String, dynamic> item, {double radius = 28}) {
    final l10n = AppLocalizations.of(context)!;
    // 🛡️ ROBUST IDENTITY RESOLUTION (Synced with List Builder)
    final rawName = item['pet_name'] ?? (item['data'] is Map ? item['data']['pet_name'] : null) ?? (item['data'] is Map ? item['data']['name'] : null);
    final rawId = item['pet_id'] ?? item['id'] ?? (item['data'] is Map ? (item['data']['pet_id'] ?? item['data']['id']) : null);
    
    final petName = (rawName != null && rawName.toString().trim().isNotEmpty) 
                      ? rawName.toString().trim() 
                      : l10n.petUnknown;

    final identifier = rawId?.toString() ?? petName;

    debugPrint('🔍 [UI_TRACE] Avatar Build for: $petName ($identifier)');

    // 1. Try to get FRESH image from Profile Service cache
    String? imagePath = _currentProfileImages[identifier];
    debugPrint('   [UI_TRACE] Profile Cache Path: $imagePath');
    
    // 2. Fallback to history item data if cache is empty
    if (imagePath == null) {
        imagePath = item['image_path'] as String?;
        if (imagePath == null && item['data'] != null && item['data'] is Map) {
            imagePath = item['data']['image_path']?.toString();
        }
        debugPrint('   [UI_TRACE] History Fallback Path: $imagePath');
    }
    
    // 🛡️ Verificar se imagem existe e é válida
    bool hasValidImage = imagePath != null &&
                          imagePath.isNotEmpty &&
                          File(imagePath).existsSync();
    
    debugPrint('   [UI_TRACE] Initial Valid Check: $hasValidImage');
    
    // 🚑 RECOVERY STRATEGY: Global Search for file in Documents
    if (!hasValidImage && imagePath != null && _appDocsDir != null) {
        debugPrint('   [UI_TRACE] Entering Emergency UI Recovery...');
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
                debugPrint('🚑 [UI_TRACE] Rescued image for $petName at: $rPath');
                imagePath = rPath;
                hasValidImage = true;
            }
        } catch (e) {
            debugPrint('Error recovering history image: $e');
        }
    }
    
    if (hasValidImage) {
      debugPrint('   ✅ [UI_TRACE] Valid image found for $petName: $imagePath');
    } else {
      debugPrint('   ℹ️ [UI_TRACE] No valid image for $petName - using fallback');
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

  Future<void> _handleEditTap(Map<String, dynamic> item, String identifier, String petName, dynamic data) async {
    final sw = Stopwatch()..start();

    // 🛡️ UX Fix: Show loading immediately
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppDesign.petPink)),
    );

    // 🛡️ UI FORCE RENDER: Aguarda o frame ser desenhado
    await Future.delayed(const Duration(milliseconds: 100));
    debugPrint('⏱️ [PERF] UI Render Wait: ${sw.elapsedMilliseconds}ms');

    PetProfileExtended? loaded;
    try {
      final profileService = PetProfileService();
      await profileService.init();
      debugPrint('⏱️ [PERF] Service Init: ${sw.elapsedMilliseconds}ms');

      final existingMap = await profileService.getProfile(identifier);
      debugPrint('⏱️ [PERF] Hive Fetch: ${sw.elapsedMilliseconds}ms');

      if (existingMap != null && existingMap['data'] != null) {
        final startParse = sw.elapsedMilliseconds;
        final dataMap = deepCastMap(existingMap['data']);
        debugPrint('⏱️ [PERF] deepCastMap (Cost): ${sw.elapsedMilliseconds - startParse}ms');

        final startJson = sw.elapsedMilliseconds;
        loaded = PetProfileExtended.fromJson(dataMap);
        debugPrint('⏱️ [PERF] fromJson (Cost): ${sw.elapsedMilliseconds - startJson}ms');
      }
    } catch (e) {
      debugPrint('Error loading full profile: $e');
    }

    if (!mounted) return;
    Navigator.of(context).pop(); // Dismiss loader

    debugPrint('⏱️ [PERF] Ready to Push: ${sw.elapsedMilliseconds}ms');
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPetForm(
          existingProfile: loaded ?? PetProfileExtended(
            id: data['id'] ?? data['pet_id'] ?? const Uuid().v4(),
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
            final newName = profile.petName;
            
            // 🛡️ O UUID garante que estamos atualizando o mesmo registro, não importa se o nome mudou.
            await service.saveOrUpdateProfile(newName, profile.toJson());
            
            final analysisData = profile.rawAnalysis ?? {};
            if (profile.raca != null) {
              if (analysisData['identificacao'] == null) analysisData['identificacao'] = {};
              analysisData['identificacao']['raca_predominante'] = profile.raca;
              analysisData['breed'] = profile.raca;
            }
            
            // 🛡️ [V_FIX] CRITICAL: Use profile.id to ensure the History entry is updated, not duplicated.
            // Never delete by name in an auto-save environment.
            await HistoryService().savePetAnalysis(
              newName, 
              analysisData, 
              imagePath: profile.imagePath, 
              petId: profile.id, // <--- STABLE UUID
            );
          },
           onDelete: () => _confirmDelete(context, identifier, petName),
        ),
      ),
    );
    if (mounted) _loadHistory();
  }

  Future<void> _handleMenuTap(BuildContext context, String identifier, String petName) async {
    // Get pet profile to extract race name
    final profileService = PetProfileService();
    await profileService.init();
    final profileData = await profileService.getProfile(identifier);
    
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
          petId: identifier,
          petName: petName,
          raceName: raceName,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String identifier, String petName) async {

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
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
       await HistoryService.deletePet(identifier);
       final service = PetProfileService();
       await service.init();
       await service.deleteProfile(identifier);
       if (mounted) _loadHistory();
    }
  }
}

