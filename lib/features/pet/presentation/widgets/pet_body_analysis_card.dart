import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scannut/core/theme/app_design.dart';
import 'package:scannut/l10n/app_localizations.dart';
import 'package:scannut/core/services/gemini_service.dart';
import 'package:scannut/features/pet/services/pet_event_service.dart';
import 'package:scannut/features/pet/models/pet_event.dart';
import 'package:scannut/core/services/media_vault_service.dart';
import 'package:scannut/features/pet/services/pet_profile_service.dart';
import 'package:scannut/features/pet/services/pet_indexing_service.dart'; // 🧠 Indexing Service
import 'package:path/path.dart' as p;

class PetBodyAnalysisCard extends StatefulWidget {
  final String? petId; // 🛡️ UUID Link
  final String petName;
  final List<Map<String, dynamic>> analysisHistory;
  final Function(Map<String, dynamic>)? onDeleteAnalysis;
  final VoidCallback? onAnalysisSaved; // 🔄 Callback para recarregar histórico
  
  const PetBodyAnalysisCard({
    super.key, 
    this.petId,
    required this.petName,
    this.analysisHistory = const [],
    this.onDeleteAnalysis,
    this.onAnalysisSaved, // 🔄 Novo parâmetro
  });

  @override
  State<PetBodyAnalysisCard> createState() => _PetBodyAnalysisCardState();
}

class _PetBodyAnalysisCardState extends State<PetBodyAnalysisCard> {
  bool _isProcessing = false;
  String? _errorMessage;
  Map<String, dynamic>? _lastResult;
  final ImagePicker _picker = ImagePicker();

