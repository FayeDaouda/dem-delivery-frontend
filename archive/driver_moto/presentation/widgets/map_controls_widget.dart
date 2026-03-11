import 'package:delivery_express_mobility_frontend/design_system/index.dart';
import 'package:flutter/material.dart';

/// Widget pour les contrôles de la map
class MapControlsWidget extends StatelessWidget {
  final VoidCallback onRecenter;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final double bottomPosition;

  const MapControlsWidget({
    super.key,
    required this.onRecenter,
    required this.onZoomIn,
    required this.onZoomOut,
    this.bottomPosition = 360,
  });

  Widget _mapButton(
    IconData icon,
    VoidCallback onTap, {
    bool isPrimary = false,
  }) {
    return GlassPanel(
      padding: const EdgeInsets.all(4),
      borderRadius: BorderRadius.circular(16),
      opacity: 0.78,
      enableGradient: false,
      child: Container(
        decoration: isPrimary
            ? BoxDecoration(
                color: DEMColors.primary,
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: IconButton(
          icon: Icon(
            icon,
            color: isPrimary ? Colors.white : DEMColors.primary,
          ),
          onPressed: onTap,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: bottomPosition,
      right: 16,
      child: Column(
        children: [
          _mapButton(Icons.my_location, onRecenter, isPrimary: true),
          const SizedBox(height: 10),
          _mapButton(Icons.add, onZoomIn),
          const SizedBox(height: 8),
          _mapButton(Icons.remove, onZoomOut),
        ],
      ),
    );
  }
}
