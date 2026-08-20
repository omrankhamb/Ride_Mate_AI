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
  List<Ride> boardRides = [];

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
        // Move slightly towards target (simulating driving at ~30km/h -> ~0.0002 degrees per 3s tick)
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
        final groupRides = (group as List).map((r) => Ride.fromJson(r)).toList();
        return groupRides.first;
      }).toList();

      if (!mounted) return;
      setState(() {
        rides = data;
        boardRides = boardData;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        rides = [];
        boardRides = [];
      });
    }
  }

  Future<void> updateStatus(bool value) async {
    setState(() {
      loading = true;
      message = '';
    });

    try {
      await widget.api.post('/api/drivers/status', {
        'isOnline': value,
        'locationLabel': 'Driver near demo pickup',
        'lat': currentLat,
        'lng': currentLng,
      });
      if (!mounted) return;
      setState(() => online = value);
      await loadRides();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => message = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => message = 'Could not update driver status.');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> rideAction(Ride ride, String action, String? otp) async {
    try {
      if (action == 'accept' && ride.poolGroupId != null) {
        await widget.api.post('/api/rides/group/${ride.poolGroupId}/accept', {});
      } else {
        await widget.api.post('/api/rides/${ride.id}/$action', {
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
        loading: loading,
        rides: rides,
        otpController: otpController,
        driverLat: currentLat,
        driverLng: currentLng,
        onToggleOnline: updateStatus,
        onRefresh: loadRides,
        onRideAction: rideAction,
      ),
      _DriverRequestsTab(
        rides: boardRides,
        otpController: otpController,
        onRideAction: rideAction,
        onRefresh: loadRides,
      ),
      _DriverProfileTab(
          user: widget.user, online: online, onLogout: widget.onLogout),
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
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.inbox_outlined), label: 'Requests'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
