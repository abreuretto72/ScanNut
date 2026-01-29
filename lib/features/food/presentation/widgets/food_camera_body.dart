
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

import '../../l10n/app_localizations.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../core/utils/permission_helper.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/models/analysis_state.dart';
import '../../providers/food_analysis_provider.dart';
import '../food_router.dart';
import './food_camera_overlay.dart';

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
    debugPrint('🔄 [FoodCameraBody] Lifecycle Change: $state');
    final controller = _controller;
    
    // Se a aplicação for minimizada ou perder foco (ex: Galeria)
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      if (controller != null && controller.value.isInitialized) {
        _disposeCamera();
      }
    } 
    // Se a aplicação voltar ao foco e esta aba estiver ativa
    else if (state == AppLifecycleState.resumed) {
      if (widget.isActive) {
         _initCamera();
      }
    }
  }

  Future<void> _initCamera() async {
    if (_isInitializing || _controller != null) return;
    if (!mounted) return;

    debugPrint('📷 [FoodTrace] Initializing Camera');
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
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isProcessing) return;

    // 1. Reset Mandatório de Estado (Lei de Ferro)
    ref.read(foodAnalysisNotifierProvider.notifier).reset();

    try {
      debugPrint('📸 [FoodTrace] Capture started');
      setState(() => _isProcessing = true);
      HapticFeedback.mediumImpact();

      // 2. Captura
      final XFile rawFile = await controller.takePicture();
      final File optimizedFile = await _optimizeImage(File(rawFile.path));
      
      if (!mounted) return;

      // 3. Preview
      setState(() {
        _capturedImage = optimizedFile;
      });

      // 4. Disparo Seguro
      debugPrint('🚀 [FoodTrace] Triggering analyzeAndOpen from Camera');
      await FoodRouter.analyzeAndOpen(
        context: context, 
        ref: ref, 
        image: optimizedFile
      );

    } catch (e) {
      debugPrint('❌ Erro na captura de comida: $e');
      if (mounted) {
        AppFeedback.showError(context, 'Erro ao capturar: $e');
      }
    } finally {
      // 5. Liberação Obrigatória de Recursos
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _capturedImage = null; // Limpa preview para liberar câmera
        });
      }
    }
  }

  Future<void> _pickFromGallery() async {
    // 1. Reset Mandatório (Start Fresh)
    ref.read(foodAnalysisNotifierProvider.notifier).reset();

    try {
      final picker = ImagePicker();
      // 2. Await User Input
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        debugPrint('🖼️ [FoodTrace] Image picked from gallery: ${image.path}');
        
        setState(() => _isProcessing = true);
        
        final File optimizedFile = await _optimizeImage(File(image.path));
        
        if (mounted) {
           setState(() => _capturedImage = optimizedFile);
           
           await FoodRouter.analyzeAndOpen(
              context: context, 
              ref: ref, 
              image: optimizedFile
           );
        }
      } else {
        debugPrint('⚠️ Seleção da galeria cancelada pelo usuário.');
      }
    } catch (e) {
      debugPrint('❌ Erro na galeria: $e');
      if (mounted) {
        AppFeedback.showError(context, 'Erro na galeria: $e');
      }
    } finally {
      // 3. Liberação de Estado (Garante que botões desbloqueiem)
      if (mounted) {
         setState(() {
           _isProcessing = false;
           _capturedImage = null;
         });
         
         // 🛡️ REPARO DE CICLO DE VIDA: Força reinicialização da câmera ao retornar da galeria
         // O ImagePicker pode causar pausa da atividade, e o lifecycle pode não ter recuperado a tempo.
         if (widget.isActive && (_controller == null || !_controller!.value.isInitialized)) {
            debugPrint('🔄 [FoodTrace] Forçando reinicialização da câmera após Galeria');
            await _initCamera();
         }
      }
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

    final captured = _capturedImage;
    final controller = _controller;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Camera Preview ou Imagem Capturada
        if (captured != null)
          Image.file(captured, fit: BoxFit.cover)
        else if (controller != null && controller.value.isInitialized)
          CameraPreview(controller)
        else
          Container(color: Colors.black),

        // 2. MOLDURA DE ENQUADRAMENTO (Lei de Ferro)
        // Sempre visível se a câmera estiver ativa, mesmo durante processamento
        if (controller != null && controller.value.isInitialized)
          const FoodCameraOverlay(),

        // 3. Loading Overlay (Estilo V135)
        if (isLoading) _buildLoadingOverlay(context, analysisState),

        // 4. Controles de Captura (Escondidos se carregando)
        if (!isLoading) _buildControls(context),
        
        // 5. Domain Top Actions (Isolado no Micro-App)
        if (!isLoading) _buildTopActions(context),
      ],
    );
  }

  Widget _buildTopActions(BuildContext context) {
    return Positioned(
      top: 50,
      right: 20,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // History Button
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: IconButton(
              icon: const Icon(Icons.history, color: AppDesign.foodOrange, size: 28),
              tooltip: FoodLocalizations.of(context)?.foodTooltipNutritionHistory,
              onPressed: () => FoodRouter.navigateToHistory(context),
            ),
          ),
          const SizedBox(width: 12),
          
          // 🚀 MEAL ANALYSIS (Central & Exclusive)
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppDesign.foodOrange.withValues(alpha: 0.8), width: 1.5),
            ),
            child: IconButton(
              icon: const Icon(Icons.restaurant, color: AppDesign.foodOrange, size: 28), 
              tooltip: "Chef Vision: Sugestão de Receitas",
              onPressed: _onChefVision,
            ),
            ),
          const SizedBox(width: 12),

          // Management
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: IconButton(
              icon: const Icon(Icons.restaurant_menu, color: AppDesign.foodOrange, size: 28),
              tooltip: FoodLocalizations.of(context)?.foodTooltipNutritionManagement,
              onPressed: () => FoodRouter.navigateToManagement(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onChefVision() async {
    final constraintController = TextEditingController();
    
    // Show Selection Dialog
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // Allow keyboard
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: AppDesign.backgroundDark.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            border: Border.all(color: AppDesign.success.withValues(alpha: 0.5)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              
              const Icon(Icons.auto_awesome, color: AppDesign.success, size: 40),
              const SizedBox(height: 12),
              
              Text(
                "Chef Vision", 
                style: GoogleFonts.poppins(color: AppDesign.success, fontSize: 22, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 8),
              Text(
                "Mostre seus ingredientes! Aponte a câmera para os alimentos (na geladeira ou bancada) e eu sugerirei receitas completas para você.", 
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center
              ),
              
              const SizedBox(height: 24),
              
              // Input de Restrições (Saneamento V135)
              TextField(
                controller: constraintController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Ex: Sem fritura, tenho pressa, sou vegano...",
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.mic, color: AppDesign.foodOrange), // Visual cue for voice (impl: text for now)
                ),
              ),
              
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionTile(Icons.camera_alt, "Câmera", () {
                     Navigator.pop(context);
                     _pickChefVisionImage(ImageSource.camera, constraintController.text);
                  }),
                  _buildActionTile(Icons.photo_library, "Galeria", () {
                     Navigator.pop(context);
                     _pickChefVisionImage(ImageSource.gallery, constraintController.text);
                  }),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: Colors.white10,
              shape: BoxShape.circle,
              border: Border.all(color: AppDesign.foodOrange),
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white70))
        ],
      ),
    );
  }

  Future<void> _pickChefVisionImage(ImageSource source, String constraints) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);
      
      if (image != null && mounted) {
        final File rawFile = File(image.path);
        
        await FoodRouter.analyzeAndOpen(
           context: context, 
           ref: ref, 
           image: rawFile,
           isChefVision: true,
           userConstraints: constraints
        );
      }
    } catch (e) {
      debugPrint("❌ Error picking chef vision image: $e");
    }
  }

  Widget _buildLoadingOverlay(BuildContext context, AnalysisState state) {
    String message = 'Processando...';
    if (state is AnalysisLoading) {
      final l10n = FoodLocalizations.of(context);
      message = l10n?.foodLoading ?? "Analisando...";
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
    // 🛡️ Samsung A25 Defense: Eleva os botões acima da NavigationBar de domínios (80px + 16px padding + margin)
    final totalOffset = 116.0;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: totalOffset),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // 🛡️ V135: Compact Layout
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
              
              const SizedBox(width: 86), // Balanço visual para o botão de troca de câmera (se existisse à direita)
            ],
          ),
        ),
      ),
    );
  }
}
