import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scannut/l10n/app_localizations.dart';

/// Tela de detalhes completos da análise da raça do pet
class RaceAnalysisDetailScreen extends StatelessWidget {
  final Map<String, dynamic> raceAnalysis;
  final String petName;

  const RaceAnalysisDetailScreen({
    Key? key,
    required this.raceAnalysis,
    required this.petName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 🛡️ DATA NORMALIZATION ADAPTER (EN/PT Support)
    // Extracts English keys first, falls back to Portuguese keys
    
    // 1. Identification
    Map? rawIdent = (raceAnalysis['identification'] ?? raceAnalysis['identificacao']) as Map?;
    Map<String, dynamic>? ident;
    if (rawIdent != null) {
       ident = {
          'linhagem_mista': rawIdent['lineage'] ?? rawIdent['linhagem_mista'],
          'raca_predominante': rawIdent['breed'] ?? rawIdent['raca_predominante'],
          'racas_secundarias': rawIdent['secondary_breeds'] ?? rawIdent['racas_secundarias'],
          'confiabilidade': rawIdent['confidence'] ?? rawIdent['confiabilidade'],
       };
    }

    // 2. Temperament
    Map? rawTemp = (raceAnalysis['temperament'] ?? raceAnalysis['temperamento']) as Map?;
    Map<String, dynamic>? temp;
    if (rawTemp != null) {
       temp = {
          'personalidade': rawTemp['personality'] ?? rawTemp['personalidade'],
          'comportamento_social': rawTemp['social_behavior'] ?? rawTemp['comportamento_social'],
          'nivel_energia': rawTemp['energy_level'] ?? rawTemp['nivel_energia'],
       };
    }

    // 3. Physical
    Map? rawFisica = (raceAnalysis['characteristics'] ?? raceAnalysis['caracteristicas_fisicas']) as Map?;
    Map<String, dynamic>? fisica;
    if (rawFisica != null) {
       fisica = {
          'porte': rawFisica['size'] ?? rawFisica['porte'],
          'peso_estimado': rawFisica['weight'] ?? rawFisica['peso_estimado'],
          'altura': rawFisica['height'] ?? rawFisica['altura'],
          'expectativa_vida': rawFisica['lifespan'] ?? rawFisica['longevity'] ?? rawFisica['expectativa_vida'],
          'tipo_pelagem': rawFisica['coat'] ?? rawFisica['tipo_pelagem'],
          'cores_comuns': rawFisica['colors'] ?? rawFisica['cores_comuns'],
       };
    }

    // 4. Care
    Map? rawCuidados = (raceAnalysis['care'] ?? raceAnalysis['cuidados']) as Map?;
    Map<String, dynamic>? cuidados;
    if (rawCuidados != null) {
       cuidados = {
          'exercicio': rawCuidados['exercise'] ?? rawCuidados['exercicio'],
          'alimentacao': rawCuidados['nutrition'] ?? rawCuidados['alimentacao'],
          'higiene': rawCuidados['grooming'] ?? rawCuidados['higiene'],
          'saude': rawCuidados['health'] ?? rawCuidados['saude'],
       };
    }

    // 5. Origin & Curiosities
    final origem = (raceAnalysis['origin'] ?? raceAnalysis['origin_history'] ?? raceAnalysis['origem'] ?? raceAnalysis['origem_historia'])?.toString();
    final curiosidades = (raceAnalysis['curiosities'] ?? raceAnalysis['fun_facts'] ?? raceAnalysis['curiosidades']) as List?;

    // 6. NEW INFERENCE MODEL SUPPORT (Lifestyle, Nutrition, Health, Grooming)
    Map? rawLifestyle = raceAnalysis['lifestyle'] as Map?;
    Map? rawNutrition = raceAnalysis['nutrition'] as Map?;
    Map? rawGrooming = raceAnalysis['grooming'] as Map?;
    Map? rawHealth = raceAnalysis['health'] as Map?;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.petFullAnalysisTitle,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com nome do pet
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E676), Color(0xFF00C853)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.pets, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          petName,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context)!.petGeneticAnalysisSub,
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Identificação
            if (ident != null) ...[
              _buildSectionTitle(AppLocalizations.of(context)!.petGeneticId, Icons.science),
              const SizedBox(height: 12),
              _buildInfoCard([
                _buildInfoRow(AppLocalizations.of(context)!.petLineage, ident['linhagem_mista']?.toString() ?? AppLocalizations.of(context)!.petNotIdentified),
                _buildInfoRow(AppLocalizations.of(context)!.petPrimaryRace, ident['raca_predominante']?.toString() ?? AppLocalizations.of(context)!.petNotIdentified),
                _buildInfoRow(AppLocalizations.of(context)!.petSecondaryRaces, ident['racas_secundarias']?.toString() ?? AppLocalizations.of(context)!.petNotIdentifiedPlural),
                _buildInfoRow(AppLocalizations.of(context)!.petReliability, ident['confiabilidade']?.toString() ?? AppLocalizations.of(context)!.petReliabilityLow),
              ]),
              const SizedBox(height: 20),
            ],

