part of ridemate_ai;

class RiderHome extends StatefulWidget {
  const RiderHome({
    required this.api,
    required this.user,
    required this.onLogout,
    super.key,
  });

  final ApiClient api;
  final AppUser user;
  final VoidCallback onLogout;

  @override
  State<RiderHome> createState() => _RiderHomeState();
}

class _RiderHomeState extends State<RiderHome> {
  final pickupController = TextEditingController(text: 'VIT Pune, Bibwewadi');
  final destinationController = TextEditingController();
  RideLocation? currentLocation;
  RideLocation pickupLocation = const RideLocation(
    latitude: 18.4637,
    longitude: 73.8677,
    label: 'VIT Pune, Bibwewadi',
  );
  RideLocation? destinationLocation;
  int tabIndex = 0;
  bool loading = false;
  bool locationLoading = false;
  bool selectingPickup = false;
  bool isBookingMode = false;
  String message = '';
  List<DriverSummary> drivers = [];
  List<Ride> rides = [];
  List<RideMatch> nearbyMatches = [];
  Ride? activeRide;
  List<Map<String, dynamic>> pendingRequests = [];
  StreamSubscription<Ride>? _rideSubscription;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    loadDrivers();
    loadRides();
    useCurrentLocation(silent: true);
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        loadRides();
        if (activeRide != null && activeRide!.status == 'SEARCHING') {
          loadNearbyMatches();
        }
      }
    });
  }

  @override
  void dispose() {
    _rideSubscription?.cancel();
    // _pollTimer stays active
    pickupController.dispose();
    destinationController.dispose();
    super.dispose();
  }

  Future<void> loadDrivers() async {
    try {
      final data = await widget.api.availableDrivers();
      if (mounted) setState(() => drivers = data);
    } catch (_) {
      if (mounted) setState(() => drivers = []);
    }
  }

  Future<void> loadRides() async {
    try {
      final response = await widget.api.getMyRidesAndRequests();
      final List<Ride> data = response['rides'];
      final List<Map<String, dynamic>> reqs = response['pendingRequests'];
      Ride? nextRide;
      for (final item in data) {
        if (item.status != 'COMPLETED' && item.status != 'CANCELLED') {
          nextRide = item;
          break;
        }
      }
      if (mounted) {
        setState(() {
          rides = data;
          activeRide = nextRide;
          pendingRequests = reqs;
        });
        _subscribeToActiveRide();
      }
    } catch (_) {
      if (mounted) setState(() => rides = []);
    }
  }

  void _subscribeToActiveRide() {
    _rideSubscription?.cancel();
    // _pollTimer stays active
    if (activeRide != null) {
      _rideSubscription = widget.api.sseListenToRide(activeRide!.id).listen((updatedRide) {
        if (mounted) {
          setState(() {
            activeRide = updatedRide;
          });
          loadRides(); // Keep full list in sync
        }
      });
    }
  }

  Future<void> cancelRide() async {
    if (activeRide == null) return;
    try {
      await widget.api.post('/api/rides/${activeRide!.id}/cancel', {});
      setState(() {
        activeRide = null;
        isBookingMode = false;
      });
      loadRides();
    } catch (e) {
      if (mounted) setState(() => message = 'Failed to cancel ride.');
    }
  }

  Future<void> requestRide({DriverSummary? preferred}) async {
    if (destinationLocation == null) {
      setState(() => message = 'Search or pin your destination on the map first.');
      return;
    }
    setState(() {
      loading = true;
      message = '';
    });
    try {
      final data = await widget.api.post('/api/rides/request', {
        'pickup': pickupController.text.trim(),
        'destination': destinationController.text.trim(),
        'pickupLocation': pickupLocation.toJson(),
        'destinationLocation': destinationLocation!.toJson(),
        if (preferred != null) 'driverId': preferred.id,
      });
      if (!mounted) return;
      setState(() {
        activeRide = Ride.fromJson(data['ride'] as Map<String, dynamic>);
        tabIndex = 1;
      });
      await loadRides();
      await loadNearbyMatches();
    } on ApiException catch (error) {
      if (mounted) setState(() => message = error.message);
    } catch (_) {
      if (mounted)
        setState(() => message = 'Ride service is not available yet.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> respondToRequest(String requestId, String action) async {
    try {
      await widget.api.respondToCoriderRequest(requestId, action);
      loadRides();
    } catch (_) {
      if (mounted) setState(() => message = 'Failed to respond');
    }
  }

  void setDestination(RideLocation value) {
    setState(() {
      destinationLocation = value;
      destinationController.text = value.label;
      message = '';
    });
  }

  void setMapPoint(RideLocation location) {
    setState(() {
      if (selectingPickup) {
        pickupLocation = location;
        pickupController.text = location.label;
      } else {
        destinationLocation = location;
        destinationController.text = location.label;
      }
      message = '';
    });
  }

  Future<void> useCurrentLocation({bool silent = false}) async {
    setState(() => locationLoading = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError('Location permission denied');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final location = RideLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        label: 'Current location',
      );
      if (!mounted) return;
      setState(() {
        currentLocation = location;
        pickupLocation = location;
        pickupController.text = location.label;
        message = '';
      });
    } catch (_) {
      if (!mounted || silent) return;
      setState(() => message =
          'Could not read your GPS. You can choose a point directly on the map.');
    } finally {
      if (mounted) setState(() => locationLoading = false);
    }
  }

  Future<void> loadNearbyMatches() async {
    if (activeRide == null || destinationLocation == null) return;
    try {
      final matches = await widget.api.findNearbyRideMatches(
        rideId: activeRide!.id,
        riderId: widget.user.id,
        pickup: pickupLocation,
        destination: destinationLocation!,
      );
      if (mounted) setState(() => nearbyMatches = matches);
    } catch (_) {
      if (mounted) setState(() => nearbyMatches = []);
    }
  }

  Future<void> connectToRide(RideMatch match) async {
    if (activeRide == null) return;
    setState(() {
      loading = true;
      message = '';
    });
    try {
      await widget.api.connectRide(
        myRideId: activeRide!.id,
        targetGroupId: match.rideId,
      );
      setState(() => message = 'Connected to shared ride!');
      await loadRides();
    } on ApiException catch (error) {
      setState(() => message = error.message);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _RiderHomeTab(
        api: widget.api,
        user: widget.user,
        pickupController: pickupController,
        destinationController: destinationController,
        loading: loading,
        message: message,
        drivers: drivers,
        activeRide: activeRide,
        pickupLocation: pickupLocation,
        destinationLocation: destinationLocation,
        currentLocation: currentLocation,
        locationLoading: locationLoading,
        selectingPickup: selectingPickup,
        onSetDestination: setDestination,
        onMapPoint: setMapPoint,
        onUseCurrentLocation: useCurrentLocation,
        onSelectMapMode: (value) => setState(() => selectingPickup = value as bool),
        onBook: requestRide,
        onOpenMap: () => setState(() => tabIndex = 1),
        onRefresh: () {
          loadDrivers();
          loadRides();
        },
        
      ),
      _RiderMapTab(
        activeRide: activeRide,
        user: widget.user,
        api: widget.api,
        pickupLocation: pickupLocation,
        destinationLocation: destinationLocation,
        currentLocation: currentLocation,
        selectingPickup: selectingPickup,
        isBookingMode: isBookingMode,
        onToggleBookingMode: (val) => setState(() => isBookingMode = val),
        matches: nearbyMatches,
        pendingRequests: pendingRequests,
        onRespondRequest: respondToRequest,
        onPointSelected: setMapPoint,
        onSelectMapMode: (value) => setState(() => selectingPickup = value as bool),
        onUseCurrentLocation: useCurrentLocation,
        onConnectMatch: connectToRide,
        onBook: requestRide,
        onCancel: cancelRide,
        
      ),
      _RiderTripsTab(rides: rides, onRefresh: loadRides),
      _RiderProfileTab(
        user: widget.user,
        activeRide: activeRide,
        rides: rides,
        onLogout: widget.onLogout,
      ),
    ];

    return ThemedShell(
      user: widget.user,
      title: 'Rider',
      onLogout: widget.onLogout,
      body: IndexedStack(index: tabIndex, children: tabs),
      bottomBar: NavigationBar(
        selectedIndex: tabIndex,
        onDestinationSelected: (value) => setState(() => tabIndex = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Map'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined), label: 'Activity'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), label: 'Account'),
        ],
      ),
    );
  }
}

