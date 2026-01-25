import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_design.dart';
import '../../../../l10n/app_localizations.dart';
import '../../models/walk_models.dart';
import '../../models/pet_profile_extended.dart';
import '../../services/scan_walk_service.dart';
import '../../services/session_guard.dart';

class ScanWalkScreen extends StatefulWidget {
  const ScanWalkScreen({super.key});

  @override
  State<ScanWalkScreen> createState() => _ScanWalkScreenState();
}

class _ScanWalkScreenState extends State<ScanWalkScreen>
    with TickerProviderStateMixin {
  // --- STATE ---
  bool _isWalking = false;
  DateTime? _walkStartTime;
  Timer? _walkTimer;
  Duration _walkDuration = Duration.zero;
  double _distanceKm = 0.0;

  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isAnalyzing = false; // Overlay for AI processing

  final List<WalkEvent> _events = [];
  final ImagePicker _picker = ImagePicker();
  final ScanWalkService _walkService = ScanWalkService();
  PetProfileExtended? _activePet;
  StreamSubscription<Position>? _positionStream;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    // 🛡️ [CHECK-IN INTELIGENTE] - Lógica de Entrada Zero Fricção
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final guard = SessionGuard();
      final pet = await guard.validatePetSession(context);

      if (pet == null) {
        if (mounted) Navigator.pop(context);
        return;
      }

      if (mounted) {
        setState(() {
          _activePet = pet;
        });
      }
    });
  }

  @override
  void dispose() {
    _walkTimer?.cancel();
    _positionStream?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  // --- CORE ACTIONS ---

  void _startWalkSequence() async {
    final l10n = AppLocalizations.of(context)!;
    final hasPerm = await _walkService.checkPermissions();
    if (!hasPerm) {
      _showError(l10n.errorLocation);
      return;
    }

    setState(() {
      _isWalking = true;
      _walkStartTime = DateTime.now();
      _walkDuration = Duration.zero;
      _distanceKm = 0.0;
      _events.clear();
    });

    _positionStream =
        _walkService.getPositionStream().listen((Position position) {
      if (mounted) {
        setState(() {
          if (_currentPosition != null) {
            final dist = Geolocator.distanceBetween(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
                position.latitude,
                position.longitude);
            if (dist > 5) {
              // Jitter filter
              _distanceKm += (dist / 1000.0);
            }
          }
          _currentPosition = position;
        });
      }
    });

    _walkTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _walkDuration = Duration(seconds: _walkDuration.inSeconds + 1);
        });
      }
    });
  }

  void _stopWalk() async {
    if (_walkDuration.inSeconds < 10 && _events.isEmpty) {
      Navigator.pop(context);
      return;
    }

    _walkTimer?.cancel();
    _positionStream?.cancel();

    final kcalBurned = (_distanceKm * 60).toInt();

    // 🛡️ [AUTO-SAVE & PERSISTÊNCIA]
    if (_activePet != null && _walkStartTime != null) {
      final session = WalkSession(
        id: const Uuid().v4(),
        startTime: _walkStartTime!,
        endTime: DateTime.now(),
        petId: _activePet!.id,
        events: List.from(_events),
        distanceKm: _distanceKm,
        caloriesBurned: kcalBurned,
        safetyCheckCompleted: true,
      );

      await _walkService.saveWalkSession(session);
    }

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildEndWalkSummary(kcalBurned),
    );

    if (mounted) Navigator.pop(context);
  }

  // --- TRIPLE-INPUT LOGIC (8 ICONS) ---

  Future<void> _handleEvent(WalkEventType type) async {
    final l10n = AppLocalizations.of(context)!;
    String? photoPath;
    String? audioPath;
    int? bristol;
    String? description;

    switch (type) {
      case WalkEventType.poo:
        final XFile? photo =
            await _picker.pickImage(source: ImageSource.camera);
        if (photo == null) return;
        photoPath = photo.path;

        setState(() => _isAnalyzing = true);
        await Future.delayed(const Duration(seconds: 1)); // AI Mock
        bristol = 4;
        description = "IA Bristol: 4 (${l10n.walkBristolIdeal})";
        setState(() => _isAnalyzing = false);
        break;

      case WalkEventType.friend:
        audioPath = await _recordVoiceSnippet(l10n.walkVoicePromptFriend);
        description = l10n.walkFriendDesc;
        break;

      case WalkEventType.bark:
        audioPath = await _recordVoiceSnippet(l10n.walkAnalysisBark);
        description = "IA Vocal: Alerta";
        break;

      case WalkEventType.hazard:
      case WalkEventType.fight:
        final XFile? photo =
            await _picker.pickImage(source: ImageSource.camera);
        photoPath = photo?.path;
        audioPath = await _recordVoiceSnippet(type == WalkEventType.hazard
            ? l10n.walkVoicePromptDanger
            : l10n.walkVoicePromptFight);
        description = type == WalkEventType.hazard
            ? l10n.walkHazardDesc
            : l10n.walkFightDesc;
        break;

      default:
        description = l10n.walkSaveSuccess;
        break;
    }

    _addEvent(WalkEvent(
      timestamp: DateTime.now(),
      type: type,
      description: description,
      photoPath: photoPath,
      audioPath: audioPath,
      bristolScore: bristol,
      lat: _currentPosition?.latitude,
      lng: _currentPosition?.longitude,
    ));

    _showToast(l10n.walkSaveSuccess);
  }

  Future<String?> _recordVoiceSnippet(String prompt) async {
    if (await Permission.microphone.request().isDenied) return null;

    final dir = await getApplicationDocumentsDirectory();
    final path =
        '${dir.path}/walk_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _audioRecorder.start(const RecordConfig(), path: path);
    setState(() => _isRecording = true);
    await Future.delayed(const Duration(seconds: 4));
    await _audioRecorder.stop();
    setState(() => _isRecording = false);
    return path;
  }

  void _addEvent(WalkEvent event) {
    setState(() {
      _events.add(event);
    });
  }

  // --- UI BUILDING (FULLSCREEN) ---

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppDesign.backgroundDark,
      body: Stack(
        children: [
          Positioned.fill(child: _buildMapLayer()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _isWalking ? _buildStatPill() : const SizedBox.shrink(),
                  _buildCloseButton(),
                ],
              ),
            ),
          ),
          if (_isWalking)
            Center(
              child: _buildCentralTrigger(),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _isWalking
                ? _buildTacticalGrid(l10n)
                : _buildStartOverlay(l10n),
          ),
          if (_isAnalyzing) Positioned.fill(child: _buildAnalysisOverlay(l10n)),
        ],
      ),
    );
  }

  Widget _buildMapLayer() {
    return Container(
      color: const Color(0xFF151515),
      child: Stack(
        children: [
          CustomPaint(size: Size.infinite, painter: MapPainter()),
          const Center(
            child: _PulseMarker(color: AppDesign.petPink),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill() {
    final timerText =
        "${_walkDuration.inMinutes.toString().padLeft(2, '0')}:${(_walkDuration.inSeconds % 60).toString().padLeft(2, '0')}";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, color: AppDesign.petPink, size: 18),
          const SizedBox(width: 8),
          Text(timerText,
              style: GoogleFonts.robotoMono(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          Container(width: 1, height: 15, color: Colors.white24),
          const SizedBox(width: 12),
          Text("${_distanceKm.toStringAsFixed(2)} km",
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildCloseButton() {
    return GestureDetector(
      onTap: () {
        if (_isWalking) {
          _confirmExit();
        } else {
          Navigator.pop(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white10),
        ),
        child: const Icon(Icons.close, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildCentralTrigger() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _handleEvent(WalkEventType.others),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: AppDesign.petPink.withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 10),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppDesign.petPink, width: 2),
                  ),
                ),
                Container(
                  width: 75,
                  height: 75,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: _activePet?.imagePath != null
                        ? DecorationImage(
                            image: FileImage(File(_activePet!.imagePath!)),
                            fit: BoxFit.cover)
                        : null,
                  ),
                  child: _activePet?.imagePath == null
                      ? const Icon(Icons.pets, color: Colors.white)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.black, size: 20),
                  ),
                )
              ],
            ),
          ),
        ),
        if (_isRecording)
          Padding(
            padding: const EdgeInsets.only(top: 15),
            child: _buildMicPulse(),
          ),
      ],
    );
  }

  Widget _buildTacticalGrid(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildGridRow([
            _GridItem(l10n.walkXixi, Icons.water_drop, Colors.blue,
                () => _handleEvent(WalkEventType.pee)),
            _GridItem(l10n.walkFezes, Icons.circle, Colors.brown,
                () => _handleEvent(WalkEventType.poo)),
            _GridItem(l10n.walkAgua, Icons.local_drink, Colors.lightBlue,
                () => _handleEvent(WalkEventType.water)),
            _GridItem(l10n.walkOutros, Icons.more_horiz, Colors.grey,
                () => _handleEvent(WalkEventType.others)),
          ]),
          const SizedBox(height: 16),
          _buildGridRow([
            _GridItem(l10n.walkAmigo, Icons.person_add, Colors.purple,
                () => _handleEvent(WalkEventType.friend)),
            _GridItem(l10n.walkLatido, Icons.graphic_eq, Colors.green,
                () => _handleEvent(WalkEventType.bark)),
            _GridItem(l10n.walkPerigo, Icons.warning_amber, Colors.orange,
                () => _handleEvent(WalkEventType.hazard)),
            _GridItem(l10n.walkBrigas, Icons.bolt, Colors.red,
                () => _handleEvent(WalkEventType.fight)),
          ]),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _stopWalk,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                l10n.commonClose.toUpperCase(),
                style: GoogleFonts.poppins(
                    color: Colors.white60,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGridRow(List<Widget> children) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: children,
    );
  }

  Widget _buildStartOverlay(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "${l10n.tabScanWalk}: ${_activePet?.petName ?? '...'}",
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.instructionPetBody,
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _startWalkSequence,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppDesign.petPink,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(l10n.scanWalkStart.toUpperCase(),
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  void _confirmExit() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppDesign.surfaceDark,
        title: Text(l10n.walkExitConfirm,
            style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.commonNo)),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                _stopWalk();
              },
              child: Text(l10n.commonYes)),
        ],
      ),
    );
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppDesign.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  Widget _buildAnalysisOverlay(AppLocalizations l10n) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppDesign.petPink),
            const SizedBox(height: 20),
            Text(l10n.walkAnalysisStool,
                style: GoogleFonts.poppins(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildMicPulse() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.mic, color: Colors.blueAccent, size: 16),
        const SizedBox(width: 8),
        Text("Listening...",
            style: GoogleFonts.poppins(
                color: Colors.blueAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildEndWalkSummary(int kcal) {
    final l10n = AppLocalizations.of(context)!;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Color(0xFF151515),
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, color: Colors.white24),
            const SizedBox(height: 24),
            const Icon(Icons.check_circle_outline,
                color: Colors.greenAccent, size: 60),
            const SizedBox(height: 16),
            Text(l10n.walkSaveSuccess,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryStat(
                    l10n.scanWalkDuration, "${_walkDuration.inMinutes}m"),
                _buildSummaryStat(l10n.scanWalkDistance,
                    "${_distanceKm.toStringAsFixed(1)}km"),
                _buildSummaryStat("Kcal", "$kcal"),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(l10n.commonClose.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white30, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: GoogleFonts.robotoMono(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _GridItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _GridItem(this.label, this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.18,
            height: MediaQuery.of(context).size.width * 0.18,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PulseMarker extends StatefulWidget {
  final Color color;
  const _PulseMarker({required this.color});

  @override
  State<_PulseMarker> createState() => _PulseMarkerState();
}

class _PulseMarkerState extends State<_PulseMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: (1 - _ctrl.value) * 0.5),
            border: Border.all(
                color: widget.color.withValues(alpha: 1 - _ctrl.value),
                width: 2),
          ),
          child: Center(
            child: Container(
              width: 12,
              height: 12,
              decoration:
                  BoxDecoration(color: widget.color, shape: BoxShape.circle),
            ),
          ),
        );
      },
    );
  }
}
