import 'package:delivery_express_mobility_frontend/features/deliveries/domain/entities/delivery.dart';

/// Test data factory for generating mock deliveries
class DeliveryTestDataFactory {
  /// Generate a single test delivery
  static Delivery generateDelivery({
    String id = '1',
    String clientName = 'John Doe',
    String clientPhone = '+221771234567',
    String pickupAddress = '123 Main St, Dakar',
    String deliveryAddress = '456 Oak Ave, Dakar',
    String status = 'PENDING',
    double amount = 5000,
    int distance = 10,
    int estimatedTime = 30,
  }) {
    return Delivery(
      id: id,
      clientName: clientName,
      clientPhone: clientPhone,
      pickupAddress: pickupAddress,
      deliveryAddress: deliveryAddress,
      status: status,
      amount: amount,
      createdAt: DateTime.now(),
      distance: distance.toDouble(),
      estimatedTime: estimatedTime,
    );
  }

  /// Generate multiple test deliveries
  static List<Delivery> generateDeliveries(int count) {
    final statuses = ['PENDING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'];
    final clients = [
      'John Doe',
      'Jane Smith',
      'Ahmed Hassan',
      'Marie Diallo',
      'Pierre Ndiaye',
    ];

    return List.generate(
      count,
      (index) => Delivery(
        id: '${index + 1}',
        clientName: clients[index % clients.length],
        clientPhone: '+22177${1000000 + index}',
        pickupAddress: '${index + 100} Main St, Dakar',
        deliveryAddress: '${index + 200} Oak Ave, Dakar',
        status: statuses[index % statuses.length],
        amount: (5000 + (index * 500)).toDouble(),
        createdAt: DateTime.now(),
        distance: (5 + index).toDouble(),
        estimatedTime: 20 + (index * 5),
      ),
    );
  }

  /// Generate deliveries by status
  static List<Delivery> generateDeliveriesByStatus(String status, int count) {
    return List.generate(
      count,
      (index) => generateDelivery(
        id: '${index + 1}',
        clientName: 'Client ${index + 1}',
        status: status,
      ),
    );
  }

  /// Generate a delivery with custom status progression
  static List<Delivery> generateDeliveryProgression() {
    return [
      generateDelivery(id: '1', status: 'PENDING'),
      generateDelivery(id: '2', status: 'IN_PROGRESS'),
      generateDelivery(id: '3', status: 'COMPLETED'),
      generateDelivery(id: '4', status: 'CANCELLED'),
    ];
  }
}