class _RiderHomeTab extends StatelessWidget {
  const _RiderHomeTab({
    required this.api,
    required this.user,
    required this.pickupController,
    required this.destinationController,
    required this.loading,
    required this.message,
    required this.drivers,
    required this.activeRide,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.currentLocation,
    required this.locationLoading,
    required this.selectingPickup,
    required this.onSetDestination,
    required this.onMapPoint,
    required this.onUseCurrentLocation,
    required this.onSelectMapMode,
    required this.onBook,
    required this.onOpenMap,
    required this.onRefresh,
  });

  final ApiClient api;
  final AppUser user;
  final TextEditingController pickupController;
  final TextEditingController destinationController;
  final bool loading;
  final String message;
  final List<DriverSummary> drivers;
  final Ride? activeRide;
  final RideLocation pickupLocation;
  final RideLocation? destinationLocation;
  final RideLocation? currentLocation;
  final bool locationLoading;
  final bool selectingPickup;
  final ValueChanged<RideLocation> onSetDestination;
  final ValueChanged<RideLocation> onMapPoint;
  final Future<void> Function({bool silent}) onUseCurrentLocation;
  final ValueChanged<bool> onSelectMapMode;
  final Future<void> Function({DriverSummary? preferred}) onBook;
  final VoidCallback onOpenMap;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          if (!wide) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 110),
              children: _mobileContent(),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 110),
            children: _webContent(),
          );
        },
      ),
    );
  }

  List<Widget> _mobileContent() => [
        _RideGreeting(user: user, driversOnline: drivers.length),
        const SizedBox(height: 16),
        _DestinationPanel(
          pickupController: pickupController,
          destinationController: destinationController,
          pickupLocation: pickupLocation,
          destinationLocation: destinationLocation,
          loading: loading,
          locationLoading: locationLoading,
          api: api,
          onLocationSelected: onSetDestination,
          onUseCurrentLocation: () => onUseCurrentLocation(),
          onBook: onBook,
        ),
        _message(),
        const SizedBox(height: 16),
        _MapModeSwitch(
          selectingPickup: selectingPickup,
          onChanged: onSelectMapMode,
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 258,
          child: InteractiveRideMap(
            pickup: pickupLocation,
            destination: destinationLocation,
            currentLocation: currentLocation,
            driverLocation: activeRide?.driverProfile != null && activeRide!.driverProfile!['last_latitude'] != null
                ? RideLocation(
                    latitude: double.tryParse(activeRide!.driverProfile!['last_latitude'].toString()) ?? 0,
                    longitude: double.tryParse(activeRide!.driverProfile!['last_longitude'].toString()) ?? 0,
                    label: 'Driver',
                  )
                : null,
            selectingPickup: selectingPickup,
            onPointSelected: onMapPoint,
            onUseCurrentLocation: () => onUseCurrentLocation(),
            compact: true,
          ),
        ),
        const SizedBox(height: 18),
        _RecentPlaces(onSetDestination: onSetDestination),
        const SizedBox(height: 18),
        _TravelBenefits(),
        const SizedBox(height: 20),
        const SectionHeading(title: 'For you', action: 'See all'),
        const SizedBox(height: 10),
        _ServiceGrid(onOpenMap: onOpenMap),
        const SizedBox(height: 22),
        SectionHeading(
            title: 'Nearby',
            action: '${drivers.length} cars',
            onAction: onRefresh),
        const SizedBox(height: 10),
        _NearbyDrivers(drivers: drivers, onBook: onBook),
        const SizedBox(height: 22),
        const SectionHeading(title: 'Ride as you like it'),
        const SizedBox(height: 10),
        const _RideChoices(),
        if (activeRide != null) ...[
          const SizedBox(height: 18),
          const SectionHeading(title: 'Your active ride'),
          const SizedBox(height: 10),
          RideSummaryCard(ride: activeRide!),
        ],
        const SizedBox(height: 18),
        const SafetyToolkitCard(),
      ];

  List<Widget> _webContent() => [
        _RideGreeting(user: user, driversOnline: drivers.length),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Column(
                children: [
                  _DestinationPanel(
                    pickupController: pickupController,
                    destinationController: destinationController,
                    pickupLocation: pickupLocation,
                    destinationLocation: destinationLocation,
                    loading: loading,
                    locationLoading: locationLoading,
                    api: api,
                    onLocationSelected: onSetDestination,
                    onUseCurrentLocation: () => onUseCurrentLocation(),
                    onBook: onBook,
                  ),
                  _message(),
                  const SizedBox(height: 18),
                  _TravelBenefits(),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
                flex: 5,
                child: Column(
                  children: [
                    _MapModeSwitch(
                      selectingPickup: selectingPickup,
                      onChanged: onSelectMapMode,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 272,
                      child: InteractiveRideMap(
                        pickup: pickupLocation,
                        destination: destinationLocation,
                        currentLocation: currentLocation,
                        driverLocation: activeRide?.driverProfile != null && activeRide!.driverProfile!['last_latitude'] != null
                            ? RideLocation(
                                latitude: double.tryParse(activeRide!.driverProfile!['last_latitude'].toString()) ?? 0,
                                longitude: double.tryParse(activeRide!.driverProfile!['last_longitude'].toString()) ?? 0,
                                label: 'Driver',
                              )
                            : null,
                        selectingPickup: selectingPickup,
                        onPointSelected: onMapPoint,
                        onUseCurrentLocation: () => onUseCurrentLocation(),
                      ),
                    ),
                  ],
                )),
          ],
        ),
        const SizedBox(height: 22),
        _RecentPlaces(onSetDestination: onSetDestination),
        const SizedBox(height: 22),
        const SectionHeading(title: 'For you', action: 'See all'),
        const SizedBox(height: 10),
        _ServiceGrid(onOpenMap: onOpenMap),
        const SizedBox(height: 22),
        SectionHeading(
            title: 'Nearby',
            action: '${drivers.length} drivers',
            onAction: onRefresh),
        const SizedBox(height: 10),
        _NearbyDrivers(drivers: drivers, onBook: onBook),
        const SizedBox(height: 22),
        const SectionHeading(title: 'Ride as you like it'),
        const SizedBox(height: 10),
        const _RideChoices(),
        if (activeRide != null) ...[
          const SizedBox(height: 18),
          const SectionHeading(title: 'Your active ride'),
          const SizedBox(height: 10),
          RideSummaryCard(ride: activeRide!),
        ],
        const SizedBox(height: 18),
        const SafetyToolkitCard(),
      ];

  Widget _message() => message.isEmpty
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(message,
                style: const TextStyle(
                    color: AppColors.danger, fontWeight: FontWeight.w700)),
          ),
        );
}

