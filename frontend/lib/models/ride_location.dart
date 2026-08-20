part of ridemate_ai;

class RideLocation {
  const RideLocation({
    required this.latitude,
    required this.longitude,
    required this.label,
  });

  final double latitude;
  final double longitude;
  final String label;

  LatLng get latLng => LatLng(latitude, longitude);

  Map<String, dynamic> toJson() => {
        'lat': latitude,
        'lng': longitude,
        'label': label,
      };

  factory RideLocation.fromJson(Map<String, dynamic> json) {
    return RideLocation(
      latitude: double.tryParse((json['lat'] ?? json['latitude']).toString()) ??
          0,
      longitude:
          double.tryParse((json['lng'] ?? json['longitude']).toString()) ?? 0,
      label: json['label']?.toString() ??
          json['displayName']?.toString() ??
          'Pinned location',
    );
  }
}
