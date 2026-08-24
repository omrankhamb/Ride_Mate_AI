part of ridemate_ai;

class _DriverLiveTab extends StatelessWidget {
  const _DriverLiveTab({
    required this.user,
    required this.online,
    required this.currentLocation,
    required this.currentRides,
    this.groups = const [],
    required this.onToggleOnline,
    required this.onRideAction,
  });

  final AppUser user;
  final bool online;
  final RideLocation? currentLocation;
  final List<Ride> currentRides;
  final List<List<Ride>> groups;
  final ValueChanged<bool> onToggleOnline;
  final Future<void> Function(List<Ride> rides, String action, String? otp) onRideAction;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Full Screen Interactive Map with Auto, Pickup, Drop Pins & Polyline
        Positioned.fill(
          child: InteractiveRideMap(
            rides: currentRides,
            currentLocation: currentLocation,
            driverLocation: currentLocation,
            selectingPickup: false,
            onPointSelected: (_) {},
            onUseCurrentLocation: () {},
          ),
        ),

        // 2. Online / Offline Floating Switch at top-left
        Positioned(
          top: 14,
          left: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.line),
              boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: online ? AppColors.primary : AppColors.muted,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  online ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: online ? AppColors.primary : AppColors.muted,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 6),
                Switch(
                  value: online,
                  activeThumbColor: AppColors.primary,
                  onChanged: onToggleOnline,
                ),
              ],
            ),
          ),
        ),

        // 3. Navigation Status Badge at top-right
        if (online && currentRides.isNotEmpty)
          Positioned(
            top: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.navigation, color: AppColors.bg, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    currentRides[0].status == 'ACCEPTED' ? 'Head to Pickup' : 'En Route to Drop',
                    style: const TextStyle(color: AppColors.bg, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

        // 4. Clean Bottom Floating Navigation Card (Zero lag, always visible!)
        if (online)
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: currentRides.isNotEmpty
                ? Container(
                    constraints: const BoxConstraints(maxHeight: 250),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 14, offset: Offset(0, 4))],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: DriverRideActionCard(
                          rides: currentRides,
                          onAction: onRideAction,
                        ),
                      ),
                    ),
                  )
                : (groups.isNotEmpty
                    ? Container(
                        constraints: const BoxConstraints(maxHeight: 320),
                        decoration: BoxDecoration(
                          color: AppColors.card.withValues(alpha: 0.98),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.line),
                          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 16, offset: Offset(0, 4))],
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Incoming Requests (${groups.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                                    child: const Text('Live', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ...groups.map((group) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: DriverRideActionCard(
                                  rides: group,
                                  onAction: onRideAction,
                                ),
                              )),
                            ],
                          ),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.card.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.line),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.radar, color: AppColors.primary, size: 20),
                            SizedBox(width: 10),
                            Text('Waiting for Shared Ride Requests...', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      )),
          ),
      ],
    );
  }
}