class _RideGreeting extends StatelessWidget {
  const _RideGreeting({required this.user, required this.driversOnline});

  final AppUser user;
  final int driversOnline;

  @override
  Widget build(BuildContext context) {
    final name = user.fullName.split(' ').first;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Good morning',
                  style: TextStyle(fontSize: 12, color: AppColors.muted)),
              const SizedBox(height: 3),
              Text('Where to, $name?',
                  style: const TextStyle(
                      fontSize: 25, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 23,
              backgroundColor: AppColors.primary,
              child: Text(name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                      color: AppColors.bg, fontWeight: FontWeight.w800)),
            ),
            Positioned(
              right: -1,
              top: -1,
              child: Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.bg, width: 2),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DestinationPanel extends StatefulWidget {
  const _DestinationPanel({
    required this.pickupController,
    required this.destinationController,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.loading,
    required this.locationLoading,
    required this.api,
    required this.onLocationSelected,
    required this.onUseCurrentLocation,
    required this.onBook,
  });

  final TextEditingController pickupController;
  final TextEditingController destinationController;
  final RideLocation pickupLocation;
  final RideLocation? destinationLocation;
  final bool loading;
  final bool locationLoading;
  final ApiClient api;
  final ValueChanged<RideLocation> onLocationSelected;
  final VoidCallback onUseCurrentLocation;
  final Future<void> Function({DriverSummary? preferred}) onBook;

  @override
  State<_DestinationPanel> createState() => _DestinationPanelState();
}

class _DestinationPanelState extends State<_DestinationPanel> {
  List<RideLocation> suggestions = [];
  bool searching = false;

