import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/delivery.dart';
import '../../domain/usecases/deliveries_usecases.dart';

part 'deliveries_event.dart';
part 'deliveries_state.dart';

class DeliveriesBloc extends Bloc<DeliveriesEvent, DeliveriesState> {
  final FetchDeliveriesUseCase fetchDeliveriesUseCase;
  final GetDeliveryDetailsUseCase getDeliveryDetailsUseCase;
  final UpdateDeliveryStatusUseCase updateDeliveryStatusUseCase;

  DeliveriesBloc({
    required this.fetchDeliveriesUseCase,
    required this.getDeliveryDetailsUseCase,
    required this.updateDeliveryStatusUseCase,
  }) : super(const DeliveriesInitial()) {
    on<FetchDeliveriesEvent>(_onFetchDeliveries);
    on<GetDeliveryDetailsEvent>(_onGetDeliveryDetails);
    on<UpdateDeliveryStatusEvent>(_onUpdateDeliveryStatus);
  }

  Future<void> _onFetchDeliveries(
    FetchDeliveriesEvent event,
    Emitter<DeliveriesState> emit,
  ) async {
    // Évite le flicker si une liste est déjà affichée
    if (state is! DeliveriesLoaded) {
      emit(const DeliveriesLoading());
    }
    try {
      final deliveries = await fetchDeliveriesUseCase();
      emit(DeliveriesLoaded(deliveries: deliveries));
    } catch (e) {
      emit(DeliveriesFailure(message: e.toString()));
    }
  }

  Future<void> _onGetDeliveryDetails(
    GetDeliveryDetailsEvent event,
    Emitter<DeliveriesState> emit,
  ) async {
    // Évite le flicker quand on navigue entre détails
    if (state is! DeliveryDetailsLoaded) {
      emit(const DeliveriesLoading());
    }
    try {
      final delivery = await getDeliveryDetailsUseCase(event.id);
      emit(DeliveryDetailsLoaded(delivery: delivery));
    } catch (e) {
      emit(DeliveriesFailure(message: e.toString()));
    }
  }

  Future<void> _onUpdateDeliveryStatus(
    UpdateDeliveryStatusEvent event,
    Emitter<DeliveriesState> emit,
  ) async {
    try {
      await updateDeliveryStatusUseCase(event.id, event.status);
      emit(DeliveryStatusUpdated(deliveryId: event.id));
    } catch (e) {
      emit(DeliveriesFailure(message: e.toString()));
    }
  }
}
