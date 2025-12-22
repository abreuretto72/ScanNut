import 'package:flutter/material.dart';
import 'app_pdf_icon.dart';

class PdfActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String tooltip;

  const PdfActionButton({
    Key? key,
    required this.onPressed,
    this.tooltip = 'Gerar PDF',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: const AppPdfIcon(),
    );
  }
}

