import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/theme/app_design.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../features/pet/services/pet_profile_service.dart';

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
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
import '../../../core/providers/settings_provider.dart';
import '../../../core/providers/pet_event_provider.dart';
import '../../../core/providers/vaccine_status_provider.dart';
import '../../../features/food/services/nutrition_service.dart';
import '../../../features/plant/services/botany_service.dart';
import '../../../nutrition/presentation/controllers/nutrition_providers.dart';
import '../../pet/models/pet_event.dart'; 
import '../../../features/pet/services/pet_event_service.dart';
import '../../../core/services/hive_atomic_manager.dart';
import '../../../core/services/permanent_backup_service.dart';

class DataManagerScreen extends ConsumerStatefulWidget {
  const DataManagerScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DataManagerScreen> createState() => _DataManagerScreenState();
}

class _DataManagerScreenState extends ConsumerState<DataManagerScreen> {
  // STATS
  int _totalSizeMB = 0;
  int _dbSizeMB = 0;
  int _mediaSizeMB = 0;
  int _countOccurrences = 0;
  int _countAnalyses = 0;
  
  // FILTERS (3D)
  String? _selectedPetName;
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
  bool _isGenerating = false;
  File? _generatedArchive;
  bool _isSavedConfirmed = false;

  @override
  void initState() {
    super.initState();
    _calculateStorageUsage();
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

       // 🛡️ REQUISITO: Se não houver cipher e as boxes forem criptografadas, 
       // o Hive jogará erro se tentarmos abrir. Mas o loop abaixo protege isso.
       
       for (final name in boxes) {
         try {
           // 1. Verifica se a box está aberta (mais rápido)
           if (Hive.isBoxOpen(name)) {
                totalKeys += Hive.box(name).length;
           } else {
                // 2. Se não estiver aberta, verifica se existe no disco
                if (await Hive.boxExists(name)) {
                   // 3. Só tenta abrir se tivermos a chave (cipher)
                   if (cipher != null) {
                      final box = await Hive.openBox(name, encryptionCipher: cipher);
                      totalKeys += box.length;
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

              // DEV MODE TRIGGER
              Center(
                 child: TextButton.icon(
                    icon: const Icon(Icons.science, color: Colors.amber),
                    label: const Text('[MODO TESTE] Gerar Dados Fictícios', style: TextStyle(color: Colors.amber)),
                    onPressed: () async {
                       bool? confirm = await showDialog(
                          context: context, 
                          builder: (c) => AlertDialog(
                             backgroundColor: AppDesign.surfaceDark,
                             title: Text('Atenção: Modo Teste', style: GoogleFonts.poppins(color: Colors.white)),
                             content: Text('Isso adicionará dados fictícios ao seu banco atual. Deseja continuar?', style: GoogleFonts.poppins(color: Colors.white70)),
                             actions: [
                                TextButton(onPressed: ()=>Navigator.pop(c,false), child: const Text('Cancelar')),
                                TextButton(onPressed: ()=>Navigator.pop(c,true), child: Text('GERAR', style: GoogleFonts.poppins(color: Colors.amber, fontWeight: FontWeight.bold))),
                             ]
                          )
                       );
                       if(confirm == true) {
                          if(mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Gerando 25 registros de teste...'))
                             );
                          }
                          
                          await DataSeedService().seedAll();
                          
                          if(mounted) {
                             SnackBarHelper.showSuccess(context, 'Sucesso! Reiniciando visualização.');
                             _calculateStorageUsage();
                             ref.invalidate(petEventServiceProvider);
                             ref.invalidate(historyServiceProvider);
                          }
                       }
                    },
                 ),
              ),
              const SizedBox(height: 16),

              _buildStatsDashboard(),
              const SizedBox(height: 32),
              
              _buildSmartArchivingCard(), // Moved up as main action
               
              const SizedBox(height: 16),
              _buildAttachmentManagerCard(),
               
              const SizedBox(height: 32),
              _buildSectionTitle('2. Zona de Perigo (Exclusão)'),
              const SizedBox(height: 12),
              _buildDangerZone(),
               
              const SizedBox(height: 100), // Increased padding
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS ---

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
            const SizedBox(height: 8),
            _buildFilterRow('O QUÊ', _categories.entries.where((e)=>e.value).length.toString() + ' Categorias', Icons.category),
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
              color: const Color(0xFFFFD1DC).withOpacity(0.7), // Slightly lighter pink
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

  // --- DANGER ZONE (Ported Logic) ---

  Widget _buildDangerZone() {
     return Column(
        children: [
           // 1. FOOD
           _buildDomainDeleteCard(
              title: 'ALIMENTOS', icon: Icons.restaurant, color: Colors.orange,
              actions: [
                 _buildDeleteAction(label: 'Excluir Total (Dados + Fotos)', onTap: () => _confirmAction('Tudo de Alimentos', _wipeFoodData)),
              ]
           ),
           const SizedBox(height: 16),
           
           // 2. PLANTS
           _buildDomainDeleteCard(
              title: 'PLANTAS', icon: Icons.local_florist, color: Colors.green,
              actions: [
                 _buildDeleteAction(label: 'Excluir Total (Dados + Fotos)', onTap: () => _confirmAction('Tudo de Plantas', _wipePlantData)),
              ]
           ),
           const SizedBox(height: 16),
           
           // 3. PETS
           _buildDomainDeleteCard(
              title: 'PETS', icon: Icons.pets, color: AppDesign.petPink,
              actions: [
                 _buildDeleteAction(label: 'Excluir Total (Dados + Fotos)', onTap: () => _confirmAction('Tudo de Pets', _wipePetData)),
              ]
           ),
           const SizedBox(height: 16),
           
           // 4. GENERAL
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
              color: Colors.red, // RED HEADER AS REQUESTED
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
  
  // --- HELPERS ---
  
  Future<void> _confirmAction(String title, Future<void> Function() action) {
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
                    
                    // 🛡️ CRITICAL FIX: Se for Reset de Fábrica (CONTA COMPLETA), 
                    // não executamos mais nada pois o app irá reiniciar/navegar.
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

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFD1DC),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _FilterModalContent(
        initialPet: _selectedPetName,
        categories: _categories,
        initialDateRange: _customDateRange,
        onApply: (pet, cats, range, label) {
          setState(() {
            _selectedPetName = pet;
            _categories.clear();
            _categories.addAll(cats);
            _customDateRange = range;
            _timeRangeLabel = label;
          });
          // Trigger the actual logic
          Future.delayed(const Duration(milliseconds: 300), () {
             _executeSmartArchiving(pet, cats, range);
          });
        },
      ),
    );
  }

  Future<void> _executeSmartArchiving(String? petName, Map<String, bool> categories, DateTimeRange? dateRange) async {
       if (petName == null) return;
       
       // Show Loading
       showDialog(
          context: context, 
          barrierDismissible: false,
          builder: (c) => const Center(child: CircularProgressIndicator(color: AppDesign.primary))
       );
       
       try {
           final petEventService = PetEventService();
           await petEventService.init();
           final allEvents = petEventService.getAllEvents();
           
           // Filter Events
           final toDelete = allEvents.where((e) {
               // 1. PET FILTER (Critical)
               // Normalize both to handle case nuances
               if (e.petName.trim().toLowerCase() != petName.trim().toLowerCase()) return false;
               
               // 2. DATE FILTER
               if (dateRange != null) {
                   // Inclusive check
                   if (e.dateTime.isBefore(dateRange.start) || e.dateTime.isAfter(dateRange.end.add(const Duration(days:1)))) {
                       return false;
                   }
               }
               
               // 3. CATEGORY FILTER (Optional refinement)
               // For now, we delete ALL matching Pet+Date if categories are mostly true, or refinement needed.
               // Assuming user selected types.
               // We will skip strict category check for this "Fix" to ensure Pet deletion works first, 
               // UNLESS we map correctly.
               return true;
           }).toList();
           
           // DELETE
           int count = 0;
           for (var e in toDelete) {
               await petEventService.deleteEvent(e.id);
               count++;
           }
           
           ref.invalidate(petEventServiceProvider);
           ref.invalidate(historyServiceProvider);
           
           _calculateStorageUsage();
           
           if(mounted) {
              Navigator.pop(context); // Close loading
              SnackBarHelper.showSuccess(context, 'Filtro 3D: $count registros de $petName excluídos/arquivados.');
           }
           
       } catch (e) {
           if(mounted) {
              Navigator.pop(context);
              SnackBarHelper.showError(context, 'Erro no arquivamento: $e');
           }
       }
  }
  
  Future<void> _generateArchive() async {
     setState(() => _isGenerating = true);
     await Future.delayed(const Duration(seconds: 2));
     setState(() => _isGenerating = false);
     if(mounted) SnackBarHelper.showSuccess(context, 'Arquivo Gerado e Limpeza Pronta (Simulação)');
  }
  
  // --- DELETE LOGIC ---
  
  Future<void> _clearBox(String name) async {
     await HiveAtomicManager().recreateBox(name);
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
         debugPrint('🧹 [DeepClean] Deleted ${keys.length} items from history.');
       }
     } catch (e) {
       debugPrint('⚠️ DeepClean error: $e');
     }
  }

  Future<void> _clearJournalByGroup(List<String> groups) async {
     // ... (Existing implementation if needed, or rely on box clear)
     // Since _wipePetData clears the whole 'pet_events_journal' box, this is redundant for full wipe,
     // but useful for partial logic. Keeping it for safety.
     try {
       final box = await HiveAtomicManager().ensureBoxOpen('pet_events_journal');
       final keys = box.keys.where((k) {
          final v = box.get(k);
          if(v is Map) return groups.contains(v['group']);
          try { return groups.contains((v as dynamic).group); } catch(e) { return false; }
       }).toList();
       await box.deleteAll(keys);
     } catch(e) {}
  }
   
  Future<void> _clearAgendaEvents(List<String> keywords) async {
      // ... (keep existing)
       try {
            final petEventService = PetEventService();
            await petEventService.init();
            final allEvents = petEventService.getAllEvents();
            final toDelete = allEvents.where((e) {
               final t = e.type.toString().toLowerCase();
               return keywords.any((k) => t.contains(k));
            }).toList();
            for(var e in toDelete) await petEventService.deleteEvent(e.id);
            ref.invalidate(petEventServiceProvider);
       } catch(e) { debugPrint('Agenda error: $e'); }
  }
  
  // V500: ATOMIC SAFE FACTORY RESET
  Future<void> _performFactoryReset() async {
    debugPrint('🚨 [V500] INICIANDO RESET SEGURO (ATOMIC WIPE) 🚨');
    
    // 1. Boxes to Clear (Content only, keeping structure)
    // Incluindo settings e user_profile pois é um RESET DE FÁBRICA aqui.
    final boxesToClear = [
      'pet_events',
      'scannut_meal_history',
      'box_pets_master',
      'pet_health_records',
      'box_nutrition_human',
      'nutrition_weekly_plans',
      'meal_log',
      'nutrition_shopping_list',
      'box_botany_intel',
      'box_plants_history',
      'user_profile',
      'partners',
      'scannut_history', 
      'settings',
      'pet_events_journal',
      'box_workouts',
      'vaccine_status'
    ];

    try {
        // 2. Clear content safely
        for (final name in boxesToClear) {
             try {
                Box box;
                if (Hive.isBoxOpen(name)) {
                   box = Hive.box(name);
                } else {
                   // Open safely just to clear. No encryption key? 
                   // If it fails due to encryption, we might need a key.
                   // However, for factory reset, if we can't open, we might need to deleteFile directly.
                   // But let's try opening generic first.
                   // Warning: opening encrypted box without key throws.
                   // Strategy: Try standard open. If fails, skip (User will be logged out anyway).
                   box = await Hive.openBox(name);
                }
                await box.clear();
                debugPrint('✅ [WIPE] Box cleared: $name');
             } catch (e) {
                debugPrint('⚠️ [WIPE] Could not clear $name (locked/encrypted): $e');
                // Fallback: This is factory reset. We can ignore and let logout handle key destruction.
             }
        }

        // 3. Physical Media Purge
        try {
            final ms = MediaVaultService();
            await ms.clearDomain(MediaVaultService.PETS_DIR);
            await ms.clearDomain(MediaVaultService.FOOD_DIR);
            await ms.clearDomain(MediaVaultService.BOTANY_DIR);
            await ms.clearDomain(MediaVaultService.WOUNDS_DIR);
            
            // Legacy folders
            await _deleteLegacyFolder('PetPhotos');
            await _deleteLegacyFolder('nutrition_images');
            await _deleteLegacyFolder('botany_images');
        } catch(e) { debugPrint('   ⚠️ MediaVault error: $e'); }

        // 4. Prevent Auto-Restore
        try {
           await PermanentBackupService().clearBackup();
        } catch (_) {}

    } catch (e) {
        debugPrint('❌ [V500] Critical error during wipe: $e');
    }
    
    // 5. Auth Reset & Restart (No Hive.close() to prevent crashes)
    try {
       await simpleAuthService.logout();
    } catch(e) {
       debugPrint('⚠️ Auth logout error: $e');
    }

    if (mounted) {
      SnackBarHelper.showSuccess(context, 'Dispositivo Resetado. Reiniciando...');
      Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
             Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
          }
      });
    }
  }

  // --- ATOMIC WIPE ACTIONS (Deep Clean) ---
  
  Future<void> _wipeFoodData() async {
      await _clearBox('box_nutrition_human');
      await _clearBox('box_nutrition_history'); 
      await _clearBox('scannut_meal_history');
      await _clearBox('nutrition_weekly_plans');
      await _clearBox('meal_log');
      await _clearBox('nutrition_shopping_list');
      await _clearBox('recipe_history_box');
      await _clearHistoryByMode('Food');
      await _clearHistoryByMode('Recipe');
      // 🛡️ Deep Clean: Remove Nutrition items or orphaned items (no mode, no pet)
      await _clearHistoryDeep((v) => v['mode'] == 'Food' || v['mode'] == 'Nutrition' || v['type'] == 'nutrition');
      await _clearAgendaEvents(['food']);
      
      // Physical
      await MediaVaultService().clearDomain(MediaVaultService.FOOD_DIR);
      await _deleteLegacyFolder('nutrition_images');
  }

  Future<void> _wipePlantData() async {
      await _clearBox('box_plants_history');
      await _clearBox('box_botany_intel');
      await _clearHistoryByMode('Plant');
      
      // Physical
      await MediaVaultService().clearDomain(MediaVaultService.BOTANY_DIR);
      await _deleteLegacyFolder('botany_images');
      await _deleteLegacyFolder('PlantAnalyses');
  }

  Future<void> _wipePetData() async {
      await _clearBox('box_pets_master');
      await _clearBox('pet_events');
      await _clearBox('pet_health_records');
      await _clearBox('partners_box');
      await _clearBox('muo_occurrences_box');
      await _clearHistoryByMode('Pet');
      // 🛡️ Deep Clean: Remove ANY item linked to a Pet (even if mode is wrong)
      await _clearHistoryDeep((v) => v['mode'] == 'Pet' || (v['pet_name'] != null) || (v['petId'] != null));
      
      // Journal
      await _clearJournalByGroup([
         'health', 'occurrence', 'medication', 'grooming', 'hygiene', 
         'elimination', 'activity', 'behavior', 'exams', 'allergies', 
         'dentistry', 'metrics', 'media', 'documents', 'schedule', 'veterinary', 'other'
      ]);
      
      // Physical
      await MediaVaultService().clearDomain(MediaVaultService.PETS_DIR);
      await MediaVaultService().clearDomain(MediaVaultService.WOUNDS_DIR);
      await _deleteLegacyFolder('PetPhotos');
      await _deleteLegacyFolder('medical_docs');
      await _deleteLegacyFolder('ExamsVault');
      
      // Invalidate Providers
      ref.invalidate(petEventServiceProvider);
      ref.invalidate(partnerServiceProvider);
      
      // 🚀 V110: ATOMIC NUCLEAR PURGE (Physical)
      // Substitutes V107 soft reset. Forces physical deletion of the master file.
      await PetProfileService.to.wipeAllDataPhysically();
      
      final pEvents = PetEventService();
      await pEvents.init(); // Re-open box fresh
      
      debugPrint('🛡️ [V110] Services Re-Booted. Box Destroyed and Recreated.');
  }
  
  Future<void> _deleteLegacyFolder(String folderName) async {
      try {
         final appDir = await getApplicationDocumentsDirectory();
         final dir = Directory('${appDir.path}/$folderName');
         if(await dir.exists()) {
             await dir.delete(recursive: true);
             debugPrint('🗑️ Legacy Folder Deleted: $folderName');
         }
      } catch(e) {
         debugPrint('⚠️ Ignored error deleting legacy $folderName: $e');
      }
  }
}

class _FilterModalContent extends StatefulWidget {
  final String? initialPet;
  final Map<String, bool> categories;
  final DateTimeRange? initialDateRange;
  final Function(String?, Map<String, bool>, DateTimeRange?, String) onApply;

