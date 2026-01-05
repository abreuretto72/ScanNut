import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/nutrition_history_item.dart';
import '../services/nutrition_service.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/food_analysis_model.dart';
import 'food_result_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/utils/translation_mapper.dart';

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
    debugPrint('🖥️ [HistoryScreen] Building...');
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(l10n.foodHistoryTitle,
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder(
        future: NutritionService().init(), // Ensure init
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
             return const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)));
          }
          
          final listenable = NutritionService().listenable as ValueListenable<Box<NutritionHistoryItem>>?;
          if (listenable == null) {
             debugPrint('⚠️ [HistoryScreen] Listenable is null');
             return _buildEmptyState();
          }

          return ValueListenableBuilder<Box<NutritionHistoryItem>>(
            valueListenable: listenable,
            builder: (context, box, _) {
              final items = box.values.whereType<NutritionHistoryItem>().toList().reversed.toList();
              debugPrint('🔄 [HistoryScreen] Rebuilding List. Count: ${items.length}');
              
               if (items.isEmpty) {
                return _buildEmptyState();
              }

              return AnimationLimiter(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
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
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, size: 80, color: Colors.grey.shade800),
          const SizedBox(height: 16),
          Text(
            l10n.foodHistoryEmpty,
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
                setState(() { _isLoading = true; });
                _loadHistory();
            },
            icon: const Icon(Icons.refresh, color: Colors.black),
            label: Text(l10n.foodReload),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodCard(NutritionHistoryItem item) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => _showDetailModal(item),

      child: Container(
        // height: 140, // Removed fixed height to prevent overflow
        constraints: const BoxConstraints(minHeight: 120),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade900.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: item.isUltraprocessed ? Colors.redAccent.withOpacity(0.3) : Colors.greenAccent.withOpacity(0.2),
          ),
        ),
        // Removed IntrinsicHeight to fix layout error
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start, // Align to top since heights differ
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
                          height: 120, // Fixed height for image
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 100,
                            height: 120,
                            color: Colors.grey.shade800,
                            child: const Icon(Icons.broken_image, color: Colors.white24),
                          ),
                        )
                      : Container(
                          width: 100,
                          height: 120,
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                                TranslationMapper.localizeFoodName(item.foodName, l10n),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                               Text(
                                DateFormat('dd/MM', Localizations.localeOf(context).toString()).format(item.timestamp),
                                style: GoogleFonts.poppins(color: Colors.grey, fontSize: 10),
                              ),
                              GestureDetector(
                                onTap: () => _confirmDelete(item),
                                child: const Padding(
                                  padding: EdgeInsets.all(4.0),
                                  child: Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${item.calories} ${l10n.foodKcalPer100g}',
                          style: GoogleFonts.poppins(color: const Color(0xFF00E676), fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Divider(color: Colors.white10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _buildMacroMini(l10n.foodProt, item.proteins, Colors.blueAccent),
                          _buildMacroMini(l10n.foodCarb, item.carbs, Colors.orangeAccent),
                          _buildMacroMini(l10n.foodFat, item.fats, Colors.greenAccent),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ),
    );
  }

  Widget _buildMacroMini(String label, String value, Color color) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 70), // Limit width to prevent overflow
      child: Column(
      children: [
        Text(label, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 10), overflow: TextOverflow.ellipsis),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value.split(' ')[0], // Get just the number part
            style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ],
      ),
    );
  }

  Future<void> _confirmDelete(NutritionHistoryItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(l10n.foodDeleteConfirmTitle, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(l10n.foodDeleteConfirmContent, style: GoogleFonts.poppins(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel, style: GoogleFonts.poppins(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonDelete, style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await NutritionService().deleteHistoryItem(item);
      _loadHistory(); // Refresh list
    }
  }

  void _showDetailModal(NutritionHistoryItem item) {
    debugPrint('🔍 [History] Opening details for: ${item.foodName}');
    
    if (item.rawMetadata != null) {
       debugPrint('📄 [History] keys: ${item.rawMetadata!.keys.toList()}');
       // debugPrint('📄Raw: ${item.rawMetadata}'); // Uncomment if needed, can be huge
    } else {
       debugPrint('⚠️ [History] rawMetadata is NULL');
    }

    if (item.rawMetadata == null || item.rawMetadata!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Detalhes antigos não suportados na visualização completa.')));
        return;
    }

    try {
      // Robust conversion from dynamic Hive maps to Map<String, dynamic>
      final jsonMap = _convertToMapStringDynamic(item.rawMetadata);
      final analysis = FoodAnalysisModel.fromJson(jsonMap);
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FoodResultScreen(
            analysis: analysis,
            imageFile: item.imagePath != null ? File(item.imagePath!) : null,
            onSave: () {}, 
            isReadOnly: true,
          ),
        ),
      );
    } catch (e, stack) {
       debugPrint('❌ [History] Error parsing history item: $e');
       debugPrint(stack.toString());
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao processar dados salvos.')));
    }
  }

  // Helper to deep convert to Map<String, dynamic>
  Map<String, dynamic> _convertToMapStringDynamic(dynamic input) {
     final fixed = _deepFixMaps(input);
     if (fixed is Map) {
        return Map<String, dynamic>.from(fixed);
     }
     return {};
  }
  
  // Better implementation of the helper inside the class
  dynamic _deepFixMaps(dynamic value) {
    if (value is Map) {
      return value.map<String, dynamic>((k, v) => MapEntry(k.toString(), _deepFixMaps(v)));
    }
    if (value is List) {
      return value.map((e) => _deepFixMaps(e)).toList();
    }
    return value;
  }
}
