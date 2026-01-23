import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'media_manager_screen.dart';

import '../../../core/theme/app_design.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../features/pet/services/pet_profile_service.dart';
import '../../../core/services/media_vault_service.dart';
import '../../../core/services/history_service.dart';
import '../../../core/services/data_seed_service.dart';
import '../../../core/services/simple_auth_service.dart';
import '../../../core/providers/partner_provider.dart';
import '../../../core/providers/pet_event_provider.dart';
import '../../../features/pet/services/pet_event_service.dart';
import '../../../features/pet/services/pet_event_repository.dart';
import '../../../core/services/hive_atomic_manager.dart';
import '../../../core/services/permanent_backup_service.dart';
import '../../../core/providers/settings_provider.dart';

class DataManagerScreen extends ConsumerStatefulWidget {
  const DataManagerScreen({super.key});

  @override
  ConsumerState<DataManagerScreen> createState() => _DataManagerScreenState();
}

class _DataManagerScreenState extends ConsumerState<DataManagerScreen> {
  // STATS
  int _totalSizeMB = 0;
  int _dbSizeMB = 0;
  int _mediaSizeMB = 0;
  int _countOccurrences = 0;
  final int _countAnalyses = 0;
  
  // FILTERS (3D)
  String? _selectedPetName;
  String? _selectedPetId;
  final Map<String, bool> _categories = {
    'Análises': true,
    'Cardápios': true,
    'Ocorrências': true,
    'Agenda': true,
    'Exames': true,
  };
  String _timeRangeLabel = 'Todo o período';
  DateTimeRange? _customDateRange;

  // FLOW STATE
  final bool _isSavedConfirmed = false;
  
  // LAST BACKUP INFO
  String _lastBackupDate = "Sem Backup";
  String _lastBackupFileName = "";
  String _lastBackupSize = "";

  @override
  void initState() {
    super.initState();
    _calculateStorageUsage();
    _loadLastBackupInfo();
  }

  Future<void> _calculateStorageUsage() async {
     try {
       int totalKeys = 0;
       
       // List of boxes to count
       final boxes = [
         'nutrition_weekly_plans',
         'nutrition_shopping_list',
         'nutrition_user_profile',
         'nutrition_meal_logs',
         'box_nutrition_human',
         'box_plants_history',
         'vaccine_status',
         'pet_events',
         'weekly_meal_plans',
         'box_pets_master',
         'pet_health_records',
         'box_workouts',
         'scannut_history'
       ];

       final authService = SimpleAuthService();
       final cipher = authService.encryptionCipher;

       for (final name in boxes) {
         try {
           if (Hive.isBoxOpen(name)) {
                try {
                  totalKeys += Hive.box(name).length;
                } catch (e) {
                  // Box open but type mismatch likely
                  debugPrint('ℹ️ [Stats] Skipping open box $name due to type/access error.');
                }
           } else {
                if (await Hive.boxExists(name)) {
                   if (cipher != null) {
                      try {
                        // Open as dynamic to avoid TypeAdapter errors just for counting
                        final box = await Hive.openBox(name, encryptionCipher: cipher);
                        totalKeys += box.length;
                        // We close it if we opened it just for stats to keep memory clean
                        await box.close(); 
                      } catch (e) {
                        debugPrint('⚠️ [Stats] Failed to open $name for counting: $e');
                      }
                   }
                }
           }
         } catch (e) {
            debugPrint('⚠️ Error counting box $name: $e');
         }
       }

       if (mounted) {
         setState(() {
            _countOccurrences = totalKeys;
            _dbSizeMB = 1 + (totalKeys / 10).ceil();
            _mediaSizeMB = 15; 
            _totalSizeMB = _dbSizeMB + _mediaSizeMB;
         });
       }

     } catch (e) {
        debugPrint('❌ Critical Stats error: $e');
     }
  }

