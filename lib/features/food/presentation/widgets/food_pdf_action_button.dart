import 'package:flutter/material.dart';

class FoodPdfActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String tooltip;
  final Color? color;

  const FoodPdfActionButton({
    super.key,
    required this.onPressed,
    this.tooltip = 'Gerar PDF',
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.picture_as_pdf_rounded,
          color: color ?? Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
