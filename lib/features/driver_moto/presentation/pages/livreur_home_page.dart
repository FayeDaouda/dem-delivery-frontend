import 'dart:async';

import 'package:delivery_express_mobility_frontend/core/di/service_locator.dart';
import 'package:delivery_express_mobility_frontend/core/storage/secure_storage_service.dart';
import 'package:delivery_express_mobility_frontend/design_system/components/glass_draggable_sheet.dart';
import 'package:delivery_express_mobility_frontend/design_system/index.dart';
import 'package:delivery_express_mobility_frontend/features/driver_shared/panels/active_pass_panel.dart';
import 'package:delivery_express_mobility_frontend/features/driver_shared/panels/livreur_panel_state.dart';
import 'package:delivery_express_mobility_frontend/features/driver_shared/panels/pass_activation_panel.dart';
import 'package:delivery_express_mobility_frontend/features/driver_shared/panels/welcome_panel.dart';
import 'package:delivery_express_mobility_frontend/features/driver_shared/widgets/map_controls_widget.dart';
import 'package:delivery_express_mobility_frontend/features/driver_shared/widgets/delivery_badges_widget.dart';
import 'package:delivery_express_mobility_frontend/features/driver_shared/widgets/floating_header_widget.dart';
import 'package:delivery_express_mobility_frontend/features/passes/presentation/bloc/pass_bloc.dart';
import 'package:delivery_express_mobility_frontend/services/delivery_live_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DriverMotoHomePage extends StatelessWidget {
  final String? driverName;
  final String? driverId;

  const DriverMotoHomePage({
    super.key,
    this.driverName,
    this.driverId,
  });

  @override
  Widget build(BuildContext context) {
    return _LivreurHomePageContent(
      driverName: driverName,
      driverId: driverId,
    );
  }
}

typedef LivreurHomePage = DriverMotoHomePage;

class _LivreurHomePageContent extends StatefulWidget {
  final String? driverName;
  final String? driverId;

  const _LivreurHomePageContent({
    required this.driverName,
    required this.driverId,
  });

  @override
  State<_LivreurHomePageContent> createState() =>
      _LivreurHomePageContentState();
}

