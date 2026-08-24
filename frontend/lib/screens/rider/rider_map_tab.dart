part of ridemate_ai;

class _RiderMapTab extends StatelessWidget {
  const _RiderMapTab({
    required this.activeRide,
    required this.user,
    required this.api,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.currentLocation,
    required this.selectingPickup,
    required this.isBookingMode,
    required this.onToggleBookingMode,
    required this.matches,
    this.pendingRequests = const [],
    this.onRespondRequest,
    required this.onPointSelected,
    required this.onSelectMapMode,
    required this.onUseCurrentLocation,
    this.onConnectMatch,
    this.onBook,
    this.onCancel,
  });

  final Ride? activeRide;
  final AppUser user;
  final ApiClient api;
  final RideLocation pickupLocation;
  final RideLocation? destinationLocation;
  final RideLocation? currentLocation;
  final bool selectingPickup;
  final bool isBookingMode;
  final ValueChanged<bool> onToggleBookingMode;
  final List<RideMatch> matches;
  final List<Map<String, dynamic>> pendingRequests;
  final void Function(String, String)? onRespondRequest;
  final ValueChanged<RideLocation> onPointSelected;
  final ValueChanged<bool> onSelectMapMode;
  final Future<void> Function({bool silent}) onUseCurrentLocation;
  final ValueChanged<RideMatch>? onConnectMatch;
  final VoidCallback? onBook;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    if (!isBookingMode && activeRide == null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
        children: [
          _RideGreeting(user: user, driversOnline: 1),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => onToggleBookingMode(true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, color: AppColors.primary, size: 24),
                  SizedBox(width: 16),
                  Text('Where to go?', style: TextStyle(color: AppColors.ink, fontSize: 18, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ServiceIcon(icon: Icons.electric_rickshaw, label: 'Shared Auto', active: true),
              _ServiceIcon(icon: Icons.two_wheeler, label: 'Bike', active: false),
              _ServiceIcon(icon: Icons.directions_bus, label: 'Transit', active: false),
              _ServiceIcon(icon: Icons.inventory_2_outlined, label: 'Package', active: false),
            ],
          ),
          const SizedBox(height: 32),
          const Text('Suggestions for you', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.ink)),
          const SizedBox(height: 16),
          const _RecentTile(icon: Icons.school_outlined, title: 'VIT Pune Campus', subtitle: 'Bibwewadi, Pune'),
          const _RecentTile(icon: Icons.train_outlined, title: 'Pune Railway Station', subtitle: 'Agarkar Nagar, Pune'),
        ],
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: InteractiveRideMap(
            pickup: pickupLocation,
            destination: destinationLocation,
            currentLocation: currentLocation,
            driverLocation: activeRide?.driverProfile?['lastLocation'] != null
                ? RideLocation(
                    latitude: double.tryParse(activeRide!.driverProfile!['lastLocation']['lat'].toString()) ?? 18.5204,
                    longitude: double.tryParse(activeRide!.driverProfile!['lastLocation']['lng'].toString()) ?? 73.8567,
                    label: 'Driver',
                  )
                : null,
            selectingPickup: selectingPickup,
            onPointSelected: onPointSelected,
            onUseCurrentLocation: () => onUseCurrentLocation(),
          ),
        ),

        if (activeRide == null)
          Positioned(
            top: 48,
            left: 16,
            child: CircleAvatar(
              backgroundColor: AppColors.card,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.ink),
                onPressed: () => onToggleBookingMode(false),
              ),
            ),
          ),

        DraggableScrollableSheet(
          initialChildSize: activeRide != null ? 0.65 : 0.45,
          minChildSize: 0.25,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12, spreadRadius: 4)],
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(3)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  if (activeRide == null) ...[
                    DetailRow(label: 'Pickup', value: pickupLocation.label, highlight: true),
                    const SizedBox(height: 12),
                    DetailRow(label: 'Destination', value: destinationLocation?.label ?? 'Tap map to set destination', highlight: true),
                    const SizedBox(height: 16),
                    _MapModeSwitch(selectingPickup: selectingPickup, onChanged: onSelectMapMode),
                    const SizedBox(height: 24),
                    if (destinationLocation != null)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.bg,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => onBook?.call(),
                        child: const Text('Find Co-riders & Shared Auto', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                  ] 
                  else if (activeRide!.status == 'SEARCHING') ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Finding your co-rider...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink)),
                                SizedBox(height: 2),
                                Text('Looking for nearby riders going your way', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (pendingRequests.isNotEmpty) ...[
                      const Text('Co-rider Requests (Action Needed)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                      const SizedBox(height: 8),
                      ...pendingRequests.map((req) => CardSurface(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const CircleAvatar(backgroundColor: AppColors.primary, child: Icon(Icons.person, color: AppColors.bg)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('${req['senderName']} wants to share this ride!', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.ink)),
                                          const Text('Save 50% on fare by sharing', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                DetailRow(label: 'Pickup', value: req['pickup'] ?? 'Nearby'),
                                DetailRow(label: 'Drop', value: req['destination'] ?? 'En route'),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                                        onPressed: () => onRespondRequest?.call(req['id'].toString(), 'reject'),
                                        child: const Text('Decline'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.bg),
                                        onPressed: () {
                                          onRespondRequest?.call(req['id'].toString(), 'accept');
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ChatScreen(
                                                poolGroupId: activeRide!.poolGroupId ?? '',
                                                api: api,
                                                user: user,
                                                myRideId: activeRide!.id,
                                                targetRideId: req['senderRideId']?.toString(),
                                              ),
                                            ),
                                          );
                                        },
                                        child: const Text('Accept & Chat', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )),
                      const SizedBox(height: 16),
                    ],

                    if (matches.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Nearby Co-riders Going Your Way', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.ink)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                            child: Text('${matches.length} found', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...matches.map((m) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _MatchCard(
                          match: m,
                          onConnect: () {
                            onConnectMatch?.call(m);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  poolGroupId: m.poolGroupId,
                                  api: api,
                                  user: user,
                                  myRideId: activeRide!.id,
                                  targetRideId: m.rideId,
                                  coRiderName: m.riderName,
                                  routeDistanceKm: m.destinationDistanceMeters / 1000.0,
                                  destinationLabel: m.destination,
                                ),
                              ),
                            );
                          },
                        ),
                      )),
                    ] else ...[
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text('Scanning 5km radius for matching routes...', style: TextStyle(color: AppColors.muted, fontSize: 14)),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => onCancel?.call(),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Cancel Ride Request'),
                    )
                  ]
                  else if (activeRide!.status == 'POOLED') ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Finding your auto', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.ink)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
                          child: const Text('2 riders pooled', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                        )
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Center(child: SizedBox(width: 60, height: 60, child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 5))),
                    const SizedBox(height: 18),
                    const Center(child: Text('Looking for nearby drivers...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink))),
                    const SizedBox(height: 6),
                    const Center(child: Text('Assigning the nearest auto for both riders', style: TextStyle(color: AppColors.muted), textAlign: TextAlign.center)),
                    const SizedBox(height: 24),
                    CardSurface(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(backgroundColor: AppColors.primary, child: Text(user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U', style: const TextStyle(color: AppColors.bg))),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const Text('You', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold)),
                                Text('₹${activeRide!.fareShare?.toStringAsFixed(2) ?? (activeRide!.estimatedFare / 2).toStringAsFixed(2)} · your share (50% OFF)', style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                              ])),
                            ],
                          ),
                          const Divider(color: AppColors.line, height: 20),
                          Row(
                            children: [
                              const CircleAvatar(backgroundColor: AppColors.cardAlt, child: Icon(Icons.people, color: AppColors.primary)),
                              const SizedBox(width: 12),
                              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Co-rider', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold)),
                                Text('Agreed & Confirmed', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                              ])),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cardAlt,
                        foregroundColor: AppColors.ink,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              poolGroupId: activeRide!.poolGroupId ?? '',
                              api: api,
                              user: user,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
                      label: const Text('Open Co-rider Chat', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                      onPressed: () => onCancel?.call(),
                      child: const Text('Cancel Ride'),
                    ),
                  ]
                  else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          activeRide!.status == 'ACCEPTED' ? 'Driver is on the way' : 'Ride in progress',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.ink),
                        ),
                        StatusPill(text: activeRide!.status, color: AppColors.primary),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (activeRide!.driver != null)
                      CardSurface(
                        child: Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: AppColors.primary,
                              child: Icon(Icons.drive_eta, color: AppColors.bg),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(activeRide!.driver!.fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink)),
                                  Text(
                                    '${activeRide!.driverProfile?['vehicleType'] ?? "Auto"} · ${activeRide!.driverProfile?['vehicleNumber'] ?? ""}',
                                    style: const TextStyle(color: AppColors.muted),
                                  ),
                                ],
                              ),
                            ),
                            if (activeRide!.etaMinutes != null)
                              Text('${activeRide!.etaMinutes} mins', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primary)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Ride OTP', style: TextStyle(fontSize: 14, color: AppColors.muted)),
                              Text('Share with driver to start', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                            ],
                          ),
                          Text(activeRide!.otp, style: const TextStyle(fontSize: 30, letterSpacing: 6, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (activeRide!.poolGroupId != null)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.bg,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                poolGroupId: activeRide!.poolGroupId!,
                                api: api,
                                user: user,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text('Chat with Co-rider', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ServiceIcon extends StatelessWidget {
  const _ServiceIcon({required this.icon, required this.label, required this.active});
  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: active ? AppColors.primary : AppColors.line),
          ),
          child: Icon(icon, color: active ? AppColors.bg : AppColors.ink, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: active ? AppColors.primary : AppColors.muted, fontSize: 12, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}

class _RecentTile extends StatelessWidget {
  const _RecentTile({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: AppColors.cardAlt, child: Icon(icon, color: AppColors.primary)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 16)),
                Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 14)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.muted),
        ],
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match, required this.onConnect});
  final RideMatch match;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    return CardSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Text(
                  match.riderName.isNotEmpty ? match.riderName[0].toUpperCase() : 'R',
                  style: const TextStyle(color: AppColors.bg, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(match.riderName, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, color: AppColors.primary, size: 16),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('${match.matchScore}% route match · Nearby', style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.bg,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: onConnect,
                child: const Text('Connect & Chat', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DetailRow(label: 'Destination', value: match.destination),
        ],
      ),
    );
  }
}
