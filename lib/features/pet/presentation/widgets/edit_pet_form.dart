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
import 'package:hive/hive.dart';
import 'package:open_filex/open_filex.dart';
import '../../../../core/services/file_upload_service.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../../core/utils/prompt_factory.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../core/enums/scannut_mode.dart';
import '../../models/pet_profile_extended.dart';
import '../../services/pet_pdf_generator.dart'; // 🛡️ NEW PDF GENERATOR
import '../../models/analise_ferida_model.dart'; // 🛡️ Import for Health History
import '../../services/pet_vision_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/utils/permission_helper.dart';

import '../../../partners/presentation/partners_hub_screen.dart'; // Add this line
import '../../../partners/presentation/partner_registration_screen.dart'; // Add this line
import '../../../../core/services/whatsapp_service.dart';
import '../../../../core/services/partner_service.dart';
import '../../../../core/models/partner_model.dart';
import '../../../../core/widgets/pdf_action_button.dart';
import '../../../../core/services/export_service.dart';
import '../../../../core/widgets/pdf_preview_screen.dart';
import '../../../../core/widgets/app_pdf_icon.dart';
import 'filter_3d_modal.dart';
import '../../../../core/widgets/cumulative_observations_field.dart';
import '../../models/lab_exam.dart';
import 'meal_plan_loading_widget.dart';
import '../../services/lab_exam_service.dart';
import 'lab_exams_section.dart';
import 'race_analysis_detail_screen.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/pet_weight_database.dart';
import '../../services/pet_profile_service.dart';

