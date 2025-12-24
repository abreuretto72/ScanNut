import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import '../../data/models/weekly_plan.dart';

/// Painel de diagnóstico do Hive (apenas DEBUG)
class HiveDebugPanel extends StatelessWidget {
  const HiveDebugPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.red.shade900,
        title: Text(
          '🔍 Hive Debug Panel',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('📦 BOXES ABERTOS', _getOpenBoxes()),
            const SizedBox(height: 24),
            _buildSection('🔑 WEEKLY PLANS BOX', _getWeeklyPlansInfo()),
            const SizedBox(height: 24),
            _buildSection('📅 SEMANA ATUAL', _getCurrentWeekInfo()),
            const SizedBox(height: 24),
            _buildSection('💾 DADOS SALVOS', _getSavedData()),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.red.shade300,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  List<Widget> _getOpenBoxes() {
    final boxes = Hive.box.keys.toList();
    return [
      _buildInfoRow('Total de boxes abertos', '${boxes.length}'),
      const Divider(color: Colors.white24),
      ...boxes.map((name) {
        final box = Hive.box(name);
        return _buildInfoRow(
          name.toString(),
          'Aberto: ${box.isOpen}, Keys: ${box.length}',
        );
      }).toList(),
    ];
  }

  List<Widget> _getWeeklyPlansInfo() {
    try {
      final box = Hive.box<WeeklyPlan>('nutrition_weekly_plans');
      final keys = box.keys.toList();
      
      return [
        _buildInfoRow('Nome do box', 'nutrition_weekly_plans'),
        _buildInfoRow('Box aberto?', box.isOpen ? '✅ SIM' : '❌ NÃO'),
        _buildInfoRow('Total de keys', '${keys.length}'),
        const Divider(color: Colors.white24),
        Text(
          'Keys no box:',
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 8),
        if (keys.isEmpty)
          Text(
            '(vazio)',
            style: GoogleFonts.poppins(color: Colors.orange, fontSize: 12),
          )
        else
          ...keys.map((key) => Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Text(
              '• $key',
              style: GoogleFonts.poppins(color: Colors.green, fontSize: 12),
            ),
          )).toList(),
      ];
    } catch (e) {
      return [
        _buildInfoRow('ERRO', e.toString(), isError: true),
      ];
    }
  }

  List<Widget> _getCurrentWeekInfo() {
    final now = DateTime.now();
    final monday = _getMonday(now);
    final key = _getWeekKey(monday);
    
    try {
      final box = Hive.box<WeeklyPlan>('nutrition_weekly_plans');
      final hasKey = box.containsKey(key);
      final plan = box.get(key);
      
      return [
        _buildInfoRow('Data atual', now.toString().split('.')[0]),
        _buildInfoRow('Segunda-feira', monday.toString().split(' ')[0]),
        _buildInfoRow('Key esperada', key),
        const Divider(color: Colors.white24),
        _buildInfoRow('Box contém key?', hasKey ? '✅ SIM' : '❌ NÃO'),
        _buildInfoRow('get(key) retorna', plan != null ? '✅ WeeklyPlan' : '❌ NULL'),
        if (plan != null) ...[
          const Divider(color: Colors.white24),
          _buildInfoRow('Dias no plano', '${plan.days.length}'),
          _buildInfoRow(
            'Total de refeições',
            '${plan.days.fold(0, (sum, day) => sum + day.meals.length)}',
          ),
          _buildInfoRow('Criado em', plan.criadoEm.toString().split('.')[0]),
          _buildInfoRow('Atualizado em', plan.atualizadoEm.toString().split('.')[0]),
        ],
      ];
    } catch (e) {
      return [
        _buildInfoRow('ERRO', e.toString(), isError: true),
      ];
    }
  }

  List<Widget> _getSavedData() {
    try {
      final box = Hive.box<WeeklyPlan>('nutrition_weekly_plans');
      final allPlans = box.values.toList();
      
      if (allPlans.isEmpty) {
        return [
          Text(
            'Nenhum cardápio salvo',
            style: GoogleFonts.poppins(color: Colors.orange, fontSize: 14),
          ),
        ];
      }
      
      return allPlans.map((plan) {
        final totalMeals = plan.days.fold(0, (sum, day) => sum + day.meals.length);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade700),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Semana: ${plan.weekStartDate.toString().split(' ')[0]}',
                style: GoogleFonts.poppins(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Dias: ${plan.days.length} | Refeições: $totalMeals',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        );
      }).toList();
    } catch (e) {
      return [
        _buildInfoRow('ERRO', e.toString(), isError: true),
      ];
    }
  }

  Widget _buildInfoRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: isError ? Colors.red : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  DateTime _getMonday(DateTime date) {
    final weekday = date.weekday;
    final monday = date.subtract(Duration(days: weekday - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }

  String _getWeekKey(DateTime monday) {
    return '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
  }
}
