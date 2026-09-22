import 'dart:math';
import 'package:flutter/material.dart';

class TimerPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;

  TimerPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);
    final strokeWidth = 32.0;
    
    // Background track
    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
      
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
      
    final startAngle = -pi / 2; // Top
    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );

    // Draw ticks inside the progress track
    final tickPaint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final numTicks = 60; // 60 minutes
    // Make ticks only cover the inner part of the stroke width (like the image)
    final tickRadiusStart = radius - (strokeWidth / 2) + 4;
    final tickRadiusEnd = radius + 2;

    for (int i = 0; i < numTicks; i++) {
      final angle = (i * 2 * pi / numTicks) - pi / 2;
      
      // Ticks are only visible on the progress part
      if (i * (2 * pi / numTicks) <= sweepAngle) {
        final startX = center.dx + tickRadiusStart * cos(angle);
        final startY = center.dy + tickRadiusStart * sin(angle);
        final endX = center.dx + tickRadiusEnd * cos(angle);
        final endY = center.dy + tickRadiusEnd * sin(angle);

        canvas.drawLine(Offset(startX, startY), Offset(endX, endY), tickPaint);
      }
    }
  }

  @override
  bool shouldRepaint(TimerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.backgroundColor != backgroundColor ||
           oldDelegate.progressColor != progressColor;
  }
}

