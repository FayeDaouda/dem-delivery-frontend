import 'package:google_maps_flutter/google_maps_flutter.dart';

abstract class DriverState {
  const DriverState();
}

class DriverInitial extends DriverState {
  const DriverInitial();
}

class DriverLoading extends DriverState {
  const DriverLoading();
}

class DriverReady extends DriverState {
  final bool isOnline;
  final int dailyEarnings;
  final bool hasActivePass;
  final String? profilePhotoUrl;
  final LatLng? currentPosition;

  const DriverReady({
    required this.isOnline,
    required this.dailyEarnings,
    required this.hasActivePass,
    this.profilePhotoUrl,
    this.currentPosition,
  });

  DriverReady copyWith({
    bool? isOnline,
    int? dailyEarnings,
    bool? hasActivePass,
    String? profilePhotoUrl,
    LatLng? currentPosition,
  }) {
    return DriverReady(
      isOnline: isOnline ?? this.isOnline,
      dailyEarnings: dailyEarnings ?? this.dailyEarnings,
      hasActivePass: hasActivePass ?? this.hasActivePass,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      currentPosition: currentPosition ?? this.currentPosition,
    );
  }
}

class DriverLocationUpdated extends DriverState {
  final LatLng position;
  const DriverLocationUpdated(this.position);
}

class DriverRidesLoaded extends DriverState {
  final List<Map<String, dynamic>> rides;
  const DriverRidesLoaded(this.rides);
}

class DriverDashboardLoaded extends DriverState {
  final int todayEarnings;
  final int todayDeliveries;
  final List<Circle> heatmap;
  final bool isOnline;

  const DriverDashboardLoaded({
    required this.todayEarnings,
    required this.todayDeliveries,
    required this.heatmap,
    required this.isOnline,
  });
}

class DriverError extends DriverState {
  final String message;
  const DriverError(this.message);
}
