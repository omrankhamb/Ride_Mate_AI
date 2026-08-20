part of ridemate_ai;

class AuthHeroPanel extends StatelessWidget {
  const AuthHeroPanel({required this.compact, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? null : double.infinity,
      padding: EdgeInsets.all(compact ? 18 : 26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: const Color(0xFFF3FBF7),
        border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 30, offset: Offset(0, 18)),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const AppBrandMark(),
                const Spacer(),
                StatusPill(text: 'NO KYC', color: AppColors.accentDark),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'RideMate AI',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
            ),
            const SizedBox(height: 10),
            const Text(
              'A clean shared auto app for riders and drivers with live map, pickup distance, endpoint destination, and OTP ride start.',
              style:
                  TextStyle(color: AppColors.muted, height: 1.5, fontSize: 15),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: const [
                FeatureChip(icon: Icons.map_outlined, label: 'Live map'),
                FeatureChip(
                    icon: Icons.social_distance_outlined, label: '700m match'),
                FeatureChip(icon: Icons.pin_outlined, label: 'OTP start'),
                FeatureChip(
                    icon: Icons.local_taxi_outlined, label: 'Driver flow'),
              ],
            ),
            SizedBox(height: compact ? 18 : 24),
            RidePhoneShowcase(compact: compact),
          ],
        ),
      ),
    );
  }
}
