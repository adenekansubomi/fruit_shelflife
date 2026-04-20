/// FreshSense API client for Flutter.
///
/// Set [apiBaseUrl] to your FastAPI server before calling [predictFruit].
/// The app falls back to [PredictionService.analyzeFruit] (local stub)
/// when [apiBaseUrl] is null.
///
/// Example:
///   ApiService.apiBaseUrl = 'http://192.168.1.10:8000';

import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/fruit_prediction.dart';
import 'prediction_service.dart';

class ApiService {
  /// Set this before calling [predictFruit].
  /// e.g.  ApiService.apiBaseUrl = 'http://192.168.1.10:8000';
  static String? apiBaseUrl;

  static bool get isConfigured =>
      apiBaseUrl != null && apiBaseUrl!.trim().isNotEmpty;

  /// Calls POST /api/v1/predict with the image and metadata.
  /// Returns a [FruitPrediction] mapped from the API response.
  static Future<FruitPrediction> predictFruit(
    PredictionInput input,
  ) async {
    if (!isConfigured) {
      return PredictionService.analyzeFruit(input);
    }

    try {
      final uri = Uri.parse('$apiBaseUrl/api/v1/predict');
      final request = http.MultipartRequest('POST', uri);

      // Attach image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          input.imageUri,
          filename: 'fruit.jpg',
        ),
      );

      // Attach optional metadata fields
      if (input.fruitType != null) {
        request.fields['fruit_type'] = input.fruitType!;
      }
      if (input.storageMethod != null) {
        request.fields['storage_method'] = input.storageMethod!;
      }
      if (input.purchaseDate != null) {
        request.fields['purchase_date'] = input.purchaseDate!;
      }
      if (input.temperature != null) {
        request.fields['temperature'] = input.temperature!;
      }
      if (input.humidity != null) {
        request.fields['humidity'] = input.humidity!;
      }

      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode != 200) {
        throw Exception(
          'API error ${response.statusCode}: ${response.body}',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return _mapResponse(json, input);
    } catch (e) {
      // Fallback to local stub on any error
      return PredictionService.analyzeFruit(input);
    }
  }

  /// Check server health.
  static Future<Map<String, dynamic>?> checkHealth() async {
    if (!isConfigured) return null;
    try {
      final uri = Uri.parse('$apiBaseUrl/api/v1/health');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static FruitPrediction _mapResponse(
    Map<String, dynamic> json,
    PredictionInput input,
  ) {
    FruitStatus statusFromString(String s) {
      switch (s) {
        case 'fresh':      return FruitStatus.fresh;
        case 'ripening':   return FruitStatus.ripening;
        case 'near_expiry':return FruitStatus.nearExpiry;
        default:           return FruitStatus.spoiled;
      }
    }

    return FruitPrediction(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      fruitName: json['fruit_name'] as String,
      imageUri: input.imageUri,
      shelfLifeDays: json['shelf_life_days'] as int,
      status: statusFromString(json['status'] as String),
      confidence: (json['confidence'] as num).toDouble(),
      explanation: json['explanation'] as String,
      recommendations: List<String>.from(
        json['recommendations'] as List,
      ),
      storageMethod: json['storage_method'] as String? ?? input.storageMethod,
      purchaseDate: json['purchase_date'] as String? ?? input.purchaseDate,
      temperature: json['temperature'] as String? ?? input.temperature,
      humidity: json['humidity'] as String? ?? input.humidity,
      timestamp: DateTime.now(),
    );
  }
}
