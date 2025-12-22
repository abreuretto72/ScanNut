import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/partner_model.dart';
import '../../../core/services/partner_service.dart';
import '../../../core/services/whatsapp_service.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/widgets/pdf_action_button.dart';
import '../../pet/models/pet_analysis_result.dart';

class PartnersScreen extends ConsumerStatefulWidget {
  final PetAnalysisResult? suggestionContext;

  const PartnersScreen({Key? key, this.suggestionContext}) : super(key: key);

  @override
  ConsumerState<PartnersScreen> createState() => _PartnersScreenState();
}

class _PartnersScreenState extends ConsumerState<PartnersScreen> {
  final PartnerService _service = PartnerService();
  
  List<PartnerModel> _partners = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPartners();
  }

  Future<void> _loadPartners() async {
    setState(() => _loading = true);
    await _service.init();
    
    final settings = ref.read(settingsProvider);
    final userLat = -23.5500; // Mock
    final userLon = -46.6330; // Mock

    List<PartnerModel> allInRadius = _service.getPartnersInRadius(
      userLat: userLat, 
      userLon: userLon, 
      radiusKm: settings.partnerSearchRadius
    );

    if (widget.suggestionContext != null) {
      _partners = _service.suggestPartners(widget.suggestionContext!);
    } else {
      _partners = allInRadius;
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _sendWhatsApp(PartnerModel partner) {
    String message = '';
    if (widget.suggestionContext != null) {
      switch (partner.category) {
        case 'Veterinário':
          message = WhatsAppService.gerarMensagemVeterinario(
            petName: 'Seu Pet',
            raca: widget.suggestionContext!.raca,
            statusSaude: widget.suggestionContext!.orientacaoImediata,
          );
          break;
        default:
          message = 'Olá, gostaria de saber mais sobre os serviços da ' + partner.name + '.';
      }
    } else {
      message = 'Olá, vi sua empresa no ScanNut e gostaria de mais informações.';
    }
    WhatsAppService.abrirChat(telefone: partner.phone, mensagem: message);
  }

  void _showAddPartnerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(
          'Cadastrar Parceiro (Em breve)', 
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        content: Text(
          'A funcionalidade de cadastro manual de parceiros está sendo finalizada. Por enquanto, os parceiros são homologados automaticamente pelo ScanNut.',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF00E676))),
          )
        ],
      ),
    );
  }

  void _confirmPartnerRegistration(PartnerModel partner) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Vincular Parceiro', 
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        content: Text(
          'Deseja adicionar "' + partner.name + '" à sua Rede de Apoio personalizada?',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(partner.name + ' vinculado com sucesso!'))
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676)),
            child: const Text('Vincular', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final radius = ref.watch(settingsProvider).partnerSearchRadius;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
        title: Text(
          'Futuros Parceiros',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          PdfActionButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gerar PDF: Funcionalidade em desenvolvimento'), backgroundColor: Colors.blueAccent),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_business, color: Color(0xFF00E676)),
            onPressed: () => _showAddPartnerDialog(),
            tooltip: 'Cadastrar Parceiro',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)))
        : Column(
            children: [
              _buildLocationBanner(radius),
              if (widget.suggestionContext != null) _buildSuggestionBanner(),
              Expanded(
                child: _partners.isEmpty 
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _partners.length,
                      itemBuilder: (context, index) => _buildPartnerCard(_partners[index]),
                    ),
              ),
            ],
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPartnerDialog(),
        backgroundColor: const Color(0xFF00E676),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildLocationBanner(double radius) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, color: Colors.white60, size: 16),
          const SizedBox(width: 8),
          Text(
            'Mostrando parceiros em um raio de ' + radius.toInt().toString() + 'km',
            style: GoogleFonts.poppins(color: Colors.white60, fontSize: 11),
          ),
          const Spacer(),
          Text(
            'SP (Mock Location)',
            style: GoogleFonts.poppins(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off_outlined, color: Colors.white24, size: 64),
            const SizedBox(height: 16),
            Text(
              'Nenhum parceiro encontrado\nneste raio de busca.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white54),
            ),
            TextButton(
              onPressed: () {
                // Future navigation to settings
              },
              child: const Text('Aumentar Raio de Busca', style: TextStyle(color: Color(0xFF00E676))),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF00E676).withOpacity(0.15),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF00E676).withOpacity(0.4))
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFF00E676)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Baseado na análise do seu pet, encontramos estes especialistas para você.',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPartnerCard(PartnerModel partner) {
    bool isOpen24h = partner.openingHours['plantao24h'] == true;
    final dist = _service.calculateDistance(-23.5500, -46.6330, partner.latitude, partner.longitude);

    return InkWell(
      onTap: () => _confirmPartnerRegistration(partner),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: _buildCategoryIcon(partner.category),
              title: Text(
                partner.name, 
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.directions_walk, size: 12, color: Color(0xFF00E676)),
                      const SizedBox(width: 4),
                      Text(dist.toStringAsFixed(1) + ' km de você', style: const TextStyle(color: Color(0xFF00E676), fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    partner.address, 
                    style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: partner.specialties.map((s) => _buildTag(s)).toList(),
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      Text(' ' + partner.rating.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (isOpen24h)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(4)),
                      child: const Text('24H', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
            const Divider(color: Colors.white10, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildActionButton(Icons.phone, 'Ligar', () => launchUrl(Uri.parse('tel:' + partner.phone))),
                    const SizedBox(width: 8),
                    if (partner.whatsapp != null)
                      _buildActionButton(Icons.chat_bubble_outline, 'WhatsApp', () => _sendWhatsApp(partner)),
                    const SizedBox(width: 8),
                    _buildActionButton(Icons.map_outlined, 'Mapa', () {}),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(String category) {
    IconData icon;
    switch (category) {
      case 'Veterinário': icon = Icons.local_hospital; break;
      case 'Pet Shop': icon = Icons.shopping_basket; break;
      case 'Banho e Tosa': icon = Icons.content_cut; break;
      case 'Farmácias': icon = Icons.medication; break;
      default: icon = Icons.store;
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.blueAccent),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white70),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}