import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Replace with your actual OpenWeatherMap API Key
  static const String openWeatherMapKey = "2c6b0fed6195b024d1e9b9144d8dcf2a";

  // Use correct OneCall API URL (v3.0 requires API key access)
  static const String oneCallUrl = "https://api.openweathermap.org/data/3.0/onecall";

  // Correct Open-Meteo Marine API URL and parameters
  static const String openMeteoMarineUrl = "https://marine-api.open-meteo.com/v1/marine";

  Future<Map<String, dynamic>> fetchWeatherData(String lat, String lon) async {
    try {
      final weatherResponse = await http.get(
        Uri.parse("https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$openWeatherMapKey&units=metric"),
      );

      if (weatherResponse.statusCode != 200) throw Exception("Weather API failed");

      final weatherData = json.decode(weatherResponse.body);

      // Fetch OneCall data for rain probability
      final oneCallResponse = await http.get(
        Uri.parse("$oneCallUrl?lat=$lat&lon=$lon&exclude=minutely,hourly&appid=$openWeatherMapKey&units=metric"),
      );

      if (oneCallResponse.statusCode != 200) throw Exception("OneCall API failed");
      final oneCallData = json.decode(oneCallResponse.body);

      return {
        'temperature': weatherData['main']['temp']?.toStringAsFixed(1) ?? '--',
        'wind_speed': weatherData['wind']['speed']?.toStringAsFixed(1) ?? '--',
        'rain_probability': (oneCallData['daily'][0]['pop'] * 100).toStringAsFixed(0),
      };
    } catch (e) {
      return {}; // Return empty to avoid null errors
    }
  }

  Future<Map<String, dynamic>> fetchMarineData(String lat, String lon) async {
    try {
      final response = await http.get(
        Uri.parse("$openMeteoMarineUrl?latitude=$lat&longitude=$lon&hourly=wave_height"),
      );

      if (response.statusCode != 200) throw Exception("Marine API failed");
      final data = json.decode(response.body);

      return {
        'wave_height': data['hourly']['wave_height'][0]?.toStringAsFixed(1) ?? '--',
        'tide_level': '--', // Tide data not available in Open-Meteo's free tier
      };
    } catch (e) {
      return {}; // Return empty to avoid null errors
    }
  }
}