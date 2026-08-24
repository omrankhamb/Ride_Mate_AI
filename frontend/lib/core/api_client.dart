part of ridemate_ai;

class ApiClient {
  ApiClient({
    this.baseUrl = 'http://localhost:3000',
    this.locationBaseUrl = 'http://localhost:8000',
  });

  final String baseUrl;
  final String locationBaseUrl;
  String? token;

  Future<Map<String, dynamic>> get(String path) => _send('GET', path);

  Future<Map<String, dynamic>> post(String path,
          [Map<String, dynamic>? body]) =>
      _send('POST', path, body);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final uri = Uri.parse('$baseUrl$path');
    late http.Response response;
    if (method == 'POST') {
      response =
          await http.post(uri, headers: headers, body: jsonEncode(body ?? {}));
    } else {
      response = await http.get(uri, headers: headers);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(decoded['message']?.toString() ?? 'Request failed');
    }
    return decoded;
  }

  Future<List<DriverSummary>> availableDrivers() async {
    final data = await get('/api/drivers/available');
    return (data['drivers'] as List)
        .map((item) => DriverSummary.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> getMyRidesAndRequests() async {
    final data = await get('/api/rides/mine');
    final rides = (data['rides'] as List)
        .map((item) => Ride.fromJson(item as Map<String, dynamic>))
        .toList();
    final pendingRequests = (data['pendingRequests'] as List?) ?? [];
    return {'rides': rides, 'pendingRequests': pendingRequests.cast<Map<String, dynamic>>()};
  }

  
  Future<void> shareConfirmRide(String myRideId, String targetRideId) async {
    await post('/api/rides/share_confirm', {
      'myRideId': myRideId,
      'targetRideId': targetRideId,
    });
  }

  Future<List<Ride>> getGroupDetails(String groupId) async {
    final res = await get('/api/rides/group/$groupId/details');
    return (res['rides'] as List).map((r) => Ride.fromJson(r)).toList();
  }
  Future<void> respondToCoriderRequest(String requestId, String action) async {
    await post('/api/rides/corider_respond', {
      'requestId': requestId,
      'action': action,
    });
  }

  Future<List<Ride>> myRides() async {
    final data = await get('/api/rides/mine');
    return (data['rides'] as List)
        .map((item) => Ride.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> connectRide({
    required String myRideId,
    required String targetGroupId,
  }) async {
    await post('/api/rides/connect', {
      'myRideId': myRideId,
      'targetGroupId': targetGroupId,
    });
  }

  Future<List<Ride>> driverRides() async {
    final data = await get('/api/drivers/rides');
    return (data['rides'] as List)
        .map((item) => Ride.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> demoSession(String role) =>
      post('/api/demo/session', {'role': role});

  Stream<Ride> sseListenToRide(String rideId) async* {
    final uri = Uri.parse('$baseUrl/api/rides/$rideId/stream');
    final request = http.Request('GET', uri);
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    try {
      final response = await http.Client().send(request);
      if (response.statusCode == 200) {
        await for (final line in response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
          if (line.startsWith('data: ')) {
            final dataStr = line.substring(6);
            if (dataStr.trim().isEmpty) continue;
            final map = jsonDecode(dataStr) as Map<String, dynamic>;
            if (map.containsKey('id')) {
              yield Ride.fromJson(map);
            }
          }
        }
      }
    } catch (e) {
      // Stream error or disconnect
    }
  }

  Future<List<RideLocation>> searchLocations(String query) async {
    final data = await _sendLocation('/api/geocode', {'query': query});
    return (data['locations'] as List? ?? const [])
        .map((item) => RideLocation.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<RideMatch>> findNearbyRideMatches({
    required String rideId,
    required String riderId,
    required RideLocation pickup,
    required RideLocation destination,
    int pickupRadiusMeters = 1000,
    int destinationRadiusMeters = 1500,
  }) async {
    final data = await _send('POST', '/api/matches/nearby-rides', {
      'excludeRideId': rideId,
      'excludeRiderId': riderId,
      'pickup': pickup.toJson(),
      'destination': destination.toJson(),
      'pickupRadiusMeters': pickupRadiusMeters,
      'destinationRadiusMeters': destinationRadiusMeters,
    });
    return (data['matches'] as List? ?? const [])
        .map((item) => RideMatch.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> _sendLocation(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse('$locationBaseUrl$path'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
          decoded['detail']?.toString() ?? decoded['message']?.toString() ?? 'Location request failed');
    }
    return decoded;
  }

  void logout() {
    token = null;
  }

  Future<List<Map<String, dynamic>>> getChatMessages(String poolGroupId) async {
    final data = await get('/api/chat/$poolGroupId');
    final msgs = data['messages'] as List;
    return msgs.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> sendChatMessage(String poolGroupId, String message) async {
    final data = await post('/api/chat', {
      'poolGroupId': poolGroupId,
      'message': message,
    });
    return data['message'] as Map<String, dynamic>;
  }
}

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}
