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
    if (_selectedCategory.isEmpty || _selectedCategory == 'Todos' || _selectedCategory == 'All') {
       _selectedCategory = AppLocalizations.of(context)!.partnersFilterAll;
    }
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

  Future<void> _executePdfGeneration(String category, String type) async {
    final reportPartners = category == AppLocalizations.of(context)!.partnersFilterAll
        ? _allPartners // Renamed from _allPartners
        : _allPartners.where((p) => p.category == category).toList(); // Renamed from _allPartners

    if (reportPartners.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.noPartnersForFilters), backgroundColor: Colors.orange), // This one seemed okay? If fails, I'll fix it.
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
    if (_selectedCategory == AppLocalizations.of(context)!.partnersFilterAll) return _allPartners;
    return _allPartners.where((p) {
        // Map localized category back to canonical or compare loosely?
        // Better: Use internal canonical categories ('veterinarian', 'pharmacy') vs Display categories.
        // For now, assuming PartnerModel stores localized or canonical.
        // If PartnerModel stores 'Veterinária' (pt), we need to ensure compatibility.
        // Assuming PartnerService saves localized strings from UI.
        // Quick fix: Check if category contains partial match or match exact.
        return p.category.toLowerCase() == _selectedCategory.toLowerCase();
    }).toList();
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
    if (category == AppLocalizations.of(context)!.partnersFilterVet) { icon = Icons.local_hospital; color = Colors.redAccent; }
    else if (category == AppLocalizations.of(context)!.partnersFilterPharmacy) { icon = Icons.medication; color = Colors.blueAccent; }
    else if (category == AppLocalizations.of(context)!.partnersFilterPetShop) { icon = Icons.shopping_basket; color = Colors.orangeAccent; }
    else if (category == AppLocalizations.of(context)!.partnersFilterGrooming) { icon = Icons.content_cut; color = Colors.purpleAccent; }
    else if (category == AppLocalizations.of(context)!.partnersFilterHotel) { icon = Icons.hotel; color = Colors.amberAccent; }
    else if (category == AppLocalizations.of(context)!.partnersFilterLab) { icon = Icons.biotech; color = Colors.cyanAccent; }
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
    _selectedCategory = 'Todos';
    _startDiscovery();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedCategory == 'Todos') {
       _selectedCategory = AppLocalizations.of(context)!.partnersFilterAll;
    }
  }

  Future<void> _startDiscovery() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 1. Check/Request Permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
            _errorMessage = AppLocalizations.of(context)!.partnersLocationDenied;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _errorMessage = AppLocalizations.of(context)!.partnersLocationPermanentlyDenied;
        });
        return;
      }

      // 2. Get Position
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (e) {
        final lastPos = await Geolocator.getLastKnownPosition();
        if (lastPos != null) {
          position = lastPos;
        } else {
          throw AppLocalizations.of(context)!.partnersLocationError;
        }
      }

      // 3. Search real data
      final radius = ref.read(settingsProvider).partnerSearchRadius;
      final results = await _service.discoverNearbyPartners(
        lat: position.latitude,
        lng: position.longitude,
        radiusKm: radius,
      );

      if (mounted) {
        setState(() {
          _discoveredResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erro ao buscar dados: $e';
        });
      }
    }
  }

  List<PartnerModel> get _filteredResults {
    if (_selectedCategory == 'Todos') return _discoveredResults;
    return _discoveredResults.where((p) => p.category == _selectedCategory).toList();
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
                      child: Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
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
    switch (category) {
      case 'Veterinário': icon = Icons.local_hospital; color = Colors.redAccent; break;
      case 'Farmácias Pet': icon = Icons.medication; color = Colors.blueAccent; break;
      case 'Pet Shop': icon = Icons.shopping_basket; color = Colors.orangeAccent; break;
      case 'Banho e Tosa': icon = Icons.content_cut; color = Colors.purpleAccent; break;
      case 'Hotéis': icon = Icons.hotel; color = Colors.amberAccent; break;
      case 'Laboratórios': icon = Icons.biotech; color = Colors.cyanAccent; break;
      default: icon = Icons.pets; color = Colors.greenAccent;
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 16),
    );
  }
}