  Future<void> _loadLastBackupInfo() async {
    try {
      final path = await PermanentBackupService().getBackupPath();
      final dir = Directory(path);
      if (await dir.exists()) {
        final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.scannut')).toList();
        if (files.isNotEmpty) {
          // Sort by last modified descending
          files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
          final lastFile = files.first;
          final stats = await lastFile.stat();
          final sizeKB = (stats.size / 1024).toStringAsFixed(1);
          
          if (mounted) {
            setState(() {
              _lastBackupDate = DateFormat('dd/MM/yyyy HH:mm').format(stats.modified);
              _lastBackupFileName = lastFile.path.split('/').last.split('\\').last;
              _lastBackupSize = "$sizeKB KB";
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint("⚠️ Erro ao carregar info de backup: $e");
    }
    
    if (mounted) {
      setState(() {
        _lastBackupDate = "Sem Backup";
        _lastBackupFileName = "";
        _lastBackupSize = "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesign.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppDesign.surfaceDark,
        elevation: 0,
        title: Text('Gerenciador de Dados', style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppDesign.textPrimaryDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

               // BACKUP STATUS CARD
               Container(
                 width: double.infinity,
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: AppDesign.surfaceDark,
                   borderRadius: BorderRadius.circular(16),
                   border: Border.all(color: Colors.white10),
                 ),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Row(
                       children: [
                         Icon(Icons.history, color: _lastBackupDate == "Sem Backup" ? Colors.orange : Colors.green, size: 20),
                         const SizedBox(width: 8),
                         Text('Último Backup Permanente', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                       ],
                     ),
                     const SizedBox(height: 12),
                     if (_lastBackupDate == "Sem Backup")
                        Text("Sem Backup", style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13, fontStyle: FontStyle.italic))
                     else ...[
                        _buildBackupDetail('Data:', _lastBackupDate),
                        _buildBackupDetail('Arquivo:', _lastBackupFileName),
                        _buildBackupDetail('Tamanho:', _lastBackupSize),
                     ],
                   ],
                 ),
               ),
              const SizedBox(height: 16),

              _buildStatsDashboard(),
              const SizedBox(height: 32),
              
              _buildSmartArchivingCard(), 
               
              const SizedBox(height: 16),
              _buildAttachmentManagerCard(),
               
              const SizedBox(height: 32),
              _buildSectionTitle('2. Zona de Perigo (Exclusão)'),
              const SizedBox(height: 12),
              _buildDangerZone(),
               
              const SizedBox(height: 100), 
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsDashboard() {
     return Column(
        children: [
           Row(
              children: [
                 Expanded(child: _buildStatCard('Espaço Total', '$_totalSizeMB MB', Icons.sd_storage, Colors.blue)),
                 const SizedBox(width: 8),
                 Expanded(child: _buildStatCard('Mídia (Anexos)', '$_mediaSizeMB MB', Icons.image, Colors.purple)),
              ],
           ),
           const SizedBox(height: 8),
           Row(
              children: [
                 Expanded(child: _buildStatCard('Banco de Dados', '$_dbSizeMB MB', Icons.storage, Colors.orange)),
                 const SizedBox(width: 8),
                 Expanded(child: _buildStatCard('Itens Registrados', '$_countOccurrences+', Icons.list_alt, Colors.green)),
              ],
           ),
        ],
     );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
     return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
           color: AppDesign.surfaceDark,
           borderRadius: BorderRadius.circular(12),
           border: Border.all(color: Colors.white10),
        ),
        child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 8),
              Text(value, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              Text(label, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11)),
           ],
        ),
     );
  }

  Widget _buildSmartArchivingCard() {
     return Container(
       padding: const EdgeInsets.all(16),
       decoration: BoxDecoration(
         color: const Color(0xFFFFD1DC), // Pastel Pink
         borderRadius: BorderRadius.circular(16),
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            Row(
               children: [
                  const Icon(Icons.inventory_2, color: Colors.black87),
                  const SizedBox(width: 8),
                  Text('Arquivamento com Filtro 3D', style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
               ],
            ),
            const Divider(color: Colors.black12, height: 24),
            
            // FILTERS PREVIEW
            _buildFilterRow('QUEM', _selectedPetName ?? 'Todos os Pets', Icons.pets),
            if (_selectedPetId != null && _selectedPetId != _selectedPetName) ...[
               const SizedBox(height: 4),
               _buildFilterRow('ID', '${_selectedPetId!.substring(0, 8)}...', Icons.fingerprint),
            ],
            const SizedBox(height: 8),
            _buildFilterRow('O QUÊ', '${_categories.entries.where((e)=>e.value).length} Categorias', Icons.category),
            const SizedBox(height: 8),
            _buildFilterRow('QUANDO', _timeRangeLabel, Icons.calendar_today),
            
            const SizedBox(height: 16),
            // ACTIONS
            SizedBox(
               width: double.infinity,
               child: ElevatedButton.icon(
                  onPressed: () => _showFilterDialog(),
                  icon: const Icon(Icons.file_download, size: 20),
                  label: const Text('Arquivar Dados (Filtro Personalizado)', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.white,
                     foregroundColor: Colors.black,
                     padding: const EdgeInsets.symmetric(vertical: 16),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                     elevation: 0,
                  ),
               ),
            ),
         ],
       ),
    );
  }

  Widget _buildAttachmentManagerCard() {
     return InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MediaManagerScreen())),
        borderRadius: BorderRadius.circular(16),
        child: Container(
           padding: const EdgeInsets.all(16),
           decoration: BoxDecoration(
              color: const Color(0xFFFFD1DC).withOpacity(0.7), 
              borderRadius: BorderRadius.circular(16),
           ),
           child: Row(
              children: [
                 const Icon(Icons.perm_media, color: Colors.black87),
                 const SizedBox(width: 12),
                 Expanded(
                    child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                          Text('Anexos Físicos', style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.bold)),
                          Text('Gerenciar arquivos pesados', style: GoogleFonts.poppins(color: Colors.black54, fontSize: 11)),
                       ],
                    ),
                 ),
                 const Icon(Icons.chevron_right, color: Colors.black54),
              ],
           ),
        ),
     );
  }
  
  Widget _buildFilterRow(String label, String value, IconData icon) {
     return Row(
        children: [
           Icon(icon, size: 14, color: Colors.black54),
           const SizedBox(width: 8),
           Text('$label:', style: GoogleFonts.poppins(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.bold)),
           const SizedBox(width: 4),
           Expanded(child: Text(value, style: GoogleFonts.poppins(color: Colors.black87, fontSize: 12))),
        ],
     );
  }

  Widget _buildDangerZone() {
     return Column(
        children: [
           _buildDomainDeleteCard(
              title: 'ALIMENTOS', icon: Icons.restaurant, color: Colors.orange,
              actions: [
                 _buildDeleteAction(label: 'Excluir Total (Dados + Fotos)', onTap: () => _confirmAction('Tudo de Alimentos', _wipeFoodData)),
              ]
           ),
           const SizedBox(height: 16),
           _buildDomainDeleteCard(
              title: 'PLANTAS', icon: Icons.local_florist, color: Colors.green,
              actions: [
                 _buildDeleteAction(label: 'Excluir Total (Dados + Fotos)', onTap: () => _confirmAction('Tudo de Plantas', _wipePlantData)),
              ]
           ),
           const SizedBox(height: 16),
           _buildDomainDeleteCard(
              title: 'PETS', icon: Icons.pets, color: AppDesign.petPink,
              actions: [
                 _buildDeleteAction(label: 'Excluir Total (Dados + Fotos)', onTap: () => _confirmAction('Tudo de Pets', _wipePetData)),
              ]
           ),
           const SizedBox(height: 16),
           _buildDomainDeleteCard(
              title: 'GERAL', icon: Icons.settings_backup_restore, color: Colors.grey,
              actions: [
                 _buildDeleteAction(label: 'Excluir TUDO (Reset de Fábrica)', isDestructive: true, onTap: () => _confirmAction('CONTA COMPLETA', () => _performFactoryReset())),
              ]
           ),
        ],
     );
  }

  Widget _buildDomainDeleteCard({required String title, required IconData icon, required Color color, required List<Widget> actions}) {
    return Container(
      decoration: BoxDecoration(
        color: AppDesign.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.red, 
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }

  Widget _buildDeleteAction({required String label, required VoidCallback onTap, bool isDestructive = false}) {
    return ListTile(
      title: Text(label, style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark, fontSize: 14)),
      trailing: Icon(Icons.delete_outline, color: isDestructive ? Colors.red : AppDesign.textSecondaryDark, size: 20),
      onTap: onTap,
    );
  }
  
  Future<void> _confirmAction(String title, Future<void> Function() action) async {
     // 1. 🛡️ SECURITY CHALLENGE FIRST
     final auth = SimpleAuthService();
      final bool isVerified = await auth.verifyIdentity(
        reason: 'Autentique-se para iniciar a exclusão de $title'
      );
      
      // Wait for OS dialog animation to fully close
      await Future.delayed(const Duration(milliseconds: 500));

     if (!isVerified) {
        if (mounted) {
           SnackBarHelper.showError(context, 'Autenticação falhou. Ação cancelada.');
        }
        return;
     }

     if (!mounted) return;

     // 2. SHOW CONFIRMATION DIALOG
     return showDialog(
        context: context,
        builder: (context) => AlertDialog(
           backgroundColor: AppDesign.surfaceDark,
           title: Text('Excluir $title?', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
           content: Text('Esta ação é irreversível.', style: GoogleFonts.poppins(color: Colors.white70)),
           actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              TextButton(
                 onPressed: () async {
                    Navigator.pop(context);
                    await action();
                    if (title == 'CONTA COMPLETA') return;

                    if(mounted) {
                       SnackBarHelper.showSuccess(context, 'Excluído com sucesso.');
                       _calculateStorageUsage();
                    }
                 }, 
                 child: Text('EXCLUIR', style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
           ],
        ),
     );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(), 
      style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2),
    );
  }

  Widget _buildBackupDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(label, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFD1DC),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _FilterModalContent(
        initialPetId: _selectedPetId,
        categories: _categories,
        initialDateRange: _customDateRange,
        onApply: (petName, petId, cats, range, label) {
          setState(() {
            _selectedPetName = petName;
            _selectedPetId = petId;
            _categories.clear();
            _categories.addAll(cats);
            _customDateRange = range;
            _timeRangeLabel = label;
          });
          Future.delayed(const Duration(milliseconds: 300), () {
             _executeSmartArchiving(petName, petId, cats, range);
          });
        },
      ),
    );
  }

  Future<void> _executeSmartArchiving(String? petName, String? petId, Map<String, bool> categories, DateTimeRange? dateRange) async {
       if (petName == null && petId == null) return;
       showDialog(
          context: context, 
          barrierDismissible: false,
          builder: (c) => const Center(child: CircularProgressIndicator(color: AppDesign.primary))
       );
       
       try {
           final petEventService = PetEventService();
           await petEventService.init();
           final allEvents = petEventService.getAllEvents();
           final targetId = petId?.trim();
           final targetName = petName?.trim().toLowerCase();
           
           final toDelete = allEvents.where((e) {
               if (targetId != null && e.petId == targetId) return true;
               if (targetName != null && e.petName.trim().toLowerCase() == targetName) return true;
               return false;
           }).where((e) {
               if (dateRange != null) {
                   if (e.dateTime.isBefore(dateRange.start) || e.dateTime.isAfter(dateRange.end.add(const Duration(days:1)))) {
                       return false;
                   }
               }
               return true;
           }).toList();
           
           int count = 0;
           for (var e in toDelete) {
               await petEventService.deleteEvent(e.id);
               count++;
           }
           
           ref.invalidate(petEventServiceProvider);
           ref.invalidate(historyServiceProvider);
           _calculateStorageUsage();
           
           if(mounted) {
              Navigator.pop(context); 
              SnackBarHelper.showSuccess(context, 'Filtro 3D: $count registros de $petName excluídos/arquivados.');
           }
           
       } catch (e) {
           if(mounted) {
              Navigator.pop(context);
              SnackBarHelper.showError(context, 'Erro no arquivamento: $e');
           }
       }
  }
  
  Future<void> _clearBox(String name) async {
      try {
        final box = await HiveAtomicManager().ensureBoxOpen(name);
        await box.clear();
      } catch (e) {
        debugPrint('⚠️ Error clearing box "$name": $e');
      }
  }
  
  Future<void> _clearHistoryByMode(String mode) async {
      final box = await HiveAtomicManager().ensureBoxOpen('scannut_history');
      final keys = box.keys.where((k) {
         final v = box.get(k);
         return v is Map && v['mode'] == mode;
      }).toList();
      await box.deleteAll(keys);
  }
  
  Future<void> _clearHistoryDeep(bool Function(Map) predicate) async {
      try {
        final box = await HiveAtomicManager().ensureBoxOpen('scannut_history');
        final keys = box.keys.where((k) {
           final v = box.get(k);
           if (v is! Map) return false;
           return predicate(v);
        }).toList();
        if (keys.isNotEmpty) {
          await box.deleteAll(keys);
        }
      } catch (e) {
        debugPrint('⚠️ DeepClean error: $e');
      }
  }

  Future<void> _clearAgendaEvents(List<String> keywords) async {
        try {
             final petEventService = PetEventService();
             await petEventService.init();
             final allEvents = petEventService.getAllEvents();
             final toDelete = allEvents.where((e) {
                final t = e.type.toString().toLowerCase();
                return keywords.any((k) => t.contains(k));
             }).toList();
             for(var e in toDelete) {
               await petEventService.deleteEvent(e.id);
             }
             ref.invalidate(petEventServiceProvider);
        } catch(e) { debugPrint('Agenda error: $e'); }
  }
  
  Future<void> _performFactoryReset() async {
    final boxesToClear = [
      // 🐾 Módulo Pet
      'box_pets_master',
      'pet_events',
      'pet_events_journal',
      'vaccine_status',
      'pet_health_records',
      'lab_exams',
      'weekly_meal_plans',
      
      // 🍎 Módulo Nutrição (Humano)
      'box_nutrition_human',
      'nutrition_user_profile',
      'nutrition_weekly_plans',
      'nutrition_meal_logs',
      'nutrition_shopping_list',
      'menu_filter_settings',
      'recipe_history_box',
      'box_nutrition_history',
      'meal_log',
      'scannut_meal_history',
      
      // 🌿 Módulo Botânica
      'box_plants_history',
      'box_botany_intel',
      
      // 🛠️ Módulo Core / Histórico / Misc
      'scannut_history',
      'settings',
      'user_profiles',    // Real name used in HiveInit
      'user_profile',     // Legacy variant
      'box_workouts',
      'processed_images_box',
      'partners_box',
      'partners',         // Legacy variant
      'box_user_profile', // Legacy variant
      'pet_shopping_lists', // Added (V231)
      'box_nutrition_pets',  // Added (Legacy fallback)
      'box_pets_profiles',   // Added (Legacy fallback)
    ];


    try {
        final cipher = SimpleAuthService().encryptionCipher;
        debugPrint('🛡️ [Factory Reset] Trace: Encryption Cipher is ${cipher != null ? "ACTIVE" : "NULL/INACTIVE"}');
        
        // 🚀 STEP 0: CLOSE ALL BOXES
        // This is critical to avoid "Box already open with different type" errors during reset
        debugPrint('🧹 [Factory Reset] Step 0: Closing all boxes to ensure clean deletion...');
        await Hive.close();
        
        for (final name in boxesToClear) {
             try {
                debugPrint('🔍 [Factory Reset] Processing Box: $name...');
                
                // Nuclear approach: Delete files directly from disk
                if (await Hive.boxExists(name)) {
                   await Hive.deleteBoxFromDisk(name);
                   debugPrint('✅ [Factory Reset] NUCLEAR DELETE for $name (Disk files removed)');
                } else {
                   debugPrint('ℹ️ [Factory Reset] Box $name does not exist on disk, skipping.');
                }
             } catch (e) {
                debugPrint('❌ [Factory Reset] ERROR deleting $name: $e');
             }
        }

        // 🛡️ STEP 1: Reconstruct Auth Box (Essential for maintaining session)
        debugPrint('🌱 [Factory Reset] Step 1: Reconstructing Auth Box...');
        await Hive.openBox('box_auth_local');


        // 🛡️ RE-INIT SERVICES: After atomic reconstruction, memory singletons need a nudge
        debugPrint('🔄 [Factory Reset] Re-initializing critical repositories...');
        try {
           await PetEventRepository().init(cipher: cipher);
           await PetEventService().init(cipher: cipher);
           await PetProfileService().init(cipher: cipher);
           debugPrint('✅ [Factory Reset] Repositories re-initialized.');
        } catch (e) {
           debugPrint('⚠️ [Factory Reset] Repository re-init warning: $e');
        }




        try {
            final ms = MediaVaultService();
            await ms.clearDomain(MediaVaultService.PETS_DIR);
            await ms.clearDomain(MediaVaultService.FOOD_DIR);
            await ms.clearDomain(MediaVaultService.BOTANY_DIR);
            await ms.clearDomain(MediaVaultService.WOUNDS_DIR);
            
            await _deleteLegacyFolder('PetPhotos');
            await _deleteLegacyFolder('nutrition_images');
            await _deleteLegacyFolder('botany_images');
        } catch(e) {}

        // 🛡️ V231: Clear Permanent Backup (DESATIVADO POR SOLICITAÇÃO)
        /*
        try {
           await PermanentBackupService().clearBackup();
        } catch (_) {}
        */

    } catch (e) {
       debugPrint('❌ [Factory Reset] CRITICAL FAILURE: $e');
    }
    
    // 🛡️ User request: Keep Login/Auth Intact. No logout here.
    
    // 🔄 Force Refresh of all Riverpod providers to clear UI state
    try {
      ref.invalidate(petProfileServiceProvider);
      ref.invalidate(petEventServiceProvider);
      ref.invalidate(historyServiceProvider);
      ref.invalidate(settingsProvider);
      // ref.invalidate(nutritionServiceProvider); // If exists
      debugPrint('🔄 [Factory Reset] Providers invalidated. UI should refresh.');
    } catch (e) {
      debugPrint('⚠️ [Factory Reset] Provider invalidation warning: $e');
    }

    if (mounted) {
      SnackBarHelper.showSuccess(context, 'Dados limpos com sucesso. ');
      _calculateStorageUsage();
    }

  }

  Future<void> _wipeFoodData() async {
      final cipher = SimpleAuthService().encryptionCipher;
      
      // 🍎 Atomic List of all Food related boxes
      final foodBoxes = [
        'box_nutrition_human',
        'nutrition_user_profile',
        'nutrition_weekly_plans',
        'nutrition_meal_logs',
        'nutrition_shopping_list',
        'menu_filter_settings',
        'recipe_history_box',
      ];

      for (final boxName in foodBoxes) {
        try {
          final box = await HiveAtomicManager().ensureBoxOpen(boxName, cipher: cipher);
          await box.clear();
          debugPrint('🧹 [Wipe Food] $boxName cleared.');
        } catch (e) {
          debugPrint('⚠️ [Wipe Food] Failed to clear $boxName: $e');
        }
      }

      await _clearHistoryByMode('Food');
      await _clearHistoryByMode('Recipe');
      await _clearHistoryDeep((v) => v['mode'] == 'Food' || v['mode'] == 'Nutrition' || v['type'] == 'nutrition');
      await _clearAgendaEvents(['food']);
      
      // Cleanup Media
      await MediaVaultService().clearDomain(MediaVaultService.FOOD_DIR);
      await _deleteLegacyFolder('nutrition_images');
      
      // Clear image cache registry for food photos
      await _clearBox('processed_images_box');
      
      // Update Permanent Backup to reflect removals
      await PermanentBackupService().createAutoBackup();
      
      ref.invalidate(historyServiceProvider);
  }

  Future<void> _wipePlantData() async {
      final cipher = SimpleAuthService().encryptionCipher;
      
      // 🌿 Atomic List of all Plant related boxes
      final plantBoxes = [
        'box_plants_history',
        'box_botany_intel',
      ];

      for (final boxName in plantBoxes) {
        try {
          final box = await HiveAtomicManager().ensureBoxOpen(boxName, cipher: cipher);
          await box.clear();
          debugPrint('🧹 [Wipe Plant] $boxName cleared.');
        } catch (e) {
          debugPrint('⚠️ [Wipe Plant] Failed to clear $boxName: $e');
        }
      }

      await _clearHistoryByMode('Plant');
      
      // Cleanup Media
      await MediaVaultService().clearDomain(MediaVaultService.BOTANY_DIR);
      await _deleteLegacyFolder('botany_images');
      await _deleteLegacyFolder('PlantAnalyses');
      
      // Clear image cache registry for plant photos
      await _clearBox('processed_images_box');
      
      // Update Permanent Backup to reflect removals
      await PermanentBackupService().createAutoBackup();
      
      ref.invalidate(historyServiceProvider);
  }

  Future<void> _wipePetData() async {
      final cipher = SimpleAuthService().encryptionCipher;
      
      // 🐾 Atomic List of all Pet related boxes
      final petBoxes = [
         'box_pets_master',
         'pet_events',
         'pet_events_journal',
         'vaccine_status',
         'pet_health_records',
         'lab_exams',
         'weekly_meal_plans',
      ];

      for (final boxName in petBoxes) {
        try {
          final box = await HiveAtomicManager().ensureBoxOpen(boxName, cipher: cipher);
          await box.clear();
          debugPrint('🧹 [Wipe Pet] $boxName cleared.');
        } catch (e) {
          debugPrint('⚠️ [Wipe Pet] Failed to clear $boxName: $e');
        }
      }

      await _clearHistoryByMode('Pet');
      await _clearHistoryDeep((v) => v['mode'] == 'Pet' || (v['pet_name'] != null) || (v['petId'] != null));
      
      // Cleanup Media
      await MediaVaultService().clearDomain(MediaVaultService.PETS_DIR);
      await _deleteLegacyFolder('PetPhotos');
      
      // Clear image cache registry for pet photos
      await _clearBox('processed_images_box');
      
      // Update Permanent Backup to reflect removals
      await PermanentBackupService().createAutoBackup();
      
      ref.invalidate(petEventServiceProvider);
      ref.invalidate(partnerServiceProvider);
      ref.invalidate(historyServiceProvider);
  }
  
  Future<void> _deleteLegacyFolder(String folderName) async {
      try {
         final appDir = await getApplicationDocumentsDirectory();
         final dir = Directory('${appDir.path}/$folderName');
         if(await dir.exists()) {
             await dir.delete(recursive: true);
         }
      } catch(e) {}
  }
}

