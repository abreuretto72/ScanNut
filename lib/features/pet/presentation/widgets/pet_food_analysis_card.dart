import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scannut/core/theme/app_design.dart';
import 'package:scannut/l10n/app_localizations.dart';
import 'package:scannut/core/services/gemini_service.dart';
import 'package:scannut/core/services/media_vault_service.dart';
import 'package:scannut/features/pet/services/pet_profile_service.dart';
import 'package:scannut/features/pet/services/pet_indexing_service.dart'; // 🧠 Indexing Service
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../../../../core/services/image_deduplication_service.dart';

class PetFoodAnalysisCard extends StatefulWidget {
  final String? petId; // 🛡️ UUID Link
  final String petName;
  final List<Map<String, dynamic>> analysisHistory;
  
  const PetFoodAnalysisCard({
    super.key, 
    this.petId,
    required this.petName,
    this.analysisHistory = const [],
    this.onDeleteAnalysis,
    this.onAnalysisSaved,
  });

  final Function(Map<String, dynamic>)? onDeleteAnalysis;
  final VoidCallback? onAnalysisSaved;

  @override
  State<PetFoodAnalysisCard> createState() => _PetFoodAnalysisCardState();
}

class _PetFoodAnalysisCardState extends State<PetFoodAnalysisCard> {
  bool _isProcessing = false;
  String? _errorMessage;
  Map<String, dynamic>? _lastResult;
  final ImagePicker _picker = ImagePicker();

