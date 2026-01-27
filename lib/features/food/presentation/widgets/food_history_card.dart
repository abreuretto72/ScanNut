import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/nutrition_history_item.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/translation_mapper.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../core/services/media_vault_service.dart';

class FoodHistoryCard extends StatelessWidget {
  final NutritionHistoryItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const FoodHistoryCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    try {
      final l10n = AppLocalizations.of(context);
      if (l10n == null) return const SizedBox.shrink();
      
      // 🛡️ DATA DEFENSE: Garantia de que valores nulos do Hive não matem a UI
      final safeFoodName = item.foodName ?? 'Alimento';
      final safeCalories = item.calories ?? 0;
      final safeProteins = item.proteins ?? '0g';
      final safeCarbs = item.carbs ?? '0g';
      final safeFats = item.fats ?? '0g';
      final safeTimestamp = item.timestamp ?? DateTime.now();

      String localeStr;
      try {
        localeStr = Localizations.localeOf(context).toString();
      } catch (e) {
        localeStr = 'pt_BR';
      }

      return GestureDetector(
        onTap: onTap,
        child: Container(
          clipBehavior: Clip.antiAlias, // 🛡️ V135: Proteção contra vazamento de conteúdo
          constraints: const BoxConstraints(
            minHeight: 110.0,
            maxHeight: 145.0, // Regra de Ouro: Dynamic Content, Guarded Container
          ),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade900.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (item.isUltraprocessed ?? false)
                  ? Colors.redAccent.withValues(alpha: 0.4)
                  : AppDesign.foodOrange.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Thumbnail - Otimizado para ocupar todo o lado esquerdo (Flush Look)
              Container(
                width: 100,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(19)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(19)),
                  child: Hero(
                    tag: 'img_${item.id}',
                    child: item.imagePath != null
                        ? FutureBuilder<String>(
                            future: MediaVaultService().attemptRecovery(
                                item.imagePath ?? '',
                                category: MediaVaultService.FOOD_DIR),
                            builder: (context, snapshot) {
                              // 🛡️ Safe recovery path
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const SizedBox(width: 100, height: 120);
                              }
                              
                              final displayPath = snapshot.data ?? item.imagePath ?? '';
                              if (displayPath.isEmpty) return _buildPlaceholder(Icons.fastfood);
                              
                              return Image.file(
                                File(displayPath),
                                width: 100,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildPlaceholder(Icons.broken_image),
                              );
                            },
                          )
                        : _buildPlaceholder(Icons.fastfood),
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
                    mainAxisSize: MainAxisSize.min, // Garantir que não tente expandir infinitamente
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              safeFoodName.toLowerCase().contains('inventário')
                                  ? l10n.chefVisionTitle
                                  : TranslationMapper.localizeFoodName(safeFoodName, l10n),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 13, // Reduzido para evitar overlap em telas pequenas
                                color: Colors.white,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                DateFormat('dd/MM', localeStr).format(safeTimestamp),
                                style: GoogleFonts.poppins(
                                    color: Colors.white60, fontSize: 10),
                              ),
                              GestureDetector(
                                onTap: onDelete,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  child: const Icon(Icons.delete_forever,
                                      color: Colors.redAccent, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      
                      // ⚖️ CALORIE LINE: FittedBox sem Flexible para evitar "hasSize: false"
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '\u00B1 $safeCalories ${l10n.foodKcalPer100g}',
                          style: GoogleFonts.poppins(
                              color: AppDesign.foodOrange, // Sincronia com domínio
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      const Divider(height: 1, color: Colors.white10),
                      const SizedBox(height: 8),
                      
                      // 🛡️ MACRO ROW: FittedBox de proteção final contra overflow lateral/vertical
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          children: [
                            SizedBox(
                                width: 70,
                                child: _buildMacroMini(l10n.foodProt, safeProteins,
                                    const Color(0xFF6F8CFF))),
                            SizedBox(
                                width: 70,
                                child: _buildMacroMini(l10n.foodCarb, safeCarbs,
                                    const Color(0xFFFFC24B))),
                            SizedBox(
                                width: 70,
                                child: _buildMacroMini(l10n.foodFat, safeFats,
                                    const Color(0xFFFF6FAE))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ [FoodHistoryCard] Fatal Render Error: $e');
      return Container(
        height: 120,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: const Center(child: Text('Erro no Card', style: TextStyle(color: Colors.red))),
      );
    }
  }

  Widget _buildPlaceholder(IconData icon) {
    return Container(
      width: 100,
      color: Colors.grey.shade800,
      child: Icon(icon, color: Colors.white24),
    );
  }

  Widget _buildMacroMini(String label, String? value, Color color) {
    // 🛡️ Fallback para valor nulo
    final rawValue = value ?? '0g';
    
    final sanitized = rawValue
        .replaceAll('aproximadamente', '±')
        .replaceAll('Aproximadamente', '±');

    final match = RegExp(r'(±?\s*\d+[.,]?\d*\s*g)', caseSensitive: false)
        .firstMatch(sanitized);

    String shortValue;
    if (match != null) {
      final captured = match.group(1);
      shortValue = (captured ?? sanitized).trim();
    } else {
      shortValue = sanitized
          .replaceAll(RegExp(r'\bpor\b', caseSensitive: false), '')
          .split('(')[0]
          .split('/')[0]
          .split(',')[0]
          .trim();
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: color.withValues(alpha: 0.85),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          '\u00B1 $shortValue',
          style: GoogleFonts.poppins(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
