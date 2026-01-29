
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../core/utils/permission_helper.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/models/analysis_state.dart';
import '../../../../core/providers/analysis_provider.dart';
import '../../../../core/services/meal_history_service.dart';
import '../../../../core/enums/scannut_mode.dart';

// Pet Domain
import '../../services/pet_profile_service.dart';
import '../../models/pet_analysis_result.dart';
import '../pet_result_screen.dart';
import '../widgets/pet_selection_dialog.dart';
import '../pet_history_screen.dart';
import '../../../../features/partners/presentation/global_agenda_screen.dart';
import '../../../../features/partners/presentation/partners_hub_screen.dart';

/// 🐾 PET DOMAIN CAMERA BODY
/// Isolamento total da lógica de Pets (ex-HomeView).
class PetCameraBody extends ConsumerStatefulWidget {
  final bool isActive;

  const PetCameraBody({
    super.key,
    required this.isActive,
  });

  @override
  ConsumerState<PetCameraBody> createState() => _PetCameraBodyState();
}

class _PetCameraBodyState extends ConsumerState<PetCameraBody> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitializing = false;
  bool _isProcessing = false;
  File? _capturedImage;
  
  // Pet Specific State
  int _petMode = 0; // 0 = Identification, 1 = Health/Stool
  String? _petName; // Context
  String? _petId;   // Context
  String? _displayPetName; // Loading overlay

  final Color _domainColor = AppDesign.petPink;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.isActive) {
      _initCamera();
    }
  }

  @override
  void didUpdateWidget(PetCameraBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _initCamera();
    } else if (!widget.isActive && oldWidget.isActive) {
      _disposeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeCamera();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed && widget.isActive) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    if (_isInitializing || _controller != null) return;
    if (!mounted) return;

    setState(() => _isInitializing = true);

    try {
      final granted = await PermissionHelper.requestCameraPermission(context);
      if (!granted) {
        debugPrint('🚫 Permissão de câmera negada no PetBody');
        return;
      }

      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        final controller = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.jpeg : ImageFormatGroup.bgra8888,
        );

        await controller.initialize();
        if (mounted) {
          setState(() {
            _controller = controller;
            _isInitializing = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Erro ao iniciar câmera no PetBody: $e');
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  Future<void> _disposeCamera() async {
    if (_controller != null) {
      final camera = _controller;
      _controller = null;
      if (mounted) setState(() {});
      try {
        await camera?.dispose();
      } catch (e) {
        debugPrint('⚠️ Erro ao liberar câmera: $e');
      }
    }
  }

  // --- CAPTURE & LOGIC ---

  Future<void> _onCapture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isProcessing) return;

    try {
      setState(() => _isProcessing = true);
      HapticFeedback.mediumImpact();

      final XFile rawFile = await controller.takePicture();
      final File optimizedFile = await _optimizeImage(File(rawFile.path));
      
      if (!mounted) return;
      setState(() => _capturedImage = optimizedFile);

      await _processCaptureFlow(optimizedFile);

    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        AppFeedback.showError(context, 'Erro ao capturar: $e');
      }
    }
  }

  Future<void> _pickFromGallery() async {
      try {
        final picker = ImagePicker();
        final XFile? image = await picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
           setState(() {
             _isProcessing = true;
             _capturedImage = File(image.path);
           });
           await _processCaptureFlow(_capturedImage!);
        }
      } catch(e) {
        debugPrint("Gallery error: $e");
      }
  }

  Future<void> _processCaptureFlow(File image) async {
      // 1. Pet Selection Logic
      if (_petMode == 1) {
         // Health Mode -> Needs Pet Context
         final selected = await _showPetSelectionDialog();
         if (selected == null) {
            // Cancelled
            _resetCapture();
            return;
         }
      } else {
         // ID Mode -> Use dummy or prompt name logic from HomeView?
         // HomeView logic: Prompt for name if ID mode.
         // Actually, ID mode is to IDENTIFY the pet, create a new one.
         // HomeView used `_promptPetName`.
         await _promptPetName();
         // If user cancels prompt, we might continue with null?
         // HomeView logic says: if name null, return.
         if (_petName == null && _petMode == 0) {
             // Maybe user wants to identify a generic dog?
             // But existing logic forced a name.
             // We'll stick to prompting.
            if (_petName == null) {
               _resetCapture();
               return; 
            }
         }
      }

      // 2. Prepare Analysis
      final locale = Localizations.localeOf(context).toString();
      ScannutMode mode = _petMode == 0 ? ScannutMode.petIdentification : ScannutMode.petDiagnosis;

      ref.read(analysisNotifierProvider.notifier).reset();
      
      // Context Injection
      Map<String, String>? contextData;
      if (_petName != null) {
          try {
             final srv = PetProfileService();
             await srv.init();
             final pMap = await srv.getProfile(_petName!);
             if (pMap != null && pMap['data'] != null) {
                final d = pMap['data'];
                contextData = {
                  'species': d['especie']?.toString() ?? 'Unknown',
                  'breed': d['raca']?.toString() ?? 'Unknown',
                  'weight': d['peso']?.toString() ?? 'Unknown'
                };
             }
          } catch(e) { /* ignore */ }
      }

      // Excluded Ingredients (Just to replicate HomeView logic exactly, mostly for Food but maybe Bio?)
      List<String> excluded = [];
      if (_petName != null) {
         excluded = await ref.read(mealHistoryServiceProvider).getRecentIngredients(_petName!);
      }

      // 3. Trigger Analysis
      final resultState = await ref.read(analysisNotifierProvider.notifier).analyzeImage(
         imageFile: image,
         mode: mode,
         petName: _petName,
         petId: _petId,
         excludedBases: excluded,
         locale: locale,
         contextData: contextData
      );

      // 4. Handle Result
      if (!mounted) return;
      
      if (resultState is AnalysisSuccess && resultState.data is PetAnalysisResult) {
         final res = resultState.data as PetAnalysisResult;
         
         // Navigate to Result Screen (Unified Flow)
         // Not Saving here because PetResultScreen handles saving confirmation/editing?
         // HomeView: "Always rely on PetResultScreen for saving to avoid double entries."
         
         Navigator.push(
           context,
           MaterialPageRoute(
             builder: (context) => PetResultScreen(
               imageFile: image,
               existingResult: res,
               mode: mode,
             ),
           ),
         ).then((_) => _resetCapture());
      } else if (resultState is AnalysisError) {
         AppFeedback.showError(context, resultState.message);
         _resetCapture();
      } else {
         _resetCapture();
      }
  }

  void _resetCapture() {
     if (mounted) {
       setState(() {
         _isProcessing = false;
         _capturedImage = null;
         _petName = null;
         _petId = null;
         _displayPetName = null;
       });
       ref.read(analysisNotifierProvider.notifier).reset();
     }
  }

  // --- DIALOGS ---

  Future<String?> _showPetSelectionDialog() async {
    try {
      PetProfileService.to.clearMemoryCache();
      await PetProfileService.to.syncWithDisk();
      final pets = await PetProfileService.to.getAllPetIdsWithNames();
      
      // Sort
      pets.sort((a,b) => (a['name'] ?? '').toLowerCase().compareTo((b['name'] ?? '').toLowerCase()));
      
      final selectedId = await showDialog<String>(
         context: context,
         barrierDismissible: false,
         builder: (ctx) => PetSelectionDialog(registeredPets: pets),
      );

      if (selectedId != null && selectedId != '<NOVO>') {
          final p = pets.firstWhere((element) => element['id'] == selectedId, orElse: () => {});
          setState(() {
             _petId = selectedId;
             _petName = p['name'];
             _displayPetName = _petName;
          });
      } else if (selectedId == '<NOVO>') {
          setState(() {
             _petId = null;
             _petName = null;
             _displayPetName = null;
          });
      }
      return selectedId;
    } catch(e) {
      debugPrint("Pet selection error: $e");
      return null;
    }
  }

  Future<void> _promptPetName() async {
    final l10n = AppLocalizations.of(context)!;
    String? name;
    await showDialog(
      context: context,
      builder: (ctx) {
        final c = TextEditingController(text: _petName);
        return AlertDialog(
           backgroundColor: Colors.black.withValues(alpha: 0.8),
           title: Text(l10n.petNamePromptTitle, style: const TextStyle(color: Colors.white)),
           content: TextField(
             controller: c,
             style: const TextStyle(color: Colors.white),
             decoration: InputDecoration(hintText: l10n.petNamePromptHint, hintStyle: const TextStyle(color: Colors.white38)),
           ),
           actions: [
             TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
             ElevatedButton(
               onPressed: () { name = c.text; Navigator.pop(ctx); },
               child: const Text("OK"),
             )
           ],
        );
      }
    );
    if (name != null && name!.trim().isNotEmpty) {
       setState(() {
         _petName = name!.trim();
         _displayPetName = _petName;
       });
    }
  }

  Future<File> _optimizeImage(File original) async {
    final tempDir = await getTemporaryDirectory();
    final targetPath = path.join(tempDir.path, 'pet_opt_${DateTime.now().millisecondsSinceEpoch}.jpg');
    final result = await FlutterImageCompress.compressAndGetFile(
       original.absolute.path, targetPath,
       minWidth: 1080, minHeight: 1440, quality: 75
    );
    return File(result?.path ?? original.path);
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return const SizedBox.shrink();

    final analysisState = ref.watch(analysisNotifierProvider);
    final isLoading = _isProcessing || analysisState is AnalysisLoading;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera
        if (_capturedImage != null)
           Image.file(_capturedImage!, fit: BoxFit.cover)
        else if (_controller != null && _controller!.value.isInitialized)
           CameraPreview(_controller!)
        else
           Container(color: Colors.black),
        
        // Frame
        _buildOverlayFrame(context),

        // Controls
        if (!isLoading) ...[
            _buildControls(context),
            _buildModeToggles(context),
            _buildTopActions(context),
        ],

        // Loading
        if (isLoading) _buildLoadingOverlay(context, analysisState),
      ],
    );
  }

  Widget _buildOverlayFrame(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hint = _petMode == 0 ? l10n.homeHintPetBreed : l10n.homeHintPetHealth;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
           Padding(
             padding: const EdgeInsets.only(bottom: 16),
             child: Container(
               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
               decoration: BoxDecoration(color: _domainColor, borderRadius: BorderRadius.circular(20)),
               child: Text(hint, style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600)),
             ),
           ),
           Container(
             width: 280, height: 280,
             decoration: BoxDecoration(
               border: Border.all(color: _domainColor, width: 3),
               borderRadius: BorderRadius.circular(24),
             ),
           )
        ],
      ),
    );
  }

  Widget _buildTopActions(BuildContext context) {
    return Positioned(
      top: 50, right: 20,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
           _buildActionButton(Icons.calendar_month, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalAgendaScreen()))),
           const SizedBox(width: 8),
           _buildActionButton(Icons.handshake, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PartnersHubScreen()))),
           const SizedBox(width: 8),
           _buildActionButton(Icons.pets, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PetHistoryScreen()))),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onTap) {
      return Container(
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white24)),
        child: IconButton(icon: Icon(icon, color: _domainColor), onPressed: onTap),
      );
  }

  Widget _buildModeToggles(BuildContext context) {
    return Positioned(
      top: 160, left: 0, right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(30)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildToggleBtn(0, Icons.pets, AppLocalizations.of(context)!.modePetIdentification),
              const SizedBox(width: 8),
              _buildToggleBtn(1, Icons.health_and_safety, AppLocalizations.of(context)!.modePetHealth),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleBtn(int mode, IconData icon, String label) {
    bool selected = _petMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _petMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
           color: selected ? _domainColor : Colors.transparent,
           borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
             Icon(icon, size: 20, color: selected ? Colors.black : Colors.white),
             if (selected) ...[
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
             ]
          ],
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    final totalOffset = 116.0; 
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: totalOffset),
          child: Row(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
                GestureDetector(
                  onTap: _pickFromGallery,
                  child: Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle, border: Border.all(color: _domainColor, width: 2)),
                    child: Icon(Icons.photo_library, color: _domainColor),
                  ),
                ),
                const SizedBox(width: 30),
                GestureDetector(
                  onTap: _onCapture,
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _domainColor, width: 4), color: _domainColor.withValues(alpha: 0.2)),
                    padding: const EdgeInsets.all(4),
                    child: Container(decoration: BoxDecoration(shape: BoxShape.circle, color: _domainColor), child: const Icon(Icons.camera_alt, color: Colors.black, size: 36)),
                  ),
                ),
                const SizedBox(width: 86),
             ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay(BuildContext context, AnalysisState state) {
     final l10n = AppLocalizations.of(context)!;
     String msg = _petMode == 0 ? l10n.loadingMsgPetId : l10n.loadingMsgClinical;
     return Container(
       color: Colors.black.withValues(alpha: 0.7),
       child: Center(
         child: Container(
           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
           margin: const EdgeInsets.symmetric(horizontal: 32),
           decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
           child: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
                 CircularProgressIndicator(color: _domainColor),
                 const SizedBox(height: 16),
                 Text(msg, textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                 if (_displayPetName != null)
                    Text(_displayPetName!, style: GoogleFonts.poppins(color: _domainColor, fontWeight: FontWeight.bold, fontSize: 18)),
             ],
           ),
         ),
       ),
     );
  }
}