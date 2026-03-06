part of 'deliveries_bloc.dart';

abstract class DeliveriesEvent extends Equatable {
  const DeliveriesEvent();

  @override
  List<Object?> get props => [];
}

class FetchDeliveriesEvent extends DeliveriesEvent {
  const FetchDeliveriesEvent();
}

class GetDeliveryDetailsEvent extends DeliveriesEvent {
  final String id;

  const GetDeliveryDetailsEvent({required this.id});

  @override
  List<Object?> get props => [id];
}

class UpdateDeliveryStatusEvent extends DeliveriesEvent {
  final String id;
  final String status;

  const UpdateDeliveryStatusEvent({
    required this.id,
    required this.status,
  });

  @override
  List<Object?> get props => [id, status];
}
