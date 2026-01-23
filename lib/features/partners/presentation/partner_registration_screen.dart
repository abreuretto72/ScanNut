
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart'; // Add this line
import 'package:uuid/uuid.dart';
import '../../../core/models/partner_model.dart';
import '../../../core/services/partner_service.dart';
import '../../../core/widgets/pdf_action_button.dart';
import '../../../core/providers/settings_provider.dart'; // Add this line
import '../../../core/services/simple_auth_service.dart'; // Add this line
import '../../settings/settings_screen.dart';
import '../../../core/theme/app_design.dart';

import 'package:intl/intl.dart';
import 'package:scannut/l10n/app_localizations.dart';
import '../../../core/services/export_service.dart';
import '../../../core/widgets/pdf_preview_screen.dart';
import './widgets/radar_export_filter_modal.dart';
import '../../pet/services/pet_indexing_service.dart';

class PartnerRegistrationScreen extends StatefulWidget {
  final PartnerModel? initialData;
  final List<Map<String, dynamic>>? linkedNotes; // If provided, shows notes section
  final String? petId;
  final String? petName;

  const PartnerRegistrationScreen({
    super.key, 
    this.initialData, 
    this.linkedNotes,
    this.petId,
    this.petName,
  });

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
  final _websiteController = TextEditingController();
  final _emailController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _teamController = TextEditingController(); // Input auxiliar para o time
  
  List<String> _teamMembers = [];
  
  // Notes Logic
  final _noteController = TextEditingController();
  List<Map<String, dynamic>> _notes = [];

