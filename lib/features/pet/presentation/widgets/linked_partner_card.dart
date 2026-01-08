import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:scannut/l10n/app_localizations.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../core/models/partner_model.dart';

// Private widget extracted to be public/reusable if needed, 
// but currently just moved to reduce file size.
class LinkedPartnerCard extends StatefulWidget {
  final PartnerModel partner;
  final VoidCallback onUnlink;
  final Function(PartnerModel) onUpdate;
  final VoidCallback onOpenAgenda;

  const LinkedPartnerCard({
    Key? key,
    required this.partner,
    required this.onUnlink,
    required this.onUpdate,
    required this.onOpenAgenda,
  }) : super(key: key);

  @override
  State<LinkedPartnerCard> createState() => _LinkedPartnerCardState();
}

class _LinkedPartnerCardState extends State<LinkedPartnerCard> {
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
            SnackBar(content: Text(AppLocalizations.of(context)!.errorOpeningApp))
          );
        }
      }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withOpacity(0.08),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppDesign.petPink.withOpacity(0.3))),
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
                                 Text(widget.partner.category, style: const TextStyle(color: AppDesign.petPink, fontSize: 12)),
                             ],
                         ),
                     ),
                     Column(
                       children: [
                         Switch(
                             value: true, 
                             activeColor: AppDesign.petPink,
                             onChanged: (v) {
                                 if (!v) widget.onUnlink();
                             }
                         ),
                         Text(AppLocalizations.of(context)!.petPartnersLinked, style: const TextStyle(color: Colors.white54, fontSize: 10))
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
                                 widget.partner.address.isNotEmpty ? widget.partner.address : AppLocalizations.of(context)!.petPartnersNoAddress,
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
                             decoration: InputDecoration(
                                 isDense: true,
                                 border: InputBorder.none,
                                 hintText: AppLocalizations.of(context)!.petPartnersPhoneHint,
                                 hintStyle: const TextStyle(color: Colors.white30),
                                 enabledBorder: InputBorder.none,
                                 focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppDesign.petPink)),
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
                         color: AppDesign.petPink, 
                         label: AppLocalizations.of(context)!.petPartnersCall, 
                         onTap: () => _launch('tel', widget.partner.phone)
                     ),
                     _ActionIcon(
                         icon: Icons.event_note, 
                         color: Colors.amberAccent, 
                         label: AppLocalizations.of(context)!.petPartnersSchedule, 
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
