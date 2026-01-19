import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../services/pet_weight_database.dart';
import '../../../../../core/theme/app_design.dart';

class WeightFeedbackSection extends StatelessWidget {
  final TextEditingController pesoController;
  final String? raca;
  final String? porte;

  const WeightFeedbackSection({
    Key? key,
    required this.pesoController,
    required this.raca,
    required this.porte,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pesoController,
      builder: (context, _) {
        final weightStatus = _calculateStatus(context);
        if (weightStatus == null) return const SizedBox.shrink();
        
        return Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: weightStatus.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: weightStatus.color.withOpacity(0.3), width: 2)
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(weightStatus.icon, color: weightStatus.color, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      weightStatus.message, 
                      style: GoogleFonts.poppins(
                        color: weightStatus.color, 
                        fontSize: 14, 
                        fontWeight: FontWeight.bold
                      )
                    )
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: weightStatus.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${weightStatus.percentage}%',
                      style: TextStyle(
                        color: weightStatus.color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                weightStatus.getRecommendation(AppLocalizations.of(context)!),
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  WeightStatus? _calculateStatus(BuildContext context) {
    final currentWeight = double.tryParse(pesoController.text.trim().replaceAll(',', '.'));
    if (currentWeight == null || currentWeight == 0) return null;
    
    final idealWeight = PetWeightDatabase.getIdealWeight(raca: raca, porte: porte);
    if (idealWeight == null || idealWeight == 0) return null;

    return PetWeightDatabase.calculateWeightStatus(
      currentWeight: currentWeight,
      idealWeight: idealWeight,
      strings: AppLocalizations.of(context)!,
    );
  }
}
