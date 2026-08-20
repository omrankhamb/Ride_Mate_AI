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
            (json['pickupDistanceMeters'] as num?)?.round() ?? 0,
        destinationDistanceMeters:
            (json['destinationDistanceMeters'] as num?)?.round() ?? 0,
        matchScore: (json['matchScore'] as num?)?.round() ?? 0,
        poolGroupId: json['poolGroupId']?.toString() ?? json['rideId'].toString(),
      );
}
