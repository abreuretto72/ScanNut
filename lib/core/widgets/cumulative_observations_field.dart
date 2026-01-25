import 'package:flutter/material.dart';
import 'package:scannut/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../utils/permission_helper.dart';

/// Widget de campo de observações editável com suporte a voz integrado
class CumulativeObservationsField extends StatefulWidget {
  final String sectionName;
  final String initialValue;
  final Function(String) onChanged;
  final IconData? icon;
  final Color? accentColor;
  final TextEditingController? controller;
  final String? label;

  const CumulativeObservationsField({
    super.key,
    required this.sectionName,
    required this.initialValue,
    required this.onChanged,
    this.icon,
    this.accentColor,
    this.controller,
    this.label,
  });

  @override
  State<CumulativeObservationsField> createState() =>
      _CumulativeObservationsFieldState();
}

class _CumulativeObservationsFieldState
    extends State<CumulativeObservationsField> {
  late TextEditingController _controller;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechAvailable = false;
  String _currentTranscript = '';

  // Para inserção de voz na posição do cursor
  TextSelection _lastSelection = const TextSelection.collapsed(offset: 0);

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ?? TextEditingController(text: widget.initialValue);

    _speech = stt.SpeechToText();
    _initSpeech();
  }

  @override
  void didUpdateWidget(CumulativeObservationsField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
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
    final granted = await PermissionHelper.requestMicrophonePermission(context);
    if (!granted) return;

    if (!_speechAvailable || !_speech.isAvailable) {
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
          SnackBar(
              content: Text(AppLocalizations.of(context)!.voiceNotAvailable),
              backgroundColor: Colors.orange),
        );
      }
      return;
    }

    if (_isListening) {
      await _speech.stop();
      if (_currentTranscript.isNotEmpty) {
        _insertTextAtCursor(_currentTranscript);
        _currentTranscript = '';
      }
      setState(() => _isListening = false);
    } else {
      // Salva a última posição do cursor antes de começar
      _lastSelection = _controller.selection;
      if (_lastSelection.start < 0) {
        _lastSelection =
            TextSelection.collapsed(offset: _controller.text.length);
      }

      setState(() {
        _isListening = true;
        _currentTranscript = '';
      });

      String localeId = 'pt_BR';
      try {
        final loc = Localizations.localeOf(context);
        if (loc.languageCode == 'pt') {
          localeId = (loc.countryCode == 'PT') ? 'pt_PT' : 'pt_BR';
        } else if (loc.languageCode == 'es') {
          localeId = 'es_ES';
        }
      } catch (e) {
        localeId = 'pt_BR';
      }

      await _speech.listen(
        onResult: (result) {
          setState(() {
            _currentTranscript = result.recognizedWords;
          });
          if (result.finalResult) {
            _insertTextAtCursor(_currentTranscript);
            _currentTranscript = '';
          }
        },
        localeId: localeId,
        listenMode: stt.ListenMode.confirmation,
      );
    }
  }

  void _insertTextAtCursor(String text) {
    final currentText = _controller.text;
    final selection = _lastSelection;

    // Garantir que a seleção é válida para a string atual
    final start = selection.start.clamp(0, currentText.length);
    final end = selection.end.clamp(0, currentText.length);

    final newText = currentText.replaceRange(start, end, text);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + text.length),
    );

    widget.onChanged(newText);
    _lastSelection = _controller.selection;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(widget.icon ?? Icons.history_edu,
                color: widget.accentColor ?? const Color(0xFF00E676), size: 20),
            const SizedBox(width: 8),
            Text(
                widget.label ??
                    AppLocalizations.of(context)!.petObservationsHistory,
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
            '${AppLocalizations.of(context)!.petRegisterObservations} (${widget.sectionName})',
            style: GoogleFonts.poppins(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isListening
                  ? Colors.red
                  : Colors.white.withValues(alpha: 0.1),
              width: _isListening ? 2 : 1,
            ),
          ),
          child: TextField(
            controller: _controller,
            maxLines: 10,
            minLines: 4,
            readOnly: false,
            onChanged: widget.onChanged,
            style: GoogleFonts.poppins(
                color: Colors.white, fontSize: 13, height: 1.6),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.petNoObservations,
              hintStyle:
                  GoogleFonts.poppins(color: Colors.white38, fontSize: 11),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              suffixIcon: IconButton(
                icon: Icon(_isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? Colors.red : Colors.white),
                onPressed: _speechAvailable ? _toggleListening : null,
                tooltip: AppLocalizations.of(context)!.commonVoice,
              ),
            ),
          ),
        ),
        if (_isListening && _currentTranscript.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.mic, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(_currentTranscript,
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 11))),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
