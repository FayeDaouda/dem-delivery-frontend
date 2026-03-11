import 'package:delivery_express_mobility_frontend/design_system/index.dart';
import 'package:flutter/material.dart';

/// Widget pour le header flottant premium (partagé)
class FloatingHeaderWidget extends StatelessWidget {
  final String driverName;
  final bool isOnline;
  final bool gpsActive;
  final int batteryLevel;
  final int dailyEarnings;
  final VoidCallback onToggleOnline;
  final VoidCallback onNotificationTap;

  const FloatingHeaderWidget({
    super.key,
    required this.driverName,
    required this.isOnline,
    required this.gpsActive,
    required this.batteryLevel,
    required this.dailyEarnings,
    required this.onToggleOnline,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 8,
      left: 16,
      right: 16,
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        borderRadius: BorderRadius.circular(20),
        opacity: 0.85,
        enableGradient: false,
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: DEMColors.gray100,
                  child: Icon(Icons.person, color: DEMColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Bonjour $driverName',
                    style: DEMTypography.body1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: onToggleOnline,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOnline ? Colors.green : Colors.redAccent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isOnline ? 'En ligne' : 'Hors ligne',
                      style: DEMTypography.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  onPressed: onNotificationTap,
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  gpsActive ? Icons.gps_fixed_rounded : Icons.gps_off_rounded,
                  color: gpsActive ? Colors.green : Colors.redAccent,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  gpsActive ? 'GPS actif' : 'GPS inactif',
                  style: DEMTypography.caption.copyWith(
                    color: DEMColors.gray700,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.battery_5_bar_rounded,
                    size: 16, color: DEMColors.gray700),
                const SizedBox(width: 4),
                Text(
                  '$batteryLevel%',
                  style: DEMTypography.caption.copyWith(
                    color: DEMColors.gray700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: DEMColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '💰 ${dailyEarnings.toString()} FCFA',
                    style: DEMTypography.caption.copyWith(
                      color: DEMColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (!isOnline)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '🚫 Vous ne recevrez pas de livraisons',
                    style: DEMTypography.caption.copyWith(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
