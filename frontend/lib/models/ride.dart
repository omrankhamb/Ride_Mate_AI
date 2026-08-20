part of ridemate_ai;

class Ride {
  Ride({
    required this.id,
    this.riderId,
    this.driverId,
    this.poolGroupId,
    required this.pickup,
    required this.destination,
    required this.status,
    required this.otp,
    required this.coRiderPickupDistanceMeters,
    required this.estimatedFare,
    this.etaMinutes,
    this.rider,
    this.driver,
    this.driverProfile,
    this.pickupLocation,
    this.destinationLocation,
  });

  final String id;
  final String? riderId;
  final String? driverId;
  final String? poolGroupId;
  final String pickup;
  final String destination;
  final String status;
  final String otp;
  final int coRiderPickupDistanceMeters;
  final int estimatedFare;
  final int? etaMinutes;
  final AppUser? rider;
  final AppUser? driver;
  final Map<String, dynamic>? driverProfile;
  final RideLocation? pickupLocation;
  final RideLocation? destinationLocation;

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['id'].toString(),
      riderId: json['riderId']?.toString(),
      driverId: json['driverId']?.toString(),
      poolGroupId: json['poolGroupId']?.toString(),
      pickup: json['pickup'].toString(),
      destination: json['destination'].toString(),
      status: json['status'].toString(),
      otp: json['otp'].toString(),
      coRiderPickupDistanceMeters:
          int.tryParse(json['coRiderPickupDistanceMeters'].toString()) ?? 0,
      estimatedFare: int.tryParse(json['estimatedFare'].toString()) ?? 0,
      etaMinutes: json['etaMinutes'] == null
          ? null
          : int.tryParse(json['etaMinutes'].toString()),
      rider: json['rider'] == null
          ? null
          : AppUser.fromJson(json['rider'] as Map<String, dynamic>),
      driver: json['driver'] == null
          ? null
          : AppUser.fromJson(json['driver'] as Map<String, dynamic>),
      driverProfile: json['driverProfile'] == null
          ? null
          : Map<String, dynamic>.from(json['driverProfile'] as Map),
      pickupLocation: json['pickupLocation'] == null
          ? null
          : RideLocation.fromJson(
              Map<String, dynamic>.from(json['pickupLocation'] as Map)),
      destinationLocation: json['destinationLocation'] == null
          ? null
          : RideLocation.fromJson(
              Map<String, dynamic>.from(json['destinationLocation'] as Map)),
    );
  }
}
