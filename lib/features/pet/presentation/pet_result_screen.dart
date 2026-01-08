import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pet_analysis_result.dart';
import '../services/pet_analysis_service.dart';
import '../../../core/enums/scannut_mode.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/pet_profile_extended.dart';
import 'widgets/edit_pet_form.dart';
import 'widgets/pet_analysis_details_view.dart';
import '../services/pet_profile_service.dart';
import '../../../core/services/history_service.dart';
import '../../../core/services/file_upload_service.dart';
import '../../../core/widgets/pro_access_wrapper.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../../core/theme/app_design.dart';
import '../../../l10n/app_localizations.dart';

final petResultProvider = StateProvider<PetAnalysisResult?>((ref) => null);

class PetResultScreen extends ConsumerStatefulWidget {
  final File imageFile;
  final PetAnalysisResult? existingResult;
  final bool isHistoryView;

  const PetResultScreen({
    Key? key, 
    required this.imageFile,
    this.existingResult,
    this.isHistoryView = false,
  }) : super(key: key);

  @override
  ConsumerState<PetResultScreen> createState() => _PetResultScreenState();
}

class _PetResultScreenState extends ConsumerState<PetResultScreen> {
  bool _isLoading = true;
  File? _permanentImage;
  bool _autoSaveAttempted = false; // Flag to prevent duplicate saves

  @override
  void initState() {
    super.initState();
    if (widget.existingResult != null) {
       // If existing result is passed (Observation or History), use it directly
       // Skip auto-save if history view (already saved)
       if (!widget.isHistoryView && !_autoSaveAttempted) {
          _autoSaveAttempted = true;
          _performAutoSave(widget.existingResult!);
       }
       
       WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(petResultProvider.notifier).state = widget.existingResult;
          setState(() { 
              _isLoading = false; 
          });
       });
    } else {
      // New Analysis
      _analyzeImage();
    }
  }

  Future<void> _analyzeImage() async {
    try {
      final service = ref.read(petAnalysisServiceProvider);
      final result = await service.analyzePet(widget.imageFile, ScannutMode.petIdentification);
      
      // 📸 MOVER PARA PERMANENTE IMEDIATAMENTE (Organizado por Pet)
      try {
          final fileService = FileUploadService();
          final savedPath = await fileService.saveMedicalDocument(
            file: widget.imageFile,
            petName: result.petName ?? 'Unknown',
            attachmentType: 'analysis',
          );
          
          if (savedPath != null) {
              _permanentImage = File(savedPath);
              debugPrint('✅ Imagem salva permanentemente via FileService: $savedPath');
          } else {
              _permanentImage = widget.imageFile;
          }
      } catch (e) {
          debugPrint('⚠️ Erro ao mover imagem para permanente: $e');
          _permanentImage = widget.imageFile; // Fallback
      }

      // AUTO-SAVE LOGIC
      if (!_autoSaveAttempted) {
         _autoSaveAttempted = true;
         // Perform silent background save
         _performAutoSave(result);
      }

      if (mounted) {
        ref.read(petResultProvider.notifier).state = result;
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(petResultProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppDesign.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppDesign.textPrimaryDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l10n.petResultTitle, style: const TextStyle(color: AppDesign.textPrimaryDark, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: AppDesign.petPink),
            tooltip: l10n.petResultGeneratePDF,
            onPressed: () => _generatePDF(context, result),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActionBar(context, result),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppDesign.petPink))
          : result == null
              ? Center(child: Text(l10n.errorGeneric, style: const TextStyle(color: AppDesign.textPrimaryDark)))
              : PetAnalysisDetailsView(
                  result: result,
                  imageFile: _permanentImage ?? widget.imageFile,
                ),
    );
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildBottomActionBar(BuildContext context, PetAnalysisResult? result) {
     if (result == null || _isLoading) return const SizedBox.shrink();
     final l10n = AppLocalizations.of(context)!;

     return Container(
       padding: const EdgeInsets.all(16) + const EdgeInsets.only(bottom: 12),
       decoration: const BoxDecoration(
         color: AppDesign.surfaceDark,
         border: Border(top: BorderSide(color: Colors.white10)),
       ),
       child: SafeArea(
         child: Row(
           children: [
             Expanded(
               child: widget.isHistoryView 
               ? ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, size: 20),
                  label: Text(l10n.commonBack ?? 'Voltar', style: const TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white10,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                 )
               : ElevatedButton(
                 onPressed: () => _handleAutoSaveAndNav(context, result),
                 style: ElevatedButton.styleFrom(
                   backgroundColor: AppDesign.petPink,
                   foregroundColor: Colors.white,
                   padding: const EdgeInsets.symmetric(vertical: 16),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                   elevation: 4,
                 ),
                 child: Text(l10n.petResultViewProfile, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
               ),
             ),
             const SizedBox(width: 12),
             IconButton(
               onPressed: () => _generatePDF(context, result),
               icon: const Icon(Icons.picture_as_pdf, color: AppDesign.petPink),
               style: IconButton.styleFrom(
                 backgroundColor: Colors.white10,
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                 padding: const EdgeInsets.all(12)
               ),
             ),
           ],
         ),
       ),
     );
  }



  // --- LOGIC ---

  void _generatePDF(BuildContext context, PetAnalysisResult? result) async {
     final l10n = AppLocalizations.of(context)!;
     // TODO: Implement PDF generation using ExportService
     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.petGeneratingPDF)));
  }

  void _handleAutoSaveAndNav(BuildContext context, PetAnalysisResult? result) async {
       if (result == null) return;
       // We rely on initial auto-save.
       // But to be robust, we can double-check if we need to ensure profile existence
       
       // Just Navigate logic
       final imagePathToUse = _permanentImage?.path ?? widget.imageFile.path;
       final profile = PetProfileExtended.fromAnalysisResult(result, imagePathToUse);
       
       if (context.mounted) {
           Navigator.push(
              context, 
              MaterialPageRoute(
                  builder: (_) => EditPetForm(
                      existingProfile: profile,
                      isNewEntry: false, 
                      onSave: (updated) async {
                          final ps = PetProfileService(); await ps.init();
                          await ps.saveOrUpdateProfile(updated.petName, updated.toJson());
                      }
                  )
              )
           );
       }
  }

  Future<void> _performAutoSave(PetAnalysisResult result) async {
    try {
      final imagePathToUse = _permanentImage?.path ?? widget.imageFile.path;
      // result.imagePath = imagePathToUse; // Removed as field does not exist
      final profile = PetProfileExtended.fromAnalysisResult(result, imagePathToUse);

      final profileService = PetProfileService();
      await profileService.init();
      // Auto-save logic: Save/Update profile and Add to History
      await profileService.saveOrUpdateProfile(profile.petName, profile.toJson());

      final historyService = HistoryService();
      await historyService.savePetAnalysis(
        profile.petName, 
        profile.rawAnalysis ?? {}, 
        imagePath: profile.imagePath
      );
      
      final box = await HistoryService.getBox();
      if (box.isOpen) await box.flush();
      
      debugPrint("✅ Auto-Save completed for ${profile.petName}");
    } catch (e) {
      debugPrint("❌ Auto-Save failed: $e");
      if (mounted) {
         // Subtle error feedback only
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Falha no salvamento automático. Tente novamente.'), backgroundColor: AppDesign.warning, duration: const Duration(seconds: 2))
         );
      }
    }
  }
}
