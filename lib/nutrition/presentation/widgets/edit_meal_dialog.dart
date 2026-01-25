import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scannut/core/theme/app_design.dart';
import 'package:scannut/l10n/app_localizations.dart';
import 'package:scannut/nutrition/data/models/meal.dart';
// MealItem is defined in meal.dart

class EditMealDialog extends StatefulWidget {
  final Meal meal;
  final Function(Meal) onSave;

  const EditMealDialog({super.key, required this.meal, required this.onSave});

  @override
  State<EditMealDialog> createState() => _EditMealDialogState();
}

class _EditMealDialogState extends State<EditMealDialog> {
  late TextEditingController _nameController;
  late TextEditingController _obsController;
  late List<MealItem> _items;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.meal.nomePrato);
    _obsController = TextEditingController(text: widget.meal.observacoes);
    // Create a mutable copy of items
    _items = widget.meal.itens
        .map((i) => MealItem(nome: i.nome, quantidadeTexto: i.quantidadeTexto))
        .toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add(MealItem(nome: '', quantidadeTexto: ''));
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _save() {
    // Filter out empty items
    final validItems = _items.where((i) => i.nome.trim().isNotEmpty).toList();

    final updatedMeal = Meal(
      tipo: widget.meal.tipo,
      recipeId: widget.meal.recipeId,
      nomePrato: _nameController.text,
      itens: validItems,
      observacoes: _obsController.text,
      criadoEm: widget.meal.criadoEm,
    );
    widget.onSave(updatedMeal);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: AppDesign.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              l10n.editMeal,
              style: GoogleFonts.poppins(
                color: AppDesign.textPrimaryDark,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome do Prato
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: l10n.mealDefault,
                      labelStyle: const TextStyle(color: Colors.white54),
                      enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: AppDesign.accent)),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),

                  // Observações
                  TextField(
                    controller: _obsController,
                    decoration: const InputDecoration(
                      labelText: 'Kcal / Info',
                      labelStyle: TextStyle(color: Colors.white54),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppDesign.accent)),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),

                  const SizedBox(height: 24),

                  // Ingredientes Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.ingredientsTitle,
                        style: GoogleFonts.poppins(
                          color: AppDesign.accent,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add,
                            size: 16, color: AppDesign.accent),
                        label: Text('Adicionar',
                            style: GoogleFonts.poppins(
                                color: AppDesign.accent, fontSize: 12)),
                        style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Ingredientes List
                  if (_items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('Nenhum ingrediente',
                          style: GoogleFonts.poppins(
                              color: Colors.white30,
                              fontStyle: FontStyle.italic)),
                    )
                  else
                    ..._items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                initialValue: item.nome,
                                onChanged: (val) => item.nome = val,
                                decoration: const InputDecoration(
                                  hintText: 'Ingrediente',
                                  hintStyle: TextStyle(
                                      color: Colors.white30, fontSize: 12),
                                  isDense: true,
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 8),
                                  enabledBorder: UnderlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.white12)),
                                ),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                initialValue: item.quantidadeTexto,
                                onChanged: (val) => item.quantidadeTexto = val,
                                decoration: const InputDecoration(
                                  hintText: 'Qtd.',
                                  hintStyle: TextStyle(
                                      color: Colors.white30, fontSize: 12),
                                  isDense: true,
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 8),
                                  enabledBorder: UnderlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.white12)),
                                ),
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 13),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close,
                                  color: AppDesign.error, size: 16),
                              onPressed: () => _removeItem(index),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.commonCancel,
                      style: const TextStyle(color: Colors.white54)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppDesign.accent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(l10n.saveChanges,
                      style: const TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
