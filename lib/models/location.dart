class TruckerLocation {
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
  final String? state;
  final String? country;

  TruckerLocation({
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.state,
    this.country,
  });

  @override
  String toString() {
    return 'TruckerLocation(lat: $latitude, lng: $longitude, address: $address)';
  }
} 