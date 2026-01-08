import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/pet_analysis_result.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../l10n/app_localizations.dart';

class PetAnalysisDetailsView extends StatelessWidget {
  final PetAnalysisResult result;
  final String? imagePath;
  final File? imageFile;

  const PetAnalysisDetailsView({
    Key? key, 
    required this.result, 
    this.imagePath,
    this.imageFile
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // Determine the image provider efficiently
    ImageProvider? imageProvider;
    if (imageFile != null) {
      imageProvider = FileImage(imageFile!);
    } else if (imagePath != null && imagePath!.isNotEmpty) {
      final f = File(imagePath!);
      if (f.existsSync()) {
        imageProvider = FileImage(f);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100), // Space for footer
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // 1. IMAGE HEADER (Full Width)
            Container(
              width: double.infinity,
              height: 240,
              decoration: BoxDecoration(
                color: AppDesign.surfaceDark,
                image: imageProvider != null ? DecorationImage(
                    image: imageProvider,
                    fit: BoxFit.cover,
                ) : null,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  )
                ),
                child: imageProvider == null ? const Center(child: Icon(Icons.pets, size: 60, color: Colors.white24)) : null,
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 2. IDENTITY CARD & WARNING
                  _buildIdentitySection(context, imageProvider),
                  const SizedBox(height: 16),
                  _buildAiDisclaimer(context),
                  const SizedBox(height: 24),

                  // 3. DIAGNOSIS (Conditional)
                  if (result.analysisType == 'diagnosis') ...[
                      _buildUrgencyCard(context),
                      const SizedBox(height: 16),
                  ],

                  // 4. ACCORDION SECTIONS
                  _buildSectionHeader(l10n.petResultDossier),
                  _buildAccordion(
                    title: l10n.petSectionObservedSigns,
                    icon: Icons.visibility_outlined,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCheckItem('${l10n.petSize}: ${result.identificacao.porteEstimado}'),
                        _buildCheckItem('${l10n.petCoatType}: ${result.higiene.manutencaoPelagem['tipo_pelo'] ?? 'Normal'}'),
                        if (result.descricaoVisualDiag != null && result.descricaoVisualDiag!.isNotEmpty) 
                           _buildCheckItem('Obs: ${result.descricaoVisualDiag}'),
                      ],
                    )
                  ),
                  
                  _buildAccordion(
                    title: l10n.petSectionNutrition,
                    icon: Icons.restaurant,
                    initiallyExpanded: true,
                    content: Column(
                      children: [
                          _buildDataRow(l10n.petMetaPuppy, result.nutricao.metaCalorica['kcal_filhote'] ?? l10n.petNoData),
                          _buildDataRow(l10n.petMetaAdult, result.nutricao.metaCalorica['kcal_adulto'] ?? l10n.petNoData),
                          _buildDataRow(l10n.petMetaSenior, result.nutricao.metaCalorica['kcal_senior'] ?? l10n.petNoData),
                          const Divider(color: Colors.white12),
                          Align(alignment: Alignment.centerLeft, child: Text('${l10n.petTargetNutrients}:', style: const TextStyle(color: Colors.white70, fontSize: 12))),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6, 
                            runSpacing: 6,
                            children: result.nutricao.nutrientesAlvo.map((n) => 
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: AppDesign.petPink.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppDesign.petPink.withOpacity(0.3))),
                                child: Text(n, style: const TextStyle(color: AppDesign.petPink, fontSize: 11)),
                              )
                            ).toList(),
                          )
                      ],
                    )
                  ),

                  _buildAccordion(
                    title: l10n.petSectionGrooming,
                    icon: Icons.content_cut,
                    content: Column(
                      children: [
                          _buildDataRow(l10n.petCoatType, result.higiene.manutencaoPelagem['tipo_pelo']?.toString() ?? l10n.petNoData),
                          _buildDataRow(l10n.petBrushingFreq, result.higiene.manutencaoPelagem['frequencia_escovacao_semanal']?.toString() ?? l10n.petNoData),
                          _buildDataRow(l10n.petBathSug, 'Quinzenal'),
                      ],
                    )
                  ),

                  _buildAccordion(
                    title: l10n.petSectionHealth,
                    icon: Icons.health_and_safety,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Text('${l10n.petPredispositions}:', style: const TextStyle(color: AppDesign.accent, fontSize: 12)),
                          ...result.saude.predisposicaoDoencas.map((e) => Padding(padding: const EdgeInsets.only(left: 8), child: Text('• $e', style: const TextStyle(color: Colors.white70)))),
                          const SizedBox(height: 8),
                          _buildDataRow(l10n.petCheckup, result.saude.checkupVeterinario['exames_obrigatorios_anuais'].toString()),
                      ],
                    )
                  ),

                  _buildAccordion(
                    title: l10n.petSectionLifestyle,
                    icon: Icons.psychology,
                    content: Column(
                      children: [
                          _buildDataRow(l10n.petEnergy, result.perfilComportamental.nivelEnergia > 0 ? '${result.perfilComportamental.nivelEnergia}/5' : 'Moderado'),
                          _buildDataRow(l10n.petIntelligence, result.perfilComportamental.nivelInteligencia > 0 ? '${result.perfilComportamental.nivelInteligencia}/5' : 'Média'),
                          _buildDataRow(l10n.petDrive, result.perfilComportamental.driveAncestral),
                      ],
                    )
                  ),

                  const SizedBox(height: 24),
                  
                  // 5. INSIGHT HIGHLIGHT
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppDesign.petPink.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppDesign.petPink.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [const Icon(Icons.lightbulb, color: AppDesign.petPink, size: 20), const SizedBox(width: 8), Text(l10n.petInsightSpecialist, style: const TextStyle(color: AppDesign.petPink, fontWeight: FontWeight.bold, fontSize: 16))]),
                        const SizedBox(height: 8),
                        Text(
                          result.dica.insightExclusivo.isNotEmpty ? result.dica.insightExclusivo : 'Mantenha vacinas em dia e proporcione uma dieta balanceada para longevidade.',
                          style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // --- Helpers ---
  Widget _buildIdentitySection(BuildContext context, ImageProvider? imageProvider) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Container(
             width: 80,
             height: 80, 
             decoration: BoxDecoration(
               shape: BoxShape.circle,
               border: Border.all(color: AppDesign.petPink, width: 2),
               image: imageProvider != null ? DecorationImage(
                 image: imageProvider,
                 fit: BoxFit.cover, 
               ) : null,
             ),
             child: imageProvider == null ? const Icon(Icons.pets, color: Colors.white54) : null,
           ),
           const SizedBox(width: 16),
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(result.petName ?? 'Pet', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                 const SizedBox(height: 4),
                 if (result.identificacao.racaPredominante != 'N/A')
                    Text('${result.identificacao.racaPredominante}', style: const TextStyle(color: AppDesign.accent, fontWeight: FontWeight.w500)),
                 const SizedBox(height: 4),
                 Text('${result.identificacao.porteEstimado} • ${result.identificacao.expectativaVidaMedia}', style: const TextStyle(color: Colors.white54, fontSize: 13)),
               ],
             ),
           )
        ],
      );
  }

  Widget _buildAiDisclaimer(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.petDisclaimerAI, style: const TextStyle(color: Colors.amber, fontSize: 11))),
        ],
      ),
    );
  }
  
  Widget _buildAccordion({required String title, required IconData icon, required Widget content, bool initiallyExpanded = false}) {
     return Card(
       color: Colors.white, // Changed to White
       margin: const EdgeInsets.only(bottom: 12),
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
       child: ExpansionTile(
         initiallyExpanded: initiallyExpanded,
         leading: Icon(icon, color: AppDesign.petPink),
         title: Text(title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600)), // Changed to Black
         iconColor: AppDesign.petPink,
         collapsedIconColor: Colors.black54, // Changed to Black54
         childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
         children: [content],
       ),
     );
  }

  Widget _buildCheckItem(String text) {
     return Padding(
       padding: const EdgeInsets.only(bottom: 6),
       child: Row(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           const Icon(Icons.check_circle, color: AppDesign.petPink, size: 14),
           const SizedBox(width: 8),
           Expanded(child: Text(text, style: const TextStyle(color: Colors.black87, fontSize: 13))), // Changed to Black87
         ],
       ),
     );
  }
  
  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
           Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)), // Changed to Black54
           Flexible(child: Text(value, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 13), textAlign: TextAlign.right)), // Changed to Black
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title.toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
    );
  }

  Widget _buildUrgencyCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Color color = AppDesign.success;
    String title = l10n.petUrgencyGreen;
    IconData icon = Icons.check_circle;

    if (result.urgenciaNivelDiag == 'Vermelho') {
      color = AppDesign.error;
      title = l10n.petUrgencyRed;
      icon = Icons.warning;
    } else if (result.urgenciaNivelDiag == 'Amarelo') {
      color = AppDesign.warning;
      title = l10n.petUrgencyYellow;
      icon = Icons.info;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.5))),
      child: Row(
        children: [
           Icon(icon, color: color),
           const SizedBox(width: 12),
           Expanded(child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
               if (result.urgenciaNivelDiag == 'Vermelho') Text(l10n.petSignCritical, style: TextStyle(color: color, fontSize: 12)),
             ],
           ))
        ],
      ),
    );
  }
}
