import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/utils/permission_helper.dart';
import '../../../core/services/file_upload_service.dart';
import '../../../core/utils/app_feedback.dart';

// Core
import '../../../core/providers/analysis_provider.dart';
import '../../../core/services/simple_auth_service.dart';
import '../../../core/services/history_service.dart';
import '../../../core/services/meal_history_service.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/models/analysis_state.dart';
import '../../../core/enums/scannut_mode.dart';

// Models
import '../../food/models/food_analysis_model.dart';
import '../../plant/models/plant_analysis_model.dart';
import '../../pet/models/pet_analysis_result.dart';
import '../../pet/models/pet_profile_extended.dart';
import '../../pet/services/pet_profile_service.dart';
import '../../food/services/nutrition_service.dart';
import '../../plant/services/botany_service.dart';
import '../../pet/presentation/widgets/edit_pet_form.dart';

// Widgets
import '../../food/presentation/widgets/result_card.dart';
import '../../food/presentation/food_result_screen.dart';
import '../../plant/presentation/widgets/plant_result_card.dart';
import '../../pet/presentation/widgets/pet_result_card.dart';
import '../../pet/presentation/pet_result_screen.dart';
import '../../pet/presentation/widgets/pet_selection_dialog.dart';
import '../../pet/presentation/pet_history_screen.dart';
import '../../pet/services/pet_profile_service.dart';
import '../../partners/presentation/partners_hub_screen.dart';
import '../../partners/presentation/global_agenda_screen.dart';
import 'widgets/app_drawer.dart';
import '../../../core/theme/app_design.dart';
import '../../../nutrition/presentation/screens/nutrition_home_screen.dart';
import '../../food/presentation/nutrition_history_screen.dart';
import '../../plant/presentation/botany_history_screen.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> with WidgetsBindingObserver {
  String? _petName; // stores pet name entered by user
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  int _currentIndex = -1; // -1: None selected, 0: Food, 1: Plant, 2: Pet
  int _petMode = 0; // 0: Identification, 1: Diagnosis
  bool _isCameraInitialized = false;
  File? _capturedImage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle camera lifecycle
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initialize() async {
    await _checkDisclaimer();
    
    // 🧬 V114: Biometria Inteligente
    if (mounted) {
      final shouldPrompt = await simpleAuthService.shouldPromptBiometricActivation();
      if (shouldPrompt) {
        _showBiometricActivationDialog();
      }
    }

    // 🛡️ V115: Validação Anti-Fantasmas (TOI)
    _validateNoGhostPets();

    // Don't initialize camera on startup - wait for user to select a mode
    setState(() {
      _isLoading = false;
    });
  }

  void _validateNoGhostPets() async {
    try {
      final petService = PetProfileService();
      await petService.init();
      final pets = await petService.getAllProfiles();
      final toiExists = pets.any((p) => p['name']?.toString().toUpperCase() == 'TOI');
      
      debugPrint('🛡️ [V115-AUDIT] Pets Validados (${pets.length}): ${pets.map((p) => p['name']).toList()}');
      if (toiExists) {
        debugPrint('🚨 [V115-AUDIT] GHOST DETECTADO: "TOI" ainda presente. Iniciando eliminação...');
        // Atomic wipe of TOI is handled at service level if needed, but here we just audit.
      } else {
        debugPrint('✅ [V115-AUDIT] Sistema limpo de pets fantasmas.');
      }
    } catch (e) {
      debugPrint('⚠️ [V115-AUDIT] Erro na auditoria de pets: $e');
    }
  }

  Future<void> _showBiometricActivationDialog() async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: AppDesign.backgroundDark.withOpacity(0.9),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppDesign.success, width: 2)),
          title: Row(
            children: [
              const Icon(Icons.fingerprint, color: AppDesign.success),
              const SizedBox(width: 10),
              Text('Acesso Rápido', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Detectamos que seu dispositivo suporta biometria. Deseja ativar o acesso rápido para entrar no ScanNut sem digitar senha?',
            style: GoogleFonts.poppins(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel, style: GoogleFonts.poppins(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppDesign.success),
              onPressed: () async {
                await simpleAuthService.setBiometricEnabled(true);
                if (mounted) {
                   Navigator.pop(context);
                   AppFeedback.showSuccess(context, 'Acesso rápido ativado!');
                }
              },
              child: Text('Ativar Agora', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkDisclaimer() async {
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool('disclaimer_accepted') ?? false;

    if (!accepted && mounted) {
      // Use Future.delayed to show dialog after build
      Future.delayed(Duration.zero, () {
        _showDisclaimerDialog();
      });
    }
  }

  Future<void> _showDisclaimerDialog() async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: AppDesign.backgroundDark.withOpacity(0.8),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppDesign.accent, width: 1)),
          title: Text(l10n.disclaimerTitle,
              style: const TextStyle(color: AppDesign.textPrimaryDark)),
          content: Text(
            l10n.disclaimerBody,
            style: const TextStyle(color: AppDesign.textSecondaryDark),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('disclaimer_accepted', true);
                 if (mounted) {
                   Navigator.pop(context);
                 }
              },
              child: Text(l10n.disclaimerButton,
                  style: const TextStyle(
                      color: AppDesign.accent, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initCamera() async {
    final granted = await PermissionHelper.requestCameraPermission(context);
    if (granted) {
      try {
        _cameras = await availableCameras();
        if (_cameras != null && _cameras!.isNotEmpty) {
          _controller = CameraController(
            _cameras![0],
            ResolutionPreset.medium,
            enableAudio: false,
          );
          await _controller!.initialize();
          await _controller!.setFlashMode(FlashMode.off);
          if (mounted) {
            setState(() {
              _isCameraInitialized = true;
            });
          }
        }
      } catch (e) {
        debugPrint('Camera initialization error: $e');
        if (mounted) {
          AppFeedback.showError(context, '${AppLocalizations.of(context)!.cameraError}$e');
        }
      }
    } else {
       // Reset current index if permission denied
       if (mounted) {
         // Show localized permission error
         final l10n = AppLocalizations.of(context)!;
         AppFeedback.showError(context, l10n.cameraPermission);
       }
       setState(() {
         _currentIndex = -1;
       });
    }
  }
  Future<void> _disposeCamera() async {
    if (_controller != null) {
      debugPrint('🔴 _disposeCamera: Starting disposal sequence...');
      
      // 1. Immediately update state to remove CameraPreview from tree
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
          // Note: We do NOT reset _currentIndex here anymore locally if we want to stay on the screen
          // But original logic did. Let's keep it consistent, but note unified flow might need mode.
          // _currentIndex = -1; // Removed to allow UI to persist mode during analysis
        });
      }

      // 2. Perform actual disposal in background
      final controllerToDispose = _controller;
      _controller = null; // Important: Clear immediately to prevent re-use attempt
      
      try {
        if (controllerToDispose != null) {
          await controllerToDispose.dispose();
          debugPrint('✅ _disposeCamera: Controller successfully disposed');
        }
      } catch (e) {
        debugPrint('⚠️ _disposeCamera: Error during dispose: $e');
      }
    }
  }

  /// 🚀 [V85] SUPER PROMPT: UNIFIED CAPTURE FLOW
  /// Handles camera capture
  Future<void> _onCapture() async {
    debugPrint('🔵 _onCapture: START');
    
    if (_controller == null || !_controller!.value.isInitialized) {
      debugPrint('❌ _onCapture: Camera not initialized');
      return;
    }

    if (_controller!.value.isTakingPicture) {
      debugPrint('⚠️ _onCapture: Already taking picture');
      return;
    }

    try {
      debugPrint('📸 _onCapture: Taking picture...');
      HapticFeedback.mediumImpact();
      final XFile image = await _controller!.takePicture();
      debugPrint('✅ _onCapture: Picture taken: ${image.path}');
      
      await _processCapturedImage(File(image.path));
      
    } catch (e, stackTrace) {
      debugPrint('❌❌❌ ERROR in _onCapture: $e');
       if (mounted) AppFeedback.showError(context, 'Erro na captura: $e');
    }
  }

  /// 🚀 [V85] SUPER PROMPT: GALLERY FLOW
  /// Handles gallery selection
  Future<void> _pickFromGallery() async {
    debugPrint('🔵 _pickFromGallery: START');
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        debugPrint('🖼️ _pickFromGallery: Image selected: ${image.path}');
        await _processCapturedImage(File(image.path));
      } else {
        debugPrint('⚠️ _pickFromGallery: User cancelled');
      }
    } catch (e) {
      debugPrint('❌ Error picking from gallery: $e');
      if (mounted) AppFeedback.showError(context, 'Erro ao abrir galeria: $e');
    }
  }

  /// 🛡️ [V85] CORE PROCESSOR: Otimização Atômica e Injeção
  Future<void> _processCapturedImage(File rawImage) async {
      try {
          // 1. Otimização Atômica (V70.1) - 1080px / 70%
          final optimizedImage = await _optimizeImage(rawImage);
          
           setState(() {
            _capturedImage = optimizedImage;
          });
          debugPrint('✅ _process: Image optimized & State updated.');

          // 2. Dispose Camera (if active) to free resources
          // We only dispose if we are NOT going to restart it immediately, 
          // but for analysis it is good to pause/dispose.
          if (_isCameraInitialized) {
             debugPrint('🔴 _process: Disposing camera for analysis...');
             await _disposeCamera();
          }

          final capturedMode = _currentIndex;
          final capturedPetMode = _petMode;

          // 3. Logic for Pet Selection (Unified)
          if (capturedMode == 2 && (capturedPetMode == 1 || capturedPetMode == 2)) { // Health or Stool 💩
             debugPrint('🏥 _process: Clinical mode detected, showing pet selection...');
             final selectedPet = await _showPetSelectionDialog();
             
             if (selectedPet == null) {
               debugPrint('❌ _process: User cancelled pet selection');
               // Re-init camera if we cancelled? Or just valid exit.
               return; 
             }
             setState(() => _petName = selectedPet == '<NOVO>' ? null : selectedPet);
          } else if (capturedMode == 2 && capturedPetMode == 0) { // ID
             debugPrint('🐾 _process: Prompting for pet name...');
             final name = await _promptPetName();
             if (name == null || name.trim().isEmpty) return;
             setState(() => _petName = name.trim());
          }

          // 4. Injeção na IA Gemini
          debugPrint('🔍 _process: Configuring Analysis Mode...');
          ScannutMode mode;
          switch (capturedMode) {
            case 0: mode = ScannutMode.food; break;
            case 1: mode = ScannutMode.plant; break;
            case 2: 
              if (capturedPetMode == 0) mode = ScannutMode.petIdentification;
              else if (capturedPetMode == 1) mode = ScannutMode.petDiagnosis;
              else mode = ScannutMode.petStoolAnalysis; // 💩 V231
              break;
            default: mode = ScannutMode.petIdentification; break;
          }

          List<String> excludedIngredients = [];
          if (mode == ScannutMode.petIdentification && _petName != null) {
             excludedIngredients = await ref.read(mealHistoryServiceProvider).getRecentIngredients(_petName!);
          }

          // 🛡️ Context Injection
          Map<String, String>? contextData;
          if (_petName != null) {
              try {
                  final pSrv = PetProfileService();
                  await pSrv.init();
                  final pMap = await pSrv.getProfile(_petName!);
                  if (pMap != null && pMap['data'] != null) {
                      final pd = pMap['data'];
                      contextData = {
                          'species': pd['especie']?.toString() ?? 'Unknown',
                          'breed': pd['raca']?.toString() ?? 'Unknown',
                          'weight': pd['peso']?.toString() ?? 'Unknown', // 💩 V231: Crucial for stool volume
                      };
                  }
              } catch (e) {
                  debugPrint('Error loading context: $e');
              }
          }

          String localeCode = Localizations.localeOf(context).toString();
          if (localeCode.toLowerCase().contains('en')) localeCode = 'en_US';

          // Trigger
          await ref.read(analysisNotifierProvider.notifier).analyzeImage(
            imageFile: optimizedImage, 
            mode: mode,
            petName: _petName,
            excludedBases: excludedIngredients,
            locale: localeCode,
            contextData: contextData,
          );
          
          final resultState = ref.read(analysisNotifierProvider);
          
          // Critical Fix: Reset to remove overlay
          ref.read(analysisNotifierProvider.notifier).reset();

          if (!context.mounted) return;
          await Future.delayed(const Duration(milliseconds: 100));
          
          await _handleAnalysisResult(resultState);
          debugPrint('🎉 _process: END SUCCESS');

      } catch (e) {
           debugPrint('❌❌❌ ERROR in _processCapturedImage: $e');
           if (mounted) AppFeedback.showError(context, 'Erro no processamento: $e');
      }
  }

  Future<File> _optimizeImage(File originalFile) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = path.join(tempDir.path, 'opt_${DateTime.now().millisecondsSinceEpoch}.jpg');

      final result = await FlutterImageCompress.compressAndGetFile(
        originalFile.absolute.path,
        targetPath,
        minWidth: 1080,
        minHeight: 1080,
        quality: 70,
        format: CompressFormat.jpeg, 
      );

      if (result == null) return originalFile;
      return File(result.path);
    } catch (e) {
      debugPrint('⚠️ Optimization failed, using original: $e');
      return originalFile;
    }
  }

  Future<void> _handleAnalysisResult([AnalysisState? injectedState]) async {
    // Use injected state if provided (from _onCapture), otherwise read from provider
    final state = injectedState ?? ref.read(analysisNotifierProvider);

    try {
      if (state is AnalysisSuccess) {
        if (state.data is FoodAnalysisModel) {
          // 🛡️ V231: Auto-Save Food Analysis to History
          final foodData = state.data as FoodAnalysisModel;
          _handleSave('Food', data: foodData);

          if (_capturedImage != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FoodResultScreen(
                  analysis: foodData,
                  imageFile: _capturedImage,
                  onSave: () => _handleSave('Food', data: foodData),
                ),
              ),
            );
          } else {
             _showResultSheet(
              context,
              ResultCard(
                analysis: foodData,
                onSave: () => _handleSave('Food', data: foodData),
              ),
            );
          }
        } else if (state.data is PlantAnalysisModel) {
          // 🛡️ V231: Auto-Save Plant Analysis to History
          final plantData = state.data as PlantAnalysisModel;
          _handleSave('Plant', data: plantData);

          _showResultSheet(
            context,
            PlantResultCard(
              analysis: plantData,
              imagePath: _capturedImage?.path,
              onSave: () => _handleSave('Plant', data: plantData),
              onShop: () => _handleShop(),
            ),
          );
        } else if (state.data is PetAnalysisResult) {

          final petAnalysis = state.data as PetAnalysisResult;

          // If in diagnosis mode, we rely on PetResultScreen for auto-save
          // to avoid double entries (Legacy vs Structured).
          if (_petMode == 1) {
            debugPrint('🏥 [Home] Health mode: Handing off to PetResultScreen for unified save.');
          }

          
          // Clean up state before navigation
          ref.read(analysisNotifierProvider.notifier).reset();

          // Navigate to Full Screen Result
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PetResultScreen(
                  imageFile: _capturedImage!,
                  existingResult: petAnalysis,
                ),
              ),
            );
          }
        }
      }
    } catch (e, stackTrace) {
        debugPrint('❌ ERRO NA NAVEGAÇÃO: $e');
        debugPrint('📚 STACKTRACE: $stackTrace');
        if (mounted) {
           AppFeedback.showError(context, "Erro de Navegação: $e");
        }
    }
    if (state is AnalysisError) {
      final l10n = AppLocalizations.of(context)!;
      String errorMessage;

      switch (state.message) {
        case 'analysisErrorAiFailure': errorMessage = l10n.analysisErrorAiFailure; break;
        case 'analysisErrorJsonFormat': errorMessage = l10n.analysisErrorJsonFormat; break;
        case 'analysisErrorUnexpected': errorMessage = l10n.analysisErrorUnexpected; break;
        case 'analysisErrorInvalidCategory': errorMessage = l10n.analysisErrorInvalidCategory; break;
        case 'errorBadPhoto': errorMessage = l10n.errorBadPhoto; break;
        case 'errorAiTimeout': errorMessage = l10n.errorAiTimeout; break;
        default: errorMessage = state.message;
      }

      AppFeedback.showError(context, errorMessage);
    }
  }

  void _showResultSheet(BuildContext context, Widget child) {
    // 1. Reset do loading para remover o desfoque da Home
    ref.read(analysisNotifierProvider.notifier).reset(); 
    
    // 2. Pequeno delay para o Flutter limpar a UI
    Future.delayed(const Duration(milliseconds: 100), () {
      if (context.mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          enableDrag: true, // Permitir fechar arrastando para baixo
          backgroundColor: Colors.transparent,
          builder: (context) => child,
        );
      }
    });
  }

  Future<void> _handleSave(String type, {dynamic data}) async {
    final state = ref.read(analysisNotifierProvider);
    // Prioritize passed data, fallback to provider (though provider is likely reset)
    final activeData = data ?? (state is AnalysisSuccess ? state.data : null);

    if (activeData == null) {
      return;
    }

    if (type == 'Pet' && activeData is PetAnalysisResult) {
      debugPrint('💾 [HomeView] Handling Save for Pet mode...');
      final petData = activeData;
      final petName = petData.petName ?? _petName;

      if (petName != null && petName.trim().isNotEmpty) {
        final dataMap = petData.toJson();
        if (_capturedImage != null) {
          dataMap['image_path'] = _capturedImage!.path;
        }
        
        try {
          await ref.read(historyServiceProvider).savePetAnalysis(petName, dataMap);
        } catch (e) {
            debugPrint('Error saving pet: $e');
        }
         if (!mounted) return;
        AppFeedback.showSuccess(context, AppLocalizations.of(context)!.petSavedSuccess(petName));

        // Auto-Navigation Logic for Diagnosis Mode
        if (_petMode == 1) { // 1 = Diagnosis
            // Close the Result Sheet
            Navigator.of(context).pop();

            // Load Profile and Navigate to Health Tab
            try {
                final profileService = PetProfileService();
                await profileService.init();
                final profileData = await profileService.getProfile(petName);

                if (profileData != null && profileData['data'] != null) {
                    final profile = PetProfileExtended.fromHiveEntry(Map<String, dynamic>.from(profileData['data']));

                    if (mounted) {
                        Navigator.of(context).push(
                            MaterialPageRoute(builder: (ctx) => Scaffold(
                                backgroundColor: AppDesign.surfaceDark,
                                appBar: AppBar(
                                    title: Text(petName),
                                    backgroundColor: AppDesign.backgroundDark,
                                    iconTheme: const IconThemeData(color: AppDesign.textPrimaryDark),
                                    titleTextStyle: GoogleFonts.poppins(color: AppDesign.textPrimaryDark, fontSize: 20),
                                ),
                                body: EditPetForm(
                                    existingProfile: profile,
                                    onSave: (p) async { 
                                        await profileService.saveOrUpdateProfile(p.petName, p.toJson());
                                        if (mounted && Navigator.canPop(context)) Navigator.pop(context);
                                    },
                                    initialTabIndex: 1, // HEALTH TAB
                                ),
                            ))
                        );
                    }
                }
            } catch (e) {
                debugPrint('Navigation error: $e');
            }
        }
      } else {
         if (!mounted) return;
        AppFeedback.showError(context, AppLocalizations.of(context)!.errorPetNameNotFound);
      }
    } else {
        // Handle saving for Food or Plant
        try {
            if (type == 'Food' && activeData is FoodAnalysisModel) {
                await NutritionService().saveFoodAnalysis(
                    activeData,
                    _capturedImage
                );
            } else if (type == 'Plant' && activeData is PlantAnalysisModel) {
                debugPrint("🌱 Requesting BotanyService to save plant...");
                await BotanyService().savePlantAnalysis(
                    activeData,
                    _capturedImage
                );
            }
            
            // Still save to main history for backward compatibility and unified view
            final dataJson = (activeData is FoodAnalysisModel) 
                ? activeData.toJson()
                : (activeData as dynamic).toJson();
            
            await ref.read(historyServiceProvider).saveAnalysis(
                dataJson, 
                type, 
                imagePath: _capturedImage?.path
            );

            if (!mounted) return;
            AppFeedback.showSuccess(context, AppLocalizations.of(context)!.savedSuccess(type));
        } catch (e) {
            debugPrint('❌ Save error for $type: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: AppDesign.error),
            );
        }
    }
    
    // Reset state after saving (already reset, but harmless)
    ref.read(analysisNotifierProvider.notifier).reset();
  }

  void _handleShop() {
    // Implement shop navigation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.redirectShop),
        backgroundColor: AppDesign.info,
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    _checkSingleActiveTab();
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppDesign.backgroundDark,
        body: Center(child: CircularProgressIndicator(color: AppDesign.progress)),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        _showExitDialog(context);
      },
      child: Scaffold(
        backgroundColor: AppDesign.backgroundDark,
      drawer: const AppDrawer(),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Layer - Only show when mode is selected
          if (_currentIndex != -1) ...[
            if (_isCameraInitialized && _controller != null && _controller!.value.isInitialized)
              CameraPreview(_controller!)
            else
              Container(color: AppDesign.backgroundDark),
          ],
          
          // 🛡️ LOADING OVERLAY (Analysis State)
          if (ref.watch(analysisNotifierProvider) is AnalysisLoading)
            Container(
              color: Colors.black.withOpacity(0.7), // Dimmed background
              width: double.infinity,
              height: double.infinity,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white, // White card for Black Text contrast
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))
                    ]
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Loading Indicator (Orange for Food)
                      const SizedBox(
                        width: 40, 
                        height: 40, 
                        child: CircularProgressIndicator(
                          color: AppDesign.foodOrange, // Food Domain Color
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _currentIndex == 0 ? "Otimizando Dieta..." :
                        _currentIndex == 1 ? "Identificando Planta..." :
                        _petMode == 1 ? "Iniciando Triagem Clínica..." :
                        _petMode == 2 ? "Analisando Amostra Coprológica..." :
                        "Identificando seu PET...",
                        style: GoogleFonts.poppins(
                          color: Colors.black, // PRETO PURO (Requested)
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Por favor, aguarde.",
                        style: GoogleFonts.poppins(
                          color: Colors.black54, 
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 2. Scan Frame Overlay - Show when mode selected OR when we have a captured image
          if (_currentIndex != -1 || _capturedImage != null)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   // Hint Banner ABOVE the frame
                   if (_currentIndex != -1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: IgnorePointer(
                        ignoring: true,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppDesign.getModeColor(_currentIndex),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ]
                          ),
                          child: Text(
                            _getHintText(context),
                            style: GoogleFonts.poppins(
                              color: Colors.black, // Pure Black as requested
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),

                  Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      border: Border.all(color: _currentIndex == -1 ? AppDesign.textPrimaryDark.withOpacity(0.5) : AppDesign.getModeColor(_currentIndex), width: 3),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Stack(
                  children: [
                    if (_capturedImage != null)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(21),
                          child: Image.file(
                            _capturedImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                                return Container(
                                    color: Colors.white10,
                                    child: const Center(
                                        child: Icon(Icons.broken_image, color: Colors.white24, size: 40)
                                    ),
                                );
                            },
                          ),
                        ),
                      ),
                    // Corner accents
                    Positioned(
                    top: -2,
                    left: -2,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: _currentIndex == -1 ? AppDesign.accent : AppDesign.getModeColor(_currentIndex), width: 4),
                          left: BorderSide(color: _currentIndex == -1 ? AppDesign.accent : AppDesign.getModeColor(_currentIndex), width: 4),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: _currentIndex == -1 ? AppDesign.accent : AppDesign.getModeColor(_currentIndex), width: 4),
                          right: BorderSide(color: _currentIndex == -1 ? AppDesign.accent : AppDesign.getModeColor(_currentIndex), width: 4),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -2,
                    left: -2,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: _currentIndex == -1 ? AppDesign.accent : AppDesign.getModeColor(_currentIndex), width: 4),
                          left: BorderSide(color: _currentIndex == -1 ? AppDesign.accent : AppDesign.getModeColor(_currentIndex), width: 4),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: _currentIndex == -1 ? AppDesign.accent : AppDesign.getModeColor(_currentIndex), width: 4),
                          right: BorderSide(color: _currentIndex == -1 ? AppDesign.accent : AppDesign.getModeColor(_currentIndex), width: 4),
                        ),
                      ),
                    ),
                  ),
                 ],
               ),
             ),
                ],
              ),
            ),

          // 2.5 PET MODE TOGGLES (Top Center)
          if (_currentIndex == 2)
            Positioned(
              top: 160, // Deep optical centering (~160px from top)
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppDesign.backgroundDark.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white24),
                    boxShadow: const [
                       BoxShadow(
                         color: Colors.black26, 
                         blurRadius: 8, 
                         offset: Offset(0, 4)
                       )
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Toggle 1: Identification
                      GestureDetector(
                        onTap: () { setState(() { _petMode = 0; }); _clearCapturedImage(); },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: _petMode == 0 ? AppDesign.getModeColor(2) : Colors.transparent,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.pets, size: 20, color: _petMode == 0 ? Colors.black : AppDesign.textPrimaryDark), // Black Text
                              if (_petMode == 0) ...[
                                const SizedBox(width: 8),
                                Text(AppLocalizations.of(context)!.modePetIdentification, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), // Black Text
                              ]
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Toggle 2: Diagnosis
                      GestureDetector(
                        onTap: () { setState(() { _petMode = 1; }); _clearCapturedImage(); },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: _petMode == 1 ? AppDesign.getModeColor(2) : Colors.transparent,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.health_and_safety, size: 20, color: _petMode == 1 ? Colors.black : AppDesign.textPrimaryDark),
                              if (_petMode == 1) ...[
                                const SizedBox(width: 8),
                                Text(AppLocalizations.of(context)!.modePetHealth, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                              ]
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Toggle 3: Stool (💩 V231)
                      GestureDetector(
                        onTap: () { setState(() { _petMode = 2; }); _clearCapturedImage(); },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: _petMode == 2 ? AppDesign.getModeColor(2) : Colors.transparent,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.biotech, size: 20, color: _petMode == 2 ? Colors.black : AppDesign.textPrimaryDark),
                              if (_petMode == 2) ...[
                                const SizedBox(width: 8),
                                const Text("Fezes", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                              ]
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ),
          ),


          // 3. Menu Button (Top Left)
          Positioned(
            top: 50,
            left: 20,
            child: Builder(
              builder: (context) => Container(
                decoration: BoxDecoration(
                  color: AppDesign.backgroundDark.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppDesign.textPrimaryDark.withOpacity(0.2)),
                ),
                child: IconButton(
                  icon: Icon(AppDesign.iconMenu, color: _currentIndex == -1 ? AppDesign.textPrimaryDark : AppDesign.getModeColor(_currentIndex), size: 28),
                  onPressed: () {
                    _clearCapturedImage();
                    Scaffold.of(context).openDrawer();
                  },
                ),
              ),
            ),
          ),

          // 3.5 Nutrition Button (Top Right) - Only for Food Mode
          if (_currentIndex == 0)
            Positioned(
              top: 50,
              right: 20,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // History Button (New)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.history, color: AppDesign.getModeColor(0), size: 28),
                      tooltip: AppLocalizations.of(context)!.tooltipNutritionHistory,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NutritionHistoryScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Nutrition Module Button (Existing)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.restaurant_menu, color: AppDesign.getModeColor(0), size: 28),
                      tooltip: AppLocalizations.of(context)!.tooltipNutritionManagement,
                      onPressed: () {
                        try {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NutritionHomeScreen(),
                            ),
                          );
                        } catch (e) {
                          debugPrint('❌ Error opening Nutrition module: $e');
                          AppFeedback.showError(context, 'Erro ao abrir módulo de nutrição: $e');
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

          // 3.5 Action Buttons (Top Right) - Only for Plant Mode
          if (_currentIndex == 1)
            Positioned(
              top: 50,
              right: 20,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   // History Button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.history, color: AppDesign.getModeColor(1), size: 28),
                      tooltip: AppLocalizations.of(context)!.tooltipBotanyHistory,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const BotanyHistoryScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          // 3.5 Action Buttons (Top Right) - Only for Pet Mode
          if (_currentIndex == 2)
            Positioned(
              top: 50,
              right: 20,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Agenda Global Button (only in PET mode)
                  if (_currentIndex == 2) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.calendar_month, color: AppDesign.getModeColor(2), size: 28),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const GlobalAgendaScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  // Partners Button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.handshake, color: AppDesign.getModeColor(2), size: 28),
                      onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PartnersHubScreen()),
                  );
                },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // History Button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.pets, color: AppDesign.getModeColor(2), size: 28),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PetHistoryScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          
          // 3. Shutter Button (Center) - Only show when mode is selected
          if (_currentIndex != -1)
            Positioned(
              bottom: 155, // Lifted +5px (Total 155px)
              left: 0,
              right: 0,
              child: Center(
                child: _buildCaptureControls(),
              ),
            ),

          // 4. Loading Overlay - Using Consumer to watch analysis state
          Consumer(
            builder: (context, ref, child) {
              final analysisState = ref.watch(analysisNotifierProvider);
              if (analysisState is AnalysisLoading) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background Preview
                    if (analysisState.imagePath != null)
                      Image.file(
                        File(analysisState.imagePath!),
                        fit: BoxFit.cover,
                      ),
                    
                    // Dark Overlay
                    Container(
                      color: Colors.black.withOpacity(0.7),
                    ),

                    // Loading Content
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.1),
                            ),
                            child: const CircularProgressIndicator(
                              color: AppDesign.accent,
                              strokeWidth: 3,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _translateLoadingMessage(analysisState.message, AppLocalizations.of(context)!),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              shadows: [
                                const Shadow(blurRadius: 4, color: Colors.black, offset: Offset(0, 2)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // 5. Bottom Bar
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomBar(),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildCaptureControls() {
    final modeColor = AppDesign.getModeColor(_currentIndex);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Gallery Button (Left)
          GestureDetector(
            onTap: _pickFromGallery,
            child: Container(
              width: 56, // Fixed size for symmetry
              height: 56,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
                border: Border.all(color: modeColor, width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))
                ],
              ),
              child: Icon(Icons.photo_library, color: modeColor, size: 26),
            ),
          ),
          
          const SizedBox(width: 30), // Spacing

          // Shutter Button (Center)
           GestureDetector(
            onTap: _onCapture,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: modeColor, width: 4),
                color: modeColor.withOpacity(0.2),
                 boxShadow: [
                  BoxShadow(color: modeColor.withOpacity(0.3), blurRadius: 15, spreadRadius: 1)
                ],
              ),
              padding: const EdgeInsets.all(4),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: modeColor,
                ),
                child: const Icon(Icons.camera_alt, color: AppDesign.backgroundDark, size: 36),
              ),
            ),
          ),

          const SizedBox(width: 30), // Spacing

          // Invisible Balancing Element (Right)
          const SizedBox(width: 56, height: 56),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16, left: 20, right: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.transparent, // Transparent background as requested
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (ref.watch(settingsProvider).showFoodButton) _buildNavItem(0, Icons.restaurant, l10n.tabFood, AppDesign.getModeColor(0)),
                  if (ref.watch(settingsProvider).showPlantButton) _buildNavItem(1, Icons.grass, l10n.tabPlants, AppDesign.getModeColor(1)),
                  if (ref.watch(settingsProvider).showPetButton) _buildNavItem(2, Icons.pets, l10n.tabPets, AppDesign.getModeColor(2)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ... (Helper skipped) ...

  Widget _buildNavItem(int index, IconData icon, String label, Color activeColor) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () async {
        setState(() {
          _capturedImage = null;
          _currentIndex = index;
          if (index == 2) {
            _petMode = 0;
          }
        });
        
        // Initialize camera when mode is selected (if not already initialized)
        if (!_isCameraInitialized) {
          await _initCamera();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : Colors.white60, // Restore white for dark bg
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : Colors.white60, // Restore white for dark bg
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _checkSingleActiveTab() {
    // No auto-selection - user must click a mode button
    // This method can be used for validation if needed in the future
  }

  // Helper to compare configs
  String _lastConfig = "";

  Widget _buildStaticNavItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white60, size: 28),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ],
        ),
      ),
    );
  }


  // Helper dialog to ask for pet name
  Future<String?> _promptPetName() async {
    String? petName;
    final l10n = AppLocalizations.of(context)!;
    await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        final controller = TextEditingController(text: _petName);
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: Colors.black.withOpacity(0.8),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: AppDesign.accent, width: 1)),
            title: Text(l10n.petNamePromptTitle,
                style: const TextStyle(color: Colors.white)),
            content: TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: l10n.petNamePromptHint,
                hintStyle: const TextStyle(color: Colors.white38),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white38),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppDesign.accent),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.petNamePromptCancel,
                    style: const TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppDesign.accent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () {
                  petName = controller.text;
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
    return petName;
  }

  // Show pet selection dialog for Health mode
  Future<String?> _showPetSelectionDialog() async {
    try {
      // 1. [V108] Pre-Render Validation (Protocolo de Interface Reativa)
      // Zera cache da memória e força leitura do disco
      PetProfileService.to.clearMemoryCache(); 
      await PetProfileService.to.syncWithDisk();
      
      final registeredPets = await PetProfileService.to.getAllPetNames();
      
      // 🛡️ [V106/V108] GHOST PURGE PROTOCOL
      // We explicitly DO NOT merge pets from HistoryService.
      // History logs may contain "Ghost Pets" (deleted from profile but remaining in logs).
      // By restricting selection to Active Profiles only, we eliminate the crash risk.
      
      final allUniquePets = registeredPets.toList();
      allUniquePets.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      
      debugPrint('🔍 [V108-UI] Pets Validados (${allUniquePets.length}): $allUniquePets');
      
      // Show dialog
      final selectedPet = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => PetSelectionDialog(
          registeredPets: allUniquePets,
        ),
      );
      
      return selectedPet;
    } catch (e) {
      debugPrint('❌ Error loading pets for selection: $e');
      return null;
    }
  }

  // Save wound analysis to pet's health history
  Future<void> _saveWoundAnalysis(PetAnalysisResult analysis) async {
    try {
      final petProfileService = PetProfileService();
      await petProfileService.init();
      
      // Save image permanently
      String? savedImagePath = _capturedImage?.path;
      if (_capturedImage != null) {
        final fileService = FileUploadService();
        final permanentPath = await fileService.saveMedicalDocument(
          file: _capturedImage!,
          petName: _petName!,
          attachmentType: 'wound_analysis',
        );
        if (permanentPath != null) {
          savedImagePath = permanentPath;
        }
      }

      // Extract wound/diagnosis information from analysis
      final analysisData = {
        'imagePath': savedImagePath ?? '',
        'diagnosis': analysis.descricaoVisualDiag ?? analysis.orientacaoImediataDiag ?? AppLocalizations.of(context)!.defaultWoundAnalysis,
        'severity': _extractSeverity(analysis),
        'recommendations': analysis.possiveisCausasDiag ?? [],
        'rawData': analysis.toJson(), // Store complete analysis
      };
      
      await petProfileService.saveWoundAnalysis(
        petName: _petName!,
        analysisData: analysisData,
      );
      
      debugPrint('✅ Wound analysis saved successfully for $_petName');
      
      // Show confirmation to user
      if (mounted) {
        AppFeedback.showSuccess(
          context,
          AppLocalizations.of(context)!.healthAnalysisSaved(_petName!),
        );
      }
    } catch (e) {
      debugPrint('❌ Error saving wound analysis: $e');
      if (mounted) {
        AppFeedback.showError(
          context,
          AppLocalizations.of(context)!.errorSavingAnalysis(e.toString()),
        );
      }
    }
  }

  // Extract severity level from analysis
  String _extractSeverity(PetAnalysisResult analysis) {
    // For diagnosis mode, use urgenciaNivelDiag if available
    if (analysis.urgenciaNivelDiag != null) {
      final nivel = analysis.urgenciaNivelDiag!.toLowerCase();
      if (nivel.contains('vermelho') || nivel.contains('urgente')) {
        return 'Alta';
      } else if (nivel.contains('amarelo') || nivel.contains('atenção')) {
        return 'Média';
      } else {
        return 'Baixa';
      }
    }
    
    // Fallback: analyze description text
    final descricao = (analysis.descricaoVisualDiag ?? analysis.orientacaoImediataDiag ?? '').toLowerCase();
    
    if (descricao.contains('grave') || descricao.contains('urgente') || descricao.contains('crítico')) {
      return 'Alta';
    } else if (descricao.contains('moderado') || descricao.contains('atenção')) {
      return 'Média';
    } else {
      return 'Baixa';
    }
  }

  Future<void> _clearCapturedImage() async {
    if (_capturedImage != null) {
      try {
        if (await _capturedImage!.exists()) {
          await _capturedImage!.delete();
          debugPrint('🗑️ Deleted temporary image file');
        }
      } catch (e) {
        debugPrint('⚠️ Failed to delete temp image: $e');
      }
      if (mounted) {
        setState(() {
          _capturedImage = null;
        });
      }
    }
  }

  String _translateLoadingMessage(String key, AppLocalizations l10n) {
    switch (key) {
      case 'loadingFood': return l10n.loadingFood;
      case 'loadingPlant': return l10n.loadingPlant;
      case 'loadingPetBreed': return l10n.loadingPetBreed;
      case 'loadingPetHealth': return l10n.loadingPetHealth;
      default: return key;
    }
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppDesign.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppLocalizations.of(context)!.exitDialogTitle,
          style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark),
        ),
        content: Text(
          AppLocalizations.of(context)!.exitDialogContent,
          style: GoogleFonts.poppins(color: AppDesign.textSecondaryDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: GoogleFonts.poppins(color: AppDesign.textSecondaryDark),
            ),
          ),
          TextButton(
            onPressed: () {
              SystemNavigator.pop();
            },
            child: Text(
              AppLocalizations.of(context)!.exit,
              style: GoogleFonts.poppins(color: AppDesign.error),
            ),
          ),
        ],
      ),
    );
  }

  String _getHintText(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (_currentIndex) {
      case 0: return l10n.homeHintFood;
      case 1: return l10n.homeHintPlant;
      case 2: 
        // Pet mode: check sub-mode (Breed & ID vs Health)
        return _petMode == 0 ? l10n.homeHintPetBreed : l10n.homeHintPetHealth;
      default: return '';
    }
  }
}
