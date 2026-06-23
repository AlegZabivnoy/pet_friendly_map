import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class CompassConePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          Colors.blue.withOpacity(0.4),
          Colors.blue.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = ui.Path()
      ..moveTo(size.width / 2, size.height / 2)
      ..lineTo(size.width / 2 - 25, 0)
      ..lineTo(size.width / 2 + 25, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}