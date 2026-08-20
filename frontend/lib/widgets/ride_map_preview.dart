part of ridemate_ai;

class RideMapPreview extends StatelessWidget {
  const RideMapPreview({required this.ride, super.key});

  final Ride? ride;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF172638), Color(0xFF101923)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 22, offset: Offset(0, 12)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: SoftMapPainter())),
            Positioned(
              left: 20,
              top: 18,
              child: MiniActionBubble(
                label: ride == null ? 'Route preview' : 'Live route',
                icon: Icons.route_rounded,
              ),
            ),
            Positioned(
                left: 34,
                bottom: 96,
                child: PinDot(label: 'P', color: AppColors.primary)),
            Positioned(
                right: 30,
                top: 44,
                child: PinDot(label: 'D', color: AppColors.accent)),
            Positioned(
                left: 120,
                top: 130,
                child:
                    PinDot(label: 'C', color: AppColors.warm, darkText: true)),
            Positioned(right: 36, bottom: 58, child: AutoChip()),
            Positioned(
              left: 18,
              right: 18,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Live map',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            ride == null
                                ? 'Driver, route, and next stop stay visible.'
                                : '${ride!.pickup} to ${ride!.destination}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    StatusPill(
                        text: ride?.status ?? 'READY',
                        color: AppColors.primary),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SoftMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0x183E6691)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 42) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += 42) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final road = Paint()
      ..color = const Color(0xFF243549)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 18;
    final roadStroke = Paint()
      ..color = const Color(0xFF2C4057)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4;

    final path = Path()
      ..moveTo(-20, size.height * 0.72)
      ..quadraticBezierTo(size.width * 0.18, size.height * 0.22,
          size.width * 0.45, size.height * 0.4)
      ..quadraticBezierTo(size.width * 0.78, size.height * 0.62,
          size.width + 20, size.height * 0.18);
    canvas.drawPath(path, road);
    canvas.drawPath(path, roadStroke);

    final route = Paint()
      ..color = AppColors.primary
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5;
    canvas.drawLine(
      Offset(size.width * 0.18, size.height * 0.64),
      Offset(size.width * 0.76, size.height * 0.36),
      route,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MiniActionBubble extends StatelessWidget {
  const MiniActionBubble({required this.label, required this.icon, super.key});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 14, offset: Offset(0, 8)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}

class PinDot extends StatelessWidget {
  const PinDot({
    required this.label,
    required this.color,
    this.darkText = false,
    super.key,
  });

  final String label;
  final Color color;
  final bool darkText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.card, width: 3),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: darkText ? AppColors.ink : Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class AutoChip extends StatelessWidget {
  const AutoChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.warm,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.card, width: 3),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: const Icon(Icons.local_taxi_rounded, color: AppColors.ink),
    );
  }
}
