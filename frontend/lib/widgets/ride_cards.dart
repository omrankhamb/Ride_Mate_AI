part of ridemate_ai;

class RiderMiniCard extends StatelessWidget {
  const RiderMiniCard({
    required this.name,
    required this.infoText,
    super.key,
  });

  final String name;
  final String infoText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(color: AppColors.bg, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 13)),
                Text(infoText, style: const TextStyle(color: AppColors.muted, fontSize: 11), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
                backgroundColor: AppColors.primary,
                child: Icon(Icons.person, color: AppColors.bg),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driverText,
                      style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      '⭐ 4.9',
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (ride.otp.isNotEmpty && ride.status == 'ACCEPTED')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Text(
                    ride.otp,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      letterSpacing: 4,
                    ),
                  ),
                ),
            ],
          ),
          if (ride.fareShare != null) ...[
            const SizedBox(height: 16),
            const Divider(color: AppColors.line),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Your fare share', style: TextStyle(color: AppColors.muted, fontSize: 14)),
                Text('₹${ride.fareShare!.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class SharedRideRequestCard extends StatelessWidget {
  const SharedRideRequestCard({
    required this.rides,
    required this.onAccept,
    super.key,
  });

  final List<Ride> rides;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    if (rides.isEmpty) return const SizedBox.shrink();
    
    double totalFare = 0;
    for (var r in rides) totalFare += (r.fareShare ?? (r.estimatedFare.toDouble() / rides.length));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('New shared-ride\nrequest', style: GoogleFonts.outfit(color: AppColors.ink, fontSize: 22, fontWeight: FontWeight.bold, height: 1.2)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('0.4 km away', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
            )
          ],
        ),
        const SizedBox(height: 16),
        CardSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹${totalFare.toStringAsFixed(2)}', style: GoogleFonts.outfit(color: AppColors.primary, fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Text('total fare', style: TextStyle(color: AppColors.muted, fontSize: 14)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.circle, color: AppColors.primary, size: 12),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(color: AppColors.muted, fontSize: 14),
                        children: [
                          const TextSpan(text: 'Pickup: ', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold)),
                          TextSpan(text: rides[0].pickup),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.circle, color: AppColors.warm, size: 12),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(color: AppColors.muted, fontSize: 14),
                        children: [
                          const TextSpan(text: 'Drop: ', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold)),
                          TextSpan(text: rides.length > 1 ? '${rides[0].destination.split(',')[0]} — ${rides.length} nearby stops' : rides[0].destination),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: rides.map((r) {
                  final share = r.fareShare ?? (r.estimatedFare.toDouble() / rides.length);
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: r == rides.last ? 0 : 8),
                      child: RiderMiniCard(
                        name: r.rider?.fullName.split(' ')[0] ?? 'Rider',
                        infoText: 'Verified ✓ · ₹${share.toStringAsFixed(2)}',
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: BorderSide(color: AppColors.danger.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Decline', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: onAccept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.bg,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Accept Ride', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          "Both riders' pickup, drop & contact details unlock only after you accept.",
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    );
  }
}

class DriverRideActionCard extends StatefulWidget {
  const DriverRideActionCard({
    required this.rides,
    required this.onAction,
    super.key,
  });

  final List<Ride> rides;
  final Future<void> Function(List<Ride> rides, String action, String? otp) onAction;

  @override
  State<DriverRideActionCard> createState() => _DriverRideActionCardState();
}

class _DriverRideActionCardState extends State<DriverRideActionCard> {
  final otpController = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  Future<void> _handle(String action) async {
    setState(() => loading = true);
    await widget.onAction(widget.rides, action, action == 'start' ? otpController.text : null);
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rides.isEmpty) return const SizedBox.shrink();
    
    final status = widget.rides[0].status;

    if (status == 'SEARCHING' || status == 'POOLED') {
      return SharedRideRequestCard(
        rides: widget.rides,
        onAccept: () => _handle('accept'),
      );
    }
    
    if (status == 'ACCEPTED') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Rider Location & Contact Cards
          ...widget.rides.map((r) => CardSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary,
                      radius: 18,
                      child: Text(
                        r.rider?.fullName.isNotEmpty == true ? r.rider!.fullName[0].toUpperCase() : 'R',
                        style: const TextStyle(color: AppColors.bg, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(r.rider?.fullName ?? 'Rider', style: const TextStyle(color: AppColors.ink, fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 6),
                              const Icon(Icons.verified, color: AppColors.primary, size: 16),
                            ],
                          ),
                          Text('Fare: ₹${r.fareShare?.toStringAsFixed(2) ?? r.estimatedFare}', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.phone, size: 18, color: AppColors.primary),
                      style: IconButton.styleFrom(backgroundColor: AppColors.cardAlt),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.cardAlt,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.trip_origin_rounded, color: AppColors.primary, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(color: AppColors.muted, fontSize: 13),
                                children: [
                                  const TextSpan(text: 'Pickup: ', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold)),
                                  TextSpan(text: r.pickup),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: AppColors.warm, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(color: AppColors.muted, fontSize: 13),
                                children: [
                                  const TextSpan(text: 'Drop: ', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold)),
                                  TextSpan(text: r.destination),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(height: 12),
          // OTP Entry Card
          CardSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Arrived at Pickup? Enter Rider OTP to Start', style: TextStyle(color: AppColors.ink, fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppField(
                        label: '4-digit OTP',
                        controller: otpController,
                        icon: Icons.pin,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: loading ? null : () => _handle('start'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.bg, strokeWidth: 2)) : const Text('Start Ride', style: TextStyle(color: AppColors.bg, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }
    
    if (status == 'STARTED') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...widget.rides.map((r) => CardSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: AppColors.warm, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dropping off: ${r.rider?.fullName ?? "Rider"}', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(r.destination, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )),
          const SizedBox(height: 12),
          CardSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Trip in Progress', style: TextStyle(color: AppColors.ink, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: loading ? null : () => _handle('complete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.bg, strokeWidth: 2)) : const Text('Complete Trip', style: TextStyle(color: AppColors.bg, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      );
    }
    
    return const SizedBox.shrink();
  }
}

class RideHistoryCard extends StatelessWidget {
  const RideHistoryCard({required this.ride, super.key});
  final Ride ride;
  @override
  Widget build(BuildContext context) {
    return CardSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text((ride.createdAt ?? "").split('T')[0], style: const TextStyle(color: AppColors.muted)),
              Text('₹${ride.estimatedFare}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(ride.pickup, style: const TextStyle(color: AppColors.ink), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(ride.destination, style: const TextStyle(color: AppColors.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
