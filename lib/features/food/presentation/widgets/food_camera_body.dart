
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
import '../../providers/food_analysis_provider.dart';
import '../food_router.dart';

/// 📸 FOOD DOMAIN CAMERA BODY (V135)
/// Micro-app independente para captura e análise de comida.
/// Gerencia seu próprio CameraController, evitando erros de dispose na HomeView.
class FoodCameraBody extends ConsumerStatefulWidget {
  final bool isActive;

  const FoodCameraBody({
    super.key,
    required this.isActive,
  });

  @override
  ConsumerState<FoodCameraBody> createState() => _FoodCameraBodyState();
}

class _FoodCameraBodyState extends ConsumerState<FoodCameraBody> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitializing = false;
  bool _isProcessing = false;
  File? _capturedImage;
  
  // Constantes de Design V135
  final Color _domainColor = AppDesign.foodOrange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.isActive) {
      _initCamera();
    }
  }

  @override
  void didUpdateWidget(FoodCameraBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      // Entrou na aba de Comida
      _initCamera();
    } else if (!widget.isActive && oldWidget.isActive) {
      // Saiu da aba de Comida
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
    if (!_controller!.value.isInitialized) return;

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
        debugPrint('🚫 Permissão de câmera negada no FoodBody');
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
      debugPrint('❌ Erro ao iniciar câmera no FoodBody: $e');
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  Future<void> _disposeCamera() async {
    if (_controller != null) {
      final camera = _controller;
      _controller = null; // Detach first
      if (mounted) setState(() {});
      try {
        await camera?.dispose();
        debugPrint('♻️ Câmera de Comida liberada.');
      } catch (e) {
        debugPrint('⚠️ Erro ao liberar câmera: $e');
      }
    }
  }

  Future<void> _onCapture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isProcessing) return;

    try {
      setState(() => _isProcessing = true);
      HapticFeedback.mediumImpact();

      final XFile rawFile = await _controller!.takePicture();
      final File optimizedFile = await _optimizeImage(File(rawFile.path));
      
      if (!mounted) return;

      // Atualiza visualização local
      setState(() {
        _capturedImage = optimizedFile;
      });

      // 🛡️ INJEÇÃO V135: Disparo de Análise + Auto-Save
      // O FoodAnalysisNotifier já contém a lógica de Auto-Save (verif. passo 3686)
      await FoodRouter.analyzeAndOpen(
        context: context, 
        ref: ref, 
        image: optimizedFile
      );

      // Limpa estado local após retorno (se necessário)
      if (mounted) {
         setState(() {
            _isProcessing = false;
            _capturedImage = null; // Limpa preview para próxima foto
         });
      }

    } catch (e) {
      debugPrint('❌ Erro na captura de comida: $e');
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
        setState(() => _isProcessing = true);
        final File optimizedFile = await _optimizeImage(File(image.path));
        
        if (mounted) {
           setState(() => _capturedImage = optimizedFile);
           
           await FoodRouter.analyzeAndOpen(
              context: context, 
              ref: ref, 
              image: optimizedFile
           );
           
           if(mounted) {
              setState(() {
                _isProcessing = false;
                _capturedImage = null;
              });
           }
        }
      }
    } catch (e) {
      debugPrint('❌ Erro na galeria: $e');
    }
  }

  Future<File> _optimizeImage(File original) async {
    final tempDir = await getTemporaryDirectory();
    final targetPath = path.join(tempDir.path, 'food_opt_${DateTime.now().millisecondsSinceEpoch}.jpg');
    
    final result = await FlutterImageCompress.compressAndGetFile(
      original.absolute.path,
      targetPath,
      minWidth: 1080,
      minHeight: 1920,
      quality: 75,
    );
    
    return File(result?.path ?? original.path);
  }

  @override
  Widget build(BuildContext context) {
    // 🛡️ Monitoramento de Estado Global (Feedback V135)
    final analysisState = ref.watch(foodAnalysisNotifierProvider);
    final isLoading = analysisState is AnalysisLoading || _isProcessing;

    if (!widget.isActive) return const SizedBox.shrink();

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Camera Preview ou Imagem Capturada
        if (_capturedImage != null)
          Image.file(_capturedImage!, fit: BoxFit.cover)
        else if (_controller != null && _controller!.value.isInitialized)
          CameraPreview(_controller!)
        else
          Container(color: Colors.black),

        // 2. Loading Overlay (Estilo V135)
        if (isLoading) _buildLoadingOverlay(context, analysisState),

        // 3. Controles de Captura (Escondidos se carregando)
        if (!isLoading) _buildControls(context),
      ],
    );
  }

  Widget _buildLoadingOverlay(BuildContext context, AnalysisState state) {
    String message = 'Processando...';
    if (state is AnalysisLoading) {
      message = AppLocalizations.of(context)!.loadingFood; // Usa string traduzida "Analizando la imagen de comida..."
    }

    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: _domainColor,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Text(
                      message,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    return Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
            padding: const EdgeInsets.only(bottom: 120), // Espaço para BottomBar
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Galeria
                GestureDetector(
                  onTap: _pickFromGallery,
                  child: Container(
                    width: 56,
                    height: 56,
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
                    width: 80,
                    height: 80,
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
                
                const SizedBox(width: 86), // Balanço
              ],
            )));
  }
}
