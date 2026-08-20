part of ridemate_ai;

class _DriverProfileTab extends StatelessWidget {
  const _DriverProfileTab({
    required this.user,
    required this.online,
    required this.onLogout,
  });

  final AppUser user;
  final bool online;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
      children: [
        const _SectionTitle(
          title: 'Driver account',
          subtitle: 'Vehicle, earnings, and driver preferences.',
        ),
        const SizedBox(height: 12),
        ProfileHeaderCard(
          name: user.fullName,
          email: user.email,
          role: 'Driver',
          status: online ? 'ONLINE' : 'OFFLINE',
          icon: Icons.local_taxi,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Expanded(child: MetricCard(label: 'Rating', value: '4.8')),
            const SizedBox(width: 10),
            Expanded(
                child: MetricCard(
                    label: 'Status', value: online ? 'Ready' : 'Paused')),
          ],
        ),
        const SizedBox(height: 12),
        CardSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SettingsTile(
                icon: Icons.confirmation_number_outlined,
                title: 'Vehicle',
                value: 'Shared Auto',
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
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.person_rounded),
                label: const Text('Open rider demo'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
