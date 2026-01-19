import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_design.dart';
import '../../../core/utils/color_helper.dart';
import '../models/pet_analysis_result.dart';
import '../models/pet_profile_extended.dart';
import '../models/analise_ferida_model.dart';

class DeepAnalysisPetScreen extends StatefulWidget {
  final PetAnalysisResult analysis;
  final String imagePath;
  final PetProfileExtended? petProfile;

  const DeepAnalysisPetScreen({
    Key? key,
    required this.analysis,
    required this.imagePath,
    this.petProfile,
  }) : super(key: key);

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
          'Deep Analysis 360°',
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
            tabs: const [
              Tab(text: 'Diagnóstico'),
              Tab(text: 'Biometria'),
              Tab(text: 'Evolução'),
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
                  widget.petProfile?.petName ?? widget.analysis.petName ?? 'Pet Desconhecido',
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. ANÁLISE VISUAL (NOVA SEÇÃO)
          if (widget.analysis.descricaoVisual.isNotEmpty && widget.analysis.descricaoVisual != 'N/A') ...[
             _buildSectionTitle('Descrição Visual'),
             Container(
               padding: const EdgeInsets.all(12),
               margin: const EdgeInsets.only(bottom: 20),
               decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
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
             _buildSectionTitle('Características Observadas'),
             _buildBulletPoint(widget.analysis.caracteristicas),
             const SizedBox(height: 20),
          ],
          
          // 3. SINAIS CLÍNICOS (Iteração Robusta)
          if (widget.analysis.clinicalSignsDiag != null && widget.analysis.clinicalSignsDiag!.isNotEmpty) ...[
            _buildSectionTitle('Sinais Clínicos Detalhados'),
            ...widget.analysis.clinicalSignsDiag!.entries.where((e) {
                 final k = e.key.toString().toLowerCase();
                 return !['identification', 'identificacao', 'pet_name', 'analysis_type', 'metadata'].contains(k);
            }).map((e) {
                 // Clean & Translate Key
                 String label = _translateKey(e.key.toString());
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
                            )).toList(),
                            const SizedBox(height: 12),
                        ],
                     );
                 } else if (rawVal is Map) {
                      // Caso seja mapa, tenta unificar
                      return _buildInfoTile(label, rawVal.toString()); 
                 }
                 
                 String val = rawVal.toString();
                 if (val == 'null' || val.trim().isEmpty) val = 'Não detectado';
                 return _buildInfoTile(label, val);
            }),
            const SizedBox(height: 20),
          ],
          
          _buildSectionTitle('Diagnósticos Prováveis'),
          if (widget.analysis.possiveisCausas.isNotEmpty)
            ...widget.analysis.possiveisCausas.map((c) => _buildBulletPoint(c))
          else
            const Text('Nenhum diagnóstico provável listado.', style: TextStyle(color: Colors.white70)),
            
          const SizedBox(height: 20),
          _buildSectionTitle('Recomendação'),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Análise de Profundidade & Relevo'),
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
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.layers, size: 40, color: AppDesign.petPink),
                  SizedBox(height: 8),
                  Text(
                    "Mapeamento 3D Indisponível (Beta)",
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          _buildSectionTitle('Biometria Detalhada'),
          if (signs.isEmpty)
             const Text('Sem dados biométricos detalhados.', style: TextStyle(color: Colors.white70)),

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
          "Primeira Análise Registrada",
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
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
                        item.nivelRisco,
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

  // 📝 TRANSLATION MAP (English AI Keys -> Portuguese UI)
  static final Map<String, String> _keyTranslations = {
    'IDENTIFICATION': 'IDENTIFICAÇÃO',
    'BREED_NAME': 'RAÇA',
    'BREED NAME': 'RAÇA',
    'ORIGIN_REGION': 'REGIÃO DE ORIGEM',
    'ORIGIN REGION': 'REGIÃO DE ORIGEM',
    'MORPHOLOGY_TYPE': 'TIPO MORFOLÓGICO',
    'MORPHOLOGY TYPE': 'TIPO MORFOLÓGICO',
    'LINEAGE': 'LINHAGEM',
    'SIZE': 'PORTE',
    'LIFESPAN': 'EXPECTATIVA DE VIDA',
    'GROWTH_CURVE': 'CURVA DE CRESCIMENTO', 
    'GROWTH CURVE': 'CURVA DE CRESCIMENTO',
    'NUTRITION': 'NUTRIÇÃO',
    'KCAL_PUPPY': 'KCAL FILHOTE',
    'KCAL PUPPY': 'KCAL FILHOTE',
    'KCAL_ADULT': 'KCAL ADULTO', 
    'KCAL ADULT': 'KCAL ADULTO',
    'KCAL_SENIOR': 'KCAL SENIOR',
    'TARGET_NUTRIENTS': 'NUTRIENTES ALVO',
    'TARGET NUTRIENTS': 'NUTRIENTES ALVO',
    'WEIGHT': 'PESO',
    'HEIGHT': 'ALTURA',
    'COAT': 'PELAGEM',
    'COLOR': 'COR',
    'TEMPERAMENT': 'TEMPERAMENTO',
    'ENERGY_LEVEL': 'NÍVEL DE ENERGIA',
    'SOCIAL_BEHAVIOR': 'COMPORTAMENTO SOCIAL',
    'CLINICAL_SIGNS': 'SINAIS CLÍNICOS',
    'CLINICAL SIGNS': 'SINAIS CLÍNICOS',
    
    // Additional Keys from Analysis
    'GROOMING': 'CUIDADOS & HIGIENE',
    'COAT_TYPE': 'TIPO DE PELAGEM',
    'COAT TYPE': 'TIPO DE PELAGEM',
    'GROOMING_FREQUENCY': 'FREQUÊNCIA DE ESCOVAÇÃO',
    'GROOMING FREQUENCY': 'FREQUÊNCIA DE ESCOVAÇÃO',
    'HEALTH': 'SAÚDE',
    'PREDISPOSITIONS': 'PREDISPOSIÇÕES',
    'PREVENTIVE_CHECKUP': 'CHECK-UP PREVENTIVO',
    'PREVENTIVE CHECKUP': 'CHECK-UP PREVENTIVO',
    'LIFESTYLE': 'ESTILO DE VIDA',
    'TRAINING_INTELLIGENCE': 'INTELIGÊNCIA / TREINAMENTO',
    'TRAINING INTELLIGENCE': 'INTELIGÊNCIA / TREINAMENTO',
    'ENVIRONMENT_TYPE': 'AMBIENTE IDEAL',
    'ENVIRONMENT TYPE': 'AMBIENTE IDEAL',
    'ACTIVITY_LEVEL': 'NÍVEL DE ATIVIDADE',
    'ACTIVITY LEVEL': 'NÍVEL DE ATIVIDADE',
    'PERSONALITY': 'PERSONALIDADE',
  };

  String _translateKey(String key) {
    final upper = key.toUpperCase();
    // Try exact match
    if (_keyTranslations.containsKey(upper)) return _keyTranslations[upper]!;
    
    // Try with underscore/space swap
    final withUnderscore = upper.replaceAll(' ', '_');
    if (_keyTranslations.containsKey(withUnderscore)) return _keyTranslations[withUnderscore]!;
    
    final withSpace = upper.replaceAll('_', ' ');
    if (_keyTranslations.containsKey(withSpace)) return _keyTranslations[withSpace]!;

    // Fallback: Just return the cleaned string
    return withSpace; 
  }
}
