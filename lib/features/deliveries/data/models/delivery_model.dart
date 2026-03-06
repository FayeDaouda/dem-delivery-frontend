import '../../domain/entities/delivery.dart';

class DeliveryModel extends Delivery {
  const DeliveryModel({
    required super.id,
    required super.pickupAddress,
    required super.deliveryAddress,
    required super.status,
    required super.clientName,
    required super.clientPhone,
    required super.amount,
    required super.createdAt,
    super.completedAt,
    super.distance,
    super.estimatedTime,
  });

  factory DeliveryModel.fromJson(Map<String, dynamic> json) {
    return DeliveryModel(
      id: json['id'] ?? '',
      pickupAddress: json['pickupAddress'] ?? '',
      deliveryAddress: json['deliveryAddress'] ?? '',
      status: json['status'] ?? 'PENDING',
      clientName: json['clientName'] ?? '',
      clientPhone: json['clientPhone'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      distance: json['distance'] != null
          ? (json['distance'] as num).toDouble()
          : null,
      estimatedTime: json['estimatedTime'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pickupAddress': pickupAddress,
      'deliveryAddress': deliveryAddress,
      'status': status,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'amount': amount,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}
