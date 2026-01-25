import 'package:flutter/material.dart';
import 'package:scannut/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/partner_model.dart';
import '../../../core/services/partner_service.dart';
import '../../../core/services/whatsapp_service.dart';
import '../../../core/providers/settings_provider.dart';
import '../../settings/settings_screen.dart';
import 'partner_registration_screen.dart';
import '../../../core/widgets/pdf_action_button.dart';
import '../../../core/widgets/pdf_preview_screen.dart';
import '../../../core/services/export_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/auth_trace_logger.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_design.dart';
import './widgets/radar_export_filter_modal.dart';
import '../../pet/services/pet_indexing_service.dart';

class PartnersHubScreen extends ConsumerStatefulWidget {
  final bool isSelectionMode;
  final String? petId;
  final String? petName;
  final bool initialOpenRadar; // 🛡️ V_FIX: Direct Link to Radar

  const PartnersHubScreen({
    super.key,
    this.isSelectionMode = false,
    this.petId,
    this.petName,
    this.initialOpenRadar = false,
  });

  @override
  ConsumerState<PartnersHubScreen> createState() => _PartnersHubScreenState();
}

class _PartnersHubScreenState extends ConsumerState<PartnersHubScreen> {
  final PartnerService _service = PartnerService();
  List<PartnerModel> _allPartners = [];
  bool _loading = true;
  late String _selectedCategory; // Initialized in didChangeDependencies

  List<String> get _allSelectableCategories {
    final strings = AppLocalizations.of(context)!;
    return [
      strings.partnersFilterAll,
      // Health & Wellness
      strings.catVet,
      strings.catVetEmergency,
      strings.catVetSpecialist,
      strings.catPhysio,
      strings.catHomeo,
      strings.catNutri,
      strings.catAnest,
      strings.catOnco,
      strings.catDentist,
      strings.partnersFilterLab,
      strings.partnersFilterPharmacy,
      // Daily Care
      strings.catSitter,
      strings.partnersFilterDogWalker,
      strings.catNanny,
      strings.partnersFilterHotel,
      strings.catDaycare,
      // Grooming
      strings.partnersFilterGrooming,
      strings.catStylist,
      strings.catGroomerBreed,
      // Training
      strings.catTrainer,
      strings.catBehaviorist,
      strings.catCatSultant,
      // Retail
      strings.catPetShop,
      strings.partnersFilterPetShop,
      strings.catSupplies,
      strings.catTransport,
      // Other
      strings.catNgo,
      strings.catBreeder,
      strings.catInsurance,
      strings.catFuneralPlan,
      strings.catCemeterie,
      strings.catCremation,
      strings.catFuneral,
    ];
  }

