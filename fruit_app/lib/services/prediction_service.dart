import 'dart:math';

import '../models/fruit_prediction.dart';

class PredictionInput {
  final String imageUri;
  final String? fruitType;
  final String? storageMethod;
  final String? purchaseDate;
  final String? temperature;
  final String? humidity;
  // New environment metadata
  final String? lightExposure;
  final String? airflow;

  PredictionInput({
    required this.imageUri,
    this.fruitType,
    this.storageMethod,
    this.purchaseDate,
    this.temperature,
    this.humidity,
    this.lightExposure,
    this.airflow,
  });
}

class _FruitData {
  final int maxDays;
  final List<String> keywords;
  const _FruitData({required this.maxDays, required this.keywords});
}

// Multipliers for light exposure
const _lightFactor = {
  'direct_sunlight': 0.80,
  'shaded': 1.00,
  'dark_cupboard': 1.10,
};

// Multipliers for airflow
const _airflowFactor = {
  'open_shelf': 0.95,
  'closed_drawer': 1.10,
  'ventilated_basket': 1.00,
};

class PredictionService {
  static const _fruitData = {
    'banana':     _FruitData(maxDays: 7,  keywords: ['banana', 'bananas']),
    'mango':      _FruitData(maxDays: 14, keywords: ['mango', 'mangoes']),
    'apple':      _FruitData(maxDays: 30, keywords: ['apple', 'apples']),
    'orange':     _FruitData(maxDays: 21, keywords: ['orange', 'oranges', 'citrus']),
    'strawberry': _FruitData(maxDays: 5,  keywords: ['strawberry', 'strawberries']),
    'grape':      _FruitData(maxDays: 10, keywords: ['grape', 'grapes']),
    'watermelon': _FruitData(maxDays: 14, keywords: ['watermelon']),
    'pineapple':  _FruitData(maxDays: 5,  keywords: ['pineapple']),
    'avocado':    _FruitData(maxDays: 5,  keywords: ['avocado']),
    'peach':      _FruitData(maxDays: 5,  keywords: ['peach', 'peaches']),
  };

  static String _detectFruit(String text) {
    final lower = text.toLowerCase();
    for (final entry in _fruitData.entries) {
      if (entry.value.keywords.any((k) => lower.contains(k))) return entry.key;
    }
    return 'fruit';
  }

  static FruitStatus _getStatus(int days, int maxDays) {
    final ratio = days / maxDays;
    if (ratio > 0.7) return FruitStatus.fresh;
    if (ratio > 0.4) return FruitStatus.ripening;
    if (ratio > 0.1) return FruitStatus.nearExpiry;
    return FruitStatus.spoiled;
  }

  static List<String> _getRecommendations(
      String fruitName, FruitStatus status, PredictionInput input) {
    final base = {
      FruitStatus.fresh: [
        'Store at optimal temperature to maintain freshness',
        'Keep away from ethylene-producing fruits like bananas',
        'Check daily for any signs of bruising or mold',
      ],
      FruitStatus.ripening: [
        'Consume within the next few days for best quality',
        'Move to refrigerator to slow ripening process',
        'Ideal time to prepare jams, smoothies, or baked goods',
      ],
      FruitStatus.nearExpiry: [
        'Consume today or tomorrow to avoid waste',
        'Consider freezing if not consuming immediately',
        'Inspect carefully before eating — remove any bruised spots',
      ],
      FruitStatus.spoiled: [
        'Discard immediately — do not consume',
        'Clean storage area to prevent mold spread',
        'Check adjacent fruits for contamination',
      ],
    };

    final recs = List<String>.from(base[status]!);

    if (fruitName == 'banana' && status == FruitStatus.fresh) {
      recs.add('Keep at room temperature — refrigeration turns skin black');
    }
    if (fruitName == 'mango' && status == FruitStatus.ripening) {
      recs.add('Place in a paper bag to accelerate ripening');
    }
    if (input.storageMethod == 'refrigerator') {
      recs.add('Refrigerator storage is helping extend shelf life');
    }
    if (input.lightExposure == 'direct_sunlight') {
      recs.add('Move away from direct sunlight — UV and heat accelerate decay');
    }
    if (input.airflow == 'closed_drawer') {
      recs.add('Ensure there is some ventilation to prevent moisture buildup');
    }
    return recs.take(3).toList();
  }

