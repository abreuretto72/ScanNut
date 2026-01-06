import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../l10n/app_localizations.dart';
import '../../models/pet_event_model.dart';
import '../../models/attachment_model.dart';
import '../../services/pet_event_repository.dart';
import '../../../../core/services/file_upload_service.dart';

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
  
  DateTime _eventDate = DateTime.now();
  String? _selectedSubtype;
  bool _includeInPdf = true;
  bool _isSaving = false;
  bool _showDetails = false;
  
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
  };

  @override
  void initState() {
    super.initState();
    // Default subtype
    if (_groupSubtypes.containsKey(widget.groupId)) {
      _selectedSubtype = _groupSubtypes[widget.groupId]!.first;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(String kind) async {
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

      // Save file permanently
      final savedPath = await service.saveMedicalDocument(
        file: file,
        petName: widget.petId,
        attachmentType: 'event_${widget.groupId}',
      );

      if (savedPath != null) {
        setState(() {
          _attachments.add(AttachmentModel(
            id: const Uuid().v4(),
            kind: kind == 'file' ? 'file' : 'image',
            path: savedPath,
            mimeType: kind == 'file' ? 'application/pdf' : 'image/jpeg',
            size: size,
            hash: hash,
            createdAt: DateTime.now(),
          ));
        });
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    final l10n = AppLocalizations.of(context)!;
    
    try {
      String title = _titleController.text.trim();
      if (title.isEmpty) {
        title = '${widget.groupLabel} — ${_selectedSubtype ?? ""}';
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

    return Container(
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
                    // Subtypes Chips
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
                    
                    // Notes
                    TextFormField(
                      controller: _notesController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: l10n.petEvent_notes,
                        hintStyle: const TextStyle(color: Colors.white30),
                        filled: true,
                        fillColor: AppDesign.backgroundDark,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Dynamic Data Section (Payload)
                    _buildDynamicFields(),
                    
                    const SizedBox(height: 10),
                    
                    // Expandable Details
                    InkWell(
                      onTap: () => setState(() => _showDetails = !_showDetails),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(l10n.petEvent_details, style: const TextStyle(color: AppDesign.petPink, fontWeight: FontWeight.bold)),
                            Icon(_showDetails ? Icons.expand_less : Icons.expand_more, color: AppDesign.petPink),
                          ],
                        ),
                      ),
                    ),
                    
                    if (_showDetails) ...[
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _titleController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Título customizado (opcional)',
                          hintStyle: const TextStyle(color: Colors.white30),
                          filled: true,
                          fillColor: AppDesign.backgroundDark,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: Text(l10n.petEvent_includeInPdf, style: const TextStyle(color: Colors.white, fontSize: 14)),
                        value: _includeInPdf,
                        activeColor: AppDesign.petPink,
                        onChanged: (val) => setState(() => _includeInPdf = val),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                    
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
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isSaving 
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                              : Text(l10n.petEvent_save.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          )
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
            _buildAttachBtn(Icons.camera_alt, 'Câmera', () => _pickFile('camera')),
            _buildAttachBtn(Icons.photo_library, 'Galeria', () => _pickFile('gallery')),
            _buildAttachBtn(Icons.description, 'Arquivo', () => _pickFile('file')),
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
                child: Row(
                  children: [
                    Icon(a.kind == 'file' ? Icons.description : Icons.image, color: AppDesign.petPink, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Anexo ${index + 1} (${(a.size / 1024 / 1024).toStringAsFixed(1)}MB)',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                      onPressed: () => setState(() => _attachments.removeAt(index)),
                    ),
                  ],
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
        return Column(
          children: [
             _buildTextField('quantidade', 'Quantidade (ex: 200g)', icon: Icons.scale),
             const SizedBox(height: 12),
             _buildTextField('marca', 'Marca/Ração', icon: Icons.shopping_bag),
             const SizedBox(height: 12),
             _buildChipsField('apetite', 'Apetite', ['Normal', 'Baixo', 'Alto']),
          ],
        );
      case 'health':
        return Column(
          children: [
            _buildTextField('med_name', 'Nome do Medicamento', icon: Icons.medication),
            const SizedBox(height: 12),
            _buildTextField('dose', 'Dose', icon: Icons.vaccines),
            const SizedBox(height: 12),
            _buildRatingField('intensidade', 'Intensidade / Dor (1-5)'),
          ],
        );
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
             _buildTextField('local', 'Local / Profissional', icon: Icons.place),
             const SizedBox(height: 12),
             _buildSwitchField('lembrete', 'Ativar Lembrete?'),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
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
}
