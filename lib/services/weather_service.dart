import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WeatherSnapshot {
  final double? temperature;
  final double? pressure;
  final double? humidity;
  final int? weatherCode;

  const WeatherSnapshot({
    required this.temperature,
    required this.pressure,
    required this.humidity,
    required this.weatherCode,
  });

  factory WeatherSnapshot.unavailable() {
    return const WeatherSnapshot(
      temperature: null,
      pressure: null,
      humidity: null,
      weatherCode: null,
    );
  }

  bool get hasData => temperature != null;

  String get conditionLabel {
    final code = weatherCode;
    if (code == null) return 'Unavailable';
    if (code == 0) return 'Clear';
    if (code == 1 || code == 2 || code == 3) return 'Cloudy';
    if (code == 45 || code == 48) return 'Fog';
    if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) {
      return 'Rain';
    }
    if ((code >= 71 && code <= 77) || (code >= 85 && code <= 86)) {
      return 'Snow';
    }
    if (code >= 95) return 'Storm';
    return 'Weather';
  }
}

class WeatherService {
  Future<WeatherSnapshot> getWeather() async {
    try {
      // Check if location services are enabled on the device
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return WeatherSnapshot.unavailable();
      }

      // Check and request permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return WeatherSnapshot.unavailable();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return WeatherSnapshot.unavailable();
      }

      // Permission granted — get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      ).timeout(const Duration(seconds: 6));

      // Build Open-Meteo URL with current coordinates
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=${position.latitude}'
        '&longitude=${position.longitude}'
        '&current=temperature_2m,surface_pressure,relative_humidity_2m,weather_code',
      );

      // Make the API call
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      // If API call failed return nulls — don't crash the app
      if (response.statusCode != 200) {
        return WeatherSnapshot.unavailable();
      }

      // Parse the JSON response
      final data = jsonDecode(response.body);
      final current = data['current'];

      if (current is! Map<String, dynamic>) {
        return WeatherSnapshot.unavailable();
      }

      return WeatherSnapshot(
        temperature: (current['temperature_2m'] as num?)?.toDouble(),
        pressure: (current['surface_pressure'] as num?)?.toDouble(),
        humidity: (current['relative_humidity_2m'] as num?)?.toDouble(),
        weatherCode: (current['weather_code'] as num?)?.toInt(),
      );

    } catch (e) {
      // Any unexpected error: return nulls, log still saves without weather
      return WeatherSnapshot.unavailable();
    }
  }
}