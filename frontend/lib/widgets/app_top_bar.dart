part of ridemate_ai;

class AppTopBar extends StatelessWidget {
  const AppTopBar({
    required this.title,
    required this.subtitle,
    required this.onLogout,
    super.key,
  });

  final String title;
  final String subtitle;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          const AppBrandMark(compact: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title == 'Driver' ? 'Drive with RideMate' : 'RideMate AI',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  title == 'Driver'
                      ? 'Driver mode · $subtitle'
                      : 'Your smart commute · $subtitle',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: title == 'Driver' ? 'Switch to rider' : 'Switch to driver',
            onPressed: onLogout,
            icon: Icon(title == 'Driver'
                ? Icons.person_rounded
                : Icons.drive_eta_rounded),
          ),
        ],
      ),
    );
  }
}

class AppBrandMark extends StatelessWidget {
  const AppBrandMark({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 42.0 : 52.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 20, offset: Offset(0, 10)),
        ],
      ),
      child: const Icon(Icons.route_rounded, color: AppColors.bg),
    );
  }
}
