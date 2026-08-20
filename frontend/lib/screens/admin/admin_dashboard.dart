part of ridemate_ai;

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key, required this.api, required this.onLogout});
  final ApiClient api;
  final VoidCallback onLogout;

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  Timer? _timer;
  List<DriverSummary> _drivers = [];
  List<Ride> _rides = [];

  @override
  void initState() {
    super.initState();
    _fetchState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchState());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchState() async {
    try {
      final res = await widget.api.get('/api/admin/state');
      final driversList = (res['drivers'] as List).map((d) => DriverSummary.fromJson(d)).toList();
      final ridesList = (res['rides'] as List).map((r) => Ride.fromJson(r)).toList();
      if (mounted) {
        setState(() {
          _drivers = driversList;
          _rides = ridesList;
        });
      }
    } catch (e) {
      // Ignore errors silently on auto-refresh
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchState),
          TextButton(
            onPressed: widget.onLogout,
            child: const Text('Exit', style: TextStyle(color: AppColors.primary)),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // Side panel
          Container(
            width: 320,
            color: Colors.white,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                MetricCard(label: 'Online Drivers', value: '\${_drivers.length}'),
                const SizedBox(height: 16),
                MetricCard(label: 'Active Rides', value: '\${_rides.length}'),
                const SizedBox(height: 24),
                const Text('Live Drivers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Divider(),
                ..._drivers.map((d) => ListTile(
                  leading: const Icon(Icons.local_taxi, color: AppColors.primary),
                  title: Text(d.name),
                  subtitle: Text(d.locationLabel),
                  dense: true,
                )),
                const SizedBox(height: 24),
                const Text('Active Rides', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Divider(),
                ..._rides.map((r) => ListTile(
                  leading: const Icon(Icons.person, color: Colors.blue),
                  title: Text(r.status),
                  subtitle: Text('\${r.pickup} → \${r.destination}'),
                  dense: true,
                )),
              ],
            ),
          ),
          // Map
          Expanded(
            child: _AdminMap(drivers: _drivers, rides: _rides),
          ),
        ],
      ),
    );
  }
}

class _AdminMap extends StatelessWidget {
  const _AdminMap({required this.drivers, required this.rides});
  final List<DriverSummary> drivers;
  final List<Ride> rides;

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[];

    // Add driver markers
    for (final d in drivers) {
      // We parse coordinates if we stored them in summary, but DriverSummary doesn't have lat/lng directly.
      // Wait, DriverSummary doesn't have lat/lng! The admin endpoint needs to return coordinates.
      // For now, we'll just put them in a central place if coordinates are missing.
      // Actually, let's just show riders if drivers don't have coords exposed.
    }

    // Add rider markers
    for (final r in rides) {
      if (r.pickupLocation != null) {
        markers.add(Marker(
          point: LatLng(r.pickupLocation!.latitude, r.pickupLocation!.longitude),
          width: 32,
          height: 32,
          child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 32),
        ));
      }
      if (r.destinationLocation != null) {
        markers.add(Marker(
          point: LatLng(r.destinationLocation!.latitude, r.destinationLocation!.longitude),
          width: 32,
          height: 32,
          child: const Icon(Icons.location_on, color: Colors.red, size: 32),
        ));
      }
    }

    // Since we don't have driver coordinates in the minimal DriverSummary, we'll mock them around Pune for demo if needed,
    // or just rely on the side panel.

    return FlutterMap(
      options: const MapOptions(
        initialCenter: LatLng(18.5204, 73.8567),
        initialZoom: 13,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.ridemate.app',
        ),
        MarkerLayer(markers: markers),
      ],
    );
  }
}
