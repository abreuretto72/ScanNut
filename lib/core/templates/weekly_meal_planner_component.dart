import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class WeeklyMealPlanner extends StatelessWidget {
  final List<Map<String, String>> weeklyPlan;
  final String? generalGuidelines;
  final DateTime? startDate;
  final String? dailyKcal; // Added Kcal Goal

    const WeeklyMealPlanner({
      super.key, 
      required this.weeklyPlan, 
      this.generalGuidelines, 
      this.startDate,
      this.dailyKcal,
    });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> displayedPlan = [];
    
    for (int i = 0; i < weeklyPlan.length; i++) {
        final item = Map<String, String>.from(weeklyPlan[i]);
        
        if (startDate != null) {
            final dateForDay = startDate!.add(Duration(days: i));
            final dateStr = DateFormat('dd/MM').format(dateForDay);
            final weekDayName = DateFormat('EEEE', 'pt_BR').format(dateForDay); 
            final weekDayCap = weekDayName[0].toUpperCase() + weekDayName.substring(1);
            item['dia'] = "$weekDayCap - $dateStr";
        } else {
            item['dia'] = item['dia'] ?? 'Dia ${i + 1}';
        }
        displayedPlan.add(item);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (generalGuidelines != null)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
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
        itemCount: displayedPlan.length,
        itemBuilder: (context, index) {
          final dayData = displayedPlan[index];
            final dia = dayData['dia'] ?? 'Dia ${index + 1}';
            final refeicao = dayData['refeicao'] ?? '';
            final beneficio = dayData['beneficio'] ?? '';
            final initial = dia.isNotEmpty ? dia[0].toUpperCase() : '?';

            return Card(
              color: Colors.white.withOpacity(0.05),
              elevation: 0,
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: Colors.greenAccent.withOpacity(0.2),
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
                    // Kcal Row per user request
                    if (dailyKcal != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Principais Nutrientes', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11)),
                          Text('$dailyKcal', style: GoogleFonts.poppins(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      refeicao,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.greenAccent, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            beneficio,
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

  String _getFormattedDate(DateTime date) {
    final dateFormat = DateFormat('EEEE - dd/MM', 'pt_BR');
    final formatted = dateFormat.format(date);
    return formatted[0].toUpperCase() + formatted.substring(1);
  }
}
