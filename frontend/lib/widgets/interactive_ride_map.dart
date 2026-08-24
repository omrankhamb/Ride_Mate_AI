part of ridemate_ai;

class InteractiveRideMap extends StatefulWidget {
  const InteractiveRideMap({
    this.pickup,
    this.destination,
    this.currentLocation,
    this.selectingPickup = false,
    required this.onPointSelected,
    required this.onUseCurrentLocation,
    this.driverLocation,
    this.rides,
    this.compact = false,
    super.key,
  });

  final RideLocation? pickup;
  final RideLocation? destination;
  final RideLocation? currentLocation;
  final RideLocation? driverLocation;
  final List<Ride>? rides;
  final bool selectingPickup;
  final ValueChanged<RideLocation> onPointSelected;
  final VoidCallback onUseCurrentLocation;
  final bool compact;

  @override
  State<InteractiveRideMap> createState() => _InteractiveRideMapState();
}

class _InteractiveRideMapState extends State<InteractiveRideMap> {
  late final MapController _mapController;
  bool _initialCameraFitted = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  List<LatLng> _collectPoints() {
    final List<LatLng> points = [];

    if (widget.driverLocation != null) {
      points.add(widget.driverLocation!.latLng);
    } else if (widget.currentLocation != null) {
      points.add(widget.currentLocation!.latLng);
    }

    if (widget.rides != null && widget.rides!.isNotEmpty) {
      for (final r in widget.rides!) {
        if (r.pickupLocation != null) {
          points.add(r.pickupLocation!.latLng);
        }
        if (r.destinationLocation != null) {
          points.add(r.destinationLocation!.latLng);
        }
      }
    } else {
      if (widget.pickup != null) points.add(widget.pickup!.latLng);
      if (widget.destination != null) points.add(widget.destination!.latLng);
    }

    return points;
  }

  @override
  Widget build(BuildContext context) {
    final points = _collectPoints();
    final List<Marker> markers = [];

    // 1. Driver or User Location Marker
    if (widget.driverLocation != null) {
      markers.add(_mapMarker(widget.driverLocation!.latLng, Icons.local_taxi, AppColors.mint, 'Auto (You)'));
    } else if (widget.currentLocation != null) {
      markers.add(_mapMarker(widget.currentLocation!.latLng, Icons.my_location_rounded, const Color(0xFF59A8FF), 'You'));
    }

    // 2. Rider Stops Markers
    if (widget.rides != null && widget.rides!.isNotEmpty) {
      for (int i = 0; i < widget.rides!.length; i++) {
        final r = widget.rides![i];
        final name = r.rider?.fullName.isNotEmpty == true ? r.rider!.fullName.split(' ')[0] : 'Rider ${i + 1}';
        if (r.pickupLocation != null) {
          markers.add(_mapMarker(r.pickupLocation!.latLng, Icons.person_pin_circle, AppColors.primary, 'Pickup: $name'));
        }
        if (r.destinationLocation != null) {
          markers.add(_mapMarker(r.destinationLocation!.latLng, Icons.location_on_rounded, AppColors.warm, 'Drop: $name'));
        }
      }
    } else {
      if (widget.pickup != null) {
        markers.add(_mapMarker(widget.pickup!.latLng, Icons.trip_origin_rounded, AppColors.primary, 'Pickup'));
      }
      if (widget.destination != null) {
        markers.add(_mapMarker(widget.destination!.latLng, Icons.location_on_rounded, AppColors.warm, 'Destination'));
      }
    }

    // Calculate smart center and zoom
    LatLng center = const LatLng(18.5204, 73.8567);
    double zoom = widget.compact ? 12.0 : 13.0;

    if (points.isNotEmpty) {
      if (points.length == 1) {
        center = points.first;
        zoom = 14.5;
      } else {
        double minLat = points.first.latitude;
        double maxLat = points.first.latitude;
        double minLng = points.first.longitude;
        double maxLng = points.first.longitude;

        for (final p in points) {
          if (p.latitude < minLat) minLat = p.latitude;
          if (p.latitude > maxLat) maxLat = p.latitude;
          if (p.longitude < minLng) minLng = p.longitude;
          if (p.longitude > maxLng) maxLng = p.longitude;
        }

        center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);

        final dLat = (maxLat - minLat).abs();
        final dLng = (maxLng - minLng).abs();
        final maxSpan = dLat > dLng ? dLat : dLng;

        if (maxSpan < 0.02) {
          zoom = 14.0;
        } else if (maxSpan < 0.05) {
          zoom = 13.0;
        } else if (maxSpan < 0.12) {
          zoom = 12.0;
        } else {
          zoom = 11.0;
        }
      }
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: zoom,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
            onTap: (_, point) => widget.onPointSelected(
              RideLocation(
                latitude: point.latitude,
                longitude: point.longitude,
                label: widget.selectingPickup ? 'Pinned pickup' : 'Pinned destination',
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
                    strokeWidth: 5.5,
                  ),
                ],
              ),
            MarkerLayer(markers: markers),
          ],
        ),

        // Map mode indicator
        if (widget.rides == null || widget.rides!.isEmpty)
          Positioned(
            left: 16,
            top: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.card.withValues(alpha: .95),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
              ),
              child: Text(
                widget.selectingPickup
                    ? 'Tap map to set pickup'
                    : 'Tap map to set destination',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.ink),
              ),
            ),
          ),

        // Fit Bounds / Center button
        Positioned(
          right: 16,
          bottom: widget.rides != null && widget.rides!.isNotEmpty ? 180 : 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (points.length >= 2)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: IconButton.filled(
                    tooltip: 'Fit entire route on map',
                    onPressed: () {
                      if (points.length >= 2) {
                        _mapController.fitCamera(
                          CameraFit.bounds(
                            bounds: LatLngBounds.fromPoints(points),
                            padding: const EdgeInsets.all(70),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.zoom_out_map, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.card,
                      foregroundColor: AppColors.primary,
                      elevation: 4,
                    ),
                  ),
                ),
              IconButton.filled(
                tooltip: 'My current location',
                onPressed: () {
                  widget.onUseCurrentLocation();
                  if (widget.currentLocation != null) {
                    _mapController.move(widget.currentLocation!.latLng, 14.5);
                  }
                },
                icon: const Icon(Icons.my_location_rounded, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.card,
                  foregroundColor: AppColors.primary,
                  elevation: 4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Marker _mapMarker(LatLng point, IconData icon, Color color, String label) {
    return Marker(
      point: point,
      width: 80,
      height: 64,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.card, width: 3),
              boxShadow: const [
                BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 3)),
              ],
            ),
            child: Icon(icon, color: AppColors.bg, size: 20),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.6)),
            ),
            child: Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.ink),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
