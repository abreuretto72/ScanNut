import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:scannut/l10n/app_localizations.dart';
import '../../../core/models/partner_model.dart';
import '../../../core/services/partner_service.dart';
import '../../../core/services/whatsapp_service.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/widgets/pdf_action_button.dart';
import '../../pet/models/pet_analysis_result.dart';
import '../../../core/services/export_service.dart';
import '../../../core/widgets/pdf_preview_screen.dart';
import '../../../core/theme/app_design.dart';
import 'partner_registration_screen.dart';
import 'widgets/partner_export_configuration_modal.dart';

class PartnersScreen extends ConsumerStatefulWidget {
  final PetAnalysisResult? suggestionContext;

  const PartnersScreen({super.key, this.suggestionContext});

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
    const userLat = -23.5500; // Mock
    const userLon = -46.6330; // Mock

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
          message = 'Olá, gostaria de saber mais sobre os serviços da ${partner.name}.';
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
        backgroundColor: AppDesign.surfaceDark,
        title: Text(
          'Cadastrar Parceiro (Em breve)', 
          style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark, fontWeight: FontWeight.bold)
        ),
        content: Text(
          'A funcionalidade de cadastro manual de parceiros está sendo finalizada. Por enquanto, os parceiros são homologados automaticamente pelo ScanNut.',
          style: GoogleFonts.poppins(color: AppDesign.textSecondaryDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: AppDesign.petPink)),
          )
        ],
      ),
    );
  }

  void _confirmPartnerRegistration(PartnerModel partner) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppDesign.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppLocalizations.of(context)!.partnersLinkTitle, 
          style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark, fontWeight: FontWeight.bold)
        ),
        content: Text(
          AppLocalizations.of(context)!.partnersLinkContent(partner.name),
          style: GoogleFonts.poppins(color: AppDesign.textSecondaryDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.btnCancel, style: const TextStyle(color: AppDesign.textSecondaryDark)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.partnersLinkSuccess(partner.name)))
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppDesign.petPink,
              foregroundColor: Colors.black,
            ),
            child: Text(AppLocalizations.of(context)!.partnersBtnLink, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final radius = ref.watch(settingsProvider).partnerSearchRadius;

    return Scaffold(
      backgroundColor: AppDesign.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppDesign.surfaceDark,
        title: Text(
          AppLocalizations.of(context)!.partnersTitle,
          style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: AppDesign.textPrimaryDark),
        elevation: 0,
        actions: [
          PdfActionButton(
            onPressed: _generatePartnersPDF,
          ),
          IconButton(
            icon: const Icon(Icons.add_business, color: AppDesign.petPink),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PartnerRegistrationScreen())),
            tooltip: AppLocalizations.of(context)!.partnerRegisterTitle,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator(color: AppDesign.petPink))
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
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PartnerRegistrationScreen())),
        backgroundColor: AppDesign.petPink,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildLocationBanner(double radius) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, color: AppDesign.textSecondaryDark, size: 16),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.of(context)!.partnersRadiusInfo(radius.toInt().toString()),
            style: GoogleFonts.poppins(color: AppDesign.textSecondaryDark, fontSize: 11),
          ),
          const Spacer(),
          Text(
            'SP (Mock Location)',
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 10),
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
            const Icon(Icons.location_off_outlined, color: AppDesign.textSecondaryDark, size: 64),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.partnersEmpty,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: AppDesign.textSecondaryDark),
            ),
            TextButton(
              onPressed: () {
                // Future navigation to settings
              },
              child: Text(AppLocalizations.of(context)!.partnersIncreaseRadius, style: const TextStyle(color: AppDesign.petPink)),
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
        color: AppDesign.petPink.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppDesign.petPink.withValues(alpha: 0.4))
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: AppDesign.petPink),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.partnersSuggestion,
              style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark, fontSize: 13, fontWeight: FontWeight.w500),
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
          color: Colors.white10,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: _buildCategoryIcon(partner.category),
              title: Text(
                partner.name, 
                style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.directions_walk, size: 12, color: AppDesign.petPink),
                      const SizedBox(width: 4),
                      Text(AppLocalizations.of(context)!.partnersKmFromYou(dist.toStringAsFixed(1)), style: const TextStyle(color: AppDesign.petPink, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    partner.address, 
                    style: GoogleFonts.poppins(color: AppDesign.textSecondaryDark, fontSize: 12),
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
                      const Icon(Icons.star, color: AppDesign.warning, size: 16),
                      Text(' ${partner.rating}', style: const TextStyle(color: AppDesign.textPrimaryDark, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (isOpen24h)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppDesign.error, borderRadius: BorderRadius.circular(4)),
                      child: const Text('24H', style: TextStyle(color: AppDesign.textPrimaryDark, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildActionButton(Icons.phone, AppLocalizations.of(context)!.partnersCall, () => launchUrl(Uri.parse('tel:${partner.phone}'))),
                    const SizedBox(width: 8),
                    if (partner.whatsapp != null)
                      _buildActionButton(Icons.chat_bubble_outline, 'WhatsApp', () => _sendWhatsApp(partner)),
                    const SizedBox(width: 8),
                    _buildActionButton(Icons.map_outlined, AppLocalizations.of(context)!.partnersMap, () {}),
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
      decoration: const BoxDecoration(
        color: Color(0x1A5C6BC0),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppDesign.info),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: const TextStyle(color: AppDesign.textSecondaryDark, fontSize: 10)),
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
            Icon(icon, size: 16, color: AppDesign.textSecondaryDark),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: AppDesign.textSecondaryDark, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Future<void> _generatePartnersPDF() async {
    if (_partners.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum parceiro para exportar!'))
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => PartnerExportConfigurationModal(
        allPartners: _partners,
        onGenerate: (selectedPartners) async {
          // Close the modal first
          Navigator.pop(modalContext);
          
          // Show loading dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => const Center(
              child: CircularProgressIndicator(color: AppDesign.petPink)
            ),
          );

          try {
            final pdf = await ExportService().generatePartnersReport(
              partners: selectedPartners,
              region: 'SP (Mock Location)',
              strings: AppLocalizations.of(context)!,
            );

            // Close loading dialog
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }

            if (!mounted) return;
            
            // Navigate to PDF preview
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PdfPreviewScreen(
                  title: 'Guia de Parceiros ScanNut',
                  buildPdf: (format) async => pdf.save(),
                ),
              ),
            );
          } catch (e) {
            // Close loading dialog on error
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
            
            debugPrint('Erro ao gerar PDF: $e');
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erro ao gerar PDF: $e'), backgroundColor: AppDesign.error),
              );
            }
          }
        },
      ),
    );
  }
}