class _LivreurHomePageContentState extends State<_LivreurHomePageContent>
    with WidgetsBindingObserver {
  final SecureStorageService _storage = getIt<SecureStorageService>();
  final DeliveryLiveService _deliveryLiveService = getIt<DeliveryLiveService>();
  final Dio _dio = getIt<Dio>();
  final PassBloc _passBloc = getIt<PassBloc>();

  String _driverName = 'Livreur';
  String? _driverPhone;
  int _currentNavIndex = 1;
  GoogleMapController? _mapController;
  LivreurPanelState _panelState = LivreurPanelState.welcome;
  bool _isOnline = true;
  bool _gpsActive = true;
  final int _batteryLevel = 78;
  final int _dailyEarnings = 8500;
  List<AvailableDelivery> _nearbyDeliveries = [];
  DateTime? _passValidUntil;
  bool _hasActivePass = false;
  StreamSubscription<List<AvailableDelivery>>? _deliverySubscription;
  Timer? _passStatePollingTimer;
  bool _hasShownPassExpiringSoonAlert = false;
  final Set<String> _shownDeliveryIds = {}; // Pour éviter les doublons notifs

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initDriverContext();
    _startPassStatePolling();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshDriverProfileFromApi(silent: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _deliverySubscription?.cancel();
    _passStatePollingTimer?.cancel();
    _deliveryLiveService.stopListening();
    _deliveryLiveService.dispose();
    super.dispose();
  }

  Future<void> _initDriverContext() async {
    await _initDriverNameAndStatus();
    await _refreshDriverProfileFromApi(silent: true);
    _syncDeliveryListening();
  }

  void _startPassStatePolling() {
    _passStatePollingTimer?.cancel();

    _passBloc.add(const LoadPassStateEvent());
    _passStatePollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      _passBloc.add(const LoadPassStateEvent());
    });
  }

  Future<void> _refreshDriverProfileFromApi({bool silent = false}) async {
    try {
      final response = await _dio.get('/users/me');
      final userFromApi = _extractUserMap(response.data);
      if (userFromApi == null || !mounted) return;

      final phone = userFromApi['phone']?.toString();
      if (phone != null && phone.isNotEmpty) {
        await _storage.saveUser(
          phone: phone,
          name: userFromApi['name']?.toString(),
          fullName: userFromApi['fullName']?.toString(),
          isOnline: _asBool(userFromApi['isOnline']),
          hasActivePass: _asBool(userFromApi['hasActivePass']),
          passExpiresAt: userFromApi['passExpiresAt']?.toString(),
        );
      }

      _applyDriverStateFromUser(userFromApi);
    } catch (_) {
      if (!silent && mounted) {
        DEMToast.show(
          context: context,
          message: 'Impossible de rafraîchir le profil livreur',
          type: ToastType.error,
        );
      }
    }
  }

  Map<String, dynamic>? _extractUserMap(dynamic payload) {
    if (payload is! Map) return null;

    final data = payload['data'];
    if (data is Map<String, dynamic>) {
      final nestedUser = data['user'];
      if (nestedUser is Map<String, dynamic>) return nestedUser;
      return data;
    }

    if (payload is Map<String, dynamic>) {
      final nestedUser = payload['user'];
      if (nestedUser is Map<String, dynamic>) return nestedUser;
      return payload;
    }

    return null;
  }

  void _syncDeliveryListening() {
    final canReceiveDeliveries = _isOnline && _hasActivePass;

    if (!canReceiveDeliveries) {
      _deliverySubscription?.cancel();
      _deliverySubscription = null;
      _deliveryLiveService.stopListening();
      if (mounted) {
        setState(() => _nearbyDeliveries = []);
      }
      _shownDeliveryIds.clear();
      return;
    }

    // Éviter les doubles abonnements
    if (_deliverySubscription != null) return;

    _deliverySubscription =
        _deliveryLiveService.deliveryStream.listen((deliveries) {
      if (!mounted) return;
      setState(() => _nearbyDeliveries = deliveries);

      if (deliveries.isNotEmpty) {
        final delivery = deliveries.first;

        // Toast notification
        DEMToast.show(
          context: context,
          message:
              '📦 Nouvelle livraison • ${delivery.distance.toStringAsFixed(1)} km • ${delivery.price} FCFA',
          type: ToastType.info,
          duration: const Duration(seconds: 2),
        );

        // Show rich notification after toast (800ms delay)
        _showDeliveryNotificationIfNew(delivery);
      }
    });

    _deliveryLiveService.startListening();
  }

  void _showDeliveryNotificationIfNew(AvailableDelivery delivery) {
    if (_shownDeliveryIds.contains(delivery.id)) {
      return;
    }

    _shownDeliveryIds.add(delivery.id);

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        DeliveryNotification.show(
          context,
          pickupLocation: delivery.pickupAddress,
          dropoffLocation: delivery.dropoffAddress,
          amount: delivery.price.toString(),
        );
      }
    });
  }

  Future<void> _initDriverNameAndStatus() async {
    final user = await _storage.getUser();

    if (!mounted) return;

    _applyDriverStateFromUser(user ?? {});
    _showWelcomeNotifications(_driverName);
  }

  void _applyDriverStateFromUser(Map<String, dynamic> user) {
    final rawName = (user['fullName'] ?? user['name'])?.toString().trim();
    final rawPhone = user['phone']?.toString().trim();
    final fromParam = widget.driverName?.trim();

    final nextDriverName = (fromParam != null && fromParam.isNotEmpty)
        ? fromParam
        : ((rawName != null && rawName.isNotEmpty) ? rawName : _driverName);

    final userIsOnline = _asBool(user['isOnline']);
    final hasActivePass = _asBool(user['hasActivePass']);
    final expiresAt = _asDateTime(user['passExpiresAt']);
    final hasValidPass = hasActivePass && _isPassStillValid(expiresAt);

    if (!mounted) return;

    setState(() {
      _driverName = nextDriverName;
      _driverPhone =
          (rawPhone != null && rawPhone.isNotEmpty) ? rawPhone : _driverPhone;
      _hasActivePass = hasValidPass;
      _passValidUntil = hasValidPass ? expiresAt : null;

      if (hasValidPass) {
        _isOnline = true;
        _panelState = LivreurPanelState.activePass;
      } else {
        _isOnline = false;
        _panelState = LivreurPanelState.welcome;
      }

      if (!hasValidPass && userIsOnline) {
        _isOnline = false;
      }
    });

    _syncDeliveryListening();
  }

  bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      final v = value.toLowerCase();
      return v == 'true' || v == '1' || v == 'yes';
    }
    if (value is num) return value == 1;
    return false;
  }

  DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  bool _isPassStillValid(DateTime? passExpiresAt) {
    if (passExpiresAt == null) return false;
    return passExpiresAt.isAfter(DateTime.now());
  }

  void _maybeShowPassExpiringSoonAlert(DateTime? validUntil) {
    if (validUntil == null || !mounted) return;

    final remaining = validUntil.difference(DateTime.now());
    final isExpiringSoon = remaining.inSeconds > 0 && remaining.inMinutes <= 5;

    if (isExpiringSoon && !_hasShownPassExpiringSoonAlert) {
      _hasShownPassExpiringSoonAlert = true;
      DEMToast.show(
        context: context,
        message: '⏰ Votre pass expire dans moins de 5 minutes',
        type: ToastType.warning,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    if (remaining.inMinutes > 5) {
      _hasShownPassExpiringSoonAlert = false;
    }
  }

  void _showWelcomeNotifications(String name) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      DEMToast.show(
        context: context,
        message: 'Bonjour, $name👋',
        type: ToastType.info,
        duration: const Duration(seconds: 3),
      );
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      DEMToast.show(
        context: context,
        message: 'Livrez vos colis rapidement autour de vous',
        type: ToastType.info,
        duration: const Duration(seconds: 3),
      );
    });
  }

  void _handleNavTap(int index) {
    setState(() => _currentNavIndex = index);

    switch (index) {
      case 0:
        DEMToast.show(
          context: context,
          message: 'Activité (Coming Soon)',
          type: ToastType.info,
        );
        break;
      case 1:
        // Home - current page
        break;
      case 2:
        // Profile - Navigate to profile page
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }

  void _toggleOnlineStatus() {
    if (!_hasActivePass) {
      DEMToast.show(
        context: context,
        message: '🔒 Activez un pass valide pour passer en ligne',
        type: ToastType.error,
      );
      return;
    }

    setState(() => _isOnline = !_isOnline);

    if (!_isOnline) {
      setState(() => _panelState = LivreurPanelState.welcome);
      DEMToast.show(
        context: context,
        message: '🔴 Vous êtes hors ligne',
        type: ToastType.warning,
      );
    } else {
      setState(() => _panelState = LivreurPanelState.activePass);
      DEMToast.show(
        context: context,
        message: '🟢 Vous êtes en ligne • Prêt à recevoir des livraisons',
        type: ToastType.success,
      );
    }

    _syncDeliveryListening();
  }

  Future<void> _zoomIn() async {
    if (_mapController != null) {
      await _mapController!.animateCamera(CameraUpdate.zoomIn());
    }
  }

  Future<void> _zoomOut() async {
    if (_mapController != null) {
      await _mapController!.animateCamera(CameraUpdate.zoomOut());
    }
  }

  Future<void> _recenterMap() async {
    if (_mapController != null) {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 5));

        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 15.5,
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        DEMToast.show(
          context: context,
          message: 'Impossible de recentrer',
          type: ToastType.error,
        );
      }
    }
  }

  void _goToKyc() {
    Navigator.pushNamed(context, '/kycSubmission');
  }

  void _activatePassWithMethod({
    required String method,
    String? promoCode,
    String passType = 'daily',
  }) {
    final normalizedMethod = method.toLowerCase();
    final requiresPhone = normalizedMethod == 'wave' ||
        normalizedMethod == 'orange' ||
        normalizedMethod == 'orange_money';

    if (requiresPhone && (_driverPhone == null || _driverPhone!.isEmpty)) {
      DEMToast.show(
        context: context,
        message: 'Numéro requis pour ce moyen de paiement',
        type: ToastType.error,
      );
      return;
    }

    _passBloc.add(ActivatePassEvent(
      passType: passType,
      paymentMethod: normalizedMethod,
      phoneNumber: _driverPhone,
      promoCode: promoCode,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final mapControlsBottom = screenHeight * 0.35;
    final navBarHeight = MediaQuery.of(context).padding.bottom + 75;

    return BlocProvider<PassBloc>.value(
      value: _passBloc,
      child: Scaffold(
        body: BlocListener<PassBloc, PassState>(
          listener: (context, state) {
            if (state is PassActivationSuccess) {
              setState(() {
                _panelState = LivreurPanelState.activePass;
                _passValidUntil = state.validUntil;
                _hasActivePass = true;
                _isOnline = true;
              });

              _syncDeliveryListening();

              // 🎉 Afficher l'animation de succès
              showDialog(
                context: context,
                barrierDismissible: true,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: DEMSpacing.md),
                      const Text(
                        '🎉',
                      ),
                      const SizedBox(height: DEMSpacing.md),
                      Text(
                        'Pass Activé',
                        style: DEMTypography.h3.copyWith(
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: DEMSpacing.sm),
                      Text(
                        'Bonne livraison!',
                        style: DEMTypography.body1.copyWith(
                          color: DEMColors.gray700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: DEMSpacing.lg),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Commencer'),
                      ),
                    ],
                  ),
                ),
              );

              // Toast de succès
              if (mounted) {
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (!mounted || !context.mounted) return;
                  if (mounted) {
                    DEMToast.show(
                      context: context,
                      message: '✅ Vous êtes prêt à recevoir des livraisons',
                      type: ToastType.success,
                      duration: const Duration(seconds: 3),
                    );
                  }
                });
              }
            } else if (state is PassActivationPending) {
              // Paiement en attente - afficher message d'attente
              DEMToast.show(
                context: context,
                message: '⏳ Paiement en cours... Reference: ${state.reference}',
                type: ToastType.warning,
                duration: const Duration(seconds: 5),
              );
              // Rester dans le panel d'activation pour que l'utilisateur puisse voir le statut
              // Le polling GET /passes/current va détecter quand le paiement est confirmé
            } else if (state is PassActive) {
              setState(() {
                _hasActivePass = true;
                _passValidUntil = state.validUntil;
                _panelState = LivreurPanelState.activePass;
                _isOnline = true;
              });
              _maybeShowPassExpiringSoonAlert(state.validUntil);
              _syncDeliveryListening();
            } else if (state is PassInactive) {
              setState(() {
                _hasActivePass = false;
                _passValidUntil = null;
                _panelState = LivreurPanelState.welcome;
                _isOnline = false;
                _hasShownPassExpiringSoonAlert = false;
              });
              _syncDeliveryListening();
            } else if (state is PassError) {
              DEMToast.show(
                context: context,
                message: '❌ ${state.message}',
                type: ToastType.error,
              );
            }
          },
          child: Stack(
            children: [
              /// 🗺 MAP FULLSCREEN
              Positioned.fill(
                child: DynamicMap(
                  showUserLocation: true,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  onLocationUpdated: (position) {
                    if (!_gpsActive && mounted) {
                      setState(() => _gpsActive = true);
                    }
                  },
                ),
              ),

              /// 👤 FLOATING PREMIUM HEADER
              FloatingHeaderWidget(
                driverName: _driverName,
                isOnline: _isOnline,
                gpsActive: _gpsActive,
                batteryLevel: _batteryLevel,
                dailyEarnings: _dailyEarnings,
                onToggleOnline: _toggleOnlineStatus,
                onNotificationTap: () {
                  DEMToast.show(
                    context: context,
                    message: 'Notifications à venir',
                    type: ToastType.info,
                  );
                },
              ),

              /// 📦 DELIVERY BADGES ON MAP (masqués si offline)
              if (_isOnline && _hasActivePass)
                BlocBuilder<PassBloc, PassState>(
                  builder: (context, state) {
                    final isPassActive = state is PassActive;
                    return DeliveryBadgesWidget(
                      deliveries: _nearbyDeliveries,
                      isPassActive: isPassActive,
                    );
                  },
                ),

              /// 🎯 MAP CONTROLS
              MapControlsWidget(
                onRecenter: _recenterMap,
                onZoomIn: _zoomIn,
                onZoomOut: _zoomOut,
                bottomPosition: mapControlsBottom,
              ),

              /// ⚠ WARNINGS (batterie & offline)
              _buildBatteryWarning(),
              _buildOfflineWarning(),

              /// 📄 BOTTOM PANEL - DRAGGABLE
              BlocBuilder<PassBloc, PassState>(
                builder: (context, state) {
                  final isLoading = state is PassLoading;

                  // Panel-specific snap sizes
                  List<double> panelSnapSizes;
                  switch (_panelState) {
                    case LivreurPanelState.welcome:
                      // Welcome panel: short content
                      panelSnapSizes = [0.45, 0.50, 0.51];
                      break;
                    case LivreurPanelState.passActivation:
                      // Pass activation: longer content (3 payment buttons)
                      panelSnapSizes = [0.60, 0.71, 0.72];
                      break;
                    case LivreurPanelState.activePass:
                      // Active pass: dynamic list of deliveries
                      panelSnapSizes = [0.35, 0.45, 0.75];
                      break;
                  }

                  return GlassDraggableSheet(
                    minSize: panelSnapSizes.first,
                    initialSize: panelSnapSizes[1],
                    maxSize: panelSnapSizes.last,
                    snapSizes: panelSnapSizes,
                    tintColor: DEMColors.gray50,
                    opacity: 0.95,
                    enableHandleBar: true,
                    padding: EdgeInsets.fromLTRB(16, 12, 16, navBarHeight),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.3),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: _buildPanelContent(isLoading),
                    ),
                  );
                },
              ),

              /// 🧭 BOTTOM NAV BAR
              FloatingNavBar(
                currentIndex: _currentNavIndex,
                onTap: _handleNavTap,
                items: [
                  FloatingNavItem(
                    icon: Icons.local_activity_rounded,
                    label: 'Activité',
                  ),
                  FloatingNavItem(
                    icon: Icons.home_rounded,
                    label: 'Accueil',
                  ),
                  FloatingNavItem(
                    icon: Icons.account_circle_rounded,
                    label: 'Profil',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🎯 Construit le contenu du panel basé sur l'état
  Widget _buildPanelContent(bool isLoading) {
    switch (_panelState) {
      case LivreurPanelState.welcome:
        return WelcomePanel(
          nearbyDeliveriesCount: _nearbyDeliveries.length,
          onActivatePass: () {
            setState(() => _panelState = LivreurPanelState.passActivation);
          },
          onGoToKyc: _goToKyc,
          hasPass: _hasActivePass,
        );

      case LivreurPanelState.passActivation:
        return PassActivationPanel(
          isLoading: isLoading,
          onBack: () => setState(() => _panelState = LivreurPanelState.welcome),
          onActivate: (paymentMethod, promoCode) {
            switch (paymentMethod) {
              case 'wave':
                _activatePassWithMethod(
                  method: 'wave',
                  promoCode: promoCode,
                );
                break;
              case 'orange':
                _activatePassWithMethod(
                  method: 'orange_money',
                  promoCode: promoCode,
                );
                break;
              case 'yas':
                _activatePassWithMethod(
                  method: 'free_money',
                  promoCode: promoCode,
                );
                break;
              default:
                _activatePassWithMethod(
                  method: 'wave',
                  promoCode: promoCode,
                );
            }
          },
        );

      case LivreurPanelState.activePass:
        return ActivePassPanel(
          passValidUntil: _passValidUntil,
          nearbyDeliveries: _nearbyDeliveries,
        );
    }
  }

  /// ⚠ Afficher warning batterie faible
  Widget _buildBatteryWarning() {
    if (_batteryLevel >= 15) return const SizedBox.shrink();

    return Positioned(
      top: 120,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(DEMSpacing.md),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: DEMRadii.borderRadiusMd,
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.battery_alert, color: Colors.red.shade700, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '⚠ Batterie faible ($_batteryLevel%) - Rechargez votre téléphone',
                style: DEMTypography.body2.copyWith(
                  color: Colors.red.shade900,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔴 Afficher warning offline
  Widget _buildOfflineWarning() {
    if (_isOnline || _hasActivePass) return const SizedBox.shrink();

    return Positioned(
      top: 120,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(DEMSpacing.md),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: DEMRadii.borderRadiusMd,
          border: Border.all(
            color: Colors.orange.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_off, color: Colors.orange.shade700, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '🚫 Vous êtes hors ligne - Activez le statut pour recevoir des livraisons',
                style: DEMTypography.body2.copyWith(
                  color: Colors.orange.shade900,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
