import 'package:permission_handler/permission_handler.dart';

class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  bool _isListening = false;

  Future<bool> initialize() async {
    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      return status.isGranted;
    } catch (e) {
      print('Error initializing speech service: $e');
      return false;
    }
  }

  Future<bool> startListening({
    required Function(String text) onResult,
    required Function() onListeningComplete,
  }) async {
    if (_isListening) return false;

    try {
      _isListening = true;
      
      // Simulate speech recognition for now
      await Future.delayed(const Duration(seconds: 2));
      
      // Return a demo result
      onResult("Los Angeles");
      onListeningComplete();
      _isListening = false;

      return true;
    } catch (e) {
      print('Error starting speech recognition: $e');
      _isListening = false;
      return false;
    }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      _isListening = false;
    }
  }

  Future<void> speak(String text) async {
    try {
      print('TTS: $text');
      // For now, just print to console
    } catch (e) {
      print('Error with text-to-speech: $e');
    }
  }

  Future<void> speakRouteInfo(String routeInfo) async {
    final speechText = _formatRouteForSpeech(routeInfo);
    await speak(speechText);
  }

  String _formatRouteForSpeech(String routeInfo) {
    // Convert route information to speech-friendly format
    return routeInfo
        .replaceAll('km', 'kilometers')
        .replaceAll('h', 'hours')
        .replaceAll('m', 'minutes')
        .replaceAll('\$', 'dollars');
  }

  bool get isListening => _isListening;

  Future<void> dispose() async {
    // Cleanup if needed
  }

  // Parse voice input for common trucker commands
  Map<String, dynamic> parseVoiceCommand(String voiceInput) {
    final input = voiceInput.toLowerCase();
    
    // Extract destination from voice input
    String? destination;
    if (input.contains('to ')) {
      final parts = input.split('to ');
      if (parts.length > 1) {
        destination = parts[1].trim();
      }
    } else if (input.contains('destination ')) {
      final parts = input.split('destination ');
      if (parts.length > 1) {
        destination = parts[1].trim();
      }
    }

    // Detect route preferences
    String routeType = 'truck_route';
    if (input.contains('fastest') || input.contains('quickest')) {
      routeType = 'fastest';
    } else if (input.contains('shortest') || input.contains('shortest distance')) {
      routeType = 'shortest';
    } else if (input.contains('avoid tolls') || input.contains('no tolls')) {
      routeType = 'avoid_tolls';
    }

    return {
      'destination': destination,
      'routeType': routeType,
      'command': input,
    };
  }
} 