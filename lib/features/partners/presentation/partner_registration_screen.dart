import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:developer' as dev;
import 'package:geolocator/geolocator.dart';
import '../../../core/models/partner_model.dart';
import '../../../core/services/partner_service.dart';
import '../../../core/providers/settings_provider.dart';
import '../../settings/settings_screen.dart';
import 'package:uuid/uuid.dart';

class PartnerRegistrationScreen extends StatefulWidget {
  final PartnerModel? initialData;

  const PartnerRegistrationScreen({Key? key, this.initialData}) : super(key: key);

  @override
  State<PartnerRegistrationScreen> createState() => _PartnerRegistrationScreenState();
}

class _PartnerRegistrationScreenState extends State<PartnerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = PartnerService();
  
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _openingHoursController = TextEditingController();
  final _instagramController = TextEditingController();
  final _specialtiesController = TextEditingController();
  String _category = 'Veterinário';
  bool _is24h = false;
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _nameController.text = widget.initialData!.name;
      _addressController.text = widget.initialData!.address;
      _phoneController.text = widget.initialData!.phone;
      _instagramController.text = widget.initialData!.instagram ?? '';
      _specialtiesController.text = widget.initialData!.specialties.join(', ');
      _openingHoursController.text = widget.initialData!.openingHours['raw'] ?? '';
      _is24h = widget.initialData!.openingHours['plantao24h'] ?? false;
      _category = widget.initialData!.category;
      _lat = widget.initialData!.latitude;
      _lng = widget.initialData!.longitude;
    }
  }

  Future<void> _startRadarSearch() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => _RadarBottomSheet(
        onPartnerSelected: (partner) {
          setState(() {
            _nameController.text = partner.name;
            _addressController.text = partner.address;
            _phoneController.text = partner.phone;
            _instagramController.text = partner.instagram ?? '';
            _specialtiesController.text = partner.specialties.join(', ');
            _openingHoursController.text = partner.openingHours['raw'] ?? '';
            _is24h = partner.openingHours['plantao24h'] ?? false;
            _category = partner.category;
            _lat = partner.latitude;
            _lng = partner.longitude;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _deletePartner() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text('Excluir Parceiro', style: GoogleFonts.poppins(color: Colors.white)),
        content: Text('Deseja remover "${widget.initialData!.name}" da sua rede de apoio?', style: GoogleFonts.poppins(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _service.init();
      await _service.deletePartner(widget.initialData!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Parceiro removido.'), backgroundColor: Colors.redAccent),
        );
        Navigator.pop(context, true);
      }
    }
  }

  void _savePartner() async {
    debugPrint("Iniciando salvamento do parceiro...");
    if (_formKey.currentState!.validate()) {
      final specialties = _specialtiesController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final partner = PartnerModel(
        id: widget.initialData?.id ?? const Uuid().v4(),
        name: _nameController.text,
        category: _category,
        latitude: _lat ?? 0.0,
        longitude: _lng ?? 0.0,
        phone: _phoneController.text,
        whatsapp: _phoneController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        instagram: _instagramController.text.isNotEmpty ? _instagramController.text : null,
        address: _addressController.text,
        specialties: specialties,
        openingHours: {
          'plantao24h': _is24h,
          'raw': _openingHoursController.text,
        },
      );

      try {
        await _service.init();
        await _service.savePartner(partner);
        debugPrint("Parceiro salvo com sucesso no Hive.");

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Parceiro "${partner.name}" salvo com sucesso!'),
              backgroundColor: const Color(0xFF00E676),
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        debugPrint("Erro fatal ao salvar: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.redAccent),
          );
        }
      }
    } else {
      debugPrint("Validação do formulário falhou.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.initialData != null ? 'Editar Parceiro' : 'Cadastrar Parceiro', style: GoogleFonts.poppins()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (widget.initialData != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: _deletePartner,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildRadarButton(),
              const SizedBox(height: 32),
              _buildTextField(_nameController, 'Nome do Estabelecimento', Icons.business),
              const SizedBox(height: 16),
              _buildCategoryDropdown(),
              const SizedBox(height: 16),
              _buildTextField(_phoneController, 'Telefone / WhatsApp', Icons.phone),
              const SizedBox(height: 16),
              _buildTextField(_instagramController, 'Instagram (ex: @meupet)', Icons.camera_alt),
              const SizedBox(height: 16),
              _buildTextField(_openingHoursController, 'Horário de Funcionamento', Icons.access_time),
              const SizedBox(height: 16),
              _build24hSwitch(),
              const SizedBox(height: 16),
              _buildTextField(_specialtiesController, 'Especialidades (separe por vírgula)', Icons.stars),
              const SizedBox(height: 16),
              _buildTextField(_addressController, 'Endereço Completo', Icons.location_on, maxLines: 2),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _savePartner,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 8,
                ),
                child: Text('SALVAR PARCEIRO', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 100), // Extra space to scroll past the keyboard
            ],
          ),
        ),
      ),
    );
  }

  bool _isRadarSearching = false;

  Widget _buildRadarButton() {
    return InkWell(
      onTap: () async {
        if (_isRadarSearching) return;
        setState(() => _isRadarSearching = true);
        await _startRadarSearch();
        if (mounted) setState(() => _isRadarSearching = false);
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.blue.shade900, Colors.blue.shade600]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, spreadRadius: 2)],
        ),
        child: Row(
          children: [
            const Icon(Icons.radar, color: Colors.white, size: 40),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Busca Inteligente por Radar', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('Encontre e importe dados via GPS', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _build24hSwitch() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: SwitchListTile(
        title: Text('Plantão 24h / Emergência', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
        subtitle: const Text('Local funciona ininterruptamente', style: TextStyle(color: Colors.white38, fontSize: 11)),
        value: _is24h,
        activeColor: const Color(0xFF00E676),
        onChanged: (v) => setState(() => _is24h = v),
        secondary: const Icon(Icons.emergency_share, color: Colors.redAccent),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: const Color(0xFF00E676)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
      validator: (v) => null,
    );
  }

  Widget _buildCategoryDropdown() {
    final List<String> categories = ['Veterinário', 'Pet Shop', 'Farmácias Pet', 'Banho e Tosa', 'Hotéis', 'Laboratórios'];
    if (!categories.contains(_category) && _category != 'Pet Shop') {
        _category = 'Pet Shop';
    }
    return DropdownButtonFormField<String>(
      value: _category,
      dropdownColor: Colors.grey.shade900,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Categoria',
        labelStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: const Icon(Icons.category, color: Color(0xFF00E676)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
      items: categories
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: (v) => setState(() => _category = v!),
    );
  }
}

class _RadarBottomSheet extends ConsumerStatefulWidget {
  final Function(PartnerModel) onPartnerSelected;

  const _RadarBottomSheet({required this.onPartnerSelected});

  @override
  ConsumerState<_RadarBottomSheet> createState() => _RadarBottomSheetState();
}

class _RadarBottomSheetState extends ConsumerState<_RadarBottomSheet> {
  final PartnerService _service = PartnerService();
  List<PartnerModel> _discovered = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _discover();
  }

  Future<void> _discover() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // 1. Check Permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.always && permission != LocationPermission.whileInUse) {
           throw 'Permissão de localização necessária.';
        }
      }

      // 2. Get Coords with Timeout
      Position? pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      ).catchError((_) => Geolocator.getLastKnownPosition());

      if (pos == null || (pos.latitude == 0.0 && pos.longitude == 0.0)) {
        throw 'GPS não retornou coordenadas válidas. Verifique as permissões.';
      }

      print('📍 GPS Capturado: Lat=${pos.latitude}, Lng=${pos.longitude}');

      // 3. Step 1: Search in 10KM (Optimized Radius)
      debugPrint("Radar: Iniciando busca em 10km...");
      var results = await _service.discoverNearbyPartners(
        lat: pos.latitude,
        lng: pos.longitude,
        radiusKm: 10.0,
      );

      // 4. Step 2: Auto-Expand to 20KM if empty
      if (results.isEmpty) {
        debugPrint("Radar: Nenhum resultado em 10km. Expandindo para 20km...");
        if (mounted) {
          setState(() => _error = 'Ampliando área de busca para 20km...');
        }
        results = await _service.discoverNearbyPartners(
          lat: pos.latitude,
          lng: pos.longitude,
          radiusKm: 20.0,
        );
      }

      if (mounted) {
        setState(() {
          _discovered = results;
          _isLoading = false;
          _error = results.isEmpty ? 'Nenhum parceiro encontrado nesta região.' : '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      height: 500,
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ).then((_) => _discover());
            },
            borderRadius: BorderRadius.circular(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Radar Geo (${ref.watch(settingsProvider).partnerSearchRadius.toInt()}km)', 
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
                      ),
                      const Text(
                        'Toque para alterar o raio de busca', 
                        style: TextStyle(color: Color(0xFF00E676), fontSize: 11, fontWeight: FontWeight.w500)
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.radar, color: Color(0xFF00E676)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('Estabelecimentos reais detectados na sua região:', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF00E676)),
                      const SizedBox(height: 16),
                      Text('Sintonizando Radar e GPS...', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                )
              : _error.isNotEmpty
                ? Center(child: Text(_error, style: const TextStyle(color: Colors.redAccent)))
                : _discovered.isEmpty
                  ? Center(child: Text('Nenhum local encontrado.', style: GoogleFonts.poppins(color: Colors.white38)))
                  : ListView.builder(
                      itemCount: _discovered.length,
                      itemBuilder: (context, index) {
                        final p = _discovered[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.withOpacity(0.1),
                            child: Icon(_getIcon(p.category), color: Colors.blue, size: 20),
                          ),
                          title: Text(p.name, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text('${p.category} • ${p.address}', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11)),
                          onTap: () => widget.onPartnerSelected(p),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(String category) {
    switch (category) {
      case 'Veterinário': return Icons.local_hospital;
      case 'Farmácias Pet': return Icons.medication;
      case 'Pet Shop': return Icons.shopping_basket;
      case 'Banho e Tosa': return Icons.content_cut;
      case 'Hotéis': return Icons.hotel;
      case 'Laboratórios': return Icons.biotech;
      default: return Icons.pets;
    }
  }
}