import '../../services/lab_exam_service.dart';
import 'lab_exams_section.dart';
import 'race_analysis_detail_screen.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/pet_weight_database.dart';
import '../../services/pet_profile_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/pet_menu_generator_service.dart';
import '../../services/meal_plan_service.dart';
import 'pet_menu_filter_dialog.dart';
import 'pet_menu_filter_dialog.dart';
import 'weekly_menu_screen.dart';
import '../../models/meal_plan_request.dart';
import '../../models/weekly_meal_plan.dart';
import 'partner_agenda_sheet.dart';
import 'linked_partner_card.dart';
import '../pet_event_history_screen.dart'; // Added
import 'pet_event_grid.dart'; // Added
import '../../services/pet_indexing_service.dart';

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
  final _visionService = PetVisionService();

  // Controllers
  late TextEditingController _nameController;
  String? _especie; // Seleção: Cão ou Gato
  late TextEditingController _racaController;
  late TextEditingController _idadeController;
  late TextEditingController _pesoController;
  late TextEditingController _pesoIdealController; // New
  late TextEditingController _alergiasController;
  late TextEditingController _preferenciasController;
  late TextEditingController _restricoesController;

  // Dropdown values (initialized with default Portuguese values)
  String _nivelAtividade = 'Moderado';
  String _statusReprodutivo = 'Não informado';
  String? _sexo; // Nullable for validation
  String _frequenciaBanho = 'Quinzenal';
  String? _porte; // Pequeno, Médio, Grande, Gigante
  String? _reliability; // % of AI confidence

  // Dates
  DateTime? _dataUltimaV10;
  DateTime? _dataUltimaAntirrabica;

  // Lists
  List<String> _alergiasConhecidas = [];
  List<String> _preferencias = [];
  List<String> _restricoes = [];
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
  List<Map<String, dynamic>> _analysisHistory = [];
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
  DateTime? _lastMealPlanDate;
  File? _profileImage;
  String? _initialImagePath;

  // Auto-Save State
  bool _hasChanges = false;
  bool _isSaving = false;
  bool _isAnalyzingPet = false;
  PetProfileExtended? _petBackup; // Backup for Undo
  
  // Partner Updates
  final PartnerService _partnerService = PartnerService();
  final Map<String, PartnerModel> _modifiedPartners = {};
  
  // Lab Exams & History
  final LabExamService _labExamService = LabExamService();
  final ImagePicker _imagePicker = ImagePicker();
  List<AnaliseFeridaModel> _historicoAnaliseFeridas = []; // 🛡️ Load structured history
  
  // Navigation & Scroll
  final ScrollController _scrollController = ScrollController();

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
        especie: _especie,
        raca: PetProfileExtended.normalizeBreed(_racaController.text, _especie),
        idadeExata: _idadeController.text.trim().isEmpty ? null : _idadeController.text.trim(),
        pesoAtual: double.tryParse(_pesoController.text.trim().replaceAll(',', '.')),
        pesoIdeal: double.tryParse(_pesoIdealController.text.trim().replaceAll(',', '.')),
        nivelAtividade: _nivelAtividade,
        statusReprodutivo: _statusReprodutivo,
        sex: _sexo,
        alergiasConhecidas: _alergiasConhecidas,
        preferencias: _preferencias,
        restricoes: _restricoes,
        dataUltimaV10: _dataUltimaV10,
        dataUltimaAntirrabica: _dataUltimaAntirrabica,
        frequenciaBanho: _frequenciaBanho,
        linkedPartnerIds: _linkedPartnerIds,
        partnerNotes: _partnerNotes,
        weightHistory: _getUpdatedWeightHistory(),
        labExams: _labExams.map((e) => e.toJson()).toList(),
        woundAnalysisHistory: _woundHistory,
        historicoAnaliseFeridas: _historicoAnaliseFeridas, // 🛡️ Persist
        analysisHistory: _analysisHistory,
        observacoesIdentidade: _observacoesIdentidade,
        observacoesSaude: _observacoesSaude,
        observacoesNutricao: _observacoesNutricao,
        observacoesGaleria: _observacoesGaleria,
        observacoesPrac: _observacoesPrac,
        lastUpdated: DateTime.now(),
        imagePath: finalImagePath,
        rawAnalysis: _currentRawAnalysis,
        reliability: _reliability,
        porte: _porte,
        );

       await widget.onSave(profile);

       // 🛡️ CRITICAL FIX: Update baseline state to prevent storage bloat
       // Sync local state with the persisted reality immediately
       if (mounted && finalImagePath != null) {
           setState(() {
               _initialImagePath = finalImagePath; 
               // Also update the _profileImage to point to the canonical persisted file
               // This prevents (source != initial) logic from triggering another copy
               if (_profileImage != null && _profileImage!.path != finalImagePath) {
                   _profileImage = File(finalImagePath!);
               }
           });
       }

       // Save modified partners
       if (_modifiedPartners.isNotEmpty) {
           for (final p in _modifiedPartners.values) {
               await _partnerService.savePartner(p);
           }
       }
       
       // Update Backup for Undo (Atomic Save -> New Baseline)
       _petBackup = _deepCopyProfile(profile);
       _hasChanges = false; // Changes are now persisted
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
                SnackBar(content: Text(AppLocalizations.of(context)!.commonSyncError(e.toString())), backgroundColor: AppDesign.error)
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

  // Speech to Text
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechAvailable = false;
  TextEditingController? _activeVoiceController;
  String _lastWords = '';

  @override
  void initState() {
    final sw = Stopwatch()..start();
    super.initState();
    debugPrint('⏱️ [PERF_FORM] initState Start');
    _speech = stt.SpeechToText();
    _initSpeech(); // Initialize speech engine

    // CRITICAL: Monitor app lifecycle to save on minimize/close
    WidgetsBinding.instance.addObserver(this);
    
    _partnerService.init();
    _loadAttachments();
    
    final existing = widget.existingProfile;
    
    // Load existing profile image
    // Load existing profile image with Fallback Recovery
    _initialImagePath = existing?.imagePath;
    if (_initialImagePath != null) {
      final file = File(_initialImagePath!);
      if (file.existsSync()) {
        _profileImage = file;
      } else {
        // 🚑 Attempt Recovery async (for path changes)
        getApplicationDocumentsDirectory().then((dir) {
            final filename = path.basename(_initialImagePath!);
            final petName = _nameController.text.trim();
            
            // 🔍 SEARCH 1: Root of Documents
            var rPath = path.join(dir.path, filename);
            var rFile = File(rPath);
            
            // 🔍 SEARCH 2: medical_docs/$petName/
            if (!rFile.existsSync() && petName.isNotEmpty) {
                rPath = path.join(dir.path, 'medical_docs', petName, filename);
                rFile = File(rPath);
            }

            if (rFile.existsSync()) {
                debugPrint('🚑 EditForm recovered image: $rPath');
                if (mounted) {
                    setState(() {
                        _profileImage = rFile;
                        _initialImagePath = rPath; // Update baseline to avoid duplicate save
                    });
                }
            }
        }).catchError((e) => debugPrint('Image recovery failed: $e'));
      }
    }

    _tabController = TabController(length: 6, vsync: this, initialIndex: widget.initialTabIndex);
    
    if (existing != null) {
        _petBackup = _deepCopyProfile(existing);
    }

    _nameController = TextEditingController(text: existing?.petName ?? '');
    _especie = existing?.especie;
    _porte = existing?.porte;
    _racaController = TextEditingController(text: existing?.raca ?? '');
    _idadeController = TextEditingController(text: existing?.idadeExata ?? '');
    _pesoController = TextEditingController(
      text: existing?.pesoAtual?.toString() ?? '',
    );
    _pesoIdealController = TextEditingController(
      text: existing?.pesoIdeal?.toString() ?? '',
    );
    _alergiasController = TextEditingController();
    _preferenciasController = TextEditingController();
    _restricoesController = TextEditingController();

    // 🛡️ NÃO acessar AppLocalizations aqui!
    // Valores padrão fixos em português (serão atualizados em didChangeDependencies)
    if (existing != null) {
      _nivelAtividade = existing.nivelAtividade ?? 'Moderado';
      _statusReprodutivo = existing.statusReprodutivo ?? 'Não informado';
      _sexo = existing.sex;
      _frequenciaBanho = existing.frequenciaBanho ?? 'Quinzenal';
      _reliability = existing.reliability;
      _dataUltimaV10 = existing.dataUltimaV10;
      _dataUltimaAntirrabica = existing.dataUltimaAntirrabica;
      _alergiasConhecidas = List.from(existing.alergiasConhecidas);
      _preferencias = List.from(existing.preferencias);
      _restricoes = List.from(existing.restricoes);
      _linkedPartnerIds = List.from(existing.linkedPartnerIds);
      _partnerNotes = Map.from(existing.partnerNotes).map((k, v) => MapEntry(k, List<Map<String, dynamic>>.from(v)));
      _weightHistory = List.from(existing.weightHistory);
      _labExams = (existing.labExams).map((json) => LabExam.fromJson(json)).toList();
      _woundHistory = (existing.woundAnalysisHistory).map((e) => Map<String, dynamic>.from(e)).toList();
      _historicoAnaliseFeridas = List.from(existing.historicoAnaliseFeridas); // 🛡️ Load
      _analysisHistory = List.from(existing.analysisHistory);
      
      // FIX: Auto-fill Breed from Analysis (Aggressive & Comprehensive)
      final currentBreed = _racaController.text.trim().toUpperCase();
      final isGeneric = currentBreed.isEmpty || 
                        currentBreed == 'N/A' || 
                        currentBreed == 'SRD' || 
                        currentBreed.contains('SEM RAÇA') ||
                        currentBreed.contains('UNKNOWN') ||
                        currentBreed.contains('DESCONHECIDO');

      // Determine source of analysis data (History OR Single Raw Analysis)
      final sourceData = _analysisHistory.isNotEmpty 
          ? _analysisHistory.last 
          : (existing.rawAnalysis != null ? Map<String, dynamic>.from(existing.rawAnalysis!) : null);

      if (isGeneric && sourceData != null) {
          final breed = _findBreedRecursive(sourceData);
          if (breed != null && 
              !breed.toLowerCase().contains('null') && 
              !breed.toLowerCase().contains('n/a')) {
              _racaController.text = breed;
          }
      }
      _observacoesIdentidade = existing.observacoesIdentidade;
      _observacoesSaude = existing.observacoesSaude;
      _observacoesNutricao = existing.observacoesNutricao;
      _observacoesGaleria = existing.observacoesGaleria;
      _observacoesPrac = existing.observacoesPrac;
      _loadLinkedPartners(); // Async load
      _loadMealPlanStatus(); // Async load meal plan status
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
    _restricoesController.addListener(_onUserTyping);
    debugPrint('⏱️ [PERF_FORM] initState End: ${sw.elapsedMilliseconds}ms');
  }

  void _updateProfileFromAI(Map<String, dynamic> result) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      
      if (result.containsKey('identification')) {
          final idData = result['identification'];
          final breed = idData['breed']?.toString();
          final species = idData['species']?.toString();
          
          // Metadata extraction (Reliability)
          if (result.containsKey('metadata')) {
              setState(() => _reliability = result['metadata']['reliability']?.toString());
          }
          
          // Breed
          if (breed != null && breed.toLowerCase() != 'n/a') {
              _racaController.text = breed;
          }

          // Species (Lock Logic)
          if (species != null && species.toLowerCase() != 'n/a') {
              String normalized = species.toLowerCase();
              // Only apply if it looks like a supported pet
              if (normalized.contains('cão') || normalized.contains('cao') || normalized.contains('dog') || normalized.contains('cachorro')) {
                  setState(() => _especie = l10n.species_dog);
              } else if (normalized.contains('gato') || normalized.contains('cat') || normalized.contains('felino')) {
                  setState(() => _especie = l10n.species_cat);
              }
          }
          
          setState(() {
              _currentRawAnalysis = result;
              _markDirty();
          });
      }
  }

  // 🛡️ Flag para garantir que didChangeDependencies rode apenas uma vez
  bool _depsReady = false;
  late AppLocalizations l10n;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // 🛡️ Executar apenas uma vez
    if (_depsReady) return;
    _depsReady = true;

    // ✅ AGORA é seguro acessar AppLocalizations
    l10n = AppLocalizations.of(context)!;
    
    // Atualizar filtro de parceiros com localização
    if (_selectedPartnerFilter == 'Todos' || _selectedPartnerFilter.isEmpty) {
        _selectedPartnerFilter = l10n.partnersFilterAll;
    }
    
    // 🛡️ Atualizar valores padrão com localização (apenas se não existir perfil)
    if (widget.existingProfile == null) {
      if (_nivelAtividade == 'Moderado') {
        _nivelAtividade = l10n.petActivityModerate;
      }
      if (_statusReprodutivo == 'Não informado') {
        _statusReprodutivo = l10n.petNeutered;
      }
      if (_frequenciaBanho == 'Quinzenal') {
        _frequenciaBanho = l10n.petBathBiweekly;
      }
    }
  }

  /// 🛡️ PROTEÇÃO: Retorna lista localizada ou fallback se não estiver pronta
  List<String> _getLocalizedItems(List<String> Function(AppLocalizations) getter) {
    if (!_depsReady) {
      return ['Carregando...'];  // Fallback temporário
    }
    try {
      final items = getter(l10n);
      return items.isEmpty ? ['Não informado'] : items;
    } catch (e) {
      debugPrint('⚠️ Erro ao obter items localizados: $e');
      return ['Não informado'];
    }
  }

  // --- PARTNERS TAB IMPLEMENTATION ---
  
  String _selectedPartnerFilter = '';
  
  List<String> get _partnerFilterCategories {
    final strings = AppLocalizations.of(context)!;
    return [
      strings.partnersFilterAll,
      strings.partnersFilterVet,
      strings.partnersFilterPetShop,
      strings.partnersFilterPharmacy,
      strings.partnersFilterGrooming,
      strings.partnersFilterHotel,
      strings.partnersFilterLab,
    ];
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

  // Meal Plan Status
  Future<void> _loadMealPlanStatus() async {
    final petName = widget.existingProfile?.petName ?? _nameController.text.trim();
    if (petName.isEmpty) return;

    try {
        final plans = await MealPlanService().getPlansForPet(petName);
        if (plans.isNotEmpty && mounted) {
            setState(() {
                _lastMealPlanDate = plans.first.startDate;
            });
        }
    } catch (e) {
        debugPrint('Error loading meal plan status: $e');
    }
  }

  // Attachment Logic
  Future<void> _loadAttachments() async {
    final petName = widget.existingProfile?.petName ?? _nameController.text.trim();
    if (petName.isEmpty) return;

    final allDocs = await _fileService.getMedicalDocuments(petName);
    if (!mounted) return;

    // Define prefixes for specific categories
    bool isIdentity(String n) => n.startsWith('identity_');
    bool isExam(String n) => n.startsWith('health_exams_');
    bool isPrescription(String n) => n.startsWith('health_prescriptions_');
    bool isVaccine(String n) => n.startsWith('health_vaccines_');
    bool isNutrition(String n) => n.startsWith('nutrition_');
    // Gallery is explicitly 'gallery_' OR anything that doesn't fit others
    bool isGallery(String n) => n.startsWith('gallery_') || 
                                (!isIdentity(n) && !isExam(n) && !isPrescription(n) && !isVaccine(n) && !isNutrition(n));

    // Helper to Deduplicate (Aggressive V143)
    List<File> optimizeList(List<File> rawList) {
       final Map<String, File> uniqueMap = {};
       
       debugPrint('🔍 [V143] optimizeList: Processing ${rawList.length} files');
       
       for (var f in rawList) {
          if (!f.existsSync()) continue;
          
          final name = path.basename(f.path);
          
          // 1. Extract potential timestamp ID (10+ digits) to group variations
          // e.g. "image_1234567890.jpg", "opt_1234567890.jpg" -> ID_1234567890
          final match = RegExp(r'(\d{10,})').firstMatch(name);
          String contentId;
          
          if (match != null) {
              contentId = "ID_${match.group(0)}"; 
          } else {
              // Fallback: Group by Exact Size (Collision risk is low for photos)
              // This removes identical duplicates with different names
              contentId = "SIZE_${f.lengthSync()}";
          }

          // Decision: Who stays?
          if (uniqueMap.containsKey(contentId)) {
             final existing = uniqueMap[contentId]!;
             final existingName = path.basename(existing.path);
             
             // Preference Logic:
             // 1. Prefer 'OPT_' (Optimized)
             // 2. Otherwise keep the first one found (usually fine)
             
             final isNewOpt = name.toUpperCase().startsWith('OPT_');
             final isOldOpt = existingName.toUpperCase().startsWith('OPT_');
             
             if (isNewOpt && !isOldOpt) {
                 uniqueMap[contentId] = f; // Upgrade to optimized version
             }
          } else {
             uniqueMap[contentId] = f;
          }
       }
       
       // Convert to list and sort by modification time desc (Newest First)
       final result = uniqueMap.values.toList();
       result.sort((a,b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
       
       debugPrint('✅ [V143] optimizeList: Reduced to ${result.length} unique files');
       return result;
    }

    setState(() {
      _attachments['identity'] = optimizeList(allDocs.where((f) => isIdentity(path.basename(f.path))).toList());
      _attachments['health_exams'] = optimizeList(allDocs.where((f) => isExam(path.basename(f.path))).toList());
      _attachments['health_prescriptions'] = optimizeList(allDocs.where((f) => isPrescription(path.basename(f.path))).toList());
      _attachments['health_vaccines'] = optimizeList(allDocs.where((f) => isVaccine(path.basename(f.path))).toList());
      _attachments['nutrition'] = optimizeList(allDocs.where((f) => isNutrition(path.basename(f.path))).toList());
      
      // Gallery gets the rest (Catch-all)
      _attachments['gallery'] = optimizeList(allDocs.where((f) => isGallery(path.basename(f.path))).toList());
      
      // 🛡️ V123: Debug logging
      debugPrint('📎 [V123] Attachments loaded:');
      debugPrint('  Identity: ${_attachments['identity']?.length ?? 0}');
      debugPrint('  Prescriptions: ${_attachments['health_prescriptions']?.length ?? 0}');
      debugPrint('  Vaccines: ${_attachments['health_vaccines']?.length ?? 0}');
      debugPrint('  Nutrition: ${_attachments['nutrition']?.length ?? 0}');
      debugPrint('  Gallery: ${_attachments['gallery']?.length ?? 0}');
      
      if (allDocs.isNotEmpty) {
        debugPrint('📎 [V123] Sample filenames:');
        for (var doc in allDocs.take(5)) {
          final name = path.basename(doc.path);
          debugPrint('  - $name');
          debugPrint('    Identity: ${isIdentity(name)}, Prescription: ${isPrescription(name)}, Vaccine: ${isVaccine(name)}');
        }
      }
    });
  }

  Future<void> _analyzePetProfile(File file) async {
    if (mounted) setState(() => _isAnalyzingPet = true);
    
    // Show "Detecting..." notice
    if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Row(
             children: [
               const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
               const SizedBox(width: 12),
               Text(AppLocalizations.of(context)!.detecting_pet),
             ],
           ),
           backgroundColor: AppDesign.petPink,
           duration: const Duration(seconds: 2),
         ),
       );
    }

    try {
      // 🛡️ PROACTIVE HIVE CHECK (User requested fix)
      final profileService = PetProfileService();
      await profileService.init(); 

      final locale = Localizations.localeOf(context).languageCode;
      
      String? knownSpecies = (_especie != null && _especie!.isNotEmpty) ? _especie : null;
      String? knownBreed = _racaController.text.trim().isNotEmpty ? _racaController.text.trim() : null;

      // 🛡️ V139: Context-Aware Analysis Mode
      ScannutMode mode = ScannutMode.petIdentification;
      
      // Determine mode based on active tab
      // 0: Identity, 1: Health, 2: Nutrition, 3: Events?, 4: Gallery?, 5: Partners?
      if (_tabController.index == 1) { 
          mode = ScannutMode.petDiagnosis;
          debugPrint('🛡️ [EditPetForm] Health Tab (1) active. Switching to DIAGNOSIS mode.');
      } else if (_tabController.index == 2) {
          // Could enable food analysis here if implemented for Pet Food
          // mode = ScannutMode.petNutrition; // Future
      }

      final result = await _visionService.analisarFotoPet(
          file, 
          locale, 
          knownSpecies: knownSpecies, 
          knownBreed: knownBreed,
          mode: mode
      );
      
      _updateProfileFromAI(result);
      
          
          if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context)!.auto_fill_success, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(AppLocalizations.of(context)!.is_pet_breed_correct(result['identification']?['breed']?.toString() ?? 'SRD')),
                    ],
                  ),
                  backgroundColor: AppDesign.petPink,
                  duration: const Duration(seconds: 4),
                  action: SnackBarAction(label: "OK", textColor: Colors.white, onPressed: () {}),
                ),
              );
          }
    } catch (e) {
      debugPrint('Pet identification error: $e');
    } finally {
      if (mounted) setState(() => _isAnalyzingPet = false);
    }
  }

  Future<void> _handleNewImageSelection(File tempFile) async {
    // 🛡️ CRITICAL FIX: Immediate Persistence
    // Prevent data loss by saving to Documents immediately, even before the form is saved.
    String petName = _nameController.text.trim();
    if (petName.isEmpty) petName = "New_Pet_${DateTime.now().millisecondsSinceEpoch}";
    
    try {
        final permanentPath = await _fileService.saveMedicalDocument(
            file: tempFile,
            petName: petName,
            attachmentType: 'profile_pic_source'
        );
        
        if (permanentPath != null) {
            final permFile = File(permanentPath);
            debugPrint('✅ Immediate Persistence: Image secured at $permanentPath');
            
            if (mounted) {
                setState(() {
                    _profileImage = permFile;
                    // Note: We don't update _initialImagePath here because we want _saveNow 
                    // to detect this as a "change" and update the ID/Hive record.
                });
                _markDirty(); // Trigger Profile Update
                _analyzePetProfile(permFile);
            }
        }
    } catch (e) {
        debugPrint('❌ Critical Error: Failed to secure image: $e');
        // Fallback to temp file (Better than nothing)
         if (mounted) {
            setState(() => _profileImage = tempFile);
            _markDirty();
            _analyzePetProfile(tempFile);
         }
    }
  }

  Future<void> _pickProfileImage() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: AppDesign.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom), 
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppLocalizations.of(context)!.petChangePhoto, style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark, fontSize: 16)),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: AppDesign.info),
                  title: Text(AppLocalizations.of(context)!.petTakePhoto, style: const TextStyle(color: AppDesign.textPrimaryDark)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final file = await _fileService.pickFromCamera();
                    if (file != null) _handleNewImageSelection(file);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.image, color: AppDesign.petPink),
                  title: Text(AppLocalizations.of(context)!.petChooseGallery, style: const TextStyle(color: AppDesign.textPrimaryDark)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final file = await _fileService.pickFromGallery();
                    if (file != null) _handleNewImageSelection(file);
                  },
                ),
                const SizedBox(height: 20), 
              ],
            ),
          ),
        ),
      ),
    );
  }


  Future<void> _addAttachment(String type) async {
    final petName = widget.existingProfile?.petName ?? _nameController.text.trim();
    if (petName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.commonSaveNameFirst)));
      return;
    }

    final isGallery = type == 'gallery';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite expansão correta
      backgroundColor: AppDesign.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isGallery ? AppLocalizations.of(context)!.petAddMedia : AppLocalizations.of(context)!.petAttachDoc, style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark, fontSize: 16)),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: AppDesign.info),
                  title: Text(AppLocalizations.of(context)!.petCameraPhoto, style: const TextStyle(color: AppDesign.textPrimaryDark)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final file = await _fileService.pickFromCamera();
                    if (file != null) _saveFile(file, petName, type);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.image, color: AppDesign.petPink),
                  title: Text(AppLocalizations.of(context)!.petGalleryPhoto, style: const TextStyle(color: AppDesign.textPrimaryDark)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final file = await _fileService.pickFromGallery();
                    if (file != null) _saveFile(file, petName, type);
                  },
                ),
                if (isGallery) ...[
                  ListTile(
                    leading: const Icon(Icons.videocam, color: AppDesign.warning),
                    title: Text(AppLocalizations.of(context)!.petCameraVideo, style: const TextStyle(color: AppDesign.textPrimaryDark)),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final file = await _fileService.pickVideoFromCamera();
                      if (file != null) _saveFile(file, petName, type);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.video_library, color: AppDesign.primary),
                    title: Text(AppLocalizations.of(context)!.petGalleryVideo, style: const TextStyle(color: AppDesign.textPrimaryDark)),
                    onTap: () async {
                      Navigator.pop(ctx);
      final file = await _fileService.pickVideoFromGallery();
                      if (file != null) _saveFile(file, petName, type);
                    },
                  ),
                ] else
                ListTile(
                  leading: const AppPdfIcon(),
                  title: const Text('PDF', style: TextStyle(color: AppDesign.textPrimaryDark)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      debugPrint('🔍 [PDF_ATTACH] Starting PDF picker for type: $type');
                      final file = await _fileService.pickPdfFile();

                      if (file != null) {
                        debugPrint('✅ [PDF_ATTACH] File picked: ${file.path}');
                        await _saveFile(file, petName, type);
                      } else {
                        debugPrint('⚠️ [PDF_ATTACH] File picker returned null (user cancelled or error)');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Nenhum arquivo selecionado'))
                          );
                        }
                      }
                    } catch (e) {
                      debugPrint('❌ [PDF_ATTACH] Error picking PDF: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro ao selecionar PDF: $e'))
                        );
                      }
                    }
                  },
                ),
                SizedBox(height: 20), // Padding extra
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGalleryTabContent() {
    final docs = _attachments['gallery'] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('📸 ${AppLocalizations.of(context)!.petGallery}'),
        const SizedBox(height: 16),
        Text(
          AppLocalizations.of(context)!.petEmptyGalleryDesc,
          style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark.withValues(alpha: 0.6), fontSize: 12),
        ),
        const SizedBox(height: 20),

        if (docs.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: AppDesign.textPrimaryDark.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppDesign.textPrimaryDark.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                Icon(Icons.perm_media_outlined, size: 48, color: AppDesign.textPrimaryDark.withOpacity(0.24)),
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.petEmptyGallery, style: GoogleFonts.poppins(color: AppDesign.textSecondaryDark)),
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
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.commonFilePrefix + path.basename(file.path))));
                },
                onLongPress: () => _deleteAttachment(file),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppDesign.surfaceDark,
                    borderRadius: BorderRadius.circular(8),
                    image: !isVideo ? DecorationImage(image: FileImage(file), fit: BoxFit.cover) : null,
                  ),
                  child: isVideo 
                    ? const Center(child: Icon(Icons.play_circle_fill, color: AppDesign.textPrimaryDark, size: 32))
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
            label: Text(AppLocalizations.of(context)!.petAddToGallery),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              side: const BorderSide(color: AppDesign.accent),
              foregroundColor: AppDesign.accent,
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
    try {
      debugPrint('💾 [PDF_SAVE] Saving file: ${file.path} for pet: $petName, type: $type');

      final savedPath = await _fileService.saveMedicalDocument(
        file: file,
        petName: petName,
        attachmentType: type,
      );

      if (savedPath != null) {
        debugPrint('✅ [PDF_SAVE] File saved successfully: $savedPath');
        _loadAttachments();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.petDocAttached))
          );
        }
      } else {
        debugPrint('⚠️ [PDF_SAVE] saveMedicalDocument returned null');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao salvar arquivo'))
          );
        }
      }
    } catch (e) {
      debugPrint('❌ [PDF_SAVE] Error saving file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e'))
        );
      }
    }
  }

  Future<void> _deleteAttachment(File file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(AppLocalizations.of(context)!.petDeleteAttachment, style: const TextStyle(color: Colors.white)),
        content: Text(AppLocalizations.of(context)!.petDeleteAttachmentContent, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.commonCancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.of(context)!.commonDelete, style: const TextStyle(color: Colors.red))),
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
        color: Colors.white.withOpacity(0.05),
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
                      decoration: BoxDecoration(color: AppDesign.petPink, shape: BoxShape.circle),
                      child: Text('${docs.length}', style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              IconButton( // Small Add Button
                onPressed: () => _addAttachment(type),
                icon: const Icon(Icons.add_circle_outline, color: AppDesign.petPink, size: 20),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                tooltip: AppLocalizations.of(context)!.commonAdd,
              ),
            ],
          ),
          if (docs.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 90, // 🛡️ V121: Increased height to fit filename
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final file = docs[index];
                  final isPdf = file.path.toLowerCase().endsWith('.pdf');
                  final filename = path.basenameWithoutExtension(file.path);
                  
                  // 🛡️ V121: Remove type prefix from display name
                  final displayName = filename.replaceFirst(RegExp(r'^(identity|nutrition|health_\w+|gallery)_'), '');
                  
                  return InkWell(
                  onTap: () async {
                    // 🛡️ V120: Open file with system default app
                    try {
                      debugPrint('📂 [V120] Opening file: ${file.path}');
                      final result = await OpenFilex.open(file.path);

                      if (result.type != ResultType.done) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erro ao abrir arquivo: ${result.message}'),
                              backgroundColor: AppDesign.error,
                            )
                          );
                        }
                      }
                    } catch (e) {
                      debugPrint('❌ [V120] Error opening file: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erro ao abrir arquivo: $e'),
                            backgroundColor: AppDesign.error,
                          )
                        );
                      }
                    }
                  },
                  onLongPress: () => _deleteAttachment(file),
                    child: Stack(
                      children: [
                        Container(
                          width: 85, // 🛡️ V122: Slightly increased for better spacing
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppDesign.surfaceDark,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isPdf ? Colors.red.withOpacity(0.3) : Colors.blueAccent.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min, // 🛡️ V122: Prevent overflow
                            children: [
                              Icon(
                                isPdf ? Icons.picture_as_pdf_rounded : Icons.image,
                                color: isPdf ? Colors.red : Colors.blueAccent,
                                size: 28,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isPdf ? 'PDF' : 'IMG',
                                style: TextStyle(
                                  color: isPdf ? Colors.red.withOpacity(0.7) : Colors.blueAccent.withOpacity(0.7),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // 🛡️ V122: Constrained text to prevent overflow
                              Flexible(
                                child: Text(
                                  displayName,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 9,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 🛡️ V122: Delete icon hint
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.delete_outline,
                              size: 12,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(AppLocalizations.of(context)!.commonNoAttachments, style: GoogleFonts.poppins(color: Colors.white30, fontSize: 11, fontStyle: FontStyle.italic)),
            ),
        ],
      ),
    );
  }

  Widget _buildIdentityTabContentNEW() {
    final l10n = AppLocalizations.of(context)!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. NAME (Top Priority)
        _buildTextField(
          controller: _nameController,
          label: 'Nome do Pet *',
          icon: Icons.person,
          validator: (v) => v?.trim().isEmpty ?? true ? 'Este campo é obrigatório para a análise 360°' : null,
          onChanged: (v) => _onUserTyping(),
          isRequired: true,
        ),
        
        const SizedBox(height: 12),

        // 2. SPECIES
        _buildSectionTitle('📌 ${l10n.species_label}'),
        const SizedBox(height: 12),
        FormField<String>(
          validator: (val) => _especie == null ? 'Espécie obrigatória' : null,
          initialValue: _especie,
          builder: (FormFieldState<String> state) {
             return InputDecorator(
               decoration: InputDecoration(
                 label: RichText(text: TextSpan(text: 'Espécie', style: const TextStyle(color: Colors.white60, fontSize: 16), children: [const TextSpan(text: ' *', style: TextStyle(color: AppDesign.petPink))])),
                 prefixIcon: const Icon(Icons.pets, color: Colors.white30, size: 18),
                 filled: true,
                 fillColor: AppDesign.backgroundDark,
                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                 errorText: state.hasError ? state.errorText : null,
               ),
               child: Row(
                  children: [
                    Expanded(child: InkWell(onTap: () { setState(() => _especie = 'Cão'); state.didChange('Cão'); _onUserInteractionGeneric(); }, child: Container(padding: const EdgeInsets.symmetric(vertical: 4), decoration: BoxDecoration(color: _especie == 'Cão' ? AppDesign.petPink.withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(8)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Radio<String>(value: 'Cão', groupValue: _especie, activeColor: AppDesign.petPink, onChanged: (val) { setState(() => _especie = val); state.didChange(val); _onUserInteractionGeneric(); }), const Icon(Icons.pets, color: Colors.white70, size: 18), const SizedBox(width: 4), Text(l10n.species_dog, style: TextStyle(color: _especie == 'Cão' ? Colors.white : Colors.white60, fontSize: 13))])))),
                    const SizedBox(width: 8),
                    Expanded(child: InkWell(onTap: () { setState(() => _especie = 'Gato'); state.didChange('Gato'); _onUserInteractionGeneric(); }, child: Container(padding: const EdgeInsets.symmetric(vertical: 4), decoration: BoxDecoration(color: _especie == 'Gato' ? AppDesign.petPink.withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(8)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Radio<String>(value: 'Gato', groupValue: _especie, activeColor: AppDesign.petPink, onChanged: (val) { setState(() => _especie = val); state.didChange(val); _onUserInteractionGeneric(); }), const Icon(Icons.auto_awesome, color: Colors.white70, size: 18), const SizedBox(width: 4), Text(l10n.species_cat, style: TextStyle(color: _especie == 'Gato' ? Colors.white : Colors.white60, fontSize: 13))])))),
                  ],
               ),
             );
          },
        ),

        const SizedBox(height: 24),
        
        // 3. BREED
        _buildTextField(
          controller: _racaController,
          label: l10n.petProfile_breed,
          icon: Icons.category,
          validator: (v) => v?.trim().isEmpty ?? true ? 'Este campo é obrigatório para a análise 360°' : null,
          isRequired: true,
        ),
        if (_reliability != null) ...[
           const SizedBox(height: 4),
           Align(alignment: Alignment.centerRight, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppDesign.petPink.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppDesign.petPink.withOpacity(0.3))), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.verified, color: AppDesign.petPink, size: 14), const SizedBox(width: 4), Text('${l10n.reliability_label}: $_reliability', style: const TextStyle(color: AppDesign.petPink, fontSize: 11, fontWeight: FontWeight.bold))]))),
        ],
        _buildRaceDetailsSection(),

        const SizedBox(height: 12),

        // 4. AGE
        _buildTextField(
          controller: _idadeController,
          label: l10n.petAgeLabel,
          icon: Icons.cake,
          validator: (v) => v?.trim().isEmpty ?? true ? 'Este campo é obrigatório para a análise 360°' : null,
          isRequired: true,
        ),
        
        // 5. WEIGHT (Moved Here)
        const SizedBox(height: 12),
        _buildTextField(
            controller: _pesoController,
            label: l10n.petCurrentWeight,
            icon: Icons.monitor_weight,
            keyboardType: TextInputType.number,
            validator: (v) => v?.trim().isEmpty ?? true ? 'Este campo é obrigatório para a análise 360°' : null,
            isRequired: true,
        ),
        _buildWeightFeedback(),

        const SizedBox(height: 12),
        
        // 6. PORTE
         _buildSectionTitle('📏 Porte / Tamanho'),
        const SizedBox(height: 12),
        _buildOptionSelector(
          value: _porte,
          label: 'Porte',
          icon: Icons.straighten,
          options: ['Pequeno', 'Médio', 'Grande', 'Gigante'],
          onChanged: (val) { setState(() => _porte = val); _onUserInteractionGeneric(); },
          isRequired: true,
        ),

        const SizedBox(height: 24),
        
        // 7. SEX
        _buildSectionTitle('⚤ Sexo'),
         const SizedBox(height: 12),
        FormField<String>(
          validator: (val) => _sexo == null ? 'Sexo obrigatório' : null,
          initialValue: _sexo,
          builder: (FormFieldState<String> state) {
             return InputDecorator(
               decoration: InputDecoration(
                 label: RichText(text: TextSpan(text: 'Sexo', style: const TextStyle(color: Colors.white60, fontSize: 16), children: [const TextSpan(text: ' *', style: TextStyle(color: AppDesign.petPink))])),
                 prefixIcon: const Icon(Icons.transgender, color: Colors.white30, size: 18),
                 filled: true,
                 fillColor: AppDesign.backgroundDark,
                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                 errorText: state.hasError ? state.errorText : null,
                 contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
               ),
               child: Row(
                  children: [
                    Expanded(child: InkWell(onTap: () { setState(() => _sexo = 'Male'); state.didChange('Male'); _onUserInteractionGeneric(); }, child: Container(padding: const EdgeInsets.symmetric(vertical: 4), decoration: BoxDecoration(color: _sexo == 'Male' ? AppDesign.petPink.withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(8)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Radio<String>(value: 'Male', groupValue: _sexo, activeColor: AppDesign.petPink, onChanged: (val) { setState(() => _sexo = val); state.didChange(val); _onUserInteractionGeneric(); }), Text(l10n.gender_male, style: TextStyle(color: _sexo == 'Male' ? Colors.white : Colors.white60, fontSize: 13))])))),
                    const SizedBox(width: 8),
                    Expanded(child: InkWell(onTap: () { setState(() => _sexo = 'Female'); state.didChange('Female'); _onUserInteractionGeneric(); }, child: Container(padding: const EdgeInsets.symmetric(vertical: 4), decoration: BoxDecoration(color: _sexo == 'Female' ? AppDesign.petPink.withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(8)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Radio<String>(value: 'Female', groupValue: _sexo, activeColor: AppDesign.petPink, onChanged: (val) { setState(() => _sexo = val); state.didChange(val); _onUserInteractionGeneric(); }), Text(l10n.gender_female, style: TextStyle(color: _sexo == 'Female' ? Colors.white : Colors.white60, fontSize: 13))])))),
                  ],
               ),
             );
          },
        ),

        const SizedBox(height: 24),
        _buildSectionTitle('⚙️ ${l10n.petBiologicalProfile}'),
        const SizedBox(height: 16),
        
        // 8. ACTIVITY
       _buildOptionSelector(
        value: _nivelAtividade,
        label: l10n.petActivityLevel,
        icon: Icons.directions_run,
        options: _getLocalizedItems((l) => [
           l.petActivityLow,
           l.petActivityModerate,
           l.petActivityHigh,
           l.petActivityAthlete
        ]),
        onChanged: (val) { setState(() => _nivelAtividade = val!); _onUserInteractionGeneric(); },
        isRequired: true,
      ),
      
      // 9. REPRO STATUS
       FormField<String>(
          validator: (val) => (_statusReprodutivo == 'Não informado' || _statusReprodutivo == 'Not Informed') ? l10n.petProfile_errorReproductive : null,
          initialValue: _statusReprodutivo,
          builder: (FormFieldState<String> state) {
             return InputDecorator(
               decoration: InputDecoration(
                 label: RichText(text: TextSpan(text: l10n.petProfile_reproductiveStatus, style: const TextStyle(color: Colors.white60, fontSize: 16), children: [const TextSpan(text: ' *', style: TextStyle(color: AppDesign.petPink))])),
                 prefixIcon: const Icon(Icons.medical_services, color: Colors.white30, size: 18),
                 filled: true,
                 fillColor: AppDesign.backgroundDark,
                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                 errorText: state.hasError ? state.errorText : null,
                 contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
               ),
               child: Row(
                 children: [
                    Expanded(child: InkWell(onTap: () { setState(() => _statusReprodutivo = l10n.petNeutered); state.didChange(l10n.petNeutered); _onUserInteractionGeneric(); }, child: Container(padding: const EdgeInsets.symmetric(vertical: 4), decoration: BoxDecoration(color: _localizeValue(_statusReprodutivo) == l10n.petNeutered ? AppDesign.petPink.withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(8)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Radio<String>(value: l10n.petNeutered, groupValue: _localizeValue(_statusReprodutivo), activeColor: AppDesign.petPink, onChanged: (val) { setState(() => _statusReprodutivo = val!); state.didChange(val); _onUserInteractionGeneric(); }), Expanded(child: Text(l10n.petNeutered, style: TextStyle(color: _localizeValue(_statusReprodutivo) == l10n.petNeutered ? Colors.white : Colors.white60, fontSize: 13)))])))),
                    const SizedBox(width: 8),
                    Expanded(child: InkWell(onTap: () { setState(() => _statusReprodutivo = l10n.petIntact); state.didChange(l10n.petIntact); _onUserInteractionGeneric(); }, child: Container(padding: const EdgeInsets.symmetric(vertical: 4), decoration: BoxDecoration(color: _localizeValue(_statusReprodutivo) == l10n.petIntact ? AppDesign.petPink.withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(8)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Radio<String>(value: l10n.petIntact, groupValue: _localizeValue(_statusReprodutivo), activeColor: AppDesign.petPink, onChanged: (val) { setState(() => _statusReprodutivo = val!); state.didChange(val); _onUserInteractionGeneric(); }), Expanded(child: Text(l10n.petIntact, style: TextStyle(color: _localizeValue(_statusReprodutivo) == l10n.petIntact ? Colors.white : Colors.white60, fontSize: 13)))])))),
                 ],
               ),
             );
          },
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
          accentColor: AppDesign.petPink,
        ),

        _buildAttachmentSection('identity', AppLocalizations.of(context)!.pdfIdentitySection),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (bool didPop) async {
        // Atomic Save: Ensure any pending changes or debounced writes are committed
        if ((_debounce?.isActive ?? false) || _hasChanges) {
           _debounce?.cancel();
           await _saveNow(silent: true);
        }
      },
      child: Scaffold(
        backgroundColor: AppDesign.backgroundDark,
        body: Form(
          key: _formKey,
          child: _buildProfileLayout(),
        ),
      ),
    );
  }

  // --- PARTNERS TAB IMPLEMENTATION ---
  

  // Helper for deep search (public within class)
  String? _findBreedRecursive(Map map) {
      if (map['breed'] != null) return map['breed'].toString();
      if (map['raca'] != null) return map['raca'].toString();
      for (var v in map.values) {
          if (v is Map) {
              final found = _findBreedRecursive(v);
              if (found != null) return found;
          }
      }
      return null;
  }

  String _tryLocalizeLabel(BuildContext context, String key) {
    if (!context.mounted) return key.toUpperCase().replaceAll('_', ' ');
    final k = key.toLowerCase().trim().replaceAll(' ', '_');
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return key.toUpperCase().replaceAll('_', ' ');
    
    switch (k) {
        case 'urgency_level': return l10n.petLabelUrgencyLevel;
        case 'confidence': return l10n.petLabelConfidence;
        case 'diagnosis': return l10n.petLabelDiagnosis;
        case 'visual_aspects': return l10n.petLabelVisualAspects;
        case 'possible_causes': return l10n.petLabelPossibleCauses;
        case 'recommendations': return l10n.petLabelRecommendations;
        case 'breed': return l10n.petLabelBreed;
        case 'raca': return l10n.petLabelBreed;
        case 'species': return l10n.petLabelSpecies;
        case 'especie': return l10n.petLabelSpecies;
        case 'color': return l10n.petLabelColor;
        case 'coat_type': return l10n.petLabelCoatType;
        case 'size': return l10n.petLabelSize;
        case 'life_expectancy': return l10n.petLabelLifeExpectancy;
        case 'origin': return l10n.petLabelOrigin;
        case 'temperament': return l10n.petLabelTemperament;
        case 'personality': return l10n.petLabelPersonality;
        case 'social_behavior': return l10n.petLabelSocialBehavior;
        case 'identification': case 'identificacao': return l10n.petLabelIdentification;
        case 'growth_curve': case 'curva_crescimento': return l10n.petLabelGrowthCurve;
        case 'nutrition': case 'nutricao': return l10n.petLabelNutrition;
        case 'grooming': case 'higiene': return l10n.petLabelGrooming;
        case 'health': case 'saude': return l10n.petLabelHealth;
        case 'lifestyle': case 'estilo_vida': return l10n.petLabelLifestyle;
        case 'behavior': case 'comportamento': return l10n.petLabelBehavior;
        default: return key.toUpperCase().replaceAll('_', ' '); 
    }
  }

  Widget _buildAnalysisTabContent() {
    final history = _analysisHistory;
    final current = _currentRawAnalysis;
    final hasData = history.isNotEmpty || (current != null && current.isNotEmpty);

    if (!hasData) {
       return Center(child: Padding(
         padding: const EdgeInsets.symmetric(vertical: 60),
         child: Column(mainAxisSize: MainAxisSize.min, children: [
           const Icon(Icons.analytics_outlined, size: 60, color: Colors.white24),
           const SizedBox(height: 16),
           Text(AppLocalizations.of(context)!.petHistoryEmpty, style: GoogleFonts.poppins(color: Colors.white54)),
         ]),
       ));
    }

    // Show List of Analyses
    return Column(
      children: List.generate(history.length + (current != null && current.isNotEmpty && history.isEmpty ? 1 : 0) + 1, (index) {
          if (index == 0) {
              // AI Disclaimer
              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.amberAccent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.petAnalysisDisclaimer,
                        style: GoogleFonts.poppins(color: Colors.amberAccent, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              );
          }
          
          final actualIndex = index - 1;
          // If history empty but current exists
          Map<String, dynamic> data;
          if (history.isEmpty) {
              data = current!;
          } else {
              // Reverse order
              data = history[history.length - 1 - actualIndex];
          }
          
          final type = data['analysis_type']?.toString().toUpperCase() ?? AppLocalizations.of(context)!.petAnalysisDefaultTitle;
          
          // Date Parsing Logic with Fallback
          String dateStr = AppLocalizations.of(context)!.petAnalysisDateUnknown;
          DateTime? dt;
          if (data['last_updated'] != null) {
             try {
                 dt = DateTime.parse(data['last_updated'].toString());
             } catch (_) {}
          } else if (widget.existingProfile != null) {
             // Fallback to Profile Last Updated
             dt = widget.existingProfile!.lastUpdated;
          }

          if (dt != null) {
             dateStr = '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2,'0')}';
             if (data['last_updated'] == null) {
                 dateStr += AppLocalizations.of(context)!.petAnalysisProfileDate;
             }
          }

          // Deep Search for Breed (Using class helper)
          String? extractedBreed = data['breed']?.toString() ?? _findBreedRecursive(data);
          
          // Last Resort: Regex Search in toString() if still null
          if (extractedBreed == null) {
              final str = data.toString();
              // Try 'breed: Value' pattern (Dart Map toString uses key: value)
              final match = RegExp(r'(?:breed|raca)[:]\s*([^,}\]]+)', caseSensitive: false).firstMatch(str);
              if (match != null) extractedBreed = match.group(1)?.trim();
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10)
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(type, style: const TextStyle(color: AppDesign.petPink, fontWeight: FontWeight.bold)),
                    const Icon(Icons.history, size: 16, color: Colors.white30)
                ]),
                
                // Show Breed explicitly
                if (extractedBreed != null) ...[
                    const SizedBox(height: 4),
                    Text(
                        extractedBreed, 
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)
                    ),
                ],
                
                const SizedBox(height: 8),
                Text(dateStr, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                const Divider(color: Colors.white10),
                
                // Structured Data View
                ...data.entries.where((e) {
                    final k = e.key;
                    final v = e.value;
                    
                    // Filter out technical keys and null values
                    if (['analysis_type', 'last_updated', 'pet_name', 'tabela_benigna', 'tabela_maligna', 'plano_semanal', 'weekly_plan', 'data_inicio_semana', 'data_fim_semana', 'orientacoes_gerais', 'general_guidelines', 'start_date', 'end_date', 'identificacao', 'identification'].contains(k)) return false;
                    
                    // 🛡️ V127: More robust null filtering
                    if (v == null) return false;
                    if (v.toString().toLowerCase() == 'null') return false;
                    if (v is String && v.trim().isEmpty) return false;
                    
                    return true;
                }).map((e) {
                   final val = e.value;
                   
                   if (e.key.contains('image_path') && val is String) {
                       return InkWell(
                           onTap: () async {
                               String finalPath = val;
                               if (!File(finalPath).existsSync()) {
                                   try {
                                       final dir = await getApplicationDocumentsDirectory();
                                       final filename = path.basename(finalPath);
                                       final petName = _nameController.text.trim();
                                       var rPath = path.join(dir.path, filename);
                                       if (File(rPath).existsSync()) {
                                           finalPath = rPath;
                                       } else if (petName.isNotEmpty) {
                                           rPath = path.join(dir.path, 'medical_docs', petName, filename);
                                           if (File(rPath).existsSync()) finalPath = rPath;
                                       }
                                   } catch (e) {
                                       debugPrint('Recovery error: $e');
                                   }
                               }

                               if (File(finalPath).existsSync()) {
                                   if (!context.mounted) return;
                                   showDialog(context: context, builder: (_) => Dialog(
                                       backgroundColor: Colors.transparent,
                                       child: Column(mainAxisSize: MainAxisSize.min, children: [
                                           Image.file(File(finalPath)),
                                           TextButton(
                                               onPressed: () => Navigator.pop(context), 
                                               child: Text(AppLocalizations.of(context)!.commonClose, style: const TextStyle(color: Colors.white))
                                           )
                                       ])
                                   ));
                               }
                           },
                           child: Container(
                               margin: const EdgeInsets.symmetric(vertical: 8),
                               padding: const EdgeInsets.all(8),
                               decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white12)),
                               child: Row(children: [
                                   const Icon(Icons.image, color: AppDesign.petPink, size: 20),
                                   const SizedBox(width: 8),
                                   Expanded(child: Text(AppLocalizations.of(context)!.petAnalysisViewImage, style: const TextStyle(color: AppDesign.petPink, fontWeight: FontWeight.bold, fontSize: 12))),
                                   const Icon(Icons.open_in_new, color: Colors.white30, size: 16)
                               ]),
                           )
                       );
                   }

                   if (val is Map) {
                       return ExpansionTile(
                           initiallyExpanded: true, // 🛡️ V126: Open by default
                           title: Text(_tryLocalizeLabel(context, e.key), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                           childrenPadding: const EdgeInsets.only(left: 16, bottom: 8),
                           children: (val as Map).entries.where((sub) => sub.value != null).map((sub) => Padding(
                               padding: const EdgeInsets.only(bottom: 4),
                               child: Row(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                       Text('${_tryLocalizeLabel(context, sub.key)}: ', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                                       Expanded(child: Text(sub.value.toString(), style: const TextStyle(color: Colors.white, fontSize: 11))),
                                   ]
                               ),
                           )).toList(),
                       );
                   }
                   return Padding(
                       padding: const EdgeInsets.symmetric(vertical: 4),
                       child: Row(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                               Text('${_tryLocalizeLabel(context, e.key)}: ', style: const TextStyle(color: AppDesign.petPink, fontSize: 11, fontWeight: FontWeight.bold)),
                               Expanded(child: Text(val.toString(), style: const TextStyle(color: Colors.white70, fontSize: 11))),
                           ]
                       ),
                   );
                }).toList(),
            ]),
          );
      }),
    );
  }

  Widget _buildPartnersTabContent() {
    return FutureBuilder<List<PartnerModel>>(
      future: (() async {
        final ps = PartnerService();
        await ps.init();
        return ps.getAllPartners();
      })(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppDesign.petPink));
        
        final allPartners = snapshot.data!;
        final filterAll = AppLocalizations.of(context)!.partnersFilterAll;
        final filtered = _selectedPartnerFilter == filterAll
            ? allPartners 
            : allPartners.where((p) => _localizeValue(p.category) == _selectedPartnerFilter).toList();

        return Column(
          children: [
            // 1. Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: _partnerFilterCategories.map((cat) {
                  final isSelected = _selectedPartnerFilter == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (v) => setState(() => _selectedPartnerFilter = cat),
                      backgroundColor: Colors.white.withOpacity(0.05),
                      selectedColor: AppDesign.petPink,
                      labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white),
                      checkmarkColor: Colors.black,
                    ),
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 10),

            // 2. Partners List
            if (allPartners.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.petPartnersNoPartners,
                    style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.petPartnersNotFound,
                    style: GoogleFonts.poppins(color: Colors.white30),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                      final partner = filtered[index];
                      final isLinked = _linkedPartnerIds.contains(partner.id);
                      
                       if (isLinked) {
                        return LinkedPartnerCard(
                          partner: partner,
                          petId: widget.existingProfile?.petName ?? _nameController.text.trim(),
                          petName: _nameController.text.trim(),
                          onUnlink: () async {
                            setState(() {
                              _linkedPartnerIds.remove(partner.id);
                              _linkedPartnerModels.removeWhere((p) => p.id == partner.id);
                            });
                            _markDirty(); // Trigger auto-save
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
                        color: AppDesign.textPrimaryDark.withOpacity(0.05),
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
                                    Text(_localizeValue(partner.category), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Switch(
                                value: false,
                                activeColor: AppDesign.petPink,
                                onChanged: (val) async {
                                  if (val) {
                                    setState(() {
                                      _linkedPartnerIds.add(partner.id);
                                      _linkedPartnerModels.add(partner);
                                    });
                                    _markDirty(); // Trigger auto-save
                                    
                                    // Indexing
                                    try {
                                      PetIndexingService().indexPartnerInteraction(
                                        petId: widget.existingProfile?.petName ?? _nameController.text.trim(),
                                        petName: _nameController.text.trim(),
                                        partnerName: partner.name,
                                        partnerId: partner.id,
                                        interactionType: 'linked_partner',
                                        localizedTitle: AppLocalizations.of(context)!.petIndexing_partnerLinked(partner.name),
                                        localizedNotes: AppLocalizations.of(context)!.petIndexing_partnerInteractionNotes,
                                      );
                                    } catch (e) {
                                      debugPrint('Error indexing partner link: $e');
                                    }
                                  }
                                },
                              )
                            ],
                          ),
                        ),
                      );
                },
              ),

            // 3. Observations Field
            Padding(
              padding: const EdgeInsets.all(16),
              child: CumulativeObservationsField(
                sectionName: AppLocalizations.of(context)!.petPartnersObs,
                initialValue: _observacoesPrac,
                onChanged: (value) {
                  setState(() => _observacoesPrac = value);
                  _onUserTyping();
                },
                icon: Icons.handshake,
                accentColor: AppDesign.petPink,
              ),
            ),

            // 4. Action Buttons
            _buildActionButtons(),

            // 5. Bottom Padding (ensures content is visible above keyboard)
            const SizedBox(height: 100),
          ],
        );
      }
    );
  }




  Widget _buildProfileImageHeader() {
    // 1. Determine Image Source
    ImageProvider? imageProvider;

    if (_profileImage != null && _profileImage!.existsSync() && _profileImage!.lengthSync() > 0) {
      imageProvider = FileImage(_profileImage!);
    } else if (_initialImagePath != null && _initialImagePath!.isNotEmpty) {
       final f = File(_initialImagePath!);
       if (f.existsSync() && f.lengthSync() > 0) {
           imageProvider = FileImage(f);
       } else if (_initialImagePath!.startsWith('http')) {
           imageProvider = NetworkImage(_initialImagePath!);
       }
    }

    // Debug Log
    debugPrint('PET_PROFILE_IMAGE: path=${_profileImage?.path}, initial=$_initialImagePath, provider=$imageProvider');

    // 2. Build Widget with Robust Error Handling
    return Center(
      child: GestureDetector(
        onTap: _pickProfileImage,
        child: Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppDesign.petPink, width: 3),
                color: Colors.white.withOpacity(0.1),
              ),
              child: ClipOval(
                child: imageProvider != null
                    ? Image(
                        image: imageProvider,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                            debugPrint('🔴 Erro visual recuperado na imagem: $error');
                            return const Center(child: Icon(Icons.pets, size: 60, color: Colors.white24));
                        },
                      )
                    : const Center(child: Icon(Icons.pets, size: 60, color: Colors.white24)),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppDesign.petPink,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, color: Colors.black, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentityTabContent() {
      return _buildIdentityTabContentNEW();
  }

  Widget _buildIdentityTabContent_OLD() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ESPÉCIE (Mandatory Selection - MOVED TO TOP)
        _buildSectionTitle('📌 ${AppLocalizations.of(context)!.species_label} *'),
        const SizedBox(height: 12),
        FormField<String>(
          validator: (val) => _especie == null ? 'Espécie obrigatória' : null,
          initialValue: _especie,
          builder: (FormFieldState<String> state) {
             return InputDecorator(
               decoration: InputDecoration(
                 labelText: 'Espécie *', 
                 prefixIcon: const Icon(Icons.pets, color: Colors.white30, size: 18),
                 filled: true,
                 fillColor: AppDesign.backgroundDark,
                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                 errorText: state.hasError ? state.errorText : null,
               ),
               child: Row(
                 children: [
                    Expanded(
                      child: InkWell(
                        onTap: () { 
                            setState(() => _especie = 'Cão'); 
                            state.didChange('Cão'); 
                            _onUserInteractionGeneric(); 
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: _especie == 'Cão' ? AppDesign.petPink.withOpacity(0.1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                               Radio<String>(
                                 value: 'Cão',
                                 groupValue: _especie,
                                 activeColor: AppDesign.petPink,
                                 onChanged: (val) { 
                                     setState(() => _especie = val); 
                                     state.didChange(val); 
                                     _onUserInteractionGeneric(); 
                                 },
                               ),
                               const Icon(Icons.pets, color: Colors.white70, size: 18),
                               const SizedBox(width: 4),
                               Text(l10n.species_dog, style: TextStyle(color: _especie == 'Cão' ? Colors.white : Colors.white60, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                         onTap: () { 
                             setState(() => _especie = 'Gato'); 
                             state.didChange('Gato'); 
                             _onUserInteractionGeneric(); 
                         },
                         child: Container(
                           padding: const EdgeInsets.symmetric(vertical: 4),
                           decoration: BoxDecoration(
                             color: _especie == 'Gato' ? AppDesign.petPink.withOpacity(0.1) : Colors.transparent,
                             borderRadius: BorderRadius.circular(8),
                           ),
                           child: Row(
                             mainAxisAlignment: MainAxisAlignment.center,
                             children: [
                                Radio<String>(
                                  value: 'Gato',
                                  groupValue: _especie,
                                  activeColor: AppDesign.petPink,
                                  onChanged: (val) { 
                                      setState(() => _especie = val); 
                                      state.didChange(val); 
                                      _onUserInteractionGeneric(); 
                                  },
                                ),
                                const Icon(Icons.auto_awesome, color: Colors.white70, size: 18),
                                const SizedBox(width: 4),
                                Text(l10n.species_cat, style: TextStyle(color: _especie == 'Gato' ? Colors.white : Colors.white60, fontSize: 13)),
                             ],
                           ),
                         ),
                      ),
                    ),
                 ],
               ),
             );
          },
        ),

        const SizedBox(height: 24),
        _buildRaceDetailsSection(),
        const SizedBox(height: 24),

        // SEXO DO PET
        _buildSectionTitle('⚤ Sexo *'),
        const SizedBox(height: 12),
        FormField<String>(
          validator: (val) => _sexo == null ? 'Sexo obrigatório' : null,
          initialValue: _sexo,
          builder: (FormFieldState<String> state) {
             return InputDecorator(
               decoration: InputDecoration(
                 labelText: 'Sexo *',
                 prefixIcon: const Icon(Icons.transgender, color: Colors.white30, size: 18),
                 filled: true,
                 fillColor: AppDesign.backgroundDark,
                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                 errorText: state.hasError ? state.errorText : null,
                 contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
               ),
               child: Row(
                 children: [
                    Expanded(
                      child: InkWell(
                        onTap: () { 
                            setState(() => _sexo = 'Male'); 
                            state.didChange('Male'); 
                            _onUserInteractionGeneric(); 
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: _sexo == 'Male' ? AppDesign.petPink.withOpacity(0.1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                               Radio<String>(
                                 value: 'Male',
                                 groupValue: _sexo,
                                 activeColor: AppDesign.petPink,
                                 onChanged: (val) { 
                                     setState(() => _sexo = val); 
                                     state.didChange(val); 
                                     _onUserInteractionGeneric(); 
                                 },
                               ),
                               Text(l10n.gender_male, style: TextStyle(color: _sexo == 'Male' ? Colors.white : Colors.white60, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                         onTap: () { 
                             setState(() => _sexo = 'Female'); 
                             state.didChange('Female'); 
                             _onUserInteractionGeneric(); 
                         },
                         child: Container(
                           padding: const EdgeInsets.symmetric(vertical: 4),
                           decoration: BoxDecoration(
                             color: _sexo == 'Female' ? AppDesign.petPink.withOpacity(0.1) : Colors.transparent,
                             borderRadius: BorderRadius.circular(8),
                           ),
                           child: Row(
                             mainAxisAlignment: MainAxisAlignment.center,
                             children: [
                               Radio<String>(
                                 value: 'Female',
                                 groupValue: _sexo,
                                 activeColor: AppDesign.petPink,
                                 onChanged: (val) { 
                                     setState(() => _sexo = val); 
                                     state.didChange(val); 
                                     _onUserInteractionGeneric(); 
                                 },
                               ),
                               Text(l10n.gender_female, style: TextStyle(color: _sexo == 'Female' ? Colors.white : Colors.white60, fontSize: 13)),
                             ],
                           ),
                         ),
                      ),
                    ),
                 ],
               ),
             );
          },
        ),
        
        const SizedBox(height: 12),
        
        // NAME
        _buildTextField(
          controller: _nameController,
          label: 'Nome do Pet *',
          icon: Icons.person,
          validator: (v) => v?.trim().isEmpty ?? true ? 'Nome obrigatório' : null,
          onChanged: (v) => _onUserTyping(),
        ),

        const SizedBox(height: 12),
        
        // BREED (Validated)
        _buildTextField(
          controller: _racaController,
          label: '${AppLocalizations.of(context)!.petProfile_breed} *',
          icon: Icons.category,
          validator: (v) => v?.trim().isEmpty ?? true ? AppLocalizations.of(context)!.breed_required : null,
        ),
        if (_reliability != null) ...[
           const SizedBox(height: 4),
           Align(
             alignment: Alignment.centerRight,
             child: Container(
               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
               decoration: BoxDecoration(
                 color: AppDesign.petPink.withOpacity(0.1),
                 borderRadius: BorderRadius.circular(12),
                 border: Border.all(color: AppDesign.petPink.withOpacity(0.3)),
               ),
               child: Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   const Icon(Icons.verified, color: AppDesign.petPink, size: 14),
                   const SizedBox(width: 4),
                   Text(
                     '${l10n.reliability_label}: $_reliability',
                     style: const TextStyle(color: AppDesign.petPink, fontSize: 11, fontWeight: FontWeight.bold),
                   ),
                 ],
               ),
             ),
           ),
        ],
        
        const SizedBox(height: 12),

        // PORTE (Mandatory Selection)
        _buildSectionTitle('📏 Porte / Tamanho *'),
        const SizedBox(height: 12),
        _buildOptionSelector(
          value: _porte,
          label: 'Porte *',
          icon: Icons.straighten,
          options: [
            'Pequeno',
            'Médio',
            'Grande',
            'Gigante'
          ],
          onChanged: (val) { 
            setState(() => _porte = val); 
            _onUserInteractionGeneric(); 
          },
        ),

        const SizedBox(height: 12),

        _buildTextField(
          controller: _idadeController,
          label: '${AppLocalizations.of(context)!.petAgeLabel} *',
          icon: Icons.cake,
          validator: (v) => v?.trim().isEmpty ?? true ? AppLocalizations.of(context)!.commonRequired : null,
        ),
        
        const SizedBox(height: 24),
      _buildSectionTitle('⚙️ ${l10n.petBiologicalProfile}'),
      const SizedBox(height: 16),
      
      _buildOptionSelector(
        value: _nivelAtividade,
        label: l10n.petActivityLevel,
        icon: Icons.directions_run,
        options: _getLocalizedItems((l) => [
           l.petActivityLow,
           l.petActivityModerate,
           l.petActivityHigh,
           l.petActivityAthlete
        ]),
        onChanged: (val) { setState(() => _nivelAtividade = val!); _onUserInteractionGeneric(); },
      ),
      
      // STATUS REPRODUTIVO (Radio Sim/Não para Castrado)
      FormField<String>(
          validator: (val) => (_statusReprodutivo == 'Não informado' || _statusReprodutivo == 'Not Informed') ? l10n.petProfile_errorReproductive : null,
          initialValue: _statusReprodutivo,
          builder: (FormFieldState<String> state) {
             return InputDecorator(
               decoration: InputDecoration(
                 labelText: '${l10n.petProfile_reproductiveStatus} *',
                 prefixIcon: const Icon(Icons.medical_services, color: Colors.white30, size: 18),
                 filled: true,
                 fillColor: AppDesign.backgroundDark,
                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                 errorText: state.hasError ? state.errorText : null,
                 contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
               ),
               child: Row(
                 children: [
                    Expanded(
                      child: InkWell(
                        onTap: () { 
                            setState(() => _statusReprodutivo = l10n.petNeutered); 
                            state.didChange(l10n.petNeutered); 
                            _onUserInteractionGeneric(); 
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: _localizeValue(_statusReprodutivo) == l10n.petNeutered ? AppDesign.petPink.withOpacity(0.1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                               Radio<String>(
                                 value: l10n.petNeutered,
                                 groupValue: _localizeValue(_statusReprodutivo),
                                 activeColor: AppDesign.petPink,
                                 onChanged: (val) { 
                                     setState(() => _statusReprodutivo = val!); 
                                     state.didChange(val); 
                                     _onUserInteractionGeneric(); 
                                 },
                               ),
                               Expanded(child: Text(l10n.petNeutered, style: TextStyle(color: _localizeValue(_statusReprodutivo) == l10n.petNeutered ? Colors.white : Colors.white60, fontSize: 13))),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () { 
                            setState(() => _statusReprodutivo = l10n.petIntact); 
                            state.didChange(l10n.petIntact); 
                            _onUserInteractionGeneric(); 
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: _localizeValue(_statusReprodutivo) == l10n.petIntact ? AppDesign.petPink.withOpacity(0.1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                               Radio<String>(
                                 value: l10n.petIntact,
                                 groupValue: _localizeValue(_statusReprodutivo),
                                 activeColor: AppDesign.petPink,
                                 onChanged: (val) { 
                                     setState(() => _statusReprodutivo = val!); 
                                     state.didChange(val); 
                                     _onUserInteractionGeneric(); 
                                 },
                               ),
                               Expanded(child: Text(l10n.petIntact, style: TextStyle(color: _localizeValue(_statusReprodutivo) == l10n.petIntact ? Colors.white : Colors.white60, fontSize: 13))),
                            ],
                          ),
                        ),
                      ),
                    ),
                 ],
               ),
             );
          },
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
          accentColor: AppDesign.petPink,
        ),

        _buildAttachmentSection('identity', AppLocalizations.of(context)!.pdfIdentitySection),
      ],
    );
  }

  Widget _buildHealthTabContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox.shrink(), // Weight Section Removed (Moved to Identify Tab)
        
        const SizedBox(height: 24),
        _buildSectionTitle('💉 ${AppLocalizations.of(context)!.petVaccinationHistory}'),
        const SizedBox(height: 16),
        
        _buildDatePicker(
          label: AppLocalizations.of(context)!.petLastV10,
          icon: Icons.vaccines,
          selectedDate: _dataUltimaV10,
          onDateSelected: (date) { setState(() => _dataUltimaV10 = date); _onUserInteractionGeneric(); },
        ),
        
        _buildDatePicker(
          label: AppLocalizations.of(context)!.petLastRabies,
          icon: Icons.coronavirus,
          selectedDate: _dataUltimaAntirrabica,
          onDateSelected: (date) { setState(() => _dataUltimaAntirrabica = date); _onUserInteractionGeneric(); },
        ),
        
        const SizedBox(height: 24),
      _buildSectionTitle('🛁 ${l10n.petHygiene}'),
      const SizedBox(height: 16),
      
      _buildOptionSelector(
        value: _frequenciaBanho,
        label: l10n.petBathFrequency,
        icon: Icons.water_drop,
        options: _getLocalizedItems((l) => [
           l.petBathBiweekly,
           l.petBathWeekly,
           l.petBathMonthly
        ]),
        onChanged: (val) { setState(() => _frequenciaBanho = val!); _onUserInteractionGeneric(); },
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
        _buildSectionTitle('📄 ${AppLocalizations.of(context)!.petMedicalDocs}'),
        const SizedBox(height: 8),
        
        _buildAttachmentSection('health_prescriptions', '📝 ${AppLocalizations.of(context)!.petPrescriptions}'),
        _buildAttachmentSection('health_vaccines', '💉 ${AppLocalizations.of(context)!.petVaccineCard}'),

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
          accentColor: AppDesign.petPink,
        ),
      ],
    );
  }

  Widget _buildNutritionTabContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('⚠️ ${AppLocalizations.of(context)!.petFoodAllergies}'),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.petFoodAllergiesDesc,
          style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12),
        ),
        const SizedBox(height: 16),
        
        _buildChipInput(
          controller: _alergiasController,
          label: AppLocalizations.of(context)!.petAddAllergy,
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
        _buildSectionTitle('🚫 ${AppLocalizations.of(context)!.petFoodRestrictions ?? 'Restrições'}'),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.petFoodRestrictionsDesc ?? 'Ingredientes proibidos ou a evitar (ex: sem frango, sem glúten).',
          style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12),
        ),
        const SizedBox(height: 16),
        
        _buildChipInput(
          controller: _restricoesController,
          label: AppLocalizations.of(context)!.petAddRestriction ?? 'Adicionar restrição',
          icon: Icons.block,
          chips: _restricoes,
          chipColor: AppDesign.petPink.withOpacity(0.8),
          onAdd: (text) {
            setState(() {
              _restricoes.add(text);
              _restricoesController.clear();
            });
            _markDirty();
          },
          onDelete: (index) {
            setState(() => _restricoes.removeAt(index));
            _markDirty();
          },
        ),
        
        const SizedBox(height: 24),
        _buildSectionTitle('❤️ ${AppLocalizations.of(context)!.petFoodPreferences}'),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.petFoodPreferencesDesc,
          style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12),
        ),
        const SizedBox(height: 16),
        
        _buildChipInput(
          controller: _preferenciasController,
          label: AppLocalizations.of(context)!.petAddPreference,
          icon: Icons.favorite,
          chips: _preferencias,
          chipColor: AppDesign.petPink,
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

        _buildAttachmentSection('nutrition', AppLocalizations.of(context)!.petDietRecipes),
        
        const SizedBox(height: 24),
        CumulativeObservationsField(
          sectionName: 'Nutrição',
          initialValue: _observacoesNutricao,
          onChanged: (value) {
            setState(() => _observacoesNutricao = value);
            _onUserTyping();
          },
          icon: Icons.restaurant,
          accentColor: AppDesign.petPink,
        ),
      ],
    );
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppLocalizations.of(context)!.petDeleteTitle, style: const TextStyle(color: Colors.white)),
        content: Text(
          AppLocalizations.of(context)!.petDeleteContent(widget.existingProfile?.petName ?? AppLocalizations.of(context)!.petDefaultName),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.commonCancel, style: const TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.petDeleteConfirm, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
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
    final woundHistory = _woundHistory; // Legacy
    final structuredHistory = _historicoAnaliseFeridas; // New Structured
    
    if (woundHistory.isEmpty && structuredHistory.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('🩹 ${AppLocalizations.of(context)!.petWoundHistory}'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppDesign.textPrimaryDark.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white54, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.petNoWounds,
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
        _buildSectionTitle('🩹 ${AppLocalizations.of(context)!.petWoundHistory}'),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.petWoundsCount(woundHistory.length + structuredHistory.length),
          style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 16),
        // Deduplicate: If an image exists in structured history, don't show it in legacy history
        ...woundHistory.where((legacy) {
            final legacyPath = legacy['imagePath']?.toString();
            return !structuredHistory.any((structured) => structured.imagemRef == legacyPath);
        }).map((analysis) => _buildWoundAnalysisCard(analysis)),

        // Render New Structured History (Higher precision)
        ...structuredHistory.map((analysis) => _buildStructuredWoundCard(analysis)).toList().reversed,

      ],
    );
  }

  Widget _buildWoundAnalysisCard(Map<String, dynamic> analysis) {
    final date = DateTime.parse(analysis['date'] as String);
    final diagnosisRaw = analysis['diagnosis'] as String?;
    final diagnosis = (diagnosisRaw != null && diagnosisRaw.isNotEmpty) ? diagnosisRaw : AppLocalizations.of(context)!.diagnosisPending;
    // Removed old severityDisplay logic
    final recommendations = (analysis['recommendations'] as List?)?.cast<String>() ?? [];
    
    Color severityColor;
    final severity = analysis['severity'] as String? ?? 'Baixa';
    final sevLower = severity.toLowerCase();
    
    String severityDisplay;
    if (sevLower.contains('alta') || sevLower.contains('high')) {
        severityColor = Colors.red;
        severityDisplay = AppLocalizations.of(context)!.severityHigh;
    } else if (sevLower.contains('média') || sevLower.contains('media') || sevLower.contains('medium')) {
        severityColor = Colors.orange;
        severityDisplay = AppLocalizations.of(context)!.severityMedium;
    } else {
        severityColor = AppDesign.petPink;
        severityDisplay = AppLocalizations.of(context)!.severityLow;
    }

    final imagePath = analysis['imagePath'] as String?;
    final hasImage = imagePath != null && imagePath.isNotEmpty && File(imagePath!).existsSync();

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
                '${AppLocalizations.of(context)!.petSeverity}: $severityDisplay',
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
          tooltip: AppLocalizations.of(context)!.commonDelete,
        ),
        children: [
          const Divider(color: Colors.white12),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              AppLocalizations.of(context)!.petDiagnosis,
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
              AppLocalizations.of(context)!.petRecommendations,
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


               // 1. Refresh Wound History (Local + Structured)
               if (data['wound_analysis_history'] != null) {
                   if (mounted) {
                      setState(() {
                          _woundHistory = (data['wound_analysis_history'] as List)
                              .map((e) => Map<String, dynamic>.from(e as Map))
                              .toList();
                      });
                   }
               }
               
               // 🛡️ V_FIX: Load Structured History (Gallery)
               if (data['historicoAnaliseFeridas'] != null) {
                   try {
                       final list = (data['historicoAnaliseFeridas'] as List).map((e) => AnaliseFeridaModel.fromJson(Map<String, dynamic>.from(e))).toList();
                       if (mounted) setState(() => _historicoAnaliseFeridas = list);
                   } catch (e) {
                       debugPrint('Error loading structured history: $e');
                   }
               }
               
               // 🛡️ V_FIX: Load Lab Exams
               if (data['labExams'] != null) {
                   try {
                       final list = (data['labExams'] as List).map((e) => LabExam.fromJson(Map<String, dynamic>.from(e))).toList();
                       if (mounted) setState(() => _labExams = list);
                   } catch (e) {
                       debugPrint('Error loading lab exams: $e');
                   }
               }

               // 2. Refresh Linked Partners and Notes
               if (data['linked_partner_ids'] != null) {
                   if (mounted) {
                      setState(() {
                          _linkedPartnerIds = (data['linked_partner_ids'] as List?)?.cast<String>() ?? [];
                      });
                      // Reload partner models
                      _loadLinkedPartners();
                   }
               }
               
               if (data['partner_notes'] != null) {
                   if (mounted) {
                      setState(() {
                          _partnerNotes = (data['partner_notes'] as Map?)?.map(
                              (k, v) => MapEntry(k.toString(), (v as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? []),
                          ) ?? {};
                      });
                   }
               }

               // 3. Refresh Opaque Data (Raw Analysis & Agenda)
               final freshRaw = data['raw_analysis'];
               if (freshRaw != null) {
                   _currentRawAnalysis = Map<String,dynamic>.from(freshRaw);
               }
               
               if (data['agendaEvents'] != null) {
                   _currentRawAnalysis ??= {};
                   _currentRawAnalysis!['agendaEvents'] = data['agendaEvents'];
               }

               debugPrint('HIVE: Dados recarregados e fundidos com sucesso (Wound History + Linked Partners + Raw Data).');
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
                AppLocalizations.of(context)!.petWoundDeleteTitle,
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
          AppLocalizations.of(context)!.petWoundDeleteConfirm,
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              AppLocalizations.of(context)!.cancel,
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
              AppLocalizations.of(context)!.commonDelete,
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
                AppLocalizations.of(context)!.petWoundDeleteSuccess,
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: AppDesign.petPink,
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
                '${AppLocalizations.of(context)!.petWoundDeleteError} $e',
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
    void Function(String)? onChanged,
    bool isRequired = false,
  }) {
    final bool isActive = _isListening && _activeVoiceController == controller;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        keyboardType: keyboardType,
        decoration: InputDecoration(
          label: RichText(
             text: TextSpan(
                text: label.replaceAll('*', '').trim(),
                style: const TextStyle(color: Colors.white60, fontSize: 16),
                children: [
                   if (isRequired)
                      const TextSpan(text: ' *', style: TextStyle(color: AppDesign.petPink)),
                ]
             )
          ),
          prefixIcon: Icon(icon, color: AppDesign.petPink, size: 20),
          suffixIcon: IconButton(
            icon: Icon(
              isActive ? Icons.mic : Icons.mic_none,
              color: isActive ? Colors.redAccent : Colors.white,
            ),
            onPressed: () => _toggleListening(controller),
            tooltip: 'Ditado por voz',
          ),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppDesign.petPink)),
        ),
        validator: validator,
        onChanged: onChanged,
      ),
    );
  }

  // --- VOICE INPUT LOGIC ---

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onError: (e) => debugPrint('Erro de voz: $e'),
        onStatus: (status) {
          if (mounted) {
             if (status == 'done' || status == 'notListening') {
                setState(() => _isListening = false);
             }
          }
        },
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Falha ao inicializar speech: $e');
    }
  }

  Future<void> _toggleListening(TextEditingController controller) async {
    if (!_speechAvailable) {
       await _initSpeech();
       if (!_speechAvailable) {
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reconhecimento de voz não disponível')));
         }
         return;
       }
    }

    // Se já estiver ouvindo neste controle, para.
    if (_isListening && _activeVoiceController == controller) {
      _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    // Se estiver ouvindo em outro, para antes de começar o novo
    if (_isListening) {
      await _speech.stop();
    }

    final granted = await PermissionHelper.requestMicrophonePermission(context);
    if (!granted) return;

    if (mounted) {
      setState(() {
        _isListening = true;
        _activeVoiceController = controller;
        _lastWords = '';
      });
    }

    // Detectar idioma atual
    String localeId = 'pt_BR';
    try {
      final loc = Localizations.localeOf(context);
      if (loc.languageCode == 'pt') {
         localeId = (loc.countryCode == 'PT') ? 'pt_PT' : 'pt_BR';
      } else if (loc.languageCode == 'es') {
         localeId = 'es_ES';
      } else {
         localeId = 'en_US'; 
      }
    } catch (e) {
       localeId = 'pt_BR';
    }

    final savedCursor = controller.selection.baseOffset < 0 ? controller.text.length : controller.selection.baseOffset;

    await _speech.listen(
      onResult: (result) {
         if (!mounted) return;
         
         final recognized = result.recognizedWords;
         
         String textBefore = controller.text.substring(0, savedCursor);
         String textAfter = controller.text.substring(savedCursor + _lastWords.length); 
         
         if (textAfter.length + savedCursor + _lastWords.length > controller.text.length) {
             textBefore = controller.text;
             textAfter = '';
         }

         final newText = textBefore + recognized + textAfter;
         
         controller.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: savedCursor + recognized.length),
         );
         
         _lastWords = recognized;
         
         if (result.finalResult) {
             _lastWords = ''; 
             _onUserTyping(); 
         }
      },
      localeId: localeId,
      listenMode: stt.ListenMode.dictation,
      cancelOnError: true,
    );
  }

   Widget _buildOptionSelector({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> options,
    required Function(String?) onChanged,
    bool isRequired = false,
  }) {
    final localizedValue = _localizeValue(value);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white30, size: 18),
            const SizedBox(width: 8),
            RichText(
               text: TextSpan(
                  text: label.replaceAll('*', '').trim(),
                  style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                  children: [
                      if (isRequired)
                        const TextSpan(text: ' *', style: TextStyle(color: AppDesign.petPink)),
                  ]
               )
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = localizedValue == option;
            return ChoiceChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) onChanged(option);
              },
              selectedColor: AppDesign.petPink.withOpacity(0.2),
              backgroundColor: AppDesign.backgroundDark,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isSelected ? AppDesign.petPink : Colors.white12),
              ),
              showCheckmark: false,
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
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
                    primary: AppDesign.petPink,
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
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppDesign.petPink),
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
                          : AppLocalizations.of(context)!.petNotOffice,
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
                  prefixIcon: Icon(icon, color: AppDesign.petPink),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
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
              icon: const Icon(Icons.add_circle, color: AppDesign.petPink, size: 32),
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
              backgroundColor: chipColor.withOpacity(0.2),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.petNameRequired)));
        return;
     }

     DateTimeRange? selectedDateRange = DateTimeRange(
        start: DateTime.now().add(const Duration(days: 1)),
        end: DateTime.now().add(const Duration(days: 7)),
     );
     bool isNatural = true;
     bool isKibble = false;
     
     final goals = _getLocalizedItems((l) => [
        l.goalWeightMaintenance,
        l.goalWeightLoss,
        l.goalMuscleGain,
        l.goalRecovery
     ]);
     String goal = goals.isNotEmpty ? goals.first : 'Manter Peso';

     final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) {
           return StatefulBuilder(
              builder: (context, setDialogState) {
                 return AlertDialog(
                    backgroundColor: Colors.grey[900],
                    title: Row(
                       children: [
                          Icon(Icons.auto_awesome, color: AppDesign.petPink),
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
                                          colorScheme: const ColorScheme.dark(primary: AppDesign.petPink, onPrimary: Colors.black, onSurface: Colors.white),
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
                                         const Icon(Icons.calendar_today, color: AppDesign.petPink, size: 16),
                                      ],
                                   ),
                                ),
                             ),
                             const SizedBox(height: 16),
                             Text(AppLocalizations.of(context)!.dietType, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                             CheckboxListTile(
                                title: Text(AppLocalizations.of(context)!.dietNatural, style: const TextStyle(color: Colors.white, fontSize: 14)),
                                value: isNatural,
                                activeColor: AppDesign.petPink,
                                checkColor: Colors.black,
                                contentPadding: EdgeInsets.zero,
                                onChanged: (v) => setDialogState(() => isNatural = v ?? false),
                             ),
                             CheckboxListTile(
                                title: Text(AppLocalizations.of(context)!.dietKibble, style: const TextStyle(color: Colors.white, fontSize: 14)),
                                value: isKibble,
                                activeColor: AppDesign.petPink,
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
                             Wrap(
                                spacing: 8,
                                children: goals.map((g) {
                                   final isSelected = goal == g;
                                   return ChoiceChip(
                                      label: Text(g, style: const TextStyle(fontSize: 12)),
                                      selected: isSelected,
                                      onSelected: (v) => setDialogState(() => goal = g),
                                      selectedColor: AppDesign.petPink.withOpacity(0.2),
                                      backgroundColor: Colors.white10,
                                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white60),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isSelected ? AppDesign.petPink : Colors.transparent)),
                                      showCheckmark: false,
                                   );
                                }).toList(),
                             ),
                          ],
                       ),
                    ),
                    actions: [
                       TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.btnCancel, style: const TextStyle(color: Colors.white54))),
                       ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppDesign.petPink, foregroundColor: Colors.black),
                          onPressed: () {
                             if (!isNatural && !isKibble) {
                                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.selectRegime)));
                                return;
                             }
                             if (selectedDateRange == null) {
                                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.selectDatesError)));
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
                 children: [
                    const CircularProgressIndicator(color: AppDesign.petPink),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.aiCalculatingMetrics,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                 ],
              ),
           ),
        ),
     );

     try {
        final locale = Localizations.localeOf(context).toString();
        final isEn = locale.startsWith('en');
        final isEs = locale.startsWith('es');
        
        String langName = isEn ? "English" : (isEs ? "Spanish" : "Portuguese-BR");
        String langInst = isEn ? "Respond in English." : (isEs ? "Responda en Español." : "Responda em Português do Brasil.");

        final service = GeminiService();
        final existingPlan = _currentRawAnalysis?['plano_semanal'] as List?;
        
        // Smart Merge Logic: Preserve history before 'Today' or selected start date
        // Logic: Preserve ALL items where date is strictly BEFORE generation start.
        List<Map<String, dynamic>> history = [];
        if (existingPlan != null && existingPlan.isNotEmpty) {
           history = existingPlan.map((e) => Map<String, dynamic>.from(e)).toList();
        }
        
        String historyContext = "${AppLocalizations.of(context)!.menuProfileHeader}\n";
        if (_alergiasConhecidas.isNotEmpty) historyContext += "${AppLocalizations.of(context)!.menuAllergiesForbidden}: ${_alergiasConhecidas.join(', ')}\n";
        if (_preferencias.isNotEmpty) historyContext += "${AppLocalizations.of(context)!.menuPreferences}: ${_preferencias.join(', ')}\n";
        if (history.isNotEmpty) {
           final historySample = history.take(5).map((e) => e['dia']).toList();
           historyContext += "\n${AppLocalizations.of(context)!.menuRecentMeals}: $historySample\n";
        }

        final formatter = DateFormat.yMd(locale);
        final startStr = formatter.format(selectedDateRange!.start);
        final endStr = formatter.format(selectedDateRange!.end);
        final duration = selectedDateRange!.end.difference(selectedDateRange!.start).inDays + 1;
        
        String dietType = isEn ? 'Undefined' : (isEs ? 'Indefinido' : 'Indefinido');
        if (isNatural && isKibble) dietType = 'Hybrid (${AppLocalizations.of(context)!.dietKibble} + ${AppLocalizations.of(context)!.dietNatural})';
        else if (isNatural) dietType = '100% ${AppLocalizations.of(context)!.dietNatural}';
        else dietType = '100% ${AppLocalizations.of(context)!.dietKibble}';

        final prompt = PromptFactory.getWeeklyMenuPrompt(
          petName: _nameController.text.trim(),
          breed: _racaController.text.trim(),
          age: _idadeController.text.trim(),
          weight: _pesoController.text.trim(),
          goal: goal,
          dietType: dietType,
          startStr: startStr,
          endStr: endStr,
          duration: duration,
          historyContext: historyContext,
          languageName: langName,
          languageInstruction: langInst,
        );

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
        if (currentProfile != null && currentProfile['data'] != null) {
             final pData = currentProfile['data'];
             final rawOldPlan = pData['plano_semanal'] ?? pData['raw_analysis']?['plano_semanal'];
             
             if (rawOldPlan != null && rawOldPlan is List) {
                 combinedPlan = List<Map<String, dynamic>>.from(
                     rawOldPlan.map((x) => Map<String, dynamic>.from(x as Map))
                 );
                 combinedPlan = [...combinedPlan, ...finalItems];
             } else {
                 combinedPlan = finalItems;
             }
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
            _hasChanges = true; // Mark as dirty
        });

        debugPrint('💾 [Generator] Requesting atomic save...');
        await _saveNow(silent: true);

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.menuPlannedSuccess),
            backgroundColor: AppDesign.petPink,
        ));

     } catch (e, stack) {
        debugPrint('❌ [Generator] Error: $e\n$stack');
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
           Padding(
             padding: const EdgeInsets.symmetric(vertical: 8),
             child: _buildSectionTitle(AppLocalizations.of(context)!.petRaceAnalysis),
           ),
           const SizedBox(height: 8),
           
           
            if (ident != null) ...[
               _buildInfoRow(AppLocalizations.of(context)!.petLineage, _localizeValue(ident['linhagem_mista']?.toString())),
               _buildInfoRow(AppLocalizations.of(context)!.petRaceAnalysis, _localizeValue(ident['raca_predominante']?.toString())),
               _buildInfoRow(AppLocalizations.of(context)!.petReliability, _localizeValue(ident['confiabilidade']?.toString(), isReliability: true)),
            ],
            
            if (fisica != null) ...[
               _buildInfoRow(AppLocalizations.of(context)!.petLifeExpectancy, fisica['expectativa_vida']?.toString() ?? AppLocalizations.of(context)!.petNotEstimated),
               _buildInfoRow(AppLocalizations.of(context)!.petSize, fisica['porte']?.toString() ?? AppLocalizations.of(context)!.petNotIdentified),
               _buildInfoRow(AppLocalizations.of(context)!.petTypicalWeight, fisica['peso_estimado']?.toString() ?? AppLocalizations.of(context)!.petVariable),
            ],

           if (temp != null) ...[
               const SizedBox(height: 12),
               Text(AppLocalizations.of(context)!.petTemperament, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  title: Text(AppLocalizations.of(context)!.petOrigin, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
                  collapsedIconColor: Colors.white54,
                  iconColor: AppDesign.petPink,
                  children: [Padding(padding: const EdgeInsets.all(8), child: Text(origem, style: const TextStyle(color: Colors.white70)))],
               )
           ],

           if (curiosidades != null && curiosidades.isNotEmpty) ...[
               const SizedBox(height: 12),
               ExpansionTile(
                  title: Text(AppLocalizations.of(context)!.petCuriosities, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
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

  Future<void> _handleGenerateTap(BuildContext context, WidgetRef ref) async {
      if (widget.existingProfile == null && _nameController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.petNameRequired)));
          return;
      }
      
      final l10n = AppLocalizations.of(context)!;
      final config = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => PetMenuFilterDialog(),
      );

      if (config == null || !mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => MealPlanLoadingWidget(petName: _nameController.text.trim()),
      );

      try {
          // Construct profile context using latest UI values (Source of Truth)
          final Map<String, dynamic> profileData = widget.existingProfile?.toJson() ?? {};
          profileData['pet_name'] = _nameController.text;
          profileData['especie'] = _especie; 
          profileData['raca'] = _racaController.text;
          profileData['peso_atual'] = double.tryParse(_pesoController.text.replaceAll(',', '.'));
          profileData['idade_exata'] = _idadeController.text;
          profileData['porte'] = _porte;
          
          // Compatibilidade com chaves do PetMenuGeneratorService
          profileData['species'] = _especie;
          profileData['breed'] = _racaController.text;
          profileData['weight'] = _pesoController.text;
          profileData['age'] = _idadeController.text;
          profileData['size'] = _porte;
          
          // 🛡️ PRE-REQUEST VALIDATION (Phase 7)
          if (_especie == null || _especie!.isEmpty ||
              _racaController.text.trim().isEmpty ||
              _idadeController.text.trim().isEmpty ||
              _pesoController.text.trim().isEmpty ||
              _porte == null || _porte!.isEmpty) {
              
              if (mounted) {
                  Navigator.pop(context); // loading
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Complete os dados do perfil do pet para gerar o cardápio."),
                          backgroundColor: AppDesign.error,
                      )
                  );
              }
              return;
          }
          
          final request = MealPlanRequest(
              petId: widget.existingProfile?.petName ?? _nameController.text.trim(),
              profileData: profileData,
              mode: config['mode'],
              startDate: config['startDate'],
              endDate: config['endDate'],
              locale: Localizations.localeOf(context).toString(),
              dietType: config['dietType'] as PetDietType,
              otherNote: config['otherNote'] as String?,
              source: 'PetProfile', // Authorized Source
          );

          await ref.read(petMenuGeneratorProvider).generateAndSave(request);


          if (mounted) {
              Navigator.pop(context); // loading
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.petMenuSuccess), backgroundColor: AppDesign.petPink)
              );
              
              // Update status
              _loadMealPlanStatus();
              
              // Open Weekly Menu
              Navigator.push(context, MaterialPageRoute(builder: (_) => WeeklyMenuScreen(
                  currentWeekPlan: [],
                  generalGuidelines: '',
                  petName: widget.existingProfile?.petName ?? _nameController.text,
                  raceName: _racaController.text,
              )));
          }
      } catch (e) {
         if (mounted) {
             Navigator.pop(context); // loading
             ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text('Erro: $e'), backgroundColor: AppDesign.error)
             );
         }
      }
  }

  Widget _buildWeeklyPlanSection() {
    return Container(
       padding: const EdgeInsets.all(16),
       decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
       ),
       child: Column(
          children: [
              const Icon(Icons.restaurant_menu, size: 48, color: AppDesign.petPink),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.petWeeklyPlanTitle,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Visualize o histórico completo, lista de compras e gere novos cardápios personalizados.',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _lastMealPlanDate != null ? AppDesign.petPink.withOpacity(0.1) : Colors.white10,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _lastMealPlanDate != null ? AppDesign.petPink.withOpacity(0.3) : Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _lastMealPlanDate != null ? Icons.check_circle : Icons.pending,
                      size: 14,
                      color: _lastMealPlanDate != null ? AppDesign.petPink : Colors.white38,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _lastMealPlanDate != null 
                        ? 'Atualizado em ${DateFormat('dd/MM/yyyy').format(_lastMealPlanDate!)}'
                        : 'Nenhum cardápio ativo',
                      style: GoogleFonts.poppins(
                        color: _lastMealPlanDate != null ? AppDesign.petPink : Colors.white38,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Button Open Menu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                   icon: const Icon(Icons.calendar_month, color: Colors.white),
                   label: Text(AppLocalizations.of(context)!.petViewMenu ?? 'Ver Cardápio'),
                   style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                   ),
                   onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => WeeklyMenuScreen(
                          currentWeekPlan: [],
                          generalGuidelines: '',
                          petName: widget.existingProfile?.petName ?? _nameController.text,
                          raceName: _racaController.text,
                      )));
                   },
                ),
              ),
              const SizedBox(height: 12),
              
              // Button Generate
              Consumer(
                builder: (context, ref, child) {
                   return SizedBox(
                     width: double.infinity,
                     child: ElevatedButton.icon(
                        icon: const Icon(Icons.auto_awesome, color: Colors.black),
                        label: Text(AppLocalizations.of(context)!.petGenerateWeeklyMenu),
                        style: ElevatedButton.styleFrom(
                           backgroundColor: AppDesign.petPink,
                           foregroundColor: Colors.black,
                           padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () => _handleGenerateTap(context, ref),
                     ),
                   );
                }
              ),
          ],
       )
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
                              decoration: BoxDecoration(color: AppDesign.petPink.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                              child: Text(hora, style: GoogleFonts.poppins(color: AppDesign.petPink, fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(titulo, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15))),
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
                      padding: const EdgeInsets.only(left: 48),
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
                              weightStatus.getRecommendation(AppLocalizations.of(context)!),
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
          strings: AppLocalizations.of(context)!,
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
            content: Text(AppLocalizations.of(context)!.errorAddingExam(e.toString())),
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
          SnackBar(
            content: Text(AppLocalizations.of(context)!.ocrSuccess),
            backgroundColor: AppDesign.petPink,
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
        child: CircularProgressIndicator(color: AppDesign.petPink),
      ),
    );
    
    try {
      final locale = Localizations.localeOf(context).toString();
      
      // Direct language detection for lab exam explanations
      String languageInstruction = "Responda em Português do Brasil.";
      String languageName = "Portuguese-BR";
      
      if (locale.startsWith('en')) {
          languageName = "English";
          languageInstruction = "Respond in English. Translate all medical terms.";
      } else if (locale.startsWith('es')) {
          languageName = "Spanish";
          languageInstruction = "Responda en Español. Traduzca todos los términos médicos.";
      }

      final explanation = await _labExamService.generateExplanation(
          exam, 
          languageName: languageName, 
          languageInstruction: languageInstruction
      );
      
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
            content: Text(AppLocalizations.of(context)!.errorGeneratingExplanation(e.toString())),
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
        title: Text(AppLocalizations.of(context)!.examDeleteTitle, style: GoogleFonts.poppins(color: Colors.white)),
        content: Text(
          AppLocalizations.of(context)!.examDeleteContent,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(color: Colors.white54)),
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
          
          final l10n = AppLocalizations.of(context)!;
          _nivelAtividade = b.nivelAtividade ?? l10n.petActivityModerate;
          _statusReprodutivo = b.statusReprodutivo ?? l10n.petNeutered;
          _frequenciaBanho = b.frequenciaBanho ?? l10n.petBathBiweekly;
          
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
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.petChangesDiscarded)));
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
       builder: (_) => PartnersHubScreen(
         isSelectionMode: true,
         petId: widget.existingProfile?.petName ?? _nameController.text.trim(),
         petName: _nameController.text.trim(),
       )
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
        // 🚀 V68: DIRECT PDF GENERATION - NO FILTER MODAL
        // User wants the complete medical record immediately
        debugPrint('[PDF_FULL] Generating complete report for ${_nameController.text.trim()}');
        
        // 🛡️ V72: HIVE FLUSH - Ensure all data is persisted before PDF generation
        try {
          final petsBox = Hive.box('box_pets_master');
          await petsBox.flush();
          debugPrint('✅ [V72] Hive box flushed - data synchronized');
        } catch (e) {
          debugPrint('⚠️ [V72] Hive flush warning: $e');
        }
        
        
        // 🛡️ V73: EXPLICIT MEAL PLAN EXTRACTION (Pre-Isolate)
        // Force load meal plan data before PDF generation to prevent null reference in isolate
        Map<String, dynamic>? mealPlanData;
        try {
          final petsBox = Hive.box('box_pets_master');
          final petData = petsBox.get(_nameController.text.trim().toLowerCase());
          
          if (petData != null && petData is Map) {
            final rawData = Map<String, dynamic>.from(petData);
            if (rawData.containsKey('rawAnalysis') && rawData['rawAnalysis'] != null) {
              final analysis = rawData['rawAnalysis'] as Map;
              if (analysis.containsKey('plano_semanal')) {
                mealPlanData = Map<String, dynamic>.from(analysis);
                debugPrint('✅ [V73] Meal plan extracted from rawAnalysis: ${analysis['plano_semanal']?.length ?? 0} days');
              } else {
                debugPrint('⚠️ [V73] No meal plan found in rawAnalysis');
              }
            } else {
              debugPrint('⚠️ [V73] No rawAnalysis found for pet');
            }
          }
        } catch (e) {
          debugPrint('❌ [V73] Error extracting meal plan from rawAnalysis: $e');
        }
        
        // 🛡️ V74: INDEPENDENT MEAL PLAN SEARCH (Secondary Source)
        // Search in weekly_meal_plans box as fallback/primary source
        try {
          final mealPlanBox = Hive.box<WeeklyMealPlan>('weekly_meal_plans');
          final petPlans = mealPlanBox.values.where((plan) => plan.petId == _nameController.text.trim()).toList();
          
          if (petPlans.isNotEmpty) {
            // Get most recent plan
            petPlans.sort((a, b) => b.startDate.compareTo(a.startDate));
            final latestPlan = petPlans.first;
            
            debugPrint('✅ [V74] Found ${petPlans.length} meal plan(s) in weekly_meal_plans box');
            debugPrint('✅ [V74] Using latest plan: ${latestPlan.id} (${latestPlan.startDate} to ${latestPlan.endDate})');
            
            // Convert WeeklyMealPlan to rawAnalysis format if not already present
            if (mealPlanData == null || !mealPlanData.containsKey('plano_semanal')) {
              // Group meals by day of week
              final dayGroups = <int, List<Map<String, dynamic>>>{};
              for (var meal in latestPlan.meals) {
                final dayKey = meal.dayOfWeek;
                if (!dayGroups.containsKey(dayKey)) {
                  dayGroups[dayKey] = [];
                }
                dayGroups[dayKey]!.add({
                  'hora': meal.time,
                  'titulo': meal.title,
                  'descricao': meal.description,
                  'quantidade': meal.quantity,
                });
              }
              
              // Convert to plano_semanal format (sorted by day)
              final planoDias = dayGroups.entries.toList()
                ..sort((a, b) => a.key.compareTo(b.key));
              
              final planoSemanal = planoDias.map((entry) => {
                'dia': entry.key,
                'refeicoes': entry.value,
              }).toList();
              
              mealPlanData = {
                'plano_semanal': planoSemanal,
                'tipo_dieta': latestPlan.dietType,
                'data_inicio_semana': latestPlan.startDate.toIso8601String(),
              };
              debugPrint('✅ [V74] Converted WeeklyMealPlan to rawAnalysis format: ${planoSemanal.length} days');
            }
          } else {
            debugPrint('⚠️ [V74] No meal plans found in weekly_meal_plans box for pet: ${_nameController.text.trim()}');
          }
        } catch (e) {
          debugPrint('❌ [V74] Error searching weekly_meal_plans box: $e');
        }
        
        // Use extracted meal plan data or current raw analysis
        final finalRawAnalysis = mealPlanData ?? _currentRawAnalysis;
        
        if (finalRawAnalysis != null && finalRawAnalysis.containsKey('plano_semanal')) {
          debugPrint('🟢 [V74] MEAL PLAN READY FOR PDF: ${finalRawAnalysis['plano_semanal']?.length ?? 0} days');
        } else {
          debugPrint('🔴 [V74] NO MEAL PLAN DATA - PDF will show "not defined" message');
        }
        
        final exportService = ExportService();
        
        // Construct current profile from screen data (freshest state)
        final profile = PetProfileExtended(
            petName: _nameController.text.trim(),
            especie: _especie,
            raca: PetProfileExtended.normalizeBreed(_racaController.text, _especie),
            idadeExata: _idadeController.text.trim().isEmpty ? null : _idadeController.text.trim(),
            pesoAtual: double.tryParse(_pesoController.text.trim()),
            pesoIdeal: double.tryParse(_pesoIdealController.text.trim()),
            nivelAtividade: _nivelAtividade,
            statusReprodutivo: _statusReprodutivo,
            sex: _sexo,
            alergiasConhecidas: _alergiasConhecidas,
            preferencias: _preferencias,
            restricoes: _restricoes,
            dataUltimaV10: _dataUltimaV10,
            dataUltimaAntirrabica: _dataUltimaAntirrabica,
            frequenciaBanho: _frequenciaBanho,
            linkedPartnerIds: _linkedPartnerIds,
            partnerNotes: _partnerNotes,
            weightHistory: _weightHistory,
            labExams: _labExams.map((e) => e.toJson()).toList(),
            woundAnalysisHistory: _woundHistory,
            historicoAnaliseFeridas: _historicoAnaliseFeridas, // 🛡️ V_FIX: Pass structured history
            analysisHistory: _analysisHistory,
            observacoesIdentidade: _observacoesIdentidade,
            observacoesSaude: _observacoesSaude,
            observacoesNutricao: _observacoesNutricao,
            observacoesGaleria: _observacoesGaleria,
            observacoesPrac: _observacoesPrac,
            lastUpdated: DateTime.now(),
            imagePath: _profileImage?.path ?? _initialImagePath,
            rawAnalysis: finalRawAnalysis, // V74: Use meal plan from both sources
            reliability: _reliability,
            porte: _porte,
        );

        // V68: ALL SECTIONS ENABLED BY DEFAULT (Complete Medical Record)
        final allSectionsEnabled = {
          'identity': true,
          'health': true,
          'nutrition': true,
          'vaccines': true,
          'exams': true,
          'wounds': true,
          'weight': true,
          'partners': true,
          'gallery': true,
          'prac': true,
          'analysis': true,
          'meal_plan': true,
          'observations': true,
        };

        debugPrint('[PDF_FULL] Total data domains: ${allSectionsEnabled.length}');

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PdfPreviewScreen(
              title: '${AppLocalizations.of(context)!.pdfReportTitle} - ${profile.petName}',
              buildPdf: (format) async {
                final pdf = await PetPdfGenerator().generateReport(
                  profile: profile,
                  strings: AppLocalizations.of(context)!,
                  manualGallery: _attachments['gallery'], // Pass manual gallery
                );
                return pdf.save();
              },
            ),
          ),
        );
    } catch (e) {
        debugPrint('❌ [PDF_FULL] Error generating complete report: $e');
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${AppLocalizations.of(context)!.pdfError} $e'), 
                  backgroundColor: Colors.red
                ),
            );
        }
    }
  }
  String _localizeValue(String? value, {bool isReliability = false}) {
    if (value == null) return AppLocalizations.of(context)!.petNotIdentified;
    
    final v = value.trim().toLowerCase();
    final strings = AppLocalizations.of(context)!;

    // Standard Null/NA checks
    if (v == 'não informado' || v == 'not informed' || v == 'no informado' || v == 'n/a' || v == 'uninformed' || v == 'none' || v == 'nenhum' || v == 'ninguno') return strings.petNotOffice;
    if (v == 'sem diagnóstico' || v == 'no diagnosis' || v == 'sin diagnóstico') return strings.petDiagnosisDefault;

    // Partner Categories
    if (v == 'todos' || v == 'all') return strings.partnersFilterAll;
    if (v.contains('veterinário') || v.contains('veterinário') || v.contains('veterinarian')) return strings.partnersFilterVet;
    if (v.contains('pet shop')) return strings.partnersFilterPetShop;
    if (v.contains('farmácia') || v.contains('pharmacy')) return strings.partnersFilterPharmacy;
    if (v.contains('banho') || v.contains('grooming') || v.contains('higiene') || v.contains('bath')) return strings.partnersFilterGrooming;
    if (v.contains('hotel') || v.contains('hotéis')) return strings.partnersFilterHotel;
    if (v.contains('lab') || v.contains('laboratório') || v.contains('laboratory')) return strings.partnersFilterLab;

    if (isReliability) {
      if (v.contains('baixa') || v.contains('low') || v.contains('baja')) return strings.petReliabilityLow;
      if (v.contains('média') || v.contains('media') || v.contains('medium')) return strings.petReliabilityMedium;
      if (v.contains('alta') || v.contains('high')) return strings.petReliabilityHigh;
    }

    // Activity Levels
    if (v.contains('sedentário') || v.contains('baixo') || v.contains('low')) return strings.petActivityLow;
    if (v.contains('moderado') || v.contains('moderate') || v.contains('médio') || v.contains('meio')) return strings.petActivityModerate;
    if (v.contains('ativo') || v.contains('alta') || v.contains('alto') || v.contains('high')) return strings.petActivityHigh;
    if (v.contains('atleta') || v.contains('athlete')) return strings.petActivityAthlete;

    // Reproductive Status
    if (v.contains('castrado') || v.contains('neutered')) return strings.petNeutered;
    if (v.contains('inteiro') || v.contains('intacto') || v.contains('intact') || v.contains('entero')) return strings.petIntact;

    // Bath Frequency
    if (v.contains('semanal') || v.contains('weekly')) return strings.petBathWeekly;
    if (v.contains('quinzenal') || v.contains('biweekly') || v.contains('bi-weekly')) return strings.petBathBiweekly;
    if (v.contains('mensal') || v.contains('monthly')) return strings.petBathMonthly;

    // General Not Identified/Estimated/Informed
    if (v.contains('não identificada') || v.contains('not identified') || v.contains('no identificado')) return strings.petNotIdentified;
    if (v.contains('não estimada') || v.contains('not estimated') || v.contains('no estimado')) return strings.petNotEstimated;
    
    // Model Fallbacks
    if (v.contains('consulte veterinário') || v.contains('consult a veterinarian') || v.contains('consulte al veterinario')) return strings.petConsultVet;
    if (v.contains('hemograma') || v.contains('blood count')) return strings.petHemogramaCheckup;
    if (v.contains('reforço positivo') || v.contains('positive reinforcement') || v.contains('refuerzo positivo')) return strings.petPositiveReinforcement;
    if (v.contains('brinquedos interativos') || v.contains('interactive toys') || v.contains('juguetes interactivos')) return strings.petInteractiveToys;
    if (v.contains('consulte um vet') || v.contains('consult a vet') || v.contains('consulte a un vet')) return strings.petConsultVetCare;

    // Size
    if (v.contains('pequeno') || v.contains('small')) return strings.petSizeSmall;
    if (v.contains('médio') || v.contains('medium') || v.contains('mediano')) return strings.petSizeMedium;
    if (v.contains('grande') || v.contains('large')) return strings.petSizeLarge;
    if (v.contains('gigante') || v.contains('giant')) return strings.petSizeGiant;

    // Coat Type
    if (v.contains('curto') || v.contains('short') || v.contains('corto')) return strings.petCoatShort;
    if (v.contains('longo') || v.contains('long') || v.contains('largo')) return strings.petCoatLong;
    if (v.contains('duplo') || v.contains('double') || v.contains('doble')) return strings.petCoatDouble;
    if (v.contains('duro') || v.contains('wire')) return strings.petCoatWire;
    if (v.contains('encaracolado') || v.contains('curly') || v.contains('rizado')) return strings.petCoatCurly;

    return value;
  }

  // ===========================================================================
  // 🐾 NEW PROFILE DESIGN (MODERN HIERARCHY)
  // ===========================================================================

  Widget _buildProfileLayout() {
    return Container(
      color: AppDesign.backgroundDark,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildProfileHeader(),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                _buildOrganizedCards(),
                const SizedBox(height: 120),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      stretch: true,
      backgroundColor: AppDesign.backgroundDark,
      elevation: 0,
      leading: widget.onCancel != null 
          ? IconButton(icon: const Icon(Icons.close, color: AppDesign.petPink), onPressed: widget.onCancel)
          : IconButton(icon: const Icon(Icons.arrow_back, color: AppDesign.petPink), onPressed: () => Navigator.pop(context)),
      actions: [
         PdfActionButton(onPressed: _generatePetReport),
         if (widget.onDelete != null)
           IconButton(
             icon: const Icon(Icons.delete_outline, color: Colors.red),
             onPressed: _confirmDelete,
           ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background Gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppDesign.petPink.withOpacity(0.2),
                    AppDesign.backgroundDark,
                  ],
                ),
              ),
            ),
            // Content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                _buildProfileImageHeader(),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    _nameController.text.isEmpty ? l10n.petDefaultName : _nameController.text,
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppDesign.petPink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_especie ?? ''} • ${_racaController.text.isEmpty ? l10n.petBreedUnknown : _racaController.text}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppDesign.petPink,
                    ),
                  ),
                ),
                if (_idadeController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _idadeController.text,
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.white38),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildOrganizedCards() {
    return Column(
      children: [
        _buildProfileCard(
          title: l10n.petIdentity,
          icon: Icons.pets_rounded,
          initiallyExpanded: true,
          children: _buildIdentityFields(),
        ),
        const SizedBox(height: 16),
        _buildProfileCard(
          title: l10n.petNutrition,
          icon: Icons.restaurant_rounded,
          children: _buildNutritionFields(),
        ),
        _buildProfileCard(
          title: l10n.petHealth,
          icon: Icons.favorite_rounded,
          children: _buildHealthFields(),
        ),
        _buildProfileCard(
          title: l10n.petPartners,
          icon: Icons.handshake_rounded,
          children: [_buildPartnersTabContent()],
        ),
        _buildProfileCard(
            title: l10n.petAnalysisResults,
            icon: Icons.analytics_outlined,
            children: [_buildAnalysisTabContent()],
        ),
        _buildProfileCard(
            title: l10n.petGallery,
            icon: Icons.camera_alt_rounded,
            children: [_buildGalleryTabContent()],
        ),
      ],
    );
  }

  Widget _buildProfileCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    List<Widget>? childrens, // Fallback for specific tab contents
    bool initiallyExpanded = true, // 🛡️ V126: Open by default for better UX
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppDesign.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        leading: Icon(icon, color: AppDesign.petPink, size: 22),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        iconColor: AppDesign.petPink,
        collapsedIconColor: Colors.white30,
        children: childrens ?? children,
      ),
    );
  }

  // Wrappers to extract fields without ListView
  List<Widget> _buildIdentityFields() {
    return [
       // Removido Header de imagem aqui pois já está no Topo
       const SizedBox(height: 8),
       _buildIdentityTabContent(),
    ];
  }

  List<Widget> _buildHealthFields() {
     return [_buildHealthTabContent()];
  }

  List<Widget> _buildNutritionFields() {
     return [_buildNutritionTabContent()];
  }

  // Helper navigators
  void _openMealPlan() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WeeklyMenuScreen(
          petName: widget.existingProfile?.petName ?? _nameController.text,
          raceName: _racaController.text,
        ),
      ),
    );
  }

  void _openEventHistory() {
     Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PetEventHistoryScreen(
            petId: widget.existingProfile?.petName ?? _nameController.text,
            petName: widget.existingProfile?.petName ?? _nameController.text,
          ),
        ),
    );
  }

  // --- WOUND ANALYSIS RICH DISPLAY ---

  Widget _buildStructuredWoundCard(AnaliseFeridaModel analysis) {
      Color severityColor;
      // Map Risk Levels to Colors
      final risk = (analysis.nivelRisco ?? 'Green').toLowerCase();
      if (risk.contains('red') || risk.contains('vermelho') || risk.contains('alta')) {
          severityColor = AppDesign.error;
      } else if (risk.contains('yellow') || risk.contains('amarelo') || risk.contains('média')) {
          severityColor = Colors.orange;
      } else {
          severityColor = AppDesign.success;
      }
      
      final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(analysis.dataAnalise);

      return InkWell(
        onTap: () {
             _showWoundDetails(analysis);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
               ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                      File(analysis.imagemRef),
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_,__,___) => Container(width: 60, height: 60, color: Colors.white10, child: const Icon(Icons.image_not_supported, size: 20, color: Colors.white30)),
                  ),
               ),
               const SizedBox(width: 12),
               Expanded(
                   child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                            Row(children: [
                                Container(
                                    width: 8, height: 8,
                                    decoration: BoxDecoration(color: severityColor, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(
                                    analysis.diagnosticosProvaveis.isNotEmpty ? analysis.diagnosticosProvaveis.first : 'Sem diagnóstico',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    maxLines: 1, overflow: TextOverflow.ellipsis
                                )),
                            ]),
                            const SizedBox(height: 4),
                            Text(dateStr, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                            const SizedBox(height: 4),
                            Text(
                                analysis.recomendacao ?? '', 
                                maxLines: 2, 
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white70, fontSize: 11)
                            )
                       ]
                   )
               ),
               const Icon(Icons.chevron_right, color: Colors.white30)
            ],
          ),
        ),
      );
  }

  void _showWoundDetails(AnaliseFeridaModel analysis) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
            backgroundColor: AppDesign.backgroundDark,
            insetPadding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        if (File(analysis.imagemRef).existsSync())
                             Image.file(File(analysis.imagemRef), height: 250, width: double.infinity, fit: BoxFit.cover),
                        
                        Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Diagnóstico Detalhado', style: GoogleFonts.poppins(color: AppDesign.petPink, fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 16),
                                
                                _buildDetailRow('Nível de Risco', analysis.nivelRisco, color: Colors.white),
                                _buildDetailRow('Data', DateFormat('dd/MM/yyyy HH:mm').format(analysis.dataAnalise), color: Colors.white),
                                
                                const Divider(color: Colors.white12, height: 24),
                                
                                if (analysis.diagnosticosProvaveis.isNotEmpty) ...[
                                    const Text('Causas Prováveis:', style: TextStyle(color: Colors.white60, fontSize: 12)),
                                    const SizedBox(height: 4),
                                    ...analysis.diagnosticosProvaveis.map((c) => Padding(padding: const EdgeInsets.only(bottom: 2), child: Text('• $c', style: const TextStyle(color: Colors.white)))),
                                    const SizedBox(height: 12),
                                ],
                                
                                if (analysis.descricaoVisual != null) ...[
                                    const Text('Descrição Visual:', style: TextStyle(color: Colors.white60, fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Text(analysis.descricaoVisual!, style: const TextStyle(color: Colors.white)),
                                    const SizedBox(height: 12),
                                ],
                                
                                if (analysis.caracteristicas != null) ...[
                                    const Text('Características:', style: TextStyle(color: Colors.white60, fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Text(analysis.caracteristicas!, style: const TextStyle(color: Colors.white)),
                                    const SizedBox(height: 12),
                                ],

                                const Text('Recomendação:', style: TextStyle(color: Colors.white60, fontSize: 12)),
                                const SizedBox(height: 4),
                                Text(analysis.recomendacao, style: const TextStyle(color: Colors.white)),

                            ]),
                        ),
                        
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Fechar', style: TextStyle(color: Colors.white54))
                        )
                    ]
                )
            )
        )
      );
  }

  Widget _buildDetailRow(String label, String value, {Color color = Colors.white}) {
      return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Text('$label: ', style: const TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.bold)),
                  Expanded(child: Text(value, style: TextStyle(color: color, fontSize: 13))),
              ]
          )
      );
  }

}

