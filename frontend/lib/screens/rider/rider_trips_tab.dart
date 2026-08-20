part of ridemate_ai;

class _RiderTripsTab extends StatelessWidget {
  const _RiderTripsTab({
    required this.rides,
    required this.onRefresh,
  });

  final List<Ride> rides;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
        children: [
          const _SectionTitle(
            title: 'Trips',
            subtitle: 'Recent rides and their status.',
          ),
          const SizedBox(height: 12),
          if (rides.isEmpty)
            const EmptyStateCard(
              title: 'No trips yet',
              subtitle: 'Your completed and active rides will appear here.',
            )
          else
            ...rides.map(
              (ride) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: RideHistoryCard(
                  ride: ride,
                  onTap: () => showRideDetails(context, ride),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
