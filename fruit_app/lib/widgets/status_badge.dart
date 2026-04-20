import 'package:flutter/material.dart';

import '../models/fruit_prediction.dart';
import '../theme/app_colors.dart';

enum BadgeSize { sm, md, lg }

class StatusBadge extends StatelessWidget {
  final FruitStatus status;
  final BadgeSize size;

  const StatusBadge({
    super.key,
    required this.status,
    this.size = BadgeSize.md,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.statusColor(status);

    final hPad = size == BadgeSize.sm ? 8.0 : size == BadgeSize.md ? 12.0 : 16.0;
    final vPad = size == BadgeSize.sm ? 3.0 : size == BadgeSize.md ? 5.0 : 7.0;
    final fontSize = size == BadgeSize.sm ? 11.0 : size == BadgeSize.md ? 13.0 : 15.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        border: Border.all(color: color.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}
