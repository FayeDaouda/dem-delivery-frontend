import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../services/driver_location_service.dart';
import '../../services/driver_rides_service.dart';
import '../../services/driver_stats_service.dart';
import 'driver_event.dart';
import 'driver_state.dart';

class DriverBloc extends Bloc<DriverEvent, DriverState> {
  final DriverLocationService _locationService;
  final DriverRidesService _ridesService;
  final DriverStatsService _statsService;

  DriverBloc({
    required DriverLocationService locationService,
    required DriverRidesService ridesService,
    required DriverStatsService statsService,
  })  : _locationService = locationService,
        _ridesService = ridesService,
        _statsService = statsService,
        super(const DriverInitial()) {
    on<InitializeDriverEvent>(_onInitialize);
    on<ToggleOnlineStatusEvent>(_onToggleOnlineStatus);
    on<UpdateLocationEvent>(_onUpdateLocation);
    on<LoadRidesEvent>(_onLoadRides);
    on<LoadDashboardDataEvent>(_onLoadDashboardData);
    on<RefreshProfileEvent>(_onRefreshProfile);
  }

  Future<void> _onInitialize(
    InitializeDriverEvent event,
    Emitter<DriverState> emit,
  ) async {
    emit(const DriverLoading());
    try {
      final profile = await _statsService.loadDriverProfile();
      if (profile == null) {
        emit(const DriverError('Impossible de charger le profil'));
        return;
      }

      final hasLocationAccess = await _locationService.ensureLocationAccess();
      LatLng? currentPosition;
      if (hasLocationAccess) {
        final pos = await _locationService.getCurrentLocation();
        if (pos != null) {
          currentPosition = LatLng(pos.latitude, pos.longitude);
        }
      }

      emit(DriverReady(
        isOnline: _parseBool(profile['isOnline']),
        dailyEarnings: _parseInt(
          profile['dailyEarnings'] ??
              profile['dailyEarningsToday'] ??
              profile['todayGain'],
        ),
        hasActivePass: _parseBool(profile['hasActivePass']),
        profilePhotoUrl: profile['profilePhoto'] ?? profile['photoUrl'],
        currentPosition: currentPosition,
      ));
    } catch (e) {
      emit(DriverError('Erreur: $e'));
    }
  }

  Future<void> _onToggleOnlineStatus(
    ToggleOnlineStatusEvent event,
    Emitter<DriverState> emit,
  ) async {
    if (state is! DriverReady) return;
    final currentState = state as DriverReady;

    final success = await _statsService.toggleOnlineStatus(event.newStatus);
    if (success) {
      emit(currentState.copyWith(isOnline: event.newStatus));
    }
  }

  Future<void> _onUpdateLocation(
    UpdateLocationEvent event,
    Emitter<DriverState> emit,
  ) async {
    final newPosition = LatLng(event.latitude, event.longitude);
    emit(DriverLocationUpdated(newPosition));

    if (state is DriverReady) {
      final currentState = state as DriverReady;
      emit(currentState.copyWith(currentPosition: newPosition));
    }
  }

  Future<void> _onLoadRides(
    LoadRidesEvent event,
    Emitter<DriverState> emit,
  ) async {
    emit(const DriverLoading());
    try {
      final rides = await _ridesService.loadDeliveryHistory();
      emit(DriverRidesLoaded(rides));
    } catch (e) {
      emit(DriverError('Erreur: $e'));
    }
  }

  Future<void> _onLoadDashboardData(
    LoadDashboardDataEvent event,
    Emitter<DriverState> emit,
  ) async {
    emit(const DriverLoading());
    try {
      final profile = await _statsService.loadDriverProfile();
      final deliveries = await _ridesService.loadDeliveryHistory();

      final todayDeliveries = _ridesService.getTodayDeliveries(deliveries);
      final todayEarnings = _statsService.calculateTodayEarnings(deliveries);

      final circles = <Circle>[];
      for (var i = 0; i < todayDeliveries.length; i++) {
        final location =
            _ridesService.extractPickupLocation(todayDeliveries[i]);
        final center = location ?? const LatLng(14.6937, -17.4441);

        circles.add(
          Circle(
            circleId: CircleId('heat_$i'),
            center: center,
            radius: 250,
            fillColor: const Color.fromARGB(56, 255, 0, 0),
            strokeColor: const Color.fromARGB(127, 255, 0, 0),
            strokeWidth: 1,
          ),
        );
      }

      emit(DriverDashboardLoaded(
        todayEarnings: todayEarnings,
        todayDeliveries: todayDeliveries.length,
        heatmap: circles,
        isOnline: _parseBool(profile?['isOnline']),
      ));
    } catch (e) {
      emit(DriverError('Erreur: $e'));
    }
  }

  Future<void> _onRefreshProfile(
    RefreshProfileEvent event,
    Emitter<DriverState> emit,
  ) async {
    if (state is! DriverReady) return;
    try {
      final profile = await _statsService.loadDriverProfile();
      if (profile != null && state is DriverReady) {
        final currentState = state as DriverReady;
        emit(currentState.copyWith(
          isOnline: _parseBool(profile['isOnline']),
          dailyEarnings: _parseInt(
            profile['dailyEarnings'] ??
                profile['dailyEarningsToday'] ??
                profile['todayGain'],
          ),
          profilePhotoUrl: profile['profilePhoto'] ?? profile['photoUrl'],
        ));
      }
    } catch (e) {
      // Silent error, keep current state
    }
  }

  bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.toLowerCase();
      return v == 'true' || v == '1' || v == 'yes';
    }
    return false;
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
