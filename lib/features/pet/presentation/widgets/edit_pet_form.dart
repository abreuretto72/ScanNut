import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../../../partners/presentation/partner_agenda_screen.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:scannut/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../../../../core/services/file_upload_service.dart';
import '../../../../core/services/gemini_service.dart';
import '../../models/pet_profile_extended.dart';
import '../../models/pet_analysis_result.dart';
import 'pet_result_card.dart';
import '../../../partners/presentation/partners_screen.dart';
import '../../../partners/presentation/partners_hub_screen.dart'; // Add this line
import '../../../partners/presentation/partner_registration_screen.dart'; // Add this line
import '../../../../core/services/whatsapp_service.dart';
import '../../../../core/services/partner_service.dart';
import '../../../../core/models/partner_model.dart';
import '../../../../core/widgets/pdf_action_button.dart';
import '../../../../core/services/export_service.dart';
import '../../../../core/widgets/pdf_preview_screen.dart';
import '../../../../core/widgets/app_pdf_icon.dart';
import '../../../../core/widgets/pdf_section_filter_dialog.dart';
import '../../../../core/widgets/cumulative_observations_field.dart';
import '../../models/lab_exam.dart';
import '../../services/lab_exam_service.dart';
import 'lab_exams_section.dart';
import 'race_analysis_detail_screen.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/pet_weight_database.dart';
import '../../services/pet_profile_service.dart';

enum SaveStatus { saved, saving, error }

/// Comprehensive pet profile edit form with tabs
class EditPetForm extends StatefulWidget {
  final PetProfileExtended? existingProfile;
  final Map<String, dynamic>? petData;
  final Function(PetProfileExtended) onSave;
  final VoidCallback? onCancel;
  final VoidCallback? onDelete;
  final bool isNewEntry;

  const EditPetForm({
    Key? key, 
    this.existingProfile, 
    this.petData,
    required this.onSave, 
    this.onCancel, 
    this.onDelete, 
    this.isNewEntry = false,
    this.initialTabIndex = 0,
  }) : super(key: key);

  final int initialTabIndex;

  @override
  State<EditPetForm> createState() => _EditPetFormState();
}