  Future<void> _analyze(String path) async {
    debugPrint('🔍 [PetBody] ========== INÍCIO DA ANÁLISE ==========');
    debugPrint('   - Pet: ${widget.petName}');
    debugPrint('   - Image Path: $path');
    
    final strings = AppLocalizations.of(context);
    setState(() {
       _isProcessing = true;
       _errorMessage = null;
       _lastResult = null;
    });

    try {
      debugPrint('🤖 [PetBody] Chamando Gemini AI...');
      final result = await GeminiService().analyzePetBody(path);
      debugPrint('✅ [PetBody] IA retornou resultado: ${result.keys}');
      
      if (mounted) {
        setState(() {
          _lastResult = result;
          _isProcessing = false;
        });
        debugPrint('✅ [PetBody] Estado atualizado com resultado');
      }
      
      debugPrint('💾 [PetBody] Iniciando auto-save...');
      await _autoSave(result, path);
      debugPrint('✅ [PetBody] Auto-save concluído');

    } catch (e) {
      debugPrint('❌ [PetBody] ERRO na análise: $e');
      if (mounted) {
        setState(() {
          _errorMessage = strings?.petBodyError ?? 'Falha na análise postural';
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
     try {
       final XFile? image = await _picker.pickImage(
         source: source,
         imageQuality: 70,
         maxWidth: 1024,
       );
       if (image != null) {
          _analyze(image.path);
       }
     } catch (e) {
       setState(() => _errorMessage = 'Erro ao capturar: $e');
     }
  }

  Future<void> _autoSave(Map<String, dynamic> data, String tempPath) async {
    debugPrint('💾 [PetBody] ========== INÍCIO DO AUTO-SAVE ==========');
    debugPrint('   - Pet: ${widget.petName}');
    debugPrint('   - Temp Path: $tempPath');
    debugPrint('   - Data Keys: ${data.keys}');
    
    try {
       // 🛡️ Resolve ID once at the beginning
       final String petId;
       if (widget.petId != null) {
           petId = widget.petId!;
       } else {
           final petProfile = await PetProfileService().getProfile(widget.petName);
           petId = petProfile?['id']?.toString() ?? widget.petName;
       }
       debugPrint('🔑 [PetBody] UUID pet: $petId');

       final vault = MediaVaultService();
       final file = File(tempPath);
       String finalPath = tempPath;
       
       debugPrint('📁 [PetBody] Verificando arquivo...');
       if (await file.exists()) {
           debugPrint('✅ [PetBody] Arquivo existe, clonando para vault...');
           finalPath = await vault.secureClone(file, MediaVaultService.PETS_DIR, widget.petName, true);
           debugPrint('✅ [PetBody] Arquivo clonado: $finalPath');
       } else {
           debugPrint('⚠️ [PetBody] Arquivo não existe em: $tempPath');
       }

       final analysisForHistory = {
          'analysis_type': 'body_analysis',
          'original_filename': p.basename(tempPath),
          'health_score': data['health_score'],
          'body_signals': data['body_signals'],
          'simple_advice': data['simple_advice'],
          'image_path': finalPath,
          'last_updated': DateTime.now().toIso8601String(),
       };
       
       debugPrint('📝 [PetBody] Dados preparados para histórico:');
       debugPrint('   - analysis_type: ${analysisForHistory['analysis_type']}');
       debugPrint('   - health_score: ${analysisForHistory['health_score']}');
       debugPrint('   - image_path: ${analysisForHistory['image_path']}');

       debugPrint('💾 [PetBody] Salvando no histórico via PetProfileService...');
       await PetProfileService().addAnalysisToHistory(petId, analysisForHistory);
       debugPrint('✅ [PetBody] Salvo no histórico com sucesso');

       final service = PetEventService();
       await service.init();
       
       final score = data['health_score'] ?? '?';
       final signals = data['body_signals'] ?? '';

       final event = PetEvent(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          petId: petId, // ✅ NOW USING REAL UUID
          petName: widget.petName, 
          title: 'Análise Corporal: Score $score/10',
          type: EventType.veterinary, 
          dateTime: DateTime.now(),
          notes: 'Sinais: $signals',
       );
       
       debugPrint('📅 [PetBody] Salvando evento...');
       await service.addEvent(event);
       debugPrint('✅ [PetBody] Evento salvo com sucesso');
       
       debugPrint('✅ [PetBody] Analysis saved successfully to history');
       debugPrint('   - Pet: ${widget.petName}');
       debugPrint('   - Score: $score/10');
       debugPrint('   - Image: $finalPath');
       
       // 🔄 Notificar EditPetForm para recarregar histórico
        if (widget.onAnalysisSaved != null) {
          widget.onAnalysisSaved!.call();
          debugPrint('✅ [PetBody] Callback chamado com sucesso');
        } else {
          debugPrint('⚠️ [PetBody] Callback é NULL - não será chamado');
        }
        
       
       // 🚨 INDEXING INJECTION (Unified Timeline)
       debugPrint('🔍 [TRACE-BODY] STARTING UNIFIED INDEXING...');
       try {
           final filename = p.basename(tempPath);
           final simpleAdvice = data['simple_advice']?.toString() ?? 'Sem recomendações.';
           
           // Validação ID
           final effectivePetId = petId.isNotEmpty ? petId : widget.petName;
           debugPrint('🔍 [TRACE-BODY] Target ID: $effectivePetId, Name: ${widget.petName}');

           await PetIndexingService().indexOccurrence(
              petId: effectivePetId,
              petName: widget.petName,
              group: 'health',
              type: 'Análise Corporal',
              title: 'Análise Corporal (Score $score/10)',
              localizedTitle: 'Análise Corporal (Score $score/10)',
              localizedNotes: 'Arquivo: $filename\nResumo: $simpleAdvice',
              extraData: {
                  'score': score.toString(),
                  'signals': signals.toString(),
                  'advice': simpleAdvice,
                  'file_name': filename,
                  'source': 'body_analysis',
                  'image_path': finalPath,
                  'is_automatic': true
              }
           );
           debugPrint('✅ [TRACE-BODY] SUCESSO! Indexado na Timeline Unificada.');
       } catch (idxError, stack) {
           debugPrint('🛑 [TRACE-BODY] CRITICAL FAILURE na indexação: $idxError');
           debugPrint('🛑 [TRACE-BODY] Stack: $stack');
       }

       debugPrint('🎉 [PetBody] ========== AUTO-SAVE COMPLETO ==========');
    } catch (e) {
       debugPrint('❌ [PetBody] ERRO no save: $e');
       debugPrint('❌ [PetBody] Stack trace: ${StackTrace.current}');
    }
  }
  
  Color _getScoreColor(dynamic scoreObj) {
     final score = int.tryParse(scoreObj?.toString() ?? '0') ?? 0;
     if (score >= 8) return Colors.green;
     if (score >= 5) return Colors.amber;
     return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final scoreColor = _lastResult != null ? _getScoreColor(_lastResult?['health_score']) : Colors.grey;
    final bgColor = _errorMessage != null ? Colors.red.withValues(alpha: 0.1) : (_lastResult != null ? scoreColor.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.2));
    final borderColor = _errorMessage != null ? Colors.red : (_lastResult != null ? scoreColor : Colors.grey.withValues(alpha: 0.3));

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
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                    Row(
                      children: [
                         const Icon(Icons.accessibility_new, color: AppDesign.petPink),
                         const SizedBox(width: 8),
                         Text(
                           strings?.petBodyAnalysisTitle ?? 'Análise Corporal',
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
                 ],
               ),
               
               const SizedBox(height: 8),
               Text(
                 strings?.petBodyAnalysisDesc ?? 'Avalie bem-estar físico e sinais de dor.',
                 style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
               ),
               
               const SizedBox(height: 16),
               
               if (!_isProcessing && _lastResult == null)
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                   children: [
                      _buildInputBtn(Icons.camera_alt, 'Câmera', () => _pickImage(ImageSource.camera)),
                      _buildInputBtn(Icons.image, 'Galeria', () => _pickImage(ImageSource.gallery)),
                   ],
                 ),

               if (_isProcessing)
                  Center(
                    child: Column(
                      children: [
                         const CircularProgressIndicator(color: AppDesign.petPink),
                         const SizedBox(height: 12),
                         Text(strings?.petBodyProcessing ?? 'Analisando...', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),

                if (_lastResult != null) ...[
                   if (_lastResult?['original_filename'] != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Arquivo: ${_lastResult!['original_filename']}',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10, fontStyle: FontStyle.italic),
                        ),
                      ),
                   
                   if (_lastResult?['image_path'] != null && File(_lastResult!['image_path']).existsSync())
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_lastResult!['image_path']), 
                            height: 140, 
                            width: double.infinity, 
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                   _buildResultRow(Icons.favorite, strings?.petBodyHealthScore ?? 'Nível Saúde', '${_lastResult?['health_score']}/10', color: scoreColor),
                   _buildResultRow(Icons.visibility, strings?.petBodySignals ?? 'Sinais', _lastResult?['body_signals']?.toString()),
                   _buildResultRow(Icons.health_and_safety, strings?.petBodyAdvice ?? 'Dica', _lastResult?['simple_advice']?.toString()),
                   
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

                if (widget.analysisHistory.any((a) => a['analysis_type'] == 'body_analysis')) ...[
                   const SizedBox(height: 24),
                   const Divider(color: Colors.white10),
                   const SizedBox(height: 8),
                   const Text('Histórico Postural', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 12),
                   ...widget.analysisHistory
                       .where((a) => a['analysis_type'] == 'body_analysis')
                       .map((a) => _buildHistoryItem(a)),
                ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputBtn(IconData icon, String label, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
             Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
               child: Icon(icon, color: Colors.white, size: 28),
             ),
             const SizedBox(height: 8),
             Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ),
      );
  }

  Widget _buildResultRow(IconData icon, String label, String? value, {Color? color}) {
     return Padding(
       padding: const EdgeInsets.only(bottom: 12),
       child: Row(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            Icon(icon, size: 20, color: color ?? Colors.white70),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(
                    value ?? '...', 
                    style: TextStyle(color: color ?? Colors.white, fontWeight: FontWeight.w600, fontSize: 14)
                  ),
                ],
              ),
            ),
         ],
       ),
     );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
     final score = item['health_score']?.toString() ?? '?';
     final filename = item['original_filename']?.toString() ?? 'Img s/ nome';
     final color = _getScoreColor(item['health_score']);
     
     return InkWell(
       onTap: () => setState(() {
         _lastResult = item;
         _errorMessage = null;
       }),
       borderRadius: BorderRadius.circular(8),
       child: Container(
         margin: const EdgeInsets.only(bottom: 8),
         padding: const EdgeInsets.all(10),
         decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
         child: Row(
           children: [
              Icon(Icons.accessibility_new, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                   Text(filename, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                   Text('Bem-estar: $score/10', style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.bold)),
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
