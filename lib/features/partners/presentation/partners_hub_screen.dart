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

class PartnersHubScreen extends ConsumerStatefulWidget {
  final bool isSelectionMode;

  const PartnersHubScreen({Key? key, this.isSelectionMode = false}) : super(key: key);

  @override
  ConsumerState<PartnersHubScreen> createState() => _PartnersHubScreenState();
}

class _PartnersHubScreenState extends ConsumerState<PartnersHubScreen> {
  final PartnerService _service = PartnerService();
  List<PartnerModel> _allPartners = [];
  bool _loading = true;
  late String _selectedCategory; // Initialized in didChangeDependencies

  List<String> get _filterCategories => [
    AppLocalizations.of(context)!.partnersFilterAll,
    AppLocalizations.of(context)!.partnersFilterVet,
    AppLocalizations.of(context)!.partnersFilterPetShop,
    AppLocalizations.of(context)!.partnersFilterPharmacy,
    AppLocalizations.of(context)!.partnersFilterGrooming,
    AppLocalizations.of(context)!.partnersFilterHotel,
    AppLocalizations.of(context)!.partnersFilterLab,
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = ''; // Initialize empty
    _loadPartners();
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
    return c == 'todos' || c == 'all' || 
           c == AppLocalizations.of(context)!.partnersFilterAll.toLowerCase();
  }

