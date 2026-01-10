import 'package:flutter/material.dart';

class AppPdfIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const AppPdfIcon({
    Key? key,
    this.size = 22,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.picture_as_pdf_rounded,
      color: color ?? Colors.white,
      size: size,
    );
  }
}