class _EditPetFormState extends State<EditPetForm> 
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _racaController;
  late TextEditingController _idadeController;
  late TextEditingController _pesoController;
  late TextEditingController _pesoIdealController; // New
  late TextEditingController _alergiasController;
  late TextEditingController _preferenciasController;

  // Dropdown values
  String _nivelAtividade = 'Moderado';
  String _statusReprodutivo = 'Castrado';
  String _frequenciaBanho = 'Quinzenal';

  // Dates
  DateTime? _dataUltimaV10;
  DateTime? _dataUltimaAntirrabica;

  // Lists
  List<String> _alergiasConhecidas = [];
  List<String> _preferencias = [];
  List<String> _linkedPartnerIds = [];
  List<PartnerModel> _linkedPartnerModels = [];
  Map<String, List<Map<String, dynamic>>> _partnerNotes = {}; 
  List<Map<String, dynamic>> _weightHistory = [];
  List<LabExam> _labExams = []; // Lab exams with OCR
  List<Map<String, dynamic>> _woundHistory = []; // Local state for wound analysis history

  // Cumulative Observations (with timestamps)
  String _observacoesIdentidade = '';
  String _observacoesSaude = '';
  String _observacoesNutricao = '';
  String _observacoesGaleria = '';
  String _observacoesPrac = '';

  // File Upload
  final FileUploadService _fileService = FileUploadService();
  Map<String, List<File>> _attachments = {
    'identity': [],
    'health_exams': [],
    'health_prescriptions': [],
    'health_vaccines': [],
    'nutrition': [],
    'gallery': [],
  };
  
  Map<String, dynamic>? _currentRawAnalysis;
  File? _profileImage;
  String? _initialImagePath;

  // Auto-Save State
  bool _hasChanges = false;
  bool _isSaving = false;
  PetProfileExtended? _petBackup; // Backup for Undo
  
  // Partner Updates
  final PartnerService _partnerService = PartnerService();
  final Map<String, PartnerModel> _modifiedPartners = {};
  
  // Lab Exams
  final LabExamService _labExamService = LabExamService();
  final ImagePicker _imagePicker = ImagePicker();

  // Atomic Save Logic
  Timer? _debounce;
  bool _isSavingSilently = false;

  void _onUserTyping() {
      // Mark as changed locally
      _hasChanges = true;
      
      // Cancel previous timer
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      
      // Start new timer (500ms debounce)
      _debounce = Timer(const Duration(milliseconds: 500), () {
          _saveNow(silent: true);
      });
  }

  void _onUserInteractionGeneric() {
      // Immediate save for clicks/toggles
      _hasChanges = true;
      if (mounted) setState(() {});
      _saveNow(silent: true);
  }

  // Deprecated: Use _onUserTyping or _onUserInteractionGeneric
  void _markDirty() {
    _onUserTyping();
  }

  Future<void> _saveNow({bool silent = false}) async {
    // Basic validation only if not silent (to allow partial saves during typing if valid)
    // For auto-save, we try to save what we can.
    
    // If saving explicitly (exit), we validate fully.
    if (!silent && !_formKey.currentState!.validate()) return;
    
    // Check if already saving
    if (_isSaving) return;

    if (mounted) {
        if (silent) {
            _isSavingSilently = true;
        } else {
            setState(() => _isSaving = true);
        }
    }

    try {
       String? finalImagePath = _initialImagePath;
      
       // Save new profile image if selected
       if (_profileImage != null && _profileImage!.path != _initialImagePath) {
        final savedPath = await _fileService.saveMedicalDocument(
          file: _profileImage!,
          petName: _nameController.text.trim(),
          attachmentType: 'profile_pic',
        );
        if (savedPath != null) {
          finalImagePath = savedPath;
        }
       }

       final profile = PetProfileExtended(
        petName: _nameController.text.trim(),
        raca: _racaController.text.trim().isEmpty ? null : _racaController.text.trim(),
        idadeExata: _idadeController.text.trim().isEmpty ? null : _idadeController.text.trim(),
        pesoAtual: double.tryParse(_pesoController.text.trim()),
        pesoIdeal: double.tryParse(_pesoIdealController.text.trim()),
        nivelAtividade: _nivelAtividade,
        statusReprodutivo: _statusReprodutivo,
        alergiasConhecidas: _alergiasConhecidas,
        preferencias: _preferencias,
        dataUltimaV10: _dataUltimaV10,
        dataUltimaAntirrabica: _dataUltimaAntirrabica,
        frequenciaBanho: _frequenciaBanho,
        linkedPartnerIds: _linkedPartnerIds,
        partnerNotes: _partnerNotes,
        weightHistory: _getUpdatedWeightHistory(),
        labExams: _labExams.map((e) => e.toJson()).toList(),
        woundAnalysisHistory: _woundHistory,
        observacoesIdentidade: _observacoesIdentidade,
        observacoesSaude: _observacoesSaude,
        observacoesNutricao: _observacoesNutricao,
        observacoesGaleria: _observacoesGaleria,
        observacoesPrac: _observacoesPrac,
        lastUpdated: DateTime.now(),
        imagePath: finalImagePath,
        rawAnalysis: _currentRawAnalysis,
       );

       await widget.onSave(profile);

       // Save modified partners
       if (_modifiedPartners.isNotEmpty) {
           for (final p in _modifiedPartners.values) {
               await _partnerService.savePartner(p);
           }
       }
       
       // Update Backup for Undo (Atomic Save -> New Baseline)
       _petBackup = _deepCopyProfile(profile);
       _hasChanges = true; // Keep true so PopScope can still do verify if needed, or set false?
       // Actually, with atomic save, we are always "saved". 
       // But user might want to "Undo" changes made in this session.
       // The prompt says: "Undo system must be updated to reflect the last saved state."
       // So basically, Undo reverts to the state BEFORE the session started, OR specific steps?
       // Typically "Undo" in this context (Cancel/Back) might mean "Revert to original".
       // But if we are overwriting the DB immediately, "Cancel" is tricky.
       // However, the prompt says: "If success, UNDO system must be updated to reflect last saved state."
       // This implies the new baseline is NOW. So "Revert" would revert to NOW.
       // This effectively kills "Cancel" button functionality in the traditional sense, which is expected for "Auto-Save" apps like Notion.
       
       if (silent) {
           debugPrint('✅ Auto-Saved (Silent)');
       } else {
           debugPrint('✅ Saved Explicitly');
       }
       
    } catch (e) {
       debugPrint("❌ Save error: $e");
       if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('⚠️ Erro ao sincronizar: $e'), backgroundColor: Colors.red)
           );
       }
    } finally {
       if (mounted) {
           if (silent) {
               _isSavingSilently = false;
           } else {
               setState(() => _isSaving = false);
           }
       }
    }
  }

  @override
  void initState() {
    super.initState();
    
    // CRITICAL: Monitor app lifecycle to save on minimize/close
    WidgetsBinding.instance.addObserver(this);
    
    _partnerService.init();
    _loadAttachments();
    
    // Compute the working profile from direct object or raw Map entry
    final existing = widget.existingProfile ?? 
        (widget.petData != null ? PetProfileExtended.fromHiveEntry(Map<String, dynamic>.from(widget.petData!)) : null);

    // Load existing profile image
    _initialImagePath = existing?.imagePath;
    if (_initialImagePath != null) {
      final file = File(_initialImagePath!);
      if (file.existsSync()) {
        _profileImage = file;
      }
    }

    _tabController = TabController(length: 5, vsync: this, initialIndex: widget.initialTabIndex);
    
    if (existing != null) {
        _petBackup = _deepCopyProfile(existing);
    }

    _nameController = TextEditingController(text: existing?.petName ?? '');
    _racaController = TextEditingController(text: existing?.raca ?? '');
    _idadeController = TextEditingController(text: existing?.idadeExata ?? '');
    _pesoController = TextEditingController(
      text: existing?.pesoAtual?.toString() ?? '',
    );
    _pesoIdealController = TextEditingController(
      text: existing?.pesoIdeal?.toString() ?? '',
    ); // New
    _alergiasController = TextEditingController();
    _preferenciasController = TextEditingController();

    if (existing != null) {
      _nivelAtividade = existing.nivelAtividade ?? 'Moderado';
      _statusReprodutivo = existing.statusReprodutivo ?? 'Castrado';
      _frequenciaBanho = existing.frequenciaBanho ?? 'Quinzenal';
      _dataUltimaV10 = existing.dataUltimaV10;
      _dataUltimaAntirrabica = existing.dataUltimaAntirrabica;
      _alergiasConhecidas = List.from(existing.alergiasConhecidas);
      _preferencias = List.from(existing.preferencias);
      _linkedPartnerIds = List.from(existing.linkedPartnerIds);
      _partnerNotes = Map.from(existing.partnerNotes).map((k, v) => MapEntry(k, List<Map<String, dynamic>>.from(v)));
      _weightHistory = List.from(existing.weightHistory);
      _labExams = (existing.labExams).map((json) => LabExam.fromJson(json)).toList();
      _woundHistory = (existing.woundAnalysisHistory).map((e) => Map<String, dynamic>.from(e)).toList();
      _observacoesIdentidade = existing.observacoesIdentidade;
      _observacoesSaude = existing.observacoesSaude;
      _observacoesNutricao = existing.observacoesNutricao;
      _observacoesGaleria = existing.observacoesGaleria;
      _observacoesPrac = existing.observacoesPrac;
      _loadLinkedPartners(); // Async load
      _currentRawAnalysis = existing.rawAnalysis != null 
          ? Map<String, dynamic>.from(existing.rawAnalysis!) 
          : {};
    } else {
        _currentRawAnalysis = {};
    }
    debugPrint('DEBUG_LOAD: Pet carregado da Box: ${existing?.petName}');


    // Auto-Save Listeners (Direct Binding)
    _nameController.addListener(_onNameChanged);
    _racaController.addListener(_onRacaChanged);
    _idadeController.addListener(_onIdadeChanged);
    _pesoController.addListener(_onPesoChanged);
    _pesoIdealController.addListener(_onPesoIdealChanged);
    _alergiasController.addListener(_onUserTyping);
    _preferenciasController.addListener(_onUserTyping);
  }

  // --- DISK-FIRST LOGGING HELPERS ---
  void _onNameChanged() { debugPrint('DEBUG: Gravando [NOME] no disco agora...'); _onUserTyping(); }
  void _onRacaChanged() { debugPrint('DEBUG: Gravando [RAÇA] no disco agora...'); _onUserTyping(); }
  void _onIdadeChanged() { debugPrint('DEBUG: Gravando [IDADE] no disco agora...'); _onUserTyping(); }
  void _onPesoChanged() { debugPrint('DEBUG: Gravando [PESO] no disco agora...'); _onUserTyping(); }
  void _onPesoIdealChanged() { debugPrint('DEBUG: Gravando [PESO IDEAL] no disco agora...'); _onUserTyping(); }



  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('🔴 App lifecycle changed to: $state');
    
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (_hasChanges) {
        debugPrint('⚠️ CRITICAL: Unsaved changes detected! Saving immediately...');
        _saveNow(silent: true);
      }
    } else if (state == AppLifecycleState.resumed) {
        debugPrint('🔄 App Resumed: Validating data coherence...');
        // In a "Disk-First" architecture, we trusts the DB.
        // However, if we have unsaved changes in memory that failed to write, overwriting them with DB data causes data loss.
        // So we only refresh if we are "clean".
        if (!_hasChanges) {
             _reloadFreshData();
             debugPrint('✅ UI is clean. Refreshed from disk.');
        } else {
             debugPrint('⚠️ UI has unsaved changes. Attempting to merge...');
             // We could reload opaque data here too, but riskier.
             // For now, save existing changes to overwrite disk (user intention prevails).
             _saveNow(silent: true);
        }
    }
  }


  @override
  void dispose() {
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    
    // Cancel debounce
    _debounce?.cancel();
    
    // Dispose controllers
    _tabController.dispose();
    _nameController.dispose();
    _racaController.dispose();
    _idadeController.dispose();
    _pesoController.dispose();
    _pesoIdealController.dispose();
    _alergiasController.dispose();
    _preferenciasController.dispose();
    _labExamService.dispose();
    
    super.dispose();
  }

  Future<void> _savePetProfile() async {
      await _saveNow(silent: false);
  }


  Future<void> _loadLinkedPartners() async {
    if (_linkedPartnerIds.isEmpty) {
        if (mounted) setState(() => _linkedPartnerModels = []);
        return;
    }

    // Need a service method to get partners by IDs or filter all
    // Since we don't have getByIds, we fetch all and filter locally for now (assuming small list)
    try {
        final partnerService = PartnerService();
        await partnerService.init();
        final all = partnerService.getAllPartners();
        debugPrint('DEBUG: LinkedPartner: IDs needed: $_linkedPartnerIds');
        debugPrint('DEBUG: LinkedPartner: Service returned ${all.length} partners');
        
        final matches = all.where((p) => _linkedPartnerIds.contains(p.id)).toList();
        debugPrint('DEBUG: LinkedPartner: Found ${matches.length} matches');
        
        if (mounted) setState(() => _linkedPartnerModels = matches);
    } catch (e) {
        debugPrint('Error loading linked partners: $e');
    }
  }

  // Attachment Logic
  Future<void> _loadAttachments() async {
    final petName = widget.existingProfile?.petName ?? _nameController.text.trim();
    if (petName.isEmpty) return;

    final allDocs = await _fileService.getMedicalDocuments(petName);
    if (!mounted) return;

    setState(() {
      _attachments['identity'] = allDocs.where((f) => path.basename(f.path).startsWith('identity_')).toList();
      _attachments['health_exams'] = allDocs.where((f) => path.basename(f.path).startsWith('health_exams_')).toList();
      _attachments['health_prescriptions'] = allDocs.where((f) => path.basename(f.path).startsWith('health_prescriptions_')).toList();
      _attachments['health_vaccines'] = allDocs.where((f) => path.basename(f.path).startsWith('health_vaccines_')).toList();
      _attachments['nutrition'] = allDocs.where((f) => path.basename(f.path).startsWith('nutrition_')).toList();
      _attachments['gallery'] = allDocs.where((f) => path.basename(f.path).startsWith('gallery_')).toList();
    });
  }

  Future<void> _pickProfileImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Alterar Foto do Perfil', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Tirar Foto', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(ctx);
                final file = await _fileService.pickFromCamera();
                if (file != null) {
                   setState(() => _profileImage = file);
                   _markDirty();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.image, color: Colors.green),
              title: const Text('Escolher da Galeria', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(ctx);
                final file = await _fileService.pickFromGallery();
                if (file != null) {
                   setState(() => _profileImage = file);
                   _markDirty();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImageHeader() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF00E676), width: 3),
              boxShadow: [
                BoxShadow(color: const Color(0xFF00E676).withValues(alpha: 0.3), blurRadius: 15, spreadRadius: 2),
              ],
              image: _profileImage != null
                  ? DecorationImage(image: FileImage(_profileImage!), fit: BoxFit.cover)
                  : null,
            ),
            child: _profileImage == null
                ? const Icon(Icons.pets, size: 60, color: Colors.white24)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 18,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.camera_alt, size: 20, color: Colors.black),
                onPressed: _pickProfileImage,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addAttachment(String type) async {
    final petName = widget.existingProfile?.petName ?? _nameController.text.trim();
    if (petName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salve o pet ou insira o nome primeiro.')));
      return;
    }

    final isGallery = type == 'gallery';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isGallery ? 'Adicionar Mídia' : 'Anexar Documento', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Câmera (Foto)', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(ctx);
                final file = await _fileService.pickFromCamera();
                if (file != null) _saveFile(file, petName, type);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image, color: Colors.green),
              title: const Text('Galeria (Foto)', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(ctx);
                final file = await _fileService.pickFromGallery();
                if (file != null) _saveFile(file, petName, type);
              },
            ),
            if (isGallery) ...[
              ListTile(
                leading: const Icon(Icons.videocam, color: Colors.orange),
                title: const Text('Câmera (Vídeo)', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await _fileService.pickVideoFromCamera();
                  if (file != null) _saveFile(file, petName, type);
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library, color: Colors.purple),
                title: const Text('Galeria (Vídeo)', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await _fileService.pickVideoFromGallery();
                  if (file != null) _saveFile(file, petName, type);
                },
              ),
            ] else 
              ListTile(
                leading: const AppPdfIcon(),
                title: const Text('PDF', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await _fileService.pickPdfFile();
                  if (file != null) _saveFile(file, petName, type);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryTab() {
    final docs = _attachments['gallery'] ?? [];
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildSectionTitle('📸 Book de Mídias'),
        const SizedBox(height: 16),
        Text(
          'Fotos e vídeos dos melhores momentos',
          style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12),
        ),
        const SizedBox(height: 20),

        if (docs.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                const Icon(Icons.perm_media_outlined, size: 48, color: Colors.white24),
                const SizedBox(height: 16),
                Text('A galeria está vazia', style: GoogleFonts.poppins(color: Colors.white54)),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final file = docs[index];
              final isVideo = file.path.toLowerCase().endsWith('.mp4') || file.path.toLowerCase().endsWith('.mov');
              return InkWell(
                onTap: () {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Arquivo: ${path.basename(file.path)}')));
                },
                onLongPress: () => _deleteAttachment(file),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                    image: !isVideo ? DecorationImage(image: FileImage(file), fit: BoxFit.cover) : null,
                  ),
                  child: isVideo 
                    ? const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 32))
                    : null,
                ),
              );
            },
          ),
        
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _addAttachment('gallery'),
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Adicionar à Galeria'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              side: const BorderSide(color: Color(0xFF00E676)),
              foregroundColor: const Color(0xFF00E676),
            ),
          ),
        ),

        const SizedBox(height: 24),
        CumulativeObservationsField(
          sectionName: 'Galeria',
          initialValue: _observacoesGaleria,
          onChanged: (value) {
            setState(() => _observacoesGaleria = value);
            _onUserTyping();
          },
          icon: Icons.photo_library,
          accentColor: Colors.purple,
        ),

        // Include actions at the bottom explicitly
         _buildActionButtons(),
      ],
    );
  }

  Future<void> _saveFile(File file, String petName, String type) async {
    final savedPath = await _fileService.saveMedicalDocument(
      file: file,
      petName: petName,
      attachmentType: type,
    );
    if (savedPath != null) {
      _loadAttachments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Documento anexado!')));
      }
    }
  }

  Future<void> _deleteAttachment(File file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Excluir Anexo?', style: TextStyle(color: Colors.white)),
        content: const Text('Esta ação não pode ser desfeita.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await _fileService.deleteMedicalDocument(file.path);
      _loadAttachments();
    }
  }

  Widget _buildAttachmentSection(String type, String title) {
    final docs = _attachments[type] ?? [];
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.attach_file, color: Colors.white54, size: 16),
                  const SizedBox(width: 8),
                  Text(title, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                  if (docs.isNotEmpty) 
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: const Color(0xFF00E676), shape: BoxShape.circle),
                      child: Text('${docs.length}', style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              IconButton( // Small Add Button
                onPressed: () => _addAttachment(type),
                icon: const Icon(Icons.add_circle_outline, color: Color(0xFF00E676), size: 20),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                tooltip: 'Adicionar',
              ),
            ],
          ),
          if (docs.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final file = docs[index];
                  final isPdf = file.path.toLowerCase().endsWith('.pdf');
                  return InkWell(
                    onTap: () {
                      // TODO: Implement open file
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Arquivo: ${path.basename(file.path)}')));
                    },
                    onLongPress: () => _deleteAttachment(file),
                    child: Container(
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isPdf ? Icons.picture_as_pdf_rounded : Icons.image,
                            color: isPdf ? Colors.red : Colors.blueAccent,
                            size: 24,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isPdf ? 'PDF' : 'IMG',
                            style: const TextStyle(color: Colors.white30, fontSize: 8),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text('Nenhum documento anexado.', style: GoogleFonts.poppins(color: Colors.white30, fontSize: 11, fontStyle: FontStyle.italic)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (bool didPop) async {
        // Atomic Save: Ensure any pending debounce is saved before closing
        if (_debounce?.isActive ?? false) {
           _debounce!.cancel();
           await _saveNow(silent: true);
        }
        // Pass back result if needed (optional via Navigator.pop manually elsewhere, but here logic is auto)
      },
      child: Scaffold(
        backgroundColor: Colors.grey[900],
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text(
            widget.existingProfile == null ? 'Novo Pet' : 'Editar Perfil',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF00E676),
            labelColor: const Color(0xFF00E676),
            unselectedLabelColor: Colors.white60,
            tabs: const [
              Tab(icon: Icon(Icons.pets), text: 'Identidade'),
              Tab(icon: Icon(Icons.favorite), text: 'Saúde'),
              Tab(icon: Icon(Icons.restaurant), text: 'Nutrição'),
              Tab(icon: Icon(Icons.perm_media), text: 'Galeria'),
              Tab(icon: Icon(Icons.handshake_outlined), text: 'Parc.'),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Builder(builder: (context) {
                  if (_isSaving) {
                    return const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white54,
                        strokeWidth: 2,
                      ),
                    );
                  }
                  if (_hasChanges) {
                    return Tooltip(
                      message: 'Desfazer alterações',
                      child: GestureDetector(
                        onTap: _undoAllChanges,
                        child: const Icon(
                          Icons.undo,
                          color: Colors.amberAccent,
                          size: 22,
                        ),
                      ),
                    );
                  }
                  return const Tooltip(
                    message: 'Tudo salvo',
                    child: Icon(
                      Icons.cloud_done,
                      color: Colors.white30,
                      size: 20,
                    ),
                  );
                }),
              ),
            ),
            PdfActionButton(
              onPressed: _generatePetReport,
            ),
            if (widget.onCancel != null)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: widget.onCancel,
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildIdentityTab(),
              _buildHealthTab(),
              _buildNutritionTab(),
              _buildGalleryTab(),
              _buildPartnersTab(),
            ],
          ),
        ),
      ),
    );
  }

  // --- PARTNERS TAB IMPLEMENTATION ---
  
  String _selectedPartnerFilter = 'Todos';
  final List<String> _partnerCategories = ['Todos', 'Veterinário', 'Pet Shop', 'Farmácias Pet', 'Banho e Tosa', 'Hotéis', 'Laboratórios'];

  Widget _buildPartnersTab() {
    return FutureBuilder<List<PartnerModel>>(
      future: (() async {
        final ps = PartnerService();
        await ps.init();
        return ps.getAllPartners();
      })(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)));
        
        final allPartners = snapshot.data!;
        final filtered = _selectedPartnerFilter == 'Todos' 
            ? allPartners 
            : allPartners.where((p) => p.category == _selectedPartnerFilter).toList();

        return CustomScrollView(
          slivers: [
            // 1. Filter Chips Header
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: _partnerCategories.map((cat) {
                    final isSelected = _selectedPartnerFilter == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (v) => setState(() => _selectedPartnerFilter = cat),
                        backgroundColor: Colors.white.withOpacity(0.05),
                        selectedColor: const Color(0xFF00E676),
                        labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white),
                        checkmarkColor: Colors.black,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 10)),

            // 2. Partners List
            if (allPartners.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Nenhum parceiro cadastrado.\nAdicione parceiros através do Hub de Parceiros na tela inicial.',
                      style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
            else if (filtered.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    'Nenhum parceiro encontrado nesta categoria.',
                    style: GoogleFonts.poppins(color: Colors.white30),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final partner = filtered[index];
                      final isLinked = _linkedPartnerIds.contains(partner.id);
                      
                      if (isLinked) {
                        return _LinkedPartnerCard(
                          partner: partner,
                          onUnlink: () async {
                            setState(() {
                              _linkedPartnerIds.remove(partner.id);
                              _linkedPartnerModels.removeWhere((p) => p.id == partner.id);
                            });
                            await PetProfileService().updateLinkedPartners(_nameController.text.trim(), _linkedPartnerIds);
                          },
                          onUpdate: (updated) async {
                            setState(() {
                              _modifiedPartners[updated.id] = updated;
                              final idx = _linkedPartnerModels.indexWhere((p) => p.id == updated.id);
                              if (idx != -1) _linkedPartnerModels[idx] = updated;
                            });
                            await PartnerService().savePartner(updated);
                          },
                          onOpenAgenda: () => _openPartnerAgenda(partner),
                        );
                      }

                      return Card(
                        color: Colors.white.withOpacity(0.05),
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.grey.withOpacity(0.1),
                                child: const Icon(Icons.link_off, color: Colors.grey, size: 20),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(partner.name, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                                    Text(partner.category, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Switch(
                                value: false,
                                activeColor: const Color(0xFF00E676),
                                onChanged: (val) async {
                                  if (val) {
                                    setState(() {
                                      _linkedPartnerIds.add(partner.id);
                                      _linkedPartnerModels.add(partner);
                                    });
                                    await PetProfileService().updateLinkedPartners(_nameController.text.trim(), _linkedPartnerIds);
                                  }
                                },
                              )
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              ),

            // 3. Observations Field
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CumulativeObservationsField(
                  sectionName: 'Prac (Rede de Apoio)',
                  initialValue: _observacoesPrac,
                  onChanged: (value) {
                    setState(() => _observacoesPrac = value);
                    _onUserTyping();
                  },
                  icon: Icons.handshake,
                  accentColor: Colors.blue,
                ),
              ),
            ),

            // 4. Action Buttons
            SliverToBoxAdapter(
              child: _buildActionButtons(),
            ),

            // 5. Bottom Padding (ensures content is visible above keyboard)
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        );
      }
    );
  }





  Widget _buildIdentityTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildProfileImageHeader(),
        const SizedBox(height: 24),
        
        // NOVO: Rede de Apoio (Partners Integration moved to Parc. tab)
        // _buildSupportNetworkCard(),
        const SizedBox(height: 12),

        _buildRaceDetailsSection(),
        const SizedBox(height: 24),

        _buildSectionTitle('🐾 Informações Básicas'),
        const SizedBox(height: 16),
        
        _buildTextField(
          controller: _nameController,
          label: 'Nome do Pet',
          icon: Icons.pets,
          validator: (v) => v?.isEmpty ?? true ? 'Nome obrigatório' : null,
        ),
        
        _buildTextField(
          controller: _racaController,
          label: 'Raça',
          icon: Icons.category,
        ),
        
        _buildTextField(
          controller: _idadeController,
          label: 'Idade Exata (ex: 2 anos 3 meses)',
          icon: Icons.cake,
        ),
        
        const SizedBox(height: 24),
        _buildSectionTitle('⚙️ Perfil Biológico'),
        const SizedBox(height: 16),
        
        _buildDropdown(
          value: _nivelAtividade,
          label: 'Nível de Atividade',
          icon: Icons.directions_run,
          items: ['Sedentário', 'Moderado', 'Ativo'],
          onChanged: (v) { setState(() => _nivelAtividade = v!); _onUserInteractionGeneric(); },
        ),
        
        _buildDropdown(
          value: _statusReprodutivo,
          label: 'Status Reprodutivo',
          icon: Icons.medical_services,
          items: ['Castrado', 'Inteiro'],
          onChanged: (v) { setState(() => _statusReprodutivo = v!); _onUserInteractionGeneric(); },
        ),


        const SizedBox(height: 24),
        CumulativeObservationsField(
          sectionName: 'Identidade',
          initialValue: _observacoesIdentidade,
          onChanged: (value) {
            setState(() => _observacoesIdentidade = value);
            _onUserTyping();
          },
          icon: Icons.pets,
          accentColor: const Color(0xFF00E676),
        ),

        _buildAttachmentSection('identity', 'Documentos de Identificação'),
        
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildHealthTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildSectionTitle('⚖️ Controle de Peso Inteligente'),
        const SizedBox(height: 8),
        Text(
          'Análise automática baseada na raça e porte do pet',
          style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11),
        ),
        const SizedBox(height: 16),
        _buildTextField(
            controller: _pesoController,
            label: 'Peso Atual (kg)',
            icon: Icons.monitor_weight,
            keyboardType: TextInputType.number,
        ),
        _buildWeightFeedback(),
        
        const SizedBox(height: 24),
        _buildSectionTitle('💉 Histórico de Vacinas'),
        const SizedBox(height: 16),
        
        _buildDatePicker(
          label: 'Última V10/V8',
          icon: Icons.vaccines,
          selectedDate: _dataUltimaV10,
          onDateSelected: (date) { setState(() => _dataUltimaV10 = date); _onUserInteractionGeneric(); },
        ),
        
        _buildDatePicker(
          label: 'Última Antirrábica',
          icon: Icons.coronavirus,
          selectedDate: _dataUltimaAntirrabica,
          onDateSelected: (date) { setState(() => _dataUltimaAntirrabica = date); _onUserInteractionGeneric(); },
        ),
        
        const SizedBox(height: 24),
        _buildSectionTitle('🛁 Higiene'),
        const SizedBox(height: 16),
        
        _buildDropdown(
          value: _frequenciaBanho,
          label: 'Frequência de Banho',
          icon: Icons.bathtub,
          items: ['Semanal', 'Quinzenal', 'Mensal'],
          onChanged: (v) { setState(() => _frequenciaBanho = v!); _onUserInteractionGeneric(); },
        ),

        const SizedBox(height: 24),
        
        // New Lab Exams Section
        LabExamsSection(
          exams: _labExams,
          onAddExam: _addLabExam,
          onDeleteExam: _deleteLabExam,
          onExplainExam: _explainLabExam,
          onMarkDirty: _markDirty,
        ),
        
        const SizedBox(height: 24),
        _buildSectionTitle('📄 Outros Documentos Médicos'),
        const SizedBox(height: 8),
        
        _buildAttachmentSection('health_prescriptions', '📝 Receitas Veterinárias'),
        _buildAttachmentSection('health_vaccines', '💉 Carteira de Vacinação'),

        const SizedBox(height: 24),
        _buildWoundAnalysisHistory(),

        const SizedBox(height: 24),
        CumulativeObservationsField(
          sectionName: 'Saúde',
          initialValue: _observacoesSaude,
          onChanged: (value) {
            setState(() => _observacoesSaude = value);
            _onUserTyping();
          },
          icon: Icons.medical_services,
          accentColor: Colors.red,
        ),

        _buildActionButtons(),
      ],
    );
  }

  Widget _buildNutritionTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildSectionTitle('⚠️ Alergias Alimentares'),
        const SizedBox(height: 8),
        Text(
          'Ingredientes que devem ser evitados',
          style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12),
        ),
        const SizedBox(height: 16),
        
        _buildChipInput(
          controller: _alergiasController,
          label: 'Adicionar Alergia',
          icon: Icons.warning,
          chips: _alergiasConhecidas,
          onAdd: (text) {
            setState(() {
              _alergiasConhecidas.add(text);
              _alergiasController.clear();
            });
            _markDirty();
          },
          onDelete: (index) {
            setState(() => _alergiasConhecidas.removeAt(index));
            _markDirty();
          },
        ),
        
        const SizedBox(height: 24),
        _buildSectionTitle('❤️ Preferências Alimentares'),
        const SizedBox(height: 8),
        Text(
          'Alimentos que o pet mais gosta',
          style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12),
        ),
        const SizedBox(height: 16),
        
        _buildChipInput(
          controller: _preferenciasController,
          label: 'Adicionar Preferência',
          icon: Icons.favorite,
          chips: _preferencias,
          chipColor: Colors.green,
          onAdd: (text) {
            setState(() {
              _preferencias.add(text);
              _preferenciasController.clear();
            });
            _markDirty();
          },
          onDelete: (index) {
            setState(() => _preferencias.removeAt(index));
            _markDirty();
          },
        ),

        _buildWeeklyPlanSection(),

        _buildAttachmentSection('nutrition', 'Receitas e Dietas'),
        
        const SizedBox(height: 24),
        CumulativeObservationsField(
          sectionName: 'Nutrição',
          initialValue: _observacoesNutricao,
          onChanged: (value) {
            setState(() => _observacoesNutricao = value);
            _onUserTyping();
          },
          icon: Icons.restaurant,
          accentColor: Colors.orange,
        ),

        _buildActionButtons(),
      ],
    );
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Excluir Pet?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Deseja remover ${widget.existingProfile?.petName ?? 'este pet'} e todo o seu histórico? Esta ação não pode ser desfeita.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir Definitivamente', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && widget.onDelete != null) {
      widget.onDelete!();
    }
  }

  Widget _buildActionButtons() {
    // All actions removed. Edit only mode.
    return const SizedBox(height: 40);
  }

  Widget _buildWoundAnalysisHistory() {
    final woundHistory = _woundHistory;
    
    if (woundHistory.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('🩹 Histórico de Análises de Feridas'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white54, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Nenhuma análise de ferida registrada ainda',
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('🩹 Histórico de Análises de Feridas'),
        const SizedBox(height: 8),
        Text(
          '${woundHistory.length} análise(s) registrada(s)',
          style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 16),
        ...woundHistory.map((analysis) => _buildWoundAnalysisCard(analysis)),
      ],
    );
  }

  Widget _buildWoundAnalysisCard(Map<String, dynamic> analysis) {
    final date = DateTime.parse(analysis['date'] as String);
    final diagnosis = analysis['diagnosis'] as String? ?? 'Sem diagnóstico';
    final severity = analysis['severity'] as String? ?? 'Baixa';
    final recommendations = (analysis['recommendations'] as List?)?.cast<String>() ?? [];
    
    Color severityColor;
    switch (severity) {
      case 'Alta':
        severityColor = Colors.red;
        break;
      case 'Média':
        severityColor = Colors.orange;
        break;
      default:
        severityColor = Colors.green;
    }

    final imagePath = analysis['imagePath'] as String?;
    final hasImage = imagePath != null && imagePath.isNotEmpty && File(imagePath).existsSync();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: severityColor.withOpacity(0.3)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: hasImage 
            ? GestureDetector(
                onTap: () {
                    showDialog(
                        context: context,
                        builder: (ctx) => Dialog(
                            backgroundColor: Colors.transparent,
                            insetPadding: const EdgeInsets.all(10),
                            child: Stack(
                                alignment: Alignment.topRight,
                                children: [
                                    ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(File(imagePath!)),
                                    ),
                                    Container(
                                        margin: const EdgeInsets.all(8),
                                        decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                        ),
                                        child: IconButton(
                                            icon: const Icon(Icons.close, color: Colors.white, size: 20),
                                            onPressed: () => Navigator.pop(ctx),
                                        ),
                                    ),
                                ],
                            ),
                        ),
                    );
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: severityColor.withOpacity(0.5)),
                    image: DecorationImage(
                        image: FileImage(File(imagePath!)),
                        fit: BoxFit.cover,
                    ),
                  ),
                ),
            ) 
            : Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: severityColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.medical_services,
                color: severityColor,
                size: 24,
              ),
            ),
        title: Text(
          DateFormat('dd/MM/yyyy - HH:mm').format(date),
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: severityColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Gravidade: $severity',
                style: GoogleFonts.poppins(
                  color: severityColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.delete_outline,
            color: Colors.red,
            size: 22,
          ),
          onPressed: () => _confirmDeleteWoundAnalysis(analysis['date'] as String),
          tooltip: 'Excluir análise',
        ),
        children: [
          const Divider(color: Colors.white12),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Diagnóstico:',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            diagnosis,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 13,
            ),
          ),
          if (recommendations.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Recomendações:',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            ...recommendations.map((rec) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: GoogleFonts.poppins(color: Colors.white70),
                  ),
                  Expanded(
                    child: Text(
                      rec,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Future<void> _reloadFreshData() async {
      try {
          final service = PetProfileService();
          await service.init();
          final freshData = await service.getProfile(_nameController.text.trim());
          
          if (freshData != null && freshData['data'] != null) {
               final data = freshData['data'];
               
               // 1. Refresh Wound History (Local State)
               if (data['wound_analysis_history'] != null) {
                   if (mounted) {
                      setState(() {
                          _woundHistory = (data['wound_analysis_history'] as List)
                              .map((e) => Map<String, dynamic>.from(e as Map))
                              .toList();
                      });
                   }
               }

               // 2. Refresh Opaque Data (Raw Analysis & Agenda)
               final freshRaw = data['raw_analysis'];
               if (freshRaw != null) {
                   _currentRawAnalysis = Map<String,dynamic>.from(freshRaw);
               }
               
               if (data['agendaEvents'] != null) {
                   _currentRawAnalysis ??= {};
                   _currentRawAnalysis!['agendaEvents'] = data['agendaEvents'];
               }

               debugPrint('HIVE: Dados recarregados e fundidos com sucesso (Wound History + Raw Data).');
          }
      } catch (e) {
          debugPrint('ERRO RECARREGANDO DADOS: $e');
      }
  }

  Future<void> _confirmDeleteWoundAnalysis(String analysisDate) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Excluir Análise',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Tem certeza que deseja excluir esta análise de ferida? Esta ação não pode ser desfeita.',
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(
                color: Colors.white60,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Excluir',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Optimistic update: Remove immediately from UI
      setState(() {
        _woundHistory.removeWhere((w) => w['date'] == analysisDate);
      });

      try {
        // Delete from database
        await PetProfileService().deleteWoundAnalysis(
          petName: _nameController.text.trim(),
          analysisDate: analysisDate,
        );

        // Update verify sync
        await _reloadFreshData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Análise de ferida excluída com sucesso',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        debugPrint('❌ Error deleting wound analysis: $e');
        // Revert optimistic update if needed (optional, but good practice)
        await _reloadFreshData(); 
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Erro ao excluir análise: $e',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white60),
          prefixIcon: Icon(icon, color: const Color(0xFF00E676)),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF00E676), width: 2),
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        dropdownColor: Colors.grey[800],
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white60),
          prefixIcon: Icon(icon, color: const Color(0xFF00E676)),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required IconData icon,
    required DateTime? selectedDate,
    required Function(DateTime?) onDateSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: selectedDate ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime.now(),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: Color(0xFF00E676),
                    onSurface: Colors.white,
                  ),
                ),
                child: child!,
              );
            },
          );
          onDateSelected(date);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF00E676)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      selectedDate != null
                          ? DateFormat('dd/MM/yyyy').format(selectedDate)
                          : 'Não informado',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.calendar_today, color: Colors.white60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChipInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required List<String> chips,
    required Function(String) onAdd,
    required Function(int) onDelete,
    Color chipColor = Colors.red,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: label,
                  labelStyle: const TextStyle(color: Colors.white60),
                  prefixIcon: Icon(icon, color: const Color(0xFF00E676)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (text) {
                  if (text.trim().isNotEmpty) {
                    onAdd(text.trim());
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  onAdd(controller.text.trim());
                }
              },
              icon: const Icon(Icons.add_circle, color: Color(0xFF00E676), size: 32),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: chips.asMap().entries.map((entry) {
            return Chip(
              label: Text(entry.value),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () => onDelete(entry.key),
              backgroundColor: chipColor.withValues(alpha: 0.2),
              labelStyle: GoogleFonts.poppins(color: Colors.white),
              deleteIconColor: Colors.white,
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _generateNewMenu() async {
     if (_nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nome do pet é obrigatório.')));
        return;
     }

     DateTimeRange? selectedDateRange = DateTimeRange(
        start: DateTime.now().add(const Duration(days: 1)),
        end: DateTime.now().add(const Duration(days: 7)),
     );
     bool isNatural = true;
     bool isKibble = false;
     String goal = 'Manutenção de Peso';
     final goals = ['Manutenção de Peso', 'Perda de Peso', 'Ganho de Massa', 'Recuperação/Convalescença'];

     final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) {
           return StatefulBuilder(
              builder: (context, setDialogState) {
                 return AlertDialog(
                    backgroundColor: Colors.grey[900],
                    title: Row(
                       children: [
                          Icon(Icons.auto_awesome, color: const Color(0xFF00E676)),
                          const SizedBox(width: 10),
                          Text(AppLocalizations.of(context)!.menuPlanTitle, style: const TextStyle(color: Colors.white, fontSize: 16)),
                       ],
                    ),
                    content: SingleChildScrollView(
                       child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Text(AppLocalizations.of(context)!.menuPeriod, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                             const SizedBox(height: 8),
                             InkWell(
                                onTap: () async {
                                   final picked = await showDateRangePicker(
                                      context: context,
                                      firstDate: DateTime.now().subtract(const Duration(days: 1)),
                                      lastDate: DateTime.now().add(const Duration(days: 365)),
                                      initialDateRange: selectedDateRange,
                                      builder: (context, child) => Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: const ColorScheme.dark(primary: Color(0xFF00E676), onPrimary: Colors.black, onSurface: Colors.white),
                                        ),
                                        child: child!,
                                      ),
                                   );
                                   if (picked != null) setDialogState(() => selectedDateRange = picked);
                                },
                                child: Container(
                                   padding: const EdgeInsets.all(12),
                                   decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                                   child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                         Text(
                                            selectedDateRange != null 
                                            ? '${DateFormat.yMd(Localizations.localeOf(context).toString()).format(selectedDateRange!.start)} - ${DateFormat.yMd(Localizations.localeOf(context).toString()).format(selectedDateRange!.end)}'
                                            : AppLocalizations.of(context)!.selectDates,
                                            style: const TextStyle(color: Colors.white),
                                         ),
                                         const Icon(Icons.calendar_today, color: Color(0xFF00E676), size: 16),
                                      ],
                                   ),
                                ),
                             ),
                             const SizedBox(height: 16),
                             Text(AppLocalizations.of(context)!.dietType, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                             CheckboxListTile(
                                title: Text(AppLocalizations.of(context)!.dietNatural, style: const TextStyle(color: Colors.white, fontSize: 14)),
                                value: isNatural,
                                activeColor: const Color(0xFF00E676),
                                checkColor: Colors.black,
                                contentPadding: EdgeInsets.zero,
                                onChanged: (v) => setDialogState(() => isNatural = v ?? false),
                             ),
                             CheckboxListTile(
                                title: Text(AppLocalizations.of(context)!.dietKibble, style: const TextStyle(color: Colors.white, fontSize: 14)),
                                value: isKibble,
                                activeColor: const Color(0xFF00E676),
                                checkColor: Colors.black,
                                contentPadding: EdgeInsets.zero,
                                onChanged: (v) => setDialogState(() => isKibble = v ?? false),
                             ),
                             if (isNatural && isKibble)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text('✅ ${AppLocalizations.of(context)!.dietHybrid}', style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontStyle: FontStyle.italic)),
                                ),
                             const SizedBox(height: 16),
                             Text(AppLocalizations.of(context)!.nutritionalGoal, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                             const SizedBox(height: 8),
                             Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                                child: DropdownButtonHideUnderline(
                                   child: DropdownButton<String>(
                                      value: goal,
                                      dropdownColor: Colors.grey[850],
                                      isExpanded: true,
                                      style: const TextStyle(color: Colors.white),
                                      items: goals.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                                      onChanged: (v) => setDialogState(() => goal = v!),
                                   ),
                                ),
                             ),
                          ],
                       ),
                    ),
                    actions: [
                       TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
                       ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black),
                          onPressed: () {
                             if (!isNatural && !isKibble) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione ao menos um regime.')));
                                return;
                             }
                             if (selectedDateRange == null) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione as datas.')));
                                return;
                             }
                             Navigator.pop(ctx, true);
                          },
                          child: Text(AppLocalizations.of(context)!.generateMenu),
                       ),
                    ],
                 );
              },
           );
        },
     );

     if (confirmed != true) return;

     showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Center(
           child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(16)),
              child: Column(
                 mainAxisSize: MainAxisSize.min,
                 children: const [
                    CircularProgressIndicator(color: Color(0xFF00E676)),
                    SizedBox(height: 16),
                    Text('Nutricionista IA criando plano...', style: TextStyle(color: Colors.white)),
                 ],
              ),
           ),
        ),
     );

     try {
        final service = GeminiService();
        final existingPlan = _currentRawAnalysis?['plano_semanal'] as List?;
        
        // Smart Merge Logic: Preserve history before 'Today' or selected start date
        // Logic: Preserve ALL items where date is strictly BEFORE generation start.
        List<Map<String, dynamic>> history = [];
        if (existingPlan != null && existingPlan.isNotEmpty) {
           history = existingPlan.map((e) => Map<String, dynamic>.from(e)).toList();
        }
        
        String historyContext = "⚠️ PERFIL ESPECÍFICO DO PET:\n";
        if (_alergiasConhecidas.isNotEmpty) historyContext += "- ALERGIAS (PROIBIDO): ${_alergiasConhecidas.join(', ')}\n";
        if (_preferencias.isNotEmpty) historyContext += "- PREFERÊNCIAS: ${_preferencias.join(', ')}\n";
        if (history.isNotEmpty) historyContext += "\n- ÚLTIMAS REFEIÇÕES (PARA VARIAÇÃO): ${history.take(5).toList()}\n";

        final formatter = DateFormat('dd/MM/yyyy');
        final startStr = formatter.format(selectedDateRange!.start);
        final endStr = formatter.format(selectedDateRange!.end);
        final duration = selectedDateRange!.end.difference(selectedDateRange!.start).inDays + 1;
        
        String dietType = 'Indefinido';
        if (isNatural && isKibble) dietType = 'Hybrid (${AppLocalizations.of(context)!.dietKibble} + ${AppLocalizations.of(context)!.dietNatural})';
        else if (isNatural) dietType = '100% ${AppLocalizations.of(context)!.dietNatural}';
        else dietType = '100% ${AppLocalizations.of(context)!.dietKibble}';

        final prompt = '''
           ATUE COMO NUTRÓLOGO VETERINÁRIO ESPECIALISTA EXCLUSIVO (MÉTODO SCANNUT).
           Gere um cardápio personalizado para: ${_nameController.text} (${_racaController.text}, ${_idadeController.text}, ${_pesoController.text}kg).
           Meta Nutricional: $goal.
           Regime Estabelecido: $dietType.
           Período de Planejamento: $startStr até $endStr ($duration dias).
           
           $historyContext
           
           ⚠️ REGRAS INEGOCIÁVEIS (PROTOCOLOS SCANNUT):
           1. Mantenha consistência biológica. Não sugira alimentos tóxicos (uva, cebola, chocolate, etc).
           2. O plano deve ser diário e cobrir EXATAMENTE o período de $duration dias.
           3. O campo 'refeicoes' deve ser preenchido para CADA dia.
           4. Detalhamento Obrigatório nos 5 PILARES DE SAÚDE PET em TODAS as refeições:
              - PROTEÍNA (Ex: Frango, Carne Bovina, Ovo, Peixe)
              - GORDURA SAUDÁVEL (Ex: Azeite, Óleo de Peixe)
              - FIBRAS (Ex: Abóbora, Chuchu, Cenoura)
              - MINERAIS (Ex: Suplementação específica, casca de ovo processada)
              - HIDRATAÇÃO (Ex: Água, caldos caseiros sem tempero)
           
           ESTRUTURA JSON OBRIGATÓRIA:
           {
             "plano_semanal": [
               {
                 "dia": "Dia da Semana - DD/MM", 
                 "refeicoes": [
                    {
                      "hora": "HH:MM", 
                      "titulo": "Nome Curto da Refeição", 
                      "descricao": "Texto detalhado incluindo os 5 Pilares citados acima.", 
                      "tipo_dieta": "$dietType"
                    }
                 ]
               }
             ],
             "orientacoes_gerais": "Resumo estratégico focado na meta de $goal."
           }
           
           NÃO ADICIONE TEXTO FORA DO JSON.
        ''';

        final rawResponse = await service.generateTextContent(prompt);
        Navigator.pop(context); // Hide loader

        if (rawResponse['plano_semanal'] == null) throw Exception("Erro na resposta da IA.");

        var generatedList = (rawResponse['plano_semanal'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
        
        final shortFormatter = DateFormat('dd/MM');
        
        // CLIENT-SIDE DATE ENFORCEMENT
        final List<Map<String, dynamic>> finalItems = [];
        // Recalculate duration here or ensure it's available. It was defined above in try block.
        // It is `duration` variable.
        
        for (int i = 0; i < duration; i++) {
             if (i >= generatedList.length) break; 
             
             final item = Map<String, dynamic>.from(generatedList[i]);
             final dateForDay = selectedDateRange!.start.add(Duration(days: i));
             final dateStr = DateFormat.yMd(Localizations.localeOf(context).toString()).format(dateForDay);
             
             // Get Locale-aware Weekday
             final weekDayName = DateFormat('EEEE', Localizations.localeOf(context).toString()).format(dateForDay); 
             final weekDayCap = weekDayName[0].toUpperCase() + weekDayName.substring(1);
             
             item['dia'] = "$weekDayCap - $dateStr";
             finalItems.add(item);
        }

        // Fetch current profile to get old plan (History)
        final profileService = PetProfileService();
        await profileService.init();
        final currentProfile = await profileService.getProfile(_nameController.text.trim());
        
        List<Map<String, dynamic>> combinedPlan = [];
        if (currentProfile != null && currentProfile['data'] != null && currentProfile['data']['plano_semanal'] != null) {
             final oldPlan = List<Map<String, dynamic>>.from(
                 (currentProfile['data']['plano_semanal'] as List).map((x) => Map<String, dynamic>.from(x))
             );
             combinedPlan = [...oldPlan, ...finalItems];
        } else {
             combinedPlan = finalItems;
        }

        // Direct Save (Authoritative)
        await profileService.saveWeeklyMenu(
             petName: _nameController.text.trim(),
             menuPlan: combinedPlan,
             guidelines: rawResponse['orientacoes_gerais'],
             startDate: DateFormat('yyyy-MM-dd').format(selectedDateRange!.start),
             endDate: DateFormat('yyyy-MM-dd').format(selectedDateRange!.end),
        );

        setState(() {
            if (_currentRawAnalysis == null) _currentRawAnalysis = {};
            _currentRawAnalysis!['plano_semanal'] = combinedPlan;
            _currentRawAnalysis!['data_inicio_semana'] = DateFormat('yyyy-MM-dd').format(selectedDateRange!.start);
            _currentRawAnalysis!['data_fim_semana'] = DateFormat('yyyy-MM-dd').format(selectedDateRange!.end);
            _currentRawAnalysis!['orientacoes_gerais'] = rawResponse['orientacoes_gerais'];
        });

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ Cardápio Inteligente Planejado!'),
            backgroundColor: Color(0xFF00E676),
        ));

     } catch (e) {
        if (mounted && Navigator.canPop(context)) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
     }
  }

  Widget _buildRaceDetailsSection() {
     final raw = _currentRawAnalysis;
     if (raw == null) return const SizedBox.shrink();

     final ident = raw['identificacao'] as Map?;
     final temp = raw['temperamento'] as Map?;
     final fisica = raw['caracteristicas_fisicas'] as Map?;
     final origem = raw['origem_historia'] as String?;
     final curiosidades = raw['curiosidades'] as List?;
     
     if (ident == null && temp == null && fisica == null && origem == null) return const SizedBox.shrink();

     return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           const SizedBox(height: 24),
           InkWell(
             onTap: _openFullAnalysis,
             borderRadius: BorderRadius.circular(8),
             child: Padding(
               padding: const EdgeInsets.symmetric(vertical: 8),
               child: Row(
                 children: [
                   _buildSectionTitle('🧬 Análise da Raça'),
                   const Spacer(),
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                     decoration: BoxDecoration(
                         color: const Color(0xFF00E676).withOpacity(0.1),
                         borderRadius: BorderRadius.circular(20),
                         border: Border.all(color: const Color(0xFF00E676).withOpacity(0.3))
                     ),
                     child: Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         const Text('Ver Completo', style: TextStyle(color: Color(0xFF00E676), fontSize: 12, fontWeight: FontWeight.bold)),
                         const SizedBox(width: 4),
                         const Icon(Icons.arrow_forward, color: Color(0xFF00E676), size: 14),
                       ],
                     ),
                   )
                 ],
               ),
             ),
           ),
           const SizedBox(height: 8),
           
           
            if (ident != null) ...[
               _buildInfoRow('Linhagem', ident['linhagem_mista']?.toString() ?? 'Não identificada'),
               _buildInfoRow('Raça Predominante', ident['raca_predominante']?.toString() ?? 'Não identificada'),
               _buildInfoRow('Confiabilidade', ident['confiabilidade']?.toString() ?? 'Baixa'),
            ],
            
            if (fisica != null) ...[
               _buildInfoRow('Expectativa de Vida', fisica['expectativa_vida']?.toString() ?? 'Não estimada'),
               _buildInfoRow('Porte', fisica['porte']?.toString() ?? 'Não identificado'),
               _buildInfoRow('Peso Típico', fisica['peso_estimado']?.toString() ?? 'Variável'),
            ],

           if (temp != null) ...[
               const SizedBox(height: 12),
               const Text('Temperamento', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
               const SizedBox(height: 4),
               if (temp['personalidade'] != null)
                  Text(temp['personalidade'].toString(), style: const TextStyle(color: Colors.white70)),
               if (temp['comportamento_social'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(temp['comportamento_social'].toString(), style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12, fontStyle: FontStyle.italic)),
                  ),
           ],
           
           if (origem != null) ...[
               const SizedBox(height: 12),
               ExpansionTile(
                  title: Text('Origem & História', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
                  collapsedIconColor: Colors.white54,
                  iconColor: const Color(0xFF00E676),
                  children: [Padding(padding: const EdgeInsets.all(8), child: Text(origem, style: const TextStyle(color: Colors.white70)))],
               )
           ],

           if (curiosidades != null && curiosidades.isNotEmpty) ...[
               const SizedBox(height: 12),
               ExpansionTile(
                  title: Text('Curiosidades', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
                  collapsedIconColor: Colors.white54,
                  iconColor: Colors.amber,
                  children: curiosidades.map((c) => ListTile(
                      leading: const Icon(Icons.star, color: Colors.amber, size: 16),
                      title: Text(c.toString(), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  )).toList(),
               )
           ]
        ]
     );
  }

   void _openFullAnalysis() {
      if (_currentRawAnalysis == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Detalhes completos indisponíveis. Realize uma nova análise.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RaceAnalysisDetailScreen(
            raceAnalysis: _currentRawAnalysis!,
            petName: _nameController.text.trim().isEmpty 
              ? 'Pet' 
              : _nameController.text.trim(),
          ),
        ),
      );
   }

  Widget _buildInfoRow(String label, String value) {
      if (value.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                SizedBox(width: 130, child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13))),
                Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 14))),
            ]
        ),
      );
  }

  Widget _buildWeeklyPlanSection() {
    final raw = _currentRawAnalysis;
    if (raw == null || raw['plano_semanal'] == null) {
      return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
              child: ElevatedButton.icon(
                  icon: const Icon(Icons.restaurant_menu),
                  label: const Text('Gerar Cardápio Semanal'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black),
                  onPressed: _generateNewMenu,
              )
          )
      );
    }

    final List<dynamic> plano = raw['plano_semanal'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                _buildSectionTitle('📅 Plano Alimentar Semanal'),
                IconButton(
                    icon: const Icon(Icons.restaurant_menu, color: Color(0xFF00E676)),
                    tooltip: 'Gerar Novo Cardápio',
                    onPressed: _generateNewMenu,
                ),
            ],
        ),
        const SizedBox(height: 8),
        Text(
          'Cada refeição foca nos 5 Pilares (Protéina, Gordura, Fibras, Minerais e Hidratação)',
          style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11),
        ),
        const SizedBox(height: 16),
        ...plano.asMap().entries.map((entry) {
          final index = entry.key;
          final d = entry.value as Map;
          
          String diaTitulo = d['dia']?.toString() ?? 'Dia';
          
          // FORÇAR FORMATO DINÂMICO SE TIVERMOS DATA DE INÍCIO
          DateTime? startData = raw['data_inicio_semana'] != null ? DateTime.tryParse(raw['data_inicio_semana']) : null;
          
          if (startData == null) {
              // FALLBACK: Se não tem data salva, assumimos a segunda-feira da semana em que foi atualizado (ou hoje)
              final baseDate = widget.existingProfile?.lastUpdated ?? DateTime.now();
              startData = DateTime(baseDate.year, baseDate.month, baseDate.day).subtract(Duration(days: baseDate.weekday - 1));
          }

          final dateForDay = startData.add(Duration(days: index));
          final dateStr = DateFormat.yMd(Localizations.localeOf(context).toString()).format(dateForDay);
          final weekDayName = DateFormat('EEEE', Localizations.localeOf(context).toString()).format(dateForDay);
          final weekDayCap = weekDayName[0].toUpperCase() + weekDayName.substring(1);
          diaTitulo = "$weekDayCap - $dateStr";
          
          // Suporte a novo formato (refeicoes[]) ou legado (chaves soltas)
          List<Map<String, dynamic>> refeicoes = [];
          
          if (d.containsKey('refeicoes') && d['refeicoes'] is List) {
              refeicoes = (d['refeicoes'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
          } else {
              // Migração/Legado: Tenta converter as chaves 'manha', 'tarde', 'noite' ou 'refeicao' para a lista
              final keysRaw = ['manha', 'manhã', 'tarde', 'noite', 'jantar', 'refeicao'];
              for (var k in keysRaw) {
                 if (d[k] != null) {
                    refeicoes.add({
                        'hora': k.toUpperCase(),
                        'titulo': 'Principais Nutrientes',
                        'descricao': d[k].toString(),
                        'tipo_dieta': 'Histórico'
                    });
                 }
              }
          }

          return Card(
            color: Colors.white.withValues(alpha: 0.05),
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: Text(diaTitulo, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                leading: const Icon(Icons.calendar_month, color: Color(0xFF00E676), size: 22),
                iconColor: const Color(0xFF00E676),
                collapsedIconColor: Colors.white54,
                children: [
                  ...refeicoes.map((r) => _buildMealDetailItem(r)).toList(),
                  if (refeicoes.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Nenhuma refeição detalhada para este dia.', style: TextStyle(color: Colors.white30, fontSize: 12)),
                    ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildMealDetailItem(Map<String, dynamic> meal) {
      final hora = meal['hora'] ?? '??:??';
      final titulo = meal['titulo'] ?? 'Refeição';
      final desc = meal['descricao'] ?? '';
      final tipo = meal['tipo_dieta'] ?? '';

      return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Row(
                      children: [
                          Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFF00E676).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                              child: Text(hora, style: GoogleFonts.poppins(color: const Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(titulo, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14))),
                          if (tipo.isNotEmpty && tipo != 'Histórico')
                             Container(
                                 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                 decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                 child: Text(tipo, style: const TextStyle(color: Colors.blueAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                             ),
                      ],
                  ),
                  const SizedBox(height: 6),
                  Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                          desc, 
                          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12, height: 1.4)
                      ),
                  ),
                  const Divider(color: Colors.white10),
              ],
          ),
      );
  }

  Future<bool> _onWillPop() async {
    // FORCE SYNC ON CLOSE - SAVE ON EXIT
    if (_hasChanges && _nameController.text.trim().isNotEmpty) {
       await _saveNow(silent: true);
    }
    return true; 
  }




  Widget _buildWeightFeedback() {
      return AnimatedBuilder(
          animation: _pesoController,
          builder: (context, _) {
              final weightStatus = _calculateIntelligentWeightStatus();
              if (weightStatus == null) return const SizedBox.shrink();
              
              return Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: weightStatus.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: weightStatus.color.withOpacity(0.3), width: 2)
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Row(
                              children: [
                                  Icon(weightStatus.icon, color: weightStatus.color, size: 22),
                                  const SizedBox(width: 10),
                                  Expanded(
                                      child: Text(
                                          weightStatus.message, 
                                          style: GoogleFonts.poppins(
                                              color: weightStatus.color, 
                                              fontSize: 14, 
                                              fontWeight: FontWeight.bold
                                          )
                                      )
                                  ),
                                  Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                          color: weightStatus.color.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                          '${weightStatus.percentage}%',
                                          style: TextStyle(
                                              color: weightStatus.color,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                          ),
                                      ),
                                  ),
                              ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                              weightStatus.recommendation,
                              style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 11,
                              ),
                          ),
                      ],
                  ),
              );
          }
      );
  }

  /// Cálculo inteligente de status de peso usando database
  WeightStatus? _calculateIntelligentWeightStatus() {
      final currentWeight = double.tryParse(_pesoController.text.trim().replaceAll(',', '.'));
      if (currentWeight == null || currentWeight == 0) return null;
      
      // Busca peso ideal baseado na raça ou porte
      final raca = _racaController.text.trim();
      final porte = PetWeightDatabase.getPorteFromRaca(raca);
      
      final idealWeight = PetWeightDatabase.getIdealWeight(
          raca: raca.isNotEmpty ? raca : null,
          porte: porte,
      );
      
      if (idealWeight == null) return null;
      
      // Calcula status usando database
      return PetWeightDatabase.calculateWeightStatus(
          currentWeight: currentWeight,
          idealWeight: idealWeight,
      );
  }




  List<Map<String, dynamic>> _getUpdatedWeightHistory() {
      final currentWeight = double.tryParse(_pesoController.text.trim());
      if (currentWeight == null) return _weightHistory;

      // Check if last entry is different or if empty
      if (_weightHistory.isNotEmpty) {
          final last = _weightHistory.last;
          final lastWeight = last['weight'];
          // Simple check: ignore if same weight (avoid spam)
          if (lastWeight == currentWeight) return _weightHistory;
      }

      final weightStatus = _calculateIntelligentWeightStatus();
      
      final newEntry = {
          'date': DateTime.now().toIso8601String(),
          'weight': currentWeight,
          'status_label': weightStatus?.message ?? 'Normal',
          'status_code': weightStatus?.status.name ?? 'normal',
          'percentage': weightStatus?.percentage ?? 100,
      };
      
      // Create new list to avoid mutation issues
      final newList = List<Map<String, dynamic>>.from(_weightHistory);
      newList.add(newEntry);
      return newList;
  }

  // --- LAB EXAMS MANAGEMENT ---
  
  Future<void> _addLabExam(LabExam examTemplate) async {
    try {
      final category = examTemplate.category;
      
      // Pick file (image or PDF)
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      
      if (pickedFile == null) return;
      
      // Copy file to app directory for persistence
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(pickedFile.path)}';
      final savedPath = path.join(appDir.path, 'lab_exams', fileName);
      
      // Create directory if needed
      final dir = Directory(path.dirname(savedPath));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      
      // Copy file
      await File(pickedFile.path).copy(savedPath);
      
      // Create exam object
      final newExam = LabExam(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        category: category,
        filePath: savedPath,
        uploadDate: DateTime.now(),
        isProcessing: true,
      );
      
      setState(() {
        _labExams.add(newExam);
      });
      _onUserInteractionGeneric();
      
      // Process OCR in background
      _processExamOCR(newExam.id);
      
    } catch (e) {
      debugPrint('Error adding lab exam: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao adicionar exame: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _processExamOCR(String examId) async {
    try {
      final examIndex = _labExams.indexWhere((e) => e.id == examId);
      if (examIndex == -1) return;
      
      final exam = _labExams[examIndex];
      
      // Process with OCR service
      final processedExam = await _labExamService.processExam(exam);
      
      if (mounted) {
        setState(() {
          _labExams[examIndex] = processedExam;
        });
        _onUserInteractionGeneric();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Texto extraído com sucesso! Clique em "Explicar Exame" para análise.'),
            backgroundColor: Color(0xFF00E676),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error processing OCR: $e');
      if (mounted) {
        final examIndex = _labExams.indexWhere((e) => e.id == examId);
        if (examIndex != -1) {
          setState(() {
            _labExams[examIndex] = _labExams[examIndex].copyWith(isProcessing: false);
          });
        }
      }
    }
  }
  
  Future<void> _explainLabExam(String examId) async {
    final examIndex = _labExams.indexWhere((e) => e.id == examId);
    if (examIndex == -1) return;
    
    final exam = _labExams[examIndex];
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF00E676)),
      ),
    );
    
    try {
      final explanation = await _labExamService.generateExplanation(exam);
      
      if (mounted) {
        Navigator.pop(context); // Close loading
        
        setState(() {
          _labExams[examIndex] = exam.copyWith(aiExplanation: explanation);
        });
        _onUserInteractionGeneric();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar explicação: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _deleteLabExam(String examId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Excluir Exame', style: GoogleFonts.poppins(color: Colors.white)),
        content: const Text(
          'Tem certeza que deseja excluir este exame? Esta ação não pode ser desfeita.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                final exam = _labExams.firstWhere((e) => e.id == examId);
                // Delete physical file
                try {
                  File(exam.filePath).deleteSync();
                } catch (e) {
                  debugPrint('Error deleting file: $e');
                }
                _labExams.removeWhere((e) => e.id == examId);
              });
              _onUserInteractionGeneric();
              Navigator.pop(context);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _openPartnerAgenda(PartnerModel partner) async {
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => PartnerAgendaScreen(
                partner: partner,
                initialEvents: _partnerNotes[partner.id] ?? [],
                onSave: (events) async {
                    setState(() {
                        _partnerNotes[partner.id] = events;
                    });
                    await PetProfileService().updatePartnerNotes(_nameController.text.trim(), _partnerNotes);
                },
                petId: widget.existingProfile?.petName ?? _nameController.text.trim(),
            ),
        ),
    );
    await _reloadFreshData();
  }

  // --- UNDO / RESTORE LOGIC ---

  Future<bool> _handleWillPop() async {
      if (_hasChanges) {
         await _saveNow(silent: true);
         // Pass backup back to caller for SnackBar Undo
         if (mounted) {
             Navigator.pop(context, {'action': 'save', 'backup': _petBackup, 'petName': _nameController.text.trim()});
         }
         return false; // Handled manually
      }
      return true;
  }

  PetProfileExtended _deepCopyProfile(PetProfileExtended original) {
      return PetProfileExtended(
          petName: original.petName,
          raca: original.raca,
          idadeExata: original.idadeExata,
          pesoAtual: original.pesoAtual,
          pesoIdeal: original.pesoIdeal,
          nivelAtividade: original.nivelAtividade,
          statusReprodutivo: original.statusReprodutivo,
          alergiasConhecidas: List<String>.from(original.alergiasConhecidas),
          preferencias: List<String>.from(original.preferencias),
          dataUltimaV10: original.dataUltimaV10,
          dataUltimaAntirrabica: original.dataUltimaAntirrabica,
          frequenciaBanho: original.frequenciaBanho,
          linkedPartnerIds: List<String>.from(original.linkedPartnerIds),
          partnerNotes: Map<String, List<Map<String, dynamic>>>.from(
             original.partnerNotes.map((k, v) => MapEntry(k, List<Map<String, dynamic>>.from(v)))
          ),
          weightHistory: List<Map<String, dynamic>>.from(
             original.weightHistory.map((e) => Map<String, dynamic>.from(e))
          ),
          lastUpdated: original.lastUpdated,
          imagePath: original.imagePath,
          rawAnalysis: original.rawAnalysis != null ? Map<String, dynamic>.from(original.rawAnalysis!) : null,
      );
  }
  
  void _undoAllChanges() {
      if (_petBackup == null) return;
      
      final b = _petBackup!;
      
      setState(() {
          _nameController.text = b.petName;
          _racaController.text = b.raca ?? '';
          _idadeController.text = b.idadeExata ?? '';
          _pesoController.text = b.pesoAtual?.toString() ?? '';
          _pesoIdealController.text = b.pesoIdeal?.toString() ?? '';
          
          _nivelAtividade = b.nivelAtividade ?? 'Moderado';
          _statusReprodutivo = b.statusReprodutivo ?? 'Castrado';
          _frequenciaBanho = b.frequenciaBanho ?? 'Quinzenal';
          
          _dataUltimaV10 = b.dataUltimaV10;
          _dataUltimaAntirrabica = b.dataUltimaAntirrabica;
          
          _alergiasConhecidas = List.from(b.alergiasConhecidas);
          _preferencias = List.from(b.preferencias);
          _linkedPartnerIds = List.from(b.linkedPartnerIds);
          _partnerNotes = Map.from(b.partnerNotes).map((k, v) => MapEntry(k, List.from(v)));
          _weightHistory = List.from(b.weightHistory);
          _labExams = (b.labExams).map((json) => LabExam.fromJson(json)).toList();
          
          // _hasChanges = false; 
      });
      _onUserInteractionGeneric();
      _loadLinkedPartners(); // Refresh partners UI
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alterações desfeitas.')));
  }

  void _removeLinkedPartner(String id) {
      setState(() {
          _linkedPartnerIds.remove(id);
          _partnerNotes.remove(id);
          _linkedPartnerModels.removeWhere((p) => p.id == id);
      });
      _onUserInteractionGeneric();
  }

  void _openPartnerSelection() async {
     // Navigate to My Support Hub in Selection Mode
     // Note: We are ignoring 'suggestionContext' for now as Hub displays user's registered partners.
     
     final result = await Navigator.push(context, MaterialPageRoute(
       builder: (_) => const PartnersHubScreen(isSelectionMode: true)
     ));
     
     if (result != null && result is PartnerModel) {
         if (!_linkedPartnerIds.contains(result.id)) {
             setState(() {
                 _linkedPartnerIds.add(result.id);
                 _linkedPartnerModels.add(result);
             });
             _onUserInteractionGeneric();
         }
     }
  }

  Future<void> _generatePetReport() async {
    try {
        // Show section filter dialog
        final selectedSections = await showDialog<Map<String, bool>>(
          context: context,
          builder: (context) => const PdfSectionFilterDialog(),
        );
        
        // User cancelled the dialog
        if (selectedSections == null) return;
        
        final exportService = ExportService();
        
        // Construct current profile from screen data
        final profile = PetProfileExtended(
            petName: _nameController.text.trim(),
            raca: _racaController.text.trim(),
            idadeExata: _idadeController.text.trim(),
            pesoAtual: double.tryParse(_pesoController.text.trim()),
            pesoIdeal: double.tryParse(_pesoIdealController.text.trim()),
            nivelAtividade: _nivelAtividade,
            statusReprodutivo: _statusReprodutivo,
            alergiasConhecidas: _alergiasConhecidas,
            preferencias: _preferencias,
            dataUltimaV10: _dataUltimaV10,
            dataUltimaAntirrabica: _dataUltimaAntirrabica,
            frequenciaBanho: _frequenciaBanho,
            linkedPartnerIds: _linkedPartnerIds,
            partnerNotes: _partnerNotes,
            weightHistory: _weightHistory,
            woundAnalysisHistory: _woundHistory, // HISTÓRICO DE FERIDAS ADICIONADO
            labExams: _labExams.map((e) => e.toJson()).toList(),
            observacoesIdentidade: _observacoesIdentidade,
            observacoesSaude: _observacoesSaude,
            observacoesNutricao: _observacoesNutricao,
            observacoesGaleria: _observacoesGaleria,
            observacoesPrac: _observacoesPrac,
            lastUpdated: DateTime.now(),
            imagePath: _profileImage?.path,
            rawAnalysis: _currentRawAnalysis,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PdfPreviewScreen(
              title: 'Prontuário de ${profile.petName}',
              buildPdf: (format) async {
                final pdf = await ExportService().generatePetProfileReport(
                  profile: profile,
                  strings: AppLocalizations.of(context)!,
                  selectedSections: selectedSections,
                );
                return pdf.save();
              },
            ),
          ),
        );
    } catch (e) {
        debugPrint('Erro ao gerar PDF: $e');
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erro ao gerar PDF: $e'), backgroundColor: Colors.red),
            );
        }
    }
  }
}

