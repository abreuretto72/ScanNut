import 'package:flutter/material.dart';
import '../../models/food_recipe_suggestion.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../features/food/l10n/app_localizations.dart';

class FoodRecipeCard extends StatelessWidget {
  final RecipeSuggestion recipe;
  final String originFoodName;
  final Color themeColor;
  final VoidCallback onDelete;
  final bool isExpansionTile;

  const FoodRecipeCard({
    super.key,
    required this.recipe,
    required this.originFoodName,
    required this.themeColor,
    required this.onDelete,
    this.isExpansionTile = true,
  });

  @override
  Widget build(BuildContext context) {
    try {
      final foodL10n = FoodLocalizations.of(context);
      if (foodL10n == null) return const SizedBox.shrink();
      
      // 🛡️ DATA DEFENSE
      final safeName = recipe.name ?? 'Sem Nome';
      final safeInstructions = recipe.instructions ?? '';
      final safePrepTime = recipe.prepTime ?? '15 min';
      final safeSourceFood = (recipe.sourceFood?.isNotEmpty ?? false) ? recipe.sourceFood : originFoodName;
      final safeJustification = recipe.justification ?? '';
      
      // Formatting calories with the unicode plus-minus symbol
      String caloriesFormatted = recipe.calories ?? '350';
      if (!caloriesFormatted.contains('\u00B1')) {
        caloriesFormatted = '\u00B1 $caloriesFormatted';
      }
      if (!caloriesFormatted.toLowerCase().contains('kcal')) {
        caloriesFormatted = '$caloriesFormatted kcal';
      }

      if (isExpansionTile) {
        return Card(
          color: const Color(0xFF1E1E1E),
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: ExpansionTile(
            title: Text(safeName, 
              style: TextStyle(fontWeight: FontWeight.bold, color: themeColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(foodL10n.foodOrigin(safeSourceFood), style: const TextStyle(color: Colors.white70)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: onDelete,
              iconSize: 20,
            ),
            iconColor: Colors.white70,
            collapsedIconColor: Colors.white54,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMacroInfo(caloriesFormatted, safePrepTime),
                    Divider(height: 24, color: Colors.white.withValues(alpha: 0.1)),
                    Text(safeInstructions, style: const TextStyle(fontSize: 12, color: Colors.white)),
                  ],
                ),
              )
            ],
          ),
        );
      }

      // Modal/Dialog version (non-expansion)
      return Card(
        color: const Color(0xFF1E1E1E), // Dark
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(safeName, 
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: themeColor),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(foodL10n.foodOrigin(safeSourceFood), 
                          style: const TextStyle(fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: onDelete,
                    tooltip: foodL10n.food_delete_confirm_action,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildMacroInfo(caloriesFormatted, safePrepTime),
              Divider(height: 24, color: Colors.white.withValues(alpha: 0.1)),
              if (safeJustification.isNotEmpty) ...[
                Text(foodL10n.foodJustificationLabel, style: TextStyle(color: themeColor, fontWeight: FontWeight.bold)),
                Text(safeJustification, style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.white70)),
                const SizedBox(height: 12),
              ],
              Text("${foodL10n.foodInstructionsLabel ?? 'Instruções'}:", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              Text(safeInstructions, style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ [FoodRecipeCard] Render Error: $e');
      return const SizedBox.shrink();
    }
  }

  Widget _buildMacroInfo(String calories, String prepTime) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(prepTime, style: const TextStyle(color: Colors.grey)),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_fire_department, size: 16, color: themeColor),
            const SizedBox(width: 4),
            Text(calories, style: TextStyle(color: themeColor, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