            // Características Físicas
            if (fisica != null) ...[
              _buildSectionTitle(AppLocalizations.of(context)!.petPhysicalChars, Icons.straighten),
              const SizedBox(height: 12),
              _buildInfoCard([
                _buildInfoRow(AppLocalizations.of(context)!.petSize, fisica['porte']?.toString() ?? AppLocalizations.of(context)!.petNotIdentified),
                _buildInfoRow(AppLocalizations.of(context)!.petWeightEstimated, fisica['peso_estimado']?.toString() ?? AppLocalizations.of(context)!.petVariable),
                _buildInfoRow(AppLocalizations.of(context)!.petHeight, fisica['altura']?.toString() ?? AppLocalizations.of(context)!.petNotEstimated),
                _buildInfoRow(AppLocalizations.of(context)!.petExpectancy, fisica['expectativa_vida']?.toString() ?? AppLocalizations.of(context)!.petNotEstimated),
                _buildInfoRow(AppLocalizations.of(context)!.petCoatType, fisica['tipo_pelagem']?.toString() ?? AppLocalizations.of(context)!.petNotIdentified),
                _buildInfoRow(AppLocalizations.of(context)!.petCommonColors, fisica['cores_comuns']?.toString() ?? AppLocalizations.of(context)!.petVaried),
              ]),
              const SizedBox(height: 20),
            ],

            // === NEW SECTIONS (Inference Master) ===
            
            // 1. Lifestyle
            if (rawLifestyle != null) ...[
                _buildSectionTitle('Estilo de Vida & Ambiente', Icons.home),
                 const SizedBox(height: 12),
                 _buildGenericMapCard(rawLifestyle),
                 const SizedBox(height: 20),
            ],

            // 2. Nutrição
           if (rawNutrition != null) ...[
                _buildSectionTitle('Nutrição Recomendada', Icons.restaurant),
                 const SizedBox(height: 12),
                 _buildGenericMapCard(rawNutrition),
                 const SizedBox(height: 20),
            ],

            // 3. Higiene (Grooming)
           if (rawGrooming != null) ...[
                _buildSectionTitle('Higiene & Cuidados', Icons.content_cut),
                 const SizedBox(height: 12),
                 _buildGenericMapCard(rawGrooming),
                 const SizedBox(height: 20),
            ],

            // 4. Saúde (Health)
           if (rawHealth != null) ...[
                _buildSectionTitle('Saúde & Prevenção', Icons.local_hospital),
                 const SizedBox(height: 12),
                 _buildGenericMapCard(rawHealth),
                 const SizedBox(height: 20),
            ],
            
            // === LEGACY SECTIONS ===

            // Temperamento (Legacy)
            if (temp != null) ...[
              _buildSectionTitle(AppLocalizations.of(context)!.petTemperamentTitle, Icons.psychology),
              const SizedBox(height: 12),
              _buildInfoCard(temp.entries.map((e) => _buildInfoRow(e.key.toUpperCase(), e.value.toString())).toList()),
              const SizedBox(height: 20),
            ],

            // Cuidados (Legacy)
            if (cuidados != null) ...[
              _buildSectionTitle(AppLocalizations.of(context)!.petRecommendedCare, Icons.favorite),
              const SizedBox(height: 12),
              _buildInfoCard(cuidados.entries.map((e) => _buildCareItem(e.key.toUpperCase(), e.value.toString())).toList()),
              const SizedBox(height: 20),
            ],

            // Origem e História (Legacy)
            if (origem != null && origem.isNotEmpty) ...[
              _buildSectionTitle(AppLocalizations.of(context)!.petOriginHistory, Icons.history_edu),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Text(
                  origem,
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13, height: 1.6),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Curiosidades (Legacy)
            if (curiosidades != null && curiosidades.isNotEmpty) ...[
              _buildSectionTitle(AppLocalizations.of(context)!.petCuriositiesTitle, Icons.lightbulb),
              const SizedBox(height: 12),
              ...curiosidades.map((curiosidade) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(curiosidade.toString(), style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)))
                  ])
              )).toList(),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Helper Widget for Generic Maps
  Widget _buildGenericMapCard(Map map) {
     return Container(
       padding: const EdgeInsets.all(16),
       decoration: BoxDecoration(
         color: Colors.white.withOpacity(0.05),
         borderRadius: BorderRadius.circular(12),
         border: Border.all(color: Colors.white.withOpacity(0.1)),
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: map.entries.map((e) {
            final val = e.value;
            if (val is Map) return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                 Text(e.key.toString().toUpperCase(), style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 12)),
                 const SizedBox(height: 4),
                 _buildGenericMapCard(val),
                 const SizedBox(height: 8),
            ]);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text('${e.key.toString().replaceAll('_', ' ').toUpperCase()}: ', style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 11)),
                   Expanded(child: Text(val.toString(), style: const TextStyle(color: Colors.white70, fontSize: 11))),
                ]
              ),
            );
         }).toList(),
       ),
     );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00E676), size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: const Color(0xFF00E676),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            color: const Color(0xFF00E676),
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
