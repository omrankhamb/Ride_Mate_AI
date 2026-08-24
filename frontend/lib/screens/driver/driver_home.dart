part of ridemate_ai;

class DriverHome extends StatefulWidget {
  const DriverHome({
    required this.api,
    required this.user,
    required this.onLogout,
    super.key,
  });

  final ApiClient api;
  final AppUser user;
  final VoidCallback onLogout;

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  int tabIndex = 0;
  bool loading = false;
  bool online = false;
  String message = '';
  final otpController = TextEditingController();
  List<Ride> rides = [];
  List<List<Ride>> boardGroups = [];

  Timer? _pollTimer;
  double currentLat = 18.5204;
  double currentLng = 73.8567;

  @override
  void initState() {
    super.initState();
    loadRides();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (online && mounted) {
        _simulateGPSMovement();
        loadRides();
      }
    });
  }

  void _simulateGPSMovement() {
    final activeRide = rides.where((r) => r.status == 'ACCEPTED' || r.status == 'STARTED').firstOrNull;
    if (activeRide != null) {
      final target = activeRide.status == 'ACCEPTED' ? activeRide.pickupLocation : activeRide.destinationLocation;
      if (target != null) {
        final dLat = target.latitude - currentLat;
        final dLng = target.longitude - currentLng;
        final dist = math.sqrt(dLat * dLat + dLng * dLng);
        if (dist > 0.0002) {
          currentLat += (dLat / dist) * 0.0002;
          currentLng += (dLng / dist) * 0.0002;
          _silentUpdateLocation();
        }
      }
    }
  }

  Future<void> _silentUpdateLocation() async {
    try {
      await widget.api.post('/api/drivers/status', {
        'isOnline': true,
        'locationLabel': 'Driver En Route',
        'lat': currentLat,
        'lng': currentLng,
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    otpController.dispose();
    super.dispose();
  }

  Future<void> loadRides() async {
    try {
      final data = await widget.api.driverRides();
      final boardRes = await widget.api.get('/api/drivers/board');
      final rawBoard = boardRes['board'] as List;
      final boardData = rawBoard.map((group) {
        return (group as List).map((r) => Ride.fromJson(r)).toList();
      }).toList();

      if (!mounted) return;
      
      // Only call setState if data changed
      bool ridesChanged = data.length != rides.length || 
          (data.isNotEmpty && rides.isNotEmpty && data[0].status != rides[0].status);
      bool boardChanged = boardData.length != boardGroups.length;

      if (ridesChanged || boardChanged || rides.isEmpty && data.isNotEmpty) {
        setState(() {
          rides = data;
          boardGroups = boardData;
        });
      }
    } catch (_) {}
  }

  Future<void> updateStatus(bool val) async {
    setState(() => loading = true);
    try {
      await widget.api.post('/api/drivers/status', {
        'isOnline': val,
        'locationLabel': 'Current Location',
        'lat': currentLat,
        'lng': currentLng,
      });
      if (!mounted) return;
      setState(() {
        online = val;
        message = val ? 'You are online.' : 'You are offline.';
      });
      if (val) loadRides();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => message = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => message = 'Could not update driver status.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> rideAction(String action, String? otp, {String? groupId, String? rideId}) async {
    try {
      if (action == 'accept' && groupId != null) {
        await widget.api.post('/api/rides/group/$groupId/accept', {});
      } else if (rideId != null) {
        await widget.api.post('/api/rides/$rideId/$action', {
          if (action == 'start') 'otp': otp,
        });
      }
      otpController.clear();
      await loadRides();
      if (action == 'accept') setState(() => tabIndex = 0);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => message = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => message = 'Could not update ride.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _DriverLiveTab(
        user: widget.user,
        online: online,
        currentLocation: RideLocation(latitude: currentLat, longitude: currentLng, label: 'Driver'),
        currentRides: rides,
        groups: boardGroups,
        onToggleOnline: updateStatus,
        onRideAction: (ridesList, action, otp) => rideAction(action, otp, groupId: ridesList.isNotEmpty ? ridesList[0].poolGroupId : null, rideId: ridesList.isNotEmpty ? ridesList[0].id : null),
      ),
      _DriverRequestsTab(
        groups: boardGroups,
        onRideAction: (ridesList, action, otp) => rideAction(action, otp, groupId: ridesList.isNotEmpty ? ridesList[0].poolGroupId : null, rideId: ridesList.isNotEmpty ? ridesList[0].id : null),
        onRefresh: loadRides,
      ),
      _DriverProfileTab(
        user: widget.user, 
        online: online,
        onLogout: widget.onLogout
      ),
    ];

    return ThemedShell(
      user: widget.user,
      title: 'Driver',
      onLogout: widget.onLogout,
      body: IndexedStack(index: tabIndex, children: tabs),
      bottomBar: NavigationBar(
        selectedIndex: tabIndex,
        onDestinationSelected: (value) => setState(() => tabIndex = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.drive_eta_outlined), label: 'Live'),
          NavigationDestination(icon: Icon(Icons.list_alt_outlined), label: 'Requests'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Account'),
        ],
      ),
    );
  }
}
