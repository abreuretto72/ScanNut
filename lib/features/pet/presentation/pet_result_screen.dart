import 'dart:io';
import '../../../core/services/image_deduplication_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pet_analysis_result.dart';
import '../services/pet_analysis_service.dart';
import '../../../core/enums/scannut_mode.dart';
import '../models/pet_profile_extended.dart';
import 'widgets/edit_pet_form.dart';
import 'widgets/pet_dossier_view.dart';
import '../models/analise_ferida_model.dart'; // 🛡️ V170 Import

import '../services/pet_profile_service.dart';
import '../../../core/services/file_upload_service.dart'; // Added
import '../../../core/services/history_service.dart';
import '../../../core/theme/app_design.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/services/media_vault_service.dart';
import '../services/pet_indexing_service.dart';

import '../services/pet_pdf_generator.dart';
import '../../../core/widgets/pdf_preview_screen.dart';

final petResultProvider = StateProvider<PetAnalysisResult?>((ref) => null);

class PetResultScreen extends ConsumerStatefulWidget {
  final File imageFile;
  final PetAnalysisResult? existingResult;
  final bool isHistoryView;
  final ScannutMode mode;

  const PetResultScreen({
    super.key, 
    required this.imageFile,
    this.existingResult,
    this.isHistoryView = false,
    this.mode = ScannutMode.petIdentification,
  });

  @override
  ConsumerState<PetResultScreen> createState() => _PetResultScreenState();
}

class _PetResultScreenState extends ConsumerState<PetResultScreen> {
  bool _isLoading = true;
  File? _permanentImage;
  bool _isSaving = false; // 🛡️ V_FIX: Atomic lock
  bool _autoSaveAttempted = false; // Flag to prevent duplicate saves

