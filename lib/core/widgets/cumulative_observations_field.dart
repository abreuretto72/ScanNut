import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

/// Widget de campo de observações cumulativo com suporte a voz
/// Mantém histórico cronológico inverso com timestamps
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

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      // Solicitar permissão de microfone
      final status = await Permission.microphone.request();
      if (status.isGranted) {
        _speechAvailable = await _speech.initialize(
          onError: (error) {
            debugPrint('Speech error: $error');
            setState(() => _isListening = false);
          },
          onStatus: (status) {
            debugPrint('Speech status: $status');
            if (status == 'done' || status == 'notListening') {
              setState(() => _isListening = false);
            }
          },
        );
        setState(() {});
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permissão de microfone negada'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error initializing speech: $e');
      setState(() => _speechAvailable = false);
    }
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reconhecimento de voz não disponível'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_isListening) {
      // Parar de ouvir e adicionar ao histórico
      await _speech.stop();
      if (_currentTranscript.isNotEmpty) {
        _addObservation(_currentTranscript);
        _currentTranscript = '';
      }
      setState(() => _isListening = false);
    } else {
      // Começar a ouvir
      setState(() {
        _isListening = true;
        _currentTranscript = '';
      });

      await _speech.listen(
        onResult: (result) {
          setState(() {
            _currentTranscript = result.recognizedWords;
          });
        },
        localeId: 'pt_BR',
        listenMode: stt.ListenMode.confirmation,
      );
    }
  }

  void _addObservation(String text) {
    if (text.trim().isEmpty) return;

    // Gerar timestamp
    final now = DateTime.now();
    final timestamp = DateFormat('dd/MM/yyyy - HH:mm').format(now);
    final newEntry = '[$timestamp]: $text';

    // Adicionar ao topo do histórico (ordem cronológica inversa)
    final currentText = _controller.text.trim();
    final updatedText = currentText.isEmpty
        ? newEntry
        : '$newEntry\n\n$currentText';

    _controller.text = updatedText;
    widget.onChanged(updatedText);
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
            Expanded(
              child: Text(
                'Nova Observação',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
        content: TextField(
          controller: textController,
          maxLines: 5,
          autofocus: true,
          style: GoogleFonts.poppins(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Digite sua observação...',
            hintStyle: GoogleFonts.poppins(color: Colors.white54),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: widget.accentColor ?? const Color(0xFF00E676)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.accentColor ?? const Color(0xFF00E676),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (textController.text.trim().isNotEmpty) {
                _addObservation(textController.text.trim());
                Navigator.pop(context);
              }
            },
            child: Text(
              'Adicionar',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              widget.icon ?? Icons.history_edu,
              color: widget.accentColor ?? const Color(0xFF00E676),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Observações e Histórico',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Registre observações importantes sobre ${widget.sectionName}',
          style: GoogleFonts.poppins(
            color: Colors.white60,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 12),
        
        // Campo de texto com histórico
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isListening 
                ? Colors.red 
                : Colors.white.withOpacity(0.1),
              width: _isListening ? 2 : 1,
            ),
          ),
          child: TextField(
            controller: _controller,
            maxLines: 6,
            readOnly: true,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12,
              height: 1.6,
            ),
            decoration: InputDecoration(
              hintText: 'Nenhuma observação registrada ainda.\nToque no + para adicionar ou no microfone para ditar.',
              hintStyle: GoogleFonts.poppins(
                color: Colors.white38,
                fontSize: 11,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Botões de ação
        Row(
          children: [
            // Botão de adicionar texto
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _showAddObservationDialog,
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  'Adicionar Texto',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.accentColor ?? const Color(0xFF00E676),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Botão de voz
            ElevatedButton.icon(
              onPressed: _speechAvailable ? _toggleListening : null,
              icon: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                size: 18,
              ),
              label: Text(
                _isListening ? 'Ouvindo...' : 'Voz',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isListening ? Colors.red : Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        
        // Indicador de transcrição em tempo real
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
                Expanded(
                  child: Text(
                    _currentTranscript,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
