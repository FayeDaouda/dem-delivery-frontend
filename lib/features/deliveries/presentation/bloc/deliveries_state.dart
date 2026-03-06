part of 'deliveries_bloc.dart';

abstract class DeliveriesState extends Equatable {
  const DeliveriesState();

  @override
  List<Object?> get props => [];
}

class DeliveriesInitial extends DeliveriesState {
  const DeliveriesInitial();
}

class DeliveriesLoading extends DeliveriesState {
  const DeliveriesLoading();
}

class DeliveriesLoaded extends DeliveriesState {
  final List<Delivery> deliveries;

  const DeliveriesLoaded({required this.deliveries});

  @override
  List<Object?> get props => [deliveries];
}

class DeliveryDetailsLoaded extends DeliveriesState {
  final Delivery delivery;

  const DeliveryDetailsLoaded({required this.delivery});

  @override
  List<Object?> get props => [delivery];
}

class DeliveriesFailure extends DeliveriesState {
  final String message;

  const DeliveriesFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

class DeliveryStatusUpdated extends DeliveriesState {
  final String deliveryId;

  const DeliveryStatusUpdated({required this.deliveryId});

  @override
  List<Object?> get props => [deliveryId];
}
