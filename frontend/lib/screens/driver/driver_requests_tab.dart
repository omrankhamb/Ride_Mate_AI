part of ridemate_ai;

class _DriverRequestsTab extends StatelessWidget {
  const _DriverRequestsTab({
    required this.rides,
    required this.otpController,
    required this.onRideAction,
    required this.onRefresh,
  });

  final List<Ride> rides;
  final TextEditingController otpController;
  final Future<void> Function(Ride ride, String action, String? otp) onRideAction;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
        children: [
          const _SectionTitle(
            title: 'Requests',
            subtitle: 'Incoming ride cards with quick actions.',
          ),
          const SizedBox(height: 12),
          if (rides.isEmpty)
            const EmptyStateCard(
              title: 'No ride requests yet',
              subtitle:
                  'Rider requests will show here when they book your route.',
            )
          else
            ...rides.map(
              (ride) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DriverRideActionCard(
                  ride: ride,
                  otpController: otpController,
                  onAction: onRideAction,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