  String _category = 'Veterinário';
  bool _is24h = false;
  bool _isFavorite = false;
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
      _websiteController.text = widget.initialData!.website ?? '';
      _emailController.text = widget.initialData!.email ?? '';
      _cnpjController.text = widget.initialData!.cnpj ?? '';
      _whatsappController.text = widget.initialData!.whatsapp ?? '';
      _teamMembers = List.from(widget.initialData!.teamMembers);
      _isFavorite = widget.initialData!.isFavorite;
    }
    if (widget.linkedNotes != null) {
        _notes = List.from(widget.linkedNotes!);
    }
  }

  Future<void> _startRadarSearch() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppDesign.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => _RadarBottomSheet(
        initialQuery: _category,
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
    // Check if partner is linked to any pet (Stub logic - Replace with real check when relational DB is ready)
    // For now, we assume no pets are linked to partners directly in the PartnerModel.
    // Use PetProfileService or similar to iterate pets and check foreign keys if they existed.
    
    // Simulate check (always false for now in this MVP structure)
    bool isLinkedToPet = false; 

    if (isLinkedToPet) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(AppLocalizations.of(context)!.partnerCantDeleteLinked),
                    backgroundColor: AppDesign.error
                ),
            );
        }
        return;
    }

    // 1. 🛡️ SECURITY CHALLENGE FIRST
    final auth = SimpleAuthService();
    final bool isVerified = await auth.verifyIdentity(
      reason: 'Autentique-se para excluir este parceiro'
    );

    if (!isVerified) {
        if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Autenticação falhou. Exclusão cancelada.'), backgroundColor: AppDesign.error)
            );
        }
        return;
    }

    if (!mounted) return;

    // 2. SHOW CONFIRMATION DIALOG
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppDesign.surfaceDark,
        title: Text(AppLocalizations.of(context)!.partnerDeleteTitle, style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark)),
        content: Text(AppLocalizations.of(context)!.partnerDeleteContent(widget.initialData!.name), style: GoogleFonts.poppins(color: AppDesign.textSecondaryDark)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.of(context)!.btnCancel, style: const TextStyle(color: AppDesign.textSecondaryDark))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.btnDelete, style: const TextStyle(color: AppDesign.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _service.init();
      await _service.deletePartner(widget.initialData!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.partnerDeleted), backgroundColor: AppDesign.error),
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
        whatsapp: _whatsappController.text.isNotEmpty ? _whatsappController.text : _phoneController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        instagram: _instagramController.text.isNotEmpty ? _instagramController.text : null,
        address: _addressController.text,
        specialties: specialties,
        email: _emailController.text,
        cnpj: _cnpjController.text,
        teamMembers: _teamMembers,
        website: _websiteController.text,
        metadata: {
            // website removed from here as it's now a formal field
        },
        openingHours: {
          'plantao24h': _is24h,
          'raw': _openingHoursController.text,
        },
        isFavorite: _isFavorite,
      );

      try {
        await _service.init();
        await _service.savePartner(partner);
        debugPrint("Parceiro salvo com sucesso no Hive.");

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.partnerSaved(partner.name), style: const TextStyle(color: Colors.black)),
              backgroundColor: AppDesign.petPink,
            ),
          );
          
          if (widget.linkedNotes != null) {
              Navigator.pop(context, {'updated': true, 'notes': _notes});
          } else {
              Navigator.pop(context, true);
          }
        }
      } catch (e) {
        debugPrint("Erro fatal ao salvar: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.partnerSaveError(e.toString())), backgroundColor: AppDesign.error),
          );
        }
      }
    } else {
      debugPrint("Validação do formulário falhou.");
    }
  }

  Future<void> _generatePdf() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.agendaRequired)));
        return;
    }

    final specialties = _specialtiesController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // Construct model from current state
    final partner = PartnerModel(
        id: widget.initialData?.id ?? '',
        name: name,
        category: _category,
        latitude: _lat ?? 0.0,
        longitude: _lng ?? 0.0,
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        email: _emailController.text.trim(),
        website: _websiteController.text.trim(),
        instagram: _instagramController.text.trim(),
        whatsapp: _whatsappController.text.trim(),
        cnpj: _cnpjController.text.trim(),
        openingHours: {
          'plantao24h': _is24h,
          'raw': _openingHoursController.text.trim(),
        },
        metadata: {'notes': _notes},
        teamMembers: _teamMembers,
        specialties: specialties,
        rating: widget.initialData?.rating ?? 0.0,
        isFavorite: _isFavorite,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfPreviewScreen(
          title: '${AppLocalizations.of(context)!.pdfReportTitle} - $name',
          buildPdf: (format) async {
            final pdf = await ExportService().generateSinglePartnerReport(
              partner: partner,
              strings: AppLocalizations.of(context)!,
            );
            return pdf.save();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesign.backgroundDark,
      appBar: AppBar(
        title: Text(widget.initialData != null ? AppLocalizations.of(context)!.partnerEditTitle : AppLocalizations.of(context)!.partnerRegisterTitle, style: GoogleFonts.poppins()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (widget.initialData != null) ...[
            IconButton(
              icon: Icon(
                _isFavorite ? Icons.star : Icons.star_border,
                color: _isFavorite ? Colors.amber : Colors.white24,
              ),
              onPressed: () {
                setState(() => _isFavorite = !_isFavorite);
                if (_isFavorite && widget.petId != null) {
                   PetIndexingService().indexPartnerInteraction(
                      petId: widget.petId!,
                      petName: widget.petName ?? 'Pet',
                      partnerName: _nameController.text,
                      partnerId: widget.initialData?.id,
                      interactionType: 'favorited',
                      localizedTitle: AppLocalizations.of(context)!.petIndexing_partnerFavorited(_nameController.text),
                      localizedNotes: AppLocalizations.of(context)!.petIndexing_partnerInteractionNotes,
                   );
                }
              },
            ),
            PdfActionButton(onPressed: _generatePdf),
          ],
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
              _buildTextField(_nameController, AppLocalizations.of(context)!.partnerFieldEstablishment, Icons.business),
              const SizedBox(height: 16),
              _buildCategoryDropdown(),
              const SizedBox(height: 16),
              _buildTextField(_phoneController, AppLocalizations.of(context)!.partnerFieldPhone, Icons.phone),
              const SizedBox(height: 16),
              _buildTextField(_instagramController, AppLocalizations.of(context)!.partnerFieldInstagram, Icons.camera_alt),
              const SizedBox(height: 16),
              _buildTextField(_openingHoursController, AppLocalizations.of(context)!.partnerFieldHours, Icons.access_time),
              const SizedBox(height: 16),
              _build24hSwitch(),
              const SizedBox(height: 16),
              _buildTextField(_specialtiesController, AppLocalizations.of(context)!.partnerFieldSpecialties, Icons.stars),
              const SizedBox(height: 16),
              _buildTextField(_websiteController, AppLocalizations.of(context)!.partnerFieldWebsite, Icons.language),
              const SizedBox(height: 16),
              _buildTextField(_emailController, AppLocalizations.of(context)!.partnerFieldEmail, Icons.email),
              const SizedBox(height: 16),
              _buildTeamSection(),
              const SizedBox(height: 16),
              _buildTextField(_addressController, AppLocalizations.of(context)!.partnerFieldAddress, Icons.location_on, maxLines: 2),
              const SizedBox(height: 32),
              
              if (widget.linkedNotes != null) ...[
                 _buildNotesSection(),
                 const SizedBox(height: 32),
              ],

              ElevatedButton(
                onPressed: _savePartner,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppDesign.petPink,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 8,
                ),
                child: Text(AppLocalizations.of(context)!.partnerBtnSave, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 32),
              if (widget.initialData != null) _buildDangerZone(),
              const SizedBox(height: 100), // Extra space to scroll past the keyboard
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDangerZone() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white24,
        border: Border.all(color: const Color(0x4DD32F2F)),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppDesign.error),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.partnerDangerZone, style: GoogleFonts.poppins(color: AppDesign.error, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.partnerDangerZoneDesc,
            style: GoogleFonts.poppins(color: AppDesign.textSecondaryDark, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _deletePartner,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0x3357315D),
              foregroundColor: AppDesign.error,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: AppDesign.error)),
            ),
            child: Text(AppLocalizations.of(context)!.partnerBtnDelete),
          ),
        ],
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
          gradient: const LinearGradient(colors: [AppDesign.petPink, Color(0xFFFFB7C5)]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppDesign.petPink.withOpacity(0.3), blurRadius: 10, spreadRadius: 2)],
        ),
        child: Row(
          children: [
            const Icon(Icons.radar, color: Colors.black, size: 40),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.partnerRadarButtonTitle, style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(AppLocalizations.of(context)!.partnerRadarButtonDesc, style: GoogleFonts.poppins(color: Colors.black54, fontSize: 12)),
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
        color: Colors.black45,
        borderRadius: BorderRadius.circular(15),
      ),
      child: SwitchListTile(
        title: Text(AppLocalizations.of(context)!.partnerField24h, style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark, fontSize: 14)),
        subtitle: Text(AppLocalizations.of(context)!.partnerField24hSub, style: const TextStyle(color: AppDesign.textSecondaryDark, fontSize: 11)),
        value: _is24h,
        activeThumbColor: AppDesign.petPink,
        onChanged: (v) => setState(() => _is24h = v),
        secondary: const Icon(Icons.emergency_share, color: AppDesign.error),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: AppDesign.textPrimaryDark),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppDesign.textSecondaryDark),
        prefixIcon: Icon(icon, color: AppDesign.petPink),
        filled: true,
        fillColor: Colors.black45,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
      validator: (v) {
          if (label == AppLocalizations.of(context)!.partnerFieldEstablishment && (v == null || v.isEmpty)) return AppLocalizations.of(context)!.agendaRequired;
          if (label == AppLocalizations.of(context)!.partnerFieldEmail && v != null && v.isNotEmpty) {
              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!emailRegex.hasMatch(v)) return 'E-mail inválido';
          }
          if (label == AppLocalizations.of(context)!.partnerFieldWebsite && v != null && v.isNotEmpty) {
              if (!v.startsWith('http')) return 'Deve começar com http:// ou https://';
          }
          return null;
      },
    );
  }

  Widget _buildNotesSection() {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
            Row(
              children: [
                const Icon(Icons.note_alt_outlined, color: AppDesign.warning),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.partnerNotesTitle, style: GoogleFonts.poppins(color: AppDesign.warning, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _notes.isEmpty 
                ? Center(
                    child: Text(
                      AppLocalizations.of(context)!.partnerNotesEmpty,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: AppDesign.textSecondaryDark, fontSize: 12),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _notes.length,
                    separatorBuilder: (_, __) => const Divider(color: Colors.white10),
                    itemBuilder: (context, index) {
                      final note = _notes[index];
                      final date = DateTime.parse(note['date']);
                      final formattedDate = DateFormat('dd/MM/yy HH:mm').format(date);
                      
                      return Dismissible(
                          key: Key(note['id']),
                          direction: DismissDirection.endToStart,
                          background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 16),
                              color: const Color(0x4DD32F2F),
                              child: const Icon(Icons.delete, color: Colors.red),
                          ),
                          onDismissed: (_) => _deleteNote(index),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(note['content'], style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(formattedDate, style: const TextStyle(color: AppDesign.textSecondaryDark, fontSize: 10)),
                            ],
                          ),
                      );
                    },
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    style: const TextStyle(color: AppDesign.textPrimaryDark),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.partnerNotesHint,
                      hintStyle: const TextStyle(color: AppDesign.textSecondaryDark),
                      filled: true,
                      fillColor: Colors.black45,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    onSubmitted: (_) => _addNote(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppDesign.petPink,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.black, size: 20),
                    onPressed: _addNote,
                  ),
                ),
                 // Mic button placeholder
                 const SizedBox(width: 8),
                 CircleAvatar(
                  backgroundColor: Colors.white10,
                  child: IconButton(
                    icon: const Icon(Icons.mic, color: AppDesign.warning, size: 20),
                     onPressed: () {
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(
                             content: Text('Gravação de voz: Em breve'),
                              backgroundColor: AppDesign.petPink,
                           ),
                         );
                     },
                  ),
                ),
              ],
            ),
        ],
    );
  }

  void _addNote() {
    final text = _noteController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _notes.insert(0, {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'content': text,
        'date': DateTime.now().toIso8601String(),
        'type': 'text' // ready for audio later
      });
      _noteController.clear();
    });
  }

  void _deleteNote(int index) {
      setState(() {
          _notes.removeAt(index);
      });
  }

  Widget _buildTeamSection() {
      return Container(
          decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                   Row(
                       children: [
                           const Icon(Icons.people, color: AppDesign.petPink),
                           const SizedBox(width: 8),
                           Text(AppLocalizations.of(context)!.partnerTeamTitle, style: GoogleFonts.poppins(color: AppDesign.textSecondaryDark)),
                       ],
                   ),
                   const SizedBox(height: 8),
                   Wrap(
                       spacing: 8,
                       runSpacing: 4,
                       children: _teamMembers.map((member) => Chip(
                           label: Text(member, style: const TextStyle(fontSize: 12)),
                           backgroundColor: AppDesign.petPink.withOpacity(0.2),
                           deleteIcon: const Icon(Icons.close, size: 14),
                           onDeleted: () {
                               setState(() {
                                   _teamMembers.remove(member);
                               });
                           },
                       )).toList(),
                   ),
                   const SizedBox(height: 8),
                   Row(
                       children: [
                           Expanded(
                               child: TextField(
                                   controller: _teamController,
                                   style: const TextStyle(color: AppDesign.textPrimaryDark, fontSize: 13),
                                   decoration: InputDecoration(
                                       hintText: AppLocalizations.of(context)!.partnerTeamAddHint,
                                       hintStyle: const TextStyle(color: Colors.white24),
                                       isDense: true,
                                       filled: true,
                                       fillColor: Colors.black45,
                                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                   ),
                                   onSubmitted: (_) => _addTeamMember(),
                               ),
                           ),
                           IconButton(
                               icon: const Icon(Icons.add_circle, color: AppDesign.petPink),
                               onPressed: _addTeamMember,
                           )
                       ],
                   )
              ],
          ),
      );
  }

  void _addTeamMember() {
      final name = _teamController.text.trim();
      if (name.isNotEmpty && !_teamMembers.contains(name)) {
          setState(() {
              _teamMembers.add(name);
              _teamController.clear();
          });
      }
  }

  Widget _buildCategoryDropdown() {
    final strings = AppLocalizations.of(context)!;
    
    // Detailed Category Groups
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
          strings.partnersFilterLab, // Reuse existing
          strings.partnersFilterPharmacy, // Reuse existing
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
          strings.partnersFilterGrooming, // Old key "Banho e Tosa" or similar
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
          strings.partnersFilterPetShop, // Keep legacy as fallback or alias? "Pet Shop" is common. Use specific keys if distinct.
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

    // Flatten logic
    final List<String> allSelectableItems = [];
    final List<DropdownMenuItem<String>> menuItems = [];

    for (var g in groups) {
      final title = g['title'] as String;
      final items = g['items'] as List<String>;

      // Header (Non-selectable, but must have unique value if generic type used, but DropdownMenuItem value can be whatever)
      // Actually DropdownButton value must match one of the items.
      // Headers should NOT be values. But DropdownMenuItem requires a value?
      // Yes. We give it a value that user never selects.
      
      menuItems.add(DropdownMenuItem<String>(
        value: "HEADER_$title", 
        enabled: false,
        child: Text(
          title, 
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppDesign.petPink, fontSize: 13),
        ),
      ));

      for (var item in items) {
        // Dedup
        if (!allSelectableItems.contains(item)) {
            allSelectableItems.add(item);
            menuItems.add(DropdownMenuItem<String>(
              value: item,
              child: Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: Text(item, style: GoogleFonts.poppins(fontSize: 14)),
              ),
            ));
        }
      }
    }

    // Ensure current _category is valid
    if (!allSelectableItems.contains(_category)) {
      // Try to match partial or default
       if (allSelectableItems.isNotEmpty) {
           // If it's a legacy value, maybe add it nicely?
           // No, force default or add it temporarily?
           // Better to add it to the list to avoid crash (DropdownButton value must be in items)
           menuItems.add(DropdownMenuItem(value: _category, child: Text(_category)));
       }
    }

    return DropdownButtonFormField<String>(
      initialValue: _category,
      dropdownColor: AppDesign.surfaceDark,
      isExpanded: true, // Important for long names
      style: const TextStyle(color: AppDesign.textPrimaryDark),
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.partnerCategory,
        labelStyle: const TextStyle(color: AppDesign.textSecondaryDark),
        prefixIcon: const Icon(Icons.category, color: AppDesign.petPink),
        filled: true,
        fillColor: Colors.black45,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
      items: menuItems,
      onChanged: (v) {
        if (v != null && !v.startsWith("HEADER_")) {
             setState(() => _category = v);
        }
      },
    );
  }

  bool _isSameCategory(String catA, String catB) {
    if (catA == catB) return true;
    final a = catA.toLowerCase();
    final b = catB.toLowerCase();
    
    final List<List<String>> synonymGroups = [
      ['veterinário', 'veterinary', 'veterinarian', 'veterinario', 'vet'],
      ['pet shop', 'petshop', 'tienda de mascotas'],
      ['farmácias pet', 'pet pharmacy', 'pharmacy', 'farmacia pet', 'farmacia'],
      ['banho e tosa', 'grooming', 'peluquería', 'tosa'],
      ['hotéis', 'hotel', 'pet hotel', 'adestramento', 'training'],
      ['laboratórios', 'laboratory', 'lab', 'laboratorio', 'laboratorios'],
      ['dog walker', 'passeador', 'passeador de cães', 'paseador'],
    ];

    for (var group in synonymGroups) {
      bool hasA = group.any((s) => a.contains(s));
      bool hasB = group.any((s) => b.contains(s));
      if (hasA && hasB) return true;
    }
    return false;
  }
}

