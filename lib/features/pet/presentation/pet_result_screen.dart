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
import '../models/analise_ferida_model.dart'; // 🛡️ V170 Import
import '../models/analise_fezes_model.dart'; // 🛡️ V231 Import
import '../services/pet_profile_service.dart';
import '../../../core/services/history_service.dart';
import '../../../core/utils/json_cast.dart';
import '../../../core/services/file_upload_service.dart';
import '../../../core/widgets/pro_access_wrapper.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../../core/theme/app_design.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/services/media_vault_service.dart';
import '../services/pet_indexing_service.dart';

import '../../../core/services/export_service.dart';
import '../../../core/widgets/pdf_preview_screen.dart';

final petResultProvider = StateProvider<PetAnalysisResult?>((ref) => null);

class PetResultScreen extends ConsumerStatefulWidget {
  final File imageFile;
  final PetAnalysisResult? existingResult;
  final bool isHistoryView;
  final ScannutMode mode;

  const PetResultScreen({
    Key? key, 
    required this.imageFile,
    this.existingResult,
    this.isHistoryView = false,
    this.mode = ScannutMode.petIdentification,
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
      final result = await service.analyzePet(widget.imageFile, widget.mode);
      
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
                  onSave: () {
                    if (!_autoSaveAttempted) {
                         _autoSaveAttempted = true;
                        _performAutoSave(result);
                    }
                },

                  onGeneratePDF: () => _generatePDF(context, result),
                  onViewProfile: () => _handleAutoSaveAndNav(context, result),
                ),
    );
  }

  // --- WIDGET COMPONENTS ---


  // --- LOGIC ---

  void _generatePDF(BuildContext context, PetAnalysisResult? result) async {
     if (result == null) return;
     final l10n = AppLocalizations.of(context)!;
     final imagePathToUse = _permanentImage?.path ?? widget.imageFile.path;
     
     // 🛡️ V116: AUDIT LOG
     debugPrint('📄 [V116-PDF] Preparando exportação PDF para ${result.petName ?? "Pet"}');
     
     Navigator.push(
       context,
       MaterialPageRoute(
         builder: (context) => PdfPreviewScreen(
           title: 'Relatório Vet 360 - ${result.petName ?? "Pet"}',
           buildPdf: (format) async {
             final exportService = ExportService();
             
             // 🛡️ V180 POINTER TO HISTORY
             final profileService = PetProfileService();
             await profileService.init();
             PetProfileExtended? fullProfile;
             try {
                 final pData = await profileService.getProfile(result.petName ?? '');
                 if (pData != null && pData['data'] != null) {
                      fullProfile = PetProfileExtended.fromJson(deepCastMap(pData['data']));
                 }
             } catch (e) {
                 debugPrint('⚠️ Helper Profile Load Error: $e');
             }

             final pdf = await exportService.generateVeterinary360Report(
               analysis: result, 
               imagePath: imagePathToUse, 
               strings: l10n,
               profile: fullProfile, // 🛡️ V180
             );
             return pdf.save();
           },
         ),
       ),
     );
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
      final profileService = PetProfileService();
      await profileService.init();

      // 🛡️ V220: FIX - Ensure Valid Pet Name
      final String safePetName = (result.petName != null && result.petName!.trim().isNotEmpty) 
          ? result.petName! 
          : 'Pet';

      // 🛡️ V220: SEPARATION OF DOMAINS (Identity vs Health vs Stool)
      if (result.analysisType == 'stool_analysis') {
           // STOOL DOMAIN: SPECIALIZED COPROLOGICAL ANALYSIS
           debugPrint('💩 [V231] Persisting Stool Analysis (Fezes Category)');
           
           if (!await profileService.hasProfile(safePetName)) {
               debugPrint('   [V231] Profile "$safePetName" not found. Creating skeleton profile...');
               final newProfile = PetProfileExtended.fromAnalysisResult(result, imagePathToUse);
               final jsonProfile = newProfile.toJson();
               jsonProfile['pet_name'] = safePetName;
               await profileService.saveOrUpdateProfile(safePetName, jsonProfile);
           }

           // A. Save to Master History (Timeline)
           final historyPayload = result.toJson();
           historyPayload['pet_name'] = safePetName;
           await HistoryService.addScan(
             'Pet', 
             historyPayload, 
             imagePath: imagePathToUse,
             thumbnailPath: imagePathToUse,
             petName: safePetName
           );

           // B. Save to Structured Stool History
           final stoolAnalysis = AnaliseFezesModel(
              dataAnalise: DateTime.now(), 
              imagemRef: imagePathToUse, 
              caracteristicas: result.caracteristicas,
              descricaoVisual: result.descricaoVisual,
              stoolDetails: result.stoolAnalysis ?? {},
              possiveisCausas: result.possiveisCausas,
              nivelRisco: result.urgenciaNivel, 
              recomendacao: result.orientacaoImediata,
           );
           
           await profileService.saveStoolAnalysis(safePetName, stoolAnalysis);

      } else if (result.analysisType == 'diagnosis') {
           // HEALTH DOMAIN: DO NOT OVERWRITE PROFILE IMAGE
           debugPrint('🏥 [V220] Persisting Health Analysis (No Profile Image Overwrite)');
           
           // 🛡️ CRITICAL FIX: Ensure Profile Exists
           // If we don't have a profile for this pet (e.g. new scan), create a basic one
           // using the current image. It's better to have a profile with a wound image
           // than no profile/history at all.
           if (!await profileService.hasProfile(safePetName)) {
               debugPrint('   [V220] Profile "$safePetName" not found. Creating skeleton profile...');
               final newProfile = PetProfileExtended.fromAnalysisResult(result, imagePathToUse);
               
               // Ensure correct name in ID
               final jsonProfile = newProfile.toJson();
               jsonProfile['pet_name'] = safePetName;
               
               await profileService.saveOrUpdateProfile(safePetName, jsonProfile);
           }
           
           // A. Save to History Line (Timeline)
           debugPrint('📜 [PetResult] Saving to History (Detailed Diagnosis)... (mode: Pet)');
           
           // 🛡️ V221: Force Name Injection for History Consistency
           final historyPayload = result.toJson();
           historyPayload['pet_name'] = safePetName; // Ensure explicit link
           
           await HistoryService.addScan(
             'Pet', 
             historyPayload, 
             imagePath: imagePathToUse,
             thumbnailPath: imagePathToUse,
             petName: safePetName // Explicit Argument
           );

           // B. Save to Structured Profile History (Wounds)
           final healthAnalysis = AnaliseFeridaModel(
              dataAnalise: DateTime.now(), 
              imagemRef: imagePathToUse, // Use the wound image here
              achadosVisuais: result.category == 'olhos' ? (result.eyeDetails ?? {}) :
                           result.category == 'dentes' ? (result.dentalDetails ?? {}) :
                           result.category == 'pele' ? (result.skinDetails ?? {}) :
                           result.category == 'ferida' ? (result.woundDetails ?? {}) :
                           (result.clinicalSignsDiag ?? {}), 
            categoria: result.category,
              nivelRisco: result.urgenciaNivel, 
              recomendacao: result.orientacaoImediata,
              diagnosticosProvaveis: result.possiveisCausas,
              rawClinicalSigns: result.clinicalSignsDiag != null ? {'clinical_signs': result.clinicalSignsDiag} : null,
              descricaoVisual: result.descricaoVisual,
              caracteristicas: result.caracteristicas,
           );
           
           // This method appends to the history list inside the profile without touching the main image
           await profileService.saveDetailedAnalysis(safePetName, healthAnalysis);

      } else {
           // IDENTITY DOMAIN: SAVE/UPDATE PROFILE & IMAGE
           debugPrint('🐾 [V220] Persisting Identity (Profile Update)');
           
           // Standard update
           final profile = PetProfileExtended.fromAnalysisResult(result, imagePathToUse);
           final jsonProfile = profile.toJson();
           
           // Ensure name consistency
           jsonProfile['pet_name'] = safePetName;
           
           await profileService.saveOrUpdateProfile(safePetName, jsonProfile);
           
           // Also save to generic history
           debugPrint('📜 [PetResult] Saving to History (Identity)... (mode: Pet)');
           await HistoryService.addScan(
             'Pet', 
             result.toJson(), 
             imagePath: imagePathToUse,
             thumbnailPath: imagePathToUse
           );
      }
      
      final box = await HistoryService.getBox();
      if (box.isOpen) await box.flush();
      
      // 🧠 AUTOMATIC INDEXING (MARE Logic)
      try {
        final indexer = PetIndexingService();
        await indexer.indexAiAnalysis(
          petId: result.petName ?? 'Unknown', 
          petName: result.petName ?? 'Unknown',
          analysisType: result.analysisType,
          resultId: DateTime.now().millisecondsSinceEpoch.toString(),
          localizedTitle: AppLocalizations.of(context)!.petIndexing_aiTitle(result.analysisType),
          localizedNotes: result.urgenciaNivel,
        );
      } catch (e) {
        debugPrint("⚠️ Indexing failed: $e");
      }

      debugPrint("✅ Auto-Save completed for ${result.petName}");
    } catch (e) {
      debugPrint("❌ Auto-Save failed: $e");
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Falha no salvamento automático: $e'), backgroundColor: AppDesign.warning)
         );
      }
    }
  }

  Map<String, dynamic> deepCastMap(dynamic data) {
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return {};
  }
}
