import 'package:flutter/material.dart';
import '../../models/recipe_suggestion.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../l10n/app_localizations.dart';

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
      final l10n = AppLocalizations.of(context);
      if (l10n == null) return const SizedBox.shrink();
      
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
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Text(safeName, 
              style: TextStyle(fontWeight: FontWeight.bold, color: themeColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text("${l10n.food_recipe_origin}: $safeSourceFood"),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: onDelete,
              iconSize: 20,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMacroInfo(caloriesFormatted, safePrepTime),
                    const Divider(height: 24),
                    Text(safeInstructions, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              )
            ],
          ),
        );
      }

      // Modal/Dialog version (non-expansion)
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
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
                        Text("${l10n.food_recipe_origin}: $safeSourceFood", 
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: onDelete,
                    tooltip: l10n.food_delete_confirm_action,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildMacroInfo(caloriesFormatted, safePrepTime),
              const Divider(height: 24),
              if (safeJustification.isNotEmpty) ...[
                Text(l10n.foodJustification, style: TextStyle(color: themeColor, fontWeight: FontWeight.bold)),
                Text(safeJustification, style: const TextStyle(fontStyle: FontStyle.italic)),
                const SizedBox(height: 12),
              ],
              Text("${l10n.foodInstructions ?? 'Instruções'}:", style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(safeInstructions),
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
