import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/location.dart' as trucker_models;
import '../models/route_info.dart';
import '../models/weather_data.dart';
import 'location_service.dart';
import 'weather_service.dart';

class RouteService {
  static final RouteService _instance = RouteService._internal();
  factory RouteService() => _instance;
  RouteService._internal();

  final LocationService _locationService = LocationService();
  final WeatherService _weatherService = WeatherService();

  // You'll need to get a Google Maps API key from Google Cloud Console
  static const String _apiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';

  Future<RouteInfo?> getOptimalRoute(
    trucker_models.TruckerLocation origin,
    trucker_models.TruckerLocation destination, {
    String routeType = 'truck_route',
  }) async {
    try {
      // Get weather data for both origin and destination
      final originWeather = await _weatherService.getWeatherData(
        origin.latitude,
        origin.longitude,
      );
      
      final destWeather = await _weatherService.getWeatherData(
        destination.latitude,
        destination.longitude,
      );

      // Get route from Google Maps API
      final route = await _getGoogleMapsRoute(origin, destination, routeType);
      
      if (route != null) {
        // Apply AI-powered optimizations based on weather and conditions
        return _optimizeRouteWithAI(route, originWeather, destWeather);
      }
      
      return null;
    } catch (e) {
      print('Error getting optimal route: $e');
      return _getMockRoute(origin, destination);
    }
  }

  Future<RouteInfo?> _getGoogleMapsRoute(
    trucker_models.TruckerLocation origin,
    trucker_models.TruckerLocation destination,
    String routeType,
  ) async {
    try {
      final url = Uri.parse(
        '$_baseUrl?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&avoid=highways&mode=driving&key=$_apiKey'
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final legs = route['legs'][0];
          
          return RouteInfo(
            origin: origin,
            destination: destination,
            distance: legs['distance']['value'] / 1000, // Convert to km
            estimatedTime: legs['duration']['value'] ~/ 60, // Convert to minutes
            trafficCondition: _analyzeTrafficCondition(route),
            waypoints: _extractWaypoints(route),
            routeType: routeType,
            fuelCost: _calculateFuelCost(legs['distance']['value'] / 1000),
            warnings: _generateWarnings(route, legs),
          );
        }
      }
      
      return null;
    } catch (e) {
      print('Error getting Google Maps route: $e');
      return null;
    }
  }

  RouteInfo _optimizeRouteWithAI(
    RouteInfo route,
    WeatherData? originWeather,
    WeatherData? destWeather,
  ) {
    final warnings = List<String>.from(route.warnings);
    
    // Add weather-based warnings
    if (originWeather != null && !originWeather.isGoodForTrucking) {
      warnings.add('Weather warning at origin: ${originWeather.weatherAlert}');
    }
    
    if (destWeather != null && !destWeather.isGoodForTrucking) {
      warnings.add('Weather warning at destination: ${destWeather.weatherAlert}');
    }

    // Adjust estimated time based on weather conditions
    int adjustedTime = route.estimatedTime;
    if (originWeather != null && originWeather.condition.toLowerCase().contains('rain')) {
      adjustedTime += (route.estimatedTime * 0.2).round(); // 20% longer in rain
    }
    
    if (originWeather != null && originWeather.windSpeed > 20) {
      adjustedTime += (route.estimatedTime * 0.15).round(); // 15% longer in high winds
    }

    return RouteInfo(
      origin: route.origin,
      destination: route.destination,
      distance: route.distance,
      estimatedTime: adjustedTime,
      trafficCondition: route.trafficCondition,
      waypoints: route.waypoints,
      routeType: route.routeType,
      fuelCost: route.fuelCost,
      warnings: warnings,
    );
  }

  String _analyzeTrafficCondition(Map<String, dynamic> route) {
    // This would normally use real-time traffic data
    // For now, we'll use a simple heuristic based on route complexity
    final steps = route['legs'][0]['steps'] as List;
    final hasTraffic = steps.any((step) => 
      step['duration_in_traffic'] != null || 
      step['traffic_speed_entry'] != null
    );
    
    if (hasTraffic) return 'moderate';
    if (steps.length > 20) return 'heavy';
    return 'light';
  }

  List<trucker_models.TruckerLocation> _extractWaypoints(Map<String, dynamic> route) {
    final waypoints = <trucker_models.TruckerLocation>[];
    final steps = route['legs'][0]['steps'] as List;
    
    for (var step in steps) {
      final location = step['start_location'];
      waypoints.add(trucker_models.TruckerLocation(
        latitude: location['lat'].toDouble(),
        longitude: location['lng'].toDouble(),
      ));
    }
    
    return waypoints;
  }

  double _calculateFuelCost(double distanceKm) {
    // Assuming 8 mpg for a truck and $3.50 per gallon
    const mpg = 8.0;
    const pricePerGallon = 3.50;
    final gallons = distanceKm * 0.621371 / mpg; // Convert km to miles, then to gallons
    return gallons * pricePerGallon;
  }

  List<String> _generateWarnings(Map<String, dynamic> route, Map<String, dynamic> legs) {
    final warnings = <String>[];
    
    // Check for toll roads
    if (route['fare'] != null) {
      warnings.add('Toll road detected - additional cost: \$${route['fare']['value']}');
    }
    
    // Check for long routes
    if (legs['duration']['value'] > 28800) { // More than 8 hours
      warnings.add('Long route - consider rest stops and DOT regulations');
    }
    
    // Check for complex routes
    final steps = legs['steps'] as List;
    if (steps.length > 30) {
      warnings.add('Complex route with many turns - plan accordingly');
    }
    
    return warnings;
  }

  // Mock route for development/testing
  RouteInfo _getMockRoute(trucker_models.TruckerLocation origin, trucker_models.TruckerLocation destination) {
    final distance = _locationService.calculateDistance(origin, destination);
    final estimatedTime = (distance * 2).round(); // Rough estimate: 2 min per km
    
    return RouteInfo(
      origin: origin,
      destination: destination,
      distance: distance,
      estimatedTime: estimatedTime,
      trafficCondition: 'light',
      waypoints: [origin, destination],
      routeType: 'truck_route',
      fuelCost: _calculateFuelCost(distance),
      warnings: ['Using mock data - real API key required'],
    );
  }

  Future<List<RouteInfo>> getAlternativeRoutes(trucker_models.TruckerLocation origin, trucker_models.TruckerLocation destination) async {
    final routes = <RouteInfo>[];
    
    // Get different route types
    final routeTypes = ['fastest', 'shortest', 'avoid_tolls', 'truck_route'];
    
    for (final routeType in routeTypes) {
      final route = await getOptimalRoute(origin, destination, routeType: routeType);
      if (route != null) {
        routes.add(route);
      }
    }
    
    // Sort by estimated time
    routes.sort((a, b) => a.estimatedTime.compareTo(b.estimatedTime));
    
    return routes;
  }
} 