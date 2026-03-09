import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/di/service_locator.dart';
import '../core/storage/secure_storage_service.dart';
import '../design_system/index.dart';
import '../features/passes/presentation/bloc/pass_bloc.dart';
import '../widgets/top_glass_sheet.dart';

/// Page d'accueil pour les chauffeurs VTC
/// Affichée lorsque role=DRIVER et driverType=VTC
class DriverVtcHomePage extends StatelessWidget {
  final String? driverName;
  final String? driverId;

  const DriverVtcHomePage({
    super.key,
    this.driverName,
    this.driverId,
  });

  @override
  Widget build(BuildContext context) {
    return _DriverVtcHomeContent(
      driverName: driverName,
      driverId: driverId,
    );
  }
}

class _DriverVtcHomeContent extends StatefulWidget {
  final String? driverName;
  final String? driverId;

  const _DriverVtcHomeContent({
    required this.driverName,
    required this.driverId,
  });

  @override
  State<_DriverVtcHomeContent> createState() => _DriverVtcHomeContentState();
}

class _DriverVtcHomeContentState extends State<_DriverVtcHomeContent>
    with SingleTickerProviderStateMixin {
  final SecureStorageService _storage = getIt<SecureStorageService>();
  final Dio _dio = getIt<Dio>();
  final PassBloc _passBloc = getIt<PassBloc>();

  String? _profilePhotoUrl;
  GoogleMapController? _mapController;
  Position? _currentPosition;
  int _dailyEarnings = 0;
  bool _hasActivePass = false;
  DateTime? _passExpiresAt;
  bool _isOnline = false;
  bool _locationPermissionGranted = false;
  bool _isTogglingOnline = false;
  bool _isTopStatusBarVisible = true;
  late AnimationController _pulseController;

  // Suivi GPS en temps réel
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _locationSyncTimer;
  Timer? _topBarAutoHideTimer;

  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(14.6937, -17.4441), // Dakar
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Préchargement non bloquant pour éviter le spinner au clic sur "Activer un pass"
    _passBloc.add(const LoadPassStateEvent());
    _startTopBarAutoHideTimer();
    _initDriverContext();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _positionStreamSubscription?.cancel();
    _locationSyncTimer?.cancel();
    _topBarAutoHideTimer?.cancel();
    super.dispose();
  }

  void _startTopBarAutoHideTimer() {
    _topBarAutoHideTimer?.cancel();
    _topBarAutoHideTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() {
        _isTopStatusBarVisible = false;
      });
    });
  }

  void _toggleTopStatusBar() {
    if (!mounted) return;
    setState(() {
      _isTopStatusBarVisible = !_isTopStatusBarVisible;
    });
  }

  Future<void> _initDriverContext() async {
    final user = await _storage.getUser() ?? {};
    _applyUserData(user);
    await _refreshDriverProfileFromApi();

    final canUseLocation = await _ensureLocationAccess();
    if (!mounted) return;
    setState(() {
      _locationPermissionGranted = canUseLocation;
    });
    if (!canUseLocation) return;

    await _getCurrentLocation();
    _startLocationTracking();
  }

  Future<bool> _ensureLocationAccess() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('❌ Service de localisation désactivé');
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      debugPrint('❌ Permission de localisation refusée: $permission');
      return false;
    }

    return true;
  }

  Future<void> _refreshDriverProfileFromApi() async {
    try {
      final response = await _dio.get('/users/me');
      final user = _extractUserMap(response.data);
      if (user == null) return;

      final phone = user['phone']?.toString();
      if (phone != null && phone.isNotEmpty) {
        await _storage.saveUser(
          phone: phone,
          name: user['name']?.toString(),
          fullName: user['fullName']?.toString(),
          isOnline: _asBool(user['isOnline']),
          hasActivePass: _asBool(user['hasActivePass']),
          passExpiresAt: user['passExpiresAt']?.toString(),
        );
      }

      _applyUserData(user);
    } catch (e) {
      debugPrint('⚠️ VTC /users/me indisponible: $e');
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
      _profilePhotoUrl =
          user['profilePhoto'] ?? user['photoUrl'] ?? user['avatar'];
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

  String get _activityLabel => _hasActivePass ? 'Actif' : 'Inactif';

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      setState(() {
        _currentPosition = position;
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(position.latitude, position.longitude),
        ),
      );
    } catch (e) {
      debugPrint('❌ Erreur localisation: $e');
    }
  }

  /// Démarre le suivi GPS en temps réel
  void _startLocationTracking() {
    // 1. Stream de positions GPS (mise à jour continue)
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Mise à jour tous les 10 mètres
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        if (!mounted) return;
        setState(() {
          _currentPosition = position;
        });

        // Centrer la carte sur la nouvelle position
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(position.latitude, position.longitude),
          ),
        );

        debugPrint(
            '📍 Position mise à jour: ${position.latitude}, ${position.longitude}');
      },
      onError: (e) {
        debugPrint('❌ Erreur stream GPS: $e');
      },
    );

    // 2. Timer pour envoyer la position au backend toutes les 10 secondes
    _locationSyncTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _syncLocationToBackend(),
    );
  }

  /// Envoie la position actuelle au backend (dispatch des courses)
  Future<void> _syncLocationToBackend() async {
    // Envoyer uniquement si le driver est online
    if (!_isOnline || _currentPosition == null) return;

    try {
      await _dio.patch(
        '/users/me/location',
        data: {
          'latitude': _currentPosition!.latitude,
          'longitude': _currentPosition!.longitude,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      debugPrint(
          '✅ Position envoyée au backend: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
    } catch (e) {
      debugPrint('⚠️ Échec envoi localisation: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: _defaultPosition,
              myLocationEnabled: _locationPermissionGranted,
              myLocationButtonEnabled: false,
              zoomGesturesEnabled: true,
              scrollGesturesEnabled: true,
              rotateGesturesEnabled: true,
              tiltGesturesEnabled: true,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
                if (_currentPosition != null) {
                  controller.animateCamera(
                    CameraUpdate.newLatLng(
                      LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                    ),
                  );
                }
              },
            ),
          ),

          // Barre d'état en haut
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedSlide(
              offset:
                  _isTopStatusBarVisible ? Offset.zero : const Offset(1.1, 0),
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOut,
              child: AnimatedOpacity(
                opacity: _isTopStatusBarVisible ? 1 : 0,
                duration: const Duration(milliseconds: 220),
                child: IgnorePointer(
                  ignoring: !_isTopStatusBarVisible,
                  child: _buildTopStatusBar(),
                ),
              ),
            ),
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 14,
            right: 0,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _toggleTopStatusBar,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(999),
                  bottomLeft: Radius.circular(999),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.94),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(999),
                      bottomLeft: Radius.circular(999),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    height: 54,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 11,
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
                ),
              ),
            ),
          ),

          // Bouton bas dynamique selon pass
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: _buildBottomActionButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopStatusBar() {
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
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatusChip(),
          const SizedBox(width: DEMSpacing.xs),
          _buildGainsChip(),
          const SizedBox(width: DEMSpacing.xs),
          _buildAvailabilityChip(),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: 50),
            child: _buildProfileButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    return InkWell(
      onTap: () {
        if (!_hasActivePass) {
          _showPassRequiredSheet();
        }
      },
      borderRadius: BorderRadius.circular(999),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _hasActivePass
                  ? Colors.green
                      .withOpacity(0.12 + (_pulseController.value * 0.08))
                  : Colors.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 10,
                  color: _hasActivePass ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 6),
                Text(
                  _activityLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color:
                        _hasActivePass ? Colors.green[800] : Colors.orange[800],
                  ),
                ),
              ],
            ),
          );
        },
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
          color: DEMColors.primary.withOpacity(0.12),
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

  Widget _buildAvailabilityChip() {
    final isOnline = _isOnline;
    return InkWell(
      onTap: _isTogglingOnline
          ? null
          : () {
              if (!_hasActivePass) {
                _showPassRequiredForOnlineSheet();
              } else {
                _toggleOnlineStatus();
              }
            },
      borderRadius: BorderRadius.circular(999),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isOnline
                  ? Colors.green
                      .withOpacity(0.16 + (_pulseController.value * 0.08))
                  : Colors.grey.withOpacity(0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isTogglingOnline)
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
          );
        },
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
          border: Border.all(
            color: DEMColors.gray300,
            width: 1.5,
          ),
        ),
        child: ClipOval(
          child: _profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty
              ? Image.network(
                  _profilePhotoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.account_circle,
                      size: 36,
                      color: DEMColors.gray500,
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  },
                )
              : const Icon(
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
      onPressed: hasPass
          ? null
          : () {
              _showCurrentPassesWidget(context);
            },
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
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Afficher un top sheet pour informer qu'un pass est requis
  void _showPassRequiredSheet() {
    TopGlassSheetSlideIn.show(
      context: context,
      title: 'Pass requis',
      child: Padding(
        padding: const EdgeInsets.all(DEMSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.card_membership,
              size: 44,
              color: Colors.orange,
            ),
            const SizedBox(height: DEMSpacing.md),
            Text(
              'Vous devez activer un pass pour devenir actif et recevoir des courses.',
              textAlign: TextAlign.center,
              style: DEMTypography.body1.copyWith(
                color: DEMColors.gray700,
              ),
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

  // Afficher les détails des gains
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
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.payments_rounded,
                    size: 36,
                    color: Colors.green,
                  ),
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
            const SizedBox(height: DEMSpacing.md),
            Text(
              'Continuez à accepter des courses pour augmenter vos gains !',
              textAlign: TextAlign.center,
              style: DEMTypography.body2.copyWith(
                color: DEMColors.gray600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Afficher un top sheet pour informer qu'un pass est requis pour être en ligne
  void _showPassRequiredForOnlineSheet() {
    TopGlassSheetSlideIn.show(
      context: context,
      title: 'Pass requis',
      child: Padding(
        padding: const EdgeInsets.all(DEMSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off,
              size: 44,
              color: Colors.orange,
            ),
            const SizedBox(height: DEMSpacing.md),
            Text(
              'Vous devez activer un pass pour vous mettre en ligne et recevoir des courses.',
              textAlign: TextAlign.center,
              style: DEMTypography.body1.copyWith(
                color: DEMColors.gray700,
              ),
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

  // Toggle online/offline status
  Future<void> _toggleOnlineStatus() async {
    setState(() => _isTogglingOnline = true);

    try {
      final newStatus = !_isOnline;
      final response = await _dio.patch(
        '/users/me',
        data: {'isOnline': newStatus},
      );

      if (response.statusCode == 200) {
        setState(() {
          _isOnline = newStatus;
        });

        // Démarrer/arrêter l'envoi de localisation selon le statut
        if (newStatus) {
          // Envoyer la position immédiatement quand on passe online
          await _syncLocationToBackend();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus
                  ? '✅ Vous êtes maintenant en ligne - GPS activé'
                  : '⚠️ Vous êtes maintenant hors ligne - GPS en veille',
            ),
            backgroundColor: newStatus ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur toggle online: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Erreur lors du changement de statut'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isTogglingOnline = false);
    }
  }

  void _showCurrentPassesWidget(BuildContext context) {
    final passes = [
      {
        'name': 'Pass Journalier',
        'duration': '24 heures',
        'price': 1000,
        'description': 'Recevez des demandes de livraison pendant 24 heures',
      },
      {
        'name': 'Pass Hebdomadaire',
        'duration': '7 jours',
        'price': 5000,
        'description': 'Recevez des demandes de livraison pendant 7 jours',
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
                children: [
                  ...passes.map(
                    (pass) => Padding(
                      padding: const EdgeInsets.only(bottom: DEMSpacing.md),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(sheetContext);
                          Future.delayed(const Duration(milliseconds: 300), () {
                            _showPassCheckout(
                              context,
                              pass['name']!.toString(),
                              pass['duration']!.toString(),
                              pass['price'] as int,
                              pass['description']!.toString(),
                            );
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(DEMSpacing.lg),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: DEMColors.primary.withOpacity(0.3),
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
                                    crossAxisAlignment: CrossAxisAlignment.end,
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
                  ),
                ],
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
    int discountAmount = 0;
    int finalAmount = price;
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
                  // Infos du pass
                  Container(
                    padding: const EdgeInsets.all(DEMSpacing.lg),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: DEMColors.primary.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          passName,
                          style: DEMTypography.subtitle1.copyWith(
                            fontWeight: FontWeight.w700,
                            color: DEMColors.primary,
                          ),
                        ),
                        const SizedBox(height: DEMSpacing.sm),
                        Text(
                          description,
                          style: DEMTypography.body2.copyWith(
                            color: DEMColors.gray700,
                          ),
                        ),
                        const SizedBox(height: DEMSpacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Durée',
                                  style: DEMTypography.caption.copyWith(
                                    color: DEMColors.gray600,
                                  ),
                                ),
                                Text(
                                  duration,
                                  style: DEMTypography.body2.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Prix',
                                  style: DEMTypography.caption.copyWith(
                                    color: DEMColors.gray600,
                                  ),
                                ),
                                Text(
                                  '$price FCFA',
                                  style: DEMTypography.body2.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: DEMColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (discountAmount > 0) ...[
                          const SizedBox(height: DEMSpacing.md),
                          const Divider(),
                          const SizedBox(height: DEMSpacing.sm),
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
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: DEMSpacing.lg),

                  // Code promo
                  TextField(
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (value) => promoCode = value,
                    decoration: InputDecoration(
                      labelText: 'Code promo (optionnel)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DEMSpacing.sm),
                      ),
                      prefixIcon: const Icon(Icons.local_offer,
                          color: DEMColors.primary),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: DEMSpacing.sm),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: DEMColors.primary, width: 1.5),
                      padding:
                          const EdgeInsets.symmetric(vertical: DEMSpacing.sm),
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
                              final dio = getIt<Dio>();
                              final response = await dio.post(
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
                            } on DioException catch (e) {
                              final message =
                                  e.response?.data?['message']?.toString() ??
                                      'Code promo invalide.';
                              setSheetState(() {
                                promoValidated = false;
                                discountAmount = 0;
                                finalAmount = price;
                                promoMessage = message;
                              });
                            } catch (_) {
                              setSheetState(() {
                                promoValidated = false;
                                discountAmount = 0;
                                finalAmount = price;
                                promoMessage =
                                    'Impossible de vérifier le code promo.';
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
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
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
                    children: [
                      ChoiceChip(
                        label: const Text('Wave'),
                        selected: selectedMethod == 'wave',
                        onSelected: (_) =>
                            setSheetState(() => selectedMethod = 'wave'),
                      ),
                      ChoiceChip(
                        label: const Text('Orange Money'),
                        selected: selectedMethod == 'orange_money',
                        onSelected: (_) => setSheetState(
                            () => selectedMethod = 'orange_money'),
                      ),
                      ChoiceChip(
                        label: const Text('Yas'),
                        selected: selectedMethod == 'yas',
                        onSelected: (_) =>
                            setSheetState(() => selectedMethod = 'yas'),
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

                        final passBloc = getIt<PassBloc>();
                        passBloc.add(
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