  Future<void> searchDestination() async {
    final query = widget.destinationController.text.trim();
    if (query.length < 2) return;
    setState(() => searching = true);
    try {
      final results = await widget.api.searchLocations(query);
      if (mounted) setState(() => suggestions = results);
    } catch (_) {
      if (mounted) setState(() => suggestions = []);
    } finally {
      if (mounted) setState(() => searching = false);
    }
  }

  void selectLocation(RideLocation location) {
    widget.onLocationSelected(location);
    setState(() => suggestions = []);
  }

  @override
  Widget build(BuildContext context) {
    return CardSurface(
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.my_location_rounded,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(widget.pickupLocation.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              TextButton.icon(
                onPressed: widget.locationLoading
                    ? null
                    : widget.onUseCurrentLocation,
                icon: const Icon(Icons.gps_fixed_rounded, size: 15),
                label: Text(widget.locationLoading ? 'Locating' : 'Use GPS'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: widget.destinationController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => searchDestination(),
            decoration: InputDecoration(
              hintText: 'Search destination...',
              prefixIcon:
                  const Icon(Icons.search_rounded, color: AppColors.primary),
              suffixIcon: IconButton(
                tooltip: 'Search location',
                onPressed: searching ? null : searchDestination,
                icon: searching
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.arrow_forward_rounded),
              ),
            ),
          ),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...suggestions.take(3).map(
                  (location) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.place_outlined,
                        color: AppColors.warm, size: 20),
                    title: Text(location.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                    onTap: () => selectLocation(location),
                  ),
                ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.electric_rickshaw_rounded,
                          color: AppColors.bg, size: 18),
                      SizedBox(width: 8),
                      Text('Shared Auto',
                          style: TextStyle(
                              color: AppColors.bg,
                              fontSize: 12,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.loading ? null : () => widget.onBook(),
                  icon: const Icon(Icons.directions_car_rounded, size: 17),
                  label: Text(widget.loading ? 'Finding...' : 'Find ride'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 42),
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: AppColors.line),
                  ),
                ),
              ),
            ],
          ),
          Offstage(
              offstage: true,
              child: TextField(controller: widget.pickupController)),
        ],
      ),
    );
  }
}

