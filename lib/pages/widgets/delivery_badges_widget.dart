import 'package:flutter/material.dart';

import '../../design_system/index.dart';
import '../../services/delivery_live_service.dart';

/// Widget pour afficher les badges des livraisons disponibles
class DeliveryBadgesWidget extends StatelessWidget {
  final List<AvailableDelivery> deliveries;
  final bool isPassActive;

  const DeliveryBadgesWidget({
    super.key,
    required this.deliveries,
    required this.isPassActive,
  });

  @override
  Widget build(BuildContext context) {
    if (!isPassActive || deliveries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 170,
      left: 16,
      right: 80,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: deliveries.map((delivery) {
          return GlassPanel.small(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_shipping_rounded,
                      size: 14, color: DEMColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    '${delivery.distance.toStringAsFixed(1)} km',
                    style: DEMTypography.caption.copyWith(
                      color: DEMColors.gray900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 1,
                    height: 12,
                    color: DEMColors.gray400,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${delivery.price.toString()} FCFA',
                    style: DEMTypography.caption.copyWith(
                      color: DEMColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
