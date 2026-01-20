import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:scannut/core/theme/app_design.dart';
import 'package:scannut/l10n/app_localizations.dart';
import 'package:scannut/core/services/gemini_service.dart';
import 'package:scannut/core/services/media_vault_service.dart';
import 'package:scannut/features/pet/services/pet_profile_service.dart';
import 'package:scannut/features/pet/services/pet_event_service.dart';
import 'package:scannut/features/pet/models/pet_event.dart';
import 'package:path/path.dart' as p;

class SoundAnalysisCard extends StatefulWidget {
  final String petName;
  final List<Map<String, dynamic>> analysisHistory;
  
  const SoundAnalysisCard({
    Key? key, 
    required this.petName,
    this.analysisHistory = const [],
    this.onDeleteAnalysis,
    this.onAnalysisSaved,
  }) : super(key: key);

  final Function(Map<String, dynamic>)? onDeleteAnalysis;
  final VoidCallback? onAnalysisSaved;

  @override
  State<SoundAnalysisCard> createState() => _SoundAnalysisCardState();
}

class _SoundAnalysisCardState extends State<SoundAnalysisCard> {
  late final AudioRecorder _audioRecorder;
  bool _isRecording = false;
  bool _isProcessing = false;
  StreamSubscription<RecordState>? _recordSub;
  Timer? _timer;
  int _recordDuration = 0;
  String? _errorMessage;
  Map<String, dynamic>? _lastResult;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _recordSub = _audioRecorder.onStateChanged().listen((recordState) { });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recordSub?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/sound_rec_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc), 
          path: path
        );

        setState(() {
          _isRecording = true;
          _recordDuration = 0;
          _errorMessage = null;
          _lastResult = null;
        });

        _timer?.cancel();
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() => _recordDuration++);
          if (_recordDuration >= 15) { // Limit to 15s
             _stopRecording();
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isRecording = false;
      });
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    if (!_isRecording) return;
    
    final path = await _audioRecorder.stop();
    setState(() {
      _isRecording = false;
      _isProcessing = true;
    });

    if (path != null) {
      await _analyze(path);
    }
  }

  Future<void> _pickFile() async {
      try {
          FilePickerResult? result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg'],
          );

          if (result != null && result.files.single.path != null) {
              setState(() {
                  _isProcessing = true;
                  _lastResult = null;
                  _errorMessage = null;
              });
              await _analyze(result.files.single.path!);
          }
      } catch (e) {
          setState(() => _errorMessage = 'Erro ao ler arquivo: $e');
      }
  }

  Future<void> _analyze(String path) async {
    final strings = AppLocalizations.of(context);
    try {
      final result = await GeminiService().analyzeAudio(path);
      
      setState(() {
        _lastResult = result;
        _isProcessing = false;
      });
      
      await _autoSave(result, path);

    } catch (e) {
      if (mounted) {
        setState(() {
            _errorMessage = e.toString().contains('GeminiException') 
                ? e.toString() 
                : '${strings?.soundError ?? 'Erro na análise'}: ${e.toString().split(':').last}';
            _isProcessing = false;
        });
      }
    }
  }

  Future<void> _autoSave(Map<String, dynamic> data, String tempPath) async {
    try {
       final filename = p.basename(tempPath);
       
       // 1. Prepare for History
       final analysisForHistory = {
          'analysis_type': 'vocal_analysis',
          'original_filename': filename, // 🔊 NOME DO ARQUIVO
          'emotion_simple': data['emotion_simple'] ?? data['emotional_state'] ?? '?',
          'reason_simple': data['reason_simple'] ?? '',
          'action_tip': data['action_tip'] ?? data['recommended_action'] ?? '',
          'last_updated': DateTime.now().toIso8601String(),
       };
       
       await PetProfileService().addAnalysisToHistory(widget.petName, analysisForHistory);

       // 2. Save to Events
       final service = PetEventService();
       await service.init();
       if (!service.box.isOpen) await service.init();
       
       final emotion = data['emotion_simple'] ?? data['emotional_state'] ?? '?';
       final reason = data['reason_simple'] ?? '';
       final action = data['action_tip'] ?? data['recommended_action'] ?? '';

       final event = PetEvent(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          petId: widget.petName,
          petName: widget.petName, 
          title: 'Análise Sonora: $emotion',
          type: EventType.behavior, // Usando Behavior
          dateTime: DateTime.now(),
          notes: 'Motivo: $reason\n\nDica: $action',
       );
       
       await service.addEvent(event);
       debugPrint('✅ [SoundAnalysis] Auto-saved to Hive (History & Events).');
       
       if (widget.onAnalysisSaved != null) {
         widget.onAnalysisSaved!();
       }
    } catch (e) {
       debugPrint('❌ [SoundAnalysis] Save failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    // Cores indicativas (Using withOpacity for compatibility)
    final borderColor = _errorMessage != null ? Colors.red : (_lastResult != null ? Colors.green : Colors.grey.withOpacity(0.3));
    final bgColor = _errorMessage != null ? Colors.red.withOpacity(0.1) : (_lastResult != null ? Colors.green.withOpacity(0.1) : Colors.black.withOpacity(0.2));

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView( 
        physics: const NeverScrollableScrollPhysics(), 
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               // Header
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                         Icon(Icons.graphic_eq, color: _isRecording ? Colors.red : AppDesign.petPink),
                         const SizedBox(width: 8),
                         Text(
                           strings?.soundAnalysisTitle ?? 'Análise Vocal',
                           style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                         ),
                      ],
                    ),
                    if (_lastResult != null)
                       IconButton(
                         icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                         onPressed: () => setState(() => _lastResult = null),
                         padding: EdgeInsets.zero,
                         constraints: const BoxConstraints(),
                       ),
                    if (_isRecording)
                       Text('00:${_recordDuration.toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
               
               const SizedBox(height: 8),
               Text(
                 strings?.soundAnalysisDesc ?? 'Entenda o que seu pet diz.',
                 style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
               ),
               
               const SizedBox(height: 16),
               
               // Botões de Entrada (Dual Input)
               if (!_isProcessing && _lastResult == null)
                 Row(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     // Gravar
                     Column(
                       children: [
                         GestureDetector(
                           onTap: _isRecording ? _stopRecording : _startRecording,
                           child: AnimatedContainer(
                             duration: const Duration(milliseconds: 300),
                             padding: EdgeInsets.all(_isRecording ? 24 : 16),
                             decoration: BoxDecoration(
                               shape: BoxShape.circle,
                               color: _isRecording ? Colors.red.withOpacity(0.2) : AppDesign.petPink.withOpacity(0.1),
                               border: Border.all(color: _isRecording ? Colors.red : AppDesign.petPink, width: 2),
                             ),
                             child: Icon(
                               _isRecording ? Icons.stop : Icons.mic,
                               size: 32,
                               color: _isRecording ? Colors.red : AppDesign.petPink,
                             ),
                           ),
                         ),
                         const SizedBox(height: 8),
                         Text(_isRecording ? 'Parar' : 'Gravar', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                       ],
                     ),

                     if (!_isRecording) ...[
                        const SizedBox(width: 40),
                        // Upload
                        Column(
                          children: [
                            IconButton(
                              onPressed: _pickFile,
                              icon: const Icon(Icons.upload_file, color: Colors.white, size: 32),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.1),
                                padding: const EdgeInsets.all(16),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(strings?.soundUploadBtn ?? 'Arquivo', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                          ],
                        ),
                     ],
                   ],
                 ),

               if (_isProcessing)
                  Center(
                    child: Column(
                      children: [
                        const CircularProgressIndicator(color: AppDesign.petPink),
                        const SizedBox(height: 8),
                        Text(strings?.soundProcessing ?? 'Analisando...', style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),

                // Resultados Simplificados
                if (_lastResult != null) ...[
                   if (_lastResult?['original_filename'] != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Arquivo: ${_lastResult!['original_filename']}',
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, fontStyle: FontStyle.italic),
                        ),
                      ),
                   _buildResultRow(Icons.sentiment_satisfied_alt, strings?.soundEmotionSimple ?? 'O que ele sente', _lastResult?['emotion_simple']?.toString()),
                   _buildResultRow(Icons.help_outline, strings?.soundReasonSimple ?? 'Motivo', _lastResult?['reason_simple']?.toString()),
                   _buildResultRow(Icons.lightbulb_outline, strings?.soundActionTip ?? 'Dica', _lastResult?['action_tip']?.toString()),
                   
                   const SizedBox(height: 12),
                   Align(
                     alignment: Alignment.centerRight,
                     child: TextButton.icon(
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Nova Análise'),
                        onPressed: () => setState(() => _lastResult = null), 
                     ),
                   )
                ],
                
                if (_errorMessage != null)
                   Padding(
                     padding: const EdgeInsets.only(top: 16),
                     child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                   ),

                // --- HISTÓRICO DE ARQUIVOS ---
                if (widget.analysisHistory.any((a) => a['analysis_type'] == 'vocal_analysis')) ...[
                   const SizedBox(height: 24),
                   const Divider(color: Colors.white10),
                   const SizedBox(height: 8),
                   const Text('Arquivos Analisados', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 12),
                   ...widget.analysisHistory
                       .where((a) => a['analysis_type'] == 'vocal_analysis')
                       .map((a) => _buildHistoryItem(a)).toList(),
                ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow(IconData icon, String label, String? value) {
     return Padding(
       padding: const EdgeInsets.only(bottom: 12),
       child: Row(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
              child: Icon(icon, size: 16, color: AppDesign.petPink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(
                    value ?? '...', 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)
                  ),
                ],
              ),
            ),
         ],
       ),
     );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
     final emotion = item['emotion_simple']?.toString() ?? '?';
     final filename = item['original_filename']?.toString() ?? 'Gravado via Mic';
     
     return InkWell(
       onTap: () => setState(() {
         _lastResult = item;
         _errorMessage = null;
       }),
       borderRadius: BorderRadius.circular(8),
       child: Container(
         margin: const EdgeInsets.only(bottom: 8),
         padding: const EdgeInsets.all(10),
         decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withOpacity(0.05))),
         child: Row(
           children: [
              const Icon(Icons.audio_file, color: AppDesign.petPink, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                   Text(filename, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                   Text('Veredito: $emotion', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                ]),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 12),
              if (widget.onDeleteAnalysis != null) ...[
                 const SizedBox(width: 8),
                 IconButton(
                   icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                   onPressed: () => widget.onDeleteAnalysis!(item),
                   padding: EdgeInsets.zero,
                   constraints: const BoxConstraints(),
                 ),
              ],
           ],
         ),
       ),
     );
  }
}