class _MapModeSwitch extends StatelessWidget {
  const _MapModeSwitch({required this.selectingPickup, required this.onChanged});

  final bool selectingPickup;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          _mapModeButton('Set pickup', selectingPickup, () => onChanged(true)),
          _mapModeButton('Set destination', !selectingPickup, () => onChanged(false)),
        ],
      ),
    );
  }

  Widget _mapModeButton(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: selected ? AppColors.bg : AppColors.muted,
          backgroundColor: selected ? AppColors.primary : Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class _RecentPlaces extends StatelessWidget {
  const _RecentPlaces({required this.onSetDestination});

  final ValueChanged<RideLocation> onSetDestination;

  @override
  Widget build(BuildContext context) {
    return CardSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('RECENT',
              style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 7),
          RecentPlaceTile(
            icon: Icons.apartment_rounded,
            title: 'Swargate',
            subtitle: 'Pune, Maharashtra',
            onTap: () => onSetDestination(const RideLocation(
              latitude: 18.5018,
              longitude: 73.8636,
              label: 'Swargate Bus Stand',
            )),
          ),
          const Divider(color: AppColors.line),
          RecentPlaceTile(
            icon: Icons.home_rounded,
            title: 'Katraj',
            subtitle: 'Near VIT Pune campus',
            onTap: () => onSetDestination(const RideLocation(
              latitude: 18.4575,
              longitude: 73.8652,
              label: 'Katraj, Pune',
            )),
          ),
        ],
      ),
    );
  }
}

