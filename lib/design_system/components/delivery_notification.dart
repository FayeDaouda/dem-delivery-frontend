import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import 'glass_panel.dart';

/// 📦 Notification Éphémère pour nouvelles livraisons
/// Style Uber/Bolt/Glovo
class DeliveryNotification extends StatefulWidget {
  final String pickupLocation;
  final String dropoffLocation;
  final String amount;
  final Duration displayDuration;
  final VoidCallback? onDismiss;

  const DeliveryNotification({
    super.key,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.amount,
    this.displayDuration = const Duration(seconds: 4),
    this.onDismiss,
  });

  // Gestionnaire de notifications empilées
  static final List<OverlayEntry> _activeNotifications = [];
  static int _notificationOffset = 0;

  static void show(
    BuildContext context, {
    required String pickupLocation,
    required String dropoffLocation,
    required String amount,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    final currentOffset = _notificationOffset;
    _notificationOffset += 1;

    overlayEntry = OverlayEntry(
      builder: (context) => DeliveryNotificationOverlay(
        pickupLocation: pickupLocation,
        dropoffLocation: dropoffLocation,
        amount: amount,
        verticalOffset: currentOffset * 90.0,
        onDismiss: () {
          overlayEntry.remove();
          _activeNotifications.remove(overlayEntry);
          if (_activeNotifications.isEmpty) {
            _notificationOffset = 0;
          }
        },
      ),
    );

    _activeNotifications.add(overlayEntry);
    overlay.insert(overlayEntry);

    // Auto-dismiss après 4 secondes
    Future.delayed(const Duration(seconds: 4), () {
      if (_activeNotifications.contains(overlayEntry)) {
        overlayEntry.remove();
        _activeNotifications.remove(overlayEntry);
        if (_activeNotifications.isEmpty) {
          _notificationOffset = 0;
        }
      }
    });
  }

  @override
  State<DeliveryNotification> createState() => _DeliveryNotificationState();
}

class _DeliveryNotificationState extends State<DeliveryNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _controller.forward();

    // Auto-dismiss après la durée
    Future.delayed(widget.displayDuration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss?.call();
          if (mounted) Navigator.pop(context);
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 60,
      left: DEMSpacing.lg,
      right: DEMSpacing.lg,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic)),
        child: FadeTransition(
          opacity: _controller,
          child: GestureDetector(
            onTap: () {
              _controller.reverse();
            },
            child: GlassPanel(
              sigmaX: 25,
              sigmaY: 25,
              tintColor: Colors.white,
              opacity: 0.90,
              borderRadius: DEMRadii.borderRadiusLg,
              padding: const EdgeInsets.all(DEMSpacing.lg),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 1,
              ),
              child: Row(
                children: [
                  // Icône livraison
                  Container(
                    decoration: BoxDecoration(
                      color: DEMColors.primary.withValues(alpha: 0.15),
                      borderRadius: DEMRadii.borderRadiusMd,
                    ),
                    padding: const EdgeInsets.all(10),
                    child: const Icon(
                      Icons.local_shipping_rounded,
                      color: DEMColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: DEMSpacing.lg),
                  // Contenu
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '📦 Nouvelle livraison',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: DEMColors.gray700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.pickupLocation,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: DEMColors.gray900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              ' → ',
                              style: TextStyle(
                                fontSize: 12,
                                color: DEMColors.gray500,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                widget.dropoffLocation,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: DEMColors.gray900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: DEMSpacing.md),
                  // Montant
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.amount,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: DEMColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'FCFA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: DEMColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DeliveryNotificationOverlay extends StatefulWidget {
  final String pickupLocation;
  final String dropoffLocation;
  final String amount;
  final double verticalOffset;
  final VoidCallback? onDismiss;

  const DeliveryNotificationOverlay({
    super.key,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.amount,
    this.verticalOffset = 0.0,
    this.onDismiss,
  });

  @override
  State<DeliveryNotificationOverlay> createState() =>
      _DeliveryNotificationOverlayState();
}

class _DeliveryNotificationOverlayState
    extends State<DeliveryNotificationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _controller.forward();

    // Auto-dismiss après 4 secondes
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss?.call();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 60 + widget.verticalOffset,
      left: DEMSpacing.lg,
      right: DEMSpacing.lg,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
        ),
        child: FadeTransition(
          opacity: _controller,
          child: GestureDetector(
            onTap: () {
              _controller.reverse().then((_) {
                widget.onDismiss?.call();
              });
            },
            child: GlassPanel(
              sigmaX: 25,
              sigmaY: 25,
              tintColor: Colors.white,
              opacity: 0.90,
              borderRadius: DEMRadii.borderRadiusLg,
              padding: const EdgeInsets.all(DEMSpacing.lg),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 1,
              ),
              child: Row(
                children: [
                  // Icône livraison
                  Container(
                    decoration: BoxDecoration(
                      color: DEMColors.primary.withValues(alpha: 0.15),
                      borderRadius: DEMRadii.borderRadiusMd,
                    ),
                    padding: const EdgeInsets.all(10),
                    child: const Icon(
                      Icons.local_shipping_rounded,
                      color: DEMColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: DEMSpacing.lg),
                  // Contenu
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '📦 Nouvelle livraison',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: DEMColors.gray700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.pickupLocation,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: DEMColors.gray900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              ' → ',
                              style: TextStyle(
                                fontSize: 12,
                                color: DEMColors.gray500,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                widget.dropoffLocation,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: DEMColors.gray900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: DEMSpacing.md),
                  // Montant
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.amount,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: DEMColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'FCFA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: DEMColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
