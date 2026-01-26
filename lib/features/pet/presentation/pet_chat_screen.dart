import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/theme/app_design.dart';
import '../../../core/utils/permission_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../models/pet_profile_extended.dart';
import '../services/pet_ai_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isDangerous;
  final bool isSafe;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isDangerous = false,
    this.isSafe = false,
  });
}

class PetChatScreen extends ConsumerStatefulWidget {
  final String petId;
  final String petName;
  final PetProfileExtended? profile;

  const PetChatScreen({
    super.key,
    required this.petId,
    required this.petName,
    this.profile,
  });

  @override
  ConsumerState<PetChatScreen> createState() => _PetChatScreenState();
}

class _PetChatScreenState extends ConsumerState<PetChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  // removed _petContext

  late stt.SpeechToText _speech;
  bool _isListeningVoice = false;
  bool _speechAvailable = false;
  
  final PetAiService _aiService = PetAiService();

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
    
    // Welcome message
    WidgetsBinding.instance.addPostFrameCallback((_) {
       setState(() {
         _messages.add(ChatMessage(
           text: "Olá! Sou o ScanNut AI. Já carreguei todo o histórico do ${widget.petName}. Como posso ajudar hoje?",
           isUser: false,
           timestamp: DateTime.now(),
         ));
       });
    });
  }

  Future<void> _initSpeech() async {
    try {
      final status = await Permission.microphone.status;
      if (status.isGranted) {
        _speechAvailable = await _speech.initialize(
          onError: (error) => debugPrint('Speech error: $error'),
          onStatus: (status) {
            if (status == 'done' || status == 'notListening') {
              if (mounted) setState(() => _isListeningVoice = false);
            }
          },
        );
      }
    } catch (e) {
      debugPrint('Error initializing speech engine: $e');
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
            if (mounted) setState(() => _isListeningVoice = false);
          }
        },
      );
    }

    if (!_speechAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.voiceNotAvailable),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (_isListeningVoice) {
      await _speech.stop();
      setState(() => _isListeningVoice = false);
    } else {
      setState(() => _isListeningVoice = true);

      String localeId = 'pt_BR';
      try {
        final loc = Localizations.localeOf(context);
        if (loc.languageCode == 'pt') {
          localeId = (loc.countryCode == 'PT') ? 'pt_PT' : 'pt_BR';
        } else if (loc.languageCode == 'es') {
          localeId = 'es_ES';
        } else if (loc.languageCode == 'en') {
          localeId = 'en_US';
        }
      } catch (e) {
        localeId = 'pt_BR';
      }

      await _speech.listen(
        onResult: (result) {
          setState(() {
            _controller.text = result.recognizedWords;
            // Place cursor at the end
            _controller.selection = TextSelection.fromPosition(
              TextPosition(offset: _controller.text.length),
            );
          });
          if (result.finalResult) {
            setState(() => _isListeningVoice = false);
          }
        },
        localeId: localeId,
      );
    }
  }

  /* removed _loadContext */

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
      _controller.clear();
    });
    _scrollToBottom();
    
    _aiService.addToHistory('user', text);

    try {
      final response = await _aiService.sendQuery(
        text, 
        widget.petId, 
        locale: Localizations.localeOf(context).toString()
      );

      bool isDangerous = response.contains("🚨 [DANGER]");
      bool isSafe = response.contains("✅ [SAFE]");

      String cleanResponse = response
          .replaceAll("🚨 [DANGER]", "")
          .replaceAll("✅ [SAFE]", "")
          .trim();

      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: cleanResponse,
            isUser: false,
            timestamp: DateTime.now(),
            isDangerous: isDangerous,
            isSafe: isSafe,
          ));
          _isLoading = false;
        });
        _scrollToBottom();
        _aiService.addToHistory('model', cleanResponse);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: "Desculpe, tive um problema para processar sua pergunta. Pode tentar de novo?",
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppDesign.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppDesign.backgroundDark,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.petChatTitle,
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.petName,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.white60),
            ),
          ],
        ),
        actions: [
          CircleAvatar(
            backgroundColor: AppDesign.accent.withValues(alpha: 0.1),
            child:
                const Icon(Icons.psychology, color: AppDesign.accent, size: 20),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                color: AppDesign.accent,
              ),
            ),
          _buildInputArea(l10n),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: message.isUser
              ? AppDesign.accent
              : message.isDangerous
                  ? Colors.redAccent.withValues(alpha: 0.9)
                  : message.isSafe
                      ? Colors.green.withValues(alpha: 0.9)
                      : AppDesign.surfaceDark,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(message.isUser ? 20 : 0),
            bottomRight: Radius.circular(message.isUser ? 0 : 20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.isDangerous)
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.report_problem, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text("ALERTA CRÍTICO",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10)),
                  ],
                ),
              ),
            if (message.isSafe)
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text("SAÚDE CONFIRMADA",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10)),
                  ],
                ),
              ),
            Text(
              message.text,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 12,
        top: 12,
      ),
      decoration: BoxDecoration(
        color: AppDesign.surfaceDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment
            .end, // Align buttons to the bottom as field grows
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _isListeningVoice
                      ? Colors.red
                      : Colors.white.withValues(alpha: 0.1),
                  width: _isListeningVoice ? 2 : 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLines: 5, // Allows expanding up to 5 lines
                      minLines: 1,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: l10n.petChatPrompt,
                        hintStyle: const TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: IconButton(
                      icon: Icon(
                        _isListeningVoice ? Icons.mic : Icons.mic_none,
                        color: _isListeningVoice ? Colors.red : Colors.white60,
                        size: 22,
                      ),
                      onPressed: _toggleListening,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: CircleAvatar(
              radius: 26,
              backgroundColor: AppDesign.accent,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.black, size: 24),
                onPressed: _sendMessage,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
