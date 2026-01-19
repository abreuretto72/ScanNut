import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_design.dart';

class ChipsInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final List<String> chips;
  final Function(String) onAdd;
  final Function(int) onDelete;
  final Color? chipColor;

  const ChipsInputField({
    Key? key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.chips,
    required this.onAdd,
    required this.onDelete,
    this.chipColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.white60),
            prefixIcon: Icon(icon, color: Colors.white30, size: 18),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_circle, color: AppDesign.petPink),
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) onAdd(text);
              },
            ),
            filled: true,
            fillColor: AppDesign.backgroundDark,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          onSubmitted: (text) {
             final t = text.trim();
             if (t.isNotEmpty) onAdd(t);
          },
        ),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(chips.length, (index) {
              return Chip(
                label: Text(chips[index], style: const TextStyle(color: Colors.white, fontSize: 11)),
                backgroundColor: chipColor ?? AppDesign.petPink.withOpacity(0.1),
                deleteIcon: const Icon(Icons.close, size: 14, color: Colors.white70),
                onDeleted: () => onDelete(index),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              );
            }),
          ),
        ],
      ],
    );
  }
}
