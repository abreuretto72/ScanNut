import 'dart:async';
import '../../../partners/presentation/partner_agenda_screen.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:scannut/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/file_upload_service.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../core/enums/scannut_mode.dart';
import '../../models/pet_profile_extended.dart';
import '../../services/pet_pdf_generator.dart'; // 🛡️ NEW PDF GENERATOR
import '../../models/analise_ferida_model.dart'; // 🛡️ Import for Health History
import '../../services/pet_event_service.dart';
import '../../models/pet_event.dart';

import '../../services/pet_vision_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../../core/utils/permission_helper.dart';

import '../../../partners/presentation/partners_hub_screen.dart'; // Add this line
// Add this line
import '../../services/pet_menu_generator_service.dart';
import '../../services/meal_plan_service.dart';
import '../../models/meal_plan_request.dart';
import 'pet_menu_filter_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/partner_service.dart';
import '../../../../core/models/partner_model.dart';
import '../../../../core/widgets/pdf_action_button.dart';
import '../../../../core/services/export_service.dart';
import '../../../../core/widgets/pdf_preview_screen.dart';
import '../../../../core/widgets/app_pdf_icon.dart';
import '../../models/lab_exam.dart';
import '../../services/lab_exam_service.dart';
import 'lab_exams_section.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/pet_weight_database.dart';
import '../../services/pet_profile_service.dart';

import 'weekly_menu_screen.dart';
import '../../models/weekly_meal_plan.dart';
import '../pet_event_history_screen.dart'; // Added
// Added

import 'profile_fragments/identity_fragment.dart';
import 'profile_fragments/nutrition_fragment.dart';
import 'profile_fragments/health_fragment.dart';
import 'profile_fragments/partners_fragment.dart';
import 'profile_fragments/analysis_results_fragment.dart';
import 'profile_fragments/gallery_fragment.dart';
import 'profile_fragments/plans_fragment.dart'; // V200: Added

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
    super.key, 
    this.existingProfile, 
    this.petData,
    required this.onSave, 
    this.onCancel, 
    this.onDelete, 
    this.isNewEntry = false,
    this.initialTabIndex = 0,
  });

  final int initialTabIndex;

  @override
  State<EditPetForm> createState() => _EditPetFormState();
}

