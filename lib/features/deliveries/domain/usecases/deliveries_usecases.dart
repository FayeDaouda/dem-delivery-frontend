import '../../domain/entities/delivery.dart';
import '../../domain/repositories/deliveries_repository.dart';

class FetchDeliveriesUseCase {
  final DeliveriesRepository repository;

  FetchDeliveriesUseCase({required this.repository});

  Future<List<Delivery>> call() async {
    return await repository.fetchDeliveries();
  }
}

class GetDeliveryDetailsUseCase {
  final DeliveriesRepository repository;

  GetDeliveryDetailsUseCase({required this.repository});

  Future<Delivery> call(String id) async {
    return await repository.getDeliveryDetails(id);
  }
}

class UpdateDeliveryStatusUseCase {
  final DeliveriesRepository repository;

  UpdateDeliveryStatusUseCase({required this.repository});

  Future<void> call(String id, String status) async {
    return await repository.updateDeliveryStatus(id, status);
  }
}
