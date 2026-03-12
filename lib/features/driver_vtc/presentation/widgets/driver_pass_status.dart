import 'package:flutter/material.dart';

/// Affiche le statut du pass (Actif/Inactif)
class DriverPassStatus extends StatelessWidget {
  final bool hasActivePass;
  final VoidCallback? onTap;

  const DriverPassStatus({
    super.key,
    required this.hasActivePass,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: hasActivePass
              ? Colors.green.withValues(alpha: 0.12)
              : Colors.orange.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.circle,
              size: 10,
              color: hasActivePass ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 6),
            Text(
              hasActivePass ? 'Actif' : 'Inactif',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: hasActivePass ? Colors.green[800] : Colors.orange[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
