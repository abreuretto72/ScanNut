import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/partner_model.dart';
import '../../../core/services/partner_service.dart';
import '../../../core/services/whatsapp_service.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/widgets/pdf_action_button.dart';
import '../../settings/settings_screen.dart';
import 'partner_registration_screen.dart';

class PartnersHubScreen extends ConsumerStatefulWidget {
  final bool isSelectionMode;

  const PartnersHubScreen({Key? key, this.isSelectionMode = false}) : super(key: key);

  @override
  ConsumerState<PartnersHubScreen> createState() => _PartnersHubScreenState();
}

class _PartnersHubScreenState extends ConsumerState<PartnersHubScreen> {
  final PartnerService _service = PartnerService();
  List<PartnerModel> _registeredPartners = [];
  bool _loading = true;
  String _selectedCategory = 'Todos';

  final List<String> _filterCategories = [
    'Todos',
    'Veterinário',
    'Pet Shop',
    'Farmácias Pet',
    'Banho e Tosa',
    'Hotéis',
    'Laboratórios'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _loading = true);
      await _service.init();
      _registeredPartners = _service.getAllPartners();
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
          if (result == true) _loadData();
        },
      ),
    );
  }

  void _openManualRegistration() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PartnerRegistrationScreen()),
    );
    if (result == true) _loadData();
  }

  Future<void> _generatePdf() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gerar PDF: Funcionalidade em desenvolvimento'), backgroundColor: Colors.redAccent),
    );
  }

  List<PartnerModel> get _filteredPartners {
    if (_selectedCategory == 'Todos') return _registeredPartners;
    return _registeredPartners.where((p) => p.category == _selectedCategory).toList();
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
              title: Text(widget.isSelectionMode ? 'Selecionar Parceiro' : 'Meu Hub de Apoio', 
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
        label: Text('CADASTRAR', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
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
              _selectedCategory == 'Todos' 
                ? 'Sua rede de apoio está vazia' 
                : 'Nenhum parceiro em "$_selectedCategory"', 
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 16)
            ),
            const SizedBox(height: 8),
            Text('Use o Radar para descobrir locais próximos', style: GoogleFonts.poppins(color: Colors.white24, fontSize: 12)),
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
              if (result == true) _loadData();
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
                    mensagem: 'Olá, venho através do ScanNut e gostaria de informações sobre seus serviços.',
                    );
                },
            ),
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
  String _selectedCategory = 'Todos';
  List<PartnerModel> _discoveredResults = [];
  bool _isLoading = true;
  String _errorMessage = '';
  
  final List<String> _categories = [
    'Todos',
    'Veterinário',
    'Pet Shop',
    'Farmácias Pet',
    'Banho e Tosa',
    'Hotéis',
    'Laboratórios'
  ];

  @override
  void initState() {
    super.initState();
    _startDiscovery();
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
            _errorMessage = 'Permissão de localização negada.';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Permissão negada permanentemente nas configurações.';
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
          throw 'Não foi possível obter sua localização atual.';
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
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
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
            const Text('Detectamos estabelecimentos reais na sua região', style: TextStyle(color: Colors.white38, fontSize: 13)),
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
                        Text('Rastreando estabelecimentos via GPS...', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  )
                : _errorMessage.isNotEmpty
                  ? Center(child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
                    ))
                  : _filteredResults.isEmpty 
                    ? Center(child: Text('Nenhum local nesta categoria.', style: GoogleFonts.poppins(color: Colors.white38)))
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
