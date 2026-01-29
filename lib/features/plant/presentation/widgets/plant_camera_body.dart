
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
import '../../../../core/enums/scannut_mode.dart';

import '../../models/plant_analysis_model.dart';
import '../../services/botany_service.dart';
import '../widgets/plant_result_card.dart';
import '../botany_history_screen.dart';

/// 🌿 PLANT DOMAIN CAMERA BODY
/// Isolamento da lógica de captura e análise de plantas (ex-HomeView).
class PlantCameraBody extends ConsumerStatefulWidget {
  final bool isActive;

  const PlantCameraBody({
    super.key,
    required this.isActive,
  });

  @override
  ConsumerState<PlantCameraBody> createState() => _PlantCameraBodyState();
}

class _PlantCameraBodyState extends ConsumerState<PlantCameraBody> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitializing = false;
  bool _isProcessing = false;
  File? _capturedImage;

  // Design Constants
  final Color _domainColor = AppDesign.getModeColor(1); // Plant Green
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.isActive) {
      _initCamera();
    }
  }

  @override
  void didUpdateWidget(PlantCameraBody oldWidget) {
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
        debugPrint('🚫 Permissão de câmera negada no PlantBody');
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
      debugPrint('❌ Erro ao iniciar câmera no PlantBody: $e');
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

  // --- CAPTURE & PROCESSING ---

  Future<void> _onCapture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isProcessing) return;

    try {
      setState(() => _isProcessing = true);
      HapticFeedback.mediumImpact();

      final XFile rawFile = await controller.takePicture();
      final File optimizedFile = await _optimizeImage(File(rawFile.path));
      
      if (!mounted) return;

      setState(() {
        _capturedImage = optimizedFile;
      });

      await _analyzePlant(optimizedFile);

    } catch (e) {
      debugPrint('❌ Erro na captura de planta: $e');
      if (mounted) {
        setState(() => _isProcessing = false);
        AppFeedback.showError(context, 'Erro ao capturar: $e');
      }
    }
  }

  Future<void> _analyzePlant(File image) async {
    try {
       // Reset Global Analysis Notifier
       ref.read(analysisNotifierProvider.notifier).reset();

       final String locale = Localizations.localeOf(context).toString();
       
       // Trigger Analysis using Global Provider (reused for Plant/Pet for now)
       final resultState = await ref.read(analysisNotifierProvider.notifier).analyzeImage(
          imageFile: image,
          mode: ScannutMode.plant,
          locale: locale,
       );
       
       if (!mounted) return;

       if (resultState is AnalysisSuccess && resultState.data is PlantAnalysisModel) {
          final plantData = resultState.data as PlantAnalysisModel;
          
          // Auto-Save logic moved here
          await BotanyService().savePlantAnalysis(plantData, image);

          _showResultSheet(plantData, image);
       } else if (resultState is AnalysisError) {
          AppFeedback.showError(context, resultState.message);
       }

    } catch (e) {
      debugPrint("❌ Plant Analysis Error: $e");
      if(mounted) AppFeedback.showError(context, "Erro na análise: $e");
    } finally {
      if(mounted) {
        setState(() {
          _isProcessing = false;
          _capturedImage = null; // Clear preview to get ready for next
        });
        ref.read(analysisNotifierProvider.notifier).reset();
      }
    }
  }

  void _showResultSheet(PlantAnalysisModel data, File image) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlantResultCard(
        analysis: data, 
        imagePath: image.path,
        onSave: () {}, // Already saved
        onShop: () {}, 
      ),
    );
  }

  Future<File> _optimizeImage(File original) async {
    final tempDir = await getTemporaryDirectory();
    final targetPath = path.join(tempDir.path, 'plant_opt_${DateTime.now().millisecondsSinceEpoch}.jpg');
    
    final result = await FlutterImageCompress.compressAndGetFile(
      original.absolute.path,
      targetPath,
      minWidth: 1080,
      minHeight: 1440,
      quality: 70,
    );
    
    return File(result?.path ?? original.path);
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return const SizedBox.shrink();

    // Watch global provider just for loading feedback if needed, 
    // although we are using local _isProcessing mostly.
    final analysisState = ref.watch(analysisNotifierProvider);
    final isLoading = _isProcessing || analysisState is AnalysisLoading;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Camera
        if (_capturedImage != null)
           Image.file(_capturedImage!, fit: BoxFit.cover)
        else if (_controller != null && _controller!.value.isInitialized)
           CameraPreview(_controller!)
        else
           Container(color: Colors.black),
        
        // 2. Overlay Frame
        _buildOverlayFrame(context),

        // 3. Loading
        if (isLoading) _buildLoadingOverlay(context),

        // 4. Controls
        if (!isLoading) _buildControls(context),

        // 5. Top Actions
        if (!isLoading) _buildTopActions(context),
      ],
    );
  }

  Widget _buildOverlayFrame(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
           Padding(
             padding: const EdgeInsets.only(bottom: 16),
             child: Container(
               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
               decoration: BoxDecoration(
                 color: _domainColor,
                 borderRadius: BorderRadius.circular(20),
                 boxShadow: [
                   BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0,2))
                 ]
               ),
               child: Text(
                 l10n.homeHintPlant,
                 style: GoogleFonts.poppins(
                   color: Colors.black,
                   fontWeight: FontWeight.w600,
                   fontSize: 14
                 ),
               ),
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
      child: Container(
        decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: IconButton(
          icon: Icon(Icons.history, color: _domainColor, size: 28),
          tooltip: AppLocalizations.of(context)!.tooltipBotanyHistory,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BotanyHistoryScreen()),
            );
          },
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    final totalOffset = 116.0; // Align with Food Body
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: totalOffset),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Gallery
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker(); // Lazy load
                  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setState(() {
                       _capturedImage = File(image.path);
                       _isProcessing = true;
                    });
                    await _analyzePlant(_capturedImage!);
                  }
                },
                child: Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                    border: Border.all(color: _domainColor, width: 2),
                  ),
                  child: Icon(Icons.photo_library, color: _domainColor, size: 26),
                ),
              ),
              const SizedBox(width: 30),
              // Shutter
              GestureDetector(
                onTap: _onCapture,
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _domainColor, width: 4),
                    color: _domainColor.withValues(alpha: 0.2),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _domainColor,
                    ),
                    child: const Icon(Icons.camera_alt, color: AppDesign.backgroundDark, size: 36),
                  ),
                ),
              ),
              const SizedBox(width: 86),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               CircularProgressIndicator(color: _domainColor),
               const SizedBox(height: 16),
               Text(
                 AppLocalizations.of(context)!.loadingPlant,
                 style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold),
               )
            ],
          ),
        ),
      ),
    );
  }
}