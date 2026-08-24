part of ridemate_ai;

class _DriverRequestsTab extends StatelessWidget {
  const _DriverRequestsTab({
    required this.groups,
    required this.onRideAction,
    required this.onRefresh,
  });

  final List<List<Ride>> groups;
  final Future<void> Function(List<Ride> rides, String action, String? otp) onRideAction;
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
            subtitle: 'Incoming shared-ride requests.',
          ),
          const SizedBox(height: 12),
          if (groups.isEmpty)
            const EmptyStateCard(
              title: 'No ride requests yet',
              subtitle: 'Rider requests will show here when they book your route.',
            )
          else
            ...groups.map(
              (group) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DriverRideActionCard(
                  rides: group,
                  onAction: onRideAction,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
