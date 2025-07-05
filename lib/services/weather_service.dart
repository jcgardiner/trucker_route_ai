import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/weather_data.dart';

class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  // You'll need to get a free API key from https://openweathermap.org/api
  static const String _apiKey = 'YOUR_OPENWEATHERMAP_API_KEY';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  Future<WeatherData?> getWeatherData(double lat, double lng) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/weather?lat=$lat&lon=$lng&appid=$_apiKey&units=metric'
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseWeatherData(data);
      } else {
        print('Weather API error: ${response.statusCode}');
        return _getMockWeatherData(); // Fallback to mock data
      }
    } catch (e) {
      print('Error fetching weather data: $e');
      return _getMockWeatherData(); // Fallback to mock data
    }
  }

  WeatherData _parseWeatherData(Map<String, dynamic> data) {
    final main = data['main'];
    final weather = data['weather'][0];
    final wind = data['wind'];
    final visibility = data['visibility'] ?? 10000; // Default visibility

    return WeatherData(
      temperature: main['temp'].toDouble(),
      condition: weather['main'],
      windSpeed: wind['speed'].toDouble(),
      windDirection: _getWindDirection(wind['deg']?.toDouble() ?? 0),
      visibility: visibility / 1000, // Convert to kilometers
      humidity: main['humidity'].toDouble(),
      description: weather['description'],
    );
  }

  String _getWindDirection(double degrees) {
    if (degrees >= 337.5 || degrees < 22.5) return 'N';
    if (degrees >= 22.5 && degrees < 67.5) return 'NE';
    if (degrees >= 67.5 && degrees < 112.5) return 'E';
    if (degrees >= 112.5 && degrees < 157.5) return 'SE';
    if (degrees >= 157.5 && degrees < 202.5) return 'S';
    if (degrees >= 202.5 && degrees < 247.5) return 'SW';
    if (degrees >= 247.5 && degrees < 292.5) return 'W';
    if (degrees >= 292.5 && degrees < 337.5) return 'NW';
    return 'N';
  }

  // Mock weather data for development/testing
  WeatherData _getMockWeatherData() {
    return WeatherData(
      temperature: 22.0,
      condition: 'Clear',
      windSpeed: 15.0,
      windDirection: 'SW',
      visibility: 10.0,
      humidity: 65.0,
      description: 'Clear sky',
    );
  }

  Future<List<WeatherData>> getWeatherForecast(double lat, double lng) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/forecast?lat=$lat&lon=$lng&appid=$_apiKey&units=metric'
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<WeatherData> forecast = [];
        
        for (var item in data['list']) {
          forecast.add(_parseWeatherData(item));
        }
        
        return forecast;
      } else {
        print('Weather forecast API error: ${response.statusCode}');
        return [_getMockWeatherData()];
      }
    } catch (e) {
      print('Error fetching weather forecast: $e');
      return [_getMockWeatherData()];
    }
  }
} 