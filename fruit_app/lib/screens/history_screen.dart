import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:provider/provider.dart';

import '../models/fruit_prediction.dart';
import '../providers/prediction_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/prediction_card.dart';
import 'detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PredictionProvider>();
    final predictions = provider.predictions;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(child: _buildBody(context, predictions)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(FeatherIcons.arrowLeft,
                  size: 22, color: AppColors.foreground),
            ),
          ),
          const Expanded(
            child: Text(
              'History',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.foreground,
              ),
            ),
          ),
          const SizedBox(width: 30),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, List<FruitPrediction> predictions) {
    if (predictions.isEmpty) {
      return _buildEmpty();
    }
    return _buildList(context, predictions);
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
                color: AppColors.muted, shape: BoxShape.circle),
            child: const Icon(FeatherIcons.inbox,
                size: 32, color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 12),
          const Text(
            'No scans yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Scan your first fruit to see results here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, List<FruitPrediction> predictions) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: predictions.length,
      itemBuilder: (context, index) {
        final prediction = predictions[index];
        return PredictionCard(
          prediction: prediction,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetailScreen(predictionId: prediction.id),
            ),
          ),
        );
      },
    );
  }
}
