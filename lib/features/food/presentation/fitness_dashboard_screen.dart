import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../services/nutrition_service.dart';
import '../services/workout_service.dart';
import '../models/workout_item.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class FitnessDashboardScreen extends StatefulWidget {
  const FitnessDashboardScreen({Key? key}) : super(key: key);

  @override
  State<FitnessDashboardScreen> createState() => _FitnessDashboardScreenState();
}

class _FitnessDashboardScreenState extends State<FitnessDashboardScreen> {
  double _consumed = 0;
  int _burned = 0;
  double _goal = 2000;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDailyData();
  }

  Future<void> _loadDailyData() async {
    final now = DateTime.now();
    final nutritionSummary = await NutritionService().getDailySummary(now);
    final burned = await WorkoutService().getDailyCaloriesBurned(now);

    setState(() {
      _consumed = nutritionSummary['calories'] ?? 0;
      _burned = burned;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    double balance = _consumed - _burned;
    double percent = _consumed / _goal;
    if (percent > 1.0) percent = 1.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Dashboard Fitness', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)))
          : RefreshIndicator(
              onRefresh: _loadDailyData,
              color: const Color(0xFF00E676),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildCalorieCard(balance, percent),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: _buildInfoCard('Consumido', '${_consumed.toInt()} kcal', Icons.restaurant, Colors.orangeAccent)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildInfoCard('Queimado', '$_burned kcal', Icons.directions_run, Colors.blueAccent)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildPerformanceSection(),
                  const SizedBox(height: 24),
                  _buildQuickActionSection(),
                ],
              ),
            ),
    );
  }

  Future<Map<String, dynamic>> _calculateDailyTotals() async {
    final now = DateTime.now();
    final nutritionSummary = await NutritionService().getDailySummary(now);
    final burned = await WorkoutService().getDailyCaloriesBurned(now);
    return {
      'consumed': nutritionSummary['calories'] ?? 0.0,
      'burned': burned,
    };
  }

  Widget _buildCalorieCard(double balance, double percent) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: const Color(0xFF00E676).withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          CircularPercentIndicator(
            radius: 80.0,
            lineWidth: 12.0,
            percent: percent,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${balance.toInt()}', style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('Saldo kcal', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
              ],
            ),
            circularStrokeCap: CircularStrokeCap.round,
            backgroundColor: Colors.white12,
            progressColor: const Color(0xFF00E676),
            animation: true,
            animationDuration: 1200,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.flag_outlined, color: Colors.grey, size: 16),
              const SizedBox(width: 8),
              Text('Meta diária: ${_goal.toInt()} kcal', style: GoogleFonts.poppins(color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13)),
          Text(value, style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPerformanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Performance Biohacking', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: Colors.blueAccent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Dica do Dia: Treine em jejum hoje para otimizar a queima de gordura de acordo com o seu último consumo de carboidratos.',
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionSection() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            'Add Treino', 
            Icons.add_task, 
            () => _showAddWorkoutDialog(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white10,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _showAddWorkoutDialog() {
    final nameCtrl = TextEditingController();
    final calCtrl = TextEditingController();
    final durCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text('Registrar Treino', style: GoogleFonts.poppins(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogField(nameCtrl, 'Exercício (ex: Corrida)', Icons.directions_run),
            const SizedBox(height: 12),
            _buildDialogField(calCtrl, 'Calorias Queimadas', Icons.local_fire_department, keyboard: TextInputType.number),
            const SizedBox(height: 12),
            _buildDialogField(durCtrl, 'Duração (min)', Icons.timer, keyboard: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty && calCtrl.text.isNotEmpty) {
                final workout = WorkoutItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  timestamp: DateTime.now(),
                  exerciseName: nameCtrl.text,
                  caloriesBurned: int.tryParse(calCtrl.text) ?? 0,
                  durationMinutes: int.tryParse(durCtrl.text) ?? 0,
                );
                await WorkoutService().saveWorkout(workout);
                Navigator.pop(context);
                _loadDailyData();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogField(TextEditingController ctrl, String hint, IconData icon, {TextInputType? keyboard}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey, size: 20),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