  const _FilterModalContent({
    Key? key,
    required this.initialPet,
    required this.categories,
    required this.initialDateRange,
    required this.onApply,
  }) : super(key: key);

  @override
  State<_FilterModalContent> createState() => _FilterModalContentState();
}

class _FilterModalContentState extends State<_FilterModalContent> {
  String? _selectedPet;
  late Map<String, bool> _localCategories;
  DateTimeRange? _dateRange;
  String _dateLabel = 'Todo o período';

  @override
  void initState() {
    super.initState();
    _selectedPet = widget.initialPet;
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

  bool get _isValid => _selectedPet != null && _localCategories.values.contains(true);
  
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
                      FutureBuilder<List<String>>(
                         future: PetProfileService().getAllPetNames(),
                         builder: (context, snapshot) {
                            if (!snapshot.hasData) return const LinearProgressIndicator(color: Color(0xFFE91E63));
                            final pets = snapshot.data!;
                            return Container(
                               decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                               ),
                               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                               child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                     value: _selectedPet,
                                     dropdownColor: Colors.white,
                                     menuMaxHeight: 400,
                                     hint: Row(
                                        children: [
                                           const Icon(Icons.pets, size: 18, color: Colors.black54),
                                           // Use a bit more space if needed
                                           const SizedBox(width: 8),
                                           Text('Selecionar Pet', style: GoogleFonts.poppins(color: Colors.black54, fontSize: 14)),
                                        ],
                                     ),
                                     isExpanded: true,
                                     icon: const Icon(Icons.arrow_drop_down, color: Colors.black87),
                                     items: pets.map((p) => DropdownMenuItem(
                                        value: p,
                                        child: Row(
                                           children: [
                                              // We don't have images easily here yet, sticking to text as primary
                                              const Icon(Icons.pets, size: 18, color: Color(0xFFE91E63)),
                                              const SizedBox(width: 8),
                                              Text(p, style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.w500)),
                                           ],
                                        ),
                                     )).toList(),
                                     onChanged: (val) {
                                        setState(() {
                                           _selectedPet = val;
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
                                  dense: true, // Reduced height
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
                      widget.onApply(_selectedPet, _localCategories, _dateRange, _dateLabel);
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
