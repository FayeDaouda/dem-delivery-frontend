import 'package:flutter/material.dart';

Color deliveryStatusColor(String status) {
  switch (status) {
    case 'PENDING':
      return Colors.orange;
    case 'IN_PROGRESS':
      return Colors.blue;
    case 'COMPLETED':
      return Colors.green;
    case 'CANCELLED':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

String deliveryStatusLabel(String status) {
  switch (status) {
    case 'PENDING':
      return 'En attente';
    case 'IN_PROGRESS':
      return 'En cours';
    case 'COMPLETED':
      return 'Complétée';
    case 'CANCELLED':
      return 'Annulée';
    default:
      return status;
  }
}

class DeliveryStatusBadge extends StatelessWidget {
  final String status;

  const DeliveryStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final color = deliveryStatusColor(status);
    final label = deliveryStatusLabel(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
