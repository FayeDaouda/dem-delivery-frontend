import 'package:flutter/material.dart';

import '../features/deliveries/domain/entities/delivery.dart';
import 'delivery_action_button.dart';
import 'delivery_status_badge.dart';

class DeliveryListItem extends StatelessWidget {
  final Delivery delivery;
  final VoidCallback onTap;
  final VoidCallback? onStart;
  final VoidCallback? onComplete;

  const DeliveryListItem({
    super.key,
    required this.delivery,
    required this.onTap,
    this.onStart,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            title: Text(delivery.clientName),
            subtitle: Text(delivery.deliveryAddress),
            trailing: DeliveryStatusBadge(status: delivery.status),
            onTap: onTap,
          ),
          if (onStart != null || onComplete != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (delivery.status == 'PENDING' && onStart != null)
                    DeliveryActionButton(
                      onPressed: onStart!,
                      icon: Icons.start,
                      label: 'Démarrer',
                    ),
                  if (delivery.status == 'IN_PROGRESS' && onComplete != null)
                    DeliveryActionButton(
                      onPressed: onComplete!,
                      icon: Icons.check_circle,
                      label: 'Complétée',
                      backgroundColor: Colors.green,
                    ),
                  Text(
                    '${delivery.amount} XOF',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
