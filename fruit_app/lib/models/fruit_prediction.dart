enum FruitStatus { fresh, ripening, nearExpiry, spoiled }

extension FruitStatusLabel on FruitStatus {
  String get label {
    switch (this) {
      case FruitStatus.fresh:      return 'Fresh';
      case FruitStatus.ripening:   return 'Ripening';
      case FruitStatus.nearExpiry: return 'Near Expiry';
      case FruitStatus.spoiled:    return 'Spoiled';
    }
  }
}

class FruitPrediction {
  final String id;
  final String fruitName;
  final String imageUri;
  final int shelfLifeDays;
  final FruitStatus status;
  final double confidence;
  final String explanation;
  final List<String> recommendations;
  final String? storageMethod;
  final String? purchaseDate;
  final String? temperature;
  final String? humidity;
  // New environment metadata
  final String? lightExposure;
  final String? airflow;
  final DateTime timestamp;

  FruitPrediction({
    required this.id,
    required this.fruitName,
    required this.imageUri,
    required this.shelfLifeDays,
    required this.status,
    required this.confidence,
    required this.explanation,
    required this.recommendations,
    this.storageMethod,
    this.purchaseDate,
    this.temperature,
    this.humidity,
    this.lightExposure,
    this.airflow,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fruitName': fruitName,
        'imageUri': imageUri,
        'shelfLifeDays': shelfLifeDays,
        'status': status.name,
        'confidence': confidence,
        'explanation': explanation,
        'recommendations': recommendations,
        'storageMethod': storageMethod,
        'purchaseDate': purchaseDate,
        'temperature': temperature,
        'humidity': humidity,
        'lightExposure': lightExposure,
        'airflow': airflow,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  factory FruitPrediction.fromJson(Map<String, dynamic> json) {
    FruitStatus statusFromName(String name) {
      switch (name) {
        case 'fresh':      return FruitStatus.fresh;
        case 'ripening':   return FruitStatus.ripening;
        case 'nearExpiry': return FruitStatus.nearExpiry;
        default:           return FruitStatus.spoiled;
      }
    }

    return FruitPrediction(
      id: json['id'] as String,
      fruitName: json['fruitName'] as String,
      imageUri: json['imageUri'] as String,
      shelfLifeDays: json['shelfLifeDays'] as int,
      status: statusFromName(json['status'] as String),
      confidence: (json['confidence'] as num).toDouble(),
      explanation: json['explanation'] as String,
      recommendations: List<String>.from(json['recommendations'] as List),
      storageMethod: json['storageMethod'] as String?,
      purchaseDate: json['purchaseDate'] as String?,
      temperature: json['temperature'] as String?,
      humidity: json['humidity'] as String?,
      lightExposure: json['lightExposure'] as String?,
      airflow: json['airflow'] as String?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
    );
  }
}
