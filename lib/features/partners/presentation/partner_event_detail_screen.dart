import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:scannut/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/partner_model.dart';
import '../../../core/services/partner_service.dart';
import '../../pet/models/pet_event.dart';
import '../../pet/services/pet_event_service.dart';
import '../../pet/presentation/widgets/edit_pet_form.dart';
import '../../pet/services/pet_profile_service.dart';
import 'partner_registration_screen.dart';
import 'widgets/add_event_modal.dart';
import '../models/agenda_event.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../core/theme/app_design.dart';

class PartnerEventDetailScreen extends StatefulWidget {
  final String partnerId;
  final PetEvent event;

  const PartnerEventDetailScreen({
    super.key,
    required this.partnerId,
    required this.event,
  });

  @override
  State<PartnerEventDetailScreen> createState() => _PartnerEventDetailScreenState();
}

class _PartnerEventDetailScreenState extends State<PartnerEventDetailScreen> {
  PartnerModel? _partner;
  late PetEvent _event;
  bool _isLoading = true;
  final stt.SpeechToText _speech = stt.SpeechToText();

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _loadPartner();
  }

  Future<void> _loadPartner() async {
    final service = PartnerService();
    await service.init(); // Garante box aberta
    
    try {
        final found = service.getPartner(widget.partnerId);
        setState(() {
            _partner = found;
            _isLoading = false;
        });
    } catch (e) {
        debugPrint('Error loading partner: $e');
        if (mounted) {
            setState(() {
                _isLoading = false;
            });
        }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: cleaned,
    );
    if (!await launchUrl(launchUri)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.errorOpeningApp)));
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    // Se não tiver código do país, assumir Brasil (55)
    String number = cleaned;
    if (number.length <= 11) {
      number = '55$number';
    }
    
    final url = Uri.parse('https://wa.me/$number');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorOpeningApp)),
        );
      }
    }
  }

  Future<void> _openMap(String address) async {
    final query = Uri.encodeComponent(address);
    final googleUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (!await launchUrl(googleUrl, mode: LaunchMode.externalApplication)) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.errorOpeningApp)));
    }
  }

  Future<void> _openEditModal() async {
    final profileService = PetProfileService();
    await profileService.init();
    final profile = await profileService.getProfile(_event.petName);
    
    if (profile == null) return;
    
    final agendaEvents = profile['data']?['agendaEvents'] as List? ?? [];
    final eventMap = agendaEvents.firstWhere(
      (e) => e['id'] == _event.id,
      orElse: () => null,
    );
    
    if (eventMap == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.agendaOriginalDataMissing))
        );
      }
      return;
    }
    
    final agendaEvent = AgendaEvent.fromJson(eventMap);
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppDesign.surfaceDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: AddEventModal(
            selectedDate: agendaEvent.dateTime,
            scrollController: scrollController,
            partner: _partner!,
            petId: _event.petName,
            existingEvent: agendaEvent,
              onSave: (updatedEvent) async {
              // Save back to profile
              final updatedEvents = List<Map<String, dynamic>>.from(agendaEvents);
              final index = updatedEvents.indexWhere((e) => e['id'] == agendaEvent.id);
              if (index != -1) {
                updatedEvents[index] = updatedEvent.toJson();
              }
              
              await profileService.saveOrUpdateProfile(_event.petName, profile);
              
                // Update local PetEvent to refresh UI
              final pType = updatedEvent.category.name == 'vacina' ? EventType.vaccine :
                            updatedEvent.category.name == 'banho' ? EventType.bath :
                            updatedEvent.category.name == 'tosa' ? EventType.grooming :
                            updatedEvent.category.name == 'consulta' ? EventType.veterinary :
                            updatedEvent.category.name == 'remedios' ? EventType.medication : EventType.other;
              
              if (mounted) {
                setState(() {
                   _event = PetEvent(
                      id: updatedEvent.id,
                      petId: _event.petId,
                      petName: _event.petName,
                      title: updatedEvent.title,
                      type: _event.type, // keep original or map
                      dateTime: updatedEvent.dateTime,
                      notes: updatedEvent.description,
                   );
                   _isLoading = false;
                });
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.agendaEventUpdated), backgroundColor: AppDesign.success)
                );
              }
            },
            speech: _speech,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesign.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppDesign.backgroundDark,
        title: Text(AppLocalizations.of(context)!.agendaServiceRecord, style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark)),
        leading: const BackButton(color: AppDesign.textPrimaryDark),
        actions: [
          if (_partner != null)
            IconButton(
              icon: const Icon(Icons.edit, color: AppDesign.petPink),
              onPressed: () => _openEditModal(),
            ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppDesign.petPink))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Detalhes do Agendamento
                  Text(
                    AppLocalizations.of(context)!.agendaAppointmentDetails,
                    style: GoogleFonts.poppins(
                      color: AppDesign.petPink,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildEventInfoCard(),
                  
                  const SizedBox(height: 32),
                  
                  // 2. Dados do Parceiro
                  Text(
                      AppLocalizations.of(context)!.agendaResponsiblePartner,
                    style: GoogleFonts.poppins(
                      color: AppDesign.petPink,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_partner != null) 
                    _buildPartnerInfoCard()
                  else
                    Text(AppLocalizations.of(context)!.agendaPartnerNotFound, style: const TextStyle(color: AppDesign.textSecondaryDark)),
                  
                  if (!_event.completed) ...[
                      const SizedBox(height: 32),
                      SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                              onPressed: () async {
                                  await PetEventService().markAsCompleted(_event.id);
                                  if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.agendaEventCompleted), backgroundColor: AppDesign.success));
                                      if (!mounted) return;
                                      Navigator.pop(context);
                                  }
                              },
                              icon: const Icon(Icons.check_circle_outline),
                              label: Text(AppLocalizations.of(context)!.agendaMarkCompleted),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white10,
                                  foregroundColor: AppDesign.petPink,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppDesign.petPink)),
                              ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildEventInfoCard() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');
    
    // Parse Attendant Logic
    String? attendantName;
    String displayNotes = _event.notes ?? '';
    if (displayNotes.startsWith('Atendente: ')) {
       final endIdx = displayNotes.indexOf('\n\n');
       if (endIdx != -1) {
          attendantName = displayNotes.substring(11, endIdx).trim();
          displayNotes = displayNotes.substring(endIdx + 2).trim();
       } else {
          attendantName = displayNotes.substring(11).trim();
          displayNotes = ''; // Todo conteúdo era o atendente
       }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_event.typeEmoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _event.title,
                      style: GoogleFonts.poppins(
                        color: AppDesign.textPrimaryDark,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _event.typeLabel,
                      style: const TextStyle(color: AppDesign.textSecondaryDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 32),
          _buildDetailRow(Icons.calendar_today, AppLocalizations.of(context)!.pdfDate, dateFormat.format(_event.dateTime)),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.access_time, AppLocalizations.of(context)!.pdfFieldTime, timeFormat.format(_event.dateTime)),
          const SizedBox(height: 12),
          
          if (attendantName != null) ...[
              _buildDetailRow(Icons.person, AppLocalizations.of(context)!.partnerDetailsRole, attendantName),
             const SizedBox(height: 12),
          ],

          // Pet Row with Navigation
          InkWell(
             onTap: () async {
                 final service = PetProfileService();
                 final profileData = await service.getProfile(_event.petName);
                 if (profileData != null && mounted) {
                     debugPrint('Navegando para o Pet: ${_event.petName} | Foto: ${profileData['photo_path']} | Vínculos: ${profileData['data']?['linked_partner_ids']}');
                     
                     Navigator.push(context, MaterialPageRoute(builder: (_) => EditPetForm(
                         petData: profileData,
                         onSave: (updated) async {
                             await service.saveOrUpdateProfile(_event.petName, updated.toJson());
                             if (!mounted) return;
                             if (mounted) Navigator.pop(context); 
                         },
                         onCancel: () => Navigator.pop(context),
                     )));
                 } else {
                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Perfil não encontrado: ${_event.petName}')));
                 }
             },
             child: Row(
               children: [
                  const Icon(Icons.pets, color: AppDesign.petPink, size: 18),
                  const SizedBox(width: 8),
                  const Text('Pet: ', style: TextStyle(color: AppDesign.textSecondaryDark)),
                 Expanded(
                   child: Text(
                        '${_event.petName} ${AppLocalizations.of(context)!.agendaViewProfile}', 
                       style: const TextStyle(color: AppDesign.petPink, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)
                   ),
                 ),
               ],
             ),
          ),
          
          if (displayNotes.isNotEmpty) ...[
            const Divider(color: Colors.white12, height: 32),
            Text('${AppLocalizations.of(context)!.pdfObservations}:', style: const TextStyle(color: AppDesign.textSecondaryDark, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              displayNotes,
              style: const TextStyle(color: AppDesign.textPrimaryDark, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPartnerInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppDesign.petPink.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(
             _partner!.name,
             style: GoogleFonts.poppins(
               color: AppDesign.textPrimaryDark,
               fontSize: 20,
               fontWeight: FontWeight.bold,
             ),
           ),
           const SizedBox(height: 4),
           Text(
             _partner!.specialties.isNotEmpty ? _partner!.specialties.join(', ') : _partner!.category,
              style: const TextStyle(color: AppDesign.petPink),
           ),
           const SizedBox(height: 8),

           InkWell(
             onTap: () async {
                await Navigator.push(context, MaterialPageRoute(
                    builder: (_) => PartnerRegistrationScreen(initialData: _partner!)
                ));
                _loadPartner(); // Refresh data on return
             },
             borderRadius: BorderRadius.circular(4),
             child: Padding(
               padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
               child: Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                    const Icon(Icons.info_outline, color: AppDesign.petPink, size: 14),
                    const SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(context)!.agendaViewRegistration,
                      style: GoogleFonts.poppins(
                          color: AppDesign.petPink,
                          fontSize: 12, 
                          decoration: TextDecoration.underline
                      ),
                    ),
                 ],
               ),
             ),
           ),
           
           const SizedBox(height: 16),
           
           if (_partner!.address.isNotEmpty)
             _buildActionRow(Icons.location_on, _partner!.address, () => _openMap(_partner!.address)),
           
           const SizedBox(height: 12),
           
           if (_partner!.phone.isNotEmpty)
             _buildActionRow(Icons.phone, _partner!.phone, () => _makePhoneCall(_partner!.phone)),

           const SizedBox(height: 12),

           if (_partner!.whatsapp != null && _partner!.whatsapp!.isNotEmpty)
              _buildActionRow(Icons.chat, AppLocalizations.of(context)!.agendaWhatsAppChat, () => _openWhatsApp(_partner!.whatsapp!))
            else if (_partner!.phone.isNotEmpty)
              _buildActionRow(Icons.chat, AppLocalizations.of(context)!.agendaWhatsAppChat, () => _openWhatsApp(_partner!.phone)),

           const SizedBox(height: 12),
           
           if (_partner!.email != null && _partner!.email!.isNotEmpty)
             _buildActionRow(Icons.email, _partner!.email!, null),

           const SizedBox(height: 12),

           if (_partner!.website != null && _partner!.website!.isNotEmpty)
             _buildActionRow(Icons.language, _partner!.website!, () async {
                 final url = Uri.parse(_partner!.website!);
                 if (!await launchUrl(url)) {
                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.agendaWebsiteError)));
                 }
             }),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppDesign.textSecondaryDark, size: 18),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: AppDesign.textSecondaryDark)),
        Expanded(
          child: Text(value, style: const TextStyle(color: AppDesign.textPrimaryDark, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
  
  Widget _buildActionRow(IconData icon, String text, VoidCallback? onTap) {
      return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                  children: [
                      Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: const Color(0x1A5C6BC0),
                              borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, color: AppDesign.info, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(text, style: const TextStyle(color: AppDesign.textSecondaryDark))),
                      if (onTap != null)
                          const Icon(Icons.arrow_forward_ios, color: AppDesign.textSecondaryDark, size: 12),
                  ],
              ),
          ),
      );
  }
}