  @override
  void initState() {
    super.initState();
    if (widget.existingResult != null) {
       // If existing result is passed (Observation or History), use it directly
       // Skip auto-save if history view (already saved)
       WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!widget.isHistoryView && !_autoSaveAttempted) {
              _autoSaveAttempted = true;
              _performAutoSave(widget.existingResult!);
          }
          ref.read(petResultProvider.notifier).state = widget.existingResult;
          if (mounted) {
            setState(() { 
                _isLoading = false; 
            });
          }
       });
    } else {
      // New Analysis
      _analyzeImage();
    }
  }

  Future<void> _analyzeImage() async {
    try {
      // 🛡️ [V180] Deduplication Check
      final deduplication = ImageDeduplicationService();
      final hash = await deduplication.calculateHash(widget.imageFile);
      
      if (hash.isNotEmpty) {
          final existing = await deduplication.checkDeduplication(hash);
          if (existing != null) {
              debugPrint('🚫 [PetResult] [DEDUPLICATION] Match found. Stopping.');
              if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(AppLocalizations.of(context)!.error_image_already_analyzed),
                          backgroundColor: Colors.red,
                      )
                  );
                  setState(() { _isLoading = false; });
              }
              return;
          }
      }

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

      // 🛡️ [V180] Register hash on success
      if (hash.isNotEmpty) {
          await deduplication.registerProcessedImage(
              hash: hash,
              type: widget.mode.toString(),
              petId: result.petId,
              petName: result.petName,
          );
      }
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.commonError}: $e')),
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
     debugPrint('📄 [V116-PDF] Preparando exportação PDF do Dossiê Veterinário 360 para ${result.petName ?? "Pet"}');
     
     Navigator.push(
       context,
       MaterialPageRoute(
         builder: (context) => PdfPreviewScreen(
           title: l10n.vet360ReportTitle(result.petName ?? "Pet"),
           buildPdf: (format) async {
             final generator = PetPdfGenerator();
             
             // 🛡️ FIX: Use generateDossierReport for Dossier (shows current analysis data)
             final pdf = await generator.generateDossierReport(
               analysis: result,
               imagePath: imagePathToUse,
               strings: l10n,
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
       
       // 🛡️ [V_FIX] LOAD EXISTING PROFILE TO AVOID OVERWRITING IDENTITY/IMAGE
       final ps = PetProfileService();
       await ps.init();
       final existingEntry = await ps.getProfile(result.petId ?? result.petName ?? '');
       
       PetProfileExtended profile;
       if (existingEntry != null && existingEntry['data'] != null) {
           // Existing Pet: Load current profile to preserve all fields (weight, vaccines, photo)
           profile = PetProfileExtended.fromHiveEntry(Map<String, dynamic>.from(existingEntry));
       } else {
           // New Pet: Create skeleton
           profile = PetProfileExtended.fromAnalysisResult(result, imagePathToUse);
       }
       
       // 🛡️ V_FIX: Optimistic UI Update (Immediate History)
       // Add current analysis to profile history so it shows up in Edit Form immediately
       try {
            Map<String, dynamic> visualFindings = {};
            String cat = result.category?.toLowerCase() ?? '';
            
            // Refined category detection
            if (cat == 'olhos' || cat == 'eyes') {
              visualFindings = result.eyeDetails ?? {};
            } else if (cat == 'dentes' || cat == 'dental') {
              visualFindings = result.dentalDetails ?? {};
            } else if (cat == 'pele' || cat == 'skin') {
              visualFindings = result.skinDetails ?? {};
            } else if (cat == 'ferida' || cat == 'wound') {
              visualFindings = result.woundDetails ?? {};
            }
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

            // 🛡️ Prevenção de duplicidade: verificar se já existe entrada com a mesma imagem
            final alreadyExists = profile.historicoAnaliseFeridas.any((e) => e.imagemRef == imagePathToUse);
            if (!alreadyExists) {
                profile.historicoAnaliseFeridas.add(healthAnalysis);
            }
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
    if (_isSaving) return;
    final l10n = AppLocalizations.of(context)!;
    debugPrint('🚀 [AUDIT-RESULT] Iniciando Auto-Save para pet: ${result.petName}');
    try {
      if (mounted) setState(() => _isSaving = true);
      final profileService = PetProfileService();
      await profileService.init();

      // 🛡️ V_FIX: Persist Image Permanently
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
                if (mounted) setState(() => _permanentImage = File(savedPath));
             }
          } catch (e) {
             debugPrint('❌ [AUDIT-RESULT] Falha ao persistir imagem: $e');
          }
      }

      // 🛡️ V220: FIX - Ensure Valid Pet Name
      final String safePetName = (result.petName != null && result.petName!.trim().isNotEmpty) 
          ? result.petName! 
          : 'Pet';

      debugPrint('   🔍 [AUDIT-RESULT] Pet Identificado como: "$safePetName" (Type: ${result.analysisType})');

      // 🛡️ [V_UUID] RESOLVE PROFILE EARLY
      final existingEntry = await profileService.getProfile(result.petId ?? safePetName);
      PetProfileExtended profile;
      
      if (existingEntry != null && existingEntry['data'] != null) {
          debugPrint('   ✅ [AUDIT-RESULT] Perfil existente encontrado. ID=${existingEntry['id']}');
          profile = PetProfileExtended.fromHiveEntry(Map<String, dynamic>.from(existingEntry));
      } else {
          debugPrint('   🆕 [AUDIT-RESULT] Perfil não encontrado. Criando novo esqueleto...');
          profile = PetProfileExtended.fromAnalysisResult(result, imagePathToUse);
          // If it's a health analysis, DO NOT use the clinical image as the main profile photo
          final bool isClinical = result.analysisType == 'diagnosis' || result.analysisType == 'stool_analysis';
          if (isClinical) {
              profile = profile.copyWith(imagePath: null);
          }
          
          final jsonProfile = profile.toJson();
          jsonProfile['pet_name'] = safePetName;
          await profileService.saveOrUpdateProfile(result.petId ?? safePetName, jsonProfile);
          debugPrint('   ✨ [AUDIT-RESULT] Novo perfil salvo com ID: ${profile.id}');
      }

      // 🛡️ V144: UNIFIED ROUTING - ALL CLINICAL/STOOL GOES TO WOUND HISTORY ('historicoAnaliseFeridas')
      if (result.analysisType == 'diagnosis' || result.analysisType == 'stool_analysis') {
           debugPrint('   🏥 [AUDIT-RESULT] Roteamento: Health Domain (Wound/Stool)');
           
           final historyPayload = result.toJson();
           historyPayload['pet_name'] = safePetName;
           
           await HistoryService.addScan(
             'Pet', 
             historyPayload, 
             imagePath: imagePathToUse,
             thumbnailPath: imagePathToUse,
             petName: safePetName,
             petId: profile.id,
           );

           // Extraction for clinical history
           final String cat = (result.category ?? result.analysisType).toLowerCase();
           Map<String, dynamic> visualFindings = {};
           if (cat == 'olhos' || cat == 'eyes') visualFindings = result.eyeDetails ?? {};
           else if (cat == 'dental') visualFindings = result.dentalDetails ?? {};
           else if (cat == 'pele') visualFindings = result.skinDetails ?? {};
           else if (cat == 'ferida') visualFindings = result.woundDetails ?? {};
           else if (cat == 'fezes' || cat == 'stool' || result.analysisType == 'stool_analysis') visualFindings = result.stoolAnalysis ?? {};
           else visualFindings = result.clinicalSignsDiag ?? {};

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
           await profileService.saveDetailedAnalysis(profile.id, healthAnalysis);

      } else {
           // IDENTITY DOMAIN: SAVE/UPDATE PROFILE & IMAGE
           debugPrint('🐾 [V220] Persisting Identity (Profile Update)');
           
           profile = profile.copyWith(
              especie: profile.especie ?? result.especie,
              raca: (profile.raca == null || profile.raca == 'N/A' || profile.raca!.contains('SRD')) ? result.raca : profile.raca,
              imagePath: imagePathToUse, 
              lastUpdated: DateTime.now(),
              reliability: result.reliability,
           );
           
           final jsonProfile = profile.toJson();
           jsonProfile['pet_name'] = safePetName;
           
           await profileService.saveOrUpdateProfile(safePetName, jsonProfile);
           
           await HistoryService.addScan(
             'Pet', 
             result.toJson(), 
             imagePath: imagePathToUse,
             thumbnailPath: imagePathToUse,
             petName: safePetName,
             petId: profile.id,
           );
      }
      
      final box = await HistoryService.getBox();
      if (box.isOpen) await box.flush();
      
      // Indexing
      try {
        final indexer = PetIndexingService();
        String displayType = result.analysisType;
        if (displayType == 'stool_analysis') displayType = l10n.labCategoryFeces;
        if (displayType == 'wound_analysis') displayType = l10n.petWoundHistory;
        if (displayType == 'identification') displayType = l10n.guideIdentity;
        if (displayType == 'diagnosis') displayType = l10n.petDiagnosis;

        await indexer.indexAiAnalysis(
          petId: profile.id, 
          petName: result.petName ?? safePetName,
          analysisType: displayType, 
          resultId: DateTime.now().millisecondsSinceEpoch.toString(),
          rawResult: result.toJson(),
          imagePath: imagePathToUse,
          localizedTitle: AppLocalizations.of(context)!.petIndexing_aiTitle(displayType),
          localizedNotes: result.urgenciaNivel,
        );
      } catch (e) {
        debugPrint("⚠️ Indexing failed: $e");
      }
      debugPrint("✅ Auto-Save completed for ${profile.petName}");
    } catch (e) {
      debugPrint("❌ Auto-Save failed: $e");
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(l10n.errorAutoSave(e.toString())), backgroundColor: AppDesign.warning)
         );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Map<String, dynamic> deepCastMap(dynamic data) {
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return {};
  }
}
