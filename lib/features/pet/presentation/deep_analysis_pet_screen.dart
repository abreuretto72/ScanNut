import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_design.dart';
import '../../../core/utils/color_helper.dart';
import '../models/pet_analysis_result.dart';
import '../models/pet_profile_extended.dart';
import '../../../l10n/app_localizations.dart';

class DeepAnalysisPetScreen extends StatefulWidget {
  final PetAnalysisResult analysis;
  final String imagePath;
  final PetProfileExtended? petProfile;

  const DeepAnalysisPetScreen({
    super.key,
    required this.analysis,
    required this.imagePath,
    this.petProfile,
  });

  @override
  State<DeepAnalysisPetScreen> createState() => _DeepAnalysisPetScreenState();
}

class _DeepAnalysisPetScreenState extends State<DeepAnalysisPetScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesign.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.deepAnalysisTitle,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildHeader(),
          TabBar(
            controller: _tabController,
            indicatorColor: AppDesign.petPink,
            labelColor: AppDesign.petPink,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(text: AppLocalizations.of(context)!.tabDiagnosis),
              Tab(text: AppLocalizations.of(context)!.tabBiometrics),
              Tab(text: AppLocalizations.of(context)!.tabEvolution),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDiagnosisTab(),
                _buildBiometricsTab(),
                _buildEvolutionTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(widget.imagePath),
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 80,
                height: 80,
                color: Colors.grey[800],
                child: const Icon(Icons.pets, color: Colors.white54),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.petProfile?.petName ?? widget.analysis.petName ?? AppLocalizations.of(context)!.petUnknown,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  widget.analysis.urgenciaNivel,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: ColorHelper.getPetThemeColor(widget.analysis.urgenciaNivel),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosisTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // 🛡️ V_FIX: Protected Footer Padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. ANÁLISE VISUAL (NOVA SEÇÃO)
          if (widget.analysis.descricaoVisual.isNotEmpty && widget.analysis.descricaoVisual != 'N/A') ...[
             _buildSectionTitle(AppLocalizations.of(context)!.sectionVisualDesc),
             Container(
               padding: const EdgeInsets.all(12),
               margin: const EdgeInsets.only(bottom: 20),
               decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
               ),
               child: Text(
                 widget.analysis.descricaoVisual,
                 style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
               ),
             ),
          ],

          // 2. CARACTERÍSTICAS
          if (widget.analysis.caracteristicas.isNotEmpty && widget.analysis.caracteristicas != 'N/A') ...[
             _buildSectionTitle(AppLocalizations.of(context)!.sectionObservedFeatures),
             _buildBulletPoint(widget.analysis.caracteristicas),
             const SizedBox(height: 20),
          ],
          
          // 3. SINAIS CLÍNICOS (Iteração Robusta)
          if (widget.analysis.clinicalSignsDiag != null && widget.analysis.clinicalSignsDiag!.isNotEmpty) ...[
            _buildSectionTitle(AppLocalizations.of(context)!.sectionClinicalSigns),
            ...widget.analysis.clinicalSignsDiag!.entries.where((e) {
                 final k = e.key.toString().toLowerCase();
                 return !['identification', 'identificacao', 'pet_name', 'analysis_type', 'metadata'].contains(k);
            }).map((e) {
                 // Clean & Translate Key
                 String label = _translateKey(e.key.toString(), AppLocalizations.of(context)!);
                 dynamic rawVal = e.value;
                 
                 if (rawVal is List) {
                     // Caso seja lista, exibe como subtópicos
                     return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                            const SizedBox(height: 4),
                            ...rawVal.map((item) => Padding(
                                padding: const EdgeInsets.only(left: 12, bottom: 4),
                                child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                        const Text('• ', style: TextStyle(color: AppDesign.petPink)),
                                        Expanded(child: Text(item.toString(), style: const TextStyle(color: Colors.white70, fontSize: 13))),
                                    ],
                                ),
                            )),
                            const SizedBox(height: 12),
                        ],
                     );
                 } else if (rawVal is Map) {
                      // Caso seja mapa, tenta unificar
                      return _buildInfoTile(label, rawVal.toString()); 
                 }
                 
                 String val = rawVal.toString();
                 if (val == 'null' || val.trim().isEmpty) val = AppLocalizations.of(context)!.petNotIdentified;
                 return _buildInfoTile(label, val);
            }),
            const SizedBox(height: 20),
          ],
          
          _buildSectionTitle(AppLocalizations.of(context)!.sectionProbableDiagnosis),
          if (widget.analysis.possiveisCausas.isNotEmpty)
            ...widget.analysis.possiveisCausas.map((c) => _buildBulletPoint(c))
          else
            Text(AppLocalizations.of(context)!.noDiagnosisListed, style: const TextStyle(color: Colors.white70)),
            
          const SizedBox(height: 20),
          _buildSectionTitle(AppLocalizations.of(context)!.sectionRecommendation),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppDesign.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppDesign.petPink.withValues(alpha: 0.3)),
            ),
            child: Text(
              widget.analysis.orientacaoImediata,
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricsTab() {
    // Exibe detalhes específicos de olhos/pele se disponíveis nos sinais clínicos
    final signs = widget.analysis.clinicalSignsDiag ?? {};
    
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // 🛡️ V_FIX: Protected Footer Padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(AppLocalizations.of(context)!.sectionDepthAnalysis),
          const SizedBox(height: 8),
          Container(
            height: 150,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black54, AppDesign.petPink.withValues(alpha: 0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.layers, size: 40, color: AppDesign.petPink),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.analysis3DUnavailable,
                    style: const TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          _buildSectionTitle(AppLocalizations.of(context)!.sectionDetailedBiometrics),
          if (signs.isEmpty)
             Text(AppLocalizations.of(context)!.noBiometricsListed, style: const TextStyle(color: Colors.white70)),

          ...signs.entries.map((e) {
             IconData icon = Icons.analytics;
             if (e.key.toLowerCase().contains('olho') || e.key.toLowerCase().contains('ocular')) icon = Icons.remove_red_eye;
             if (e.key.toLowerCase().contains('pele') || e.key.toLowerCase().contains('derma')) icon = Icons.spa;
             
             return Card(
               color: AppDesign.surfaceDark,
               margin: const EdgeInsets.symmetric(vertical: 6),
               child: ListTile(
                 leading: Icon(icon, color: AppDesign.petPink),
                 title: Text(e.key, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                 subtitle: Text(e.value, style: const TextStyle(color: Colors.white70)),
               ),
             );
          }),
        ],
      ),
    );
  }

  Widget _buildEvolutionTab() {
    final history = widget.petProfile?.historicoAnaliseFeridas ?? [];

    if (history.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.analysisFirstRecord,
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // 🛡️ V_FIX: Protected Footer Padding
      itemCount: history.length,
      itemBuilder: (context, index) {
        // Ordenação reversa (mais recente primeiro) se a lista não estiver ordenada
        // Mas assumindo que vamos mostrar a lista como está ou ordenar aqui.
        // Vamos mostrar do mais recente para o mais antigo.
        final item = history[history.length - 1 - index]; 
        
        return Card(
          color: AppDesign.surfaceDark,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(item.imagemRef),
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_,__,___) => Container(width: 60, height: 60, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(item.dataAnalise),
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _translateStatus(item.nivelRisco, AppLocalizations.of(context)!),
                        style: TextStyle(
                          color: ColorHelper.getPetThemeColor(item.nivelRisco),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.recomendacao,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppDesign.petPink,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, color: AppDesign.petPink, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                children: [
                  TextSpan(
                    text: "$label: ",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: Colors.white60),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  String _translateKey(String key, AppLocalizations l10n) {
    final upper = key.toUpperCase().replaceAll(' ', '_');
    
    final Map<String, String> mapper = {
      'IDENTIFICATION': l10n.labelIdentification,
      'BREED_NAME': l10n.labelBreed,
      'ORIGIN_REGION': l10n.labelOriginRegion,
      'MORPHOLOGY_TYPE': l10n.labelMorphologyType,
      'LINEAGE': l10n.labelLineage,
      'SIZE': l10n.labelSize,
      'LIFESPAN': l10n.labelLifespan,
      'GROWTH_CURVE': l10n.labelGrowthCurve,
      'NUTRITION': l10n.labelNutrition,
      'KCAL_PUPPY': l10n.labelKcalPuppy,
      'KCAL_ADULT': l10n.labelKcalAdult,
      'KCAL_SENIOR': l10n.labelKcalSenior,
      'TARGET_NUTRIENTS': l10n.labelTargetNutrients,
      'WEIGHT': l10n.labelWeight,
      'HEIGHT': l10n.labelHeight,
      'COAT': l10n.labelCoat,
      'COLOR': l10n.labelColor,
      'TEMPERAMENT': l10n.labelTemperament,
      'ENERGY_LEVEL': l10n.labelEnergyLevel,
      'SOCIAL_BEHAVIOR': l10n.labelSocialBehavior,
      'CLINICAL_SIGNS': l10n.labelClinicalSigns,
      'GROOMING': l10n.labelGrooming,
      'COAT_TYPE': l10n.labelCoatType,
      'GROOMING_FREQUENCY': l10n.labelGroomingFrequency,
      'HEALTH': l10n.labelHealth,
      'PREDISPOSITIONS': l10n.labelPredispositions,
      'PREVENTIVE_CHECKUP': l10n.labelPreventiveCheckup,
      'LIFESTYLE': l10n.labelLifestyle,
      'TRAINING_INTELLIGENCE': l10n.labelTrainingIntelligence,
      'ENVIRONMENT_TYPE': l10n.labelEnvironmentType,
      'ACTIVITY_LEVEL': l10n.labelActivityLevel,
      'PERSONALITY': l10n.labelPersonality,
      'EYES': l10n.labelEyes,
      'SKIN': l10n.labelSkin,
      'DENTAL': l10n.labelDental,
      'ORAL': l10n.labelOral,
      'STOOL': l10n.labelStool,
      'WOUNDS': l10n.labelWounds,
      'EYE': l10n.labelEyes,
    };

    return mapper[upper] ?? key.replaceAll('_', ' ').toUpperCase();
  }

  String _translateStatus(String status, AppLocalizations l10n) {
    switch (status.toLowerCase().trim()) {
      case 'verde':
      case 'green':
      case 'bajo':
      case 'low':
        return l10n.commonGreen;
      case 'amarelo':
      case 'yellow':
      case 'medio':
      case 'medium':
        return l10n.commonYellow;
      case 'vermelho':
      case 'red':
      case 'rojo':
      case 'high':
      case 'alta':
        return l10n.commonRed;
      default:
        return status;
    }
  }
}
