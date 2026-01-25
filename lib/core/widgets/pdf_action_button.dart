import 'package:flutter/material.dart';
import 'app_pdf_icon.dart';

class PdfActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String tooltip;
  final Color? color;

  const PdfActionButton({
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
        child: AppPdfIcon(color: color ?? Colors.white, size: 24),
      ),
    );
  }
}