  Future<void> _loadPartners() async { // Renamed from _loadData
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
      backgroundColor: Colors.grey.shade900,
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
              builder: (context) => PartnerRegistrationScreen(initialData: partner),
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
      MaterialPageRoute(builder: (context) => const PartnerRegistrationScreen()),
    );
    if (result == true) _loadPartners(); // Updated call
  }

  Future<void> _generatePdf() async {
    String selectedReportCategory = AppLocalizations.of(context)!.partnersFilterAll;
    String selectedReportType = AppLocalizations.of(context)!.partnersSummary;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            AppLocalizations.of(context)!.partnersExportPdf,
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.partnersCategory, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
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
                        dropdownColor: Colors.grey[850],
                        style: const TextStyle(color: Colors.white),
                        items: _filterCategories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                        onChanged: (val) => setDialogState(() => selectedReportCategory = val!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(AppLocalizations.of(context)!.partnersDetailLevel, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildTypeOption(
                        AppLocalizations.of(context)!.partnersSummary,
                        selectedReportType == AppLocalizations.of(context)!.partnersSummary,
                        () => setDialogState(() => selectedReportType = AppLocalizations.of(context)!.partnersSummary)
                      ),
                      const SizedBox(width: 12),
                      _buildTypeOption(
                        AppLocalizations.of(context)!.partnersDetailed,
                        selectedReportType == AppLocalizations.of(context)!.partnersDetailed,
                        () => setDialogState(() => selectedReportType = AppLocalizations.of(context)!.partnersDetailed)
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context)!.partnersExportDisclaimer,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _executePdfGeneration(selectedReportCategory, selectedReportType);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E676),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      child: Text(AppLocalizations.of(context)!.partnersGenerateReport, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.1)),
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
                child: Text(AppLocalizations.of(context)!.partnersBack, style: const TextStyle(color: Colors.white24, fontSize: 12)),
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
            color: isSelected ? const Color(0xFF00E676).withOpacity(0.2) : Colors.white.withOpacity(0.05),
            border: Border.all(color: isSelected ? const Color(0xFF00E676) : Colors.white10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: isSelected ? const Color(0xFF00E676) : Colors.white38,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _executePdfGeneration(String selectedCategory, String type) async {
    final reportPartners = _isAll(selectedCategory)
        ? _allPartners
        : _allPartners.where((p) => _isSameCategory(p.category, selectedCategory)).toList();

    if (reportPartners.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.noPartnersForFilters), backgroundColor: Colors.orange),
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
    return _allPartners.where((p) => _isSameCategory(p.category, _selectedCategory)).toList();
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
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            backgroundColor: Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.isSelectionMode ? AppLocalizations.of(context)!.partnersSelectTitle : AppLocalizations.of(context)!.partnersTitle,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
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
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Color(0xFF00E676))))
          else if (_filteredPartners.isEmpty)
            _buildEmptyState()
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildPartnerCard(_filteredPartners[index]),
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
        backgroundColor: const Color(0xFF00E676),
        icon: const Icon(Icons.add, color: Colors.black),
        label: Text(AppLocalizations.of(context)!.partnersRegister, style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildFilterBar() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filterCategories.length,
        itemBuilder: (context, index) {
          final category = _filterCategories[index];
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(category, style: GoogleFonts.poppins(
                color: isSelected ? Colors.black : Colors.white,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              )),
              backgroundColor: Colors.white.withOpacity(0.05),
              selectedColor: const Color(0xFF00E676),
              checkmarkColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onSelected: (selected) {
                setState(() => _selectedCategory = category);
              },
            ),
          );
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
            Icon(Icons.handshake_outlined, size: 80, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 16),
            Text(
              _selectedCategory == AppLocalizations.of(context)!.partnersFilterAll
                ? AppLocalizations.of(context)!.partnersNoneFound
                : AppLocalizations.of(context)!.partnersNoneInCategory(_selectedCategory),
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 16)
            ),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.partnersRadarHint, style: GoogleFonts.poppins(color: Colors.white24, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerCard(PartnerModel partner) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        onTap: () async {
          if (widget.isSelectionMode) {
              Navigator.pop(context, partner);
          } else {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PartnerRegistrationScreen(initialData: partner),
                ),
              );
              if (result == true) _loadPartners(); // Updated call
          }
        },
        contentPadding: const EdgeInsets.all(16),
        leading: _getCategoryIcon(partner.category),
        title: Text(partner.name, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: Text(partner.category, style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12)),
        trailing: widget.isSelectionMode
            ? const Icon(Icons.check_circle_outline, color: Color(0xFF00E676))
            : IconButton(
                icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF00E676)),
                onPressed: () {
                    WhatsAppService.abrirChat(
                    telefone: partner.phone,
                    mensagem: AppLocalizations.of(context)!.whatsappInitialMessage,
                    );
                },
            ),
      ),
    );
  }

  Widget _getCategoryIcon(String category) {
    IconData icon;
    Color color;
    final c = category.toLowerCase();
    
    if (c.contains('vet')) { icon = Icons.local_hospital; color = Colors.redAccent; }
    else if (c.contains('farm') || c.contains('pharm')) { icon = Icons.medication; color = Colors.blueAccent; }
    else if (c.contains('shop') || c.contains('tienda')) { icon = Icons.shopping_basket; color = Colors.orangeAccent; }
    else if (c.contains('banho') || c.contains('grooming') || c.contains('peluquer')) { icon = Icons.content_cut; color = Colors.purpleAccent; }
    else if (c.contains('hotel')) { icon = Icons.hotel; color = Colors.amberAccent; }
    else if (c.contains('lab')) { icon = Icons.biotech; color = Colors.cyanAccent; }
    else { icon = Icons.pets; color = Colors.greenAccent; }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
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

  List<String> get _categories => [
    AppLocalizations.of(context)!.partnersFilterAll,
    AppLocalizations.of(context)!.partnersFilterVet,
    AppLocalizations.of(context)!.partnersFilterPetShop,
    AppLocalizations.of(context)!.partnersFilterPharmacy,
    AppLocalizations.of(context)!.partnersFilterGrooming,
    AppLocalizations.of(context)!.partnersFilterHotel,
    AppLocalizations.of(context)!.partnersFilterLab,
  ];

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
    return c == 'todos' || c == 'all' || 
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
          authTrace.endStep('GPS.checkPermission', success: false, details: 'Permission Denied');
          setState(() {
            _isLoading = false;
            _errorMessage = AppLocalizations.of(context)!.partnersLocationDenied;
          });
          return;
        }
      }
      authTrace.endStep('GPS.checkPermission');

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _errorMessage = AppLocalizations.of(context)!.partnersLocationPermanentlyDenied;
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
        logger.info('📍 Coordenadas capturadas: Lat: ${position.latitude}, Lng: ${position.longitude}');
        authTrace.endStep('GPS.getPosition', details: 'Lat: ${position.latitude}, Lng: ${position.longitude}');
      } catch (e) {
        logger.warning('⚠️ Falha ao obter posição atual, tentando última conhecida: $e');
        final lastPos = await Geolocator.getLastKnownPosition();
        if (lastPos != null) {
          position = lastPos;
          logger.info('📍 Usando última posição conhecida: Lat: ${position.latitude}, Lng: ${position.longitude}');
          authTrace.endStep('GPS.getPosition', details: 'Using last known pos');
        } else {
          authTrace.endStep('GPS.getPosition', success: false, details: e.toString());
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
      
      authTrace.endStep('GooglePlaces.search', details: 'Found ${results.length} results');

      if (mounted) {
        setState(() {
          _discoveredResults = results;
          _isLoading = false;
        });
      }
      authTrace.endStep('RadarDiscovery.start', details: 'Flow Completed Successfully');
    } catch (e, stack) {
      String technicalDetails = e.toString();
      bool isAuthError = technicalDetails.contains('10') || technicalDetails.contains('DEVELOPER_ERROR') || technicalDetails.contains('AUTH');
      
      authTrace.endStep('RadarDiscovery.start', success: false, details: technicalDetails);
      logger.error('❌ Erro na busca por radar', error: e, stackTrace: stack);

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (isAuthError) {
             _errorMessage = 'Erro de Autenticação Google (ApiException 10).\n'
                             'Verifique as credenciais SHA-1 no console do Firebase.\n\n'
                             'Detalhes: $technicalDetails';
          } else {
             _errorMessage = 'Erro ao buscar dados: $e';
          }
        });
      }
    }
  }

  List<PartnerModel> get _filteredResults {
    if (_isAll(_selectedCategory)) return _discoveredResults;
    return _discoveredResults.where((p) => _isSameCategory(p.category, _selectedCategory)).toList();
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
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsScreen()),
                ).then((_) => _startDiscovery()); // Re-search if settings changed
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.explore, color: Colors.blueAccent, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Radar Explorer (${ref.watch(settingsProvider).partnerSearchRadius.toInt()}km)', 
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
                          ),
                          const Text(
                            'Toque para alterar o raio de busca', 
                            style: TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.w500)
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.settings_outlined, color: Colors.white24, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.partnersRadarDetecting, style: const TextStyle(color: Colors.white38, fontSize: 13)),
            const SizedBox(height: 16),
            _buildRadarFilterBar(),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading 
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: Colors.blueAccent),
                        const SizedBox(height: 16),
                        Text(AppLocalizations.of(context)!.partnersRadarTracking, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  )
                  : _errorMessage.isNotEmpty
                   ? Center(child: Padding(
                       padding: const EdgeInsets.all(20),
                       child: Column(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                           const SizedBox(height: 16),
                           Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                           const SizedBox(height: 24),
                           ElevatedButton.icon(
                             onPressed: _startDiscovery,
                             icon: const Icon(Icons.refresh, size: 18),
                             label: const Text('Tentar Novamente'),
                             style: ElevatedButton.styleFrom(backgroundColor: Colors.white10),
                           ),
                           const SizedBox(height: 12),
                           TextButton.icon(
                             onPressed: () {
                               showDialog(
                                 context: context,
                                 builder: (context) => AlertDialog(
                                   backgroundColor: Colors.grey[900],
                                   title: const Text('Trace de Diagnóstico', style: TextStyle(color: Colors.white)),
                                   content: SizedBox(
                                     width: double.maxFinite,
                                     child: SingleChildScrollView(
                                       child: Text(authTrace.getTraceAsString(), style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace')),
                                     ),
                                   ),
                                   actions: [
                                     TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
                                     TextButton(
                                       onPressed: () {
                                         Clipboard.setData(ClipboardData(text: authTrace.getTraceAsString()));
                                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logs copiados!')));
                                       }, 
                                       child: const Text('Copiar')
                                     ),
                                   ],
                                 ),
                               );
                             },
                             icon: const Icon(Icons.bug_report_outlined, size: 18, color: Colors.blueAccent),
                             label: const Text('Ver Detalhes Técnicos', style: TextStyle(color: Colors.blueAccent)),
                           ),
                         ],
                       ),
                     ))
                  : _filteredResults.isEmpty 
                    ? Center(child: Text(AppLocalizations.of(context)!.partnersRadarNoResults, style: GoogleFonts.poppins(color: Colors.white38)))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _filteredResults.length,
                        itemBuilder: (context, index) {
                          final p = _filteredResults[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(15)),
                            child: ListTile(
                              leading: _getCategoryIcon(p.category),
                              title: Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              subtitle: Text("${p.category} • ${p.address}", 
                                  maxLines: 1, 
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
                              trailing: const Icon(Icons.chevron_right, color: Colors.blueAccent),
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

  Widget _buildRadarFilterBar() {
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(category, style: GoogleFonts.poppins(
                fontSize: 11,
                color: isSelected ? Colors.black : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              )),
              selected: isSelected,
              selectedColor: Colors.blueAccent,
              backgroundColor: Colors.white.withOpacity(0.05),
              onSelected: (selected) {
                setState(() => _selectedCategory = category);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _getCategoryIcon(String category) {
    IconData icon;
    Color color;
    final c = category.toLowerCase();
    
    if (c.contains('vet')) { icon = Icons.local_hospital; color = Colors.redAccent; }
    else if (c.contains('farm') || c.contains('pharm')) { icon = Icons.medication; color = Colors.blueAccent; }
    else if (c.contains('shop') || c.contains('tienda')) { icon = Icons.shopping_basket; color = Colors.orangeAccent; }
    else if (c.contains('banho') || c.contains('grooming') || c.contains('peluquer')) { icon = Icons.content_cut; color = Colors.purpleAccent; }
    else if (c.contains('hotel')) { icon = Icons.hotel; color = Colors.amberAccent; }
    else if (c.contains('lab')) { icon = Icons.biotech; color = Colors.cyanAccent; }
    else { icon = Icons.pets; color = Colors.greenAccent; }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 16),
    );
  }
}