class _RadarBottomSheet extends ConsumerStatefulWidget {
  final Function(PartnerModel) onPartnerSelected;
  final String? initialQuery;

  const _RadarBottomSheet({required this.onPartnerSelected, this.initialQuery});

  @override
  ConsumerState<_RadarBottomSheet> createState() => _RadarBottomSheetState();
}

class _RadarBottomSheetState extends ConsumerState<_RadarBottomSheet> {
  final PartnerService _service = PartnerService();
  List<PartnerModel> _discovered = [];
  bool _isLoading = true;
  String _error = '';
  Position? _currentPosition;

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
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (_) {
          pos = await Geolocator.getLastKnownPosition();
      }

      if (pos == null || (pos.latitude == 0.0 && pos.longitude == 0.0)) {
        throw 'GPS não retornou coordenadas válidas. Verifique as permissões.';
      }

      setState(() => _currentPosition = pos);

      // Log removed for privacy

      // 3. Step 1: Search in 10KM (Optimized Radius)
      debugPrint("Radar: Iniciando busca em 10km...");
      var results = await _service.discoverNearbyPartners(
        lat: pos.latitude,
        lng: pos.longitude,
        radiusKm: 10.0,
        query: widget.initialQuery != null ? '${widget.initialQuery} Pet' : null,
      );

