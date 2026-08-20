part of ridemate_ai;

class RideSummaryCard extends StatelessWidget {
  const RideSummaryCard({required this.ride, super.key});

  final Ride ride;

  @override
  Widget build(BuildContext context) {
    final driverText = ride.driver == null
        ? 'Searching for driver'
        : '${ride.driver!.fullName} - ${ride.driverProfile?['vehicleNumber'] ?? 'Vehicle'}';

    return CardSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.mint,
                child: Icon(Icons.route_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Shared ride confirmed', style: TextStyle(fontWeight: FontWeight.w800)),
                    SizedBox(height: 3),
                    Text('Status updates and OTP live here.', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  ],
                ),
              ),
              StatusPill(text: ride.status, color: AppColors.accent),
            ],
          ),
          const SizedBox(height: 14),
          DetailRow(label: 'Pickup', value: ride.pickup),
          DetailRow(label: 'Destination', value: ride.destination),
          DetailRow(label: 'Driver', value: driverText),
          DetailRow(label: 'Co-rider distance', value: '${ride.coRiderPickupDistanceMeters} m away'),
          DetailRow(label: 'ETA', value: ride.etaMinutes == null ? 'Waiting' : '${ride.etaMinutes} min'),
          DetailRow(label: 'Fare', value: 'Rs ${ride.estimatedFare}'),
          DetailRow(label: 'OTP', value: ride.otp, highlight: true),
        ],
      ),
    );
  }
}

class RideHistoryCard extends StatelessWidget {
  const RideHistoryCard({
    required this.ride,
    this.onTap,
    super.key,
  });

  final Ride ride;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: CardSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long_outlined, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(child: Text(ride.status, style: const TextStyle(fontWeight: FontWeight.w800))),
                StatusPill(text: 'Rs ${ride.estimatedFare}', color: AppColors.accent),
              ],
            ),
            const SizedBox(height: 12),
            DetailRow(label: 'Pickup', value: ride.pickup),
            DetailRow(label: 'Destination', value: ride.destination),
            DetailRow(label: 'OTP', value: ride.otp, highlight: true),
          ],
        ),
      ),
    );
  }
}

class DriverRideActionCard extends StatefulWidget {
  const DriverRideActionCard({
    required this.ride,
    this.otpController,
    required this.onAction,
    super.key,
  });

  final Ride ride;
  final TextEditingController? otpController;
  final Future<void> Function(Ride, String, String?) onAction;

  @override
  State<DriverRideActionCard> createState() => _DriverRideActionCardState();
}

class _DriverRideActionCardState extends State<DriverRideActionCard> {
  final _localOtpController = TextEditingController();

  @override
  void dispose() {
    _localOtpController.dispose();
    super.dispose();
  }

  TextEditingController get _otpController => widget.otpController ?? _localOtpController;

  @override
  Widget build(BuildContext context) {
    final ride = widget.ride;
    final onAction = widget.onAction;
    return CardSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.mint,
                child: Icon(Icons.person, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ride.rider?.fullName ?? 'Rider', style: const TextStyle(fontWeight: FontWeight.w800)),
                    const Text('Pickup request', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  ],
                ),
              ),
              StatusPill(text: ride.status, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 12),
          DetailRow(label: 'Pickup', value: ride.pickup),
          DetailRow(label: 'Destination', value: ride.destination),
          DetailRow(label: 'Co-rider distance', value: '${ride.coRiderPickupDistanceMeters} m away'),
          if (ride.status != 'SEARCHING') 
            DetailRow(label: 'OTP', value: ride.otp, highlight: true),
          const SizedBox(height: 6),
          if (ride.status == 'MATCHED' || ride.status == 'SEARCHING')
            ElevatedButton.icon(
              onPressed: () => onAction(ride, 'accept', null),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Accept ride'),
            ),
          if (ride.status == 'ACCEPTED') ...[
            AppField(
              controller: _otpController,
              label: 'Enter OTP',
              icon: Icons.pin_outlined,
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => onAction(ride, 'start', _otpController.text.trim()),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start ride'),
            ),
          ],
          if (ride.status == 'STARTED')
            ElevatedButton.icon(
              onPressed: () => onAction(ride, 'complete', null),
              icon: const Icon(Icons.flag_outlined),
              label: const Text('Complete ride'),
            ),
          if (ride.status != 'COMPLETED') ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => onAction(ride, 'cancel', null),
              icon: const Icon(Icons.close),
              label: const Text('Cancel'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
            ),
          ],
        ],
      ),
    );
  }
}
