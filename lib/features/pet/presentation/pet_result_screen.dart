import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pet_analysis_result.dart';
import '../services/pet_analysis_service.dart';
import '../../../core/enums/scannut_mode.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/pet_profile_extended.dart';
import 'widgets/edit_pet_form.dart';
import 'widgets/pet_dossier_view.dart';
import '../services/pet_profile_service.dart';
import '../../../core/services/history_service.dart';
import '../../../core/services/file_upload_service.dart';
import '../../../core/widgets/pro_access_wrapper.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../../core/theme/app_design.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/services/media_vault_service.dart';
import '../services/pet_indexing_service.dart';

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
      
      // 🔐 VACUUM VAULT: Move to Secure Storage immediately
      try {
          final vault = MediaVaultService();
          final petNameForPath = result.petName ?? 'Unknown_${DateTime.now().millisecondsSinceEpoch}';
          final savedPath = await vault.secureClone(
              widget.imageFile, 
              MediaVaultService.PETS_DIR, 
              petNameForPath
          );
          
          _permanentImage = File(savedPath);
          debugPrint('✅ Vault Secure Save: $savedPath');
      } catch (e) {
          debugPrint('⚠️ Vault Save Failed: $e');
          _permanentImage = widget.imageFile; // Fallback to cache (better than nothing)
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
      // AppBar and BottomNavBar are now handled inside PetDossierView for better layout control
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppDesign.petPink))
          : result == null
              ? Center(child: Text(l10n.errorGeneric, style: const TextStyle(color: AppDesign.textPrimaryDark)))
              : PetDossierView(
                  analysis: result,
                  imagePath: _permanentImage?.path ?? widget.imageFile.path,
                  petName: result.petName,
                  onSave: () => _performAutoSave(result),
                  onGeneratePDF: () => _generatePDF(context, result),
                  onViewProfile: () => _handleAutoSaveAndNav(context, result),
                ),
    );
  }

  // --- WIDGET COMPONENTS ---


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
      
      // 🧠 AUTOMATIC INDEXING (MARE Logic)
      try {
        final indexer = PetIndexingService();
        await indexer.indexAiAnalysis(
          petId: profile.petName, // Using name as ID if no profile ID yet
          petName: profile.petName,
          analysisType: result.analysisType ?? 'Identificação',
          resultId: DateTime.now().millisecondsSinceEpoch.toString(),
          localizedTitle: AppLocalizations.of(context)!.petIndexing_aiTitle(result.analysisType ?? 'Identificação'),
          localizedNotes: AppLocalizations.of(context)!.petIndexing_aiNotes,
        );
      } catch (e) {
        debugPrint("⚠️ Indexing failed: $e");
      }

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