  @override
  void initState() {
    super.initState();
    _selectedCategory = ''; // Initialize empty
    _loadPartners();

    // 🛡️ [V_FIX] AUTO-RADAR: Open radar discovery if requested
    if (widget.initialOpenRadar) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openRadar());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedCategory.isEmpty || _isAll(_selectedCategory)) {
      _selectedCategory = AppLocalizations.of(context)!.partnersFilterAll;
    }
  }

  bool _isAll(String category) {
    if (category.isEmpty) return true;
    final c = category.toLowerCase();
    return c == 'todos' ||
        c == 'all' ||
        c == AppLocalizations.of(context)!.partnersFilterAll.toLowerCase();
  }

  Future<void> _loadPartners() async {
    // Renamed from _loadData
    try {
      setState(() => _loading = true);
      await _service.init();
      _allPartners = _service.getAllPartners(); // Renamed from _allPartners
    } catch (e) {
      debugPrint("Erro ao carregar parceiros: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openRadar() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppDesign.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => _ExploreRadarSheet(
        onImport: (partner) async {
          Navigator.pop(context);
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PartnerRegistrationScreen(
                initialData: partner,
                petId: widget.petId,
                petName: widget.petName,
              ),
            ),
          );
          if (result == true) _loadPartners(); // Updated call
        },
      ),
    );
  }

  void _openManualRegistration() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => const PartnerRegistrationScreen()),
    );
    if (result == true) _loadPartners(); // Updated call
  }

  Future<void> _generatePdf() async {
    String selectedReportCategory =
        AppLocalizations.of(context)!.partnersFilterAll;
    if (!mounted) return;
    String selectedReportType = AppLocalizations.of(context)!.partnersSummary;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppDesign.surfaceDark,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            AppLocalizations.of(context)!.partnersExportPdf,
            style: GoogleFonts.poppins(
                color: AppDesign.textPrimaryDark, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.partnersCategory,
                      style: GoogleFonts.poppins(
                          color: AppDesign.textSecondaryDark, fontSize: 13)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedReportCategory,
                        isExpanded: true,
                        dropdownColor: AppDesign.surfaceDark,
                        style:
                            const TextStyle(color: AppDesign.textPrimaryDark),
                        items: _allSelectableCategories
                            .map((cat) =>
                                DropdownMenuItem(value: cat, child: Text(cat)))
                            .toList(),
                        onChanged: (val) =>
                            setDialogState(() => selectedReportCategory = val!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(AppLocalizations.of(context)!.partnersDetailLevel,
                      style: GoogleFonts.poppins(
                          color: AppDesign.textSecondaryDark, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildTypeOption(
                          AppLocalizations.of(context)!.partnersSummary,
                          selectedReportType ==
                              AppLocalizations.of(context)!.partnersSummary,
                          () => setDialogState(() => selectedReportType =
                              AppLocalizations.of(context)!.partnersSummary)),
                      const SizedBox(width: 12),
                      _buildTypeOption(
                          AppLocalizations.of(context)!.partnersDetailed,
                          selectedReportType ==
                              AppLocalizations.of(context)!.partnersDetailed,
                          () => setDialogState(() => selectedReportType =
                              AppLocalizations.of(context)!.partnersDetailed)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context)!.partnersExportDisclaimer,
                    style: const TextStyle(
                        color: AppDesign.textSecondaryDark, fontSize: 11),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _executePdfGeneration(
                            selectedReportCategory, selectedReportType);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppDesign.success,
                        foregroundColor: AppDesign.backgroundDark,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      child: Text(
                          AppLocalizations.of(context)!.partnersGenerateReport,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 1.1)),
                    ),
                  ),
                  const SizedBox(height: 20), // Anti-overflow Rule of Gold
                ],
              ),
            ),
          ),
          actions: [
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.partnersBack,
                    style: const TextStyle(
                        color: AppDesign.textSecondaryDark, fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppDesign.success.withValues(alpha: 0.2)
                : Colors.white10,
            border: Border.all(
                color: isSelected ? AppDesign.success : Colors.white10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color:
                  isSelected ? AppDesign.success : AppDesign.textSecondaryDark,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _executePdfGeneration(
      String selectedCategory, String type) async {
    final reportPartners = _isAll(selectedCategory)
        ? _allPartners
        : _allPartners
            .where((p) => _isSameCategory(p.category, selectedCategory))
            .toList();

    if (reportPartners.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.noPartnersForFilters),
            backgroundColor: AppDesign.warning),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfPreviewScreen(
          title: AppLocalizations.of(context)!.partnersExportPdf,
          buildPdf: (format) async {
            final pdf = await ExportService().generatePartnersHubReport(
              partners: reportPartners,
              reportType: type,
              strings: AppLocalizations.of(context)!,
            );
            return pdf.save();
          },
        ),
      ),
    );
  }

  List<PartnerModel> get _filteredPartners {
    if (_isAll(_selectedCategory)) return _allPartners;
    return _allPartners
        .where((p) => _isSameCategory(p.category, _selectedCategory))
        .toList();
  }

  bool _isSameCategory(String catA, String catB) {
    if (catA == catB) return true;
    final a = catA.toLowerCase();
    final b = catB.toLowerCase();
    if (a == b) return true;

    // Canonical mapping check for multi-language support
    // (Veterinary, Vet, Lab, Grooming, etc.)
    final List<List<String>> synonymGroups = [
      ['veterinário', 'veterinary', 'veterinarian', 'veterinario', 'vet'],
      ['pet shop', 'petshop', 'tienda de mascotas'],
      ['farmácias pet', 'pet pharmacy', 'pharmacy', 'farmacia pet', 'farmacia'],
      ['banho e tosa', 'grooming', 'peluquería', 'tosa'],
      ['hotéis', 'hotel', 'pet hotel', 'adestramento', 'training'],
      ['laboratórios', 'laboratory', 'lab', 'laboratorio', 'laboratorios'],
    ];

    for (var group in synonymGroups) {
      bool hasA = group.any((s) => a.contains(s));
      bool hasB = group.any((s) => b.contains(s));
      if (hasA && hasB) return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesign.backgroundDark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            backgroundColor: AppDesign.backgroundDark,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                  widget.isSelectionMode
                      ? AppLocalizations.of(context)!.partnersSelectTitle
                      : AppLocalizations.of(context)!.partnersTitle,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            ),
            actions: [
              if (!widget.isSelectionMode)
                PdfActionButton(onPressed: _generatePdf),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: _buildFilterBar(),
          ),
          if (_loading)
            const SliverFillRemaining(
                child: Center(
                    child: CircularProgressIndicator(color: AppDesign.petPink)))
          else if (_filteredPartners.isEmpty)
            _buildEmptyState()
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildPartnerCard(_filteredPartners[index]),
                  childCount: _filteredPartners.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: widget.isSelectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: _openManualRegistration,
              backgroundColor: AppDesign.petPink,
              icon: const Icon(Icons.add, color: Colors.black),
              label: Text(AppLocalizations.of(context)!.partnersRegister,
                  style: GoogleFonts.poppins(
                      color: Colors.black, fontWeight: FontWeight.bold)),
            ),
    );
  }

  Widget _buildFilterBar() {
    final strings = AppLocalizations.of(context)!;

    final groups = [
      {
        'title': strings.catHeaderHealth,
        'items': [
          strings.catVet,
          strings.catVetEmergency,
          strings.catVetSpecialist,
          strings.catPhysio,
          strings.catHomeo,
          strings.catNutri,
          strings.catAnest,
          strings.catOnco,
          strings.catDentist,
          strings.partnersFilterLab,
          strings.partnersFilterPharmacy,
        ]
      },
      {
        'title': strings.catHeaderDaily,
        'items': [
          strings.catSitter,
          strings.partnersFilterDogWalker,
          strings.catNanny,
          strings.partnersFilterHotel,
          strings.catDaycare,
        ]
      },
      {
        'title': strings.catHeaderGrooming,
        'items': [
          strings.partnersFilterGrooming,
          strings.catStylist,
          strings.catGroomerBreed,
        ]
      },
      {
        'title': strings.catHeaderTraining,
        'items': [
          strings.catTrainer,
          strings.catBehaviorist,
          strings.catCatSultant,
        ]
      },
      {
        'title': strings.catHeaderRetail,
        'items': [
          strings.catPetShop,
          strings.partnersFilterPetShop,
          strings.catSupplies,
          strings.catTransport,
        ]
      },
      {
        'title': strings.catHeaderOther,
        'items': [
          strings.catNgo,
          strings.catBreeder,
          strings.catInsurance,
          strings.catFuneralPlan,
          strings.catCemeterie,
          strings.catCremation,
          strings.catFuneral,
        ]
      }
    ];

    final List<DropdownMenuItem<String>> menuItems = [];

    // Add "All" option first
    menuItems.add(DropdownMenuItem<String>(
      value: strings.partnersFilterAll,
      child: Text(
        strings.partnersFilterAll,
        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    ));

    // Add grouped categories
    for (var g in groups) {
      final title = g['title'] as String;
      final items = g['items'] as List<String>;

      // Header (non-selectable)
      menuItems.add(DropdownMenuItem<String>(
        value: "HEADER_$title",
        enabled: false,
        child: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppDesign.petPink,
            fontSize: 13,
          ),
        ),
      ));

      // Category items
      for (var item in items) {
        menuItems.add(DropdownMenuItem<String>(
          value: item,
          child: Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Text(item, style: GoogleFonts.poppins(fontSize: 14)),
          ),
        ));
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedCategory,
        dropdownColor: AppDesign.surfaceDark,
        isExpanded: true,
        style: const TextStyle(color: AppDesign.textPrimaryDark),
        decoration: InputDecoration(
          labelText: strings.partnersCategory,
          labelStyle: const TextStyle(color: AppDesign.textSecondaryDark),
          prefixIcon: const Icon(Icons.filter_list, color: AppDesign.petPink),
          filled: true,
          fillColor: Colors.white10,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        items: menuItems,
        onChanged: (v) {
          if (v != null && !v.startsWith("HEADER_")) {
            setState(() => _selectedCategory = v);
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.handshake_outlined,
                size: 80, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
                _selectedCategory ==
                        AppLocalizations.of(context)!.partnersFilterAll
                    ? AppLocalizations.of(context)!.partnersNoneFound
                    : AppLocalizations.of(context)!
                        .partnersNoneInCategory(_selectedCategory),
                style: GoogleFonts.poppins(
                    color: AppDesign.textSecondaryDark, fontSize: 16)),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.partnersRadarHint,
                style: GoogleFonts.poppins(
                    color: AppDesign.textSecondaryDark.withValues(alpha: 0.5),
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerCard(PartnerModel partner) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        onTap: () async {
          if (widget.isSelectionMode) {
            Navigator.pop(context, partner);
          } else {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PartnerRegistrationScreen(
                  initialData: partner,
                  petId: widget.petId,
                  petName: widget.petName,
                ),
              ),
            );
            if (result == true) _loadPartners(); // Updated call
          }
        },
        contentPadding: const EdgeInsets.all(16),
        leading: _getCategoryIcon(partner.category),
        title: Text(partner.name,
            style: GoogleFonts.poppins(
                color: AppDesign.textPrimaryDark, fontWeight: FontWeight.w600)),
        subtitle: Text(partner.category,
            style: GoogleFonts.poppins(
                color: AppDesign.textSecondaryDark, fontSize: 12)),
        trailing: widget.isSelectionMode
            ? const Icon(Icons.check_circle_outline, color: AppDesign.petPink)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      partner.isFavorite ? Icons.star : Icons.star_border,
                      color: partner.isFavorite ? Colors.amber : Colors.white24,
                    ),
                    onPressed: () async {
                      final updated =
                          partner.copyWith(isFavorite: !partner.isFavorite);
                      await _service.init();
                      await _service.savePartner(updated);
                      _loadPartners();

                      if (updated.isFavorite && widget.petId != null) {
                        PetIndexingService().indexPartnerInteraction(
                          petId: widget.petId!,
                          petName: widget.petName ?? 'Pet',
                          partnerName: partner.name,
                          partnerId: partner.id,
                          interactionType: 'favorited',
                          localizedTitle: AppLocalizations.of(context)!
                              .petIndexing_partnerFavorited(partner.name),
                          localizedNotes: AppLocalizations.of(context)!
                              .petIndexing_partnerInteractionNotes,
                        );
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline,
                        color: AppDesign.petPink),
                    onPressed: () {
                      WhatsAppService.abrirChat(
                        telefone: partner.phone,
                        mensagem: AppLocalizations.of(context)!
                            .whatsappInitialMessage,
                      );

                      if (widget.petId != null) {
                        PetIndexingService().indexPartnerInteraction(
                          petId: widget.petId!,
                          petName: widget.petName ?? 'Pet',
                          partnerName: partner.name,
                          partnerId: partner.id,
                          interactionType: 'contacted',
                          localizedTitle: AppLocalizations.of(context)!
                              .petIndexing_partnerContacted(partner.name),
                          localizedNotes: AppLocalizations.of(context)!
                              .petIndexing_partnerInteractionNotes,
                        );
                      }
                    },
                  ),
                ],
              ),
      ),
    );
  }

  Widget _getCategoryIcon(String category) {
    IconData icon;
    Color color;
    final c = category.toLowerCase();

    if (c.contains('vet')) {
      icon = Icons.local_hospital;
      color = AppDesign.error;
    } else if (c.contains('farm') || c.contains('pharm')) {
      icon = Icons.medication;
      color = AppDesign.info;
    } else if (c.contains('shop') || c.contains('tienda')) {
      icon = Icons.shopping_basket;
      color = AppDesign.warning;
    } else if (c.contains('banho') ||
        c.contains('grooming') ||
        c.contains('peluquer')) {
      icon = Icons.content_cut;
      color = AppDesign.petPink;
    } else if (c.contains('hotel')) {
      icon = Icons.hotel;
      color = AppDesign.petPink;
    } else if (c.contains('lab')) {
      icon = Icons.biotech;
      color = AppDesign.info;
    } else {
      icon = Icons.pets;
      color = AppDesign.success;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _ExploreRadarSheet extends ConsumerStatefulWidget {
  final Function(PartnerModel) onImport;
  const _ExploreRadarSheet({required this.onImport});

  @override
  ConsumerState<_ExploreRadarSheet> createState() => _ExploreRadarSheetState();
}

class _ExploreRadarSheetState extends ConsumerState<_ExploreRadarSheet> {
  final PartnerService _service = PartnerService();
  late String _selectedCategory;
  List<PartnerModel> _discoveredResults = [];
  bool _isLoading = true;
  String _errorMessage = '';
  Position? _currentPosition;

  List<String> get _allSelectableCategories {
    final strings = AppLocalizations.of(context)!;
    return [
      strings.partnersFilterAll,
      // Health & Wellness
      strings.catVet,
      strings.catVetEmergency,
      strings.catVetSpecialist,
      strings.catPhysio,
      strings.catHomeo,
      strings.catNutri,
      strings.catAnest,
      strings.catOnco,
      strings.catDentist,
      strings.partnersFilterLab,
      strings.partnersFilterPharmacy,
      // Daily Care
      strings.catSitter,
      strings.partnersFilterDogWalker,
      strings.catNanny,
      strings.partnersFilterHotel,
      strings.catDaycare,
      // Grooming
      strings.partnersFilterGrooming,
      strings.catStylist,
      strings.catGroomerBreed,
      // Training
      strings.catTrainer,
      strings.catBehaviorist,
      strings.catCatSultant,
      // Retail
      strings.catPetShop,
      strings.partnersFilterPetShop,
      strings.catSupplies,
      strings.catTransport,
      // Other
      strings.catNgo,
      strings.catBreeder,
      strings.catInsurance,
      strings.catFuneralPlan,
      strings.catCemeterie,
      strings.catCremation,
      strings.catFuneral,
    ];
  }

  @override
  void initState() {
    super.initState();
    _selectedCategory = 'All'; // Will be localized in didChangeDependencies
    _startDiscovery();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isAll(_selectedCategory)) {
      _selectedCategory = AppLocalizations.of(context)!.partnersFilterAll;
    }
  }

  bool _isAll(String category) {
    if (category.isEmpty) return true;
    final c = category.toLowerCase();
    return c == 'todos' ||
        c == 'all' ||
        c == AppLocalizations.of(context)!.partnersFilterAll.toLowerCase();
  }

  Future<void> _startDiscovery() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    authTrace.clearTrace();
    authTrace.startStep('RadarDiscovery.start');
    logger.info('🛰️ Iniciando protocolo de busca inteligente (Radar)');

    try {
      // 1. Check Permissions
      authTrace.startStep('GPS.checkPermission');
      LocationPermission permission = await Geolocator.checkPermission();
      logger.info('📍 Status Permissão GPS: $permission');

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          authTrace.endStep('GPS.checkPermission',
              success: false, details: 'Permission Denied');
          setState(() {
            _isLoading = false;
            if (!mounted) return;
            _errorMessage =
                AppLocalizations.of(context)!.partnersLocationDenied;
          });
          return;
        }
      }
      authTrace.endStep('GPS.checkPermission');

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              AppLocalizations.of(context)!.partnersLocationPermanentlyDenied;
        });
        return;
      }

      // 2. Get Position
      authTrace.startStep('GPS.getPosition');
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10),
        );
        logger.info(
            '📍 Coordenadas capturadas: Lat: ${position.latitude}, Lng: ${position.longitude}');
        authTrace.endStep('GPS.getPosition',
            details: 'Lat: ${position.latitude}, Lng: ${position.longitude}');
      } catch (e) {
        logger.warning(
            '⚠️ Falha ao obter posição atual, tentando última conhecida: $e');
        final lastPos = await Geolocator.getLastKnownPosition();
        if (lastPos != null) {
          position = lastPos;
          logger.info(
              '📍 Usando última posição conhecida: Lat: ${position.latitude}, Lng: ${position.longitude}');
          authTrace.endStep('GPS.getPosition', details: 'Using last known pos');
        } else {
          authTrace.endStep('GPS.getPosition',
              success: false, details: e.toString());
          if (!mounted) return;
          throw AppLocalizations.of(context)!.partnersLocationError;
        }
      }

      // 3. Search real data
      authTrace.startStep('GooglePlaces.search');
      final radius = ref.read(settingsProvider).partnerSearchRadius;
      logger.info('📡 Chamando API de busca num raio de ${radius}km');

      final results = await _service.discoverNearbyPartners(
        lat: position.latitude,
        lng: position.longitude,
        radiusKm: radius,
      );

      authTrace.endStep('GooglePlaces.search',
          details: 'Found ${results.length} results');

      if (mounted) {
        setState(() {
          _discoveredResults = results;
          _isLoading = false;
          _currentPosition = position;
        });
      }
      authTrace.endStep('RadarDiscovery.start',
          details: 'Flow Completed Successfully');
    } catch (e, stack) {
      String technicalDetails = e.toString();
      bool isAuthError = technicalDetails.contains('10') ||
          technicalDetails.contains('DEVELOPER_ERROR') ||
          technicalDetails.contains('AUTH');

      authTrace.endStep('RadarDiscovery.start',
          success: false, details: technicalDetails);
      logger.error('❌ Erro na busca por radar', error: e, stackTrace: stack);

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (isAuthError) {
            _errorMessage =
                '${AppLocalizations.of(context)!.errorGoogleAuth}\n\n'
                '${AppLocalizations.of(context)!.errorGoogleAuthDetailMsg(technicalDetails)}';
          } else {
            _errorMessage =
                AppLocalizations.of(context)!.errorSearchFailed(e.toString());
          }
        });
      }
    }
  }

  List<PartnerModel> get _filteredResults {
    if (_isAll(_selectedCategory)) return _discoveredResults;
    return _discoveredResults
        .where((p) => _isSameCategory(p.category, _selectedCategory))
        .toList();
  }

  bool _isSameCategory(String catA, String catB) {
    if (catA == catB) return true;
    final a = catA.toLowerCase();
    final b = catB.toLowerCase();
    if (a == b) return true;

    final List<List<String>> synonymGroups = [
      ['veterinário', 'veterinary', 'veterinarian', 'veterinario', 'vet'],
      ['pet shop', 'petshop', 'tienda de mascotas'],
      ['farmácias pet', 'pet pharmacy', 'pharmacy', 'farmacia pet', 'farmacia'],
      ['banho e tosa', 'grooming', 'peluquería', 'tosa'],
      ['hotéis', 'hotel', 'pet hotel', 'adestramento', 'training'],
      ['laboratórios', 'laboratory', 'lab', 'laboratorio', 'laboratorios'],
    ];

    for (var group in synonymGroups) {
      bool hasA = group.any((s) => a.contains(s));
      bool hasB = group.any((s) => b.contains(s));
      if (hasA && hasB) return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SettingsScreen()),
                      ).then((_) =>
                          _startDiscovery()); // Re-search if settings changed
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.explore,
                              color: AppDesign.petPink, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'Radar Explorer (${ref.watch(settingsProvider).partnerSearchRadius.toInt()}km)',
                                    style: GoogleFonts.poppins(
                                        color: AppDesign.textPrimaryDark,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                Text(
                                    AppLocalizations.of(context)!
                                        .radarTapToChangeRadius,
                                    style: const TextStyle(
                                        color: AppDesign.petPink,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          const Icon(Icons.settings_outlined,
                              color: AppDesign.textSecondaryDark, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_discoveredResults.isNotEmpty)
                  PdfActionButton(
                    onPressed: _showExportModal,
                    color: Colors.transparent,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
                "${AppLocalizations.of(context)!.partnerRadarFoundTitle} $_selectedCategory",
                style: const TextStyle(
                    color: AppDesign.textSecondaryDark, fontSize: 13)),
            const SizedBox(height: 16),
            _buildRadarFilterBar(),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                              color: AppDesign.petPink),
                          const SizedBox(height: 16),
                          Text(
                              AppLocalizations.of(context)!
                                  .partnersRadarTracking,
                              style: GoogleFonts.poppins(
                                  color: AppDesign.textSecondaryDark,
                                  fontSize: 12)),
                        ],
                      ),
                    )
                  : _errorMessage.isNotEmpty
                      ? Center(
                          child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline,
                                  color: AppDesign.error, size: 48),
                              const SizedBox(height: 16),
                              Text(_errorMessage,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: AppDesign.error, fontSize: 13)),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _startDiscovery,
                                icon: const Icon(Icons.refresh, size: 18),
                                label: Text(
                                    AppLocalizations.of(context)!.tryAgain),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white10),
                              ),
                              const SizedBox(height: 12),
                              TextButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: AppDesign.surfaceDark,
                                      title: Text(
                                          AppLocalizations.of(context)!
                                              .diagnosticTrace,
                                          style: const TextStyle(
                                              color:
                                                  AppDesign.textPrimaryDark)),
                                      content: SizedBox(
                                        width: double.maxFinite,
                                        child: SingleChildScrollView(
                                          child: Text(
                                              authTrace.getTraceAsString(),
                                              style: const TextStyle(
                                                  color: AppDesign
                                                      .textSecondaryDark,
                                                  fontSize: 10,
                                                  fontFamily: 'monospace')),
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: Text(
                                                AppLocalizations.of(context)!
                                                    .commonClose)),
                                        TextButton(
                                            onPressed: () {
                                              Clipboard.setData(ClipboardData(
                                                  text: authTrace
                                                      .getTraceAsString()));
                                              if (!mounted) return;
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                      content: Text(
                                                          AppLocalizations.of(
                                                                  context)!
                                                              .logsCopied)));
                                            },
                                            child: Text(
                                                AppLocalizations.of(context)!
                                                    .actionCopy)),
                                      ],
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.bug_report_outlined,
                                    size: 18, color: AppDesign.petPink),
                                label: Text(
                                    AppLocalizations.of(context)!
                                        .viewTechDetails,
                                    style: const TextStyle(
                                        color: AppDesign.petPink)),
                              ),
                            ],
                          ),
                        ))
                      : _filteredResults.isEmpty
                          ? Center(
                              child: Text(
                                  AppLocalizations.of(context)!
                                      .partnersRadarNoResults,
                                  style: GoogleFonts.poppins(
                                      color: AppDesign.textSecondaryDark)))
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: _filteredResults.length,
                              itemBuilder: (context, index) {
                                final p = _filteredResults[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                      color: const Color(0x08FFFFFF),
                                      borderRadius: BorderRadius.circular(15)),
                                  child: ListTile(
                                    leading: _getCategoryIcon(p.category),
                                    title: Text(p.name,
                                        style: const TextStyle(
                                            color: AppDesign.textPrimaryDark,
                                            fontWeight: FontWeight.bold)),
                                    subtitle: Text(
                                        "${p.category} • ${p.address}",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: AppDesign.textSecondaryDark,
                                            fontSize: 11)),
                                    trailing: const Icon(Icons.chevron_right,
                                        color: AppDesign.petPink),
                                    onTap: () => widget.onImport(p),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => RadarExportFilterModal(
        currentResults: _discoveredResults,
        onGenerate: (partners) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PdfPreviewScreen(
                title: 'Exportação Radar Geo',
                buildPdf: (format) => ExportService()
                    .generateRadarReport(
                      partners: partners,
                      userLat: _currentPosition?.latitude ?? 0.0,
                      userLng: _currentPosition?.longitude ?? 0.0,
                      strings: AppLocalizations.of(context)!,
                    )
                    .then((pdf) => pdf.save()),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRadarFilterBar() {
    final strings = AppLocalizations.of(context)!;

    final groups = [
      {
        'title': strings.catHeaderHealth,
        'items': [
          strings.catVet,
          strings.catVetEmergency,
          strings.catVetSpecialist,
          strings.catPhysio,
          strings.catHomeo,
          strings.catNutri,
          strings.catAnest,
          strings.catOnco,
          strings.catDentist,
          strings.partnersFilterLab,
          strings.partnersFilterPharmacy,
        ]
      },
      {
        'title': strings.catHeaderDaily,
        'items': [
          strings.catSitter,
          strings.partnersFilterDogWalker,
          strings.catNanny,
          strings.partnersFilterHotel,
          strings.catDaycare,
        ]
      },
      {
        'title': strings.catHeaderGrooming,
        'items': [
          strings.partnersFilterGrooming,
          strings.catStylist,
          strings.catGroomerBreed,
        ]
      },
      {
        'title': strings.catHeaderTraining,
        'items': [
          strings.catTrainer,
          strings.catBehaviorist,
          strings.catCatSultant,
        ]
      },
      {
        'title': strings.catHeaderRetail,
        'items': [
          strings.catPetShop,
          strings.partnersFilterPetShop,
          strings.catSupplies,
          strings.catTransport,
        ]
      },
      {
        'title': strings.catHeaderOther,
        'items': [
          strings.catNgo,
          strings.catBreeder,
          strings.catInsurance,
          strings.catFuneralPlan,
          strings.catCemeterie,
          strings.catCremation,
          strings.catFuneral,
        ]
      }
    ];

    final List<DropdownMenuItem<String>> menuItems = [];

    // Add "All" option first
    menuItems.add(DropdownMenuItem<String>(
      value: strings.partnersFilterAll,
      child: Text(
        strings.partnersFilterAll,
        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    ));

    // Add grouped categories
    for (var g in groups) {
      final title = g['title'] as String;
      final items = g['items'] as List<String>;

      // Header (non-selectable)
      menuItems.add(DropdownMenuItem<String>(
        value: "HEADER_$title",
        enabled: false,
        child: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppDesign.petPink,
            fontSize: 13,
          ),
        ),
      ));

      // Category items
      for (var item in items) {
        menuItems.add(DropdownMenuItem<String>(
          value: item,
          child: Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Text(item, style: GoogleFonts.poppins(fontSize: 14)),
          ),
        ));
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedCategory,
        dropdownColor: AppDesign.surfaceDark,
        isExpanded: true,
        style: const TextStyle(color: AppDesign.textPrimaryDark),
        decoration: InputDecoration(
          labelText: strings.partnersCategory,
          labelStyle:
              const TextStyle(color: AppDesign.textSecondaryDark, fontSize: 12),
          prefixIcon:
              const Icon(Icons.filter_list, color: AppDesign.petPink, size: 20),
          filled: true,
          fillColor: Colors.white10,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          isDense: true,
        ),
        items: menuItems,
        onChanged: (v) {
          if (v != null && !v.startsWith("HEADER_")) {
            setState(() => _selectedCategory = v);
          }
        },
      ),
    );
  }

  Widget _getCategoryIcon(String category) {
    IconData icon;
    Color color;
    final c = category.toLowerCase();

    color = AppDesign.petPink;
    if (c.contains('vet')) {
      icon = Icons.local_hospital;
    } else if (c.contains('farm') || c.contains('pharm')) {
      icon = Icons.medication;
    } else if (c.contains('shop') || c.contains('tienda')) {
      icon = Icons.shopping_basket;
    } else if (c.contains('banho') ||
        c.contains('grooming') ||
        c.contains('peluquer')) {
      icon = Icons.content_cut;
    } else if (c.contains('hotel')) {
      icon = Icons.hotel;
    } else if (c.contains('lab')) {
      icon = Icons.biotech;
    } else {
      icon = Icons.pets;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 16),
    );
  }
}