class _PartnerAgendaSheet extends StatefulWidget {
  final PartnerModel partner;
  final List<Map<String, dynamic>> initialEvents;
  final Function(List<Map<String, dynamic>>) onSave;

  const _PartnerAgendaSheet({
    required this.partner,
    required this.initialEvents,
    required this.onSave,
  });

  @override
  State<_PartnerAgendaSheet> createState() => _PartnerAgendaSheetState();
}

class _PartnerAgendaSheetState extends State<_PartnerAgendaSheet> {
  late List<Map<String, dynamic>> _events;
  
  // Controllers for new event
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _events = List.from(widget.initialEvents);
    // Sort by date/time (newest first)
    _sortEvents();
  }

  void _sortEvents() {
    _events.sort((a, b) {
        final dA = DateTime.parse(a['date']);
        final dB = DateTime.parse(b['date']);
        return dB.compareTo(dA);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _saveEvent() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    // Construct DateTime from selected Date + Time
    final fullDateTime = DateTime(
      _selectedDate.year, 
      _selectedDate.month, 
      _selectedDate.day,
      _selectedTime.hour, 
      _selectedTime.minute
    );

    setState(() {
      _events.insert(0, {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'content': _descController.text.trim(),
        'date': fullDateTime.toIso8601String(), // This is the Event Date
        'createdAt': DateTime.now().toIso8601String(),
        'type': 'event'
      });
      _sortEvents();
      _isAdding = false;
      _titleController.clear();
      _descController.clear();
    });
    
    widget.onSave(_events);
  }

  void _deleteEvent(Map<String, dynamic> event) {
      setState(() {
          _events.removeWhere((e) => e['id'] == event['id']);
      });
      widget.onSave(_events);
  }

  Map<String, List<Map<String, dynamic>>> _groupEventsByDate() {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final event in _events) {
      final date = DateTime.parse(event['date']);
      final key = DateFormat('yyyy-MM-dd').format(date);
      if (!grouped.containsKey(key)) grouped[key] = [];
      grouped[key]!.add(event);
    }
    return grouped;
  }
  
  // Helpers
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      isDense: true,
      border: const OutlineInputBorder(),
      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF00E676))),
    );
  }

  Widget _buildDateHeader(String dateKey) {
    final date = DateTime.parse(dateKey);
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    final isYesterday = DateUtils.isSameDay(date, DateTime.now().subtract(const Duration(days: 1)));
    
    String label;
    if (isToday) label = 'Hoje';
    else if (isYesterday) label = 'Ontem';
    else label = DateFormat('dd ' 'de' ' MMMM', 'pt_BR').format(date);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Row(
        children: [
          Container(
            width: 8, height: 8, 
            decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle)
          ),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.poppins(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 1, color: Colors.white10)),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> event) {
      final date = DateTime.parse(event['date']);
      return Dismissible(
        key: Key(event['id']),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          color: Colors.redAccent.withOpacity(0.3),
          margin: const EdgeInsets.only(bottom: 8),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        onDismissed: (_) => _deleteEvent(event),
        child: Container(
            margin: const EdgeInsets.only(bottom: 8, left: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))]
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Text(DateFormat('HH:mm').format(date), style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(width: 12),
                            Expanded(child: Text(event['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15))),
                        ],
                    ),
                    if (event['content'] != null && event['content'].isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 48),
                          child: Text(event['content'], style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ),
                    ]
                ],
            ),
        ),
      );
  }

  Widget _buildEmptyState() {
     return Center(
         child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
                 Icon(Icons.event_busy, color: Colors.white.withOpacity(0.2), size: 48),
                 const SizedBox(height: 16),
                 Text(
                   'Nenhum evento registrado.\nAdicione agendamentos, vacinas ou notas.',
                   textAlign: TextAlign.center,
                   style: GoogleFonts.poppins(color: Colors.white30, fontSize: 12),
                 ),
             ],
         )
     );
  }

  Widget _buildAddEventForm() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           const Text('Novo Evento', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
           const SizedBox(height: 12),
           TextField(
             controller: _titleController,
             style: const TextStyle(color: Colors.white),
             decoration: _inputDecoration('Título'),
           ),
           const SizedBox(height: 12),
           Row(
             children: [
               Expanded(
                 child: InkWell(
                   onTap: () async {
                     final d = await showDatePicker(
                       context: context, 
                       initialDate: _selectedDate, 
                       firstDate: DateTime(2000), 
                       lastDate: DateTime(2100)
                     );
                     if (d != null) setState(() => _selectedDate = d);
                   },
                   child: InputDecorator(
                     decoration: _inputDecoration('Data'),
                     child: Text(DateFormat('dd/MM/yyyy').format(_selectedDate), style: const TextStyle(color: Colors.white)),
                   ),
                 ),
               ),
               const SizedBox(width: 12),
               Expanded(
                 child: InkWell(
                   onTap: () async {
                     final t = await showTimePicker(context: context, initialTime: _selectedTime);
                     if (t != null) setState(() => _selectedTime = t);
                   },
                   child: InputDecorator(
                     decoration: _inputDecoration('Hora'),
                     child: Text(_selectedTime.format(context), style: const TextStyle(color: Colors.white)),
                   ),
                 ),
               ),
             ],
           ),
           const SizedBox(height: 12),
           TextField(
             controller: _descController,
             style: const TextStyle(color: Colors.white),
             maxLines: 2,
             decoration: _inputDecoration('Observações'),
           ),
           const SizedBox(height: 16),
           Row(
             mainAxisAlignment: MainAxisAlignment.end,
             children: [
               TextButton(
                 onPressed: () => setState(() => _isAdding = false), 
                 child: const Text('Cancelar', style: TextStyle(color: Colors.white54))
               ),
               const SizedBox(width: 8),
               ElevatedButton(
                 onPressed: _saveEvent,
                 style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black),
                 child: const Text('Adicionar'),
               )
             ],
           )
        ],
      );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).viewPadding.bottom + 20,
        left: 20,
        right: 20,
        top: 20
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.event_note, color: Colors.amberAccent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Agenda: ${widget.partner.name}', 
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!_isAdding)
                IconButton(
                    icon: const Icon(Icons.add_circle, color: Color(0xFF00E676)), 
                    onPressed: () => setState(() => _isAdding = true)
                ),
              IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context))
            ],
          ),
          const SizedBox(height: 20),
          
          if (_isAdding) _buildAddEventForm(),
          if (false) ...[
              Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                     color: Colors.white.withOpacity(0.05),
                     borderRadius: BorderRadius.circular(12),
                     border: Border.all(color: const Color(0xFF00E676).withOpacity(0.3))
                 ),
                 child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        const Text('Novo Evento', style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        TextField(
                            controller: _titleController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                                labelText: 'Título (ex: Consulta, Banho)',
                                labelStyle: TextStyle(color: Colors.white54),
                                isDense: true,
                                border: OutlineInputBorder()
                            ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                            children: [
                                Expanded(
                                    child: InkWell(
                                        onTap: () async {
                                            final d = await showDatePicker(
                                                context: context, 
                                                initialDate: _selectedDate, 
                                                firstDate: DateTime(2020), 
                                                lastDate: DateTime(2030),
                                                builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFF00E676), onSurface: Colors.white)), child: child!)
                                            );
                                            if (d != null) setState(() => _selectedDate = d);
                                        },
                                        child: InputDecorator(
                                            decoration: const InputDecoration(
                                                labelText: 'Data', 
                                                isDense: true, 
                                                border: OutlineInputBorder()
                                            ),
                                            child: Text(DateFormat('dd/MM/yyyy').format(_selectedDate), style: const TextStyle(color: Colors.white)),
                                        ),
                                    ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: InkWell(
                                        onTap: () async {
                                            final t = await showTimePicker(
                                                context: context, 
                                                initialTime: _selectedTime,
                                                builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFF00E676), onSurface: Colors.white)), child: child!)
                                            );
                                            if (t != null) setState(() => _selectedTime = t);
                                        },
                                        child: InputDecorator(
                                            decoration: const InputDecoration(
                                                labelText: 'Hora', 
                                                isDense: true, 
                                                border: OutlineInputBorder()
                                            ),
                                            child: Text(_selectedTime.format(context), style: const TextStyle(color: Colors.white)),
                                        ),
                                    ),
                                ),
                            ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                            controller: _descController,
                            style: const TextStyle(color: Colors.white),
                            maxLines: 2,
                            decoration: const InputDecoration(
                                labelText: 'Observações',
                                labelStyle: TextStyle(color: Colors.white54),
                                isDense: true,
                                border: OutlineInputBorder()
                            ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                                TextButton(onPressed: () => setState(() => _isAdding = false), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                    onPressed: _saveEvent,
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black),
                                    child: const Text('Adicionar'),
                                )
                            ],
                        )
                    ],
                 ),
              ),
              const SizedBox(height: 20),
          ],

          Expanded(
            child: _events.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: _groupEventsByDate().length,
                  itemBuilder: (context, index) {
                      final grouped = _groupEventsByDate();
                      final keys = grouped.keys.toList()..sort((a,b)=>b.compareTo(a));
                      final key = keys[index];
                      final events = grouped[key]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDateHeader(key),
                          ...events.map((e) => _buildTimelineItem(e)).toList(),
                          const SizedBox(height: 16),
                        ],
                      );
                  } 
              ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _LinkedPartnerCard extends StatefulWidget {
  final PartnerModel partner;
  final VoidCallback onUnlink;
  final Function(PartnerModel) onUpdate;
  final VoidCallback onOpenAgenda;

  const _LinkedPartnerCard({
    required this.partner,
    required this.onUnlink,
    required this.onUpdate,
    required this.onOpenAgenda,
  });

  @override
  State<_LinkedPartnerCard> createState() => _LinkedPartnerCardState();
}

