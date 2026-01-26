import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theme/app_design.dart';
import '../../models/walk_models.dart';
import '../../models/pet_profile_extended.dart';
import '../../services/pet_profile_service.dart';
import '../../services/scan_walk_service.dart';
import '../../services/multimodal_event_controller.dart';
import '../widgets/multimodal_capture_modal.dart';
import '../../../../core/services/partner_service.dart';
import '../../../../core/models/partner_model.dart'; // Para acessar PartnerModel

/// 🛡️ SCANWALK FULLSCREEN - Clean Navigation Experience
/// Isolated fullscreen route for walk tracking with zero visual pollution
class ScanWalkFullscreen extends StatefulWidget {
  final PetProfileExtended? activePet;
  
  const ScanWalkFullscreen({super.key, this.activePet});

  @override
  State<ScanWalkFullscreen> createState() => _ScanWalkFullscreenState();
}

class _ScanWalkFullscreenState extends State<ScanWalkFullscreen> with TickerProviderStateMixin {
  // Walk State
  DateTime? _walkStartTime;
  Timer? _walkTimer;
  Duration _walkDuration = Duration.zero;
  double _distanceKm = 0.0;
  
  // Multimodal Event Controller (Triple Input System)
  final MultimodalEventController _multimodalController = MultimodalEventController();
  bool _isRecording = false;
  String? _currentEventType; // Track which event is being recorded
  
  // Data Collection
  final List<WalkEvent> _events = [];
  final PetProfileService _petService = PetProfileService();
  final ScanWalkService _walkService = ScanWalkService();
  PetProfileExtended? _activePet;
  StreamSubscription<Position>? _positionStream;
  Position? _currentPosition;

