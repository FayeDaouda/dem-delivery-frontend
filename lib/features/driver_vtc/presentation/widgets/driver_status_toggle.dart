import 'package:flutter/material.dart';

/// Chip de statut online/offline
class DriverStatusToggle extends StatelessWidget {
  final bool isOnline;
  final bool isLoading;
  final ValueChanged<bool>? onChanged;

  const DriverStatusToggle({
    super.key,
    required this.isOnline,
    this.isLoading = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : () => onChanged?.call(!isOnline),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isOnline
              ? Colors.green.withValues(alpha: 0.16)
              : Colors.grey.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                isOnline ? Icons.wifi : Icons.wifi_off,
                size: 16,
                color: isOnline ? Colors.green[800] : Colors.grey[800],
              ),
            const SizedBox(width: 6),
            Text(
              isOnline ? 'En ligne' : 'Hors ligne',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isOnline ? Colors.green[800] : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
