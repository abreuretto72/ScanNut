import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import '../../../../core/services/file_upload_service.dart';
import '../../../../core/services/gemini_service.dart';
import '../../models/pet_profile_extended.dart';
import '../../models/pet_analysis_result.dart';
import 'pet_result_card.dart';
import '../../../partners/presentation/partners_screen.dart';
import '../../../../core/services/whatsapp_service.dart';
import '../../../../core/services/partner_service.dart';
import '../../../../core/models/partner_model.dart';

/// Comprehensive pet profile edit form with tabs
class EditPetForm extends StatefulWidget {
  final PetProfileExtended? existingProfile;
  final Function(PetProfileExtended) onSave;
  final VoidCallback? onCancel;
  final VoidCallback? onDelete;
  final bool isNewEntry;

  const EditPetForm({Key? key, this.existingProfile, required this.onSave, this.onCancel, this.onDelete, this.isNewEntry = false}) : super(key: key);

  @override
  State<EditPetForm> createState() => _EditPetFormState();
}

class _EditPetFormState extends State<EditPetForm> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _racaController;
  late TextEditingController _idadeController;
  late TextEditingController _pesoController;
  late TextEditingController _alergiasController;
  late TextEditingController _preferenciasController;

  // Dropdown values
  String _nivelAtividade = 'Moderado';
  String _statusReprodutivo = 'Castrado';
  String _frequenciaBanho = 'Quinzenal';

  // Dates
  DateTime? _dataUltimaV10;
  DateTime? _dataUltimaAntirrabica;

  // Lists
  List<String> _alergiasConhecidas = [];
  List<String> _preferencias = [];

  // File Upload
  final FileUploadService _fileService = FileUploadService();
  Map<String, List<File>> _attachments = {
    'identity': [],
    'health_exams': [],
    'health_prescriptions': [],
    'health_vaccines': [],
    'nutrition': [],
    'gallery': [],
  };
  
  Map<String, dynamic>? _currentRawAnalysis;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadAttachments();
    
    // Load existing profile image
    if (widget.existingProfile?.imagePath != null) {
      final file = File(widget.existingProfile!.imagePath!);
      if (file.existsSync()) {
        _profileImage = file;
      }
    }

    _tabController = TabController(length: 4, vsync: this);
    
    // Initialize controllers with existing data
    final existing = widget.existingProfile;
    _nameController = TextEditingController(text: existing?.petName ?? '');
    _racaController = TextEditingController(text: existing?.raca ?? '');
    _idadeController = TextEditingController(text: existing?.idadeExata ?? '');
    _pesoController = TextEditingController(
      text: existing?.pesoAtual?.toString() ?? '',
    );
    _alergiasController = TextEditingController();
    _preferenciasController = TextEditingController();

    if (existing != null) {
      _nivelAtividade = existing.nivelAtividade ?? 'Moderado';
      _statusReprodutivo = existing.statusReprodutivo ?? 'Castrado';
      _frequenciaBanho = existing.frequenciaBanho ?? 'Quinzenal';
      _dataUltimaV10 = existing.dataUltimaV10;
      _dataUltimaAntirrabica = existing.dataUltimaAntirrabica;
      _alergiasConhecidas = List.from(existing.alergiasConhecidas);
      _alergiasConhecidas = List.from(existing.alergiasConhecidas);
      _preferencias = List.from(existing.preferencias);
      _currentRawAnalysis = existing.rawAnalysis != null 
          ? Map<String, dynamic>.from(existing.rawAnalysis!) 
          : {};
    } else {
        _currentRawAnalysis = {};
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _racaController.dispose();
    _idadeController.dispose();
    _pesoController.dispose();
    _alergiasController.dispose();
    _preferenciasController.dispose();
    super.dispose();
  }

  Future<void> _savePetProfile() async {
    if (_formKey.currentState!.validate()) {
      
      String? finalImagePath = widget.existingProfile?.imagePath;
      
      // Save new profile image if selected
      if (_profileImage != null && _profileImage!.path != widget.existingProfile?.imagePath) {
        final savedPath = await _fileService.saveMedicalDocument(
          file: _profileImage!,
          petName: _nameController.text.trim(),
          attachmentType: 'profile_pic',
        );
        if (savedPath != null) {
          finalImagePath = savedPath;
        }
      }

      final profile = PetProfileExtended(
        petName: _nameController.text.trim(),
        raca: _racaController.text.trim().isEmpty ? null : _racaController.text.trim(),
        idadeExata: _idadeController.text.trim().isEmpty ? null : _idadeController.text.trim(),
        pesoAtual: double.tryParse(_pesoController.text.trim()),
        nivelAtividade: _nivelAtividade,
        statusReprodutivo: _statusReprodutivo,
        alergiasConhecidas: _alergiasConhecidas,
        preferencias: _preferencias,
        dataUltimaV10: _dataUltimaV10,
        dataUltimaAntirrabica: _dataUltimaAntirrabica,
        frequenciaBanho: _frequenciaBanho,
        lastUpdated: DateTime.now(),
        imagePath: finalImagePath,
        rawAnalysis: _currentRawAnalysis,
      );

      widget.onSave(profile);
    }
  }

  // Attachment Logic
  Future<void> _loadAttachments() async {
    final petName = widget.existingProfile?.petName ?? _nameController.text.trim();
    if (petName.isEmpty) return;

    final allDocs = await _fileService.getMedicalDocuments(petName);
    if (!mounted) return;

    setState(() {
      _attachments['identity'] = allDocs.where((f) => path.basename(f.path).startsWith('identity_')).toList();
      _attachments['health_exams'] = allDocs.where((f) => path.basename(f.path).startsWith('health_exams_')).toList();
      _attachments['health_prescriptions'] = allDocs.where((f) => path.basename(f.path).startsWith('health_prescriptions_')).toList();
      _attachments['health_vaccines'] = allDocs.where((f) => path.basename(f.path).startsWith('health_vaccines_')).toList();
      _attachments['nutrition'] = allDocs.where((f) => path.basename(f.path).startsWith('nutrition_')).toList();
      _attachments['gallery'] = allDocs.where((f) => path.basename(f.path).startsWith('gallery_')).toList();
    });
  }

  Future<void> _pickProfileImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Alterar Foto do Perfil', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Tirar Foto', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(ctx);
                final file = await _fileService.pickFromCamera();
                if (file != null) setState(() => _profileImage = file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image, color: Colors.green),
              title: const Text('Escolher da Galeria', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(ctx);
                final file = await _fileService.pickFromGallery();
                if (file != null) setState(() => _profileImage = file);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImageHeader() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF00E676), width: 3),
              boxShadow: [
                BoxShadow(color: const Color(0xFF00E676).withValues(alpha: 0.3), blurRadius: 15, spreadRadius: 2),
              ],
              image: _profileImage != null
                  ? DecorationImage(image: FileImage(_profileImage!), fit: BoxFit.cover)
                  : null,
            ),
            child: _profileImage == null
                ? const Icon(Icons.pets, size: 60, color: Colors.white24)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 18,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.camera_alt, size: 20, color: Colors.black),
                onPressed: _pickProfileImage,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addAttachment(String type) async {
    final petName = widget.existingProfile?.petName ?? _nameController.text.trim();
    if (petName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salve o pet ou insira o nome primeiro.')));
      return;
    }

    final isGallery = type == 'gallery';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isGallery ? 'Adicionar Mídia' : 'Anexar Documento', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Câmera (Foto)', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(ctx);
                final file = await _fileService.pickFromCamera();
                if (file != null) _saveFile(file, petName, type);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image, color: Colors.green),
              title: const Text('Galeria (Foto)', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(ctx);
                final file = await _fileService.pickFromGallery();
                if (file != null) _saveFile(file, petName, type);
              },
            ),
            if (isGallery) ...[
              ListTile(
                leading: const Icon(Icons.videocam, color: Colors.orange),
                title: const Text('Câmera (Vídeo)', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await _fileService.pickVideoFromCamera();
                  if (file != null) _saveFile(file, petName, type);
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library, color: Colors.purple),
                title: const Text('Galeria (Vídeo)', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await _fileService.pickVideoFromGallery();
                  if (file != null) _saveFile(file, petName, type);
                },
              ),
            ] else 
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('PDF', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await _fileService.pickPdfFile();
                  if (file != null) _saveFile(file, petName, type);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryTab() {
    final docs = _attachments['gallery'] ?? [];
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildSectionTitle('📸 Book de Mídias'),
        const SizedBox(height: 16),
        Text(
          'Fotos e vídeos dos melhores momentos',
          style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12),
        ),
        const SizedBox(height: 20),

        if (docs.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                const Icon(Icons.perm_media_outlined, size: 48, color: Colors.white24),
                const SizedBox(height: 16),
                Text('A galeria está vazia', style: GoogleFonts.poppins(color: Colors.white54)),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final file = docs[index];
              final isVideo = file.path.toLowerCase().endsWith('.mp4') || file.path.toLowerCase().endsWith('.mov');
              return InkWell(
                onTap: () {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Arquivo: ${path.basename(file.path)}')));
                },
                onLongPress: () => _deleteAttachment(file),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                    image: !isVideo ? DecorationImage(image: FileImage(file), fit: BoxFit.cover) : null,
                  ),
                  child: isVideo 
                    ? const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 32))
                    : null,
                ),
              );
            },
          ),
        
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _addAttachment('gallery'),
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Adicionar à Galeria'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              side: const BorderSide(color: Color(0xFF00E676)),
              foregroundColor: const Color(0xFF00E676),
            ),
          ),
        ),

        // Include actions at the bottom explicitly
         _buildActionButtons(),
      ],
    );
  }

  Future<void> _saveFile(File file, String petName, String type) async {
    final savedPath = await _fileService.saveMedicalDocument(
      file: file,
      petName: petName,
      attachmentType: type,
    );
    if (savedPath != null) {
      _loadAttachments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Documento anexado!')));
      }
    }
  }

  Future<void> _deleteAttachment(File file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Excluir Anexo?', style: TextStyle(color: Colors.white)),
        content: const Text('Esta ação não pode ser desfeita.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await _fileService.deleteMedicalDocument(file.path);
      _loadAttachments();
    }
  }

  Widget _buildAttachmentSection(String type, String title) {
    final docs = _attachments[type] ?? [];
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.attach_file, color: Colors.white54, size: 16),
                  const SizedBox(width: 8),
                  Text(title, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                  if (docs.isNotEmpty) 
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: const Color(0xFF00E676), shape: BoxShape.circle),
                      child: Text('${docs.length}', style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              IconButton( // Small Add Button
                onPressed: () => _addAttachment(type),
                icon: const Icon(Icons.add_circle_outline, color: Color(0xFF00E676), size: 20),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                tooltip: 'Adicionar',
              ),
            ],
          ),
          if (docs.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final file = docs[index];
                  final isPdf = file.path.toLowerCase().endsWith('.pdf');
                  return InkWell(
                    onTap: () {
                      // TODO: Implement open file
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Arquivo: ${path.basename(file.path)}')));
                    },
                    onLongPress: () => _deleteAttachment(file),
                    child: Container(
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isPdf ? Icons.picture_as_pdf : Icons.image,
                            color: isPdf ? Colors.redAccent : Colors.blueAccent,
                            size: 24,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isPdf ? 'PDF' : 'IMG',
                            style: const TextStyle(color: Colors.white30, fontSize: 8),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text('Nenhum documento anexado.', style: GoogleFonts.poppins(color: Colors.white30, fontSize: 11, fontStyle: FontStyle.italic)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.grey[900],
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text(
            widget.existingProfile == null ? 'Novo Pet' : 'Editar Perfil',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF00E676),
          labelColor: const Color(0xFF00E676),
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.pets), text: 'Identidade'),
            Tab(icon: Icon(Icons.favorite), text: 'Saúde'),
            Tab(icon: Icon(Icons.restaurant), text: 'Nutrição'),
            Tab(icon: Icon(Icons.perm_media), text: 'Galeria'),
          ],
        ),
        actions: [
          if (widget.onCancel != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: widget.onCancel,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildIdentityTab(),
            _buildHealthTab(),
            _buildNutritionTab(),
            _buildGalleryTab(),
          ],
        ),
      ),
      floatingActionButton: _buildWhatsAppFAB(),
    ));
  }

  Widget? _buildWhatsAppFAB() {
     // Só mostramos o FAB se houver uma análise ativa
     if (_currentRawAnalysis == null) return null;

     return FloatingActionButton(
        onPressed: _sendEmergencyWhatsApp,
        backgroundColor: const Color(0xFF25D366), // WhatsApp Green
        child: const Icon(Icons.chat, color: Colors.white),
     );
  }

  Future<void> _sendEmergencyWhatsApp() async {
      final partnerService = PartnerService();
      await partnerService.init();
      final partners = partnerService.getAllPartners();
      
      // Busca o primeiro veterinário disponível
      final vet = partners.where((p) => p.category == 'Veterinário').firstOrNull;
      
      if (vet == null || vet.whatsapp == null) {
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Nenhum veterinário parceiro cadastrado para contato rápido.'))
            );
         }
         return;
      }

      final raw = _currentRawAnalysis!;
      final petName = _nameController.text.isNotEmpty ? _nameController.text : 'meu pet';
      final raca = _racaController.text.isNotEmpty ? _racaController.text : 'SRD';

      String statusSaude = 'Check-up';
      if (raw['urgency_level'] != null && raw['urgency_level'] != 'Verde') {
          statusSaude = 'Alerta de saúde detectado (${raw['urgency_level']})';
      }

      final mensagem = WhatsAppService.gerarMensagemVeterinario(
          petName: petName, 
          raca: raca,
          statusSaude: statusSaude
      );

      try {
          await WhatsAppService.abrirChat(telefone: vet.whatsapp!, mensagem: mensagem);
      } catch (e) {
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
         }
      }
  }

  Widget _buildIdentityTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildProfileImageHeader(),
        const SizedBox(height: 24),
        
        // NOVO: Rede de Apoio (Partners Integration)
        _buildSupportNetworkCard(),
        const SizedBox(height: 24),

        _buildRaceDetailsSection(),
        const SizedBox(height: 24),

        _buildSectionTitle('🐾 Informações Básicas'),
        const SizedBox(height: 16),
        
        _buildTextField(
          controller: _nameController,
          label: 'Nome do Pet',
          icon: Icons.pets,
          validator: (v) => v?.isEmpty ?? true ? 'Nome obrigatório' : null,
        ),
        
        _buildTextField(
          controller: _racaController,
          label: 'Raça',
          icon: Icons.category,
        ),
        
        _buildTextField(
          controller: _idadeController,
          label: 'Idade Exata (ex: 2 anos 3 meses)',
          icon: Icons.cake,
        ),
        
        _buildTextField(
          controller: _pesoController,
          label: 'Peso Atual (kg)',
          icon: Icons.monitor_weight,
          keyboardType: TextInputType.number,
        ),
        
        const SizedBox(height: 24),
        _buildSectionTitle('⚙️ Perfil Biológico'),
        const SizedBox(height: 16),
        
        _buildDropdown(
          value: _nivelAtividade,
          label: 'Nível de Atividade',
          icon: Icons.directions_run,
          items: ['Sedentário', 'Moderado', 'Ativo'],
          onChanged: (v) => setState(() => _nivelAtividade = v!),
        ),
        
        _buildDropdown(
          value: _statusReprodutivo,
          label: 'Status Reprodutivo',
          icon: Icons.medical_services,
          items: ['Castrado', 'Inteiro'],
          onChanged: (v) => setState(() => _statusReprodutivo = v!),
        ),


        _buildAttachmentSection('identity', 'Documentos de Identificação'),
        
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildHealthTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildSectionTitle('💉 Histórico de Vacinas'),
        const SizedBox(height: 16),
        
        _buildDatePicker(
          label: 'Última V10/V8',
          icon: Icons.vaccines,
          selectedDate: _dataUltimaV10,
          onDateSelected: (date) => setState(() => _dataUltimaV10 = date),
        ),
        
        _buildDatePicker(
          label: 'Última Antirrábica',
          icon: Icons.coronavirus,
          selectedDate: _dataUltimaAntirrabica,
          onDateSelected: (date) => setState(() => _dataUltimaAntirrabica = date),
        ),
        
        const SizedBox(height: 24),
        _buildSectionTitle('🛁 Higiene'),
        const SizedBox(height: 16),
        
        _buildDropdown(
          value: _frequenciaBanho,
          label: 'Frequência de Banho',
          icon: Icons.bathtub,
          items: ['Semanal', 'Quinzenal', 'Mensal'],
          onChanged: (v) => setState(() => _frequenciaBanho = v!),
        ),

        const SizedBox(height: 16),
        _buildSectionTitle('📄 Documentos Médicos'),
        const SizedBox(height: 8),

        _buildAttachmentSection('health_exams', '🧪 Exames Laboratoriais'),
        _buildAttachmentSection('health_prescriptions', '📝 Receitas Veterinárias'),
        _buildAttachmentSection('health_vaccines', '💉 Carteira de Vacinação'),

        _buildActionButtons(),
      ],
    );
  }

  Widget _buildNutritionTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildSectionTitle('⚠️ Alergias Alimentares'),
        const SizedBox(height: 8),
        Text(
          'Ingredientes que devem ser evitados',
          style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12),
        ),
        const SizedBox(height: 16),
        
        _buildChipInput(
          controller: _alergiasController,
          label: 'Adicionar Alergia',
          icon: Icons.warning,
          chips: _alergiasConhecidas,
          onAdd: (text) {
            setState(() {
              _alergiasConhecidas.add(text);
              _alergiasController.clear();
            });
          },
          onDelete: (index) {
            setState(() => _alergiasConhecidas.removeAt(index));
          },
        ),
        
        const SizedBox(height: 24),
        _buildSectionTitle('❤️ Preferências Alimentares'),
        const SizedBox(height: 8),
        Text(
          'Alimentos que o pet mais gosta',
          style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12),
        ),
        const SizedBox(height: 16),
        
        _buildChipInput(
          controller: _preferenciasController,
          label: 'Adicionar Preferência',
          icon: Icons.favorite,
          chips: _preferencias,
          chipColor: Colors.green,
          onAdd: (text) {
            setState(() {
              _preferencias.add(text);
              _preferenciasController.clear();
            });
          },
          onDelete: (index) {
            setState(() => _preferencias.removeAt(index));
          },
        ),

        _buildWeeklyPlanSection(),

        _buildAttachmentSection('nutrition', 'Receitas e Dietas'),
        
        _buildActionButtons(),
      ],
    );
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Excluir Pet?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Deseja remover ${widget.existingProfile?.petName ?? 'este pet'} e todo o seu histórico? Esta ação não pode ser desfeita.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir Definitivamente', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && widget.onDelete != null) {
      widget.onDelete!();
    }
  }

  Widget _buildActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _savePetProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Salvar Perfil',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        if (widget.existingProfile != null && widget.onDelete != null) ...[
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _confirmDelete,
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            label: Text(
              'Excluir Pet', 
              style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.w500),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  // Helper Widgets

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white60),
          prefixIcon: Icon(icon, color: const Color(0xFF00E676)),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF00E676), width: 2),
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        dropdownColor: Colors.grey[800],
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white60),
          prefixIcon: Icon(icon, color: const Color(0xFF00E676)),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required IconData icon,
    required DateTime? selectedDate,
    required Function(DateTime?) onDateSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: selectedDate ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime.now(),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: Color(0xFF00E676),
                    onSurface: Colors.white,
                  ),
                ),
                child: child!,
              );
            },
          );
          onDateSelected(date);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF00E676)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      selectedDate != null
                          ? DateFormat('dd/MM/yyyy').format(selectedDate)
                          : 'Não informado',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.calendar_today, color: Colors.white60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChipInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required List<String> chips,
    required Function(String) onAdd,
    required Function(int) onDelete,
    Color chipColor = Colors.red,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: label,
                  labelStyle: const TextStyle(color: Colors.white60),
                  prefixIcon: Icon(icon, color: const Color(0xFF00E676)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (text) {
                  if (text.trim().isNotEmpty) {
                    onAdd(text.trim());
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  onAdd(controller.text.trim());
                }
              },
              icon: const Icon(Icons.add_circle, color: Color(0xFF00E676), size: 32),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: chips.asMap().entries.map((entry) {
            return Chip(
              label: Text(entry.value),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () => onDelete(entry.key),
              backgroundColor: chipColor.withValues(alpha: 0.2),
              labelStyle: GoogleFonts.poppins(color: Colors.white),
              deleteIconColor: Colors.white,
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _generateNewMenu() async {
     if (_nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nome do pet é obrigatório.')));
        return;
     }

     final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text('✨ Gerar Novo Cardápio com IA?', style: TextStyle(color: Colors.white)),
            content: const Text(
                'A IA vai criar um plano semanal novo baseado nos dados atuais do pet (peso, idade, alergias). O plano atual será substituído.',
                style: TextStyle(color: Colors.white70)),
            actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true), 
                    child: const Text('Gerar Agora', style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold))
                ),
            ],
        )
     );

     if (confirm != true) return;

     showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator(color: Color(0xFF00E676))),
     );

     try {
        final service = GeminiService();
        final raw = await service.generateDietPlan(
            petName: _nameController.text.trim(),
            raca: _racaController.text.trim().isEmpty ? 'SRD' : _racaController.text,
            idade: _idadeController.text.trim().isEmpty ? 'Desconhecida' : _idadeController.text,
            peso: double.tryParse(_pesoController.text.trim()) ?? 10.0,
            nivelAtividade: _nivelAtividade,
            alergias: _alergiasConhecidas,
        );
        
        Navigator.pop(context); // Hide loader

        // Normalize keys (Busca inteligente pelo plano)
        var plano = raw['plano_semanal'] ?? raw['planoSemanal'] ?? raw['weekly_plan'] ?? raw['cardapio'];
        
        // Se ainda nulo, procura qualquer Lista de Maps no JSON
        if (plano == null) {
           for (var val in raw.values) {
              if (val is List && val.isNotEmpty && val.first is Map) {
                 plano = val;
                 break;
              }
           }
        }
        
        if (plano == null) {
            throw Exception("Formato de cardápio inválido retornado pela IA.");
        }

        setState(() {
            if (_currentRawAnalysis == null) _currentRawAnalysis = {};
            _currentRawAnalysis!['plano_semanal'] = plano;
            if (raw['orientacoes_gerais'] != null) {
                _currentRawAnalysis!['orientacoes_gerais'] = raw['orientacoes_gerais'];
            } else if (raw['orientacoes'] != null) {
                _currentRawAnalysis!['orientacoes_gerais'] = raw['orientacoes'];
            }
        });

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ Cardápio gerado! Salvando alterações...'),
            backgroundColor: Color(0xFF00E676),
            duration: Duration(seconds: 2),
        ));
        
        // Auto-save to ensure persistence
        Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) _savePetProfile();
        });

     } catch (e) {
        Navigator.pop(context); // Hide loader
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
     }
  }

  Widget _buildRaceDetailsSection() {
     final raw = _currentRawAnalysis;
     if (raw == null) return const SizedBox.shrink();

     final ident = raw['identificacao'] as Map?;
     final temp = raw['temperamento'] as Map?;
     final fisica = raw['caracteristicas_fisicas'] as Map?;
     final origem = raw['origem_historia'] as String?;
     final curiosidades = raw['curiosidades'] as List?;
     
     if (ident == null && temp == null && fisica == null && origem == null) return const SizedBox.shrink();

     return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           const SizedBox(height: 24),
           InkWell(
             onTap: _openFullAnalysis,
             borderRadius: BorderRadius.circular(8),
             child: Padding(
               padding: const EdgeInsets.symmetric(vertical: 8),
               child: Row(
                 children: [
                   _buildSectionTitle('🧬 Análise da Raça'),
                   const Spacer(),
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                     decoration: BoxDecoration(
                         color: const Color(0xFF00E676).withOpacity(0.1),
                         borderRadius: BorderRadius.circular(20),
                         border: Border.all(color: const Color(0xFF00E676).withOpacity(0.3))
                     ),
                     child: Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         const Text('Ver Completo', style: TextStyle(color: Color(0xFF00E676), fontSize: 12, fontWeight: FontWeight.bold)),
                         const SizedBox(width: 4),
                         const Icon(Icons.arrow_forward, color: Color(0xFF00E676), size: 14),
                       ],
                     ),
                   )
                 ],
               ),
             ),
           ),
           const SizedBox(height: 8),
           
           
            if (ident != null) ...[
               _buildInfoRow('Linhagem', ident['linhagem_mista']?.toString() ?? 'Não identificada'),
               _buildInfoRow('Raça Predominante', ident['raca_predominante']?.toString() ?? 'Não identificada'),
               _buildInfoRow('Confiabilidade', ident['confiabilidade']?.toString() ?? 'Baixa'),
            ],
            
            if (fisica != null) ...[
               _buildInfoRow('Expectativa de Vida', fisica['expectativa_vida']?.toString() ?? 'Não estimada'),
               _buildInfoRow('Porte', fisica['porte']?.toString() ?? 'Não identificado'),
               _buildInfoRow('Peso Típico', fisica['peso_estimado']?.toString() ?? 'Variável'),
            ],

           if (temp != null) ...[
               const SizedBox(height: 12),
               const Text('Temperamento', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
               const SizedBox(height: 4),
               if (temp['personalidade'] != null)
                  Text(temp['personalidade'].toString(), style: const TextStyle(color: Colors.white70)),
               if (temp['comportamento_social'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(temp['comportamento_social'].toString(), style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12, fontStyle: FontStyle.italic)),
                  ),
           ],
           
           if (origem != null) ...[
               const SizedBox(height: 12),
               ExpansionTile(
                  title: Text('Origem & História', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
                  collapsedIconColor: Colors.white54,
                  iconColor: const Color(0xFF00E676),
                  children: [Padding(padding: const EdgeInsets.all(8), child: Text(origem, style: const TextStyle(color: Colors.white70)))],
               )
           ],

           if (curiosidades != null && curiosidades.isNotEmpty) ...[
               const SizedBox(height: 12),
               ExpansionTile(
                  title: Text('Curiosidades', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
                  collapsedIconColor: Colors.white54,
                  iconColor: Colors.amber,
                  children: curiosidades.map((c) => ListTile(
                      leading: const Icon(Icons.star, color: Colors.amber, size: 16),
                      title: Text(c.toString(), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  )).toList(),
               )
           ]
        ]
     );
  }

   void _openFullAnalysis() {
      final raw = _currentRawAnalysis;
      if (raw == null) return;
      
      try {
          var jsonForParse = Map<String, dynamic>.from(raw);
          
          // Map DTO keys back to AnalysisResult expected keys if needed
          if (jsonForParse['perfil_comportamental'] == null && jsonForParse['temperamento'] != null) {
              jsonForParse['perfil_comportamental'] = jsonForParse['temperamento'];
          }
          /* Ensure identificacao sub-keys match if needed. 
             Factory: raca_predominante -> PetAnalysisResult expects raca_predominante? Yes.
          */
           
          final analysis = PetAnalysisResult.fromJson(jsonForParse);
          
          Navigator.push(context, MaterialPageRoute(
              builder: (_) => Scaffold(
                  backgroundColor: Colors.black,
                  appBar: AppBar(
                      backgroundColor: Colors.transparent,
                      iconTheme: const IconThemeData(color: Colors.white),
                      elevation: 0,
                      title: const Text('Análise Completa', style: TextStyle(color: Colors.white)),
                  ),
                  body: PetResultCard(
                      analysis: analysis,
                      imagePath: widget.existingProfile?.imagePath ?? _profileImage?.path ?? '', 
                      petName: _nameController.text,
                      onSave: () {}, 
                  )
              )
          ));
      } catch (e) {
         debugPrint('Error parsing analysis: $e');
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Detalhes completos indisponíveis para este perfil.')));
      }
   }

  Widget _buildInfoRow(String label, String value) {
      if (value.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                SizedBox(width: 130, child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13))),
                Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 14))),
            ]
        ),
      );
  }

  Widget _buildWeeklyPlanSection() {
    final raw = _currentRawAnalysis;
    if (raw == null || raw['plano_semanal'] == null) {
        // If empty, show button to generate
      return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
              child: ElevatedButton.icon(
                  icon: const Icon(Icons.restaurant_menu),
                  label: const Text('Gerar Cardápio Semanal'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black),
                  onPressed: _generateNewMenu,
              )
          )
      );
    }

    final List<dynamic> plano = raw['plano_semanal'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                _buildSectionTitle('📅 Plano Alimentar Semanal'),
                IconButton(
                    icon: const Icon(Icons.restaurant_menu, color: Color(0xFF00E676)),
                    tooltip: 'Gerar Novo Cardápio',
                    onPressed: _generateNewMenu,
                ),
            ],
        ),
        const SizedBox(height: 16),
        ...plano.map((dia) {
          final d = dia as Map;
          return Card(
            color: Colors.white.withValues(alpha: 0.05),
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: Text(d['dia'] ?? 'Dia', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                leading: const Icon(Icons.calendar_today, color: Color(0xFF00E676), size: 20),
                iconColor: const Color(0xFF00E676),
                collapsedIconColor: Colors.white54,
                children: [
                  _buildFlexibleMealRow(d, ['manha', 'manhã', 'morning', 'café', 'breakfast'], '🌅 Manhã'),
                  _buildFlexibleMealRow(d, ['tarde', 'almoço', 'almoco', 'afternoon', 'lanche', 'lunch'], '☀️ Tarde'),
                  _buildFlexibleMealRow(d, ['noite', 'jantar', 'night', 'ceia', 'dinner'], '🌙 Noite'),
                  
                  // Render extra keys fallback (Robustez total)
                  ...d.entries.where((e) {
                      final k = e.key.toString().toLowerCase();
                      const stdKeys = ['dia', 'manha', 'manhã', 'morning', 'café', 'breakfast', 'tarde', 'almoço', 'almoco', 'afternoon', 'lanche', 'lunch', 'noite', 'jantar', 'night', 'ceia', 'dinner'];
                      return !stdKeys.contains(k);
                  }).map((e) => _buildMealRow(e.key.toString(), e.value.toString())),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildFlexibleMealRow(Map rawData, List<String> keys, String label) {
    // Ensure data handles String keys to avoid runtime type errors
    final data = rawData.map((k, v) => MapEntry(k.toString(), v));
    
    String? content;
    for (var key in keys) {
       final entry = data.entries.firstWhere(
         (e) => e.key.toLowerCase() == key.toLowerCase(),
         orElse: () => const MapEntry('', null),
       );
       if (entry.value != null) {
         content = entry.value.toString();
         break;
       }
    }
    
    if (content == null || content.isEmpty) return const SizedBox.shrink();
    return _buildMealRow(label, content);
  }

  Widget _buildMealRow(String label, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 70, child: Text(label, style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12))),
          Expanded(child: Text(content, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13))),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    // Se não for novo (edição), permite sair sem aviso por enquanto (comportamento padrão)
    // Ou verifique se houve alterações.
    // O foco do request é proteger dados do Scan (isNewEntry = true).
    
    if (!widget.isNewEntry) return true;

    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('⚠️ Dados não salvos', style: TextStyle(color: Colors.white)),
        content: const Text(
            'Você possui uma análise de IA recém-gerada.\nSe sair sem salvar, esses dados serão perdidos permanentemente.\n\nDeseja realmente sair?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('VOLTAR', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('DESCARTAR DADOS', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }

  Widget _buildSupportNetworkCard() {
    // Check if there are any specific health alerts in rawAnalysis to customize the label
    final raw = _currentRawAnalysis;
    bool hasAlert = false;
    if (raw != null && raw['urgency_level'] != null && raw['urgency_level'] != 'Verde') {
      hasAlert = true;
    }

    return InkWell(
      onTap: () {
         // Create a virtual analysis result from raw if needed, or pass raw
         // For now, if we have raw analysis, we can reconstruct a PetAnalysisResult object for the suggested filter
         PetAnalysisResult? contextAnalysis;
         if (raw != null) {
            try {
               var jsonForParse = Map<String, dynamic>.from(raw);
               if (jsonForParse['perfil_comportamental'] == null && jsonForParse['temperamento'] != null) {
                  jsonForParse['perfil_comportamental'] = jsonForParse['temperamento'];
               }
               contextAnalysis = PetAnalysisResult.fromJson(jsonForParse);
            } catch (e) {
               debugPrint('Error creating partner context: $e');
            }
         }

         Navigator.push(context, MaterialPageRoute(
           builder: (_) => PartnersScreen(suggestionContext: contextAnalysis)
         ));
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF00E676).withOpacity(0.1), Colors.blueAccent.withOpacity(0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF00E676).withOpacity(0.3)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
          ]
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: Color(0xFF00E676), shape: BoxShape.circle),
              child: const Icon(Icons.handshake, color: Colors.black, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rede de Apoio', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    hasAlert 
                      ? 'Encontramos especialistas para cuidar do alerta de saúde detectado.' 
                      : 'Veja veterinários, pet shops e serviços próximos.',
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }
}
