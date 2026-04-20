/// Weather service — fetches outdoor temperature and humidity from the
/// device's current GPS location using the Open-Meteo API.
///
/// Open-Meteo (open-meteo.com) is completely free and requires no API key.
///
/// IMPORTANT: Add the following permissions to your project before using:
///
/// Android — android/app/src/main/AndroidManifest.xml (inside <manifest>):
///   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
///   <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
///
/// iOS — ios/Runner/Info.plist (inside <dict>):
///   <key>NSLocationWhenInUseUsageDescription</key>
///   <string>FreshSense uses your location to fetch local weather conditions
///   that affect fruit shelf life.</string>

import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class WeatherData {
  final double temperature;
  final double humidity;
  final String locationDisplay;

  const WeatherData({
    required this.temperature,
    required this.humidity,
    required this.locationDisplay,
  });
}

class WeatherService {
  static const _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  /// Requests location permission, gets GPS fix, then calls Open-Meteo.
  /// Returns null if permission denied or network fails.
  static Future<WeatherData?> fetchCurrentWeather() async {
    // 1. Check / request permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    // 2. Get current position (low accuracy is fine for weather)
    final Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (_) {
      return null;
    }

    // 3. Call Open-Meteo — free, no API key needed
    final url = Uri.parse(
      '$_baseUrl'
      '?latitude=${position.latitude}'
      '&longitude=${position.longitude}'
      '&current=temperature_2m,relative_humidity_2m'
      '&forecast_days=1',
    );

    try {
      final response =
          await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final current = body['current'] as Map<String, dynamic>;

      final temp = (current['temperature_2m'] as num).toDouble();
      final humidity =
          (current['relative_humidity_2m'] as num).toDouble();

      final lat = position.latitude.toStringAsFixed(2);
      final lon = position.longitude.toStringAsFixed(2);

      return WeatherData(
        temperature: temp,
        humidity: humidity,
        locationDisplay: '$lat°, $lon°',
      );
    } catch (_) {
      return null;
    }
  }
}
