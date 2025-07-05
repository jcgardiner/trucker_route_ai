import 'package:flutter/material.dart';
import '../services/location_service.dart';
import '../services/speech_service.dart';
import '../services/weather_service.dart';
import '../services/route_service.dart';
import '../models/location.dart' as trucker_models;
import '../models/weather_data.dart';
import '../models/route_info.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocationService _locationService = LocationService();
  final SpeechService _speechService = SpeechService();
  final WeatherService _weatherService = WeatherService();
  final RouteService _routeService = RouteService();
  
  final TextEditingController _destinationController = TextEditingController();
  
  trucker_models.TruckerLocation? _currentLocation;
  WeatherData? _currentWeather;
  RouteInfo? _currentRoute;
  bool _isListening = false;
  bool _isLoading = false;
  String _statusMessage = 'Ready to help you find the best route!';

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Initializing services...';
    });

    try {
      // Initialize speech service
      final speechInitialized = await _speechService.initialize();
      if (!speechInitialized) {
        setState(() {
          _statusMessage = 'Speech recognition not available';
        });
      }

      // Get current location
      await _getCurrentLocation();
      
      setState(() {
        _isLoading = false;
        _statusMessage = 'Ready to help you find the best route!';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error initializing services: $e';
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final location = await _locationService.getCurrentLocation();
      if (location != null) {
        setState(() {
          _currentLocation = location;
        });
        
        // Get weather for current location
        await _getCurrentWeather();
      } else {
        // Fallback for when location is not available
        setState(() {
          _statusMessage = 'Location not available - using demo mode';
        });
      }
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        _statusMessage = 'Location error - using demo mode';
      });
    }
  }

  Future<void> _getCurrentWeather() async {
    if (_currentLocation != null) {
      try {
        final weather = await _weatherService.getWeatherData(
          _currentLocation!.latitude,
          _currentLocation!.longitude,
        );
        setState(() {
          _currentWeather = weather;
        });
      } catch (e) {
        print('Error getting weather: $e');
      }
    }
  }

  Future<void> _startVoiceInput() async {
    if (_isListening) return;

    setState(() {
      _isListening = true;
      _statusMessage = 'Listening... Speak your destination';
    });

    await _speechService.startListening(
      onResult: (text) {
        setState(() {
          _destinationController.text = text;
          _isListening = false;
          _statusMessage = 'Heard: $text';
        });
        _findRoute();
      },
      onListeningComplete: () {
        setState(() {
          _isListening = false;
          _statusMessage = 'Voice input completed';
        });
      },
    );
  }

  Future<void> _findRoute() async {
    if (_currentLocation == null) {
      setState(() {
        _statusMessage = 'Please allow location access first';
      });
      return;
    }

    final destination = _destinationController.text.trim();
    if (destination.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter a destination';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Finding optimal route...';
    });

    try {
      // Get destination location
      final destLocation = await _locationService.getLocationFromAddress(destination);
      if (destLocation == null) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Could not find destination: $destination';
        });
        return;
      }

      // Get optimal route
      final route = await _routeService.getOptimalRoute(
        _currentLocation!,
        destLocation,
        routeType: 'truck_route',
      );

      if (route != null) {
        setState(() {
          _currentRoute = route;
          _isLoading = false;
          _statusMessage = 'Route found! ${route.distance.toStringAsFixed(1)} km, ${route.estimatedTime} min';
        });

        // Speak route information
        await _speechService.speakRouteInfo(
          'Route found. Distance: ${route.distance.toStringAsFixed(1)} kilometers. '
          'Estimated time: ${route.estimatedTime} minutes. '
          'Fuel cost: \$${route.fuelCost.toStringAsFixed(2)}',
        );
      } else {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Could not find route to $destination';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error finding route: $e';
      });
    }
  }

  Future<void> _testDemoMode() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Loading demo data...';
    });

    // Create demo location
    final demoLocation = trucker_models.TruckerLocation(
      latitude: 40.7128,
      longitude: -74.0060,
      address: 'New York, NY',
      city: 'New York',
      state: 'NY',
      country: 'USA',
    );

    // Create demo weather
    final demoWeather = WeatherData(
      temperature: 22.0,
      condition: 'Clear',
      windSpeed: 15.0,
      windDirection: 'SW',
      visibility: 10.0,
      humidity: 65.0,
      description: 'Clear sky',
    );

    // Create demo route
    final demoRoute = RouteInfo(
      origin: demoLocation,
      destination: trucker_models.TruckerLocation(
        latitude: 34.0522,
        longitude: -118.2437,
        address: 'Los Angeles, CA',
        city: 'Los Angeles',
        state: 'CA',
        country: 'USA',
      ),
      distance: 2789.5,
      estimatedTime: 1680,
      trafficCondition: 'moderate',
      waypoints: [demoLocation],
      routeType: 'truck_route',
      fuelCost: 487.66,
      warnings: ['Long route - consider rest stops', 'Cross-country journey'],
    );

    setState(() {
      _currentLocation = demoLocation;
      _currentWeather = demoWeather;
      _currentRoute = demoRoute;
      _isLoading = false;
      _statusMessage = 'Demo mode loaded! Route: NY to LA';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trucker Route AI'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _getCurrentLocation,
            tooltip: 'Refresh location',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status and Location Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.blue[800]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _currentLocation?.address ?? 'Getting location...',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _statusMessage,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Weather Card
            if (_currentWeather != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        _getWeatherIcon(_currentWeather!.condition),
                        size: 32,
                        color: Colors.blue[800],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_currentWeather!.temperature.round()}°C',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            Text(
                              _currentWeather!.description,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              'Wind: ${_currentWeather!.windSpeed} km/h ${_currentWeather!.windDirection}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      if (!_currentWeather!.isGoodForTrucking)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Warning',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Destination Input
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Destination',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _destinationController,
                            decoration: const InputDecoration(
                              hintText: 'Enter destination or use voice input',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => _findRoute(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _isListening ? null : _startVoiceInput,
                          icon: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: _isListening ? Colors.red : Colors.blue[800],
                          ),
                          tooltip: 'Voice input',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _findRoute,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Find Route'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _testDemoMode,
                        child: const Text('Test Demo Mode'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Route Information
            if (_currentRoute != null)
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Route Information',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _buildRouteInfoRow('Distance', '${_currentRoute!.distance.toStringAsFixed(1)} km'),
                        _buildRouteInfoRow('Time', '${_currentRoute!.estimatedTime} min'),
                        _buildRouteInfoRow('Fuel Cost', '\$${_currentRoute!.fuelCost.toStringAsFixed(2)}'),
                        _buildRouteInfoRow('Traffic', _currentRoute!.trafficCondition),
                        const SizedBox(height: 16),
                        if (_currentRoute!.warnings.isNotEmpty) ...[
                          Text(
                            'Warnings',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.orange[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._currentRoute!.warnings.map((warning) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.warning, color: Colors.orange[800], size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    warning,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.orange[800],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
        return Icons.grain;
      case 'snow':
        return Icons.ac_unit;
      case 'thunderstorm':
        return Icons.flash_on;
      case 'drizzle':
        return Icons.opacity;
      case 'mist':
      case 'fog':
        return Icons.cloud;
      default:
        return Icons.wb_sunny;
    }
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _speechService.dispose();
    super.dispose();
  }
} 