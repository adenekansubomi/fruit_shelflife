import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:provider/provider.dart';

import '../models/fruit_prediction.dart';
import '../providers/prediction_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/shelf_life_ring.dart';
import '../widgets/status_badge.dart';

class DetailScreen extends StatelessWidget {
  final String predictionId;

  const DetailScreen({super.key, required this.predictionId});

  static const _maxDays = {
    'banana': 7,
    'mango': 14,
    'apple': 30,
    'orange': 21,
    'strawberry': 5,
    'grape': 10,
    'watermelon': 14,
    'pineapple': 5,
    'avocado': 5,
    'peach': 5,
    'fruit': 14,
  };

  String _storageLabel(String? method) {
    switch (method) {
      case 'refrigerator':
        return 'Refrigerator';
      case 'freezer':
        return 'Freezer';
      default:
        return 'Room Temperature';
    }
  }

  IconData _storageIcon(String? method) {
    switch (method) {
      case 'refrigerator':
        return FeatherIcons.thermometer;
      case 'freezer':
        return FeatherIcons.wind;
      default:
        return FeatherIcons.sun;
    }
  }

  @override
  Widget build(BuildContext context) {
    final prediction = context
        .watch<PredictionProvider>()
        .predictions
        .where((p) => p.id == predictionId)
        .firstOrNull;

    if (prediction == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(children: [
                    Icon(FeatherIcons.arrowLeft,
                        size: 22, color: AppColors.foreground),
                  ]),
                ),
              ),
              const Expanded(
                child: Center(
                  child: Text('Prediction not found',
                      style: TextStyle(color: AppColors.mutedForeground)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final fruitKey = prediction.fruitName.toLowerCase();
    final max = _maxDays[fruitKey] ?? 14;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(context, prediction),
              const SizedBox(height: 8),
              _buildHeroCard(prediction),
              const SizedBox(height: 14),
              _buildRingCard(prediction, max),
              const SizedBox(height: 14),
              _buildSectionCard(
                icon: FeatherIcons.fileText,
                title: 'Analysis',
                child: Text(
                  prediction.explanation,
                  style: const TextStyle(
                      fontSize: 14, height: 1.6, color: AppColors.foreground),
                ),
              ),
              const SizedBox(height: 14),
              _buildSectionCard(
                icon: FeatherIcons.checkCircle,
                title: 'Recommendations',
                child: _buildRecommendations(prediction.recommendations),
              ),
              if (prediction.purchaseDate != null ||
                  prediction.temperature != null) ...[
                const SizedBox(height: 14),
                _buildSectionCard(
                  icon: FeatherIcons.sliders,
                  title: 'Sensor Data',
                  child: _buildSensorData(prediction),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, FruitPrediction prediction) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(FeatherIcons.arrowLeft,
                size: 22, color: AppColors.foreground),
          ),
        ),
        GestureDetector(
          onTap: () => _confirmDelete(context, prediction),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(FeatherIcons.trash2,
                size: 20, color: AppColors.destructive),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(FruitPrediction prediction) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              File(prediction.imageUri),
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 90,
                height: 90,
                color: AppColors.muted,
                child: const Icon(FeatherIcons.image,
                    color: AppColors.mutedForeground),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prediction.fruitName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 8),
                StatusBadge(status: prediction.status, size: BadgeSize.lg),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(FeatherIcons.barChart2,
                        size: 13, color: AppColors.mutedForeground),
                    const SizedBox(width: 5),
                    Text(
                      '${(prediction.confidence * 100).toStringAsFixed(0)}% confidence',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.mutedForeground),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRingCard(FruitPrediction prediction, int max) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          ShelfLifeRing(
            days: prediction.shelfLifeDays,
            maxDays: max,
            status: prediction.status,
            size: 180,
          ),
          if (prediction.storageMethod != null) ...[
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_storageIcon(prediction.storageMethod),
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    _storageLabel(prediction.storageMethod),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendations(List<String> recs) {
    return Column(
      children: recs.map((rec) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      color: AppColors.primary, shape: BoxShape.circle),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(rec,
                    style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: AppColors.foreground)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSensorData(FruitPrediction prediction) {
    return Row(
      children: [
        if (prediction.purchaseDate != null)
          Expanded(
            child: _SensorItem(
              icon: FeatherIcons.calendar,
              label: 'Purchased',
              value: prediction.purchaseDate!,
            ),
          ),
        if (prediction.purchaseDate != null && prediction.temperature != null)
          const SizedBox(width: 10),
        if (prediction.temperature != null)
          Expanded(
            child: _SensorItem(
              icon: FeatherIcons.thermometer,
              label: 'Temperature',
              value: '${prediction.temperature}°C',
            ),
          ),
      ],
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.foreground)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, FruitPrediction prediction) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        title: const Text('Delete Scan'),
        content: const Text('Remove this prediction from history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context
                  .read<PredictionProvider>()
                  .deletePrediction(prediction.id);
              if (context.mounted) Navigator.pop(context);
            },
            style: TextButton.styleFrom(
                foregroundColor: AppColors.destructive),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _SensorItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SensorItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.mutedForeground)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground)),
        ],
      ),
    );
  }
}
