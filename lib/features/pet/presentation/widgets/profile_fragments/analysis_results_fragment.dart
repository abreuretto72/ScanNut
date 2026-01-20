import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../../../../../core/theme/app_design.dart';
import '../../../../../l10n/app_localizations.dart';
import '../sound_analysis_card.dart';
import '../pet_body_analysis_card.dart';

class AnalysisResultsFragment extends StatelessWidget {
  final List<Map<String, dynamic>> analysisHistory;
  final Map<String, dynamic>? currentRawAnalysis;
  final String petName;
  final String? existingProfilePetName;
  final DateTime? existingProfileLastUpdated;
  
  final String Function(BuildContext, String) tryLocalizeLabel;
  final String? Function(Map) findBreedRecursive;
  final Function(Map<String, dynamic>)? onDeleteAnalysis;
  final VoidCallback? onAnalysisSaved; // 🔄 Novo callback

  const AnalysisResultsFragment({
    Key? key,
    required this.analysisHistory,
    required this.currentRawAnalysis,
    required this.petName,
    this.existingProfilePetName,
    this.existingProfileLastUpdated,
    required this.tryLocalizeLabel,
    required this.findBreedRecursive,
    this.onDeleteAnalysis,
    this.onAnalysisSaved, // 🔄 Novo parâmetro
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final history = analysisHistory;
    final current = currentRawAnalysis;
    final hasData = history.isNotEmpty || (current != null && current.isNotEmpty);

    // Empty check moved inside Column


    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          SoundAnalysisCard(
            petName: petName,
            analysisHistory: analysisHistory,
            onDeleteAnalysis: onDeleteAnalysis,
            onAnalysisSaved: onAnalysisSaved,
          ),
          const SizedBox(height: 16),
          PetBodyAnalysisCard(
            petName: petName,
            analysisHistory: analysisHistory,
            onDeleteAnalysis: onDeleteAnalysis,
            onAnalysisSaved: onAnalysisSaved,
          ),
          const SizedBox(height: 16),
          if (!hasData)
             Padding(
               padding: const EdgeInsets.symmetric(vertical: 40),
               child: Column(children: [
                 const Icon(Icons.analytics_outlined, size: 50, color: Colors.white12),
                 const SizedBox(height: 10),
                 Text(l10n.petHistoryEmpty, style: GoogleFonts.poppins(color: Colors.white24)),
               ]),
             )
          else
            ...List.generate(history.length + (current != null && current.isNotEmpty && history.isEmpty ? 1 : 0) + 1, (index) {
          if (index == 0) {
              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.amberAccent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.petAnalysisDisclaimer,
                        style: GoogleFonts.poppins(color: Colors.amberAccent, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              );
          }
          
          final actualIndex = index - 1;
          Map<String, dynamic> data;
          if (history.isEmpty) {
              data = current!;
          } else {
              data = history[history.length - 1 - actualIndex];
          }
          
          final rawType = data['analysis_type']?.toString() ?? '';
          final type = rawType.isNotEmpty 
              ? tryLocalizeLabel(context, rawType).toUpperCase() 
              : l10n.petAnalysisDefaultTitle;
          
          String dateStr = l10n.petAnalysisDateUnknown;
          DateTime? dt;
          if (data['last_updated'] != null) {
             try {
                 dt = DateTime.parse(data['last_updated'].toString());
             } catch (_) {}
          } else if (existingProfilePetName != null) {
             dt = existingProfileLastUpdated;
          }

          if (dt != null) {
             dateStr = '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2,'0')}';
             if (data['last_updated'] == null) {
                 dateStr += l10n.petAnalysisProfileDate;
             }
          }

          String? extractedBreed = data['breed']?.toString() ?? findBreedRecursive(data);
          
          if (extractedBreed == null) {
              final str = data.toString();
              final match = RegExp(r'(?:breed|raca)[:]\s*([^,}\]]+)', caseSensitive: false).firstMatch(str);
              if (match != null) extractedBreed = match.group(1)?.trim();
          }

          String petNameFn = data['pet_name']?.toString() ?? data['name']?.toString() ?? '';
          if (petNameFn.isEmpty || petNameFn.toLowerCase() == 'null') {
              petNameFn = petName;
          }
          
          String subtitle = petNameFn;
          if (extractedBreed != null && 
              extractedBreed.toLowerCase() != 'null' && 
              extractedBreed.toLowerCase() != 'n/a' && 
              extractedBreed.trim().isNotEmpty) {
              if (subtitle.isNotEmpty) {
                  subtitle += ' - $extractedBreed';
              } else {
                  subtitle = extractedBreed!;
              }
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10)
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(type, style: const TextStyle(color: AppDesign.petPink, fontWeight: FontWeight.bold)),
                    const Icon(Icons.history, size: 16, color: Colors.white30)
                ]),
                
                if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                        subtitle, 
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)
                    ),
                ],
                
                const SizedBox(height: 8),
                Text(dateStr, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                const Divider(color: Colors.white10),
                
                ...data.entries.where((e) {
                    final k = e.key;
                    final v = e.value;
                    final lowerK = k.toLowerCase().trim();
                    if (['analysis_type', 'last_updated', 'pet_name', 'tabela_benigna', 'tabela_maligna', 'plano_semanal', 'weekly_plan', 'data_inicio_semana', 'data_fim_semana', 'orientacoes_gerais', 'general_guidelines', 'start_date', 'end_date', 'identificacao', 'identification', 'clinical_signs', 'sinais_clinicos', 'metadata', 'temperament', 'temperamento'].contains(lowerK)) return false;
                    
                    if (v == null || v.toString().toLowerCase() == 'null') return false;
                    if (v is String && v.trim().isEmpty) return false;
                    
                    return true;
                }).map((e) {
                   final val = e.value;
                   
                   if (e.key.contains('image_path') && val is String) {
                       return _buildImageLink(context, val);
                   }

                   if (val is Map) {
                       return ExpansionTile(
                           initiallyExpanded: true,
                           title: Text(tryLocalizeLabel(context, e.key), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                           childrenPadding: const EdgeInsets.only(left: 16, bottom: 8),
                           children: (val as Map).entries.where((sub) => sub.value != null).map((sub) => Padding(
                               padding: const EdgeInsets.only(bottom: 4),
                               child: Row(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                       Text('${tryLocalizeLabel(context, sub.key)}: ', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                                       Expanded(child: Text(sub.value.toString(), style: const TextStyle(color: Colors.white, fontSize: 11))),
                                   ]
                               ),
                           )).toList(),
                       );
                   }
                   return Padding(
                       padding: const EdgeInsets.symmetric(vertical: 4),
                       child: Row(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                               Text('${tryLocalizeLabel(context, e.key)}: ', style: const TextStyle(color: AppDesign.petPink, fontSize: 11, fontWeight: FontWeight.bold)),
                               Expanded(child: Text(val.toString(), style: const TextStyle(color: Colors.white70, fontSize: 11))),
                           ]
                       ),
                   );
                }).toList(),
            ]),
          );
        }),
      ],
      ),
    );
  }

  Widget _buildImageLink(BuildContext context, String val) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
        onTap: () async {
            String finalPath = val;
            if (!File(finalPath).existsSync()) {
                try {
                    final dir = await getApplicationDocumentsDirectory();
                    final filename = path.basename(finalPath);
                    var rPath = path.join(dir.path, filename);
                    if (File(rPath).existsSync()) {
                        finalPath = rPath;
                    } else if (petName.isNotEmpty) {
                        rPath = path.join(dir.path, 'medical_docs', petName, filename);
                        if (File(rPath).existsSync()) finalPath = rPath;
                    }
                } catch (e) {
                    debugPrint('Recovery error: $e');
                }
            }

            if (File(finalPath).existsSync()) {
                if (!context.mounted) return;
                showDialog(context: context, builder: (_) => Dialog(
                    backgroundColor: Colors.transparent,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Image.file(File(finalPath)),
                        TextButton(
                            onPressed: () => Navigator.pop(context), 
                            child: Text(l10n.commonClose, style: const TextStyle(color: Colors.white))
                        )
                    ])
                ));
            }
        },
        child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white12)),
            child: Row(children: [
                const Icon(Icons.image, color: AppDesign.petPink, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(l10n.petAnalysisViewImage, style: const TextStyle(color: AppDesign.petPink, fontWeight: FontWeight.bold, fontSize: 12))),
                const Icon(Icons.open_in_new, color: Colors.white30, size: 16)
            ]),
        )
    );
  }
}
