import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

// Represents a snapshot of weather conditions at a specific time.
// All fields are nullable to indicate unavailable data.
// weatherCode is based on WMO Weather interpretation codes.
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

  // Factory constructor for when weather data is unavailable.
  factory WeatherSnapshot.unavailable() {
    return const WeatherSnapshot(
      temperature: null,
      pressure: null,
      humidity: null,
      weatherCode: null,
    );
  }

  // Returns true if at least temperature data is available.
  bool get hasData => temperature != null;

  // Converts WMO weather code to human-readable condition label.
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

// Service for retrieving weather data from Open-Meteo API.
// Uses device location to fetch current and historical weather information.
class WeatherService {
  // Formats a DateTime to 'YYYY-MM-DD' string format for API requests.
  String _formatDate(DateTime date) {
    final yyyy = date.year.toString().padLeft(4, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }

  // Retrieves the device's current location.
  // Checks if location services are enabled and if permissions are granted.
  // Returns null if location is unavailable or if the request times out after 6 seconds.
  Future<Position?> _getPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low,
    ).timeout(const Duration(seconds: 6));
  }

  // Extracts weather snapshot from hourly API response data.
  // Finds the closest hour in the response to the target time and extracts temperature, pressure, humidity, and weather code.
  WeatherSnapshot _snapshotFromHourly(Map<String, dynamic> data, DateTime targetTime) {
    final hourly = data['hourly'];
    if (hourly is! Map<String, dynamic>) {
      return WeatherSnapshot.unavailable();
    }

    final times = hourly['time'];
    if (times is! List || times.isEmpty) {
      return WeatherSnapshot.unavailable();
    }

    // Find the hourly data point closest to the target time.
    var closestIndex = -1;
    Duration? closestDelta;

    for (var i = 0; i < times.length; i++) {
      final raw = times[i];
      if (raw is! String) continue;
      final parsed = DateTime.tryParse(raw);
      if (parsed == null) continue;
      final delta = parsed.difference(targetTime).abs();
      if (closestDelta == null || delta < closestDelta) {
        closestDelta = delta;
        closestIndex = i;
      }
    }

    if (closestIndex < 0) {
      return WeatherSnapshot.unavailable();
    }

    num? valueAt(String key) {
      final values = hourly[key];
      if (values is! List || closestIndex >= values.length) return null;
      final value = values[closestIndex];
      return value is num ? value : null;
    }

    return WeatherSnapshot(
      temperature: valueAt('temperature_2m')?.toDouble(),
      pressure: valueAt('surface_pressure')?.toDouble(),
      humidity: valueAt('relative_humidity_2m')?.toDouble(),
      weatherCode: valueAt('weather_code')?.toInt(),
    );
  }

  // Fetches hourly weather data from the specified API URL.
  // Makes HTTP request with 8-second timeout and extracts snapshot from response.
  Future<WeatherSnapshot> _fetchHourlyWeather({
    required Uri url,
    required DateTime targetTime,
  }) async {
    final response = await http.get(url).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      return WeatherSnapshot.unavailable();
    }

    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      return WeatherSnapshot.unavailable();
    }

    return _snapshotFromHourly(data, targetTime);
  }

  Future<WeatherSnapshot> getWeather() async {
    return getWeatherAt(DateTime.now());
  }

  // Retrieves weather data for a specific date and time.
  // First attempts to fetch from the forecast API; if no data is available, falls back to the archive API for historical data.
  Future<WeatherSnapshot> getWeatherAt(DateTime targetDateTime) async {
    try {
      final position = await _getPosition();
      if (position == null) {
        return WeatherSnapshot.unavailable();
      }

      final date = _formatDate(targetDateTime);

      // Try current forecast API first.
      final forecastUrl = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=${position.latitude}'
        '&longitude=${position.longitude}'
        '&hourly=temperature_2m,surface_pressure,relative_humidity_2m,weather_code'
        '&start_date=$date'
        '&end_date=$date'
        '&timezone=auto',
      );

      final forecastSnapshot = await _fetchHourlyWeather(
        url: forecastUrl,
        targetTime: targetDateTime,
      );
      if (forecastSnapshot.hasData) {
        return forecastSnapshot;
      }

      // Fallback to archive API for historical data.
      final archiveUrl = Uri.parse(
        'https://archive-api.open-meteo.com/v1/archive'
        '?latitude=${position.latitude}'
        '&longitude=${position.longitude}'
        '&hourly=temperature_2m,surface_pressure,relative_humidity_2m,weather_code'
        '&start_date=$date'
        '&end_date=$date'
        '&timezone=auto',
      );

      return await _fetchHourlyWeather(
        url: archiveUrl,
        targetTime: targetDateTime,
      );
    } catch (_) {
      return WeatherSnapshot.unavailable();
    }
  }
}
