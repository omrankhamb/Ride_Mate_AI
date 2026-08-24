part of ridemate_ai;

class RideMatch {
  const RideMatch({
    required this.rideId,
    required this.riderName,
    required this.pickup,
    required this.destination,
    required this.pickupDistanceMeters,
    required this.destinationDistanceMeters,
    required this.matchScore,
    required this.poolGroupId,
  });

  final String rideId;
  final String riderName;
  final String pickup;
  final String destination;
  final int pickupDistanceMeters;
  final int destinationDistanceMeters;
  final int matchScore;
  final String poolGroupId;

  factory RideMatch.fromJson(Map<String, dynamic> json) => RideMatch(
        rideId: json['rideId'].toString(),
        riderName: json['riderName'].toString(),
        pickup: json['pickup']?.toString() ?? 'Unknown',
        destination: json['destination']?.toString() ?? 'Unknown',
        pickupDistanceMeters:
            int.tryParse(json['pickupDistanceMeters']?.toString() ?? '0') ?? (double.tryParse(json['pickupDistanceMeters']?.toString() ?? '0')?.round() ?? 0),
        destinationDistanceMeters:
            int.tryParse(json['destinationDistanceMeters']?.toString() ?? '0') ?? (double.tryParse(json['destinationDistanceMeters']?.toString() ?? '0')?.round() ?? 0),
        matchScore: int.tryParse(json['matchScore']?.toString() ?? '0') ?? (double.tryParse(json['matchScore']?.toString() ?? '0')?.round() ?? 0),
        poolGroupId: json['poolGroupId']?.toString() ?? json['rideId'].toString(),
      );
}
