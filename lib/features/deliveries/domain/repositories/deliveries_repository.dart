import '../../domain/entities/delivery.dart';

abstract class DeliveriesRepository {
  Future<List<Delivery>> fetchDeliveries();
  Future<Delivery> getDeliveryDetails(String id);
  Future<void> updateDeliveryStatus(String id, String status);
}
