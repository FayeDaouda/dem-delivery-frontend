import 'package:delivery_express_mobility_frontend/design_system/index.dart';
import 'package:flutter/material.dart';

/// Tuile pour afficher une course VTC dans la liste historique
class DriverRidesTile extends StatelessWidget {
  final Map<String, dynamic> ride;
  final int index;
  final VoidCallback? onTap;

  const DriverRidesTile({
    super.key,
    required this.ride,
    required this.index,
    this.onTap,
  });

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
      case 'DELIVERED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      case 'IN_PROGRESS':
      case 'PICKED_UP':
        return Colors.orange;
      default:
        return DEMColors.gray600;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
      case 'DELIVERED':
        return Icons.check_circle;
      case 'CANCELLED':
        return Icons.cancel;
      case 'IN_PROGRESS':
      case 'PICKED_UP':
        return Icons.local_shipping;
      default:
        return Icons.info;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
      case 'DELIVERED':
        return 'Complétée';
      case 'CANCELLED':
        return 'Annulée';
      case 'IN_PROGRESS':
      case 'PICKED_UP':
        return 'En cours';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ride['status']?.toString() ?? 'UNKNOWN';
    final amount = ride['gain'] ?? ride['amount'] ?? ride['price'] ?? 0;
    final statusColor = _getStatusColor(status);

    return Card(
      child: ListTile(
        title: Text(
          'Course ${index + 1} • ${_getStatusLabel(status)}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${ride['pickupAddress'] ?? 'Départ'} → ${ride['deliveryAddress'] ?? 'Destination'}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          '$amount FCFA',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        leading: Icon(
          _getStatusIcon(status),
          color: statusColor,
        ),
        onTap: onTap,
      ),
    );
  }
}
