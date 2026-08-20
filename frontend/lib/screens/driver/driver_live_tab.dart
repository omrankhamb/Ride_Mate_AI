part of ridemate_ai;

class _DriverLiveTab extends StatelessWidget {
  const _DriverLiveTab({
    required this.user,
    required this.online,
    required this.loading,
    required this.rides,
    required this.otpController,
    required this.driverLat,
    required this.driverLng,
    required this.onToggleOnline,
    required this.onRefresh,
    required this.onRideAction,
  });

  final AppUser user;
  final bool online;
  final bool loading;
  final List<Ride> rides;
  final TextEditingController otpController;
  final double driverLat;
  final double driverLng;
  final Future<void> Function(bool value) onToggleOnline;
  final VoidCallback onRefresh;
  final Future<void> Function(Ride ride, String action, String? otp) onRideAction;

  List<Ride> get activeRides {
    return rides.where((r) => r.status != 'COMPLETED' && r.status != 'CANCELLED').toList();
  }

  @override
  Widget build(BuildContext context) {
    final firstName = user.fullName.split(' ').first;
    final currentRides = activeRides;
    final primaryRide = currentRides.isEmpty ? null : currentRides.first;

    // Determine map pins based on primary ride status
    RideLocation? targetLocation;
    if (primaryRide != null) {
      if (primaryRide.status == 'ACCEPTED') {
        targetLocation = RideLocation(latitude: 0, longitude: 0, label: primaryRide.pickup);
      } else if (primaryRide.status == 'STARTED') {
        targetLocation = RideLocation(latitude: 0, longitude: 0, label: primaryRide.destination);
      }
    }

    return Stack(
      children: [
        InteractiveRideMap(
          pickup: targetLocation, // Render target as pickup for polyline
          destination: null,
          currentLocation: RideLocation(latitude: driverLat, longitude: driverLng, label: 'You'),
          driverLocation: null,
          selectingPickup: false,
          onPointSelected: (_) {},
          onUseCurrentLocation: () {},
        ),
        Positioned(
          top: 48,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                child: Text(
                  online ? 'Online' : 'Offline',
                  style: TextStyle(color: online ? AppColors.primary : AppColors.muted, fontWeight: FontWeight.bold),
                ),
              ),
              Switch(
                value: online,
                onChanged: loading ? null : (val) => onToggleOnline(val),
                activeColor: AppColors.primary,
              ),
            ],
          ),
        ),
        DraggableScrollableSheet(
          initialChildSize: currentRides.isEmpty ? 0.2 : 0.45,
          minChildSize: 0.15,
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
                  if (currentRides.isEmpty) ...[
                    Center(
                      child: Text(
                        online ? 'Waiting for requests...' : 'Go online to start receiving rides',
                        style: const TextStyle(color: AppColors.muted, fontSize: 16),
                      ),
                    ),
                  ] else ...[
                    Text('Active Rides (\${currentRides.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink)),
                    const SizedBox(height: 12),
                    ...currentRides.map((ride) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: DriverRideActionCard(
                            ride: ride,
                            onAction: onRideAction,
                          ),
                        )),
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
