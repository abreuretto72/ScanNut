import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/nutrition_history_item.dart';
import '../services/nutrition_service.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class NutritionHistoryScreen extends StatefulWidget {
  const NutritionHistoryScreen({Key? key}) : super(key: key);

  @override
  State<NutritionHistoryScreen> createState() => _NutritionHistoryScreenState();
}

class _NutritionHistoryScreenState extends State<NutritionHistoryScreen> {
  List<NutritionHistoryItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final items = await NutritionService().getHistory();
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
        title: Text('Histórico Fitness',
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
                            child: _buildFoodCard(item),
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
          Icon(Icons.restaurant_menu, size: 80, color: Colors.grey.shade800),
          const SizedBox(height: 16),
          Text(
            'Nenhuma análise salva ainda.',
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodCard(NutritionHistoryItem item) {
    return GestureDetector(
      onTap: () => _showDetailModal(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade900.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: item.isUltraprocessed ? Colors.redAccent.withValues(alpha: 0.3) : Colors.greenAccent.withValues(alpha: 0.2),
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Image Thumbnail
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                child: Hero(
                  tag: 'img_${item.id}',
                  child: item.imagePath != null
                      ? Image.file(
                          File(item.imagePath!),
                          width: 100,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 100,
                          color: Colors.grey.shade800,
                          child: const Icon(Icons.fastfood, color: Colors.white24),
                        ),
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.foodName,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            DateFormat('dd/MM').format(item.timestamp),
                            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.calories} kcal / 100g',
                        style: GoogleFonts.poppins(color: const Color(0xFF00E676), fontWeight: FontWeight.w600),
                      ),
                      const Divider(color: Colors.white10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMacroMini('P', item.proteins, Colors.blueAccent),
                          _buildMacroMini('C', item.carbs, Colors.orangeAccent),
                          _buildMacroMini('G', item.fats, Colors.greenAccent),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroMini(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 10)),
        Text(
          value.split(' ')[0], // Get just the number part
          style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ],
    );
  }

  void _showDetailModal(NutritionHistoryItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 24),
              Text(item.foodName, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // Biohacking Tips
              _buildSectionTitle('Performance & Biohacking', Icons.bolt),
              const SizedBox(height: 8),
              ...item.biohackingTips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline, color: Color(0xFF00E676), size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(tip, style: GoogleFonts.poppins(color: Colors.white70))),
                  ],
                ),
              )).toList(),

              const SizedBox(height: 24),
              
              // Recipes
              _buildSectionTitle('Receitas Inteligentes (15 min)', Icons.timer),
              const SizedBox(height: 12),
              ...item.recipesList.map((recipe) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(recipe['nome'] ?? '', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
                    const SizedBox(height: 4),
                    Text(recipe['instrucoes'] ?? '', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(recipe['tempo'] ?? '15 min', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              )).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.orangeAccent, size: 20),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
      ],
    );
  }
}
