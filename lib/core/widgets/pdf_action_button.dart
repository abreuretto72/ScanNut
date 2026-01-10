import 'package:flutter/material.dart';
import 'app_pdf_icon.dart';

class PdfActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String tooltip;
  final Color? color;

  const PdfActionButton({
    Key? key,
    required this.onPressed,
    this.tooltip = 'Gerar PDF',
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color ?? Colors.transparent, // Default to transparent as requested
          shape: BoxShape.circle,
        ),
        child: const AppPdfIcon(color: Colors.white, size: 20),
      ),
    );
  }
}

