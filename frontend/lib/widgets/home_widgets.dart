part of ridemate_ai;

class FeatureChip extends StatelessWidget {
  const FeatureChip({required this.icon, required this.label, super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}

class RidePhoneShowcase extends StatelessWidget {
  const RidePhoneShowcase({required this.compact, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Center(
        child: PhoneMock(
          width: 252,
          height: 372,
          child: const MiniHomePreview(),
        ),
      );
    }

    return SizedBox(
      height: 370,
      child: Stack(
        alignment: Alignment.center,
        children: const [
          Positioned(
            left: 0,
            top: 40,
            child: PhoneMock(width: 178, height: 316, child: MiniHomePreview()),
          ),
          PhoneMock(width: 188, height: 336, child: MiniMapPreview()),
          Positioned(
            right: 0,
            top: 36,
            child:
                PhoneMock(width: 178, height: 316, child: MiniDriverPreview()),
          ),
        ],
      ),
    );
  }
}

class PhoneMock extends StatelessWidget {
  const PhoneMock({
    required this.width,
    required this.height,
    required this.child,
    super.key,
  });

  final double width;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(34),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 26, offset: Offset(0, 16)),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

class MiniHomePreview extends StatelessWidget {
  const MiniHomePreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFBFFFC), Color(0xFFEEF8F1)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.mint,
                child: Icon(Icons.person, size: 14),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.soft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.notifications_none, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Hello Muhammad,',
              style: TextStyle(fontSize: 12, color: AppColors.muted)),
          const Text('Where to go?',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Container(
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: const Row(
              children: [
                Icon(Icons.search, size: 16, color: AppColors.muted),
                SizedBox(width: 8),
                Text('Enter destination',
                    style: TextStyle(fontSize: 11, color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              Expanded(
                  child: PreviewTile(icon: Icons.local_taxi, label: 'Auto')),
              SizedBox(width: 8),
              Expanded(
                  child:
                      PreviewTile(icon: Icons.shield_outlined, label: 'Safe')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              Expanded(
                  child:
                      PreviewTile(icon: Icons.route_outlined, label: 'Live')),
              SizedBox(width: 8),
              Expanded(
                  child: PreviewTile(
                      icon: Icons.groups_2_outlined, label: 'Share')),
            ],
          ),
          const SizedBox(height: 10),
          const Expanded(child: RideMiniMap()),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Text(
                    'Ready for ride',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward, size: 16, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MiniMapPreview extends StatelessWidget {
  const MiniMapPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8FCFA), Color(0xFFE8F7EF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.arrow_back, size: 14),
              ),
              const Spacer(),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.layers_outlined, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Expanded(child: RideMiniMap()),
          const SizedBox(height: 10),
          const Text('What do you want?',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Container(
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: const Row(
              children: [
                Icon(Icons.search, size: 16, color: AppColors.muted),
                SizedBox(width: 8),
                Text('Search anything',
                    style: TextStyle(fontSize: 11, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MiniDriverPreview extends StatelessWidget {
  const MiniDriverPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFBFFFC), Color(0xFFEEF8F1)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose a driver',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 18,
                      offset: Offset(0, 10)),
                ],
              ),
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      CircleAvatar(
                        radius: 13,
                        backgroundColor: AppColors.mint,
                        child: Icon(Icons.person, size: 14),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Carlos Torres',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700)),
                            Text('Porsche Taycan',
                                style: TextStyle(
                                    fontSize: 10, color: AppColors.muted)),
                          ],
                        ),
                      ),
                      Text(
                        '130/h',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppColors.soft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.directions_car,
                        size: 28, color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text(
                        'Book now',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 14, color: AppColors.accent),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Ready to pick you up',
                          style:
                              TextStyle(fontSize: 10, color: AppColors.muted),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RideMiniMap extends StatelessWidget {
  const RideMiniMap({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppColors.sky, Color(0xFFF1F8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: CustomPaint(
          painter: MiniMapPainter(),
          child: Stack(
            children: const [
              Positioned(
                  left: 18,
                  top: 26,
                  child: PinDot(label: 'P', color: AppColors.primary)),
              Positioned(
                  right: 24,
                  top: 18,
                  child: PinDot(label: 'D', color: AppColors.accent)),
              Positioned(
                  left: 46,
                  bottom: 40,
                  child: PinDot(
                      label: 'C', color: AppColors.warm, darkText: true)),
              Positioned(right: 28, bottom: 34, child: AutoChip()),
            ],
          ),
        ),
      ),
    );
  }
}

class MiniMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0x1A34507A)
      ..strokeWidth = 1;

    for (var x = 0.0; x < size.width; x += 42) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += 42) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final road = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 18;
    final roadStroke = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4;

    final path = Path()
      ..moveTo(-10, size.height * 0.65)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.24,
        size.width * 0.55,
        size.height * 0.42,
      )
      ..quadraticBezierTo(
        size.width * 0.84,
        size.height * 0.58,
        size.width + 20,
        size.height * 0.18,
      );
    canvas.drawPath(path, road);
    canvas.drawPath(path, roadStroke);

    final route = Paint()
      ..color = AppColors.primary
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5;
    canvas.drawLine(
      Offset(size.width * 0.16, size.height * 0.72),
      Offset(size.width * 0.75, size.height * 0.34),
      route,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PreviewTile extends StatelessWidget {
  const PreviewTile({required this.icon, required this.label, super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class RideSearchPrompt extends StatelessWidget {
  const RideSearchPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    return CardSurface(
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.mint,
            child: Icon(Icons.search, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Need a shared auto?',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                SizedBox(height: 2),
                Text(
                  'Enter pickup and destination to see drivers nearby.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class QuickActionGrid extends StatelessWidget {
  const QuickActionGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 680 ? 4 : 2;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: columns == 4 ? 1.9 : 2.6,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: const [
            QuickActionCard(
              icon: Icons.local_taxi_outlined,
              label: 'Shared Auto',
              value: 'Best match',
            ),
            QuickActionCard(
              icon: Icons.route_outlined,
              label: 'Live Route',
              value: 'Map ready',
            ),
            QuickActionCard(
              icon: Icons.shield_outlined,
              label: 'Safety',
              value: 'OTP start',
            ),
            QuickActionCard(
              icon: Icons.history_outlined,
              label: 'Trips',
              value: 'Saved',
            ),
          ],
        );
      },
    );
  }
}

class QuickActionCard extends StatelessWidget {
  const QuickActionCard({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 18, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const Spacer(),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            ],
          ),
        ],
      ),
    );
  }
}

class DriverChoiceCard extends StatelessWidget {
  const DriverChoiceCard({
    required this.driver,
    required this.onBook,
    super.key,
  });

  final DriverSummary driver;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return CardSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 19,
                backgroundColor: AppColors.mint,
                child: Icon(Icons.person, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(driver.name,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(
                      driver.vehicleType,
                      style:
                          const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              StatusPill(
                  text: '${driver.rating.toStringAsFixed(1)} ★',
                  color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 12),
          VehicleAssetPreview(vehicleType: driver.vehicleType),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: DetailChip(
                      icon: Icons.schedule, value: '${driver.etaMinutes} min')),
              const SizedBox(width: 8),
              Expanded(
                child: DetailChip(
                  icon: Icons.place_outlined,
                  value: '${driver.distanceKm.toStringAsFixed(1)} km',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(driver.vehicleNumber,
              style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: onBook,
            child: const Text('Book now'),
          ),
        ],
      ),
    );
  }
}

class DriverChoiceGrid extends StatelessWidget {
  const DriverChoiceGrid({
    required this.drivers,
    required this.onPickDriver,
    super.key,
  });

  final List<DriverSummary> drivers;
  final Future<void> Function({DriverSummary? preferred}) onPickDriver;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 2 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: drivers.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 316,
          ),
          itemBuilder: (context, index) {
            final driver = drivers[index];
            return DriverChoiceCard(
              driver: driver,
              onBook: () => onPickDriver(preferred: driver),
            );
          },
        );
      },
    );
  }
}

