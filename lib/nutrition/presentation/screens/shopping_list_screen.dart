import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/nutrition_providers.dart';
import '../../data/models/shopping_list_item.dart';
import 'package:scannut/l10n/app_localizations.dart';

class ShoppingListScreen extends ConsumerWidget {
  const ShoppingListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(shoppingListProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: items.isEmpty
          ? _buildEmptyState(context, ref)
          : Column(
              children: [
                _buildHeader(context, ref, items.length),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(color: Colors.white12),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _buildItemRow(context, ref, item, index);
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemDialog(context, ref),
        backgroundColor: const Color(0xFFFF6B35),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade900,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppLocalizations.of(context)!.shopItems(count),
            style: GoogleFonts.poppins(color: Colors.white70, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _generateFromPlan(context, ref),
                icon: const Icon(Icons.sync, size: 18, color: Color(0xFF00E676)),
                label: Text(AppLocalizations.of(context)!.shopSyncPlan, style: GoogleFonts.poppins(color: const Color(0xFF00E676))),
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                tooltip: AppLocalizations.of(context)!.shopClearDone,
                onPressed: () => ref.read(shoppingListProvider.notifier).clearCompleted(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.white24),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.shopEmptyTitle,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.shopEmptySubtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.white54),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _generateFromPlan(context, ref),
            icon: const Icon(Icons.restaurant_menu),
            label: Text(AppLocalizations.of(context)!.shopGenerateFromMenu, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(BuildContext context, WidgetRef ref, ShoppingListItem item, int index) {
    return Dismissible(
      key: Key(item.nome + index.toString()),
      background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16), child: const Icon(Icons.delete, color: Colors.white)),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        ref.read(shoppingListProvider.notifier).deleteItem(index);
      },
      child: CheckboxListTile(
        value: item.marcado,
        onChanged: (_) => ref.read(shoppingListProvider.notifier).toggleItem(index),
        activeColor: const Color(0xFFFF6B35),
        checkColor: Colors.white,
        title: Text(
          item.nome,
          style: GoogleFonts.poppins(
            color: item.marcado ? Colors.white38 : Colors.white,
            decoration: item.marcado ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          item.quantidadeTexto,
          style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
        ),
        secondary: const Icon(Icons.shopping_basket, color: Colors.white24),
      ),
    );
  }

  Future<void> _generateFromPlan(BuildContext context, WidgetRef ref) async {
    final currentPlan = ref.read(currentWeekPlanProvider);
    if (currentPlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.shopNoMenuError)));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(AppLocalizations.of(context)!.shopReplaceTitle, style: const TextStyle(color: Colors.white)),
        content: Text(AppLocalizations.of(context)!.shopReplaceContent, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.of(context)!.btnCancel)),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676)), child: Text(AppLocalizations.of(context)!.shopGenerateBtn)),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(shoppingListProvider.notifier).generateFromPlan(currentPlan);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.shopGeneratedSuccess), backgroundColor: Colors.green));
      }
    }
  }

  void _showAddItemDialog(BuildContext context, WidgetRef ref) {
    final nomeController = TextEditingController();
    final qtdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(AppLocalizations.of(context)!.shopAddItemTitle, style: GoogleFonts.poppins(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.shopItemName,
                labelStyle: const TextStyle(color: Colors.white54),
                enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: qtdController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.shopItemQty,
                labelStyle: const TextStyle(color: Colors.white54),
                enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.btnCancel, style: GoogleFonts.poppins(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              if (nomeController.text.isNotEmpty) {
                ref.read(shoppingListProvider.notifier).addItem(
                  nomeController.text,
                  qtdController.text.isEmpty ? AppLocalizations.of(context)!.shopDefaultQty : qtdController.text,
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35)),
            child: Text(AppLocalizations.of(context)!.commonAdd, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
