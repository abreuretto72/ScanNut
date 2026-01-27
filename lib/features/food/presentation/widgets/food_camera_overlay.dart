
import 'package:flutter/material.dart';
import '../../../../core/theme/app_design.dart';

class FoodCameraOverlay extends StatelessWidget {
  const FoodCameraOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;
        final double squareSize = width * 0.75; // 75% da largura

        return CustomPaint(
          size: Size(width, height),
          painter: FoodCameraOverlayPainter(
            squareSize: squareSize,
            color: AppDesign.foodOrange.withValues(alpha: 0.8),
          ),
        );
      },
    );
  }
}

class FoodCameraOverlayPainter extends CustomPainter {
  final double squareSize;
  final Color color;

  FoodCameraOverlayPainter({
    required this.squareSize,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double left = (size.width - squareSize) / 2;
    final double top = (size.height - squareSize) / 2.2; // Levemente elevado para deixar espaço pros botões
    final Rect squareRect = Rect.fromLTWH(left, top, squareSize, squareSize);

    // 1. Fundo escurecido com furo (Hole)
    final Paint backgroundPaint = Paint()..color = Colors.black.withValues(alpha: 0.4);
    
    final Path backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final Path holePath = Path()..addRRect(RRect.fromRectAndRadius(squareRect, const Radius.circular(20)));
    
    final Path combinedPath = Path.combine(PathOperation.difference, backgroundPath, holePath);
    canvas.drawPath(combinedPath, backgroundPaint);

    // 2. Moldura Laranja (Lei de Ferro)
    final Paint borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawRRect(RRect.fromRectAndRadius(squareRect, const Radius.circular(20)), borderPaint);

    // 3. Cantoneiras de Foco (Opcional, mas premium)
    final double cornerSize = 25.0;
    final Paint cornerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;

    // Top Left
    canvas.drawPath(
      Path()
        ..moveTo(left, top + cornerSize)
        ..lineTo(left, top)
        ..lineTo(left + cornerSize, top),
      cornerPaint,
    );

    // Top Right
    canvas.drawPath(
      Path()
        ..moveTo(left + squareSize - cornerSize, top)
        ..lineTo(left + squareSize, top)
        ..lineTo(left + squareSize, top + cornerSize),
      cornerPaint,
    );

    // Bottom Left
    canvas.drawPath(
      Path()
        ..moveTo(left, top + squareSize - cornerSize)
        ..lineTo(left, top + squareSize)
        ..lineTo(left + cornerSize, top + squareSize),
      cornerPaint,
    );

    // Bottom Right
    canvas.drawPath(
      Path()
        ..moveTo(left + squareSize - cornerSize, top + squareSize)
        ..lineTo(left + squareSize, top + squareSize)
        ..lineTo(left + squareSize, top + squareSize - cornerSize),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
