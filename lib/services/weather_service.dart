import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WeatherService {

  Future<Map<String, double?>> getWeather() async {
    try {
      // Check if location services are enabled on the device
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return {'temperature': null, 'pressure': null, 'humidity': null};
      }

      // Check and request permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return {'temperature': null, 'pressure': null, 'humidity': null};
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return {'temperature': null, 'pressure': null, 'humidity': null};
      }

      // Permission granted — get current position
      final position = await Geolocator.getCurrentPosition();

      // Build Open-Meteo URL with current coordinates
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=${position.latitude}'
        '&longitude=${position.longitude}'
        '&current=temperature_2m,surface_pressure,relative_humidity_2m',
      );

      // Make the API call
      final response = await http.get(url);

      // If API call failed return nulls — don't crash the app
      if (response.statusCode != 200) {
        return {'temperature': null, 'pressure': null, 'humidity': null};
      }

      // Parse the JSON response
      final data = jsonDecode(response.body);
      final current = data['current'];

      return {
        'temperature': (current['temperature_2m'] as num?)?.toDouble(),
        'pressure':    (current['surface_pressure'] as num?)?.toDouble(),
        'humidity':    (current['relative_humidity_2m'] as num?)?.toDouble(),
      };

    } catch (e) {
      // Any unexpected error: return nulls, log still saves without weather
      return {'temperature': null, 'pressure': null, 'humidity': null};
    }
  }
}