import 'dart:io';
import 'package:path/path.dart' as path;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../../core/theme/app_design.dart';
import '../../../../l10n/app_localizations.dart';
import '../../models/pet_event_model.dart';
import '../../models/attachment_model.dart';
import '../../services/pet_event_repository.dart';
import '../../services/pet_profile_service.dart';
import '../../../../core/models/partner_model.dart';
import '../../../../core/services/partner_service.dart';
import '../../../partners/presentation/partner_registration_screen.dart';
import '../../../../core/services/file_upload_service.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../../core/services/media_vault_service.dart';
import '../../../../core/enums/scannut_mode.dart';
import 'attachment_analysis_dialog.dart';

class PetEventBottomSheet extends StatefulWidget {
  final String petId;
  final String groupId;
  final String groupLabel;

  const PetEventBottomSheet({
    Key? key,
    required this.petId,
    required this.groupId,
    required this.groupLabel,
  }) : super(key: key);

  @override
  State<PetEventBottomSheet> createState() => _PetEventBottomSheetState();
}

class _PetEventBottomSheetState extends State<PetEventBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _titleController = TextEditingController();
  
  // Speech to Text
  late stt.SpeechToText _speech;
  bool _isListening = false;
  
  DateTime _eventDate = DateTime.now();
  String? _selectedSubtype;
  bool _includeInPdf = true;
  bool _isSaving = false;
  bool _showValidationError = false; // Validation state
  bool _showDetails = false;
  bool _isAnalyzing = false; // Controls the analysis overlay
  
  final List<AttachmentModel> _attachments = [];
  final Map<String, dynamic> _dynamicData = {};
  
  // Group Subtypes mapping (simplified labels here, should ideally be from l10n)
  static const Map<String, List<String>> _groupSubtypes = {
    'food': ['refeicao', 'petisco', 'recusou', 'dieta'],
    'health': ['medicamento', 'sintoma', 'consulta', 'vacina'],
    'elimination': ['fezes', 'urina', 'vômito'],
    'grooming': ['banho', 'escovação', 'tosa', 'unhas', 'ouvidos'],
    'activity': ['passeio', 'brincadeira', 'treino'],
    'behavior': ['ansiedade', 'agressivo', 'letárgico', 'normal', 'outros'],
    'schedule': ['lembrete', 'consulta', 'vacina', 'banho'],
    'media': ['foto', 'vídeo'],
    'metrics': ['peso', 'medidas', 'humor'],
    'medication': ['comprimido', 'xarope', 'gotas', 'pomada', 'injeção'],
    'documents': ['registro', 'viagem', 'seguro', 'contrato'],
    'exams': ['sangue', 'imagem', 'urina', 'fezes', 'biópsia'],
    'allergies': ['alimentar', 'picada', 'medicamento', 'contato'],
    'dentistry': ['limpeza', 'extração', 'dor', 'tártaro'],
    'other': ['anotação', 'evento'],
  };


  @override
  void initState() {
    super.initState();
    // Default subtype
    if (_groupSubtypes.containsKey(widget.groupId)) {
      _selectedSubtype = _groupSubtypes[widget.groupId]!.first;
    }
    // Initialize speech to text
    _speech = stt.SpeechToText();
    // Initialize Partner Service
    PartnerService().init();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(String kind, String prefix) async {
    final service = FileUploadService();
    File? file;
    
    try {
      if (kind == 'camera') file = await service.pickFromCamera();
      else if (kind == 'gallery') file = await service.pickFromGallery();
      else if (kind == 'file') file = await service.pickPdfFile();
      
      if (file == null) return;
      
      // Check size (20MB)
      final size = await file.length();
      if (size > 20 * 1024 * 1024) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(
             content: Text(AppLocalizations.of(context)!.petEvent_attachError),
             backgroundColor: AppDesign.error,
           ));
        }
        return;
      }

      // Calculate simple hash (sha256)
      final bytes = await file.readAsBytes();
      final hash = sha256.convert(bytes).toString();

      // Check for duplicates
      if (_attachments.any((a) => a.hash == hash)) {
        debugPrint('PET_EVENTS: Duplicate attachment ignored.');
        return;
      }

      // Save file permanently (this puts it in a safe dir)
      var finalPath = await service.saveMedicalDocument(
        file: file,
        petName: widget.petId,
        attachmentType: 'event_${widget.groupId}',
      );

      if (finalPath != null && mounted) {
        // ASK FOR NAME & RENAME
        final friendlyName = await _askFileName(context);
        
        // If user provided a name, rename the file following convention
        if (friendlyName != null && friendlyName.isNotEmpty) {
            final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
            final ext = path.extension(finalPath);
            // Sanitize name
            final cleanName = friendlyName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '').trim();
            final safeName = cleanName.isEmpty ? 'Anexo' : cleanName;
            
            final newFileName = '${timestamp}_${prefix}_$safeName$ext';
            
            final dir = File(finalPath).parent.path;
            final newPath = path.join(dir, newFileName);
            
            try {
              await File(finalPath).rename(newPath);
              finalPath = newPath;
            } catch (e) {
              debugPrint('Rename failed: $e');
            }
        }

        final newAttachment = AttachmentModel(
            id: const Uuid().v4(),
            kind: kind == 'file' ? 'file' : 'image',
            path: finalPath!,
            mimeType: kind == 'file' ? 'application/pdf' : 'image/jpeg',
            size: size,
            hash: hash,
            createdAt: DateTime.now(),
        );

        setState(() {
          _attachments.add(newAttachment);
        });
        
        if (mounted) _askToAnalyze(newAttachment);
      }
    } catch (e) {
      debugPrint('❌ PET_EVENTS: Attach error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.petEvent_attachError),
          backgroundColor: AppDesign.error,
        ));
      }
    }
  }

  Future<String?> _askFileName(BuildContext context) async {
      final l10n = AppLocalizations.of(context)!;
      String imageName = "";
      return showDialog<String>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            backgroundColor: AppDesign.surfaceDark,
            title: Text(l10n.petAttachmentNameTitle, style: const TextStyle(color: Colors.white)),
            content: TextField(
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: l10n.petAttachmentNameHint,
                hintStyle: const TextStyle(color: Colors.white30),
                enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppDesign.petPink)),
              ),
              onChanged: (val) => imageName = val,
            ),
            actions: [
               TextButton(
                 onPressed: () => Navigator.pop(ctx, null), // Cancel returns null (means keep default or cancel?) 
                 // My logic above: if friendlyName != null && isNotEmpty -> rename.
                 // So if cancel, we use original name (which is likely UUID from saveMedicalDocument).
                 // Prompt says "Sempre... deve renomeá-lo".
                 // So I should enforce name?
                 // If I return 'Anexo' on cancel, it gets standardized.
                 child: Text(l10n.petEvent_cancel, style: const TextStyle(color: Colors.white60))
               ),
               ElevatedButton(
                 style: ElevatedButton.styleFrom(backgroundColor: AppDesign.petPink),
                 onPressed: () => Navigator.pop(ctx, imageName.isEmpty ? 'Anexo' : imageName), 
                 child: const Text('OK', style: TextStyle(color: Colors.white))
               ),
            ],
          );
        }
      );
  }

  void _showCategoryHelp(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // Map of help content based on groupId
    // Using prompt definitions:
    String helpText = '';
    String title = '';
    
    switch (widget.groupId) {
      case 'food':
        title = 'Alimentação';
        helpText = "Registre trocas de ração, petiscos novos ou dietas naturais. Anexe fotos da embalagem ou do prato.";
        break;
      case 'health':
        title = 'Saúde';
        helpText = "Registre sintomas, feridas ou mal-estar. Anexe fotos de lesões para análise clínica.";
        break;
      case 'elimination':
        title = 'Fezes/Urina';
        helpText = "Monitore alterações de cor ou consistência. Anexe fotos para identificação de anomalias.";
        break;
      case 'medication':
        title = 'Medicação';
        helpText = "Registre receitas e horários. Anexe a bula ou a receita física para leitura por IA.";
        break;
      case 'grooming':
        title = 'Higiene';
        helpText = "Banhos, tosas e corte de unhas. Monitore a frequência e alergias a shampoos.";
        break;
      case 'activity':
        title = 'Atividade';
        helpText = "Passeios, treinamentos e exercícios físicos. Registre o progresso e o cansaço.";
        break;
      case 'behavior':
        title = 'Comportamento';
        helpText = "Mudanças de humor, medo ou agressividade. Útil para identificar gatilhos de estresse.";
        break;
      case 'schedule':
        title = 'Agenda';
        helpText = "Lembretes de retorno ao veterinário, check-ups ou compromissos futuros.";
        break;
      case 'documents':
        title = 'Documentos';
        helpText = "Guarde RGs, Pedigrees, microchips e contratos de compra/adoção.";
        break;
      case 'exams':
        title = 'Exames';
        helpText = "Anexe aqui resultados de sangue, urina ou imagem. A IA extrairá os dados técnicos.";
        break;
      case 'allergies':
        title = 'Alergias';
        helpText = "Registre reações alérgicas e coceiras. Ajuda a identificar padrões sazonais ou alimentares.";
        break;
      case 'dentistry':
        title = 'Odontologia';
        helpText = "Saúde bucal: tártaro, gengivas e dentes. Anexe fotos da boca para monitoramento.";
        break;
      case 'metrics':
        title = 'Métricas';
        helpText = "Acompanhe peso, altura e medidas corporais. Gere gráficos de crescimento.";
        break;
      case 'media':
        title = 'Mídia/Fotos';
        helpText = "Galeria de fotos e vídeos do pet. Registre momentos especiais.";
        break;
      case 'other':
        title = 'Outros';
        helpText = "Qualquer registro geral que não se encaixe nas categorias acima.";
        break;
      default:
        title = widget.groupLabel;
        helpText = "Anexe arquivos e descreva o evento para manter o histórico do pet completo.";
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppDesign.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
            children: [
                const Icon(Icons.info_outline, color: AppDesign.petPink),
                const SizedBox(width: 10),
                Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18))),
            ]
        ),
        content: Text(helpText, style: const TextStyle(color: Colors.white70, height: 1.5, fontSize: 16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), 
              child: const Text('Entendi', style: TextStyle(color: AppDesign.petPink, fontWeight: FontWeight.bold))
          ),
        ],
      )
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;

    // VALIDATION: Notes are mandatory
    if (_notesController.text.trim().isEmpty) {
       setState(() => _showValidationError = true);
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
         content: Text(l10n.petEvent_errorRequired),
         backgroundColor: AppDesign.error,
       ));
       return;
    }

    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      String title = _titleController.text.trim();
      if (title.isEmpty) {
         title = widget.groupLabel;
      }

      final event = PetEventModel(
        id: const Uuid().v4(),
        petId: widget.petId,
        group: widget.groupId,
        type: _selectedSubtype ?? 'other',
        title: title,
        notes: _notesController.text.trim(),
        timestamp: _eventDate,
        includeInPdf: _includeInPdf,
        data: _dynamicData,
        attachments: _attachments,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final repo = PetEventRepository();
      await repo.addEvent(event);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.petEvent_savedSuccess),
          backgroundColor: AppDesign.success,
        ));
      }
    } catch (e) {
      debugPrint('❌ PET_EVENTS: Save crash: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.petEvent_saveError),
          backgroundColor: AppDesign.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isFood = widget.groupId.trim().toLowerCase() == 'food';

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85, // Fixed height for consistency
      child: Stack(
        children: [
          Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            decoration: const BoxDecoration(
              color: AppDesign.surfaceDark,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(_getGroupIcon(), color: AppDesign.petPink),
                          const SizedBox(width: 8),
                          Text(
                            widget.groupLabel,
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                           IconButton(
                              icon: const Icon(Icons.info_outline, color: Colors.white60, size: 20),
                              onPressed: () => _showCategoryHelp(context),
                              tooltip: 'Ajuda',
                           ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white60),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                ),
          
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subtypes Chips (Hidden for Food)
                    // Subtypes Chips REMOVED as per request
                    /* 
                    if (!isFood) ...[
                      Text(l10n.petEvent_type.toUpperCase(), style: const TextStyle(color: AppDesign.petPink, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (_groupSubtypes[widget.groupId] ?? ['other']).map((s) {
                          final isSelected = _selectedSubtype == s;
                          return ChoiceChip(
                            label: Text(s),
                            selected: isSelected,
                            onSelected: (val) => setState(() => _selectedSubtype = s),
                            selectedColor: AppDesign.petPink,
                            labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white, fontSize: 12),
                            backgroundColor: AppDesign.backgroundDark,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],
                    */

                    
                    // Date Time Picker
                    InkWell(
                      onTap: () => _pickDateTime(),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppDesign.backgroundDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: AppDesign.petPink, size: 18),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat('dd/MM/yyyy HH:mm').format(_eventDate),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Notes with Speech-to-Text
                    // Notes with Speech-to-Text
                    TextFormField(
                      controller: _notesController,
                      onChanged: (val) {
                         if (_showValidationError && val.trim().isNotEmpty) {
                            setState(() => _showValidationError = false);
                         }
                      },
                      style: const TextStyle(color: Colors.white),
                      minLines: 5,
                      maxLines: null,
                      decoration: InputDecoration(
                        errorText: _showValidationError ? l10n.petEvent_errorRequired : null,
                        errorStyle: const TextStyle(color: Colors.redAccent),
                        hintText: widget.groupId == 'schedule' 
                            ? 'O que vai ser feito nesta data?' 
                            : 'Descreva a ocorrência com detalhes',
                        hintStyle: const TextStyle(color: Colors.white30),
                        filled: true,
                        fillColor: AppDesign.backgroundDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: _isListening ? Colors.red : Colors.white,
                          ),
                          onPressed: _listen,
                          tooltip: 'Gravar por voz',
                        ),
                      ),
                    ),
                    
                    if (_isListening)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          l10n.healthEventListening,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),

                    
                    const SizedBox(height: 20),
                    
                    // Dynamic Data Section (Payload)
                    _buildDynamicFields(),
                    
                    const SizedBox(height: 10),
                    

                    // Expandable Details REMOVED as per request

                    const SizedBox(height: 20),

                    // Attachments
                    _buildAttachmentsSection(l10n),
                    
                    const SizedBox(height: 32),
                    
                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(l10n.petEvent_cancel, style: const TextStyle(color: Colors.white60)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppDesign.petPink,
                              foregroundColor: Colors.black, // TEXTO PRETO PURO
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isSaving 
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                              : const Text('SALVAR', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    // SAFE AREA / PADDING EXTRA
                    SizedBox(height: 24 + MediaQuery.of(context).padding.bottom),
                  ],
                ),
              ),
            ),
          ),
          ],
        ),
      ),
      if (_isAnalyzing)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                    const Icon(Icons.hourglass_empty, color: AppDesign.petPink, size: 80),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppDesign.petPink, 
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, spreadRadius: 5)
                        ]
                      ),
                      child: const Text(
                        "Analisando imagem", 
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
    ],
  ),
);
  }

  Widget _buildAttachmentsSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ANEXOS', style: TextStyle(color: AppDesign.petPink, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildAttachBtn(Icons.camera_alt, 'Câmera', () => _pickFile('camera', 'F')),
            _buildAttachBtn(Icons.photo_library, 'Galeria', () => _pickFile('gallery', 'G')),
            _buildAttachBtn(Icons.description, 'Arquivo', () => _pickFile('file', 'A')),
          ],
        ),
        if (_attachments.isNotEmpty) ...[
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _attachments.length,
            itemBuilder: (context, index) {
              final a = _attachments[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppDesign.backgroundDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FutureBuilder<String>(
                  future: MediaVaultService().attemptRecovery(a.path),
                  builder: (context, snapshot) {
                    final currentPath = snapshot.data ?? a.path;
                    final isBroken = currentPath == 'REMOVED_BY_SANITIZER' || !File(currentPath).existsSync();
                    final isSidecar = a.analysisResult == 'SIDEAR_FILE';
                    
                    return Row(
                      children: [
                        Icon(
                          isBroken 
                             ? Icons.broken_image_outlined 
                             : (isSidecar ? Icons.analytics_outlined : (a.kind == 'file' ? Icons.description : Icons.image)),
                          color: isBroken ? Colors.white24 : (isSidecar ? Colors.greenAccent : AppDesign.petPink), 
                          size: 20
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: isSidecar 
                               ? () {
                                   try {
                                      final content = File(a.path).readAsStringSync();
                                      AttachmentAnalysisDialog.show(context, content);
                                   } catch (e) {
                                      debugPrint("Error reading sidecar: $e");
                                   }
                                 }
                               : null,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isSidecar ? "LAUDO CLÍNICO IA" : _parseAttachmentName(a.path),
                                  style: TextStyle(
                                     color: isSidecar ? Colors.greenAccent : Colors.white, 
                                     fontSize: 13, 
                                     fontWeight: FontWeight.w500
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  isSidecar ? "Documento Técnico Gerado" : '${(a.size / 1024 / 1024).toStringAsFixed(1)}MB',
                                  style: const TextStyle(color: Colors.white30, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                          onPressed: () => setState(() => _attachments.removeAt(index)),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildAttachBtn(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppDesign.backgroundDark,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Icon(icon, color: Colors.white70, size: 20),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
        ],
      ),
    );
  }
  Widget _buildDynamicFields() {
    // Implement standard dynamic fields per group
    switch (widget.groupId) {
      case 'food':
        return _buildFeedingEventFields();

        return _buildHealthEventFields();
      
      case 'metrics':
        return Column(
          children: [
             _buildTextField('peso', 'Peso (kg)', keyboardType: TextInputType.number, icon: Icons.monitor_weight),
             const SizedBox(height: 12),
             _buildTextField('medidas', 'Medidas (cm)', icon: Icons.straighten),
          ],
        );
      case 'activity':
        return Column(
          children: [
             _buildTextField('duracao', 'Duração (minutos)', keyboardType: TextInputType.number, icon: Icons.timer),
             const SizedBox(height: 12),
             _buildChipsField('intensidade', 'Intensidade', ['Leve', 'Moderada', 'Intensa']),
          ],
        );
      case 'elimination':
        return Column(
          children: [
             _buildChipsField('tipo_el', 'Ocorrência', ['Fezes', 'Urina', 'Vômito']),
             const SizedBox(height: 12),
             _buildTextField('consistencia', 'Consistência / Cor', icon: Icons.color_lens),
             const SizedBox(height: 12),
             _buildSwitchField('sangue', 'Presença de sangue?'),
          ],
        );
      case 'grooming':
        return Column(
          children: [
             _buildTextField('produto', 'Produto utilizado', icon: Icons.cleaning_services),
             const SizedBox(height: 12),
             _buildChipsField('reacao', 'Reação', ['Calmo', 'Agitado', 'Apreensivo']),
          ],
        );
      case 'behavior':
        return Column(
          children: [
             _buildTextField('gatilho', 'Gatilho / Motivo', icon: Icons.bolt),
             const SizedBox(height: 12),
             _buildRatingField('nota', 'Nota do Comportamento (1-5)'),
          ],
        );
      case 'schedule':
        return Column(
          children: [
             _buildPartnerDropdown('partnerId', 'Parceiro / Local'),
             const SizedBox(height: 12),
             _buildSwitchField('lembrete', 'Ativar Lembrete?'),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // Speech to Text functionality
  Future<void> _listen() async {
    final l10n = AppLocalizations.of(context)!;
    
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
          setState(() => _isListening = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.healthEventSpeechError)),
          );
        },
      );
      
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _notesController.text = result.recognizedWords;
            });
          },
          localeId: 'pt_BR', // Use current locale
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  // Simplified Feeding Event Fields (Empty as per user request to remove Dropdown)
  Widget _buildFeedingEventFields() {
    return const SizedBox.shrink();
  }

  bool _isClinicalEventType(String eventType) {
    final clinicalEvents = [
      'vomitingImmediate',
      'vomitingDelayed',
      'nausea',
      'choking',
      'regurgitation',
      'excessiveFlatulence',
      'apparentAbdominalPain',
      'diarrhea',
      'softStool',
      'constipation',
      'stoolWithMucus',
      'stoolWithBlood',
      'stoolColorChange',
      'abnormalStoolOdor',
      'suspectedFoodIntolerance',
      'suspectedFoodAllergy',
      'adverseFoodReaction',
      'dietNotTolerated',
      'therapeuticDietRefusal',
      'clinicalWorseningAfterMeal',
      'needForDietAdjustment',
      'assistedFeeding',
    ];
    return clinicalEvents.contains(eventType);
  }

  // Health Event Fields with Categorized Dropdown
  Widget _buildHealthEventFields() {
    final l10n = AppLocalizations.of(context)!;
    
    // Health event types organized by groups (using localized group names as keys)
    final healthEventGroups = {
      l10n.health_group_daily_monitoring: [
        'temperature_check',
        'weight_check',
        'appetite_monitoring',
        'hydration_check',
        'energy_level',
        'behavior_observation',
      ],
      l10n.health_group_acute_symptoms: [
        'fever',
        'vomiting',
        'diarrhea',
        'lethargy',
        'loss_of_appetite',
        'excessive_thirst',
        'difficulty_breathing',
        'coughing',
        'sneezing',
        'nasal_discharge',
      ],
      l10n.health_group_infectious: [
        'suspected_infection',
        'wound_infection',
        'ear_infection',
        'eye_infection',
        'urinary_infection',
        'parasite_detected',
        'tick_found',
        'flea_infestation',
      ],
      l10n.health_group_dermatological: [
        'skin_rash',
        'itching',
        'hair_loss',
        'hot_spot',
        'wound',
        'abscess',
        'allergic_reaction',
        'swelling',
      ],
      l10n.health_group_mobility: [
        'limping',
        'joint_pain',
        'difficulty_walking',
        'stiffness',
        'muscle_weakness',
        'fall',
        'fracture_suspected',
      ],
      l10n.health_group_neurological: [
        'seizure',
        'tremors',
        'disorientation',
        'loss_of_balance',
        'vision_problems',
        'hearing_problems',
        'head_tilt',
      ],
      l10n.health_group_treatment: [
        'medication_administered',
        'vaccine_given',
        'wound_cleaning',
        'bandage_change',
        'vet_visit',
        'surgery',
        'emergency_care',
        'hospitalization',
      ],
    };

    // Emergency event types
    final emergencyEvents = [
      'vomiting',
      'diarrhea',
      'difficulty_breathing',
      'suspected_infection',
      'wound_infection',
      'urinary_infection',
      'wound',
      'abscess',
      'allergic_reaction',
      'swelling',
      'difficulty_walking',
      'fall',
      'fracture_suspected',
      'seizure',
      'tremors',
      'disorientation',
      'loss_of_balance',
      'head_tilt',
      'emergency_care',
      'hospitalization',
    ];

    // Get localized label for event type
    String getEventTypeLabel(String eventType) {
      final key = 'health_type_$eventType';
      try {
        // Use reflection-like approach to get localized string
        switch (eventType) {
          case 'temperature_check': return l10n.health_type_temperature_check;
          case 'weight_check': return l10n.health_type_weight_check;
          case 'appetite_monitoring': return l10n.health_type_appetite_monitoring;
          case 'hydration_check': return l10n.health_type_hydration_check;
          case 'energy_level': return l10n.health_type_energy_level;
          case 'behavior_observation': return l10n.health_type_behavior_observation;
          case 'fever': return l10n.health_type_fever;
          case 'vomiting': return l10n.health_type_vomiting;
          case 'diarrhea': return l10n.health_type_diarrhea;
          case 'lethargy': return l10n.health_type_lethargy;
          case 'loss_of_appetite': return l10n.health_type_loss_of_appetite;
          case 'excessive_thirst': return l10n.health_type_excessive_thirst;
          case 'difficulty_breathing': return l10n.health_type_difficulty_breathing;
          case 'coughing': return l10n.health_type_coughing;
          case 'sneezing': return l10n.health_type_sneezing;
          case 'nasal_discharge': return l10n.health_type_nasal_discharge;
          case 'suspected_infection': return l10n.health_type_suspected_infection;
          case 'wound_infection': return l10n.health_type_wound_infection;
          case 'ear_infection': return l10n.health_type_ear_infection;
          case 'eye_infection': return l10n.health_type_eye_infection;
          case 'urinary_infection': return l10n.health_type_urinary_infection;
          case 'parasite_detected': return l10n.health_type_parasite_detected;
          case 'tick_found': return l10n.health_type_tick_found;
          case 'flea_infestation': return l10n.health_type_flea_infestation;
          case 'skin_rash': return l10n.health_type_skin_rash;
          case 'itching': return l10n.health_type_itching;
          case 'hair_loss': return l10n.health_type_hair_loss;
          case 'hot_spot': return l10n.health_type_hot_spot;
          case 'wound': return l10n.health_type_wound;
          case 'abscess': return l10n.health_type_abscess;
          case 'allergic_reaction': return l10n.health_type_allergic_reaction;
          case 'swelling': return l10n.health_type_swelling;
          case 'limping': return l10n.health_type_limping;
          case 'joint_pain': return l10n.health_type_joint_pain;
          case 'difficulty_walking': return l10n.health_type_difficulty_walking;
          case 'stiffness': return l10n.health_type_stiffness;
          case 'muscle_weakness': return l10n.health_type_muscle_weakness;
          case 'fall': return l10n.health_type_fall;
          case 'fracture_suspected': return l10n.health_type_fracture_suspected;
          case 'seizure': return l10n.health_type_seizure;
          case 'tremors': return l10n.health_type_tremors;
          case 'disorientation': return l10n.health_type_disorientation;
          case 'loss_of_balance': return l10n.health_type_loss_of_balance;
          case 'vision_problems': return l10n.health_type_vision_problems;
          case 'hearing_problems': return l10n.health_type_hearing_problems;
          case 'head_tilt': return l10n.health_type_head_tilt;
          case 'medication_administered': return l10n.health_type_medication_administered;
          case 'vaccine_given': return l10n.health_type_vaccine_given;
          case 'wound_cleaning': return l10n.health_type_wound_cleaning;
          case 'bandage_change': return l10n.health_type_bandage_change;
          case 'vet_visit': return l10n.health_type_vet_visit;
          case 'surgery': return l10n.health_type_surgery;
          case 'emergency_care': return l10n.health_type_emergency_care;
          case 'hospitalization': return l10n.health_type_hospitalization;
          default: return eventType;
        }
      } catch (_) {
        return eventType;
      }
    }

    final selectedEventType = _dynamicData['health_event_type'] as String?;
    final isEmergency = _dynamicData['is_emergency'] as bool? ?? false;
    final isEmergencyEvent = selectedEventType != null && emergencyEvents.contains(selectedEventType);

    // Build dropdown items with category headers
    final dropdownItems = <DropdownMenuItem<String>>[];
    
    for (final group in healthEventGroups.entries) {
      // Add category header (disabled item)
      dropdownItems.add(
        DropdownMenuItem<String>(
          value: null,
          enabled: false,
          child: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              group.key,
              style: const TextStyle(
                color: AppDesign.petPink,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
      
      // Add items in this category
      for (final eventType in group.value) {
        dropdownItems.add(
          DropdownMenuItem<String>(
            value: eventType,
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                getEventTypeLabel(eventType),
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Event Type Dropdown
        Text(
          l10n.healthEventSelectType.toUpperCase(),
          style: const TextStyle(color: AppDesign.petPink, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        DropdownButtonFormField<String>(
          value: selectedEventType,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppDesign.backgroundDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          dropdownColor: AppDesign.surfaceDark,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          icon: const Icon(Icons.arrow_drop_down, color: AppDesign.petPink),
          hint: Text(
            l10n.healthEventSelectType,
            style: const TextStyle(color: Colors.white30, fontSize: 13),
          ),
          items: dropdownItems,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _dynamicData['health_event_type'] = value;
                // Auto-set emergency for critical events
                if (emergencyEvents.contains(value)) {
                  _dynamicData['is_emergency'] = true;
                  _dynamicData['severity'] = 'severe';
                }
              });
            }
          },
        ),

        if (selectedEventType != null) ...[
          const SizedBox(height: 20),
          
          // Severity
          _buildChipsField(
            'severity',
            l10n.healthEventSeverityLabel,
            [
              l10n.feedingSeverity_mild,
              l10n.feedingSeverity_moderate,
              l10n.feedingSeverity_severe,
            ],
          ),
          const SizedBox(height: 12),
          
          // Emergency Toggle
          SwitchListTile(
            title: Text(
              l10n.healthEventEmergencyToggle,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            subtitle: (isEmergency || isEmergencyEvent)
                ? Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade900.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red.shade700),
                    ),
                    child: Text(
                      l10n.healthEventEmergencyAlert,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                    ),
                  )
                : null,
            value: isEmergency || isEmergencyEvent,
            activeColor: Colors.red,
            onChanged: isEmergencyEvent 
                ? null // Disable toggle for emergency events
                : (val) {
                    setState(() {
                      _dynamicData['is_emergency'] = val;
                      if (val) {
                        _dynamicData['severity'] = 'severe';
                      }
                    });
                  },
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ],
    );
  }

  Widget _buildPartnerDropdown(String key, String label) {
    // 1. Fetch Providers
    final partners = PartnerService().getAllPartners();
    
    final selectedId = _dynamicData[key];

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: partners.any((p) => p.id == selectedId) ? selectedId : null,
            dropdownColor: AppDesign.surfaceDark,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(color: Colors.white30, fontSize: 12),
              prefixIcon: const Icon(Icons.place, color: Colors.white30, size: 18),
              filled: true,
              fillColor: AppDesign.backgroundDark,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            items: partners
                .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (val) {
                if (val != null) {
                    final partner = partners.firstWhere((p) => p.id == val);
                    setState(() {
                        _dynamicData[key] = val;
                        _dynamicData['local'] = partner.name; // For backward compatibility with UI that shows 'local'
                    });
                }
            },
            hint: Text(
              partners.isEmpty ? 'Nenhum parceiro cadastrado' : 'Selecione um parceiro',
              style: const TextStyle(color: Colors.white30, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () async {
            // Navigate to Add Partner
            final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const PartnerRegistrationScreen()));
            // Refresh state to show new partner
            if (result == true || (result is Map && result['updated'] == true)) {
                 setState(() {});
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppDesign.petPink,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add, color: Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String key, String label, {TextInputType? keyboardType, IconData? icon}) {
    return TextFormField(
      style: const TextStyle(color: Colors.white, fontSize: 14),
      keyboardType: keyboardType,
      onChanged: (val) => _dynamicData[key] = val,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white30, fontSize: 12),
        prefixIcon: icon != null ? Icon(icon, color: Colors.white30, size: 18) : null,
        filled: true,
        fillColor: AppDesign.backgroundDark,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildChipsField(String key, String label, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: AppDesign.petPink, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: options.map((o) {
            final isSelected = _dynamicData[key] == o;
            return ChoiceChip(
              label: Text(o, style: TextStyle(color: isSelected ? Colors.black : Colors.white70, fontSize: 11)),
              selected: isSelected,
              onSelected: (val) => setState(() => _dynamicData[key] = o),
              selectedColor: AppDesign.petPink,
              backgroundColor: AppDesign.backgroundDark,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSwitchField(String key, String label) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      value: _dynamicData[key] ?? false,
      activeColor: AppDesign.petPink,
      onChanged: (val) => setState(() => _dynamicData[key] = val),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildRatingField(String key, String label) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: AppDesign.petPink, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (i) {
            final val = i + 1;
            final isSelected = (_dynamicData[key] ?? 1) >= val;
            return IconButton(
              icon: Icon(isSelected ? Icons.star : Icons.star_border, color: AppDesign.petPink),
              onPressed: () => setState(() => _dynamicData[key] = val),
            );
          }),
        ),
      ],
    );
  }

  IconData _getGroupIcon() {
    switch (widget.groupId) {
      case 'food': return Icons.restaurant;
      case 'health': return Icons.medical_services;
      case 'elimination': return Icons.opacity;
      case 'grooming': return Icons.content_cut;
      case 'activity': return Icons.directions_walk;
      case 'behavior': return Icons.psychology;
      case 'schedule': return Icons.event;
      case 'media': return Icons.photo_camera;
      case 'metrics': return Icons.straighten;
      case 'medication': return Icons.medication;
      case 'documents': return Icons.description;
      case 'exams': return Icons.biotech;
      case 'allergies': return Icons.warning_amber;
      case 'dentistry': return Icons.health_and_safety;
      case 'other': return Icons.bookmark_border;
      default: return Icons.event_note;
    }
  }


  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppDesign.petPink, onPrimary: Colors.black, surface: AppDesign.surfaceDark),
        ),
        child: child!,
      ),
    );

    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_eventDate),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppDesign.petPink, onPrimary: Colors.black, surface: AppDesign.surfaceDark),
        ),
        child: child!,
      ),
    );

    if (time != null) {
      setState(() {
        _eventDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      });
    }
  }

  Future<void> _askToAnalyze(AttachmentModel attachment) async {
    final l10n = AppLocalizations.of(context)!;
    
    // Only analyze images for now
    if (attachment.kind != 'image') return; 

    final mode = await showDialog<ScannutMode>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: AppDesign.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
           const Icon(Icons.auto_awesome, color: AppDesign.petPink),
           const SizedBox(width: 8),
           Expanded(child: Text(l10n.petAttachmentAnalyzeTitle, style: const TextStyle(color: Colors.white, fontSize: 18))),
        ]),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(l10n.petAttachmentAnalyzeQuestion, style: const TextStyle(color: Colors.white70)),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, ScannutMode.petVisualAnalysis),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(children: [
                const Icon(Icons.image_search, color: AppDesign.petPink),
                const SizedBox(width: 12),
                Expanded(child: Text(l10n.petAttachmentOptionPhoto, style: const TextStyle(color: Colors.white, fontSize: 16))),
              ]),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, ScannutMode.petDocumentOCR),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(children: [
                const Icon(Icons.description, color: AppDesign.petPink),
                const SizedBox(width: 12),
                Expanded(child: Text(l10n.petAttachmentOptionOCR, style: const TextStyle(color: Colors.white, fontSize: 16))),
              ]),
            ),
          ),
          Center(
             child: TextButton(
               onPressed: () => Navigator.pop(ctx, null),
               child: Text(l10n.petNamePromptCancel, style: const TextStyle(color: Colors.white54)),
             ),
          ),
        ],
      ),
    );

    if (mode != null && mounted) {
      _analyzeAttachment(attachment, mode);
    }
  }

  Future<void> _analyzeAttachment(AttachmentModel attachment, ScannutMode mode) async {
    final l10n = AppLocalizations.of(context)!;
    
    // UI: Trigger Loading Overlay
    setState(() => _isAnalyzing = true);

    try {
      final gemini = GeminiService();
      final file = File(attachment.path);
      
      // Get Pet Data for context if available
      final profile = await PetProfileService().getProfile(widget.petId);
      final petData = profile?['data'] as Map?;

      final result = await gemini.analyzeImage(
        imageFile: file, 
        mode: mode,
        locale: Localizations.localeOf(context).toString(),
        contextData: {
            'groupId': widget.groupId,
            'species': petData?['species'] ?? 'Unknown',
            'breed': petData?['breed'] ?? 'Unknown',
        },
      );
      
      final resultString = jsonEncode(result);
      String? sidecarFilePath;

      // 💾 SIDEAR RECORDING: Save analysis result alongside the original file
      try {
        final imageFile = File(attachment.path);
        sidecarFilePath = path.join(
          imageFile.parent.path, 
          "${path.basenameWithoutExtension(imageFile.path)}_ResuAnalise.json"
        );
        await File(sidecarFilePath).writeAsString(resultString);
        debugPrint('🔐 VAULT: Analysis sidecar recorded at $sidecarFilePath');
        
        // ATOMIC MIRRORING: Also replicate to public backup
        final vault = MediaVaultService();
        // Determine category for backup mirroring
        String category = MediaVaultService.PETS_DIR;
        if (widget.groupId.contains('food')) category = MediaVaultService.FOOD_DIR;
        else if (widget.groupId.contains('health')) category = MediaVaultService.WOUNDS_DIR;
        
        final safePetName = widget.petId.replaceAll(RegExp(r'\s+'), '_').toLowerCase();
        
        // We manually place it in the backup mirror to ensure "Absolute Retention"
        final appDir = await getApplicationSupportDirectory();
        final backupRoot = Directory('${appDir.path}/ScanNut_Safe_Backup/$category/$safePetName');
        if (await backupRoot.exists()) {
           final backupResultPath = path.join(backupRoot.path, "${path.basenameWithoutExtension(imageFile.path)}_ResuAnalise.json");
           await File(backupResultPath).writeAsString(resultString);
           debugPrint('🛡️ MIRROR: Analysis sidecar replicated to backup.');
        }
      } catch (e) {
        debugPrint('⚠️ Sidecar Error: $e');
      }
      
      final newAttachedImage = AttachmentModel(
        id: attachment.id,
        kind: attachment.kind,
        path: attachment.path,
        mimeType: attachment.mimeType,
        size: attachment.size,
        hash: attachment.hash,
        createdAt: attachment.createdAt,
        analysisResult: resultString,
      );

      // Create Attachment for the Sidecar JSON
      AttachmentModel? sidecarAttachment;
      if (sidecarFilePath != null) {
        final sidecarFile = File(sidecarFilePath);
        if (await sidecarFile.exists()) {
          sidecarAttachment = AttachmentModel(
            id: const Uuid().v4(),
            kind: 'file',
            path: sidecarFilePath,
            mimeType: 'application/json',
            size: await sidecarFile.length(),
            hash: sha256.convert(await sidecarFile.readAsBytes()).toString(),
            createdAt: DateTime.now(),
            analysisResult: 'SIDEAR_FILE', // Marker
          );
        }
      }
      
      setState(() {
        final index = _attachments.indexWhere((a) => a.id == attachment.id);
        if (index != -1) {
          _attachments[index] = newAttachedImage;
          if (sidecarAttachment != null) {
            _attachments.insert(index + 1, sidecarAttachment);
          }
        }
        _isAnalyzing = false; // Stop loading
      });
      
      if (mounted) {
        // Show success briefly
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.petAttachmentAnalysisSuccess),
          backgroundColor: AppDesign.success,
          duration: const Duration(seconds: 1),
        ));
        
        // Show result dialog
        AttachmentAnalysisDialog.show(context, resultString);
      }

    } catch (e) {
      debugPrint('AI Analysis Error: $e');
      if (mounted) {
        setState(() => _isAnalyzing = false); // Stop loading on error
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.petAttachmentAnalysisError),
          backgroundColor: AppDesign.error,
        ));
      }
    }
  }

  String _parseAttachmentName(String filePath) {
    final filename = path.basenameWithoutExtension(filePath);
    return filename.replaceFirst(RegExp(r'^\d{8}_\d{6}_[A-Z]_'), '')
                   .replaceFirst(RegExp(r'^\d{8}_\d{6}_'), '');
  }
}
