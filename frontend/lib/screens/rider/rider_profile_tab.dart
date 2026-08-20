part of ridemate_ai;

class _RiderProfileTab extends StatelessWidget {
  const _RiderProfileTab({
    required this.user,
    required this.activeRide,
    required this.rides,
    required this.onLogout,
  });

  final AppUser user;
  final Ride? activeRide;
  final List<Ride> rides;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
      children: [
        const _SectionTitle(
          title: 'Account',
          subtitle: 'Ride preferences, safety, and app settings.',
        ),
        const SizedBox(height: 12),
        ProfileHeaderCard(
          name: user.fullName,
          email: user.email,
          role: 'Rider',
          status: activeRide == null ? 'READY' : activeRide!.status,
          icon: Icons.person_pin_circle_outlined,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: MetricCard(label: 'Trips', value: '${rides.length}')),
            const SizedBox(width: 10),
            Expanded(
              child: MetricCard(
                label: 'Active',
                value: activeRide == null ? 'None' : activeRide!.status,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        CardSurface(
          child: Column(
            children: [
              const SettingsTile(
                icon: Icons.notifications_active_outlined,
                title: 'Ride alerts',
                value: 'On',
              ),
              const SettingsTile(
                icon: Icons.payments_outlined,
                title: 'Payment mode',
                value: 'Cash',
              ),
              const SettingsTile(
                icon: Icons.support_agent_outlined,
                title: 'Support',
                value: 'MVP',
              ),
              const SizedBox(height: 6),
              ElevatedButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.drive_eta_rounded),
                label: const Text('Open driver demo'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
