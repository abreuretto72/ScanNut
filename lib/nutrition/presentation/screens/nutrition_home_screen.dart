import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'weekly_plan_screen.dart';

/// Tela principal do módulo de Gestão de Nutrição
/// MVP - Offline-First com Hive
class NutritionHomeScreen extends StatefulWidget {
  const NutritionHomeScreen({Key? key}) : super(key: key);

  @override
  State<NutritionHomeScreen> createState() => _NutritionHomeScreenState();
}

class _NutritionHomeScreenState extends State<NutritionHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
        elevation: 0,
        title: Text(
          'Gestão de Nutrição',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: const [],
      ),
      body: const WeeklyPlanScreen(),
    );
  }
}