class DetailChip extends StatelessWidget {
  const DetailChip({required this.icon, required this.value, super.key});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class RouteDistanceStrip extends StatelessWidget {
  const RouteDistanceStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE9FFF7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: const Row(
        children: [
          Icon(Icons.social_distance_outlined, color: AppColors.accentDark),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pickup distance: 700m between matched riders',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class LocationSuggestionPanel extends StatelessWidget {
  const LocationSuggestionPanel({
    required this.pickupController,
    required this.destinationController,
    super.key,
  });

  final TextEditingController pickupController;
  final TextEditingController destinationController;

  void applyPair(String pickup, String destination) {
    pickupController.text = pickup;
    destinationController.text = destination;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => pickupController.text = 'Current location',
                icon: const Icon(Icons.my_location_outlined),
                label: const Text('Use current location'),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              tooltip: 'Swap pickup and destination',
              onPressed: () {
                final pickup = pickupController.text;
                pickupController.text = destinationController.text;
                destinationController.text = pickup;
              },
              icon: const Icon(Icons.swap_vert),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SuggestionPill(
              icon: Icons.school_outlined,
              label: 'College to Station',
              onTap: () => applyPair('College gate', 'Railway station'),
            ),
            SuggestionPill(
              icon: Icons.apartment_outlined,
              label: 'Home to Office',
              onTap: () => applyPair('Home', 'Office'),
            ),
            SuggestionPill(
              icon: Icons.local_hospital_outlined,
              label: 'Market to Hospital',
              onTap: () => applyPair('Main market', 'City hospital'),
            ),
          ],
        ),
      ],
    );
  }
}

class SuggestionPill extends StatelessWidget {
  const SuggestionPill({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: AppColors.primary),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: AppColors.soft,
      side: const BorderSide(color: AppColors.line),
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }
}

class RideStatusTimeline extends StatelessWidget {
  const RideStatusTimeline({required this.ride, super.key});

  final Ride ride;

