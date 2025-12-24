import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/botany_history_item.dart';
import '../services/botany_service.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class BotanyHistoryScreen extends StatefulWidget {
  const BotanyHistoryScreen({Key? key}) : super(key: key);

  @override
  State<BotanyHistoryScreen> createState() => _BotanyHistoryScreenState();
}

class _BotanyHistoryScreenState extends State<BotanyHistoryScreen> {
  List<BotanyHistoryItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final items = await BotanyService().getHistory();
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Inteligência Botânica',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)))
          : _items.isEmpty
              ? _buildEmptyState()
              : AnimationLimiter(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildPlantCard(item),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_florist, size: 80, color: Colors.grey.shade800),
          const SizedBox(height: 16),
          Text(
            'Nenhuma planta analisada ainda.',
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantCard(BotanyHistoryItem item) {
    Color semaphoreColor;
    switch (item.survivalSemaphore.toLowerCase()) {
      case 'verde': semaphoreColor = Colors.greenAccent; break;
      case 'amarelo': semaphoreColor = Colors.yellowAccent; break;
      case 'vermelho': semaphoreColor = Colors.redAccent; break;
      default: semaphoreColor = Colors.greenAccent;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: semaphoreColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Image and Semaphore
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: item.imagePath != null
                    ? Image.file(
                        File(item.imagePath!),
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        height: 160,
                        width: double.infinity,
                        color: Colors.grey.shade800,
                        child: const Icon(Icons.park, color: Colors.white10, size: 50),
                      ),
              ),
              // Semaphore Indicator
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: semaphoreColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: semaphoreColor,
                          boxShadow: [BoxShadow(color: semaphoreColor, blurRadius: 4)],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'STATUS: ${item.survivalSemaphore.toUpperCase()}',
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              // Date
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    DateFormat('dd MMM yyyy').format(item.timestamp),
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.plantName,
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  item.healthStatus,
                  style: GoogleFonts.poppins(color: semaphoreColor, fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                
                // Needs Icons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNeedIcon(Icons.light_mode, item.lightWaterSoilNeeds['luz'] ?? 'N/A', Colors.yellow.shade700),
                    _buildNeedIcon(Icons.water_drop, item.lightWaterSoilNeeds['agua'] ?? 'N/A', Colors.blueAccent),
                    _buildNeedIcon(Icons.grass, item.lightWaterSoilNeeds['solo'] ?? 'N/A', Colors.brown.shade300),
                  ],
                ),

                const SizedBox(height: 16),
                // toxicity warning if any
                if (item.toxicityStatus != 'safe')
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.toxicityStatus == 'toxic' ? 'TÓXICA para humanos' : 'PERIGOSA para pets',
                            style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),
                _buildActionButtons(item),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeedIcon(IconData icon, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        SizedBox(
          width: 80,
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BotanyHistoryItem item) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _showRecoveryPlan(item),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Plano de Recuperação', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: () => _showFengShui(item),
          icon: const Icon(Icons.wb_sunny_outlined, color: Colors.orangeAccent),
          tooltip: 'Feng Shui Tips',
        ),
      ],
    );
  }

  void _showRecoveryPlan(BotanyHistoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text('Plano de Recuperação', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(item.recoveryPlan, style: GoogleFonts.poppins(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido')),
        ],
      ),
    );
  }

  void _showFengShui(BotanyHistoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text('Feng Shui & Simbolismo', style: GoogleFonts.poppins(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
        content: Text(item.fengShuiTips, style: GoogleFonts.poppins(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
        ],
      ),
    );
  }
}
