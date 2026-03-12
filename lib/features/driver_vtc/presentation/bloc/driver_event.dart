abstract class DriverEvent {
  const DriverEvent();
}

class InitializeDriverEvent extends DriverEvent {
  const InitializeDriverEvent();
}

class ToggleOnlineStatusEvent extends DriverEvent {
  final bool newStatus;
  const ToggleOnlineStatusEvent(this.newStatus);
}

class UpdateLocationEvent extends DriverEvent {
  final double latitude;
  final double longitude;
  const UpdateLocationEvent(this.latitude, this.longitude);
}

class LoadRidesEvent extends DriverEvent {
  const LoadRidesEvent();
}

class LoadDashboardDataEvent extends DriverEvent {
  const LoadDashboardDataEvent();
}

class RefreshProfileEvent extends DriverEvent {
  const RefreshProfileEvent();
}