class _LinkedPartnerCardState extends State<_LinkedPartnerCard> {
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.partner.phone);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
  
  void _updatePhone(String val) {
      if (val != widget.partner.phone) {
          final updated = PartnerModel(
              id: widget.partner.id,
              name: widget.partner.name,
              category: widget.partner.category,
              latitude: widget.partner.latitude,
              longitude: widget.partner.longitude,
              phone: val, // Updated
              whatsapp: widget.partner.whatsapp,
              address: widget.partner.address,
              openingHours: widget.partner.openingHours,
              photos: widget.partner.photos,
              rating: widget.partner.rating,
              isFavorite: widget.partner.isFavorite,
              metadata: widget.partner.metadata,
              specialties: widget.partner.specialties,
              instagram: widget.partner.instagram,
              cnpj: widget.partner.cnpj,
          );
          widget.onUpdate(updated);
      }
  }

  Future<void> _launch(String scheme, String path) async {
      String processedPath = path;
      if (scheme == 'tel') {
        processedPath = path.replaceAll(RegExp(r'[^\d]'), '');
      }
      
      final uri = Uri(scheme: scheme, path: processedPath);
      try {
        await launchUrl(uri);
      } catch (e) {
        debugPrint('Could not launch $uri: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível abrir o aplicativo'))
          );
        }
      }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withOpacity(0.08),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: const Color(0xFF00E676).withOpacity(0.3))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             // Header: Name + Unlink Switch
             Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                     Expanded(
                         child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                                 Text(widget.partner.name, style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                 Text(widget.partner.category, style: const TextStyle(color: Color(0xFF00E676), fontSize: 12)),
                             ],
                         ),
                     ),
                     Column(
                       children: [
                         Switch(
                             value: true, 
                             activeColor: const Color(0xFF00E676),
                             onChanged: (v) {
                                 if (!v) widget.onUnlink();
                             }
                         ),
                         const Text('Vinculado', style: TextStyle(color: Colors.white54, fontSize: 10))
                       ],
                     )
                 ],
             ),
             const Divider(color: Colors.white10, height: 24),
             
             // Address
             InkWell(
                 onTap: () {
                     // Launch Maps
                     // Geouri
                     _launch('geo', '${widget.partner.latitude},${widget.partner.longitude}?q=${Uri.encodeComponent(widget.partner.address)}');
                 },
                 child: Row(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                         const Icon(Icons.location_on, color: Colors.redAccent, size: 18),
                         const SizedBox(width: 8),
                         Expanded(
                             child: Text(
                                 widget.partner.address.isNotEmpty ? widget.partner.address : 'Endereço não informado',
                                 style: const TextStyle(color: Colors.white70, fontSize: 13),
                             ),
                         ),
                         const Icon(Icons.open_in_new, color: Colors.white30, size: 14)
                     ],
                 ),
             ),
             const SizedBox(height: 16),
             
             // Editable Phone
             Row(
                 children: [
                     const Icon(Icons.phone, color: Colors.white54, size: 18),
                     const SizedBox(width: 8),
                     Expanded(
                         child: TextFormField(
                             controller: _phoneController,
                             style: const TextStyle(color: Colors.white, fontSize: 14),
                             decoration: const InputDecoration(
                                 isDense: true,
                                 border: InputBorder.none,
                                 hintText: 'Telefone',
                                 hintStyle: TextStyle(color: Colors.white30),
                                 enabledBorder: InputBorder.none,
                                 focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00E676))),
                             ),
                             keyboardType: TextInputType.phone,
                             onChanged: _updatePhone,
                         ),
                     ),
                     const Icon(Icons.edit, color: Colors.white24, size: 14)
                 ],
             ),
             
             const SizedBox(height: 20),
             // ACTION BUTTONS
             Row(
                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                 children: [
                     _ActionIcon(
                         icon: Icons.phone, 
                         color: Colors.greenAccent, 
                         label: 'Ligar', 
                         onTap: () => _launch('tel', widget.partner.phone)
                     ),
                     _ActionIcon(
                         icon: Icons.event_note, 
                         color: Colors.amberAccent, 
                         label: 'Agenda', 
                         onTap: widget.onOpenAgenda,
                         isHighlighted: true,
                     ),
                 ],
             )
          ],
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
    final IconData icon;
    final Color color;
    final String label;
    final VoidCallback onTap;
    final bool isHighlighted;
    
    const _ActionIcon({required this.icon, required this.color, required this.label, required this.onTap, this.isHighlighted = false});
    
    @override
    Widget build(BuildContext context) {
        return InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: isHighlighted 
                   ? BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.5)))
                   : null,
                child: Column(
                    children: [
                        Icon(icon, color: color, size: 24),
                        const SizedBox(height: 4),
                        Text(label, style: TextStyle(color: color, fontSize: 10))
                    ],
                ),
            ),
        );
    }
}