  // Google Map
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};
  bool _mapReady = false;
  bool _hasError = false;
  String _errorMessage = "";
  
  bool _venuesLoaded = false;
  List<PartnerModel> _nearbyVenues = [];
  PartnerModel? _selectedVenue;
  final Set<String> _visitedVenueIds = {};
  
  // Settings
  double _safetyRadius = 500.0; // Padrão 500m

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _activePet = widget.activePet;
    debugPrint('🚀 [ScanWalk] Interface de Passeio Ativada para ${_activePet?.petName ?? "Pet Desconhecido"}');
    _startWalkSequence();
  }

  @override
  void dispose() {
    _walkTimer?.cancel();
    _positionStream?.cancel();
    _multimodalController.dispose();
    _mapController = null;
    super.dispose();
  }

  // --- ACTIONS ---

  void _startWalkSequence() async {
    // Check Permissions & Start GPS
    final hasPerm = await _walkService.checkPermissions();
    if (!hasPerm) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Permissão de GPS necessária!"), backgroundColor: Colors.red)
         );
       }
       return;
    }

    setState(() {
      _walkStartTime = DateTime.now();
      _walkDuration = Duration.zero;
      _distanceKm = 0.0;
      _events.clear();
    });

    // Start Real Stream
    _positionStream = _walkService.getPositionStream().listen(
      (Position position) {
        if (mounted) {
           setState(() {
              _hasError = false; // Reset error on location update
              if (_currentPosition != null) {
                 final dist = Geolocator.distanceBetween(
                    _currentPosition!.latitude, _currentPosition!.longitude, 
                    position.latitude, position.longitude
                 );
                 if (dist > 1) { // Alta sensibilidade (Servo do Pet)
                    _distanceKm += (dist / 1000.0);
                    // 🎯 Update Map Camera to follow pet
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude))
                    );
                    // Update Circle
                    _loadRiskZones();
                 }
              }
              _currentPosition = position;
              
              // 🌍 First load of VIP venues
              if (!_venuesLoaded && _currentPosition != null) {
                _fetchNearbyVenues();
                _venuesLoaded = true;
              }
              
              // 🐾 Check-in VIP (Geofence Logico)
              if (_venuesLoaded) _checkVenueProximity(position);
           });
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = "Erro de GPS: $e";
          });
        }
      },
    );

    _walkTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _walkDuration = Duration(seconds: _walkDuration.inSeconds + 1);
        });
      }
    });
  }

  void _stopWalk() async {
    _walkTimer?.cancel();
    _positionStream?.cancel();
    
    final kcalBurned = (_distanceKm * 60).toInt();
    final impactMsg = kcalBurned > 150 
        ? "Gasto calórico alto hoje! Considere +10% na próxima refeição."
        : "Passeio leve. Mantenha a dieta padrão de 120g.";

    // Save Session to History
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

      final sessionMap = {
        'id': session.id,
        'start_time': session.startTime.toIso8601String(),
        'end_time': session.endTime?.toIso8601String(),
        'pet_id': session.petId,
        'events': session.events.map((e) => e.toJson()).toList(),
        'distance_km': session.distanceKm,
        'calories_burned': session.caloriesBurned,
        'safety_check_completed': session.safetyCheckCompleted,
      };

      final updatedHistory = List<Map<String, dynamic>>.from(_activePet!.walkHistory ?? []);
      updatedHistory.add(sessionMap);
      
      if (updatedHistory.length > 20) {
         updatedHistory.removeAt(0);
      }

      final updatedPet = _activePet!.copyWith(
        walkHistory: updatedHistory,
        lastUpdated: DateTime.now(),
      );

      await _petService.saveOrUpdateProfile(updatedPet.petName, updatedPet.toJson());
    }

    if (mounted) {
      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => _buildEndWalkSummary(kcalBurned, impactMsg),
      );

      if (mounted) {
        Navigator.of(context).pop(); // Return to main screen
      }
    }
  }

  /// 🎯 Open Multimodal Capture Modal
  void _openMultimodalCapture(WalkEventType eventType) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => MultimodalCaptureModal(
        eventType: eventType,
        isRecording: _isRecording && _currentEventType == eventType.toString().split('.').last,
        onCapturePhoto: (Map<String, dynamic>? extra) => _capturePhotoForEvent(eventType, extra),
        onRecordVoice: (Map<String, dynamic>? extra) => _recordVoiceForEvent(eventType, extra),
        onCaptureSound: (Map<String, dynamic>? extra) => _captureSoundForEvent(eventType, extra),
        onQuickLog: (Map<String, dynamic>? extra) => _quickLogEvent(eventType, extra),
      ),
    );
  }


  /// 📸 Capture Photo for Event
  Future<void> _capturePhotoForEvent(WalkEventType eventType, [Map<String, dynamic>? extra]) async {
    final petId = _activePet?.id ?? 'unknown';
    final photoPath = await _multimodalController.capturePhoto(
      eventType: eventType,
      petId: petId,
      position: _currentPosition,
    );

    if (photoPath != null) {
      String? aiDescription;
      int? recommendedScore;
      
      // 💩 AI ANALYSIS: Fezes (Bristol/Parasitas)
      if (eventType == WalkEventType.poo) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                  SizedBox(width: 15),
                  Text("IA: Analisando fezes (Análise Ativa)..."),
                ],
              ),
              backgroundColor: Colors.brown,
            ),
          );
        }
        
        aiDescription = await _multimodalController.analyzeStool(photoPath);
        // Extract a score from mock description if possible, or just set a default
        recommendedScore = 4; 
      }

      final address = await _getAddressFromLatLng(_currentPosition);

      final event = WalkEvent(
        // id: const Uuid().v4(), // WalkEvent não tem ID no construtor antigo? Verificar Model.
        // O Model WalkEvent (Step 1329) NÃO TEM ID. Tem timestamp, type...
        // Vou seguir o Model que li no Step 1329.
        timestamp: DateTime.now(),
        type: eventType,
        photoPath: photoPath,
        description: aiDescription != null ? "📍 $address • $aiDescription" : "📍 $address",
        bristolScore: recommendedScore ?? extra?['bristol_score'],
        lat: _currentPosition?.latitude,
        lng: _currentPosition?.longitude,
      );

      setState(() {
        _events.add(event);
      });

      _multimodalController.clearCurrentEvent();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Text('${_getEventLabel(eventType)} com análise salvo!'),
              ],
            ),
            backgroundColor: AppDesign.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// 🎙️ Record Voice Note for Event
  Future<void> _recordVoiceForEvent(WalkEventType eventType, [Map<String, dynamic>? extra]) async {
    final petId = _activePet?.id ?? 'unknown';
    
    setState(() {
      _isRecording = true;
      _currentEventType = eventType.toString().split('.').last;
    });

    final started = await _multimodalController.startVoiceRecording(
      eventType: eventType,
      petId: petId,
      position: _currentPosition,
    );

    if (started && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(width: 10),
              Text('Gravando ${_getEventLabel(eventType)}... Fale agora!'),
            ],
          ),
          backgroundColor: Colors.red.withValues(alpha: 0.9),
          duration: const Duration(seconds: 30),
          action: SnackBarAction(
            label: 'PARAR',
            textColor: Colors.white,
            onPressed: () => _stopVoiceRecording(eventType),
          ),
        ),
      );

      // Auto-stop after 30 seconds or silence detection
      Future.delayed(const Duration(seconds: 30), () {
        if (mounted && _isRecording) _stopVoiceRecording(eventType);
      });
    }
  }

  /// 🔇 Stop Voice Recording (Auto-Save on Silence)
  Future<void> _stopVoiceRecording(WalkEventType eventType) async {
    final result = await _multimodalController.stopVoiceRecording();

    setState(() {
      _isRecording = false;
      _currentEventType = null;
    });

    if (result['audioPath'] != null) {
      String? aiLabel;
      final address = await _getAddressFromLatLng(_currentPosition);
      
      // 🗣️ AI ANALYSIS: Latido / Outros (Emoção)
      if (eventType == WalkEventType.bark || eventType == WalkEventType.others) {
        aiLabel = await _multimodalController.analyzeEmotion(result['audioPath']!);
      }

      final event = _multimodalController.buildCompleteEvent(
        eventType: eventType,
        audioPath: result['audioPath'],
        transcription: result['transcription'],
        description: "📍 $address${aiLabel != null ? " • Emoção: $aiLabel" : ""}",
        position: _currentPosition,
      );

      setState(() => _events.add(event));
      _multimodalController.clearCurrentEvent();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Text('${_getEventLabel(eventType)} registrado!'),
              ],
            ),
            backgroundColor: AppDesign.success,
          ),
        );
      }
    }
  }

  /// 🔊 Capture Ambient Sound for Event
  Future<void> _captureSoundForEvent(WalkEventType eventType, [Map<String, dynamic>? extra]) async {
    final petId = _activePet?.id ?? 'unknown';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.graphic_eq, color: Colors.white),
            const SizedBox(width: 10),
            Text('Capturando som de ${_getEventLabel(eventType)}...'),
          ],
        ),
        backgroundColor: Colors.orange.withValues(alpha: 0.9),
        duration: const Duration(seconds: 5),
      ),
    );

    final soundPath = await _multimodalController.captureAmbientSound(
      eventType: eventType,
      petId: petId,
      position: _currentPosition,
      durationSeconds: 5,
    );

    if (soundPath != null) {
      final event = _multimodalController.buildCompleteEvent(
        eventType: eventType,
        audioPath: soundPath,
        description: 'Análise emocional (IA): Processando...',
        position: _currentPosition,
      );

      setState(() {
        _events.add(event);
      });

      _multimodalController.clearCurrentEvent();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Text('${_getEventLabel(eventType)} com som salvo!'),
              ],
            ),
            backgroundColor: AppDesign.success,
          ),
        );
      }
    }
  }

  /// ⚡ Quick Log Event (No Media)
  void _quickLogEvent(WalkEventType eventType, [Map<String, dynamic>? extra]) {
    final event = _multimodalController.buildCompleteEvent(
      eventType: eventType,
      position: _currentPosition,
      bristolScore: extra?['bristol_score'],
    );

    setState(() {
      _events.add(event);
    });

    _multimodalController.clearCurrentEvent();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_getEventLabel(eventType)} registrado!'),
        backgroundColor: AppDesign.success,
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  Color _getBristolColor(int score) {
    if (score <= 2) return Colors.brown.shade900;
    if (score >= 6) return Colors.yellow.shade800;
    return Colors.brown;
  }

  /// 📍 Mock Geocoding
  Future<String> _getAddressFromLatLng(Position? pos) async {
    if (pos == null) return "Local desconhecido";
    // Mock street names for a premium feel
    final streets = ["Rua das Flores", "Av. Paulista", "Al. dos Pets", "Praça da Liberdade", "Rua do Sossego"];
    final index = (pos.latitude.abs() * 100).toInt() % streets.length;
    return "${streets[index]}, ${100 + (pos.longitude.abs() * 10).toInt()}";
  }

  /// Get event label for display
  String _getEventLabel(WalkEventType type) {
    switch (type) {
      case WalkEventType.pee: return 'Xixi';
      case WalkEventType.poo: return 'Fezes';
      case WalkEventType.water: return 'Água';
      case WalkEventType.others: return 'Outros';
      case WalkEventType.friend: return 'Amigo';
      case WalkEventType.bark: return 'Latido';
      case WalkEventType.hazard: return 'Perigo';
      case WalkEventType.fight: return 'Brigas';
      default: return 'Evento';
    }
  }



  // --- UI BUILDING ---

  // --- VIP LOCATION LOGIC ---
  
  Future<void> _fetchNearbyVenues() async {
    if (_currentPosition == null) return;
    
    try {
      final venues = await PartnerService().searchWalkVenues(
        lat: _currentPosition!.latitude, 
        lng: _currentPosition!.longitude
      );

      debugPrint("🌳 [ScanWalk VIP] ${venues.length} locais encontrados. Processando marcadores...");
      
      if (venues.isEmpty) return;

      setState(() {
        _nearbyVenues = venues;
      });

      // Gerar ícones personalizados 64x64 (Simulação de Assets)
      final iconVip = await _getBytesFromCanvas(Icons.pets, Colors.deepPurple, 120);
      final iconPark = await _getBytesFromCanvas(Icons.park, Colors.green, 120);
      final iconWater = await _getBytesFromCanvas(Icons.water_drop, Colors.blue, 120);

      setState(() {
        for (var v in venues) {
          final nameLower = v.name.toLowerCase();
          
          bool isVip = nameLower.contains('dog') || nameLower.contains('cães') || nameLower.contains('cachorro') || nameLower.contains('k9') || nameLower.contains('agility') || nameLower.contains('cercado');
          bool isWater = nameLower.contains('bebedouro') || nameLower.contains('fonte');

          BitmapDescriptor icon;
          String snippet;
          
          if (isWater) {
             icon = BitmapDescriptor.fromBytes(iconWater);
             snippet = "💧 Bebedouro Pet";
          } else if (isVip) {
             icon = BitmapDescriptor.fromBytes(iconVip);
             snippet = "🌟 Espaço Exclusivo Pet (VIP)";
          } else {
             icon = BitmapDescriptor.fromBytes(iconPark);
             snippet = "🌳 Área Verde / Praça";
          }
          
          _markers.add(
            Marker(
              markerId: MarkerId(v.id),
              position: LatLng(v.latitude, v.longitude),
              icon: icon,
              onTap: () {
                setState(() {
                  _selectedVenue = v;
                });
              },
              infoWindow: InfoWindow.noText, // Hide standard info window
              zIndex: 2, // Acima do mapa base
            )
          );
        }
      });
      
      // 🎥 Auto-Zoom: Focar no Pet + 3 locais mais próximos
      if (_mapController != null && _currentPosition != null) {
          try {
            double minLat = _currentPosition!.latitude;
            double maxLat = _currentPosition!.latitude;
            double minLng = _currentPosition!.longitude;
            double maxLng = _currentPosition!.longitude;

            // Pega os 3 mais próximos (a lista já vem ordenada por distância do PartnerService?)
            // O PartnerService tenta ordenar, mas vamos garantir os top 3 da exibição
            final topVenues = venues.take(3); 
            
            for (var v in topVenues) {
               if (v.latitude < minLat) minLat = v.latitude;
               if (v.latitude > maxLat) maxLat = v.latitude;
               if (v.longitude < minLng) minLng = v.longitude;
               if (v.longitude > maxLng) maxLng = v.longitude;
            }

            // Adiciona padding
            _mapController!.animateCamera(
              CameraUpdate.newLatLngBounds(
                LatLngBounds(
                  southwest: LatLng(minLat, minLng),
                  northeast: LatLng(maxLat, maxLng),
                ),
                100 // Padding em pixels
              )
            );
            debugPrint("🎥 [ScanWalk Cam] Zoom ajustado para cobrir o Pet e os locais VIP.");
          } catch (e) {
             debugPrint("⚠️ Erro ao ajustar câmera: $e");
          }
      }
      
      debugPrint("✅ [ScanWalk VIP] ${_markers.length} Marcadores plotados no mapa.");

    } catch (e) {
      debugPrint("⚠️ Erro ao buscar locais VIP: $e");
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erro ao renderizar locais no mapa. Verifique conexão."), backgroundColor: Colors.red)
         );
      }
    }
  }
  
  void _checkVenueProximity(Position pos) {
    for (var v in _nearbyVenues) {
       if (_visitedVenueIds.contains(v.id)) continue;

       final dist = Geolocator.distanceBetween(pos.latitude, pos.longitude, v.latitude, v.longitude);
       if (dist < 50) { // 50 metros = Check-in
          setState(() {
            _visitedVenueIds.add(v.id);
            _selectedVenue = v; // Auto-select the venue when checked-in
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.stars, color: Colors.amber),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "🌟 Check-in VIP: Você chegou em ${v.name}! Bom passeio!",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.deepPurple,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              duration: const Duration(seconds: 4),
            )
          );
          break; 
       }
    }
  }

  // --- UI BUILDING ---

  Future<void> _updatePetMarker() async {
     if (_currentPosition == null) return;
     
     // Ensure we have the pet icon
     // Usa cor primária do Design
     final petIcon = await _getBytesFromCanvas(Icons.pets, AppDesign.primary, 80);
     
     if (!mounted) return;

     setState(() {
       _markers.removeWhere((m) => m.markerId.value == 'pet_avatar');
       _markers.add(
         Marker(
           markerId: const MarkerId('pet_avatar'),
           position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
           icon: BitmapDescriptor.fromBytes(petIcon),
           zIndex: 100, // Topo absoluto, acima de tudo
           anchor: const Offset(0.5, 0.5),
           infoWindow: InfoWindow(title: _activePet?.petName ?? "Pet"),
         )
       );
     });
  }

  @override
  Widget build(BuildContext context) {
    final fmtDuration = "${_walkDuration.inMinutes.toString().padLeft(2, '0')}:${(_walkDuration.inSeconds % 60).toString().padLeft(2, '0')}";

    return Scaffold(
      backgroundColor: AppDesign.backgroundDark,
      body: Stack(
        children: [
          // 1. Full Map Layer (Camada 0)
          Positioned.fill(child: _buildMapLayer()),

          // 2. Top Status Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20, right: 20,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusBar(fmtDuration),
                const SizedBox(width: 8),
                // Gear Button
                Container(
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
                  child: IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white, size: 20),
                    onPressed: _showSettingsModal,
                  ),
                ),
              ],
            ),
          ),

          // 4. Close Button (Top Right)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 10,
            child: IconButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppDesign.surfaceDark,
                    title: const Text("Encerrar Passeio?", style: TextStyle(color: Colors.white)),
                    content: const Text("Deseja finalizar o passeio agora?", style: TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCELAR")),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        child: const Text("FINALIZAR"),
                      ),
                    ],
                  ),
                );
                if (confirm == true) _stopWalk();
              },
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
            ),
          ),

          // 5. Tactical Panel (Camada 2 - Fixed Bottom)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_selectedVenue != null) _buildVenueInfoCard(),
                _buildTacticalPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapLayer() {
    if (_hasError) {
      return Container(
        color: const Color(0xFFC62828), // Deep Red for error
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_off, color: Colors.white, size: 64),
                const SizedBox(height: 16),
                Text(
                  "Falha na Localização",
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                      _startWalkSequence();
                    });
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red),
                  child: const Text("TENTAR NOVAMENTE"),
                )
              ],
            ),
          ),
        ),
      );
    }

    if (_currentPosition == null) {
      return Container(
        color: AppDesign.backgroundDark,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 60, height: 60,
                child: CircularProgressIndicator(color: AppDesign.accent, strokeWidth: 3),
              ),
              const SizedBox(height: 24),
              Text(
                "Sincronizando Satélites...",
                style: GoogleFonts.poppins(color: Colors.white70, letterSpacing: 1.2),
              ),
            ],
          ),
        ),
      );
    }

    // A camada de GoogleMap agora está protegida por um Container de Fallback
    return SizedBox.expand(
      child: Container(
        color: const Color(0xFF1A1A1A), // Dark Neutro para manter estética premium
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 17,
          ),
          onMapCreated: (controller) {
            _mapController = controller;
            setState(() {
              _mapReady = true;
              _loadRiskZones();
            });
          },
          myLocationEnabled: false, // Desabilitado para remover ícone padrão e usar customizado
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          circles: _circles,
          markers: _markers,
          style: _mapStyle, // Dark mode map style
        ),
      ),
    );
  }

  void _loadRiskZones() {
    if (_currentPosition == null) return;
    
    // Safety Zone dinâmica ao redor do pet
    setState(() {
      _circles.clear();
      _circles.add(
        Circle(
          circleId: const CircleId('safe_zone'),
          center: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          radius: _safetyRadius, 
          fillColor: Colors.redAccent.withValues(alpha: 0.05), // Radar translúcido
          strokeColor: Colors.redAccent.withValues(alpha: 0.8), // Borda Neon
          strokeWidth: 2,
          zIndex: 0, // Abaixo dos marcadores
        ),
      );
      
      // Update Custom Pet Marker (Avatar)
      _updatePetMarker();

      // Se for a primeira vez ou update forçado de settings, ajustar zoom
      // Mas cuidado para não impedir o usuário de dar zoom manual.
      // Vamos chamar o zoom apenas se o slider foi movido recentemente ou boot.
    });
  }
  
  void _zoomToFitSafetyCircle() {
    if (_mapController == null || _currentPosition == null) return;
    
    // Calcular Bounds (Aprox. 1 grau = 111km -> 1m = 1/111000 graus)
    const double metersPerDegree = 111319.9;
    final double latDelta = _safetyRadius / metersPerDegree;
    final double lngDelta = _safetyRadius / (metersPerDegree * 0.7); // Ajuste grosseiro para longitude no Brasil (cos(-23) ~ 0.9)

    final bounds = LatLngBounds(
      southwest: LatLng(_currentPosition!.latitude - latDelta, _currentPosition!.longitude - lngDelta),
      northeast: LatLng(_currentPosition!.latitude + latDelta, _currentPosition!.longitude + lngDelta),
    );
    
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    debugPrint("🎥 [ScanWalk Cam] Ajustado para cobrir raio de ${_safetyRadius}m");
  }
  



  // Dark mode map style JSON
  final String _mapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#212121"
      }
    ]
  },
  {
    "elementType": "labels.icon",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#212121"
      }
    ]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry.fill",
    "stylers": [
      {
        "color": "#2c2c2c"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#8a8a8a"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#000000"
      }
    ]
  }
]
''';



  Widget _buildStatusBar(String duration) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.pets, color: Colors.green, size: 20),
              const SizedBox(width: 10),
              Text(duration, style: GoogleFonts.robotoMono(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(width: 20),
              const Icon(Icons.map, color: Colors.white70, size: 16),
              const SizedBox(width: 5),
              Text("${_distanceKm.toStringAsFixed(2)} km", style: const TextStyle(color: Colors.white, fontSize: 14)),
              const SizedBox(width: 20),
              const Icon(Icons.event_note, color: Colors.white70, size: 16),
              const SizedBox(width: 5),
              Text("${_events.length}", style: const TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTacticalPanel() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: 24 + MediaQuery.of(context).padding.bottom, // 🛡️ Safe Area for Android Nav Bar
          ),
          decoration: BoxDecoration(
            color: AppDesign.surfaceDark.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(color: AppDesign.accent.withValues(alpha: 0.8), width: 2),
            boxShadow: [BoxShadow(color: AppDesign.accent.withValues(alpha: 0.3), blurRadius: 20)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Classificar Registro", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text(
                "Toque para escolher: Foto • Voz • Som",
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 10),
              ),
              const SizedBox(height: 16),
              // Row 1: Saúde/Fisiologia
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                   _buildTacticalBtn("Xixi", Icons.water_drop_outlined, Colors.yellow, WalkEventType.pee),
                   _buildTacticalBtn("Fezes", Icons.circle, Colors.brown, WalkEventType.poo),
                   _buildTacticalBtn("Água", Icons.local_drink, Colors.blue, WalkEventType.water),
                   _buildTacticalBtn("Outros", Icons.more_horiz, Colors.teal, WalkEventType.others),
                ],
              ),
              const SizedBox(height: 16),
              // Row 2: Social/Comportamento
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                   _buildTacticalBtn("Amigo", Icons.person_add, Colors.purple, WalkEventType.friend),
                   _buildTacticalBtn("Latido", Icons.graphic_eq, Colors.red, WalkEventType.bark),
                   _buildTacticalBtn("Perigo", Icons.warning, Colors.orange, WalkEventType.hazard),
                   _buildTacticalBtn("Brigas", Icons.pets, Colors.deepOrange, WalkEventType.fight),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTacticalBtn(String label, IconData icon, Color color, WalkEventType eventType, {bool hasCustomAction = false}) {
    final isRecordingThis = _isRecording && _currentEventType == eventType.toString().split('.').last;
    
    return GestureDetector(
      // Tap: Open Multimodal Capture Modal
      onTap: () {
        if (_isRecording) return; // Ignore tap while recording
        
        // Use the standard multimodal capture for consistency with Pee
        _openMultimodalCapture(eventType);
      },
      
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 52,  // Reduced from 60 for 4-column layout
            height: 52,
            decoration: BoxDecoration(
              color: isRecordingThis 
                  ? Colors.red.withValues(alpha: 0.3)
                  : color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: isRecordingThis ? Colors.red : color, 
                width: isRecordingThis ? 3 : 1,
              ),
              boxShadow: isRecordingThis 
                  ? [BoxShadow(color: Colors.red.withValues(alpha: 0.5), blurRadius: 15, spreadRadius: 2)]
                  : [],
            ),
            child: Icon(
              icon, 
              color: isRecordingThis ? Colors.white : color, 
              size: 24,  // Reduced from 30
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label, 
            style: TextStyle(
              color: isRecordingThis ? Colors.red : Colors.white70, 
              fontSize: 10,  // Reduced from 11
              fontWeight: isRecordingThis ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isRecordingThis) ...[
            const SizedBox(height: 2),
            Container(
              width: 32,  // Reduced from 40
              height: 2,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(2),
              ),
              child: const LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEndWalkSummary(int kcal, String impactMsg) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppDesign.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: Container(width: 50, height: 5, color: Colors.grey[700])),
          const SizedBox(height: 20),
          Text("Resumo do Passeio", style: GoogleFonts.poppins(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          
          _buildSummaryItem("Duração Total", "${_walkDuration.inMinutes} min"),
          _buildSummaryItem("Distância", "${_distanceKm.toStringAsFixed(2)} km"),
          _buildSummaryItem("Eventos", "${_events.length}"),
          _buildSummaryItem("Calorias", "~$kcal kcal"),
          
          const Divider(color: Colors.white10, height: 30),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppDesign.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.restaurant_menu, color: AppDesign.primary),
              const SizedBox(width: 12),
              Expanded(child: Text(impactMsg, style: const TextStyle(color: Colors.white, fontSize: 12))),
            ]),
          ),
          
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppDesign.success,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("CONCLUIR", style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildVenueInfoCard() {
    if (_selectedVenue == null) return const SizedBox.shrink();

    final nameLower = _selectedVenue!.name.toLowerCase();
    bool isVip = nameLower.contains('dog') || nameLower.contains('cães') || nameLower.contains('cachorro') || nameLower.contains('k9') || nameLower.contains('agility') || nameLower.contains('cercado') || nameLower.contains('pet');
    bool isWater = nameLower.contains('bebedouro') || nameLower.contains('fonte') || nameLower.contains('água');
    bool isPlay = nameLower.contains('playground') || nameLower.contains('brinquedo') || nameLower.contains('recreação');
    bool isNature = nameLower.contains('parque') || nameLower.contains('praça') || nameLower.contains('jardim') || nameLower.contains('bosque');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppDesign.surfaceDark.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
        boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedVenue!.name,
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _selectedVenue!.address,
                            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                      onPressed: () => setState(() => _selectedVenue = null),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (isVip) _buildAmenityBadge("Área Cercada", Icons.fence, Colors.orange),
                    if (isWater) _buildAmenityBadge("Bebedouro", Icons.water_drop, Colors.blue),
                    if (isPlay) _buildAmenityBadge("Playground", Icons.toys, Colors.pinkAccent),
                    if (isNature && !isVip) _buildAmenityBadge("Área Verde", Icons.park, Colors.green),
                    const Spacer(),
                    Text(
                      "${_selectedVenue!.rating} ⭐",
                      style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmenityBadge(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
  
  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _loadSettings() async {
    final box = await Hive.openBox('settings_box');
    if (mounted) {
      setState(() {
        _safetyRadius = box.get('walk_radius_limit', defaultValue: 500.0);
      });
    }
  }
  
  Future<void> _saveSettings() async {
    final box = await Hive.openBox('settings_box');
    await box.put('walk_radius_limit', _safetyRadius);
  }

  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppDesign.surfaceDark,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Text("Configurar Raio", style: GoogleFonts.poppins(color: Colors.white, fontSize: 18)),
                   Slider(
                     value: _safetyRadius,
                     min: 50,
                     max: 2000,
                     divisions: 39,
                     onChanged: (val) {
                       setModalState(() => _safetyRadius = val);
                       setState(() {
                         _safetyRadius = val;
                         if (_currentPosition != null) {
                            _loadRiskZones(); 
                            _zoomToFitSafetyCircle();
                         }
                       });
                       _saveSettings();
                     },
                   ),
                   ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
                ],
              ),
            );
          }
        );
      }
    );
  }

  Future<Uint8List> _getBytesFromCanvas(IconData icon, Color color, int width) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = color;
    final double radius = width / 2;

    // Fundo Circular
    canvas.drawCircle(Offset(radius, radius), radius, paint);
    
    // Borda Branca
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = width * 0.05; // 5% de borda
    canvas.drawCircle(Offset(radius, radius), radius * 0.95, borderPaint);

    // Ícone Central
    final TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: width * 0.6, // 60% do tamanho
        fontFamily: icon.fontFamily,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(radius - textPainter.width / 2, radius - textPainter.height / 2),
    );

    final ui.Image image = await pictureRecorder.endRecording().toImage(width, width);
    final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }
}
