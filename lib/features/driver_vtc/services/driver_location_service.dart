import 'dart:async';

import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DriverLocationService {
  final Dio _dio;

  DriverLocationService({required Dio dio}) : _dio = dio;

  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _locationSyncTimer;

  /// Demande les permissions de localisation
  Future<bool> ensureLocationAccess() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission != LocationPermission.denied &&
        permission != LocationPermission.deniedForever;
  }

  /// Obtient la position actuelle
  Future<Position?> getCurrentLocation() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  /// Stream des positions en temps réel
  Stream<Position> getPositionStream() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // 10 mètres
    );
    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  /// Démarrer le suivi GPS avec sync périodique au backend
  void startLocationTracking({
    required Function(Position) onPositionUpdate,
    required bool isOnline,
  }) {
    _positionStreamSubscription = getPositionStream().listen(
      (Position position) {
        onPositionUpdate(position);
      },
      onError: (e) {},
    );

    // Sync position toutes les 10 secondes si online
    _locationSyncTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) {
        if (isOnline) {
          syncLocationToBackend();
        }
      },
    );
  }

  /// Envoyer la position au backend
  Future<void> syncLocationToBackend({
    Position? position,
  }) async {
    try {
      position ??= await getCurrentLocation();
      if (position == null) return;

      await _dio.patch(
        '/users/me/location',
        data: {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      // Silent
    }
  }

  /// Arrêter le suivi GPS
  void stopLocationTracking() {
    _positionStreamSubscription?.cancel();
    _locationSyncTimer?.cancel();
  }

  /// Convertir Position en LatLng
  static LatLng toLatLng(Position position) {
    return LatLng(position.latitude, position.longitude);
  }
}
