part of ridemate_ai;

class DriverSummary {
  DriverSummary({
    required this.id,
    required this.name,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.isOnline,
    required this.rating,
    required this.etaMinutes,
    required this.distanceKm,
    required this.locationLabel,
  });

  final String id;
  final String name;
  final String vehicleType;
  final String vehicleNumber;
  final bool isOnline;
  final double rating;
  final int etaMinutes;
  final double distanceKm;
  final String locationLabel;

  factory DriverSummary.fromJson(Map<String, dynamic> json) {
    return DriverSummary(
      id: json['id'].toString(),
      name: json['name'].toString(),
      vehicleType: json['vehicleType'].toString(),
      vehicleNumber: json['vehicleNumber'].toString(),
      isOnline: json['isOnline'] == true,
      rating: double.tryParse(json['rating'].toString()) ?? 4.8,
      etaMinutes: int.tryParse(json['etaMinutes'].toString()) ?? 5,
      distanceKm: double.tryParse(json['distanceKm'].toString()) ?? 0.7,
      locationLabel: json['locationLabel'].toString(),
    );
  }
}
