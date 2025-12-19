import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Core
import '../../../core/providers/analysis_provider.dart';
import '../../../core/models/analysis_state.dart';
import '../../../core/enums/scannut_mode.dart';

// Models
import '../../food/models/food_analysis_model.dart';
import '../../plant/models/plant_analysis_model.dart';
import '../../pet/models/pet_analysis_result.dart';

// Widgets
import '../../food/presentation/widgets/result_card.dart';
import '../../plant/presentation/widgets/plant_result_card.dart';
import '../../pet/presentation/widgets/pet_result_card.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  int _currentIndex = 0;
  bool _isCameraInitialized = false;
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
    await _initCamera();
    setState(() {
      _isLoading = false;
    });
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
          backgroundColor: Colors.black.withOpacity(0.8),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFF00E676), width: 1)),
          title: Text(l10n.disclaimerTitle,
              style: const TextStyle(color: Colors.white)),
          content: Text(
            l10n.disclaimerBody,
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('disclaimer_accepted', true);
                if (mounted) Navigator.pop(context);
              },
              child: Text(l10n.disclaimerButton,
                  style: const TextStyle(
                      color: Color(0xFF00E676), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      try {
        _cameras = await availableCameras();
        if (_cameras != null && _cameras!.isNotEmpty) {
          _controller = CameraController(
            _cameras![0],
            ResolutionPreset.high,
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
      }
    }
  }

  Future<void> _onCapture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    // Check current analysis state
    final analysisState = ref.read(analysisNotifierProvider);
    if (analysisState is AnalysisLoading) return; // Prevent multiple captures

    try {
      // Capture image
      final image = await _controller!.takePicture();
      final File imageFile = File(image.path);

      if (!mounted) return;

      // Determine mode
      final ScannutMode mode = _currentIndex == 0
          ? ScannutMode.food
          : _currentIndex == 1
              ? ScannutMode.plant
              : ScannutMode.pet;

      // Trigger analysis
      await ref.read(analysisNotifierProvider.notifier).analyzeImage(
            imageFile: imageFile,
            mode: mode,
          );

      // Listen for state changes and show result
      _handleAnalysisResult();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao capturar imagem: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleAnalysisResult() {
    final state = ref.read(analysisNotifierProvider);

    if (state is AnalysisSuccess) {
      if (state.data is FoodAnalysisModel) {
        _showResultSheet(
          context,
          ResultCard(
            analysis: state.data as FoodAnalysisModel,
            onSave: () => _handleSave('Food'),
          ),
        );
      } else if (state.data is PlantAnalysisModel) {
        _showResultSheet(
          context,
          PlantResultCard(
            analysis: state.data as PlantAnalysisModel,
            onSave: () => _handleSave('Plant'),
            onShop: () => _handleShop(),
          ),
        );
      } else if (state.data is PetAnalysisResult) {
        _showResultSheet(
          context,
          PetResultCard(
            analysis: state.data as PetAnalysisResult,
            onSave: () => _handleSave('Pet'),
          ),
        );
      }
    } else if (state is AnalysisError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showResultSheet(BuildContext context, Widget child) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => child,
    );
  }

  void _handleSave(String type) {
    // Implement save logic (e.g. Hive or Database)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$type salvo com sucesso!')),
    );
    // Reset state after saving
    ref.read(analysisNotifierProvider.notifier).reset();
  }

  void _handleShop() {
    // Implement shop navigation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Redirecionando para loja parceira...')),
    );
  }
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00E676))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Layer
          if (_isCameraInitialized && _controller != null)
            CameraPreview(_controller!)
          else
            Container(color: Colors.black),

          // 2. Scan Frame Overlay
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.5), width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                  // Corner accents
                  Positioned(
                    top: -2,
                    left: -2,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: const Color(0xFF00E676), width: 4),
                          left: BorderSide(color: const Color(0xFF00E676), width: 4),
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
                          top: BorderSide(color: const Color(0xFF00E676), width: 4),
                          right: BorderSide(color: const Color(0xFF00E676), width: 4),
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
                          bottom: BorderSide(color: const Color(0xFF00E676), width: 4),
                          left: BorderSide(color: const Color(0xFF00E676), width: 4),
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
                          bottom: BorderSide(color: const Color(0xFF00E676), width: 4),
                          right: BorderSide(color: const Color(0xFF00E676), width: 4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. UI Overlay (Pet Emergency Button)
          if (_currentIndex == 2)
            Positioned(
              top: 60,
              right: 20,
              child: _buildEmergencyButton(),
            ),
          
          // 3. Shutter Button (Center)
          Positioned(
            bottom: 120, // Position above bottom bar
            left: 0,
            right: 0,
            child: Center(
              child: _buildShutterButton(),
            ),
          ),

          // 4. Loading Overlay - Using Consumer to watch analysis state
          Consumer(
            builder: (context, ref, child) {
              final analysisState = ref.watch(analysisNotifierProvider);
              if (analysisState is AnalysisLoading) {
                return Container(
                  color: Colors.black54,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: Color(0xFF00E676)),
                        const SizedBox(height: 16),
                        Text(
                          analysisState.message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(blurRadius: 10, color: Colors.black, offset: Offset(2, 2))
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
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
    );
  }

   Widget _buildShutterButton() {
    return GestureDetector(
      onTap: _onCapture,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          color: Colors.white.withOpacity(0.2),
        ),
        padding: const EdgeInsets.all(4),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: const Icon(Icons.camera_alt, color: Colors.black, size: 30),
        ),
      ),
    );
  }

  Widget _buildEmergencyButton() {
     final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () {
        // Implement Action
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(l10n.emergencyCall + '...')),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.6),
              border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.phone_in_talk, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.emergencyCall,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(0, CupertinoIcons.apple, l10n.tabFood, Colors.redAccent),
                _buildNavItem(1, Icons.grass, l10n.tabPlants, Colors.greenAccent),
                _buildNavItem(2, Icons.pets, l10n.tabPets, Colors.orangeAccent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, Color activeColor) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : Colors.white60,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : Colors.white60,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
