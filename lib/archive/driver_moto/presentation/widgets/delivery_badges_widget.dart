import 'package:delivery_express_mobility_frontend/design_system/index.dart';
import 'package:delivery_express_mobility_frontend/services/delivery_live_service.dart';
import 'package:delivery_express_mobility_frontend/widgets/top_glass_sheet.dart';
import 'package:flutter/material.dart';

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
          return GestureDetector(
            onTap: () => _showDeliveryDetailsSheet(context, delivery),
            child: GlassPanel.small(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showDeliveryDetailsSheet(
      BuildContext context, AvailableDelivery delivery) {
    TopGlassSheetSlideIn.show(
      context: context,
      title: 'Détails de la livraison',
      showCloseButton: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Distance
          _buildInfoRow(
            icon: Icons.route,
            label: 'Distance',
            value: '${delivery.distance.toStringAsFixed(1)} km',
            color: DEMColors.primary,
          ),
          const SizedBox(height: DEMSpacing.md),

          // Prix
          _buildInfoRow(
            icon: Icons.payments_rounded,
            label: 'Prix',
            value: '${delivery.price} FCFA',
            color: Colors.green,
          ),
          const SizedBox(height: DEMSpacing.md),

          // Adresse de départ
          _buildInfoRow(
            icon: Icons.location_on,
            label: 'Départ',
            value: delivery.pickupAddress,
            color: DEMColors.gray700,
          ),
          const SizedBox(height: DEMSpacing.md),

          // Adresse de destination
          _buildInfoRow(
            icon: Icons.flag,
            label: 'Destination',
            value: delivery.dropoffAddress,
            color: DEMColors.gray700,
          ),
          const SizedBox(height: DEMSpacing.xl),

          // Bouton d'action
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Accepter la livraison
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Accepter la livraison'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DEMColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: DEMSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(DEMSpacing.sm),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: DEMSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: DEMTypography.caption.copyWith(
                  color: DEMColors.gray600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: DEMTypography.body2.copyWith(
                  fontWeight: FontWeight.w600,
                  color: DEMColors.gray900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
