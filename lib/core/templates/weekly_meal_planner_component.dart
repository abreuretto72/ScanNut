import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WeeklyMealPlanner extends StatelessWidget {
  final List<Map<String, String>> weeklyPlan;
  final String? generalGuidelines;

    const WeeklyMealPlanner({Key? key, required this.weeklyPlan, this.generalGuidelines}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (generalGuidelines != null)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.tips_and_updates, color: Colors.orangeAccent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    generalGuidelines!,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: weeklyPlan.length,
          itemBuilder: (context, index) {
            final dayData = weeklyPlan[index];
            final dia = dayData['dia'] ?? 'Dia ${index + 1}';
            final refeicao = dayData['refeicao'] ?? '';
            final beneficio = dayData['beneficio'] ?? '';
            final initial = dia.isNotEmpty ? dia[0].toUpperCase() : '?';

            return Card(
              color: Colors.white.withValues(alpha: 0.05),
              elevation: 0,
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: Colors.greenAccent.withValues(alpha: 0.2),
                  child: Text(
                    initial,
                    style: GoogleFonts.poppins(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  dia,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      refeicao,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.star, color: Colors.amberAccent, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "Por que: $beneficio",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
