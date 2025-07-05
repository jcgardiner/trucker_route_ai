class WeatherData {
  final double temperature;
  final String condition;
  final double windSpeed;
  final String windDirection;
  final double visibility;
  final double humidity;
  final String description;

  WeatherData({
    required this.temperature,
    required this.condition,
    required this.windSpeed,
    required this.windDirection,
    required this.visibility,
    required this.humidity,
    required this.description,
  });

  bool get isGoodForTrucking {
    return temperature > -10 && 
           temperature < 40 && 
           windSpeed < 30 && 
           visibility > 1.0;
  }

  String get weatherAlert {
    if (temperature < -10) return 'Extreme cold conditions';
    if (temperature > 40) return 'Extreme heat conditions';
    if (windSpeed > 30) return 'High winds';
    if (visibility < 1.0) return 'Poor visibility';
    return 'Good conditions for trucking';
  }

  @override
  String toString() {
    return 'WeatherData(temp: ${temperature}°C, condition: $condition, wind: ${windSpeed}km/h $windDirection)';
  }
} 