      // 4. Step 2: Auto-Expand to 20KM if empty
      if (results.isEmpty) {
        debugPrint("Radar: Nenhum resultado em 10km. Expandindo para 20km...");
        if (mounted) {
          setState(() => _error = AppLocalizations.of(context)!.partnersEmpty);
        }
        results = await _service.discoverNearbyPartners(
          lat: pos.latitude,
          lng: pos.longitude,
          radiusKm: 20.0,
          query: widget.initialQuery != null ? '${widget.initialQuery} Pet' : null,
        );
      }

      if (mounted) {
        setState(() {
          _discovered = results;
          _isLoading = false;
          _error = results.isEmpty ? AppLocalizations.of(context)!.partnersEmpty : '';
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
                      Text(
                          AppLocalizations.of(context)!.partnerRadarHint, 
                        style: const TextStyle(color: AppDesign.petPink, fontSize: 11, fontWeight: FontWeight.w500)
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.radar, color: AppDesign.petPink),
                if (_discovered.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: PdfActionButton(
                      onPressed: _showExportModal,
                      color: Colors.transparent,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text("${AppLocalizations.of(context)!.partnerRadarFoundTitle} ${widget.initialQuery ?? ''}", style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: AppDesign.petPink),
                      const SizedBox(height: 16),
                      Text(AppLocalizations.of(context)!.partnerRadarScanning, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                )
              : _error.isNotEmpty
                ? Center(child: Text(_error, style: const TextStyle(color: Colors.redAccent)))
                : _discovered.isEmpty
                  ? Center(child: Text(AppLocalizations.of(context)!.partnerRadarNoResults, style: GoogleFonts.poppins(color: Colors.white38)))
                  : ListView.builder(
                      itemCount: _discovered.length,
                      itemBuilder: (context, index) {
                        final p = _discovered[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: AppDesign.petPink.withOpacity(0.15),
                            child: Icon(_getIcon(p.category), color: AppDesign.petPink, size: 20),
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

  void _showExportModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => RadarExportFilterModal(
        currentResults: _discovered,
        onGenerate: (partners) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PdfPreviewScreen(
                title: 'Relatório Radar Geo',
                buildPdf: (format) => ExportService().generateRadarReport(
                  partners: partners,
                  userLat: _currentPosition?.latitude ?? 0.0,
                  userLng: _currentPosition?.longitude ?? 0.0,
                  strings: AppLocalizations.of(context)!,
                ).then((pdf) => pdf.save()),
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getIcon(String category) {
    final c = category.toLowerCase();
    if (c.contains('vet')) return Icons.local_hospital;
    if (c.contains('farm') || c.contains('pharm')) return Icons.medication;
    if (c.contains('shop') || c.contains('tienda')) return Icons.shopping_basket;
    if (c.contains('banho') || c.contains('grooming') || c.contains('peluquer')) return Icons.content_cut;
    if (c.contains('hotel')) return Icons.hotel;
    if (c.contains('lab')) return Icons.biotech;
    return Icons.pets;
  }
}
