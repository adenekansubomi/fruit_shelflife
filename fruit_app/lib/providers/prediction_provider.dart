import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/fruit_prediction.dart';

class PredictionProvider extends ChangeNotifier {
  static const _storageKey = 'freshsense_predictions';

  List<FruitPrediction> _predictions = [];
  bool _isLoading = true;

  List<FruitPrediction> get predictions => _predictions;
  bool get isLoading => _isLoading;

  PredictionProvider() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        _predictions =
            list.map((e) => FruitPrediction.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addPrediction(FruitPrediction prediction) async {
    _predictions = [prediction, ..._predictions];
    notifyListeners();
    await _persist();
  }

  Future<void> deletePrediction(String id) async {
    _predictions = _predictions.where((p) => p.id != id).toList();
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _storageKey, jsonEncode(_predictions.map((p) => p.toJson()).toList()));
    } catch (_) {}
  }
}