class _EditPetFormState extends State<EditPetForm> 
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  String? _petId;
  final _visionService = PetVisionService();

  // Controllers
  late TextEditingController _nameController;
  String? _especie; // Seleção: Cão ou Gato
  late TextEditingController _racaController;
  late TextEditingController _idadeController;
  late TextEditingController _pesoController;
  late TextEditingController _microchipController;
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
  List<PartnerModel> _availablePartners = []; // V_FIX: Store all partners
  String _partnerFilter = 'Todos'; // V_FIX: Filter state
  List<Map<String, dynamic>> _weightHistory = [];
  List<LabExam> _labExams = []; // Lab exams with OCR
  List<Map<String, dynamic>> _woundHistory = []; // Local state for wound analysis history

  // Cumulative Observations (with timestamps)
  String _observacoesIdentidade = '';
  String _observacoesSaude = '';
  String _observacoesNutricao = '';
  String _observacoesGaleria = '';
  String _observacoesPrac = '';
  
  // Plans & Insurance (V200)
  Map<String, dynamic>? _healthPlan;
  Map<String, dynamic>? _assistancePlan;
  Map<String, dynamic>? _funeralPlan;
  Map<String, dynamic>? _lifeInsurance;
  final TextEditingController _observacoesPlanosController = TextEditingController();

  // File Upload
  List<Map<String, dynamic>> _analysisHistory = [];
  final FileUploadService _fileService = FileUploadService();
  String? _profileUrl; // V_FIX: Added missing variable
  final Map<String, List<File>> _attachments = {
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
  
  // --- REACTIVE SAVE STATE ---
  _SaveStatus _saveStatus = _SaveStatus.idle;

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
        setState(() => _saveStatus = _SaveStatus.saving);
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
        id: _petId!,
        petName: _nameController.text.trim(),
        especie: _especie,
        raca: PetProfileExtended.normalizeBreed(_racaController.text, _especie),
        idadeExata: _idadeController.text.trim().isEmpty ? null : _idadeController.text.trim(),
        pesoAtual: double.tryParse(_pesoController.text.trim().replaceAll(',', '.')),
        pesoIdeal: double.tryParse(_pesoIdealController.text.trim().replaceAll(',', '.')),
        microchip: _microchipController.text.trim().isEmpty ? null : _microchipController.text.trim(),
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
        healthPlan: _healthPlan,
        assistancePlan: _assistancePlan,
        funeralPlan: _funeralPlan,
        lifeInsurance: _lifeInsurance,
        observacoesPlanos: _observacoesPlanosController.text,
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

       if (mounted) {
           setState(() => _saveStatus = _SaveStatus.success);
           Future.delayed(const Duration(seconds: 2), () {
               if (mounted && _saveStatus == _SaveStatus.success) {
                   setState(() => _saveStatus = _SaveStatus.idle);
               }
           });
       }
       
    } catch (e) {
       debugPrint("❌ Save error: $e");
       if (mounted) {
            setState(() => _saveStatus = _SaveStatus.error);
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
    _petId = existing?.id ?? const Uuid().v4();
    
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
        }).catchError((e) {
             debugPrint('Image recovery failed: $e');
        });
      }
    }

    _tabController = TabController(length: 7, vsync: this, initialIndex: widget.initialTabIndex);
    
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
    _microchipController = TextEditingController(text: existing?.microchip ?? '');
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
      _healthPlan = existing.healthPlan;
      _assistancePlan = existing.assistancePlan;
      _funeralPlan = existing.funeralPlan;
      _lifeInsurance = existing.lifeInsurance;
      _observacoesPlanosController.text = existing.observacoesPlanos;
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
    _microchipController.addListener(_onUserTyping);
    _alergiasController.addListener(_onUserTyping);
    _preferenciasController.addListener(_onUserTyping);
    _restricoesController.addListener(_onUserTyping);
    _observacoesPlanosController.addListener(_onUserTyping);
    debugPrint('⏱️ [PERF_FORM] initState End: ${sw.elapsedMilliseconds}ms');
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
          });
          // Immediate Reactive Save for AI Data
          _saveNow(silent: true);
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
        // 🛡️ FIX: Always reload external data (History, Exams) to prevent overwriting
        // updates made by other screens (like Analysis) while this form was in background.
        // Trusted Source: DISK (Hive).
        _reloadFreshData();
        debugPrint('✅ Data refreshed from disk on resume.');
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



  @override
  Widget build(BuildContext context) {
    // Safety check for analysis overlay
    final bool showOverlay = _isAnalyzingPet;

    return Stack(children: [
      Scaffold(
        backgroundColor: AppDesign.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppDesign.backgroundDark,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppDesign.textPrimaryDark),
            onPressed: () => _handleWillPop().then((canPop) {
                if (canPop) Navigator.of(context).pop();
            }),
          ),
          title: Text(
              widget.existingProfile == null 
                  ? AppLocalizations.of(context)!.petNew 
                  : AppLocalizations.of(context)!.petEdit,
              style: const TextStyle(color: AppDesign.textPrimaryDark)
          ),
          actions: [_buildActionButtons()],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: AppDesign.petPink,
            labelColor: AppDesign.petPink,
            unselectedLabelColor: AppDesign.textSecondaryDark,
            tabs: [
              Tab(text: AppLocalizations.of(context)!.sectionIdentity),
              const Tab(text: 'Análises'),
              Tab(text: AppLocalizations.of(context)!.sectionHealth),
              Tab(text: AppLocalizations.of(context)!.sectionNutrition),
              const Tab(text: 'Parceiros'),
              const Tab(text: 'Galeria'),
              Tab(text: AppLocalizations.of(context)!.plansTabTitle),
            ],
          ),
        ),
        body: Column(
            children: [
                const SizedBox(height: 20),
                _buildProfileImageHeader(),
                Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildIdentityTabContent(),
                        _buildAnalysisTabContent(),
                        _buildHealthTabContent(),
                        _buildNutritionTabContent(),
                        _buildPartnersTabContent(),
                        _buildGalleryTabContent(),
                        _buildPlansTabContent(),
                      ],
                    )
                )
            ]
        ),
        bottomNavigationBar: null, // Reactive Auto-Save: No manual button needed
      ),
      
      if (showOverlay)
         Container(
             color: Colors.black54,
             child: const Center(child: CircularProgressIndicator(color: AppDesign.petPink))
         ),
         
      // Auto-Save Indicator (Top Right)
      Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          right: 16,
          child: _buildAutoSaveIndicator(),
      ),
    ]);
  }

  Future<void> _savePetProfile() async {
      await _saveNow(silent: false);
  }


  Future<void> _loadLinkedPartners() async {
    // Load ALL available partners (not just linked ones)
    try {
        final partnerService = PartnerService();
        await partnerService.init();
        final all = partnerService.getAllPartners();
        
        if (mounted) {
          setState(() {
            _availablePartners = all; // Always load all available partners
            
            // Filter linked partners
            _linkedPartnerModels = all.where((p) => _linkedPartnerIds.contains(p.id)).toList();
          });
          
          debugPrint('✅ Loaded ${all.length} available partners, ${_linkedPartnerModels.length} linked');
        }
    } catch (e) {
        debugPrint('❌ Error loading partners: $e');
        if (mounted) {
          setState(() {
            _availablePartners = [];
            _linkedPartnerModels = [];
          });
        }
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
    // --- Helpers for Attachments ---
    bool _isIdentity(String n) => n.startsWith('identity_');
    bool _isExam(String n) => n.startsWith('health_exams_');
    bool _isPrescription(String n) => n.startsWith('health_prescriptions_');
    bool _isVaccine(String n) => n.startsWith('health_vaccines_');
    bool _isNutrition(String n) => n.startsWith('nutrition_');
    bool _isProfilePic(String n) => n.startsWith('profile_pic');
    
    bool _isGallery(String n) => n.startsWith('gallery_') || n.startsWith('profile_pic') || n.startsWith('health_analysis_');

    // Helper to Deduplicate (Aggressive V143) promoted to class method
    List<File> _optimizeList(List<File> rawList) {
       final Map<String, File> uniqueMap = {};
       
       debugPrint('🔍 [V143] optimizeList: Processing ${rawList.length} files');
       
       for (var f in rawList) {
          if (!f.existsSync()) continue;
          
          final name = path.basename(f.path);
          final match = RegExp(r'(\d{10,})').firstMatch(name);
          String contentId;
          
          if (match != null) {
              contentId = "ID_${match.group(0)}"; 
          } else {
              contentId = "SIZE_${f.lengthSync()}";
          }

          if (uniqueMap.containsKey(contentId)) {
             final existing = uniqueMap[contentId]!;
             final existingName = path.basename(existing.path);
             
             final isNewOpt = name.toUpperCase().startsWith('OPT_');
             final isOldOpt = existingName.toUpperCase().startsWith('OPT_');
             
             if (isNewOpt && !isOldOpt) {
                 uniqueMap[contentId] = f; 
             }
          } else {
             uniqueMap[contentId] = f;
          }
       }
       
       final result = uniqueMap.values.toList();
       result.sort((a,b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
       return result;
    }

  Future<void> _loadAttachments() async {
    final petName = widget.existingProfile?.petName ?? _nameController.text.trim();
    if (petName.isEmpty) return;

    final allDocs = await _fileService.getMedicalDocuments(petName);
    if (!mounted) return;

    setState(() {
      _attachments['identity'] = _optimizeList(allDocs.where((f) => _isIdentity(path.basename(f.path))).toList());
      _attachments['health_exams'] = _optimizeList(allDocs.where((f) => _isExam(path.basename(f.path))).toList());
      _attachments['health_prescriptions'] = _optimizeList(allDocs.where((f) => _isPrescription(path.basename(f.path))).toList());
      _attachments['health_vaccines'] = _optimizeList(allDocs.where((f) => _isVaccine(path.basename(f.path))).toList());
      _attachments['nutrition'] = _optimizeList(allDocs.where((f) => _isNutrition(path.basename(f.path))).toList());
      
      // Gallery gets the rest (Catch-all)
      _attachments['gallery'] = _optimizeList(allDocs.where((f) => _isGallery(path.basename(f.path))).toList());
      
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
          debugPrint('    Identity: ${_isIdentity(name)}, Prescription: ${_isPrescription(name)}, Vaccine: ${_isVaccine(name)}');
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
    // 🛡️ CRITICAL FIX: Context-Aware Logic
    // If user is on Health Tab (index 1), this is a CLINICAL ANALYSIS, NOT a profile pic change.
    final isHealthMode = _tabController.index == 1;

    String petName = _nameController.text.trim();
    if (petName.isEmpty) petName = "New_Pet_${DateTime.now().millisecondsSinceEpoch}";
    
    if (isHealthMode) {
        debugPrint('🛡️ [Context-Aware] Health Tab detected. Processing as CLINICAL ANALYSIS (No Profile Pic Change).');
        try {
            // Save as clinical document
            final permanentPath = await _fileService.saveMedicalDocument(
                file: tempFile, 
                petName: petName, 
                attachmentType: 'health_analysis_source'
            );

            if (permanentPath != null && mounted) {
                 final permFile = File(permanentPath);
                 
                 // Show feedback
                 ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Analisando imagem clínica... A foto de perfil não será alterada.'),
                        backgroundColor: AppDesign.petPink,
                        duration: Duration(seconds: 2),
                    )
                 );

                 // Trigger Analysis directly (bypassing _analyzePetProfile which might be ambiguous)
                 // Or calling it but ensuring it handles 'mode' correctly without side effects logic.
                 // Ideally, we call a dedicated analysis method.
                 // For now, let's reuse _analyzePetProfile but rely on its internal mode check, 
                 // BUT we must ensure IT DOES NOT update UI fields it shouldn't.
                 // _analyzePetProfile calls _updateProfileFromAI.
                 
                 _analyzePetProfile(permFile);
            }
        } catch (e) {
            debugPrint('❌ Error processing clinical image: $e');
        }
        return; // STOP HERE. Do not update _profileImage.
    }

    // --- STANDARD PROFILE PICTURE CHANGE (Identity Tab or Others) ---
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
                });
                _markDirty(); // Trigger Profile Update
                _analyzePetProfile(permFile);
            }
        }
    } catch (e) {
        debugPrint('❌ Critical Error: Failed to secure image: $e');
        // Fallback to temp file
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
                            const SnackBar(content: Text('Nenhum arquivo selecionado'))
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
                const SizedBox(height: 20), // Padding extra
              ],
            ),
          ),
        ),
      ),
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
            const SnackBar(content: Text('Erro ao salvar arquivo'))
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


  Widget _buildIdentityTabContent() {
    return IdentityFragment(
      nameController: _nameController,
      especie: _especie,
      racaController: _racaController,
      idadeController: _idadeController,
      pesoController: _pesoController,
      microchipController: _microchipController,
      porte: _porte,
      sexo: _sexo,
      nivelAtividade: _nivelAtividade,
      statusReprodutivo: _statusReprodutivo,
      reliability: _reliability,
      observacoesIdentidade: _observacoesIdentidade,
      activityOptions: _getLocalizedItems((l) => [
         l.petActivityLow,
         l.petActivityModerate,
         l.petActivityHigh,
         l.petActivityAthlete
      ]),
      attachments: _attachments,
      currentRawAnalysis: _currentRawAnalysis,
      onEspecieChanged: (val) { setState(() => _especie = val); _onUserInteractionGeneric(); },
      onSexoChanged: (val) { setState(() => _sexo = val); _onUserInteractionGeneric(); },
      onPorteChanged: (val) { setState(() => _porte = val); _onUserInteractionGeneric(); },
      onNivelAtividadeChanged: (val) { setState(() => _nivelAtividade = val); _onUserInteractionGeneric(); },
      onStatusReprodutivoChanged: (val) { setState(() => _statusReprodutivo = val); _onUserInteractionGeneric(); },
      onObservacoesChanged: (val) { setState(() => _observacoesIdentidade = val); _onUserTyping(); },
      onUserTyping: _onUserTyping,
      onUserInteractionGeneric: _onUserInteractionGeneric,
      localizeValue: _localizeValue,
      onAddAttachment: () => _addAttachment('identity'),
      onDeleteAttachment: _deleteAttachment,
    );
  }


  Widget _buildHealthTabContent() {
    return HealthFragment(
      dataUltimaV10: _dataUltimaV10,
      dataUltimaAntirrabica: _dataUltimaAntirrabica,
      frequenciaBanho: _frequenciaBanho,
      bathOptions: _getLocalizedItems((l) => [
         l.petBathBiweekly,
         l.petBathWeekly,
         l.petBathMonthly
      ]),
      petId: _petId ?? _nameController.text.trim(),
      species: _especie ?? '',
      labExams: _labExams,
      observacoesSaude: _observacoesSaude,
      onV10DateSelected: (date) { setState(() => _dataUltimaV10 = date); _onUserInteractionGeneric(); },
      onAntirrabicaDateSelected: (date) { setState(() => _dataUltimaAntirrabica = date); _onUserInteractionGeneric(); },
      onFrequenciaBanhoChanged: (val) { setState(() => _frequenciaBanho = val); _onUserInteractionGeneric(); },
      onObservacoesChanged: (value) {
        setState(() => _observacoesSaude = value);
        _onUserTyping();
      },
      attachments: _attachments,
      labExamsSection: LabExamsSection(
        exams: _labExams,
        onAddExam: _addLabExam,
        onDeleteExam: _deleteLabExam,
        onExplainExam: _explainLabExam,
        onMarkDirty: _markDirty,
      ),
      woundAnalysisHistory: _buildWoundAnalysisHistory(),
      onAddAttachmentPrescription: () => _addAttachment('health_prescriptions'),
      onAddAttachmentVaccine: () => _addAttachment('health_vaccines'),
      onDeleteAttachment: _deleteAttachment,
      petName: _nameController.text,
      analysisHistory: _analysisHistory,
      onDeleteAnalysis: _handleDeleteAnalysis,
    );
  }

  Widget _buildNutritionTabContent() {
    return NutritionFragment(
      petId: _petId ?? _nameController.text,
      petName: _nameController.text,
      alergiasController: _alergiasController,
      alergiasConhecidas: _alergiasConhecidas,
      restricoesController: _restricoesController,
      restricoes: _restricoes,
      preferenciasController: _preferenciasController,
      preferencias: _preferencias,
      observacoesNutricao: _observacoesNutricao,
      onAddAlergia: (text) {
        setState(() {
          _alergiasConhecidas.add(text);
          _alergiasController.clear();
        });
        _markDirty();
      },
      onDeleteAlergia: (index) {
        setState(() => _alergiasConhecidas.removeAt(index));
        _markDirty();
      },
      onAddRestricao: (text) {
        setState(() {
          _restricoes.add(text);
          _restricoesController.clear();
        });
        _markDirty();
      },
      onDeleteRestricao: (index) {
        setState(() => _restricoes.removeAt(index));
        _markDirty();
      },
      onAddPreferencial: (text) {
        setState(() {
          _preferencias.add(text);
          _preferenciasController.clear();
        });
        _markDirty();
      },
      onDeletePreferencial: (index) {
        setState(() => _preferencias.removeAt(index));
        _markDirty();
      },
      onObservacoesChanged: (value) {
        setState(() => _observacoesNutricao = value);
        _onUserTyping();
      },
      pesoController: _pesoController,
      raca: _racaController.text,
      porte: _porte,
      attachments: _attachments['nutrition'] ?? [],
      weeklyPlanSection: _buildWeeklyPlanSection(),
      onAddAttachment: () => _addAttachment('nutrition'),
      onDeleteAttachment: _deleteAttachment,
      analysisHistory: _analysisHistory,
      onDeleteAnalysis: _handleDeleteAnalysis,
      onAnalysisSaved: _reloadAnalysisHistory,
    );
  }

  Future<void> _handleDeleteAnalysis(Map<String, dynamic> item) async {
      final petName = _nameController.text.trim();
      if (petName.isEmpty) return;
      
      final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text('Excluir Análise', style: TextStyle(color: Colors.white)),
              content: const Text('Tem certeza que deseja remover esta análise permanentemente?', style: TextStyle(color: Colors.white70)),
              actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar', style: TextStyle(color: Colors.white60))),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir', style: TextStyle(color: Colors.redAccent))),
              ],
          ),
      );

      if (confirm != true) return;

      final petIdOrName = _petId ?? _nameController.text.trim();
      await PetProfileService().removeAnalysisFromHistory(petIdOrName, item);
      setState(() {
          _analysisHistory.removeWhere((a) => a['last_updated'] == item['last_updated']);
      });
      _onUserInteractionGeneric();
  }

  Widget _buildPlansTabContent() {
    return PlansFragment(
      healthPlan: _healthPlan,
      assistancePlan: _assistancePlan,
      funeralPlan: _funeralPlan,
      lifeInsurance: _lifeInsurance,
      observacoesController: _observacoesPlanosController,
      onHealthPlanChanged: (val) { setState(() => _healthPlan = val); _onUserInteractionGeneric(); },
      onAssistancePlanChanged: (val) { setState(() => _assistancePlan = val); _onUserInteractionGeneric(); },
      onFuneralPlanChanged: (val) { setState(() => _funeralPlan = val); _onUserInteractionGeneric(); },
      onLifeInsuranceChanged: (val) { setState(() => _lifeInsurance = val); _onUserInteractionGeneric(); },
      onUserInteraction: _onUserInteractionGeneric,
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
         PdfActionButton(onPressed: _generatePetReport),
      ],
    );
  }

  Widget _buildWoundAnalysisHistory() {
    final woundHistory = _woundHistory; // Legacy
    final structuredHistory = _historicoAnaliseFeridas; // New Structured
    
    if (woundHistory.isEmpty && structuredHistory.isEmpty) {
      return Card(
        color: Colors.white.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(AppLocalizations.of(context)!.petDiseaseHistory),
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
                    const Icon(Icons.info_outline, color: Colors.white54, size: 20),
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
          ),
        ),
      );
    }

    return Card(
      color: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(AppLocalizations.of(context)!.petDiseaseHistory),
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
        ),
      ),
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
                                        child: Image.file(File(imagePath)),
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
                        image: FileImage(File(imagePath)),
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
               

               // 1. Refresh Wound History (Legacy)
               if (data['wound_analysis_history'] != null) {
                   if (mounted) {
                      setState(() {
                          _woundHistory = (data['wound_analysis_history'] as List)
                              .map((e) => Map<String, dynamic>.from(e as Map))
                              .toList();
                      });
                   }
               }
               
               // 2. Load Structured History (Gallery)
               // 🛡️ FIX: Use correct key 'historico_analise_feridas' (snake_case) matching DB
               if (data['historico_analise_feridas'] != null) {
                   try {
                       final list = (data['historico_analise_feridas'] as List)
                           .map((e) => AnaliseFeridaModel.fromJson(Map<String, dynamic>.from(e)))
                           .toList();
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

                // 🛡️ [V_REFRESH] General Analysis History
                final hist = data['analysisHistory'] ?? data['analysis_history'];
                if (hist is List && mounted) {
                    setState(() {
                         _analysisHistory = List<Map<String, dynamic>>.from(
                             hist.map((e) => Map<String, dynamic>.from(e as Map))
                         );
                    });
                }
                
                // 🛡️ [V_REFRESH] Plans & Insurance
                if (mounted) {
                    setState(() {
                        _healthPlan = data['health_plan'];
                        _assistancePlan = data['assistance_plan'];
                        _funeralPlan = data['funeral_plan'];
                        _lifeInsurance = data['life_insurance'];
                        _observacoesPlanosController.text = data['observacoes_planos'] ?? '';
                    });
                }

                debugPrint('HIVE: Dados recarregados e fundidos com sucesso.');
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
          petId: _petId ?? _nameController.text.trim(),
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
      listenOptions: stt.SpeechListenOptions(
        cancelOnError: true,
      ),
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

  Future<void> _generateNewMenu(WidgetRef ref) async {
     if (_nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.petNameRequired)));
        return;
     }

     final result = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => const PetMenuFilterDialog(),
     );

     if (result == null) return; 

     setState(() => _isAnalyzingPet = true);

     try {
         final params = {
            'especie': _especie ?? 'Unknown',
            'raca': _racaController.text,
            'idade_exata': _idadeController.text,
            'peso_atual': _pesoController.text,
            'porte': _porte ?? 'Medium',
            'sex': _sexo ?? 'Unknown',
            'statusReprodutivo': _statusReprodutivo,
            'alergias_conhecidas': _alergiasConhecidas,
            'restricoes': _restricoes,
            'preferencias': _preferencias,
            'nivelAtividade': _nivelAtividade
         };

         final req = MealPlanRequest(
            petId: _nameController.text.trim(),
            mode: result['mode'],
            startDate: result['startDate'],
            endDate: result['endDate'],
            dietType: result['dietType'],
            foodType: result['foodType'] ?? PetFoodType.mixed,
            otherNote: result['otherNote'],
            profileData: params,
            locale: Localizations.localeOf(context).languageCode,
            source: 'PetProfile'
         );
         
         final generator = ref.read(petMenuGeneratorProvider);
         await generator.generateAndSave(req);
         
         final plans = await MealPlanService().getPlansForPet(_nameController.text.trim());
         if (plans.isNotEmpty) {
             final latest = plans.first; 
             setState(() {
                 _lastMealPlanDate = latest.startDate;
                 _currentRawAnalysis ??= {};
                 
                 final allMeals = latest.meals..sort((a,b) {
                     final d = a.dayOfWeek.compareTo(b.dayOfWeek);
                     if (d != 0) return d;
                     return a.time.compareTo(b.time);
                 });

                 _currentRawAnalysis!['plano_semanal'] = allMeals.map((m) => {
                     'dia': m.dayOfWeek,
                     'hora': m.time,
                     'titulo': m.title,
                     'descricao': m.description,
                     'quantidade': m.quantity
                 }).toList();
             });
             
             if (mounted) {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => WeeklyMenuScreen(
                     petId: _petId!,
                     petName: _nameController.text,
                     raceName: _racaController.text,
                     initialTabIndex: 1,
                 )));
             }
         }

     } catch (e) {
         debugPrint('Error generating menu: $e');
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
         }
     } finally {
         if (mounted) setState(() => _isAnalyzingPet = false);
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
                          petId: _petId!,
                          currentWeekPlan: const [],
                          generalGuidelines: '',
                          petName: widget.existingProfile?.petName ?? _nameController.text,
                          raceName: _racaController.text,
                          initialTabIndex: 1,
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
                        onPressed: () => _generateNewMenu(ref),
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
      final savedFile = await File(pickedFile.path).copy('${appDir.path}/$fileName');
      
      final newExam = examTemplate.copyWith(
        id: const Uuid().v4(),
        uploadDate: DateTime.now(),
        filePath: savedFile.path,
        isProcessing: true, // Start processing
      );
      
      setState(() {
        _labExams.add(newExam);
        _markDirty();
      });
      
      // Trigger Analysis
      _explainLabExam(newExam.id);
      
    } catch (e) {
      debugPrint('Error adding lab exam: $e');
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Erro ao adicionar exame: $e'), backgroundColor: AppDesign.error)
         );
      }
    }
  }
  
  Future<void> _explainLabExam(String examId) async {
    final examIndex = _labExams.indexWhere((e) => e.id == examId);
    if (examIndex == -1) return;
    
    // Update state to processing (UI feedback in card)
    setState(() {
      _labExams[examIndex] = _labExams[examIndex].copyWith(isProcessing: true);
    });
    
    try {
      var currentExam = _labExams[examIndex];
      
      // 1. Run OCR if text is missing
      if (currentExam.extractedText == null || currentExam.extractedText!.isEmpty) {
           currentExam = await _labExamService.processExam(currentExam);
           
           // Check for OCR failure (empty text or specific error message from service)
           final text = currentExam.extractedText ?? '';
           if (text.isEmpty || 
               text.contains('Nenhum texto foi detectado') || 
               text.contains('Erro ao extrair')) {
               
               if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(
                           content: Text(AppLocalizations.of(context)!.petNoDocumentsAttached), // Using generic "No docs/text" msg or similar
                           backgroundColor: Colors.orange,
                           duration: const Duration(seconds: 4),
                       )
                   );
                   // Show specific alert for user
                   showDialog(context: context, builder: (_) => AlertDialog(
                       title: const Text('Texto não detectado', style: TextStyle(color: Colors.white)), // Hardcoded fallback or use l10n
                       backgroundColor: Colors.grey[900],
                       content: const Text('Não foi possível ler texto nesta imagem. Se for uma foto de fezes ou lesão para análise visual, utilize a aba "Análises" ou "Feridas". Esta aba ("Exames") é exclusiva para laudos e documentos de texto.', style: TextStyle(color: Colors.white70)),
                       actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendi'))],
                   ));
               }
               
               // Abort AI, save state as not processing
               setState(() {
                   _labExams[examIndex] = currentExam.copyWith(isProcessing: false);
               });
               return;
           }
      }

      final locale = Localizations.localeOf(context).toString();
      String languageInstruction = "Responda em Português do Brasil.";
      String languageName = "Portuguese-BR";
      
      if (locale.startsWith('en')) {
          languageName = "English";
          languageInstruction = "Respond in English. Translate all medical terms.";
      } else if (locale.startsWith('es')) {
          languageName = "Spanish";
          languageInstruction = "Responda en Español. Traduzca todos los términos médicos.";
      }

      // 2. Run AI Explanation
      final explanation = await _labExamService.generateExplanation(
          currentExam, 
          languageName: languageName, 
          languageInstruction: languageInstruction
      );
      
      if (mounted) {
        setState(() {
          _labExams[examIndex] = currentExam.copyWith(
              aiExplanation: explanation,
              isProcessing: false 
          );
        });
        _onUserInteractionGeneric();
      }
    } catch (e) {
      debugPrint('Error in explainExam: $e');
      if (mounted) {
        setState(() {
          _labExams[examIndex] = _labExams[examIndex].copyWith(isProcessing: false);
        });
        
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
          id: original.id,
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

  Future<void> _generatePetReport({AnaliseFeridaModel? specificWound}) async {
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
            id: _petId ?? const Uuid().v4(),
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
            healthPlan: _healthPlan,
            assistancePlan: _assistancePlan,
            funeralPlan: _funeralPlan,
            lifeInsurance: _lifeInsurance,
            observacoesPlanos: _observacoesPlanosController.text,
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
                if (specificWound != null) {
                    final pdf = await PetPdfGenerator().generateSingleAnalysisReport(
                        profile: profile,
                        strings: AppLocalizations.of(context)!,
                        specificWound: specificWound,
                    );
                    return pdf.save();
                }

                // Fetch detailed vaccination history
                Map<String, DateTime>? vaccinationData;
                try {
                  await PetEventService.ensureReady();
                  final events = PetEventService().getEventsByPet(profile.petName);
                  final vaccineEvents = events.where((e) => e.type == EventType.vaccine).toList();
                  
                  if (vaccineEvents.isNotEmpty) {
                    vaccinationData = {};
                    // Sort by date descending to get latest
                    vaccineEvents.sort((a, b) => b.dateTime.compareTo(a.dateTime));
                    
                    // Populate map with latest date for each vaccine title
                    // Note: This relies on the title being the vaccine name. 
                    // Since VaccinationCard saves the localized title, this matches what we display.
                    for (var event in vaccineEvents) {
                       if (!vaccinationData.containsKey(event.title)) {
                         vaccinationData[event.title] = event.dateTime;
                       }
                    }
                  }
                } catch (e) {
                  debugPrint('⚠️ Error fetching vaccination data for PDF: $e');
                }

                final pdf = await PetPdfGenerator().generateReport(
                  profile: profile,
                  strings: AppLocalizations.of(context)!,
                  manualGallery: _attachments['gallery'], // Pass manual gallery
                  vaccinationData: vaccinationData,
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
            title: l10n.plansTabTitle,
            icon: Icons.assignment_rounded,
            children: [_buildPlansTabContent()],
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
          petId: _petId!,
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
            petId: _petId ?? (widget.existingProfile?.id ?? _nameController.text),
            petName: _nameController.text,
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
      final bool isStool = analysis.categoria == 'fezes' || analysis.categoria == 'stool';
      
      String title = analysis.diagnosticosProvaveis.isNotEmpty 
          ? analysis.diagnosticosProvaveis.first 
          : (isStool ? 'Análise de Fezes' : 'Sem diagnóstico');

      if (isStool && analysis.achadosVisuais.containsKey('bristol_scale')) {
          title = 'Bristol ${analysis.achadosVisuais['bristol_scale']} - ${analysis.achadosVisuais['color_name'] ?? 'Cor N/A'}';
      }

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
                                    title,
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
               IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppDesign.error, size: 20),
                    onPressed: () => _confirmDeleteStructuredWoundAnalysis(analysis),
                    tooltip: 'Excluir análise',
                ),
               const Icon(Icons.chevron_right, color: Colors.white30)
            ],
          ),
        ),
      );
  }

  void _confirmDeleteStructuredWoundAnalysis(AnaliseFeridaModel analysis) async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.commonDelete),
          content: Text('${AppLocalizations.of(context)!.commonDelete} a análise de ${DateFormat.yMd().format(analysis.dataAnalise)}?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.btnCancel)),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true), 
              child: Text(AppLocalizations.of(context)!.btnDelete, style: const TextStyle(color: Colors.red))
            ),
          ],
        ),
      );

      if (confirm == true) {
        setState(() {
           _historicoAnaliseFeridas.remove(analysis);
           // Also try to remove from _woundHistory legacy if present
           _woundHistory.removeWhere((w) => w['date'] == analysis.dataAnalise.toIso8601String() || w['imagePath'] == analysis.imagemRef);
           _markDirty();
        });
        _onUserInteractionGeneric();
      }
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
                            Container(
                                width: double.infinity,
                                height: 250,
                                color: Colors.black12,
                                child: Image.file(
                                    File(analysis.imagemRef), 
                                    height: 250, 
                                    width: double.infinity, 
                                    fit: BoxFit.contain
                                ),
                            ),
                        
                        Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                        Expanded(
                                            child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                    Text(
                                                        _nameController.text.isNotEmpty ? _nameController.text : 'Pet',
                                                        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.normal)
                                                    ),
                                                    Text(
                                                        (analysis.categoria == 'fezes' || analysis.categoria == 'stool') ? 'Análise de Fezes' : 'Diagnóstico Detalhado', 
                                                        style: GoogleFonts.poppins(color: AppDesign.petPink, fontSize: 18, fontWeight: FontWeight.bold)
                                                    ),
                                                ],
                                            ),
                                        ),
                                        PdfActionButton(
                                            onPressed: () {
                                                Navigator.pop(context); // Close dialog first?
                                                _generatePetReport(specificWound: analysis);
                                            }
                                        ),
                                    ],
                                ),
                                const SizedBox(height: 16),
                                
                                _buildDetailRow('Nível de Risco', analysis.nivelRisco, color: Colors.white),
                                _buildDetailRow('Data', DateFormat('dd/MM/yyyy HH:mm').format(analysis.dataAnalise), color: Colors.white),
                                
                                if (analysis.categoria == 'fezes' || analysis.categoria == 'stool') ...[
                                    if (analysis.achadosVisuais.containsKey('bristol') || analysis.achadosVisuais.containsKey('Escala de Bristol'))
                                        _buildDetailRow('Escala de Bristol', analysis.achadosVisuais['bristol']?.toString() ?? analysis.achadosVisuais['Escala de Bristol']?.toString() ?? 'N/A'),
                                    if (analysis.achadosVisuais.containsKey('color') || analysis.achadosVisuais.containsKey('Cor'))
                                        _buildDetailRow('Cor', analysis.achadosVisuais['color']?.toString() ?? analysis.achadosVisuais['Cor']?.toString() ?? 'N/A'),
                                ],

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

  // --- TAB CONTENT BUILDERS (Missing Methods) ---

  Widget _buildPartnersTabContent() {
    final l10n = AppLocalizations.of(context)!;
    return PartnersFragment(
      allPartners: _availablePartners, 
      linkedPartnerIds: _linkedPartnerIds,
      selectedPartnerFilter: _partnerFilter.isEmpty ? l10n.partnersFilterAll : _partnerFilter,
      filterCategories: const [], // No longer used - dropdown builds its own list
      observacoesPrac: _observacoesPrac,
      petId: widget.existingProfile?.petName ?? _nameController.text,
      petName: _nameController.text,
      onFilterChanged: (v) => setState(() => _partnerFilter = v),
      onLinkStatusChanged: (p) => setState(() {
           if (_linkedPartnerIds.contains(p.id)) {
              _linkedPartnerIds.remove(p.id);
           } else {
              _linkedPartnerIds.add(p.id);
           }
           _markDirty();
      }),
      onPartnerUpdated: (_) => _loadLinkedPartners(), 
      onOpenAgenda: (p) => Navigator.push(context, MaterialPageRoute(builder: (_) => PartnerAgendaScreen(
             partner: p,
             initialEvents: const [],
             petId: widget.existingProfile?.petName ?? _nameController.text,
             onSave: (list) {},
      ))),
      onObservacoesChanged: (v) {
          setState(() => _observacoesPrac = v);
          _onUserTyping();
      },
      actionButtons: const SizedBox(), 
      localizeValue: (v) => v,
    );
  }

  Widget _buildProfileImageHeader() {
    final imageProvider = _profileImage != null 
        ? FileImage(_profileImage!) 
        : (_profileUrl != null ? NetworkImage(_profileUrl!) : null) as ImageProvider?;

    return GestureDetector(
      onTap: _pickProfileImage,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppDesign.petPink.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: AppDesign.petPink.withOpacity(0.5), width: 3),
        ),
        child: Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
              child: ClipOval(
                child: imageProvider != null
                    ? Image(
                        image: imageProvider,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
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

  Widget _buildAnalysisTabContent() {
      // Tenta localizar labels (breed, etc) se necessario
      return AnalysisResultsFragment(
        analysisHistory: _analysisHistory, // Legacy 
        currentRawAnalysis: _currentRawAnalysis,
        petName: _nameController.text,
        existingProfilePetName: widget.existingProfile?.petName,
        existingProfileLastUpdated: widget.existingProfile?.lastUpdated,
        tryLocalizeLabel: _localizeKey,
        findBreedRecursive: _findBreedRecursive,
        onDeleteAnalysis: _handleDeleteAnalysis,
        onAnalysisSaved: _reloadAnalysisHistory, // 🔄 Conectar callback
      );
  }
  
  /// 🔄 Recarrega histórico de análises após salvar nova análise
  Future<void> _reloadAnalysisHistory() async {
    debugPrint('🔄 [EditPetForm] ========== RELOAD ANALYSIS HISTORY ==========');
    try {
      final petName = _nameController.text.trim();
      debugPrint('🔄 [EditPetForm] Pet name: $petName');
      
      if (petName.isEmpty) {
        debugPrint('⚠️ [EditPetForm] Pet name is empty, aborting reload');
        return;
      }
      
      debugPrint('🔄 [EditPetForm] Buscando perfil do pet...');
      final profile = await PetProfileService().getProfile(petName);
      
      if (profile == null) {
        debugPrint('❌ [EditPetForm] Profile is NULL');
        return;
      }
      
      debugPrint('✅ [EditPetForm] Profile encontrado');
      debugPrint('   - Profile keys: ${profile.keys}');
      
      if (mounted) {
        final data = profile['data'] as Map<String, dynamic>?;
        debugPrint('   - Data keys: ${data?.keys}');
        
        final history = data?['analysisHistory'] ?? data?['analysis_history'];
        debugPrint('   - History type: ${history.runtimeType}');
        debugPrint('   - History length: ${history is List ? history.length : 'N/A'}');
        
        setState(() {
          if (history is List) {
            _analysisHistory = List<Map<String, dynamic>>.from(
              history.map((e) => Map<String, dynamic>.from(e as Map))
            );
            debugPrint('✅ [EditPetForm] _analysisHistory atualizado: ${_analysisHistory.length} items');
            
            // Debug: Mostrar últimos 3 itens
            if (_analysisHistory.isNotEmpty) {
              debugPrint('📋 [EditPetForm] Últimas análises:');
              for (var i = 0; i < _analysisHistory.length && i < 3; i++) {
                final item = _analysisHistory[i];
                debugPrint('   [$i] type: ${item['analysis_type']}, score: ${item['health_score']}');
              }
            }
          } else {
            debugPrint('⚠️ [EditPetForm] History não é uma List');
          }
        });
        
        debugPrint('🔄 [EditPetForm] Analysis history reloaded: ${_analysisHistory.length} items');
      } else {
        debugPrint('⚠️ [EditPetForm] Widget not mounted, skipping setState');
      }
    } catch (e) {
      debugPrint('❌ [EditPetForm] Failed to reload analysis history: $e');
      debugPrint('❌ [EditPetForm] Stack trace: ${StackTrace.current}');
    }
    debugPrint('🎉 [EditPetForm] ========== RELOAD COMPLETO ==========');
  }

  Widget _buildGalleryTabContent() {
      File? profileImg;
      if (_profileImage != null) {
          profileImg = _profileImage;
      } else if (widget.existingProfile?.imagePath != null) {
          profileImg = File(widget.existingProfile!.imagePath!);
      }

      return GalleryFragment(
          docs: _attachments['gallery'] ?? [],
          profileImage: profileImg,
          observacoesGaleria: _observacoesGaleria,
          onAddAttachment: () => _addAttachment('gallery'),
          onDeleteAttachment: _deleteAttachment,
          onObservacoesChanged: (v) {
              setState(() => _observacoesGaleria = v);
              _onUserTyping();
          },
          actionButtons: const SizedBox(),
      );
  }



  // Helper
  String _localizeKey(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    final k = key.toLowerCase().trim();
    
    // Map common AI keys to localized strings
    final map = {
        // High Level Keys
        'identification': l10n.tabIdentity,
        'health_analysis': 'Análise de Saúde',
        'clinical_analysis': 'Análise Clínica',
        'clinical_signs': l10n.pdfClinicalSigns,
        'visual_findings': 'Achados Visuais',
        'diagnosis': l10n.termDiagnosis,
        'recommendations': l10n.termRecommendations,
        'severity': l10n.termSeverity,
        
        // Identification & Profile
        'breed': l10n.pdfFieldBreed,
        'species': 'Espécie',
        'lineage': 'Linhagem',
        'origin_region': 'Origem',
        'morphology_type': 'Morfologia',
        'size': 'Porte',
        'longevity': 'Expectativa de Vida',
        'growth_curve': 'Curva de Crescimento',
        'weight_3_months': 'Peso (3 meses)',
        'weight_6_months': 'Peso (6 meses)',
        'weight_12_months': 'Peso (1 ano)',
        'adult_weight': 'Peso Adulto',
        
        // Grooming & Lifestyle
        'grooming': 'Grooming',
        'coat_type': 'Tipo de Pelo',
        'grooming_frequency': 'Frequência de Banho/Tosa',
        'lifestyle': 'Estilo de Vida',
        'activity_level': 'Nível de Atividade',
        'environment_type': 'Ambiente Ideal',
        'training_intelligence': 'Inteligência/Treino',
        
        // Nutrition
        'nutrition': 'Nutrição',
        'kcal_puppy': 'Kcal (Filhote)',
        'kcal_adult': 'Kcal (Adulto)',
        'kcal_senior': 'Kcal (Sênior)',
        'target_nutrients': 'Nutrientes Alvo',
        
        // Health & Checkups
        'health': 'Saúde',
        'predispositions': 'Predisposições',
        'preventive_checkup': 'Checkup Preventivo',

        // Clinical Details (Wounds/Stools/Exam)
        'analysis_type': 'Tipo de Análise',
        'category': 'Categoria',
        
        // Sound & Food
        'vocal_analysis': 'Análise Vocal',
        'food_label': 'Análise de Ração',
        'veredit': 'Veredito',
        'simple_reason': 'Motivo',
        'daily_tip': 'Dica Sanitária',
        'emotion_simple': 'Emoção',
        'reason_simple': 'Motivo Provável',
        'action_tip': 'O que fazer',
        'characteristics': 'Características',
        'visual_description': 'Descrição Visual',
        'possible_causes': 'Causas Prováveis',
        'immediate_care': 'Cuidados Imediatos',
        'urgency_level': 'Nível de Urgência',
        
        'eye_details': 'Detalhes Oculares',
        'dental_details': 'Detalhes Dentários',
        'skin_details': 'Detalhes da Pele',
        'wound_details': 'Detalhes da Ferida',
        'stool_details': 'Análise Coprológica',
        
        // Specific Symptoms
        'eyes': l10n.pdfEyes,
        'teeth': l10n.pdfTeeth, 
        'skin': l10n.pdfSkin,
        'coat': 'Pelagem',
        'weight': l10n.petWeightEstimated,
        'hiperemia': 'Hiperemia',
        'opacidade': 'Opacidade',
        'secrecao': 'Secreção',
        'tartaro_index': 'Índice de Tártaro',
        'gengivite': 'Gengivite',
        'halitose': 'Halitose',
        'alopecias': 'Alopecias (Falhas)',
        'ectoparasitas': 'Ectoparasitas',
        'descamacao': 'Descamação',
        'profundidade': 'Profundidade',
        'bordas': 'Bordas da Lesão',
        
        // Stool Specifics
        'consistency_bristol_scale': 'Escala Bristol',
        'firmness': 'Firmeza',
        'hydration_mucus': 'Hidratação/Muco',
        'color_name': 'Cor Identificada',
        'color_hex': 'Código de Cor',
        'clinical_color_meaning': 'Significado Clínico',
        'foreign_bodies': 'Corpos Estranhos',
        'parasites_detected': 'Parasitas Detectados',
        'volume_assessment': 'Avaliação de Volume',

        // General
        'description': 'Descrição',
        'color': 'Cor',
        'age': 'Idade Estimada',
        'gender': 'Sexo',
        'neutered': 'Castrado',
        'parasites': 'Parasitas',
        'lesions': 'Lesões',
        'discharge': 'Secreção',
        'pain': 'Sinais de Dor',
        'temperature': 'Temperatura',
        'hydration': 'Hidratação',
        'mucous_membranes': 'Mucosas',
        'lymph_nodes': 'Linfonodos',
        'respiration': 'Respiração',
        'confidence': 'Confiabilidade',
        
        // Behavior & Temperament (New Domain)
        'behavior': 'Perfil Comportamental',
        'personality': 'Personalidade',
        'social_behavior': 'Comportamento Social',
        'energy_level_desc': 'Nível de Energia (Descrição)',
    };

    if (map.containsKey(k)) return map[k]!;
    
    // Fallback: Capitalize
    if (key.length > 1) {
        return key[0].toUpperCase() + key.substring(1).replaceAll('_', ' ');
    }
    return key;
  }

  String? _findBreedRecursive(Map<dynamic, dynamic> map) {
     if (map.containsKey('raca')) return map['raca']?.toString();
     if (map.containsKey('breed')) return map['breed']?.toString();
     
     for (var v in map.values) {
        if (v is Map) {
             final found = _findBreedRecursive(v);
             if (found != null) return found;
        }
     }
     return null;
  }
  Widget _buildAutoSaveIndicator() {
      Color bgColor;
      IconData icon;
      String text;
      
      switch (_saveStatus) {
          case _SaveStatus.saving:
              bgColor = Colors.amber.withValues(alpha: 0.8);
              icon = Icons.sync;
              text = 'Salvando...';
              break;
          case _SaveStatus.success:
              bgColor = Colors.green.withValues(alpha: 0.8);
              icon = Icons.check;
              text = 'Salvo';
              break;
          case _SaveStatus.error:
              bgColor = Colors.red.withValues(alpha: 0.8);
              icon = Icons.error_outline;
              text = 'Erro ao salvar';
              break;
          case _SaveStatus.idle:
          default:
              return const SizedBox.shrink();
      }
      
      return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2))
              ]
          ),
          child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                  if (_saveStatus == _SaveStatus.saving)
                      const SizedBox(
                          width: 12, height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                      )
                  else
                      Icon(icon, color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text(text, style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
          ),
      );
  }
}

enum _SaveStatus { idle, saving, success, error }

