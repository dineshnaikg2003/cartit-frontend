import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Programmatically drawn CartIT grocery cart.
///
/// The cart is intentionally asset-free and supports animated tilt, lift,
/// shadow response, and a subtle gloss sweep.
class CartPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;
  final Color metalColor;
  final double highlightProgress;
  final double tilt;
  final double lift;
  final double reaction;

  const CartPainter({
    required this.primaryColor,
    required this.accentColor,
    this.metalColor = const Color(0xFF78909C),
    this.highlightProgress = 0.0,
    this.tilt = 0.0,
    this.lift = 0.0,
    this.reaction = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // All geometry lives inside this local transform so the cart can gently
    // lean/lift as groceries land.
    final center = Offset(width * 0.5, height * 0.54);
    canvas.save();
    canvas.translate(center.dx, center.dy - lift);
    canvas.rotate(tilt);
    canvas.translate(-center.dx, -center.dy);

    // Basket dimensions follow the reference: a broad curved rim with a
    // noticeably tapered, rounded lower bowl.
    final basketTop = height * 0.26;
    final basketLeft = width * 0.24;
    final basketRight = width * 0.84;
    final basketBottom = height * 0.64;
    final basketWidth = basketRight - basketLeft;
    final basketHeight = basketBottom - basketTop;

    // Dynamic ground shadow: wider on impact, tighter while airborne.
    final shadowWidth = width * (0.48 + reaction * 0.16 + (lift / 90).clamp(0.0, 0.08));
    final shadowHeight = height * (0.055 + reaction * 0.018);
    final shadowOpacity = (0.16 + reaction * 0.07).clamp(0.0, 0.28);
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: shadowOpacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(width * 0.52, height * 0.88 + lift * 0.25),
        width: shadowWidth,
        height: shadowHeight,
      ),
      shadowPaint,
    );

    // Metal lower structure, without wheels: the cart reads cleaner as a
    // simple premium grocery icon and remains faithful to the requested form.
    final framePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.9),
          metalColor,
          metalColor.withValues(alpha: 0.88),
        ],
      ).createShader(Rect.fromLTWH(0, height * 0.12, width, height * 0.75))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final rearBasketCorner = Offset(basketLeft + 8, basketTop + basketHeight - 4);
    final frontBasketCorner =
        Offset(basketLeft + basketWidth - 10, basketTop + basketHeight - 4);
    final handleTop = Offset(width * 0.14, height * 0.14);
    final lowerFront = Offset(width * 0.73, height * 0.76);

    final chassisPath = Path()
      ..moveTo(handleTop.dx, handleTop.dy)
      ..lineTo(rearBasketCorner.dx, rearBasketCorner.dy)
      ..lineTo(width * 0.34, height * 0.76)
      ..lineTo(lowerFront.dx, lowerFront.dy)
      ..moveTo(frontBasketCorner.dx, frontBasketCorner.dy)
      ..lineTo(lowerFront.dx, lowerFront.dy);
    canvas.drawPath(chassisPath, framePaint);

    // Handle.
    final handleGripPath = Path()
      ..moveTo(handleTop.dx - 12, handleTop.dy - 6)
      ..quadraticBezierTo(
        handleTop.dx - 2,
        handleTop.dy + 3,
        handleTop.dx + 10,
        handleTop.dy + 10,
      );
    final handleGripPaint = Paint()
      ..shader = LinearGradient(
        colors: [primaryColor, accentColor],
      ).createShader(Rect.fromLTWH(0, 0, width * 0.28, height * 0.24))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(handleGripPath, handleGripPaint);

    final basketPath = Path()
      ..moveTo(basketLeft, basketTop)
      ..quadraticBezierTo(
        width * 0.52,
        basketTop + height * 0.055,
        basketRight,
        basketTop,
      )
      ..quadraticBezierTo(
        width * 0.83,
        height * 0.44,
        width * 0.76,
        height * 0.58,
      )
      ..quadraticBezierTo(
        width * 0.75,
        basketBottom,
        width * 0.67,
        basketBottom + height * 0.015,
      )
      ..lineTo(width * 0.40, basketBottom + height * 0.015)
      ..quadraticBezierTo(
        width * 0.31,
        basketBottom,
        width * 0.30,
        height * 0.55,
      )
      ..quadraticBezierTo(
        width * 0.25,
        height * 0.42,
        basketLeft,
        basketTop,
      )
      ..close();

    // Basket depth shadow.
    final basketShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(
      basketPath.shift(Offset(0, height * 0.018)),
      basketShadow,
    );

    // Rich green tapered basket body.
    final basketFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primaryColor.withValues(alpha: 0.98),
          primaryColor,
          accentColor.withValues(alpha: 0.94),
          primaryColor.withValues(alpha: 0.90),
        ],
        stops: const [0.0, 0.34, 0.70, 1.0],
      ).createShader(
        Rect.fromLTWH(
          basketLeft,
          basketTop,
          basketRight - basketLeft,
          basketBottom - basketTop,
        ),
      );
    canvas.drawPath(basketPath, basketFill);

    // Dark lower inner shading gives the basket a deeper bowl-like volume.
    final lowerShade = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.20),
        ],
      ).createShader(
        Rect.fromLTWH(
          basketLeft,
          basketTop + height * 0.15,
          basketRight - basketLeft,
          basketBottom - basketTop,
        ),
      );
    canvas.drawPath(basketPath, lowerShade);

    // Curved front highlight band.
    final frontHighlight = Path()
      ..moveTo(width * 0.31, height * 0.42)
      ..quadraticBezierTo(
        width * 0.53,
        height * 0.50,
        width * 0.79,
        height * 0.40,
      )
      ..quadraticBezierTo(
        width * 0.76,
        height * 0.45,
        width * 0.72,
        height * 0.48,
      )
      ..quadraticBezierTo(
        width * 0.52,
        height * 0.55,
        width * 0.34,
        height * 0.47,
      )
      ..close();

    final frontHighlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.18),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromLTWH(
          width * 0.30,
          height * 0.38,
          width * 0.52,
          height * 0.16,
        ),
      );
    canvas.drawPath(frontHighlight, frontHighlightPaint);

    // White curved upper rim, matching the reference silhouette.
    final rimPath = Path()
      ..moveTo(width * 0.235, basketTop)
      ..quadraticBezierTo(
        width * 0.52,
        basketTop + height * 0.065,
        width * 0.845,
        basketTop,
      )
      ..lineTo(width * 0.832, basketTop + height * 0.032)
      ..quadraticBezierTo(
        width * 0.53,
        basketTop + height * 0.095,
        width * 0.252,
        basketTop + height * 0.032,
      )
      ..close();

    final rimPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white,
          Colors.white.withValues(alpha: 0.94),
          const Color(0xFFE8F5E9),
        ],
      ).createShader(
        Rect.fromLTWH(
          width * 0.23,
          basketTop,
          width * 0.62,
          height * 0.11,
        ),
      );
    canvas.drawPath(rimPath, rimPaint);

    // Green lower edge gives the bowl a clean finished silhouette.
    final lowerEdge = Path()
      ..moveTo(width * 0.39, basketBottom)
      ..quadraticBezierTo(
        width * 0.54,
        basketBottom + height * 0.018,
        width * 0.68,
        basketBottom,
      );
    final lowerEdgePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(lowerEdge, lowerEdgePaint);

    // Minimal white leaf emblem on the front of the basket.
    final leafPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.96)
      ..style = PaintingStyle.fill;

    final leftLeaf = Path()
      ..moveTo(width * 0.46, height * 0.48)
      ..quadraticBezierTo(
        width * 0.40,
        height * 0.43,
        width * 0.37,
        height * 0.40,
      )
      ..quadraticBezierTo(
        width * 0.44,
        height * 0.405,
        width * 0.49,
        height * 0.47,
      )
      ..close();

    final rightLeaf = Path()
      ..moveTo(width * 0.51, height * 0.50)
      ..quadraticBezierTo(
        width * 0.54,
        height * 0.42,
        width * 0.61,
        height * 0.40,
      )
      ..quadraticBezierTo(
        width * 0.59,
        height * 0.48,
        width * 0.51,
        height * 0.50,
      )
      ..close();

    final stem = Path()
      ..moveTo(width * 0.50, height * 0.52)
      ..quadraticBezierTo(
        width * 0.49,
        height * 0.47,
        width * 0.47,
        height * 0.43,
      );

    canvas.drawPath(leftLeaf, leafPaint);
    canvas.drawPath(rightLeaf, leafPaint);
    canvas.drawPath(
      stem,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );

    // Gloss sweep follows the actual tapered basket silhouette.
    if (highlightProgress > 0.0 && highlightProgress <= 1.0) {
      canvas.save();
      canvas.clipPath(basketPath);
      final basketWidth = basketRight - basketLeft;
      final basketHeight = basketBottom - basketTop;
      final sheenX = basketLeft - basketWidth * 0.55 +
          highlightProgress * basketWidth * 2.10;
      final sheenPath = Path()
        ..moveTo(sheenX, basketTop - 18)
        ..lineTo(sheenX + 24, basketTop - 18)
        ..lineTo(sheenX - 18, basketTop + basketHeight + 18)
        ..lineTo(sheenX - 42, basketTop + basketHeight + 18)
        ..close();
      final sheenPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.32),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(
          sheenX - 45,
          basketTop,
          80,
          basketHeight,
        ));
      canvas.drawPath(sheenPath, sheenPaint);
      canvas.restore();
    }

    // Tiny rim sparkle at the end of the gloss sweep.
    if (highlightProgress > 0.88) {
      final sparkle = ((highlightProgress - 0.88) / 0.12).clamp(0.0, 1.0);
      final sparklePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.55 * math.sin(sparkle * math.pi));
      canvas.drawCircle(
        Offset(basketLeft + (basketRight - basketLeft) * 0.78, basketTop + 8),
        2.2,
        sparklePaint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CartPainter oldDelegate) {
    return oldDelegate.highlightProgress != highlightProgress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.metalColor != metalColor ||
        oldDelegate.tilt != tilt ||
        oldDelegate.lift != lift ||
        oldDelegate.reaction != reaction;
  }
}
