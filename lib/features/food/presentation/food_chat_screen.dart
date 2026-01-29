
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:speech_to_text/speech_to_text.dart';

import 'package:scannut/l10n/app_localizations.dart';
import 'package:scannut/features/food/l10n/app_localizations.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../core/widgets/pdf_preview_screen.dart';
import '../../../../core/services/base_pdf_helper.dart';
import '../services/food_ai_chat_service.dart';

class FoodChatScreen extends StatefulWidget {
  const FoodChatScreen({super.key});

  @override
  State<FoodChatScreen> createState() => _FoodChatScreenState();
}

class _FoodChatScreenState extends State<FoodChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FoodAiChatService _aiService = FoodAiChatService();

  // Speech to Text
  final SpeechToText _speech = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _lastWords = '';

  // Mensagens: {'role': 'user'|'ai', 'text': '...'}
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;



  @override
  void initState() {
    super.initState();
    _initSpeech();
    
    // Mensagem de boas vindas simulada (não salva no histórico de contexto ainda)
    WidgetsBinding.instance.addPostFrameCallback((_) {
       final l10n = AppLocalizations.of(context);
       final foodL10n = FoodLocalizations.of(context);
       if (l10n != null && foodL10n != null) {
         setState(() {
           _messages.add({
             'role': 'ai', 
             'text': foodL10n.foodChatWelcome
           });
         });
       }
    });
  }

  /// Inicializa o serviço de reconhecimento de fala
  void _initSpeech() async {
    try {
      _speechEnabled = await _speech.initialize(
        onError: (e) => debugPrint("Speech Error: $e"),
        onStatus: (status) {
          debugPrint("Speech Status: $status");
          if (status == 'done' || status == 'notListening') {
             if (mounted) setState(() => _isListening = false);
          }
        },
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Speech Initialization Failed: $e");
    }
  }

  /// Começa a escutar
  void _startListening() async {
    if (!_speechEnabled) {
      _initSpeech();
      return;
    }
    
    await _speech.listen(
      onResult: (result) {
        if (mounted) {
          setState(() {
            _lastWords = result.recognizedWords;
            _controller.text = _lastWords;
            _controller.selection = TextSelection.fromPosition(
              TextPosition(offset: _controller.text.length)
            );
          });
        }
      },
      localeId: Localizations.localeOf(context).toString(),
      listenMode: ListenMode.dictation,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      onSoundLevelChange: null,
      cancelOnError: true,
      partialResults: true,
    );
    
    if (mounted) {
      setState(() {
        _isListening = true;
      });
    }
  }

  /// Para de escutar
  void _stopListening() async {
    await _speech.stop();
    if (mounted) {
      setState(() {
        _isListening = false;
      });
    }
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    final foodL10n = FoodLocalizations.of(context)!;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
      _controller.clear();
    });
    _scrollToBottom();

    // Adiciona ao contexto do serviço
    _aiService.addToHistory('user', text);

    // Envia para IA
    final response = await _aiService.sendQuery(text, locale: Localizations.localeOf(context).toString());

    if (!mounted) return;

    setState(() {
      _messages.add({'role': 'ai', 'text': response});
      _isLoading = false;
    });
    _aiService.addToHistory('ai', response);
    _scrollToBottom();
  }

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

  Future<void> _confirmClearChat() async {
    final foodL10n = FoodLocalizations.of(context);
    if (foodL10n == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(foodL10n.foodChatClear,
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(foodL10n.foodDeleteConfirmContent,
            style: GoogleFonts.poppins(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(foodL10n.foodCancel,
                style: GoogleFonts.poppins(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(foodL10n.foodDelete,
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _clearChat();
    }
  }

  void _clearChat() {
    _aiService.clearHistory();
    setState(() {
      _messages.clear();
      final foodL10n = FoodLocalizations.of(context);
      if (foodL10n != null) {
        _messages.add({'role': 'ai', 'text': foodL10n.foodChatWelcome});
      }
    });
  }

  // 📝 GERAÇÃO DE PDF
  Future<void> _exportPdf() async {
    final l10n = AppLocalizations.of(context)!;
    final foodL10n = FoodLocalizations.of(context)!;
    final dateStr = DateFormat('dd-MM-yyyy').format(DateTime.now());

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfPreviewScreen(
          title: foodL10n.foodChatExportTitle(dateStr),
          buildPdf: (format) => _generatePdf(format, foodL10n, dateStr),
        ),
      ),
    );
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format, FoodLocalizations l10n, String date) async {
    debugPrint('📄 [NutriChatPdf] Iniciando com ${_messages.length} mensagens');
    final pdf = pw.Document();

    try {
      final font = await PdfGoogleFonts.robotoRegular();
      final fontBold = await PdfGoogleFonts.robotoBold();
      final theme = pw.ThemeData.withFont(base: font, bold: fontBold);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: format,
          maxPages: 20,
          margin: const pw.EdgeInsets.all(32),
          theme: theme,
          footer: (context) => _buildPdfFooter(context),
          header: (context) => _buildPdfHeader(l10n, date),
          build: (context) {
            return _messages.expand((m) {
              debugPrint('🔍 [PdfItem] Processando mensagem ID: ${m.hashCode} | Tamanho: ${m['text']?.length ?? 0}');
              final isUser = m['role'] == 'user';
              final roleLabel = isUser ? "Você" : "NutriChat IA";
              final color = isUser ? PdfColors.orange700 : PdfColors.green700;
              final isChefVision = m['source'] == 'AI_SCAN';
              
              final paragraphs = BasePdfHelper.safeSplitText(m['text'] ?? '');
              final List<pw.Widget> widgets = [];

              // 1. Cabeçalho da Mensagem (Role + Time + Label)
              widgets.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(roleLabel, 
                         style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: color)),
                      pw.SizedBox(width: 5),
                      pw.Text(DateFormat('HH:mm').format(DateTime.now()), 
                         style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                      if (isChefVision) ...[
                         pw.SizedBox(width: 5),
                         pw.Container(
                           padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                           decoration: pw.BoxDecoration(
                             color: PdfColor.fromInt(0xFF9C27B0), // Purple
                             borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
                           ),
                           child: pw.Text("Chef Vision", style: pw.TextStyle(color: PdfColors.white, fontSize: 6, fontWeight: pw.FontWeight.bold))
                         )
                      ]
                    ]
                  )
                )
              );

              // 2. Fragmentação em Parágrafos (Quebra o bloco gigante)
              for (var para in paragraphs) {
                if (para.trim().isNotEmpty) {
                   widgets.add(
                     pw.Paragraph(
                        text: para.trim(),
                        style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.2),
                        margin: const pw.EdgeInsets.only(bottom: 6), // Espaço entre parágrafos
                     )
                   );
                }
              }
              
              // 3. Espaçamento final da mensagem
              widgets.add(pw.SizedBox(height: 12));

              return widgets;
            }).toList();
          },
        ),
      );
      return pdf.save();
    } catch (e) {
      debugPrint('❌ [PdfFatal] Erro NutriChat: $e');
      rethrow;
    }
  }

  pw.Widget _buildPdfHeader(FoodLocalizations l10n, String date) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text("ScanNut IA", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, color: PdfColors.orange800)),
            pw.Text(date, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          ],
        ),
        pw.Divider(color: PdfColors.orange800, thickness: 1),
      ],
    );
  }

  pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(top: 20),
      padding: const pw.EdgeInsets.symmetric(vertical: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Text(
        'ScanNut | IA Nutricional | © 2026 Multiverso Digital | contato@multiversodigital.com.br',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final foodL10n = FoodLocalizations.of(context);
    if (l10n == null || foodL10n == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: Text(foodL10n.foodChatTitle), // "NutriChat IA"
        backgroundColor: AppDesign.foodOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: foodL10n.foodExportPdfTooltip,
            onPressed: _messages.isEmpty ? null : _exportPdf,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _confirmClearChat,
            tooltip: foodL10n.foodChatClear,
          ),
        ],
      ),
      backgroundColor: AppDesign.backgroundDark, // #121212
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120), // 🛡️ Padding Seguro (Samsung)
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    decoration: BoxDecoration(
                      color: isUser 
                          ? AppDesign.foodOrange.withValues(alpha: 0.2) 
                          : Colors.green.withValues(alpha: 0.1), // Fundo verde leve para IA
                      border: Border.all(
                        color: isUser 
                          ? AppDesign.foodOrange.withValues(alpha: 0.5) 
                          : Colors.green.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                        bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isUser ? "Você" : "ScanNut AI",
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isUser ? AppDesign.foodOrange : Colors.greenAccent,
                          ),
                        ),
                        const SizedBox(height: 4),
                         MarkdownBody(
                          data: msg['text'] ?? '',
                          styleSheet: MarkdownStyleSheet(
                            p: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                            strong: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          if (_isLoading)
             Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16, height: 16, 
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppDesign.foodOrange)
                  ),
                  const SizedBox(width: 10),
                  Text(foodL10n.foodChatRAGProcessing, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(16).copyWith(
              bottom: MediaQuery.of(context).padding.bottom + 10 // Safe Area para não invadir botão home
            ), 
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              border: const Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _isListening ? Colors.redAccent : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            minLines: 1,
                            maxLines: 5,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: foodL10n.foodChatPrompt,
                              hintStyle: const TextStyle(color: Colors.white38),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 14),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        // Mic Button (Inside)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4, right: 4),
                          child: IconButton(
                            onPressed: _speechEnabled
                                ? (_isListening
                                    ? _stopListening
                                    : _startListening)
                                : () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              foodL10n.foodChatMicUnavailable)),
                                    );
                                  },
                            icon:
                                Icon(_isListening ? Icons.mic_off : Icons.mic),
                            color: _isListening
                                ? Colors.redAccent
                                : Colors.white54,
                            tooltip: _isListening
                                ? foodL10n.foodChatStopListening
                                : foodL10n.foodChatStartListening,
                            // Removed background style for cleaner "inside" look
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Send Button
                IconButton(
                  onPressed: _isLoading ? null : _sendMessage,
                  icon: const Icon(Icons.send_rounded),
                  color: AppDesign.foodOrange,
                  style: IconButton.styleFrom(
                    backgroundColor:
                        AppDesign.foodOrange.withValues(alpha: 0.1),
                    shape: const CircleBorder(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
