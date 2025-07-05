import 'location.dart';

class RouteInfo {
  final TruckerLocation origin;
  final TruckerLocation destination;
  final double distance; // in kilometers
  final int estimatedTime; // in minutes
  final String trafficCondition; // 'light', 'moderate', 'heavy'
  final List<TruckerLocation> waypoints;
  final String routeType; // 'fastest', 'shortest', 'avoid_tolls', 'truck_route'
  final double fuelCost; // estimated fuel cost
  final List<String> warnings;

  RouteInfo({
    required this.origin,
    required this.destination,
    required this.distance,
    required this.estimatedTime,
    required this.trafficCondition,
    required this.waypoints,
    required this.routeType,
    required this.fuelCost,
    required this.warnings,
  });

  @override
  String toString() {
    return 'RouteInfo(distance: ${distance}km, time: ${estimatedTime}min, fuel: \$${fuelCost.toStringAsFixed(2)})';
  }

  String get formattedDistance => '${distance.toStringAsFixed(1)} km';
  
  String get formattedTime {
    final hours = estimatedTime ~/ 60;
    final minutes = estimatedTime % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String get trafficIcon {
    switch (trafficCondition.toLowerCase()) {
      case 'light':
        return '🟢';
      case 'moderate':
        return '🟡';
      case 'heavy':
        return '🔴';
      default:
        return '⚪';
    }
  }

  bool get isOptimalRoute {
    return trafficCondition.toLowerCase() == 'light' && 
           estimatedTime < 480; // less than 8 hours
  }
} 