  Future<void> _analyze(String path) async {
    final strings = AppLocalizations.of(context);
    setState(() {
       _isProcessing = true;
       _errorMessage = null;
       _lastResult = null;
    });

    try {
      // 🛡️ [V180] Deduplication Check
      final deduplication = ImageDeduplicationService();
      final imageFile = File(path);
      final hash = await deduplication.calculateHash(imageFile);
      
      if (hash.isNotEmpty) {
          final existing = await deduplication.checkDeduplication(hash);
          if (existing != null) {
              debugPrint('🚫 [PetFood] [DEDUPLICATION] Match found. Stopping.');
              if (mounted) {
                  setState(() {
                      _errorMessage = strings?.error_image_already_analyzed ?? 'Imagem já analisada.';
                      _isProcessing = false;
                  });
              }
              return;
          }
      }

      // 1. Fetch Pet Context
      final profileMap = await PetProfileService().getProfile(widget.petId ?? widget.petName);
      String? age;
      String? breedSpecies;
      String? weight;
      
      if (profileMap != null && profileMap['data'] != null) {
          final data = profileMap['data'];
          age = data['idade']?.toString();
          final especie = data['especie']?.toString() ?? '';
          final raca = data['raca']?.toString() ?? '';
          breedSpecies = "$especie / $raca".trim();
          weight = data['peso']?.toString();
      }

      // 2. Analyze with Gemini
      final result = await GeminiService().analyzePetFood(
        path,
        age: age,
        breedSpecies: breedSpecies,
        weight: weight,
      );
      
      if (mounted) {
        setState(() {
          _lastResult = result;
          _isProcessing = false;
        });
      }
      
      await _autoSave(result, path);
      
      // 🛡️ [V180] Register hash on success
      if (hash.isNotEmpty) {
          await deduplication.registerProcessedImage(
              hash: hash,
              type: 'pet_food_label',
              petId: widget.petId,
              petName: widget.petName,
          );
      }

    } catch (e) {
      debugPrint('🚨 [PetFood] Analysis failed: $e');
      if (mounted) {
        setState(() {
          _errorMessage = strings?.petFoodError ?? 'Erro na leitura';
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
     try {
       final XFile? image = await _picker.pickImage(
         source: source,
         imageQuality: 70, // Optimize
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
    try {
       // 1. Secure the image first
       final vault = MediaVaultService();
       final file = File(tempPath);
       String finalPath = tempPath;
       
       if (await file.exists()) {
           // 🛡️ Skip automatic indexing (4th param = true) to avoid duplicate VAULT_UPLOAD event
           finalPath = await vault.secureClone(file, MediaVaultService.PETS_DIR, widget.petName, true);
       }

       // 2. Prepare data for general history
       final analysisForHistory = {
          'id': const Uuid().v4(), // 🛡️ BLINDAGEM: UUID Único
          'analysis_type': 'food_label',
          'original_filename': p.basename(tempPath),
          'image_path': finalPath,
          'last_updated': DateTime.now().toIso8601String(),
          
          // Legacy check (for older versions compatibility if needed)
          'veredit': data['analise_rotulo']?['qualidade'] ?? 'N/A',
          'simple_reason': data['analise_rotulo']?['marca'] ?? '',
          
          // New Structure
          'data': data, 
       };

       await PetProfileService().addAnalysisToHistory(widget.petId ?? widget.petName, analysisForHistory);

       // 3. Save to PetEvents
       // 3. Save to Unified Timeline via Indexing Service
       final quality = data['analise_rotulo']?['qualidade'] ?? 'N/A';
       final marca = data['analise_rotulo']?['marca'] ?? 'Desconhecida';
       
       final filename = p.basename(tempPath);
       final feedback = data['feedback_visual'] ?? 'Info indisponível'; 
       final sugestoes = data['sugestoes'] as List<dynamic>? ?? [];
       String suggestionText = '';
       if (sugestoes.isNotEmpty) {
          final sName = sugestoes.first['marka'] ?? sugestoes.first['marca'] ?? '';
          if (sName.toString().isNotEmpty) suggestionText = '\nSugestão: $sName'; 
       }

       // Resumo Conciso (Max 5 linhas)
       final summary = 'Arquivo: $filename\nMarca: $marca\nQualidade: $quality\nStatus: $feedback$suggestionText';

       await PetIndexingService().indexOccurrence(
          petId: widget.petId ?? widget.petName,
          petName: widget.petName,
          group: 'food',
          type: 'Análise de Rótulo',
          title: 'Análise Rótulo: $marca',
          localizedTitle: 'Análise Rótulo: $marca',
          localizedNotes: summary,
          extraData: {
             'quality': quality,
             'brand': marca,
             'file_name': filename,
             'source': 'food_label',
             'image_path': finalPath
          }
       );
       
       debugPrint('✅ [PetFood] Auto-saved to Unified Timeline.');
       
       if (widget.onAnalysisSaved != null) {
         widget.onAnalysisSaved!();
       }
    } catch (e) {
       debugPrint('❌ [PetFood] Save failed: $e');
    }
  }
  
  Color _getVereditColor(Map<String, dynamic>? result) {
     if (result == null) return Colors.grey;
     
     // 1. Try new feedback_visual field
     final feedback = result['feedback_visual']?.toString().toLowerCase();
     if (feedback == 'saudavel') return Colors.green;
     if (feedback == 'alerta' || feedback == 'critico') return Colors.red;

     // 2. Fallback to nested data if result is history item
     if (result['data'] != null && result['data'] is Map) {
        final innerFeedback = result['data']['feedback_visual']?.toString().toLowerCase();
        if (innerFeedback == 'saudavel') return Colors.green;
        if (innerFeedback == 'alerta' || innerFeedback == 'critico') return Colors.red;
     }

     // 3. Last fallback (Legacy compatibility)
     final veredit = result['veredit']?.toString().toLowerCase() ?? '';
     if (veredit.contains('boa')) return Colors.green;
     if (veredit.contains('regular')) return Colors.amber;
     if (veredit.contains('ruim') || veredit.contains('pessima')) return Colors.red;
     
     return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final vereditColor = _lastResult != null ? _getVereditColor(_lastResult) : Colors.grey;
    final bgColor = _errorMessage != null ? Colors.red.withValues(alpha: 0.1) : (_lastResult != null ? vereditColor.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.2));
    final borderColor = _errorMessage != null ? Colors.red : (_lastResult != null ? vereditColor : Colors.grey.withValues(alpha: 0.3));

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
                         const Icon(Icons.restaurant, color: AppDesign.petPink),
                         const SizedBox(width: 8),
                         Text(
                           strings?.petFoodCardTitle ?? 'Análise de Rótulo',
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
               
               const SizedBox(height: 16),
               
               // Botões Dual Input
               if (!_isProcessing && _lastResult == null)
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                   children: [
                      _buildInputBtn(Icons.camera_alt, 'Câmera', () => _pickImage(ImageSource.camera)),
                      _buildInputBtn(Icons.image, 'Galeria', () => _pickImage(ImageSource.gallery)),
                   ],
                 ),

               if (_isProcessing)
                  const Center(child: CircularProgressIndicator(color: AppDesign.petPink)),

                // Resultados
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
                            height: 120, 
                            width: double.infinity, 
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                   _buildNutritionalDetails(_lastResult!),
                   
                   const SizedBox(height: 12),
                   _buildSuggestions(_lastResult!),

                   const SizedBox(height: 16),
                   _buildDisclaimer(_lastResult!),
                   
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

                // --- HISTÓRICO DE RÓTULOS ---
                if (widget.analysisHistory.any((a) => a['analysis_type'] == 'food_label')) ...[
                   const SizedBox(height: 24),
                   const Divider(color: Colors.white10),
                   const SizedBox(height: 8),
                   const Text('Rótulos Analisados', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 12),
                   ...widget.analysisHistory
                       .where((a) => a['analysis_type'] == 'food_label')
                       .map((a) => _buildFoodHistoryItem(a)),
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

  Widget _buildNutritionalDetails(Map<String, dynamic> result) {
      final data = result.containsKey('analise_rotulo') ? result : (result['data'] ?? {});
      final analysis = data['analise_rotulo'] ?? {};
      final nutrients = analysis['nutrientes'] ?? {};
      final alertas = analysis['alertas'] as List<dynamic>? ?? [];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultRow(Icons.branding_watermark, 'Marca Identificada', analysis['marca'] ?? 'Desconhecida'),
          _buildResultRow(Icons.verified, 'Qualidade', analysis['qualidade'] ?? 'Standard', color: _getVereditColor(result)),
          
          const SizedBox(height: 8),
          const Text('Níveis Garantidos:', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
               Expanded(child: _buildNutrientChip('Proteína', nutrients['proteina'] ?? '0%')),
               const SizedBox(width: 8),
               Expanded(child: _buildNutrientChip('Gordura', nutrients['gordura'] ?? '0%')),
               const SizedBox(width: 8),
               Expanded(child: _buildNutrientChip('Fibras', nutrients['fibras'] ?? '0%')),
            ],
          ),

          if (alertas.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Alertas:', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            ...alertas.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text('• $a', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            )),
          ],
        ],
      );
  }

  Widget _buildNutrientChip(String label, String value) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            Text(
              label, 
              style: const TextStyle(color: Colors.white54, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              value, 
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
  }

  Widget _buildSuggestions(Map<String, dynamic> result) {
      final data = result.containsKey('sugestoes') ? result : (result['data'] ?? {});
      final sugestoes = data['sugestoes'] as List<dynamic>? ?? [];
      if (sugestoes.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sugestões Inteligentes:', style: TextStyle(color: AppDesign.petPink, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...sugestoes.map((s) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppDesign.petPink.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s['marca'] ?? 'Marca Sugerida', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(s['motivo'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          )),
        ],
      );
  }

  Widget _buildDisclaimer(Map<String, dynamic> result) {
      final data = result.containsKey('aviso_legal') ? result : (result['data'] ?? {});
      final aviso = data['aviso_legal'] ?? 'Consulta ao Veterinário é indispensável.';
      
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.gavel, color: Colors.orange, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(aviso, style: const TextStyle(color: Colors.orange, fontSize: 11))),
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

  Widget _buildFoodHistoryItem(Map<String, dynamic> item) {
     final veredit = item['veredit']?.toString() ?? 'N/A';
     final filename = item['original_filename']?.toString() ?? 'Imagem s/ nome';
     final color = _getVereditColor(item);
     
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
              Icon(Icons.description, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                   Text(filename, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                   Text('Resultado: $veredit', style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.bold)),
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
