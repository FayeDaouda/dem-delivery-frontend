import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Section Google Maps avec heatmap
class DriverHeatmapSection extends StatelessWidget {
  final List<Circle> circles;
  final Set<Marker> markers;
  final CameraPosition initialCameraPosition;
  final String title;
  final double height;

  const DriverHeatmapSection({
    super.key,
    required this.circles,
    this.markers = const {},
    required this.initialCameraPosition,
    this.title = 'Heatmap',
    this.height = 260,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: height,
          child: GoogleMap(
            initialCameraPosition: initialCameraPosition,
            circles: circles.toSet(),
            markers: markers,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
        ),
      ],
    );
  }
}
