part of ridemate_ai;

class InteractiveRideMap extends StatelessWidget {
  const InteractiveRideMap({
    required this.pickup,
    required this.destination,
    required this.currentLocation,
    required this.selectingPickup,
    required this.onPointSelected,
    required this.onUseCurrentLocation,
    this.driverLocation,
    this.compact = false,
    super.key,
  });

  final RideLocation? pickup;
  final RideLocation? destination;
  final RideLocation? currentLocation;
  final RideLocation? driverLocation;
  final bool selectingPickup;
  final ValueChanged<RideLocation> onPointSelected;
  final VoidCallback onUseCurrentLocation;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final center = driverLocation?.latLng ?? destination?.latLng ?? pickup?.latLng ?? currentLocation?.latLng ??
        const LatLng(18.4637, 73.8677);
    final points = [
      if (driverLocation != null) driverLocation!.latLng,
      if (pickup != null) pickup!.latLng,
      if (destination != null) destination!.latLng,
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: compact ? 12.5 : 13.5,
              onTap: (_, point) => onPointSelected(
                RideLocation(
                  latitude: point.latitude,
                  longitude: point.longitude,
                  label: selectingPickup ? 'Pinned pickup' : 'Pinned destination',
                ),
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'ai.ridemate.app',
              ),
              if (points.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: points,
                      color: AppColors.primary,
                      strokeWidth: 5,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (driverLocation != null)
                    _mapMarker(
                      driverLocation!.latLng,
                      Icons.local_taxi,
                      AppColors.mint,
                      'Auto',
                    ),
                  if (currentLocation != null)
                    _mapMarker(
                      currentLocation!.latLng,
                      Icons.my_location_rounded,
                      const Color(0xFF59A8FF),
                      'You',
                    ),
                  if (pickup != null)
                    _mapMarker(
                      pickup!.latLng,
                      Icons.trip_origin_rounded,
                      AppColors.primary,
                      'P',
                    ),
                  if (destination != null)
                    _mapMarker(
                      destination!.latLng,
                      Icons.location_on_rounded,
                      AppColors.warm,
                      'D',
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 12,
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.card.withValues(alpha: .95),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: Text(
                selectingPickup
                    ? 'Tap map to set pickup'
                    : 'Tap map to set destination',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: IconButton.filled(
              tooltip: 'Use my current location',
              onPressed: onUseCurrentLocation,
              icon: const Icon(Icons.my_location_rounded),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.card,
                foregroundColor: AppColors.primary,
              ),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.card.withValues(alpha: .95),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: const Text('OpenStreetMap',
                  style: TextStyle(fontSize: 9, color: AppColors.muted)),
            ),
          ),
        ],
      ),
    );
  }

  Marker _mapMarker(LatLng point, IconData icon, Color color, String label) {
    return Marker(
      point: point,
      width: 44,
      height: 52,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.card, width: 3),
              boxShadow: const [
                BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Icon(icon, color: AppColors.bg, size: 17),
          ),
          Text(label,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
