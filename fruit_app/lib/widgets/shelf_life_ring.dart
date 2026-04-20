import 'dart:math';

import 'package:flutter/material.dart';

import '../models/fruit_prediction.dart';
import '../theme/app_colors.dart';

class ShelfLifeRing extends StatefulWidget {
  final int days;
  final int maxDays;
  final FruitStatus status;
  final double size;

  const ShelfLifeRing({
    super.key,
    required this.days,
    this.maxDays = 30,
    required this.status,
    this.size = 160,
  });

  @override
  State<ShelfLifeRing> createState() => _ShelfLifeRingState();
}

class _ShelfLifeRingState extends State<ShelfLifeRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.statusColor(widget.status);
    final ratio = (widget.days / widget.maxDays).clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RingPainter(
                  progress: _animation.value * ratio,
                  color: color,
                  strokeWidth: 10,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${widget.days}',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: color,
                      fontFamily: 'Inter',
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.days == 1 ? 'day' : 'days',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.mutedForeground,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 1),
                  const Text(
                    'remaining',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.mutedForeground,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth * 2) / 2;

    final bgPaint = Paint()
      ..color = color.withOpacity(0.13)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