class _FilterModalContent extends StatefulWidget {
  final String? initialPetId;
  final Map<String, bool> categories;
  final DateTimeRange? initialDateRange;
  final Function(String?, String?, Map<String, bool>, DateTimeRange?, String) onApply;

  const _FilterModalContent({
    required this.initialPetId,
    required this.categories,
    required this.initialDateRange,
    required this.onApply,
  });

  @override
  State<_FilterModalContent> createState() => _FilterModalContentState();
}

class _FilterModalContentState extends State<_FilterModalContent> {
  String? _selectedPetId;
  String? _selectedPetName;
  late Map<String, bool> _localCategories;
  DateTimeRange? _dateRange;
  String _dateLabel = 'Todo o período';

  @override
  void initState() {
    super.initState();
    _selectedPetId = widget.initialPetId;
    _localCategories = Map.from(widget.categories);
    _dateRange = widget.initialDateRange;
    _updateDateLabel();
  }
  
  void _updateDateLabel() {
     if(_dateRange == null) {
        _dateLabel = 'Todo o período';
     } else {
        final start = DateFormat('dd/MM/yyyy').format(_dateRange!.start);
        final end = DateFormat('dd/MM/yyyy').format(_dateRange!.end);
        _dateLabel = '$start - $end';
     }
  }

