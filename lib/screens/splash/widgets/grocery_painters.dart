import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Custom painter for a stylized 2D Tomato
class TomatoPainter extends CustomPainter {
  final Color baseColor;
  final Color shadowColor;
  final Color stemColor;

  const TomatoPainter({
    this.baseColor = const Color(0xFFEF5350),
    this.shadowColor = const Color(0xFFC62828),
    this.stemColor = const Color(0xFF388E3C),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 2);
    final radius = math.min(size.width, size.height) * 0.42;

    // Body shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center + const Offset(0, 3), radius, shadowPaint);

    // Body gradient fill
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        radius: 0.85,
        colors: [
          baseColor,
          shadowColor,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, bodyPaint);

    // Glossy Highlight
    final highlightPath = Path()
      ..addOval(
        Rect.fromLTWH(
          center.dx - radius * 0.55,
          center.dy - radius * 0.6,
          radius * 0.65,
          radius * 0.38,
        ),
      );
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    
    canvas.save();
    canvas.rotate(-0.35);
    canvas.drawPath(highlightPath, highlightPaint);
    canvas.restore();

    // Leaf / Sepals (5-star calyx at top)
    final leafPaint = Paint()
      ..color = stemColor
      ..style = PaintingStyle.fill;

    final leafCenter = Offset(center.dx, center.dy - radius * 0.85);
    final leafPath = Path();
    const numPoints = 5;
    for (int i = 0; i < numPoints; i++) {
      final angle = (i * 2 * math.pi / numPoints) - math.pi / 2;
      final outerX = leafCenter.dx + math.cos(angle) * (radius * 0.45);
      final outerY = leafCenter.dy + math.sin(angle) * (radius * 0.45);
      
      final innerAngle = angle + math.pi / numPoints;
      final innerX = leafCenter.dx + math.cos(innerAngle) * (radius * 0.15);
      final innerY = leafCenter.dy + math.sin(innerAngle) * (radius * 0.15);

      if (i == 0) {
        leafPath.moveTo(outerX, outerY);
      } else {
        leafPath.lineTo(outerX, outerY);
      }
      leafPath.lineTo(innerX, innerY);
    }
    leafPath.close();
    canvas.drawPath(leafPath, leafPaint);

    // Small curved stem
    final stemPaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final stemPath = Path()
      ..moveTo(leafCenter.dx, leafCenter.dy)
      ..cubicTo(
        leafCenter.dx - 2,
        leafCenter.dy - 6,
        leafCenter.dx + 4,
        leafCenter.dy - 10,
        leafCenter.dx + 2,
        leafCenter.dy - 12,
      );
    canvas.drawPath(stemPath, stemPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for a stylized 2D Carrot
class CarrotPainter extends CustomPainter {
  const CarrotPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Stem/Leaf top at (width * 0.5, height * 0.25)
    final leafPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.fill;

    // 3 leafy fronds
    final leaf1 = Path()
      ..moveTo(width * 0.5, height * 0.3)
      ..quadraticBezierTo(width * 0.2, height * 0.1, width * 0.3, height * 0.05)
      ..quadraticBezierTo(width * 0.45, height * 0.15, width * 0.5, height * 0.3);
    canvas.drawPath(leaf1, leafPaint);

    final leaf2 = Path()
      ..moveTo(width * 0.5, height * 0.3)
      ..quadraticBezierTo(width * 0.5, height * 0.02, width * 0.52, height * 0.02)
      ..quadraticBezierTo(width * 0.55, height * 0.15, width * 0.5, height * 0.3);
    canvas.drawPath(leaf2, leafPaint);

    final leaf3 = Path()
      ..moveTo(width * 0.5, height * 0.3)
      ..quadraticBezierTo(width * 0.8, height * 0.1, width * 0.7, height * 0.05)
      ..quadraticBezierTo(width * 0.55, height * 0.15, width * 0.5, height * 0.3);
    canvas.drawPath(leaf3, leafPaint);

    // Carrot cone body
    final bodyPath = Path()
      ..moveTo(width * 0.32, height * 0.28)
      ..cubicTo(
        width * 0.3, height * 0.25,
        width * 0.7, height * 0.25,
        width * 0.68, height * 0.28,
      )
      ..quadraticBezierTo(width * 0.62, height * 0.6, width * 0.52, height * 0.92)
      ..quadraticBezierTo(width * 0.5, height * 0.96, width * 0.48, height * 0.92)
      ..quadraticBezierTo(width * 0.38, height * 0.6, width * 0.32, height * 0.28)
      ..close();

    // Body gradient
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [
          Color(0xFFFF9800),
          Color(0xFFF57C00),
          Color(0xFFE65100),
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height));

    // Shadow
    canvas.drawPath(
      bodyPath.shift(const Offset(0, 3)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    canvas.drawPath(bodyPath, bodyPaint);

    // Horizontal ridge lines
    final linePaint = Paint()
      ..color = const Color(0xFFD84315).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(width * 0.38, height * 0.4),
      Offset(width * 0.55, height * 0.42),
      linePaint,
    );
    canvas.drawLine(
      Offset(width * 0.44, height * 0.55),
      Offset(width * 0.60, height * 0.57),
      linePaint,
    );
    canvas.drawLine(
      Offset(width * 0.42, height * 0.7),
      Offset(width * 0.54, height * 0.71),
      linePaint,
    );

    // Glossy highlight line
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final highlightPath = Path()
      ..moveTo(width * 0.38, height * 0.32)
      ..quadraticBezierTo(width * 0.42, height * 0.55, width * 0.46, height * 0.75);
    canvas.drawPath(highlightPath, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for a stylized 2D Apple
class ApplePainter extends CustomPainter {
  const ApplePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final center = Offset(width / 2, height / 2 + 2);

    // Apple body path
    final applePath = Path();
    applePath.moveTo(center.dx, center.dy - height * 0.22);
    // Right lobe
    applePath.cubicTo(
      center.dx + width * 0.32, center.dy - height * 0.42,
      center.dx + width * 0.46, center.dy + height * 0.1,
      center.dx + width * 0.18, center.dy + height * 0.36,
    );
    // Bottom indent
    applePath.cubicTo(
      center.dx + width * 0.08, center.dy + height * 0.4,
      center.dx - width * 0.08, center.dy + height * 0.4,
      center.dx - width * 0.18, center.dy + height * 0.36,
    );
    // Left lobe
    applePath.cubicTo(
      center.dx - width * 0.46, center.dy + height * 0.1,
      center.dx - width * 0.32, center.dy - height * 0.42,
      center.dx, center.dy - height * 0.22,
    );
    applePath.close();

    // Shadow
    canvas.drawPath(
      applePath.shift(const Offset(0, 3)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Body gradient fill
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.3),
        radius: 0.9,
        colors: const [
          Color(0xFFFF5252),
          Color(0xFFE53935),
          Color(0xFFB71C1C),
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height));
    canvas.drawPath(applePath, bodyPaint);

    // Stem
    final stemPaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final stemPath = Path()
      ..moveTo(center.dx, center.dy - height * 0.2)
      ..cubicTo(
        center.dx + 2, center.dy - height * 0.3,
        center.dx + 6, center.dy - height * 0.38,
        center.dx + 4, center.dy - height * 0.42,
      );
    canvas.drawPath(stemPath, stemPaint);

    // Stem Leaf
    final leafPath = Path()
      ..moveTo(center.dx + 4, center.dy - height * 0.34)
      ..quadraticBezierTo(
        center.dx + 16, center.dy - height * 0.42,
        center.dx + 20, center.dy - height * 0.32,
      )
      ..quadraticBezierTo(
        center.dx + 10, center.dy - height * 0.28,
        center.dx + 4, center.dy - height * 0.34,
      );
    final leafPaint = Paint()
      ..color = const Color(0xFF43A047)
      ..style = PaintingStyle.fill;
    canvas.drawPath(leafPath, leafPaint);

    // Gloss highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    
    canvas.save();
    canvas.translate(center.dx - width * 0.18, center.dy - height * 0.12);
    canvas.rotate(-0.4);
    canvas.drawOval(
      Rect.fromLTWH(0, 0, width * 0.18, height * 0.28),
      highlightPaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for a stylized 2D Leafy Vegetable (Broccoli / Lettuce / Cabbage)
class LeafyVegPainter extends CustomPainter {
  const LeafyVegPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final center = Offset(width / 2, height / 2);

    // Base shadow
    canvas.drawCircle(
      center + const Offset(0, 4),
      width * 0.38,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Outer dark green leaves
    final darkLeafPaint = Paint()
      ..shader = RadialGradient(
        colors: const [
          Color(0xFF2E7D32),
          Color(0xFF1B5E20),
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height));

    final outerPath = Path();
    const numPetals = 6;
    final outerRadius = width * 0.42;
    for (int i = 0; i < numPetals; i++) {
      final angle = i * (2 * math.pi / numPetals);
      final px = center.dx + math.cos(angle) * outerRadius;
      final py = center.dy + math.sin(angle) * outerRadius;
      if (i == 0) {
        outerPath.moveTo(px, py);
      } else {
        final ctrlAngle = angle - (math.pi / numPetals);
        final cx = center.dx + math.cos(ctrlAngle) * (outerRadius * 1.25);
        final cy = center.dy + math.sin(ctrlAngle) * (outerRadius * 1.25);
        outerPath.quadraticBezierTo(cx, cy, px, py);
      }
    }
    outerPath.close();
    canvas.drawPath(outerPath, darkLeafPaint);

    // Mid green leaves layer
    final midLeafPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.2),
        colors: const [
          Color(0xFF66BB6A),
          Color(0xFF388E3C),
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height));

    final midPath = Path();
    final midRadius = width * 0.32;
    for (int i = 0; i < 5; i++) {
      final angle = i * (2 * math.pi / 5) + 0.3;
      final px = center.dx + math.cos(angle) * midRadius;
      final py = center.dy + math.sin(angle) * midRadius;
      if (i == 0) {
        midPath.moveTo(px, py);
      } else {
        final ctrlAngle = angle - (math.pi / 5);
        final cx = center.dx + math.cos(ctrlAngle) * (midRadius * 1.3);
        final cy = center.dy + math.sin(ctrlAngle) * (midRadius * 1.3);
        midPath.quadraticBezierTo(cx, cy, px, py);
      }
    }
    midPath.close();
    canvas.drawPath(midPath, midLeafPaint);

    // Inner bright leaves core
    final innerPaint = Paint()
      ..color = const Color(0xFFA5D6A7)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center - const Offset(2, 2), width * 0.16, innerPaint);

    // Vein detail lines
    final veinPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      center,
      center + const Offset(-12, -14),
      veinPaint,
    );
    canvas.drawLine(
      center,
      center + const Offset(14, -10),
      veinPaint,
    );
    canvas.drawLine(
      center,
      center + const Offset(0, 16),
      veinPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for a stylized 2D Orange
class OrangePainter extends CustomPainter {
  const OrangePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 2);
    final radius = math.min(size.width, size.height) * 0.42;

    // Shadow
    canvas.drawCircle(
      center + const Offset(0, 3),
      radius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Body gradient
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 0.85,
        colors: const [
          Color(0xFFFFB74D),
          Color(0xFFFFA726),
          Color(0xFFE65100),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, bodyPaint);

    // Texture dots / dimples
    final dotPaint = Paint()
      ..color = const Color(0xFFBF360C).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center + const Offset(-8, 6), 1.5, dotPaint);
    canvas.drawCircle(center + const Offset(10, 8), 1.5, dotPaint);
    canvas.drawCircle(center + const Offset(4, 14), 1.2, dotPaint);
    canvas.drawCircle(center + const Offset(-12, -4), 1.2, dotPaint);

    // Stem / Leaf at top
    final stemCenter = Offset(center.dx, center.dy - radius * 0.9);
    final leafPaint = Paint()
      ..color = const Color(0xFF43A047)
      ..style = PaintingStyle.fill;

    final leafPath = Path()
      ..moveTo(stemCenter.dx, stemCenter.dy)
      ..quadraticBezierTo(
        stemCenter.dx + 12, stemCenter.dy - 10,
        stemCenter.dx + 18, stemCenter.dy - 2,
      )
      ..quadraticBezierTo(
        stemCenter.dx + 10, stemCenter.dy + 4,
        stemCenter.dx, stemCenter.dy,
      );
    canvas.drawPath(leafPath, leafPaint);

    // Center stem dot
    canvas.drawCircle(
      stemCenter,
      2.5,
      Paint()..color = const Color(0xFF5D4037),
    );

    // Soft highlight arc
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(center.dx - radius * 0.45, center.dy - radius * 0.45);
    canvas.rotate(-0.4);
    canvas.drawOval(
      Rect.fromLTWH(0, 0, radius * 0.5, radius * 0.3),
      highlightPaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
