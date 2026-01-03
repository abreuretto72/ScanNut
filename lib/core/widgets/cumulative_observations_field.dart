import 'package:flutter/material.dart';
import 'package:scannut/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/permission_helper.dart';

/// Widget de campo de observações cumulativo com suporte a voz
/// Mantém histórico cronológico inverso com timestamps
/// OTIMIZAÇÃO: Lazy Loading (Paginação Virtual) para evitar travamentos com textos longos.
class CumulativeObservationsField extends StatefulWidget {
  final String sectionName;
  final String initialValue;
  final Function(String) onChanged;
  final IconData? icon;
  final Color? accentColor;

  const CumulativeObservationsField({
    Key? key,
    required this.sectionName,
    required this.initialValue,
    required this.onChanged,
    this.icon,
    this.accentColor,
  }) : super(key: key);

  @override
  State<CumulativeObservationsField> createState() => _CumulativeObservationsFieldState();
}

class _CumulativeObservationsFieldState extends State<CumulativeObservationsField> {
  late TextEditingController _controller;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechAvailable = false;
  String _currentTranscript = '';
  
  // Otimização de Performance (Lazy Loading)
  String _fullText = '';
  int _visibleEntriesCount = 10;
  List<String> _allEntries = [];

  @override
  void initState() {
    super.initState();
    _fullText = widget.initialValue;
    _controller = TextEditingController(); // Texto exibido é controlado por _updateView
    _parseEntries();
    _updateView();
    
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  @override
  void didUpdateWidget(CumulativeObservationsField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue && widget.initialValue != _fullText) {
      _fullText = widget.initialValue;
      _parseEntries();
      _updateView();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _parseEntries() {
    if (_fullText.isEmpty) {
      _allEntries = [];
      return;
    }
    // Separa por quebra de linha dupla, assumindo que cada entrada termina assim
    // Se o formato for consistente (Timestamp: Text\n\n), isso funciona.
    _allEntries = _fullText.split('\n\n').where((e) => e.trim().isNotEmpty).toList();
  }

  void _updateView() {
    if (_allEntries.isEmpty) {
      _controller.text = '';
      return;
    }
    
    // Lazy Loading: Mostra apenas as últimas N entradas
    final count = _allEntries.length;
    final showCount = count > _visibleEntriesCount ? _visibleEntriesCount : count;
    // O texto é invertido (mais recente no topo), então pegamos os primeiros N
    final visibleEntries = _allEntries.take(showCount);
    
    _controller.text = visibleEntries.join('\n\n');
  }

  void _loadMore() {
    setState(() {
      _visibleEntriesCount += 10;
      _updateView();
    });
  }

  Future<void> _initSpeech() async {
    // Permission request removed from init to comply with DSPA
    try {
       // Only initialize speech engine if permission is already granted
       final status = await Permission.microphone.status;
       if (status.isGranted) {
         _speechAvailable = await _speech.initialize(
           onError: (error) => debugPrint('Speech error: $error'),
           onStatus: (status) {
             if (status == 'done' || status == 'notListening') {
               setState(() => _isListening = false);
             }
           },
         );
       }
    } catch (e) {
      debugPrint('Error initializing speech engine silent: $e');
    }
  }

  Future<void> _toggleListening() async {
    // Request permission JIT with rationale
    final granted = await PermissionHelper.requestMicrophonePermission(context);
    if (!granted) return;

    if (!_speechAvailable || !_speech.isAvailable) {
       // Initialize if not done yet
       _speechAvailable = await _speech.initialize(
          onError: (error) => debugPrint('Speech error: $error'),
          onStatus: (status) {
            if (status == 'done' || status == 'notListening') {
              setState(() => _isListening = false);
            }
          },
        );
    }
    
    if (!_speechAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.voiceNotAvailable), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    if (_isListening) {
      await _speech.stop();
      if (_currentTranscript.isNotEmpty) {
        _addObservation(_currentTranscript);
        _currentTranscript = '';
      }
      setState(() => _isListening = false);
    } else {
      setState(() {
        _isListening = true;
        _currentTranscript = '';
      });

      String localeId = 'en_US';
      try {
        final loc = Localizations.localeOf(context);
        if (loc.languageCode == 'pt') {
           localeId = (loc.countryCode == 'PT') ? 'pt_PT' : 'pt_BR';
        } else if (loc.languageCode == 'es') {
           localeId = 'es_ES';
        }
      } catch (e) {
         localeId = 'pt_BR'; // Fallback safe
      }

      await _speech.listen(
        onResult: (result) => setState(() => _currentTranscript = result.recognizedWords),
        localeId: localeId,
        listenMode: stt.ListenMode.confirmation,
      );
    }
  }

  void _addObservation(String text) {
    if (text.trim().isEmpty) return;

    final now = DateTime.now();
    final timestamp = DateFormat('dd/MM/yyyy - HH:mm').format(now);
    final newEntry = '[$timestamp]: $text';

    // Adiciona ao topo (memória)
    _fullText = _fullText.isEmpty ? newEntry : '$newEntry\n\n$_fullText';
    
    // Atualiza parse e view
    _parseEntries();
    _updateView();
    
    // Notifica pai (salva tudo)
    widget.onChanged(_fullText);
  }

  void _showAddObservationDialog() {
    final textController = TextEditingController();
    
        showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(widget.icon ?? Icons.note_add, color: widget.accentColor ?? const Color(0xFF00E676)),
            const SizedBox(width: 12),
            Expanded(child: Text(AppLocalizations.of(context)!.observationNew, style: GoogleFonts.poppins(color: Colors.white, fontSize: 18))),
          ],
        ),
        content: TextField(
          controller: textController,
          maxLines: 5,
          autofocus: true,
          style: GoogleFonts.poppins(color: Colors.white),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.observationHint,
            hintStyle: GoogleFonts.poppins(color: Colors.white54),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.btnCancel, style: GoogleFonts.poppins(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: widget.accentColor ?? const Color(0xFF00E676)),
            onPressed: () {
              if (textController.text.trim().isNotEmpty) {
                _addObservation(textController.text.trim());
                Navigator.pop(context);
              }
            },
            child: Text(AppLocalizations.of(context)!.commonAdd, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasMore = _allEntries.length > _visibleEntriesCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(widget.icon ?? Icons.history_edu, color: widget.accentColor ?? const Color(0xFF00E676), size: 20),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.petObservationsHistory, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        Text('${AppLocalizations.of(context)!.petRegisterObservations} (${widget.sectionName})', style: GoogleFonts.poppins(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 12),
        
        // Campo de Texto (Visualização Otimizada)
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isListening ? Colors.red : Colors.white.withOpacity(0.1),
              width: _isListening ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
                TextField(
                    controller: _controller,
                    maxLines: 6,
                    readOnly: true,
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, height: 1.6),
                    decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.petNoObservations,
                    hintStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 11),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    ),
                ),
                
                // Botão "Carregar Mais" (Paginação)
                if (hasMore)
                    Builder(
                      builder: (context) {
                        final count = '${_allEntries.length - _visibleEntriesCount}';
                        return Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
                            ),
                            child: TextButton.icon(
                                onPressed: _loadMore,
                                icon: const Icon(Icons.expand_more, size: 16, color: Colors.white54),
                                label: Text(
                                    AppLocalizations.of(context)!.commonLoadMore(count), 
                                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.white54)
                                ),
                            ),
                        );
                      }
                    ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Botões de Ação
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _showAddObservationDialog,
                icon: const Icon(Icons.add, size: 18),
                label: Text(AppLocalizations.of(context)!.commonAddText, style: GoogleFonts.poppins(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.accentColor ?? const Color(0xFF00E676),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _speechAvailable ? _toggleListening : null,
              icon: Icon(_isListening ? Icons.mic : Icons.mic_none, size: 18),
              label: Text(_isListening ? AppLocalizations.of(context)!.commonListening : AppLocalizations.of(context)!.commonVoice, style: GoogleFonts.poppins(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isListening ? Colors.red : Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        
        if (_isListening && _currentTranscript.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.mic, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(_currentTranscript, style: GoogleFonts.poppins(color: Colors.white, fontSize: 11))),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