  int get activeIndex {
    switch (ride.status) {
      case 'SEARCHING':
        return 0;
      case 'MATCHED':
        return 1;
      case 'ACCEPTED':
        return 2;
      case 'STARTED':
        return 3;
      case 'COMPLETED':
        return 4;
      case 'CANCELLED':
        return -1;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (ride.status == 'CANCELLED') {
      return const StatusBanner(
        icon: Icons.cancel_outlined,
        title: 'Ride cancelled',
        subtitle:
            'This ride is closed. Start a new request when you are ready.',
        color: AppColors.danger,
      );
    }

    const steps = [
      ('Search', Icons.search),
      ('Match', Icons.group_add_outlined),
      ('Accept', Icons.check_circle_outline),
      ('Start', Icons.play_arrow_outlined),
      ('Done', Icons.flag_outlined),
    ];

    return CardSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ride timeline',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var index = 0; index < steps.length; index++) ...[
                Expanded(
                  child: TimelineStep(
                    label: steps[index].$1,
                    icon: steps[index].$2,
                    active: index <= activeIndex,
                  ),
                ),
                if (index != steps.length - 1)
                  Container(
                    width: 18,
                    height: 2,
                    color: index < activeIndex
                        ? AppColors.primary
                        : AppColors.line,
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class TimelineStep extends StatelessWidget {
  const TimelineStep({
    required this.label,
    required this.icon,
    required this.active,
    super.key,
  });

  final String label;
  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.soft,
            shape: BoxShape.circle,
            border:
                Border.all(color: active ? AppColors.primary : AppColors.line),
          ),
          child: Icon(icon,
              size: 17, color: active ? Colors.white : AppColors.muted),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            color: active ? AppColors.ink : AppColors.muted,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class DriverContactCard extends StatelessWidget {
  const DriverContactCard({required this.ride, super.key});

  final Ride ride;

  @override
  Widget build(BuildContext context) {
    final driverName = ride.driver?.fullName ?? 'Driver assigning';
    final vehicle =
        ride.driverProfile?['vehicleNumber']?.toString() ?? 'Vehicle pending';

    return CardSurface(
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.mint,
            child: Icon(Icons.support_agent_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(driverName,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(vehicle,
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 12)),
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Call driver',
            onPressed: () {},
            icon: const Icon(Icons.call_outlined),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: 'Message driver',
            onPressed: () {},
            icon: const Icon(Icons.chat_bubble_outline),
          ),
        ],
      ),
    );
  }
}

class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.icon,
    super.key,
  });

  final String name;
  final String email;
  final String role;
  final String status;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return CardSurface(
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.mint,
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(email,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.muted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusPill(text: status, color: AppColors.primary),
              const SizedBox(height: 6),
              Text(role,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ],
          ),
        ],
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    required this.icon,
    required this.title,
    required this.value,
    super.key,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.soft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            child: Icon(icon, color: AppColors.primary, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w800))),
          Text(value,
              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ],
      ),
    );
  }
}

class StatusBanner extends StatelessWidget {
  const StatusBanner({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CardSurface(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(subtitle,
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void showRideDetails(BuildContext context, Ride ride) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
                color: AppColors.shadow, blurRadius: 28, offset: Offset(0, 16)),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Trip details',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w900)),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              RideSummaryCard(ride: ride),
              const SizedBox(height: 12),
              RideStatusTimeline(ride: ride),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check),
                label: const Text('Done'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class AiRideInsightCard extends StatelessWidget {
  const AiRideInsightCard({required this.driversOnline, super.key});

  final int driversOnline;

  @override
  Widget build(BuildContext context) {
    return CardSurface(
      child: Row(
        children: [
          const SizedBox(
            width: 108,
            height: 72,
            child: VehicleAssetPreview(vehicleType: 'Shared Auto'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI route suggestion',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  driversOnline == 0
                      ? 'No online drivers yet. Keep the route ready.'
                      : '$driversOnline drivers online. Shared auto is the fastest match.',
                  style: const TextStyle(color: AppColors.muted, height: 1.35),
                ),
                const SizedBox(height: 8),
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    MiniBadge(icon: Icons.bolt_outlined, label: 'Fast match'),
                    MiniBadge(icon: Icons.currency_rupee, label: 'Low fare'),
                    MiniBadge(
                        icon: Icons.people_alt_outlined, label: 'Shared ride'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VehicleAssetPreview extends StatelessWidget {
  const VehicleAssetPreview({
    required this.vehicleType,
    this.compact = false,
    super.key,
  });

  final String vehicleType;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final normalized = vehicleType.toLowerCase();
    final asset = normalized.contains('car')
        ? 'assets/images/car.png'
        : 'assets/images/rickshaw.png';

    return Container(
      height: compact ? 64 : 86,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE7F8ED), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white),
      ),
      padding: const EdgeInsets.all(8),
      child: Image.asset(asset, fit: BoxFit.contain),
    );
  }
}

class MiniBadge extends StatelessWidget {
  const MiniBadge({required this.icon, required this.label, super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.accentDark),
          const SizedBox(width: 5),
          Text(label,
              style:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
