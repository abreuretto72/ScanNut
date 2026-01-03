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
    final ident = raceAnalysis['identificacao'] as Map?;
    final temp = raceAnalysis['temperamento'] as Map?;
    final fisica = raceAnalysis['caracteristicas_fisicas'] as Map?;
    final cuidados = raceAnalysis['cuidados'] as Map?;
    final origem = raceAnalysis['origem_historia'] as String?;
    final curiosidades = raceAnalysis['curiosidades'] as List?;

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

            // Temperamento
            if (temp != null) ...[
              _buildSectionTitle(AppLocalizations.of(context)!.petTemperamentTitle, Icons.psychology),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (temp['personalidade'] != null) ...[
                      Text(
                        AppLocalizations.of(context)!.petPersonality,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF00E676),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        temp['personalidade'].toString(),
                        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (temp['comportamento_social'] != null) ...[
                      Text(
                        AppLocalizations.of(context)!.petSocialBehavior,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF00E676),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        temp['comportamento_social'].toString(),
                        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (temp['nivel_energia'] != null) ...[
                      Text(
                        AppLocalizations.of(context)!.petEnergyLevel,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF00E676),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        temp['nivel_energia'].toString(),
                        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Cuidados
            if (cuidados != null) ...[
              _buildSectionTitle(AppLocalizations.of(context)!.petRecommendedCare, Icons.favorite),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (cuidados['exercicio'] != null) ...[
                      _buildCareItem('🏃 ${AppLocalizations.of(context)!.petExercise}', cuidados['exercicio'].toString()),
                      const SizedBox(height: 12),
                    ],
                    if (cuidados['alimentacao'] != null) ...[
                      _buildCareItem('🍖 ${AppLocalizations.of(context)!.petNutrition}', cuidados['alimentacao'].toString()),
                      const SizedBox(height: 12),
                    ],
                    if (cuidados['higiene'] != null) ...[
                      _buildCareItem('🛁 ${AppLocalizations.of(context)!.petHygiene}', cuidados['higiene'].toString()),
                      const SizedBox(height: 12),
                    ],
                    if (cuidados['saude'] != null) ...[
                      _buildCareItem('💉 ${AppLocalizations.of(context)!.petHealth}', cuidados['saude'].toString()),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Origem e História
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
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Curiosidades
            if (curiosidades != null && curiosidades.isNotEmpty) ...[
              _buildSectionTitle(AppLocalizations.of(context)!.petCuriositiesTitle, Icons.lightbulb),
              const SizedBox(height: 12),
              ...curiosidades.map((curiosidade) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        curiosidade.toString(),
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ],

            const SizedBox(height: 40),
          ],
        ),
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
