import 'dart:async';

import 'package:delivery_express_mobility_frontend/design_system/index.dart';
import 'package:delivery_express_mobility_frontend/services/delivery_live_service.dart';
import 'package:flutter/material.dart';

/// Panel affichant les livraisons disponibles quand le pass est actif
class ActivePassPanel extends StatefulWidget {
  final DateTime? passValidUntil;
  final List<AvailableDelivery> nearbyDeliveries;

  const ActivePassPanel({
    super.key,
    required this.passValidUntil,
    required this.nearbyDeliveries,
  });

  @override
  State<ActivePassPanel> createState() => _ActivePassPanelState();
}

class _ActivePassPanelState extends State<ActivePassPanel> {
  Timer? _countdownTimer;
  String _timeRemaining = '--h --m';

  @override
  void initState() {
    super.initState();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdownTimer() {
    _updateTimeRemaining();
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        _updateTimeRemaining();
      }
    });
  }

  void _updateTimeRemaining() {
    if (widget.passValidUntil == null) {
      setState(() => _timeRemaining = '--h --m');
      return;
    }

    final now = DateTime.now();
    final difference = widget.passValidUntil!.difference(now);

    if (difference.isNegative) {
      setState(() => _timeRemaining = 'Expiré');
      _countdownTimer?.cancel();
    } else {
      final hours = difference.inHours;
      final minutes = difference.inMinutes.remainder(60);
      setState(() => _timeRemaining = '${hours}h ${minutes}m');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DEMSpacing.md),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.12),
              borderRadius: DEMRadii.borderRadiusMd,
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✅ PASS ACTIF',
                  style: DEMTypography.body1.copyWith(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Expire dans : $_timeRemaining',
                  style: DEMTypography.body2.copyWith(
                    color: DEMColors.gray800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Vous pouvez accepter des livraisons',
                  style: DEMTypography.caption.copyWith(
                    color: DEMColors.gray700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DEMSpacing.lg),
          Text(
            'Livraisons disponibles autour de vous',
            textAlign: TextAlign.center,
            style: DEMTypography.h3.copyWith(
              color: DEMColors.primary,
            ),
          ),
          const SizedBox(height: DEMSpacing.md),
          if (widget.nearbyDeliveries.isNotEmpty)
            Column(
              children: widget.nearbyDeliveries.take(3).map((delivery) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: DEMSpacing.md),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(DEMSpacing.md),
                    decoration: BoxDecoration(
                      color: DEMColors.gray50,
                      borderRadius: DEMRadii.borderRadiusMd,
                      border: Border.all(
                        color: DEMColors.gray200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '📍 ${delivery.pickupAddress}',
                                    style: DEMTypography.body2.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '📍 ${delivery.dropoffAddress}',
                                    style: DEMTypography.body2.copyWith(
                                      color: DEMColors.gray700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: DEMSpacing.md),
                            Text(
                              '${delivery.distance.toStringAsFixed(1)}\nkm',
                              textAlign: TextAlign.center,
                              style: DEMTypography.body2.copyWith(
                                fontWeight: FontWeight.w600,
                                color: DEMColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: DEMSpacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${delivery.price} FCFA',
                              style: DEMTypography.h3.copyWith(
                                color: Colors.green,
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                DEMToast.show(
                                  context: context,
                                  message: '✅ Livraison acceptée',
                                  type: ToastType.success,
                                );
                              },
                              child: const Text('Accepter'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: DEMSpacing.lg),
              child: Text(
                'Aucune livraison disponible pour le moment',
                style: DEMTypography.body2.copyWith(
                  color: DEMColors.gray600,
                ),
              ),
            ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}
