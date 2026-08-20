part of ridemate_ai;

class _RiderMapTab extends StatelessWidget {
  const _RiderMapTab({
    Key? key,
    this.activeRide,
    required this.user,
    required this.api,
    required this.pickupLocation,
    this.destinationLocation,
    this.currentLocation,
    required this.selectingPickup,
    required this.isBookingMode,
    required this.onToggleBookingMode,
    required this.matches,
    required this.onPointSelected,
    required this.onSelectMapMode,
    required this.onUseCurrentLocation,
    required this.onRefresh,
    this.onConnectMatch,
    this.onBook,
    this.onCancel,
    this.pendingRequests = const [],
    this.onRespondRequest,
  }) : super(key: key);

  final Ride? activeRide;
  final AppUser user;
  final ApiClient api;
  final RideLocation pickupLocation;
  final RideLocation? destinationLocation;
  final RideLocation? currentLocation;
  final bool selectingPickup;
  final bool isBookingMode;
  final ValueChanged<bool> onToggleBookingMode;
  final List<RideMatch> matches;
  final ValueChanged<RideLocation> onPointSelected;
  final ValueChanged<bool> onSelectMapMode;
  final Future<void> Function({bool silent}) onUseCurrentLocation;
  final VoidCallback onRefresh;
  final ValueChanged<RideMatch>? onConnectMatch;
  final Future<void> Function({DriverSummary? preferred})? onBook;
  final VoidCallback? onCancel;
  final List<Map<String, dynamic>> pendingRequests;
  final void Function(int, String)? onRespondRequest;

  @override
  Widget build(BuildContext context) {
    if (!isBookingMode && activeRide == null) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, ${user.fullName.split(' ').first}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Where to go?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => onToggleBookingMode(true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.cardAlt,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.search, color: AppColors.muted),
                      SizedBox(width: 12),
                      Text('Search destination', style: TextStyle(color: AppColors.muted, fontSize: 16)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  _ServiceIcon(icon: Icons.electric_rickshaw, label: 'Shared Auto', active: true),
                  _ServiceIcon(icon: Icons.motorcycle, label: 'Bike', active: false),
                  _ServiceIcon(icon: Icons.directions_transit, label: 'Transit', active: false),
                  _ServiceIcon(icon: Icons.local_shipping, label: 'Package', active: false),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                'Suggestions for you',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 16),
              const _RecentTile(icon: Icons.work, title: 'Work', subtitle: 'Tech Park, Block B'),
              const SizedBox(height: 12),
              const _RecentTile(icon: Icons.home, title: 'Home', subtitle: 'Green Valley Apartments'),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        InteractiveRideMap(
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
          onPointSelected: onPointSelected,
          onUseCurrentLocation: () => onUseCurrentLocation(silent: false),
        ),
        if (activeRide == null)
          Positioned(
            top: 48,
            left: 16,
            child: GestureDetector(
              onTap: () => onToggleBookingMode(false),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.card,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: AppColors.ink),
              ),
            ),
          ),
        if (activeRide == null && destinationLocation == null)
          Positioned(
            top: 48,
            left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(20)),
                child: const Text('Tap map to set destination', style: TextStyle(color: AppColors.bg)),
              ),
            ),
          ),
        DraggableScrollableSheet(
          initialChildSize: activeRide != null ? 0.45 : 0.4,
          minChildSize: 0.2,
          maxChildSize: 0.8,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2)],
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.line,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // STATE 1: Booking Selection
                  if (activeRide == null) ...[
                    DetailRow(
                      label: 'Pickup',
                      value: pickupLocation.label,
                      highlight: true,
                    ),
                    const SizedBox(height: 12),
                    DetailRow(
                      label: 'Destination',
                      value: destinationLocation?.label ?? 'Select destination on map',
                      highlight: true,
                    ),
                    const SizedBox(height: 16),
                    _MapModeSwitch(
                      selectingPickup: selectingPickup,
                      onChanged: onSelectMapMode,
                    ),
                    const SizedBox(height: 24),
                    if (destinationLocation != null)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.bg,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => onBook?.call(),
                        child: const Text('Confirm Ride', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                  ] 
                  
                  // STATE 2: Searching / Finding Captain
                  else if (activeRide!.status == 'SEARCHING') ...[
                    const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'Finding your captain...',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        'This might take a few seconds',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (pendingRequests.isNotEmpty) ...[
                      const Text('Co-rider Requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      ...pendingRequests.map((req) => CardSurface(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.person, color: AppColors.primary),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text('${req['senderName']} wants to share a ride with you!', style: const TextStyle(fontWeight: FontWeight.bold))),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                DetailRow(label: 'Pickup', value: req['pickup']),
                                DetailRow(label: 'Destination', value: req['destination']),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                                        onPressed: () => onRespondRequest?.call(req['id'], 'reject'),
                                        child: const Text('Decline'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.bg),
                                        onPressed: () => onRespondRequest?.call(req['id'], 'accept'),
                                        child: const Text('Accept'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )),
                      const SizedBox(height: 16),
                    ],
                    if (matches.isNotEmpty) ...[
                      const Text('Found nearby co-riders!', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...matches.map((m) => _MatchCard(
                            match: m,
                            onConnect: () => onConnectMatch?.call(m),
                          )),
                    ],
                    const SizedBox(height: 24),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                      onPressed: () => onCancel?.call(),
                      child: const Text('Cancel Ride'),
                    )
                  ]
                  
                  // STATE 3: Ride Accepted / Started
                  else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ride Status: ${activeRide!.status}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink),
                        ),
                        if (activeRide!.status != 'COMPLETED')
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, padding: EdgeInsets.zero, minimumSize: const Size(60, 30)),
                            onPressed: () => onCancel?.call(),
                            child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                          )
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (activeRide!.driver != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.cardAlt, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: AppColors.soft,
                              child: Icon(Icons.person, color: AppColors.muted),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(activeRide!.driver!.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text('${activeRide!.driverProfile?['vehicleType'] ?? "Unknown"} • ${activeRide!.driverProfile?['vehicleNumber'] ?? ""}'.trim(), style: const TextStyle(color: AppColors.muted)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
                          Text(
                            activeRide!.otp,
                            style: const TextStyle(fontSize: 32, letterSpacing: 4, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (activeRide!.poolGroupId != null)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.bg,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                poolGroupId: activeRide!.poolGroupId!,
                                api: api,
                                user: user,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text('Chat with Co-rider', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ServiceIcon extends StatelessWidget {
  const _ServiceIcon({required this.icon, required this.label, required this.active});
  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: active ? AppColors.mint : AppColors.cardAlt,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: active ? AppColors.primary : AppColors.muted, size: 32),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: active ? AppColors.ink : AppColors.muted, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}

class _RecentTile extends StatelessWidget {
  const _RecentTile({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.cardAlt, shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.muted),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: AppColors.muted),
      ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match, required this.onConnect});
  final RideMatch match;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    return CardSurface(
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.soft,
            child: Icon(Icons.person, color: AppColors.muted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(match.riderName, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${match.pickupDistanceMeters}m away', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.bg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: onConnect,
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }
}
