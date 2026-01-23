import 'package:flutter/material.dart';

enum PlantRequirementType { sun, water, soil }

class PlantLevelIcon extends StatelessWidget {
  final int level; // 1, 2, 3
  final PlantRequirementType type;
  final double size;

  const PlantLevelIcon({
    super.key,
    required this.level,
    required this.type,
    this.size = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    // Definição de Cores de Domínio
    final Color color = _getColor();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size(size, size),
          painter: _RequirementPainter(
            level: level,
            color: color,
            type: type,
          ),
        ),
      ],
    );
  }

  Color _getColor() {
    switch (type) {
      case PlantRequirementType.sun:
        return Colors.amber;
      case PlantRequirementType.water:
        return Colors.blue; 
      case PlantRequirementType.soil:
        return Colors.brown;
    }
  }
}

class _RequirementPainter extends CustomPainter {
  final int level;
  final Color color;
  final PlantRequirementType type;

  _RequirementPainter({required this.level, required this.color, required this.type});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.8) // Preenchimento sólido quase opaco para visibility
      ..style = PaintingStyle.fill;

    // 1. Desenhar o Contorno (Shape conforme o domínio)
    Path path = Path();
    final rect = Offset.zero & size;

    if (type == PlantRequirementType.sun) {
      path.addOval(rect); // Círculo
    } else if (type == PlantRequirementType.soil) {
      // Quadrado com cantos arredondados leves
      path.addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)));
    } else {
      // Copo (Trapézio simples)
      final width = size.width;
      final height = size.height;
      path.moveTo(width * 0.15, 0);       // Top Left
      path.lineTo(width * 0.85, 0);       // Top Right
      path.lineTo(width * 0.70, height);  // Bottom Right (tapered)
      path.lineTo(width * 0.30, height);  // Bottom Left (tapered)
      path.close();
    }
    canvas.drawPath(path, paint);

    // 2. Desenhar o Preenchimento (Níveis)
    if (level >= 1) {
      // User requested: Level 1 = 1/4 fill (25%), Level 2 = 1/2 fill (50%), Level 3 = Full fill (100%)
      double fillRatio = 0.25; 
      if (level == 2) fillRatio = 0.5;
      if (level >= 3) fillRatio = 1.0;
      
      if (fillRatio > 0) {
        double fillHeight = size.height * fillRatio;
        canvas.save();
        canvas.clipPath(path);
        canvas.drawRect(
          Rect.fromLTWH(0, size.height - fillHeight, size.width, fillHeight),
          fillPaint
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RequirementPainter oldDelegate) {
     return oldDelegate.level != level || oldDelegate.color != color;
  }
}
