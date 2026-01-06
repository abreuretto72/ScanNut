import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pet_analysis_result.dart';
import '../services/pet_analysis_service.dart';
import '../../../core/enums/scannut_mode.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/pet_profile_extended.dart';
import 'widgets/edit_pet_form.dart';
import '../services/pet_profile_service.dart';
import '../../../core/services/history_service.dart';
import '../../../core/services/file_upload_service.dart';
import '../../../core/widgets/pro_access_wrapper.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../../core/theme/app_design.dart';

final petResultProvider = StateProvider<PetAnalysisResult?>((ref) => null);

class PetResultScreen extends ConsumerStatefulWidget {
  final File imageFile;

  const PetResultScreen({Key? key, required this.imageFile}) : super(key: key);

  @override
  ConsumerState<PetResultScreen> createState() => _PetResultScreenState();
}

class _PetResultScreenState extends ConsumerState<PetResultScreen> {
  bool _isLoading = true;
  File? _permanentImage;

  @override
  void initState() {
    super.initState();
    _analyzeImage();
  }

  Future<void> _analyzeImage() async {
    try {
      final service = ref.read(petAnalysisServiceProvider);
      final result = await service.analyzePet(widget.imageFile, ScannutMode.petIdentification);
      
      // 📸 MOVER PARA PERMANENTE IMEDIATAMENTE (Organizado por Pet)
      try {
          final fileService = FileUploadService();
          final savedPath = await fileService.saveMedicalDocument(
            file: widget.imageFile,
            petName: result.petName ?? 'Unknown',
            attachmentType: 'analysis',
          );
          
          if (savedPath != null) {
              _permanentImage = File(savedPath);
              debugPrint('✅ Imagem salva permanentemente via FileService: $savedPath');
          } else {
              _permanentImage = widget.imageFile;
          }
      } catch (e) {
          debugPrint('⚠️ Erro ao mover imagem para permanente: $e');
          _permanentImage = widget.imageFile; // Fallback
      }

      if (mounted) {
        ref.read(petResultProvider.notifier).state = result;
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(petResultProvider);

    return Scaffold(
      backgroundColor: AppDesign.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Análise Veterinária', style: TextStyle(color: AppDesign.textPrimaryDark)),
        iconTheme: const IconThemeData(color: AppDesign.textPrimaryDark),
      ),
      floatingActionButton: _isLoading || result == null ? null : FloatingActionButton.extended(
        onPressed: () => _navigateToEdit(context, result),
        label: const Text('Salvar na Carteira', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.save_as),
        backgroundColor: AppDesign.accent,
        foregroundColor: AppDesign.textPrimaryLight,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppDesign.accent))
          : result == null
              ? const Center(child: Text('Nenhum resultado.', style: TextStyle(color: AppDesign.textPrimaryDark)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Preview
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          _permanentImage ?? widget.imageFile,
                          height: 250,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      if (result.analysisType == 'diagnosis') ...[
                        // DIAGNOSIS MODE: Urgency First
                        _buildUrgencyCard(result),
                        const SizedBox(height: 16),
                        _buildInfoCard(
                          title: 'Análise Visual / Sintomas',
                          content: result.descricaoVisual,
                          icon: Icons.visibility,
                        ),
                        ProAccessWrapper(
                          featureName: 'Análise Profunda de Causas',
                          featureDescription: 'Acesse listas detalhadas de possíveis causas médicas e diagnósticos diferenciais.',
                          featureIcon: FontAwesomeIcons.stethoscope,
                          child: _buildInfoCard(
                            title: 'Possíveis Causas',
                            content: result.possiveisCausas.join('\n• '),
                            icon: Icons.list,
                            isList: true,
                          ),
                        ),
                        _buildInfoCard(
                          title: 'Identificação',
                          content: '${result.especie} - ${result.raca}',
                          icon: Icons.pets,
                        ),
                      ] else ...[
                        // IDENTIFICATION MODE: Breed First
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppDesign.info.withOpacity(0.2), AppDesign.primary.withOpacity(0.2)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppDesign.info.withOpacity(0.5)),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.pets, color: AppDesign.info, size: 40),
                              const SizedBox(height: 8),
                              Text(
                                '${result.especie} - ${result.raca}',
                                style: const TextStyle(
                                  color: AppDesign.textPrimaryDark,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                result.caracteristicas,
                                style: const TextStyle(color: AppDesign.textSecondaryDark, fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoCard(
                          title: 'Estado de Saúde',
                          content: result.descricaoVisual, // General health check text
                          icon: Icons.health_and_safety,
                        ),
                        // Only show urgency card if it's NOT just simple "Verde" (Healthy), or show a subtle version
                         _buildUrgencyCard(result),
                      ],

                      const SizedBox(height: 16),
                      
                      // Disclaimer Footer
                      const Text(
                        'Nota: Esta é uma análise feita por IA e não substitui um diagnóstico clínico.',
                        style: TextStyle(color: AppDesign.textSecondaryDark, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }

  Widget _buildUrgencyCard(PetAnalysisResult result) {
    Color color;
    IconData icon;
    String title;

    switch (result.urgenciaNivel) {
      case 'Vermelho':
        color = AppDesign.error;
        icon = AppDesign.iconAlert;
        title = 'Urgência Veterinária';
        break;
      case 'Amarelo':
        color = AppDesign.warning;
        icon = AppDesign.iconInfo; // Actually iconAlert is better for attention, but generic info is OK.
        // Wait, app design has iconAlert (warning). iconInfo? No.
        // AppDesign has no Generic Info icon? 
        // "iconAlert = Icons.warning_amber_rounded".
        // I'll use Icons.info_outline or AppDesign.logoIcon? No.
        // I will keep Icons.info_outline as it is not strictly defined in AppDesign yet (or user didn't mention it).
        // Or I can add it? No.
        // Ill keep Icons.info_outline.
        // But the color MUST change.
        icon = Icons.info_outline;
        title = 'Atenção Necessária';
        break;
      case 'Verde':
      default:
        color = AppDesign.success;
        icon = Icons.check_circle_outline;
        title = 'Observação';
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (result.urgenciaNivel == 'Vermelho') ...[
            const SizedBox(height: 12),
            const Text(
              'SINAIS CRÍTICOS IDENTIFICADOS.\nProcure um Veterinário Imediatamente.',
              style: TextStyle(
                color: AppDesign.textPrimaryDark,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Divider(color: AppDesign.textPrimaryDark.withOpacity(0.24)),
          const SizedBox(height: 12),
          const Text(
            'Orientação Imediata:',
            style: TextStyle(color: AppDesign.textSecondaryDark, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            result.orientacaoImediata,
            style: const TextStyle(color: AppDesign.textPrimaryDark, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required String content, required IconData icon, bool isList = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppDesign.backgroundDark.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppDesign.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppDesign.textSecondaryDark,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isList ? '• $content' : content,
                  style: const TextStyle(color: AppDesign.textPrimaryDark, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToEdit(BuildContext context, PetAnalysisResult result) {
     // 🛡️ Usar a imagem PERMANENTE se disponível, senão a original (cache)
     final imagePathToUse = _permanentImage?.path ?? widget.imageFile.path;
     
     // CRITICAL: Ensure the analysis payload also reflects the permanent path
     // Some UI parts look inside rawAnalysis for the image.
     result.imagePath = imagePathToUse;

     final profile = PetProfileExtended.fromAnalysisResult(result, imagePathToUse);

     Navigator.push(
        context, 
        MaterialPageRoute(
            builder: (_) => EditPetForm(
                existingProfile: profile, 
                isNewEntry: true,
                onSave: (savedProfile) async {
                    // 1. Save Profile (Source of Truth)
                    final profileService = PetProfileService();
                    await profileService.init();
                    await profileService.saveOrUpdateProfile(savedProfile.petName, savedProfile.toJson());
                    
                    // 2. Update History (Legacy List Support) NOVO: FLUSH IMEDIATO
                    final historyService = HistoryService();
                    await historyService.savePetAnalysis(
                        savedProfile.petName, 
                        savedProfile.rawAnalysis ?? {}, 
                        imagePath: savedProfile.imagePath
                    );
                    
                    // FORÇAR PERSISTÊNCIA VISUAL
                    final box = Hive.box(HistoryService.boxName);
                    if (box.isOpen) await box.flush();
                    
                    if (context.mounted) {
                        Navigator.pop(context); // Close Edit
                        Navigator.pop(context); // Close Result
                        ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(
                             content: Text('Perfil do pet salvo e atualizado! 🐾'),
                             backgroundColor: AppDesign.success,
                           ),
                        );
                    }
                }
            )
        )
     );
  }
}
