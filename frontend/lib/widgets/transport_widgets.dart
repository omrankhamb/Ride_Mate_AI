part of ridemate_ai;

class SectionHeading extends StatelessWidget {
  const SectionHeading({
    required this.title,
    this.action,
    this.onAction,
    super.key,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title,
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        ),
        if (action != null)
          TextButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.arrow_forward_rounded, size: 15),
            label: Text(action!),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
      ],
    );
  }
}

class VehicleArtwork extends StatelessWidget {
  const VehicleArtwork({
    required this.type,
    this.height = 74,
    this.compact = false,
    super.key,
  });

  final String type;
  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isAuto = type.toLowerCase().contains('auto') ||
        type.toLowerCase().contains('rickshaw');
    final asset = isAuto
        ? 'assets/images/auto_rickshaw.jpg'
        : 'assets/images/blue_car.jpg';

    return ClipRRect(
      borderRadius: BorderRadius.circular(compact ? 12 : 16),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: isAuto ? const Color(0xFF34310F) : const Color(0xFF12293E),
            child: Icon(
              isAuto ? Icons.electric_rickshaw_rounded : Icons.directions_car,
              color: isAuto ? AppColors.warm : AppColors.primary,
              size: compact ? 24 : 36,
            ),
          ),
        ),
      ),
    );
  }
}

class ServiceShortcut extends StatelessWidget {
  const ServiceShortcut({
    required this.icon,
    required this.label,
    required this.color,
    this.badge,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color color;
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.19),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: color.withValues(alpha: 0.58)),
                  ),
                  child: Icon(icon, color: color, size: 25),
                ),
                if (badge != null)
                  Positioned(
                    right: -9,
                    top: -7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(badge!,
                          style: const TextStyle(
                              color: AppColors.bg,
                              fontSize: 8,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 7),
            Text(label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: AppColors.ink)),
          ],
        ),
      ),
    );
  }
}

class RecentPlaceTile extends StatelessWidget {
  const RecentPlaceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.cardAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.warm, size: 19),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.muted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: AppColors.mint,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_rounded,
                  size: 16, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class NearbyDriverCard extends StatelessWidget {
  const NearbyDriverCard({
    required this.driver,
    required this.onBook,
    super.key,
  });

  final DriverSummary driver;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final isAuto = driver.vehicleType.toLowerCase().contains('auto') ||
        driver.vehicleType.toLowerCase().contains('rickshaw');
    return InkWell(
      onTap: onBook,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 184,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 64,
              child: VehicleArtwork(type: driver.vehicleType, height: 64),
            ),
            const SizedBox(height: 9),
            Text(driver.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(isAuto ? 'Shared auto' : driver.vehicleType,
                style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            const Spacer(),
            Row(
              children: [
                Text('${driver.etaMinutes} min',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800)),
                const Spacer(),
                const Icon(Icons.star_rounded, color: AppColors.warm, size: 15),
                Text(driver.rating.toStringAsFixed(1),
                    style:
                        const TextStyle(fontSize: 11, color: AppColors.muted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SafetyToolkitCard extends StatelessWidget {
  const SafetyToolkitCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: .4)),
            ),
            child: const Icon(Icons.shield_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Safety toolkit',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                SizedBox(height: 3),
                Text('SOS · Live sharing · Trusted contacts',
                    style: TextStyle(fontSize: 10, color: AppColors.muted)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    );
  }
}
