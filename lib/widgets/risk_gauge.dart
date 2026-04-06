import 'dart:math' as math;

import 'package:flutter/material.dart';

class RiskGauge extends StatelessWidget {
  final double safetyScore;

  const RiskGauge({super.key, required this.safetyScore});

  Color get _color {
    if (safetyScore >= 0.7) return const Color(0xFF2E7D32);
    if (safetyScore >= 0.4) return const Color(0xFFF9A825);
    return const Color(0xFFC62828);
  }

  String get _label {
    if (safetyScore >= 0.7) return 'Low Risk';
    if (safetyScore >= 0.4) return 'Moderate Risk';
    return 'High Risk';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 132,
          height: 78,
          child: CustomPaint(
            painter: _GaugePainter(safetyScore: safetyScore, color: _color),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${(safetyScore * 100).round()}% safety',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: _color),
        ),
        Text(_label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double safetyScore;
  final Color color;

  _GaugePainter({required this.safetyScore, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(14, 14, size.width - 28, (size.height - 14) * 2 - 28);
    canvas.drawArc(rect, math.pi, math.pi, false, trackPaint);
    canvas.drawArc(rect, math.pi, math.pi * safetyScore.clamp(0.0, 1.0), false, fillPaint);
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) {
    return oldDelegate.safetyScore != safetyScore || oldDelegate.color != color;
  }
}