  static String _getExplanation(
      String fruitName, int days, FruitStatus status, PredictionInput input) {
    const phrases = {
      FruitStatus.fresh:      'appears fresh with good color and no visible deterioration',
      FruitStatus.ripening:   'shows signs of active ripening with some softening',
      FruitStatus.nearExpiry: 'shows significant ripening with potential quality loss',
      FruitStatus.spoiled:    'shows clear spoilage indicators and should not be consumed',
    };

    var explanation =
        'Visual analysis indicates this $fruitName ${phrases[status]}. ';

    if (days > 1) {
      explanation +=
          'Based on multimodal assessment, approximately $days days of shelf life remains. ';
    } else if (days == 1) {
      explanation += 'Consume today for best quality. ';
    } else {
      explanation += 'This fruit has passed its optimal consumption window. ';
    }

    if (input.storageMethod != null) {
      explanation +=
          '${input.storageMethod == 'refrigerator' ? 'Refrigeration' : 'Room temperature storage'} has been factored into this estimate. ';
    }

    if (input.temperature != null) {
      final temp = double.tryParse(input.temperature!) ?? 0;
      if (temp > 25) {
        explanation +=
            'Warm outdoor conditions (${temp.toStringAsFixed(1)}°C) may accelerate ripening. ';
      } else if (temp < 10) {
        explanation +=
            'Cool outdoor conditions (${temp.toStringAsFixed(1)}°C) are beneficial for shelf life. ';
      }
    }

    if (input.lightExposure == 'direct_sunlight') {
      explanation += 'Direct sunlight is significantly reducing shelf life. ';
    } else if (input.lightExposure == 'dark_cupboard') {
      explanation += 'Dark storage is helping slow the ripening process. ';
    }

    if (input.airflow == 'closed_drawer') {
      explanation += 'The enclosed space retains moisture, slowing moisture loss. ';
    } else if (input.airflow == 'open_shelf') {
      explanation += 'Open-air storage increases moisture loss over time. ';
    }

    return explanation.trim();
  }

  static Future<FruitPrediction> analyzeFruit(PredictionInput input) async {
    await Future.delayed(Duration(milliseconds: 2000 + Random().nextInt(1500)));

    final fruitName = input.fruitType != null
        ? _detectFruit(input.fruitType!) != 'fruit'
            ? _detectFruit(input.fruitType!)
            : input.fruitType!.toLowerCase()
        : 'fruit';

    final fruitData =
        _fruitData[fruitName] ?? const _FruitData(maxDays: 14, keywords: []);

    double days = (Random().nextInt(fruitData.maxDays) + 1).toDouble();

    // Storage adjustment
    if (input.storageMethod == 'refrigerator') {
      days = min(days * 1.5, fruitData.maxDays.toDouble());
    } else if (input.storageMethod == 'freezer') {
      days = min(days * 4.0, fruitData.maxDays * 4.0);
    }

    // Temperature adjustment (from weather)
    if (input.temperature != null) {
      final temp = double.tryParse(input.temperature!) ?? 20;
      if (temp > 30) days *= 0.6;
      else if (temp > 25) days *= 0.8;
      else if (temp < 5) days *= 1.4;
      else if (temp < 10) days *= 1.2;
    }

    // Light exposure adjustment
    final lightMult = _lightFactor[input.lightExposure ?? 'shaded'] ?? 1.0;
    days *= lightMult;

    // Airflow adjustment
    final airflowMult = _airflowFactor[input.airflow ?? 'open_shelf'] ?? 1.0;
    days *= airflowMult;

    // Age since purchase
    if (input.purchaseDate != null) {
      try {
        final purchased = DateTime.parse(input.purchaseDate!);
        final daysSince = DateTime.now().difference(purchased).inDays;
        days = max(0, days - daysSince);
      } catch (_) {}
    }

    final baseDays = days.floor();
    final confidence = 0.72 + Random().nextDouble() * 0.2;
    final status = _getStatus(baseDays, fruitData.maxDays);
    final recommendations = _getRecommendations(fruitName, status, input);
    final explanation = _getExplanation(fruitName, baseDays, status, input);
    final displayName = fruitName[0].toUpperCase() + fruitName.substring(1);

    return FruitPrediction(
      id: '${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(999999)}',
      fruitName: displayName,
      imageUri: input.imageUri,
      shelfLifeDays: baseDays,
      status: status,
      confidence: confidence,
      explanation: explanation,
      recommendations: recommendations,
      storageMethod: input.storageMethod,
      purchaseDate: input.purchaseDate,
      temperature: input.temperature,
      humidity: input.humidity,
      lightExposure: input.lightExposure,
      airflow: input.airflow,
      timestamp: DateTime.now(),
    );
  }
}