class _TravelBenefits extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 102,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF123321),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF24573B)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.cloudy_snowing, color: AppColors.warm),
                Spacer(),
                Text('28°C',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                Text('Clear for a ride',
                    style: TextStyle(fontSize: 10, color: AppColors.muted)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 102,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2412),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF5D4B1A)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_offer_rounded, color: AppColors.warm),
                    Spacer(),
                    Text('20% OFF',
                        style: TextStyle(
                            color: AppColors.warm,
                            fontSize: 9,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
                Spacer(),
                Text('Use RIDE20',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                Text('On your next shared ride',
                    style: TextStyle(fontSize: 10, color: AppColors.muted)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ServiceGrid extends StatelessWidget {
  const _ServiceGrid({required this.onOpenMap});
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    const services = [
      (Icons.electric_rickshaw_rounded, 'Auto', AppColors.warm, null),
      (Icons.local_taxi_rounded, 'Trip', Color(0xFF67A0FF), '20%'),
      (Icons.directions_car_rounded, 'Intercity', Color(0xFFB071FF), null),
      (Icons.directions_bus_rounded, 'Bus & Train', Color(0xFF70DBCB), 'Promo'),
      (Icons.key_rounded, 'Rentals', Color(0xFFFF7088), null),
      (Icons.volunteer_activism_rounded, 'Seniors', Color(0xFFFF9B5F), null),
      (Icons.inventory_2_rounded, 'Parcel', Color(0xFFF2C744), '25%'),
      (Icons.bolt_rounded, 'Teens', Color(0xFF73D17E), null),
    ];
    return Wrap(
      spacing: 7,
      runSpacing: 14,
      alignment: WrapAlignment.spaceBetween,
      children: services
          .map((service) => ServiceShortcut(
                icon: service.$1,
                label: service.$2,
                color: service.$3,
                badge: service.$4,
                onTap: service.$2 == 'Intercity' ? onOpenMap : null,
              ))
          .toList(),
    );
  }
}

class _NearbyDrivers extends StatelessWidget {
  const _NearbyDrivers({required this.drivers, required this.onBook});
  final List<DriverSummary> drivers;
  final Future<void> Function({DriverSummary? preferred}) onBook;

  @override
  Widget build(BuildContext context) {
    if (drivers.isEmpty) {
      return const EmptyStateCard(
        title: 'Searching nearby',
        subtitle: 'Drivers will appear here when they come online.',
      );
    }
    return SizedBox(
      height: 172,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: drivers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final driver = drivers[index];
          return NearbyDriverCard(
            driver: driver,
            onBook: () => onBook(preferred: driver),
          );
        },
      ),
    );
  }
}

class _RideChoices extends StatelessWidget {
  const _RideChoices();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 142,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF133222),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF28593A)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                    height: 50,
                    child: VehicleArtwork(type: 'Auto', height: 50)),
                Spacer(),
                Text('Book Auto',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                Text('Everyday commute, made easy',
                    style: TextStyle(fontSize: 10, color: AppColors.primary)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 142,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF191D36),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF343B6A)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                    height: 50, child: VehicleArtwork(type: 'Car', height: 50)),
                Spacer(),
                Text('Intercity',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                Text('Travel outside town with ease',
                    style: TextStyle(fontSize: 10, color: Color(0xFF92A3FF))),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
