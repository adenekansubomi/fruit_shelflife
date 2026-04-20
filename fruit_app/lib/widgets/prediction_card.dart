import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';

import '../models/fruit_prediction.dart';
import '../theme/app_colors.dart';
import 'status_badge.dart';

class PredictionCard extends StatelessWidget {
  final FruitPrediction prediction;
  final VoidCallback onTap;

  const PredictionCard({
    super.key,
    required this.prediction,
    required this.onTap,
  });

  String _relativeTime(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(prediction.imageUri),
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 64,
                  height: 64,
                  color: AppColors.muted,
                  child: const Icon(FeatherIcons.image,
                      color: AppColors.mutedForeground, size: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        prediction.fruitName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.foreground,
                        ),
                      ),
                      Text(
                        _relativeTime(prediction.timestamp),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  StatusBadge(status: prediction.status, size: BadgeSize.sm),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(FeatherIcons.clock,
                          size: 13, color: AppColors.mutedForeground),
                      const SizedBox(width: 4),
                      Text(
                        '${prediction.shelfLifeDays} ${prediction.shelfLifeDays == 1 ? 'day' : 'days'} remaining',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.mutedForeground,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(FeatherIcons.chevronRight,
                color: AppColors.border, size: 16),
          ],
        ),
      ),
    );
  }
}