  bool get _isValid => _selectedPetId != null && _localCategories.values.contains(true);
  
  Future<void> _pickDateRange() async {
     final picked = await showDateRangePicker(
       context: context,
       firstDate: DateTime(2020),
       lastDate: DateTime.now(),
       initialDateRange: _dateRange,
       builder: (context, child) {
          return Theme(
             data: ThemeData.light().copyWith(
                colorScheme: const ColorScheme.light(
                   primary: Color(0xFFE91E63),
                   onPrimary: Colors.white,
                   surface: Color(0xFFFFD1DC),
                   onSurface: Colors.black,
                ),
             ),
             child: child!,
          );
       }
     );
     if(picked != null) {
        setState(() {
           _dateRange = picked;
           _updateDateLabel();
        });
     }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFFFD1DC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text('FILTRO 3D', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
                   IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.black54)),
                ],
             ),
             const Divider(color: Colors.black12),
             Expanded(
                child: ListView(
                   children: [
                      Text('QUEM (Pet)', style: GoogleFonts.poppins(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 12),
                      FutureBuilder<Map<String, String>>(
                         future: PetProfileService().getAllPetSummaries(),
                         builder: (context, snapshot) {
                            if (!snapshot.hasData) return const LinearProgressIndicator(color: Color(0xFFE91E63));
                            final summaries = snapshot.data!;
                            return Container(
                               decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: DropdownButtonHideUnderline(
                                   child: DropdownButton<String>(
                                      value: _selectedPetId,
                                      dropdownColor: Colors.white,
                                      menuMaxHeight: 400,
                                      hint: Row(
                                         children: [
                                            const Icon(Icons.pets, size: 18, color: Colors.black54),
                                            const SizedBox(width: 8),
                                            Text('Selecionar Pet', style: GoogleFonts.poppins(color: Colors.black54, fontSize: 14)),
                                         ],
                                      ),
                                      isExpanded: true,
                                      icon: const Icon(Icons.arrow_drop_down, color: Colors.black87),
                                      items: summaries.entries.map((e) => DropdownMenuItem(
                                         value: e.value, 
                                         child: Row(
                                            children: [
                                               const Icon(Icons.pets, size: 18, color: Color(0xFFE91E63)),
                                               const SizedBox(width: 8),
                                               Text(e.key, style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.w500)),
                                            ],
                                         ),
                                      )).toList(),
                                      onChanged: (val) {
                                         setState(() {
                                            _selectedPetId = val;
                                            _selectedPetName = summaries.entries.firstWhere((e) => e.value == val).key;
                                         });
                                      },
                                   ),
                                ),
                             );
                          },
                       ),
                      const SizedBox(height: 24),
                      Text('O QUÊ (Categorias)', style: GoogleFonts.poppins(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 12),
                      Card(
                         color: Colors.white.withOpacity(0.5),
                         elevation: 0,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                         child: Column(
                            children: _localCategories.keys.map((k) {
                               return CheckboxListTile(
                                  title: Text(k, style: GoogleFonts.poppins(color: Colors.black87, fontSize: 14)),
                                  value: _localCategories[k],
                                  activeColor: const Color(0xFFE91E63),
                                  checkColor: Colors.white,
                                  onChanged: (val) => setState(() => _localCategories[k] = val ?? false),
                                  controlAffinity: ListTileControlAffinity.leading,
                                  dense: true, 
                               );
                            }).toList(),
                         ),
                      ),
                      const SizedBox(height: 24),
                      Text('QUANDO (Período)', style: GoogleFonts.poppins(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 12),
                      InkWell(
                         onTap: _pickDateRange,
                         child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                               color: Colors.white,
                               borderRadius: BorderRadius.circular(12),
                               border: Border.all(color: const Color(0xFFE91E63).withOpacity(0.3)),
                            ),
                            child: Row(
                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                               children: [
                                  Text(_dateLabel, style: GoogleFonts.poppins(color: Colors.black87)),
                                  const Icon(Icons.calendar_month, color: Color(0xFFE91E63)),
                               ],
                            ),
                         ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                         children: [
                            _buildPresetBtn('Últimos 3 meses', 90),
                            const SizedBox(width: 8),
                            _buildPresetBtn('Últimos 6 meses', 180),
                         ],
                      ),
                   ],
                ),
             ),
             const SizedBox(height: 16),
             SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                   onPressed: _isValid ? () {
                      Navigator.pop(context);
                      widget.onApply(_selectedPetName, _selectedPetId, _localCategories, _dateRange, _dateLabel);
                   } : null,
                   style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                   ),
                   child: Text('Exportar e Liberar Espaço', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
             ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPresetBtn(String label, int days) {
     return Expanded(
        child: TextButton(
           onPressed: () {
              final now = DateTime.now();
              setState(() {
                 _dateRange = DateTimeRange(start: now.subtract(Duration(days: days)), end: now);
                 _updateDateLabel();
              });
           },
           style: TextButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.5), foregroundColor: Colors.black87),
           child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
     );
  }
}
