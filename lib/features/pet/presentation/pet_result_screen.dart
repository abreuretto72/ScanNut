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
import '../services/pet_profile_service.dart';
import '../../../core/services/file_upload_service.dart'; // Added
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

import '../services/pet_pdf_generator.dart';
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
     debugPrint('📄 [V116-PDF] Preparando exportação PDF (NOVO GERADOR) para ${result.petName ?? "Pet"}');
     
     Navigator.push(
       context,
       MaterialPageRoute(
         builder: (context) => PdfPreviewScreen(
           title: 'Relatório Vet 360 - ${result.petName ?? "Pet"}',
           buildPdf: (format) async {
             final generator = PetPdfGenerator();
             
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

             // Fallback: Create profile from current result if not found in DB
             fullProfile ??= PetProfileExtended.fromAnalysisResult(result, imagePathToUse);

             final pdf = await generator.generateReport(
               profile: fullProfile,
               strings: l10n,
               currentAnalysis: result,
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
       
       // 🛡️ V_FIX: Optimistic UI Update (Immediate History)
       // Add current analysis to profile history so it shows up in Edit Form immediately
       try {
            Map<String, dynamic> visualFindings = {};
            String cat = result.category?.toLowerCase() ?? '';
            
            if (cat == 'olhos') visualFindings = result.eyeDetails ?? {};
            else if (cat == 'dentes') visualFindings = result.dentalDetails ?? {};
            else if (cat == 'pele') visualFindings = result.skinDetails ?? {};
            else if (cat == 'ferida') visualFindings = result.woundDetails ?? {};
            else if (cat == 'fezes' || cat == 'stool' || result.analysisType == 'stool_analysis') {
               visualFindings = result.stoolAnalysis ?? {};
               if (cat.isEmpty) cat = 'fezes'; 
            } else {
               visualFindings = result.clinicalSignsDiag ?? {};
            }

            final healthAnalysis = AnaliseFeridaModel(
               dataAnalise: DateTime.now(), 
               imagemRef: imagePathToUse, 
               achadosVisuais: visualFindings.isNotEmpty ? visualFindings : (result.clinicalSignsDiag ?? {}),
               categoria: cat.isNotEmpty ? cat : 'geral',
               nivelRisco: result.urgenciaNivel, 
               recomendacao: result.orientacaoImediata,
               diagnosticosProvaveis: result.possiveisCausas,
               rawClinicalSigns: result.clinicalSignsDiag != null ? {'clinical_signs': result.clinicalSignsDiag} : null,
               descricaoVisual: result.descricaoVisual,
               caracteristicas: result.caracteristicas,
            );
            
            // Inject into profile (in-memory)
            profile.historicoAnaliseFeridas.add(healthAnalysis);
            
            // Legacy injection for robustness
            profile.woundAnalysisHistory.add({
                'date': DateTime.now().toIso8601String(),
                'imagePath': imagePathToUse,
                'visual_findings': healthAnalysis.achadosVisuais,
                'risk_level': healthAnalysis.nivelRisco,
                'recommendation': healthAnalysis.recomendacao
            });
            
       } catch (e) {
           debugPrint('⚠️ Optimistic update failed: $e');
       }
       
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
      final profileService = PetProfileService();
      await profileService.init();

      // 🛡️ V_FIX: Persist Image Permanently
      // If we rely on cache path, it gets deleted. saving explicitly.
      String imagePathToUse = _permanentImage?.path ?? widget.imageFile.path;
      if (_permanentImage == null) {
          try {
             final fs = FileUploadService();
             final savedPath = await fs.saveMedicalDocument(
                file: widget.imageFile,
                petName: result.petName ?? 'Unknown',
                attachmentType: 'health_${result.analysisType}_${DateTime.now().millisecondsSinceEpoch}'
             );
             if (savedPath != null) {
                imagePathToUse = savedPath;
                debugPrint('✅ [V_FIX] Image persisted to: $imagePathToUse');
                if (mounted) setState(() => _permanentImage = File(savedPath));
             }
          } catch (e) {
             debugPrint('❌ [V_FIX] Failed to persist image: $e');
          }
      }

      // 🛡️ V220: FIX - Ensure Valid Pet Name
      final String safePetName = (result.petName != null && result.petName!.trim().isNotEmpty) 
          ? result.petName! 
          : 'Pet';

      // 🛡️ V144: UNIFIED ROUTING - ALL CLINICAL/STOOL GOES TO WOUND HISTORY ('historicoAnaliseFeridas')
      if (result.analysisType == 'diagnosis' || result.analysisType == 'stool_analysis') {
           // HEALTH/STOOL DOMAIN: DO NOT OVERWRITE PROFILE IMAGE
           debugPrint('🏥 [V144] Persisting Unified Health Analysis (Includes Stool) to Wound History');
           
           // 🛡️ CRITICAL FIX: Ensure Profile Exists skeleton
           if (!await profileService.hasProfile(safePetName)) {
               debugPrint('   [V144] Profile "$safePetName" not found. Creating skeleton profile...');
               final newProfile = PetProfileExtended.fromAnalysisResult(result, imagePathToUse);
               final jsonProfile = newProfile.toJson();
               jsonProfile['pet_name'] = safePetName;
               await profileService.saveOrUpdateProfile(safePetName, jsonProfile);
           }
           
           // A. Save to History Line (Timeline - Generic)
           debugPrint('📜 [PetResult] Saving to Master History... (mode: Pet)');
           final historyPayload = result.toJson();
           historyPayload['pet_name'] = safePetName;
           
           await HistoryService.addScan(
             'Pet', 
             historyPayload, 
             imagePath: imagePathToUse,
             thumbnailPath: imagePathToUse,
             petName: safePetName
           );

           // B. Save to Structured Unified History (historicoAnaliseFeridas)
           // Logic to pick the correct specific details based on category
           Map<String, dynamic> visualFindings = {};
           
           // Priority: Category Tag (from Unified Prompt)
           String cat = result.category?.toLowerCase() ?? '';
           
           if (cat == 'olhos') visualFindings = result.eyeDetails ?? {};
           else if (cat == 'dentes') visualFindings = result.dentalDetails ?? {};
           else if (cat == 'pele') visualFindings = result.skinDetails ?? {};
           else if (cat == 'ferida') visualFindings = result.woundDetails ?? {};
           else if (cat == 'fezes' || cat == 'stool' || result.analysisType == 'stool_analysis') {
              visualFindings = result.stoolAnalysis ?? {};
              if (cat.isEmpty) cat = 'fezes'; // Force category for legacy stool_analysis
           } else {
              visualFindings = result.clinicalSignsDiag ?? {};
           }

           final healthAnalysis = AnaliseFeridaModel(
              dataAnalise: DateTime.now(), 
              imagemRef: imagePathToUse, 
              // If findings are empty, try fallback to generic clinical signs
              achadosVisuais: visualFindings.isNotEmpty ? visualFindings : (result.clinicalSignsDiag ?? {}),
              categoria: cat.isNotEmpty ? cat : 'geral',
              nivelRisco: result.urgenciaNivel, 
              recomendacao: result.orientacaoImediata,
              diagnosticosProvaveis: result.possiveisCausas,
              rawClinicalSigns: result.clinicalSignsDiag != null ? {'clinical_signs': result.clinicalSignsDiag} : null,
              descricaoVisual: result.descricaoVisual,
              caracteristicas: result.caracteristicas,
           );
           
           // THIS METHOD NOW STORES EVERYTHING (EYES, TEETH, STOOL, WOUNDS)
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
