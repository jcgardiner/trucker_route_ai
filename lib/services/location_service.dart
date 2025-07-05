import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/location.dart' as trucker_models;

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  Future<bool> checkLocationPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  Future<trucker_models.TruckerLocation?> getCurrentLocation() async {
    try {
      final hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        final granted = await requestLocationPermission();
        if (!granted) return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return trucker_models.TruckerLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          address: '${placemark.street}, ${placemark.locality}',
          city: placemark.locality,
          state: placemark.administrativeArea,
          country: placemark.country,
        );
      }

      return trucker_models.TruckerLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  Future<trucker_models.TruckerLocation?> getLocationFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final location = locations.first;
        return trucker_models.TruckerLocation(
          latitude: location.latitude,
          longitude: location.longitude,
          address: address,
        );
      }
      return null;
    } catch (e) {
      print('Error getting location from address: $e');
      return null;
    }
  }

  Future<String?> getAddressFromLocation(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return '${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}';
      }
      return null;
    } catch (e) {
      print('Error getting address from location: $e');
      return null;
    }
  }

  double calculateDistance(trucker_models.TruckerLocation start, trucker_models.TruckerLocation end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    ) / 1000; // Convert to kilometers
  }
} 