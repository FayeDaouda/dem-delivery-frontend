import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../design_system/index.dart';
import '../../../../features/deliveries/domain/repositories/deliveries_repository.dart';
import '../../../../features/passes/presentation/bloc/pass_bloc.dart';
import '../../../../widgets/top_glass_sheet.dart';
import '../../services/driver_location_service.dart';
import '../../services/driver_rides_service.dart';
import '../../services/driver_stats_service.dart';
import '../bloc/driver_bloc.dart';
import '../bloc/driver_event.dart';
import 'package:delivery_express_mobility_frontend/features/driver_shared/widgets/driver_pass_status.dart';
import '../widgets/driver_payment_chip.dart';
import 'package:delivery_express_mobility_frontend/features/driver_shared/widgets/driver_status_toggle.dart';

/// Page d'accueil refactorisée pour chauffeurs VTC
class DriverVtcHomePage extends StatefulWidget {
  final String? driverName;
  final String? driverId;

  const DriverVtcHomePage({
    super.key,
    this.driverName,
    this.driverId,
  });

  @override
  State<DriverVtcHomePage> createState() => _DriverVtcHomePageState();
}

class _DriverVtcHomePageState extends State<DriverVtcHomePage>
    with SingleTickerProviderStateMixin {
  final SecureStorageService _storage = getIt<SecureStorageService>();
  final Dio _dio = getIt<Dio>();
  final PassBloc _passBloc = getIt<PassBloc>();
  final SocketService _socketService = getIt<SocketService>();
  late final DriverBloc _driverBloc;
  late final DriverLocationService _locationService;

  int _dailyEarnings = 0;
  bool _hasActivePass = false;
  DateTime? _passExpiresAt;
  bool _isOnline = false;
  bool _isTopStatusBarVisible = true;
  bool _isTogglingOnline = false;

  StreamSubscription<WebSocketEvent>? _socketSubscription;
  Timer? _locationEmitTimer;
  Timer? _offerCountdownTimer;
  bool _isSocketAuthenticated = false;
  String? _driverId;
  String? _activeDeliveryId;
  String _activeRideStatus = 'IDLE';
  int _offerExpiresIn = 0;
  Map<String, dynamic>? _activeOffer;

  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(14.6937, -17.4441), // Dakar
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    _locationService = DriverLocationService(dio: _dio);
    _driverBloc = DriverBloc(
      locationService: _locationService,
      ridesService: DriverRidesService(
        dio: _dio,
        deliveriesRepository: getIt<DeliveriesRepository>(),
      ),
      statsService: DriverStatsService(dio: _dio),
    );

    _passBloc.add(const LoadPassStateEvent());
    _initDriver();
    _initRealtimeFlow();
  }

  @override
  void dispose() {
    _offerCountdownTimer?.cancel();
    _locationEmitTimer?.cancel();
    _socketSubscription?.cancel();
    _socketService.disconnect();
    _locationService.stopLocationTracking();
    _driverBloc.close();
    super.dispose();
  }

  Future<void> _initDriver() async {
    _driverBloc.add(const InitializeDriverEvent());
    final user = await _storage.getUser() ?? {};
    _applyUserData(user);
  }

  void _applyUserData(Map<String, dynamic> user) {
    final hasPass = _asBool(user['hasActivePass']);
    final expiresAt = _asDateTime(user['passExpiresAt']);
    final hasValidPass = hasPass && _isPassStillValid(expiresAt);

    if (!mounted) return;
    setState(() {
      _hasActivePass = hasValidPass;
      _passExpiresAt = hasValidPass ? expiresAt : null;
      _isOnline = _asBool(user['isOnline']);
      _dailyEarnings = _asInt(
        user['dailyEarnings'] ??
            user['dailyEarningsToday'] ??
            user['todayGain'],
      );
    });

    _syncRealtimeTrackingState();
  }

  Future<void> _initRealtimeFlow() async {
    final accessToken = await _storage.getAccessToken();
    final driverData = await _storage.getDriverData();

    _driverId = widget.driverId ?? driverData['id'];
    if (_driverId == null || _driverId!.trim().isEmpty) return;
    if (accessToken == null || accessToken.trim().isEmpty) return;

    final wsUrl = _buildWebSocketUrl(
      _dio.options.baseUrl,
      useTrackingNamespace: false,
    );
    _socketSubscription = _socketService.events.listen(_onSocketEvent);

    try {
      await _socketService.connect(wsUrl, accessToken);
      _socketService.emit('user:authenticate', {
        'token': accessToken,
        'userId': _driverId,
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connexion temps réel indisponible')),
      );
    }
  }

  String _buildWebSocketUrl(
    String baseUrl, {
    required bool useTrackingNamespace,
  }) {
    var wsBase = baseUrl.trim();
    if (wsBase.endsWith('/')) {
      wsBase = wsBase.substring(0, wsBase.length - 1);
    }

    final namespaceBase = useTrackingNamespace ? '$wsBase/tracking' : wsBase;
    return namespaceBase;
  }

  void _onSocketEvent(WebSocketEvent event) {
    final name = event.name.toLowerCase();
    final data = event.data;

    if (name == 'user:authenticated') {
      _isSocketAuthenticated = true;
      _syncRealtimeTrackingState();
      return;
    }

    if (name == 'driver:location:received') {
      return;
    }

    if (name == 'delivery:offer') {
      _onDeliveryOffer(data);
      return;
    }

    if (name == 'delivery:accepted') {
      _activeRideStatus = 'ACCEPTED';
      if (mounted) setState(() {});
      return;
    }

    if (name == 'delivery:picked_up') {
      _activeRideStatus = 'PICKED_UP';
      if (mounted) setState(() {});
      return;
    }

    if (name == 'delivery:delivered') {
      _activeRideStatus = 'DELIVERED';
      _activeDeliveryId = null;
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course terminée ✅')),
        );
      }
      return;
    }

    if (name == 'delivery:status:changed') {
      final nextStatus = data['status']?.toString().toUpperCase();
      if (nextStatus != null && nextStatus.isNotEmpty) {
        _activeRideStatus = nextStatus;
        if (mounted) setState(() {});
      }
      return;
    }

    final errorCode = data['code']?.toString().toUpperCase();
    if (errorCode == 'PASS_REQUIRED' ||
        errorCode == 'DELIVERY_ALREADY_ASSIGNED' ||
        errorCode == 'RATE_LIMITED') {
      final message = _mapSocketError(errorCode!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  String _mapSocketError(String code) {
    switch (code) {
      case 'PASS_REQUIRED':
        return 'Pass requis pour recevoir des courses.';
      case 'DELIVERY_ALREADY_ASSIGNED':
        return 'Course déjà attribuée à un autre chauffeur.';
      case 'RATE_LIMITED':
        return 'Trop de requêtes. Réessayez dans quelques secondes.';
      default:
        return 'Erreur temps réel.';
    }
  }

  void _onDeliveryOffer(Map<String, dynamic> payload) {
    final deliveryId =
        payload['deliveryId']?.toString() ?? payload['id']?.toString();
    if (deliveryId == null || deliveryId.isEmpty) return;

    final reward =
        payload['reward'] ?? payload['amount'] ?? payload['price'] ?? 0;
    final pickup = payload['pickupLocation'];
    final dropoff = payload['dropoffLocation'];
    final expires = (payload['expiresIn'] as num?)?.toInt() ?? 30;

    _offerCountdownTimer?.cancel();
    _offerExpiresIn = expires;
    _activeOffer = {
      'deliveryId': deliveryId,
      'reward': reward,
      'pickupLocation': pickup,
      'dropoffLocation': dropoff,
      'estimatedDistance': payload['estimatedDistance'],
    };

    if (mounted) setState(() {});

    _offerCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_offerExpiresIn <= 1) {
        timer.cancel();
        setState(() {
          _offerExpiresIn = 0;
          _activeOffer = null;
        });
        return;
      }
      setState(() => _offerExpiresIn -= 1);
    });
  }

  void _syncRealtimeTrackingState() {
    final shouldTrack = _isOnline && _hasActivePass && _isSocketAuthenticated;
    if (!shouldTrack) {
      _locationEmitTimer?.cancel();
      _locationEmitTimer = null;
      return;
    }

    if (_locationEmitTimer != null) return;

    _emitDriverLocation();
    _locationEmitTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      _emitDriverLocation();
    });
  }

  Future<void> _emitDriverLocation() async {
    if (_driverId == null || _driverId!.isEmpty) return;
    final pos = await _locationService.getCurrentLocation();
    if (pos == null) return;

    final zone =
        '${pos.latitude.toStringAsFixed(2)}_${pos.longitude.toStringAsFixed(2)}';

    _socketService.emit('driver:location:update', {
      'driverId': _driverId,
      'lat': pos.latitude,
      'lon': pos.longitude,
      'zone': zone,
    });
  }

  void _acceptCurrentOffer() {
    final offer = _activeOffer;
    if (offer == null || _driverId == null) return;
    final deliveryId = offer['deliveryId']?.toString();
    if (deliveryId == null || deliveryId.isEmpty) return;

    _socketService.emit('delivery:offer:accepted', {
      'deliveryId': deliveryId,
      'driverId': _driverId,
    });
    _socketService.emit('delivery:join', {
      'deliveryId': deliveryId,
      'driverId': _driverId,
    });

    _offerCountdownTimer?.cancel();
    setState(() {
      _activeDeliveryId = deliveryId;
      _activeRideStatus = 'ACCEPTED';
      _activeOffer = null;
      _offerExpiresIn = 0;
    });
  }

  void _rejectCurrentOffer() {
    final offer = _activeOffer;
    if (offer == null || _driverId == null) return;
    final deliveryId = offer['deliveryId']?.toString();
    if (deliveryId == null || deliveryId.isEmpty) return;

    _socketService.emit('delivery:offer:rejected', {
      'deliveryId': deliveryId,
      'driverId': _driverId,
    });

    _offerCountdownTimer?.cancel();
    setState(() {
      _activeOffer = null;
      _offerExpiresIn = 0;
    });
  }

  void _markPickedUp() {
    if (_activeDeliveryId == null || _driverId == null) return;
    _socketService.emit('delivery:picked_up', {
      'deliveryId': _activeDeliveryId,
      'driverId': _driverId,
    });
    setState(() => _activeRideStatus = 'PICKED_UP');
  }

  void _markDelivered() {
    if (_activeDeliveryId == null || _driverId == null) return;
    _socketService.emit('delivery:delivered', {
      'deliveryId': _activeDeliveryId,
      'driverId': _driverId,
    });
    setState(() {
      _activeRideStatus = 'DELIVERED';
      _activeDeliveryId = null;
    });
  }

  bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.toLowerCase();
      return v == 'true' || v == '1' || v == 'yes';
    }
    return false;
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  DateTime? _asDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  bool _isPassStillValid(DateTime? expiresAt) {
    if (expiresAt == null) return _hasActivePass;
    return expiresAt.isAfter(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: _defaultPosition,
              onMapCreated:
                  (_) {}, // Carte non utilisée pour la refactorisation
            ),
          ),
          // Barre de statut
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedSlide(
              offset:
                  _isTopStatusBarVisible ? Offset.zero : const Offset(1.1, 0),
              duration: const Duration(milliseconds: 280),
              child: AnimatedOpacity(
                opacity: _isTopStatusBarVisible ? 1 : 0,
                duration: const Duration(milliseconds: 220),
                child: IgnorePointer(
                  ignoring: !_isTopStatusBarVisible,
                  child: _buildTopBar(),
                ),
              ),
            ),
          ),
          // Bouton collapse/expand
          Positioned(
            top: MediaQuery.of(context).padding.top + 14,
            right: 0,
            child: _buildToggleButton(),
          ),
          // Bouton action bas
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: _buildBottomActionButton(),
          ),
          if (_activeOffer != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 94,
              child: _buildOfferCard(),
            ),
          if (_activeDeliveryId != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: _activeOffer != null ? 220 : 94,
              child: _buildRideTrackingCard(),
            ),
        ],
      ),
    );
  }

  Widget _buildOfferCard() {
    final offer = _activeOffer!;
    final pickup = offer['pickupLocation'];
    final dropoff = offer['dropoffLocation'];
    final reward = offer['reward'];
    final distance = offer['estimatedDistance'];

    String pickupText;
    if (pickup is Map) {
      pickupText = pickup['address']?.toString() ?? 'Point de départ';
    } else {
      pickupText = pickup?.toString() ?? 'Point de départ';
    }

    String dropoffText;
    if (dropoff is Map) {
      dropoffText = dropoff['address']?.toString() ?? 'Destination';
    } else {
      dropoffText = dropoff?.toString() ?? 'Destination';
    }

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DEMColors.primary.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_taxi, color: DEMColors.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Nouvelle offre VTC',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text('$_offerExpiresIn s'),
              ],
            ),
            const SizedBox(height: 8),
            Text('Départ: $pickupText'),
            Text('Arrivée: $dropoffText'),
            Text('Gain: $reward FCFA'),
            if (distance != null) Text('Distance estimée: $distance km'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _rejectCurrentOffer,
                    child: const Text('Refuser'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _acceptCurrentOffer,
                    child: const Text('Accepter'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideTrackingCard() {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text('Course: $_activeRideStatus'),
            ),
            TextButton(
              onPressed: _markPickedUp,
              child: const Text('Pickup'),
            ),
            ElevatedButton(
              onPressed: _markDelivered,
              child: const Text('Livrée'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      margin: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 0,
      ),
      padding: const EdgeInsets.all(DEMSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DEMSpacing.sm),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          DriverPassStatus(
            hasActivePass: _hasActivePass,
            onTap:
                _hasActivePass ? null : () => _showCurrentPassesWidget(context),
          ),
          const SizedBox(width: DEMSpacing.xs),
          _buildGainsChip(),
          const SizedBox(width: DEMSpacing.xs),
          DriverStatusToggle(
            isOnline: _isOnline,
            isLoading: _isTogglingOnline,
            onChanged: _hasActivePass
                ? _toggleOnlineStatus
                : (v) => _showPassRequiredForOnlineSheet(),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: 50),
            child: _buildProfileButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () =>
            setState(() => _isTopStatusBarVisible = !_isTopStatusBarVisible),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(999),
          bottomLeft: Radius.circular(999),
        ),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(999),
              bottomLeft: Radius.circular(999),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            _isTopStatusBarVisible
                ? Icons.keyboard_arrow_right_rounded
                : Icons.keyboard_arrow_left_rounded,
            color: Colors.blue,
            size: 32,
          ),
        ),
      ),
    );
  }

  Widget _buildGainsChip() {
    return InkWell(
      onTap: () => _showEarningsSheet(),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: DEMColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.payments_rounded,
                size: 16, color: DEMColors.primary),
            const SizedBox(width: 6),
            Text(
              '$_dailyEarnings FCFA',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: DEMColors.primary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileButton() {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/profile'),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: DEMColors.gray300, width: 1.5),
        ),
        child: const ClipOval(
          child: Icon(
            Icons.account_circle,
            size: 36,
            color: DEMColors.gray500,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActionButton() {
    final hasPass = _hasActivePass && _isPassStillValid(_passExpiresAt);

    return ElevatedButton(
      onPressed: hasPass ? null : () => _showCurrentPassesWidget(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: hasPass ? DEMColors.gray700 : DEMColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DEMSpacing.sm),
        ),
        elevation: 4,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(hasPass ? Icons.timelapse_rounded : Icons.workspace_premium),
          const SizedBox(width: 8),
          Text(
            hasPass ? 'En attente de course' : 'Activer un pass',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleOnlineStatus(bool value) async {
    setState(() => _isTogglingOnline = true);
    try {
      _driverBloc.add(ToggleOnlineStatusEvent(value));
      if (!mounted) return;
      setState(() => _isOnline = value);
      _syncRealtimeTrackingState();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors du changement de statut')),
      );
    } finally {
      if (mounted) setState(() => _isTogglingOnline = false);
    }
  }

  void _showEarningsSheet() {
    TopGlassSheetSlideIn.show(
      context: context,
      title: 'Vos gains',
      child: Padding(
        padding: const EdgeInsets.all(DEMSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(DEMSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.payments_rounded,
                      size: 36, color: Colors.green),
                  const SizedBox(height: DEMSpacing.sm),
                  Text(
                    '$_dailyEarnings FCFA',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: DEMSpacing.xs),
                  Text(
                    'Gains aujourd\'hui',
                    style: DEMTypography.body2.copyWith(
                      color: DEMColors.gray700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPassRequiredForOnlineSheet() {
    TopGlassSheetSlideIn.show(
      context: context,
      title: 'Pass requis',
      child: Padding(
        padding: const EdgeInsets.all(DEMSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 44, color: Colors.orange),
            const SizedBox(height: DEMSpacing.md),
            Text(
              'Vous devez activer un pass pour vous mettre en ligne.',
              textAlign: TextAlign.center,
              style: DEMTypography.body1.copyWith(color: DEMColors.gray700),
            ),
            const SizedBox(height: DEMSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showCurrentPassesWidget(context);
                },
                icon: const Icon(Icons.workspace_premium),
                label: const Text('Activer un pass'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DEMColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: DEMSpacing.sm),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrentPassesWidget(BuildContext context) {
    final passes = [
      {
        'name': 'Pass Journalier',
        'duration': '24 heures',
        'price': 1000,
        'description': 'Recevez des demandes de courses pendant 24 heures',
      },
      {
        'name': 'Pass Hebdomadaire',
        'duration': '7 jours',
        'price': 5000,
        'description': 'Recevez des demandes de courses pendant 7 jours',
      },
    ];

    TopGlassSheet.show(
      context: context,
      title: 'Choisir un pass',
      minSize: 0.3,
      initialSize: 0.5,
      maxSize: 0.7,
      child: Builder(
        builder: (sheetContext) {
          return Padding(
            padding: const EdgeInsets.all(DEMSpacing.md),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: passes
                    .map(
                      (pass) => Padding(
                        padding: const EdgeInsets.only(bottom: DEMSpacing.md),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(sheetContext);
                            _showPassCheckout(
                              context,
                              pass['name']!.toString(),
                              pass['duration']!.toString(),
                              pass['price'] as int,
                              pass['description']!.toString(),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(DEMSpacing.lg),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: DEMColors.primary.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pass['name']!.toString(),
                                  style: DEMTypography.subtitle1.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: DEMColors.primary,
                                  ),
                                ),
                                const SizedBox(height: DEMSpacing.sm),
                                Text(
                                  pass['description']!.toString(),
                                  style: DEMTypography.body2.copyWith(
                                    color: DEMColors.gray700,
                                  ),
                                ),
                                const SizedBox(height: DEMSpacing.md),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Durée',
                                          style: DEMTypography.caption.copyWith(
                                            color: DEMColors.gray600,
                                          ),
                                        ),
                                        Text(
                                          pass['duration']!.toString(),
                                          style: DEMTypography.body2.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Prix',
                                          style: DEMTypography.caption.copyWith(
                                            color: DEMColors.gray600,
                                          ),
                                        ),
                                        Text(
                                          '${pass['price']} FCFA',
                                          style: DEMTypography.body2.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: DEMColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPassCheckout(
    BuildContext context,
    String passName,
    String duration,
    int price,
    String description,
  ) {
    String promoCode = '';
    String selectedMethod = 'wave';
    int finalAmount = price;
    int discountAmount = 0;
    bool isVerifyingPromo = false;
    bool promoValidated = false;
    String? promoMessage;

    TopGlassSheet.show(
      context: context,
      title: 'Finaliser l\'achat',
      minSize: 0.4,
      initialSize: 0.7,
      maxSize: 0.9,
      child: StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return Padding(
            padding: const EdgeInsets.all(DEMSpacing.md),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(DEMSpacing.lg),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: DEMColors.primary.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(passName,
                            style: DEMTypography.subtitle1.copyWith(
                              fontWeight: FontWeight.w700,
                              color: DEMColors.primary,
                            )),
                        const SizedBox(height: DEMSpacing.sm),
                        Text(description,
                            style: DEMTypography.body2.copyWith(
                              color: DEMColors.gray700,
                            )),
                        const SizedBox(height: DEMSpacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Durée',
                                    style: DEMTypography.caption.copyWith(
                                      color: DEMColors.gray600,
                                    )),
                                Text(duration,
                                    style: DEMTypography.body2.copyWith(
                                      fontWeight: FontWeight.w600,
                                    )),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Prix',
                                    style: DEMTypography.caption.copyWith(
                                      color: DEMColors.gray600,
                                    )),
                                Text('$price FCFA',
                                    style: DEMTypography.body2.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: DEMColors.primary,
                                    )),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DEMSpacing.lg),
                  TextField(
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (value) => promoCode = value,
                    decoration: InputDecoration(
                      labelText: 'Code promo (optionnel)',
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DEMSpacing.sm),
                        borderSide:
                            const BorderSide(color: Colors.blue, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DEMSpacing.sm),
                        borderSide:
                            const BorderSide(color: Colors.blue, width: 2.5),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DEMSpacing.sm),
                        borderSide:
                            const BorderSide(color: Colors.blue, width: 2),
                      ),
                      prefixIcon:
                          const Icon(Icons.local_offer, color: Colors.blue),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: DEMSpacing.sm),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DEMColors.primary,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: DEMSpacing.sm),
                      elevation: 2,
                    ),
                    onPressed: isVerifyingPromo
                        ? null
                        : () async {
                            final code = promoCode.trim();
                            if (code.isEmpty) {
                              setSheetState(() {
                                promoValidated = false;
                                discountAmount = 0;
                                finalAmount = price;
                                promoMessage = 'Saisissez un code promo.';
                              });
                              return;
                            }

                            setSheetState(() {
                              isVerifyingPromo = true;
                              promoMessage = null;
                            });

                            try {
                              final response = await _dio.post(
                                '/promo-codes/validate',
                                data: {'code': code, 'amount': price},
                              );

                              final data = response.data;
                              final promoData =
                                  data is Map ? (data['data'] as Map?) : null;
                              final applicableDiscount =
                                  (promoData?['applicableDiscount'] as num?)
                                          ?.toInt() ??
                                      0;
                              final computedFinal =
                                  (promoData?['finalAmount'] as num?)
                                          ?.toInt() ??
                                      (price - applicableDiscount);

                              setSheetState(() {
                                promoValidated = true;
                                discountAmount = applicableDiscount;
                                finalAmount =
                                    computedFinal < 0 ? 0 : computedFinal;
                                promoMessage =
                                    data is Map && data['message'] != null
                                        ? data['message'].toString()
                                        : 'Code promo valide.';
                              });
                            } catch (e) {
                              setSheetState(() {
                                promoValidated = false;
                                discountAmount = 0;
                                finalAmount = price;
                                promoMessage = 'Code promo invalide.';
                              });
                            } finally {
                              setSheetState(() => isVerifyingPromo = false);
                            }
                          },
                    icon: isVerifyingPromo
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.verified),
                    label: const Text('Vérifier le code'),
                  ),
                  if (promoMessage != null) ...[
                    const SizedBox(height: DEMSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(DEMSpacing.sm),
                      decoration: BoxDecoration(
                        color: promoValidated
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(DEMSpacing.xs),
                        border: Border.all(
                          color: promoValidated ? Colors.green : Colors.red,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            promoValidated ? Icons.check_circle : Icons.error,
                            color: promoValidated ? Colors.green : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: DEMSpacing.sm),
                          Expanded(
                            child: Text(
                              promoMessage!,
                              style: DEMTypography.body2.copyWith(
                                color: promoValidated
                                    ? Colors.green[700]
                                    : Colors.red[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: DEMSpacing.lg),
                  Text(
                    'Mode de paiement',
                    style: DEMTypography.subtitle1.copyWith(
                      fontWeight: FontWeight.bold,
                      color: DEMColors.gray900,
                    ),
                  ),
                  const SizedBox(height: DEMSpacing.sm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      DriverPaymentChip(
                        label: 'Wave',
                        isSelected: selectedMethod == 'wave',
                        backgroundColor: const Color(0xFF29B6F6),
                        textColor: Colors.white,
                        onTap: () =>
                            setSheetState(() => selectedMethod = 'wave'),
                      ),
                      DriverPaymentChip(
                        label: 'Orange Money',
                        isSelected: selectedMethod == 'orange_money',
                        backgroundColor: const Color.fromARGB(255, 232, 139, 0),
                        textColor: Colors.black,
                        onTap: () => setSheetState(
                            () => selectedMethod = 'orange_money'),
                      ),
                      DriverPaymentChip(
                        label: 'Yas',
                        isSelected: selectedMethod == 'yas',
                        backgroundColor: const Color.fromARGB(255, 255, 247, 0),
                        textColor: Colors.blue,
                        onTap: () =>
                            setSheetState(() => selectedMethod = 'yas'),
                      ),
                    ],
                  ),
                  const SizedBox(height: DEMSpacing.lg),
                  if (discountAmount > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Remise:',
                          style: DEMTypography.body2.copyWith(
                            color: DEMColors.gray700,
                          ),
                        ),
                        Text(
                          '-$discountAmount FCFA',
                          style: DEMTypography.body2.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: DEMSpacing.sm),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total:',
                        style: DEMTypography.body1.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$finalAmount FCFA',
                        style: DEMTypography.h3.copyWith(
                          fontWeight: FontWeight.bold,
                          color: DEMColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DEMSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final storage = getIt<SecureStorageService>();
                        final user = await storage.getUser();
                        final phone = user?['phone']?.toString();

                        if (!sheetContext.mounted) return;
                        Navigator.pop(sheetContext);

                        final passType = duration.contains('24') ||
                                duration.contains('1 jour')
                            ? 'daily'
                            : 'weekly';

                        _passBloc.add(
                          ActivatePassEvent(
                            paymentMethod: selectedMethod,
                            passType: passType,
                            phoneNumber: phone,
                            promoCode: promoCode.trim().isEmpty
                                ? null
                                : promoCode.trim(),
                            clientRequestId:
                                'vtc-${DateTime.now().millisecondsSinceEpoch}',
                          ),
                        );
                      },
                      icon: const Icon(Icons.shopping_cart),
                      label: Text(
                        'Acheter ($finalAmount FCFA)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DEMColors.primary,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: DEMSpacing.md),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(DEMSpacing.sm),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
